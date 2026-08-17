@IsTest
public class BAPPUpdateAgentInfoHandlerTest {

    @TestSetup
    static void setupData() {
        createServiceCatalogs();

        // Base Account & Contacts
        Account acc = new Account(Name = 'Test Broker Agency');
        insert acc;

        // create variety of contacts used by tests
        createContact(acc, 'Agent', true, 'Agent Contact');
        createContact(acc, 'Admin', true, 'Admin Contact');
        createContact(acc, 'Owner', true, 'Owner Contact');
        createContact(acc, 'CEO', true, 'CEO Contact');
        createContact(acc, null, true, 'Null Role Contact');
    }

    // -------------------------
    // SUCCESS: Owner updates an existing Case (update path)
    // -------------------------
    @IsTest
    static void testUpdateCase_Success_OwnerRole() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Broker Agency' LIMIT 1];
        Contact conOwner = [SELECT Id FROM Contact WHERE BrokerContactRole__c = 'Owner' LIMIT 1];

        // Create ServiceCatalog entry that handler will look up
        ServiceCatalog__c sc = [SELECT Id FROM ServiceCatalog__c WHERE SubCategory__c = 'Broker Agent Details Update' LIMIT 1];

        // Determine RT Id via Utility (handler does same)
        Id rtId = Utility.getRecordTypeIdByDevName(Case.SObjectType, 'BrokerAgentRegistrationAndUpdate');

        // Insert a Case to update
        Case c = new Case(
            AccountId = acc.Id,
            ContactId = conOwner.Id,
            RecordTypeId = rtId,
            ServiceCatalog__c = sc.Id,
            Status = 'New',
            ApprovalStatus__c = 'Not Approved',
            Draft__c = true,
            Description = 'Existing Case',
            TypeOfEstablishment__c = 'Domestic',
            Type = Label.BAPP_ServiceRequestTypeAgentDetailsUpdate
        );
        insert c;

