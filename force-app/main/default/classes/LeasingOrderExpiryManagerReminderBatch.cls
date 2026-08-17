global class LeasingOrderExpiryManagerReminderBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        Date targetDubaiDate = System.today().addDays(125);
        Date targetAbuDhabiDate = System.today().addDays(95);
        
        return Database.getQueryLocator([
            SELECT Id, Name, LeasingEndDate__c, OwnerId, Owner.Email, 
                   Project__r.City__c, LeasingOrderNumber__c, Project__r.Name, Unit__r.UnitNumber__c, Account__r.Name
            FROM LeasingOrder__c
            WHERE Status__c = 'Leased' 
            AND LeasingEndDate__c != null
            AND (
                (Project__r.City__c = 'Dubai' AND LeasingEndDate__c = :targetDubaiDate) OR
                (Project__r.City__c = 'Abu Dhabi' AND LeasingEndDate__c = :targetAbuDhabiDate)
            )
        ]);
    }
    
    global void execute(Database.BatchableContext BC, List<LeasingOrder__c> scope) {
        String REMINDER_MAIL_DUBAI_MANAGER ='LeaseExpiryReminderForManagerDubai';
        String REMINDER_MAIL_ABUDHABI_MANAGER ='LeaseExpiryReminderForManagerAbudhabi';
        List<Reminder__c> remindersToInsert = new List<Reminder__c>();
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        MetadataService metadataService = MetadataService.getInstance();
        LeasingOrderService leasingOrderService = LeasingOrderService.getInstance();
    
        Id dubaiTemplateId = metadataService.getAppSettingTextValue(REMINDER_MAIL_DUBAI_MANAGER);
        Id abuDhabiTemplateId = metadataService.getAppSettingTextValue(REMINDER_MAIL_ABUDHABI_MANAGER);
    
        Set<Id> abuDhabiOrderIds = new Set<Id>();
        Map<Id, List<String>> orderToDocumentNames = new Map<Id, List<String>>();
    
        for (LeasingOrder__c lo : scope) {
            if (lo.Project__r.City__c == 'Abu Dhabi') {
                abuDhabiOrderIds.add(lo.Id);
                orderToDocumentNames.put(lo.Id, new List<String>{'Leasing Contract - Signed'});
            }
        }
            
        Map<Id, List<Messaging.EmailFileAttachment>> orderAttachments = new Map<Id, List<Messaging.EmailFileAttachment>>();
        if (!abuDhabiOrderIds.isEmpty()) {
            Map<Id, List<ContentVersion>> orderContentVersions = leasingOrderService.getLeasingOrderAttachments(
                abuDhabiOrderIds,
                orderToDocumentNames,
                new List<String>{'Leasing Contract - Signed'}
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
    
        for (LeasingOrder__c lo : scope) {
            String uniqueToken = UUID.randomUUID().toString();
    
            Reminder__c newReminder = new Reminder__c();
            newReminder.LeasingOrder__c = lo.Id;
            newReminder.Stage__c = 'Sent to Manager';
            newReminder.ReminderToken__c = uniqueToken;
            newReminder.SendToLeasingManagerDate__c = System.today();
            remindersToInsert.add(newReminder);
    
            if (lo.Owner.Email != null) {
                Id templateId = lo.Project__r.City__c == 'Dubai' ? dubaiTemplateId : abuDhabiTemplateId;
    
                Date tenantNotificationDate = System.today().addDays(5);
    
                Messaging.SingleEmailMessage renderedMail = Messaging.renderStoredEmailTemplate(templateId, UserInfo.getUserId(), lo.Id);
    
                String subject = renderedMail.getSubject();
                String body = renderedMail.getHtmlBody();
    
                String tenantNotificationDateStr = String.valueOf(tenantNotificationDate.day()).leftPad(2, '0') + '/' +
                    String.valueOf(tenantNotificationDate.month()).leftPad(2, '0') + '/' +
                    String.valueOf(tenantNotificationDate.year());
    
                subject = subject.replace('{[LeasingOrder__c.Project__r.Name]}', lo.Project__r.Name != null ? lo.Project__r.Name : '');
                subject = subject.replace('{[LeasingOrder__c.Unit__r.UnitNumber__c]}', lo.Unit__r.UnitNumber__c != null ? lo.Unit__r.UnitNumber__c : '');
                subject = subject.replace('{[LeasingOrder__c.Account__r.Name]}', lo.Account__r.Name != null ? lo.Account__r.Name : '');
    
                body = body.replace('{[TenantNotificationDate]}', tenantNotificationDateStr);
                body = body.replace('{[AnnualRentIncreament]}', '5');
    
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                
				//mail.setTargetObjectId(lo.OwnerId);
				mail.setToAddresses(new List<String>{ lo.Owner.Email });
                mail.setTreatTargetObjectAsRecipient(true);
                mail.setWhatId(lo.Id);
                mail.setSaveAsActivity(true);
                mail.setSubject(subject);
                mail.setHtmlBody(body);
    
                if (lo.Project__r.City__c == 'Abu Dhabi' && orderAttachments.containsKey(lo.Id)) {
                    mail.setFileAttachments(orderAttachments.get(lo.Id));
                }
    
                emailsToSend.add(mail);
            }
        }
    
        if (!remindersToInsert.isEmpty()) {
            System.debug(remindersToInsert);
            System.debug(remindersToInsert.Size());
            insert remindersToInsert;
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