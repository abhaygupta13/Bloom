@isTest
public class ServiceCatalogServiceTest {
@isTest
    static void testfetchServiceCatalogByName() {
        Test.startTest();
        ServiceCatalogService.fetchServiceCatalogByName('');
        Test.stopTest();
        
    }
    
    @isTest
    static void testfetchServices() {
        Test.startTest();
        ServiceCatalogService.fetchServices('');
        Test.stopTest();
        
    }
    
      @isTest
    static void testgetServiceCatalogFields() {
        Test.startTest();
        ServiceCatalogService.getServiceCatalogFields('');
        Test.stopTest();
        
    }
    
    
    @isTest
    static void testgetServiceCatalogAndrelatedDocuments() {
        Account acc = new Account(Name='Test Acc');
        insert acc;
         Account account = TestDataFactory.createPersonalAccount('Lastname', '01010101', '1234567890', 'test@gmail.com');
        account.CustomerType__c = 'Resident';
        INSERT account;
        
        Project__c project = TestDataFactory.createProject('ProjectTest', Date.today() - 1);
        insert project;
        
        HandoverPhase__c handoverPhase = new HandoverPhase__c(
            Name = 'Test Phase',
            Project__c = project.Id
        );
        insert handoverPhase;
        
        BuildingSection__c testBuilding = new BuildingSection__c(
            Name='Test Building',
            BuildingSectionCode__c='BL-CAS',
            Project__c= project.Id
        );
        insert testBuilding;
        
        Unit__c u = TestDataFactory.createUnit(project.Id, 'A1-G01', 'Unassigned');
        u.Project__c = project.Id;
        u.RegistrationDate__c = Date.today();
        insert u;
        
        SalesOrder__c salesOrder = TestDataFactory.createSalesOrder(account.Id, null, null, null, u.Id, 100.00);
        salesOrder.UnitRegistrationDate__c = Date.today();
        salesOrder.Status__c = 'Sold';
        insert salesOrder;
       
        
        // Create test ServiceCatalog record
        ServiceCatalog__c testServiceCatalog = new ServiceCatalog__c(
            Name = 'Test Service Catalog',
            Type__c = 'Service Request',
            Category__c = 'Financial - Payment Service',
            SubCategory__c = 'Postpone/Defer Payment',
            RecordTypeDevName__c = 'DefaultUnit'
        );
        insert testServiceCatalog;
        system.debug('testServiceCatalog----->'+testServiceCatalog);
        Set<Id> serviceCatalogIds = new Set<Id>();
        serviceCatalogIds.add(testServiceCatalog.Id);
        List<String> serviceCatalogIdList = new List<String>();
        serviceCatalogIdList.add(testServiceCatalog.Id);
        
        // Create test ServiceAction record
        ServiceAction__c testServiceAction1 = new ServiceAction__c(
            ServiceCatalog__c = testServiceCatalog.Id,
            TaskType__c = 'Default Unit',
            TaskSubType__c = 'Finance Team Task 1',
            TaskSubject__c = 'Finance Team Task 1',
            Due_in_days__c = 2,
            Order__c = 1
        );
        insert testServiceAction1;
        
        ServiceAction__c testServiceAction2 = new ServiceAction__c(
            ServiceCatalog__c = testServiceCatalog.Id,
            TaskType__c = 'Default Unit',
            TaskSubType__c = 'Legal Team Task 1',
            TaskSubject__c = 'Legal Team Task 1',
            Due_in_days__c = 2,
            Order__c = 7
        );
        insert testServiceAction2;
        
         ServiceCatalog__c  servicecatalog = new ServiceCatalog__c();
        servicecatalog.ProcessFlowType__c= 'Handover';
        servicecatalog.ProcessType__c = 'Sales';
        servicecatalog.Active__c= true;
        servicecatalog.RecordTypeDevName__c = 'Non PHPP';
        insert servicecatalog;
        
        Handover__c hoRec = new Handover__c();
        hoRec.Sales_Order__c = salesOrder.Id;
        hoRec.Unit__c = u.Id;
        hoRec.ServiceCatalog__c = servicecatalog.Id;
        hoRec.Project__c = project.Id;
        hoRec.Handover_Phase__c = handoverPhase.Id;
        insert hoRec;
       
        
        List<Integer> intList = new List<Integer>();
        intList.add(1);
        intList.add(2);
        intList.add(3);
        intList.add(4);
        intList.add(5);
        
        // prepare a Case for testing
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Default Unit').getRecordTypeId();
        // Create test Case related to the Account
        Case cs = new Case(Status = 'New', Origin = 'Phone', AccountId = acc.Id, RecordTypeId= RecordTypeCaseId, ServiceCatalog__c = testServiceCatalog.Id, Step__c = '1');
        insert cs;
        List<Case> csList = new List<Case>();
        csList.add(cs);
        
        Test.startTest();
        ServiceCatalogService.getServiceCatalogAndrelatedDocuments();
        ServiceCatalogService servCatalogRec = ServiceCatalogService.getInstance();
        servCatalogRec.getServActionsByCatalogId(serviceCatalogIds);
        servCatalogRec.getFinalServActionsByCatalogId(serviceCatalogIds);
        servCatalogRec.getServActionsByCatalogIdAndOrder(serviceCatalogIdList,intList);
        servCatalogRec.getServiceCatalogType();
        servCatalogRec.getServiceCatalog('Service Request','Financial - Payment Service','Postpone/Defer Payment');
        servCatalogRec.getServiceCatalogForBloomApp('Service Request','Financial - Payment Service','Postpone/Defer Payment');
        servCatalogRec.getServiceCatalogByName('Service-Request-Default-Unit');
        servCatalogRec.getServiceCatalogCategories('Service Request','Account');
        servCatalogRec.getServiceCatalogSubCategories('Service Request','Financial - Payment Service','Account');
        servCatalogRec.getServiceCatalogBySubCategories('Postpone/Defer Payment');
        servCatalogRec.getServActionsByTasks(new List<String>(), new List<String>());
        servCatalogRec.getNextCaseServiceAction(csList);
        servCatalogRec.getCurrentCaseServiceAction(csList);
        servCatalogRec.getCurrentAndNextHandoverServiceAction(new List<Handover__c>{hoRec});
         servCatalogRec.getHOTaskServiceActions(new List<Handover__c>{hoRec});
        Test.stopTest();
        
    }
    
