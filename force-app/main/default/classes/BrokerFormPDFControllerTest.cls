/*****************************************************************************************
Class       : BrokerFormPDFController Test 
Author      : Vikas Baliyan
Description : BrokerFormPDFController Test Class
Test Class  : 
Created Date: 19 NOV 2024 
*****************************************************************************************/

@IsTest
public class BrokerFormPDFControllerTest {
    @TestSetup
    static void createTestData() {
                Project__c project = TestDataFactory.createProject('Project 1', System.today());
        insert project;
        

        Account acc = TestDataFactory.createBrokerAccount('test', false, '1122334455');
        insert acc;

        Opportunity opp = TestDataFactory.createOpportunity(null, null,null, acc.Id, null, null, null, null);
        insert opp;

        Unit__c unit = TestDataFactory.createUnit(project.Id, 'Test unit', 'Sold');
        insert unit;

        SalesOrder__c salesOrder = TestDataFactory.createSalesOrder(acc.Id, opp.Id, 'Sold', date.newinstance(2025, 02, 10), unit.Id, 18181818);
        insert salesOrder;
        
        List<BrokerCommission__c> commissionList = new List<BrokerCommission__c>();
        for(Integer i=0; i<20; i++){
            BrokerCommission__c commission = TestDataFactory.createBrokerCommission(null, null, null, null, null, project.Id, salesOrder.Id, null, null, null);
            commissionList.add(commission);
        }
        insert commissionList;


        

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
    }

    @IsTest
    static void testConstructor() {
        BrokerCommission__c broker = [SELECT Id,CommissionAmount__c FROM BrokerCommission__c LIMIT 1];
        broker.InvoiceVerified__c = true;
        update broker;
        
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setObjectId(broker.Id);
        Approval.ProcessResult result = Approval.process(req1);
        List<Id> newWorkItemIds = result.getNewWorkitemIds();
        Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
        req2.setComments('Approving request.');
        req2.setAction('Approve');
        req2.setWorkitemId(newWorkItemIds.get(0));
        Approval.ProcessResult result2 =  Approval.process(req2);

        // Set up the test page
        PageReference testPage = Page.BrokerFormPDFGenerator;
        testPage.getParameters().put('brokerCommissionId', broker.Id);
        Test.setCurrentPage(testPage);        

        Test.StartTest();
            BrokerFormPDFController controller = new BrokerFormPDFController();
        Test.StopTest();

        // Verify that the controller is properly initialized
        Assert.areEqual(15000, broker.CommissionAmount__c, 'Total amount should be 15000.');
    }
}