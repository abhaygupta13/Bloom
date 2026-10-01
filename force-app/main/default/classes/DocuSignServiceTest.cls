@isTest
private class DocuSignServiceTest {

    @TestSetup
    static void setupTestData() {
        // Create test Account
        Account testAccount = TestDataFactory.createPersonalAccount('Test', '784-1234-1234567-1', '971501234567', 'test@test.com');
        insert testAccount;
        
        // Create test Project
        Project__c testProject = TestDataFactory.createProject('Test Project', Date.today());
        insert testProject;
        
        // Create test Unit
        Unit__c testUnit = TestDataFactory.createUnit(testProject.Id, 'Test Unit', 'Available');
        insert testUnit;
        
        // Create test SalesOrder
        SalesOrder__c salesOrder = TestDataFactory.createSalesOrder(testAccount.Id, null, 'Active', Date.today(), testUnit.Id, 100000);
        insert salesOrder;
        
        // Create ServiceCatalog required by the trigger
        ServiceCatalog__c serviceCatalog = TestDataFactory.createServiceCatalog(
            'Test Service Catalog', 
            'Sales', 
            'Service Request', 
            'General Enquiry', 
            'Handover Update', 
            'Sales Order', 
            'Handover'
        );
        insert serviceCatalog;
        
        // Disable trigger before inserting Handover
        HandoverTriggerHandler.isTriggerDisabled = true;
        
        // Create Handover record with minimal fields
        Handover__c handover = new Handover__c(
            Name = 'Test Handover',
            Sales_Order__c = salesOrder.Id,
            Unit__c = testUnit.Id,
            Account__c = testAccount.Id,
            ServiceCatalog__c = serviceCatalog.Id
        );
        insert handover;
        
        // Re-enable trigger
        HandoverTriggerHandler.isTriggerDisabled = false;
        
        // Create DocumentType for testing
        DocumentType__c docType = TestDataFactory.createDocumentType('Handover', 'Handover Payment Attachment');
        insert docType;
        
        // Create ContentVersion for testing file attachment
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test PDF Content'));
        ContentVersion cv = TestDataFactory.createContentVersion(base64Data, 'TestDocument.pdf', 'Test Handover Document');
        insert cv;
        
        // Get ContentDocument Id
        ContentVersion cvCreated = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        
        // Create ContentDocumentLink to link file with SalesOrder
        ContentDocumentLink cdl = TestDataFactory.createContentDocumentLink(cvCreated.ContentDocumentId, salesOrder.Id, 'V', 'AllUsers');
        insert cdl;
    }
    
    @isTest
    static void testConstructor() {
        Test.startTest();
        DocuSignService config = new DocuSignService();
        Test.stopTest();
        
        System.assertNotEquals(null, config, 'Constructor should create instance successfully');
    }
    
    @isTest
    static void testSalesOrderDocuSign() {
        // Test data setup
        Id accRecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Broker Agency').getRecordTypeId();
        Account acc = new Account(Name = 'Test Account', RecordTypeId= accRecordTypeId);
        insert acc;

        Contact con1 = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@example.com',
            MobileCountryCode__c = '+1',
            MobilePhone = '1234567890',
            AccountId = acc.Id
        );
        insert con1;

        Opportunity tempOpp=new Opportunity(
            Name='tempOpp',
            StageName='New',
            CloseDate=system.today(),
            LeadChannel__c='Walk in',
            AccountId= acc.Id,
            WinReason__c='Loyalty',
            BrokerAgencyAccount__c= acc.Id,
         	BrokerAgentContact__c= con1.Id
        );
        insert tempOpp;

        Project__c testProject=new Project__c(
            Name='Test Project'
        );
        insert testProject;
        

        
        BuildingSection__c testBuilding=new BuildingSection__c(
            Name='Test Building',
            BuildingSectionCode__c='BL-CAS',
            Project__c=testProject.Id
            
        );
        insert testBuilding;

        Unit__c testUnit=new Unit__c(
            Name='test Unit',
            Status__c='Available',
            UnitType__c='Townhouse',
            BuildingSectionName__c=testBuilding.id,
            Project__c=testProject.Id,
            PropertyUsage__c='Residential',
            UnitView__c  ='Beach Side',
            FloorNumber__c='01',
            NumberOfBedrooms__c='3',
            UnitModel__c='1BHK',
            SellingPrice__c= 700000,
            EndDate__c= date.today()+10,
            StartDate__c=date.today()-10
            
        );
        insert testUnit;

        SalesOrder__c testOrder = new SalesOrder__c(
            Name = 'Test Order',
            Status__c = 'Sold',
            Unit__c =testUnit.id,
            Account__c = acc.Id,
            Opportunity__c=tempOpp.Id
            
            
        );
        insert testOrder;
        
         JointOwner__c testJointOwner=new JointOwner__c(
        	Account__c=acc.Id,
            SharePercentage__c=0,
            Salesorder__c = testOrder.id
        );
        
        insert testJointOwner;
         dfsle__EnvelopeConfiguration__c dfsub = new dfsle__EnvelopeConfiguration__c(
                dfsle__DocuSignId__c = '1122'
        );
        insert dfsub;
        
