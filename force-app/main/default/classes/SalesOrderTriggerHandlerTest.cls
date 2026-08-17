@isTest
public class SalesOrderTriggerHandlerTest {
    
    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Unit__c unt = new Unit__c(Name = 'Unit Test A1435', Status__c = 'Unassigned');
        insert unt;
        
        SalesOrder__c salesOrd = new SalesOrder__c(
            Name = 'Test SalesOrder',
            Account__c = acc.Id,
            Status__c = 'Booked'
        );
        insert salesOrd;
        
        SalesOrder__c salesOrd1 = new SalesOrder__c(
            Name = 'Test SalesOrder T',
            Account__c = acc.Id,
            Status__c = 'Booked'
        );
        insert salesOrd1;
        delete [select id, Name from SalesOrder__c  where name='Test SalesOrder T'];
        
        List<Handover__c> handovers = new List<Handover__c>();
        Handover__c hand = new Handover__c(
            Name = 'test handover',
            Sales_Order__c = salesOrd.Id,
            Unit__c = unt.Id,  
            Sub_Status__c = 'Cancelled',
            Is_Manual__c = 'Yes'
        );
        insert hand;
    }
    
    @isTest
    public static void ownersinguponsalesorderstatusTest(){
        SalesOrder__c sale = [SELECT Id, Name, Status__c FROM SalesOrder__c WHERE Name = 'Test SalesOrder'];
        sale.Status__c = 'Cancelled';
        Test.startTest();
        update sale;
        Test.stopTest();
        
        SalesOrder__c updatedSale = [SELECT Id, Status__c FROM SalesOrder__c WHERE Id = :sale.Id];
        System.assertEquals('Cancelled', updatedSale.Status__c);
    }
    
    @isTest
    public static void ownersinguponsalesorderstatusTest2(){
        SalesOrder__c sale = [SELECT Id, Name, Status__c FROM SalesOrder__c WHERE Name = 'Test SalesOrder'];
        sale.Status__c = 'Sold';
        Test.startTest();
        update sale;
        Test.stopTest();
        
        SalesOrder__c updatedSale = [SELECT Id, Status__c FROM SalesOrder__c WHERE Id = :sale.Id];
        System.assertEquals('Sold', updatedSale.Status__c);
        
        sale.Status__c = 'Booked';
        sale.SubStatus__c = 'Document Issued';
        update sale;
    }
        
    @isTest
    static void Testmethod1(){
        Test.startTest();
        //Test data for Project__c and related Units
        // Test data for Project__c and related Units
        Account account = TestDataFactory.createPersonalAccount('Lastname', '01010101', '1234567890', 'test@gmail.com');
        account.CustomerType__c = 'Resident';
        INSERT account;
        
        //Test data for Project__c and related Units
        Project__c project = TestDataFactory.createProject('ProjectTest', Date.today() - 1);
        insert project;
        
        Unit__c u = TestDataFactory.createUnit(project.Id, 'A1-G01', 'Unassigned');
        u.Project__c = project.Id;
        u.RegistrationDate__c = Date.today();
        insert u;
        
        Opportunity opp = TestDataFactory.createOpportunity(account.Id,null,null,null,null,null,null,null);
        opp.Sale_Type__c = 'Resale';
        insert opp;
        
        SalesOrder__c salesOrder = TestDataFactory.createSalesOrder(account.Id, opp.Id, null, null, u.Id, 100.00);
        salesOrder.DocumentUploadedDate__c = Date.today() - 1;
        salesOrder.UnitRegistrationDate__c = Date.today();
        insert salesOrder;
        salesOrder.Status__c = 'Sold';
        salesOrder.IsDraftOrder__c = false;
        update salesOrder;
        salesOrder.Bloom_Signed_SPA_Date__c = Date.today()+2;
        update salesOrder;
       delete salesOrder;
        undelete salesOrder;
    }
    
    @isTest
    static void Testmethod2(){
        Test.startTest();
        //Test data for Project__c and related Units
        // Test data for Project__c and related Units
        Account account = TestDataFactory.createPersonalAccount('Lastname', '01010101', '1234567890', 'test@gmail.com');
        account.CustomerType__c = 'Resident';
        INSERT account;
        
        //Test data for Project__c and related Units
        Project__c project = TestDataFactory.createProject('ProjectTest', Date.today() - 1);
        insert project;
        
        Unit__c u = TestDataFactory.createUnit(project.Id, 'A1-G01', 'Unassigned');
        u.Project__c = project.Id;
        u.RegistrationDate__c = Date.today();
        insert u;
        
        Opportunity opp = TestDataFactory.createOpportunity(account.Id,null,null,null,null,null,null,null);
        opp.Sale_Type__c = 'Resale';
        insert opp;
        
        SalesOrder__c salesOrder = TestDataFactory.createSalesOrder(account.Id, opp.Id, null, null, u.Id, 100.00);
        salesOrder.DocumentUploadedDate__c = Date.today() - 1;
        salesOrder.UnitRegistrationDate__c = Date.today();
        salesOrder.Status__c = 'Cancelled';
        insert salesOrder;
        
        List<SalesOrder__c> SoList = [SELECT Id,Unit__c,Status__c,Sale_Type__c FROM SalesOrder__c WHERE Status__c = 'Cancelled' LIMIT 1];
        SalesOrderTriggerHelper.updateUnitActiveSOAfterInsert(SoList);
       
    }

}