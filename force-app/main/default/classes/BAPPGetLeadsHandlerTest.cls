@IsTest
public class BAPPGetLeadsHandlerTest {
    
    // ==== Test Setup ====
    @TestSetup
    static void setupData() {
        Account accTest = createAccount('Test Account - 1');
        Account accBroker = createAccount('Broker Summary Account');
        
        Contact conAgent = createContact(accBroker, 'Agent', true, 'Test Contact Agent');
        Contact conAdmin = createContact(accBroker, 'Admin', false, 'Test Contact Admin');
        Contact conPartner = createContact(accBroker, 'Partner', false, 'Test Contact Partner');
        Contact conBrokerNull = createContact(accBroker, null, false, 'Test Contact null');
        
        createLead(accTest, conAgent, 'New', 1);
        createLead(accTest, conAgent, 'Closed', 2);
        insertTestLeads(accBroker, conAdmin);
    }  
    @IsTest
    static void testScenarioALL() {
        Account acc = [SELECT Id FROM Account WHERE Name='Broker Summary Account' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE BrokerContactRole__c='Admin' LIMIT 1];
        
        Map<String,Object> bodyAll = new Map<String,Object>{
            'accountId'=>acc.Id,
                'contactId'=>con.Id,
                'scenario'=>'ALL'
                };
                    
                    RestRequest reqAll = new RestRequest();
        reqAll.requestUri='/services/apexrest/brokerAppWebService/V1/getLeads';
        reqAll.httpMethod='POST';
        reqAll.requestBody=Blob.valueOf(JSON.serialize(bodyAll));
        RestContext.request=reqAll;
        RestContext.response=new RestResponse();
        
        Test.startTest();
        BAPPGetLeadsHandler.handleLeadFilters();
        Test.stopTest();
        
        System.debug('Response ALL: '+RestContext.response.responseBody.toString());
    }
    
    @IsTest
    static void testScenarioFILTER() {
        Account acc = [SELECT Id FROM Account WHERE Name='Broker Summary Account' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE BrokerContactRole__c='Admin' LIMIT 1];
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        //User realUser = [SELECT Id FROM User WHERE Alias='tuser' LIMIT 1];
        User realUser = new User(
            Alias = 'rlusr',
            Email = 'realuser+' + System.currentTimeMillis() + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'RealUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = adminProfile.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            UserName = 'realuser' + System.currentTimeMillis() + '@example.com'
        );
        insert realUser;
        
        Map<String,Object> bodyFilter = new Map<String,Object>{
            'accountId'=>acc.Id,
                'contactId'=>con.Id,
                'scenario'=>'FILTER',
                'filterCriteria'=> new Map<String,Object>{
                    'status'=>'New',
                        'salesManagerId'=>realUser.Id,
                        'updatedOnFrom'=>Date.today().addDays(-5),
                        'updatedOnTo'=>Date.today()
                        }
        };
            
            RestRequest reqFilter = new RestRequest();
        reqFilter.requestUri='/services/apexrest/brokerAppWebService/V1/getLeads';
        reqFilter.httpMethod='POST';
        reqFilter.requestBody=Blob.valueOf(JSON.serialize(bodyFilter));
        RestContext.request=reqFilter;
        RestContext.response=new RestResponse();
        
        Test.startTest();
        BAPPGetLeadsHandler.handleLeadFilters();
        Test.stopTest();
        
        System.debug('Response FILTER: '+RestContext.response.responseBody.toString());
    }
    
