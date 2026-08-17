@isTest
public class BAWebServiceHelperTest {
    private static final string POST_SALE_PAYMENT_DEFERRAL { get { return 'Postpone/Defer payment'; } }
    private static final string BFM_SERVICE_REQUEST { get { return 'BFM Service Request'; } }
    private static final string FINANCIAL_PAYMENT_SERVICE_CATEGORY{ get { return 'Financial - Payment Service'; } }
    private static final string SERVICE_COMPLAINT { get { return 'Complaint'; } }
    private static final string  CRM_CATEGORY{ get { return 'CRM'; } }
    private static final string  BFM_SERVICE_CATEGORY{ get { return 'BFM Service'; } }
    private static final string SERVICE_REQUEST { get { return 'Service Request'; } }
    
    @testSetup
    static void setupData() {
        Id paRtId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('PersonAccount')
            .getRecordTypeId();
        
        Account acc = new Account(
            RecordTypeId = paRtId,
            FirstName = 'John',
            LastName = 'Doe',
            PersonEmail = 'test@gmail.com',
            Emirates_Id__pc = 'EID123',
            Nationality__pc = 'India',
            PersonBirthdate = Date.newInstance(1990, 1, 1),
            PrimaryMobilePhone__pc = '9999999999',
            PrimaryMobileCountryCode__pc = '91'
        );
        insert acc;
        
        acc = [
            SELECT Id, PersonContactId
            FROM Account
            WHERE Id = :acc.Id
        ];
        
        // Create Project (nested relationship in InstallmentLines__c)
        Project__c project = new Project__c(Name = 'Test Project', EnableLatePaymentFee__c = true);
        insert project;
        
        // Create Building
        Building__c building = TestDataFactory.createBuilding('Building 1', project.Id);
        insert building;
        
        // Create Unit
        Unit__c unit = new Unit__c(Name = 'Test Unit', Project__c = project.Id);
        insert unit;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = acc.Id,
            WinReason__c = 'New Project Launch'
        );
        insert opp;
        
        // Create Sales Order
        SalesOrder__c so = new SalesOrder__c(
            Name = 'SO-001',
            Status__c = 'Sold',
            Account__c = acc.Id,
            Unit__c = unit.Id,
            Opportunity__c = opp.Id,
            SoldDate__c = Date.today()
        );
        insert so;
        
        InstallmentLines__c il1 = new InstallmentLines__c(
            SalesOrder__c = so.Id,
            InstallmentNumber__c = 1,
            InstallmentAmount__c = 10000,
            AmountReceived__c = 5000,
            ClearedAmount__c  = 5000,
            InstallmentPercentage__c = 50,
            Type__c = 'Installment',
            InstallmentDate__c = Date.today(),
            Description__c = 'Installment 1'
        );
        
        InstallmentLines__c il2 = new InstallmentLines__c(
            SalesOrder__c = so.Id,
            InstallmentNumber__c = 2,
            InstallmentAmount__c = 10000,
            AmountReceived__c = 2000,
            ClearedAmount__c  = 2000,
            InstallmentPercentage__c = 50,
            Type__c = 'Post Handover Installment',
            InstallmentDate__c = Date.today(),
            Description__c = 'Installment 2'
        );
        insert new List<InstallmentLines__c>{ il1, il2 };
            
            SalesOrderOtherCharges__c oc = new SalesOrderOtherCharges__c(
                SalesOrder__c = so.Id,
                TypeOfCharge__c = 'Service Charge',
                Amount__c = 2000,
                InvoicedAmount__c = 1000,
                Due_Date__c = Date.today().addDays(5)
            );
        insert oc;
        
        List<Case> caseList = new List<Case>();
        for(Integer i = 0; i<10; i++){
            Case caseBFMObj = TestDataFactory.createBFMCase('Email', 'New', 'Test description', 'Test Subject',null,'test@gmail.com','0123456789');
            caseBFMObj.AccountId = acc.Id;
            caseBFMObj.SuppliedEmail = 'test123@gmail.com';
            caseList.add(caseBFMObj);
        }
        insert caseList;
        
