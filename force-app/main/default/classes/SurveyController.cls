public without sharing class SurveyController {

    @AuraEnabled(cacheable=true)
    public static String getSurveyLink(Id recordId) {
        SurveyService objSurveyService = SurveyService.getInstance();
        List<Survey__c> surveyList = objSurveyService.getSurveysByRelatedRecordId(recordId);

        if(surveyList != NULL && surveyList.size() > 0){
            return surveyList[0].Link__c;
        }
        return '';
    }
}