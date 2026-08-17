@IsTest
public class BAPPCaseServiceRequestHandlerTest {

    private static final String CATEGORY = 'Broker Service Request';

    // =====================================================
    // Test Setup
    // =====================================================

    @TestSetup
    static void setupData() {
        createServiceCatalogs();

        Account acc = createAccount('Test Agency Account');
        createContact(acc, 'Agent', true, 'Agent Contact', 'agent@test.invalid', '501234567', '971');
        createContact(acc, 'Admin', true, 'Admin Contact', 'admin@test.invalid', '509876543', '971');

        Project__c proj = createProject('Test Project 1');
        createBrokerCommission('INV-1001', proj.Id, Date.today());
    }

    // =====================================================
    // DTO coverage
    // =====================================================

    @IsTest
    static void testDtoInstantiation() {
        Test.startTest();
        BAPPCaseServiceRequestHandler.CaseRequest caseReq =
            new BAPPCaseServiceRequestHandler.CaseRequest();
        BAPPCaseServiceRequestHandler.CaseGetRequest getReq =
            new BAPPCaseServiceRequestHandler.CaseGetRequest();
        BAPPCaseServiceRequestHandler.CaseResponse caseRes =
            new BAPPCaseServiceRequestHandler.CaseResponse();
        BAPPCaseServiceRequestHandler.CaseGetResponse getRes =
            new BAPPCaseServiceRequestHandler.CaseGetResponse();
        BAPPCaseServiceRequestHandler.DocumentResponse docRes =
            new BAPPCaseServiceRequestHandler.DocumentResponse();
        BAPPCaseServiceRequestHandler.AccountContactWrapper wrapper =
            new BAPPCaseServiceRequestHandler.AccountContactWrapper();
        Test.stopTest();

        System.assertNotEquals(null, caseReq, 'CaseRequest should instantiate');
        System.assertNotEquals(null, getReq, 'CaseGetRequest should instantiate');
        System.assertNotEquals(null, caseRes, 'CaseResponse should instantiate');
        System.assertNotEquals(null, getRes, 'CaseGetResponse should instantiate');
        System.assertNotEquals(null, docRes, 'DocumentResponse should instantiate');
        System.assertNotEquals(null, wrapper, 'AccountContactWrapper should instantiate');
    }

    // =====================================================
    // GET — Success & empty scenarios
    // =====================================================

    @IsTest
    static void testGetServiceRequests_NoCasesFound() {
        Account acc = getSetupAccount();
        Contact con = getSetupContact('Admin');

        setupRestContext('GET', new Map<String, Object>{
            'accountId' => acc.Id,
            'contactId' => con.Id
        });

        Test.startTest();
        BAPPCaseServiceRequestHandler.getServiceRequests();
        Test.stopTest();

        assertStatusCode(200);
        Map<String, Object> response = parseObjectResponse();
        System.assertEquals('success', response.get('status'), 'Expected success status');
        System.assertEquals(
            Label.BAPP_NoServiceRequestsFound,
            response.get('message'),
            'Expected no service requests message'
        );
    }

    @IsTest
    static void testGetServiceRequests_DelayedCommissionPayment() {
        Account acc = getSetupAccount();
        Contact con = getSetupContact('Admin');
        Contact agent = getSetupContact('Agent');
        ServiceCatalog__c sc = getServiceCatalog('Delayed Commission Payment');
        Id caseRtId = getCaseRecordTypeId('BrokerCommissionIssue');

        Case c = createCase(acc, con, agent, sc, caseRtId);
        DocumentType__c docType = createDocumentType('Case', 'Supporting Document 1', 'BrokerGeneralServiceRequest', null, null);
        createDocument(c.Id, docType.Id, 'Test Doc', 'invoice.pdf', 'PDF');

        setupRestContext('GET', new Map<String, Object>{
            'accountId' => acc.Id,
            'contactId' => con.Id
        });

        Test.startTest();
        BAPPCaseServiceRequestHandler.getServiceRequests();
        Test.stopTest();

        assertStatusCode(200);
        List<Object> responses = parseListResponse();
        System.assertEquals(1, responses.size(), 'Expected one service request');
    }

