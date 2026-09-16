@isTest
private class HandoverHandlerTest {

    @TestSetup
    static void setupTestData() {
        Project__c project = TestDataFactory.createProject('Test Project', Date.today());
        insert project;

        Account acc1 = TestDataFactory.createPersonalAccount('TestLast1', '784-1234-5678901-1', '0501234567', 'test1@test.com');
        Account acc2 = TestDataFactory.createPersonalAccount('TestLast2', '784-1234-5678901-2', '0501234568', 'test2@test.com');
        insert new List<Account>{acc1, acc2};

        HandoverPhase__c handoverPhase = new HandoverPhase__c(
            Name = 'Test Phase',
            Project__c = project.Id,
            SkipHandoverCHOTasks__c = false
        );
        insert handoverPhase;

        Unit__c unit1 = TestDataFactory.createUnit(project.Id, 'Unit-001', 'Available');
        unit1.HandoverPhase__c = handoverPhase.Id;
        Unit__c unit2 = TestDataFactory.createUnit(project.Id, 'Unit-002', 'Available');
        unit2.HandoverPhase__c = handoverPhase.Id;
        insert new List<Unit__c>{unit1, unit2};

        Opportunity opp1 = TestDataFactory.createOpportunity(acc1.Id, 'Loyalty', null, null, null, 'Closed Won', String.valueOf(Date.today().addDays(30)), 500000);
        Opportunity opp2 = TestDataFactory.createOpportunity(acc2.Id, 'Loyalty', null, null, null, 'Closed Won', String.valueOf(Date.today().addDays(30)), 600000);
        insert new List<Opportunity>{opp1, opp2};

        SalesOrder__c so1 = TestDataFactory.createSalesOrder(acc1.Id, opp1.Id, 'Active', Date.today(), unit1.Id, 500000);
        SalesOrder__c so2 = TestDataFactory.createSalesOrder(acc2.Id, opp2.Id, 'Active', Date.today(), unit2.Id, 600000);
        insert new List<SalesOrder__c>{so1, so2};

        ServiceCatalog__c serviceCatalogPHPP = TestDataFactory.createServiceCatalog('Handover-PHPP', 'Sales', '', '', '', '', 'PHPP');
        serviceCatalogPHPP.ProcessFlowType__c = 'Handover';
        serviceCatalogPHPP.Active__c = true;
        insert serviceCatalogPHPP;

        ServiceCatalog__c serviceCatalogNonPHPP = TestDataFactory.createServiceCatalog('Handover', 'Sales', '', '', '', '', 'Non PHPP');
        serviceCatalogNonPHPP.ProcessFlowType__c = 'Handover';
        serviceCatalogNonPHPP.Active__c = true;
        insert serviceCatalogNonPHPP;

        List<ServiceAction__c> serviceActions = new List<ServiceAction__c>();
        serviceActions.add(TestDataFactory.createServiceActionForHandover(serviceCatalogPHPP.Id, 'QA Snagging', 'Handover Team Task 1', 'QA Snagging', 'Handover Team', 1));
        serviceActions.add(TestDataFactory.createServiceActionForHandover(serviceCatalogPHPP.Id, 'QA De-Snagging', 'Handover Team Task 2', 'QA De-Snagging', 'Handover Team', 2));
        serviceActions.add(TestDataFactory.createServiceActionForHandover(serviceCatalogPHPP.Id, 'Settlement Follow up', 'CRM Team Task 1', 'Settlement Follow up', 'CRM', 2));
        serviceActions.add(TestDataFactory.createServiceActionForHandover(serviceCatalogPHPP.Id, 'Settlement Confirmation', 'Finance Team Task 1', 'Settlement Confirmation', 'Finance', 3));
        serviceActions.add(TestDataFactory.createServiceActionForHandover(serviceCatalogPHPP.Id, 'Pre CHO Check', 'Handover Team Task 2.1', 'Pre CHO Check', 'Handover Team', 4));
        serviceActions.add(TestDataFactory.createServiceActionForHandover(serviceCatalogPHPP.Id, 'CHO Snagging', 'Handover Team Task 2.2', 'CHO Snagging', 'Handover Team', 3));
        serviceActions.add(TestDataFactory.createServiceActionForHandover(serviceCatalogPHPP.Id, 'CHO De-Snagging', 'Handover Team Task 2.3', 'CHO De-Snagging', 'Handover Team', 2));
        serviceActions.add(TestDataFactory.createServiceActionForHandover(serviceCatalogPHPP.Id, 'Register Title Deed', 'Government Relation Team Task 1', 'Register Title Deed', 'Government Relation', 1));
        serviceActions.add(TestDataFactory.createServiceActionForHandover(serviceCatalogPHPP.Id, 'Transfer Utilities', 'CRM Team Task 4', 'Transfer Utilities', 'CRM', 2));
        serviceActions.add(TestDataFactory.createServiceActionForHandover(serviceCatalogPHPP.Id, 'Generate Bank NOC', 'CRM Team Task 3', 'Generate Bank NOC', 'CRM', 3));

        serviceActions.add(TestDataFactory.createServiceActionForHandover(serviceCatalogNonPHPP.Id, 'QA Snagging', 'Handover Team Task 1', 'QA Snagging', 'Handover Team', 1));
        serviceActions.add(TestDataFactory.createServiceActionForHandover(serviceCatalogNonPHPP.Id, 'QA De-Snagging', 'Handover Team Task 2', 'QA De-Snagging', 'Handover Team', 2));
        serviceActions.add(TestDataFactory.createServiceActionForHandover(serviceCatalogNonPHPP.Id, 'Settlement Follow up', 'CRM Team Task 1', 'Settlement Follow up', 'CRM', 2));
        serviceActions.add(TestDataFactory.createServiceActionForHandover(serviceCatalogNonPHPP.Id, 'Settlement Confirmation', 'Finance Team Task 1', 'Settlement Confirmation', 'Finance', 3));
        serviceActions.add(TestDataFactory.createServiceActionForHandover(serviceCatalogNonPHPP.Id, 'Pre CHO Check', 'Handover Team Task 2.1', 'Pre CHO Check', 'Handover Team', 4));
        serviceActions.add(TestDataFactory.createServiceActionForHandover(serviceCatalogNonPHPP.Id, 'CHO Snagging', 'Handover Team Task 2.2', 'CHO Snagging', 'Handover Team', 3));
        serviceActions.add(TestDataFactory.createServiceActionForHandover(serviceCatalogNonPHPP.Id, 'CHO De-Snagging', 'Handover Team Task 2.3', 'CHO De-Snagging', 'Handover Team', 2));
        serviceActions.add(TestDataFactory.createServiceActionForHandover(serviceCatalogNonPHPP.Id, 'Generate Bank NOC', 'CRM Team Task 3', 'Generate Bank NOC', 'CRM', 3));
        serviceActions.add(TestDataFactory.createServiceActionForHandover(serviceCatalogNonPHPP.Id, 'Register Title Deed', 'Government Relation Team Task 1', 'Register Title Deed', 'Government Relation', 1));
        serviceActions.add(TestDataFactory.createServiceActionForHandover(serviceCatalogNonPHPP.Id, 'Transfer Utilities', 'CRM Team Task 4', 'Transfer Utilities', 'CRM', 2));

        insert serviceActions;
		List<ServiceAction__c> targetServiceActions = [
                SELECT Id, Name, ServiceCatalog__c
                FROM ServiceAction__c 
                WHERE TaskSubType__c = 'Handover Team Task 2.2'
            ];
        System.debug(targetServiceActions);
        List<Handover__c> handovers = new List<Handover__c>();
        Handover__c ho1 = new Handover__c(
            Account__c = acc1.Id,
            Sales_Order__c = so1.Id,
            Unit__c = unit1.Id,
            Project__c = project.Id,
            ServiceCatalog__c = serviceCatalogPHPP.Id,
            Handover_Phase__c = handoverPhase.Id,
            Sub_Status__c = 'QA Snagging',
            HandoverType__c = 'PHPP',
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
            Handover_Phase__c = handoverPhase.Id,
            Sub_Status__c = 'QA Snagging',
            HandoverType__c = 'Non PHPP',
            HO_Agent_Assigned_User__c = UserInfo.getUserId(),
            CRM_Team_Assigned_User__c = UserInfo.getUserId()
        );
        handovers.add(ho1);
        handovers.add(ho2);
        insert handovers;
        List<Handover__c> hos = [SELECT Id, ServiceCatalog__c FROm Handover__c where Id =:ho1.Id];
        System.debug(hos[0].ServiceCatalog__c);

        List<String> documentNames = new List<String>{
            'ADDC NOC', 'QA Snagging Report', 'Emirates Id', 'SOA', 'CHO Desnagging Report',
            'SPA', 'Bank NOC', 'Mortgage Contract', 'Mortgage Cheque Copy', 'Leasing ADDC NOC',
            'Bloom Title Deed', 'Service Charge Clearance Letter', 'QA Desnagging Report',
            'CHO Snagging Report', 'Developer NOC', 'KHO', 'Handover Payment Attachment',
            'Passport', 'Lease Agreement 1', 'Title Deed', 'Tawtheeq Registration Confirmation',
            'HO Undertaking Letter'
        };

        List<Document__c> docsToInsert = new List<Document__c>();
        for (String docName : documentNames) {
            Document__c doc1 = new Document__c();
            doc1.Document_Name__c = docName;
            doc1.Handover__c = ho1.Id;
            doc1.ContentDocumentId__c = '069FV001xfB1tngYAB';
            docsToInsert.add(doc1);
        }
        insert docsToInsert;

        Document__c salesOrderTitleDeedDoc = new Document__c(
            SalesOrder__c = so1.Id,
            Document_Name__c = 'Title Deed',
            ContentDocumentId__c = '069FV001xfB1tngYAB'
        );
        insert salesOrderTitleDeedDoc;

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

        ServiceCatalog__c testServiceCatalog = new ServiceCatalog__c(
            Name = 'Test Service Catalog',
            Type__c = 'Service Request',
            Category__c = 'Financial - Payment Service',
            SubCategory__c = 'Postpone/Defer Payment',
            RecordTypeDevName__c = 'DefaultUnit'
        );
        insert testServiceCatalog;

        ServiceAction__c testServiceAction1 = new ServiceAction__c(
            ServiceCatalog__c = testServiceCatalog.Id,
            TaskType__c = 'Default Unit',
            TaskSubType__c = 'Finance Team Task 1',
            TaskSubject__c = 'Finance Team Task 1',
            Due_in_days__c = 2,
            Order__c = 1
        );
        insert testServiceAction1;

        ServiceAction__c testServiceAction2 = new ServiceAction__c(
            ServiceCatalog__c = testServiceCatalog.Id,
            TaskType__c = 'Default Unit',
            TaskSubType__c = 'Legal Team Task 1',
            TaskSubject__c = 'Legal Team Task 1',
            Due_in_days__c = 2,
            Order__c = 7
        );
        insert testServiceAction2;

        ServiceCatalog__c tawtheeqEnrollmentServiceCatalog = new ServiceCatalog__c(
            Name = 'Tawtheeq Enrollment Service Catalog',
            Type__c = 'Service Request',
            Category__c = 'CRM Services',
            SubCategory__c = 'Tawtheeq Enrollment',
            Active__c = true,
            RecordTypeDevName__c = 'ServiceRequest'
        );
        insert tawtheeqEnrollmentServiceCatalog;

        Id phppRecordTypeId = Schema.SObjectType.Handover__c
            .getRecordTypeInfosByDeveloperName()
            .get('Handover_PHPP')
            .getRecordTypeId();

        Unit__c unit3 = TestDataFactory.createUnit(project.Id, 'Unit-003', 'Available');
        unit3.HandoverPhase__c = handoverPhase.Id;
        Unit__c unit4 = TestDataFactory.createUnit(project.Id, 'Unit-004', 'Available');
        unit4.HandoverPhase__c = handoverPhase.Id;
        insert new List<Unit__c>{unit3, unit4};

        SalesOrder__c so3 = TestDataFactory.createSalesOrder(acc1.Id, opp1.Id, 'Active', Date.today(), unit3.Id, 500000);
        SalesOrder__c so4 = TestDataFactory.createSalesOrder(acc1.Id, opp1.Id, 'Active', Date.today(), unit4.Id, 500000);
        insert new List<SalesOrder__c>{so3, so4};

        Handover__c ho3 = new Handover__c(
            Account__c = acc1.Id,
            Sales_Order__c = so3.Id,
            Unit__c = unit3.Id,
            Project__c = project.Id,
            ServiceCatalog__c = serviceCatalogPHPP.Id,
            Handover_Phase__c = handoverPhase.Id,
            Sub_Status__c = 'QA Snagging',
            HandoverType__c = 'PHPP',
            RecordTypeId = phppRecordTypeId,
            HO_Agent_Assigned_User__c = UserInfo.getUserId(),
            CRM_Team_Assigned_User__c = UserInfo.getUserId()
        );

        Handover__c ho4 = new Handover__c(
            Account__c = acc1.Id,
            Sales_Order__c = so4.Id,
            Unit__c = unit4.Id,
            Project__c = project.Id,
            ServiceCatalog__c = serviceCatalogPHPP.Id,
            Handover_Phase__c = handoverPhase.Id,
            Sub_Status__c = 'QA Snagging',
            HandoverType__c = 'PHPP',
            RecordTypeId = phppRecordTypeId,
            HO_Agent_Assigned_User__c = UserInfo.getUserId(),
            CRM_Team_Assigned_User__c = UserInfo.getUserId()
        );
        insert new List<Handover__c>{ho3, ho4};

        List<Document__c> ho3Docs = new List<Document__c>();
        for (String docName : documentNames) {
            Document__c doc3 = new Document__c();
            doc3.Document_Name__c = docName;
            doc3.Handover__c = ho3.Id;
            doc3.ContentDocumentId__c = '069FV001xfB1tngYAB';
            ho3Docs.add(doc3);
        }
        insert ho3Docs;
    }

