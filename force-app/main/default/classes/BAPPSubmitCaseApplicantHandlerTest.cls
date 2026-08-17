@IsTest
private class BAPPSubmitCaseApplicantHandlerTest {

    @TestSetup
    static void setupData() {

        insert new ServiceCatalog__c(
            Name = 'Broker New Agent Registration',
            RecordTypeDevName__c = 'BrokerAgentRegistrationAndUpdate',
            Category__c = 'Broker Service Request',
            SubCategory__c = 'Broker New Agent Registration',
            Type__c = 'Service Request'
        );
    }

    private static Account createAccount() {
        Account acc = new Account(
            Name = 'Test Broker'
        );
        insert acc;
        return acc;
    }

    private static Contact createAdminContact(Id accountId) {

        Contact con = new Contact(
            LastName = 'Admin',
            AccountId = accountId,
            //Email = 'admin@test.com',
            BrokerContactRole__c = 'Admin',
            //IsActive__c = isActive,
        	Email ='johnny.depp+' + System.currentTimeMillis() + '@example.com',
        	RecordTypeId = Utility.getRecordTypeIdByDevName(Contact.SObjectType, 'Broker')
        );

        insert con;
        return con;
    }

    private static BAPPSubmitCaseApplicantHandler.ApplicantRequest buildValidRequest(
        Id accId,
        Id conId
    ) {

        BAPPSubmitCaseApplicantHandler.BrokerApplicantData applicant =
            new BAPPSubmitCaseApplicantHandler.BrokerApplicantData();

        applicant.role = 'Admin';
        applicant.title = 'Mr.';
        applicant.firstName = 'John';
        applicant.lastName = 'Doe';
        applicant.phoneNumber = '999999999';
        applicant.email = 'john@test.com';
        applicant.country = 'UAE';
        applicant.dateOfBirth = '1990-01-01';
        applicant.nationalId = '123456';
        applicant.nationalIdExpiryDate = '2030-01-01';

        BAPPSubmitCaseApplicantHandler.ApplicantRequest req =
            new BAPPSubmitCaseApplicantHandler.ApplicantRequest();

        req.accountId = accId;
        req.contactId = conId;
        req.registrationStatus = 'Draft';
        req.typeOfEstablishment = 'domestic';
        req.companyPersonnel =
            new List<BAPPSubmitCaseApplicantHandler.BrokerApplicantData>{
                applicant
            };

        return req;
    }

    @IsTest
    static void testCreateApplicantSuccess() {

        Account acc = createAccount();
        Contact con = createAdminContact(acc.Id);

        BAPPSubmitCaseApplicantHandler.ApplicantRequest req =
            buildValidRequest(acc.Id, con.Id);

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();

        Test.startTest();

        BAPPSubmitCaseApplicantHandler.handleCaseBrokerApplicant(
            JSON.serialize(req)
        );

        Test.stopTest();

        System.debug('STATUS = ' + RestContext.response.statusCode);
        System.debug('BODY = ' + RestContext.response.responseBody.toString());
        
        System.assertEquals(
            200,
            RestContext.response.statusCode,
            RestContext.response.responseBody.toString()
        );
    }

    @IsTest
    static void testMissingAccountContact() {

        BAPPSubmitCaseApplicantHandler.ApplicantRequest req =
            new BAPPSubmitCaseApplicantHandler.ApplicantRequest();

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();

        Test.startTest();

        BAPPSubmitCaseApplicantHandler.handleCaseBrokerApplicant(
            JSON.serialize(req)
        );

        Test.stopTest();

        System.assertEquals(
            400,
            RestContext.response.statusCode
        );
    }

    @IsTest
    static void testContactAccountMismatch() {

        Account acc1 = createAccount();

        Account acc2 = new Account(
            Name = 'Other Broker'
        );
        insert acc2;

        Contact con = createAdminContact(acc2.Id);

        BAPPSubmitCaseApplicantHandler.ApplicantRequest req =
            buildValidRequest(acc1.Id, con.Id);

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();

        Test.startTest();

        BAPPSubmitCaseApplicantHandler.handleCaseBrokerApplicant(
            JSON.serialize(req)
        );

        Test.stopTest();

        System.assertEquals(
            400,
            RestContext.response.statusCode
        );
    }

