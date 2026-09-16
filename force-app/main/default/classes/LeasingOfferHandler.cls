/***
Class       : LeasingOfferHandler
Author      : 1.this is using in generate approved Leasing offer , 
2.Cloning the Opportunity documents to LeasingOrder , 
3.Using in Send offer to customer and attaching the offer to related email message LWC component  
Description : 
TestClass   : 
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
****************************************************************************************************************/
public class LeasingOfferHandler implements Queueable,Database.AllowsCallouts {
    
    private static final string LEASING_STATUS_QUALIIED { get { return 'Leasing Offer'; } } 
    private static final string LEASING_SUB_STATUS_OFFER_GENERATED { get { return 'Offer Generated';}} 
    private static final Set<String> INPROGRESS_LEASING_STATUSES = new Set<String>{ 'Leasing Offer', 'Pending','Approve Pending'};
        private static final string ORGANIZATION_TYPE { get { return 'Organization'; } } 
    private static final string INDIVIDUAL_TYPE { get { return 'Individual'; } } 
    private static final string COMMON_DOCS { get { return 'Common'; } } 
    private static final string COMMERCIAL_TYPE { get { return 'Commercial'; } } 
    private static final string RESIDENTIAL_TYPE { get { return 'Residential'; } } 
    private static final string LEASING_STATUS_LEASED { get { return 'Leased'; } } 
    private static final string LEASING_STATUS_OCCUPIED { get { return 'Occupied'; } } 
    private static final string LEASING_STATUS_CANCELLED { get { return 'Cancelled'; } } 
    private static final string LEASING_STATUS_AVAILABLE { get { return 'Available'; } } 
    private static final string LEASING_STATUS_BOOKED { get { return 'Booked'; } } 
    private static final string APPROVAL_STATUS_APPROVED { get { return 'Approved'; } } 
    private static final string ORGANIZATION_ACCOUNT { get { return 'OrganizationAccount'; } } 
    private static final string PERSON_ACCOUNT { get { return 'PersonAccount'; } } 
    private static final string LEASING_ORDER { get { return 'LeasingOrder__c'; } } 
    private static final string OFFER_LETTER { get { return 'Offer Letter'; } }  
    private static final string HYPHEN { get { return ' - '; } }
    private static final string PDF_FORMAT { get { return 'pdf'; } } 
    private static final string PERIOD { get { return '.'; } } 
    private static final string BLOOM_NO_REPLY_LEASING_OW_EMAIL_ID { get { return 'BloomNoReplyLeasingOWEmailId'; } }
    
    private static final string LEASING_OFFER_FOR_CUSROMER_SIGN { get { return 'LeasingOfferSignTemplateId'; } }
    
    
    private Set<Id> contractIds;
    
    public LeasingOfferHandler(Set<Id> contractIds) {
        this.contractIds = contractIds;
    }
    
    public void execute(QueueableContext context) {
        generateApprovedLeasingOffer(contractIds);
    }
    
    public static void generateApprovedLeasingOffer(Set<Id> contractIds)
    {
        LeasingOrderService leasingService = LeasingOrderService.getInstance();
        
        Map<Id, LeasingOrder__c> contractMap = new Map<Id, LeasingOrder__c>(leasingService.getLeasingOrdersByIds(contractIds));
        Map<Id, Document__c> docMap = new Map<Id, Document__c>();
        DocumentService docService = DocumentService.getInstance();
        List<Document__c> leasingOfferDocs = docService.getLeasingOfferDocumentsByContractIds(contractIds);
        for (Document__c doc : leasingOfferDocs) 
        {
            docMap.put(doc.LeasingOrder__c, doc);
        }
        List<ContentVersion> filesToInsert = new List<ContentVersion>();
        
        for (Id contractId : contractIds) {
            LeasingOrder__c contract = contractMap.get(contractId);
            Document__c doc = docMap.get(contractId);
            PageReference pdfPage ;
            // if(contract.Unit__r.PropertyUsage__c == COMMERCIAL_TYPE && contract.Account__r.Recordtype.DeveloperName == ORGANIZATION_ACCOUNT ){
            if(contract.Unit__r.PropertyUsage__c == COMMERCIAL_TYPE){
              
                pdfPage = Page.LeasingCommercialOffer;
            // }else if(contract.Unit__r.PropertyUsage__c == RESIDENTIAL_TYPE && contract.Account__r.Recordtype.DeveloperName == PERSON_ACCOUNT){
            }else if(contract.Unit__r.PropertyUsage__c == RESIDENTIAL_TYPE){
                pdfPage = Page.LeasingResidentialOffer;
            }else {
                return ;
            }
            pdfPage.getParameters().put('id', contractId);
            Blob pdfBlob;
            if(!Test.isRunningTest()){
                pdfBlob = pdfPage.getContent();
            }
            else{
                pdfBlob = blob.valueof('test');
            }
            ContentVersion file = new ContentVersion();
            file.Title = contract.Opportunity__r.Account.Name + HYPHEN+OFFER_LETTER;
            file.PathOnClient = contract.Opportunity__r.Account.Name + '_OfferLetter.pdf';
            file.VersionData = pdfBlob;
            if(!test.isRunningTest()){file.FirstPublishLocationId = doc.Id;}
            filesToInsert.add(file);
        }
        
        ContentService conService = ContentService.getInstance();
        conService.createContentVersion(filesToInsert);
    }
    