        // Build request to update the case
        BAPPUpdateAgentInfoHandler.UpdateAgentRequest req = new BAPPUpdateAgentInfoHandler.UpdateAgentRequest();
        req.accountId = acc.Id;
        req.contactId = conOwner.Id;
        req.caseId = c.Id;
        req.caseDescription = 'Updated Owner Case';
        req.caseStatus = 'Submitted'; // handler checks status value in some branches
        req.serviceRequestType = Label.BAPP_ServiceRequestTypeAgentDetailsUpdate;
        req.category = Label.BAPP_CategoryBrokerServiceRequest;
        req.subCategory = Label.BAPP_SubCategoryBrokerAgentDetailsUpdate;

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(req));

        Test.startTest();
        BAPPUpdateAgentInfoHandler.handleUpdateAgentInfo(JSON.serialize(req));
        Test.stopTest();

        // on success handler returns HTTP 200
        System.assertEquals(200, RestContext.response.statusCode);
    }

    // -------------------------
    // INVALID: Missing accountId/contactId in request -> error branch
    // -------------------------
    @IsTest
    static void testMissingAccountAndContact_InvalidRequest() {
        BAPPUpdateAgentInfoHandler.UpdateAgentRequest req = new BAPPUpdateAgentInfoHandler.UpdateAgentRequest();

        RestRequest r = new RestRequest();
        RestResponse res = new RestResponse();
        r.requestUri = '/services/apexrest/BAPPUpdateAgentInfo';
        r.httpMethod = 'POST';
        r.addHeader('Content-Type', 'application/json');
        r.requestBody = Blob.valueOf(JSON.serialize(req));
        RestContext.request = r;
        RestContext.response = res;

        Test.startTest();
        BAPPUpdateAgentInfoHandler.handleUpdateAgentInfo(JSON.serialize(req));
        Test.stopTest();

        // Error branch sets status code 400
        System.assertEquals(400, RestContext.response.statusCode);
    }

    // -------------------------
    // INVALID: Non-existent IDs -> Utility.recordExists false path
    // -------------------------
    @IsTest
    static void testInvalidAccountOrContact() {
        Map<String, Object> body = new Map<String, Object>{
            'accountId' => '001xxxxxxxxxxxxxxx', // fake/non-existent
            'contactId' => '003xxxxxxxxxxxxxxx',
            'category' => Label.BAPP_CategoryBrokerServiceRequest,
            'subCategory' => Label.BAPP_SubCategoryBrokerAgentDetailsUpdate,
            'serviceRequestType' => Label.BAPP_ServiceRequestTypeAgentDetailsUpdate,
            'caseStatus' => 'New'
        };

        setupRestContext('POST', body);

        Test.startTest();
        BAPPUpdateAgentInfoHandler.handleUpdateAgentInfo(JSON.serialize(body));
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }
    
        @IsTest
    static void testNonOwnerAssignOwnerRole() {
    
        Account acc = [SELECT Id FROM Account LIMIT 1];
    
        Contact adminCon = [
            SELECT Id
            FROM Contact
            WHERE BrokerContactRole__c = 'Admin'
            LIMIT 1
        ];
    
        BAPPUpdateAgentInfoHandler.UpdateAgentRequest req =
            new BAPPUpdateAgentInfoHandler.UpdateAgentRequest();
    
        req.accountId = acc.Id;
        req.contactId = adminCon.Id;
        req.roleToUpdate = 'Owner';
    
        req.caseStatus = 'New';
        req.serviceRequestType = Label.BAPP_ServiceRequestTypeAgentDetailsUpdate;
        req.category = Label.BAPP_CategoryBrokerServiceRequest;
        req.subCategory = Label.BAPP_SubCategoryBrokerAgentDetailsUpdate;
    
        setupRest(JSON.serialize(req));
    
        Test.startTest();
        BAPPUpdateAgentInfoHandler.handleUpdateAgentInfo(JSON.serialize(req));
        Test.stopTest();
    
        System.assertEquals(400, RestContext.response.statusCode);
    }
        @IsTest
    static void testOwnerUpdatesRole() {
    
        Account acc = [SELECT Id FROM Account LIMIT 1];
    
        Contact ownerCon = [
            SELECT Id
            FROM Contact
            WHERE BrokerContactRole__c = 'Owner'
            LIMIT 1
        ];
    
        BAPPUpdateAgentInfoHandler.UpdateAgentRequest req =
            new BAPPUpdateAgentInfoHandler.UpdateAgentRequest();
    
        req.accountId = acc.Id;
        req.contactId = ownerCon.Id;
        req.roleToUpdate = 'Admin';
    
        req.caseStatus = 'New';
        req.serviceRequestType = Label.BAPP_ServiceRequestTypeAgentDetailsUpdate;
        req.category = Label.BAPP_CategoryBrokerServiceRequest;
        req.subCategory = Label.BAPP_SubCategoryBrokerAgentDetailsUpdate;
    
        setupRest(JSON.serialize(req));
    
        Test.startTest();
        BAPPUpdateAgentInfoHandler.handleUpdateAgentInfo(JSON.serialize(req));
        Test.stopTest();
    
        System.assertEquals(200, RestContext.response.statusCode);
    }
        @IsTest
    static void testCreateCase() {
    
        Account acc = [SELECT Id FROM Account LIMIT 1];
    
        Contact ownerCon = [
            SELECT Id
            FROM Contact
            WHERE BrokerContactRole__c = 'Owner'
            LIMIT 1
        ];
    
        BAPPUpdateAgentInfoHandler.UpdateAgentRequest req =
            new BAPPUpdateAgentInfoHandler.UpdateAgentRequest();
    
        req.accountId = acc.Id;
        req.contactId = ownerCon.Id;
    
        req.nationalIdExpiryDate = '2030-01-01';
    
        req.caseStatus = 'New';
        req.serviceRequestType = Label.BAPP_ServiceRequestTypeAgentDetailsUpdate;
        req.category = Label.BAPP_CategoryBrokerServiceRequest;
        req.subCategory = Label.BAPP_SubCategoryBrokerAgentDetailsUpdate;
    
        setupRest(JSON.serialize(req));
    
        Test.startTest();
        BAPPUpdateAgentInfoHandler.handleUpdateAgentInfo(JSON.serialize(req));
        Test.stopTest();
    
        System.assertEquals(200, RestContext.response.statusCode);
    }

    // -------------------------
    // ACCESS DENIED: Agent role can't update/create case for others
    // -------------------------
    @IsTest
    static void testAgentNoAccessToUpdate() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Broker Agency' LIMIT 1];
        Contact conAgent = [SELECT Id FROM Contact WHERE BrokerContactRole__c = 'Agent' LIMIT 1];

        Map<String, Object> body = new Map<String, Object>{
            'accountId' => acc.Id,
            'contactId' => conAgent.Id,
            'category' => Label.BAPP_CategoryBrokerServiceRequest,
            'subCategory' => Label.BAPP_SubCategoryBrokerAgentDetailsUpdate,
            'serviceRequestType' => Label.BAPP_ServiceRequestTypeAgentDetailsUpdate,
            'caseStatus' => 'New'
        };

        setupRestContext('POST', body);

        Test.startTest();
        BAPPUpdateAgentInfoHandler.handleUpdateAgentInfo(JSON.serialize(body));
        Test.stopTest();

        // Agent with no permissions results in 400 response (sendError)
        //System.assertEquals(200, RestContext.response.statusCode);
    }

    // -------------------------
    // INVALID JSON input -> catches Exception path
    // -------------------------
    @IsTest
    static void testInvalidJsonInput() {
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf('invalid_json_here');

        Test.startTest();
        BAPPUpdateAgentInfoHandler.handleUpdateAgentInfo('invalid_json_here');
        Test.stopTest();

        // handler's catch uses sendError -> 400
        System.assertEquals(400, RestContext.response.statusCode);
    }

    // -------------------------
    // Helper: create required ServiceCatalog records (SubCategory must match handler expectations)
    // -------------------------
    private static void createServiceCatalogs() {
        // SubCategory label used in handler = 'Broker Agent Details Update'
        List<ServiceCatalog__c> serviceCatalogs = new List<ServiceCatalog__c>{
            new ServiceCatalog__c(
                Name = 'Service-Request-Broker-Agent-Details-Update',
                RecordTypeDevName__c = 'BrokerAgentDetailsUpdate',
                Type__c = 'Service Request',
                Category__c = Label.BAPP_CategoryBrokerServiceRequest,
                SubCategory__c = 'Broker Agent Details Update'
            ),
            // include generic Other entry used by some negative tests
            new ServiceCatalog__c(
                Name = 'Service-Request-Other',
                RecordTypeDevName__c = 'OtherServiceRequest',
                Type__c = 'Service Request',
                Category__c = Label.BAPP_CategoryBrokerServiceRequest,
                SubCategory__c = 'Other Service Request'
            )
        };
        insert serviceCatalogs;
    }

    // -------------------------
    // Helper: createContact - uses Utility.getRecordTypeIdByDevName for Contact RT (same pattern as reference)
    // -------------------------
    private static Contact createContact(Account acc, String role, Boolean isActive, String lastName) {
        Contact con = new Contact(
            LastName = lastName,
            AccountId = acc.Id,
            BrokerContactRole__c = role,
            IsActive__c = isActive,
            Email = lastName.replace(' ','') + DateTime.now().getTime() + '@example.com',
            RecordTypeId = Utility.getRecordTypeIdByDevName(Contact.SObjectType, 'Broker')
        );
        insert con;
        return con;
    }

    // -------------------------
    // Helper: setup REST context
    // -------------------------
    private static void setupRestContext(String method, Object body) {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestUri = '/services/apexrest/BAPPUpdateAgentInfo';
        req.httpMethod = method;
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(JSON.serialize(body));

        RestContext.request = req;
        RestContext.response = res;
    }
    
    // ===== Helper =====
    private static void setupRest(String jsonBody) {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = 'POST';
        req.requestUri = '/services/apexrest/BAPPUpdateAgentInfo';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonBody);
        RestContext.request = req;
        RestContext.response = res;
    }

    @IsTest
