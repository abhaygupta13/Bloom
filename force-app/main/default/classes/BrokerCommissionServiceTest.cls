/*****************************************************************************************
Class       : BrokerCommissionServiceTest
Author      : Aman Bharti
Description : BrokerCommissionService Test
Test Class  : 
Created Date: 04 DEC 2025 
*****************************************************************************************/
@isTest
public class BrokerCommissionServiceTest {
    @testSetup
    private static void testData() {
         Account acc = TestDataFactory.createBrokerAccount('test', false, '1122334455');
        acc.Broker_Registration_Expiry_Date__c = Date.today().addDays(5);
        acc.RERACertificateExpiryDate__c = Date.today().addDays(5);
        acc.Trade_License_Expiry_Date__c = Date.today().addDays(5);
        insert acc;

        Contact con = TestDataFactory.createContact('test', acc.Id, true, 'test@gmail.com');
        insert con;

        DocumentType__c docTypeGeneratedInvoice = TestDataFactory.createDocumentType('Commission Invoice','Generated Invoice');
        insert docTypeGeneratedInvoice;
        DocumentType__c docTypeBrokerInvoice = TestDataFactory.createDocumentType('Commission Invoice','Broker Shared Invoice');
        insert docTypeBrokerInvoice;

        Project__c project = new Project__c();
        project.Name = 'TEST';
        project.ProjectRegistrationDate__c = Date.today() - 1;
        insert project;

        List<Unit__c> unitLst = new List<Unit__c>();
        for (Integer i = 0; i < 1; i++) {
            Unit__c u = TestDataFactory.createUnit(project.Id, 'A1-G01' + i, 'Unassigned');
            u.RegistrationDate__c = Date.today();
            unitLst.add(u);
        }
        insert unitLst;

        SalesOrder__c salesOrder = new SalesOrder__c();
        salesOrder.Unit__c = unitLst[0].Id;
        salesOrder.Account__c = acc.Id;
        salesOrder.DocumentUploadedDate__c = Date.today() - 1;
        insert salesOrder;

        unitLst[0].Active_Sales_Order__c = salesOrder.Id;
        update unitLst;
                
        DocumentType__c documentType = TestDataFactory.createDocumentType('Account', 'Emirates ID');
        insert documentType;
        
        DocumentType__c dc1 = TestDataFactory.createDocumentType('Broker Commission', 'Broker Shared Invoice');
        insert dc1;
        
        // Create Document
        Document__c document = TestDataFactory.createDocument(null, documentType.Id, 'test');
        insert document;

        List<CommissionSchedule__c> comSchList = new List<CommissionSchedule__c>();
        CommissionSchedule__c comSchedule1 = TestDataFactory.createCommissionSchedule(project.Id, 6, 0, 500000);
        CommissionSchedule__c comSchedule2 = TestDataFactory.createCommissionSchedule(project.Id, 6, 500001, 999999999);
        comSchList.add(comSchedule1); comSchList.add(comSchedule2);
        insert comSchList;

        List<BrokerCommission__c> brokerCommissionList = new List<BrokerCommission__c>();
        BrokerCommission__c bc = TestDataFactory.createBrokerCommission(null, null, null, null, null, project.Id, salesOrder.Id, acc.Id, con.Id, comSchedule1.Id);
        bc.Status__c = 'Draft';
        bc.BrokerInvoiceNumber__c = '123455';bc.InvoiceDate__c = Date.today();
        brokerCommissionList.add(bc);
        BrokerCommission__c bc2 = TestDataFactory.createBrokerCommission(null, null, null, null, null, project.Id, salesOrder.Id, acc.Id, con.Id, comSchedule2.Id);
        bc2.Status__c = 'Shared';bc2.InvoiceDate__c = Date.today();
        bc2.BrokerInvoiceNumber__c = '123455';
        brokerCommissionList.add(bc2);
        BrokerCommission__c bc3 = TestDataFactory.createBrokerCommission(null, null, null, null, null, project.Id, salesOrder.Id, acc.Id, con.Id, comSchedule2.Id);
        bc3.Status__c = 'Payment Initiated';bc3.InvoiceDate__c = Date.today();
        brokerCommissionList.add(bc3);
        insert brokerCommissionList;

    }



    @isTest
    private static void testGetBrokerCommission(){
        List<BrokerCommission__c> bcList = [SELECT Id,Name FROM BrokerCommission__c];
        Test.StartTest();
            List<BrokerCommission__c> brokerCommissionList = BrokerCommissionService.getInstance().getBrokerCommission(bcList);
        Test.StopTest();
        Assert.areEqual(3,brokerCommissionList.size(),'Their should be 3 records');
    }