        List<ServiceCatalog__c> scList = new List<ServiceCatalog__c>();
        ServiceCatalog__c scBFM = TestDataFactory.createServiceCatalog('BFM', 'Sales', 'Service Request', 'BFM Service', 'BFM Service Request', 'Account;Sales Order;Unit', 'BFMServiceRequest');
        scBFM.AvailableForOwner__c = true;scBFM.AvailableForTenant__c = true;
        ServiceCatalog__c scPost = TestDataFactory.createServiceCatalog('BFM', 'Sales', 'Service Request', 'Financial - Payment Service', POST_SALE_PAYMENT_DEFERRAL, 'Account;Sales Order;Unit', 'Post_Sale_Payment_Deferral');
        scPost.AvailableForOwner__c = true;
        scList.add(scBFM); scList.add(scPost);
        
        ServiceCatalog__c testServiceCatalog = new ServiceCatalog__c(
            Name = 'Test Service Catalog',
            Type__c = 'Service Request',
            Category__c = 'Customer Service Request',
            SubCategory__c = 'KYC Update Request',
            RecordTypeDevName__c = 'ThirdPartyForm',
            AvailableForOwner__c = true,
            IsAvailableForSuperApp__c = true
        );
        scList.add(testServiceCatalog);
        
        ServiceCatalog__c testServiceCatalog1 = new ServiceCatalog__c(
            Name = 'Test Service Catalog',
            Type__c = 'Service Request',
            Category__c = 'Financial - Payment Service',
            SubCategory__c = 'Payment',
            RecordTypeDevName__c = 'Payment_Sr',
            AvailableForOwner__c = true,
            IsAvailableForSuperApp__c = true
        );
        scList.add(testServiceCatalog1);
        ServiceCatalog__c testServiceCatalog2 = new ServiceCatalog__c(
            Name = 'Test Service Catalog',
            Type__c = 'Service Request',
            Category__c = 'General Enquiry',
            SubCategory__c = 'General Enquiry',
            RecordTypeDevName__c = 'GeneralEnquiry',
            AvailableForOwner__c = true,
            IsAvailableForSuperApp__c = true
        );
        scList.add(testServiceCatalog2);
        ServiceCatalog__c testServiceCatalog3 = new ServiceCatalog__c(
            Name = 'Test Service Catalog',
            Type__c = 'Service Request',
            Category__c = 'Financial - Payment Service',
            SubCategory__c = 'Payment Due Date Update',
            RecordTypeDevName__c = 'Payment_Due_Date_Update',
            AvailableForOwner__c = true
        );
        scList.add(testServiceCatalog3);
        
        insert scList;
        
        List<OnlinePaymentLog__c> lstPaymentLog = new List<OnlinePaymentLog__c>();
        OnlinePaymentLogService service = OnlinePaymentLogService.getInstance();
        OnlinePaymentLog__c objPaymentLog = new OnlinePaymentLog__c(Contact__c = acc.PersonContactId,JSONData__c = '{"transactionId":"TX123","amount":100}',IsProcessed__c = true,
                                                                    TransactionStatus__c = 'Success');
        insert objPaymentLog;
        
        OnlinePaymentLog__c objPaymentLog1 = new OnlinePaymentLog__c(Contact__c = acc.PersonContactId,JSONData__c = '{"transactionId":"TX123","amount":100}',IsProcessed__c = true,
                                                                     TransactionStatus__c = 'Failed');       
        insert objPaymentLog1;
        lstPaymentLog.add(objPaymentLog1);
        service.updateOnlinePaymentLog(lstPaymentLog);
        
        /* ---------- App Registration ---------- */
        AppRegistration__c ar = new AppRegistration__c(
            Contact__c = acc.PersonContactId,
            Status__c = 'Under Review',
            Email__c = 'test@test.com',
            MobileCountryCode__c = '91',
            MobilePhone__c = '9999999999',
            DeviceId__c = 'DEVICE-1'
        );
        insert ar;
        
