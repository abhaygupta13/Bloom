/*****************************************************************************************
Class       : PDFQueueable Test
Author      : Vikas Baliyan
Description : PDF Queueable Test
Test Class  : 
Created Date: 17 DEC 2024 
*****************************************************************************************/
@isTest
public class PDFQueueableTest {
    @testSetup
    private static void testData() {
        Integer i;
        List<Project__c> projectList = new List<Project__c>();
        Date regDateADM = date.newinstance(2024, 10, 01);
        for(i = 0; i < 20; i++){ 
            Project__c project = TestDataFactory.createProject('Project Test', Date.newinstance(2024, 01, 01), Date.newInstance(2025, 01, 01), Date.newInstance(2025, 01, 15), Date.newInstance(2025, 01, 16), Date.newInstance(2025, 01, 30), Date.newInstance(2025, 02, 01));
            projectList.add(project);
        }
        insert projectList;

        Account acc = TestDataFactory.createBrokerAccount('test', false, '1122334455');
        insert acc;

        Contact con = TestDataFactory.createContact('test', acc.Id, true, 'test@gmail.com');
        insert con;

        Opportunity opp = TestDataFactory.createOpportunity(null, null,null, acc.Id, null, null, null, null);
        insert opp;

        List<CommissionSchedule__c> comSchList = new List<CommissionSchedule__c>();
        CommissionSchedule__c comSchedule1 = TestDataFactory.createCommissionSchedule(projectList[0].Id, 6, 0, 500000);
        CommissionSchedule__c comSchedule2 = TestDataFactory.createCommissionSchedule(projectList[0].Id, 6, 500001, 999999999);
        comSchList.add(comSchedule1); comSchList.add(comSchedule2);
        insert comSchList;

        Unit__c unit = TestDataFactory.createUnit(projectList[0].Id, 'Test unit', 'Sold');
        insert unit;

        SalesOrder__c salesOrder = TestDataFactory.createSalesOrder(acc.Id, opp.Id, 'Sold', date.newinstance(2025, 01, 10), unit.Id, 18181818);
        insert salesOrder;

        PaymentPlan__c paymentPlan = TestDataFactory.createPaymentPlan('Test Plan');
        insert paymentPlan;

        List<PaymentInstallments__c> paymentInstallmentsList = new List<PaymentInstallments__c>();
        PaymentInstallments__c paymentInstallments1 = TestDataFactory.createPaymentInstallment(paymentPlan.Id, 1, 6);
        PaymentInstallments__c paymentInstallments2 = TestDataFactory.createPaymentInstallment(paymentPlan.Id, 2, 6);
        paymentInstallmentsList.add(paymentInstallments1); paymentInstallmentsList.add(paymentInstallments2);
        insert paymentInstallmentsList;

        List<InstallmentLines__c> installmentLinesList = new List<InstallmentLines__c>();
        InstallmentLines__c installmentLines1 = TestDataFactory.createInstallmentLines(salesOrder.Id, 50500, 50500 , 1, paymentPlan.Id, paymentInstallmentsList[0].Id);
        installmentLinesList.add(installmentLines1);
        InstallmentLines__c installmentLines2 = TestDataFactory.createInstallmentLines(salesOrder.Id, 50500, 50500 , 2, paymentPlan.Id, paymentInstallmentsList[1].Id);
        installmentLinesList.add(installmentLines2);
        insert installmentLinesList;

        List<DocumentType__c> docTypeList = new List<DocumentType__c>();
        DocumentType__c docType1 = TestDataFactory.createDocumentType('Broker Commission','Generated Invoice');
        docTypeList.add(docType1);
        DocumentType__c docType2 = TestDataFactory.createDocumentType('Broker Commission','Broker Form');
        docTypeList.add(docType2);
        insert docTypeList;

        List<BrokerCommission__c> brokerCommissionList = new List<BrokerCommission__c>();
        BrokerCommission__c bc = TestDataFactory.createBrokerCommission(null, null, null, null, null, projectList[0].Id, salesOrder.Id, acc.Id, con.Id, comSchList[0].Id);
        bc.Status__c = 'Draft';
        brokerCommissionList.add(bc);
        BrokerCommission__c bc2 = TestDataFactory.createBrokerCommission(null, null, null, null, null, projectList[0].Id, salesOrder.Id, acc.Id, con.Id, comSchList[0].Id);
        bc2.Status__c = 'Shared';
        brokerCommissionList.add(bc2);
        insert brokerCommissionList;
    }
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/pdf');
            res.setBodyAsBlob(Blob.valueOf('Mock PDF Content'));
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    private static void testBrokerInvoice(){
        List<InstallmentLines__c> installmetnList = [SELECT Id, SalesOrder__r.Unit__r.DARIRegistration__c, ClearedAmount__c, BrokerCommissionCreated__c, InstallmentNumber__c, SalesOrder__r.Broker_Agency__c, SalesOrder__r.Status__c, SalesOrder__r.SoldDate__c FROM InstallmentLines__c];
        List<SalesOrder__c> salesOrder = [SELECT Id, Broker_Agency__c, Status__c, SoldDate__c,Unit__r.DARIRegistration__c FROM SalesOrder__c];
        List<Unit__c> unitList = [SELECT Id,DARIRegistration__c FROM Unit__c];
        List<BrokerCommission__c> commissionList = [SELECT Id,Name FROM BrokerCommission__c];
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.StartTest();
        	System.enqueueJob(new PDFQueueable(commissionList ,BrokerCommission__c.SObjectType , 'Broker Invoice' ));
        Test.StopTest();
        List<BrokerCommission__c> brokerCommissionList = [SELECT Id, CommissionAmount__c FROM BrokerCommission__c];
        Assert.areEqual(2,brokerCommissionList.size(),'Their should be 2 records');
        delete brokerCommissionList[0];
        List<BrokerCommission__c> brokerCommissionList2 = [SELECT Id, CommissionAmount__c FROM BrokerCommission__c];
        Assert.areEqual(1,brokerCommissionList2.size(),'Their should be 1 records');
    }

    @isTest
    private static void testBrokerForm(){
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());      
        Test.StartTest();
            List<Contact> conList = [SELECT Id,ReceiveInvoiceCommunication__c FROM Contact];
            conList[0].ReceiveInvoiceCommunication__c = true;
            update conList;
            List<BrokerCommission__c> brokerCommissionList = [SELECT Id, FirstApprovalStatus__c, SecondApprovalStatus__c FROM BrokerCommission__c];
            brokerCommissionList[0].SecondApprovalStatus__c = 'Approved';
            brokerCommissionList[0].Status__c = 'Paid';
            update brokerCommissionList[0];
        Test.StopTest();     
        List<IntegrationRecord__c> integrationRecordList = [SELECT Id FROM IntegrationRecord__c];
        Assert.areEqual(1,integrationRecordList.size(),'Their should be 1 records');
    }
}