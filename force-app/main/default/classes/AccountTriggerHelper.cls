/*
* @Author : Biswajeet Samal
* @CreatedDate : 7th AUG 2024
* @Description : AccountTriggerHelper
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           Biswajeet   07AUG2024        Initial draft 
* 1.1           Anjaneya    21April2025      added Category Update
* 1.2           Kalpana   	22May2025        Added handleAfterUpdateFieldUpdates
* 1.3           Swapnil   	15April2026      Move the BAPP after-insert logic to the before-insert context
*****************************************************************************************************/
public class AccountTriggerHelper {
    
    private static final Set<String> royalSalutations = new Set<String>{'Her Royal Highness','His Royal Highness','Her Excellency','His Highness','His Excellency','Sheikh/Sheikah'};
        private static final string CUSTOMER_CATEGORY_DIAMOND { get { return 'Diamond'; } }
    private static final string ACCOUNT_RT_DEV_NAME_PERSON_ACCOUNT { get { return 'PersonAccount'; } }
    private static final string ACCOUNT_RT_DEV_NAME_ORGANIZATION_ACCOUNT { get { return 'OrganizationAccount'; } }
    private static final string ACCOUNT_RT_DEV_NAME_BROKER_AGENCY_ACCOUNT { get { return 'Broker_Agency'; } }
    private static final String LINE_MANAGER_USER_ID { get { return 'LineManagerUserId'; } } //BAPP
    private static final String EXEC_SALES_DIR_USER_ID { get { return 'ExecutiveSalesDirectorUserId'; } }//BAPP
    public static final String SUQUR_AL_WATAN = 'Suqur Al-Watan';
    