           Bloom_Docusign_Submissions__c submission = new Bloom_Docusign_Submissions__c(
            Description__c = 'Test Description',
           // Docusign_Envelope_Template_ID__c = dfsub.Id
            Sales_Order_ID__c = testOrder.Id,
            Document_Output_Name__c = 'Test Document'
        );
        insert submission;
       	Test.startTest();
        DocuSignService.SalesOrderGetRecipients(testOrder.Id, 'Broker');
        DocuSignService.SalesOrderGetRecipients(testOrder.Id, 'SPA');
        DocuSignService.SalesOrderGetRecipients(testOrder.Id, 'Referral');
        DocuSignService.SalesOrderGetRecipients(testOrder.Id, 'Offer');
        
        Test.stopTest();
	}
    
    @isTest
    static void BldocusignclsTestMethod() {
        // Test data setup
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Contact con1 = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@example.com',
            MobileCountryCode__c = '+1',
            MobilePhone = '1234567890',
            AccountId = acc.Id
        );
        insert con1;
        
        Opportunity tempOpp=new Opportunity(
            Name='tempOpp',
            StageName='New',
            CloseDate=system.today(),
            LeadChannel__c='Walk in',
            AccountId= acc.Id,
            WinReason__c='Loyalty'
            
            
        );
        insert tempOpp;
        
        Project__c testProject=new Project__c(
            Name='Test Project'
        );
        insert testProject;
        
        
        
        BuildingSection__c testBuilding=new BuildingSection__c(
            Name='Test Building',
            BuildingSectionCode__c='BL-CAS',
            Project__c=testProject.Id
            
        );
        insert testBuilding;
        
        Unit__c testUnit=new Unit__c(
            Name='test Unit',
            Status__c='Available',
            UnitType__c='Townhouse',
            BuildingSectionName__c=testBuilding.id,
            Project__c=testProject.Id,
            PropertyUsage__c='Residential',
            UnitView__c  ='Beach Side',
            FloorNumber__c='01',
            NumberOfBedrooms__c='3',
            UnitModel__c='1BHK',
            SellingPrice__c= 700000,
            EndDate__c= date.today()+10,
            StartDate__c=date.today()-10
            
        );
        insert testUnit;
        
        SalesOrder__c testOrder = new SalesOrder__c(
            Name = 'Test Order',
            Status__c = 'Sold',
            Unit__c =testUnit.id,
            Account__c = acc.Id,
            Opportunity__c=tempOpp.Id
            
            
        );
        insert testOrder;
        
        JointOwner__c testJointOwner=new JointOwner__c(
            Account__c=acc.Id,
            SharePercentage__c=0,
            Salesorder__c = testOrder.id
        );
        
        insert testJointOwner;
        dfsle__EnvelopeConfiguration__c dfsub = new dfsle__EnvelopeConfiguration__c(
            dfsle__DocuSignId__c = '1122'
        );
        insert dfsub;
        
        Bloom_Docusign_Submissions__c submission = new Bloom_Docusign_Submissions__c(
            Description__c = 'Test Description',
            // Docusign_Envelope_Template_ID__c = dfsub.Id
            Sales_Order_ID__c = testOrder.Id,
            Document_Output_Name__c = 'Test Document'
        );
        insert submission;
        
        // Create a test User with BBM in name
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User bbmUser = new User(
            FirstName = 'Test',
            LastName  = 'BBM User',
            Alias     = 'tuser',
            Email     = 'shruti.kulkarni@infobeans.com',
            Username  = 'tuser' + DateTime.now().getTime() + '@test.com',
            CommunityNickname = 'tuser' + DateTime.now().getTime(),
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = testProfile.Id
        );
        insert bbmUser;
        
        BrokerApplication__c brokerApp = new BrokerApplication__c(
            Name = 'Test Broker App',
            BBMId__c = bbmUser.Id
        );
        insert brokerApp;
        
        BrokerApplicant__c bApplicant = New BrokerApplicant__c();
        bApplicant.BrokerApplication__c = brokerApp.Id;
        bApplicant.FirstName__c = 'Test';
        bApplicant.LastName__c = 'User';
        bApplicant.Email__c = 'shruti.kulkarni@infobeans.com';
        bApplicant.BrokerContactRole__c = '	AuthorizedSignatoryOfficer';
        
        Insert bApplicant;

        Test.startTest();
        DocuSignService.BAPPGetRecipients(brokerApp.Id, 'Broker Agreement');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetRecipients_WithValidHandoverId() {
        // Get test handover
        Handover__c testHandover = [SELECT Id FROM Handover__c LIMIT 1];
        
        Test.startTest();
        List<dfsle.Recipient> recipients = DocuSignService.HandoverGetRecipients(testHandover.Id, 'Test Document');
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, recipients, 'Recipients list should not be null');
        System.assertEquals(2, recipients.size(), 'Should return 2 recipients (BloomSigner1 and BloomSigner2)');
    }
    @isTest
static void testCaseGetRecipients_KYCUpdateRequest() {

    Account testAccount = [
        SELECT Id, Name
        FROM Account
        LIMIT 1
    ];

    Id kycRecordTypeId = Schema.SObjectType.Case
        .getRecordTypeInfosByDeveloperName()
        .get('KYCUpdateRequest')
        .getRecordTypeId();

    Case testCase = new Case(
        AccountId = testAccount.Id,
        RecordTypeId = kycRecordTypeId,
        Origin = 'Web',
        Status = 'New',
        Subject = 'KYC Test Case'
    );
    insert testCase;

    Test.startTest();

    List<dfsle.Recipient> recipients =
        DocuSignService.CaseGetRecipientsforCIS(
            testCase.Id,
            'KYC Document'
        );

    Test.stopTest();

    System.assertNotEquals(null, recipients);
}
}