    // ======================
    // Lead Status Counts - METHOD
    // ======================
    @IsTest
    static void testGetLeadStatusCounts_Agent() {
        Account acc = [SELECT Id FROM Account where name = 'Test Account - 1'];
        Contact conAgent = createContact(acc, 'Agent', true, 'Test Contact Agent');
        
        // Add a lead without status to cover "Unknown"
        Lead l = new Lead(
            LastName = 'Lead With No Status',
            Company = 'Test Company X',
            BrokerAgency__c = acc.Id,
            BrokerAgent__c = conAgent.Id,
            RecordTypeId = Utility.getRecordTypeIdByDevName(Lead.SObjectType, 'IndividualLead')
        );
        insert l;
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/brokerAppWebService/V1/leadStatusCount';
        req.httpMethod = 'GET';
        req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
            'accountId' => acc.Id,
                'contactId' => conAgent.Id
                }));
        RestContext.request = req;
        RestContext.response = res;
        
        BAPPWebService.doGet();
        
        System.debug('Status Code: ' + RestContext.response.statusCode);
        System.debug('Response: ' + RestContext.response.responseBody.toString());
    }
    
    @IsTest
    static void testGetLeadStatusCounts_NoLeads() {
        delete [SELECT Id FROM Lead];
        Account acc = [SELECT Id FROM Account where name = 'Test Account - 1'];
        Contact conAdmin = createContact(acc, 'Admin', false, 'Test Contact Admin');
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/brokerAppWebService/V1/leadStatusCount';
        req.httpMethod = 'GET';
        req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
            'accountId' => acc.Id,
                'contactId' => conAdmin.Id,
                'updatedOnFrom' => Date.today().addDays(-30),
                'updatedOnTo' => Date.today()
                }));
        RestContext.request = req;
        RestContext.response = res;
        
        BAPPWebService.doGet();
        
        System.debug('Status Code: ' + RestContext.response.statusCode);
        System.debug('Response: ' + RestContext.response.responseBody.toString());
    }
    
    @IsTest
    static void testGetLeadStatusCounts_InvalidRequest() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/brokerAppWebService/V1/leadStatusCount';
        req.httpMethod = 'GET';
        req.requestBody = Blob.valueOf('{}');
        RestContext.request = req;
        RestContext.response = res;
        
        BAPPWebService.doGet();
        
        System.debug('Status Code: ' + RestContext.response.statusCode);
        System.debug('Response: ' + RestContext.response.responseBody.toString());
    }
    
    @IsTest
    static void testGetLeadStatusCounts_OnlyFromDate() {
        Account acc = [SELECT Id FROM Account where name = 'Test Account - 1'];
        Contact con = [SELECT Id FROM Contact WHERE BrokerContactRole__c = 'Agent' LIMIT 1];
        
        runLeadStatusTest(acc, con, Date.today().addDays(-10), null);
    }
    
    @IsTest
    static void testGetLeadStatusCounts_OnlyToDate() {
        Account acc = [SELECT Id FROM Account where name = 'Test Account - 1'];
        Contact conAgent = createContact(acc, 'Agent', true, 'Test Contact Agent');
        
        runLeadStatusTest(acc, conAgent, null, Date.today());
    }
    
    @IsTest
    static void testGetLeadStatusCounts_FutureFromDate() {
        Account acc = [SELECT Id FROM Account where name = 'Test Account - 1'];
        Contact conAgent = createContact(acc, 'Agent', true, 'Test Contact Agent');
        
        runLeadStatusTest(acc, conAgent, Date.today().addDays(5), Date.today().addDays(10));
    }
    
    @IsTest
    static void testGetLeadStatusCounts_UnauthorizedRole() {
        Account acc = [SELECT Id FROM Account where name = 'Test Account - 1'];
        Contact conAgent = createContact(acc, 'Agent', true, 'Test Contact Agent');
        
        runLeadStatusTest(acc, conAgent, null, null);
    }
    
    @IsTest
    static void testGetLeadStatusCounts_NullRole() {
        Account acc = [SELECT Id FROM Account where name = 'Test Account - 1'];
        Contact conBrokerNull = createContact(acc, null, false, 'Test Contact null');
        
        runLeadStatusTest(acc, conBrokerNull, null, null);
    }
    
    @IsTest
    static void testGetLeadStatusCounts_MissingToDate() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account - 1'];
        Contact conAgent = createContact(acc, 'Agent', true, 'Test Contact Agent - Missing ToDate');
        
        runLeadStatusTest(acc, conAgent, Date.today().addDays(-5), null);
    }
    
    // ======================
    // Broker Summary Counts - METHOD
    // ======================
    @IsTest
    static void testMissingRequestBody() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = 'GET';
        req.requestUri = '/services/apexrest/brokerAppWebService/V1/brokerSummaryCount';
        req.requestBody = null;
        RestContext.request = req;
        RestContext.response = res;
        
        BAPPGetLeadsHandler.getBrokerSummaryCounts();
        System.debug('Response (Missing Body): ' + RestContext.response.responseBody.toString());
    }
    
    @IsTest
    static void testAccessDeniedRole() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Broker Summary Account' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE BrokerContactRole__c = 'Agent' LIMIT 1];
        
        Map<String, Object> body = new Map<String, Object>{
            'accountId' => acc.Id,
                'contactId' => con.Id
                };
                    
                    RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = 'GET';
        req.requestUri = '/services/apexrest/brokerAppWebService/V1/brokerSummaryCount';
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        RestContext.request = req;
        RestContext.response = res;
        
        BAPPGetLeadsHandler.getBrokerSummaryCounts();
        System.debug('Response (Access Denied): ' + RestContext.response.responseBody.toString());
    }
    
    @IsTest
    static void testNoActiveContacts() {
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Broker Summary Account' LIMIT 1];
        Contact admin = [SELECT Id, Name, BrokerContactRole__c FROM Contact WHERE BrokerContactRole__c = 'Admin' LIMIT 1];
        
        // Fetch all related contacts first
        List<Contact> allContacts = [
            SELECT Id, Name, IsActive__c, BrokerContactRole__c, Email, Phone, AccountId
            FROM Contact
            WHERE AccountId = :acc.Id
        ];
        
        // Make all contacts inactive
        for (Contact c : allContacts) {
            c.IsActive__c = false;
        }
        update allContacts;
        
        
        // Prepare request
        Map<String, Object> body = new Map<String, Object>{
            'accountId' => acc.Id,
                'contactId' => admin.Id
                };
                    
                    RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = 'GET';
        req.requestUri = '/services/apexrest/brokerAppWebService/V1/brokerSummaryCount';
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        BAPPGetLeadsHandler.getBrokerSummaryCounts();
        Test.stopTest();
        
        System.debug('Response (No Active Contacts): ' + RestContext.response.responseBody.toString());
    }
    
    @IsTest
    static void testGetBrokerSummaryCounts_Valid() {
        // Fetch existing setup records
        Account acc = [SELECT Id FROM Account WHERE Name = 'Broker Summary Account' LIMIT 1];
        Contact admin = [SELECT Id FROM Contact WHERE BrokerContactRole__c = 'Admin' LIMIT 1];
        Contact agent = [SELECT Id FROM Contact WHERE BrokerContactRole__c = 'Agent' LIMIT 1];
        // === Insert Project__c ===
        Project__c proj1 = new Project__c(
            Name = 'Test Project 1'
        );
        insert proj1;
        
        // Insert valid data for all components
        insertTestLeads(acc, agent);
        insertTestSalesOrders(acc, agent);
        insertTestBrokerCommissions(acc, agent, proj1);
        
        // Prepare request body
        Map<String, Object> body = new Map<String, Object>{
            'accountId' => acc.Id,
                'contactId' => admin.Id,
                'updatedOnFrom' => String.valueOf(Date.today().addDays(-30)),
                'updatedOnTo' => String.valueOf(Date.today())
                };
                    
                    RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = 'GET';
        req.requestUri = '/services/apexrest/brokerAppWebService/V1/brokerSummaryCount';
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        RestContext.request = req;
        RestContext.response = res;
        
        //  Execute
        Test.startTest();
        BAPPGetLeadsHandler.getBrokerSummaryCounts();
        Test.stopTest();
        
        System.debug('Response (Valid): ' + RestContext.response.responseBody.toString());
    }
    
    @IsTest
    static void testBrokerSummary_Exception() {
        // Force exception: invalid date string
        Account acc = [SELECT Id FROM Account WHERE Name = 'Broker Summary Account' LIMIT 1];
        Contact admin = [SELECT Id FROM Contact WHERE BrokerContactRole__c = 'Admin' LIMIT 1];
        
        Map<String, Object> body = new Map<String, Object>{
            'accountId' => acc.Id,
                'contactId' => admin.Id,
                'updatedOnFrom' => 'INVALID_DATE'
                };
                    
                    RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = 'GET';
        req.requestUri = '/services/apexrest/brokerAppWebService/V1/brokerSummaryCount';
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        BAPPGetLeadsHandler.getBrokerSummaryCounts();
        Test.stopTest();
        
        System.debug('Response (Exception Path): ' + RestContext.response.responseBody.toString());
    }
    
    @IsTest
    static void testBrokerSummaryDTOs() {
        BAPPGetLeadsHandler.BrokerSummaryResponse summary = new BAPPGetLeadsHandler.BrokerSummaryResponse();
        summary.LeadCreated = 5;
        summary.LeadConverted = 2;
        summary.NewLead = 1;
        summary.InProgressLead = 2;
        summary.ClosedLead = 1;
        summary.SalesOrder = 3;
        summary.TotalCommission = 100.55;
        summary.ConversionRate = 40;
        
        BAPPGetLeadsHandler.BrokerContactWrapper wrapper = new BAPPGetLeadsHandler.BrokerContactWrapper();
        wrapper.BrokerAgentName = 'Test Agent';
        wrapper.BrokerContactId = '003000000000001';
        wrapper.BrokerSummary = summary;
        
        System.debug('Wrapper DTO: ' + JSON.serialize(wrapper));
    }
    
    // ======================
    // FILTER - METHOD
    // ======================
    @IsTest
    static void test_FilterScenario_Success() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Broker Summary Account' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE BrokerContactRole__c = 'Admin' LIMIT 1];
        
        Date fromDate = Date.today().addDays(-15);
        Date toDate = Date.today();
        
        Map<String, Object> body = new Map<String, Object>{
            'accountId' => acc.Id,
                'contactId' => con.Id,
                'leadType' => 'IndividualLead',
                'scenario' => 'FILTER',
                'filterCriteria' => new Map<String, Object>{
                    'status' => 'New;Closed',
                        'updatedOnFrom' => fromDate,
                        'updatedOnTo' => toDate
                        }
        };
            
            RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/brokerAppWebService/V1/getLeads';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        BAPPGetLeadsHandler.handleLeadFilters();
        Test.stopTest();
        
    }
    
    @IsTest
    static void test_AllScenario_Success() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Broker Summary Account' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE BrokerContactRole__c = 'Admin' LIMIT 1];
        
        Map<String, Object> body = new Map<String, Object>{
            'accountId' => acc.Id,
                'contactId' => con.Id,
                'leadType' => 'organizationlead',
                'scenario' => 'ALL'
                };
                    
                    RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = 'POST';
        req.requestUri = '/services/apexrest/brokerAppWebService/V1/getLeads';
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        BAPPGetLeadsHandler.handleLeadFilters();
        Test.stopTest();
        
    }
    
    @IsTest
    static void test_MissingAccountContact_Error() {
        Map<String, Object> body = new Map<String, Object>{
            'accountId' => null,
                'contactId' => null
                };
                    
                    RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = 'POST';
        req.requestUri = '/services/apexrest/brokerAppWebService/V1/getLeads';
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        BAPPGetLeadsHandler.handleLeadFilters();
        Test.stopTest();
        
    }
    
    @IsTest
    static void test_InvalidDateRange_Error() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Broker Summary Account' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE BrokerContactRole__c = 'Admin' LIMIT 1];
        
        Map<String, Object> body = new Map<String, Object>{
            'accountId' => acc.Id,
                'contactId' => con.Id,
                'scenario' => 'FILTER',
                'filterCriteria' => new Map<String, Object>{
                    'updatedOnFrom' => Date.today().addDays(-120),
                        'updatedOnTo' => Date.today()
                        }
        };
            
            RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = 'POST';
        req.requestUri = '/services/apexrest/brokerAppWebService/V1/getLeads';
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        BAPPGetLeadsHandler.handleLeadFilters();
        Test.stopTest();
        
    }
    
    @IsTest
    static void test_MissingScenario_Error() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Broker Summary Account' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE BrokerContactRole__c = 'Admin' LIMIT 1];
        
        Map<String, Object> body = new Map<String, Object>{
            'accountId' => acc.Id,
                'contactId' => con.Id
                };
                    
                    RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = 'POST';
        req.requestUri = '/services/apexrest/brokerAppWebService/V1/getLeads';
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        BAPPGetLeadsHandler.handleLeadFilters();
        Test.stopTest();
        
    }
    
    @IsTest
    static void testHandleLeadFilters_OwnerBranches() {
        // ===== Create supporting data =====
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        User realUser = new User(
            Alias = 'rlusr',
            Email = 'realuser+' + System.currentTimeMillis() + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'RealUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = adminProfile.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            UserName = 'realuser' + System.currentTimeMillis() + '@example.com'
        );
        insert realUser;
        
        // ===== Use runAs to create queue to avoid mixed DML error =====
        Group queue;
        System.runAs(realUser) {
            queue = new Group(
                Name = 'Broker Unassigned Leads',
                Type = 'Queue'
            );
            insert queue;
            
            QueueSobject qs = new QueueSobject(
                QueueId = queue.Id,
                SobjectType = 'Lead'
            );
            insert qs;
        }
        
        // ===== Create account and contact =====
        Account acc = [SELECT Id FROM Account WHERE Name = 'Broker Summary Account' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE BrokerContactRole__c = 'Admin' LIMIT 1];
        
        // ===== Create Leads for both owner cases =====
        Lead queueLead = new Lead(
            LastName = 'Queue Lead',
            Company = 'Queue Co',
            Status = 'New',
            OwnerId = queue.Id,
            BrokerAgency__c = acc.Id
        );
        
        Lead userLead = new Lead(
            LastName = 'User Lead',
            Company = 'User Co',
            Status = 'New',
            OwnerId = realUser.Id,
            BrokerAgency__c = acc.Id
        );
        insert new List<Lead>{ queueLead, userLead };
            
            // ===== Re-query Leads to populate Owner relationships =====
            queueLead = [SELECT Id, OwnerId, Owner.Name, Owner.Email, Owner.Profile.Name FROM Lead WHERE Id = :queueLead.Id];
        userLead  = [SELECT Id, OwnerId, Owner.Name, Owner.Email, Owner.Profile.Name FROM Lead WHERE Id = :userLead.Id];
        
        // ===== Build REST request body =====
        Map<String, Object> body = new Map<String, Object>{
            'accountId' => acc.Id,
                'contactId' => con.Id,
                'scenario'  => 'ALL',
                'leadType'  => 'IndividualLead'
                };
                    
                    RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/brokerAppWebService/V1/getLeads';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;
        
        // ===== Call method under test =====
        Test.startTest();
        BAPPGetLeadsHandler.handleLeadFilters();
        Test.stopTest();
        
        // ===== Verify response =====
        System.debug('Response: ' + RestContext.response.responseBody.toString());
    }
    
    @IsTest // NOT NEEDED - DELETE AFTER FINAL REVIEW
    static void testHandleLeadFilters_UserOwnerBranch() {
        // Create a real User
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User u = new User(
            Alias = 'uowner',
            Email = 'userowner+' + System.currentTimeMillis() + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'OwnerUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = adminProfile.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            UserName = 'userowner' + System.currentTimeMillis() + '@example.com'
        );
        insert u;
        
        // ===== Create account and contact =====
        Account acc = [SELECT Id FROM Account WHERE Name = 'Broker Summary Account' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE BrokerContactRole__c = 'Admin' LIMIT 1];
        
        // Insert Lead owned by the User
        Lead userLead = new Lead(
            LastName = 'Lead User Owner',
            Company = 'UserOwner Co',
            Status = 'New',
            LeadSource = 'Event',
            OwnerId = u.Id
        );
        insert userLead;
        
        // Build REST request body
        Map<String, Object> body = new Map<String, Object>{
            'accountId' => acc.Id,
                'contactId' => con.Id,
                'scenario' => 'ALL',
                'leadType' => 'IndividualLead'
                };
                    
                    RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/brokerAppWebService/V1/getLeads';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;
        
        // Call the public method that internally calls toRecord()
        Test.startTest();
        BAPPGetLeadsHandler.handleLeadFilters();
        Test.stopTest();
        
    }
    
    @IsTest
    static void testFromDateWithoutToDate() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Broker Summary Account' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE BrokerContactRole__c = 'Admin' LIMIT 1];
        
        // Pass only updatedOnFrom, should trigger "FromAndToDatesRequired"
        runLeadFiltersTest(acc, con, 'FILTER', Date.today().addDays(-10), null);
    }
    
    @IsTest
    static void testToDateWithoutFromDate() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Broker Summary Account' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE BrokerContactRole__c = 'Admin' LIMIT 1];
        
        // Pass only updatedOnTo, should trigger "FromAndToDatesRequired"
        runLeadFiltersTest(acc, con, 'FILTER', null, Date.today());
    }
    
    @IsTest
    static void testFromDateInFuture() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Broker Summary Account' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE BrokerContactRole__c = 'Admin' LIMIT 1];
        
        // Pass future updatedOnFrom, should trigger "FromDateCannotFuture"
        runLeadFiltersTest(acc, con, 'FILTER', Date.today().addDays(5), Date.today().addDays(6));
    }
    
    @IsTest
    static void testToDateInFuture() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Broker Summary Account' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE BrokerContactRole__c = 'Admin' LIMIT 1];
        
        // Pass future updatedOnTo, should trigger "ToDateCannotFuture"
        runLeadFiltersTest(acc, con, 'FILTER', Date.today().addDays(-2), Date.today().addDays(3));
    }
    
    @IsTest
    static void testAllScenarioWithFilterCriteria() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Broker Summary Account' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE BrokerContactRole__c = 'Admin' LIMIT 1];
        
        // scenario = ALL and filterCriteria provided, should trigger "FilterCriteriaMustBeNullForAll"
        runLeadFiltersTest(acc, con, 'ALL', Date.today().addDays(-5), Date.today());
    }
    
    @IsTest
    static void testFilterScenarioWithoutFilterCriteria() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Broker Summary Account' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE BrokerContactRole__c = 'Admin' LIMIT 1];
        
        // scenario = FILTER but no filterCriteria provided, should trigger "FilterCriteriaRequiredForFilter"
        runLeadFiltersTest(acc, con, 'FILTER', null, null);
    }
    
    // ==== Account helper ====
    private static Account createAccount(String accName) {
        Account acc = new Account();
        acc.Name = accName;
        acc.RecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType,'Broker_Agency');
        insert acc;
        return acc;
    }
    
    // ==== Contact helper ====
    private static Contact createContact(Account acc, String role, Boolean isActive, String conName) {
        Contact con = new Contact(
            LastName = conName,
            AccountId = acc.Id,
            BrokerContactRole__c = role,
            IsActive__c = isActive,
            Email ='johnny.depp+' + System.currentTimeMillis() + '@example.com',
            RecordTypeId = Utility.getRecordTypeIdByDevName(Contact.SObjectType, 'Broker'));
        insert con;
        return con;
    }
    
    // ==== Lead helper ====
    private static Lead createLead(Account acc, Contact con, String status, Integer num) {
        Lead l = new Lead();
        l.LastName = 'Lead ' + num;
        l.Company = 'Test Company ' + num;
        l.Status = status;
        l.BrokerAgency__c = acc.Id;
        l.BrokerAgent__c = con.Id;
        l.RecordTypeId = Utility.getRecordTypeIdByDevName(
            Lead.SObjectType,
            'IndividualLead'
        );
        insert l;
        return l;
    }
    
    private static void runLeadStatusTest(Account acc, Contact con, Date fromDate, Date toDate) {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/brokerAppWebService/V1/leadStatusCount';
        req.httpMethod = 'GET';
        
        Map<String, Object> body = new Map<String, Object>{
            'accountId' => acc.Id,
                'contactId' => con.Id
                };
                    
                    if (fromDate != null) body.put('updatedOnFrom', fromDate);
        if (toDate != null)   body.put('updatedOnTo', toDate);
        
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        BAPPWebService.doGet();
        Test.stopTest();
        
        System.debug('Response (From > To): ' + RestContext.response.responseBody.toString());
    }
    
    // Helper method to run handleLeadFilters with dates
    private static void runLeadFiltersTest(Account acc, Contact con, String scenario, Date fromDate, Date toDate) {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/brokerAppWebService/V1/getLeads';
        req.httpMethod = 'POST';
        
        Map<String, Object> filterCriteria = new Map<String, Object>();
        if (fromDate != null) filterCriteria.put('updatedOnFrom', fromDate);
        if (toDate != null) filterCriteria.put('updatedOnTo', toDate);
        
        Map<String, Object> body = new Map<String, Object>{
            'accountId' => acc.Id,
                'contactId' => con.Id,
                'scenario' => scenario
                };
                    
                    if (!filterCriteria.isEmpty()) {
                        body.put('filterCriteria', filterCriteria);
                    }
        
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        BAPPGetLeadsHandler.handleLeadFilters();
        Test.stopTest();
        
        System.debug('Response: ' + RestContext.response.responseBody.toString());
    }
    
    private static void insertTestLeads(Account acc, Contact agent) {
        List<Lead> leads = new List<Lead>();
        
        for (Integer i = 0; i < 3; i++) {
            leads.add(new Lead(
                LastName = 'Lead ' + i,
                Company = 'Test Co ' + i,
                Status = (i == 2 ? 'Closed' : 'New'),
                BrokerAgency__c = acc.Id,
                BrokerAgent__c = agent.Id,
                lead_channel__c = 'Broker Portal',
                ownerId = Userinfo.getUserId(),
                RecordTypeId = Utility.getRecordTypeIdByDevName(Lead.SObjectType, 'IndividualLead')
            ));
        }
        insert leads;
    }
    
    private static void insertTestSalesOrders(Account acc, Contact agent) {
        // Create Opportunity (because SalesOrder__c references it)
        Opportunity opp = new Opportunity(
            Name = 'Broker Opp ' + acc.Id,
            StageName = 'Closed Won',
            WinReason__c = 'New Project Launch',
            CloseDate = Date.today(),
            BrokerAgencyAccount__c = acc.Id,
            BrokerAgentContact__c = agent.Id
        );
        insert opp;
        
        List<SalesOrder__c> orders = new List<SalesOrder__c>();
        for (Integer i = 0; i < 2; i++) {
            orders.add(new SalesOrder__c(
                Name = 'SO-' + i,
                Opportunity__c = opp.Id,
                Status__c = 'Reserved',
                Account__c = acc.Id,
                SubStatus__c = 'Submitted to Sales Operations'
            ));
        }
        insert orders;
    }
    
    private static void insertTestBrokerCommissions(Account acc, Contact agent, Project__c projRec) {
        // Get any SalesOrder created for the agent
        List<SalesOrder__c> soList = [SELECT Id, Opportunity__r.BrokerAgentContact__c FROM SalesOrder__c LIMIT 1];
        if (soList.isEmpty()) return;
        
        List<BrokerCommission__c> commissions = new List<BrokerCommission__c>();
        for (Integer i = 0; i < 2; i++) {
            commissions.add(new BrokerCommission__c(
                Status__c = 'Paid',
                CommissionAmount__c = 2500 + (i * 500),
                SalesOrder__c = soList[0].Id,
                Project__c = projRec.Id,
                StartDate__c = Date.today()
            ));
        }
        insert commissions;
    }
    
    @IsTest
    static void test_InvalidScenario_Error() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        
        Map<String, Object> body = new Map<String, Object>{
            'accountId' => acc.Id,
                'contactId' => con.Id,
                'scenario' => 'INVALID'
                };
                    
                    RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/brokerAppWebService/V1/getLeads';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        BAPPGetLeadsHandler.handleLeadFilters();
        Test.stopTest();
    }
    
    @IsTest
    static void test_FilterScenario_EmptyCriteria_Error() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        
        Map<String, Object> body = new Map<String, Object>{
            'accountId' => acc.Id,
                'contactId' => con.Id,
                'scenario' => 'FILTER',
                'filterCriteria' => new Map<String, Object>() // EMPTY
                };
                    
                    RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/brokerAppWebService/V1/getLeads';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        BAPPGetLeadsHandler.handleLeadFilters();
        Test.stopTest();
    }
    
    @IsTest
    static void test_DateRange_Exceeds90Days() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        
        Map<String, Object> body = new Map<String, Object>{
            'accountId' => acc.Id,
                'contactId' => con.Id,
                'scenario' => 'FILTER',
                'filterCriteria' => new Map<String, Object>{
                    'updatedOnFrom' => Date.today().addDays(-120),
                        'updatedOnTo' => Date.today()
                        }
        };
            
            RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/brokerAppWebService/V1/getLeads';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        BAPPGetLeadsHandler.handleLeadFilters();
        Test.stopTest();
    }
    
    @IsTest
    static void test_ConvertedLead_StatusCount() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        
        Lead l = new Lead(
            LastName = 'Convert Me',
            Company = 'Test Co',
            Status = 'New'
        );
        insert l;
        LeadStatus ls = [SELECT MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        // Convert Lead
        /*Database.LeadConvert lc = new Database.LeadConvert();
lc.setLeadId(l.Id);
lc.setConvertedStatus(ls.MasterLabel);
lc.setDoNotCreateOpportunity(false);
Database.convertLead(lc);*/
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/brokerAppWebService/V1/leadStatusCount';
        req.httpMethod = 'GET';
        req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
            'accountId' => acc.Id,
                'contactId' => con.Id
                }));
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        BAPPWebService.doGet();
        Test.stopTest();
    }
    
    @IsTest
    static void test_HasAdminAccess_MultipleRoles() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Contact con = new Contact(
            LastName = 'Multi Role',
            AccountId = acc.Id,
            BrokerContactRole__c = 'Agent;CEO',
            Email = 'johnny.depp+' + System.currentTimeMillis() + '@example.com'
        );
        insert con;
        
        Map<String, Object> body = new Map<String, Object>{
            'accountId' => acc.Id,
                'contactId' => con.Id,
                'scenario' => 'ALL'
                };
                    
                    RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/brokerAppWebService/V1/getLeads';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(body));
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        BAPPGetLeadsHandler.handleLeadFilters();
        Test.stopTest();
    }
    
    @IsTest
    static void test_QueueOwner_BrokerUnassignedBranch() {
        // Create User (needed for runAs)
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Contact con = new Contact(
            LastName = 'Multi Role',
            AccountId = acc.Id,
            BrokerContactRole__c = 'Agent;CEO',
            Email = 'johnny.depp+' + System.currentTimeMillis() + '@example.com'
        );
        insert con;
        User u = new User(
            Alias = 'testu',
            Email = 'testu+' + System.currentTimeMillis() + '@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            UserName = 'testu' + System.currentTimeMillis() + '@test.com'
        );
        insert u;
        
        System.runAs(u) {
            // Create Queue EXACT NAME
            Group queue = new Group(
                Name = 'Broker Unassigned Leads',
                Type = 'Queue'
            );
            insert queue;
            
            insert new QueueSobject(
                QueueId = queue.Id,
                SobjectType = 'Lead'
            );
            
            // Create Lead owned by Queue
            Lead l = new Lead(
                LastName = 'Queue Lead',
                Company = 'Test Co',
                Status = 'New',
                OwnerId = queue.Id,
                BrokerAgency__c = acc.Id,
                BrokerAgent__c = con.Id,
                lead_channel__c = 'Broker Portal',
                RecordTypeId = Utility.getRecordTypeIdByDevName(
                    Lead.SObjectType, 'IndividualLead'
                )
            );
            insert l;
            
            // IMPORTANT: Re-query WITH Owner fields
            l = [
                SELECT Id, OwnerId, Owner.Name, Owner.Email 
                FROM Lead 
                WHERE Id = :l.Id
            ];
            
            // Call method via REST
            Map<String, Object> body = new Map<String, Object>{
                'accountId' => acc.Id,
                    'contactId' => con.Id,
                    'scenario'  => 'ALL'
                    };
                        
                        RestRequest req = new RestRequest();
            req.requestUri = '/services/apexrest/brokerAppWebService/V1/getLeads';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueOf(JSON.serialize(body));
            
            RestContext.request = req;
            RestContext.response = new RestResponse();
            
            Test.startTest();
            BAPPGetLeadsHandler.handleLeadFilters();
            Test.stopTest();
        }
    } 
}