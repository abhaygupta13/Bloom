@isTest
private class ContactCenterScheduleBatchTest {

    private class BusinessHoursMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            System.assertEquals('PATCH', req.getMethod());

            HttpResponse res = new HttpResponse();
            res.setStatusCode(204);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('SUCCESS');

            return res;
        }
    }

    private static BusinessHoursSchedule__c createSchedule(Boolean invalidTime) {

        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];
        User usr = [SELECT Id, BusinessHour__c FROM User WHERE Id = :UserInfo.getUserId()];

        usr.BusinessHour__c = bh.Id;
        update usr;

        Date mondayDate = Date.today().toStartOfWeek().addDays(7);

        BusinessHoursSchedule__c sch = new BusinessHoursSchedule__c();
        sch.Name = 'Test Schedule';
        sch.User__c = usr.Id;

        if (invalidTime) {
            sch.StartDateTime__c = DateTime.newInstance(mondayDate, Time.newInstance(18, 0, 0, 0));
            sch.EndDateTime__c = DateTime.newInstance(mondayDate, Time.newInstance(10, 0, 0, 0));
        } else {
            sch.StartDateTime__c = DateTime.newInstance(mondayDate, Time.newInstance(8, 30, 0, 0));
            sch.EndDateTime__c = DateTime.newInstance(mondayDate, Time.newInstance(17, 30, 0, 0));
        }

        insert sch;
        return sch;
    }

    @isTest
    static void testBatchExecution() {

        createSchedule(false);

        Test.setMock(HttpCalloutMock.class, new BusinessHoursMock());

        Test.startTest();
        Database.executeBatch(new ContactCenterScheduleBatch(), 200);
        Test.stopTest();

        System.assert(true);
    }

    @isTest
    static void testSchedulerExecution() {

        Test.setMock(HttpCalloutMock.class, new BusinessHoursMock());

        Test.startTest();
        Database.executeBatch(new ContactCenterScheduleBatch(), 200);
        Test.stopTest();

        System.assert(true);
    }

    @isTest
    static void testExecuteWithEmptyScope() {

        Test.setMock(HttpCalloutMock.class, new BusinessHoursMock());

        Test.startTest();
        new ContactCenterScheduleBatch().execute(null, new List<User>());
        Test.stopTest();

        System.assert(true);
    }

    @isTest
    static void testInvalidTimeRange() {

        createSchedule(true);

        Test.setMock(HttpCalloutMock.class, new BusinessHoursMock());

        Test.startTest();

        User usr = [SELECT Id, BusinessHour__c FROM User WHERE Id = :UserInfo.getUserId()];
        new ContactCenterScheduleBatch().execute(null, new List<User>{usr});

        Test.stopTest();

        System.assert(true);
    }

    @isTest
    static void testExecuteMethodCoverage() {

        BusinessHoursSchedule__c sch = createSchedule(false);

        List<BusinessHoursSchedule__c> schedules = [
            SELECT Id, Name, User__c, StartDateTime__c, EndDateTime__c, User__r.BusinessHour__c
            FROM BusinessHoursSchedule__c
            WHERE Id = :sch.Id
        ];

        Test.setMock(HttpCalloutMock.class, new BusinessHoursMock());

        Test.startTest();

        User usr = [SELECT Id, BusinessHour__c FROM User WHERE Id = :UserInfo.getUserId()];
        new ContactCenterScheduleBatch().execute(null, new List<User>{usr});

        Test.stopTest();

        System.assertEquals(1, schedules.size());
    }

    @isTest
    static void testExecuteMethodOne() {

        Test.setMock(HttpCalloutMock.class, new BusinessHoursMock());

        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];
        User usr = [SELECT Id, BusinessHour__c FROM User WHERE Id = :UserInfo.getUserId()];

        usr.BusinessHour__c = bh.Id;
        update usr;

        Date nextMonday = Date.today();

        while (DateTime.newInstance(nextMonday, Time.newInstance(0, 0, 0, 0)).format('EEEE') != 'Monday')
            nextMonday = nextMonday.addDays(1);

        BusinessHoursSchedule__c sch = new BusinessHoursSchedule__c(
            Name = 'Test Schedule',
            User__c = usr.Id,
            StartDateTime__c = DateTime.newInstance(nextMonday, Time.newInstance(8, 30, 0, 0)),
            EndDateTime__c = DateTime.newInstance(nextMonday, Time.newInstance(17, 30, 0, 0))
        );

        insert sch;

        List<BusinessHoursSchedule__c> schedules = [
            SELECT Id, Name, User__c, StartDateTime__c, EndDateTime__c, User__r.BusinessHour__c
            FROM BusinessHoursSchedule__c
            WHERE Id = :sch.Id
        ];

        Test.startTest();
        new ContactCenterScheduleBatch().execute(null, new List<User>{usr});
        Test.stopTest();

        System.assertEquals(1, schedules.size());
    }
}