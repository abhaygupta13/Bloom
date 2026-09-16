@IsTest
public class BAPPAgencyInfoUpdateHandlerTest {
    
    @TestSetup
    static void setupData() {
        // Create required service catalog
        createServiceCatalogs();
        
        // Base Account & Contacts
        Account acc = new Account(Name = 'Test Broker Agency');
        insert acc;
        
        Contact conAgent = createContact(acc, 'Agent', true, 'Agent Contact');
        Contact conAdmin = createContact(acc, 'Admin', true, 'Admin Contact');
        Contact conPartner = createContact(acc, 'Partner', true, 'Partner Contact');
        Contact conNullRole = createContact(acc, null, true, 'Null Role Contact');
    }
    
    @IsTest
    static void testCreateCase_Success() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Broker Agency' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE BrokerContactRole__c = 'Admin' LIMIT 1];
        
        BAPPAgencyInfoUpdateHandler.AgencyInfoUpdateRequest req = new BAPPAgencyInfoUpdateHandler.AgencyInfoUpdateRequest();
        req.accountId = acc.Id;
        req.contactId = con.Id;
        req.caseDescription = 'Test Case';
        req.caseStatus = 'New';
        req.serviceRequestType = 'Broker Service Request';
        req.category = 'Broker Service Request';
        req.subCategory = 'Broker Agency Details Update';
        //req.TypeOfEstablishment__c = 'Domestic';
        req.agencyInformation = new BAPPAgencyInfoUpdateHandler.AgencyInformation();
        req.agencyInformation.tradeLicenseExpiryDate = Date.today().addDays(10);
        req.agencyInformation.isVatRegistered = true;
        
        req.addressDetails = new BAPPAgencyInfoUpdateHandler.AddressDetails();
        req.addressDetails.addressLine01 = 'Line 1';
        req.addressDetails.countryCode = '+971';
        req.addressDetails.companyPhoneNumber = '9999999';
        
