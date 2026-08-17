@isTest
public class DocusignStatusTriggerHelperTest {
    
    @testSetup
    static void setupData() {
        User bbmUser = [SELECT Id FROM User WHERE Profile.Name = 'Broker Management Team' AND IsActive = true LIMIT 1];
        // Create Broker Application
        TestDataFactory.createBrokerApplication('Test Agency', 'Domestic');
        BrokerApplication__c app = [SELECT Id, Name, ApplicationNumber__c, Drawloop_Next_1__c FROM BrokerApplication__c WHERE Name = 'Test Agency' LIMIT 1];
        
         BrokerApplicant__c newApplicant = new BrokerApplicant__c(
            BrokerApplication__c = app.Id,
            FirstName__c = 'Alice',
            LastName__c = 'Smith',
            Email__c = 'alice.smith@example.com'
        );
        
        app.BloomSignatoryEmail__c = 'invalid@invalid.com';
        app.BBMId__c = bbmUser.Id;
        update app;

        // Create Envelope Status record (initial state)
        dfsle__EnvelopeStatus__c env = new dfsle__EnvelopeStatus__c(
            dfsle__SourceId__c = app.Id,
            dfsle__Status__c = 'Sent',
            BrokerSigned__c = false
        );
        insert env;
    }

    @isTest
    static void testStatusChangeToCompleted() {
        // Fetch test data
        dfsle__EnvelopeStatus__c env = [SELECT Id, dfsle__Status__c, dfsle__SourceId__c FROM dfsle__EnvelopeStatus__c WHERE dfsle__SourceId__c != null AND dfsle__Status__c = 'Sent' LIMIT 1];
        BrokerApplication__c app = [SELECT Id, Name,BloomSignatoryEmail__c, BBMId__c, ApplicationNumber__c, Drawloop_Next_1__c FROM BrokerApplication__c WHERE Name = 'Test Agency' LIMIT 1];
        env.dfsle__Status__c = 'Completed';
        Test.startTest();
        update env;
        Test.stopTest();
    }

    @isTest
    static void testBrokerSignedChange() {
        dfsle__EnvelopeStatus__c env = [
            SELECT Id, BrokerSigned__c
            FROM dfsle__EnvelopeStatus__c
            LIMIT 1
        ];

        env.BrokerSigned__c = true;

        Test.startTest();
        update env;
        Test.stopTest();
    }

    @isTest
    static void testNoSourceIdIgnored() {
        dfsle__EnvelopeStatus__c env = [SELECT Id, BrokerSigned__c FROM dfsle__EnvelopeStatus__c LIMIT 1];

        Test.startTest();
        env.dfsle__Status__c = 'Completed';
        update env;
        Test.stopTest();
    }

    @isTest
    static void testNonBrokerApplicationSourceIgnored() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        dfsle__EnvelopeStatus__c env = new dfsle__EnvelopeStatus__c(
            dfsle__SourceId__c = acc.Id,
            dfsle__Status__c = 'Sent'
        );
        insert env;

        env.dfsle__Status__c = 'Completed';

        Test.startTest();
        update env;
        delete env;
        Test.stopTest();
    }
}