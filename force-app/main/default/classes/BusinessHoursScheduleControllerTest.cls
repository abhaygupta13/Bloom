@isTest
public class BusinessHoursScheduleControllerTest {

    static User createUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@test.com',
            Username = 'testuser' + System.currentTimeMillis() + '@test.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );

        insert u;
        return u;
    }

    @isTest
    static void testUploadScheduleInsert() {
        createUser();

        String csvData =
            'AgentName,Email,StartDate,StartTime,EndDate,EndTime\n' +
            'Test User,testuser@test.com,05-01-2026,09:00 AM,05-01-2026,06:00 PM';

        Test.startTest();
        String result = BusinessHoursScheduleController.uploadSchedule(csvData, 'test.csv');
        Test.stopTest();

        System.assert(result.contains('1 records inserted'));

        List<BusinessHoursSchedule__c> records = [
            SELECT Id, Name
            FROM BusinessHoursSchedule__c
        ];

        System.assertEquals(1, records.size());
    }

    @isTest
    static void testUploadScheduleUpdate() {
        User u = createUser();

        BusinessHoursSchedule__c rec = new BusinessHoursSchedule__c(
            Name = 'Old Record',
            User__c = u.Id,
            StartDateTime__c = DateTime.newInstance(2026, 5, 19, 9, 0, 0),
            EndDateTime__c = DateTime.newInstance(2026, 5, 19, 18, 0, 0)
        );

        insert rec;

        String csvData =
            'AgentName,Email,StartDate,StartTime,EndDate,EndTime\n' +
            'Updated User,testuser@test.com,19-05-2026,09:00 AM,19-05-2026,08:00 PM';

        Test.startTest();
        String result = BusinessHoursScheduleController.uploadSchedule(csvData, 'test.csv');
        Test.stopTest();
    }

    @isTest
    static void testBlankCSV() {
        Test.startTest();

        try {
            BusinessHoursScheduleController.uploadSchedule('', 'test.csv');
            System.assert(false);
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException);
        }

        Test.stopTest();
    }

    @isTest
    static void testInvalidFileFormat() {
        Test.startTest();

        try {
            BusinessHoursScheduleController.uploadSchedule('data', 'test.txt');
            System.assert(false);
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException);
        }

        Test.stopTest();
    }

    @isTest
    static void testInvalidHeader() {
        String csvData =
            'Name,Email,Start,End\n' +
            'Test,test@test.com,05/19/2026 09:00,05/19/2026 18:00';

        Test.startTest();

        try {
            BusinessHoursScheduleController.uploadSchedule(csvData, 'test.csv');
            System.assert(false);
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException);
        }

        Test.stopTest();
    }

    @isTest
    static void testInvalidEmail() {
        String csvData =
            'AgentName,Email,StartDateTime,EndDateTime\n' +
            'Test,invalidemail,05/19/2026 09:00,05/19/2026 18:00';

        Test.startTest();

        try {
            BusinessHoursScheduleController.uploadSchedule(csvData, 'test.csv');
            System.assert(false);
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException);
        }

        Test.stopTest();
    }

    @isTest
    static void testNoUserFound() {
        String csvData =
            'AgentName,Email,StartDateTime,EndDateTime\n' +
            'Test,nouser@test.com,05/19/2026 09:00,05/19/2026 18:00';

        Test.startTest();

        try {
            BusinessHoursScheduleController.uploadSchedule(csvData, 'test.csv');
            System.assert(false);
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException);
        }

        Test.stopTest();
    }

    @isTest
    static void testInvalidDateFormat() {
        createUser();

        String csvData =
            'AgentName,Email,StartDateTime,EndDateTime\n' +
            'Test,testuser@test.com,invaliddate,05/19/2026 18:00';

        Test.startTest();

        try {
            BusinessHoursScheduleController.uploadSchedule(csvData, 'test.csv');
            System.assert(false);
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException);
        }

        Test.stopTest();
    }

    @isTest
    static void testEndDateLessThanStartDate() {
        createUser();

        String csvData =
            'AgentName,Email,StartDateTime,EndDateTime\n' +
            'Test,testuser@test.com,05/19/2026 18:00,05/19/2026 09:00';

        Test.startTest();

        try {
            BusinessHoursScheduleController.uploadSchedule(csvData, 'test.csv');
            System.assert(false);
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException);
        }

        Test.stopTest();
    }
}