@isTest
private class HandoverSendOrientationBatchTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test project
        Project__c project = TestDataFactory.createProject('Test Project', Date.today());
        insert project;
        
        // Create test accounts
        Account acc1 = TestDataFactory.createPersonalAccount('TestLast1', '784-1234-5678901-1', '0501234567', 'test1@test.com');
        Account acc2 = TestDataFactory.createPersonalAccount('TestLast2', '784-1234-5678901-2', '0501234568', 'test2@test.com');
        insert new List<Account>{acc1, acc2};
        
        // Create test units
        Unit__c unit1 = TestDataFactory.createUnit(project.Id, 'Unit-001', 'Available');
        Unit__c unit2 = TestDataFactory.createUnit(project.Id, 'Unit-002', 'Available');
        insert new List<Unit__c>{unit1, unit2};
        
        // Create test opportunities
        Opportunity opp1 = TestDataFactory.createOpportunity(acc1.Id, 'Loyalty', null, null, null, 'Closed Won', String.valueOf(Date.today().addDays(30)), 500000);
        Opportunity opp2 = TestDataFactory.createOpportunity(acc2.Id, 'Loyalty', null, null, null, 'Closed Won', String.valueOf(Date.today().addDays(30)), 600000);
        insert new List<Opportunity>{opp1, opp2};
        
        // Create sales orders
        SalesOrder__c so1 = TestDataFactory.createSalesOrder(acc1.Id, opp1.Id, 'Active', Date.today(), unit1.Id, 500000);
        SalesOrder__c so2 = TestDataFactory.createSalesOrder(acc2.Id, opp2.Id, 'Active', Date.today(), unit2.Id, 600000);
        insert new List<SalesOrder__c>{so1, so2};
        
        // Create service catalogs
        ServiceCatalog__c serviceCatalogPHPP = TestDataFactory.createServiceCatalog('Handover-PHPP', 'Sales', '', '', '', '', 'Handover_PHPP');
        serviceCatalogPHPP.ProcessFlowType__c = 'Handover';
        serviceCatalogPHPP.Active__c = true;
        insert serviceCatalogPHPP;
        
        ServiceCatalog__c serviceCatalogNonPHPP = TestDataFactory.createServiceCatalog('Handover', 'Sales', '', '', '', '', 'Handover');
        serviceCatalogNonPHPP.ProcessFlowType__c = 'Handover';
        serviceCatalogNonPHPP.Active__c = true;
        insert serviceCatalogNonPHPP;
        
        // Create service actions
        List<ServiceAction__c> serviceActions = new List<ServiceAction__c>();
        serviceActions.add(TestDataFactory.createServiceActionForHandover(serviceCatalogPHPP.Id, 'QA Snagging', 'Handover Team Task 1', 'QA Snagging', 'Handover Team', 1));
        serviceActions.add(TestDataFactory.createServiceActionForHandover(serviceCatalogPHPP.Id, 'QA De-Snagging', 'Handover Team Task 2', 'QA De-Snagging', 'Handover Team', 2));
        serviceActions.add(TestDataFactory.createServiceActionForHandover(serviceCatalogPHPP.Id, 'Settlement Follow up', 'CRM Team Task 1', 'Settlement Follow up', 'CRM', 2));
        serviceActions.add(TestDataFactory.createServiceActionForHandover(serviceCatalogPHPP.Id, 'Settlement Confirmation', 'Finance Team Task 1', 'Settlement Confirmation', 'Finance', 3));
        serviceActions.add(TestDataFactory.createServiceActionForHandover(serviceCatalogPHPP.Id, 'Pre CHO Check', 'Handover Team Task 2.1', 'Pre CHO Check', 'Handover Team', 4));
        serviceActions.add(TestDataFactory.createServiceActionForHandover(serviceCatalogPHPP.Id, 'Register Title Deed', 'Government Relation Team Task 1', 'Register Title Deed', 'Government Relation', 1));
        serviceActions.add(TestDataFactory.createServiceActionForHandover(serviceCatalogPHPP.Id, 'Transfer Utilities', 'CRM Team Task 4', 'Transfer Utilities', 'CRM', 2));
        serviceActions.add(TestDataFactory.createServiceActionForHandover(serviceCatalogPHPP.Id, 'NOC Internal Follow Up', 'CRM Team Task 3', 'NOC Internal Follow Up', 'CRM', 3));
        
        serviceActions.add(TestDataFactory.createServiceActionForHandover(serviceCatalogNonPHPP.Id, 'QA Snagging', 'Handover Team Task 1', 'QA Snagging', 'Handover Team', 1));
        serviceActions.add(TestDataFactory.createServiceActionForHandover(serviceCatalogNonPHPP.Id, 'QA De-Snagging', 'Handover Team Task 2', 'QA De-Snagging', 'Handover Team', 2));
        serviceActions.add(TestDataFactory.createServiceActionForHandover(serviceCatalogNonPHPP.Id, 'Settlement Follow up', 'CRM Team Task 1', 'Settlement Follow up', 'CRM', 2));
        serviceActions.add(TestDataFactory.createServiceActionForHandover(serviceCatalogNonPHPP.Id, 'Settlement Confirmation', 'Finance Team Task 1', 'Settlement Confirmation', 'Finance', 3));
        serviceActions.add(TestDataFactory.createServiceActionForHandover(serviceCatalogNonPHPP.Id, 'Pre CHO Check', 'Handover Team Task 2.1', 'Pre CHO Check', 'Handover Team', 4));
        serviceActions.add(TestDataFactory.createServiceActionForHandover(serviceCatalogNonPHPP.Id, 'NOC Internal Follow Up', 'CRM Team Task 3', 'NOC Internal Follow Up', 'CRM', 3));
        serviceActions.add(TestDataFactory.createServiceActionForHandover(serviceCatalogNonPHPP.Id, 'Register Title Deed', 'Government Relation Team Task 1', 'Register Title Deed', 'Government Relation', 1));
        serviceActions.add(TestDataFactory.createServiceActionForHandover(serviceCatalogNonPHPP.Id, 'Transfer Utilities', 'CRM Team Task 4', 'Transfer Utilities', 'CRM', 2));

        insert serviceActions;
        
        // Create handover records
        List<Handover__c> handovers = new List<Handover__c>();
        Handover__c ho1 = new Handover__c(
            Account__c = acc1.Id,
            Sales_Order__c = so1.Id,
            Unit__c = unit1.Id,
            Project__c = project.Id,
            ServiceCatalog__c = serviceCatalogPHPP.Id,
            Sub_Status__c = 'QA Snagging',
            HO_Agent_Assigned_User__c = UserInfo.getUserId(),
            CRM_Team_Assigned_User__c = UserInfo.getUserId(),
            Is_Manual__c = 'No'
        );
        Handover__c ho2 = new Handover__c(
            Account__c = acc2.Id,
            Sales_Order__c = so2.Id,
            Unit__c = unit2.Id,
            Project__c = project.Id,
            ServiceCatalog__c = serviceCatalogNonPHPP.Id,
            Sub_Status__c = 'QA Snagging',
            HO_Agent_Assigned_User__c = UserInfo.getUserId(),
            CRM_Team_Assigned_User__c = UserInfo.getUserId()
        );
        handovers.add(ho1);
        handovers.add(ho2);
        insert handovers;
        
        List<String> documentNames = new List<String>{
            'ADDC NOC',
            'QA Snagging Report',
            'Emirates ID',
            'SOA',
            'CHO Desnagging Report',
            'SPA',
            'Bank NOC',
            'Mortgage Contract',
            'Mortgage Cheque Copy',
            'Leasing ADDC NOC',
            'Bloom Title Deed',
            'Service Charge Clearance Letter',
            'QA Desnagging Report',
            'CHO Snagging Report',
            'Developer NOC',
            'KHO',
            'Handover Payment Attachment',
            'Passport',
            'Lease Agreement 1',
            'Title Deed',
            'Tawtheeq Registration Confirmation'
        };

    	List<Document__c> docsToInsert = new List<Document__c>();
    
        for (String docName : documentNames) {
            Document__c doc1 = new Document__c();
            doc1.Document_Name__c = docName;
            doc1.Handover__c = ho1.Id; 
            doc1.ContentDocumentId__c = '069FV001xfB1tngYAB';
            docsToInsert.add(doc1);
        }

        // Bulk insert all documents in one DML call
        insert docsToInsert;
        
        DocumentType__c docType = new DocumentType__c(
            Active__c = true,
            IsDocgen__c = true,
            DigitalSignature__c = true,
            ObjectType__c = 'Handover',
            Type__c = 'Developer NOC',
            Document_Digital_Name__c = 'Developer_NOC',
            Document_Output_Name__c = 'Developer_NOC.pdf'
        );
        insert docType;
    }
    
    @isTest
    static void testHandoverSendOrientationBatch() {
        Project__c project = new Project__c(
            Name = 'Test Project',
            Office_Location__c = 'Test Location'
        );
        insert project;
        
        Unit__c unit = new Unit__c(
            Name = 'Unit Test A1435',
            SAP_Unit_Number__c = 'SAP12345',
            Status__c = 'Available'
        );
        insert unit;
        
        Handover__c handover = new Handover__c(
            Name = 'Test Handover',
            Customer_Email__c = 'test@example.com',
            Is_Orientation_Letter_Sent__c = false,
            Is_BCC_Announcement_Sent__c = false,
            Unit__c = unit.Id,
            Project__c = project.Id,
            Customer_Availability_for_CHO__c = 'Customer Available',
            HO_Agent_Assigned_User__c = UserInfo.getUserId()
        );
        insert handover;
        
        Event evn = new Event();
        evn.WhatId = handover.Id;
        evn.Subject = 'Other';
        evn.StartDateTime = DateTime.newInstance(2024, 6, 20, 8, 43, 38); 
        evn.EndDateTime = DateTime.newInstance(2024, 6, 22, 8, 43, 38); 
        evn.CurrencyIsoCode ='AED';
        insert evn;
        
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'Full Guideline Document';
        contentVersion.PathOnClient = 'FullGuidelineDocument.pdf';
        contentVersion.VersionData = Blob.valueOf('Full Guideline Document');
        insert contentVersion;
        system.debug('contentVersion'+contentVersion);
        ContentVersion con = [SELECT Id, ContentDocumentId FROM ContentVersion where Id = : contentVersion.Id];
        system.debug('con version'+con);
        
        Document__c dc= new Document__c();
        dc.Document_Name__c = 'Full Guideline Document';
        dc.Handover__c = handover.Id;
        dc.ContentDocumentId__c = con.ContentDocumentId;
        dc.Content_Version_Id__c = con.Id;
        insert dc;

        System.debug('DCCCCC=====> ' + dc);
        
        List<Id> handoverIds = new List<Id>{handover.Id};
        
        HandoverSendOrientationBatch batch = new HandoverSendOrientationBatch(handoverIds);

        Test.startTest();
        Database.executeBatch(batch, 1);
        Test.stopTest();

        /*
        Handover__c updatedHandover = [SELECT Id, Unit_is_Ready__c, Is_Orientation_Letter_Sent__c, Home_Orientation_Invitation_Date__c, Sub_Status__c FROM Handover__c WHERE Id = :testHandover.Id];
        
        System.assertEquals(true, updatedHandover.Unit_is_Ready__c, 'Unit_is_Ready__c should be true.');
        System.assertEquals(true, updatedHandover.Is_Orientation_Letter_Sent__c, 'Is_Orientation_Letter_Sent__c should be true.');
        System.assertEquals(Date.Today(), updatedHandover.Home_Orientation_Invitation_Date__c, 'Home_Orientation_Invitation_Date__c should be today\'s date.');
        System.assertEquals(Constants.Handover_Sub_Status_Home_Orientation_Sent, updatedHandover.Sub_Status__c, 'Sub_Status__c should be set to Handover_Sub_Status_Home_Orientation_Sent.');*/
        
    }
    
    @isTest
    static void testHandoverSendOrientationBatchException() {
        Project__c project = new Project__c(
            Name = 'Test Project',
            Office_Location__c = 'Test Location'
        );
        insert project;
        
        Unit__c unit = new Unit__c(
            Name = 'Unit Test A1435',
            SAP_Unit_Number__c = 'SAP12345',
            Status__c = 'Available'
        );
        insert unit;
        
        Handover__c handover = new Handover__c(
            Name = 'Test Handover',
            Customer_Email__c = 'test@example.com',
            Is_Orientation_Letter_Sent__c = false,
            Is_BCC_Announcement_Sent__c = false,
            Unit__c = unit.Id,
            Project__c = project.Id,
            Customer_Availability_for_CHO__c = 'Customer Available'
           // HO_Agent_Assigned_User__c = UserInfo.getUserId()
        );
        insert handover;
        
        Event evn = new Event();
        evn.WhatId = handover.Id;
        evn.Subject = 'Other';
        evn.StartDateTime = DateTime.newInstance(2024, 6, 20, 8, 43, 38); 
        evn.EndDateTime = DateTime.newInstance(2024, 6, 22, 8, 43, 38); 
        evn.CurrencyIsoCode ='AED';
        insert evn;
        
        List<Id> handoverIds = new List<Id>{handover.Id};
        
        HandoverSendOrientationBatch batch = new HandoverSendOrientationBatch(handoverIds);

        Test.startTest();
        Database.executeBatch(batch, 1);
        Test.stopTest();

        /*
        Handover__c updatedHandover = [SELECT Id, Unit_is_Ready__c, Is_Orientation_Letter_Sent__c, Home_Orientation_Invitation_Date__c, Sub_Status__c FROM Handover__c WHERE Id = :testHandover.Id];
        
        System.assertEquals(true, updatedHandover.Unit_is_Ready__c, 'Unit_is_Ready__c should be true.');
        System.assertEquals(true, updatedHandover.Is_Orientation_Letter_Sent__c, 'Is_Orientation_Letter_Sent__c should be true.');
        System.assertEquals(Date.Today(), updatedHandover.Home_Orientation_Invitation_Date__c, 'Home_Orientation_Invitation_Date__c should be today\'s date.');
        System.assertEquals(Constants.Handover_Sub_Status_Home_Orientation_Sent, updatedHandover.Sub_Status__c, 'Sub_Status__c should be set to Handover_Sub_Status_Home_Orientation_Sent.');*/
        
    }
}