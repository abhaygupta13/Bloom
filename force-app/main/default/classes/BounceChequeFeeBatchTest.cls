/*****************************************************************************************
Class       : BounceChequeFeeBatchTest
Author      : Aman Bharti
Description : BounceChequeFeeBatchTest
Test Class  : 
Created Date: 17 JUNE 2025 
*****************************************************************************************/
@isTest
public class BounceChequeFeeBatchTest {
    @TestSetup
    static void testData(){
        Account acc = TestDataFactory.createBrokerAccount('test', false, '1122334455');
        insert acc;

        Contact con = TestDataFactory.createContact('lname', acc.Id, true, 'test@gmail.com');
        insert con;

        Opportunity opp = TestDataFactory.createOpportunity(null, null,null, acc.Id, null, null, null, null);
        insert opp;

        Project__c project = TestDataFactory.createProject('Project Test', Date.newinstance(2024, 01, 01), Date.newInstance(2025, 01, 01), Date.newInstance(2025, 01, 15), Date.newInstance(2025, 01, 16), Date.newInstance(2025, 01, 30), Date.newInstance(2025, 02, 01));
        project.ProjectNameArabic__c = 'اختبار المشروع';
        insert project;

        Unit__c unit = TestDataFactory.createUnit(project.Id, 'Test unit', 'Sold');
        insert unit;

        SalesOrder__c salesOrder = TestDataFactory.createSalesOrder(acc.Id, opp.Id, 'Sold', date.newinstance(2025, 02, 10), unit.Id, 18181818);
        insert salesOrder;

        PaymentPlan__c paymentPlan = TestDataFactory.createPaymentPlan('Test Plan');
        insert paymentPlan;

        PaymentInstallments__c paymentInstallments = TestDataFactory.createPaymentInstallment(paymentPlan.Id, 1, 6);
        insert paymentInstallments;

        InstallmentLines__c installmentLines = TestDataFactory.createInstallmentLines(salesOrder.Id, 50500, 50500 , 1, paymentPlan.Id, paymentInstallments.Id);
        insert installmentLines;

        ReceiptAcknowledgement__c receiptAck = TestDataFactory.createReceiptAcknowledgement(opp.Id, 'Cheque', 18000, acc.Id, 'Received', System.today().addDays(8), salesOrder.Id);
        insert receiptAck;

        ReceiptAllocation__c receiptAllocation = TestDataFactory.createReceiptAllocation(receiptAck.Id, acc.Id, installmentLines.Id, 12000, null);
        insert receiptAllocation;
    }

    @isTest
    private static void testBatchableForDownPayment(){
        Test.StartTest();
            ReceiptAcknowledgement__c receiptAck = [SELECT Id, Status__c FROM ReceiptAcknowledgement__c LIMIT 1];
            Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
            Contact con = [SELECT Id FROM Contact LIMIT 1];
            receiptAck.Status__c = 'Reversed';
            receiptAck.Unit__c = unit.Id;
            receiptAck.Contact__c = con.Id;
            receiptAck.ReceiptReversalCategory__c = 'Bounced Cheque';
            receiptAck.Reason__c = 'Irregular signature';
            receiptAck.ReversalComments__c = 'Test remarks';
            receiptAck.ActualReversalDate__c = Date.today();
            update receiptAck;
        	receiptAck.ChequeBouncedDate__c = System.today().addDays(-4);
        	update receiptAck;
            InstallmentLines__c installmentLines = [SELECT Id FROM InstallmentLines__c LIMIT 1];
            installmentLines.Type__c = 'Down Payment';
            Update installmentLines;
            Opportunity Opp = [SELECT Id FROM Opportunity LIMIT 1];
            SalesOrder__c salesOrder = [SELECT Id FROM SalesOrder__c LIMIT 1];
            Account acc = [SELECT Id FROM Account LIMIT 1];
            ReceiptAcknowledgement__c receiptAckNew = TestDataFactory.createReceiptAcknowledgement(opp.Id, 'Cheque', 18000, acc.Id, 'Received', System.today().addDays(8), salesOrder.Id);
            insert receiptAckNew;
            ReceiptAllocation__c receiptAllocation = TestDataFactory.createReceiptAllocation(receiptAck.Id, acc.Id, installmentLines.Id, 12000, null);
            insert receiptAllocation;
            BounceChequeFeeBatch batchJob = new BounceChequeFeeBatch();
            Database.executeBatch(batchJob);
        Test.StopTest();
        List<SalesOrderOtherCharges__c> salesOrderOtherChargesList = [SELECT Id FROM SalesOrderOtherCharges__c];
        Assert.areEqual(0, salesOrderOtherChargesList.size(), 'No Sales Order Other Charges record will be created');
    }