    private static Handover__c getHo1() {
        return [SELECT Id, Name,FinanceTeamAssingedUser__c,PropertyHomeOrientationWOCustomer__c,PropertyHomeOrientationByBloom__c,PropertyHomeOrientationReport_Sent__c,HasCHODesnaggingemailsent__c, HO_Agent_Assigned_User__c, Unit__r.Status__c, OwnerId, Is_Property_keys_given__c, Date__c,
            Project__c, Project_Name__c, Customer_Availability_for_CHO__c, Sales_Order__c, Sales_Order__r.NetAmount__c,
            Unit__r.UnitType__c, UnitCategory__c, Mortgage_Value__c, Current_USer_Profile__c, Next_Step__c, ServiceCatalog__c,
            Account__c, Account__r.PersonEmail, Account__r.FirstName, Account__r.LastName, Unit__c, Unit__r.UnitNumber__c,
            Unit__r.HO_Agent__c, Previous_HO_Status__c, Sub_Status__c, Orientation_Appointment_Status__c,
            Is_Notice_of_Completion_Sent__c, Payment_Type__c, RecordTypeId, Is_Appointment_Booked__c, Payment_Settled__c,
            Payment_Date__c, HandoverType__c, Handover_Phase__c, Handover_Phase__r.SkipHandoverCHOTasks__c,
            Handover_Phase__r.ExcludedHandoverStages__c, Property_Enrollment_Under_Tawtheeq__c,
            Property_Enrollment_Under_Tawtheeq_Accou__c, CRM_Team_Assigned_User__c
            FROM Handover__c WHERE Unit__r.Name = 'Unit-001' LIMIT 1];
    }

