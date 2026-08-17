/*****************************************************************************************
Class       : ApprovalController Test
Author      : Vikas Baliyan
Description : Approval Controller Test
Test Class  : 
Created Date: 17 DEC 2024 
*****************************************************************************************/
@isTest
public class ApprovalControllerTest {
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

        ContentVersion cv = TestDataFactory.createContentVersion('test data', 'Invoice', 'Invoice');
        insert cv;
    }

    @IsTest
    static void testSendApprovalForDraft(){  
        Test.startTest();
        // Fetching Commission Invoice
        BrokerCommission__c broker = [SELECT Id, Status__c From BrokerCommission__c WHERE Status__c = 'Draft' LIMIT 1];
        // Calling Send Approval
        String msg = ApprovalController.sendApproval(broker.Id, 'Test Comment');
        Test.stopTest();
        Assert.areEqual('Record has been send for approval successfully!', msg, 'Approval process not triggered');
        
    }

     @IsTest
    static void testSendApprovalForCommissionSchedule(){  
        Test.startTest();
        // Fetching Commission Invoice
        CommissionSchedule__c cs = [SELECT Id, ApprovalStatus__c From CommissionSchedule__c LIMIT 1];
        // Calling Send Approval
        String msg = ApprovalController.sendApproval(cs.Id, 'Test Comment');
        Test.stopTest();
        Assert.areEqual('Record has been send for approval successfully!', msg, 'Approval process not triggered');
        
    }

   

    @IsTest
    static void testSendApprovalForPostedError(){ 
        String msg = ''; 
        Test.startTest();
        List<BrokerCommission__c> broker = [SELECT Id FROM BrokerCommission__c WHERE Status__c = 'Shared' LIMIT 1];
        // Calling Send Approval
        msg = ApprovalController.sendApproval(broker[0].Id, 'Test Comment');
        Test.stopTest();
        Assert.areEqual('Please upload the Broker Invoice before submitting for Financial Approval.', msg, 'Approval process should not be triggered');
    }
    
    @IsTest
    static void testSendApprovalForFinalApproval(){ 
        String msg = ''; 
        Test.startTest();
        List<BrokerCommission__c> broker = [SELECT Id FROM BrokerCommission__c WHERE Status__c = 'Payment Initiated' LIMIT 1];
        // Calling Send Approval
        msg = ApprovalController.sendApproval(broker[0].Id, 'Test Comment');
        Test.stopTest();
        Assert.areEqual('', msg, 'Approval process should not be triggered');
    }

    @IsTest
    static void testSendApprovalForFinalApprovalValidation(){
        String msg = '';
        BrokerCommission__c broker = [SELECT Id, Status__c, SecondApprovalStatus__c FROM BrokerCommission__c WHERE Status__c = 'Draft' LIMIT 1];
        broker.Status__c = 'Posted';
        broker.SecondApprovalStatus__c = 'Approved';
        update broker;

        Test.startTest();
        msg = ApprovalController.sendApproval(broker.Id, 'Test Comment');
        Test.stopTest();

        Assert.areEqual('Record has been send for approval successfully!', msg, 'Final approval should not be submitted unless second approval is Approved and status is Posted.');
    }
}