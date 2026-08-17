@IsTest
public class BAPPLeadGenerationHandlerTest {
    
    @TestSetup
    static void setupTestData() {
        // Initialize RestContext
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        // Create Broker Account via TestDataFactory
        Account acc = TestDataFactory.createBrokerAccount('Test Broker Agency', false, '1234567890');
        insert acc;
        Contact agentContact = createContact(acc, 'Agent', true, 'Agent Contact');
        Contact nonAgentContact = createContact(acc, 'Admin', true, 'Admin Contact');
        //Contact conPartner = createContact(acc, 'Partner', true, 'Partner Contact');
        //Contact conNullRole = createContact(acc, null, true, 'Null Role Contact');
        
        // Create a Queue for Owner assignment
        List<Group> existingQueue = [
            SELECT Id FROM Group 
            WHERE DeveloperName = 'Broker_Unassigned_Leads' AND Type = 'Queue' LIMIT 1
        ];
        Group queue;
        if (existingQueue.isEmpty()) {
            queue = new Group(
                Name = 'Broker Unassigned Leads',
                DeveloperName = 'Broker_Unassigned_Leads',
                Type = 'Queue'
            );
            insert queue;
        } else {
            queue = existingQueue[0];
        }
        
        // Create an existing Lead to test duplicate scenario
        Lead existingLead = new Lead(
            FirstName = 'Kabir',
            LastName = 'Test',
            Email = 'kabir@mailinator.com',
            MobilePhoneNumber__c = '264682111',
            Company = 'Test Company',
            Status = 'Open - Not Contacted'
        );
        insert existingLead;
    }
    
    // --------------------------
    // TEST: Successful Lead Creation
    // --------------------------
    