    private static Handover__c getHo2() {
        return [SELECT Id, Name, HO_Agent_Assigned_User__c, Unit__r.Status__c, OwnerId, Is_Property_keys_given__c, Date__c,
            Project__c, Project_Name__c, Customer_Availability_for_CHO__c, Sales_Order__c, Sales_Order__r.NetAmount__c,
            Unit__r.UnitType__c, UnitCategory__c, Mortgage_Value__c, Current_USer_Profile__c, Next_Step__c, ServiceCatalog__c,
            Account__c, Account__r.PersonEmail, Account__r.FirstName, Account__r.LastName, Unit__c, Unit__r.UnitNumber__c,
            Unit__r.HO_Agent__c, Previous_HO_Status__c, Sub_Status__c, Orientation_Appointment_Status__c,
            Is_Notice_of_Completion_Sent__c, Payment_Type__c, RecordTypeId, Is_Appointment_Booked__c, Payment_Settled__c,
            Payment_Date__c, HandoverType__c, Handover_Phase__c, Handover_Phase__r.SkipHandoverCHOTasks__c,
            Handover_Phase__r.ExcludedHandoverStages__c, Property_Enrollment_Under_Tawtheeq__c,
            Property_Enrollment_Under_Tawtheeq_Accou__c, CRM_Team_Assigned_User__c
            FROM Handover__c WHERE Unit__r.Name = 'Unit-002' LIMIT 1];
    }

    private static Handover__c getHo3() {
        return [SELECT Id, Name, HO_Agent_Assigned_User__c, Unit__r.Status__c, OwnerId, Is_Property_keys_given__c, Date__c,
            Project__c, Project_Name__c, Customer_Availability_for_CHO__c, Sales_Order__c, Sales_Order__r.NetAmount__c,
            Unit__r.UnitType__c, UnitCategory__c, Mortgage_Value__c, Current_USer_Profile__c, Next_Step__c, ServiceCatalog__c,
            Account__c, Account__r.PersonEmail, Account__r.FirstName, Account__r.LastName, Unit__c, Unit__r.UnitNumber__c,
            Unit__r.HO_Agent__c, Previous_HO_Status__c, Sub_Status__c, Orientation_Appointment_Status__c,
            Is_Notice_of_Completion_Sent__c, Payment_Type__c, RecordTypeId, Is_Appointment_Booked__c, Payment_Settled__c,
            Payment_Date__c, HandoverType__c, Handover_Phase__c, Handover_Phase__r.SkipHandoverCHOTasks__c,
            Handover_Phase__r.ExcludedHandoverStages__c, Property_Enrollment_Under_Tawtheeq__c,
            Property_Enrollment_Under_Tawtheeq_Accou__c, CRM_Team_Assigned_User__c
            FROM Handover__c WHERE Unit__r.Name = 'Unit-003' LIMIT 1];
    }

    private static Handover__c getHo4() {
        return [SELECT Id, Name, HO_Agent_Assigned_User__c, Unit__r.Status__c, OwnerId, Is_Property_keys_given__c, Date__c,
            Project__c, Project_Name__c, Customer_Availability_for_CHO__c, Sales_Order__c, Sales_Order__r.NetAmount__c,
            Unit__r.UnitType__c, UnitCategory__c, Mortgage_Value__c, Current_USer_Profile__c, Next_Step__c, ServiceCatalog__c,
            Account__c, Account__r.PersonEmail, Account__r.FirstName, Account__r.LastName, Unit__c, Unit__r.UnitNumber__c,
            Unit__r.HO_Agent__c, Previous_HO_Status__c, Sub_Status__c, Orientation_Appointment_Status__c,
            Is_Notice_of_Completion_Sent__c, Payment_Type__c, RecordTypeId, Is_Appointment_Booked__c, Payment_Settled__c,
            Payment_Date__c, HandoverType__c, Handover_Phase__c, Handover_Phase__r.SkipHandoverCHOTasks__c,
            Handover_Phase__r.ExcludedHandoverStages__c, Property_Enrollment_Under_Tawtheeq__c,
            Property_Enrollment_Under_Tawtheeq_Accou__c, CRM_Team_Assigned_User__c
            FROM Handover__c WHERE Unit__r.Name = 'Unit-004' LIMIT 1];
    }

    @isTest
    static void testGetInstance() {
        HandoverHandler h1 = HandoverHandler.getInstance();
        HandoverHandler h2 = HandoverHandler.getInstance();
        System.assertEquals(h1, h2);
    }

    @isTest
    static void testConstructor() {
        HandoverHandler h = new HandoverHandler();
        System.assertNotEquals(null, h);
    }

    @isTest
    static void testValidateHandoverNextStep_WithOpenTasks() {
        Handover__c ho = getHo1();
        Task t = new Task(Subject = 'Test Task', WhatId = ho.Id, Status = 'Open');
        insert t;
        Map<String, Object> resp = HandoverHandler.getInstance().validateHandoverNextStep(ho, false);
        System.assertNotEquals(null, resp);
    }

    @isTest
    static void testValidateHandoverNextStep_PHPP() {
        /*
         * FIX: multiple Handover__c updates in one test method re-fire
         * HandoverTrigger.afterUpdate repeatedly, exceeding 100 SOQL queries
         * via HandoverTriggerHelper.updateInstallmentLineItems /
         * updateServiceChargeDatesOnSalesOrder. This test targets
         * HandoverHandler logic only, so the unrelated trigger is disabled.
         */
        Boolean previousTriggerState = HandoverTriggerHandler.isTriggerDisabled;
        HandoverTriggerHandler.isTriggerDisabled = true;
        try {
            Handover__c ho = getHo1();
            ho.Sub_Status__c = 'Settlement Confirmation';
            update ho;
            Map<String, Object> resp = HandoverHandler.getInstance().validateHandoverNextStep(ho, false);
            System.assertNotEquals(null, resp);
        } finally {
            HandoverTriggerHandler.isTriggerDisabled = previousTriggerState;
        }
    }

    @isTest
    static void testValidateHandoverNextStep_NonPHPP() {
        Boolean previousTriggerState = HandoverTriggerHandler.isTriggerDisabled;
        HandoverTriggerHandler.isTriggerDisabled = true;
        try {
            Handover__c ho = getHo2();
            Task tsk = new Task(Subject = 'Settlement Confirmation', WhatId = ho.Id, SubType__c = 'Finance Team Task 1', Status = 'Completed');
            insert tsk;
            Task tsk2 = new Task(Subject = 'Settlement Follow up', WhatId = ho.Id, SubType__c = 'CRM Team Task 1', Status = 'Completed');
            insert tsk2;

            ho.Previous_HO_Status__c = 'Send Handover Notice';
            ho.Sub_Status__c = 'Book Appointment with Customer';
            update ho;
            HandoverHandler.getInstance().validateHandoverNextStep(ho, false);
            ho.Previous_HO_Status__c = 'Book Appointment with Customer';
            ho.Sub_Status__c = 'Settlement Follow up';
            update ho;
            Map<String, Object> resp = HandoverHandler.getInstance().validateHandoverNextStep(ho, false);
            ho.Previous_HO_Status__c = 'Settlement Follow up';
            ho.Sub_Status__c = 'Settlement Confirmation';
            update ho;
            HandoverHandler.getInstance().validateHandoverNextStep(ho, false);
            System.assertNotEquals(null, resp);
        } finally {
            HandoverTriggerHandler.isTriggerDisabled = previousTriggerState;
        }
    }

