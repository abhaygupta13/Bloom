@IsTest
private class BusinessHoursScheduleServiceTest {

    @testSetup
    static void createData() {

        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];
        User usr = [SELECT Id, BusinessHour__c FROM User WHERE Id = :UserInfo.getUserId()];

        usr.BusinessHour__c = bh.Id;
        update usr;

        Date nextDay = Date.today().addDays(1);

        BusinessHoursSchedule__c schedule = new BusinessHoursSchedule__c(
            Name = 'Test Schedule',
            User__c = usr.Id,
            StartDateTime__c = Datetime.newInstance(nextDay, Time.newInstance(9, 0, 0, 0)),
            EndDateTime__c = Datetime.newInstance(nextDay, Time.newInstance(18, 0, 0, 0))
        );

        insert schedule;
    }

    @IsTest
    static void testGetInstance() {

        Test.startTest();
        BusinessHoursScheduleService service = BusinessHoursScheduleService.getInstance();
        Test.stopTest();

        System.assertNotEquals(null, service);
    }

    @IsTest
    static void testGetBusinessHoursScheduleByUserIds() {

        User usr = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        DateTime startDT = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
        DateTime endDT = DateTime.newInstance(Date.today().addDays(7), Time.newInstance(23, 59, 59, 0));

        Test.startTest();
        List<BusinessHoursSchedule__c> schedules = BusinessHoursScheduleService.getInstance().getBusinessHoursScheduleByUserIdStartDTEndDTs(new Set<Id>{usr.Id}, startDT, endDT);
        Test.stopTest();

        System.assert(schedules.size() > 0, 'Schedule records should be returned');
    }

    @IsTest
    static void testgetBusinessHoursScheduleByUserIdStartDTs() {

        User usr = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        DateTime startDT = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));

        Test.startTest();
        List<BusinessHoursSchedule__c> schedules = BusinessHoursScheduleService.getInstance().getBusinessHoursScheduleByUserIdStartDTs(new Set<Id>{usr.Id}, startDT);
        Test.stopTest();

        System.assert(schedules.size() > 0, 'Schedule records should be returned');
    }

    @IsTest
    static void testGetBusinessHoursScheduleByUserIdsEmpty() {

        DateTime startDT = DateTime.now();
        DateTime endDT = DateTime.now().addDays(7);

        Test.startTest();
        List<BusinessHoursSchedule__c> schedules = BusinessHoursScheduleService.getInstance().getBusinessHoursScheduleByUserIdStartDTEndDTs(new Set<Id>(), startDT, endDT);
        Test.stopTest();

        System.assertEquals(0, schedules.size());
    }
}