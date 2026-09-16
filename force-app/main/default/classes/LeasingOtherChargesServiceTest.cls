@isTest
private class LeasingOtherChargesServiceTest {

    @testSetup
    static void setupData(){   
        Test.startTest();
        //Creating Unit__c
        Unit__c objUnit = new Unit__c();
        objUnit.Name = 'Test unit'; 
        insert objUnit;

        // Create a minimal LeasingOrder__c record
        LeasingOrder__c contract = new LeasingOrder__c(Name = 'Test Contract', Status__c = 'Leased', Unit__c = objUnit.Id);
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
    static void testGetOtherChargesByLeasingOrderIds(){
        LeasingOrder__c contract = [SELECT Id FROM LeasingOrder__c LIMIT 1];
        
        LeasingOtherChargesService service = LeasingOtherChargesService.getInstance();
        
        List<LeasingOrdersOtherCharges__c> result =
            service.getOtherChargesByLeasingOrderIds(new Set<Id>{contract.Id});
        
        System.assert(result.size() > 0, 'Should return related records');
    }
    
    @isTest
    static void testUpdateLeasingOtherCharges(){
        LeasingOrdersOtherCharges__c charge =
            [SELECT Id, Type__c FROM LeasingOrdersOtherCharges__c LIMIT 1];
        
        charge.Type__c = 'Legal Fee';
        
        LeasingOtherChargesService service = LeasingOtherChargesService.getInstance();
        
        Test.startTest();
        List<LeasingOrdersOtherCharges__c> updated =
            service.updateLeasingOtherCharges(new List<LeasingOrdersOtherCharges__c>{charge});
        Test.stopTest();
        
        System.assertEquals('Legal Fee', updated[0].Type__c);
    }
    
    @isTest
    static void testUpdateOtherCharge(){
        LeasingOrdersOtherCharges__c charge =
            [SELECT Id, Type__c FROM LeasingOrdersOtherCharges__c LIMIT 1];
        
        charge.Type__c = 'Utilities';
        
        LeasingOtherChargesService service = LeasingOtherChargesService.getInstance();
        
        Test.startTest();
        LeasingOrdersOtherCharges__c updated =
            service.updateOtherCharge(charge);
        Test.stopTest();
        
        System.assertEquals('Utilities', updated.Type__c);
    }
    
    @isTest
    static void testGetLeasingOtherChargesByIds(){
        LeasingOrdersOtherCharges__c charge =
            [SELECT Id FROM LeasingOrdersOtherCharges__c LIMIT 1];
        
        // Set required field so it passes ConditionType__c != null
        charge.ConditionType__c = 'R003';
        update charge;
        
        LeasingOtherChargesService service = LeasingOtherChargesService.getInstance();
        
        List<LeasingOrdersOtherCharges__c> result =
            service.getLeasingOtherChargesByIds(new Set<Id>{charge.Id});
        
        System.assertEquals(1, result.size());
    }
    @isTest
    static void testGetLeasingOtherChargeRecords(){
        LeasingOrdersOtherCharges__c charge =
            [SELECT Id, LeasingOrder__c FROM LeasingOrdersOtherCharges__c LIMIT 1];
        
        // Prepare required fields
        charge.ConditionType__c = 'R003';
        charge.IsReversed__c = false;
        charge.isVATApplied__c = true;
        charge.ReversalCategory__c = 'Reversal of Bounce cheque fees paid';
        charge.ChargeAmount__c = 500;
        update charge;
        
        charge = [
            SELECT Id,
            ChargeAmount__c,
            isVATApplied__c,
            DueDate__c,
            IsReversed__c,
            ReversedDate__c,
            ReversedReason__c,
            ReversedRemarks__c,
            ReversalCategory__c,
            Refdocno__c,
            Paymentdoc__c,IsPosting__c,
            CalculationFromDate__c,
            ConditionType__c,RelatedPartyBloomHolding__c,
            LeasingOrder__r.LeasingSAPContractId__c,
            LeasingOrder__r.LeasingStartDate__c,CalculationToDate__c,
            LeasingOrder__r.Project__r.Leasing_Company__r.LeasingSAPCompanyCode__c
            FROM LeasingOrdersOtherCharges__c
            WHERE Id = :charge.Id
        ];
        
        LeasingOtherChargesService service = LeasingOtherChargesService.getInstance();
        
        Test.startTest();
        IntegrationRecord__c rec =
            service.getLeasingOtherChargeRecords(charge);
        Test.stopTest();
        
        System.assertNotEquals(null, rec, 'Integration record should not be null');
    }
    @isTest
    static void testGetLeasingOtherChargeRecords_Reversed(){
        LeasingOrdersOtherCharges__c charge =
            [SELECT Id FROM LeasingOrdersOtherCharges__c LIMIT 1];
        
        charge.ConditionType__c = 'R003';
        charge.IsReversed__c = true;
        charge.isVATApplied__c = false;
        charge.ReversalCategory__c = 'Reversal of Bounce cheque fees paid';
        charge.ReversedDate__c = System.today();
        update charge;
        
        charge = [
            SELECT Id,
            ChargeAmount__c,
            isVATApplied__c,
            DueDate__c,
            IsReversed__c,
            ReversedDate__c,
            ReversedReason__c,
            TotalAmount__c,
            ReversedRemarks__c,
            ReversalCategory__c,
            Refdocno__c,
            Paymentdoc__c,IsPosting__c,
            CalculationFromDate__c,
            ConditionType__c,RelatedPartyBloomHolding__c,
            LeasingOrder__r.LeasingSAPContractId__c,
            LeasingOrder__r.LeasingStartDate__c,CalculationToDate__c,
            LeasingOrder__r.Project__r.Leasing_Company__r.LeasingSAPCompanyCode__c 
            FROM LeasingOrdersOtherCharges__c
            WHERE Id = :charge.Id
        ];
        
        LeasingOtherChargesService service = LeasingOtherChargesService.getInstance();
        
        Test.startTest();
        IntegrationRecord__c rec =
            service.getLeasingOtherChargeRecords(charge);
        Test.stopTest();
        
        System.assertNotEquals(null, rec);
    }
    
    @isTest
    static void testStaticMaps(){
        LeasingOtherChargesService service = LeasingOtherChargesService.getInstance();
        
        Map<String,String> map1 = service.getTypeToConditionTypeMap();
        Map<String,String> map2 = service.getTypeToSubCategoryMap();
        
        System.assert(map1.containsKey('Admin Fee'));
        System.assert(map2.containsKey('Security Deposit'));
    }

}