/*****************************************************************************************
Class       : BFMSurveyBatch
Author      : Aman Bharti
Description : BFM Survey Batch
Test Class  : BFMSurveyBatchTest
Created Date: 25 March 2026 
*****************************************************************************************/
/*****************************************************************************************************
* Version       Author          Date             Comment
* 1.0         Aman Bharti      25 MAR 2026
*****************************************************************************************************/
public class BFMSurveyBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable{
    private static final string STATUS_CLOSED { get { return 'Closed'; } }
    private static final string BFM_RECORD_TYPE_DEV_NAME { get { return 'BFMServiceRequest'; } }
    Set<String> uniqueEmails = new Set<String>();

    public Database.QueryLocator start(Database.BatchableContext bc) {
        DateTime fromDate = System.now().addDays(-5);
        Id bfmRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, BFM_RECORD_TYPE_DEV_NAME);
        return Database.getQueryLocator([SELECT Id, RequesterEmail__c FROM Case WHERE RecordTypeId = :bfmRecordTypeId AND RequesterEmail__c != NULL AND Status = :STATUS_CLOSED AND ClosedDate >= :fromDate]);
    }

    public void execute(Database.BatchableContext bc, List<Case> caseList) {
        Set<Id> eligibleCaseIds = new Set<Id>();

        for(Case objCase : caseList){
            if(String.isNotBlank(objCase.RequesterEmail__c) && !uniqueEmails.contains(objCase.RequesterEmail__c)){ 
                uniqueEmails.add(objCase.RequesterEmail__c);
                eligibleCaseIds.add(objCase.Id);
            }
        }
        SurveyHandler.sendBFMCaseSurvey(eligibleCaseIds);
    }

    public void finish(Database.BatchableContext bc) {
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new BFMSurveyBatch(), 200);
    }
}