    //Helper method to clone the documents From Opportunity Including the content version to associate to Leasing Order Id
    public static void cloneDocumentsWithFiles(Id sourceOppId, Id targetLeasingOrderId) {
        // Fetch documents at Opportunity level (source)
        Map<Id, Document__c> sourceDocRecordsMap = new Map<Id, Document__c>(DocumentService.getInstance().getDocumentsByOpportunityId(sourceOppId));
        // Fetch target document placeholders under Leasing Contract
        List<Document__c> targetDocs = DocumentService.getInstance().getDocumentsByLeasingOrderId(targetLeasingOrderId);
        // Create a map from Document_Name__c to target Document__c
        Map<String, Id> docNameToTargetDocId = new Map<String, Id>();
        for (Document__c doc : targetDocs) {
            docNameToTargetDocId.put(doc.Document_Name__c, doc.Id);
        }
        // Fetch ContentDocumentLinks for source documents
        List<ContentDocumentLink> sourceDocLinks = ContentService.getContentDocumentLink(sourceDocRecordsMap.keySet());
        
        Set<Id> contentDocIds = new Set<Id>();
        for (ContentDocumentLink link : sourceDocLinks) {
            contentDocIds.add(link.ContentDocumentId);
        }
        // Get latest ContentVersion records
        Map<Id, ContentVersion> latestVersions = new Map<Id, ContentVersion>();
        List<ContentVersion> versions = ContentService.getInstance().getContentVersionsByCDIds(contentDocIds);
        for (ContentVersion ver : versions) {
            latestVersions.put(ver.ContentDocumentId, ver);
        }
        // Map source Document Id → Document_Name__c
        Map<Id, String> sourceDocIdToName = new Map<Id, String>();
        for (Document__c doc : sourceDocRecordsMap.values()) {
            sourceDocIdToName.put(doc.Id, doc.Document_Name__c);
        }
        // Prepare list of cloned ContentVersions to attach to target documents
        List<ContentVersion> newVersions = new List<ContentVersion>();
        for (ContentDocumentLink link : sourceDocLinks) {
            String docName = sourceDocIdToName.get(link.LinkedEntityId);
            if (docName != null && docNameToTargetDocId.containsKey(docName)) {
                Id targetDocId = docNameToTargetDocId.get(docName);
                ContentVersion oldVersion = latestVersions.get(link.ContentDocumentId);
                if (oldVersion != null && targetDocId != null) {
                    ContentVersion clonedVersion = new ContentVersion();
                    clonedVersion.Title = oldVersion.Title;
                    clonedVersion.PathOnClient = oldVersion.PathOnClient;
                    clonedVersion.VersionData = oldVersion.VersionData;
                    clonedVersion.Description = oldVersion.Description;
                    clonedVersion.Origin = 'H'; // chatter file
                    clonedVersion.FirstPublishLocationId = targetDocId; // map to target placeholder
                    newVersions.add(clonedVersion);
                }
            }
        }
        ContentService conService = ContentService.getInstance();
        conService.createContentVersion(newVersions);
    }
}