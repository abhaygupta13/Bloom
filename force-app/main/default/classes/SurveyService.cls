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
        return surveyList;
    }
    
    
    public List<Survey__c>getServeysByParentIdandSurveyType(Id recordId, String surveyType) { 
        List<Survey__c> surveyList = new List<Survey__c>();
        if(recordId.getSObjectType() == Handover__c.SobjectType){
            surveyList = [SELECT Id,SurveyType__c,Handover__c,Link__c FROM Survey__c where  Handover__c=:recordId AND SurveyType__c='Handover Survey' ];
                          }
               return null;
    }
    public Survey__c getSingleSurveyByParentIdAndSurveyType(Id recordId, String surveyType) {
       if(recordId.getSObjectType() == Handover__c.SobjectType){
        Survey__c survey = [SELECT Id,SurveyType__c,Handover__c,Link__c FROM Survey__c where  Handover__c=:recordId AND SurveyType__c='Handover Survey' limit 1];
        return  survey;
       }
        return null;
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