    public static void createDocuments(List<Account> newList){
        
        Id personAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_PERSON_ACCOUNT);
        Id organizationAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_ORGANIZATION_ACCOUNT);
        Id brokerAgencyAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, ACCOUNT_RT_DEV_NAME_BROKER_AGENCY_ACCOUNT);
        
        DocumentService objDocumentService = DocumentService.getInstance();
        List<DocumentType__c> accountDocTypeList = objDocumentService.getDocTypes('Account');
        List<Document__c> documentList = new List<Document__c>();
        for(Account acc :newList){
            //fetch Suqur Al Watan doc types
           List<DocumentType__c> suqurDocTypeList = objDocumentService.getSuqurAlWatanDocumentTypes(acc.id);
            
            for(DocumentType__c objDocumentType :accountDocTypeList){
                if(objDocumentType.RecordTypeDevName__c == ACCOUNT_RT_DEV_NAME_BROKER_AGENCY_ACCOUNT && acc.RecordTypeId == brokerAgencyAccountRecordTypeId){
                    if (objDocumentType.TypeofEstablishment__c != null && acc.TypeofEstablishment__c != null) {
                        String docTypeEst = ';' + objDocumentType.TypeofEstablishment__c + ';';
                        String accEst = ';' + acc.TypeofEstablishment__c + ';';
                        
                        if (docTypeEst.contains(accEst)) {
                            documentList.add(new Document__c(Account__c = acc.Id,DocumentType__c = objDocumentType.Id,Document_Name__c = objDocumentType.Type__c));
                        }
                    }
                    //documentList.add(new Document__c(Account__c = acc.Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c));
                }else if(objDocumentType.RecordTypeDevName__c == ACCOUNT_RT_DEV_NAME_PERSON_ACCOUNT && acc.RecordTypeId == personAccountRecordTypeId){
                    documentList.add(new Document__c(Account__c = acc.Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c));
                }else if(objDocumentType.RecordTypeDevName__c == ACCOUNT_RT_DEV_NAME_ORGANIZATION_ACCOUNT && acc.RecordTypeId == organizationAccountRecordTypeId){
                    documentList.add(new Document__c(Account__c = acc.Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c));
                }
            }
            // New Suqur Al Watan block(Added By ranjan)
            if(acc.CustomerSubType__c == SUQUR_AL_WATAN && !suqurDocTypeList.isEmpty()){
            for(DocumentType__c suqurDocType : suqurDocTypeList){
                documentList.add(new Document__c(
                    Account__c       = acc.Id,
                    DocumentType__c  = suqurDocType.Id,
                    Document_Name__c = suqurDocType.Type__c
                ));
            }
          }
        }
        objDocumentService.insertDocuments(documentList);   
    }
    
    public static void handleSuqurAlWatanDocumentOnUpdate(List<Account> newList, Map<Id, Account> oldMap) {
    DocumentService objDocumentService = DocumentService.getInstance();
    List<Document__c> documentList = new List<Document__c>();

    for (Account acc : newList) {
        Account oldAcc = oldMap.get(acc.Id);

        // Only proceed if CustomerSubType__c changed TO 'Suqur Al Watan'
        if (acc.CustomerSubType__c == SUQUR_AL_WATAN 
            && oldAcc.CustomerSubType__c != SUQUR_AL_WATAN) {

            List<DocumentType__c> suqurDocTypeList = 
                objDocumentService.getSuqurAlWatanDocumentTypes(acc.Id);

            if (!suqurDocTypeList.isEmpty()) {
                // Get existing documents to avoid duplicates
                List<Document__c> existingDocs = 
                    objDocumentService.getDocumentByAccountIds(new Set<Id>{ acc.Id });

                Set<Id> existingDocTypeIds = new Set<Id>();
                for (Document__c doc : existingDocs) {
                    if (doc.DocumentType__c != null) {
                        existingDocTypeIds.add(doc.DocumentType__c);
                    }
                }

                for (DocumentType__c suqurDocType : suqurDocTypeList) {
                    if (!existingDocTypeIds.contains(suqurDocType.Id)) {
                        documentList.add(new Document__c(
                            Account__c       = acc.Id,
                            DocumentType__c  = suqurDocType.Id,
                            Document_Name__c = suqurDocType.Type__c
                        ));
                    }
                }
            }
        }
    }

    if (!documentList.isEmpty()) {
        objDocumentService.insertDocuments(documentList);
    }
}
    
    public static void handleBeforeInsertFieldUpdates(List<Account> newList) {
        MetadataService objMetadataService = MetadataService.getInstance();
        Id brokerAgencyRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker Agency').getRecordTypeId();
        String lineManagerUserId = objMetadataService.getAppSettingTextValue(LINE_MANAGER_USER_ID);//BAPP
        String executiveSalesDirectorUserId = objMetadataService.getAppSettingTextValue(EXEC_SALES_DIR_USER_ID);//BAPP
        for(Account objAccount :newList){
            if(objAccount.RecordTypeId == brokerAgencyRtId){
                objAccount.Send_To_SAP__c = true;
                // BAPP after-insert logic to the before-insert context
                if (String.isNotBlank(objAccount.TypeofEstablishment__c)){
                    objAccount.LineManager__c = lineManagerUserId;
                    objAccount.ExecutiveSalesDirector__c = executiveSalesDirectorUserId;
                }
            }
            if (objAccount.RecordTypeId == brokerAgencyRtId || objAccount.Send_To_SAP__c) {
                objAccount.Integration_Status__c = 'In Progress';
            }
            objAccount.Segment__c = royalSalutations.contains(objAccount.Salutation) ? CUSTOMER_CATEGORY_DIAMOND : '' ;
            if(objAccount.IsPersonAccount){
                objAccount.Emirates_Id__pc = Utility.formatEmiratesId(objAccount.Emirates_Id__pc);
            }
            
            if(String.isNotBlank(objAccount.Nationality__c)){
                objAccount.CountryCodeForSAP__c = objMetadataService.getCountryCodeByNationality(objAccount.Nationality__c);
                objAccount.NationalityInArabic__c = objMetadataService.getNationalityInArabic(objAccount.Nationality__c);
            }
            
            if(objAccount.IsPersonAccount){
                if(objAccount.PrimaryMobileCountryCode__pc != NULL && objAccount.PrimaryMobilePhone__pc != NULL){
                    objAccount.PersonMobilePhone = Utility.formatPhoneNumber(objAccount.PrimaryMobileCountryCode__pc, objAccount.PrimaryMobilePhone__pc);
                }
                if(objAccount.SecondaryMobileCountryCode__pc != NULL && objAccount.SecondaryMobilePhone__pc != NULL){
                    objAccount.PersonHomePhone = Utility.formatPhoneNumber(objAccount.SecondaryMobileCountryCode__pc, objAccount.SecondaryMobilePhone__pc);
                }
                if(objAccount.TertiaryMobileCountryCode__pc != NULL && objAccount.TertiaryMobilePhone__pc != NULL){
                    objAccount.PersonOtherPhone = Utility.formatPhoneNumber(objAccount.TertiaryMobileCountryCode__pc, objAccount.TertiaryMobilePhone__pc);
                }
            }else{
                objAccount.Phone = Utility.formatPhoneNumber(objAccount.PhoneCountryCode__c, objAccount.Phone__c);
            }
        }
    }
    
    public static void handleAfterInsertFieldUpdates(List<Account> newList) {
        
        Set<Id> accountIds = new Set<Id>();
        
        for (Account acc : newList) {
            if (acc.Send_To_SAP__c) {
                accountIds.add(acc.Id);
            }
        }
        
        if (!accountIds.isEmpty()) {
            AccountService accService = AccountService.getInstance();
            List<IntegrationRecord__c> integrationRecordsToInsert = new List<IntegrationRecord__c>();
            List<Account> accountList = accService.getAccountsWithPrimrayContact(accountIds);
            for(Account acc : accountList ){
                integrationRecordsToInsert.add(accService.getIntegrationRecord(acc));
            }
            IntegrationRecordService.getInstance().insertIntegrationRecords(integrationRecordsToInsert);
        }
    }
    
    public static void handleBeforeUpdateFieldUpdates(List<Account> newList, Map<Id, Account> oldMap) {
        MetadataService objMetadataService = MetadataService.getInstance();
        List<Schema.FieldSetMember> sapFieldSetFields = Schema.SObjectType.Account.fieldSets.getMap().get('SAP_Integration_Fields').getFields();
        for(Account objAccount :newList){
            if( objAccount.Salutation != oldMap.get(objAccount.Id).Salutation && 
               royalSalutations.contains(objAccount.Salutation) ){
                   objAccount.Segment__c = CUSTOMER_CATEGORY_DIAMOND ;
               }
            if(objAccount.IsPersonAccount && objAccount.Emirates_Id__pc != oldMap.get(objAccount.Id).Emirates_Id__pc){
                objAccount.Emirates_Id__pc = Utility.formatEmiratesId(objAccount.Emirates_Id__pc);
            }
            
            if(String.isNotBlank(objAccount.Nationality__c) && objAccount.Nationality__c != oldMap.get(objAccount.Id).Nationality__c){
                objAccount.CountryCodeForSAP__c = objMetadataService.getCountryCodeByNationality(objAccount.Nationality__c);
                objAccount.NationalityInArabic__c = objMetadataService.getNationalityInArabic(objAccount.Nationality__c);
            }
            
            if(objAccount.IsPersonAccount){
                if((objAccount.PrimaryMobileCountryCode__pc != oldMap.get(objAccount.Id).PrimaryMobileCountryCode__pc)
                   || (objAccount.PrimaryMobilePhone__pc != oldMap.get(objAccount.Id).PrimaryMobilePhone__pc)){
                       objAccount.PersonMobilePhone = Utility.formatPhoneNumber(objAccount.PrimaryMobileCountryCode__pc, objAccount.PrimaryMobilePhone__pc);
                   }
                
                if((objAccount.SecondaryMobileCountryCode__pc != oldMap.get(objAccount.Id).SecondaryMobileCountryCode__pc)
                   || (objAccount.SecondaryMobilePhone__pc != oldMap.get(objAccount.Id).SecondaryMobilePhone__pc)){
                       objAccount.PersonHomePhone = Utility.formatPhoneNumber(objAccount.SecondaryMobileCountryCode__pc, objAccount.SecondaryMobilePhone__pc);
                   }
                
                if((objAccount.TertiaryMobileCountryCode__pc != oldMap.get(objAccount.Id).TertiaryMobileCountryCode__pc)
                   || (objAccount.TertiaryMobilePhone__pc != oldMap.get(objAccount.Id).TertiaryMobilePhone__pc)){
                       objAccount.PersonOtherPhone = Utility.formatPhoneNumber(objAccount.TertiaryMobileCountryCode__pc, objAccount.TertiaryMobilePhone__pc);
                   }
            }else{
                if((objAccount.PhoneCountryCode__c != oldMap.get(objAccount.Id).PhoneCountryCode__c)
                   || (objAccount.Phone__c != oldMap.get(objAccount.Id).Phone__c)){
                       objAccount.Phone = Utility.formatPhoneNumber(objAccount.PhoneCountryCode__c, objAccount.Phone__c);
                   }
            }
            
            // Set the Send_To_SAP__c field to true based on changes made in the FieldSet SAP_Integration_Fields.
            for (FieldSetMember member : sapFieldSetFields){
                String field = member.getFieldPath();
                if (objAccount.get(field) != oldMap.get(objAccount.Id).get(field)){
                    objAccount.Send_To_SAP__c = true;
                    break;
                }
            }
            if(!oldMap.get(objAccount.Id).Send_To_SAP__c && objAccount.Send_To_SAP__c){
                objAccount.Integration_Status__c = 'In Progress';
            }
        }
    }
    
    public static void handleAfterUpdateFieldUpdates(List<Account> newList, Map<Id, Account> oldMap) {
        
        Set<Id> accountIds = new Set<Id>();
        
        for (Account acc : newList) {
            if (!oldMap.get(acc.Id).Send_To_SAP__c && acc.Send_To_SAP__c) {
                accountIds.add(acc.Id);
            }
        }
        
        if (!accountIds.isEmpty()) {
            AccountService accService = AccountService.getInstance();
            List<IntegrationRecord__c> integrationRecordsToInsert = new List<IntegrationRecord__c>();
            List<Account> accountList = accService.getAccountsWithPrimrayContact(accountIds);
            for(Account acc : accountList ){
                integrationRecordsToInsert.add(accService.getIntegrationRecord(acc));
            }
            IntegrationRecordService integService = IntegrationRecordService.getInstance();
            integService.insertIntegrationRecords(integrationRecordsToInsert);
        }
        
    }
    
    public static void BrokerAgencyAfterUpdate(List<Account> newList, Map<Id, Account> oldMap) {
        List<Account> accountsToUpdate = new List<Account>();
        List<Contact> contactsToUpdate = new List<Contact>();
        List<Id> accountIdsForEmail = new List<Id>();
        
        for (Account acc : newList) {
            Account oldAcc = oldMap.get(acc.Id);
            
            // Proceed only if ApprovalStatus__c has changed
            if (acc.ApprovalStatus__c != oldAcc.ApprovalStatus__c) {
                
                //  Approved by Executive Sales Director + Suspend
                if (acc.ApprovalStatus__c == 'Approved By Executive Sales Director' &&
                    acc.Scenarios__c == 'Suspend') {
                        
                        Account accUpdate = new Account(Id = acc.Id, IsActive__c = false, IsSuspended__c = true);
                        accountsToUpdate.add(accUpdate);
                        
                        List<Contact> conSuspendList = ContactService.getInstance().getContactByAccountId(acc.Id);
                        
                        // Related Contacts
                        for (Contact con : conSuspendList) {
                            Contact conUpdate = new Contact(
                                Id = con.Id,
                                IsActive__c = false,
                                IsSuspended__c = true,
                                Suspension_Reason__c = acc.SuspensionReason__c
                            );
                            contactsToUpdate.add(conUpdate);
                        }
                        
                        accountIdsForEmail.add(acc.Id);
                    }
                
                //  Approved by Executive Sales Director + Terminate
                else if (acc.ApprovalStatus__c == 'Approved By Executive Sales Director' && acc.Scenarios__c == 'Terminate') {
                    
                    Account accUpdate = new Account(Id = acc.Id, IsActive__c = false, Blacklisted__c = true);
                    accountsToUpdate.add(accUpdate);
                    
                    List<Contact> conTerminateList = ContactService.getInstance().getContactByAccountId(acc.Id);
                    // Related Contacts
                    for (Contact con : conTerminateList) {
                        Contact conUpdate = new Contact(
                            Id = con.Id,
                            IsActive__c = false,
                            Blacklisted__c = true,
                            BlacklistReason__c = acc.Blacklist_Reason__c
                        );
                        contactsToUpdate.add(conUpdate);
                    }
                    
                    accountIdsForEmail.add(acc.Id);
                }
                
                //  Approved by Line Manager + Suspend
                else if (acc.ApprovalStatus__c == 'Approved By Line Manager' &&
                         acc.Scenarios__c == 'Suspend') {
                             sendNotificationEmail(acc, 'Line Manager Approved Suspend');
                         }
                
                //  Approved by Line Manager + Terminate
                else if (acc.ApprovalStatus__c == 'Approved By Line Manager' &&
                         acc.Scenarios__c == 'Terminate') {
                             sendNotificationEmail(acc, 'Line Manager Approved');
                         }
            }
        }
        
        AccountService accService = AccountService.getInstance();
        accService.updateAccountsWithoutTrigger(accountsToUpdate);
        
        ContactService conService = ContactService.getInstance();
        conService.updateContactsWithoutTrigger(contactsToUpdate);
        
        // Call Email Handler for Suspension/Termination (ESD Approved)
        if (!accountIdsForEmail.isEmpty()) {
            BAPPSuspentionTerminationEmailHandler.sendWarningEmails(accountIdsForEmail);
        }
    }
    
    public static void sendNotificationEmail(Account acc, String templateName) {
        try {
            //  Get Email Template by DeveloperName (using the variable, not string literal)
        EmailTemplate emailTemplate = EmailTemplateService.getEmailTemplateByName(templateName);
            
            if (emailTemplate == null) {
                System.debug(' No email template found with DeveloperName: ' + templateName);
                return;
        }
        
        //  Get Users (Line Manager + Executive Sales Director) assigned on Account
            Id lineManagerId = acc.LineManager__c;
            Id executiveSalesDirectorId = acc.ExecutiveSalesDirector__c;
        
        List<Id> toUserIds = new List<Id>();
        if (lineManagerId != null) toUserIds.add(lineManagerId);
        if (executiveSalesDirectorId != null) toUserIds.add(executiveSalesDirectorId);
        
        if (toUserIds.isEmpty()) {
                System.debug(' No recipients found for Account: ' + acc.Id);
            return;
        }
        
            //  Query user emails
            Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Email FROM User WHERE Id IN :toUserIds]);
        
            //  Prepare list of emails to send
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
            
            for (User u : userMap.values()) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTemplateId(emailTemplate.Id);
                mail.setTargetObjectId(u.Id);
            mail.setWhatId(acc.Id);
            mail.setSaveAsActivity(false);
            
            mails.add(mail);
        }             
            
        //  Send all emails in one call
            if (!mails.isEmpty()) {
                Messaging.sendEmail(mails);
                System.debug('Email sent using template: ' + templateName + ' for Account: ' + acc.Id);
            }
        } catch (Exception e) {
            System.debug('Error sending email for Account ' + acc.Id + ': ' + e.getMessage());
        }
    }
}