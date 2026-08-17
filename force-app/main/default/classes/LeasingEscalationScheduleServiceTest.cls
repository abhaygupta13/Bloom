@isTest
private class LeasingEscalationScheduleServiceTest {

    @testSetup
    static void setupTestData() {

        Test.startTest();
        //Creating Unit__c
        Unit__c objUnit = new Unit__c();
        objUnit.Name = 'Test unit';
        insert objUnit;

        // Create a test LeasingOrder__c record
        LeasingOrder__c leasingOrder = new LeasingOrder__c(Name = 'Test Contract',  Status__c = 'Leased', Unit__c = objUnit.Id);
        insert leasingOrder;

        // Create test LeasingEscalationSchedule__c records
        List<LeasingEscalationSchedule__c> schedules = new List<LeasingEscalationSchedule__c>();
        for (Integer i = 1; i <= 3; i++) {
            schedules.add(new LeasingEscalationSchedule__c(
                LeasingOrder__c = leasingOrder.Id,
                Year__c = i,
                AnnualRent__c = 10000 * i,
                Escalation__c = 5 * i,
                TotalRent__c = 10500 * i,
                AfterDiscount__c = 9500 * i
            ));
        }
        insert schedules;
        Test.stopTest();
    }

    @isTest
    static void testGetInstance() {
        LeasingEscalationScheduleService service1 = LeasingEscalationScheduleService.getInstance();
        LeasingEscalationScheduleService service2 = LeasingEscalationScheduleService.getInstance();
        System.assertNotEquals(null, service1, 'Service instance should not be null');
        System.assertEquals(service1, service2, 'Singleton instance should return same object');
    }

    @isTest
    static void testGetEscalationSchedulesForAmend() {
        LeasingOrder__c contract = [SELECT Id FROM LeasingOrder__c LIMIT 1];
        LeasingEscalationScheduleService service = LeasingEscalationScheduleService.getInstance();
        List<LeasingEscalationSchedule__c> result = service.getEscalationSchedulesByContractId(contract.Id);
        System.assertEquals(3, result.size(), 'Should return 3 escalation schedules');
    }

    @isTest
    static void testGetEscSchedulesForOfferGen() {
        LeasingOrder__c contract = [SELECT Id FROM LeasingOrder__c LIMIT 1];
        LeasingEscalationScheduleService service = LeasingEscalationScheduleService.getInstance();
        List<LeasingEscalationSchedule__c> result = service.getEscalationSchedulesByContractId(contract.Id);
        System.assertEquals(3, result.size(), 'Should return 3 schedules');
        System.assertNotEquals(null, result[0].AnnualRent__c, 'AnnualRent should be populated');
    }

     
    @isTest
    static void testInsertEscSchedulesWithoutTrigger() {
        LeasingOrder__c contract = [SELECT Id FROM LeasingOrder__c LIMIT 1];

        List<LeasingEscalationSchedule__c> newSchedules = new List<LeasingEscalationSchedule__c>{
            new LeasingEscalationSchedule__c(
                LeasingOrder__c = contract.Id,
                Year__c = 4,
                AnnualRent__c = 40000,
                Escalation__c = 20,
                TotalRent__c = 48000,
                AfterDiscount__c = 42000
            )
        };

        LeasingEscalationScheduleService service = LeasingEscalationScheduleService.getInstance();
        Test.startTest();
        //List<LeasingEscalationSchedule__c> insertedSchedules = service.insertEscSchedulesWithoutTrigger(newSchedules);
        List<LeasingEscalationSchedule__c> insertedSchedules = service.insertLeasingEscalationSchedule(newSchedules);
        Test.stopTest();

        System.assertEquals(1, insertedSchedules.size(), '1 new schedule should be inserted');
    }

    @isTest
    static void testDeleteEscSchedulesWithoutTrigger() {
        List<LeasingEscalationSchedule__c> schedulesToDelete = [
            SELECT Id FROM LeasingEscalationSchedule__c LIMIT 2
        ];

        LeasingEscalationScheduleService service = LeasingEscalationScheduleService.getInstance();
        Test.startTest();
        //service.deleteEscSchedulesWithoutTrigger(schedulesToDelete);
        service.deleteEscSchedules(schedulesToDelete);
        Test.stopTest();

        List<LeasingEscalationSchedule__c> remaining = [
            SELECT Id FROM LeasingEscalationSchedule__c WHERE Id IN :schedulesToDelete
        ];
        System.assertEquals(0, remaining.size(), 'Selected schedules should be deleted');
    }
}