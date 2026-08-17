/***
Class       : LeasingOfferLineService
Author      : 
Description : 
TestClass   : 
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
****************************************************************************************************************/
public inherited sharing class LeasingOfferLineService {
    private static LeasingOfferLineService instance;
    
    private LeasingOfferLineService() {
        
    }
    
    public static LeasingOfferLineService getInstance() { 
        if(instance == null) {
            instance = new LeasingOfferLineService();
        }
        return instance;
    }
    public List<LeasingOfferLines__c> getLeasingAdditionalDiscountOfferLines(Id promoId){
        return [SELECT OfferValue__c FROM LeasingOfferLines__c WHERE OfferName__c = :promoId
                AND OfferValueType__c = '%' AND OfferType__c = 'Additional Discount'];
    }
}