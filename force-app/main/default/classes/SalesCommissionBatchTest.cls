/*****************************************************************************************
Class       : SalesCommissionBatchTest
Author      : Vikas Baliyan
Description : Sales Commission Batch Test
Test Class  : 
Created Date: 03 NOV 2024 
*****************************************************************************************/
@isTest
public class SalesCommissionBatchTest {
    @testSetup
    private static void testData() {
        Integer i;
        List<Project__c> projectList = new List<Project__c>();
        Date regDateADM = date.newinstance(2024, 10, 01);
        for(i = 0; i < 20; i++){ 
            Project__c project = TestDataFactory.createProject('Project Test', Date.newinstance(2024, 01, 01), Date.newInstance(2025, 01, 01), Date.newInstance(2025, 01, 15), Date.newInstance(2025, 01, 16), Date.newInstance(2025, 01, 30), Date.newInstance(2025, 02, 01));
            project.ApplyADRECBrokerCommissionPolicy__c = true;
            projectList.add(project);
        }
        insert projectList;

        Account acc = TestDataFactory.createBrokerAccount('test', false, '1122334455');
        insert acc;
        
        Account acc2 = TestDataFactory.createBrokerAccount('testBroker', false, '1122334455');
        insert acc2;

        Opportunity opp = TestDataFactory.createOpportunity(null, null,null, acc.Id, null, null, null, null);
        insert opp;
        
        Opportunity opp2 = TestDataFactory.createOpportunity(null, null,null, acc2.Id, null, null, null, null);
        insert opp2;

        List<CommissionSchedule__c> comSchList = new List<CommissionSchedule__c>();
        CommissionSchedule__c comSchedule1 = TestDataFactory.createCommissionSchedule(projectList[0].Id, 6, 0, 500000);
        comSchedule1.ApprovalStatus__c = 'Approved';
        CommissionSchedule__c comSchedule2 = TestDataFactory.createCommissionSchedule(projectList[0].Id, 6, 500001, 999999999);
        comSchedule2.ApprovalStatus__c = 'Approved';
        CommissionSchedule__c comSchedule3 = TestDataFactory.createCommissionSchedule(null, 6, 500001, 999999999);
        comSchedule3.ApprovalStatus__c = 'Approved';comSchedule3.BrokerAccount__c = acc2.Id;
        comSchedule1.LaunchType__c = 'Post Launch';comSchedule2.LaunchType__c = 'Post Launch';comSchedule3.LaunchType__c = 'Post Launch';
        comSchedule1.StartDate__c = date.newinstance(2025, 01, 10); comSchedule2.StartDate__c = date.newinstance(2025, 01, 10);
        comSchList.add(comSchedule1); comSchList.add(comSchedule2);comSchList.add(comSchedule3);
        insert comSchList;

        Unit__c unit = TestDataFactory.createUnit(projectList[0].Id, 'Test unit', 'Sold');
        insert unit;
        
        Unit__c unit2 = TestDataFactory.createUnit(projectList[1].Id, 'Test unit2', 'Sold');
        insert unit2;

        SalesOrder__c salesOrder = TestDataFactory.createSalesOrder(acc.Id, opp.Id, 'Sold', date.newinstance(2025, 02, 10), unit.Id, 18181818);
        salesOrder.ADM_DLD_Pre_Registered_Date__c= Date.today();
        insert salesOrder;
        
        SalesOrder__c salesOrder2 = TestDataFactory.createSalesOrder(acc2.Id, opp2.Id, 'Sold', date.newinstance(2025, 02, 10), unit2.Id, 18181818);
        salesOrder2.ADM_DLD_Pre_Registered_Date__c= Date.today();
        insert salesOrder2;
        
        SalesOrder__c salesOrder3 = TestDataFactory.createSalesOrder(acc2.Id, opp2.Id, 'Sold', date.newinstance(2025, 02, 10), unit2.Id, 18181818);
        insert salesOrder3;

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
        InstallmentLines__c installmentLines3 = TestDataFactory.createInstallmentLines(salesOrder2.Id, 50500, 50500 , 1, paymentPlan.Id, paymentInstallmentsList[1].Id);
        installmentLinesList.add(installmentLines3);
        InstallmentLines__c installmentLines4 = TestDataFactory.createInstallmentLines(salesOrder3.Id, 50500, 50500 , 1, paymentPlan.Id, paymentInstallmentsList[0].Id);
        installmentLinesList.add(installmentLines4);
        insert installmentLinesList;

        DocumentType__c docType = TestDataFactory.createDocumentType('Broker Commission','Generated Invoice');
        insert docType;

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
    private static void testBatchable(){
        List<InstallmentLines__c> installmetnList = [SELECT Id, SalesOrder__r.Unit__r.DARIRegistration__c, ClearedAmount__c, BrokerCommissionCreated__c, InstallmentNumber__c, SalesOrder__r.Broker_Agency__c, SalesOrder__r.Status__c, SalesOrder__r.SoldDate__c FROM InstallmentLines__c];
        List<SalesOrder__c> salesOrder = [SELECT Id, Broker_Agency__c, Status__c, SoldDate__c,Unit__r.DARIRegistration__c FROM SalesOrder__c];
        List<Unit__c> unitList = [SELECT Id,DARIRegistration__c FROM Unit__c];
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.StartTest();
            SalesCommissionBatch batchJob = new SalesCommissionBatch();
            Database.executeBatch(batchJob);
        Test.StopTest();
        List<BrokerCommission__c> brokerCommissionList = [SELECT Id, CommissionAmount__c FROM BrokerCommission__c];
        Assert.areEqual(5,brokerCommissionList.size(),'Their should be 5 records');
    }

    @isTest
    private static void testSchedule() {
        Test.startTest();
            String sch = '0 0 23 * * ?';
            SalesCommissionBatch batchJob = new SalesCommissionBatch();
            System.schedule('SalesCommissionBatch',sch,batchJob);
        Test.stopTest();
        List<AsyncApexJob> batchJobs = [SELECT Id, Status FROM AsyncApexJob WHERE ApexClass.Name = 'SalesCommissionBatch' AND JobType = 'BatchApex'];        
        System.assertEquals(1, batchJobs.size(), 'Unexpected number of batch jobs ran: ' + batchJobs);
    }
}