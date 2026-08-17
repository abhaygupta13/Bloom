@isTest
public class AssignToSelfTaskAssignmentControllerTest {
    
    @testSetup
    static void setupData() {
         Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Post_Sale_Payment_Deferral').getRecordTypeId();
        // Create test Case
        Case testCase = new Case(Subject = 'Test Case',RecordTypeId = caseRecordTypeId);
        insert testCase;
        
        // Create test Task related to the Case
        Task testTask = new Task(
            Subject = 'Follow up',
            WhatId = testCase.Id,
            Status = 'Not Started',
            Priority = 'Normal'
        );
        insert testTask;
    }
    
    @isTest
    static void testUpdateCaseOwner_Success() {
        // Get the test Task
        Task t = [SELECT Id FROM Task LIMIT 1];
        
        // Call the method
        Test.startTest();
        Boolean result = AssignToSelfTaskAssignmentController.updateCaseOwner(t.Id);
        Test.stopTest();
        
        // Verify the result
        System.assertEquals(true, result, 'Expected method to return true');
        
        // Check that task owner was updated
        Task updatedTask = [SELECT Id, OwnerId FROM Task WHERE Id = :t.Id];
        System.assertEquals(UserInfo.getUserId(), updatedTask.OwnerId, 'OwnerId should be current user');
        
        // Verify the case assignment history was inserted
        List<CaseAssignmentHistory__c> histories = [
            SELECT Id, Case__c, AssignedBy__c, OwnerId, Reason__c 
            FROM CaseAssignmentHistory__c
        ];
        System.assertEquals(1, histories.size(), 'Should have one history record');
        System.assertEquals('Assigned from Queue to User', histories[0].Reason__c);
    }
    
    @isTest
    static void testUpdateCaseOwner_NullId() {
        Test.startTest();
        Boolean result = AssignToSelfTaskAssignmentController.updateCaseOwner(null);
        Test.stopTest();
        
        System.assertEquals(true, result, 'Should return true even if recordId is null');
    }

    @isTest
    static void testUpdateCaseOwner_NotATask() {
        // Create an Account (not a Task)
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Test.startTest();
        Boolean result = AssignToSelfTaskAssignmentController.updateCaseOwner(acc.Id);
        Test.stopTest();
        
        System.assertEquals(true, result, 'Should return true if record is not a Task');
    }

}