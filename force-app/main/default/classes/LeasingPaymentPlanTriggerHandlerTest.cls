@isTest
private class LeasingPaymentPlanTriggerHandlerTest {
    
    @testSetup
    static void setupData() { 
        
        Unit__c uc =  new Unit__c(Name = 'Unit1');
        insert uc;
        
        // Create a dummy LeasingOrder__c (contract)
        LeasingOrder__c contract = new LeasingOrder__c(
            Name = 'Test Contract',
            IntegrationMessage__c = 'Data Migration',
            unit__c = uc.id
        );
        insert contract;
        
        // Create sample PaymentPlanSchedule__c records
        List<PaymentPlanSchedule__c> schedules = new List<PaymentPlanSchedule__c>();
        for(Integer i = 0; i < 3; i++){
            schedules.add(new PaymentPlanSchedule__c(
                Name = 'Schedule ' + i,
                LeasingOrder__c = contract.Id,
                 PaymentStartDate__c = Date.today()
            ));
        }
        insert schedules;
    }
    
    @isTest
    static void testMethods() {
        // Get the singleton instance
        LeasingPaymentScheduleService  service = LeasingPaymentScheduleService.getInstance();
        System.assertNotEquals(null, service, 'Singleton instance should not be null');
        
        // Fetch setup data
        LeasingOrder__c contract = [SELECT Id FROM LeasingOrder__c LIMIT 1];
        List<PaymentPlanSchedule__c> existingSchedules = [SELECT Id FROM PaymentPlanSchedule__c WHERE LeasingOrder__c = :contract.Id];
        System.assertEquals(3, existingSchedules.size(), '3 schedules should be inserted during @testSetup');
        Set<Id> contractIds = new Set<Id>();
        contractIds.add(contract.Id);
        
        // Test getPaymentSchedulesForAmend
        List<PaymentPlanSchedule__c> fetchedSchedules = service.getPaymentSchedulesByLeasingOrders(contractIds);
        system.debug(fetchedSchedules);
        System.assertEquals(3, fetchedSchedules.size(), 'Should retrieve all 3 schedules for the contract');
        
        // Test insertPaymentSchedulesWithoutTrigger
        PaymentPlanSchedule__c newSchedule = new PaymentPlanSchedule__c(
            Name = 'New Schedule',
            LeasingOrder__c = contract.Id
        );
        List<PaymentPlanSchedule__c> toInsert = new List<PaymentPlanSchedule__c>{ newSchedule };
            
            Test.startTest();
        List<PaymentPlanSchedule__c> insertedList = service.insertPaymentSchedules(toInsert);
        //Test.stopTest();
        
        System.assertEquals(1, insertedList.size(), 'Insert method should return the inserted list');
        
        service.getLeasingPaymentScheRecords(insertedList [0]);  
        service.getpaymentPlanByIds(new Set<id>{insertedList [0].Id});
        service.updatePaymentPlanSchedules(insertedList);
        
        // Validate that the record is actually inserted in DB
        List<PaymentPlanSchedule__c> afterInsert = [
            SELECT Id FROM PaymentPlanSchedule__c WHERE Id = :insertedList[0].Id
        ];
        System.assertEquals(1, afterInsert.size(), 'Schedule should be actually inserted');
        
        // Test deletePaymentSchedulesWithoutTrigger
        //Test.startTest();
        service.deletePaymentSchedules(insertedList);
        Test.stopTest();
        
        // Validate that it was deleted
        List<PaymentPlanSchedule__c> afterDelete = [
            SELECT Id FROM PaymentPlanSchedule__c WHERE Id = :insertedList[0].Id
        ];
        System.assertEquals(0, afterDelete.size(), 'Inserted schedule should be deleted');
    }
    
    @isTest
    static void testLeasingPaymentPlanBatch() {
        
        LeasingOrder__c contract = [SELECT Id FROM LeasingOrder__c LIMIT 1];
        List<PaymentPlanSchedule__c> todaysPaymentPlan = new List<PaymentPlanSchedule__c>{
            new PaymentPlanSchedule__c(
                LeasingOrder__c = contract.Id,
                PaymentStartDate__c  = Date.today(),
                PaymentStatus__c = 'Not Invoiced',
                isVATApplied__c = true,   
                SendToSAP__c = false           
            )
                };
                    insert todaysPaymentPlan;
        
        Test.startTest();
        LeasingPaymentScheduleBatch batch = new LeasingPaymentScheduleBatch();
        Database.executeBatch(batch, 20);
        Test.stopTest();
        
        PaymentPlanSchedule__c updated = [
            SELECT SendToSAP__c 
            FROM PaymentPlanSchedule__c 
            WHERE Id = :todaysPaymentPlan[0].Id
        ];
        
        System.assertEquals(true, updated.SendToSAP__c,
                            'Batch should update SendToSAP__c = TRUE for today records');
    }
}