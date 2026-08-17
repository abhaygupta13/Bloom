@isTest
public with sharing class FollowUpTriggerHandlerTest {
    
    @testSetup
    static void setupData() {
        // Create a User as Case Owner
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + Math.random() + '@example.com',
            Alias = 'tusr',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = UserInfo.getProfileId(),
            LanguageLocaleKey = 'en_US'
        );
        insert u;
        // Create a Queue (Group of type Queue)
        Group q = new Group(
            Name = 'FollowUp Test Queue',
            Type = 'Queue'
        );
        insert q;
        // Create GroupMember mapping queue → current test user
        insert new GroupMember(
            GroupId = q.Id,
            UserOrGroupId = u.Id
        );
    }

    @isTest
    static void testAfterInsertHandler() {

        // Ensure trigger is enabled
        FollowUpTriggerHandler.isTriggerDisabled = false;
        
        Group grpRec = [SELECT Id FROM Group WHERE Name = 'FollowUp Test Queue' LIMIT 1];
        Test.startTest();
		String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Default Unit').getRecordTypeId();
        // Create Case for FollowUp
        Case c = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Origin = 'Phone',
            OwnerId = grpRec.Id,
            RecordTypeId=RecordTypeCaseId
            //Case_Sub_Status__c = 'In Progress'
        );
        insert c;

        // Create FollowUp__c linked to Case
        FollowUp__c fu = new FollowUp__c(
            Comments__c = 'Test FU',
            Case__c = c.Id
        );
		//insert fu;
        

        //Test.startTest();

        //FollowUp__c fu = new FollowUp__c(Comments__c = 'Test FollowUp', OwnerId = UserInfo.getUserId());
        insert fu;

        fu.Comments__c = 'Testing';
        update fu;
        
        delete fu;
        //FollowUp__c insertedFu = [SELECT Id, Name FROM FollowUp__c WHERE Id = :fu.Id LIMIT 1];
        // System.assertEquals('ExpectedValue', insertedFu.Some_Field__c);
        Test.stopTest();
    }

    @isTest
    static void testTriggerDisabled() {

        // Disable trigger
        FollowUpTriggerHandler.isTriggerDisabled = true;

        Test.startTest();

        FollowUp__c fu = new FollowUp__c(Comments__c = 'Trigger Disabled Test');
        insert fu;

        Test.stopTest();

        // Since disabled, helper logic should NOT run.
        // Validate fields are unchanged (modify according to helper logic)
        // FollowUp__c fuCheck = [SELECT Id, Name FROM FollowUp__c WHERE Id = :fu.Id LIMIT 1];
        // System.assertEquals(null, fuCheck.Some_Field__c);  // Example
    }
}