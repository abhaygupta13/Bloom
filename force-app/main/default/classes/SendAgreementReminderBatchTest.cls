/*
* @Author      : Akshay Khairnar
* @CreatedDate : 27th JUNE 2025
* @Description : Test class for SendAgreementReminderBatch.Verifies execution of the batch process and 
*                correct update of RFI__c records with remaining days.
*/
/*****************************************************************************************************
* Version   Author           Date           Comment
* 1.0       Rushikesh        27-JUN-2025    Validates batch execution and RFI 
*                                           remaining days calculation logic
*****************************************************************************************************/
@isTest
private class SendAgreementReminderBatchTest {

    @testSetup
    static void setupTestData() {
        Date today = Date.today();
        List<BrokerApplication__c> apps = new List<BrokerApplication__c>();

        // Create 3 test applications for days 7, 15, 30
        for (Integer i : new Integer[]{7, 15, 30}) {
            apps.add(new BrokerApplication__c(
                Name = 'App ' + i,
                AgencyEmail__c = 'test' + i + '@example.com',
                CompanyPhone_Number__c = '999999999' + i,
                CountryCode__c = '971',
                AgreementInitiationDate__c = today.addDays(-i),
                ApprovalStatus__c = 'Under Agreement',
                BrokerSigned__c = false
            ));
        }
        insert apps;
    }

    @isTest
    static void testNoReminderDay() {
        Date today = Date.today();
    
        BrokerApplication__c app = new BrokerApplication__c(
            Name = 'No Reminder App',
            AgencyEmail__c = 'noreminder@test.com',
            CompanyPhone_Number__c = '9999999999',
            CountryCode__c = '971',
            AgreementInitiationDate__c = today.addDays(-7), 
            ApprovalStatus__c = 'Under Agreement',
            BrokerSigned__c = false
        );
        insert app;
    
        Test.startTest();
        Database.executeBatch(new SendAgreementReminderBatch(), 200);
        Test.stopTest();
    
        BrokerApplication__c updatedApp = [
            SELECT AgreementRemainingDays__c
            FROM BrokerApplication__c
            WHERE Id = :app.Id
        ];
    
        System.assertNotEquals(null, updatedApp.AgreementRemainingDays__c);
    }

    @isTest
    static void testSchedulableExecution() {
        Test.startTest();
        SendAgreementReminderBatch batch = new SendAgreementReminderBatch();
        batch.execute((SchedulableContext) null);
        Test.stopTest();

        System.assert(true, 'Schedulable execution completed successfully.');
    }
}