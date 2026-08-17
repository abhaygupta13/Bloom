@IsTest
public class CaseRequestHandlerTest {
    @IsTest
    static void testhandleAssignment() {
        Test.startTest();
        Service_Catalog__c testServiceCatalog =BCAPP_TestDataFactory.createServiceCatalog();
        insert testServiceCatalog;
        
        Account accountRecord =BCAPP_TestDataFactory.createAccount('Test Account');
        accountRecord.Azure_UserPrincipal_Id__c='testttt';
        insert accountRecord;
        
        Contact cntRecord= BCAPP_TestDataFactory.createContact(accountRecord.id,'ewew@dasds.com');
        insert cntRecord;
        Service_Contract__c Service_Contract=  BCAPP_TestDataFactory.createServiceContract();
        Service_Contract.Customer_Name__c=accountRecord.id;
        insert Service_Contract;
        
        Service_Catolog_Documents__c testService_Catolog_Documents =BCAPP_TestDataFactory.createServiceCatalogDocuments();
        testService_Catolog_Documents.Service_Catalog__c=testServiceCatalog.id;
        insert testService_Catolog_Documents;
        
        Case testCase =BCAPP_TestDataFactory.createCase();
        String RecordTypeCaseId =  Utilities.getRecordTypeId('Case', BCAPP_Constants.ACCESS_PERMIT);
        testCase.RecordTypeId=RecordTypeCaseId;
        testCase.AccountId= accountRecord.id;
        testCase.Move_Out_Date__c=system.today();
        testCase.Email_Address__c='testuser@fff.com';
        testCase.type='Deletion Joint Owner';
        testCase.Service_Catalog__c=testServiceCatalog.id;
        insert testCase;
        PdfControllerHelper p = new PdfControllerHelper(testCase.Id);

        ApexPages.StandardController sc = new ApexPages.StandardController(testCase);        
        //ApexPages.StandardController sc = new ApexPages.StandardController(pageRef);
        PdfControllerHelper ps = new PdfControllerHelper(sc);
        testCase.Status='Submitted';
        
        case testCaseold=new case();
        testCaseold.id=testCase.id;
        testCaseold.Status='Draft';
        
        map<id,case> caseOld=new  map<id,case>();
        caseOld.put(testCaseold.id,testCaseold);
        CaseRequestHandler.handleAssignment(new List<Case> {testCase},caseOld);
            CaseRequestHandler.handleSubmittedCases(new List<Case> {testCase});
        Test.StopTest();
        
    }

    static void testhandleAssignment1() {
        Test.startTest();
        Service_Catalog__c testServiceCatalog =BCAPP_TestDataFactory.createServiceCatalog();
        insert testServiceCatalog;
        
        Account accountRecord =BCAPP_TestDataFactory.createAccount('Test Account');
        accountRecord.Azure_UserPrincipal_Id__c='testttt';
        insert accountRecord;
        
        Contact cntRecord= BCAPP_TestDataFactory.createContact(accountRecord.id,'ewew@dasds.com');
        insert cntRecord;
        Service_Contract__c Service_Contract=  BCAPP_TestDataFactory.createServiceContract();
        Service_Contract.Customer_Name__c=accountRecord.id;
        insert Service_Contract;
        
        Service_Catolog_Documents__c testService_Catolog_Documents =BCAPP_TestDataFactory.createServiceCatalogDocuments();
        testService_Catolog_Documents.Service_Catalog__c=testServiceCatalog.id;
        insert testService_Catolog_Documents;
        

        Case testCase =BCAPP_TestDataFactory.createCase();
        String RecordTypeCaseId =  Utilities.getRecordTypeId('Case', BCAPP_Constants.ACCESS_PERMIT);
        testCase.RecordTypeId=RecordTypeCaseId;
        testCase.AccountId= accountRecord.id;
        testCase.Move_Out_Date__c=system.today();
        testCase.Email_Address__c='testuser@fff.com';
        testCase.type='Deletion Joint Owner';
        testCase.Service_Catalog__c=testServiceCatalog.id;
       
        insert testCase;

        Case testCase1 =BCAPP_TestDataFactory.createCase();
        String RecordTypeCaseId1 =  Utilities.getRecordTypeId('Case', BCAPP_Constants.ACCESS_PERMIT);
        testCase1.RecordTypeId=RecordTypeCaseId1;
        testCase1.AccountId= accountRecord.id;
        testCase1.Move_Out_Date__c=system.today();
        testCase1.Email_Address__c='testuser@fff.com';
        testCase1.type='Deletion Joint Owner';
        testCase1.Service_Catalog__c=testServiceCatalog.id;
        testCase1.ParentId = testCase.Id;
        insert testCase1;
        PdfControllerHelper p = new PdfControllerHelper(testCase.Id);

        ApexPages.StandardController sc = new ApexPages.StandardController(testCase);        
        //ApexPages.StandardController sc = new ApexPages.StandardController(pageRef);
        PdfControllerHelper ps = new PdfControllerHelper(sc);
        testCase.Status='Submitted';
        
        case testCaseold=new case();
        testCaseold.id=testCase.id;
        testCaseold.Status='Draft';
        
        map<id,case> caseOld=new  map<id,case>();
        caseOld.put(testCaseold.id,testCaseold);
        CaseRequestHandler.handleAssignment(new List<Case> {testCase},caseOld);
            CaseRequestHandler.handleSubmittedCases(new List<Case> {testCase});
        Test.StopTest();
        
    }
}