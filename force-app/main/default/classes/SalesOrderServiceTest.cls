@isTest
public class SalesOrderServiceTest {
    
    @TestSetup
    static void setupTestData(){
        
        // Test data for Project__c and related Units
        Account account = TestDataFactory.createPersonalAccount('Lastname', '01010101', '1234567890', 'test@gmail.com');
        account.CustomerType__c = 'Resident';
        INSERT account;
        
        Account acc = TestDataFactory.createBrokerAccount('test', false, '1122334455');
        insert acc;
        
        //Test data for Project__c and related Units
        Project__c project = TestDataFactory.createProject('ProjectTest', Date.today() - 1);
        insert project;
        
        Unit__c u = TestDataFactory.createUnit(project.Id, 'A1-G01', 'Unassigned');
        u.Project__c = project.Id;
        u.RegistrationDate__c = Date.today();
        insert u;
        
        Opportunity opp = TestDataFactory.createOpportunity(null, null,null, acc.Id, null, null, null, null);
        opp.ADHAApplicationNumber__c = '123456';
        opp.ADHAStatus__c = 'Init';
        insert opp;
        
        SalesOrder__c salesOrder = TestDataFactory.createSalesOrder(account.Id, opp.Id, null, null, u.Id, 100.00);
        //salesOrder.DocumentUploadedDate__c = Date.today();
        salesOrder.UnitRegistrationDate__c = Date.today();
        salesOrder.Status__c='Sold';
        insert salesOrder;
        
        DocumentType__c dc1 = TestDataFactory.createDocumentType('Sales Order', 'Emirates ID');
        INSERT dc1;
        DocumentType__c dc2 = TestDataFactory.createDocumentType('Sales Order' , 'Passport');
        INSERT dc2;
        DocumentType__c dc3 = TestDataFactory.createDocumentType('Sales Order', 'SPA - Signed');
        INSERT dc3;
        
        Document__c testDocument = TestDataFactory.createDoc(dc1.Id, salesOrder.Id, null);
        testDocument.Document_Name__c = 'Emirates ID';
        testDocument.ContentDocumentId__c = '001001';
        insert testDocument;
        // Create test Document__c record
        Document__c testDocument2 = TestDataFactory.createDoc(dc2.Id, salesOrder.Id, null);
        testDocument.Document_Name__c = 'Passport';
        testDocument2.ContentDocumentId__c = '001002';
        insert testDocument2;
        // Create test Document__c record
        Document__c testDocument3 = TestDataFactory.createDoc(dc3.Id, salesOrder.Id, null);
        testDocument.Document_Name__c = 'SPA - Signed';
        testDocument3.ContentDocumentId__c = '001003';
        insert testDocument3;
        
    }
    
    @isTest
    static void Testmethod1(){
        SalesOrderService service = SalesOrderService.getInstance();
        
        List<SalesOrder__c> soList = [SELECT Id, Unit__c FROM SalesOrder__c LIMIT 1];
        List<Opportunity> oppList = [SELECT Id FROM Opportunity LIMIT 1];
        List<Account> acc = [SELECT Id FROM Account];
        List<Project__c> projectList = [SELECT Id FROM Project__c];
        Test.startTest();
        List<SalesOrder__c> soLists = service.updateSalesOrders(soList);
        List<SalesOrder__c> soListTWO = service.getSalesOrdersNOtherChargesByIds(new Set<Id>{acc[0].Id},new Set<Id>{projectList[0].Id}, 10000);
        SalesOrder__c soRec = service.getSalesOrderByUnit(soList[0].Unit__c);
        List<SalesOrder__c> soListTHREE = service.getSalesOrderByUnitIds(new Set<Id>{soList[0].Unit__c});
        List<SalesOrder__c> soListOpp = service.getSalesOrdersByOppIds(new Set<Id>{oppList[0].Id});
        SalesOrder__c so = service.getSalesOrderById(soList[0].Id);
        List<SalesOrder__c> activeSOList = service.getActiveSalesOrdersByAccountId(acc[0].Id);
        Test.stopTest();
        
        System.assertEquals(1, soLists.size(), 'Size should match');
        
    }

    
    @isTest
    static void Testmethod2and3(){
        SalesOrderService service = SalesOrderService.getInstance();
        
        List<SalesOrder__c> soList = [SELECT Id FROM SalesOrder__c LIMIT 1];
        Set<Id> soSet = new Set<Id>();
        for(SalesOrder__c soL :soList ){
            soSet.add(soL.Id);
        }
        Test.startTest();
        List<SalesOrder__c> soLists1 = service.getSalesOrdersByIds(soSet); 
        List<SalesOrder__c> soLists2 = service.getUnitRegisteredSalesOrders(soSet); 
        List<SalesOrder__c> soLists3 = service.getNewSalesOrdersByIds(soSet);
        SalesOrder__c soRec = service.getSalesOrdersById(soList[0].Id);
        Test.stopTest();
        
        System.assertEquals(1, soLists1.size(), 'Size should match');
        
    }
    