    @IsTest
    static void testHandleLeadCreationSuccess() {
        // Fetch test data
        Account acc = [SELECT Id FROM Account WHERE Name='Test Broker Agency' LIMIT 1];
        Contact agent = [SELECT Id FROM Contact WHERE BrokerContactRole__c='Agent' And AccountId=:acc.Id LIMIT 1];
        
        // Prepare full LeadGenerationRequest
        BAPPLeadGenerationHandler.LeadGenerationRequest req = 
            new BAPPLeadGenerationHandler.LeadGenerationRequest();
        
        req.contactId = agent.Id;
        req.accountId = acc.Id;
        req.salesManagerId = '';
        req.leadId = '';
        req.leadType = 'IndividualLead';
        req.title = 'Ms.';
        req.firstName = 'KabirTest';
        req.middleName = 'M';
        req.lastName = 'Test';
        req.email = 'ka@mailinator.com';
        req.countryCode = '94';
        req.phoneNumber = '27636474';
        req.preferredCommunication = 'Email';
        req.preferredLanguage = 'English';
        req.organizationName = 'Test Org';
        req.passportNumber = '53553535';
        req.passportExpiryDate = '2029-08-31';
        req.nationalId = '784-1234-1238867-8';
        req.nationalIdExpiryDate = '2029-08-31';
        req.leadStatus = 'New';
        req.project = 'Palm Jumeirah Villas';
        req.unitType = 'Apartment';
        //req.numberOfBedrooms = '3';
        
        String requestBody = JSON.serialize(req);
        
        // Initialize RestContext for testing
        RestRequest reqObj = new RestRequest();
        RestResponse resObj = new RestResponse();
        RestContext.request = reqObj;
        RestContext.response = resObj;
        
        Test.startTest();
        BAPPLeadGenerationHandler.handleLeadGeneration(requestBody);
        Test.stopTest();
        
        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(
            RestContext.response.responseBody.toString()
        );
    }
    
    
    // --------------------------
    // TEST: Successful Lead Update
    // --------------------------
    @IsTest
    static void testLeadUpdateSuccess() {
        Lead existingLead = [SELECT Id, Status FROM Lead LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact agent = [SELECT Id FROM Contact WHERE BrokerContactRole__c='Agent' LIMIT 1];
        User salesManager = [SELECT Id,IsActive FROM User WHERE Profile.name ='Sales Manager' And IsActive = true LIMIT 1];
        BAPPLeadGenerationHandler.LeadGenerationRequest req = new BAPPLeadGenerationHandler.LeadGenerationRequest();
        req.accountId = acc.Id;
        req.contactId = agent.Id;
        req.leadId = existingLead.Id;
        req.salesManagerId = salesManager.Id;
        req.leadType = 'IndividualLead';
        req.title = 'Ms.';
        req.firstName = 'Test Kabir';
        req.middleName = 'M';
        req.lastName = 'Test';
        req.email = 'ka@mailinator.com';
        req.countryCode = '94';
        req.phoneNumber = '27636474';
        req.preferredCommunication = 'Email';
        req.preferredLanguage = 'English';
        req.organizationName = 'Test Org';
        req.passportNumber = '53553535';
        req.passportExpiryDate = '2029-08-31';
        req.nationalId = '784-1234-1238867-8';
        req.nationalIdExpiryDate = '2029-08-31';
        req.leadStatus = 'New';
        req.project = 'Palm Jumeirah Villas';
        req.unitType = 'Apartment';
        //req.numberOfBedrooms = '3';
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        Test.startTest();
        BAPPLeadGenerationHandler.handleLeadGeneration(JSON.serialize(req));
        Test.stopTest();
    }
    @IsTest
    static void testValidationErrors() {
        // Setup RestContext
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        
        BAPPLeadGenerationHandler.LeadGenerationRequest req = new BAPPLeadGenerationHandler.LeadGenerationRequest();
        req.accountId = null; // missing
        req.contactId = null; // missing
        req.leadType = null; // missing
        req.title = null;
        req.firstName = null;
        req.lastName = null;
        req.email = null;
        req.phoneNumber = null;
        req.countryCode = null;
        req.preferredLanguage = null;
        
        Test.startTest();
        BAPPLeadGenerationHandler.handleLeadGeneration(JSON.serialize(req));
        Test.stopTest();
        
    }
    // --------------------------
    // TEST: Duplicate Lead Detection
    // --------------------------
    @IsTest
    static void testDuplicateLeadDetected() {
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact agent = [SELECT Id FROM Contact WHERE BrokerContactRole__c='Agent' LIMIT 1];
        
        BAPPLeadGenerationHandler.LeadGenerationRequest req = new BAPPLeadGenerationHandler.LeadGenerationRequest();
        req.accountId = acc.Id;
        req.contactId = agent.Id;
        req.leadType = 'IndividualLead';
        req.title = 'Ms.';
        req.firstName = 'Kabir';
        req.lastName = 'Test';
        req.email = 'kabir@mailinator.com';
        req.phoneNumber = '264682111';
        req.countryCode = '94';
        req.preferredLanguage = 'English';
        
        Test.startTest();
        BAPPLeadGenerationHandler.handleLeadGeneration(JSON.serialize(req));
        Test.stopTest();
        
    }
    
    // --------------------------
    // TEST: Access Denied for Non-Agent
    // --------------------------
    @IsTest
    static void testAccessDeniedNonAgent() {
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact nonAgent = [SELECT Id FROM Contact WHERE BrokerContactRole__c='Admin' LIMIT 1];
        
        BAPPLeadGenerationHandler.LeadGenerationRequest req = new BAPPLeadGenerationHandler.LeadGenerationRequest();
        req.accountId = acc.Id;
        req.contactId = nonAgent.Id;
        req.leadType = 'IndividualLead';
        req.title = 'Mr.';
        req.firstName = 'NonAgent';
        req.lastName = 'User';
        req.email = 'nonagentuser@mailinator.com';
        req.phoneNumber = '971555999000';
        req.countryCode = '94';
        req.preferredLanguage = 'English';
        
        Test.startTest();
        BAPPLeadGenerationHandler.handleLeadGeneration(JSON.serialize(req));
        Test.stopTest();
        
    }
    @IsTest
    static void testInvalidJsonInput() {
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        
        String invalidJson = '{invalidJson}'; // malformed JSON
        Test.startTest();
        BAPPLeadGenerationHandler.handleLeadGeneration(invalidJson);
        Test.stopTest();
        
    }
    @IsTest
    static void testDmlExceptionHandling() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact agent = [SELECT Id FROM Contact WHERE BrokerContactRole__c='Agent' LIMIT 1];
        
        // Create an invalid Lead request to trigger DML exception
        BAPPLeadGenerationHandler.LeadGenerationRequest req = new BAPPLeadGenerationHandler.LeadGenerationRequest();
        req.accountId = acc.Id;
        req.contactId = agent.Id;
        req.leadType = 'IndividualLead';
        req.title = 'Mr.';
        req.firstName = 'Error';
        req.lastName = 'Test';
        req.email = 'invalidEmail'; 
        req.phoneNumber = '971500000000';
        req.countryCode = '971';
        req.preferredLanguage = 'English';
        
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        
        Test.startTest();
        BAPPLeadGenerationHandler.handleLeadGeneration(JSON.serialize(req));
        Test.stopTest();
        
    }
    @IsTest
    static void testOrgLeadCreationSuccess() {
        // Fetch test data
        Account acc = [SELECT Id FROM Account WHERE Name='Test Broker Agency' LIMIT 1];
        Contact agent = [SELECT Id FROM Contact WHERE BrokerContactRole__c='Agent' And AccountId=:acc.Id LIMIT 1];
        
        // Prepare full LeadGenerationRequest
        BAPPLeadGenerationHandler.LeadGenerationRequest req = 
            new BAPPLeadGenerationHandler.LeadGenerationRequest();
        
        req.contactId = agent.Id;
        req.accountId = acc.Id;
        req.salesManagerId = '';
        req.leadId = '';
        req.leadType = 'OrganizationLead';
        req.title = 'Ms.';
        req.firstName = 'KabirTest';
        req.middleName = 'M';
        req.lastName = 'Test';
        req.email = 'ka@mailinator.com';
        req.countryCode = '94';
        req.phoneNumber = '27636474';
        req.preferredCommunication = 'Email';
        req.preferredLanguage = 'English';
        req.organizationName = 'Test Org';
        req.passportNumber = '53553535';
        req.passportExpiryDate = '2029-08-31';
        req.nationalId = '784-1234-1238867-8';
        req.nationalIdExpiryDate = '2029-08-31';
        req.leadStatus = 'New';
        req.project = 'Palm Jumeirah Villas';
        req.unitType = 'Apartment';
        //req.numberOfBedrooms = '3';
        
        String requestBody = JSON.serialize(req);
        
        // Initialize RestContext for testing
        RestRequest reqObj = new RestRequest();
        RestResponse resObj = new RestResponse();
        RestContext.request = reqObj;
        RestContext.response = resObj;
        
        Test.startTest();
        BAPPLeadGenerationHandler.handleLeadGeneration(requestBody);
        Test.stopTest();
        
        
        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(
            RestContext.response.responseBody.toString()
        );
    }
    
