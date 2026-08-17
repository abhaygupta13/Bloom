@IsTest
private class BAPPGetSalesOrdersHandlerTest {
    
    // ====== Common Test Data Setup ======
    @TestSetup
    static void setupData() {
        Date today = System.today();
        // Create Account
        Account acc = new Account(
            Name = 'Test Broker Account',
            RecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, 'Broker_Agency')
        );
        insert acc;
        
        // Create Contact
        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = acc.Id,
            Email = 'test@broker.com',
            BrokerContactRole__c = 'Agent',
            RecordTypeId = Utility.getRecordTypeIdByDevName(Contact.SObjectType, 'Broker')
        );
        insert con;
        
        // ===== Project =====
        Project__c proj = new Project__c(
            Name = 'Test Project',
            IsPublic__c = true,
            IsAvailableForBroker__c = true,
            StartDate__c = today.addDays(-10),
            EndDate__c = today.addDays(10)
        );
        insert proj;
        
        // ===== Unit =====
        Unit__c unit = new Unit__c(
            Name = 'Unit-101',
            Project__c = proj.Id,
            UnitType__c = 'Apartment',
            Status__c = 'Available'
        );
        insert unit;
        
        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Closed Won',
            WinReason__c = 'New Project Launch',
            CloseDate = System.today(),
            AccountId = acc.Id,
            BrokerAgentContact__c = con.Id,
            BrokerAgencyAccount__c = acc.Id
        );
        insert opp;
        
        // Create Sales Order
        SalesOrder__c so = new SalesOrder__c(
            Name = 'SO-0001',
            Status__c = 'Booked',
            Opportunity__c = opp.Id,
            //SalesManager__c = con.Id,
            Unit__c = unit.Id,
            Account__c = acc.Id
        );
        insert so;
        
        // Create Broker Commission
        BrokerCommission__c bc = new BrokerCommission__c(
            SalesOrder__c = so.Id,
            CommissionAmount__c = 5000,
            CommissionPercentage__c = 2.5,
            VATPercentage__c = 5,
            Status__c = 'Shared',
            IsFullPayment__c = true,
            Project__c = proj.Id,                     // ✅ Required lookup
            StartDate__c = System.today().addDays(-5) // ✅ Required date
        );
        insert bc;
        
        
        // Create Document Type & Document
        DocumentType__c docType = new DocumentType__c(
            Type__c = 'Generated Invoice'
        );
        insert docType;
        
        Document__c doc = new Document__c(
            BrokerCommission__c = bc.Id,
            DocumentType__c = docType.Id
            //ContentDocumentId__c = '069XXXXXXX',
            //Content_Version_Id__c = '068XXXXXXX'
        );
        insert doc;
    }
    
    // ====== Helper: Setup REST Context ======
    private static void setupRestContext(String method, String body) {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/bapp/v1/getSalesOrders';
        req.httpMethod = method;
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;
    }
    
    // ====== Test: Valid Request Success ======
    @IsTest
    static void test_handleSalesOrderFilters_Success() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        
        // Create filter JSON
        Map<String, Object> filters = new Map<String, Object>{
            'status' => 'Booked;Sold;Cancelled',
                'salesManagerId' => con.Id,
                'updatedOnFrom' => System.today().addDays(-10),
                'updatedOnTo' => System.today()
                };
                    Map<String, Object> reqBody = new Map<String, Object>{
                        'accountId' => acc.Id,
                            'contactId' => con.Id,
                            'searchKey' => 'SO-001',
                            'filters' => filters
                            };
                                
                                setupRestContext('POST', JSON.serialize(reqBody));
        
        Test.startTest();
        BAPPGetSalesOrdersHandler.handleSalesOrderFilters();
        Test.stopTest();
        
        System.debug('Response Body: ' + RestContext.response.responseBody.toString());
    }
    
    // ====== Test: Missing Account or Contact ======
    @IsTest
    static void test_handleSalesOrderFilters_MissingIds() {
        Map<String, Object> reqBody = new Map<String, Object>{
            'accountId' => null,
                'contactId' => null
                };
                    setupRestContext('POST', JSON.serialize(reqBody));
        
        Test.startTest();
        BAPPGetSalesOrdersHandler.handleSalesOrderFilters();
        Test.stopTest();
    }
    
    // ====== Test: Invalid Account ======
    @IsTest
    static void test_handleSalesOrderFilters_InvalidAccount() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Map<String, Object> reqBody = new Map<String, Object>{
            'accountId' => '001XXXXInvalid',
                'contactId' => con.Id
                };
                    setupRestContext('POST', JSON.serialize(reqBody));
        
        Test.startTest();
        BAPPGetSalesOrdersHandler.handleSalesOrderFilters();
        Test.stopTest();
    }
    
    // ====== Test: Invalid Contact ======
    @IsTest
    static void test_handleSalesOrderFilters_InvalidContact() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Map<String, Object> reqBody = new Map<String, Object>{
            'accountId' => acc.Id,
                'contactId' => '003XXXXInvalid'
                };
                    setupRestContext('POST', JSON.serialize(reqBody));
        
        Test.startTest();
        BAPPGetSalesOrdersHandler.handleSalesOrderFilters();
        Test.stopTest();
    }
    
    // ====== Test: Date Range Validation ======
    @IsTest
    static void test_handleSalesOrderFilters_InvalidDateRange() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        
        Map<String, Object> filters = new Map<String, Object>{
            'updatedOnFrom' => System.today().addDays(5),
                'updatedOnTo' => System.today()
                };
                    Map<String, Object> reqBody = new Map<String, Object>{
                        'accountId' => acc.Id,
                            'contactId' => con.Id,
                            'filters' => filters
                            };
                                setupRestContext('POST', JSON.serialize(reqBody));
        
        Test.startTest();
        BAPPGetSalesOrdersHandler.handleSalesOrderFilters();
        Test.stopTest();
    }
    
    // ====== Test: Missing updatedOnTo when updatedOnFrom provided ======
    @IsTest
    static void test_handleSalesOrderFilters_MissingUpdatedOnTo() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        
        Map<String, Object> filters = new Map<String, Object>{
            'updatedOnFrom' => System.today().addDays(-5)
                };
                    Map<String, Object> reqBody = new Map<String, Object>{
                        'accountId' => acc.Id,
                            'contactId' => con.Id,
                            'filters' => filters
                            };
                                setupRestContext('POST', JSON.serialize(reqBody));
        
        Test.startTest();
        BAPPGetSalesOrdersHandler.handleSalesOrderFilters();
        Test.stopTest();
    }
    
    // ====== Test: Exception Handling (Invalid JSON) ======
    @IsTest
    static void test_handleSalesOrderFilters_ExceptionCase() {
        setupRestContext('POST', '{invalidJson:true}');
        
        Test.startTest();
        BAPPGetSalesOrdersHandler.handleSalesOrderFilters();
        Test.stopTest();
    }
    
    @IsTest
    static void test_handleSalesOrderFilters_RecordNotExists() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        // ContactId exists but will delete to simulate record missing
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        delete con; // simulate non-existent contact
        
        Map<String, Object> reqBody = new Map<String, Object>{
            'accountId' => acc.Id,
                'contactId' => con.Id // now deleted
                };
                    
                    setupRestContext('POST', JSON.serialize(reqBody));
        
        Test.startTest();
        BAPPGetSalesOrdersHandler.handleSalesOrderFilters();
        Test.stopTest();
    }
    @IsTest
    static void test_handleSalesOrderFilters_InvalidAccountContactRelation() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        
        // Create a new account not related to the contact
        Account otherAcc = new Account(Name = 'Other Account');
        insert otherAcc;
        
        Map<String, Object> reqBody = new Map<String, Object>{
            'accountId' => otherAcc.Id,
                'contactId' => con.Id
                };
                    
                    setupRestContext('POST', JSON.serialize(reqBody));
        
        Test.startTest();
        BAPPGetSalesOrdersHandler.handleSalesOrderFilters();
        Test.stopTest();
    }
    
    @IsTest
    static void test_handleSalesOrderFilters_UpdatedOnToFuture() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        
        Map<String, Object> filters = new Map<String, Object>{
            'updatedOnTo' => System.today().addDays(5) // future date
                };
                    Map<String, Object> reqBody = new Map<String, Object>{
                        'accountId' => acc.Id,
                            'contactId' => con.Id,
                            'filters' => filters
                            };
                                
                                setupRestContext('POST', JSON.serialize(reqBody));
        
        Test.startTest();
        BAPPGetSalesOrdersHandler.handleSalesOrderFilters();
        Test.stopTest();
    }
    @IsTest
    static void test_handleSalesOrderFilters_UpdatedOnRangeInvalid() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        
        Map<String, Object> filters = new Map<String, Object>{
            'updatedOnFrom' => System.today(),
                'updatedOnTo' => System.today().addDays(-1)
                };
                    Map<String, Object> reqBody = new Map<String, Object>{
                        'accountId' => acc.Id,
                            'contactId' => con.Id,
                            'filters' => filters
                            };
                                
                                setupRestContext('POST', JSON.serialize(reqBody));
        
        Test.startTest();
        BAPPGetSalesOrdersHandler.handleSalesOrderFilters();
        Test.stopTest();
    }

        @IsTest
        static void testSerializeResponse_basic() {
            // ==== Build sample wrapper ====
            BAPPGetSalesOrdersHandler.GetSalesOrdersResponse resp = 
                new BAPPGetSalesOrdersHandler.GetSalesOrdersResponse();
            resp.status = 'success';
            
            // ==== Build SalesOrderRecord ====
            BAPPGetSalesOrdersHandler.SalesOrderRecord soRec = 
                new BAPPGetSalesOrdersHandler.SalesOrderRecord();
            soRec.id = 'a0WFakeSO123456789';
            soRec.orderNumber = 'SO-0001';
            soRec.salesManagerId = '005FakeMgr001';
            soRec.status = 'Booked';
            soRec.salesManagerName = 'John Doe';
            soRec.customerName = 'Acme Corp';
            soRec.projectName = 'Sunrise Towers';
            soRec.unitType = '2BHK';
            soRec.unitName = 'Unit 203';
            soRec.lastModifiedDate = Datetime.now();
            
            // ==== Build CommissionRecord ====
            BAPPGetSalesOrdersHandler.CommissionRecord comm = 
                new BAPPGetSalesOrdersHandler.CommissionRecord();
            comm.id = 'a07FakeComm001';
            comm.status = 'Shared';
            comm.invoiceNumber = 'INV-100';
            comm.commissionAmount = 5000;
            comm.commissionPercentage = 2.5;
            comm.vatPercentage = 5.0;
            comm.totalCommissionAmountWithVAT = 5250;
            comm.installmentNumber = 1;
            comm.isFullPayment = true;
            
            // ==== Build DocumentRecord ====
            BAPPGetSalesOrdersHandler.DocumentRecord doc = 
                new BAPPGetSalesOrdersHandler.DocumentRecord();
            doc.id = '069FakeDoc001';
            doc.contentDocumentId = '069FakeCD001';
            doc.contentVersionId = '068FakeCV001';
            doc.name = 'Invoice.pdf';
            comm.documents = new List<BAPPGetSalesOrdersHandler.DocumentRecord>{ doc };
                
                // Add commissions to SO record
                soRec.commissions = new List<BAPPGetSalesOrdersHandler.CommissionRecord>{ comm };
                    
                    // Add SO to response
                    resp.salesOrders = new List<BAPPGetSalesOrdersHandler.SalesOrderRecord>{ soRec };
                        
                        // ==== Call serialize method ====
                        String jsonOutput = BAPPGetSalesOrdersHandler.serializeResponse(resp);
            
            // Optional: pretty debug
            System.debug('Serialized JSON: ' + jsonOutput);
        }    
    
    @IsTest
    static void testMapStatus_allScenarios() {
        // Null input
        BAPPGetSalesOrdersHandler.mapStatus(null);

        // Booked group
        for (String val : new List<String>{'Booked', 'Validation In Progress', 'Approve Pending', 'Reserved'}) {
            BAPPGetSalesOrdersHandler.mapStatus(val);
        }

        // Sold group
        BAPPGetSalesOrdersHandler.mapStatus('Sold');

        // Cancelled group
        for (String val : new List<String>{'Cancelled', 'Book Cancelled'}) {
            BAPPGetSalesOrdersHandler.mapStatus(val);
        }

        // Fallback (unmapped)
        BAPPGetSalesOrdersHandler.mapStatus('In Progress');
    }
}