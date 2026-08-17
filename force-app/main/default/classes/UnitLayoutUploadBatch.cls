/*****************************************************************************************
Class       : UnitLayoutUploadBatch
Author      : Biswajeet
Description : Unit Layout Upload Batch
Test Class  : 
Created Date: 06 NOV 2024 
*****************************************************************************************/
public class UnitLayoutUploadBatch implements Database.Batchable<sObject>, Schedulable {
    
    private static final string MTD_UNIT_LAYOUT_LIBRARY_FOLDER_ID { get { return 'UnitLayoutLibraryFolderId'; } }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        MetadataService objMetadataService = MetadataService.getInstance();
       
        Id unitLayoutLibraryFolderId = objMetadataService.getAppSettingTextValue(MTD_UNIT_LAYOUT_LIBRARY_FOLDER_ID);
         
        String query = 'SELECT Title, ContentDocumentId, FileType, IsLatest, PathOnClient, FileExtension, VersionData FROM ContentVersion WHERE ContentDocument.ParentId = :UnitLayoutLibraryFolderId';
      
        return Database.getQueryLocator(query);
        
    }
    
    // Main logic of processing each batch
    public void execute(Database.BatchableContext bc, List<ContentVersion> cvList){
       
        UnitService objUnitService = UnitService.getInstance();
        ContentService objContentService = ContentService.getInstance();
        
        for(ContentVersion objCV :cvList){
            Savepoint sp = Database.setSavePoint();
            try{
                Unit__c objUnit = objUnitService.getUnitByName(objCV.Title);
                
                ContentVersion floorPlanContentVersion = objContentService.createContentVersion(objCV.VersionData, objCV.PathOnClient, objCV.Title);
                Id floorPlanContentDocumentId = objContentService.getContentDocumentId(floorPlanContentVersion.Id);
                objContentService.createContentDocumentLink(floorPlanContentDocumentId, objUnit.Id, 'I', 'AllUsers');
                    
                objUnit.WebFloorPlanCVId__c = floorPlanContentVersion.Id;
                ContentDistribution floorPlanContentDistribution = objContentService.createContentDistribution(floorPlanContentVersion.Id, objCV.Title + '-FloorPlan.' + objCV.FileExtension);
                objUnit.WebFloorPlan__c = objContentService.getContentPubicURL(floorPlanContentDistribution.Id);
                
                
                ContentVersion markettingPlanContentVersion = objContentService.createContentVersion(objCV.VersionData, objCV.PathOnClient, objCV.Title);
                Id markettingPlanContentDocumentId = objContentService.getContentDocumentId(markettingPlanContentVersion.Id);
                objContentService.createContentDocumentLink(markettingPlanContentDocumentId, objUnit.Id, 'I', 'AllUsers');
                
                objUnit.MarkettingPlanCVId__c = markettingPlanContentVersion.Id;
                ContentDistribution markettingPlanContentDistribution = objContentService.createContentDistribution(markettingPlanContentVersion.Id, objCV.Title + '-MarketingPlan.' + objCV.FileExtension);
                objUnit.MarketingPlan__c = objContentService.getContentPubicURL(markettingPlanContentDistribution.Id);
                
                
                ContentVersion affectionPlanContentVersion = objContentService.createContentVersion(objCV.VersionData, objCV.PathOnClient, objCV.Title);
                Id affectionPlanContentDocumentId = objContentService.getContentDocumentId(affectionPlanContentVersion.Id);
                objContentService.createContentDocumentLink(affectionPlanContentDocumentId, objUnit.Id, 'I', 'AllUsers');
                
                objUnit.AffectionPlanCVId__c = affectionPlanContentVersion.Id;
                ContentDistribution affectionPlanContentDistribution = objContentService.createContentDistribution(affectionPlanContentVersion.Id, objCV.Title + '-AffectionPlan.' + objCV.FileExtension);
                objUnit.AffectionPlan__c = objContentService.getContentPubicURL(affectionPlanContentDistribution.Id);
                
                objUnitService.updateUnitWithoutTrigger(objUnit);
                
                objContentService.deleteContentDocument(new ContentDocument(Id = objCV.ContentDocumentId));
                
            }catch(System.exception ex){
                Database.rollback(sp);
            }
        }
    }
    
    public void finish(Database.BatchableContext bc){
        
    }
    
    // Scheduling the batch
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new UnitLayoutUploadBatch(), 1);
    }
}