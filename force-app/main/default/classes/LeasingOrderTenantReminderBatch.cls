global class LeasingOrderTenantReminderBatch implements Database.Batchable<sObject>, Database.Stateful {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        Date targetManagerDate = System.today().addDays(-5);
        Date targetTenantDate = System.today().addDays(-60);
    
        return Database.getQueryLocator([
            SELECT Id,
                   Stage__c,
                   ReminderToken__c,
                   SendToLeasingManagerDate__c,
                   SendToTenantDate__c,
                   LeasingOrder__c,
                   LeasingOrder__r.LeasingOrderNumber__c,
                   LeasingOrder__r.Unit__r.UnitNumber__c,
                   LeasingOrder__r.Account__r.tdc_tvte__EmailAccount__c,
                   LeasingOrder__r.Account__r.PersonEmail,
                   LeasingOrder__r.Project__r.City__c,
                   LeasingOrder__r.RERAIndex__c,
                   LeasingOrder__r.Account__r.IsPersonAccount,
                   LeasingOrder__r.Account__r.PersonContactId
            FROM Reminder__c
            WHERE (
                Stage__c = 'Sent to Manager'
                AND SendToLeasingManagerDate__c = :targetManagerDate
            )
            OR (
                Stage__c = 'Sent to Tenant'
                AND SendToTenantDate__c = :targetTenantDate
            )
        ]);
    }

    global void execute(Database.BatchableContext BC, List<Reminder__c> scope) {
        List<Reminder__c> remindersToExpire = new List<Reminder__c>();
        List<Reminder__c> managerScope = new List<Reminder__c>();
        String SITE_URL = 'RenewalResponsePublicSiteURL';
        String EMAIL_TEMPLATE_TENANT = 'LeaseExpiryReminderForTenant';
        
        //Expire the old records
        for (Reminder__c reminder : scope) {
            if (reminder.Stage__c == 'Sent to Tenant') {
                reminder.Stage__c = 'Expired';
                remindersToExpire.add(reminder);
            } else if (reminder.Stage__c == 'Sent to Manager') {
                managerScope.add(reminder);
            }
        }
        
        if (!remindersToExpire.isEmpty()) {
            Database.update(remindersToExpire, false);
        }
        //---------
        scope = managerScope;
        
        if (scope.isEmpty()) {
            return;
        }
        
        //Send new remiders to tenants
        List<Reminder__c> remindersToUpdate = new List<Reminder__c>();
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        Set<Id> dubaiLeasingOrderIds = new Set<Id>();
        Map<Id, List<String>> orderToDocumentNames = new Map<Id, List<String>>();
        
        Set<Id> businessAccountIds = new Set<Id>();
    
        for (Reminder__c reminder : scope) {
            if (reminder.LeasingOrder__r.Project__r.City__c == 'Dubai') {
                dubaiLeasingOrderIds.add(reminder.LeasingOrder__c);
                orderToDocumentNames.put(reminder.LeasingOrder__c, new List<String>{'Dubai rera index', 'Tawtheeq /Ejari Document'});
            }
            
             if (reminder.LeasingOrder__r.Account__c != null && !reminder.LeasingOrder__r.Account__r.IsPersonAccount) { //collect business Account IDs
                businessAccountIds.add(reminder.LeasingOrder__r.Account__c);
            }
        }
        
        Map<Id, Id> accountToContactMap = new Map<Id, Id>();
        if (!businessAccountIds.isEmpty()) {
            ContactService conService = ContactService.getInstance();
            List<Contact> businessContacts = conService.getPrimaryContactsByAccountIds(businessAccountIds);
            
            for (Contact con : businessContacts) {
                if (!accountToContactMap.containsKey(con.AccountId)) {
                    accountToContactMap.put(con.AccountId, con.Id);  //Is First contact on business account, correct?
                }
            }
        }
    
        Set<Id> validDubaiLeasingOrderIds = new Set<Id>();
		Map<Id, List<Messaging.EmailFileAttachment>> orderAttachments = new Map<Id, List<Messaging.EmailFileAttachment>>();
		
        //Validation for dubai location
        if (!dubaiLeasingOrderIds.isEmpty()) {
            DocumentService docService = DocumentService.getInstance();
            LeasingOrderService leasingOrderService = LeasingOrderService.getInstance();
    
            List<Document__c> dubaiDocs = docService.getLeasingSignDocuments(dubaiLeasingOrderIds, new List<String>{'Dubai rera index'});
            for (Document__c doc : dubaiDocs) {
                if (doc.ContentDocumentId__c != null && doc.Content_Version_Id__c != null ) {
                    validDubaiLeasingOrderIds.add(doc.LeasingOrder__c);
                }
            }
            
            //leasing order attachment gathering
            Map<Id, List<ContentVersion>> orderContentVersions = leasingOrderService.getLeasingOrderAttachments(
                dubaiLeasingOrderIds,
                orderToDocumentNames,
                new List<String>{'Dubai rera index', 'Tawtheeq /Ejari Document'}
            );
    
            for (Id orderId : orderContentVersions.keySet()) {
                List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
                for (ContentVersion cv : orderContentVersions.get(orderId)) {
                    Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                    attachment.setBody(cv.VersionData);
                    attachment.setFileName(cv.Title + '.' + cv.FileExtension);
                    attachments.add(attachment);
                }
                orderAttachments.put(orderId, attachments);
            }
        }  
            //Email invoke
        
        MetadataService metaService = MetadataService.getInstance();
        Id emailTemplateId = metaService.getAppSettingTextValue(EMAIL_TEMPLATE_TENANT);
        String siteUrl = metaService.getAppSettingTextValue(SITE_URL);
        
        for (Reminder__c reminder : scope) {
            Boolean isDubai = reminder.LeasingOrder__r.Project__r.City__c == 'Dubai';
            if (isDubai && (reminder.LeasingOrder__r.RERAIndex__c == null || !validDubaiLeasingOrderIds.contains(reminder.LeasingOrder__c))) {
                continue;
            }
            
            String rawToken = reminder.ReminderToken__c != null ? reminder.ReminderToken__c : '';
            String renewalUrl = siteUrl + '?token=' + EncodingUtil.urlEncode(rawToken, 'UTF-8');
            
            Messaging.SingleEmailMessage renderedMail = Messaging.renderStoredEmailTemplate(emailTemplateId, UserInfo.getUserId(), reminder.LeasingOrder__c);
            String subject = renderedMail.getSubject();
            String body = renderedMail.getHtmlBody();
            
            body = body.replace('[{LeasingOrder__c.Unit__r.UnitNumber__c}]', reminder.LeasingOrder__r.Unit__r.UnitNumber__c != null ? reminder.LeasingOrder__r.Unit__r.UnitNumber__c : '');
            body = body.replace('[{renewalUrl}]', renewalUrl);
            body = body.replace('[{SendingDate}]', Datetime.now().format('dd/MM/yyyy'));
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            
            Id targetContactId = null;
            
            if (reminder.LeasingOrder__r.Account__r.IsPersonAccount) {
                targetContactId = reminder.LeasingOrder__r.Account__r.PersonContactId;
            } else {
                Id accId = reminder.LeasingOrder__r.Account__c;
                if (accId != null && accountToContactMap.containsKey(accId)) {
                    targetContactId = accountToContactMap.get(accId);
                }
            }
            
            if (targetContactId == null) {
                continue; 
            }
            
            email.setTargetObjectId(targetContactId);
            email.setTreatTargetObjectAsRecipient(true);
            email.setWhatId(reminder.LeasingOrder__c);
            email.setSaveAsActivity(true);
            
            email.setSubject(subject);
            email.setHtmlBody(body);
            
            if (isDubai && orderAttachments.containsKey(reminder.LeasingOrder__c)) {
                email.setFileAttachments(orderAttachments.get(reminder.LeasingOrder__c));
            }
            
            emailsToSend.add(email);
            reminder.Stage__c = 'Sent to Tenant';
            reminder.SendToTenantDate__c = System.today();
            remindersToUpdate.add(reminder);
        }
    
        if (!remindersToUpdate.isEmpty()) {
            Database.update(remindersToUpdate, false);
        }
    
        if (!emailsToSend.isEmpty() && Limits.getEmailInvocations() < Limits.getLimitEmailInvocations()) {
             System.debug(emailsToSend);
           	 System.debug(emailsToSend.Size());
             for (Messaging.SendEmailResult r : Messaging.sendEmail(emailsToSend, false)) {
                System.debug(r.isSuccess());
                if (!r.isSuccess()) {
                    System.debug(r.getErrors());
                }
            }
        }
    }


    global void finish(Database.BatchableContext BC) {
    }
}