global class BrokerTerminationSuspensionExpiryBatch implements Database.Batchable<SObject>{//, Schedulable{
    
    private static final string MTD_BROKER_TERMINATION_COMPLETION_EMAIL_TEMPLATE_ID { get { return 'BrokerTerminationCompletionEmailTemplate'; } }
    private static final string MTD_BROKER_PASSPORT_EXPIRY_EMAIL_TEMPLATE_ID  { get { return 'BrokerPassportDocExpiryEmailTemplate'; } }
    private static final string MTD_BROKER_NATIONAL_ID_EXPIRY_EMAIL_TEMPLATE_ID  { get { return 'NationalIdExpiryEmailTemplate'; } }
    private static final string MTD_BROKER_RERA_EXPIRY_EMAIL_TEMPLATE_ID  { get { return 'ReraExpiryEmailTemplate'; } }
    private static final string MTD_BROKER_SUSPEND_EMAIL_TEMPLATE_ID { get { return 'BrokerSuspendNotification'; } } // BAPP    
    private static final string NO_REPLY_OWEID { get { return 'BloomNoReplyOWEmailId'; } }
    
    private static final string MTD_BROKER_REG_EXPIRY_FIRST_NOTIFICATION_DAYS { get { return 'FirstNotificationDays'; } }
    private static final string MTD_BROKER_REG_EXPIRY_SECOND_NOTIFICATION_DAYS { get { return 'SecondNotificationDays'; } }
    private static final string MTD_BROKER_REG_EXPIRY_THIRD_NOTIFICATION_DAYS { get { return 'ThirdNotificationDays'; } }
    
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id,Email,PassportExpiryDate__c,EID_Expiry_Date__c,AccountId,Blacklisted__c,TerminationApprovalStatus__c,Broker_Restriction_Type__c,BrokerContactRole__c,
                                         IsSuspended__c,SuspensionStartDate__c,SuspensionEndDate__c,BRN_RERA_Expiry_Date__c FROM Contact WHERE AccountId != null AND RecordType.Name = 'Broker']);
    }
    
    global void execute(Database.BatchableContext bc, List<Contact> scope) {
        Date currentDate = System.today();
        //List<Contact> contactsToUpdate = new List<Contact>();
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        Id brokerTerminationCompletedTemplateId  = objMetadataService.getAppSettingTextValue(MTD_BROKER_TERMINATION_COMPLETION_EMAIL_TEMPLATE_ID);
        Id brokerPassportExpiryTemplateId   = objMetadataService.getAppSettingTextValue(MTD_BROKER_PASSPORT_EXPIRY_EMAIL_TEMPLATE_ID);
        Id brokerNationalIdExpiryTemplateId   = objMetadataService.getAppSettingTextValue(MTD_BROKER_NATIONAL_ID_EXPIRY_EMAIL_TEMPLATE_ID);
        Id brokerReraExpiryTemplateId   = objMetadataService.getAppSettingTextValue(MTD_BROKER_RERA_EXPIRY_EMAIL_TEMPLATE_ID);
        
        Id brokerSuspendTemplateId = objMetadataService.getAppSettingTextValue(MTD_BROKER_SUSPEND_EMAIL_TEMPLATE_ID);
        Id noReplyOWEId = objMetadataService.getAppSettingTextValue(NO_REPLY_OWEID);
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        
        Integer firstNotificationDays = objMetadataService.getAppSettingNumberValue(MTD_BROKER_REG_EXPIRY_FIRST_NOTIFICATION_DAYS);
        Integer secondNotificationDays = objMetadataService.getAppSettingNumberValue(MTD_BROKER_REG_EXPIRY_SECOND_NOTIFICATION_DAYS);
        Integer thirdNotificationDays = objMetadataService.getAppSettingNumberValue(MTD_BROKER_REG_EXPIRY_THIRD_NOTIFICATION_DAYS);
        
        Date firstNotificationDate = System.today().addDays(firstNotificationDays);
        Date secondNotificationDate = System.today().addDays(secondNotificationDays);
        Date thirdNotificationDate = System.today().addDays(thirdNotificationDays);
        
        
        Set<Id> contactIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        
        for (Contact con : scope) {
            system.debug('con'+con);
            contactIds.add(con.Id);
            accountIds.add(con.AccountId);
        }
        
        Map<Id,List<BrokerCommission__c>> pendingCommissionMap = BrokerCommissionService.getInstance().getPendingBrokerCommissionByAccountAndContact(accountIds,contactIds);
        Map<Id, Contact> contactsToUpdate = new Map<Id, Contact>();
        
        for (Contact con : scope) {
            if(con.EID_Expiry_Date__c == firstNotificationDate || con.EID_Expiry_Date__c == secondNotificationDate  
               || con.EID_Expiry_Date__c == thirdNotificationDate){
                   emailList.add(objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(brokerNationalIdExpiryTemplateId,noReplyOWEId,null,con.Id,null,null,null));
               }
            if(con.PassportExpiryDate__c == firstNotificationDate || con.PassportExpiryDate__c == secondNotificationDate
               || con.PassportExpiryDate__c == thirdNotificationDate){
                   emailList.add(objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(brokerPassportExpiryTemplateId,noReplyOWEId,null,con.Id,null,null,null));
               }
            if(con.BRN_RERA_Expiry_Date__c == firstNotificationDate || con.BRN_RERA_Expiry_Date__c == secondNotificationDate  
               || con.BRN_RERA_Expiry_Date__c == thirdNotificationDate){
                   emailList.add(objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(brokerReraExpiryTemplateId,noReplyOWEId,null,con.Id,null,null,null));
               }
            if (con.TerminationApprovalStatus__c == 'Approved' && con.Blacklisted__c == false && con.Broker_Restriction_Type__c == 'Terminate') {
                List<BrokerCommission__c> pendingCommissions = pendingCommissionMap.containsKey(con.Id) ? pendingCommissionMap.get(con.Id) : new List<BrokerCommission__c>();
                // No pending commissions means fully paid
                system.debug('Condition true');
                if (pendingCommissions.isEmpty()) {
                    system.debug('pendingCommissions>>>>'+pendingCommissions);
                    Contact upd = contactsToUpdate.containsKey(con.Id) ? contactsToUpdate.get(con.Id) : new Contact(Id = con.Id);
                    upd.Blacklisted__c = true;
                    upd.IsActive__c = false;
                    contactsToUpdate.put(con.Id, upd);
                    //contactsToUpdate.add(new Contact(Id = con.Id, Blacklisted__c = true, IsActive__c = false));
                    if(con.Email != null){
                        emailList.add(objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(brokerTerminationCompletedTemplateId,noReplyOWEId,null,con.Id,null,null,null));
                    }
                }
            }
            if(con.EID_Expiry_Date__c == currentDate && con.IsSuspended__c == false){
                if(con.Email != null){
                    Contact upd = contactsToUpdate.containsKey(con.Id) ? contactsToUpdate.get(con.Id) : new Contact(Id = con.Id);
                    upd.IsSuspended__c = true;
                    upd.SuspensionStartDate__c = currentDate;
                    contactsToUpdate.put(con.Id, upd);
                    //contactsToUpdate.add(new Contact(Id = con.Id, IsSuspended__c = true,SuspensionStartDate__c = currentDate));
                    emailList.add(objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(brokerSuspendTemplateId,noReplyOWEId,null,con.Id,null,null,null));
                }
            }
            if( con.PassportExpiryDate__c == currentDate && con.IsSuspended__c == false){
                if(con.Email != null && (con.BrokerContactRole__c.contains('Admin') || con.BrokerContactRole__c.contains('Partner') ||
                                         con.BrokerContactRole__c.contains('Owner') || con.BrokerContactRole__c.contains('AuthorizedSignatoryOfficer'))){
                                             Contact upd = contactsToUpdate.containsKey(con.Id) ? contactsToUpdate.get(con.Id) : new Contact(Id = con.Id);
                                             upd.IsSuspended__c = true;
                                             upd.SuspensionStartDate__c = currentDate;
                                             contactsToUpdate.put(con.Id, upd);
                                             //contactsToUpdate.add(new Contact(Id = con.Id, IsSuspended__c = true,SuspensionStartDate__c = currentDate));
                                             emailList.add(objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(brokerSuspendTemplateId,noReplyOWEId,null,con.Id,null,null,null));
                                         }
            }
            if(con.BRN_RERA_Expiry_Date__c == currentDate && con.IsSuspended__c == false){
                system.debug('con.BRN_RERA_Expiry_Date__c-->'+con.BRN_RERA_Expiry_Date__c);
                if(con.Email != null){
                    system.debug('con.Email-->'+con.Email);
                    Contact upd = contactsToUpdate.containsKey(con.Id) ? contactsToUpdate.get(con.Id) : new Contact(Id = con.Id);
                    upd.IsSuspended__c = true;
                    upd.SuspensionStartDate__c = currentDate;
                    contactsToUpdate.put(con.Id, upd);
                    
                    //contactsToUpdate.add(new Contact(Id = con.Id, IsSuspended__c = true,SuspensionStartDate__c = currentDate));
                    emailList.add(objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(brokerSuspendTemplateId,noReplyOWEId,null,con.Id,null,null,null));
                }
            }
            // Keep Suspended if no suspension end date
            if (con.SuspensionEndDate__c == null && con.SuspensionStartDate__c != null && con.isSuspended__c == false) {
                Contact upd = contactsToUpdate.containsKey(con.Id) ? contactsToUpdate.get(con.Id) : new Contact(Id = con.Id);
                upd.IsSuspended__c = true;
                contactsToUpdate.put(con.Id, upd);
                
                //contactsToUpdate.add(new Contact(Id = con.Id, IsSuspended__c = true));
            }
            // Auto Reactivate when:
            if (con.SuspensionEndDate__c != null && con.SuspensionEndDate__c == currentDate
                && con.isSuspended__c == true && con.EID_Expiry_Date__c > currentDate && con.PassportExpiryDate__c > currentDate) {
                    Contact upd = contactsToUpdate.containsKey(con.Id) ? contactsToUpdate.get(con.Id) : new Contact(Id = con.Id);
                    upd.IsSuspended__c = false;
                    upd.IsActive__c = true;
                    contactsToUpdate.put(con.Id, upd);
                    
                    //contactsToUpdate.add(new Contact(Id = con.Id, IsSuspended__c = false,IsActive__c = true));
                }
            
        }
        
        ContactService.updateExistingContacts(contactsToUpdate.values());
        objEmailService.sendEmail(emailList);
    }
    
    global void finish(Database.BatchableContext bc) {
    }
    
    // Scheduler Method
    /*global void execute(SchedulableContext sc) {

Database.executeBatch(new BrokerTerminationBatch(), 200);
}*/
}