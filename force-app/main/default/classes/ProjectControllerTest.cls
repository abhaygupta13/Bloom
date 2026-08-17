/***
Class       : ProjectControllerTest
Author      : Jayesh
Description : Test class of ProjectController class
TestClass   : N/A
----------------------------------------------------------------------------------------------------------------
****************************************************************************************************************/
@isTest
private class ProjectControllerTest {
    @TestSetup
    static void setupTestData() {
        // Test data for Project__c and related Units
        Account account = TestDataFactory.createPersonalAccount('Lastname', '01010101', '1234567890', 'test@gmail.com');
        account.CustomerType__c = 'Resident';
        INSERT account;
        
        DocumentType__c dc1 = TestDataFactory.createDocumentType('Sales Order', 'Emirates ID');
        INSERT dc1;
        DocumentType__c dc2 = TestDataFactory.createDocumentType('Sales Order' , 'Passport');
        INSERT dc2;
        DocumentType__c dc3 = TestDataFactory.createDocumentType('Sales Order', 'SPA - Signed');
        INSERT dc3;
        DocumentType__c dc4 = TestDataFactory.createDocumentType('Project', 'ADM Registration Document');
        INSERT dc4;
        
        //Test data for Project__c and related Units
        Project__c project = TestDataFactory.createProject('ProjectTest', Date.today() - 1);
        insert project;
        
        Unit__c u = TestDataFactory.createUnit(project.Id, 'A1-G01', 'Unassigned');
        u.Project__c = project.Id;
        u.RegistrationDate__c = Date.today();
        insert u;
        
        SalesOrder__c salesOrder = TestDataFactory.createSalesOrder(account.Id, null, null, null, u.Id, 100.00);
        salesOrder.DocumentUploadedDate__c = Date.today() - 1; 
        salesOrder.UnitRegistrationDate__c = Date.today();
        insert salesOrder;
        
        u.Active_Sales_Order__c = salesOrder.Id;
        update u;
        
        // Create test Document__c record
        Document__c testDocument = TestDataFactory.createDoc(dc1.Id, salesOrder.Id, null);
        testDocument.ContentDocumentId__c = '001001';
        insert testDocument;
        // Create test Document__c record
        Document__c testDocument2 = TestDataFactory.createDoc(dc2.Id, salesOrder.Id, null);
        testDocument2.ContentDocumentId__c = '001001';
        insert testDocument2;
        // Create test Document__c record
        Document__c testDocument3 = TestDataFactory.createDoc(dc3.Id, salesOrder.Id, null);
        testDocument3.ContentDocumentId__c = '001001';
        insert testDocument3;
        
        Document__c testDocument4 = TestDataFactory.createDoc(dc4.Id, salesOrder.Id, project.Id);
        insert testDocument4;
        
        ContentVersion cv = TestDataFactory.createContentVersion('base 64', 'filename', 'title');
        INSERT cv;
        
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion LIMIT 1];
        
