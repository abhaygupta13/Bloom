/*****************************************************************************************
Class       : BFMSurveyBatchTest
Author      : Aman Bharti
Description : BFM Survey Batch Test
Test Class  : 
Created Date: 14 APRIL 2026 
*****************************************************************************************/
@isTest
public with sharing class BFMSurveyBatchTest {
    
    @TestSetup
    private static void testData(){
        List<Case> caseList = new List<Case>();
        caseList.add(TestDataFactory.createBFMCase('Web','Closed', 'description BFM1', 'BFM Case 1', '', 'testBFM1@gmail.com', '1234567890'));
        caseList.add(TestDataFactory.createBFMCase('Web','Closed', 'description BFM2', 'BFM Case 2', '', 'testBFM1@gmail.com', '1234567890'));
        caseList.add(TestDataFactory.createBFMCase('Web','Closed', 'description BFM3', 'BFM Case 3', '', 'testBFM2@gmail.com', '1234567890'));
        caseList.add(TestDataFactory.createBFMCase('Web','New', 'description BFM4', 'BFM Case 4', '', 'testBFM4@gmail.com', '1234567890'));
        insert caseList;
    }

    @isTest
    private static void testBFMSurveyBatchCreatesUniqueSurveyRecords(){
        Case oldCase = TestDataFactory.createBFMCase('Web','Closed','description BFM6','BFM Case 6','','testBFM6@gmail.com','1234567890');
        oldCase.ClosedDate = System.now().addDays(-6);
        oldCase.CreatedDate = System.now().addDays(-7);
        insert oldCase;
        Test.StartTest();
             Database.executeBatch(new BFMSurveyBatch(), 200);
        Test.StopTest();

        List<Survey__c> surveyList = [ SELECT Id, Email__c, SurveyType__c, Case__c FROM Survey__c WHERE SurveyType__c = 'BFM Customer Survey'];
        Assert.areEqual(2, surveyList.size(),'Only unique requester emails should create surveys');

        Set<String> emails = new Set<String>();
        for (Survey__c survey : surveyList) {
            emails.add(survey.Email__c);
        }
        Assert.areEqual(emails.contains('testBFM1@gmail.com'),false,'Expected email not found');
        Assert.areEqual(emails.contains('testBFM2@gmail.com'),false,'Expected email not found');
    }

    @isTest
    private static void testBatchWithNoEligibleCases() {
        List<Case> caseList = [SELECT Id FROM Case WHERE Status = 'Closed'];
        delete caseList;

        Test.startTest();
            Database.executeBatch(new BFMSurveyBatch(), 200);
        Test.stopTest();
        Integer surveyRecordCount = [SELECT COUNT() FROM Survey__c WHERE SurveyType__c = 'BFM Customer Survey'];
        Assert.areEqual(0, surveyRecordCount,'No surveys should be created when no eligible cases exist');
    }

    @isTest
    private static void testSchedule() {
        Test.startTest();
            String sch = '0 0 23 * * ?';
            BFMSurveyBatch batchJob = new BFMSurveyBatch();
            System.schedule('BFMSurveyBatch',sch,batchJob);
        Test.stopTest();
        List<AsyncApexJob> batchJobs = [SELECT Id, Status FROM AsyncApexJob WHERE ApexClass.Name = 'BFMSurveyBatch' AND JobType = 'BatchApex'];        
        System.assertEquals(1, batchJobs.size(), 'Unexpected number of batch jobs ran: ' + batchJobs);
    }
}