    @isTest
    static void testCreateNewAndCloseCurrentTask_EmptyList() {
        HandoverHandler.getInstance().createNewAndCloseCurrentTask(new List<Handover__c>(), true);
        System.assert(true);
    }

    @isTest
    static void testProcessHandoversAndHandleNextActions_QADeSnagging() {
        Boolean previousTriggerState = HandoverTriggerHandler.isTriggerDisabled;
        HandoverTriggerHandler.isTriggerDisabled = true;
        try {
            Handover__c ho = getHo1();
            ho.Sub_Status__c = 'QA Snagging';
            update ho;
            HandoverHandler.getInstance().createNewAndCloseCurrentTask(new List<Handover__c>{ho}, false);
            ho.Sub_Status__c = 'QA De-Snagging';
            update ho;
            HandoverHandler.getInstance().createNewAndCloseCurrentTask(new List<Handover__c>{ho}, false);
            System.assert(true);
        } finally {
            HandoverTriggerHandler.isTriggerDisabled = previousTriggerState;
        }
    }

    @isTest
    static void testProcessHandoversAndHandleNextActions_SettlementConfirmation() {
        Boolean previousTriggerState = HandoverTriggerHandler.isTriggerDisabled;
        HandoverTriggerHandler.isTriggerDisabled = true;
        try {
            Handover__c ho = getHo1();
            ho.Sub_Status__c = 'Settlement Confirmation';
            update ho;
            Map<Id, Map<String, ServiceAction__c>> emptyMap = new Map<Id, Map<String, ServiceAction__c>>();
            HandoverHandler.getInstance().processHandoversAndHandleNextActions(new List<Handover__c>{ho}, emptyMap, true);
            System.assert(true);
        } finally {
            HandoverTriggerHandler.isTriggerDisabled = previousTriggerState;
        }
    }

    @isTest
    static void testProcessHandoversAndHandleNextActions_HandoverCompleted() {
        Boolean previousTriggerState = HandoverTriggerHandler.isTriggerDisabled;
        HandoverTriggerHandler.isTriggerDisabled = true;
        try {
            Handover__c ho = getHo1();
            ho.Sub_Status__c = 'Register Title Deed';
            update ho;
            HandoverHandler.getInstance().createNewAndCloseCurrentTask(new List<Handover__c>{ho}, false);
            ho.Sub_Status__c = 'Transfer Utilities';
            update ho;
            HandoverHandler.getInstance().createNewAndCloseCurrentTask(new List<Handover__c>{ho}, false);
            Handover__c updatedHo = [SELECT Status__c FROM Handover__c WHERE Id = :ho.Id];
        } finally {
            HandoverTriggerHandler.isTriggerDisabled = previousTriggerState;
        }
    }

    @isTest
    static void testProcessHandoversAndHandleNextActions_HandoverCompletedDirect() {
        Boolean previousTriggerState = HandoverTriggerHandler.isTriggerDisabled;
        HandoverTriggerHandler.isTriggerDisabled = true;
        try {
            Handover__c ho = getHo1();
            ho.Sub_Status__c = 'Handover Completed';
            update ho;
            Map<Id, Map<String, ServiceAction__c>> emptyMap = new Map<Id, Map<String, ServiceAction__c>>();
            HandoverHandler.getInstance().processHandoversAndHandleNextActions(new List<Handover__c>{ho}, emptyMap, true);
            Handover__c updatedHo = [SELECT Status__c FROM Handover__c WHERE Id = :ho.Id];
            System.assertEquals('Completed', updatedHo.Status__c, 'Status should be Completed');
        } finally {
            HandoverTriggerHandler.isTriggerDisabled = previousTriggerState;
        }
    }

    @isTest
    static void testProcessHandoversAndHandleNextActions_SettlementFollowUpPreCHO() {
        Boolean previousTriggerState = HandoverTriggerHandler.isTriggerDisabled;
        HandoverTriggerHandler.isTriggerDisabled = true;
        try {
            Handover__c ho = getHo1();
            ho.Sub_Status__c = 'Settlement Follow up';
            update ho;
            HandoverHandler.getInstance().createNewAndCloseCurrentTask(new List<Handover__c>{ho}, false);
            System.assert(true);
        } finally {
            HandoverTriggerHandler.isTriggerDisabled = previousTriggerState;
        }
    }

    @isTest
    static void testProcessHandoversAndHandleNextActions_NOCInternalFollowUp() {
        Boolean previousTriggerState = HandoverTriggerHandler.isTriggerDisabled;
        HandoverTriggerHandler.isTriggerDisabled = true;
        try {
            Handover__c ho = getHo1();
            ho.Sub_Status__c = 'Generate Bank NOC';
            update ho;
            HandoverHandler.getInstance().createNewAndCloseCurrentTask(new List<Handover__c>{ho}, false);
            HandoverHandler.getInstance().createPotentialDefaulterCase(new List<Handover__c>{ho});
            System.assert(true);
        } finally {
            HandoverTriggerHandler.isTriggerDisabled = previousTriggerState;
        }
    }

    @isTest
    static void testValidateHandoverNextStep_SendHandoverNotice() {
        Boolean previousTriggerState = HandoverTriggerHandler.isTriggerDisabled;
        HandoverTriggerHandler.isTriggerDisabled = true;
        try {
            Handover__c ho = getHo1();
            ho.Sub_Status__c = 'Send Handover Notice';
            update ho;
            Map<String, Object> resp = HandoverHandler.getInstance().validateHandoverNextStep(ho, false);
            System.assertNotEquals(null, resp);
        } finally {
            HandoverTriggerHandler.isTriggerDisabled = previousTriggerState;
        }
    }

    @isTest
    static void testValidateHOTeamTasks_DocumentCheck() {
        Handover__c ho = getHo1();
        ho.HO_Agent_Assigned_User__c = UserInfo.getUserId();
        update ho;

        Task tsk = new Task(Subject = 'Test Task', WhatId = ho.Id, SubType__c = 'Handover Team Task 3', Status = 'Open');
        insert tsk;

        Test.startTest();
        HandoverHandler handler = HandoverHandler.getInstance();
        Map<String, Object> response = handler.commonValidationChecks(ho);
       // handler.createTawtheeqEnrollmentCase(ho);
        Test.stopTest();

        System.assertNotEquals(null, response, 'Response should not be null');
    }

    @isTest
    static void testHandleNextSteps() {
        Boolean previousTriggerState = HandoverTriggerHandler.isTriggerDisabled;
        HandoverTriggerHandler.isTriggerDisabled = true;
        try {
            Handover__c ho = getHo1();
            ho.Sub_Status__c = 'QA Snagging';
            update ho;

            Test.startTest();
            HandoverHandler handler = HandoverHandler.getInstance();
            handler.handleNextSteps(ho, true);
            Test.stopTest();

            System.assert(true, 'Method should execute without error');
        } finally {
            HandoverTriggerHandler.isTriggerDisabled = previousTriggerState;
        }
    }

    // ===================== commonValidationChecks: PASS PATHS (default Record Type, ho1) =====================

    @isTest
    static void testCommonValidationChecks_Pass_QASnagging() {
        Handover__c ho = getHo1();
        ho.Sub_Status__c = HandoverConstants.Handover_Sub_Status_QA_Snagging;
        update ho;
        Map<String, Object> resp = HandoverHandler.getInstance().commonValidationChecks(ho);
        System.assertEquals('success', resp.get('status'));
    }

    @isTest
    static void testCommonValidationChecks_Pass_UploadSOA() {
        Handover__c ho = getHo1();
        ho.Sub_Status__c = HandoverConstants.Handover_Sub_Status_Upload_SOA;
        update ho;
        Map<String, Object> resp = HandoverHandler.getInstance().commonValidationChecks(ho);
        System.assertEquals('success', resp.get('status'));
    }