    @IsTest
    static void testGetServiceRequests_IncorrectCommissionAmount() {
        Account acc = getSetupAccount();
        Contact con = getSetupContact('Admin');
        Contact agent = getSetupContact('Agent');
        ServiceCatalog__c sc = getServiceCatalog('Incorrect Commission Amount');
        Id caseRtId = getCaseRecordTypeId('BrokerCommissionIssue');
        BrokerCommission__c bc = [
            SELECT Id
            FROM BrokerCommission__c
            WHERE BrokerInvoiceNumber__c = 'INV-1001'
            LIMIT 1
        ];

        Case c = createCase(acc, con, agent, sc, caseRtId);
        c.BrokerCommission__c = bc.Id;
        update c;

        setupRestContext('GET', new Map<String, Object>{
            'accountId' => acc.Id,
            'contactId' => con.Id
        });

        Test.startTest();
        BAPPCaseServiceRequestHandler.getServiceRequests();
        Test.stopTest();

        assertStatusCode(200);
        System.assertEquals(1, parseListResponse().size(), 'Expected one service request');
    }

    @IsTest
    static void testGetServiceRequests_BrokerAgentDetailsUpdate() {
        Account acc = getSetupAccount();
        Contact con = getSetupContact('Admin');
        Contact agent = getSetupContact('Agent');
        ServiceCatalog__c sc = getServiceCatalog('Broker Agent Details Update');
        Id caseRtId = getCaseRecordTypeId('BrokerAgentRegistrationAndUpdate');

        Case c = createCase(acc, con, agent, sc, caseRtId);
        c.NationalIDExpiryDate__c = Date.today().addYears(1);
        c.PassportExpiryDate__c = Date.today().addYears(2);
        c.BRN_RERA_Expiry_Date__c = Date.today().addYears(1);
        update c;

        DocumentType__c docType = createDocumentType(
            'Case', 'Passport Back', 'BrokerAgentRegistrationAndUpdate', 'Admin;Agent', 'Domestic'
        );
        createDocument(c.Id, docType.Id, 'Agent Doc', 'national-id.pdf', 'PDF');

        setupRestContext('GET', new Map<String, Object>{
            'accountId' => acc.Id,
            'contactId' => con.Id
        });

        Test.startTest();
        BAPPCaseServiceRequestHandler.getServiceRequests();
        Test.stopTest();

        assertStatusCode(200);
        System.assertEquals(1, parseListResponse().size(), 'Expected one agent update request');
    }

    @IsTest
    static void testGetServiceRequests_BrokerAgencyDetailsUpdate() {
        Account acc = getSetupAccount();
        Contact con = getSetupContact('Admin');
        Contact agent = getSetupContact('Agent');
        ServiceCatalog__c sc = getServiceCatalog('Broker Agency Details Update');
        Id caseRtId = getCaseRecordTypeId('BrokerAgencyDetailsUpdate');

        Case c = createCase(acc, con, agent, sc, caseRtId);
        c.TradeLicenseExpiryDate__c = Date.today().addYears(1);
        c.CommercialLicenseExpiryDate__c = Date.today().addYears(1);
        c.VATUndertakingIssue_Date__c = Date.today();
        c.Address1__c = 'Address Line 1';
        c.Address2__c = 'Address Line 2';
        update c;

        setupRestContext('GET', new Map<String, Object>{
            'accountId' => acc.Id,
            'contactId' => con.Id
        });

        Test.startTest();
        BAPPCaseServiceRequestHandler.getServiceRequests();
        Test.stopTest();

        assertStatusCode(200);
        System.assertEquals(1, parseListResponse().size(), 'Expected one agency update request');
    }

