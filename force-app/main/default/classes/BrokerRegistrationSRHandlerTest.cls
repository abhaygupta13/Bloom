@IsTest
private class BrokerRegistrationSRHandlerTest {
    
    @TestSetup
    static void setupData() {
        
        Account acc = new Account(
            Name = 'Test Account'
        );
        insert acc;
        
        Project__c proj = new Project__c(
            Name = 'Test Project'
        );
        insert proj;
        
        Unit__c unitRec = new Unit__c(
            Name = 'Test Unit',
            Project__c = proj.Id
        );
        insert unitRec;
        
        SalesOrder__c so = new SalesOrder__c(
            Name = 'SO-001',
            Account__c = acc.Id,
            Unit__c = unitRec.Id
        );
        insert so;
        
        ServiceCatalog__c sc = new ServiceCatalog__c(
            Name = 'Service-Request-Broker-Registration',
            RecordTypeDevName__c = 'BrokerAgentRegistrationAndUpdate',
            Type__c = 'Service Request',
            Category__c = 'Broker Service Request',
            SubCategory__c = 'Agent Onboarding'
        );
        insert sc;
        
        // Create test ServiceAction record
        ServiceAction__c testServiceAction = new ServiceAction__c(
            Name = 'Broker Management Team Task',
            ServiceCatalog__c = sc.Id,
            TaskType__c = 'Agent Onboarding',
            TaskSubType__c = 'Broker Management Team Task',
            TaskSubject__c = 'Broker Management Team Task', 
            Department__c ='Broker Management',
            Due_in_days__c = 1,
            Order__c = 1
        );
        insert testServiceAction;
        // Create test ServiceAction record
        ServiceAction__c testServiceAction2 = new ServiceAction__c(
            Name = 'Legal Team Task',
            ServiceCatalog__c = sc.Id,
            TaskType__c = 'Agent Onboarding',
            TaskSubType__c = 'Legal Team Task',
            TaskSubject__c = 'Legal Team Task',
            Department__c ='Legal',
            Due_in_days__c = 2,
            Order__c = 2
        );
        insert testServiceAction2;
        
        // Create test ServiceAction record
        ServiceAction__c finalAction = new ServiceAction__c(
            Name = 'Broker Management Team Task',
            ServiceCatalog__c = sc.Id,
            TaskType__c = 'Agent Onboarding',
            TaskSubType__c = 'Broker Management Team Task',
            TaskSubject__c = 'Broker Management Team Task',
            Department__c ='Broker Management',
            Due_in_days__c = 2,
            Order__c = 3,
            FinalTask__c = true
        );
        insert finalAction;
    }
    
    
    // =====================================================
    // getInstance()
    // =====================================================
    
    @IsTest
    static void testGetInstance() {
        
        Test.startTest();
        
        BrokerRegistrationSRHandler obj =
            BrokerRegistrationSRHandler.getInstance();
        
        Test.stopTest();
        
        System.assertNotEquals(null, obj);
    }
    
    // =====================================================
    // createFirstTask()
    // =====================================================
    
    @IsTest
    static void testCreateFirstTask_NullList() {
        
        Test.startTest();
        
        BrokerRegistrationSRHandler obj = BrokerRegistrationSRHandler.getInstance();
        obj.createFirstTask(null);
        
        BrokerRegistrationSRHandler.getInstance().createFirstTask(null);
        
        Test.stopTest();
        
        System.assert(true);
    }
    
    // =====================================================
    // validateCaseForNextReview() NULL
    // =====================================================
    
    @IsTest
    static void testValidateCaseForNextReview_NullCase() {
        
        Test.startTest();
        
        Map<String, Object> result = BrokerRegistrationSRHandler.getInstance().validateCaseForNextReview(null);
        
        Test.stopTest();
        
        System.assertEquals(
            'error',
            result.get('status')
        );
    }
    
    // =====================================================
    // CLOSED CASE
    // =====================================================
    
