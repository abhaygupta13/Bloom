@isTest
private class LeasingSiteControllerTest {

    @testSetup
    static void setupTestData() { 
        Id personAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, 'PersonAccount');
        Account personAccount = new Account(
            RecordTypeId = personAccountRecordTypeId,
            LastName = 'Test Person Account', 
            Phone = '971202520',
            PersonEmail='abc@gmail.com',
            Nationality__c = 'Indian',
            PrimaryMobilePhone__pc = '1234567890',
            SecondaryMobilePhone__pc = '9876543210',
            TertiaryMobilePhone__pc = '1122334455'
        );
        insert personAccount;

        DocumentType__c dc1 = TestDataFactory.createDocumentType('Opportunity', 'Emirates ID');
        dc1.Customer_Type__c = 'Individual';
        insert dc1;
        
        DocumentType__c dc2 = TestDataFactory.createDocumentType('Opportunity', 'Visa');
        dc2.Customer_Type__c = 'Individual';
        insert dc2;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = personAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            OpportunityType__c = 'Leasing'
        );
        insert opp;
        
        Document__c doc = new Document__c(
            Document_Name__c = 'testDoc',
            Opportunity__c = opp.Id
        );
        insert doc;
    }

    @isTest
    static void testUploadFiles() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        String fakeData = EncodingUtil.base64Encode(Blob.valueOf('Test file content'));

        List<LeasingSiteController.FileWrapper> files = new List<LeasingSiteController.FileWrapper>();
        LeasingSiteController.FileWrapper fw = new LeasingSiteController.FileWrapper();
        fw.fileName = 'testFile.pdf';
        fw.fileData = fakeData;
        fw.category = 'Visa';
        files.add(fw);

        Test.startTest();
        LeasingSiteController.uploadFiles(opp.Id, files);
        Test.stopTest();

        List<ContentVersion> cvs = [SELECT Id, Title FROM ContentVersion WHERE Title LIKE 'Visa_testFile.pdf%'];
        System.assert(!cvs.isEmpty(), 'ContentVersion should have been inserted');
    }

    @isTest
    static void testSendOpportunityNotificationEmail() { 
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        LeasingSiteController.sendOpportunityNotificationEmail(opp.Id);
        Opportunity oppFetched = LeasingSiteController.getOpportunity(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, oppFetched, 'Opportunity should not be null');
    }
}