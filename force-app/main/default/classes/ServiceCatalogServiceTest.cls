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
        servCatalogRec.getServiceCatalogByName('Service-Request-Default-Unit');
        servCatalogRec.getServiceCatalogCategories('Service Request');
        servCatalogRec.getServiceCatalogSubCategories('Service Request','Financial - Payment Service');
        servCatalogRec.getServiceCatalogBySubCategories('Postpone/Defer Payment');
        servCatalogRec.getServActionsByTasks(new List<String>(), new List<String>());
        servCatalogRec.getNextCaseServiceAction(csList);
        servCatalogRec.getCurrentCaseServiceAction(csList);
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
}