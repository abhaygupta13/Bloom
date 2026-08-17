@isTest
public class LeasingOfferServiceTest {
    
    @testSetup
    static void setupData(){

        Test.startTest(); 
      

        //Creating LeasingOfferPromotion__c
        LeasingOfferPromotion__c objLeasingOfferPromo = new LeasingOfferPromotion__c();
        objLeasingOfferPromo.Name = 'Test Offer Promo';
        insert objLeasingOfferPromo;

      

        // Create some test LeasingOffer__c records
        List<LeasingOffer__c> offers = new List<LeasingOffer__c>();
        for(Integer i = 0; i < 3; i++){
            offers.add(new LeasingOffer__c(
                Name = 'Test Offer ' + i,
             
                LeasingOfferPromotion__c = objLeasingOfferPromo.Id
            ));
        }
        insert offers;
        Test.stopTest();
    }
    
    @isTest
    static void testGetLeasingDiscountOffers(){
        // Fetch one of the inserted test records
        LeasingOffer__c offer = [SELECT Id FROM LeasingOffer__c LIMIT 1];
        
        Test.startTest();
        LeasingOfferService service = LeasingOfferService.getInstance();
        LeasingOffer__c result = service.getLeasingDiscountOffers(offer.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(offer.Id, result.Id, 'Returned record Id should match');
    }
    
    @isTest
    static void testGetAllLeasingDiscountOffers(){
        Test.startTest();
        LeasingOfferService service = LeasingOfferService.getInstance();
        List<LeasingOffer__c> resultList = service.getAllLeasingDiscountOffers();
        Test.stopTest();
        
        System.assert(resultList.size() > 0, 'There should be at least one LeasingOffer__c returned');
    }
}