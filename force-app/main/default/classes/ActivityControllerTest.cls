/*****************************************************************************************
Class       : ActivityControllerTest
Author      : Dhanraj Poojary
Description : Test class for ActivityController
Created Date: 26 MAR 2025
*****************************************************************************************/
@isTest
public class ActivityControllerTest {
    @testSetup
    static void setup() {
        // Create test data
        List<user> ulist = [select id from user where Profile.Name ='System Administrator' AND IsActive = true limit 1];
        Id BrokeragencyId =Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Broker_Agency').getRecordTypeId();
        Account a = new Account();
        a.Name = 'TestVinay';
        insert a;
        Contact c = new Contact();
        c.LastName = 'test conatat';
        c.AccountId = a.id;
        c.Email = 'test@test.com';
        insert c;
        Lead testLead = TestDataFactory.createLead('Test', '9843216782', 'test@gmail.com');
        insert testLead;
        
        
        Task testTask = new Task(
            Subject = 'Day 1 Call 1 - Follow Up',
            Status = 'Open',
            OwnerId = UserInfo.getUserId(),
            WhoId = testLead.Id
        );
        insert testTask;
    }

    @isTest
    static void testMarkTaskComplete() {
        // Retrieve test task
        Task testTask = [SELECT Id, Status, WhoId FROM Task LIMIT 1];
        // Call method under test
        Test.startTest();
        String result = ActivityController.markTaskComplete(testTask.Id);
        Test.stopTest();
    }

    @isTest
    static void testCreateNewFollowupTask() {
        // Retrieve test task
        Task testTask = [SELECT Id, Status, Subject, OwnerId, WhoId FROM Task LIMIT 1];
        Lead objLead = [SELECT Id,lead_channel__c, ContactCentreLeadStatus__c FROM Lead];
        // Set status to Qualified to trigger follow-up mapping
        testTask.Status = 'Qualified';
        update testTask;
        
        // Call method under test
        Test.startTest();
        Task followUpTask = ActivityController.createNewFollowupTask(testTask,objLead);
        Test.stopTest();
    }
}