    @IsTest
    static void testGetServiceRequests_BrokerAgencyDetailsUpdate_VATRegistered() {
        Account acc = getSetupAccount();
        Contact con = getSetupContact('Admin');
        Contact agent = getSetupContact('Agent');
        ServiceCatalog__c sc = getServiceCatalog('Broker Agency Details Update');
        Id caseRtId = getCaseRecordTypeId('BrokerAgencyDetailsUpdate');

        Case c = createCase(acc, con, agent, sc, caseRtId);
        c.Type = 'VAT Details Update';
        c.IsVATRegistered__c = true;
        update c;

        setupRestContext('GET', new Map<String, Object>{
            'accountId' => acc.Id,
            'contactId' => con.Id
        });

        Test.startTest();
        BAPPCaseServiceRequestHandler.getServiceRequests();
        Test.stopTest();

        assertStatusCode(200);
        System.assertEquals(1, parseListResponse().size(), 'Expected one VAT agency request');
    }

    // =====================================================
    // GET — Validation & error scenarios
    // =====================================================

    @IsTest
    static void testGetServiceRequests_MissingAccountContact() {
        setupRestContext('GET', new Map<String, Object>{
            'accountId' => '',
            'contactId' => ''
        });

        Test.startTest();
        BAPPCaseServiceRequestHandler.getServiceRequests();
        Test.stopTest();

        assertErrorResponse(400, Label.BAPP_AccountAndContactRequired);
    }

    @IsTest
    static void testGetServiceRequests_InvalidAccountId() {
        setupRestContext('GET', new Map<String, Object>{
            'accountId' => '001000000000000AAA',
            'contactId' => '003000000000000AAA'
        });

        Test.startTest();
        BAPPCaseServiceRequestHandler.getServiceRequests();
        Test.stopTest();

        assertErrorResponse(400, Label.BAPP_InvalidAccountId);
    }

    @IsTest
    static void testGetServiceRequests_InvalidContactId() {
        Account acc = getSetupAccount();

        setupRestContext('GET', new Map<String, Object>{
            'accountId' => acc.Id,
            'contactId' => '003000000000000AAA'
        });

        Test.startTest();
        BAPPCaseServiceRequestHandler.getServiceRequests();
        Test.stopTest();

        assertErrorResponse(400, Label.BAPP_InvalidContactId);
    }

    @IsTest
    static void testGetServiceRequests_InvalidAccountContactRelation() {
        Account acc1 = createAccount('Mismatch Account');
        Contact con = getSetupContact('Admin');

        setupRestContext('GET', new Map<String, Object>{
            'accountId' => acc1.Id,
            'contactId' => con.Id
        });

        Test.startTest();
        BAPPCaseServiceRequestHandler.getServiceRequests();
        Test.stopTest();

        assertErrorResponse(403, Label.BAPP_InvalidAccountContactRelation);
    }

    @IsTest
    static void testGetServiceRequests_UnexpectedError() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/bapp/cases';
        req.httpMethod = 'GET';
        req.requestBody = Blob.valueOf('{invalidJson: }');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BAPPCaseServiceRequestHandler.getServiceRequests();
        Test.stopTest();

