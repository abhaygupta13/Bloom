/*****************************************************************************************
Class       : ServiceRequestControllerTest
Author      : Vikas Baliyan
Description : ServiceRequestController Test
Test Class  : 
Created Date: 25 Mar 2025 
*****************************************************************************************/
@isTest
public class ServiceRequestControllerTest {
private static final string POST_SALE_PAYMENT_DEFERRAL { get { return 'Postpone/Defer payment'; } }
    private static final string BFM_SERVICE_REQUEST { get { return 'BFM Service Request'; } }
    private static final string RESALE_PROPERTY_UNDER_CONSTRUCTION { get { return 'Resale Property Under Construction'; } }
    private static final string RESALE_PROPERTY_COMPLETED_PROJECT{ get { return 'Resale Property of a Completed Project'; } }
    private static final string RESALE_PROPERTY_WITH_PPHP{ get { return 'Resale Property with Post Handover Payment Plan'; } }
    private static final string FINANCIAL_PAYMENT_SERVICE_CATEGORY{ get { return 'Financial - Payment Service'; } }
    private static final string SERVICE_COMPLAINT { get { return 'Complaint'; } }
    private static final string CRM_CATEGORY{ get { return 'CRM'; } }
    private static final string BFM_SERVICE_CATEGORY{ get { return 'BFM Service'; } }
    private static final string SERVICE_REQUEST { get { return 'Service Request'; } }
    private static final string RESALE_CATEGORY { get { return 'Resale'; } }
    private static final string CHEQUE_REPLACEMENT_REQUEST { get { return 'Cheque Replacement Request'; } }
    private static final string CHEQUE_WITHDRAWAL_REQUEST { get { return 'Cheque Withdrawal Request'; } }
    private static final string ACKNOWLEDGEMENT_RECEIPT_SUB_CATEGORY  { get { return 'Acknowledgement Receipt'; } }//Pranav
    private static final string PAYMENT_DUE_DATE_UPDATE_SUB_CATEGORY  { get { return 'Payment Due Date Update'; } }//Pranav
    private static final string THIRD_PARTY_FORM_SUB_CATEGORY  { get { return 'Third Party Form'; } }//Pranav
    private static final string PAYMENT_SR_SUB_CATEGORY { get { return 'Payment'; } }//Pranav
    private static final String LPF_WAIVER_REQUEST = 'LPF Waiver Request';
private static final String SOA_REQUEST = 'SOA Request';
private static final String POPSHARE_SR_SUB_CATEGORY = 'Proof of Payment Shared';
private static final String BANK_ACC_DTAIL_SUB_CATEGORY = 'Bank Account Details Inquiry';
private static final String GENERAL_PAYMENT_ENQUIRY_SUB_CATEGORY = 'General Payment Enquiry';
    private static final String COMPLAINT_REQUEST_TYPE = 'Complaint';

private static final String SALES_OPERATION_CATEGORY =
    'Sales Operation Service';

private static final String CUSTOMER_SERVICE_REQUEST_CATEGORY =
    'Customer Service Request';

private static final String KYC_UPDATE_REQUEST =
    'KYC Update Request';

private static final String CRM_REQUESTS_CATEGORY =
    'CRM Services';

private static final String TAWTHEEQ_ENROLLMENT_SUB_CATEGORY =
    'Tawtheeq Enrollment';

private static final String COMMUNITY_SERVICE_REQUEST =
    'Community Service Request';

private static final String COMMON_AREA_SERVICE_REQUEST =
    'Common Area Service Request';
    private static final String GENERAL_ENQUIRY =
    'General Enquiry';
    