    @isTest
    static void Testmethod4(){
        SalesOrderService service = SalesOrderService.getInstance();
        
        List<SalesOrder__c> soList = [SELECT Id FROM SalesOrder__c LIMIT 1];
        Test.startTest();
        List<SalesOrder__c> soLists = service.getSalesOrdersWithDocuments(new List<String>{soList[0].id}); 
        Test.stopTest();
        
        System.assertEquals(1, soLists.size(), 'Size should match');
        
    }
    
    @isTest
    static void testGetSalesOrder(){
        SalesOrderService service = SalesOrderService.getInstance();
        
        List<SalesOrder__c> soList = [SELECT Id, DocumentUploadedDate__c FROM SalesOrder__c LIMIT 1];
        System.debug('soList ---------->:' + soList);
        Test.startTest();
        List<SalesOrder__c> soLists = service.getSalesOrders(new List<String>{soList[0].id}, soList[0].DocumentUploadedDate__c); 
        Test.stopTest();
        
        System.assertEquals(1, soLists.size(), 'Size should match');
        
    }
    
    @isTest
    static void testGetSalesOrdersWithDocuments(){
        SalesOrderService service = SalesOrderService.getInstance();
        
        List<SalesOrder__c> soList = [SELECT Id, DocumentUploadedDate__c FROM SalesOrder__c LIMIT 1];
        System.debug('soList ---------->:' + soList);
        Test.startTest();
        List<SalesOrder__c> soLists = service.getSalesOrdersWithDocuments(new List<String>{soList[0].id}); 
        Test.stopTest();
        
        System.assertEquals(1, soLists.size(), 'Size should match');
        
    }
    