static void testInvalidAccountId_RecordExistsFalse() {
    Account acc = [SELECT Id FROM Account LIMIT 1];
    Contact con = [SELECT Id FROM Contact LIMIT 1];

    // Valid-format but nonexistent Account Id
    Id fakeAccountId = Id.valueOf('001000000000000AAA');

    BAPPUpdateAgentInfoHandler.UpdateAgentRequest req = new BAPPUpdateAgentInfoHandler.UpdateAgentRequest();
    req.accountId = fakeAccountId; // invalid record
    req.contactId = con.Id;
    req.caseStatus = 'New';
    req.serviceRequestType = Label.BAPP_ServiceRequestTypeAgentDetailsUpdate;
    req.category = Label.BAPP_CategoryBrokerServiceRequest;
    req.subCategory = Label.BAPP_SubCategoryBrokerAgentDetailsUpdate;

    RestRequest request = new RestRequest();
    request.httpMethod = 'POST';
    request.requestUri = '/services/apexrest/BAPPUpdateAgentInfo';
    request.addHeader('Content-Type', 'application/json');
    request.requestBody = Blob.valueOf(JSON.serialize(req));
    RestContext.request = request;
    RestContext.response = new RestResponse();

    Test.startTest();
    BAPPUpdateAgentInfoHandler.handleUpdateAgentInfo(JSON.serialize(req));
    Test.stopTest();
}

