/*****************************************************************************************
Class       : UnitRegGRTeamEmailBatch
Author      : Dhanraj
Description : Batch class to send email to GR Team for Unit Registration.
Test Class  : UnitRegGRTeamEmailBatchTest
Created Date: 19 Jun 2026
*****************************************************************************************/
public class UnitRegGRTeamEmailBatch implements Database.Batchable<SObject>, Schedulable{
    private static final String MTD_NO_REPLY_OWEID_SETTING { get { return 'NoReplySalesIT'; }}
    private static final string MTD_UNIT_REGISTRATION_GR_EMAIL_TEMPLATE_ID { get { return 'UnitRegistrationGREmailTemplateId'; } }
    private static final string MTD_GR_TEAM_EMAIL_ADDSS { get { return 'GRTeamEmailAddresses'; } }
    private static final string MTD_GR_DOCUMENT_LIST { get { return 'GRBatchDocumentList'; } }
    
    // Query to fetch records
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date yesterdayDate = System.today().addDays(-1);
        return Database.getQueryLocator([
            Select Id, Name,Account__c,Account__r.Name,Unit__c,Unit__r.Name,Unit__r.Project__r.Name,FundMovedToGRDate__c,FundMovedtoGR__c
            FROM SalesOrder__c
            WHERE FundMovedToGRDate__c = :yesterdayDate
        ]);
    }
    
    // Processing each batch
    public void execute(Database.BatchableContext bc, List<SalesOrder__c> scope) {
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        DocumentService objDocumentService = DocumentService.getInstance();
        Id noReplyOWDId = objMetadataService.getAppSettingTextValue(MTD_NO_REPLY_OWEID_SETTING);
        String grEmails = objMetadataService.getAppSettingTextValue(MTD_GR_TEAM_EMAIL_ADDSS);
        List<String> toAddresses = grEmails.split(',');
        List<String> requiredDocTypes = objMetadataService.getAppSettingTextValue(MTD_GR_DOCUMENT_LIST).split(',');
        EmailTemplate template = objEmailService.getEmailTemplateById(objMetadataService.getAppSettingTextValue(MTD_UNIT_REGISTRATION_GR_EMAIL_TEMPLATE_ID));
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        Set<Id> soIds = new Set<Id>();
        for(SalesOrder__c so : scope) {
            soIds.add(so.Id);
        }
        Map<Id, Map<String, Document__c>> soDocumentMap = objDocumentService.getSalesOrderDocumentsByTypes(soIds,requiredDocTypes);
        Set<Id> contentVersionIds = new Set<Id>();
        for(Map<String, Document__c> docs : soDocumentMap.values()) {
            for(Document__c doc : docs.values()) {
                if(doc.Content_Version_Id__c != null) {
                    contentVersionIds.add(doc.Content_Version_Id__c);
                }
            }
        }
        
        Map<Id, ContentVersion> contentVersionMap = new Map<Id, ContentVersion>(objDocumentService.getContentVersionsByIds(contentVersionIds));
        for(SalesOrder__c so : scope) {
            String emailBody = template.HtmlValue;
            String emailSubject = template.Subject;
            Map<String, Document__c> docs = soDocumentMap.get(so.Id);
            List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
            if(docs != null) {
                for(String docType : requiredDocTypes) {
                    Document__c doc = docs.get(docType);
                    if(doc.Content_Version_Id__c != null) {
                        ContentVersion cv = contentVersionMap.get(doc.Content_Version_Id__c);
                        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                        attachment.setFileName(cv.Title + '.' + cv.FileExtension);
                        attachment.setBody(cv.VersionData);
                        attachment.setContentType('application/pdf');
                        attachments.add(attachment);
                    }
                }
            }
            emailBody = emailBody.replace('[Project_Name]',so.Unit__r.Project__r.Name);
            emailBody = emailBody.replace('[Unit_Number]',so.Unit__r.Name);
            emailBody = emailBody.replace('[Buyer_Name]',so.Account__r.Name);
            
            Messaging.SingleEmailMessage email = objEmailService.getSingleEmailMessage(toAddresses,emailSubject,emailBody,noReplyOWDId);
            if(!attachments.isEmpty()) {
                email.setFileAttachments(attachments);
            }
            emailList.add(email);
        }
        objEmailService.sendEmail(emailList);
    }
    
    public void finish(Database.BatchableContext bc) {
        
    }
    
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new UnitRegGRTeamEmailBatch(),5);
    }
}