    @isTest
    private static void testGetBrokerCommissionForPDF(){
        List<BrokerCommission__c> bcList = [SELECT Id,Name FROM BrokerCommission__c];
        Test.StartTest();
            List<BrokerCommission__c> brokerCommissionList = BrokerCommissionService.getInstance().getBrokerCommissionForPDF(bcList[0].Id);
        Test.StopTest();
        Assert.areEqual(1,brokerCommissionList.size(),'Their should be 1 records');
    }
    @isTest
    private static void testGetOnlyBrokerCommissionFields(){
        List<BrokerCommission__c> bcList = [SELECT Id,Name FROM BrokerCommission__c];
        Test.StartTest();
            BrokerCommission__c brokerCommission = BrokerCommissionService.getInstance().getOnlyBrokerCommissionFields(bcList[0].Id);
        Test.StopTest();
        Assert.areEqual(true,brokerCommission != null,'Their should be 1 records');
    }
    @isTest
    private static void testGetBrokerCommissionById(){
        List<BrokerCommission__c> bcList = [SELECT Id,Name FROM BrokerCommission__c];
        Test.StartTest();
            BrokerCommission__c brokerCommission = BrokerCommissionService.getInstance().getBrokerCommissionById(bcList[0].Id);
        Test.StopTest();
        Assert.areEqual(true,brokerCommission != null,'Their should be 1 records');
    }
    @isTest
    private static void testGetBrokerCommissionByIdList(){
        List<BrokerCommission__c> bcList = [SELECT Id,Name FROM BrokerCommission__c];
        Test.StartTest();
            List<BrokerCommission__c> brokerCommissionList = BrokerCommissionService.getInstance().getBrokerCommissionById(bcList);
        Test.StopTest();
        Assert.areEqual(3,brokerCommissionList.size(),'Their should be 3 records');
    }
    @isTest
    private static void testUpdateBrokerCommissions(){
        List<BrokerCommission__c> bcList = [SELECT Id,Name FROM BrokerCommission__c WHERE Status__c = 'Shared'];
        bcList[0].Status__c = 'Draft';
        Test.StartTest();
            List<BrokerCommission__c> brokerCommissionList = BrokerCommissionService.getInstance().updateBrokerCommissions(new List<BrokerCommission__c>{bcList[0]});
        Test.StopTest();
        Assert.areEqual('Draft',brokerCommissionList[0].Status__c,'Status should be Draft');
    }
    @isTest
    private static void testInsertBrokerCommissions(){
        List<Project__c> projectList = [SELECT Id FROM Project__c];
        BrokerCommission__c bc = TestDataFactory.createBrokerCommission(null, null, null, null, null, projectList[0].Id, null, null, null, null);
        bc.Status__c = 'Draft';
        bc.BrokerInvoiceNumber__c = '123455';bc.InvoiceDate__c = Date.today();
        Test.StartTest();
            List<BrokerCommission__c> brokerCommissionList = BrokerCommissionService.getInstance().insertBrokerCommissions(new List<BrokerCommission__c>{bc});
        Test.StopTest();
        Assert.areEqual('Draft',brokerCommissionList[0].Status__c,'Status should be Draft');
    }

     @isTest
    private static void testGetBrokerRecordsByidSet(){
        List<BrokerCommission__c> bcList = [SELECT Id,Name FROM BrokerCommission__c];
        Test.StartTest();
            List<BrokerCommission__c> brokerCommissionList = BrokerCommissionService.getInstance().getBrokerRecordsByidSet(new Set<Id>{bcList[0].Id});
        Test.StopTest();
        Assert.areEqual(1,brokerCommissionList.size(),'Their should be 1 records');
    }

    @isTest
    private static void testUpdateBrokerCommissionWithoutTrigger(){
        List<BrokerCommission__c> bcList = [SELECT Id,Name FROM BrokerCommission__c WHERE Status__c = 'Shared'];
        bcList[0].Status__c = 'Draft';
        Test.StartTest();
            List<BrokerCommission__c> brokerCommissionList = BrokerCommissionService.getInstance().updateBrokerCommissionWithoutTrigger(new List<BrokerCommission__c>{bcList[0]});
        Test.StopTest();
        Assert.areEqual('Draft',brokerCommissionList[0].Status__c,'Status should be Draft');
    }
    @isTest
    private static void testGetByInvoiceNumber(){
        List<BrokerCommission__c> bcList = [SELECT Id,Name FROM BrokerCommission__c WHERE Status__c = 'Shared'];
        bcList[0].Status__c = 'Draft';
        Test.StartTest();
            BrokerCommission__c brokerCommission = BrokerCommissionService.getInstance().getByInvoiceNumber('123455');
        Test.StopTest();
        Assert.areEqual(true,brokerCommission != null,'Their should be 1 records');
    }

    @isTest
    private static void testGetTotalCommissions() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        List<BrokerCommission__c> bcList = [
            SELECT Id, Status__c, CommissionAmount__c, SalesOrder__r.Opportunity__r.BrokerAgentContact__c
            FROM BrokerCommission__c
            LIMIT 1
        ];
        
        bcList[0].Status__c = 'Paid';
        bcList[0].CommissionAmount__c = 10000;
        update bcList;

        Test.StartTest();
            Map<Id, Decimal> result = BrokerCommissionService.getTotalCommissions(
                acc.Id,
                new Set<Id>{ con.Id },
                Date.today().addDays(-1),
                Date.today().addDays(1)
            );
        Test.StopTest();

        System.debug('Result = ' + result);
    }

    
}