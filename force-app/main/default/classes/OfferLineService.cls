/***
Class       : OfferLineService
Author      : Biswajeet
Description : 
TestClass   : OfferLineServiceTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              25/08/23           Initial Version 
****************************************************************************************************************/

public class OfferLineService {
    
    private static OfferLineService instance;
    
    private OfferLineService() {
        
    }
    
    public static OfferLineService getInstance() { 
        if(instance == null) {
            instance = new OfferLineService();
        }
        return instance;
    }
    
    public List<OfferLines__c> getOfferLinesByOfferIds(Set<Id> offerIds){
        return [SELECT Id, Name, BudgetTaskName__c, OfferName__c, OfferValue__c FROM OfferLines__c WHERE OfferName__c IN :offerIds];
    }
      public List<OfferLines__c> getOfferLinesByProjectId(Id projectId){
        return [SELECT Id, Name, OfferType__c FROM OfferLines__c WHERE OfferName__r.Project__c = :projectId ORDER BY OfferType__c];
    }
}