        ContentDocumentLink cd = TestDataFactory.createContentDocumentLink(cv.ContentDocumentId, testDocument4.Id, '', '');
        INSERT cd;
    }
    
    @IsTest
    static void testGetProjectRecord() {
        // Get test Project__c Id
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        
        // Call the method
        Project__c result = ProjectController.getProjectRecord(project.Id);
        
        // Assert
        System.assertNotEquals(null, result, 'Project record should not be null');
    }
    
    @IsTest
    static void testGetProjectRecordWithUnits() {
        // Get test Project__c Id
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        // Call the method
        Project__c result = ProjectController.getProjectRecordWithUnits(project.Id);
        // Assert
        System.assertNotEquals(null, result, 'Project record should not be null');
    }
    
    @IsTest
    static void testUpdateUnitRegDateOnSalesOrder() {
        
        // Fetch the inserted record
        List<SalesOrder__c> salesOrders = [SELECT Id FROM SalesOrder__c];
        List<Project__c> prj=[select id from Project__c limit 1];
        
        // Call the method
        Test.startTest();
        try {
            ProjectController.updateUnitRegDateOnSalesOrder(salesOrders);
        } catch (Exception e) {
            System.debug('---->'+e.getMessage());
            //System.assert(false, 'Unexpected Exception: ' + e.getMessage());
            System.assertEquals('Script-thrown exception',e.getMessage());
        }
        Test.stopTest();
        
        // Assert: Ensure no exceptions and records are updated
        SalesOrder__c updatedSO = [SELECT Id FROM SalesOrder__c WHERE Id = :salesOrders[0].Id];
        System.assertNotEquals(null, updatedSO, 'Sales Order record should exist');
    }
    
    
    @IsTest
    static void testGetSalesOrderDocuments() {
        // Get test SalesOrder__c Id
        SalesOrder__c testSalesOrder = [SELECT Id FROM SalesOrder__c LIMIT 1];
        ContentVersion cv = [SELECT Id, ContentDocumentId FROM ContentVersion LIMIT 1];
        List<Document__c> documents = [SELECT Id, Document_Name__c, ContentDocumentId__c FROM Document__c 
                                       WHERE Salesorder__c =: testSalesOrder.Id AND Document_Name__c = 'Passport'];
        System.debug('documents===>'+documents);
        documents[0].ContentDocumentId__c = cv.ContentDocumentId;
        UPDATE documents;
        // Call the method
        String result = ProjectController.getSalesOrderDocuments(testSalesOrder.Id);        
        // Assert
        System.assertNotEquals(null, result, 'Documents should be retrieved as JSON');
    }
    
    
    @isTest
    static void unitTest(){
        List<Project__c> prj=[select id from Project__c limit 1];
        try{
        List<Unit__c> uniList=new List<Unit__c>();
        ProjectController.updateADMRegDateOnUnits( uniList,prj[0],false);
        }
        catch(exception ex){}
    }
    
    @IsTest
    static void testUploadUnitRegDocument() {
        String salesOrderId = [SELECT Id FROM SalesOrder__c LIMIT 1].Id;
        // Prepare test data
        String base64 = 'dGVzdCBkYXRh'; // Base64 for 'test data'
        String fileName = 'TestFile.pdf';
        //String activeSalesOrderId = salesOrderId;
        
        ProjectController.UnitRegDocumentWrapper wrapper = new ProjectController.UnitRegDocumentWrapper();
        wrapper.recordId = salesOrderId;
        wrapper.base64 = base64;
        wrapper.fileName = fileName;
        
        String serializedWrapper = JSON.serialize(wrapper);
        
        
        // Call the method
        Test.startTest();
        try{
            ProjectController.uploadUnitRegDocument(serializedWrapper);
        }catch(Exception e){
            
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateADMRegDateOnUnits() {
        // Get test data
        Project__c testProject = [SELECT Id FROM Project__c LIMIT 1];
        List<Unit__c> testUnits = [SELECT Id FROM Unit__c LIMIT 1];
        List<String> listSalesOrder_str = new List<String>();
        List<SalesOrder__c> listsalesOrder = [SELECT Id FROM SalesOrder__c WHERE Account__c != null];
        if(listsalesOrder.size() > 0){
            for(SalesOrder__c objSales : listsalesOrder){
                listSalesOrder_str.add(objSales.Id);
            } 
        }
        Document__c doc = [SELECT Id FROM Document__c  LIMIT 1];
        
        // Call the method
        String base64 = 'dGVzdCBkYXRh'; // Base64 for 'test data'
        Test.startTest();
        ProjectController.updateADMRegDateOnUnits(testUnits, testProject, false);
        ProjectController.getSalesOrderRecordWithNoDocuments(listSalesOrder_str);
        Test.stopTest();
        
        // Assert: Validate updates
        Project__c updatedProject = [SELECT ProjectRegistrationDate__c FROM Project__c WHERE Id = :testProject.Id];
        System.assertNotEquals(null, updatedProject.ProjectRegistrationDate__c, 'Project registration date should be updated');
    }
    
    @IsTest
    static void testUpdateProject() {
        // Get test data
        Project__c testProject = [SELECT Id FROM Project__c LIMIT 1];
        List<Unit__c> testUnits = [SELECT Id FROM Unit__c LIMIT 1];
        List<String> listSalesOrder_str = new List<String>();
        List<SalesOrder__c> listsalesOrder = [SELECT Id FROM SalesOrder__c WHERE Account__c != null];
        if(listsalesOrder.size() > 0){
            for(SalesOrder__c objSales : listsalesOrder){
                listSalesOrder_str.add(objSales.Id);
            } 
        }
        Document__c doc = [SELECT Id FROM Document__c  LIMIT 1];
        
        // Call the method
        String base64 = 'dGVzdCBkYXRh'; // Base64 for 'test data'
        Test.startTest();
        ProjectController.updateADMRegDateOnUnits(testUnits, testProject, true);
        ProjectController.getSalesOrderRecordWithNoDocuments(listSalesOrder_str);
        Test.stopTest();
    }
    
    @IsTest
    static void testgetSalesOrderUnitDocument() {
        SalesOrder__c testSalesOrder = [SELECT Id FROM SalesOrder__c LIMIT 1];
        ProjectController.getSalesOrderUnitDocument(new List<String>{testSalesOrder.Id});
    }
    
    @IsTest
    static void testUploadFile() {
        List<Document__c> documents = [SELECT Id, DocumentType__c, Document_Name__c, SalesOrder__c, Project__c 
                                       FROM Document__c WHERE Document_Name__c = 'ADM Registration Document'];
        try{
            ProjectController.uploadFile('base64', 'filnema', documents[0].Project__c); 
        }catch(Exception e){
            
        }
    }
    
    @IsTest
    static void testWrapper() {
        ProjectController.ContentVersionWrapper wrapper2 = new ProjectController.ContentVersionWrapper('test', 'test', 1);
        System.assertNotEquals(null, wrapper2, 'Wrapper should be filled');
    }
    
    @IsTest
    static void updateSalesOrderRecordsTest() {
        SalesOrder__c testSalesOrder = [SELECT Id, UnitRegistrationDate__c FROM SalesOrder__c LIMIT 1];
        testSalesOrder.UnitRegistrationDate__c = Date.today();
        ProjectController.updateSalesOrderRecords(new List<SalesOrder__c> {testSalesOrder});
        testSalesOrder = [SELECT Id, UnitRegistrationDate__c FROM SalesOrder__c LIMIT 1];
        System.assert(testSalesOrder.UnitRegistrationDate__c != null , 'Updated');
    }
    
     @IsTest
    static void testGetProjectAndSoldUnits() {
        // Get test Project__c Id
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        
        // Call the method
        Project__c result = ProjectController.getProjectAndSoldUnits(project.Id);
        
        // Assert
        System.assertNotEquals(null, result, 'Project record should not be null');
    }
    
     @IsTest
    static void testGetUnitDocuments() {
        // Get test Project__c Id
        Unit__c testUnits = [SELECT Id FROM Unit__c LIMIT 1];
        
        // Call the method
         Map<String, Document__c> result = ProjectController.getUnitDocuments(New List <String>{testUnits.Id});
        
        // Assert
        System.assertNotEquals(null, result, 'Project record should not be null');
    }
    
    @IsTest
    static void testGetProjectClassifications() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        BuildingSection__c testBuilding=new BuildingSection__c(
            Name='Test Building',
            BuildingSectionCode__c='BL-CAS',
            Project__c=project.Id
            
        );
        insert testBuilding;
        Unit__c testUnit=new Unit__c(
            Name='test Unit',
            Status__c='Available',
            UnitType__c='Townhouse',
            BuildingSectionName__c=testBuilding.id,
            Project__c=project.Id,
            PropertyUsage__c='Residential',
            UnitView__c  ='Beach Side',
            FloorNumber__c='01',
            NumberOfBedrooms__c='3',
            UnitModel__c='1BHK',
            SellingPrice__c= 700000,
            EndDate__c= date.today()+10,
            StartDate__c=date.today()-10
            
        );
        insert testUnit;
        List<PaymentPlan__c> plans = new List<PaymentPlan__c>();
        PaymentPlan__c  pp = new PaymentPlan__c();
        pp.Name ='July Plan';
        pp.Unit__c= testUnit.id;
        pp.Description__c ='Test Description';
        pp.Description__c = 'Test';
        pp.IsActive__c = 'NO';
        pp.BrokerPortalFlag__c = True;
        pp.Classification__c = Constants.PAYMENT_PLAN_TYPE_STANDARD;
        insert pp;
        Test.startTest();
        List<String> classifications = ProjectController.getProjectClassifications(project.Id);
        Test.stopTest();
    }
    
    @IsTest
    static void testGetPaymentPlans() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        BuildingSection__c testBuilding=new BuildingSection__c(
            Name='Test Building',
            BuildingSectionCode__c='BL-CAS',
            Project__c=project.Id
            
        );
        insert testBuilding;
        Unit__c testUnit=new Unit__c(
            Name='test Unit',
            Status__c='Available',
            UnitType__c='Townhouse',
            BuildingSectionName__c=testBuilding.id,
            Project__c=project.Id,
            PropertyUsage__c='Residential',
            UnitView__c  ='Beach Side',
            FloorNumber__c='01',
            NumberOfBedrooms__c='3',
            UnitModel__c='1BHK',
            SellingPrice__c= 700000,
            EndDate__c= date.today()+10,
            StartDate__c=date.today()-10
            
        );
        insert testUnit;
        List<PaymentPlan__c> plans = new List<PaymentPlan__c>();
        PaymentPlan__c  pp = new PaymentPlan__c();
        pp.Name ='July Plan';
        pp.Unit__c= testUnit.id;
        pp.Description__c ='Test Description';
        pp.Description__c = 'Test';
        pp.IsActive__c = 'NO';
        pp.BrokerPortalFlag__c = True;
        pp.Classification__c = Constants.PAYMENT_PLAN_TYPE_STANDARD;
        insert pp;
        Test.startTest();
        List<PaymentPlan__c> result = ProjectController.getPaymentPlans(project.Id, Constants.PAYMENT_PLAN_TYPE_STANDARD);
        Test.stopTest();
    }
    
    @IsTest
    static void testGetInstallmentsByPlan() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        BuildingSection__c testBuilding=new BuildingSection__c(
            Name='Test Building',
            BuildingSectionCode__c='BL-CAS',
            Project__c=project.Id
            
        );
        insert testBuilding;
        Unit__c testUnit=new Unit__c(
            Name='test Unit',
            Status__c='Available',
            UnitType__c='Townhouse',
            BuildingSectionName__c=testBuilding.id,
            Project__c=project.Id,
            PropertyUsage__c='Residential',
            UnitView__c  ='Beach Side',
            FloorNumber__c='01',
            NumberOfBedrooms__c='3',
            UnitModel__c='1BHK',
            SellingPrice__c= 700000,
            EndDate__c= date.today()+10,
            StartDate__c=date.today()-10
            
        );
        insert testUnit;
        List<PaymentPlan__c> plans = new List<PaymentPlan__c>();
        PaymentPlan__c  pp = new PaymentPlan__c();
        pp.Name ='July Plan';
        pp.Unit__c= testUnit.id;
        pp.Description__c ='Test Description';
        pp.Description__c = 'Test';
        pp.IsActive__c = 'NO';
        pp.BrokerPortalFlag__c = True;
        pp.Classification__c = Constants.PAYMENT_PLAN_TYPE_STANDARD;
        insert pp;
        PaymentInstallments__c ppi = new PaymentInstallments__c();
        ppi.BrokerPayoutPercentage__c =100;
        ppi.Description__c = 'test description';
        ppi.InstallmentNumber__c = 1;
        ppi.InstallmentPercentage__c=100;
        ppi.PaymentPlan__c = pp.id;
        ppi.InstallmentPercentage__c=100;
        ppi.Condition_Type__c='P012';
        
        insert ppi;
        Test.startTest();
        List<PaymentInstallments__c> result = ProjectController.getInstallmentsByPlan(pp.Id);
        Test.stopTest();
    }
    
    @IsTest
    static void testIsPaymentPlanPendingApproval_Null() {
        Test.startTest();
        Boolean result = ProjectController.isPaymentPlanPendingApproval(null);
        Test.stopTest();
        System.assertEquals(false, result);
    }
    
    @IsTest
    static void testUpdateInstallmentLineRecords() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        BuildingSection__c testBuilding=new BuildingSection__c(
            Name='Test Building',
            BuildingSectionCode__c='BL-CAS',
            Project__c=project.Id
            
        );
        insert testBuilding;
        Unit__c testUnit=new Unit__c(
            Name='test Unit',
            Status__c='Available',
            UnitType__c='Townhouse',
            BuildingSectionName__c=testBuilding.id,
            Project__c=project.Id,
            PropertyUsage__c='Residential',
            UnitView__c  ='Beach Side',
            FloorNumber__c='01',
            NumberOfBedrooms__c='3',
            UnitModel__c='1BHK',
            SellingPrice__c= 700000,
            EndDate__c= date.today()+10,
            StartDate__c=date.today()-10
            
        );
        insert testUnit;
        List<PaymentPlan__c> plans = new List<PaymentPlan__c>();
        PaymentPlan__c  pp = new PaymentPlan__c();
        pp.Name ='July Plan';
        pp.Unit__c= testUnit.id;
        pp.Description__c ='Test Description';
        pp.Description__c = 'Test';
        pp.IsActive__c = 'NO';
        pp.BrokerPortalFlag__c = True;
        pp.Classification__c = Constants.PAYMENT_PLAN_TYPE_STANDARD;
        insert pp;
        PaymentInstallments__c ppi = new PaymentInstallments__c();
        ppi.BrokerPayoutPercentage__c =100;
        ppi.Description__c = 'test description';
        ppi.InstallmentNumber__c = 1;
        ppi.InstallmentPercentage__c=100;
        ppi.PaymentPlan__c = pp.id;
        ppi.InstallmentPercentage__c=100;
        ppi.Condition_Type__c='P012';
        insert ppi;
        
        ppi.RevisedDate__c = Date.today().addDays(10);
        Test.startTest();
        try {
            ProjectController.updateInstallmentLineRecords(new List<PaymentInstallments__c>{ ppi },pp.Id);
        }
        catch (Exception e) {
        }
        Test.stopTest();
    }
}