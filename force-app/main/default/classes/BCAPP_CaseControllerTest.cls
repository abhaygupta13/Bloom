@IsTest
public class BCAPP_CaseControllerTest {
    private class AzureCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            // Create a mock HTTP response
            HttpResponse res = new HttpResponse();
            // Determine the endpoint being called
            String endpoint = req.getEndpoint();
            
            if (endpoint.contains('oauth2/v2.0/token')) {
                // Mock response for access token request
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"token_type": "Bearer", "expires_in": 3600, "access_token": "mock-access-token"}');
                res.setStatusCode(200);
            } else if (endpoint.contains('graph.microsoft.com/v1.0/users')) {
                // Mock response for user creation or retrieval
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"id": "mock-user-id", "displayName": "Mock User", "email": "mockuser@example.com"}');
                res.setStatusCode(201); // Status 201 for created resource
            } else {
                // Default response for unsupported endpoints
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"error": "Unsupported endpoint"}');
                res.setStatusCode(400);
            }
            return res;
        }
    }
    @isTest
    static void testUpdateCaseOwner() {
        // Set up test data
        Account account = new Account(Name = 'Test Account');
        insert account;
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Move In Holiday Homes').getRecordTypeId();
        
        Case testCase =BCAPP_TestDataFactory.createCase();
        testCase.RecordTypeId= RecordTypeCaseId;
        insert testCase;
        
        Test.startTest();
        Boolean result = BCAPP_CaseController.updateCaseOwner(testCase.Id);
        Test.stopTest();
        
    }
    
    @isTest
    static void testCheckDocumentsAndSubmit() {
        // Set up test data
        Account account = new Account(Name = 'Test Account');
        insert account;
        
        Case testCase =BCAPP_TestDataFactory.createCase();
        
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Move In Holiday Homes').getRecordTypeId();
        testCase.RecordTypeId=RecordTypeCaseId;
        insert testCase;
        
        Customer_Document__c document = new Customer_Document__c(Case__c = testCase.Id);
        insert document;
        
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.pdf',
            VersionData = Blob.valueOf('Test content for file') // Mock file content
        );
        insert contentVersion;
        
        ContentVersion ContentVersionRecord=[select id,ContentDocumentId from ContentVersion where  id=:contentVersion.Id];
        ContentDocument contentDoc = [
            SELECT Id 
            FROM ContentDocument 
            WHERE Id = :ContentVersionRecord.ContentDocumentId
            LIMIT 1
        ];
        
        ContentDocumentLink link = new ContentDocumentLink(LinkedEntityId = document.Id,ContentDocumentId = contentDoc.Id,ShareType = 'I' );
        insert link;
        
        Test.startTest();
        Boolean result = BCAPP_CaseController.checkDocumentsAndSubmit(testCase.Id);
        Test.stopTest();
        
    }
    
    @isTest
    static void testGetCaseDetails() {
        // Set up test data
        Account account = new Account(Name = 'Test Account');
        insert account;
        
        Case testCase =BCAPP_TestDataFactory.createCase();
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Move In Holiday Homes').getRecordTypeId();
        testCase.RecordTypeId=RecordTypeCaseId;
        insert testCase;
        
        Test.startTest();
        Map<String, Object> result = BCAPP_CaseController.getCaseDetails(testCase.Id);
        Test.stopTest();
        
    }
    
    @isTest
    static void testhandleRenew() {

        Account accountRecord =BCAPP_TestDataFactory.createAccount('Test Account');
        insert accountRecord;
        
        Service_Contract__c Service_Contract=  BCAPP_TestDataFactory.createServiceContract();
        Service_Contract.Customer_Name__c=accountRecord.id;
        insert Service_Contract;
        
        Case testCase =BCAPP_TestDataFactory.createCase();
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Move In Holiday Homes').getRecordTypeId();
        testCase.RecordTypeId=RecordTypeCaseId;
        testCase.AccountId= accountRecord.id;
        testCase.Move_Out_Date__c=system.today();
        insert testCase;
        Test.startTest();
        try{
        BCAPP_CaseController.handleRenew(testCase,new List<string>{'eeee@adssd.com'});
        }catch(exception e){}
            Test.stopTest();
        
    }
    
    @isTest
    static void testhandleMoveOut() {
        
        Account accountRecord =BCAPP_TestDataFactory.createAccount('Test Account');
        accountRecord.Azure_UserPrincipal_Id__c='testttt';
        insert accountRecord;
        
        Service_Contract__c Service_Contract=  BCAPP_TestDataFactory.createServiceContract();
        Service_Contract.Customer_Name__c=accountRecord.id;
        insert Service_Contract;
        
        Case testCase =BCAPP_TestDataFactory.createCase();
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Move In Holiday Homes').getRecordTypeId();
        testCase.RecordTypeId=RecordTypeCaseId;
        testCase.AccountId= accountRecord.id;
        testCase.Move_Out_Date__c=system.today();
        insert testCase;
        
        User__c userRecord= BCAPP_TestDataFactory.createUser('testttt');
        insert userRecord;
        
        Unit__c unit= BCAPP_TestDataFactory.createUnit();
        insert unit;
        testCase.Unit__c=unit.id;
        update testCase;
        
        Unit_Allocation__c unitAllocation= BCAPP_TestDataFactory.createUnitAllocation();
        unitAllocation.Unit__c=unit.id;
        unitAllocation.User__c=userRecord.id;
        unitAllocation.Account__c=accountRecord.id;
        insert unitAllocation;
        Test.startTest();
        try{
        BCAPP_CaseController.handleMoveOut(testCase,new List<string>{'eeee@adssd.com'});
        
        BCAPP_CaseController.handleMoveIn(testCase,new List<string>{'eeee@adssd.com'});
        }catch(exception e){}
        Test.stopTest();
        
    }
    
    
    @isTest
    static void testhandleMoveIn() {
         
        Test.setMock(HttpCalloutMock.class, new AzureCalloutMock());
        
        Account accountRecord =BCAPP_TestDataFactory.createAccount('Test Account');
        accountRecord.Azure_UserPrincipal_Id__c='testttt';
        insert accountRecord;
        
        Contact cntRecord= BCAPP_TestDataFactory.createContact(accountRecord.id,'ewew@dasds.com');
        insert cntRecord;
        Service_Contract__c Service_Contract=  BCAPP_TestDataFactory.createServiceContract();
        Service_Contract.Customer_Name__c=accountRecord.id;
        insert Service_Contract;
        
        Case testCase =BCAPP_TestDataFactory.createCase();
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Move In Holiday Homes').getRecordTypeId();
        testCase.RecordTypeId=RecordTypeCaseId;
        testCase.AccountId= accountRecord.id;
        testCase.Move_Out_Date__c=system.today();
        testCase.Email_Address__c='testuser@fff.com';
        insert testCase;
        
        User__c userRecord= BCAPP_TestDataFactory.createUser('testttt');
        userRecord.Email__c=testCase.Email_Address__c;
        insert userRecord;
        
        Unit__c unit= BCAPP_TestDataFactory.createUnit();
        insert unit;
        testCase.Unit__c=unit.id;
        update testCase;
        
        Unit_Allocation__c unitAllocation= BCAPP_TestDataFactory.createUnitAllocation();
        unitAllocation.Unit__c=unit.id;
        unitAllocation.User__c=userRecord.id;
        unitAllocation.Account__c=accountRecord.id;
        insert unitAllocation;
        
        try{
            Test.startTest();
            testCase.Email_Address__c='testuser@f.com';
            BCAPP_CaseController.handleMoveIn(testCase,new List<string>{'eeee@adssd.com'});
            
            testCase.User_Type__c='Tenant';
            BCAPP_CaseController.handleMoveIn(testCase,new List<string>{'eeee@adssd.com'});
            
            testCase.User_Type__c='Owner';
            BCAPP_CaseController.handleMoveIn(testCase,new List<string>{'eeee@adssd.com'});
            
            testCase.Email_Address__c='testuser@fff.com';
            BCAPP_CaseController.handleMoveIn(testCase,new List<string>{'eeee@adssd.com'});
         }
       catch(exception e){
           
       }
        Test.stopTest();

        
    }
    
    @isTest
    static void testhandleMoveInOwner() {
        
        Test.setMock(HttpCalloutMock.class, new AzureCalloutMock());
        
        Account accountRecord =BCAPP_TestDataFactory.createAccount('Test Account');
        accountRecord.Azure_UserPrincipal_Id__c='testttt';
        insert accountRecord;
        
        Contact cntRecord= BCAPP_TestDataFactory.createContact(accountRecord.id,'ewew@dasds.com');
        insert cntRecord;
        Service_Contract__c Service_Contract=  BCAPP_TestDataFactory.createServiceContract();
        Service_Contract.Customer_Name__c=accountRecord.id;
        insert Service_Contract;
        
        Case testCase =BCAPP_TestDataFactory.createCase();
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Move In Holiday Homes').getRecordTypeId();
        testCase.RecordTypeId=RecordTypeCaseId;
        testCase.AccountId= accountRecord.id;
        testCase.Move_Out_Date__c=system.today();
        testCase.Email_Address__c='testuser@fff.com';
        insert testCase;
        
        User__c userRecord= BCAPP_TestDataFactory.createUser('testttt');
        userRecord.Email__c=testCase.Email_Address__c;
        insert userRecord;
        
        Unit__c unit= BCAPP_TestDataFactory.createUnit();
        insert unit;
        testCase.Unit__c=unit.id;
        update testCase;
        
        Unit_Allocation__c unitAllocation= BCAPP_TestDataFactory.createUnitAllocation();
        unitAllocation.Unit__c=unit.id;
        unitAllocation.User__c=userRecord.id;
        unitAllocation.Account__c=accountRecord.id;
        insert unitAllocation;
        Test.startTest();
        testCase.Email_Address__c='teuser@fff.com';
        testCase.User_Type__c='Owner';
        try{
        BCAPP_CaseController.handleMoveIn(testCase,new List<string>{'eeee@adssd.com'});
        }catch(exception e){}
        Test.stopTest();
        
        
    }

    @isTest
    static void testhandleMoveInTenant() {
        
        Test.setMock(HttpCalloutMock.class, new AzureCalloutMock());
        
        Account accountRecord =BCAPP_TestDataFactory.createAccount('Test Account');
        accountRecord.Azure_UserPrincipal_Id__c='testttt';
        insert accountRecord;
        
        Contact cntRecord= BCAPP_TestDataFactory.createContact(accountRecord.id,'ewew@dasds.com');
        insert cntRecord;
        Service_Contract__c Service_Contract=  BCAPP_TestDataFactory.createServiceContract();
        Service_Contract.Customer_Name__c=accountRecord.id;
        insert Service_Contract;
        
        Case testCase =BCAPP_TestDataFactory.createCase();
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Move In Holiday Homes').getRecordTypeId();
        testCase.RecordTypeId=RecordTypeCaseId;
        testCase.AccountId= accountRecord.id;
        testCase.Move_Out_Date__c=system.today();
        testCase.Email_Address__c='testuser@fff.com';
        insert testCase;
        
        User__c userRecord= BCAPP_TestDataFactory.createUser('testttt');
        userRecord.Email__c=testCase.Email_Address__c;
        insert userRecord;
        
        Unit__c unit= BCAPP_TestDataFactory.createUnit();
        insert unit;
        testCase.Unit__c=unit.id;
        update testCase;
        
        Unit_Allocation__c unitAllocation= BCAPP_TestDataFactory.createUnitAllocation();
        unitAllocation.Unit__c=unit.id;
        unitAllocation.User__c=userRecord.id;
        unitAllocation.Account__c=accountRecord.id;
        insert unitAllocation;
        Test.startTest();
        testCase.Email_Address__c='teuser@fff.com';
        testCase.User_Type__c='Tenant';
        try{
        BCAPP_CaseController.handleMoveIn(testCase,new List<string>{'eeee@adssd.com'});
        }catch(exception e){}
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testUpdateCaseOwner1() {
        // Set up test data
        Account account = new Account(Name = 'Test Account');
        insert account;
        String RecordTypeCaseId = Utility.getRecordTypeIdByDevName(Case.SObjectType,'Payment_SR');
        
        Case testCase =BCAPP_TestDataFactory.createCase();
        testCase.RecordTypeId= RecordTypeCaseId;
        insert testCase;
        
        Test.startTest();
        Boolean result = BCAPP_CaseController.updateCaseOwner(testCase.Id);
        Test.stopTest();
        
    }
    
    @isTest
    static void testUpdateCaseOwner2() {
        // Set up test data
        Account account = new Account(Name = 'Test Account');
        insert account;
        String RecordTypeCaseId = Utility.getRecordTypeIdByDevName(Case.SObjectType,'ThirdPartyForm');
        
        Case testCase =BCAPP_TestDataFactory.createCase();
        testCase.RecordTypeId= RecordTypeCaseId;
        insert testCase;
        
        Test.startTest();
        Boolean result = BCAPP_CaseController.updateCaseOwner(testCase.Id);
        Test.stopTest();
        
    }
    
    @isTest
    static void testUpdateCaseOwner3() {
        // Set up test data
        Account account = new Account(Name = 'Test Account');
        insert account;
        String RecordTypeCaseId = Utility.getRecordTypeIdByDevName(Case.SObjectType,'Acknowledgment_Receipt');
        
        Case testCase =BCAPP_TestDataFactory.createCase();
        testCase.RecordTypeId= RecordTypeCaseId;
        insert testCase;
        
        Test.startTest();
        Boolean result = BCAPP_CaseController.updateCaseOwner(testCase.Id);
        Test.stopTest();
        
    }
    
    @isTest
    static void testUpdateCaseOwner4() {
        // Set up test data
        Account account = new Account(Name = 'Test Account');
        insert account;
        String RecordTypeCaseId = Utility.getRecordTypeIdByDevName(Case.SObjectType,'Payment_Due_Date_Update');
        
        Case testCase =BCAPP_TestDataFactory.createCase();
        testCase.RecordTypeId= RecordTypeCaseId;
        insert testCase;
        
        Test.startTest();
        Boolean result = BCAPP_CaseController.updateCaseOwner(testCase.Id);
        Test.stopTest();
        
    }
    
    @isTest
    static void testUpdateCaseStatusApproved(){
        RestContext.response = new RestResponse();

        Account accountRecord = BCAPP_TestDataFactory.createAccount('Status Account');
        insert accountRecord;

        Contact contactRecord = BCAPP_TestDataFactory.createContact(accountRecord.Id, 'status@example.com');
        insert contactRecord;

        Project__c project = BCAPP_TestDataFactory.createProject();
        insert project;

        Unit__c unit = BCAPP_TestDataFactory.createUnit();
        unit.Project__c = project.Id;
        unit.Status__c = 'Available';
        insert unit;

        Service_Catalog__c accessCatalog = new Service_Catalog__c(
            Name = 'Access Permit',
            Active__c = true,
            Access_To__c = 'Owner;Tenant',
            Service_Available_on_Mobile__c = true
        );
        insert accessCatalog;

        Map<String, Schema.RecordTypeInfo> caseRecordTypes = Schema.SObjectType.Case.getRecordTypeInfosByName();
        Id accessRecordTypeId = caseRecordTypes.containsKey('Access Permit')
            ? caseRecordTypes.get('Access Permit').getRecordTypeId()
            : caseRecordTypes.values()[0].getRecordTypeId();

        Case statusCase = new Case(
            Subject = 'Access Permit Case',
            Status = 'Submitted',
            AccountId = accountRecord.Id,
            Unit__c = unit.Id,
            Service_Catalog__c = accessCatalog.Id,
            Email_Address__c = 'applicant@example.com',
            RecordTypeId = accessRecordTypeId
        );
        insert statusCase;

        Test.startTest();
        BCAPP_CaseController.updateCaseStatus(statusCase.Id, 'Approved', 'Approved for processing');
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateCaseStatusApproved2(){
        RestContext.response = new RestResponse();

        Account accountRecord = BCAPP_TestDataFactory.createAccount('Status Account');
        insert accountRecord;

        Contact contactRecord = BCAPP_TestDataFactory.createContact(accountRecord.Id, 'status@example.com');
        insert contactRecord;

        Project__c project = BCAPP_TestDataFactory.createProject();
        insert project;

        Unit__c unit = BCAPP_TestDataFactory.createUnit();
        unit.Project__c = project.Id;
        unit.Status__c = 'Available';
        unit.Occupancy_Type__c = 'Available';
        insert unit;

        Service_Catalog__c accessCatalog = new Service_Catalog__c(
            Name = 'Move Out',
            Active__c = true,
            Access_To__c = 'Owner;Tenant',
            Service_Available_on_Mobile__c = true
        );
        insert accessCatalog;

        Map<String, Schema.RecordTypeInfo> caseRecordTypes = Schema.SObjectType.Case.getRecordTypeInfosByName();
        Id accessRecordTypeId = caseRecordTypes.containsKey('Access Permit')
            ? caseRecordTypes.get('Access Permit').getRecordTypeId()
            : caseRecordTypes.values()[0].getRecordTypeId();

        Case statusCase = new Case(
            Subject = 'Access Permit Case',
            Status = 'Submitted',
            AccountId = accountRecord.Id,
            Unit__c = unit.Id,
            Service_Catalog__c = accessCatalog.Id,
            Email_Address__c = 'applicant@example.com',
            RecordTypeId = accessRecordTypeId
        );
        insert statusCase;

        Test.startTest();
        BCAPP_CaseController.updateCaseStatus(statusCase.Id, 'Approved', 'Approved for processing');
        Test.stopTest();
    }
    
    

    @isTest
    static void testSendApprovalEmailHelper(){
        RestContext.response = new RestResponse();

        Account accountRecord = BCAPP_TestDataFactory.createAccount('Email Account');
        insert accountRecord;

        Contact contactRecord = BCAPP_TestDataFactory.createContact(accountRecord.Id, 'approval@example.com');
        insert contactRecord;

        Project__c project = BCAPP_TestDataFactory.createProject();
        insert project;

        Unit__c unit = BCAPP_TestDataFactory.createUnit();
        unit.Project__c = project.Id;
        insert unit;

        Map<String, Schema.RecordTypeInfo> caseRecordTypes = Schema.SObjectType.Case.getRecordTypeInfosByName();
        Id recordTypeId = caseRecordTypes.values()[0].getRecordTypeId();

        Case emailCase = new Case(
            Subject = 'Approval Email Case',
            Status = 'Submitted',
            AccountId = accountRecord.Id,
            RecordTypeId = recordTypeId
        );
        insert emailCase;

        final Id emailFolderId = [SELECT Id FROM Folder WHERE Type = 'Email' LIMIT 1].Id;
        EmailTemplate approvalTemplate = TestDataFactory.createEmailTemplate('Approval Template');
        approvalTemplate.DeveloperName = 'Bloom_Welcome_Email_Template_1749456253567';
        approvalTemplate.FolderId = emailFolderId;
        try{
        BCAPP_CaseController.sendApprovalEmail(approvalTemplate.DeveloperName, new List<String>{'recipient@example.com'}, false, emailCase.Id);
        }
        catch(Exception ex){
            
        }
    }
    
    @isTest
    static void test_checkDocuments_noDocuments() {
        
        Account accountRecord = BCAPP_TestDataFactory.createAccount('Email Account');
        insert accountRecord;
        Map<String, Schema.RecordTypeInfo> caseRecordTypes = Schema.SObjectType.Case.getRecordTypeInfosByName();
        Id recordTypeId = caseRecordTypes.values()[0].getRecordTypeId();
        
        Case c = new Case(
            Subject = 'Approval Email Case',
            Status = 'Submitted',
            AccountId = accountRecord.Id,
            RecordTypeId = recordTypeId
        );
        insert c;
    
        Test.startTest();
        Boolean result = BCAPP_CaseController.checkDocumentsAndSubmit(c.Id);
        Test.stopTest();
    
        System.assertEquals(false, result);
    }
    
    @isTest
    static void test_checkDocuments_missingFile() {
        Account accountRecord = BCAPP_TestDataFactory.createAccount('Email Account');
        insert accountRecord;
        Map<String, Schema.RecordTypeInfo> caseRecordTypes = Schema.SObjectType.Case.getRecordTypeInfosByName();
        Id recordTypeId = caseRecordTypes.values()[0].getRecordTypeId();
        Case c = new Case(
            Subject = 'Approval Email Case',
            Status = 'Submitted',
            AccountId = accountRecord.Id,
            RecordTypeId = recordTypeId
        );
        insert c;
    
        Customer_Document__c doc = new Customer_Document__c(Case__c = c.Id);
        insert doc;
    
        Test.startTest();
        Boolean result = BCAPP_CaseController.checkDocumentsAndSubmit(c.Id);
        Test.stopTest();
    
        System.assertEquals(false, result);
    }
    
    @isTest
    static void test_updateCaseOwner_nonFinalStep() {
        Id rtId = Utility.getRecordTypeIdByDevName(
            Case.SObjectType,
            'Post_Sale_Payment_Deferral'
        );
    
        Case c = new Case(
            Subject = 'Step Test',
            RecordTypeId = rtId,
            Status = 'New',
            Step__c = '1'
        );
        insert c;
    
        Task t = new Task(
            WhatId = c.Id,
            Status = 'Open',
            Subject = 'Test Task',
            OwnerId = UserInfo.getUserId()
        );
        insert t;
    
        Test.startTest();
        BCAPP_CaseController.updateCaseOwner(c.Id);
        Test.stopTest();
    }



    
    @IsTest
    static void test_updateCaseOwner_withDelayedCommissionCase() {
        // Get RecordType Ids
        Id delayedCommissionRT = Utility.getRecordTypeIdByDevName(Case.SObjectType, 'DelayedCommissionPayment');
        
        // Create Case with Status = 'New'
        Case testCase = new Case(
            RecordTypeId = delayedCommissionRT,
            Status = 'New',
            Step__c = 'Final',
            Subject = 'Test Case',
            City__c = 'Abu Dhabi'
        );
        insert testCase;
        
        // Create related Task
        Task t = new Task(
            WhatId = testCase.Id,
            Status = 'Open',
            Subject = 'Follow up',
            OwnerId = UserInfo.getUserId()
        );
        insert t;
        
        // Run method
        Test.startTest();
        BCAPP_CaseController.updateCaseOwner(testCase.Id);
        Test.stopTest();
    }
}