    @IsTest
    static void testAccessDeniedRole() {

        Account acc = createAccount();

        Contact con = new Contact(
            LastName = 'Agent',
            AccountId = acc.Id,
            BrokerContactRole__c = 'Agent',
            //IsActive__c = isActive,
        	Email ='johnny.depp+' + System.currentTimeMillis() + '@example.com',
        	RecordTypeId = Utility.getRecordTypeIdByDevName(Contact.SObjectType, 'Broker')
        );

        insert con;

        BAPPSubmitCaseApplicantHandler.ApplicantRequest req =
            buildValidRequest(acc.Id, con.Id);

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();

        Test.startTest();

        BAPPSubmitCaseApplicantHandler.handleCaseBrokerApplicant(
            JSON.serialize(req)
        );

        Test.stopTest();

        System.assertEquals(
            400,
            RestContext.response.statusCode
        );
    }

    @IsTest
    static void testValidationFailure() {

        Account acc = createAccount();
        Contact con = createAdminContact(acc.Id);

        BAPPSubmitCaseApplicantHandler.BrokerApplicantData applicant =
            new BAPPSubmitCaseApplicantHandler.BrokerApplicantData();

        applicant.firstName = 'John';

        BAPPSubmitCaseApplicantHandler.ApplicantRequest req =
            new BAPPSubmitCaseApplicantHandler.ApplicantRequest();

        req.accountId = acc.Id;
        req.contactId = con.Id;
        req.registrationStatus = 'Draft';
        req.typeOfEstablishment = 'domestic';
        req.companyPersonnel =
            new List<BAPPSubmitCaseApplicantHandler.BrokerApplicantData>{
                applicant
            };

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();

        Test.startTest();

        BAPPSubmitCaseApplicantHandler.handleCaseBrokerApplicant(
            JSON.serialize(req)
        );

        Test.stopTest();

        System.assertEquals(
            400,
            RestContext.response.statusCode
        );
    }

    @IsTest
    static void testServerError() {

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();

        Test.startTest();

        BAPPSubmitCaseApplicantHandler.handleCaseBrokerApplicant(
            'INVALID_JSON'
        );

        Test.stopTest();

        System.assertEquals(
            500,
            RestContext.response.statusCode
        );
    }

    @IsTest
    static void testMakeSuccessResponse() {

        RestContext.response = new RestResponse();

        BAPPSubmitCaseApplicantHandler.makeSuccessResponse(
            new Map<String,Object>{
                'status' => 'success'
            }
        );

        System.assertEquals(
            200,
            RestContext.response.statusCode
        );
    }