    @isTest
    static void testCommonValidationChecks_Pass_UploadSPA() {
        Handover__c ho = getHo1();
        ho.Sub_Status__c = HandoverConstants.Handover_Sub_Status_Upload_SPA;
        update ho;
        Map<String, Object> resp = HandoverHandler.getInstance().commonValidationChecks(ho);
        System.assertEquals('success', resp.get('status'));
    }

   /* @isTest
    static void testCommonValidationChecks_Pass_CHOSnagging() {
        Handover__c ho = getHo1();
        ho.Sub_Status__c = HandoverConstants.Handover_Sub_Status_CHO_Snagging;
        update ho;
        Map<String, Object> resp = HandoverHandler.getInstance().commonValidationChecks(ho);
        System.assertNotEquals(null, resp);
    }*/

   /* @isTest
    static void testCommonValidationChecks_Pass_CHODeSnagging() {
        Handover__c ho = getHo1();
        ho.Sub_Status__c = HandoverConstants.Handover_Sub_Status_CHO_DeSnagging;
        update ho;
        Map<String, Object> resp = HandoverHandler.getInstance().commonValidationChecks(ho);
        System.assertNotEquals(null, resp);
    }*/

    @isTest
    static void testCommonValidationChecks_Pass_SendCHOAndNOC() {
        Handover__c ho = getHo1();
        ho.Is_Notice_of_Completion_Sent__c = true;
        ho.Sub_Status__c = HandoverConstants.Handover_Sub_Status_Send_CHO_and_NOC;
        update ho;
        Map<String, Object> resp = HandoverHandler.getInstance().commonValidationChecks(ho);
        System.assertNotEquals(null, resp);
    }

    @isTest
    static void testCommonValidationChecks_Pass_MortgageChequeClearance() {
        Handover__c ho = getHo1();
        ho.Payment_Type__c = 'Mortgage';
        ho.Payment_Settled__c = true;
        ho.Payment_Date__c = Date.today();
        ho.Sub_Status__c = HandoverConstants.Handover_Sub_Status_Mortgage_Cheque_Clearance;
        update ho;
        Map<String, Object> resp = HandoverHandler.getInstance().commonValidationChecks(ho);
        System.assertNotEquals(null, resp);
    }

  /*  @isTest
    static void testCommonValidationChecks_Pass_PreCHOCheck_DelegateToBloom() {
        Handover__c ho = getHo1();
        ho.Customer_Availability_for_CHO__c = 'Customer Delegate To Bloom';
        ho.Sub_Status__c = HandoverConstants.Handover_Sub_Status_Pre_CHO_Check;
        update ho;
        Map<String, Object> resp = HandoverHandler.getInstance().commonValidationChecks(ho);
        System.assertEquals('success', resp.get('status'));
    }*/

    @isTest
    static void testCommonValidationChecks_Pass_SettlementFollowUp_Cash() {
        Handover__c ho = getHo1();
        ho.Payment_Type__c = 'Cash';
        ho.Is_Notice_of_Completion_Sent__c = true;
        ho.Sub_Status__c = HandoverConstants.Handover_Sub_Status_Settlement_Follow_up;
        update ho;
        Map<String, Object> resp = HandoverHandler.getInstance().commonValidationChecks(ho);
        System.assertNotEquals(null, resp);
    }

    @isTest
    static void testCommonValidationChecks_Pass_SettlementFollowUp_Mortgage() {
        Handover__c ho = getHo1();
        ho.Payment_Type__c = 'Mortgage';
        ho.Is_Notice_of_Completion_Sent__c = true;
        ho.Sub_Status__c = HandoverConstants.Handover_Sub_Status_Settlement_Follow_up;
        update ho;
        Map<String, Object> resp = HandoverHandler.getInstance().commonValidationChecks(ho);
        System.assertNotEquals(null, resp);
    }

    @isTest
    static void testCommonValidationChecks_Pass_UploadMortgageReleaseDocuments() {
        Handover__c ho = getHo1();
        ho.Sub_Status__c = HandoverConstants.Handover_Sub_Status_Upload_Mortgage_Release_Documents;
        update ho;
        Map<String, Object> resp = HandoverHandler.getInstance().commonValidationChecks(ho);
        System.assertNotEquals(null, resp);
    }

    @isTest
    static void testCommonValidationChecks_Pass_RegisterTitleDeed() {
        Handover__c ho = getHo1();
        ho.Sub_Status__c = HandoverConstants.Handover_Sub_Status_Register_Title_Deed;
        update ho;
        Map<String, Object> resp = HandoverHandler.getInstance().commonValidationChecks(ho);
        System.assertNotEquals(null, resp);
    }

    @isTest
    static void testCommonValidationChecks_Pass_TransferUtilities() {
        Handover__c ho = getHo1();
        ho.Sub_Status__c = HandoverConstants.Handover_Sub_Status_Transfer_Utilities;
        update ho;
        Map<String, Object> resp = HandoverHandler.getInstance().commonValidationChecks(ho);
        System.assertEquals('success', resp.get('status'));
    }

    // ===================== commonValidationChecks: FAIL PATHS (default Record Type, ho2) =====================

    @isTest
    static void testCommonValidationChecks_Fail_QASnagging() {
        Handover__c ho = getHo2();
        ho.Sub_Status__c = HandoverConstants.Handover_Sub_Status_QA_Snagging;
        update ho;
        Map<String, Object> resp = HandoverHandler.getInstance().commonValidationChecks(ho);
        System.assertEquals('error', resp.get('status'));
    }

    @isTest
    static void testCommonValidationChecks_Fail_UploadSOA() {
        Handover__c ho = getHo2();
        ho.Sub_Status__c = HandoverConstants.Handover_Sub_Status_Upload_SOA;
        update ho;
        Map<String, Object> resp = HandoverHandler.getInstance().commonValidationChecks(ho);
        System.assertEquals('error', resp.get('status'));
    }

   

    

    @isTest
    static void testCommonValidationChecks_Fail_BookAppointmentWithCustomer() {
        Handover__c ho = getHo2();
        ho.Customer_Availability_for_CHO__c = null;
        ho.Is_Appointment_Booked__c = false;
        ho.Sub_Status__c = HandoverConstants.Handover_Sub_Status_Book_Appointment_with_Customer;
        update ho;
        Map<String, Object> resp = HandoverHandler.getInstance().commonValidationChecks(ho);
        System.assertEquals('error', resp.get('status'));
    }

    @isTest
    static void testCommonValidationChecks_Fail_PreCHOCheck_NotBooked() {
        Handover__c ho = getHo2();
        ho.Customer_Availability_for_CHO__c = 'Customer Available';
        ho.Is_Appointment_Booked__c = false;
      //  ho.Sub_Status__c = HandoverConstants.Handover_Sub_Status_Pre_CHO_Check;
        update ho;
        Map<String, Object> resp = HandoverHandler.getInstance().commonValidationChecks(ho);
        System.assertEquals('error', resp.get('status'));
    }

    @isTest
    static void testCommonValidationChecks_Fail_SettlementFollowUp_NoNOC() {
        Handover__c ho = getHo2();
        ho.Is_Notice_of_Completion_Sent__c = false;
        ho.Sub_Status__c = HandoverConstants.Handover_Sub_Status_Settlement_Follow_up;
        update ho;
        Map<String, Object> resp = HandoverHandler.getInstance().commonValidationChecks(ho);
        System.assertEquals('error', resp.get('status'));
    }