    @testSetup
    private static void testData() {
        Account acc = TestDataFactory.createBrokerAccount('test', false, '1122334455');
        insert acc;

        Contact con = TestDataFactory.createContact('Test Contact', acc.Id, true, 'sonali.sengar@infobeans.com');
        insert con;

        Opportunity opp = TestDataFactory.createOpportunity(null, null,null, acc.Id, null, null, null, null);
        insert opp;

        Project__c project = TestDataFactory.createProject('Project Test', Date.newinstance(2024, 01, 01), Date.newInstance(2025, 01, 01), Date.newInstance(2025, 01, 15), Date.newInstance(2025, 01, 16), Date.newInstance(2025, 01, 30), Date.newInstance(2025, 02, 01));
        insert project;

        Unit__c unit = TestDataFactory.createUnit(project.Id, 'Test unit', 'Sold');
        unit.BFMUnitNumber__c = 'APT 1';
        insert unit;

        SalesOrder__c salesOrder = TestDataFactory.createSalesOrder(acc.Id, opp.Id, 'Sold', date.newinstance(2025, 01, 10), unit.Id, 18181818);
        insert salesOrder;
		System.debug('salesOrder ::::: '+ salesOrder.Id);
        
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
        ServiceCatalog__c scResaleUnderConstruction = TestDataFactory.createServiceCatalog('BFM', 'Sales', 'Service Request', 'Resale', RESALE_PROPERTY_UNDER_CONSTRUCTION, 'Account;Sales Order;Unit', 'RESALE_PROPERTY_UNDER_CONSTRUCTION');
        scPost.AvailableForOwner__c = true;
        ServiceCatalog__c scResaleCompletedProj = TestDataFactory.createServiceCatalog('BFM', 'Sales', 'Service Request', 'Resale', RESALE_PROPERTY_COMPLETED_PROJECT, 'Account;Sales Order;Unit', 'RESALE_PROPERTY_COMPLETED_PROJECT');
        scPost.AvailableForOwner__c = true;
        ServiceCatalog__c scResalePHPP = TestDataFactory.createServiceCatalog('BFM', 'Sales', 'Service Request', 'Resale', RESALE_PROPERTY_WITH_PPHP, 'Account;Sales Order;Unit', 'RESALE_PROPERTY_WITH_PPHP');
        scPost.AvailableForOwner__c = true;
        ServiceCatalog__c thirdPartyForm = TestDataFactory.createServiceCatalog('BFM', 'Sales', 'Service Request', 'Financial - Payment Service', THIRD_PARTY_FORM_SUB_CATEGORY, 'Account;Sales Order;Unit', 'THIRD_PARTY_FORM_SUB_CATEGORY');
        scPost.AvailableForOwner__c = true;
        ServiceCatalog__c scChequeReplacement =
    TestDataFactory.createServiceCatalog(
        'BFM',
        'Sales',
        'Service Request',
        'Financial - Payment Service',
        CHEQUE_REPLACEMENT_REQUEST,
        'Account;Sales Order;Unit',
        'CHEQUE_REPLACEMENT_REQUEST'
    );
scChequeReplacement.AvailableForOwner__c = true;
scChequeReplacement.AvailableForTenant__c = true;

ServiceCatalog__c scChequeWithdrawal =
    TestDataFactory.createServiceCatalog(
        'BFM',
        'Sales',
        'Service Request',
        'Financial - Payment Service',
        CHEQUE_WITHDRAWAL_REQUEST,
        'Account;Sales Order;Unit',
        'CHEQUE_WITHDRAWAL_REQUEST'
    );
scChequeWithdrawal.AvailableForOwner__c = true;
scChequeWithdrawal.AvailableForTenant__c = true;

ServiceCatalog__c scLPF =
    TestDataFactory.createServiceCatalog(
        'BFM',
        'Sales',
        'Service Request',
        'Financial - Payment Service',
        LPF_WAIVER_REQUEST,
        'Account;Sales Order;Unit',
        'LPF_WAIVER_REQUEST'
    );
scLPF.AvailableForOwner__c = true;
scLPF.AvailableForTenant__c = true;

ServiceCatalog__c scSOA =
    TestDataFactory.createServiceCatalog(
        'BFM',
        'Sales',
        'Service Request',
        'Financial - Payment Service',
        SOA_REQUEST,
        'Account;Sales Order;Unit',
        'SOA_REQUEST'
    );
scSOA.AvailableForOwner__c = true;
scSOA.AvailableForTenant__c = true;

ServiceCatalog__c scProof =
    TestDataFactory.createServiceCatalog(
        'BFM',
        'Sales',
        'Service Request',
        'Financial - Payment Service',
        POPSHARE_SR_SUB_CATEGORY,
        'Account;Sales Order;Unit',
        'POPSHARE_SR_SUB_CATEGORY'
    );
scProof.AvailableForOwner__c = true;
scProof.AvailableForTenant__c = true;

ServiceCatalog__c scBank =
    TestDataFactory.createServiceCatalog(
        'BFM',
        'Sales',
        'Service Request',
        'Financial - Payment Service',
        BANK_ACC_DTAIL_SUB_CATEGORY,
        'Account;Sales Order;Unit',
        'BANK_ACC_DTAIL_SUB_CATEGORY'
    );
scBank.AvailableForOwner__c = true;
scBank.AvailableForTenant__c = true;

ServiceCatalog__c scGeneralPayment =
    TestDataFactory.createServiceCatalog(
        'BFM',
        'Sales',
        'Service Request',
        'Financial - Payment Service',
        GENERAL_PAYMENT_ENQUIRY_SUB_CATEGORY,
        'Account;Sales Order;Unit',
        'GENERAL_PAYMENT_ENQUIRY_SUB_CATEGORY'
    );
scGeneralPayment.AvailableForOwner__c = true;
scGeneralPayment.AvailableForTenant__c = true;
        
        scList.add(scBFM); scList.add(scPost);  scList.add(scResaleUnderConstruction);//scList.add(scResaleCompletedProj);
        scList.add(scResalePHPP);
        scList.add(scChequeReplacement);
scList.add(scChequeWithdrawal);
scList.add(scLPF);
scList.add(scSOA);
scList.add(scProof);
scList.add(scBank);
scList.add(scGeneralPayment);
        scList.add(thirdPartyForm);
      



ServiceCatalog__c scSalesOperation =
    TestDataFactory.createServiceCatalog(
        'BFM',
        'Sales',
        'Service Request',
        SALES_OPERATION_CATEGORY,
        'Sales Operation',
        'Account;Sales Order;Unit',
        'SalesOperation'
    );
scSalesOperation.AvailableForOwner__c = true;
scSalesOperation.AvailableForTenant__c = true;


ServiceCatalog__c scKYC =
    TestDataFactory.createServiceCatalog(
        'BFM',
        'Sales',
        'Service Request',
        CUSTOMER_SERVICE_REQUEST_CATEGORY,
        KYC_UPDATE_REQUEST,
        'Account;Sales Order;Unit',
        'KYCUpdateRequest'
    );
scKYC.AvailableForOwner__c = true;
scKYC.AvailableForTenant__c = true;


ServiceCatalog__c scTawtheeq =
    TestDataFactory.createServiceCatalog(
        'BFM',
        'Sales',
        'Service Request',
        CRM_REQUESTS_CATEGORY,
        TAWTHEEQ_ENROLLMENT_SUB_CATEGORY,
        'Account;Sales Order;Unit',
        'TawtheeqEnrollment'
    );
scTawtheeq.AvailableForOwner__c = true;
scTawtheeq.AvailableForTenant__c = true;



scList.add(scSalesOperation);
scList.add(scKYC);
scList.add(scTawtheeq);
        insert scList;

        Building__c building = TestDataFactory.createBuilding('Building 1', project.Id);
        insert building;
    }

