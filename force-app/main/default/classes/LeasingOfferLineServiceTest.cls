@isTest
public class LeasingOfferLineServiceTest {

    @isTest
    static void testGetLeasingDiscountOfferLines() {
        // Test data setup
        //String testPromoId = 'TEST_PROMO'; 

        Test.startTest();

        //Creating LeasingOfferPromotion__c
        LeasingOfferPromotion__c objLeasingOfferPromo = new LeasingOfferPromotion__c();
        objLeasingOfferPromo.Name = 'Test Offer Promo';
        insert objLeasingOfferPromo;
        
        LeasingOfferLines__c line1 = new LeasingOfferLines__c(
            OfferName__c     = objLeasingOfferPromo.Id,
            OfferValueType__c= '%',
            OfferType__c     = 'Additional Discount',
            OfferValue__c    = 10
        );
        LeasingOfferLines__c line2 = new LeasingOfferLines__c(
            OfferName__c     = objLeasingOfferPromo.Id,
            OfferValueType__c= '%',
            OfferType__c     = 'Additional Discount',
            OfferValue__c    = 15
        );
        insert new List<LeasingOfferLines__c>{ line1, line2 };
        
        // Call the class
        LeasingOfferLineService service = LeasingOfferLineService.getInstance();
        List<LeasingOfferLines__c> results = service.getLeasingAdditionalDiscountOfferLines(objLeasingOfferPromo.Id);

        // Assertions
        System.assertEquals(2, results.size(), 'Two offer lines should be returned');
        for(LeasingOfferLines__c rec : results){
            System.assertNotEquals(null, rec.OfferValue__c, 'OfferValue__c should not be null');
        }

        Test.stopTest();
    }
}