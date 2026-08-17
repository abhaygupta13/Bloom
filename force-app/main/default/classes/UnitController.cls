/*****************************************************************************************
Class       : UnitController
Author      : Biswajeet
Description : Unit controller class
Created Date: 29 AUG 2024
Test Class  : UnitControllerTest
------------------------------------------------------------------------------------------
-- History --
------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0             29AUG2024           Initial Version 
*****************************************************************************************/
public class UnitController {
    
    @AuraEnabled
    public static void uploadUnitLayouts(Id recordId, Id floorPlanDocId, Id marketingPlanDocId, Id affectionPlanDocId){
        UnitService objUnitService = UnitService.getInstance();
        ContentService objContentService = ContentService.getInstance();
        
        Savepoint sp = Database.setSavePoint();
        try{
            Set<Id> contentDocumentIds = new Set<Id>{floorPlanDocId, marketingPlanDocId, affectionPlanDocId};
                if(!contentDocumentIds.isEmpty()){
                    Unit__c objUnit = objUnitService.getUnitsById(recordId);
                    List<ContentVersion> cvList = objContentService.getContentVersionsByCDIds(contentDocumentIds);
                    
                    for(ContentVersion cv :cvList){
                        if(cv.ContentDocumentId == floorPlanDocId){
                            objUnit.WebFloorPlanCVId__c = cv.Id;
                             objUnit.WebFloorPlanCDId__c = cv.ContentDocumentId;
                            ContentDistribution cd = objContentService.createContentDistribution(cv.Id, objUnit.Name + '-FloorPlan.' + cv.FileExtension);
                            objUnit.WebFloorPlan__c = objContentService.getContentPubicURL(cd.Id);
                        }else if(cv.ContentDocumentId == marketingPlanDocId){
                            objUnit.MarkettingPlanCVId__c = cv.Id;
                            ContentDistribution cd = objContentService.createContentDistribution(cv.Id, objUnit.Name + '-MarketingPlan.' + cv.FileExtension);
                            objUnit.MarketingPlan__c = objContentService.getContentPubicURL(cd.Id);
                        }else if(cv.ContentDocumentId == affectionPlanDocId){
                            objUnit.AffectionPlanCVId__c = cv.Id;
                            ContentDistribution cd = objContentService.createContentDistribution(cv.Id, objUnit.Name + '-AffectionPlan.' + cv.FileExtension);
                            objUnit.AffectionPlan__c = objContentService.getContentPubicURL(cd.Id);
                        }
                    }
                    objUnitService.updateUnitWithoutTrigger(objUnit);
                }
        }catch(System.exception ex){
            Database.rollback(sp);
            throw new AuraHandledException(ex.getMessage());   
        }
    }
}