        req.bankDetails = new BAPPAgencyInfoUpdateHandler.BankDetails();
        req.bankDetails.bankName = 'ABC Bank';
        req.bankDetails.accountNumber = '12345';
        req.bankDetails.iban = 'AE1234567890';
        
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(req));
        
        Test.startTest();
        BAPPAgencyInfoUpdateHandler.handleAgencyInfoUpdate(JSON.serialize(req));
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateCase_Success() {
        // === Setup REST Context (needed for sendSuccess/sendError) ===
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;
        
        // === Setup Data ===
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Broker Agency' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE BrokerContactRole__c = 'Admin' LIMIT 1];
        ServiceCatalog__c sc = [SELECT Id FROM ServiceCatalog__c WHERE SubCategory__c = 'Broker Agency Details Update' LIMIT 1];
        System.debug('sc--->'+sc);
        Id rtId = Utility.getRecordTypeIdByDevName(Case.SObjectType, 'Broker_Agency_Details_Update');
        
        // Ensure document types exist
        createDocumentType('Case', 'Other', 'Broker_Agency_Details_Update', 'Admin;Agent', 'Domestic');
        createDocumentType('Case', 'Other', 'Broker_Agency_Details_Update', 'Admin;Agent', 'International');
        
        // === Insert Case (existing one for update) ===
        Case c = new Case(
            AccountId = acc.Id,
            ContactId = con.Id,
            RecordTypeId = rtId,
            ServiceCatalog__c = sc.Id,
            Status = 'New',
            ApprovalStatus__c = 'Draft',
            Description = 'Existing',
            TypeOfEstablishment__c = 'Domestic'
        );
        insert c;
        
        // === Add a related document to trigger the document fetch loop ===
        DocumentType__c docType = [SELECT Id FROM DocumentType__c LIMIT 1];
        //   Document__c doc = new Document__c(Name = 'Test Doc',RelatedRecord__c = c.Id,DocumentType__c = docType.Id);
        // insert doc;
        
        // === Build Request ===
        BAPPAgencyInfoUpdateHandler.AgencyInfoUpdateRequest reqObj = new BAPPAgencyInfoUpdateHandler.AgencyInfoUpdateRequest();
        reqObj.accountId = acc.Id;
        reqObj.contactId = con.Id;
        reqObj.caseId = c.Id;
        reqObj.caseDescription = 'Updated Description';
        reqObj.caseStatus = 'Approved';
        reqObj.serviceRequestType = 'Broker Service Request';
        reqObj.subCategory = 'Broker Agency Details Update';
        
        reqObj.agencyInformation = new BAPPAgencyInfoUpdateHandler.AgencyInformation();
        reqObj.agencyInformation.tradeLicenseExpiryDate = Date.today().addDays(10);
        reqObj.agencyInformation.isVatRegistered = true;
        
        reqObj.addressDetails = new BAPPAgencyInfoUpdateHandler.AddressDetails();
        reqObj.addressDetails.addressLine01 = 'Line 1';
        reqObj.addressDetails.countryCode = '+971';
        reqObj.addressDetails.companyPhoneNumber = '9999999';
        
        reqObj.bankDetails = new BAPPAgencyInfoUpdateHandler.BankDetails();
        reqObj.bankDetails.bankName = 'ABC Bank';
        reqObj.bankDetails.accountNumber = '12345';
        reqObj.bankDetails.iban = 'AE1234567890';
        
        // === Execute ===
        Test.startTest();
        BAPPAgencyInfoUpdateHandler.handleAgencyInfoUpdate(JSON.serialize(reqObj));
        Test.stopTest();
        
        // === Optional Debug (no asserts) ===
        System.debug('Response: ' + RestContext.response.responseBody);
    }
    
    @IsTest
    static void testAccessDenied_NoBrokerContactRole() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Broker Agency' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE BrokerContactRole__c = 'Agent' LIMIT 1];
        
        // Build request
        Map<String, Object> body = new Map<String, Object>{
            'accountId' => acc.Id,
                'contactId' => con.Id
                };
                    setupRestContext('POST', body);
        
        Test.startTest();
        BAPPAgencyInfoUpdateHandler.handleAgencyInfoUpdate(JSON.serialize(body));
        Test.stopTest();
    }
    
    
    @IsTest
    static void testMissingAccountAndContact_InvalidRequest() {
        // Simulate an empty request body (null accountId and contactId)
        BAPPAgencyInfoUpdateHandler.AgencyInfoUpdateRequest req = 
            new BAPPAgencyInfoUpdateHandler.AgencyInfoUpdateRequest();
        
        // Setup fake REST context
        RestRequest r = new RestRequest();
        RestResponse res = new RestResponse();
        r.requestUri = '/services/apexrest/BAPPAgencyInfoUpdate';
        r.httpMethod = 'POST';
        r.addHeader('Content-Type', 'application/json');
        r.requestBody = Blob.valueOf(JSON.serialize(req));
        RestContext.request = r;
        RestContext.response = res;
        
        // Execute method — this will trigger sendError(...) and return
        Test.startTest();
        BAPPAgencyInfoUpdateHandler.handleAgencyInfoUpdate(JSON.serialize(req));
        Test.stopTest();
    }

    @IsTest
    static void testContactDoesNotBelongToAccount() {
        // Create two different accounts
        Account acc1 = new Account(Name = 'Account 1');
        insert acc1;
        Account acc2 = new Account(Name = 'Account 2');
        insert acc2;
        
        // Contact belongs to acc1
        Contact con = new Contact(LastName = 'Mismatch', AccountId = acc1.Id);
        insert con;
        
        // Prepare input with different accountId (acc2)
        Map<String, Object> body = new Map<String, Object>{
            'accountId' => acc2.Id,
                'contactId' => con.Id,
                'category' => 'Broker Service Request',
                'subCategory' => 'Other'
                };
                    
                    // Setup REST context
                    RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/BAPPAgencyInfoUpdate';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        RestContext.request = req;
        RestContext.response = res;
        
        // Run test
        Test.startTest();
        BAPPAgencyInfoUpdateHandler.handleAgencyInfoUpdate(JSON.serialize(body));
        Test.stopTest();
    }

    @IsTest
    static void testBlankBrokerContactRoleAccessDenied() {
        // Create account and contact (with blank BrokerContactRole__c)
        Account acc = new Account(Name = 'Broker Account');
        insert acc;
        
        Contact con = new Contact(
            LastName = 'NoRole',
            AccountId = acc.Id,
            BrokerContactRole__c = null
        );
        insert con;
        
        // Prepare valid input (same account-contact)
        Map<String, Object> body = new Map<String, Object>{
            'accountId' => acc.Id,
                'contactId' => con.Id,
                'category' => 'Broker Service Request',
                'subCategory' => 'Other'
                };
                    
                    // Setup REST context
                    RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/BAPPAgencyInfoUpdate';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        RestContext.request = req;
        RestContext.response = res;
        
        // Run test
        Test.startTest();
        BAPPAgencyInfoUpdateHandler.handleAgencyInfoUpdate(JSON.serialize(body));
        Test.stopTest();
    }

    
    @IsTest
    static void testInvalidJson() {
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf('invalid_json_here');
        
        Test.startTest();
        BAPPAgencyInfoUpdateHandler.handleAgencyInfoUpdate('invalid_json_here');
        Test.stopTest();
    }
    
    @IsTest
    static void testBuildAgencyInfoUpdateResponse() {
        // ----------------------
        // Step 1: Create Test Data
        // ----------------------
        Account acc = new Account(
            Name = 'Test Account',
            Phone = '1234567890'
        );
        insert acc;

        Contact con = new Contact(
            LastName = 'Test Contact',
            AccountId = acc.Id
        );
        insert con;
        
        ServiceCatalog__c sc = [SELECT Id FROM ServiceCatalog__c WHERE SubCategory__c = 'Broker Agency Details Update' LIMIT 1];
        Id rtId = Utility.getRecordTypeIdByDevName(Case.SObjectType, 'Broker_Agency_Details_Update');

        Case c = new Case(
            AccountId = acc.Id,
            ContactId = con.Id,
            RecordTypeId = rtId,
            ServiceCatalog__c = sc.Id,
            Status = 'New',
            ApprovalStatus__c = 'Draft',
            Description = 'Existing',
            TypeOfEstablishment__c = 'Domestic'
        );
        insert c;

        // ----------------------
        // Step 2: Create Input Request
        // ----------------------
        BAPPAgencyInfoUpdateHandler.AgencyInfoUpdateRequest inputReq = 
            new BAPPAgencyInfoUpdateHandler.AgencyInfoUpdateRequest();
        inputReq.serviceRequestType = 'Broker Service Request';
        inputReq.bankDetails = new BAPPAgencyInfoUpdateHandler.BankDetails();
        inputReq.agencyInformation = new BAPPAgencyInfoUpdateHandler.AgencyInformation();

        // ----------------------
        // Step 3: Call @TestVisible Method
        // ----------------------
        Map<String, Object> response = BAPPAgencyInfoUpdateHandler.buildAgencyInfoUpdateResponse(
            c, acc, con, inputReq
        );

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
    
    private static void createServiceCatalogs() {
        List<ServiceCatalog__c> serviceCatalogs = new List<ServiceCatalog__c>{
            new ServiceCatalog__c(
                Name = 'Service-Request-Other-Service-Request',
                RecordTypeDevName__c = 'OtherServiceRequest',
                Type__c = 'Service Request',
                Category__c = 'Broker Service Request',
                SubCategory__c = 'Other'
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
    
    private static Contact createContact(Account acc, String role, Boolean isActive, String lastName) {
        Contact con = new Contact(
            LastName = lastName,
            AccountId = acc.Id,
            BrokerContactRole__c = role,
            IsActive__c = isActive,
            RecordTypeId = Utility.getRecordTypeIdByDevName(Contact.SObjectType, 'Broker')
        );
        insert con;
        return con;
    }
    
    private static DocumentType__c createDocumentType(String objectType,String typeName,String recordTypeDevName,String brokerRole,String typeOfEstablishment) {
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
    
    
    private static Document__c createDocument(Id caseId, Id docTypeId, String docName, String fileName, String fileType) {
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
    
    // Helper method to simulate REST API request and response
    private static void setupRestContext(String method, Object body) {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestUri = '/services/apexrest/BAPPAgencyInfoUpdate';
        req.httpMethod = method;
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        
        RestContext.request = req;
        RestContext.response = res;
    }

    
    
}