    @isTest
    static void testCommonValidationChecks_Fail_SettlementFollowUp_NoPaymentType() {
        Handover__c ho = getHo2();
        ho.Is_Notice_of_Completion_Sent__c = true;
        ho.Payment_Type__c = null;
        ho.Sub_Status__c = HandoverConstants.Handover_Sub_Status_Settlement_Follow_up;
        update ho;
        Map<String, Object> resp = HandoverHandler.getInstance().commonValidationChecks(ho);
        System.assertEquals('error', resp.get('status'));
    }

    @isTest
    static void testCommonValidationChecks_Fail_GenerateBankNOC() {
        Handover__c ho = getHo2();
        ho.Payment_Type__c = 'Cash';
        ho.Sub_Status__c = HandoverConstants.Handover_Sub_Status_Generate_Bank_NOC;
        update ho;
        Map<String, Object> resp = HandoverHandler.getInstance().commonValidationChecks(ho);
        System.assertEquals('error', resp.get('status'));
    }

    @isTest
    static void testCommonValidationChecks_Fail_UploadMortgageReleaseDocuments() {
        Handover__c ho = getHo2();
        ho.Sub_Status__c = HandoverConstants.Handover_Sub_Status_Upload_Mortgage_Release_Documents;
        update ho;
        Map<String, Object> resp = HandoverHandler.getInstance().commonValidationChecks(ho);
        System.assertEquals('error', resp.get('status'));
    }

    @isTest
    static void testCommonValidationChecks_Fail_TransferUtilities() {
        Handover__c ho = getHo2();
        ho.Sub_Status__c = HandoverConstants.Handover_Sub_Status_Transfer_Utilities;
        update ho;
        Map<String, Object> resp = HandoverHandler.getInstance().commonValidationChecks(ho);
        System.assertEquals('error', resp.get('status'));
    }

    @isTest
    static void testCommonValidationChecks_Fail_MortgageChequeClearance_NoPaymentDate() {
        Handover__c ho = getHo2();
        ho.Payment_Type__c = 'Mortgage';
        ho.Payment_Settled__c = false;
        ho.Payment_Date__c = null;
        ho.Sub_Status__c = HandoverConstants.Handover_Sub_Status_Mortgage_Cheque_Clearance;
        update ho;
        Map<String, Object> resp = HandoverHandler.getInstance().commonValidationChecks(ho);
        System.assertEquals('error', resp.get('status'));
    }

    @isTest
    static void testCommonValidationChecks_Fail_HandoverSigningDocumentAppointment() {
        Handover__c ho = getHo2();
        ho.Sub_Status__c = HandoverConstants.Handover_Sub_Status_Handover_Signing_Document_Appointment;
        update ho;
        Map<String, Object> resp = HandoverHandler.getInstance().commonValidationChecks(ho);
        System.assertEquals('error', resp.get('status'));
    }

    // ===================== commonValidationChecks: PHPP-EXCLUSIVE PASS PATHS (ho3, Handover_PHPP Record Type) =====================

    @isTest
    static void testCommonValidationChecks_Pass_UploadSignedTawtheeqAgreement_NonMortgage() {
        Handover__c ho = getHo3();
        ho.Payment_Type__c = 'Cash';
        ho.Payment_Settled__c = true;
        ho.Payment_Date__c = Date.today();
        ho.Sub_Status__c = HandoverConstants.Handover_Sub_Status_Upload_Signed_Tawtheeq_Agreement;
        update ho;
        Map<String, Object> resp = HandoverHandler.getInstance().commonValidationChecks(ho);
        System.assertEquals('success', resp.get('status'));
    }

    @isTest
    static void testCommonValidationChecks_Pass_HOUndertakingLetter() {
        Handover__c ho = getHo3();
        ho.Sub_Status__c = HandoverConstants.Handover_Sub_Status_HO_Undertaking_Letter;
        update ho;
        Map<String, Object> resp = HandoverHandler.getInstance().commonValidationChecks(ho);
        System.assertEquals('success', resp.get('status'));
    }

    @isTest
    static void testCommonValidationChecks_Pass_LeaseAgreement_PHPP() {
        Handover__c ho = getHo3();
        ho.Payment_Type__c = 'PHPP';
        ho.Sub_Status__c = 'Lease Agreement';
        update ho;
        Map<String, Object> resp = HandoverHandler.getInstance().commonValidationChecks(ho);
        System.assertNotEquals(null, resp);
    }

    @isTest
    static void testCommonValidationChecks_Pass_PHPPHandoverKeys() {
        Handover__c ho = getHo3();
        ho.Sub_Status__c = HandoverConstants.Handover_Sub_Status_PHPP_Handover_Keys;
        update ho;
        Map<String, Object> resp = HandoverHandler.getInstance().commonValidationChecks(ho);
        System.assertNotEquals(null, resp);
    }

    // ===================== commonValidationChecks: PHPP-EXCLUSIVE FAIL PATHS (ho4, Handover_PHPP Record Type) =====================

    @isTest
    static void testCommonValidationChecks_Fail_HOUndertakingLetter() {
        Handover__c ho = getHo4();
        ho.Sub_Status__c = HandoverConstants.Handover_Sub_Status_HO_Undertaking_Letter;
        update ho;
        Map<String, Object> resp = HandoverHandler.getInstance().commonValidationChecks(ho);
        System.assertEquals('error', resp.get('status'));
    }

    @isTest
    static void testCommonValidationChecks_Fail_PHPPHandoverKeys() {
        Handover__c ho = getHo4();
        ho.Sub_Status__c = HandoverConstants.Handover_Sub_Status_PHPP_Handover_Keys;
        update ho;
        Map<String, Object> resp = HandoverHandler.getInstance().commonValidationChecks(ho);
        System.assertEquals('error', resp.get('status'));
    }
    // ==========================================
    // validateHOTeamTasks Coverage Tests
    // ==========================================

    @isTest
    static void testValidateHOTeamTasks_TaskTypeEndsWith1() {
        Handover__c ho = getHo1();
        
        // Open task ending with '1' (e.g. 'Handover Team Task 1')
        Task tsk = new Task(
            Subject = 'QA Snagging', 
            WhatId = ho.Id, 
            SubType__c = 'Handover Team Task 1', 
            Status = 'Open'
        );
        insert tsk;

        Test.startTest();
        System.debug('HO 1 Id : '+ ho.Id);
        System.debug(ServiceCatalogService.getInstance().getHOTaskServiceActions(new List<Handover__c>{ho}));
        Map<String, Object> resp = HandoverHandler.getInstance().validateHOTeamTasks(ho, new List<Task>{ tsk });
        Test.stopTest();

        System.assertNotEquals(null, resp, 'Response should not be null');
        System.assertEquals('success', (String)resp.get('status'), 'Status should be success for task digit 1');
    }

    @isTest
    static void testValidateHOTeamTasks_TaskTypeEndsWith2_DocPresent() {
        Handover__c ho = getHo1(); // Contains 'CHO Snagging Report' inserted in @TestSetup
        
        // Open task ending with '2'
        Task tsk = new Task(
            Subject = 'QA De-Snagging', 
            WhatId = ho.Id, 
            SubType__c = 'Handover Team Task 2', 
            Status = 'Open'
        );
        insert tsk;

        Test.startTest();
        Map<String, Object> resp = HandoverHandler.getInstance().validateHOTeamTasks(ho, new List<Task>{ tsk });
        Test.stopTest();

        System.assertNotEquals(null, resp, 'Response should not be null');
        System.assertEquals('success', (String)resp.get('status'), 'Should succeed when CHO Snagging Report is present');
    }