    @isTest
    private static void testBatchable(){
        Test.StartTest();
            ReceiptAcknowledgement__c receiptAck = [SELECT Id, Status__c FROM ReceiptAcknowledgement__c LIMIT 1];
            Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
            Contact con = [SELECT Id FROM Contact LIMIT 1];
            receiptAck.Status__c = 'Reversed';
            receiptAck.Unit__c = unit.Id;
            receiptAck.Contact__c = con.Id;
            receiptAck.ReceiptReversalCategory__c = 'Bounced Cheque';
            receiptAck.Reason__c = 'Irregular signature';
            receiptAck.ReversalComments__c = 'Test remarks';
            receiptAck.ActualReversalDate__c = Date.today();
            update receiptAck;
        	receiptAck.ChequeBouncedDate__c = System.today().addDays(-4);
        	update receiptAck;
            InstallmentLines__c installmentLines = [SELECT Id FROM InstallmentLines__c LIMIT 1];
            Opportunity Opp = [SELECT Id FROM Opportunity LIMIT 1];
            SalesOrder__c salesOrder = [SELECT Id FROM SalesOrder__c LIMIT 1];
            Account acc = [SELECT Id FROM Account LIMIT 1];
            ReceiptAcknowledgement__c receiptAckNew = TestDataFactory.createReceiptAcknowledgement(opp.Id, 'Cheque', 18000, acc.Id, 'Received', System.today().addDays(8), salesOrder.Id);
            insert receiptAckNew;
            ReceiptAllocation__c receiptAllocation = TestDataFactory.createReceiptAllocation(receiptAck.Id, acc.Id, installmentLines.Id, 12000, null);
            insert receiptAllocation;
            BounceChequeFeeBatch batchJob = new BounceChequeFeeBatch();
            Database.executeBatch(batchJob);
        Test.StopTest();
        List<SalesOrderOtherCharges__c> salesOrderOtherChargesList = [SELECT Id FROM SalesOrderOtherCharges__c];
        Assert.areEqual(1, salesOrderOtherChargesList.size(), 'There should be one Sales Order Other Charges record created');
    }

    @isTest
    private static void testBatchableForPoorQuality(){
        Test.StartTest();
            ReceiptAcknowledgement__c receiptAck = [SELECT Id, Status__c FROM ReceiptAcknowledgement__c LIMIT 1];
            Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
            Contact con = [SELECT Id FROM Contact LIMIT 1];
            receiptAck.Status__c = 'Reversed';
            receiptAck.Unit__c = unit.Id;
            receiptAck.Contact__c = con.Id;
            receiptAck.ReceiptReversalCategory__c = 'Bounced Cheque';
            receiptAck.Reason__c = 'Poor Quality';
            receiptAck.ReversalComments__c = 'Cheque Quality is not good';
            receiptAck.ActualReversalDate__c = Date.today();
            update receiptAck;
        	receiptAck.ChequeBouncedDate__c = System.today().addDays(-4);
        	update receiptAck;
            InstallmentLines__c installmentLines = [SELECT Id FROM InstallmentLines__c LIMIT 1];
            Opportunity Opp = [SELECT Id FROM Opportunity LIMIT 1];
            SalesOrder__c salesOrder = [SELECT Id FROM SalesOrder__c LIMIT 1];
            Account acc = [SELECT Id FROM Account LIMIT 1];
            ReceiptAcknowledgement__c receiptAckNew = TestDataFactory.createReceiptAcknowledgement(opp.Id, 'Cheque', 18000, acc.Id, 'Received', System.today().addDays(8), salesOrder.Id);
            insert receiptAckNew;
            ReceiptAllocation__c receiptAllocation = TestDataFactory.createReceiptAllocation(receiptAck.Id, acc.Id, installmentLines.Id, 12000, null);
            insert receiptAllocation;
            BounceChequeFeeBatch batchJob = new BounceChequeFeeBatch();
            Database.executeBatch(batchJob);
        Test.StopTest();
        List<SalesOrderOtherCharges__c> salesOrderOtherChargesList = [SELECT Id FROM SalesOrderOtherCharges__c];
        Assert.areEqual(0, salesOrderOtherChargesList.size(), 'Sales Order Other Charges record should not created');
    }

    @isTest
    private static void testSchedule(){
        Test.startTest();
            String sch = '0 0 23 * * ?';
            BounceChequeFeeBatch batchJob = new BounceChequeFeeBatch();
            System.schedule('BounceChequeFeeBatch',sch,batchJob);
        Test.stopTest();
        List<AsyncApexJob> batchJobs = [SELECT Id, Status FROM AsyncApexJob WHERE ApexClass.Name = 'BounceChequeFeeBatch' AND JobType = 'BatchApex'];        
        Assert.areEqual(1, batchJobs.size(), 'Unexpected number of batch jobs ran: ' + batchJobs);
    }
}