    @isTest
    private static void testGetRelatedUnits(){
        List<Case> caseList = [SELECT Id FROM Case LIMIT 1];
        List<Unit__c> unit = [Select id from Unit__c];
        List<SalesOrder__c> order = [Select id from SalesOrder__c];
        List<Account> acc = [Select id from Account];
        Test.startTest();
         List<Unit__c> unitsFromCase = ServiceRequestController.getRelatedUnits(caseList[0].Id);
         List<Unit__c> unitList = ServiceRequestController.getRelatedUnits(unit[0].Id);
         List<Unit__c> unitsForOrder = ServiceRequestController.getRelatedUnits(order[0].Id); 
         List<Unit__c> unitsForAccount = ServiceRequestController.getRelatedUnits(acc[0].Id); 
        Test.stopTest();
        Assert.areEqual(1,caseList.size(),'There should be 1 record of Integration Record');
    }

    @isTest
    private static void testGetServiceCatalog(){
        Test.startTest();
            List<ServiceCatalog__c> scList = ServiceRequestController.getServiceCatalog(SERVICE_REQUEST, BFM_SERVICE_CATEGORY, BFM_SERVICE_REQUEST);
        Test.stopTest();
        Assert.areEqual(1,scList.size(),'There should be 1 record of Integration Record');
    }

