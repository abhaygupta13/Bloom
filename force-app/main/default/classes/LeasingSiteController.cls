/***
Class       : LeasingSiteController
Author      : 
Description : This is using to Upload documents and sending email to Opportunity Owner
TestClass   : 
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
****************************************************************************************************************/
public without sharing class LeasingSiteController {
    private static final string BLOOM_NO_REPLY_LEASING_OW_EMAIL_ID { get { return 'BloomNoReplyLeasingOWEmailId'; } }
    private static final string LEASING_DOC_UPLOADED_TEMPLATE_ID { get { return 'LeasingDocUploadNotificationId'; } }
    
@AuraEnabled
    public static void uploadFiles(String recordId, List<FileWrapper> files) {
        try {
            List<ContentVersion> fileListToInsert = new List<ContentVersion>();
            DocumentService docService = DocumentService.getInstance();

            for (FileWrapper fw : files) {
                List<Document__c> docList = docService.getLeasingOfferDocumentsByOppIdAndCategory(recordId, fw.category);
                for (Document__c doc : docList) {
                    ContentVersion cv = new ContentVersion();
                    cv.Title = fw.category + '_' + fw.fileName;
                    cv.PathOnClient = fw.fileName;
                    cv.VersionData = EncodingUtil.base64Decode(fw.fileData);
                    cv.FirstPublishLocationId = doc.Id;
                    fileListToInsert.add(cv);
                }
            }

            if (!fileListToInsert.isEmpty()) {
                ContentService.getInstance().createContentVersion(fileListToInsert);
            }
            sendOpportunityNotificationEmail(recordId);

        } catch (Exception e) {
            throw new AuraHandledException('Error uploading files: ' + e.getMessage());
        }
    }
    @testVisible
    private static void sendOpportunityNotificationEmail(String opportunityId) {
        
        Opportunity opp =  OpportunityService.getInstance().getOpportunityById(opportunityId);
        List<String> emails = EmailService.getInstance().getOwnerEmails(opp.OwnerId);
        if (emails.isEmpty()) return;
        MetadataService objMetadataService = MetadataService.getInstance();
        
        Id leasingDocUploadedNotificationEmailTemplateId = objMetadataService.getAppSettingTextValue(LEASING_DOC_UPLOADED_TEMPLATE_ID);

        Id noReplyBloomLeasingOWDId = objMetadataService.getAppSettingTextValue(BLOOM_NO_REPLY_LEASING_OW_EMAIL_ID);
        
        EmailService.getInstance().sendEmailUsingTemplate(opp.OwnerId, leasingDocUploadedNotificationEmailTemplateId
                                                          , noReplyBloomLeasingOWDId,emails);
    }
    @AuraEnabled(cacheable=true)
    public static Opportunity getOpportunity(String opportunityId){
        OpportunityService oppService = OpportunityService.getInstance();
        return oppService.getOpportunityById(opportunityId);
    }

    public class FileWrapper {
        @AuraEnabled public String fileName { get; set; }
        @AuraEnabled public String fileData { get; set; }
        @AuraEnabled public String category { get; set; }
    }
}