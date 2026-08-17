@isTest
private class LeasingOtherChargesTriggerHandlerTest {
    
    @testSetup
    static void setupData(){   
        Test.startTest();
        //Creating Unit__c
        Unit__c objUnit = new Unit__c();
        objUnit.Name = 'Test unit'; 
        insert objUnit;
        
        // Create a minimal LeasingOrder__c record
        LeasingOrder__c contract = new LeasingOrder__c(Name = 'Test Contract', Status__c = 'Leased', Unit__c = objUnit.Id, 
                                                       
                                                       IntegrationMessage__c = 'Data Migration', LeasingStartDate__c = Date.today());
        insert contract;
        
        // Create some existing Other Charges
        List<LeasingOrdersOtherCharges__c> chargesList = new List<LeasingOrdersOtherCharges__c>();
        for(Integer i=1; i<=2; i++){
            chargesList.add(new LeasingOrdersOtherCharges__c(
                LeasingOrder__c = contract.Id,
                Type__c = 'Admin Fee',
                ChargeAmount__c = 100 * i,
                VATAmount__c = 5 * i,
                isVATApplied__c = true
                
            ));
        }
        insert chargesList;
        Test.stopTest();
    }
    
    @isTest
    static void testSingleton(){
        LeasingOtherChargesService s1 = LeasingOtherChargesService.getInstance();
        LeasingOtherChargesService s2 = LeasingOtherChargesService.getInstance();
        System.assertNotEquals(null, s1);
        System.assertEquals(s1, s2, 'Singleton should return same instance');
    }
    
    @isTest
    static void testGetOtherChargesForAmend(){
        LeasingOrder__c contract = [SELECT Id FROM LeasingOrder__c LIMIT 1];        
        LeasingOtherChargesService service = LeasingOtherChargesService.getInstance();        
        List<LeasingOrdersOtherCharges__c> res = service.getOtherChargesByLeasingOrderId(contract.Id);        
        System.assertEquals(2, res.size(), 'Should return 2 existing charges');
    }
    
    @isTest
    static void testGetOtherChargesForOfferGen(){
        LeasingOrder__c contract = [SELECT Id FROM LeasingOrder__c LIMIT 1];
        LeasingOtherChargesService service = LeasingOtherChargesService.getInstance();
        List<LeasingOrdersOtherCharges__c> res = service.getOtherChargesByLeasingOrderId(contract.Id);
        System.assertEquals(2, res.size());
        System.assertNotEquals(null, res[0].Type__c, 'Type__c should be populated');
    }
    
    @isTest
    static void testInsertOtherChargesWithoutTrigger(){
        LeasingOrder__c contract = [SELECT Id FROM LeasingOrder__c LIMIT 1];
        
        List<LeasingOrdersOtherCharges__c> newCharges = new List<LeasingOrdersOtherCharges__c>{
            new LeasingOrdersOtherCharges__c(
                LeasingOrder__c = contract.Id,
                Type__c = 'Admin Fee',
                ChargeAmount__c = 300,
                VATAmount__c = 15,
                isVATApplied__c = true
            )
                };
                    
                    LeasingOtherChargesService service = LeasingOtherChargesService.getInstance();
        Test.startTest();
        List<LeasingOrdersOtherCharges__c> inserted = service.insertOtherCharges(newCharges);
        Test.stopTest();
        
        System.assertEquals(1, inserted.size());
        System.assert(inserted[0].Id != null, 'Record should be inserted and have Id');
    }
    
    @isTest
    static void testDeleteOtherChargesWithoutTrigger(){
        List<LeasingOrdersOtherCharges__c> toDelete = [SELECT Id FROM LeasingOrdersOtherCharges__c LIMIT 1];
        LeasingOtherChargesService service = LeasingOtherChargesService.getInstance();
        
        Test.startTest();
        service.deleteOtherCharges(toDelete);
        Test.stopTest();
        
        List<LeasingOrdersOtherCharges__c> check = [
            SELECT Id FROM LeasingOrdersOtherCharges__c WHERE Id IN :toDelete
        ];
        System.assertEquals(0, check.size(), 'Record should be deleted');
    }
    
    @isTest
    static void testLeasingOtherChargesBatch() {
        
        LeasingOrder__c contract = [SELECT Id FROM LeasingOrder__c LIMIT 1];
        List<LeasingOrdersOtherCharges__c> todaysCharges = new List<LeasingOrdersOtherCharges__c>{
            new LeasingOrdersOtherCharges__c(
                LeasingOrder__c = contract.Id,
                Type__c = 'Admin Fee',
                ChargeAmount__c = 200,
                PaymentStatus__c = 'Not Invoiced',
                VATAmount__c = 10,
                isVATApplied__c = true,   
                SendToSAP__c = false           
            )
                };
                    insert todaysCharges;
        
        Test.startTest();
        LeasingOtherChargesBatch batch = new LeasingOtherChargesBatch();
        Database.executeBatch(batch, 20);
        Test.stopTest();
        
        LeasingOrdersOtherCharges__c updated = [
            SELECT SendToSAP__c 
            FROM LeasingOrdersOtherCharges__c 
            WHERE Id = :todaysCharges[0].Id
        ];
        
        System.assertEquals(true, updated.SendToSAP__c,
                            'Batch should update SendToSAP__c = TRUE for today records');
    }
    
    @isTest
    static void TestOtherChargeValidation(){
        List<LeasingOrder__c> LOlist= [SELECT Id From LeasingOrder__c];
		 LeasingOrdersOtherCharges__c charges = new LeasingOrdersOtherCharges__c(
                LeasingOrder__c = LOlist[0].Id,
                Type__c = 'CheckoutDamage Recovery Charge',
                ChargeAmount__c = 100,
                VATAmount__c = 5,
                isVATApplied__c = true
                
            );
        try{
              insert charges;
        }
        catch(Exception e){
            return;
        }
    }
    
}