        AppRegistration__c arApproved = new AppRegistration__c(
            Contact__c = acc.PersonContactId,
            Status__c = 'Approved',
            Email__c = 'approved@test.com',
            MobileCountryCode__c = '91',
            MobilePhone__c = '9999999999',
            DeviceId__c = 'DEVICE-2'
        );
        insert arApproved;
        
        /* ---------- Documents ---------- */
        List<DocumentType__c> lstDocType = new List<DocumentType__c>{
            new DocumentType__c(Type__c = 'Passport'),
                new DocumentType__c(Type__c = 'Title Deed'),
                new DocumentType__c(Type__c = 'SPA - Signed'),
                new DocumentType__c(Type__c = 'Emirates ID Front'),
                new DocumentType__c(Type__c = 'Emirates ID Back'),
                new DocumentType__c(Type__c = 'Floor Plan')
                };
                    insert lstDocType;
        
        ContentVersion cv = new ContentVersion(
            Title = 'Passport',
            PathOnClient = 'Passport.pdf',
            VersionData = Blob.valueOf('Test content')
        );
        insert cv;
        
        // Re-query to get ContentDocumentId
        cv = [
            SELECT Id, ContentDocumentId, FileType
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];
        
        Map<String, Id> docTypeMap = new Map<String, Id>();
        for (DocumentType__c dt : lstDocType) {
            docTypeMap.put(dt.Type__c, dt.Id);
        }
        
