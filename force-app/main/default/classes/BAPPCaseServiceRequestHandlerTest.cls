@IsTest
public class BAPPCaseServiceRequestHandlerTest {
    
    // ==== Test Setup ====
    @TestSetup
    static void setupData() {
        
        createServiceCatalogs();
        
        Account acc = createAccount('Test Agency Account');
        
        Contact conAgent = createContact(acc, 'Agent', true, 'Agent Contact', 'test1@test.com');
        Contact conAdmin = createContact(acc, 'Admin', true, 'Admin Contact', 'test2@test.com');
        Contact conPartner = createContact(acc, 'Partner', true, 'Partner Contact', 'test3@test.com');
        Contact conNullRole = createContact(acc, null, true, 'Null Role Contact', 'test4@test.com');
        
        createLead(acc, conAgent, 'New', 'Lead 1', 'Company 1');
        createLead(acc, conAgent, 'Closed', 'Lead 2', 'Company 2');
        
        Project__c proj1 = createProject('Test Project 1');
        
        createBrokerCommission('INV-1001', proj1.Id, Date.today());
    }
    
    @IsTest
    static void testCaseRequestAndResponse() {
        Account acc = createAccount('Test Account');
        Contact con = createContact(acc, 'Admin', true, 'Test Contact', 'test5@test.com');
        
        // Build CaseRequest
        BAPPCaseServiceRequestHandler.CaseRequest requestBody = new BAPPCaseServiceRequestHandler.CaseRequest();
        requestBody.accountId = acc.Id;
        requestBody.contactId = con.Id;
        requestBody.caseDescription = 'Test Case';
        requestBody.category = 'Broker Service Request';
        requestBody.subCategory = 'Other';
        requestBody.caseStatus = 'New';
        
        // Setup REST context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = 'POST';
        req.requestUri = '/services/apexrest/bapp/cases';
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        RestContext.request = req;
        RestContext.response = res;
        
        // Call handler (internally uses CaseRequest & CaseResponse)
        Test.startTest();
        BAPPCaseServiceRequestHandler.handleCaseServiceRequest();
        Test.stopTest();
        
        // Debug the response (this touches CaseResponse)
        System.debug('Response: ' + RestContext.response.responseBody.toString());
    }
    @IsTest
    static void testCaseGetRequestAndResponse() {
        Account acc = createAccount('Test Account 2');
        Contact con = createContact(acc, 'Admin', true, 'Test Contact 2', 'test6@test.com');
        
        // Setup REST context
        setupRestContext('GET', new Map<String,Object>{
            'accountId' => acc.Id,
                'contactId' => con.Id
                });
        
        // Call GET handler (internally uses CaseGetRequest & CaseGetResponse)
        Test.startTest();
        BAPPCaseServiceRequestHandler.getServiceRequests();
        Test.stopTest();
        
        // Debug to cover CaseGetResponse mapping
        System.debug('GET Response: ' + RestContext.response.responseBody.toString());
    }
    
    @IsTest
    static void testGetServiceRequests_NoCasesFound() {
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Test Agency Account' LIMIT 1];
        Contact con = [SELECT Id, Name FROM Contact WHERE BrokerContactRole__c = 'Admin' LIMIT 1];
        
        setupRestContext('GET', new Map<String,Object>{
            'accountId' => acc.Id,
                'contactId' => con.Id
                });
        
        Test.startTest();
        BAPPCaseServiceRequestHandler.getServiceRequests();
        Test.stopTest();
    }
    
    // Cover Delayed Commission Payment
    @IsTest
    static void testGetServiceRequests_DelayedCommissionPayment() {
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Test Agency Account' LIMIT 1];
        Contact con = [SELECT Id, Name FROM Contact WHERE BrokerContactRole__c = 'Admin' LIMIT 1];
        Contact conToUpdate = [SELECT Id, Name FROM Contact WHERE BrokerContactRole__c = 'Agent' LIMIT 1];
        ServiceCatalog__c sc = [SELECT Id, Name, RecordTypeDevName__c, Category__c, SubCategory__c FROM ServiceCatalog__c where SubCategory__c = 'Delayed Commission Payment' LIMIT 1];
        
        Id caseRTId = Utility.getRecordTypeIdByDevName(Case.SObjectType, 'DelayedCommissionPayment');
        
        createDocumentType('Case', 'Other', 'DelayedCommissionPayment', null, null);
        createDocumentType('Case', 'Other', 'DelayedCommissionPayment', null, null);
        Case c = createCase(acc, con, conToUpdate, sc, caseRTId);
        
        setupRestContext('GET', new Map<String,Object>{
            'accountId' => acc.Id,
                'contactId' => con.Id
                });
        
        Test.startTest();
        BAPPCaseServiceRequestHandler.getServiceRequests();
        Test.stopTest();
    }
    