    @isTest
    static void testUpdateDocumentUploadDate() {
        List<SalesOrder__c> soLists = [SELECT Id, DocumentUploadedDate__c, Account__r.CustomerType__c, 
                                       (SELECT Id, DocumentType__r.Type__c FROM Documents__r)
                                       FROM SalesOrder__c LIMIT 1];
        System.debug('soLists -------> ' +soLists);
        
        Test.startTest();
        SalesOrderService service = SalesOrderService.getInstance();
        service.updateDocumentUploadDate(new Set<String>{soLists[0].id});
        //Test.stopTest();
        
        
        //Account acc = [SELECT Id, CustomerType__c,(SELECT Id,DocumentType__r.Type__c FROM Document__c WHERE DocumentType__r.Type__c = 'Passport') FROM Account WHERE DocumentType__c = 'Passport' LIMIT 1];
        Account acc = [select id from Account limit 1];
        acc.CustomerType__c = 'GCC';
        update acc;
        
        //List<SalesOrder__c> soLists2 = [SELECT Id, DocumentUploadedDate__c, Account__r.CustomerType__c, 
        //(SELECT Id, DocumentType__r.Type__c FROM Documents__r)
        //FROM SalesOrder__c LIMIT 1];
        List<Document__c> soLists2 = [SELECT Id, Account__r.CustomerType__c,DocumentType__r.Type__c, SalesOrder__c,SalesOrder__r.Account__r.CustomerType__c FROM Document__c where SalesOrder__c!=null];
        
        System.debug('soLists2'+soLists2[1].SalesOrder__r.Account__r.CustomerType__c);
        //Test.startTest();
        service.updateDocumentUploadDate(new Set<String>{soLists2[1].SalesOrder__c});
        Test.stopTest();
        
    }
    /*@isTest
static void testGetSoldSalesOrdersByAccountIds(){
SalesOrderService service = SalesOrderService.getInstance();

Account acc = [select id,Status__c from Account limit 1];

Test.startTest();
List<SalesOrder__c> soLists = service.getSoldSalesOrdersByAccountIds(new Set<Id>{acc.id}); 
Test.stopTest();

System.assertEquals(1, soLists.size(), 'Size should match');

}*/
    @isTest
    static void testGetSalesOrdersMap(){
        SalesOrderService service = SalesOrderService.getInstance();
        
        List<SalesOrder__c> soList = [SELECT Id, DocumentUploadedDate__c FROM SalesOrder__c LIMIT 1];
        
        Test.startTest();
        Map<ID, SalesOrder__c> soMap = service.getSalesOrdersMap(new Set<Id>{soList[0].id}); 
        Test.stopTest();
        
        System.assertEquals(1, soMap.size(), 'Size should match');
        
    }
    
    @isTest
    static void testGetSalesOrdersWithInstallment(){
        SalesOrderService service = SalesOrderService.getInstance();
        
        List<SalesOrder__c> soList = [SELECT Id, DocumentUploadedDate__c FROM SalesOrder__c LIMIT 1];
        
        Test.startTest();
        List<SalesOrder__c> soLists = service.getSalesOrdersWithInstallment(new Set<Id>{soList[0].id}); 
        Test.stopTest();
        
        System.assertEquals(1, soLists.size(), 'Size should match');
        
    }
    @isTest
    static void testPrepareIntegrationRecord(){
        SalesOrderService service = SalesOrderService.getInstance();
        SalesOrder__c salesOrder = [SELECT Id, DocumentUploadedDate__c FROM SalesOrder__c LIMIT 1];
        List<SalesOrder__c> soList = service.getADHASalesOrders(new Set<Id>{salesOrder.Id});
        
        Test.startTest();
        IntegrationRecord__c integrationRec = service.prepareIntegrationRecord(soList[0]); 
        Test.stopTest();
        Assert.areEqual('123456',integrationRec.Param1__c,'param1 should be 123456');
        
    }
    
    @isTest
    static void testUpdateSalesOrdersWithoutTrigger(){
        SalesOrderService service = SalesOrderService.getInstance(); 
        Test.startTest();
        List<SalesOrder__c> soList = [SELECT Id, Status__c FROM SalesOrder__c LIMIT 1];
        soList[0].Status__c = 'Cancelled';
        List<SalesOrder__c> soLists = service.updateSalesOrdersWithoutTrigger(soList); 
        Test.stopTest();
        System.assertEquals('Cancelled', soLists[0].Status__c, 'Status should match');   
    }
    
    @isTest
    static void testGetSalesOrderMultiple(){
        SalesOrderService service = SalesOrderService.getInstance(); 
        Test.startTest();
        List<SalesOrder__c> soList = [SELECT Id, Status__c FROM SalesOrder__c LIMIT 1];
        Set<Id> salesOrderIdSet = new Set<Id>{soList[0].Id};
        service.getSalesOrderWithInstallmentAndReceiptAllocation(String.valueOf(soList[0].Id));
        service.getSalesOrderWithInstallmentLinesReceiptAllocation(String.valueOf(soList[0].Id));
        service.getSalesOrdersWithJointOwner(salesOrderIdSet);
        service.getSalesOrdersWithOpportunityAndAgency(salesOrderIdSet);
        Test.stopTest();  
    }
    
}