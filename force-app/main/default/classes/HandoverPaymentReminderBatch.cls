/***
Class       : HandoverPaymentReminderBatch
Description : Batch class to send payment reminder emails and log attachments to EmailMessage activity.
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version         Date                Details                         Author
1.      V1.0            25/06/2024          Initial Version                 Rajat Rastogi
2.      V2.0            29/07/2026          Refactored Version              Jhilik Gandhi
3.      V3.0            13/08/2026          Enforce RequiredSOAAttachment__c Antariksh Jain
****************************************************************************************************************/ 

public class HandoverPaymentReminderBatch implements Database.Batchable<SObject>, Schedulable {    
    private static final String MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final String NoReplyEmailAddress = 'NoReplyEmailAddress';
    private static final String OrgWideEmailAddress = 'OrgWideEmailAddress';
    private static final String PaymentReminderAfter30Days = 'PaymentReminderAfter30Days';
    private static final String PaymentReminderAfter20Days = 'PaymentReminderAfter20Days';
    private static final String PaymentReminderAfter10Days = 'PaymentReminderAfter10Days';
  
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, Handover_Phase__r.RequiredSOAAttachment__c, Handover_Phase__r.FirstHOPaymentReminderEmailTempId__c, 
                   Handover_Phase__r.SecondHOPaymentReminderEmailTempId__c, Handover_Phase__r.ThirdHOPaymentReminderEmailTempId__c, 
                   StopAllEmailCommunication__c, Name, Project__r.BloomPhoneArabic__c, Handover_Phase__r.PaymentReminderStop__c,
                   FirstPaymentReminderEmailDate__c, SecondPaymentReminderEmailDate__c, ThirdPaymentReminderEmail_Date__c, NOC_Date__c, 
                   Payment_Settled__c, Promise_to_Pay_Date__c, Sub_Status__c, Project_Name_Arabic__c, Project_Name__c, AccountManagerEmail__c, Unit__c,
                   CustomerEmail__c, Customer_Name__c, Project__r.Name, Account_Manager_Name__c, Account_Manager_Email__c, Account_Manager_Phone__c, 
                   Project__c, Project__r.ProjectNameArabic__c, Customer_Name_Arabic__c, Account_Manager_Name_Arabic__c, Notice_of_Completion_Date__c,
                   Sales_Order__r.Account__c, Sales_Order__r.Account__r.Phone, Sales_Order__r.Account__r.MobileCountryCode__pc, Sales_Order__r.Account__r.PersonMailingCountry,
                   Bloom_Email__c, Bloom_Phone__c, Unit_Code__c, Unit__r.DoorNumber__c, Account__c, Contact__c,
                   (SELECT Id, Content_Version_Id__c, Document_Name__c FROM Documents__r WHERE Document_Name__c = 'SOA' AND Content_Version_Id__c != NULL)
            FROM Handover__c 
            WHERE Payment_Settled__c = false 
            AND Handover_Phase__r.PaymentReminderStop__c = false 
            AND StopAllEmailCommunication__c = false 
            AND CustomerEmail__c != NULL
            AND (Notice_of_Completion_Date__c != NULL OR Promise_to_Pay_Date__c != NULL)
        ]);
    }

    public void execute(Database.BatchableContext BC, List<Handover__c> handoverList) {
        System.debug('handoverList-->' + handoverList);
        MetadataService HandoverMetadataService = MetadataService.getInstance();
        HandoverService objHandoverService = HandoverService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        EmailMessageService objEmailMessageService = EmailMessageService.getInstance();
        
        Id bloomNoReplySalesOWEId = HandoverMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
        String noreply = HandoverMetadataService.getAppSettingTextValue(NoReplyEmailAddress);
        String owea = HandoverMetadataService.getAppSettingTextValue(OrgWideEmailAddress);
      
        Set<Id> emailTemplateIds = new Set<Id>();
        for (Handover__c handover : handoverList) {   
            if (String.isNotBlank(handover.Handover_Phase__r?.FirstHOPaymentReminderEmailTempId__c)) {
                emailTemplateIds.add((Id) handover.Handover_Phase__r.FirstHOPaymentReminderEmailTempId__c);
            }
            if (String.isNotBlank(handover.Handover_Phase__r?.SecondHOPaymentReminderEmailTempId__c)) {
                emailTemplateIds.add((Id) handover.Handover_Phase__r.SecondHOPaymentReminderEmailTempId__c);
            }
            if (String.isNotBlank(handover.Handover_Phase__r?.ThirdHOPaymentReminderEmailTempId__c)) {
                emailTemplateIds.add((Id) handover.Handover_Phase__r.ThirdHOPaymentReminderEmailTempId__c);
            }
        }

        Map<Id, EmailTemplate> emailTemplateMap = new Map<Id, EmailTemplate>();
        if (!emailTemplateIds.isEmpty()) {
            emailTemplateMap = new Map<Id, EmailTemplate>(objEmailService.getEmailTemplatesByIds(emailTemplateIds));
        }
        
        // Populate SOA ContentVersion Map ONLY for Handovers whose Phase requires SOA attachments
        Map<Id, Id> handoverIdToSOADocContentVersionIdMap = new Map<Id, Id>();
        for (Handover__c handover : handoverList) {
            Boolean isSOAAttachmentRequired = isSOARequired(handover);
            if (isSOAAttachmentRequired) {
                List<Document__c> SOADocument = handover.Documents__r;
                if (SOADocument != null && !SOADocument.isEmpty()) {
                    handoverIdToSOADocContentVersionIdMap.put(handover.Id, SOADocument[0].Content_Version_Id__c);
                }
            }
        }

        Map<Id, ContentVersion> contentVersionMap = new Map<Id, ContentVersion>();
        if (!handoverIdToSOADocContentVersionIdMap.isEmpty()) {
            contentVersionMap = new Map<Id, ContentVersion>(
                [SELECT Id, VersionData, Title, FileExtension FROM ContentVersion WHERE Id IN :handoverIdToSOADocContentVersionIdMap.values()]
            );
        }

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        List<Handover__c> handoversToUpdate = new List<Handover__c>();

        for (Handover__c handover : handoverList) {
            if ((handover.Notice_of_Completion_Date__c != null && handover.Notice_of_Completion_Date__c < Date.today() && handover.Promise_to_Pay_Date__c == null)
                    || (handover.Promise_to_Pay_Date__c != null && handover.Promise_to_Pay_Date__c < Date.today())) {
                
                Date referenceDate = handover.Promise_to_Pay_Date__c != null ? handover.Promise_to_Pay_Date__c : handover.Notice_of_Completion_Date__c;

                if (referenceDate != null) {
                    Integer daysDifference = referenceDate.daysBetween(Date.today());
                    EmailTemplate template = null;
                    Id selectedTemplateId = null;

                    switch on daysDifference {
                        when 10 {
                            selectedTemplateId = handover.Handover_Phase__r?.FirstHOPaymentReminderEmailTempId__c;
                            template = emailTemplateMap.get(selectedTemplateId);
                            handover.FirstPaymentReminderEmailDate__c = Date.today();
                        }
                        when 20 {
                            selectedTemplateId = handover.Handover_Phase__r?.SecondHOPaymentReminderEmailTempId__c;
                            template = emailTemplateMap.get(selectedTemplateId);
                            handover.SecondPaymentReminderEmailDate__c = Date.today();
                        }
                        when 30 {
                            selectedTemplateId = handover.Handover_Phase__r?.ThirdHOPaymentReminderEmailTempId__c;
                            template = emailTemplateMap.get(selectedTemplateId);
                            handover.ThirdPaymentReminderEmail_Date__c = Date.today();
                        }
                        when else {
                            continue;
                        }
                    }

                    if (template == null) {
                        continue;
                    }

                    // Extract SOA ContentVersion record only if RequiredSOAAttachment__c is true
                    ContentVersion cvRecord = null;
                    if (isSOARequired(handover)) {
                        Id SOACVId = handoverIdToSOADocContentVersionIdMap.get(handover.Id);
                        cvRecord = contentVersionMap.get(SOACVId);
                    }

                    emails.add(
                        getEmailContent(handover, new List<String>{handover.CustomerEmail__c}, objEmailService, template, bloomNoReplySalesOWEId, cvRecord)
                    );
                    handoversToUpdate.add(handover);
                }
            }            
        }
        
        if (!emails.isEmpty()) {
            Messaging.SendEmailResult[] results = objEmailService.sendEmail(emails);
            
            // Query latest EmailMessage records created for successful emails
            Set<Id> processedHandoverIds = new Set<Id>();
            for (Handover__c h : handoversToUpdate) {
                processedHandoverIds.add(h.Id);
            }
            Map<Id, EmailMessage> objEmailMessageMap = objEmailMessageService.getLatestEmailMessageByRelatedIds(processedHandoverIds);
            
            List<Attachment> attachmentListOnActivity = new List<Attachment>();

            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    Id handoverId = emails[i].getWhatId();
                    
                    if (objEmailMessageMap.containsKey(handoverId)) {
                        EmailMessage objEmailMessage = objEmailMessageMap.get(handoverId);
                        
                        // Attach SOA to Activity ONLY if RequiredSOAAttachment__c is true and ContentVersion exists
                        Id SOACVId = handoverIdToSOADocContentVersionIdMap.get(handoverId);
                        ContentVersion objCV = (SOACVId != null) ? contentVersionMap.get(SOACVId) : null;

                        if (objCV != null) {
                            Attachment att = new Attachment();
                            att.ParentId = objEmailMessage.Id;
                            
                            String baseName = objCV.Title;
                            String extension = (objCV.FileExtension != null) ? objCV.FileExtension.toLowerCase() : 'pdf';
                            
                            while (baseName.toLowerCase().endsWith('.' + extension + '.' + extension)) {
                                baseName = baseName.substring(0, baseName.length() - (extension.length() + 1));
                            }
                            
                            if (!baseName.toLowerCase().endsWith('.' + extension)) {
                                baseName += '.' + extension;
                            }
                            
                            att.Name = baseName;
                            att.Body = objCV.VersionData;
                            attachmentListOnActivity.add(att);
                        }
                    }
                }
            }

          
                objEmailMessageService.insertEmailAttachment(attachmentListOnActivity);
            

            objHandoverService.updateHandovers(handoversToUpdate);
        }
    }

    public Messaging.SingleEmailMessage getEmailContent(Handover__c handoverRec, List<String> toAddresses, EmailService objEmailService, EmailTemplate emailTemplate, Id bloomNoReplySalesOWEId, ContentVersion SOADocContentVersion) {
        String emailSubject = emailTemplate.Subject != null ? emailTemplate.Subject : '';
        String emailBody = emailTemplate.HtmlValue != null ? emailTemplate.HtmlValue : '';
        
        emailSubject = emailSubject.replace('{{{Handover__c.Project_Name__c}}}', String.isNotBlank(handoverRec.Project_Name__c) ? handoverRec.Project_Name__c : '')
            .replace('{{{Handover__c.Unit_Code__c}}}', String.isNotBlank(handoverRec.Unit_Code__c) ? handoverRec.Unit_Code__c : '')
            .replace('{{{Handover__c.Project_Name_Arabic__c}}}', String.isNotBlank(handoverRec.Project_Name_Arabic__c) ? handoverRec.Project_Name_Arabic__c : '');
            
        emailBody = emailBody.replace('{{{Handover__c.Customer_Name__c}}}', String.isNotBlank(handoverRec.Customer_Name__c) ? handoverRec.Customer_Name__c : '')
            .replace('{{{Handover__c.Customer_Name_Arabic__c}}}', String.isNotBlank(handoverRec.Customer_Name_Arabic__c) ? handoverRec.Customer_Name_Arabic__c : '')
            .replace('{{{Handover__c.Project_Name__c}}}', String.isNotBlank(handoverRec.Project_Name__c) ? handoverRec.Project_Name__c : '')
            .replace('{{{Handover__c.Project_Name_Arabic__c}}}', String.isNotBlank(handoverRec.Project_Name_Arabic__c) ? handoverRec.Project_Name_Arabic__c : '')
            .replace('{{{Handover__c.Unit_Code__c}}}', String.isNotBlank(handoverRec.Unit_Code__c) ? handoverRec.Unit_Code__c : '')
            .replace('{{{Handover__c.Unit__r.DoorNumber__c}}}', handoverRec.Unit__r?.DoorNumber__c != null ? String.valueOf(handoverRec.Unit__r.DoorNumber__c) : '')
            .replace('{{{Handover__c.NOC_Date__c}}}', handoverRec.Notice_of_Completion_Date__c != null ? String.valueOf(handoverRec.Notice_of_Completion_Date__c) : '')
            .replace('{{{Handover__c.Account_Manager_Name__c}}}', String.isNotBlank(handoverRec.Account_Manager_Name__c) ? handoverRec.Account_Manager_Name__c : '')
            .replace('{{{Handover__c.Account_Manager_Name_Arabic__c}}}', String.isNotBlank(handoverRec.Account_Manager_Name_Arabic__c) ? handoverRec.Account_Manager_Name_Arabic__c : '')
            .replace('{{{Handover__c.Account_Manager_Phone__c}}}', String.isNotBlank(handoverRec.Account_Manager_Phone__c) ? handoverRec.Account_Manager_Phone__c : '')
            .replace('{{{Handover__c.Bloom_Phone__c}}}', String.isNotBlank(handoverRec.Bloom_Phone__c) ? handoverRec.Bloom_Phone__c : '')
            .replace('{{{Handover__c.Project__r.BloomPhoneArabic__c}}}', String.isNotBlank(handoverRec.Project__r?.BloomPhoneArabic__c) ? handoverRec.Project__r.BloomPhoneArabic__c : '')
            .replace('{{{Handover__c.Bloom_Email__c}}}', String.isNotBlank(handoverRec.Bloom_Email__c) ? handoverRec.Bloom_Email__c : '');
            
        Messaging.SingleEmailMessage email = objEmailService.getSingleEmailMessage(toAddresses, handoverRec.Id, handoverRec.Contact__c, emailSubject, emailBody, bloomNoReplySalesOWEId);
        
        email.setSaveAsActivity(true);

        // Attach SOA only if RequiredSOAAttachment__c is true AND valid ContentVersion data exists
        if (isSOARequired(handoverRec) 
            && SOADocContentVersion != null 
            && SOADocContentVersion.VersionData != null 
            && String.isNotBlank(SOADocContentVersion.Title)) {
            
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            String fileName = SOADocContentVersion.Title.endsWith('.pdf') ? SOADocContentVersion.Title : SOADocContentVersion.Title + '.pdf';
            attachment.setFileName(fileName);
            attachment.setBody(SOADocContentVersion.VersionData);
            attachment.setContentType('application/pdf');
            email.setFileAttachments(new List<Messaging.EmailFileAttachment>{ attachment });
        }
        
        return email;
    }

    // Helper method to safely evaluate RequiredSOAAttachment__c regardless of Checkbox or Text data type
    private Boolean isSOARequired(Handover__c handover) {
        if (handover.Handover_Phase__r == null || handover.Handover_Phase__r.RequiredSOAAttachment__c == null) {
            return false;
        }
        Object val = handover.Handover_Phase__r.RequiredSOAAttachment__c;
        if (val instanceof Boolean) {
            return (Boolean) val;
        }
        return String.valueOf(val).equalsIgnoreCase('true');
    }

    public void finish(Database.BatchableContext BC) {
        // Post-processing
    }
    
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new HandoverPaymentReminderBatch(), 200);
    }
}