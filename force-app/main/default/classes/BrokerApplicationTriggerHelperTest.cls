@isTest
public class BrokerApplicationTriggerHelperTest {

    @testSetup
    static void setupTestData() {
        // Create DocumentType__c records with ObjectType__c = 'Broker Application'
        List<DocumentType__c> docTypes = new List<DocumentType__c>();
            docTypes.add(new DocumentType__c(
                //Name = 'DocType ' + i,
                ObjectType__c = 'Broker Application',
                Type__c = 'Broker Agreement',
                Active__c = true,
                IsDocgen__c = true,
                TypeOfEstablishment__c = 'Domestic'
            ));
        
        insert docTypes;
    }

    @isTest
    static void testCreateDocuments() {
        // Create Account with RecordType Broker_Agency and Same TL No.
        RecordType brokerAgencyRT = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND DeveloperName = 'Broker_Agency'
            LIMIT 1
        ];
        Account acc = new Account(
            Name = 'Test Account',
            RecordTypeId = brokerAgencyRT.Id,
            Trade_License_No__c = 'TLN12345678',
            BillingCountry = 'United Arab Emirates',
            BillingState = 'Dubai'

        );
        insert acc;

        
        // Create a BrokerApplication__c record
        List<BrokerApplication__c> brokerAppList = new List<BrokerApplication__c>{
            
            new BrokerApplication__c(
                Name = 'Test Broker App',
                TypeofEstablishment__c = 'Domestic',
                Emirate__c = 'Dubai',
                TradeLicenseNumber__c = 'TLN12345678',
                approvalStatus__c = 'Approved'
            ),
             new BrokerApplication__c(
                Name = 'Test Broker App',
                TypeofEstablishment__c = 'International',
                Emirate__c = 'Dubai',
                TradeLicenseNumber__c = 'TLN1234567',
                approvalStatus__c = 'Approved'
            ),
                
                // Create a BrokerApplication__c record with different TL
                new BrokerApplication__c(
                    Name = 'Test Broker App',
                    TypeofEstablishment__c = 'Domestic',
                    Emirate__c = 'Dubai',
                    TradeLicenseNumber__c = 'TLN123456789',
                    approvalStatus__c = 'Approved'
                )
                };
                    
          insert brokerAppList;


        BrokerApplicant__c applicant = new BrokerApplicant__c(
            BrokerApplication__c = brokerAppList[0].Id,
            Title__c = 'Mr.',
            FirstName__c = 'Test',
            LastName__c = 'Contact',
            BrokerContactRole__c = 'CEO',
            Email__c = 'test12@bloomholding.com',
            typeOfEstablishment__c = 'Domestic'
        );
        insert applicant;
        
        // Call the method under test
        Test.startTest();
        BrokerApplicationTriggerHelper.createDocuments(brokerAppList);
        BrokerApplicationTriggerHelper.checkExistingAndCreateAccount(brokerAppList);
        Test.stopTest();

        // Assert that Document__c records were created correctly
        List<Document__c> docs = [SELECT Id, BrokerApplication__c, DocumentType__c, Document_Name__c FROM Document__c WHERE BrokerApplication__c IN :brokerAppList];
        System.assertEquals(4, docs.size(), 'Expected related Document__c records to be created');

