/***
Class       : customImageCarouselHandler
Author      : Smaartt
Description : 
TestClass   : customImageCarouselHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              27/04/23           Initial Version 
****************************************************************************************************************/
public class customImageCarouselHandler {
  
    
   @AuraEnabled(cacheable=true)
public static List<ContentVersion> getImages(Id recordId) {
    String sObjectName = recordId.getSObjectType().getDescribe().getName();
    Set<Id> documentIds = new Set<Id>();
    documentIds.add(recordId);

    List<Custom_Carousel_Config__mdt> carouselMetadata = [SELECT Id, Parent_Field_Api_Name__c FROM Custom_Carousel_Config__mdt WHERE MasterLabel = :sObjectName];
    if (carouselMetadata.size() > 0) {
        String queryStr = 'SELECT Id, ' + carouselMetadata[0].Parent_Field_Api_Name__c + ' FROM ' + sObjectName + ' WHERE Id = :recordId';
        SObject data = Database.query(queryStr);
        if (data != null && data.get(CarouselMetadata[0].Parent_Field_Api_Name__c) != null) {
            documentIds.add((Id)data.get(CarouselMetadata[0].Parent_Field_Api_Name__c));
        }
    }

    Set<Id> linkIds = new Set<Id>();
    List<ContentDocumentLink> contentDocIDList = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :documentIds];
    for (ContentDocumentLink cdl : contentDocIDList) {
        linkIds.add(cdl.ContentDocumentId);
    }

    return [SELECT Id, ContentDocumentId, ContentUrl, ContentBodyId, VersionNumber, Title, Description FROM ContentVersion WHERE ContentDocumentId IN :linkIds];
}

}