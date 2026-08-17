/***
Class       : LeasingRenewalBatch
Author      : 
Description : Batch class to send renewals to customers
TestClass   : 
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              26/12/2025           Initial Version 
****************************************************************************************************************/
public class LeasingRenewalBatch implements Database.Batchable<SObject>, Database.allowsCallouts, Schedulable{
    private static final String BATCH_SIZE_METADATA {get {return 'LeasingRenewalBatch';}}
    private static final string LEASING_RENEWAL_EMAIL { get { return 'LeasingRenewalEmailTemplate'; } }
    private static final string BLOOM_NO_REPLY_LEASING_OW_EMAIL_ID { get { return 'BloomNoReplyLeasingOWEmailId'; } }
    private static final String SEND_TO_CUSTOMER_SETTING { get { return 'SendtoCustomer'; }}
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        Date cutoffDate = Date.today().addDays(-30);
        
        return Database.getQueryLocator([
            SELECT Id, LeasingEndDate__c, Account__c, Owner.Email
            FROM LeasingOrder__c
            WHERE LeasingEndDate__c <= :cutoffDate AND Id = 'a4nFV0000FbreK4YQI'
        ]);
    }
    
    public void execute(Database.BatchableContext bc, List<SObject> scope){
        
        
        Set<Id> changedOrderIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        
        for (LeasingOrder__c contract : (list<LeasingOrder__c>)scope) {
            
            changedOrderIds.add(contract.Id);
            if (contract.Account__c != null) {
                accountIds.add(contract.Account__c);
            }
            
        }
        
        MetadataService objMetadataService = MetadataService.getInstance();
        Id leaseTerminationEmailTemplateId =
            objMetadataService.getAppSettingTextValue(LEASING_RENEWAL_EMAIL);
        
        Id noReplyBloomLeasingOWDId =
            objMetadataService.getAppSettingTextValue(BLOOM_NO_REPLY_LEASING_OW_EMAIL_ID);
        
        Boolean sendToCustomer =
            objMetadataService.getAppSettingBooleanValue(SEND_TO_CUSTOMER_SETTING);
        
        Map<Id, Account> accountMap = new Map<Id, Account>();
        
        if (sendToCustomer && !accountIds.isEmpty()) {
            
            List<Account> accounts =
                AccountService.getInstance().getAccountsByIds(accountIds);
            
            for (Account acc : accounts) {
                accountMap.put(acc.Id, acc);
            }
        }
        
        
        Map<Id, Document__c> orderToDocMap = new Map<Id, Document__c>();
        Set<Id> contentVersionIds = new Set<Id>();
        
        List<Document__c> leasingDocuments = DocumentService.getInstance().getLeasingSignedDocumentsByContractIds(changedOrderIds);
        
        
        for (Document__c doc : leasingDocuments) {
            orderToDocMap.put(doc.LeasingOrder__c, doc);
            
            if (doc.Content_Version_Id__c != null) {
                contentVersionIds.add(doc.Content_Version_Id__c);
            }
        }
        
        if (contentVersionIds.isEmpty()) {
            return;
        }
        Map<Id, ContentVersion> contentVersionMap = new Map<Id, ContentVersion>();
        List<ContentVersion> leasingContentVersions = ContentService.getInstance().getContentVersionByIds(contentVersionIds);
        for (ContentVersion cv : leasingContentVersions) {
            contentVersionMap.put(cv.Id, cv);
        }
        
        EmailService objEmailService = EmailService.getInstance();
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        for (LeasingOrder__c contract : (list<LeasingOrder__c>)scope) {
            
            if (!changedOrderIds.contains(contract.Id)) {
                continue;
            }
            
            List<String> toAddress = new List<String>();
            
            
            // Send Email to Customer(Person Email)
            if (sendToCustomer) {
                
                Account acc = accountMap.get(contract.Account__c);
                
                if (acc == null ||
                    !acc.IsPersonAccount ||
                    String.isBlank(acc.PersonEmail)) {
                        continue;
                    }
                
                toAddress.add(acc.PersonEmail);
            }
            
            // Send Email to Leasing Order Owner
            else {
                
                if (String.isBlank(contract.Owner.Email)) {
                    continue;
                }
                
                toAddress.add(contract.Owner.Email);
            }
            
            Document__c doc = orderToDocMap.get(contract.Id);
            if (doc == null) {
                continue;
            }
            
            ContentVersion version = contentVersionMap.get(doc.Content_Version_Id__c);
            if (version == null) {
                continue;
            }
            
            Messaging.SingleEmailMessage objMail =
                objEmailService.getSingleEmailMessageWithoutTargetObjectId(
                    leaseTerminationEmailTemplateId,
                    noReplyBloomLeasingOWDId,
                    contract.Id,
                    toAddress,
                    null,
                    null
                );
            
            Messaging.EmailFileAttachment objFileAttachment =
                objEmailService.getEmailAttachment(
                    version.Title + '.' + version.FileExtension,
                    version.VersionData,
                    'application/pdf'
                );
            
            objMail.setFileAttachments(
                new Messaging.EmailFileAttachment[] { objFileAttachment }
            );
            
            emails.add(objMail);
        }
        
        if (!emails.isEmpty()) {
            objEmailService.sendEmail(emails);
        }
    }
    
    public void finish(Database.BatchableContext bc){
        
    }
    
    
    public void execute(SchedulableContext sc) {
        MetadataService mtdtService = MetadataService.getInstance();
        LeasingRenewalBatch batchJob = new LeasingRenewalBatch();
        Database.executeBatch(batchJob, mtdtService.getAppSettingNumberValue(BATCH_SIZE_METADATA) != Null ? mtdtService.getAppSettingNumberValue(BATCH_SIZE_METADATA) : 5); 
    }
}