    @isTest
    static void testValidateHOTeamTasks_TaskTypeEndsWith2_DocMissing() {
        Handover__c ho = getHo2(); // Does NOT have documents inserted in @TestSetup
        
        Task tsk = new Task(
            Subject = 'QA De-Snagging', 
            WhatId = ho.Id, 
            SubType__c = 'Handover Team Task 2', 
            Status = 'Open'
        );
        insert tsk;

        Test.startTest();
        Map<String, Object> resp = HandoverHandler.getInstance().validateHOTeamTasks(ho, new List<Task>{ tsk });
        Test.stopTest();

        System.assertNotEquals(null, resp, 'Response should not be null');
        System.assertEquals('error', (String)resp.get('status'), 'Should fail when CHO Snagging Report is missing');
        System.assertEquals('Please upload CHO Snagging Report', (String)resp.get('message'));
    }

    @isTest
    static void testValidateHOTeamTasks_TaskTypeEndsWith3_DocPresent() {
        Handover__c ho = getHo1(); // Contains 'CHO Desnagging Report' inserted in @TestSetup
        
        // Open task ending with '3'
        Task tsk = new Task(
            Subject = 'Settlement Follow up', 
            WhatId = ho.Id, 
            SubType__c = 'Handover Team Task 3', 
            Status = 'Open'
        );
        insert tsk;

        Test.startTest();
        Map<String, Object> resp = HandoverHandler.getInstance().validateHOTeamTasks(ho, new List<Task>{ tsk });
        Test.stopTest();

        System.assertNotEquals(null, resp, 'Response should not be null');
        System.assertEquals('success', (String)resp.get('status'), 'Should succeed when CHO Desnagging Report is present');
    }

    @isTest
    static void testValidateHOTeamTasks_TaskTypeEndsWith3_DocMissing() {
        Handover__c ho = getHo2(); // Does NOT have documents inserted in @TestSetup
        
        Task tsk = new Task(
            Subject = 'Settlement Follow up', 
            WhatId = ho.Id, 
            SubType__c = 'Handover Team Task 3', 
            Status = 'Open'
        );
        insert tsk;

        Test.startTest();
        Map<String, Object> resp = HandoverHandler.getInstance().validateHOTeamTasks(ho, new List<Task>{ tsk });
        Test.stopTest();

        System.assertNotEquals(null, resp, 'Response should not be null');
        System.assertEquals('error', (String)resp.get('status'), 'Should fail when CHO Desnagging Report is missing');
        System.assertEquals('Please upload CHO Desnagging Report', (String)resp.get('message'));
    }
    // =========================================================================
    // validateNonPHPPHandoverForNextReview Coverage Tests
    // =========================================================================

   
    @isTest
    static void testValidateNonPHPP_CommonValidationFailure() {
        // ho2 lacks documents required for QA Snagging
        Handover__c ho = getHo2();
        ho.Sub_Status__c = 'QA Snagging';
        update ho;

        HandoverHandler handler = HandoverHandler.getInstance();
        
        Test.startTest();
        Map<String, Object> resp = handler.validateNonPHPPHandoverForNextReview(ho, false);
        Test.stopTest();

        System.assertEquals('error', (String)resp.get('status'), 'Should fail when common validation checks fail');
    }

    @isTest
    static void testValidateNonPHPP_UpdateHandoverTrue() {
        Boolean previousTriggerState = HandoverTriggerHandler.isTriggerDisabled;
        HandoverTriggerHandler.isTriggerDisabled = true;
        try {
            Handover__c ho = getHo1();
            ho.HandoverType__c = 'Non PHPP';
            ho.Sub_Status__c = 'QA Snagging';
            update ho;

            HandoverHandler handler = HandoverHandler.getInstance();
            
            Test.startTest();
            Map<String, Object> resp = handler.validateNonPHPPHandoverForNextReview(ho, true);
            Test.stopTest();

            System.assertEquals('success', (String)resp.get('status'));
        } finally {
            HandoverTriggerHandler.isTriggerDisabled = previousTriggerState;
        }
    }

    @isTest
    static void testValidateNonPHPP_UpdateHandoverFalse_TaskNotAssignedToUser() {
        Boolean previousTriggerState = HandoverTriggerHandler.isTriggerDisabled;
        HandoverTriggerHandler.isTriggerDisabled = true;
        try {
            Handover__c ho = getHo1();
            ho.HandoverType__c = 'Non PHPP';
            ho.Sub_Status__c = 'QA Snagging';
            update ho;

            // Create open task owned by another user/placeholder ID
            // Finding another active standard user
            List<User> otherUsers = [SELECT Id FROM User WHERE Id != :UserInfo.getUserId() AND IsActive = true LIMIT 1];
            Id otherUserId = !otherUsers.isEmpty() ? otherUsers[0].Id : UserInfo.getUserId();

            if (!otherUsers.isEmpty()) {
                Task tsk = new Task(Subject = 'QA Snagging', WhatId = ho.Id, OwnerId = otherUserId, Status = 'Open');
                insert tsk;

                HandoverHandler handler = HandoverHandler.getInstance();
                
                Test.startTest();
                Map<String, Object> resp = handler.validateNonPHPPHandoverForNextReview(ho, false);
                Test.stopTest();

                System.assertEquals('error', (String)resp.get('status'));
                System.assertEquals('Please try again after assigning the task to yourself by Clicking on Assign To Me button.', (String)resp.get('message'));
            }
        } finally {
            HandoverTriggerHandler.isTriggerDisabled = previousTriggerState;
        }
    }

    @isTest
    static void testValidateNonPHPP_AdvanceStage_WithSalesOrder_AndCashPayment() {
        Boolean previousTriggerState = HandoverTriggerHandler.isTriggerDisabled;
        HandoverTriggerHandler.isTriggerDisabled = true;
        try {
            Handover__c ho = getHo1();
            ho.HandoverType__c = 'Non PHPP';
            ho.Payment_Type__c = 'Cash';
            ho.Sub_Status__c = 'QA Snagging';
            ho.Property_Enrollment_Under_Tawtheeq__c = true;
            ho.Property_Enrollment_Under_Tawtheeq_Accou__c = 100;
            update ho;

            // Matching open task owned by current user
            Task tsk = new Task(
                Subject = 'QA Snagging',
                WhatId = ho.Id,
                OwnerId = UserInfo.getUserId(),
                Status = 'Open'
            );
            insert tsk;

            HandoverHandler handler = HandoverHandler.getInstance();
            
            Test.startTest();
            Map<String, Object> resp = handler.validateNonPHPPHandoverForNextReview(ho, false);
            Test.stopTest();

            System.assertEquals('success', (String)resp.get('status'));
            
            Handover__c updatedHo = [SELECT Sub_Status__c FROM Handover__c WHERE Id = :ho.Id];
            System.assertEquals('QA De-Snagging', updatedHo.Sub_Status__c, 'Stage should advance to QA De-Snagging');
        } finally {
            HandoverTriggerHandler.isTriggerDisabled = previousTriggerState;
        }
    }

    @isTest
    static void testValidateNonPHPP_AdvanceStage_UnsoldUnit_NoSalesOrder() {
        Boolean previousTriggerState = HandoverTriggerHandler.isTriggerDisabled;
        HandoverTriggerHandler.isTriggerDisabled = true;
        try {
            Handover__c ho = getHo1();
            ho.HandoverType__c = 'Non PHPP';
            ho.Sales_Order__c = null; // Unsold unit path
            ho.Sub_Status__c = 'QA Snagging';
            update ho;

            Task tsk = new Task(
                Subject = 'QA Snagging',
                WhatId = ho.Id,
                OwnerId = UserInfo.getUserId(),
                Status = 'Open'
            );
            insert tsk;

            HandoverHandler handler = HandoverHandler.getInstance();
            
            Test.startTest();
            Map<String, Object> resp = handler.validateNonPHPPHandoverForNextReview(ho, false);
            Test.stopTest();

            System.assertEquals('success', (String)resp.get('status'));
            
            Handover__c updatedHo = [SELECT Sub_Status__c FROM Handover__c WHERE Id = :ho.Id];
            System.assertEquals('QA De-Snagging', updatedHo.Sub_Status__c, 'Stage should advance via unsoldUnitiStatusFlow');
        } finally {
            HandoverTriggerHandler.isTriggerDisabled = previousTriggerState;
        }
    }