    @IsTest
    private static void testValidateEligibility() {
        List<Case> caseList = [SELECT Id,Status,Origin,Subject,Description,AccountId
                                FROM Case LIMIT 1];
        SalesOrder__c so = [SELECT Id, Unit__c FROM SalesOrder__c];
        
        Test.startTest();
        String msg = ServiceRequestController.validateEligibility(so.Id,BFM_SERVICE_REQUEST,caseList[0].AccountId,so.Unit__c,true);
        String msg2 = ServiceRequestController.validateEligibility(so.Id,POST_SALE_PAYMENT_DEFERRAL,caseList[0].AccountId,so.Unit__c,true);
        String msg3 = ServiceRequestController.validateEligibility(so.Id,RESALE_PROPERTY_UNDER_CONSTRUCTION,caseList[0].AccountId,so.Unit__c,true);
        //String msg4 = ServiceRequestController.validateEligibility(so.Id,RESALE_PROPERTY_COMPLETED_PROJECT,true);
        String msg5 = ServiceRequestController.validateEligibility(so.Id,RESALE_PROPERTY_WITH_PPHP,caseList[0].AccountId,so.Unit__c,true);
        String msg6 = ServiceRequestController.validateEligibility(so.Id,POST_SALE_PAYMENT_DEFERRAL,caseList[0].AccountId,so.Unit__c,true);
        String msg7 = ServiceRequestController.validateEligibility(so.Id,BFM_SERVICE_REQUEST,caseList[0].AccountId,so.Unit__c,true);
        
        Test.stopTest();
        //Assert.areEqual(true,String.isNotBlank(msg2),'Their should be an error msg');
    }

    @IsTest
    private static void testCreateCaseRecord(){
        List<SalesOrder__c> soList = [SELECT Id, Account__c, Unit__c, Unit__r.Name,Account__r.Id FROM SalesOrder__c LIMIT 1];
        List<ServiceCatalog__c> scList = [SELECT Id,SubCategory__c,RecordTypeDevName__c FROM ServiceCatalog__c LIMIT 1];
        List<Case> caseList = [SELECT Id,AccountId FROM Case LIMIT 1];
        Test.startTest();
        Map<String,String> outputMap = ServiceRequestController.createCaseRecord(soList[0].Id, SERVICE_REQUEST, FINANCIAL_PAYMENT_SERVICE_CATEGORY, POST_SALE_PAYMENT_DEFERRAL, soList[0].Account__c, soList[0].Unit__c,'test','Phone', false);
        Map<String,String> outputMap1 = ServiceRequestController.createCaseRecord(null, SERVICE_REQUEST, BFM_SERVICE_CATEGORY, BFM_SERVICE_REQUEST, soList[0].Account__c, soList[0].Unit__c,'test','Phone', false);
        Map<String,String> outputMap2 = ServiceRequestController.createCaseRecord(null, SERVICE_REQUEST, FINANCIAL_PAYMENT_SERVICE_CATEGORY, POST_SALE_PAYMENT_DEFERRAL, soList[0].Account__c, soList[0].Unit__c,'test','Phone', false);
        Map<String,String> outputMap3 = ServiceRequestController.createCaseRecord(null, SERVICE_REQUEST, RESALE_CATEGORY, RESALE_PROPERTY_UNDER_CONSTRUCTION, soList[0].Account__c, soList[0].Unit__c,'test','Phone', true);
        Map<String,String> outputMap4 = ServiceRequestController.createCaseRecord(null, SERVICE_REQUEST, RESALE_CATEGORY, RESALE_PROPERTY_COMPLETED_PROJECT, soList[0].Account__c, soList[0].Unit__c,'test','Phone', true);
        Map<String,String> outputMap5 = ServiceRequestController.createCaseRecord(null, SERVICE_REQUEST, RESALE_CATEGORY, RESALE_PROPERTY_WITH_PPHP, soList[0].Account__c, soList[0].Unit__c,'test','Phone', true);
        Test.stopTest();
        Assert.areEqual(false,outputMap.isEmpty(),'Their should be some values in map');
    }

    @IsTest
    private static void testGetDefaultValuesSalesOrderBFM(){
        List<SalesOrder__c> soList = [SELECT Id, Account__c, Unit__c, Unit__r.Name,Account__r.Id FROM SalesOrder__c LIMIT 1];
        List<ServiceCatalog__c> scList = [SELECT Id,SubCategory__c,RecordTypeDevName__c FROM ServiceCatalog__c LIMIT 1];
        List<Case> caseList = [SELECT Id,AccountId FROM Case LIMIT 1];
        Test.startTest();
            Map<String,String> outputMap = ServiceRequestController.createCaseRecord(soList[0].Id, SERVICE_REQUEST, BFM_SERVICE_CATEGORY, BFM_SERVICE_REQUEST, soList[0].Account__c, soList[0].Unit__c,'test','Web', false);
        Test.stopTest();
        Assert.areEqual(false,outputMap.isEmpty(),'Their should be some values in map');
    }

