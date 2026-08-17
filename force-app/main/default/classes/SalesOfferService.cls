/*****************************************************************************************
Class       : SalesOfferService
Author      : Biswajeet
Description : Lead service class
test Class  : SalesOfferServiceTest
Created Date: 29 AUG 2024
*****************************************************************************************/
public class SalesOfferService {
    
    private static SalesOfferService instance;
    
    private SalesOfferService() {
        
    }
    
    public static SalesOfferService getInstance() { 
        if(instance == null) {
            instance = new SalesOfferService();
        }
        return instance;
    }
    
    public SalesOffer__c getSalesOfferById(Id recordId){
        return [SELECT Id, Name, CustomerFirstName__c, CustomerLastName__c, CustomerEmail__c
                FROM SalesOffer__c WHERE Id = :recordId];
    }
    
    public SalesOffer__c insertSalesOffer(SalesOffer__c objSalesOffer){
        if(objSalesOffer != NULL ){
            objSalesOffer = insertSalesOffers(new List<SalesOffer__c>{objSalesOffer})[0];
        }
        return objSalesOffer;
    }
    
    public List<SalesOffer__c> insertSalesOffers(List<SalesOffer__c> salesOfferList){
        if(salesOfferList != NULL && !salesOfferList.isEmpty()){
            insert salesOfferList;
        }
        return salesOfferList;
    }
}