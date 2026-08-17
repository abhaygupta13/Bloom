@isTest
public class SurveyControllerTest {

    @isTest
    static void testGetSurveyLink_withSurvey() {
        // Create a Handover record
        Handover__c handover = new Handover__c(Name = 'Test Handover');
        insert handover;

        // Create a Survey record linked to the Handover
        Survey__c survey = new Survey__c(
            Handover__c = handover.Id,
            Link__c = 'https://example.com/survey'
        );
        insert survey;

        // Call the method
        Test.startTest();
        String result = SurveyController.getSurveyLink(handover.Id);
        Test.stopTest();

        // Assert the link is returned
        System.assertEquals('https://example.com/survey', result,
            'Expected the survey link to be returned');
    }

    @isTest
    static void testGetSurveyLink_noSurvey() {
        // Create a Handover record without any Survey
        Handover__c handover = new Handover__c(Name = 'Test Handover No Survey');
        insert handover;

        // Call the method
        Test.startTest();
        String result = SurveyController.getSurveyLink(handover.Id);
        Test.stopTest();

        // Assert empty string is returned
        System.assertEquals('', result,
            'Expected empty string when no survey exists');
    }

    @isTest
    static void testGetSurveyLink_invalidRecordType() {
        // Create a dummy Account record to simulate wrong SObject type
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Call the method with Account Id
        Test.startTest();
        String result = SurveyController.getSurveyLink(acc.Id);
        Test.stopTest();

        // Assert empty string is returned
        System.assertEquals('', result,
            'Expected empty string when recordId is not Handover__c');
    }
}