    // --------------------------
    // TEST: Missing ContactId
    // --------------------------
    @IsTest
    static void testMissingContactId() {
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        
        Account acc = [SELECT Id FROM Account LIMIT 1];
        BAPPLeadGenerationHandler.LeadGenerationRequest req = new BAPPLeadGenerationHandler.LeadGenerationRequest();
        req.accountId = acc.Id;
        req.contactId = null; // <-- missing
        req.leadType = 'IndividualLead';
        req.firstName = 'Test';
        req.lastName = 'User';
        req.email = 'test@mail.com';
        req.phoneNumber = '971500000000';
        req.countryCode = '971';
        req.preferredLanguage = 'English';
        
        Test.startTest();
        BAPPLeadGenerationHandler.handleLeadGeneration(JSON.serialize(req));
        Test.stopTest();
    }
    
    // --------------------------
    // TEST: Invalid AccountId (record does not exist)
    // --------------------------
    @IsTest
    static void testInvalidAccountId() {
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        
        Contact con = [SELECT Id FROM Contact WHERE BrokerContactRole__c='Agent' LIMIT 1];
        
        BAPPLeadGenerationHandler.LeadGenerationRequest req = new BAPPLeadGenerationHandler.LeadGenerationRequest();
        req.accountId = '001000000000000AAA'; // invalid Id
        req.contactId = con.Id;
        req.leadType = 'IndividualLead';
        req.firstName = 'Invalid';
        req.lastName = 'Account';
        req.email = 'invalid@mail.com';
        req.phoneNumber = '971500000001';
        req.countryCode = '971';
        req.preferredLanguage = 'English';
        
        Test.startTest();
        BAPPLeadGenerationHandler.handleLeadGeneration(JSON.serialize(req));
        Test.stopTest();
    }
    
    // --------------------------
    // TEST: Invalid ContactId (record does not exist)
    // --------------------------
    @IsTest
    static void testInvalidContactId() {
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        BAPPLeadGenerationHandler.LeadGenerationRequest req = new BAPPLeadGenerationHandler.LeadGenerationRequest();
        req.accountId = acc.Id;
        req.contactId = '003000000000000AAA'; // invalid Id
        req.leadType = 'IndividualLead';
        req.firstName = 'Invalid';
        req.lastName = 'Contact';
        req.email = 'invalidcontact@mail.com';
        req.phoneNumber = '971500000002';
        req.countryCode = '971';
        req.preferredLanguage = 'English';
        
        Test.startTest();
        BAPPLeadGenerationHandler.handleLeadGeneration(JSON.serialize(req));
        Test.stopTest();
    }
    
