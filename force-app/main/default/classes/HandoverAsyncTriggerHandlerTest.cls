@isTest
public class HandoverAsyncTriggerHandlerTest {
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
    
	@istest
    static void TestMethod1(){
        Test.enableChangeDataCapture();

        // Test data for Project__c and related Units
        Account account = TestDataFactory.createPersonalAccount('Lastname', '01010101', '1234567890', 'test@gmail.com');
        account.CustomerType__c = 'Resident';
        INSERT account;

        Id accRecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Broker Agency').getRecordTypeId();
        Account acc = new Account(Name = 'Test Account', RecordTypeId= accRecordTypeId);
        insert acc;
        
        //Test data for Project__c and related Units
        Project__c project = TestDataFactory.createProject('ProjectTest', Date.today() - 1);
        insert project;
        
        Unit__c u = TestDataFactory.createUnit(project.Id, 'A1-G01', 'Unassigned');
        u.Project__c = project.Id;
        u.RegistrationDate__c = Date.today();
        insert u;
        
        Contact con1 = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@example.com',
            MobileCountryCode__c = '+1',
            MobilePhone = '1234567890',
            AccountId = acc.Id,
            RecordtypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId()
        );
        insert con1;
        
        Opportunity tempOpp = new Opportunity(
            Name ='tempOpp',
            StageName ='New',
            CloseDate =system.today(),
            LeadChannel__c ='Walk in',
            AccountId = account.Id,
            WinReason__c ='Loyalty',
            BrokerAgencyAccount__c = acc.Id,
            BrokerAgentContact__c = con1.Id
        );
        insert tempOpp;
        
        Handover__c hand = new Handover__c();
        hand.Status__c = 'In Progress';
        hand.Unit__c = u.Id;  
        insert hand;  
        
        Handover__ChangeEvent event = new Handover__ChangeEvent();
        
        Test.getEventBus().deliver();
        
        //Delete the record
        Test.enableChangeDataCapture();
        DELETE hand;
        Test.getEventBus().deliver();
        //UnDelete the record
        Test.enableChangeDataCapture();
       	UNDELETE hand;
        Test.getEventBus().deliver();
        //Update the record
        Test.enableChangeDataCapture();
        hand.Sub_Status__c = 'Handover Completed';
       	UPDATE hand;
        Test.getEventBus().deliver();
        
        // Set the ChangeEventHeader
        EventBus.ChangeEventHeader header = new EventBus.ChangeEventHeader();
        header.changeType = 'CREATE'; // Change to 'UPDATE', 'DELETE', or 'UNDELETE' to test other scenarios
        event.ChangeEventHeader = header;
        //  EventBus.Publish(event);
        
        
        // Set the ChangeEventHeader
        EventBus.ChangeEventHeader header2 = new EventBus.ChangeEventHeader();
        header2.changeType = 'UPDATE'; // Change to 'UPDATE', 'DELETE', or 'UNDELETE' to test other scenarios
        event.ChangeEventHeader = header2;
        EventBus.ChangeEventHeader header3 = new EventBus.ChangeEventHeader();
        header3.changeType = 'DELETE'; // Change to 'UPDATE', 'DELETE', or 'UNDELETE' to test other scenarios
        event.ChangeEventHeader = header3;
        EventBus.ChangeEventHeader header4 = new EventBus.ChangeEventHeader();
        header4.changeType = 'UNDELETE'; // Change to 'UPDATE', 'DELETE', or 'UNDELETE' to test other scenarios
        event.ChangeEventHeader = header4;
        test.starttest();
        
        
        HandoverAsyncTriggerHandler hoAsyncHandler = new HandoverAsyncTriggerHandler(); 
        //ias.changeTypeCreate(new List<Id>{Llist[0].Id});
        //ias.changeTypeDelete(new List<Id>{Llist[0].Id});
       // ias.changeTypeUndelete(new List<Id>{Llist[0].Id});
       // ias.changeTypeUpdate(new List<Id>{Llist[0].Id});
        
        //soAsyncHandler.isDisabled();
        //AsyncTriggerDispatcher.disableAllAsyncTriggers();
        //AsyncTriggerDispatcher.enableAllAsyncTriggers();
        //AsyncTriggerDispatcher.run(null);
        
        test.stoptest();
    }
}