    @IsTest
    static void testCheckRequiredMethods() {

        List<Map<String,String>> errors =
            new List<Map<String,String>>();

        BAPPSubmitCaseApplicantHandler.checkRequired(
            (Date)null,
            'dob',
            'DOB',
            errors
        );

        BAPPSubmitCaseApplicantHandler.checkRequired(
            (Decimal)null,
            'share',
            'Share',
            errors
        );

        System.assertEquals(
            2,
            errors.size()
        );
    }
    @IsTest
    static void testInvalidCaseId() {
    
        Account acc = createAccount();
        Contact con = createAdminContact(acc.Id);
    
        BAPPSubmitCaseApplicantHandler.BrokerApplicantData applicant =
            new BAPPSubmitCaseApplicantHandler.BrokerApplicantData();
    
        applicant.caseId = '500000000000000AAA';
        applicant.role = 'Admin';
        applicant.title = 'Mr.';
        applicant.firstName = 'John';
        applicant.lastName = 'Doe';
        applicant.phoneNumber = '123456';
        applicant.email = 'john@test.com';
        applicant.country = 'UAE';
        applicant.dateOfBirth = '1990-01-01';
        applicant.nationalId = '123';
        applicant.nationalIdExpiryDate = '2030-01-01';
    
        BAPPSubmitCaseApplicantHandler.ApplicantRequest req =
            buildValidRequest(acc.Id, con.Id);
    
        req.companyPersonnel =
            new List<BAPPSubmitCaseApplicantHandler.BrokerApplicantData>{applicant};
    
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
    
        Test.startTest();
        BAPPSubmitCaseApplicantHandler.handleCaseBrokerApplicant(JSON.serialize(req));
        Test.stopTest();
    
        System.assertEquals(400, RestContext.response.statusCode);
    }
        @IsTest
    static void testExistingCaseAccountMismatch() {
    
        Account acc1 = createAccount();
        Account acc2 = new Account(Name='Other');
        insert acc2;
    
        Contact con1 = createAdminContact(acc1.Id);
    
        Case c = new Case(
            AccountId = acc2.Id,
            ContactId = con1.Id,
            Status='New',
            Draft__c=true,
            RecordTypeId = Utility.getRecordTypeIdByDevName(
                Case.SObjectType,
                'BrokerAgentRegistrationAndUpdate'
            )
        );
        insert c;
    
        BAPPSubmitCaseApplicantHandler.ApplicantRequest req =
            buildValidRequest(acc1.Id, con1.Id);
    
        req.companyPersonnel[0].caseId = c.Id;
    
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
    
        Test.startTest();
        BAPPSubmitCaseApplicantHandler.handleCaseBrokerApplicant(JSON.serialize(req));
        Test.stopTest();
    
        System.assertEquals(400, RestContext.response.statusCode);
    }
        @IsTest
    static void testSubmittedCaseCannotUpdate() {
    
        Account acc = createAccount();
        Contact con = createAdminContact(acc.Id);
    
        Case c = new Case(
            AccountId = acc.Id,
            ContactId = con.Id,
            Status='New',
            Draft__c=false,
            RecordTypeId = Utility.getRecordTypeIdByDevName(
                Case.SObjectType,
                'BrokerAgentRegistrationAndUpdate'
            )
        );
        insert c;
    
        BAPPSubmitCaseApplicantHandler.ApplicantRequest req =
            buildValidRequest(acc.Id, con.Id);
    
        req.companyPersonnel[0].caseId = c.Id;
    
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
    
        Test.startTest();
        BAPPSubmitCaseApplicantHandler.handleCaseBrokerApplicant(JSON.serialize(req));
        Test.stopTest();
    
        System.assertEquals(400, RestContext.response.statusCode);
    }
        @IsTest
    static void testInternationalValidation() {
    
        Account acc = createAccount();
        Contact con = createAdminContact(acc.Id);
    
        BAPPSubmitCaseApplicantHandler.ApplicantRequest req =
            buildValidRequest(acc.Id, con.Id);
    
        req.typeOfEstablishment = 'international';
    
        req.companyPersonnel[0].passportNumber = null;
        req.companyPersonnel[0].passportExpiryDate = null;
    
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
    
        Test.startTest();
        BAPPSubmitCaseApplicantHandler.handleCaseBrokerApplicant(JSON.serialize(req));
        Test.stopTest();
    
        System.assertEquals(400, RestContext.response.statusCode);
    }
        @IsTest
    static void testAgentValidation() {
    
        Account acc = createAccount();
        Contact con = createAdminContact(acc.Id);
    
        BAPPSubmitCaseApplicantHandler.ApplicantRequest req =
            buildValidRequest(acc.Id, con.Id);
    
        req.companyPersonnel[0].role = 'Agent';
    
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
    
        Test.startTest();
        BAPPSubmitCaseApplicantHandler.handleCaseBrokerApplicant(JSON.serialize(req));
        Test.stopTest();
    
        System.assertEquals(400, RestContext.response.statusCode);
    }
        @IsTest
    static void testOwnerValidation() {
    
        Account acc = createAccount();
        Contact con = createAdminContact(acc.Id);
    
        BAPPSubmitCaseApplicantHandler.ApplicantRequest req =
            buildValidRequest(acc.Id, con.Id);
    
        req.companyPersonnel[0].role = 'Owner';
        req.companyPersonnel[0].shareHoldingPercentage = null;
    
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
    
        Test.startTest();
        BAPPSubmitCaseApplicantHandler.handleCaseBrokerApplicant(JSON.serialize(req));
        Test.stopTest();
    
        System.assertEquals(400, RestContext.response.statusCode);
    }
        @IsTest
    static void testAuthorizedSignatoryValidation() {
    
        Account acc = createAccount();
        Contact con = createAdminContact(acc.Id);
    
        BAPPSubmitCaseApplicantHandler.ApplicantRequest req =
            buildValidRequest(acc.Id, con.Id);
    
        req.companyPersonnel[0].role = 'AuthorizedSignatoryOfficer';
        req.companyPersonnel[0].designation = null;
    
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
    
        Test.startTest();
        BAPPSubmitCaseApplicantHandler.handleCaseBrokerApplicant(JSON.serialize(req));
        Test.stopTest();
    
        System.assertEquals(400, RestContext.response.statusCode);
    }
}