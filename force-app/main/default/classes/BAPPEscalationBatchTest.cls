@isTest
public class BAPPEscalationBatchTest {

    @testSetup
    static void setupTestData() {
        // STEP 1: Insert test user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser_' + DateTime.now().getTime() + '@test.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert testUser;

        // STEP 2: Run non-setup DML in runAs block
        System.runAs(testUser) {
            Datetime now = System.now().addMinutes(-5);

            // Insert BrokerApplication__c records with ApprovalStatus__c
            insert new List<BrokerApplication__c>{
                new BrokerApplication__c(
                    Name = 'RFI App',
                   
                    RFIEscalationDate__c = now,
                    RFIRaisedBy__c = testUser.Id,
                    AgencyEmail__c = 'rfi-team@example.com',
                    ApprovalStatus__c = 'RFI',
                    IsRFIUpdated__c = true
                ),
                new BrokerApplication__c(
                    Name = 'REG App',
                   
                    RegistrationEscalationDate__c = now,
                    RFIRaisedBy__c = testUser.Id,
                    AgencyEmail__c = 'reg-team@example.com',
                    ApprovalStatus__c = 'Submitted',
                    IsRFIUpdated__c = true
                )
            };

            // Just query the EmailTemplates to make sure they exist (no insertion)
            EmailTemplate rfiTemplate = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Broker_Application_RFI_Escalation' LIMIT 1];
            EmailTemplate regTemplate = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Broker_Application_Reg_Escalation' LIMIT 1];

            // You can assert here if needed
            System.assertNotEquals(null, rfiTemplate, 'RFI template must exist');
            System.assertNotEquals(null, regTemplate, 'REG template must exist');
        }
    }

    @isTest
    static void testBatchExecution() {
        Test.startTest();
        BAPPEscalationBatch batch = new BAPPEscalationBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        System.debug('BAPPEscalationBatch executed successfully.');
    }

    @isTest
    static void testScheduledExecution() {
        Test.startTest();
        String cron = '0 0 0 1 1 ? 2050'; // Arbitrary future cron
        System.schedule('BAPP_Escalation_Schedule', cron, new BAPPEscalationBatch());
        Test.stopTest();

        System.debug('Scheduled job created.');
    }
}