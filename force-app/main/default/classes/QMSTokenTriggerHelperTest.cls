/*****************************************************************************************
Class       : QMSTokenTriggerHelperTest
Author      : Aman Bharti
Description : QMSTokenTriggerHelperTest Class 
Test Class  : 
Created Date: 23 JUL 2026 
*****************************************************************************************/

@IsTest
public class QMSTokenTriggerHelperTest {
    
    @TestSetup
    private static void createTestData() {
		
        SMSTemplate__c smsTempCreation = new SMSTemplate__c(Name = 'QMS Token Create Notification',SenderNumber__c = '1234567890',Body__c = 'Hello {0}');
        insert smsTempCreation;

        SMSTemplate__c smsTempClosure = new SMSTemplate__c(Name = 'QMS Token Closure Notification',SenderNumber__c = '1234567890',Body__c = 'Hello {0}');
        insert smsTempClosure;
        
        QMSToken__c token = TestDataFactory.createQMSTokenAssignment('C-123','Test Counter Name','test@gmail.com','123-1990-123456-78','test Name','SR-123','TRN-123');
        token.MobileNumber__c = '1234567890';
        insert token;
    }

    @IsTest
    private static void testSendSMSNotification() {
        Test.startTest();
            List<QMSToken__c> QMSTokenList = [SELECT Id,ClosedDate__c FROM QMSToken__c LIMIT 1];
            QMSTokenList[0].ClosedDate__c = Date.today();
            update QMSTokenList;
            delete QMSTokenList[0];
        Test.stopTest();
        List<IntegrationRecord__c> integrationRecList = [SELECT Id,Name FROM IntegrationRecord__c];
        Assert.areEqual(2,integrationRecList.size(),'Their should be atleast two Integration record');
    }    
}