    // Cover Broker Agent Details Update
    @IsTest
    static void testGetServiceRequests_BrokerAgentDetailsUpdate() {
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Test Agency Account' LIMIT 1];
        Contact con = [SELECT Id, Name FROM Contact WHERE BrokerContactRole__c = 'Admin' LIMIT 1];
        Contact conToUpdate = [SELECT Id, Name FROM Contact WHERE BrokerContactRole__c = 'Agent' LIMIT 1];
        ServiceCatalog__c sc = [SELECT Id, Name, RecordTypeDevName__c, Category__c, SubCategory__c FROM ServiceCatalog__c where SubCategory__c = 'Broker Agent Details Update' LIMIT 1];
        
        Id caseRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, 'BrokerAgentDetailsUpdate');
        
        createDocumentType('Case', 'Other', 'BrokerAgentDetailsUpdate', 'Admin;Agent', 'Domestic');
        createDocumentType('Case', 'Other', 'BrokerAgentDetailsUpdate', 'Agent', 'Domestic');        
        Case c = createCase(acc, con, conToUpdate, sc, caseRecordTypeId);
        
        setupRestContext('GET', new Map<String, Object>{
            'accountId' => acc.Id,
                'contactId' => con.Id
                });
        
        Test.startTest();
        BAPPCaseServiceRequestHandler.getServiceRequests();
        Test.stopTest();
    }
    
    // Cover Broker Agency Details Update
    @IsTest
    static void testGetServiceRequests_BrokerAgencyDetailsUpdate() {
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Test Agency Account' LIMIT 1];
        Contact con = [SELECT Id, Name FROM Contact WHERE BrokerContactRole__c = 'Admin' LIMIT 1];
        Contact conToUpdate = [SELECT Id, Name FROM Contact WHERE BrokerContactRole__c = 'Agent' LIMIT 1];
        ServiceCatalog__c sc = [SELECT Id, Name, RecordTypeDevName__c, Category__c, SubCategory__c FROM ServiceCatalog__c where SubCategory__c = 'Broker Agency Details Update' LIMIT 1];
        
        Id caseRTId = Utility.getRecordTypeIdByDevName(Case.SObjectType, 'Broker_Agency_Details_Update');
        
        createDocumentType('Case', 'Other', 'Broker_Agency_Details_Update', 'Admin;Agent', 'Domestic');
        createDocumentType('Case', 'Other', 'Broker_Agency_Details_Update', 'Admin;Agent', 'International');
        Case c = createCase(acc, con, conToUpdate, sc, caseRTId);
        
        setupRestContext('GET', new Map<String, Object>{
            'accountId' => acc.Id,
                'contactId' => con.Id
                });
        
        Test.startTest();
        BAPPCaseServiceRequestHandler.getServiceRequests();
        Test.stopTest();
    }
    
    @IsTest
    static void testHandleCaseServiceRequest_WithTrigger() {
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Test Agency Account' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE BrokerContactRole__c = 'Agent' LIMIT 1];
        
        createDocumentType('Case', 'Other', 'DelayedCommissionPayment', null, null);
        createDocumentType('Case', 'Other', 'DelayedCommissionPayment', null, null);
        
        Map<String, Object> body = new Map<String, Object>{
            'accountId' => acc.Id,
                'contactId' => con.Id,
                'caseDescription' => 'Test Description',
                'category' => 'Broker Service Request',
                'subCategory' => 'Delayed Commission Payment',
                'caseStatus' => 'New',
                'brokerInvoiceNumber' => 'INV-1001'
                };
                    
                    RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/bapp/cases';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        BAPPCaseServiceRequestHandler.handleCaseServiceRequest();
        Test.stopTest();
        
    }
    
    // ==== Negative & Error Scenario Tests ====
    
    @IsTest
    static void testHandleCaseServiceRequest_MissingSubCategory() {
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Test Agency Account' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE BrokerContactRole__c = 'Admin' LIMIT 1];
        
        Map<String, Object> body = new Map<String, Object>{
            'accountId' => acc.Id,
                'contactId' => con.Id,
                'category' => 'Broker Service Request',
                'subCategory' => '', // missing
                'caseDescription' => 'Missing SubCategory test'
                };
                    
                    setupRestContext('POST', body);
        BAPPCaseServiceRequestHandler.handleCaseServiceRequest();
    }
    
    @IsTest
    static void testHandleCaseServiceRequest_MissingCategory() {
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Test Agency Account' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE BrokerContactRole__c = 'Admin' LIMIT 1];
        
        Map<String, Object> body = new Map<String, Object>{
            'accountId' => acc.Id,
                'contactId' => con.Id,
                'subCategory' => 'Other', // missing category
                'caseDescription' => 'Missing Category test'
                };
                    
                    setupRestContext('POST', body);
        BAPPCaseServiceRequestHandler.handleCaseServiceRequest();
    }
    
    @IsTest
    static void testHandleCaseServiceRequest_InvalidSubCategory() {
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Test Agency Account' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE BrokerContactRole__c = 'Admin' LIMIT 1];
        
        Map<String, Object> body = new Map<String, Object>{
            'accountId' => acc.Id,
                'contactId' => con.Id,
                'category' => 'Broker Service Request',
                'subCategory' => 'InvalidCategory',
                'caseDescription' => 'Invalid subCategory test'
                };
                    
                    setupRestContext('POST', body);
        BAPPCaseServiceRequestHandler.handleCaseServiceRequest();
    }
    
    @IsTest
    static void testHandleCaseServiceRequest_NoServiceCatalog() {
        
        delete [SELECT Id FROM ServiceCatalog__c];
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Test Agency Account' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE BrokerContactRole__c = 'Admin' LIMIT 1];
        
        Map<String, Object> body = new Map<String, Object>{
            'accountId' => acc.Id,
                'contactId' => con.Id,
                'category' => 'Broker Service Request',
                'subCategory' => 'Other',
                'caseDescription' => 'No ServiceCatalog test'
                };
                    
                    setupRestContext('POST', body);
        BAPPCaseServiceRequestHandler.handleCaseServiceRequest();
    }
    
    @IsTest
    static void testHandleCaseServiceRequest_NoBrokerCommission() {
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Test Agency Account' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE BrokerContactRole__c = 'Admin' LIMIT 1];
        
        Map<String, Object> body = new Map<String, Object>{
            'accountId' => acc.Id,
                'contactId' => con.Id,
                'category' => 'Broker Service Request',
                'subCategory' => 'Other',
                'caseDescription' => 'No BrokerCommission test',
                'brokerInvoiceNumber' => 'INV-NOT-FOUND'
                };
                    
                    setupRestContext('POST', body);
        BAPPCaseServiceRequestHandler.handleCaseServiceRequest();
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
        
        BAPPCaseServiceRequestHandler.handleCaseServiceRequest();
    }
    
    private static void setupRestContext(String method, Map<String, Object> body) {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/bapp/cases';
        req.httpMethod = method;
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        RestContext.request = req;
        RestContext.response = res;
    }
    
    // Common Account & Contact Error
    @IsTest
    static void testHandleCaseServiceRequest_MissingAccountContact() {
        Map<String, Object> body = new Map<String, Object>{
            'accountId' => '',
                'contactId' => '',
                'category' => 'Broker Service Request',
                'subCategory' => 'Other'
                };
                    
                    setupRestContext('POST', body);
        Test.startTest();
        BAPPCaseServiceRequestHandler.handleCaseServiceRequest();
        Test.stopTest();
    }
    
    @IsTest
    static void testHandleCaseServiceRequest_InvalidAccountId() {
        Map<String, Object> body = new Map<String, Object>{
            'accountId' => '001000000000000AAA',
                'contactId' => '003000000000000AAA',
                'category' => 'Broker Service Request',
                'subCategory' => 'Other'
                };
                    
                    setupRestContext('POST', body);
        Test.startTest();
        BAPPCaseServiceRequestHandler.handleCaseServiceRequest();
        Test.stopTest();
    }
    
    @IsTest
    static void testHandleCaseServiceRequest_InvalidContactId() {
        
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Test Agency Account' LIMIT 1];
        String fakeContactId = '003000000000000AAA';
        
        Map<String, Object> body = new Map<String, Object>{
            'accountId' => acc.Id,
                'contactId' => fakeContactId,
                'category' => 'Broker Service Request',
                'subCategory' => 'Other',
                'caseDescription' => 'Invalid contact test'
                };
                    
                    setupRestContext('POST', body);
        Test.startTest();
        BAPPCaseServiceRequestHandler.handleCaseServiceRequest();
        Test.stopTest();
    }
    
    @IsTest
    static void testHandleCaseServiceRequest_InvalidAccountContactRelation() {
        
        Account acc1 = createAccount('Test Agency Account - 1');
        Account acc2 = createAccount('Test Agency Account - 2');
        Contact con = createContact(acc1, 'Agent', true, 'Agent Contact', 'test7@test.com');
        
        Map<String, Object> body = new Map<String, Object>{
            'accountId' => acc2.Id,
                'contactId' => con.Id,
                'category' => 'Broker Service Request',
                'subCategory' => 'Other'
                };
                    
                    setupRestContext('POST', body);
        Test.startTest();
        BAPPCaseServiceRequestHandler.handleCaseServiceRequest();
        Test.stopTest();
    }
    
    // ==== Private Helper Methods ====
    
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
    
    private static Contact createContact(Account acc, String role, Boolean isActive, String lastName, String email) {
        Contact con = new Contact(
            LastName = lastName,
            AccountId = acc.Id,
            BrokerContactRole__c = role,
            IsActive__c = isActive,
            RecordTypeId = Utility.getRecordTypeIdByDevName(Contact.SObjectType, 'Broker'),
            Email = email
        );
        insert con;
        return con;
    }
    
    private static Lead createLead(Account acc, Contact con, String status, String lastName, String company) {
        Lead l = new Lead(
            LastName = lastName,
            Company = company,
            Status = status,
            BrokerAgency__c = acc.Id,
            BrokerAgent__c = con.Id,
            RecordTypeId = Utility.getRecordTypeIdByDevName(Lead.SObjectType, 'IndividualLead')
        );
        insert l;
        return l;
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
    
    private static Case createCase(Account acc, Contact con, Contact contactToUpdate, ServiceCatalog__c sc, Id recordTypeId) {
        Case c = new Case(
            Subject = 'Test Subject',
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
}