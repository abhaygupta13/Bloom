public inherited sharing class ContentDocumentLinkService {
    
    private ContentDocumentLinkService() {}
    
    public static ContentDocumentLinkService getInstance() {
        return new ContentDocumentLinkService();
    }
    
    //insert ContentDocumentLink with trigger
    public List<ContentDocumentLink> insertContentDocumentLinkWithTrigger(List<ContentDocumentLink> contentDocumentLinkList){
        if(contentDocumentLinkList != NULL && !contentDocumentLinkList.isEmpty()){
            insert contentDocumentLinkList;
        }
        return contentDocumentLinkList;
    }
    
    public List<ContentDocumentLink> getBrokerFileLinksByBrokerAppIds(Set<Id> brokerAppIds) {
        return [SELECT ContentDocumentId, LinkedEntityId, ShareType, Visibility FROM ContentDocumentLink WHERE LinkedEntityId IN :brokerAppIds];
    }
    
    public List<ContentDocumentLink> getExistingAccountLinks(Set<Id> accountIds) {
        if (accountIds != null && !accountIds.isEmpty()) {
            return [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :accountIds];
        }
        return new List<ContentDocumentLink>();
    }
    
    //get ContentDocumentLink by serviceAppointmentIds
    public List<ContentDocumentLink> getcontentDocumentLinksByIds(Set<Id> contentDocumentLinkIds){
        if(!contentDocumentLinkIds.isEmpty() && contentDocumentLinkIds.size() > 0){
            return [SELECT Id, ContentDocumentId, LinkedEntityId, ShareType FROM ContentDocumentLink WHERE LinkedEntityId IN :contentDocumentLinkIds];            
        } 
        return null;
    }
    
    //delete ContentDocumentLinks
    public List<ContentDocumentLink> deleteContentDocumentLinks(List<ContentDocumentLink> contentDocumentLinkList){
        if(contentDocumentLinkList != NULL && !contentDocumentLinkList.isEmpty()){
            delete contentDocumentLinkList;
        }
        return contentDocumentLinkList;
    }
    
    public List<ContentDocument> getContentDocumentsByIds(Set<Id> contentDocIds) {
        if (contentDocIds != null && !contentDocIds.isEmpty()) {
            return [
                SELECT Id, LatestPublishedVersionId
                FROM ContentDocument
                WHERE Id IN :contentDocIds
            ];
        }
        return new List<ContentDocument>();
    }
	// Docusing BAPP
    public static ContentDocumentLink getLatestContentDocumentLinkByRecordAndTitle(Id recordId, String documentTitlePattern) {
        List<ContentDocumentLink> cdlList = [
            SELECT Id, ContentDocument.Title, ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId
            AND ContentDocument.Title LIKE :documentTitlePattern
            ORDER BY SystemModstamp DESC
            LIMIT 1
        ];
        
        return cdlList.isEmpty() ? null : cdlList[0];
    }
    

    public static ContentDocumentLink getLatestContentDocumentLinkByRecordAndName(Id recordId, String documentTitlePattern) {
        List<Document__c> docList = [SELECT Id, Document_Name__c FROM Document__c WHERE Id = :recordId AND Document_Name__c = 'Generated Invoice' LIMIT 1];
        
        if (docList.isEmpty()) {
            return null; // No matching Document__c record
        }
        
        Document__c objDocument = docList[0];
        List<ContentDocumentLink> cdlList = [ SELECT Id, ContentDocument.Title, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :objDocument.Id ORDER BY SystemModstamp DESC LIMIT 1];
        return cdlList.isEmpty() ? null : cdlList[0];
    }

}