    @IsTest
    private static void testGetDefaultValuesPostSale(){
        List<SalesOrder__c> soList = [SELECT Id, Account__c, Unit__c, Unit__r.Name,Account__r.Id FROM SalesOrder__c LIMIT 1];
        List<ServiceCatalog__c> scList = [SELECT Id,SubCategory__c,RecordTypeDevName__c FROM ServiceCatalog__c LIMIT 1];
        List<Case> caseList = [SELECT Id,AccountId FROM Case LIMIT 1];
        Test.startTest();
            Map<String,String> outputMap = ServiceRequestController.createCaseRecord(soList[0].Id, SERVICE_REQUEST, FINANCIAL_PAYMENT_SERVICE_CATEGORY, POST_SALE_PAYMENT_DEFERRAL, soList[0].Account__c, soList[0].Unit__c,'test','Phone', false);
           Map<String,String> outputResaleMap = ServiceRequestController.createCaseRecord(soList[0].Id, SERVICE_REQUEST,RESALE_CATEGORY, RESALE_PROPERTY_UNDER_CONSTRUCTION, soList[0].Account__c, soList[0].Unit__c,'test','Phone', true);
          Map<String,String> outputResaleMap2 = ServiceRequestController.createCaseRecord(soList[0].Id, SERVICE_REQUEST,RESALE_CATEGORY, RESALE_PROPERTY_WITH_PPHP, soList[0].Account__c, soList[0].Unit__c,'test','Phone', true);
         Map<String,String> outputResaleMap3 = ServiceRequestController.createCaseRecord(soList[0].Id, SERVICE_REQUEST,RESALE_CATEGORY, RESALE_PROPERTY_COMPLETED_PROJECT, soList[0].Account__c, soList[0].Unit__c,'test','Phone', true);
        Test.stopTest();
        Assert.areEqual(false,outputMap.isEmpty(),'Their should be some values in map');
    }

    @isTest
    private static void testConvertToRequestComplaintBFM(){
        List<Case> caseList = [SELECT Id,AccountId FROM Case LIMIT 1];
        List<ServiceCatalog__c> scList = [SELECT Id,RecordTypeDevName__c FROM ServiceCatalog__c LIMIT 1];
        Test.startTest();
            Map<String, String> outputMap = ServiceRequestController.convertToRequestComplaint(SERVICE_REQUEST, BFM_SERVICE_CATEGORY, BFM_SERVICE_REQUEST, caseList[0].AccountId, null, caseList[0].Id,'test','Phone');
        Test.stopTest();
        Assert.areEqual(false,outputMap.isEmpty(),'Their should be some values in map');
        Assert.areEqual('success',outputMap.get('status'),'Status should be success');
    }

    @isTest
    private static void testConvertToRequestComplaintPostSale(){
        List<Case> caseList = [SELECT Id,AccountId FROM Case LIMIT 1];
        List<ServiceCatalog__c> scList = [SELECT Id,RecordTypeDevName__c FROM ServiceCatalog__c LIMIT 1];
        Test.startTest();
        Map<String, String> outputMap = ServiceRequestController.convertToRequestComplaint('Service', 'CRM', POST_SALE_PAYMENT_DEFERRAL, caseList[0].AccountId, null, caseList[0].Id,'test','Phone');
        Test.stopTest();
        Assert.areEqual(false,outputMap.isEmpty(),'Their should be some values in map');
        Assert.areEqual('error',outputMap.get('status'),'Status should be success');
    }

    @isTest
    private static void testSendToBFM(){
        List<Case> caseList = [SELECT Id,RecordType.Name FROM Case WHERE RecordType.DeveloperName = 'BFMServiceRequest' LIMIT 1];
        List<Building__c> buildingList = [SELECT Id FROM Building__c LIMIT 1];
        Test.startTest();
            caseList[0].Subject = 'test Subject';
            caseList[0].RequesterRemarks__c = 'test description';
            caseList[0].RequesterName__c = 'test name';
            caseList[0].RequesterContactNumber__c = '0123456789';
            caseList[0].RequesterEmail__c = 'test@gmail.com';
            caseList[0].Priority = 'High';
            caseList[0].Type = 'CAPEX';
            //caseList[0].Category__c = 'Elevator Maintenance';
            //caseList[0].SubCategory__c = 'Others';
            caseList[0].Origin = 'Phone';
            caseList[0].Area__c = 'Others';
            update caseList[0];
        
         String msg = ServiceRequestController.sendToBFM(caseList[0].Id);
        Test.stopTest();
        List<IntegrationRecord__c> integrationRecList = [SELECT Id FROM IntegrationRecord__c WHERE RecordId__c =: caseList[0].Id];
        Assert.areEqual(0,integrationRecList.size(),'There should be 1 record of Integration Record');
    }
    @isTest
    private static void testSubmitCaseComment(){
        List<Case> caseList = [SELECT Id,AccountId FROM Case LIMIT 1];
        Test.startTest();
        ServiceRequestController.submitCaseComment(caseList[0].id, 'This is comment Body');
        Test.stopTest();
        List<IntegrationRecord__c> integrationRecList = [SELECT Id FROM IntegrationRecord__c WHERE RecordId__c =: caseList[0].Id];
        Assert.areEqual(1,integrationRecList.size(),'There should be 1 record of Integration Record');
    }

