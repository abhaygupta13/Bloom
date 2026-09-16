public with sharing class SurveyService {
    private static SurveyService instance;

    public static SurveyService getInstance() {
        if(instance == null) {
            instance = new SurveyService();
        }
        return instance;
    }
    
    public Survey__c getSurveyRecordById(Id recordId) {
        return [SELECT Id, Name FROM Survey__c WHERE Id = :recordId LIMIT 1];
    }
    
    public List<Survey__c> getSurveysByIds(List<Id> surveyIds) {
        return [SELECT Id, Name, Unit__c
                FROM Survey__c WHERE Id IN :surveyIds];
    }

    public List<Survey__c> getSurveysByRelatedRecordId(Id recordId) {
        List<Survey__c> surveyList = new List<Survey__c>();
        
        if(recordId.getSObjectType() == Handover__c.SObjectType){
            surveyList = [SELECT Id, Link__c FROM Survey__c WHERE Handover__c = :recordId LIMIT 1];
        }
        else if(recordId.getSObjectType() == SalesOrder__c.SObjectType){
            surveyList = [SELECT Id, Link__c FROM Survey__c WHERE SalesOrder__c = :recordId LIMIT 1];
        }
        else if(recordId.getSObjectType() == Case.SObjectType){
            surveyList = [SELECT Id, Link__c FROM Survey__c WHERE Case__c = :recordId LIMIT 1];
        }
        return surveyList;
    }
    
    public void insertSurveys(List<Survey__c> surveyList){
        if(surveyList != null && !surveyList.isEmpty()){
            insert surveyList;
        }
    }
    
    public void updateSurveys(List<Survey__c> surveyList){
        if(surveyList != null && !surveyList.isEmpty()){
            update surveyList;
        }
    }
}