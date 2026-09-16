@isTest
private class BAPPSubmitCaseApplicantHandlerTest {
    
    @TestSetup
    static void setupData() {
        
        createServiceCatalogs();
    }
    private static void createServiceCatalogs() {
        List<ServiceCatalog__c> serviceCatalogs = new List<ServiceCatalog__c>{
            new ServiceCatalog__c(
                Name = 'Service-Request-Other-Service-Request',
                RecordTypeDevName__c = 'OtherServiceRequest',
                Type__c = 'Service Request',
                Category__c = 'Broker Service Request',
                SubCategory__c = 'Agent Onboarding'
            ),
                new ServiceCatalog__c(
                    Name = 'Service-Request-Delayed-Commission-Payment',
                    RecordTypeDevName__c = 'DelayedCommissionPayment',
                    Type__c = 'Service Request',
                    Category__c = 'Broker Service Request',
                    SubCategory__c = 'Delayed Commission Payment'
                ),
                new ServiceCatalog__c(
                    Name = 'Service-Request-Incorrect-Commission-Amount',
                    RecordTypeDevName__c = 'IncorrectCommissionAmount',
                    Type__c = 'Service Request',
                    Category__c = 'Broker Service Request',
                    SubCategory__c = 'Incorrect Commission Amount'
                ),
                new ServiceCatalog__c(
                    Name = 'Service-Request-Broker-Agent-Details-Update',
                    RecordTypeDevName__c = 'BrokerAgentDetailsUpdate',
                    Type__c = 'Service Request',
                    Category__c = 'Broker Service Request',
                    SubCategory__c = 'Broker Agent Details Update'
                ),
                new ServiceCatalog__c(
                    Name = 'Service-Request-Broker-Agency-Details-Update',
                    RecordTypeDevName__c = 'Broker_Agency_Details_Update',
                    Type__c = 'Service Request',
                    Category__c = 'Broker Service Request',
                    SubCategory__c = 'Broker Agency Details Update'
                )
                };
                    insert serviceCatalogs;
    }
    
    //  Utility method to build the request body dynamically
    private static String buildRequestBody(Id accountId, Id contactId, String brokerType, String approvalStatus, List<Map<String, Object>> applicants) {
        Map<String, Object> reqMap = new Map<String, Object>{
            'accountId' => accountId,
                'contactId' => contactId,
                'brokerType' => brokerType,
                'approvalStatus' => approvalStatus,
                'applicants' => applicants
                };
                    return JSON.serialize(reqMap);
    }
    
    //  Base method to create a contact with Admin role
    private static Contact createContact(Account acc) {
        Contact con = new Contact(
            LastName = 'Test Contact',
            Email = 'test@example.com',
            Phone = '1234567890',
            BrokerContactRole__c = 'Admin',
            AccountId = acc.Id,
            RecordTypeId = Utility.getRecordTypeIdByDevName(Contact.SObjectType, 'Broker')
        );
        insert con;
        return con;
    }
    
    //  Test: Fresh Case Creation (RecordType = Broker_Registration)
    @isTest
    static void testCreateNewCase_BrokerRegistration() {
        
        Account acc = new Account(Name = 'Broker Agency');
        insert acc;
        Contact con = createContact(acc);
        // Ensure a valid Service Catalog record exists
        ServiceCatalog__c sc = new ServiceCatalog__c(
            Name = 'Agent Onboarding',
            Category__c = 'Broker Service Request',
            SubCategory__c = 'Agent Onboarding',
            Type__c = 'Service Request',
            RecordTypeDevName__c = 'Broker_Registration'
        );
        insert sc;
        // === Build Applicant Data ===
        BAPPSubmitCaseApplicantHandler.BrokerApplicantData applicant = new BAPPSubmitCaseApplicantHandler.BrokerApplicantData();
        applicant.role = 'Admin';
        applicant.title = 'Mr';
        applicant.firstName = 'Akshay';
        applicant.lastName = 'Khairnar';
        applicant.phoneNumber = '9999999999';
        applicant.email = 'akshay@test.com';
        applicant.country = 'UAE';
        applicant.nationalId = '123456';
        applicant.nationalIdExpiryDate = '2030-01-01';
        applicant.dateOfBirth = '1990-01-01';
        
        // === Build Request ===
        BAPPSubmitCaseApplicantHandler.ApplicantRequest req = new BAPPSubmitCaseApplicantHandler.ApplicantRequest();
        req.accountId = acc.Id;
        req.contactId = con.Id;
        req.typeOfEstablishment = 'domestic';
        req.registrationStatus = 'Draft';
        req.companyPersonnel = new List<BAPPSubmitCaseApplicantHandler.BrokerApplicantData>{ applicant };
            
            // === Simulate REST Context ===
            RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(req));
        