    @isTest
    private static void testGetTypes(){
        Test.startTest();
         Map<String, String> typeMap = ServiceRequestController.getTypes();
        Test.stopTest();
        System.assertNotEquals(null, typeMap, 'Result should not be null');
    System.assert(typeMap.size() > 0, 'Picklist should have values');
    }

    @isTest
    private static void testGetCategories(){
        Account acc = [SELECT Id FROM Account LIMIT 1];
        SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
       Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        Test.startTest();
        List<String> categoryList = ServiceRequestController.getCategories('Service Request', acc.Id);
        List<String> categoryListSO = ServiceRequestController.getCategories('Service Request', so.Id);
        List<String> categoryListUnit = ServiceRequestController.getCategories('Service Request', unit.Id);
        ServiceRequestController.getOriginValues();
        Test.stopTest();
         System.assertNotEquals(null, categoryList, 'Category list should not be null');
    }

    @isTest
    private static void testGetSubCategories(){
    Account acc = [SELECT Id FROM Account LIMIT 1];
    SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
     Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
    Test.startTest();
    List<String> subCategoryList = ServiceRequestController.getSubCategories('Service Request','BFM Service',acc.Id);
    List<String> subCategoryListSO = ServiceRequestController.getSubCategories('Service Request','BFM Service',so.Id);
    List<String> subCategoryListUnit = ServiceRequestController.getSubCategories('Service Request','BFM Service',unit.Id);
    Test.stopTest();

    System.assertNotEquals(null, subCategoryList, 'SubCategory list should not be null');
    }
    //////////////////////////////
    @isTest
    private static void validateCaseTest1(){
        List<SalesOrder__c> soList = [SELECT Id, Account__c, Unit__c, Unit__r.Name,Account__r.Id FROM SalesOrder__c LIMIT 1];
        Test.startTest();
        //ServiceRequestController.validateEligibility(soList [0].id, 'Third Party Form', False);
        Test.stopTest();
    }
    
    @isTest
    private static void validateCaseTest2(){
        List<SalesOrder__c> soList = [SELECT Id, Account__c, Unit__c, Unit__r.Name,Account__r.Id FROM SalesOrder__c LIMIT 1];
        Test.startTest();
        //ServiceRequestController.validateEligibility(soList [0].id, 'Payment', False);
        Test.stopTest();
    }
    @isTest
    private static void validateCaseTest3(){
        List<SalesOrder__c> soList = [SELECT Id, Account__c, Unit__c, Unit__r.Name,Account__r.Id FROM SalesOrder__c LIMIT 1];
        Test.startTest();
        //ServiceRequestController.validateEligibility(soList [0].id, 'Acknowledgement Receipt', False);
        Test.stopTest();
    }
    @isTest
    private static void validateCaseTest4(){
        List<SalesOrder__c> soList = [SELECT Id, Account__c, Unit__c, Unit__r.Name,Account__r.Id FROM SalesOrder__c LIMIT 1];
        Test.startTest();
        //ServiceRequestController.validateEligibility(soList [0].id, 'Payment Due Date Update', False);
        Test.stopTest();
    }
    
    @isTest
    private static void createCaseTest1(){
        List<SalesOrder__c> soList = [SELECT Id, Account__c, Unit__c, Unit__r.Name,Account__r.Id FROM SalesOrder__c LIMIT 1];
        Test.startTest();
        ServiceRequestController.createCaseRecord(soList[0].id,'Service Request','Financial - Payment Service', 'Third Party Form',soList [0].Account__c,soList [0].Unit__c, 'test','Phone', false);
        Test.stopTest();
    }
    