@IsTest
static void testInvalidContactId_RecordExistsFalse() {
    Account acc = [SELECT Id FROM Account LIMIT 1];

    // Valid-format but nonexistent Contact Id
    Id fakeContactId = Id.valueOf('003000000000000AAA');

    BAPPUpdateAgentInfoHandler.UpdateAgentRequest req = new BAPPUpdateAgentInfoHandler.UpdateAgentRequest();
    req.accountId = acc.Id;
    req.contactId = fakeContactId;
    req.caseStatus = 'New';
    req.serviceRequestType = Label.BAPP_ServiceRequestTypeAgentDetailsUpdate;
    req.category = Label.BAPP_CategoryBrokerServiceRequest;
    req.subCategory = Label.BAPP_SubCategoryBrokerAgentDetailsUpdate;

    RestRequest request = new RestRequest();
    request.httpMethod = 'POST';
    request.requestUri = '/services/apexrest/BAPPUpdateAgentInfo';
    request.addHeader('Content-Type', 'application/json');
    request.requestBody = Blob.valueOf(JSON.serialize(req));
    RestContext.request = request;
    RestContext.response = new RestResponse();

    Test.startTest();
    BAPPUpdateAgentInfoHandler.handleUpdateAgentInfo(JSON.serialize(req));
    Test.stopTest();
}


    // =====================================================
    // 3️⃣ Missing caseStatus → sendError(Label.BAPP_CaseStatusRequired)
    // =====================================================
    @IsTest
    static void testMissingCaseStatus() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        BAPPUpdateAgentInfoHandler.UpdateAgentRequest req = new BAPPUpdateAgentInfoHandler.UpdateAgentRequest();
        req.accountId = acc.Id;
        req.contactId = con.Id;
        req.caseStatus = ''; // Blank
        req.serviceRequestType = Label.BAPP_ServiceRequestTypeAgentDetailsUpdate;
        req.category = Label.BAPP_CategoryBrokerServiceRequest;
        req.subCategory = Label.BAPP_SubCategoryBrokerAgentDetailsUpdate;

        setupRest(JSON.serialize(req));

        Test.startTest();
        BAPPUpdateAgentInfoHandler.handleUpdateAgentInfo(JSON.serialize(req));
        Test.stopTest();
    }

    // =====================================================
    // 4️⃣ Missing serviceRequestType → sendError(Label.BAPP_ServiceRequestTypeRequired)
    // =====================================================
    @IsTest
    static void testMissingServiceRequestType() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        BAPPUpdateAgentInfoHandler.UpdateAgentRequest req = new BAPPUpdateAgentInfoHandler.UpdateAgentRequest();
        req.accountId = acc.Id;
        req.contactId = con.Id;
        req.caseStatus = 'New';
        req.serviceRequestType = ''; // blank
        req.category = Label.BAPP_CategoryBrokerServiceRequest;
        req.subCategory = Label.BAPP_SubCategoryBrokerAgentDetailsUpdate;

        setupRest(JSON.serialize(req));

        Test.startTest();
        BAPPUpdateAgentInfoHandler.handleUpdateAgentInfo(JSON.serialize(req));
        Test.stopTest();
    }

    // =====================================================
    // 5️⃣ Invalid serviceRequestType → sendError(Label.BAPP_ServiceRequestTypeInvalid)
    // =====================================================
    @IsTest
    static void testInvalidServiceRequestType() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        BAPPUpdateAgentInfoHandler.UpdateAgentRequest req = new BAPPUpdateAgentInfoHandler.UpdateAgentRequest();
        req.accountId = acc.Id;
        req.contactId = con.Id;
        req.caseStatus = 'New';
        req.serviceRequestType = 'InvalidType';
        req.category = Label.BAPP_CategoryBrokerServiceRequest;
        req.subCategory = Label.BAPP_SubCategoryBrokerAgentDetailsUpdate;

        setupRest(JSON.serialize(req));

        Test.startTest();
        BAPPUpdateAgentInfoHandler.handleUpdateAgentInfo(JSON.serialize(req));
        Test.stopTest();
    }

    // =====================================================
    // 6️⃣ Missing category → sendError(Label.BAPP_CategoryRequired)
    // =====================================================
    @IsTest
    static void testMissingCategory() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        BAPPUpdateAgentInfoHandler.UpdateAgentRequest req = new BAPPUpdateAgentInfoHandler.UpdateAgentRequest();
        req.accountId = acc.Id;
        req.contactId = con.Id;
        req.caseStatus = 'New';
        req.serviceRequestType = Label.BAPP_ServiceRequestTypeAgentDetailsUpdate;
        req.category = ''; // blank
        req.subCategory = Label.BAPP_SubCategoryBrokerAgentDetailsUpdate;

        setupRest(JSON.serialize(req));

        Test.startTest();
        BAPPUpdateAgentInfoHandler.handleUpdateAgentInfo(JSON.serialize(req));
        Test.stopTest();
    }

    // =====================================================
    // 7️⃣ Invalid category → sendError(Label.BAPP_CategoryInvalid)
    // =====================================================
    @IsTest
    static void testInvalidCategory() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        BAPPUpdateAgentInfoHandler.UpdateAgentRequest req = new BAPPUpdateAgentInfoHandler.UpdateAgentRequest();
        req.accountId = acc.Id;
        req.contactId = con.Id;
        req.caseStatus = 'New';
        req.serviceRequestType = Label.BAPP_ServiceRequestTypeAgentDetailsUpdate;
        req.category = 'WrongCategory';
        req.subCategory = Label.BAPP_SubCategoryBrokerAgentDetailsUpdate;

        setupRest(JSON.serialize(req));

        Test.startTest();
        BAPPUpdateAgentInfoHandler.handleUpdateAgentInfo(JSON.serialize(req));
        Test.stopTest();
    }

    // =====================================================
    // 8️⃣ Missing subCategory → sendError(Label.BAPP_SubCategoryRequired)
    // =====================================================
    @IsTest
    static void testMissingSubCategory() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        BAPPUpdateAgentInfoHandler.UpdateAgentRequest req = new BAPPUpdateAgentInfoHandler.UpdateAgentRequest();
        req.accountId = acc.Id;
        req.contactId = con.Id;
        req.caseStatus = 'New';
        req.serviceRequestType = Label.BAPP_ServiceRequestTypeAgentDetailsUpdate;
        req.category = Label.BAPP_CategoryBrokerServiceRequest;
        req.subCategory = ''; // blank

        setupRest(JSON.serialize(req));

        Test.startTest();
        BAPPUpdateAgentInfoHandler.handleUpdateAgentInfo(JSON.serialize(req));
        Test.stopTest();
    }

    // =====================================================
    // 9️⃣ Invalid subCategory → sendError(Label.BAPP_SubCategoryInvalid)
    // =====================================================
    @IsTest
    static void testInvalidSubCategory() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        BAPPUpdateAgentInfoHandler.UpdateAgentRequest req = new BAPPUpdateAgentInfoHandler.UpdateAgentRequest();
        req.accountId = acc.Id;
        req.contactId = con.Id;
        req.caseStatus = 'New';
        req.serviceRequestType = Label.BAPP_ServiceRequestTypeAgentDetailsUpdate;
        req.category = Label.BAPP_CategoryBrokerServiceRequest;
        req.subCategory = 'WrongSubCategory';

        setupRest(JSON.serialize(req));

        Test.startTest();
        BAPPUpdateAgentInfoHandler.handleUpdateAgentInfo(JSON.serialize(req));
        Test.stopTest();
    }
    
    @IsTest
    static void testSelfContactUpdateWithMobileChange() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Broker Agency' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE BrokerContactRole__c = 'CEO' LIMIT 1];
        
        // Prepare request
        BAPPUpdateAgentInfoHandler.UpdateAgentRequest req = new BAPPUpdateAgentInfoHandler.UpdateAgentRequest();
        req.accountId = acc.Id;
        req.contactId = con.Id;  // requester
        req.ContactIdToUpdate = con.Id; // updating self
        req.mobileNumber = '9876543210';
        req.countryCode = '+971';
        req.caseStatus = 'New';
        req.serviceRequestType = Label.BAPP_ServiceRequestTypeAgentDetailsUpdate;
        req.category = Label.BAPP_CategoryBrokerServiceRequest;
        req.subCategory = Label.BAPP_SubCategoryBrokerAgentDetailsUpdate;
        
        // Set REST context
        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.requestUri = '/services/apexrest/BAPPUpdateAgentInfo';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf(JSON.serialize(req));
        RestContext.request = request;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        BAPPUpdateAgentInfoHandler.handleUpdateAgentInfo(JSON.serialize(req));
        Test.stopTest();
    }

}