    @isTest
    static void testValidateNonPHPP_UserOwnsTask_SubjectMismatch_ClosesTaskOnly() {
        Boolean previousTriggerState = HandoverTriggerHandler.isTriggerDisabled;
        HandoverTriggerHandler.isTriggerDisabled = true;
        try {
            Handover__c ho = getHo1();
            ho.HandoverType__c = 'Non PHPP';
            ho.Sub_Status__c = 'QA Snagging';
            update ho;

            // Task subject differs from current Sub_Status__c
            Task tsk = new Task(
                Subject = 'Different Subject Task',
                WhatId = ho.Id,
                OwnerId = UserInfo.getUserId(),
                Status = 'Open'
            );
            insert tsk;

            HandoverHandler handler = HandoverHandler.getInstance();
            
            Test.startTest();
            Map<String, Object> resp = handler.validateNonPHPPHandoverForNextReview(ho, false);
            Test.stopTest();

            System.assertEquals('success', (String)resp.get('status'));
        } finally {
            HandoverTriggerHandler.isTriggerDisabled = previousTriggerState;
        }
    }
    // =========================================================================
    // validatePHPPHandoverForNextReview Coverage Tests
    // =========================================================================

   
    @isTest
    static void testValidatePHPP_CommonValidationFailure() {
        // ho4 lacks required documents for QA Snagging
        Handover__c ho = getHo4();
        ho.Sub_Status__c = 'QA Snagging';
        update ho;

        HandoverHandler handler = HandoverHandler.getInstance();
        
        Test.startTest();
        Map<String, Object> resp = handler.validatePHPPHandoverForNextReview(ho, false);
        Test.stopTest();

        System.assertEquals('error', (String)resp.get('status'), 'Should fail when common validations fail');
    }

    @isTest
    static void testValidatePHPP_ADRECApprovalAndMortgageRelease() {
        Boolean previousTriggerState = HandoverTriggerHandler.isTriggerDisabled;
        HandoverTriggerHandler.isTriggerDisabled = true;
        try {
            Handover__c ho = getHo3();
            ho.Sub_Status__c = 'ADREC Approval and Mortgage Release';
            update ho;

            Task tsk = new Task(
                Subject = 'ADREC Approval and Mortgage Release',
                WhatId = ho.Id,
                OwnerId = UserInfo.getUserId(),
                Status = 'Open'
            );
            insert tsk;

            HandoverHandler handler = HandoverHandler.getInstance();
            
            Test.startTest();
            Map<String, Object> resp = handler.validatePHPPHandoverForNextReview(ho, false);
            Test.stopTest();

            System.assertEquals('success', (String)resp.get('status'));
        } finally {
            HandoverTriggerHandler.isTriggerDisabled = previousTriggerState;
        }
    }

    @isTest
    static void testValidatePHPP_UpdateHandoverFalse_NoTaskForCurrentUser() {
        Boolean previousTriggerState = HandoverTriggerHandler.isTriggerDisabled;
        HandoverTriggerHandler.isTriggerDisabled = true;
        try {
            Handover__c ho = getHo3();
            ho.Sub_Status__c = 'QA Snagging';
            update ho;

            List<User> otherUsers = [SELECT Id FROM User WHERE Id != :UserInfo.getUserId() AND IsActive = true LIMIT 1];
            if (!otherUsers.isEmpty()) {
                Task tsk = new Task(Subject = 'QA Snagging', WhatId = ho.Id, OwnerId = otherUsers[0].Id, Status = 'Open');
                insert tsk;

                HandoverHandler handler = HandoverHandler.getInstance();
                
                Test.startTest();
                Map<String, Object> resp = handler.validatePHPPHandoverForNextReview(ho, false);
                Test.stopTest();

                System.assertEquals('error', (String)resp.get('status'));
                System.assertEquals('Please try again after assigning the task to yourself by Clicking on Assign To Me button.', (String)resp.get('message'));
            }
        } finally {
            HandoverTriggerHandler.isTriggerDisabled = previousTriggerState;
        }
    }

    @isTest
    static void testValidatePHPP_AdvanceStage_UnsoldUnit_NoSalesOrder() {
        Boolean previousTriggerState = HandoverTriggerHandler.isTriggerDisabled;
        HandoverTriggerHandler.isTriggerDisabled = true;
        try {
            Handover__c ho = getHo3();
            ho.Sales_Order__c = null;
            ho.Sub_Status__c = 'QA Snagging';
            update ho;

            Task tsk = new Task(
                Subject = 'QA Snagging',
                WhatId = ho.Id,
                OwnerId = UserInfo.getUserId(),
                Status = 'Open'
            );
            insert tsk;

            HandoverHandler handler = HandoverHandler.getInstance();
            
            Test.startTest();
            Map<String, Object> resp = handler.validatePHPPHandoverForNextReview(ho, false);
            Test.stopTest();

            System.assertEquals('success', (String)resp.get('status'));
            
            Handover__c updatedHo = [SELECT Sub_Status__c FROM Handover__c WHERE Id = :ho.Id];
            System.assertEquals('QA De-Snagging', updatedHo.Sub_Status__c, 'Stage should advance according to unsoldUnitiStatusFlow');
        } finally {
            HandoverTriggerHandler.isTriggerDisabled = previousTriggerState;
        }
    }

    @isTest
    static void testValidatePHPP_TaskSubjectMismatch_ClosesTaskOnly() {
        Boolean previousTriggerState = HandoverTriggerHandler.isTriggerDisabled;
        HandoverTriggerHandler.isTriggerDisabled = true;
        try {
            Handover__c ho = getHo3();
            ho.Sub_Status__c = 'QA Snagging';
            update ho;

            Task tsk = new Task(
                Subject = 'Different Subject Task',
                WhatId = ho.Id,
                OwnerId = UserInfo.getUserId(),
                Status = 'Open'
            );
            insert tsk;

            HandoverHandler handler = HandoverHandler.getInstance();
            
            Test.startTest();
            Map<String, Object> resp = handler.validatePHPPHandoverForNextReview(ho, false);
            Test.stopTest();

            System.assertEquals('success', (String)resp.get('status'));
        } finally {
            HandoverTriggerHandler.isTriggerDisabled = previousTriggerState;
        }
    }
    
    @isTest
    static void testCreateNewAndCloseCurrentTask() {
        Boolean previousTriggerState = HandoverTriggerHandler.isTriggerDisabled;
        HandoverTriggerHandler.isTriggerDisabled = true;
        try {
            
            Handover__c ho = getHo1();
            ho.Sub_Status__c = 'QA Snagging';
            update ho;
            
            HandoverHandler.getInstance().createNewAndCloseCurrentTask(new List<Handover__c>{ho}, false);
            ho.Sub_Status__c = 'QA De-Snagging';
            update ho;
            List<Task> tsks = [SELECT Id,Type__c,SubType__c,FinalTask__c,WhatId,OwnerId,Owner.email,Subject,Department__c, BusinessHours__c
                FROM Task 
                WHERE WhatId =:ho.Id 
                AND SubType__c = 'Handover Team Task 1'
                order by lastmodifieddate desc LIMIT 1];
            tsks[0].WhatId = null;
            update tsks[0];
            
            System.debug(tsks);
            System.debug(ho.Id);
            HandoverHandler.getInstance().createNewAndCloseCurrentTask(new List<Handover__c>{ho}, false);
            System.assert(true);
        } finally {
            HandoverTriggerHandler.isTriggerDisabled = previousTriggerState;
        }
    }
}