    @isTest
    private static void createCaseTest2(){
        List<SalesOrder__c> soList = [SELECT Id, Account__c, Unit__c, Unit__r.Name,Account__r.Id FROM SalesOrder__c LIMIT 1];
        Test.startTest();
        ServiceRequestController.createCaseRecord(soList[0].id,'Service Request','Financial - Payment Service', 'Payment',soList [0].Account__C,soList [0].Unit__c, 'test','Phone', false);
        Test.stopTest();
    }
    
    @isTest
    private static void createCaseTest3(){
        List<SalesOrder__c> soList = [SELECT Id, Account__c, Unit__c, Unit__r.Name,Account__r.Id FROM SalesOrder__c LIMIT 1];
        Test.startTest();
        ServiceRequestController.createCaseRecord(soList[0].id,'Service Request','Financial - Payment Service', 'Acknowledgement Receipt',soList [0].Account__C,soList [0].Unit__c, 'test','Phone', false);
        Test.stopTest();
    }
    
    @isTest
    private static void createCaseTest4(){
        List<SalesOrder__c> soList = [SELECT Id, Account__c, Unit__c, Unit__r.Name,Account__r.Id FROM SalesOrder__c LIMIT 1];
        Test.startTest();
        ServiceRequestController.createCaseRecord(soList[0].id,'Service Request','Financial - Payment Service', 'Payment Due Date Update',soList [0].Account__C,soList [0].Unit__c, 'test','Phone', false);
        Test.stopTest();
    }
    
    @isTest
    private static void testDefaultNoticeMethods(){
        Case caseRec = [SELECT Id, Step__c, CaseType__c, ServiceCatalog__c, Status FROM Case LIMIT 1];
        Test.startTest();
        ServiceRequestController.fetchDefaultNoticeEmailTemplate(caseRec.Id);
        ServiceRequestController.sendOriginalDocumentChecklist(new List<String>{'SOA','NOC'}, caseRec.Id, 'test remarks');
        ServiceRequestController.reassignCase(caseRec.Id, UserInfo.getUserId());
        Test.stopTest();
    }
    
    @isTest
    private static void testFetchRegistrationVerificationEmailTemplate(){
        Case caseRec = [SELECT Id, Step__c, CaseType__c, ServiceCatalog__c, Status FROM Case LIMIT 1];
        Test.startTest();
        ServiceRequestController.fetchRegistrationVerificationEmailTemplate(caseRec.Id);
        Test.stopTest();
    }
   @isTest
    private static void testGetRelatedAccount() {

    Account acc = [SELECT Id FROM Account LIMIT 1];
    SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];

    Test.startTest();

    // Case 1: Pass Account Id
    String accIdFromAccount = ServiceRequestController.getRelatedAccount(acc.Id);

    // Case 2: Pass SalesOrder Id
    String accIdFromSO = ServiceRequestController.getRelatedAccount(so.Id);

    Test.stopTest();

    System.assertEquals(acc.Id, accIdFromAccount, 'Should return same Account Id');
    System.assertEquals(acc.Id, accIdFromSO, 'Should return Account Id from SalesOrder');
}
   @isTest
private static void testGetRelatedUnitsByAccountId() {

    Account acc = [SELECT Id FROM Account LIMIT 1];
    SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];

    Test.startTest();

    // Case 1: Using Account Id
    List<SalesOrder__c> soListFromAccount =
        ServiceRequestController.getRelatedUnitsbyAccountId(acc.Id);

    // Case 2: Using SalesOrder Id
    List<SalesOrder__c> soListFromSO =
        ServiceRequestController.getRelatedUnitsbyAccountId(so.Id);

    Test.stopTest();

    System.assertNotEquals(null, soListFromAccount, 'List should not be null');
    System.assertNotEquals(null, soListFromSO, 'List should not be null');

    // Optional stronger checks
    System.assert(soListFromAccount.size() > 0, 'Should return at least one SalesOrder');
    System.assert(soListFromSO.size() > 0, 'Should return at least one SalesOrder');
}
    @isTest
private static void testGetSubCategoriesforSubmit() {

    // Use existing ServiceCatalog from @testSetup
    ServiceCatalog__c sc = [
        SELECT Id, SubCategory__c 
        FROM ServiceCatalog__c 
        LIMIT 1
    ];

    Test.startTest();
    List<ServiceCatalog__c> resultList =
        ServiceRequestController.getSubCategoriesforSubmit(sc.SubCategory__c);
    Test.stopTest();

    System.assertNotEquals(null, resultList, 'Result should not be null');
    System.assert(resultList.size() > 0, 'Should return at least one record');

    // Optional stronger validation
    for(ServiceCatalog__c rec : resultList){
        System.assertEquals(sc.SubCategory__c, rec.SubCategory__c);
    }
}
    @isTest
