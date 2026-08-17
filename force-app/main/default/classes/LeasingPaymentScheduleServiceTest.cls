@isTest
private class LeasingPaymentScheduleServiceTest {

    @testSetup
    static void setupData() { 
    
       Unit__c uc =  new Unit__c(Name = 'Unit1');
       insert uc;
        
        // Create a dummy LeasingOrder__c (contract)
        LeasingOrder__c contract = new LeasingOrder__c(
            Name = 'Test Contract',
            unit__c = uc.id
        );
        insert contract;

        // Create sample PaymentPlanSchedule__c records
        List<PaymentPlanSchedule__c> schedules = new List<PaymentPlanSchedule__c>();
        for(Integer i = 0; i < 3; i++){
            schedules.add(new PaymentPlanSchedule__c(
                Name = 'Schedule ' + i,
                LeasingOrder__c = contract.Id
            ));
        }
        insert schedules;
    }

    @isTest
    static void testMethods() {
        // Get the singleton instance
        LeasingPaymentScheduleService service = LeasingPaymentScheduleService.getInstance();
        System.assertNotEquals(null, service, 'Singleton instance should not be null');

        // Fetch setup data
        LeasingOrder__c contract = [SELECT Id FROM LeasingOrder__c LIMIT 1];
        List<PaymentPlanSchedule__c> existingSchedules = [SELECT Id FROM PaymentPlanSchedule__c WHERE LeasingOrder__c = :contract.Id];
        System.assertEquals(3, existingSchedules.size(), '3 schedules should be inserted during @testSetup');

        // Test getPaymentSchedulesForAmend
        List<PaymentPlanSchedule__c> fetchedSchedules = service.getPaymentSchedulesByLeasingOrderId(contract.Id);
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
        
        // getPaymentSchedulesByLeasingOrders
        List<PaymentPlanSchedule__c> schedules =
            service.getPaymentSchedulesByLeasingOrders(new Set<Id>{contract.Id});
        System.assertNotEquals(null, schedules);
        
        // updatePaymentPlanSchedules
        if (!schedules.isEmpty()) {
            schedules[0].Name = 'Updated';
            service.updatePaymentPlanSchedules(schedules);
        }
        
        // updatePaymentPlanSchedule
        PaymentPlanSchedule__c schedule = [SELECT Id, Name FROM PaymentPlanSchedule__c LIMIT 1];
        schedule.Name = 'Updated Again';
        service.updatePaymentPlanSchedule(schedule);
        
        System.assertEquals(
            'Updated Again',
            [SELECT Name FROM PaymentPlanSchedule__c WHERE Id = :schedule.Id].Name
        );
        
        List<PaymentPlanSchedule__c> paymentPlan = [SELECT
            Id,
            Name,
            Amount__c,
            PaymentStartDate__c,
            DueDate__c,
            Schedule_End_Date__c,
            isVATApplied__c,
            IsReversed__c,
            ReversalCategory__c,
            ReversedDate__c,
            ReversedReason__c,
            ReversedRemarks__c,
            Refdocno__c,
            Paymentdoc__c,
            RelatedPartyBloomHolding__c,
            LeasingContractTypeCode__c,
            LeasingOrder__c,
            LeasingOrder__r.LeasingSAPContractId__c,
            LeasingOrder__r.Unit__r.PropertyUsage__c,
            LeasingOrder__r.Project__r.Leasing_Company__r.LeasingSAPCompanyCode__c,
            LeasingOrder__r.Project__r.Leasing_Company__r.LeasingSAPResContractTypeCode__c,
            LeasingOrder__r.Project__r.Leasing_Company__r.LeasingSAPRentfreeConditionType__c
        FROM PaymentPlanSchedule__c
        LIMIT 1];
        
        IntegrationRecord__c intRecord = service.getLeasingPaymentScheRecords(paymentPlan[0]);
        System.assertEquals(true, intRecord != null, 'Method should return integration record');
    }
}