    // --------------------------
    // TEST: Contact belongs to a different Account
    // --------------------------
    @IsTest
    static void testInvalidAccountContactRelation() {
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        
        // Two accounts
        Account acc1 = [SELECT Id FROM Account WHERE Name='Test Broker Agency' LIMIT 1];
        Account acc2 = new Account(Name = 'Another Broker');
        insert acc2;
        
        // Contact under acc1
        Contact con = [SELECT Id FROM Contact WHERE AccountId = :acc1.Id LIMIT 1];
        
        // Use contact from acc1 but account from acc2
        BAPPLeadGenerationHandler.LeadGenerationRequest req = new BAPPLeadGenerationHandler.LeadGenerationRequest();
        req.accountId = acc2.Id; // mismatched account
        req.contactId = con.Id;
        req.leadType = 'IndividualLead';
        req.firstName = 'Mismatch';
        req.lastName = 'Contact';
        req.email = 'mismatch@mail.com';
        req.phoneNumber = '971500000003';
        req.countryCode = '971';
        req.preferredLanguage = 'English';
        
        Test.startTest();
        BAPPLeadGenerationHandler.handleLeadGeneration(JSON.serialize(req));
        Test.stopTest();
    }
    
    // --------------------------
    // TEST: makeSuccessResponse and makePartialSuccessResponse
    // --------------------------
    @IsTest
    static void testMakeSuccessAndPartialResponse() {
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        
        // Success response
        Map<String, Object> successRes = new Map<String, Object>{ 'status' => 'success', 'message' => 'Lead created' };
            Test.startTest();
        BAPPLeadGenerationHandler.makeSuccessResponse(successRes);
        Test.stopTest();
        
        // Partial success response
        RestContext.response = new RestResponse(); // reset
        Map<String, Object> partialRes = new Map<String, Object>{ 'message' => 'Partially processed' };
            BAPPLeadGenerationHandler.makePartialSuccessResponse(partialRes);
    }
    
    @IsTest
static void testLeadUpdate_WithSalesManager_Success() {
    // Arrange
    Account acc = [SELECT Id FROM Account WHERE Name='Test Broker Agency' LIMIT 1];
    Contact agent = [SELECT Id FROM Contact WHERE BrokerContactRole__c='Agent' LIMIT 1];

    // Create a new Lead with Status = 'New'
    Lead leadRec = new Lead(
        FirstName = 'Update',
        LastName = 'Lead',
        Company = 'Update Company',
        Status = 'New',
        Email = 'updatelead@mailinator.com',
        MobilePhoneNumber__c = '999111222',
        BrokerAgent__c = agent.Id,
        BrokerAgency__c = acc.Id
    );
    insert leadRec;

    // Fetch a Sales Manager user
    User salesManager = [SELECT Id, IsActive FROM User WHERE Profile.Name = 'Sales Manager' AND IsActive = true LIMIT 1];

    // Prepare update request
    BAPPLeadGenerationHandler.LeadGenerationRequest req = new BAPPLeadGenerationHandler.LeadGenerationRequest();
    req.leadId = leadRec.Id;
    req.accountId = acc.Id;
    req.contactId = agent.Id;
    req.salesManagerId = salesManager.Id; // sales manager provided
    req.leadType = 'IndividualLead';
    req.title = 'Mr.';
    req.firstName = 'UpdatedFirst';
    req.lastName = 'UpdatedLast';
    req.email = 'updatelead@mailinator.com';
    req.countryCode = '971';
    req.phoneNumber = '987654321';
    req.preferredLanguage = 'English';
    req.preferredCommunication = 'Email';
    req.organizationName = 'Updated Org';
    req.leadStatus = 'New';
    req.project = 'Test Project';
    req.unitType = 'Apartment';

    RestContext.request = new RestRequest();
    RestContext.response = new RestResponse();

    // Act
    Test.startTest();
    BAPPLeadGenerationHandler.handleLeadGeneration(JSON.serialize(req));
    Test.stopTest();

    // Assert (optional for coverage, but validates logic)
    Map<String, Object> res = (Map<String, Object>) JSON.deserializeUntyped(RestContext.response.responseBody.toString());
    System.debug('Lead Update Response: ' + res);
}

    
    private static Contact createContact(Account acc, String role, Boolean isActive, String lastName) {
        Contact con = new Contact(
        LastName = lastName,
        AccountId = acc.Id,
        BrokerContactRole__c = role,
       	IsActive__c = isActive,
        Email ='johnny.depp+' + System.currentTimeMillis() + '@example.com',
        RecordTypeId = Utility.getRecordTypeIdByDevName(Contact.SObjectType, 'Broker'));
        insert con;
        return con;
    }
}