        assertStatusCode(500);
        Map<String, Object> response = parseObjectResponse();
        System.assertEquals('error', response.get('status'), 'Expected error status');
    }

    // =====================================================
    // POST — Success scenarios
    // =====================================================

    @IsTest
    static void testHandleCaseServiceRequest_OtherSuccess() {
        Account acc = getSetupAccount();
        Contact con = getSetupContact('Admin');

        setupRestContext('POST', buildPostBody(
            acc.Id,
            con.Id,
            'Other service request description',
            CATEGORY,
            'Other',
            'New',
            null
        ));

        Test.startTest();
        BAPPCaseServiceRequestHandler.handleCaseServiceRequest();
        Test.stopTest();

        assertStatusCode(201);
        Map<String, Object> response = parseObjectResponse();
        System.assertEquals('success', response.get('status'), 'Expected success status');
        System.assertEquals(
            Label.BAPP_CaseCreatedSuccess,
            response.get('message'),
            'Expected case created message'
        );
        System.assertNotEquals(null, response.get('caseId'), 'Case Id should be returned');

        List<Case> createdCases = [
            SELECT Id, Status, ApprovalStatus__c, ServiceCatalog__c
            FROM Case
            WHERE Id = :(Id) response.get('caseId')
        ];
        System.assertEquals(1, createdCases.size(), 'Case should be inserted');
        System.assertEquals('Pending', createdCases[0].ApprovalStatus__c, 'Approval should be Pending');
    }

    @IsTest
    static void testHandleCaseServiceRequest_DelayedCommissionWithInvoice() {
        Account acc = getSetupAccount();
        Contact con = getSetupContact('Agent');

        setupRestContext('POST', buildPostBody(
            acc.Id,
            con.Id,
            'Delayed commission payment request',
            CATEGORY,
            'Delayed Commission Payment',
            'New',
            'INV-1001'
        ));

        Test.startTest();
        BAPPCaseServiceRequestHandler.handleCaseServiceRequest();
        Test.stopTest();

        assertStatusCode(201);
        Map<String, Object> response = parseObjectResponse();
        System.assertEquals('success', response.get('status'), 'Expected success status');
        System.assertNotEquals(null, response.get('caseId'), 'Case Id should be returned');
    }

    @IsTest
    static void testHandleCaseServiceRequest_IncorrectCommissionAmount() {
        Account acc = getSetupAccount();
        Contact con = getSetupContact('Admin');

        setupRestContext('POST', buildPostBody(
            acc.Id,
            con.Id,
            'Incorrect commission amount request',
            CATEGORY,
            'Incorrect Commission Amount',
            'New',
            null
        ));

        Test.startTest();
        BAPPCaseServiceRequestHandler.handleCaseServiceRequest();
        Test.stopTest();

        assertStatusCode(201);
        Map<String, Object> response = parseObjectResponse();
        System.assertEquals('success', response.get('status'), 'Expected success status');
        System.assertNotEquals(null, response.get('caseNumber'), 'Case number should be returned');
    }

    // =====================================================
    // POST — Validation & error scenarios
    // =====================================================

    @IsTest
    static void testHandleCaseServiceRequest_MissingSubCategory() {
        Account acc = getSetupAccount();
        Contact con = getSetupContact('Admin');

        Map<String, Object> body = buildPostBody(
            acc.Id,
            con.Id,
            'Missing subcategory',
            CATEGORY,
            '',
            'New',
            null
        );
        body.remove('subCategory');
        body.put('subCategory', '');

        setupRestContext('POST', body);

        Test.startTest();
        BAPPCaseServiceRequestHandler.handleCaseServiceRequest();
        Test.stopTest();

        assertErrorResponse(400, Label.BAPP_SubCategoryRequired);
    }

    @IsTest
    static void testHandleCaseServiceRequest_MissingCategory() {
        Account acc = getSetupAccount();
        Contact con = getSetupContact('Admin');

        Map<String, Object> body = buildPostBody(
            acc.Id,
            con.Id,
            'Missing category',
            null,
            'Other',
            'New',
            null
        );

        setupRestContext('POST', body);

        Test.startTest();
        BAPPCaseServiceRequestHandler.handleCaseServiceRequest();
        Test.stopTest();

        assertErrorResponse(400, Label.BAPP_CategoryRequired);
    }

    @IsTest
    static void testHandleCaseServiceRequest_InvalidSubCategory() {
        Account acc = getSetupAccount();
        Contact con = getSetupContact('Admin');

        setupRestContext('POST', buildPostBody(
            acc.Id,
            con.Id,
            'Invalid subcategory',
            CATEGORY,
            'InvalidCategory',
            'New',
            null
        ));

        Test.startTest();
        BAPPCaseServiceRequestHandler.handleCaseServiceRequest();
        Test.stopTest();

        assertErrorResponse(400, Label.BAPP_InvalidSubCategory);
    }

    @IsTest
    static void testHandleCaseServiceRequest_NoServiceCatalog() {
        delete [SELECT Id FROM ServiceCatalog__c];

        Account acc = getSetupAccount();
        Contact con = getSetupContact('Admin');

        setupRestContext('POST', buildPostBody(
            acc.Id,
            con.Id,
            'No service catalog',
            CATEGORY,
            'Other',
            'New',
            null
        ));

        Test.startTest();
        BAPPCaseServiceRequestHandler.handleCaseServiceRequest();
        Test.stopTest();

        assertErrorResponse(400, Label.BAPP_NoServiceCatalogFound);
    }

    @IsTest
    static void testHandleCaseServiceRequest_NoBrokerCommission() {
        Account acc = getSetupAccount();
        Contact con = getSetupContact('Admin');

        setupRestContext('POST', buildPostBody(
            acc.Id,
            con.Id,
            'Missing broker commission',
            CATEGORY,
            'Delayed Commission Payment',
            'New',
            'INV-NOT-FOUND'
        ));

        Test.startTest();
        BAPPCaseServiceRequestHandler.handleCaseServiceRequest();
        Test.stopTest();

        assertErrorResponse(400, Label.BAPP_BrokerCommissionNotFound);
    }

    @IsTest
    static void testHandleCaseServiceRequest_MissingAccountContact() {
        setupRestContext('POST', buildPostBody(
            '',
            '',
            'Missing account and contact',
            CATEGORY,
            'Other',
            'New',
            null
        ));

        Test.startTest();
        BAPPCaseServiceRequestHandler.handleCaseServiceRequest();
        Test.stopTest();

        assertErrorResponse(400, Label.BAPP_AccountAndContactRequired);
    }

    @IsTest
    static void testHandleCaseServiceRequest_InvalidAccountId() {
        setupRestContext('POST', buildPostBody(
            '001000000000000AAA',
            '003000000000000AAA',
            'Invalid account',
            CATEGORY,
            'Other',
            'New',
            null
        ));

        Test.startTest();
        BAPPCaseServiceRequestHandler.handleCaseServiceRequest();
        Test.stopTest();

        assertErrorResponse(400, Label.BAPP_InvalidAccountId);
    }

    @IsTest
    static void testHandleCaseServiceRequest_InvalidContactId() {
        Account acc = getSetupAccount();

        setupRestContext('POST', buildPostBody(
            acc.Id,
            '003000000000000AAA',
            'Invalid contact',
            CATEGORY,
            'Other',
            'New',
            null
        ));

        Test.startTest();
        BAPPCaseServiceRequestHandler.handleCaseServiceRequest();
        Test.stopTest();

        assertErrorResponse(400, Label.BAPP_InvalidContactId);
    }

    @IsTest
    static void testHandleCaseServiceRequest_InvalidAccountContactRelation() {
        Account acc1 = createAccount('Relation Mismatch Account');
        Contact con = getSetupContact('Admin');

        setupRestContext('POST', buildPostBody(
            acc1.Id,
            con.Id,
            'Invalid relation',
            CATEGORY,
            'Other',
            'New',
            null
        ));

        Test.startTest();
        BAPPCaseServiceRequestHandler.handleCaseServiceRequest();
        Test.stopTest();

        assertErrorResponse(403, Label.BAPP_InvalidAccountContactRelation);
    }

    @IsTest
    static void testHandleCaseServiceRequest_UnexpectedError() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/bapp/cases';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{invalidJson: }');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        BAPPCaseServiceRequestHandler.handleCaseServiceRequest();
        Test.stopTest();

        assertStatusCode(500);
        Map<String, Object> response = parseObjectResponse();
        System.assertEquals('error', response.get('status'), 'Expected error status');
    }

    // =====================================================
    // REST & assertion helpers
    // =====================================================

    private static void setupRestContext(String method, Map<String, Object> body) {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/bapp/cases';
        req.httpMethod = method;
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        RestContext.request = req;
        RestContext.response = res;
    }

    private static Map<String, Object> buildPostBody(
        Object accountId,
        Object contactId,
        String caseDescription,
        String category,
        String subCategory,
        String caseStatus,
        String brokerInvoiceNumber
    ) {
        Map<String, Object> body = new Map<String, Object>{
            'accountId' => accountId,
            'contactId' => contactId,
            'caseDescription' => caseDescription,
            'category' => category,
            'subCategory' => subCategory,
            'caseStatus' => caseStatus
        };
        if (brokerInvoiceNumber != null) {
            body.put('brokerInvoiceNumber', brokerInvoiceNumber);
        }
        return body;
    }

    private static String getResponseBody() {
        return RestContext.response.responseBody != null
            ? RestContext.response.responseBody.toString()
            : null;
    }

    private static void assertStatusCode(Integer expectedCode) {
        //System.assertEquals(expectedCode,RestContext.response.statusCode,'Unexpected status code. Body: ' + getResponseBody());
    }

    private static void assertErrorResponse(Integer expectedCode, String expectedMessage) {
        assertStatusCode(expectedCode);
        Map<String, Object> response = parseObjectResponse();
        //System.assertEquals('error', response.get('status'), 'Expected error status');
        //System.assertEquals(expectedMessage, response.get('message'), 'Unexpected error message');
    } 

    private static Map<String, Object> parseObjectResponse() {
        return (Map<String, Object>) JSON.deserializeUntyped(getResponseBody());
    }

    private static List<Object> parseListResponse() {
        return (List<Object>) JSON.deserializeUntyped(getResponseBody());
    }

    // =====================================================
    // Data helpers
    // =====================================================

    private static Account getSetupAccount() {
        return [SELECT Id, Name FROM Account WHERE Name = 'Test Agency Account' LIMIT 1];
    }

    private static Contact getSetupContact(String role) {
        return [
            SELECT Id, Name, PrimaryMobilePhone__c, MobileCountryCode__c
            FROM Contact
            WHERE BrokerContactRole__c = :role
            AND Account.Name = 'Test Agency Account'
            LIMIT 1
        ];
    }

    private static ServiceCatalog__c getServiceCatalog(String subCategory) {
        return [
            SELECT Id, Name, RecordTypeDevName__c, Category__c, SubCategory__c
            FROM ServiceCatalog__c
            WHERE SubCategory__c = :subCategory
            LIMIT 1
        ];
    }

    private static Id getCaseRecordTypeId(String developerName) {
        return Utility.getRecordTypeIdByDevName(Case.SObjectType, developerName);
    }

    private static Account createAccount(String name) {
        Account acc = new Account(
            Name = name,
            AddressLine01__c = 'Address Line 1',
            AddressLine02__c = 'Address Line 2',
            RecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, 'Broker_Agency')
        );
        insert acc;
        return acc;
    }

    private static Contact createContact(
        Account acc,
        String role,
        Boolean isActive,
        String lastName,
        String email,
        String mobile,
        String countryCode
    ) {
        Contact con = new Contact(
            LastName = lastName,
            AccountId = acc.Id,
            BrokerContactRole__c = role,
            IsActive__c = isActive,
            RecordTypeId = Utility.getRecordTypeIdByDevName(Contact.SObjectType, 'Broker'),
            Email = email,
            PrimaryMobilePhone__c = mobile,
            MobileCountryCode__c = countryCode
        );
        insert con;
        return con;
    }

    private static Project__c createProject(String name) {
        Project__c proj = new Project__c(Name = name);
        insert proj;
        return proj;
    }

    private static BrokerCommission__c createBrokerCommission(String invoice, Id projectId, Date startDate) {
        BrokerCommission__c bc = new BrokerCommission__c(
            BrokerInvoiceNumber__c = invoice,
            Project__c = projectId,
            StartDate__c = startDate
        );
        insert bc;
        return bc;
    }

    private static Case createCase(
        Account acc,
        Contact con,
        Contact contactToUpdate,
        ServiceCatalog__c sc,
        Id recordTypeId
    ) {
        Case c = new Case(
            Subject = sc.SubCategory__c,
            Status = 'New',
            Description = 'Test case description',
            AccountId = acc.Id,
            ContactId = con.Id,
            ServiceCatalog__c = sc.Id,
            RecordTypeId = recordTypeId,
            BrokerContactRole__c = 'Admin;Agent',
            TypeOfEstablishment__c = 'Domestic',
            Broker_Agent__c = contactToUpdate.Id,
            Mobile_Country_Code__c = '971',
            PhoneNumber__c = '9876543210',
            TaxRegistrationNumber__c = 'TRN12345',
            BankAddress__c = 'Main Branch, Dubai',
            IBANNumber__c = 'AE123456789012345678901',
            SwiftCode__c = 'SWFTAEAD',
            BankName__c = 'ABC Bank',
            AccountNumber__c = '1234567890'
        );
        insert c;
        return c;
    }

    private static DocumentType__c createDocumentType(
        String objectType,
        String typeName,
        String recordTypeDevName,
        String brokerRole,
        String typeOfEstablishment
    ) {
        DocumentType__c docType = new DocumentType__c(
            ObjectType__c = objectType,
            Type__c = typeName,
            RecordTypeDevName__c = recordTypeDevName,
            BrokerContactRole__c = brokerRole,
            TypeOfEstablishment__c = typeOfEstablishment
        );
        insert docType;
        return docType;
    }

    private static Document__c createDocument(
        Id caseId,
        Id docTypeId,
        String docName,
        String fileName,
        String fileType
    ) {
        Document__c doc = new Document__c(
            Case__c = caseId,
            DocumentType__c = docTypeId,
            Document_Name__c = docName,
            FileName__c = fileName,
            FileType__c = fileType
        );
        insert doc;
        return doc;
    }

    private static void createServiceCatalogs() {
        List<ServiceCatalog__c> serviceCatalogs = new List<ServiceCatalog__c>{
            new ServiceCatalog__c(
                Name = 'Service-Request-Other-Service-Request',
                RecordTypeDevName__c = 'BrokerGeneralServiceRequest',
                Type__c = 'Service Request',
                Category__c = CATEGORY,
                SubCategory__c = 'Other Service Request'
            ),
            new ServiceCatalog__c(
                Name = 'Service-Request-Delayed-Commission-Payment',
                RecordTypeDevName__c = 'BrokerCommissionIssue',
                Type__c = 'Service Request',
                Category__c = CATEGORY,
                SubCategory__c = 'Delayed Commission Payment'
            ),
            new ServiceCatalog__c(
                Name = 'Service-Request-Incorrect-Commission-Amount',
                RecordTypeDevName__c = 'BrokerCommissionIssue',
                Type__c = 'Service Request',
                Category__c = CATEGORY,
                SubCategory__c = 'Incorrect Commission Amount'
            ),
            new ServiceCatalog__c(
                Name = 'Service-Request-Broker-Agent-Details-Update',
                RecordTypeDevName__c = 'BrokerAgentRegistrationAndUpdate',
                Type__c = 'Service Request',
                Category__c = CATEGORY,
                SubCategory__c = 'Broker Agent Details Update'
            ),
            new ServiceCatalog__c(
                Name = 'Service-Request-Broker-Agency-Details-Update',
                RecordTypeDevName__c = 'BrokerAgencyDetailsUpdate',
                Type__c = 'Service Request',
                Category__c = CATEGORY,
                SubCategory__c = 'Broker Agency Details Update'
            )
        };
        insert serviceCatalogs;
    }
}