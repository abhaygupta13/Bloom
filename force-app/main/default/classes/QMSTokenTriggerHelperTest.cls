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
    static void testSendSMSNotification_Insert() {

        QMSToken__c token = [ SELECT Id, TokenNumber__c, MobileNumber__c FROM QMSToken__c LIMIT 1 ];
        Test.startTest();
            QMSTokenTriggerHelper.sendSMSNotification( new List<QMSToken__c>{ token }, null );
        Test.stopTest();
        List<IntegrationRecord__c> records = [ SELECT Id FROM IntegrationRecord__c ];
        System.assertEquals(false, records.isEmpty());
    }

    @IsTest
    static void testSendSMSNotification_Closure() {

        QMSToken__c oldToken = [ SELECT Id, TokenNumber__c, MobileNumber__c, ClosedDate__c FROM QMSToken__c LIMIT 1 ];
        QMSToken__c newToken = oldToken.clone(false, true, false, false);
        newToken.Id = oldToken.Id;
        newToken.ClosedDate__c = Date.today();
        Map<Id, QMSToken__c> oldMap = new Map<Id, QMSToken__c>{ oldToken.Id => oldToken };
        Test.startTest();
            QMSTokenTriggerHelper.sendSMSNotification( new List<QMSToken__c>{ newToken }, oldMap );
        Test.stopTest();
        List<IntegrationRecord__c> records = [ SELECT Id FROM IntegrationRecord__c ];
        System.assertEquals(false, records.isEmpty());
        QMSTokenTriggerHandler instanace = new QMSTokenTriggerHandler();
        instanace.beforeInsert(new List<QMSToken__c>{ newToken });
        instanace.afterInsert(new List<QMSToken__c>{ newToken }, oldMap );
        instanace.beforeUpdate(new List<QMSToken__c>{ newToken },oldMap, new List<QMSToken__c>{ newToken }, oldMap );
        instanace.afterUpdate(new List<QMSToken__c>{ newToken },oldMap, new List<QMSToken__c>{ newToken }, oldMap );
        instanace.beforeDelete(new List<QMSToken__c>{ newToken }, oldMap );
        instanace.afterDelete(new List<QMSToken__c>{ newToken }, oldMap );
    }
}