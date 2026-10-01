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
        
        acc = [SELECT Id, PersonContactId FROM Account WHERE Id = :acc.Id];
        
        Project__c project = new Project__c(Name = 'Test Project', EnableLatePaymentFee__c = true);
        insert project;
        
        Building__c building = TestDataFactory.createBuilding('Building 1', project.Id);
        insert building;
        
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
            SalesOrder__c = so.Id, InstallmentNumber__c = 1,
            InstallmentAmount__c = 10000, AmountReceived__c = 5000,
            ClearedAmount__c = 5000, InstallmentPercentage__c = 50,
            Type__c = 'Installment', InstallmentDate__c = Date.today(),
            Description__c = 'Installment 1'
        );
        InstallmentLines__c il2 = new InstallmentLines__c(
            SalesOrder__c = so.Id, InstallmentNumber__c = 2,
            InstallmentAmount__c = 10000, AmountReceived__c = 2000,
            ClearedAmount__c = 2000, InstallmentPercentage__c = 50,
            Type__c = 'Post Handover Installment', InstallmentDate__c = Date.today(),
            Description__c = 'Installment 2'
        );
        insert new List<InstallmentLines__c>{ il1, il2 };
        
        SalesOrderOtherCharges__c oc = new SalesOrderOtherCharges__c(
            SalesOrder__c = so.Id, TypeOfCharge__c = 'Service Charge',
            Amount__c = 2000, InvoicedAmount__c = 1000,
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
        scBFM.AvailableForOwner__c = true; scBFM.AvailableForTenant__c = true;
        ServiceCatalog__c scPost = TestDataFactory.createServiceCatalog('BFM', 'Sales', 'Service Request', 'Financial - Payment Service', POST_SALE_PAYMENT_DEFERRAL, 'Account;Sales Order;Unit', 'Post_Sale_Payment_Deferral');
        scPost.AvailableForOwner__c = true;
        scList.add(scBFM); scList.add(scPost);
        ServiceCatalog__c testServiceCatalog = new ServiceCatalog__c(
            Name = 'Test Service Catalog', Type__c = 'Service Request',
            Category__c = 'Customer Service Request', SubCategory__c = 'KYC Update Request',
            RecordTypeDevName__c = 'ThirdPartyForm', AvailableForOwner__c = true,
            IsAvailableForSuperApp__c = true
        );
        scList.add(testServiceCatalog);
        ServiceCatalog__c testServiceCatalog1 = new ServiceCatalog__c(
            Name = 'Test Service Catalog', Type__c = 'Service Request',
            Category__c = 'Financial - Payment Service', SubCategory__c = 'Payment',
            RecordTypeDevName__c = 'Payment_Sr', AvailableForOwner__c = true,
            IsAvailableForSuperApp__c = true
        );
        scList.add(testServiceCatalog1);
        ServiceCatalog__c testServiceCatalog2 = new ServiceCatalog__c(
            Name = 'Test Service Catalog', Type__c = 'Service Request',
            Category__c = 'General Enquiry', SubCategory__c = 'General Enquiry',
            RecordTypeDevName__c = 'GeneralEnquiry', AvailableForOwner__c = true,
            IsAvailableForSuperApp__c = true
        );
        scList.add(testServiceCatalog2);
        ServiceCatalog__c testServiceCatalog3 = new ServiceCatalog__c(
            Name = 'Test Service Catalog', Type__c = 'Service Request',
            Category__c = 'Financial - Payment Service', SubCategory__c = 'Payment Due Date Update',
            RecordTypeDevName__c = 'Payment_Due_Date_Update', AvailableForOwner__c = true
        );
        scList.add(testServiceCatalog3);
        insert scList;
        
        List<OnlinePaymentLog__c> lstPaymentLog = new List<OnlinePaymentLog__c>();
        OnlinePaymentLogService service = OnlinePaymentLogService.getInstance();
        OnlinePaymentLog__c objPaymentLog = new OnlinePaymentLog__c(
            Contact__c = acc.PersonContactId,
            JSONData__c = '{"transactionId":"TX123","amount":100}',
            IsProcessed__c = true, TransactionStatus__c = 'Success'
        );
        insert objPaymentLog;
        OnlinePaymentLog__c objPaymentLog1 = new OnlinePaymentLog__c(
            Contact__c = acc.PersonContactId,
            JSONData__c = '{"transactionId":"TX123","amount":100}',
            IsProcessed__c = true, TransactionStatus__c = 'Failed'
        );
        insert objPaymentLog1;
        lstPaymentLog.add(objPaymentLog1);
        service.updateOnlinePaymentLog(lstPaymentLog);
        
        AppRegistration__c ar = new AppRegistration__c(
            Contact__c = acc.PersonContactId, Status__c = 'Under Review',
            Email__c = 'test@test.com', MobileCountryCode__c = '91',
            MobilePhone__c = '9999999999', DeviceId__c = 'DEVICE-1'
        );
        insert ar;
        AppRegistration__c arApproved = new AppRegistration__c(
            Contact__c = acc.PersonContactId, Status__c = 'Approved',
            Email__c = 'approved@test.com', MobileCountryCode__c = '91',
            MobilePhone__c = '9999999999', DeviceId__c = 'DEVICE-2'
        );
        insert arApproved;
        
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
            Title = 'Passport', PathOnClient = 'Passport.pdf',
            VersionData = Blob.valueOf('Test content')
        );
        insert cv;
        cv = [SELECT Id, ContentDocumentId, FileType FROM ContentVersion WHERE Id = :cv.Id];
        
        Map<String, Id> docTypeMap = new Map<String, Id>();
        for (DocumentType__c dt : lstDocType) { docTypeMap.put(dt.Type__c, dt.Id); }
        
        List<Document__c> lstDocument = new List<Document__c>{
            new Document__c(Account__c = acc.Id, DocumentType__c = docTypeMap.get('Passport'),
                Document_Name__c = 'Passport Doc', AppRegistration__c = ar.Id,
                ContentDocumentId__c = cv.ContentDocumentId, Content_Version_Id__c = cv.Id),
            new Document__c(Account__c = acc.Id, DocumentType__c = docTypeMap.get('Emirates ID Front'),
                Document_Name__c = 'EID Front', AppRegistration__c = ar.Id,
                ContentDocumentId__c = cv.ContentDocumentId, Content_Version_Id__c = cv.Id),
            new Document__c(Account__c = acc.Id, DocumentType__c = docTypeMap.get('Emirates ID Back'),
                Document_Name__c = 'EID Back', AppRegistration__c = ar.Id,
                ContentDocumentId__c = cv.ContentDocumentId, Content_Version_Id__c = cv.Id),
            new Document__c(Account__c = acc.Id, DocumentType__c = docTypeMap.get('Title Deed'),
                Document_Name__c = 'TITLE_DEED', AppRegistration__c = ar.Id,
                ContentDocumentId__c = cv.ContentDocumentId, Content_Version_Id__c = cv.Id),
            new Document__c(Account__c = acc.Id, DocumentType__c = docTypeMap.get('SPA - Signed'),
                Document_Name__c = 'SPA_SIGNED', AppRegistration__c = ar.Id,
                ContentDocumentId__c = cv.ContentDocumentId, Content_Version_Id__c = cv.Id),
            new Document__c(Account__c = acc.Id, DocumentType__c = docTypeMap.get('Floor Plan'),
                Document_Name__c = 'Floor Plan', AppRegistration__c = ar.Id,
                ContentDocumentId__c = cv.ContentDocumentId, Content_Version_Id__c = cv.Id)
        };
        insert lstDocument;
        
        AppointmentSlot__c slot = new AppointmentSlot__c(
            StartDateTime__c = System.now().addHours(2),
            EndDateTime__c   = System.now().addHours(3)
        );
        insert slot;
    }
    
    // getInstance
    @IsTest
    static void test_getInstance_singleton() {
        Test.startTest();
        BAWebServiceHelper h1 = BAWebServiceHelper.getInstance();
        BAWebServiceHelper h2 = BAWebServiceHelper.getInstance();
        Test.stopTest();
        System.assertEquals(h1, h2, 'getInstance should always return the same instance');
    }
    
    // getCustomerDetailsForRegistration
    @IsTest
    static void test_getCustomerDetailsForRegistration() {
        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        Test.startTest();
        Map<String, Object> res = BAWebServiceHelper.getInstance()
            .getCustomerDetailsForRegistration('EID123', '9999999999', 'IN');
        Test.stopTest();
        System.assertNotEquals(null, res);
    }

    @IsTest
    static void test_getCustomerDetailsForRegistration2() {
        Account acc = [SELECT Id,Emirates_Id__pc,Nationality__pc, PersonContactId FROM Account WHERE RecordTypeId =: Utility.getRecordTypeIdByDevName(Account.SObjectType, 'PersonAccount') LIMIT 1];
        Test.startTest();
        Map<String, Object> res = BAWebServiceHelper.getInstance()
            .getCustomerDetailsForRegistration('EID-123', '', 'India');
        Test.stopTest();
    }

    @IsTest
    static void test_getCustomerDetailsForRegistration_noAccount() {
        Test.startTest();
        Map<String, Object> res = BAWebServiceHelper.getInstance()
            .getCustomerDetailsForRegistration('NOMATCH', '', 'India');
        Test.stopTest();
        System.assert(res.isEmpty(), 'Expected empty map when no account found');
    }

    @IsTest
    static void test_getCustomerDetailsForRegistration_noSalesOrder() {
        Id paRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Account acc2 = new Account(RecordTypeId = paRtId, FirstName = 'Jane', LastName = 'Smith',
            PersonEmail = 'jane@test.com', Emirates_Id__pc = 'EID999', Nationality__pc = 'United Arab Emirates');
        insert acc2;
        Test.startTest();
        Map<String, Object> res = BAWebServiceHelper.getInstance()
            .getCustomerDetailsForRegistration('EID999', '', 'United Arab Emirates');
        Test.stopTest();
        System.assert(res.isEmpty(), 'Expected empty map when no sales order found');
    }

    // isOtpVerified
    @IsTest
    static void test_isOtpVerified_emptyTxnIds_returnsFalse() {
        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        Test.startTest();
        Boolean result = BAWebServiceHelper.getInstance()
            .isOtpVerified(acc.PersonContactId, '', '', 'test@test.com', '9999999999');
        Test.stopTest();
        System.assertEquals(false, result, 'Both OTP txn IDs blank should return false');
    }

    @IsTest
    static void test_isOtpVerified_withEmailTxnId_notVerified() {
        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        Test.startTest();
        Boolean result = BAWebServiceHelper.getInstance()
            .isOtpVerified(acc.PersonContactId, 'FAKE-TXN-ID', '', 'test@test.com', '9999999999');
        Test.stopTest();
        System.assertEquals(false, result, 'Unverified email OTP txn should return false');
    }

    @IsTest
    static void test_isOtpVerified_withSmsTxnId_notVerified() {
        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        Test.startTest();
        Boolean result = BAWebServiceHelper.getInstance()
            .isOtpVerified(acc.PersonContactId, '', 'FAKE-SMS-TXN', 'test@test.com', '9999999999');
        Test.stopTest();
        System.assertEquals(false, result, 'Unverified SMS OTP txn should return false');
    }

    // isValidCustomer
    @IsTest
    static void test_isValidCustomer_validCustomer() {
        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        Test.startTest();
        Boolean result = BAWebServiceHelper.getInstance().isValidCustomer(acc.PersonContactId);
        Test.stopTest();
        System.assertEquals(true, result, 'Customer with active SalesOrder should be valid');
    }

    @IsTest
    static void test_isValidCustomer_nullCustomerId() {
        Test.startTest();
        Boolean result = BAWebServiceHelper.getInstance().isValidCustomer(null);
        Test.stopTest();
        System.assertEquals(false, result, 'Null customerId -> invalid');
    }

    @IsTest
    static void test_isValidCustomer_noSalesOrder() {
        Id paRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Account acc2 = new Account(RecordTypeId = paRtId, FirstName = 'No', LastName = 'Order',
            PersonEmail = 'noorder@test.com', Emirates_Id__pc = 'EID888');
        insert acc2;
        acc2 = [SELECT Id, PersonContactId FROM Account WHERE Id = :acc2.Id];
        Test.startTest();
        Boolean result = BAWebServiceHelper.getInstance().isValidCustomer(acc2.PersonContactId);
        Test.stopTest();
        System.assertEquals(false, result, 'Customer with no SalesOrder -> invalid');
    }

    // createAppRegistrationRequest
    @IsTest
    static void test_createAppRegistrationRequest_blankCustomerId() {
        Test.startTest();
        Map<String, Object> res = BAWebServiceHelper.getInstance()
            .createAppRegistrationRequest('', 'John', '', 'Doe', 'EID123', '', 'India',
                '91', '9999999999', 'test@test.com', 'DEVICE-X', 'New', 'Passport', '', '');
        Test.stopTest();
        System.assert(res.isEmpty(), 'Blank customerId should return empty map');
    }

    @IsTest
    static void test_createAppRegistrationRequest_otpNotVerified() {
        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        Test.startTest();
        Map<String, Object> res = BAWebServiceHelper.getInstance()
            .createAppRegistrationRequest(acc.PersonContactId, 'John', '', 'Doe', 'EID123', '', 'India',
                '91', '9999999999', 'test@test.com', 'DEVICE-X', 'New', 'Passport', '', '');
        Test.stopTest();
        System.assert(res.isEmpty(), 'No valid OTP should return empty map');
    }

    // getExistingAppRegistration
    @IsTest
    static void test_getExistingAppRegistration() {
        Test.startTest();
        List<AppRegistration__c> regs = BAWebServiceHelper.getInstance()
            .getExistingAppRegistration('EID123', '9999999999', 'IN');
        Test.stopTest();
    }

    // getAppRegistrationStatus
    @isTest
    static void test_App_Reg() {
        AppRegistration__c objApp = [SELECT ID FROM AppRegistration__c LIMIT 1];
        Test.startTest();
        Map<String, Object> result = BAWebServiceHelper.getInstance().getAppRegistrationStatus(objApp.Id);
        Test.stopTest();
    }

    @IsTest
    static void test_getAppRegistrationStatus_notFound() {
        AppRegistration__c ar = [SELECT Id FROM AppRegistration__c LIMIT 1];
        delete ar;
        Test.startTest();
        Map<String, Object> result = BAWebServiceHelper.getInstance().getAppRegistrationStatus(ar.Id);
        Test.stopTest();
        System.assert(result.isEmpty(), 'Deleted record -> empty map expected');
    }

    // updateCustomer
    @IsTest
    static void test_updateCustomer() {
        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        Test.startTest();
        Map<String, Object> res = BAWebServiceHelper.getInstance()
            .updateCustomer(acc.PersonContactId, 'Primary', '91', '8888888888', 'new@test.com');
        Test.stopTest();
        System.assertNotEquals(null, res);
    }

    @IsTest
    static void test_updateCustomer_Primary_blankMobileAndEmail() {
        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        Test.startTest();
        Map<String, Object> res = BAWebServiceHelper.getInstance()
            .updateCustomer(acc.PersonContactId, 'Primary', '', '', '');
        Test.stopTest();
        System.assertNotEquals(null, res);
    }

    @IsTest
    static void test_updateCustomer_Secondary() {
        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        Test.startTest();
        Map<String, Object> res = BAWebServiceHelper.getInstance()
            .updateCustomer(acc.PersonContactId, 'Secondary', '44', '7777777777', 'secondary@test.com');
        Test.stopTest();
        System.assertNotEquals(null, res);
        System.assertEquals(acc.PersonContactId, res.get('customer_id'));
    }

    // getMyProfile
    @IsTest
    static void test_getMyProfile() {
        Test.startTest();
        Map<String, Object> res = BAWebServiceHelper.getInstance().getMyProfile('EID', 'EID-123');
        Test.stopTest();
    }

    @IsTest
    static void test_getMyProfile_EID_match() {
        Test.startTest();
        Map<String, Object> res = BAWebServiceHelper.getInstance().getMyProfile('EID', 'EID123');
        Test.stopTest();
        System.assertNotEquals(null, res);
    }

    @IsTest
    static void test_getMyProfile_EID_noContact() {
        Test.startTest();
        Map<String, Object> res = BAWebServiceHelper.getInstance().getMyProfile('EID', 'UNKNOWN_EID');
        Test.stopTest();
        System.assertNotEquals(null, res);
    }

    @IsTest
    static void test_getMyProfile_AB2CID() {
        Test.startTest();
        Map<String, Object> res = BAWebServiceHelper.getInstance().getMyProfile('AB2CID', 'SOME_AD_ID');
        Test.stopTest();
        System.assertNotEquals(null, res);
    }

    @IsTest
    static void test_getMyProfile_UAEPASS_fallbackToContact() {
        Test.startTest();
        Lead lead = new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            Emirates_ID__c = '784-1990-3260514-1',
            UUID__c = 'OLD_UUID', IsConverted = false, LeadSource = 'Government Entity', leadsubsource__c = 'ADHA', Status = 'New', ApplicationNumber__c = '222'
        );
        insert lead;
        Map<String, Object> res = BAWebServiceHelper.getInstance().getMyProfile('UAEPASS', '784-1990-3260514-1');
        Test.stopTest();
        System.assertNotEquals(null, res);
    }

    @IsTest
    static void test_getMyProfile_UAEPASS_noMatch() {
        Test.startTest();
        Map<String, Object> res = BAWebServiceHelper.getInstance().getMyProfile('UAEPASS', 'NO_EID');
        Test.stopTest();
        System.assertNotEquals(null, res);
    }

    // getSalesOrderInstallmentsAndOtherCharges
    @IsTest
    static void test_getSalesOrderInstallmentsAndOtherCharges() {
        SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        Test.startTest();
        Map<String, Object> res = BAWebServiceHelper.getInstance()
            .getSalesOrderInstallmentsAndOtherCharges(so.Id, acc.PersonContactId);
        Test.stopTest();
        System.assertNotEquals(null, res);
    }

    @IsTest
    static void test_getSalesOrderInstallmentsAndOtherCharges_contactNotFound() {
        SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
        Test.startTest();
        Map<String, Object> res = BAWebServiceHelper.getInstance()
            .getSalesOrderInstallmentsAndOtherCharges(so.Id, null);
        Test.stopTest();
        System.assert(res.isEmpty(), 'Null customerId -> empty map expected');
    }

    @IsTest
    static void test_getSalesOrderInstallmentsAndOtherCharges_salesOrderMismatch() {
        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        Id paRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Account acc2 = new Account(RecordTypeId = paRtId, FirstName = 'Other', LastName = 'User',
            PersonEmail = 'other@test.com');
        insert acc2;
        Unit__c unit2 = new Unit__c(Name = 'Unit 2');
        insert unit2;
        Opportunity opp2 = new Opportunity(Name = 'Opp2', StageName = 'Prospecting',
            CloseDate = Date.today(), AccountId = acc2.Id, WinReason__c = 'New Project Launch');
        insert opp2;
        SalesOrder__c so2 = new SalesOrder__c(Name = 'SO-002', Status__c = 'Sold',
            Account__c = acc2.Id, Unit__c = unit2.Id, Opportunity__c = opp2.Id, SoldDate__c = Date.today());
        insert so2;
        Test.startTest();
        Map<String, Object> res = BAWebServiceHelper.getInstance()
            .getSalesOrderInstallmentsAndOtherCharges(so2.Id, acc.PersonContactId);
        Test.stopTest();
        System.assert(res.isEmpty(), 'Mismatched SO account -> empty map expected');
    }

    // downloadDocument
    @IsTest
    static void test_downloadDocument_PASSPORT_and_SOA() {
        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        AppRegistration__c ar = [SELECT Id FROM AppRegistration__c WHERE DeviceId__c = 'DEVICE-1' LIMIT 1];
        SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
        InstallmentLines__c objIL = [SELECT Id FROM InstallmentLines__c LIMIT 1];
        Test.startTest();
        BAWebServiceHelper.getInstance().downloadDocument('PASSPORT', ar.Id, acc.PersonContactId, false);
        BAWebServiceHelper.getInstance().downloadDocument('SALES_SOA', so.Id, acc.PersonContactId, false);
        BAWebServiceHelper.getInstance().downloadDocument('SALES_RECEIPT', so.Id, acc.PersonContactId, false);
        BAWebServiceHelper.getInstance().downloadDocument('TITLE_DEED', ar.Id, acc.PersonContactId, false);
        BAWebServiceHelper.getInstance().downloadDocument('SPA', ar.Id, acc.PersonContactId, false);
        BAWebServiceHelper.getInstance().downloadDocument('EID_FRONT', ar.Id, acc.PersonContactId, false);
        BAWebServiceHelper.getInstance().downloadDocument('EID_BACK', ar.Id, acc.PersonContactId, false);
        BAWebServiceHelper.getInstance().downloadDocument('SALES_INVOICE', objIL.Id, acc.PersonContactId, false);
        BAWebServiceHelper.getInstance().downloadDocument('SALES_PORFORMA_INVOICE', objIL.Id, acc.PersonContactId, false);
        BAWebServiceHelper.getInstance().downloadDocument('FLOOR_PLAN', so.Id, acc.PersonContactId, false);
        BAWebServiceHelper.getInstance().downloadDocument('COMMUNITY_SOA', so.Id, acc.PersonContactId, false);
        BAWebServiceHelper.getInstance().downloadDocument('COMMUNITY_RECEIPT', so.Id, acc.PersonContactId, false);
        Test.stopTest();
    }

    // uploadDocument
    @IsTest
    static void test_uploadDocument() {
        Account acc = [SELECT Id,PersonContactId FROM Account LIMIT 1];
        Test.startTest();
        Map<String,Object> res = BAWebServiceHelper.getInstance().uploadDocument('PASSPORT', acc.Id, acc.PersonContactId);
        Test.stopTest();
        System.assert(res.containsKey('doc_id'));
    }

    @IsTest
    static void test_uploadDocument_EID_FRONT() {
        Account acc = [SELECT Id,PersonContactId FROM Account LIMIT 1];
        Test.startTest();
        Map<String,Object> res = BAWebServiceHelper.getInstance().uploadDocument('EID_FRONT', acc.Id, acc.PersonContactId);
        Test.stopTest();
        System.assert(res.containsKey('doc_id'));
    }

    @IsTest
    static void test_uploadDocument_EID_BACK() {
        Account acc = [SELECT Id,PersonContactId FROM Account LIMIT 1];
        Test.startTest();
        Map<String,Object> res = BAWebServiceHelper.getInstance().uploadDocument('EID_BACK', acc.Id, acc.PersonContactId);
        Test.stopTest();
        System.assert(res.containsKey('doc_id'));
    }

    @IsTest
    static void test_uploadDocument_unknownType() {
        Account acc = [SELECT Id,PersonContactId FROM Account LIMIT 1];
        Test.startTest();
        Map<String,Object> res = BAWebServiceHelper.getInstance().uploadDocument('UNKNOWN_TYPE', acc.Id, acc.PersonContactId);
        Test.stopTest();
        System.assert(res.containsKey('doc_id'));
        System.assertEquals(null, res.get('doc_id'), 'Unknown type -> doc_id should be null');
    }

    // sendOTP + verifyOTP
    @IsTest
    static void test_send_and_verify_otp() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Account acc = [SELECT Id,PersonContactId FROM Account LIMIT 1];
        Test.startTest();
        Map<String,Object> otpRes = BAWebServiceHelper.getInstance()
            .sendOTP('LOGIN', 'test@test.com', '9999999999', 'EMAIL', acc.PersonContactId);
        String txnId = (String) otpRes.get('transactionId');
        Map<String,Object> verifyRes = BAWebServiceHelper.getInstance().verifyOTP(con.Id, '123456', txnId);
        Test.stopTest();
        System.assert(verifyRes.containsKey('isValid'));
    }

    // getListValues
    @IsTest
    static void test_getListValues() {
        ServiceCatalog__c sc = new ServiceCatalog__c(
            Name = 'Test SR', Type__c = 'Service Request',
            SuperAppName__c = 'Payment Issue', AvailableForOwner__c = true
        );
        insert sc;
        Test.startTest();
        Map<String,Object> res = BAWebServiceHelper.getInstance().getListValues('SERVICE_REQUEST_LIST');
        Test.stopTest();
        System.assert(res.containsKey('serviceRequestTypes'));
    }

    @IsTest
    static void test_getListValues_unknownType() {
        Test.startTest();
        Map<String,Object> res = BAWebServiceHelper.getInstance().getListValues('UNKNOWN_LIST');
        Test.stopTest();
        System.assert(res.isEmpty(), 'Unknown list type -> empty map expected');
    }

    // getSRs
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
        Map<String,Object> res = BAWebServiceHelper.getInstance().getSRs(con.Id);
        Test.stopTest();
        System.assert(res.containsKey('serviceRequests'));
    }

    // doCreateSR + doPostSRFollowUp
    @IsTest
    static void test_doCreateSR_and_followup() {
        Account acc = [SELECT Id,PersonContactId FROM Account LIMIT 1];
        SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
        ServiceCatalog__c sc = [SELECT Id FROM ServiceCatalog__c LIMIT 1];
        Test.startTest();
        Map<String,Object> srRes = BAWebServiceHelper.getInstance()
            .doCreateSR(sc.Id, acc.PersonContactId, so.Id, 'test@test.com', '91', '9999999999', 'Test Subject', 'Test Description');
        Id srId = (Id) srRes.get('srid');
        BAWebServiceHelper.getInstance().doPostSRFollowUp(acc.PersonContactId, srId, 'Test Followup');
        Test.stopTest();
        System.assertNotEquals(null, srId);
    }

    @IsTest
    static void test_doCreateSR_emailPath() {
        ServiceCatalog__c sc = [SELECT Id FROM ServiceCatalog__c LIMIT 1];
        Test.startTest();
        Map<String,Object> srRes = BAWebServiceHelper.getInstance()
            .doCreateSR(sc.Id, null, null, 'test@gmail.com', '91', '9999999999', 'Email SR Subject', 'Email SR Description');
        Test.stopTest();
        System.assertNotEquals(null, srRes);
    }

    @IsTest
    static void test_doCreateSR_withUnitParentId() {
        Account acc = [SELECT Id,PersonContactId FROM Account LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        ServiceCatalog__c sc = [SELECT Id FROM ServiceCatalog__c LIMIT 1];
        Test.startTest();
        Map<String,Object> srRes = BAWebServiceHelper.getInstance()
            .doCreateSR(sc.Id, acc.PersonContactId, unit.Id, 'test@test.com', '91', '9999999999', 'Unit SR Subject', 'Unit SR Description');
        Test.stopTest();
        System.assertNotEquals(null, srRes.get('srid'));
    }

    // getAuthorizedUAEPassLoginUser
    @IsTest
    static void test_getAuthorizedUAEPassLoginUser_noLeadNoContact() {
        Test.startTest();
        Map<String, Object> res = BAWebServiceHelper.getInstance()
            .getAuthorizedUAEPassLoginUser('UNKNOWN_EID', 'uuid-123', '9999', 'test@test.com');
        Test.stopTest();
        System.assertEquals(false, res.get('isValid'), 'Unknown EID -> isValid should be false');
    }

    @IsTest
    static void test_getAuthorizedUAEPassLoginUser_contactFound() {
        Test.startTest();
        Map<String, Object> res = BAWebServiceHelper.getInstance()
            .getAuthorizedUAEPassLoginUser('EID123', 'uuid-456', '9999', 'test@test.com');
        Test.stopTest();
    }

    // manageAppointment
    @IsTest
    static void test_manageAppointment_Scheduled() {
        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        AppointmentSlot__c slot = [SELECT Id FROM AppointmentSlot__c LIMIT 1];
        Test.startTest();
        Map<String, Object> res = BAWebServiceHelper.getInstance()
            .manageAppointment(acc.PersonContactId, slot.Id, 'Scheduled', null, null,null);
        Test.stopTest();
        System.assert(res.containsKey('event_id'), 'Scheduled -> event_id expected');
    }

    @IsTest
    static void test_manageAppointment_Cancelled() {
        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        AppointmentSlot__c slot = [SELECT Id FROM AppointmentSlot__c LIMIT 1];
        Map<String, Object> scheduledRes = BAWebServiceHelper.getInstance()
            .manageAppointment(acc.PersonContactId, slot.Id, 'Scheduled', null, null,null);
        Id eventId = (Id) scheduledRes.get('event_id');
        Test.startTest();
        Map<String, Object> res = BAWebServiceHelper.getInstance()
            .manageAppointment(acc.PersonContactId, null, 'Cancelled', 'No longer needed', eventId,null);
        Test.stopTest();
        System.assert(res.containsKey('event_id'));
    }

    @IsTest
    static void test_manageAppointment_Rescheduled() {
        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        AppointmentSlot__c slot = [SELECT Id FROM AppointmentSlot__c LIMIT 1];
        AppointmentSlot__c newSlot = new AppointmentSlot__c(
            StartDateTime__c = System.now().addHours(5), EndDateTime__c = System.now().addHours(6));
        insert newSlot;
        Map<String, Object> scheduledRes = BAWebServiceHelper.getInstance()
            .manageAppointment(acc.PersonContactId, slot.Id, 'Scheduled', null, null,null);
        Id oldEventId = (Id) scheduledRes.get('event_id');
        Test.startTest();
        Map<String, Object> res = BAWebServiceHelper.getInstance()
            .manageAppointment(acc.PersonContactId, newSlot.Id, 'Rescheduled', 'Changed time', oldEventId,null);
        Test.stopTest();
        System.assert(res.containsKey('event_id'));
        System.assertNotEquals(oldEventId, res.get('event_id'), 'Rescheduled -> new event expected');
    }

    @IsTest
    static void test_manageAppointment_unknownAction() {
        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        Test.startTest();
        Map<String, Object> res = BAWebServiceHelper.getInstance()
            .manageAppointment(acc.PersonContactId, null, 'UNKNOWN_ACTION', null, null,null);
        Test.stopTest();
        System.assert(res.isEmpty(), 'Unknown action -> empty map expected');
    }

    
    
    @IsTest
    static void testGetAuthorizedUAEPassLoginUser_LeadFound() {
        Lead lead = new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            Emirates_ID__c = '784-1990-3260514-1',
            UUID__c = 'OLD_UUID', IsConverted = false, LeadSource = 'Government Entity', leadsubsource__c = 'ADHA', Status = 'New', ApplicationNumber__c = '222'
        );
        insert lead;
    
        BAWebServiceHelper controller = BAWebServiceHelper.getInstance();
    
        Test.startTest();
        Map<String, Object> result = controller.getAuthorizedUAEPassLoginUser(
            '784-1990-3260514-1',
            'NEW_UUID',
            '971500000000',
            'test@test.com'
        );
        Test.stopTest();
    
        System.assertEquals(true, result.get('isValid'));
        System.assertEquals('NEW_UUID', result.get('uuid'));
        System.assertEquals(lead.Id, result.get('customer_id'));
    
        Lead updatedLead = [SELECT Id, UUID__c FROM Lead WHERE Id = :lead.Id];
        System.assertEquals('NEW_UUID', updatedLead.UUID__c);
    }
}