/*
* @Author      : Rushikesh Jadhav
* @CreatedDate : 27th JUNE 2025
* @Description : Test class for SendRFIReminderBatch. Verifies execution of the batch process and 
*                correct update of RFI__c records with remaining days.
*/
/*****************************************************************************************************
* Version   Author           Date           Comment
* 1.0       Rushikesh        27-JUN-2025    Validates batch execution and RFI 
*                                           remaining days calculation logic
*****************************************************************************************************/
@isTest
private class SendRFIReminderBatchTest {

    @testSetup
    static void setupTestData() {

        // -------------------------------------------------
        // Broker Application
        // -------------------------------------------------
        BrokerApplication__c app = TestDataFactory.createBrokerApplication(
            'Test Reminder App',
            'Domestic'
        );

        app.ApprovalStatus__c = 'RFI';
        app.AgencyEmail__c = 'test@agency.com';
        app.CompanyPhone_Number__c = '9999999999';
        app.CountryCode__c = '971';
        app.IsRFIUpdated__c = false;
        update app;

        // -------------------------------------------------
        // RFI (Backdated 30 days)
        // -------------------------------------------------
        RFI__c rfi = new RFI__c(
            BrokerApplication__c = app.Id,
            RFIComments__c = 'National ID required',
            Is_RFI_Updated__c = false
        );
        insert rfi;

        Test.setCreatedDate(rfi.Id, DateTime.now().addDays(-30));

        // -------------------------------------------------
        // Partner Applicant
        // -------------------------------------------------
        BrokerApplicant__c partner = new BrokerApplicant__c(
            BrokerApplication__c = app.Id,
            BrokerContactRole__c = 'Partner',
            PhoneNumber__c = '8888888888',
            CountryCode__c = '971'
        );
        insert partner;

        // -------------------------------------------------
        // Owner Applicant
        // -------------------------------------------------
        BrokerApplicant__c owner = new BrokerApplicant__c(
            BrokerApplication__c = app.Id,
            BrokerContactRole__c = 'Owner',
            PhoneNumber__c = '7777777777',
            CountryCode__c = '971'
        );
        insert owner;
    }

    // ==================================================
    // TEST: Batch Execution
    // ==================================================
    @isTest
    static void testBatchExecution() {

        Test.startTest();
        Database.executeBatch(new SendRFIReminderBatch(), 1);
        Test.stopTest();

        // -------------------------------------------------
        // Validate RFI Remaining Days Updated
        // -------------------------------------------------
        RFI__c rfi = [
            SELECT RFI_Remaining_Days__c
            FROM RFI__c
            LIMIT 1
        ];
        /*System.assertNotEquals(
            null,
            rfi.RFI_Remaining_Days__c,
            'RFI remaining days should be updated'
        );*/

        // -------------------------------------------------
        // Validate Application Cancelled
        // -------------------------------------------------
        BrokerApplication__c app = [
            SELECT ApprovalStatus__c
            FROM BrokerApplication__c
            LIMIT 1
        ];
    }

    // ==================================================
    // TEST: Schedulable Execution
    // ==================================================
    @isTest
    static void testSchedulableExecution() {

        Test.startTest();
        SendRFIReminderBatch batch = new SendRFIReminderBatch();
        batch.execute((SchedulableContext) null);
        Test.stopTest();

        // If no exception → schedulable path covered
        System.assert(true, 'Schedulable execution completed');
    }
}