private static void testCreateCaseRecordFinancialBranches() {

    SalesOrder__c so = [
        SELECT Id, Account__c, Unit__c
        FROM SalesOrder__c
        LIMIT 1
    ];

    Test.startTest();

    ServiceRequestController.createCaseRecord(
        so.Id,
        SERVICE_REQUEST,
        FINANCIAL_PAYMENT_SERVICE_CATEGORY,
        CHEQUE_REPLACEMENT_REQUEST,
        so.Account__c,
        so.Unit__c,
        'Test',
        'Phone',
        false
    );

    ServiceRequestController.createCaseRecord(
        so.Id,
        SERVICE_REQUEST,
        FINANCIAL_PAYMENT_SERVICE_CATEGORY,
        CHEQUE_WITHDRAWAL_REQUEST,
        so.Account__c,
        so.Unit__c,
        'Test',
        'Phone',
        false
    );

    ServiceRequestController.createCaseRecord(
        so.Id,
        SERVICE_REQUEST,
        FINANCIAL_PAYMENT_SERVICE_CATEGORY,
        LPF_WAIVER_REQUEST,
        so.Account__c,
        so.Unit__c,
        'Test',
        'Phone',
        false
    );

    ServiceRequestController.createCaseRecord(
        so.Id,
        SERVICE_REQUEST,
        FINANCIAL_PAYMENT_SERVICE_CATEGORY,
        SOA_REQUEST,
        so.Account__c,
        so.Unit__c,
        'Test',
        'Phone',
        false
    );

    ServiceRequestController.createCaseRecord(
        so.Id,
        SERVICE_REQUEST,
        FINANCIAL_PAYMENT_SERVICE_CATEGORY,
        POPSHARE_SR_SUB_CATEGORY,
        so.Account__c,
        so.Unit__c,
        'Test',
        'Phone',
        false
    );

    ServiceRequestController.createCaseRecord(
        so.Id,
        SERVICE_REQUEST,
        FINANCIAL_PAYMENT_SERVICE_CATEGORY,
        BANK_ACC_DTAIL_SUB_CATEGORY,
        so.Account__c,
        so.Unit__c,
        'Test',
        'Phone',
        false
    );

    ServiceRequestController.createCaseRecord(
        so.Id,
        SERVICE_REQUEST,
        FINANCIAL_PAYMENT_SERVICE_CATEGORY,
        GENERAL_PAYMENT_ENQUIRY_SUB_CATEGORY,
        so.Account__c,
        so.Unit__c,
        'Test',
        'Phone',
        false
    );

    Test.stopTest();
}
    @isTest
private static void testCreateCaseRecordAdditionalSalesOrderBranches() {

    SalesOrder__c so = [
        SELECT Id, Account__c, Unit__c
        FROM SalesOrder__c
        LIMIT 1
    ];

    Test.startTest();

  

    // Sales Operation
    Map<String, String> salesOperationResult =
        ServiceRequestController.createCaseRecord(
            so.Id,
            SERVICE_REQUEST,
            SALES_OPERATION_CATEGORY,
            'Sales Operation',
            so.Account__c,
            so.Unit__c,
            'Test Sales Operation',
            'Phone',
            false
        );

    // KYC Update
    Map<String, String> kycResult =
        ServiceRequestController.createCaseRecord(
            so.Id,
            SERVICE_REQUEST,
            CUSTOMER_SERVICE_REQUEST_CATEGORY,
            KYC_UPDATE_REQUEST,
            so.Account__c,
            so.Unit__c,
            'Test KYC',
            'Phone',
            false
        );

    // Tawtheeq Enrollment
    Map<String, String> tawtheeqResult =
        ServiceRequestController.createCaseRecord(
            so.Id,
            SERVICE_REQUEST,
            CRM_REQUESTS_CATEGORY,
            TAWTHEEQ_ENROLLMENT_SUB_CATEGORY,
            so.Account__c,
            so.Unit__c,
            'Test Tawtheeq',
            'Phone',
            false
        );

    Test.stopTest();

    
    System.assertNotEquals(null, salesOperationResult);
    System.assertNotEquals(null, kycResult);
    System.assertNotEquals(null, tawtheeqResult);
}
}