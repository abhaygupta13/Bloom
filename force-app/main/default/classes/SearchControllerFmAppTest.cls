@isTest
public class SearchControllerFmAppTest {

    // Test Setup Method
    @testSetup
    public static void setupTestData() {
        // Create test Account
        Account accountRecord = BCAPP_TestDataFactory.createAccount('Test Account');
        accountRecord.Azure_UserPrincipal_Id__c = 'testttt';
       // accountRecord.PersonEmail = 'test@testBloom.com';
        insert accountRecord;

        // Create test Contact
        Contact cntRecord = BCAPP_TestDataFactory.createContact(accountRecord.id, '34242@saddas.com');
        insert cntRecord;

        // Create test User
        User__c userRecord = new User__c(Azure_UserId__c = 'testUserId', Gate_Name__c = 'BG Gate 1');
        userRecord.Email__c = '34242@saddas.com';
        userRecord.Account__c = accountRecord.id;
        insert userRecord;

        // Create test Project
        Project__c testProject = BCAPP_TestDataFactory.createProject();
        testProject.isEnabledMIP__c = true;
        testProject.Gate_Name__c = 'BG Gate 1';
        insert testProject;

        // Create test BuildingSection
        BuildingSection__c testBuildingSection = BCAPP_TestDataFactory.createBuildingSection('Test');
        testBuildingSection.Project__c = testProject.id;
        insert testBuildingSection;

        // Create test Service Catalog
        Service_Catalog__c ren_serviceCatalog = new Service_Catalog__c(Name = 'Access Permit');
        insert ren_serviceCatalog;

        // Create test Unit
        Unit__c testUnit = BCAPP_TestDataFactory.createUnit();
        testUnit.Project__c = testProject.Id;
        insert testUnit;

        // Create test Case record
        Case testCase = new Case(
            RequestType__c = 'Access Permit',
            Status = 'Submitted',
            Project__c = testProject.Id,
            Unit__c = testUnit.Id,
            Access_Permit_Category__c = 'Delivery',
            Permit_Validaity__c = '1',
            Service_Types__c = 'Furniture',
            User_Type__c = 'Tenant',
            Service_Catalog__c = ren_serviceCatalog.Id,
            recordTypeId = Utilities.getRecordTypeId('Case', BCAPP_Constants.ACCESS_PERMIT),
            accountId = accountRecord.id,
            Access_Permit_Preferred_Date__c = system.today(),
            Email_Address__c = userRecord.Email__c
        );
        insert testCase;
    }

    // Test constructor with valid token
    @isTest
    public static void testSearchControllerFmAppConstructor_validToken() {
        // Fetch the first User__c record with Azure_UserId__c
        User__c userRecord = [SELECT Azure_UserId__c FROM User__c LIMIT 1];

        // Simulate the correct token in the request header
        Test.startTest();
        ApexPages.currentPage().getHeaders().put('X-App-Auth', userRecord.Azure_UserId__c); // Set header with token
        SearchControllerFmApp controller = new SearchControllerFmApp(); // Constructor will execute
        Test.stopTest();
    }

    // Test constructor with invalid token (unauthorized access)
    @isTest
    public static void testSearchControllerFmAppConstructor_invalidToken() {
        // Simulate an invalid token
        Test.startTest();
        ApexPages.currentPage().getHeaders().put('X-App-Auth', 'invalidToken'); // Set incorrect token
        try {
            SearchControllerFmApp controller = new SearchControllerFmApp();
            Test.stopTest();
        } catch (AuraHandledException e) {
            // Handle exception (no assertion needed)
        }
    }

    // Test search functionality
    @isTest
    public static void testSearchRecords() {
        Case testCase = [SELECT Request_Number__c FROM Case LIMIT 1];

        // Call the searchRecords method with the search term and user ID
        Test.startTest();
        List<Case> result = SearchControllerFmApp.searchRecords(testCase.Request_Number__c, 'testUserId','checkin');
        Test.stopTest();
    }

    // Test getCaseDetails method
    @isTest
    public static void testGetCaseDetails() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        // Call the getCaseDetails method
        Test.startTest();
        Case result = SearchControllerFmApp.getCaseDetails(testCase.Id);
        Test.stopTest();
    }

    // Test saveCaseDetails method
    @isTest
    public static void testSaveCaseDetails() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];

       SearchControllerFmApp.CaseDetailsWrapper details = new SearchControllerFmApp.CaseDetailsWrapper();
details.tradeCommercialNumber = '12345';
details.caseId = testCase.Id;
details.mobileNumber = '9876543210';
details.mobileCode = '971';
details.emiratesId = 'EMIRATESID';
details.vechilePlate = 'AB123';
details.contentDocumentIds = new List<String>{'doc1'};
details.actionlevel = 'Approved';
details.checkinTime = '2025-01-25T08:00:00Z';
details.plateSource = 'DXB0122';
details.plateCode = 'Dubai';
details.plateNumber = '3333';

        Test.startTest();
        SearchControllerFmApp.saveCaseDetails(details);
        Test.stopTest();
    }

    // Test createCases method
    @isTest
    public static void testCreateCases() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        // Create details wrapper for creating a new case
       SearchControllerFmApp.CaseDetailsWrapper details = new SearchControllerFmApp.CaseDetailsWrapper();
details.tradeCommercialNumber = '12345';
details.caseId = testCase.Id;
details.mobileNumber = '9876543210';
details.mobileCode = '971';
details.emiratesId = 'EMIRATESID';
details.vechilePlate = 'AB123';
details.contentDocumentIds = new List<String>{'doc1'};
details.actionlevel = 'Approved';
details.checkinTime = '2025-01-25T08:00:00Z';
details.plateSource = 'DXB0122';
details.plateCode = 'Dubai';
details.plateNumber = '3333';
//SearchControllerFmApp.CaseDetailsWrapper(details);

        
     details.plateNumber = '3444444';
        
        

        // Create wrapper using the correct constructor
        SearchControllerFmApp.CaseDetailsWrapper details2 = new SearchControllerFmApp.CaseDetailsWrapper(
            '12345',                        // tradeCommercialNumber
            testCase.Id,                    // caseId
            '987654321',                    // mobileNumber
            '971',                          // mobileCode
            'EMIRATESID123',                // EmiratesId
            'ABC123',                       // VechilePlate
            new List<String>{'doc1'},       // contentDocumentIds
            'Approved',                     // actionlevel
            '2025-01-25T08:00:00Z'          // checkinTime
        );

        Test.startTest();
        SearchControllerFmApp.createCases(details,true);
        SearchControllerFmApp.getDocument(testCase.Id);
        SearchControllerFmApp.saveCheckoutDetails(testCase.Id,true);
        SearchControllerFmApp.getAuthHeader();
        SearchControllerFmApp.getchildCases(testCase.Id);
        Test.stopTest();
    }
}