    @isTest
    static void testGetPreviousCaseServiceAction(){
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Social Media').getRecordTypeId();
        Case tempCase=new Case(
            CurrencyIsoCode='AED',
            Status='Draft',
            Origin='Email',
            Main_Buyer_Share_Percentage__c=40,
            // Case_Sub_Status__c= 'Created',
            RecordTypeId=RecordTypeCaseId
        );
        insert tempCase;
        ServiceCatalogService servCatalogRec = ServiceCatalogService.getInstance();
        servCatalogRec.getPreviousCaseServiceAction(new List<Case>{tempCase});
    }
    
    @isTest
    static void testGetBySubCategory(){
        ServiceCatalogService servCatalogRec = ServiceCatalogService.getInstance();
        servCatalogRec.getBySubCategory('test','test');
    }
    @isTest
static void testGetServiceCatalogByLocation() {
    
    // Create test data
    ServiceCatalog__c sc = new ServiceCatalog__c(
        Name = 'Test Service',
        Type__c = 'Service Request',
        Category__c = 'Financial - Payment Service',
        SubCategory__c = 'Postpone/Defer Payment',
        Location__c = 'Dubai',
        RecordTypeDevName__c = 'DefaultUnit'
    );
    insert sc;

    Test.startTest();
    
    ServiceCatalogService servCatalogRec = ServiceCatalogService.getInstance();
    
    servCatalogRec.getServiceCatalogByLocation(
        'Service Request',
        'Financial - Payment Service',
        'Postpone/Defer Payment',
        'Dubai'
    );
    
    Test.stopTest();
}
}