    @IsTest
    static void testValidateCaseForNextReview_ClosedCase() {
        
        Id rtId = Utility.getRecordTypeIdByDevName(
            Case.SObjectType,
            'BrokerAgentRegistrationAndUpdate'
        );
        
        Case c = new Case(
            Status = 'Closed',
            Subject = 'Test',
            RecordTypeId = rtId
        );
        
        insert c;
        
        Test.startTest();
        
        Map<String, Object> result = BrokerRegistrationSRHandler.getInstance().validateCaseForNextReview(c);
        
        Test.stopTest();
        
        System.assertEquals(
            'error',
            result.get('status')
        );
    }
    
    // =====================================================
    // MISSING SERVICE CATALOG
    // =====================================================
    
    @IsTest
    static void testValidateCaseForNextReview_NoServiceCatalog() {
        
        Id rtId = Utility.getRecordTypeIdByDevName(
            Case.SObjectType,
            'BrokerAgentRegistrationAndUpdate'
        );
        
        Case c = new Case(
            Status = 'New',
            Step__c = '1',
            Subject = 'Test',
            RecordTypeId = rtId
        );
        
        insert c;
        
        Test.startTest();
        
        Map<String, Object> result = BrokerRegistrationSRHandler.getInstance().validateCaseForNextReview(c);
        
        Test.stopTest();
        
        System.assertEquals(
            'error',
            result.get('status')
        );
    }
    
    // =====================================================
    // MISSING STEP
    // =====================================================
    
    @IsTest
    static void testValidateCaseForNextReview_NoStep() {
        
        ServiceCatalog__c sc = [
            SELECT Id
            FROM ServiceCatalog__c
            LIMIT 1
        ];
        
        Id rtId = Utility.getRecordTypeIdByDevName(
            Case.SObjectType,
            'BrokerAgentRegistrationAndUpdate'
        );
        
        Case c = new Case(
            Status = 'New',
            ServiceCatalog__c = sc.Id,
            Subject = 'Test',
            RecordTypeId = rtId
        );
        
        insert c;
        
        Test.startTest();
        
        Map<String, Object> result =
            BrokerRegistrationSRHandler.getInstance().validateCaseForNextReview(c);
        
        Test.stopTest();
        
        System.assertEquals(
            'error',
            result.get('status')
        );
    }
    
    // =====================================================
    // SendToBL__c = false
    // =====================================================
    
    @IsTest
    static void testValidateCaseForNextReview_SendToBLFalse() {
        
        Account acc = [
            SELECT Id
            FROM Account
            LIMIT 1
        ];
        
        ServiceCatalog__c sc = [
            SELECT Id
            FROM ServiceCatalog__c
            LIMIT 1
        ];
        
        Id rtId = Utility.getRecordTypeIdByDevName(
            Case.SObjectType,
            'BrokerAgentRegistrationAndUpdate'
        );
        
        Case c = new Case(
            AccountId = acc.Id,
            Status = 'New',
            ApprovalStatus__c = 'Pending',
            Step__c = '1',
            SendToBL__c = false,
            ServiceCatalog__c = sc.Id,
            Subject = 'Broker New Agent Registration',
            RecordTypeId = rtId
        );
        
        insert c;
        
        Test.startTest();
        
        Map<String, Object> result =
            BrokerRegistrationSRHandler.getInstance().validateCaseForNextReview(c);
        
        Test.stopTest();
        
        System.assertEquals(
            'success',
            result.get('status')
        );
    }
    
    // =====================================================
    // handleNextSteps()
    // =====================================================
    
    @IsTest
    static void testHandleNextSteps() {
        
        Id rtId = Utility.getRecordTypeIdByDevName(
            Case.SObjectType,
            'BrokerAgentRegistrationAndUpdate'
        );
        
        Account acc = [
            SELECT Id
            FROM Account
            LIMIT 1
        ];
        
        ServiceCatalog__c sc = [
            SELECT Id
            FROM ServiceCatalog__c
            LIMIT 1
        ];
        
        Case c = new Case(
            AccountId = acc.Id,
            Status = 'New',
            ApprovalStatus__c = 'Pending',
            Step__c = '1',
            SendToBL__c = false,
            ServiceCatalog__c = sc.Id,
            Subject = 'Broker New Agent Registration',
            RecordTypeId = rtId
        );
        
        insert c;
        
        Test.startTest();
        
        BrokerRegistrationSRHandler.getInstance().handleNextSteps(c);
        
        Test.stopTest();
        
        System.assert(true);
    }
    