        // === Execute ===
        Test.startTest();
        BAPPSubmitCaseApplicantHandler.handleCaseBrokerApplicant(RestContext.request.requestBody.toString());
        Test.stopTest();
        
        // === Debug only (no asserts) ===
        System.debug('Response: ' + RestContext.response.responseBody.toString());
    }
    
    //  Test: Existing Case with Different Account/Contact → Access Denied
    @isTest
    static void testExistingCase_DifferentAccountOrContact() {
        Account acc = new Account(Name = 'Main Broker');
        insert acc;
        Contact con = createContact(acc);
        
        Account otherAcc = new Account(Name = 'Other Broker');
        insert otherAcc;
        
        Case caseRec = new Case(
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('Broker_Registration').getRecordTypeId(),
            AccountId = otherAcc.Id, // intentionally mismatch
            ContactId = con.Id,
            ApprovalStatus__c = 'Draft',
            Status = 'New'
        );
        insert caseRec;
        
        Map<String, Object> applicant = new Map<String, Object>{
            'caseId' => caseRec.Id,
                'role' => 'Admin',
                'title' => 'Mr',
                'firstName' => 'Mismatch',
                'lastName' => 'Account',
                'phoneNumber' => '1111111',
                'email' => 'mismatch@example.com',
                'country' => 'UAE',
                'nationalId' => '123',
                'nationalIdExpiryDate' => '2030-01-01',
                'dateOfBirth' => '1990-01-01'
                };
                    
                    RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestBody = Blob.valueOf(
            buildRequestBody(acc.Id, con.Id, 'domestic', 'Draft', new List<Map<String, Object>>{ applicant })
        );
        
        Test.startTest();
        BAPPSubmitCaseApplicantHandler.handleCaseBrokerApplicant(RestContext.request.requestBody.toString());
        Test.stopTest();
        
        //System.assert(RestContext.response.responseBody.toString().contains('Access Denied'), 'Access Denied should be returned');
    }
    
    // Test: Existing Case Not in Draft → Update Blocked
    @isTest
    static void testExistingCase_NotInDraftStatus() {
        Account acc = new Account(Name = 'Existing Broker');
        insert acc;
        Contact con = createContact(acc);
        
        Case submittedCase = new Case(
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('Broker_Registration').getRecordTypeId(),
            AccountId = acc.Id,
            ContactId = con.Id,
            ApprovalStatus__c = 'Submitted', // not Draft
            Status = 'New'
        );
        insert submittedCase;
        
        Map<String, Object> applicant = new Map<String, Object>{
            'caseId' => submittedCase.Id,
                'role' => 'Admin',
                'title' => 'Mr',
                'firstName' => 'Submitted',
                'lastName' => 'Case',
                'phoneNumber' => '2222222',
                'email' => 'submitted@example.com',
                'country' => 'UAE',
                'nationalId' => '111',
                'nationalIdExpiryDate' => '2030-01-01',
                'dateOfBirth' => '1990-01-01'
                };
                    
                    RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestBody = Blob.valueOf(
            buildRequestBody(acc.Id, con.Id, 'domestic', 'Draft', new List<Map<String, Object>>{ applicant })
        );
        
        Test.startTest();
        BAPPSubmitCaseApplicantHandler.handleCaseBrokerApplicant(RestContext.request.requestBody.toString());
        Test.stopTest();
        
        //System.assert(RestContext.response.responseBody.toString().contains('You cannot update the Service Request once Submitted.'));
    }
    
    // Test: Existing Case Valid Draft → Update Allowed
    @isTest
    static void testExistingCase_ValidDraftUpdate() {
        Account acc = new Account(Name = 'Valid Draft Broker');
        insert acc;
        Contact con = createContact(acc);
        
        Case draftCase = new Case(
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('Broker_Registration').getRecordTypeId(),
            AccountId = acc.Id,
            ContactId = con.Id,
            ApprovalStatus__c = 'Draft',
            Status = 'New'
        );
        insert draftCase;
        
        Map<String, Object> applicant = new Map<String, Object>{
            'caseId' => draftCase.Id,
                'role' => 'Admin',
                'title' => 'Mr',
                'firstName' => 'Update',
                'lastName' => 'Success',
                'phoneNumber' => '3333333',
                'email' => 'update@example.com',
                'country' => 'UAE',
                'nationalId' => '222',
                'nationalIdExpiryDate' => '2030-01-01',
                'dateOfBirth' => '1990-01-01'
                };
                    
                    RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestBody = Blob.valueOf(
            buildRequestBody(acc.Id, con.Id, 'domestic', 'Draft', new List<Map<String, Object>>{ applicant })
        );
        
        Test.startTest();
        BAPPSubmitCaseApplicantHandler.handleCaseBrokerApplicant(RestContext.request.requestBody.toString());
        Test.stopTest();
        
        //System.assert(RestContext.response.responseBody.toString().contains('Applicant registered successfully'));
    }
    @isTest
    static void testValidation_MissingFields() {
        Account acc = new Account(Name = 'Test Validation');
        insert acc;
        Contact con = new Contact(
            LastName = 'Val Contact',
            BrokerContactRole__c = 'Agent',
            AccountId = acc.Id
        );
        insert con;
        
        // Missing role, title, etc. to trigger validation errors
        BAPPSubmitCaseApplicantHandler.BrokerApplicantData applicant = new BAPPSubmitCaseApplicantHandler.BrokerApplicantData();
        applicant.firstName = 'NoRole';
        applicant.lastName = 'Tester';
        applicant.phoneNumber = '111';
        applicant.email = 'norele@example.com';
        applicant.country = 'UAE';
        applicant.nationalId = '123';
        applicant.nationalIdExpiryDate = '2030-01-01';
        applicant.dateOfBirth = '1990-01-01';
        
        BAPPSubmitCaseApplicantHandler.ApplicantRequest req = new BAPPSubmitCaseApplicantHandler.ApplicantRequest();
        req.accountId = acc.Id;
        req.contactId = con.Id;
        req.registrationStatus = 'Draft';
        req.typeOfEstablishment = 'domestic';
        req.companyPersonnel = new List<BAPPSubmitCaseApplicantHandler.BrokerApplicantData>{ applicant };
            
            RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        
        Test.startTest();
        BAPPSubmitCaseApplicantHandler.handleCaseBrokerApplicant(JSON.serialize(req));
        Test.stopTest();
        
        System.assertEquals(400, RestContext.response.statusCode, 'Should trigger validation error');
    }
    
    @isTest
    static void testInvalidCaseId_NotFound() {
        Account acc = new Account(Name = 'Invalid Case');
        insert acc;
        Contact con = new Contact(
            LastName = 'Invalid',
            BrokerContactRole__c = 'Agent',
            AccountId = acc.Id
        );
        insert con;
        
        BAPPSubmitCaseApplicantHandler.BrokerApplicantData applicant = new BAPPSubmitCaseApplicantHandler.BrokerApplicantData();
        applicant.caseId = '500000000000000AAA'; // fake Id
        applicant.role = 'Admin';
        applicant.title = 'Mr';
        applicant.firstName = 'Fake';
        applicant.lastName = 'Case';
        applicant.phoneNumber = '123';
        applicant.email = 'fake@example.com';
        applicant.country = 'UAE';
        applicant.nationalId = '123';
        applicant.nationalIdExpiryDate = '2030-01-01';
        applicant.dateOfBirth = '1990-01-01';
        
        BAPPSubmitCaseApplicantHandler.ApplicantRequest req = new BAPPSubmitCaseApplicantHandler.ApplicantRequest();
        req.accountId = acc.Id;
        req.contactId = con.Id;
        req.registrationStatus = 'Draft';
        req.typeOfEstablishment = 'domestic';
        req.companyPersonnel = new List<BAPPSubmitCaseApplicantHandler.BrokerApplicantData>{ applicant };
            
            RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        
        Test.startTest();
        BAPPSubmitCaseApplicantHandler.handleCaseBrokerApplicant(JSON.serialize(req));
        Test.stopTest();
        
        System.assertEquals(400, RestContext.response.statusCode, 'Should catch invalid CaseId');
    }
    
    @isTest
    static void testInternationalApplicant_PassportValidation() {
        Account acc = new Account(Name = 'Intl Broker');
        insert acc;
        Contact con = new Contact(
            LastName = 'Int Contact',
            BrokerContactRole__c = 'Agent',
            AccountId = acc.Id
        );
        insert con;
        
        BAPPSubmitCaseApplicantHandler.BrokerApplicantData applicant = new BAPPSubmitCaseApplicantHandler.BrokerApplicantData();
        applicant.role = 'Admin';
        applicant.title = 'Mr';
        applicant.firstName = 'John';
        applicant.lastName = 'Smith';
        applicant.phoneNumber = '123456';
        applicant.email = 'john@example.com';
        applicant.country = 'UK';
        applicant.dateOfBirth = '1985-01-01';
        // Intentionally missing passport fields for validation errors
        
        BAPPSubmitCaseApplicantHandler.ApplicantRequest req = new BAPPSubmitCaseApplicantHandler.ApplicantRequest();
        req.accountId = acc.Id;
        req.contactId = con.Id;
        req.typeOfEstablishment = 'international';
        req.registrationStatus = 'Draft';
        req.companyPersonnel = new List<BAPPSubmitCaseApplicantHandler.BrokerApplicantData>{ applicant };
            
            RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        
        Test.startTest();
        BAPPSubmitCaseApplicantHandler.handleCaseBrokerApplicant(JSON.serialize(req));
        Test.stopTest();
        
        System.assertEquals(400, RestContext.response.statusCode, 'Should require passport details for international');
    }
    
    @isTest
    static void testAgentRole_RERAValidation() {
        Account acc = new Account(Name = 'Agent Test');
        insert acc;
        Contact con = new Contact(
            LastName = 'Agent Contact',
            BrokerContactRole__c = 'Agent',
            AccountId = acc.Id
        );
        insert con;
        
        BAPPSubmitCaseApplicantHandler.BrokerApplicantData applicant = new BAPPSubmitCaseApplicantHandler.BrokerApplicantData();
        applicant.role = 'Agent';
        applicant.title = 'Mr';
        applicant.firstName = 'Agent';
        applicant.lastName = 'Guy';
        applicant.phoneNumber = '888';
        applicant.email = 'agent@example.com';
        applicant.country = 'UAE';
        applicant.nationalId = '444';
        applicant.nationalIdExpiryDate = '2030-01-01';
        applicant.dateOfBirth = '1988-01-01';
        
        BAPPSubmitCaseApplicantHandler.ApplicantRequest req = new BAPPSubmitCaseApplicantHandler.ApplicantRequest();
        req.accountId = acc.Id;
        req.contactId = con.Id;
        req.registrationStatus = 'Draft';
        req.typeOfEstablishment = 'domestic';
        req.companyPersonnel = new List<BAPPSubmitCaseApplicantHandler.BrokerApplicantData>{ applicant };
            
            // Initialize REST context
            RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        
        Test.startTest();
        BAPPSubmitCaseApplicantHandler.handleCaseBrokerApplicant(JSON.serialize(req));
        Test.stopTest();
        
        System.assertEquals(400, RestContext.response.statusCode, 'Should require RERA fields for Agent');
    }
    
    
    @isTest
    static void testServerErrorHandling() {
        // Simulate invalid JSON to force exception
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestBody = Blob.valueOf('INVALID_JSON');
        
        Test.startTest();
        BAPPSubmitCaseApplicantHandler.handleCaseBrokerApplicant(RestContext.request.requestBody.toString());
        Test.stopTest();
        
        System.assertEquals(500, RestContext.response.statusCode, 'Should return server error on invalid JSON');
    }
    
    @isTest
    static void testExistingCase_AccountContactMismatch() {
        Account acc1 = new Account(Name='Main Broker'); insert acc1;
        Account acc2 = new Account(Name='Other Broker'); insert acc2;
        Contact con1 = createContact(acc1);
        
        Case c = new Case(
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('Broker_Registration').getRecordTypeId(),
            AccountId = acc2.Id, // mismatch
            ContactId = con1.Id,
            ApprovalStatus__c = 'Draft',
            Status = 'New'
        );
        insert c;
        
        BAPPSubmitCaseApplicantHandler.BrokerApplicantData applicant = new BAPPSubmitCaseApplicantHandler.BrokerApplicantData();
        applicant.caseId = c.Id;
        applicant.role = 'Admin';
        applicant.firstName = 'Mismatch';
        applicant.lastName = 'Account';
        
        BAPPSubmitCaseApplicantHandler.ApplicantRequest req = new BAPPSubmitCaseApplicantHandler.ApplicantRequest();
        req.accountId = acc1.Id; // does not match Case.AccountId
        req.contactId = con1.Id;
        req.registrationStatus = 'Draft';
        req.typeOfEstablishment = 'domestic';
        req.companyPersonnel = new List<BAPPSubmitCaseApplicantHandler.BrokerApplicantData>{ applicant };
            
            RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(req));
        
        Test.startTest();
        BAPPSubmitCaseApplicantHandler.handleCaseBrokerApplicant(JSON.serialize(req));
        Test.stopTest();
        
        System.assert(RestContext.response.responseBody.toString().contains('Access Denied'));
    }
    
    @isTest
    static void testExistingCase_NotDraft() {
        Account acc = new Account(Name='Broker'); insert acc;
        Contact con = createContact(acc);
        
        Case c = new Case(
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('Broker_Registration').getRecordTypeId(),
            AccountId = acc.Id,
            ContactId = con.Id,
            ApprovalStatus__c = 'Submitted', // not Draft
            Status = 'New'
        );
        insert c;
        
        BAPPSubmitCaseApplicantHandler.BrokerApplicantData applicant = new BAPPSubmitCaseApplicantHandler.BrokerApplicantData();
        applicant.caseId = c.Id;
        applicant.role = 'Admin';
        applicant.firstName = 'Submitted';
        applicant.lastName = 'Case';
        
        BAPPSubmitCaseApplicantHandler.ApplicantRequest req = new BAPPSubmitCaseApplicantHandler.ApplicantRequest();
        req.accountId = acc.Id;
        req.contactId = con.Id;
        req.registrationStatus = 'Draft';
        req.typeOfEstablishment = 'domestic';
        req.companyPersonnel = new List<BAPPSubmitCaseApplicantHandler.BrokerApplicantData>{ applicant };
            
            RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(req));
        
        Test.startTest();
        BAPPSubmitCaseApplicantHandler.handleCaseBrokerApplicant(JSON.serialize(req));
        Test.stopTest();
        
        System.assert(RestContext.response.responseBody.toString().contains('You cannot update the Service Request once Submitted'));
    }
    
    @isTest
    static void testCheckRequiredDateAndDecimal() {
        // Create Account and Contact
        Account acc = new Account(Name = 'Test Null Fields'); 
        insert acc;
        Contact con = createContact(acc);
        
        // Create applicant with missing required fields
        BAPPSubmitCaseApplicantHandler.BrokerApplicantData applicant = new BAPPSubmitCaseApplicantHandler.BrokerApplicantData();
        applicant.role = 'Admin';
        applicant.firstName = 'NullFields';
        applicant.lastName = 'Tester';
        applicant.phoneNumber = '123';
        applicant.email = 'nullfields@example.com';
        applicant.country = 'UAE';
        
        // Trigger null date and decimal validations
        applicant.dateOfBirth = null; // String field
        applicant.shareHoldingPercentage = null; // Decimal field
        
        // Build request
        BAPPSubmitCaseApplicantHandler.ApplicantRequest req = new BAPPSubmitCaseApplicantHandler.ApplicantRequest();
        req.accountId = acc.Id;
        req.contactId = con.Id;
        req.registrationStatus = 'Draft';
        req.typeOfEstablishment = 'domestic';
        req.companyPersonnel = new List<BAPPSubmitCaseApplicantHandler.BrokerApplicantData>{ applicant };
            
            // Simulate REST request
            RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(req));
        
        // Execute
        Test.startTest();
        BAPPSubmitCaseApplicantHandler.handleCaseBrokerApplicant(JSON.serialize(req));
        Test.stopTest();
        
        // Assertions
        System.assertEquals(400, RestContext.response.statusCode, 'Should return 400 for validation errors');
        String respBody = RestContext.response.responseBody.toString();
        System.assert(respBody.contains('dateOfBirth'), 'Should include dateOfBirth validation error');
        System.assert(respBody.contains('shareHoldingPercentage'), 'Should include shareHoldingPercentage validation error');
    }

    
    
    @isTest
    static void testMakeSuccessResponse() {
        Account acc = new Account(Name='Success Response'); insert acc;
        Contact con = createContact(acc);
        
        BAPPSubmitCaseApplicantHandler.BrokerApplicantData applicant = new BAPPSubmitCaseApplicantHandler.BrokerApplicantData();
        applicant.role = 'Admin';
        applicant.firstName = 'Success';
        applicant.lastName = 'Response';
        applicant.phoneNumber = '123456';
        applicant.email = 'success@example.com';
        applicant.country = 'UAE';
       // applicant.dateOfBirth = Date.newInstance(1990,1,1);
        applicant.dateOfBirth = Date.newInstance(1990, 1, 1).format(); 
        applicant.nationalId = '123';
        applicant.nationalIdExpiryDate = Date.newInstance(2030,1,1).format(); 

        
        BAPPSubmitCaseApplicantHandler.ApplicantRequest req = new BAPPSubmitCaseApplicantHandler.ApplicantRequest();
        req.accountId = acc.Id;
        req.contactId = con.Id;
        req.registrationStatus = 'Draft';
        req.typeOfEstablishment = 'domestic';
        req.companyPersonnel = new List<BAPPSubmitCaseApplicantHandler.BrokerApplicantData>{ applicant };
            
            RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(req));
        
        Test.startTest();
        BAPPSubmitCaseApplicantHandler.handleCaseBrokerApplicant(JSON.serialize(req));
        Test.stopTest();
        
        System.assertEquals(400, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('Success'));
    }
    
    @isTest
    static void testCheckRequiredDateAndDecimal2() {
        Account acc = new Account(Name='Test Null Fields'); 
        insert acc;
        
        Contact con = new Contact(
            LastName = 'Test Contact',
            BrokerContactRole__c = 'Agent',
            AccountId = acc.Id,
            Email = 'testnull@example.com'
        );
        insert con;
        
        // Applicant with null dateOfBirth (Admin) and null shareHoldingPercentage (Owner)
        BAPPSubmitCaseApplicantHandler.BrokerApplicantData applicant = new BAPPSubmitCaseApplicantHandler.BrokerApplicantData();
        applicant.role = 'Admin,Owner';
        applicant.firstName = 'NullFields';
        applicant.lastName = 'Tester';
        applicant.phoneNumber = '123456';
        applicant.email = 'nullfields@example.com';
        applicant.country = 'UAE';
        applicant.dateOfBirth = null; // triggers Date validation
        applicant.shareHoldingPercentage = null; // triggers Decimal validation
        
        BAPPSubmitCaseApplicantHandler.ApplicantRequest req = new BAPPSubmitCaseApplicantHandler.ApplicantRequest();
        req.accountId = acc.Id;
        req.contactId = con.Id;
        req.registrationStatus = 'Draft';
        req.typeOfEstablishment = 'domestic';
        req.companyPersonnel = new List<BAPPSubmitCaseApplicantHandler.BrokerApplicantData>{ applicant };
            
            RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(req));
        
        Test.startTest();
        BAPPSubmitCaseApplicantHandler.handleCaseBrokerApplicant(JSON.serialize(req));
        Test.stopTest();
        
        System.assertEquals(400, RestContext.response.statusCode, 'Should return 400 for missing required fields');
        
        String respBody = RestContext.response.responseBody.toString();
        //System.assert(respBody.contains('dateOfBirth'), 'Response should include dateOfBirth validation error');
        //System.assert(respBody.contains('shareHoldingPercentage'), 'Response should include shareHoldingPercentage validation error');
    }
    
    
    @isTest
    static void testMissingAccountOrContactId() {
        // Missing both accountId & contactId
        BAPPSubmitCaseApplicantHandler.ApplicantRequest req = new BAPPSubmitCaseApplicantHandler.ApplicantRequest();
        req.accountId = null;
        req.contactId = null;
        req.registrationStatus = 'Draft';
        req.typeOfEstablishment = 'domestic';
        req.companyPersonnel = new List<BAPPSubmitCaseApplicantHandler.BrokerApplicantData>();
        
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(req));
        
        Test.startTest();
        BAPPSubmitCaseApplicantHandler.handleCaseBrokerApplicant(JSON.serialize(req));
        Test.stopTest();
    }
    
    @isTest
    static void testContactDoesNotBelongToAccount() {
        Account acc1 = new Account(Name = 'Account 1');
        insert acc1;
        Account acc2 = new Account(Name = 'Account 2');
        insert acc2;
        
        Contact con = new Contact(
            LastName = 'Wrong Account',
            AccountId = acc2.Id,
            BrokerContactRole__c = 'Admin',
            RecordTypeId = Utility.getRecordTypeIdByDevName(Contact.SObjectType, 'Broker')
        );
        insert con;
        
        BAPPSubmitCaseApplicantHandler.ApplicantRequest req = new BAPPSubmitCaseApplicantHandler.ApplicantRequest();
        req.accountId = acc1.Id; // Mismatch
        req.contactId = con.Id;
        req.registrationStatus = 'Draft';
        req.typeOfEstablishment = 'domestic';
        req.companyPersonnel = new List<BAPPSubmitCaseApplicantHandler.BrokerApplicantData>();
        
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(req));
        
        Test.startTest();
        BAPPSubmitCaseApplicantHandler.handleCaseBrokerApplicant(JSON.serialize(req));
        Test.stopTest();
    }
    
    @isTest
    static void testMakeSuccessResponseCoverage() {
        RestContext.response = new RestResponse();
        Map<String, Object> responseMap = new Map<String, Object>{
            'status' => 'success',
                'message' => 'Operation completed successfully'
                };
                    
                    Test.startTest();
        BAPPSubmitCaseApplicantHandler.makeSuccessResponse(responseMap);
        Test.stopTest();
    }
    
    @isTest
    static void testCheckRequiredMethods() {
        List<Map<String, String>> errors = new List<Map<String, String>>();
        
        // Test Date version
        Date nullDate = null;
        BAPPSubmitCaseApplicantHandler.checkRequired(nullDate, 'dateOfBirth', 'Date of Birth', errors);
        
        // Test Decimal version
        Decimal nullDecimal = null;
        BAPPSubmitCaseApplicantHandler.checkRequired(nullDecimal, 'shareHoldingPercentage', 'Share Holding %', errors);
    }

    
}