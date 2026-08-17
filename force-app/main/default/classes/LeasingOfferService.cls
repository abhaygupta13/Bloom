/***
Class       : LeasingOfferService
Author      : 
Description : 
TestClass   : 
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
****************************************************************************************************************/
public inherited sharing class LeasingOfferService {
     private static LeasingOfferService instance;
    
    private LeasingOfferService() {
        
    }
    
    public static LeasingOfferService getInstance() { 
        if(instance == null) {
            instance = new LeasingOfferService();
        }
        return instance;
    }
    public LeasingOffer__c getLeasingDiscountOffers(Id leasingOfferId){
        return [SELECT LeasingOfferPromotion__c  FROM LeasingOffer__c WHERE Id = :leasingOfferId];
    }
     public List<LeasingOffer__c> getAllLeasingDiscountOffers(){
        return [SELECT Id , Name From LeasingOffer__c];
    }
    
   
}