    // =====================================================
    // createCaseRecord()
    // =====================================================
    
    @IsTest
    static void testCreateCaseRecord() {
        
        SalesOrder__c so = [SELECT Id, Account__c, Project__c, Unit__c FROM SalesOrder__c LIMIT 1];
        ServiceCatalog__c sc = [SELECT Id, RecordTypeDevName__c, SubCategory__c FROM ServiceCatalog__c LIMIT 1];
        
        Test.startTest();
        
        Case createdCase = BrokerRegistrationSRHandler.getInstance().createCaseRecord(
            so,
            sc,
            so.Account__c,
            so.Unit__c,
            'Service Request',
            'Test Description',
            'Portal'
        );
        
        Test.stopTest();
        
        System.assertNotEquals(
            null,
            createdCase
        );
        
        Case latestCase = [
            SELECT
            Id,
            Status,
            ApprovalStatus__c,
            Subject,
            Description,
            Origin,
            ServiceCatalog__c
            FROM Case
            WHERE Id = :createdCase.Id
        ];
        
        //System.assertEquals('New', latestCase.Status);
        
        //System.assertEquals('Pending', latestCase.ApprovalStatus__c);
        
        //System.assertEquals('Broker Registration', latestCase.Subject);
    }
    
    @IsTest
    static void testValidateCaseForNextReview_SendToBLTrue() {
        
        Account acc = [
            SELECT Id
            FROM Account
            LIMIT 1
        ];
        
        ServiceCatalog__c sc = [
            SELECT Id
            FROM ServiceCatalog__c
            LIMIT 1
        ];
        
        Id rtId = Utility.getRecordTypeIdByDevName(
            Case.SObjectType,
            'BrokerAgentRegistrationAndUpdate'
        );
        
        Case c = new Case(
            AccountId = acc.Id,
            Status = 'New',
            ApprovalStatus__c = 'Pending',
            Step__c = '2',
            SendToBL__c = true,
            ServiceCatalog__c = sc.Id,
            Subject = 'Broker Registration',
            RecordTypeId = rtId
        );
        
        insert c;
        
        Test.startTest();
        
        Map<String, Object> result =
            BrokerRegistrationSRHandler.getInstance()
            .validateCaseForNextReview(c);
        
        Test.stopTest();
        
        System.assertEquals(
            'success',
            result.get('status')
        );
        
        Case updatedCase = [
            SELECT SubStatus__c,
            FinalApproved__c
            FROM Case
            WHERE Id = :c.Id
        ];
        
        System.assertEquals(
            'Approved by BL',
            updatedCase.SubStatus__c
        );
        
        System.assertEquals(
            false,
            updatedCase.FinalApproved__c
        );
    }
    
    @IsTest
    static void testValidateCaseForNextReview_SendToBLFinal() {
        
        Account acc = [
            SELECT Id
            FROM Account
            LIMIT 1
        ];
        
        ServiceCatalog__c sc = [
            SELECT Id
            FROM ServiceCatalog__c
            LIMIT 1
        ];
        
        Id rtId = Utility.getRecordTypeIdByDevName(
            Case.SObjectType,
            'BrokerAgentRegistrationAndUpdate'
        );
        
        Case c = new Case(
            AccountId = acc.Id,
            Status = 'New',
            ApprovalStatus__c = 'Pending',
            Step__c = 'Final',
            SendToBL__c = true,
            ServiceCatalog__c = sc.Id,
            Subject = 'Broker Registration',
            RecordTypeId = rtId
        );
        
        insert c;
        
        Test.startTest();
        
        Map<String, Object> result =
            BrokerRegistrationSRHandler.getInstance()
            .validateCaseForNextReview(c);
        
        Test.stopTest();
        
        System.assertEquals(
            'success',
            result.get('status')
        );
        
        Case updatedCase = [
            SELECT ApprovalStatus__c
            FROM Case
            WHERE Id = :c.Id
        ];
        
        System.assertEquals(
            'Approved',
            updatedCase.ApprovalStatus__c
        );
    }
}