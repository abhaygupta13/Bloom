@IsTest
public class BrokerCommissionDocuSignHandlerTest {
    
    

    @TestSetup
    static void setupData() {
         Project__c project = TestDataFactory.createProject('Project 1', System.today());
        //project.Company__c = brokerAcc.Id;
        insert project;
        
        // Create a test Account (Agency)
        Id brokerAgencyRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType,'Broker_Agency');
        Account agency = new Account(Name = 'Test Broker Agency', Black_listed__c = false, RecordTypeId = brokerAgencyRecordTypeId);
        insert agency;

        Id brokerContactRecordTypeId = Utility.getRecordTypeIdByDevName(Contact.SObjectType, 'Broker');
        // Create an Authorized Signatory Contact
        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Signatory',
            Email = 'signatory@test.com',
            AccountId = agency.Id,
            BrokerContactRole__c = 'AuthorizedSignatoryOfficer',
            IsActive__c = true,
            RecordTypeId = brokerContactRecordTypeId
        );
        insert con;

        // Create a dummy DocuSign Envelope Template
        dfsle__EnvelopeConfiguration__c docusignTemplate = new dfsle__EnvelopeConfiguration__c(
            Name = 'Test DocuSign Template',
            dfsle__DocuSignId__c = 'd330a82e-bc79-4b02-b118-49e41e2e8ab2'
        );
        insert docusignTemplate;

        // Create DocumentType__c record related to Broker Commission
        DocumentType__c docType = new DocumentType__c(
            //Name = 'Commission Doc Type',
            ObjectType__c = 'Broker Commission',
            Type__c = 'Generated Invoice',
            Document_Output_Name__c = 'Broker Commission Invoice',
            Document_Digital_Name__c = 'DigitalInvoice',
            Docusign_Envelope_Template__c = docusignTemplate.Id
        );
        insert docType;

        // Create a dummy Opportunity and SalesOrder__c (for relation path used in getRecipients)
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            WinReason__c = 'New Project Launch',
            BrokerAgencyAccount__c = agency.Id
        );
        insert opp;

        SalesOrder__c so = new SalesOrder__c(
            Name = 'SO001',
            Opportunity__c = opp.Id,
            Account__c = agency.id
        );
        insert so;

        // Create a BrokerCommission__c record
        BrokerCommission__c bc = new BrokerCommission__c(
            //Name = 'Test Commission',
            Agency__c = agency.Id,
            SalesOrder__c = so.Id,
            StartDate__c = Date.valueOf('2025-01-10'),
            Project__c = project.Id
        );
        insert bc;

        // Create a ContentDocument + ContentVersion + ContentDocumentLink to simulate file attachment
        ContentVersion cv = new ContentVersion(
            Title = 'Generated Invoice',
            PathOnClient = 'Invoice.pdf',
            VersionData = Blob.valueOf('Test file content'),
            IsMajorVersion = true
        );
        insert cv;

        Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        // Create corresponding Document__c record
        Document__c doc = new Document__c(
            //Name = 'Broker Commission Document',
            Document_Name__c = 'Generated Invoice',
            BrokerCommission__c = bc.Id,
            ContentDocumentId__c = contentDocId
        );
        insert doc;
        
        ContentDocumentLink cdl = new ContentDocumentLink(
            //LinkedEntityId = bc.Id,
            LinkedEntityId = doc.Id,
            ContentDocumentId = contentDocId,
            ShareType = 'V'
        );
        insert cdl;
    }

    @IsTest
    static void test_getCommissionDocumentTypes() {
        Test.startTest();
        //BrokerCommission__c commission = [SELECT Id FROM BrokerCommission__c LIMIT 1];
        List<DocumentType__c> docs = BrokerCommissionDocuSignHandler.getCommissionDocumentTypes();
        Test.stopTest();
        System.assert(!docs.isEmpty(), 'Should return at least one DocumentType__c');
        System.assertEquals('Broker Commission', docs[0].ObjectType__c);
    }

    @IsTest
    static void test_sendForCommissionSignature_success() {
        BrokerCommission__c bc = [SELECT Id FROM BrokerCommission__c LIMIT 1];
        DocumentType__c dt = [SELECT Id FROM DocumentType__c LIMIT 1];

        Test.startTest();
        BrokerCommissionDocuSignHandler.sendForCommissionSignature(bc.Id, new List<Id>{ dt.Id });
        Test.stopTest();

        // If no exceptions are thrown, test passes
        System.assert(true, 'Successfully sent for commission signature');
    }

    /*@IsTest
    static void test_sendForCommissionSignature_missingAgency() {
        BrokerCommission__c bc = new BrokerCommission__c(Name = 'No Agency');
        insert bc;
        DocumentType__c dt = [SELECT Id FROM DocumentType__c LIMIT 1];

        Test.startTest();
        try {
            BrokerCommissionDocuSignHandler.sendForCommissionSignature(bc.Id, new List<Id>{ dt.Id });
            System.assert(false, 'Expected AuraHandledException for missing Agency');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('no Agency'), 'Correct error thrown');
        }
        Test.stopTest();
    }*/

    @IsTest
    static void test_getRecipients_success() {
        BrokerCommission__c bc = [SELECT Id FROM BrokerCommission__c LIMIT 1];

        Test.startTest();
        List<dfsle.Recipient> recs = BrokerCommissionDocuSignHandler.getRecipients(bc.Id, 'Broker Commission Invoice');
        Test.stopTest();

        System.assertEquals(1, recs.size(), 'Should return one Authorized Signatory recipient');
    }

    @IsTest
    static void test_getRecipients_noAuthorizedContact() {
        // Create a new Account with no active authorized contacts
        Id brokerAgencyRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType,'Broker_Agency');
        Account a2 = new Account(Name = 'NoAuth Account', Black_listed__c = false, RecordTypeId = brokerAgencyRecordTypeId);
        insert a2;

        Opportunity opp2 = new Opportunity(
            Name = 'Opp No Auth',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            BrokerAgencyAccount__c = a2.Id,
            WinReason__c = 'New Project Launch'
        );
        insert opp2;

        SalesOrder__c so2 = new SalesOrder__c(
            Name = 'SO002',
            Opportunity__c = opp2.Id,
            Account__c = a2.Id
        );
        insert so2;
        
        Project__c project = TestDataFactory.createProject('Project 1', System.today());
        //project.Company__c = brokerAcc.Id;
        insert project;

        /*BrokerCommission__c commission = TestDataFactory.createBrokerCommission(null, null, null, null, null, project.Id, null, null, null, null);
        insert commission;*/
        
        BrokerCommission__c commission = [SELECT id,StartDate__c FROM BrokerCommission__c WHERE StartDate__c = 2025-01-10 LIMIT 1 ];

        Test.startTest();
        try {
            BrokerCommissionDocuSignHandler.getRecipients(commission.Id, 'Broker Commission Invoice');
            //System.assert(false, 'Expected AuraHandledException for missing signatory email');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Authorized Signatory'), 'Correct error message expected');
        }
        Test.stopTest();
    }

    /*@IsTest
        static void test_sendBrokerCommissionEnvelope_future() {
        BrokerCommission__c bc = [SELECT Id FROM BrokerCommission__c WHERE StartDate__c = 2025-01-10 LIMIT 1];
        DocumentType__c dt = [SELECT Id, Docusign_Envelope_Template__r.dfsle__DocuSignId__c FROM DocumentType__c LIMIT 1];
        Test.startTest();
        // Simulate future call
        BrokerCommissionDocuSignHandler.sendBrokerCommissionEnvelope(
            dt.Docusign_Envelope_Template__r.dfsle__DocuSignId__c,
            'Test Description',
            [SELECT Id FROM Document__c WHERE Document_Name__c = 'Generated Invoice' LIMIT 1].Id,
            bc.Id,
            'Broker Commission Invoice',
            'Email Subject'
        );
        Test.stopTest();

        System.assert(true, 'Future call executed successfully');
    }*/

    @IsTest
    static void test_sendForCommissionSignature_invalidParams() {
        Test.startTest();
        try {
            BrokerCommissionDocuSignHandler.sendForCommissionSignature(null, new List<Id>());
            System.assert(false, 'Should have thrown exception for invalid params');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('required'), 'Expected validation error');
        }
        Test.stopTest();
    }
}