        List<Document__c> lstDocument = new List<Document__c>{
            new Document__c(
                Account__c = acc.Id,
                DocumentType__c = docTypeMap.get('Passport'),
                Document_Name__c = 'Passport Doc',
                AppRegistration__c = ar.Id,
                ContentDocumentId__c = cv.ContentDocumentId,
                Content_Version_Id__c = cv.Id
            ),
                new Document__c(
                    Account__c = acc.Id,
                    DocumentType__c = docTypeMap.get('Emirates ID Front'),
                    Document_Name__c = 'EID Front',
                    AppRegistration__c = ar.Id,
                    ContentDocumentId__c = cv.ContentDocumentId,
                    Content_Version_Id__c = cv.Id
                ),
                new Document__c(
                    Account__c = acc.Id,
                    DocumentType__c = docTypeMap.get('Emirates ID Back'),
                    Document_Name__c = 'EID Back',
                    AppRegistration__c = ar.Id,
                    ContentDocumentId__c = cv.ContentDocumentId,
                    Content_Version_Id__c = cv.Id
                ),
                new Document__c(
                    Account__c = acc.Id,
                    DocumentType__c = docTypeMap.get('Title Deed'),
                    Document_Name__c = 'TITLE_DEED',
                    AppRegistration__c = ar.Id,
                    ContentDocumentId__c = cv.ContentDocumentId,
                    Content_Version_Id__c = cv.Id
                ),
                new Document__c(
                    Account__c = acc.Id,
                    DocumentType__c = docTypeMap.get('SPA - Signed'),
                    Document_Name__c = 'SPA_SIGNED',
                    AppRegistration__c = ar.Id,
                    ContentDocumentId__c = cv.ContentDocumentId,
                    Content_Version_Id__c = cv.Id
                ),
                new Document__c(
                    Account__c = acc.Id,
                    DocumentType__c = docTypeMap.get('Floor Plan'),
                    Document_Name__c = 'Floor Plan',
                    AppRegistration__c = ar.Id,
                    ContentDocumentId__c = cv.ContentDocumentId,
                    Content_Version_Id__c = cv.Id
                ),
                new Document__c(
                    SalesOrder__c = so.Id,
                    DocumentType__c = docTypeMap.get('Title Deed'),
                    Document_Name__c = 'Title Deed',
                    ContentDocumentId__c = cv.ContentDocumentId,
                    Content_Version_Id__c = cv.Id
                )
                };
                    insert lstDocument;
        for(Document__c objDoc : lstDocument){
            System.debug(objDoc);
        }
    }
    
    @IsTest
    static void test_getCustomerDetailsForRegistration() {
        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        Test.startTest();
        Map<String, Object> res =
            BAWebServiceHelper.getInstance()
            .getCustomerDetailsForRegistration('EID123', '9999999999', 'IN');
        Test.stopTest();
        
        System.assertNotEquals(null, res);
    }
    @IsTest
    static void test_getCustomerDetailsForRegistration2() {
        Account acc = [SELECT Id,Emirates_Id__pc,Nationality__pc, PersonContactId FROM Account WHERE RecordTypeId =: Utility.getRecordTypeIdByDevName(Account.SObjectType, 'PersonAccount') LIMIT 1];
        Test.startTest();
        Map<String, Object> res =
            BAWebServiceHelper.getInstance()
            .getCustomerDetailsForRegistration('EID-123', '', 'India');
        Test.stopTest();
    }
    
    
    @IsTest
    static void test_getExistingAppRegistration() {
        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        Test.startTest();
        List<AppRegistration__c> regs =
            BAWebServiceHelper.getInstance()
            .getExistingAppRegistration('EID123', '9999999999', 'IN');
        Test.stopTest();
        
    }
    
    @IsTest
    static void test_updateCustomer() {
        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        Test.startTest();
        Map<String, Object> res =
            BAWebServiceHelper.getInstance()
            .updateCustomer(acc.PersonContactId, 'Primary', '91', '8888888888', 'new@test.com');
        Test.stopTest();
        
        System.assertNotEquals(null, res);
    }
    
    @IsTest
    static void test_getMyProfile() {
        System.debug([
            SELECT Id, Emirates_Id__c, Account.RecordTypeId
            FROM Contact
        ]);
        Test.startTest();
        Map<String, Object> res =
            BAWebServiceHelper.getInstance()
            .getMyProfile('EID', 'EID-123');
        Test.stopTest();
    }
    
    @IsTest
    static void test_getSalesOrderInstallmentsAndOtherCharges() {
        SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        Test.startTest();
        Map<String, Object> res =
            BAWebServiceHelper.getInstance()
            .getSalesOrderInstallmentsAndOtherCharges(so.Id, acc.PersonContactId);
        Test.stopTest();
        
        System.assertNotEquals(null, res);
    }
    
    @IsTest
    static void test_downloadDocument_PASSPORT_and_SOA() {
        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        AppRegistration__c ar = [SELECT Id FROM AppRegistration__c WHERE DeviceId__c = 'DEVICE-1' LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
        InstallmentLines__c objIL = [SELECT Id FROM InstallmentLines__c LIMIT 1];
        
        Test.startTest();
        BAWebServiceHelper.getInstance()
            .downloadDocument('PASSPORT', ar.Id, acc.PersonContactId, false);
        
        BAWebServiceHelper.getInstance()
            .downloadDocument('SALES_SOA', so.Id, acc.PersonContactId, false);
        
        BAWebServiceHelper.getInstance()
            .downloadDocument('SALES_RECEIPT', so.Id, acc.PersonContactId, false);
        
        BAWebServiceHelper.getInstance()
            .downloadDocument('TITLE_DEED', ar.Id, acc.PersonContactId, false);
        
        BAWebServiceHelper.getInstance()
            .downloadDocument('SPA', ar.Id, acc.PersonContactId, false);
        
        BAWebServiceHelper.getInstance()
            .downloadDocument('EID_FRONT', ar.Id, acc.PersonContactId, false);
        
        BAWebServiceHelper.getInstance()
            .downloadDocument('EID_BACK', ar.Id, acc.PersonContactId, false);
        
        BAWebServiceHelper.getInstance()
            .downloadDocument('SALES_INVOICE', objIL.Id, acc.PersonContactId, false);
        
        BAWebServiceHelper.getInstance()
            .downloadDocument('SALES_PORFORMA_INVOICE', objIL.Id, acc.PersonContactId, false);
        
        BAWebServiceHelper.getInstance()
            .downloadDocument('FLOOR_PLAN', so.Id, acc.PersonContactId, false);
        
        Test.stopTest();
    }
    
    @IsTest
    static void test_uploadDocument() {
        Account acc = [SELECT Id,PersonContactId FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        
        Test.startTest();
        Map<String,Object> res =
            BAWebServiceHelper.getInstance()
            .uploadDocument('PASSPORT', acc.Id, acc.PersonContactId);
        Test.stopTest();
        
        System.assert(res.containsKey('doc_id'));
    }
    
    @IsTest
    static void test_send_and_verify_otp() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Account acc = [SELECT Id,PersonContactId FROM Account LIMIT 1];
        Test.startTest();
        Map<String,Object> otpRes =
            BAWebServiceHelper.getInstance()
            .sendOTP('LOGIN', 'test@test.com', '9999999999', 'EMAIL', acc.PersonContactId);
        
        String txnId = (String) otpRes.get('transactionId');
        
        Map<String,Object> verifyRes =
            BAWebServiceHelper.getInstance()
            .verifyOTP(con.Id, '123456', txnId);
        Test.stopTest();
        
        System.assert(verifyRes.containsKey('isValid'));
    }
    
    @IsTest
    static void test_getListValues() {
        ServiceCatalog__c sc = new ServiceCatalog__c(
            Name = 'Test SR',
            Type__c = 'Service Request',
            SuperAppName__c = 'Payment Issue',
            AvailableForOwner__c = true
        );
        insert sc;
        
        Test.startTest();
        Map<String,Object> res =
            BAWebServiceHelper.getInstance()
            .getListValues('SERVICE_REQUEST_LIST');
        Test.stopTest();
        
        System.assert(res.containsKey('serviceRequestTypes'));
    }
    
    
    @IsTest
    static void test_getSRs() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Account acc = [SELECT Id,PersonContactId FROM Account LIMIT 1];
        List<Case> caseList = new List<Case>();
        for(Integer i = 0; i<10; i++){
            Case caseBFMObj = TestDataFactory.createBFMCase('Email', 'New', 'Test description', 'Test Subject',null,'test@gmail.com','0123456789');
            caseBFMObj.ContactId = acc.PersonContactId;
            caseBFMObj.SuppliedEmail = 'test123@gmail.com';
            caseList.add(caseBFMObj);
        }
        insert caseList;
        Test.startTest();
        Map<String,Object> res =
            BAWebServiceHelper.getInstance()
            .getSRs(con.Id);
        Test.stopTest();
        
        System.assert(res.containsKey('serviceRequests'));
    }
    
    @IsTest
    static void test_doCreateSR_and_followup() {
        Account acc = [SELECT Id,PersonContactId FROM Account LIMIT 1];
        SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
        ServiceCatalog__c sc =
            [SELECT Id FROM ServiceCatalog__c LIMIT 1];
        
        Test.startTest();
        Map<String,Object> srRes =
            BAWebServiceHelper.getInstance()
            .doCreateSR(
                sc.Id,
                acc.PersonContactId,
                so.Id,
                'test@test.com',
                '91',
                '9999999999',
                'Test Subject',
                'Test Description'
            );
        
        Id srId = (Id) srRes.get('srid');
        
        BAWebServiceHelper.getInstance()
            .doPostSRFollowUp(acc.PersonContactId, srId, 'Test Followup');
        Test.stopTest();
        
        System.assertNotEquals(null, srId);
    }
    
    @isTest
    static void test_App_Reg() {
        AppRegistration__c objApp = [SELECT ID FROM AppRegistration__c LIMIT 1];
        Test.startTest();
        Map<String, Object> result = BAWebServiceHelper.getInstance().getAppRegistrationStatus(objApp.Id);
        Test.stopTest();
    }
}