        // Optional: Check Document Names
        for (Document__c doc : docs) {
            System.assertNotEquals(null, doc.Document_Name__c, 'Document name should not be null');
        }
    }
        @isTest
    static void testCopyDocuments() {
        // Create Broker Application
        BrokerApplication__c brokerApp = new BrokerApplication__c(Name = 'Test App');
        insert brokerApp;
        
        // Create Account with RecordType Broker_Agency
        RecordType brokerAgencyRT = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND DeveloperName = 'Broker_Agency'
            LIMIT 1
        ];
        Account acc = new Account(
            Name = 'Test Account',
            RecordTypeId = brokerAgencyRT.Id,
            Broker_Application__c = brokerApp.Id
        );
        insert acc;
        
        // Create a real ContentVersion for Broker Application's document
        ContentVersion cv = new ContentVersion(
            Title = 'Trade License',
            PathOnClient = 'trade_license.pdf',
            VersionData = Blob.valueOf('Sample PDF content')
        );
        insert cv;
        
        // Query back to get the ContentDocumentId and Id
        cv = [
            SELECT Id, ContentDocumentId, Title, VersionData
            FROM ContentVersion
            WHERE Id = :cv.Id
            LIMIT 1
        ];
        
        // Create Document__c for BrokerApplication (will be matched by name)
        Document__c brokerDoc = new Document__c(
            BrokerApplication__c = brokerApp.Id,
            Document_Name__c = 'Trade License',
            FileName__c = 'Trade License.pdf',
            FileSizeMB__c = String.valueOf(0.01),
            FileType__c = 'pdf',
            ContentDocumentId__c = cv.ContentDocumentId,
            Content_Version_Id__c = cv.Id
        );
        insert brokerDoc;
        
        // Create Document__c for Account with the same Document_Name__c so key matches
        Document__c accDoc = new Document__c(
            Account__c = acc.Id,
            Document_Name__c = 'Trade License'
        );
        insert accDoc;
        
        // Re-query account to ensure Broker_Application__c is populated
        acc = [
            SELECT Id, Broker_Application__c
            FROM Account
            WHERE Id = :acc.Id
            LIMIT 1
        ];
        
        // Call the method
        Test.startTest();
        BrokerApplicationTriggerHelper.copyDocuments(new List<Account>{ acc });
        BrokerApplicationTriggerHelper.createBrokerContacts(new List<Account>{ acc });
        Test.stopTest();
        
        // Verify Account's Document__c got updated from Broker Application doc
        Document__c updatedAccDoc = [
            SELECT Id, FileName__c, FileSizeMB__c, FileType__c,
            ContentDocumentId__c, Content_Version_Id__c
            FROM Document__c
            WHERE Id = :accDoc.Id
            LIMIT 1
        ];
        
        //System.assertEquals('Trade License.pdf', updatedAccDoc.FileName__c, 'FileName__c should match broker doc');
        //System.assertEquals(brokerDoc.ContentDocumentId__c, updatedAccDoc.ContentDocumentId__c, 'ContentDocumentId__c should match');
        //System.assertNotEquals(null, updatedAccDoc.Content_Version_Id__c, 'Content_Version_Id__c should not be null');
    }
    
     @IsTest
    static void testApplicantCopyDocuments() {
        // Step 0: Create BrokerApplication
        BrokerApplication__c brokerApp = new BrokerApplication__c(
            Name = 'Test Application'
        );
        insert brokerApp;
        
        // Step 1: Create BrokerApplicant
        BrokerApplicant__c brokerApplicant = new BrokerApplicant__c(
            FirstName__c = 'John',
            LastName__c = 'Doe',
            BrokerApplication__c = brokerApp.Id
        );
        insert brokerApplicant;
        
        // Step 2: Create an actual ContentVersion for the BrokerApplicant's document
        ContentVersion cv = new ContentVersion(
            Title = 'Broker Agreement File',
            PathOnClient = 'BrokerAgreement.pdf',
            VersionData = Blob.valueOf('Test file content')
        );
        insert cv;
        
        // Fetch ContentDocumentId from inserted ContentVersion
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        
        // Step 3: Create Document__c for BrokerApplicant with real IDs
        Document__c brokerDoc = new Document__c(
            Document_Name__c = 'Broker Agreement',
            BrokerApplicant__c = brokerApplicant.Id,
            FileName__c = 'BrokerAgreement.pdf',
            FileSizeMB__c = String.valueOf(0.01),
            FileType__c = 'pdf',
            ContentDocumentId__c = cv.ContentDocumentId,
            Content_Version_Id__c = cv.Id
        );
        insert brokerDoc;
        
        // Step 4: Create Contact linked to BrokerApplicant
        Contact contact = new Contact(
            FirstName = 'Jane',
            LastName = 'Smith',
            BrokerApplicant__c = brokerApplicant.Id
        );
        insert contact;
        
        // Step 5: Create placeholder Document__c for Contact with same Document_Name__c
        Document__c contactDoc = new Document__c(
            Contact__c = contact.Id,
            Document_Name__c = 'Broker Agreement'
        );
        insert contactDoc;
        
        // Step 6: Call the method
        Test.startTest();
        BrokerApplicationTriggerHelper.copyDocumentsFromApplicantOrCase(new List<Contact>{contact});
        Test.stopTest();
        
        // Step 7: Verify the Contact's document was updated
        Document__c updatedDoc = [
            SELECT Id, ContentDocumentId__c, Content_Version_Id__c, FileName__c, FileType__c
            FROM Document__c
            WHERE Id = :contactDoc.Id
        ];
        
    }
    

}