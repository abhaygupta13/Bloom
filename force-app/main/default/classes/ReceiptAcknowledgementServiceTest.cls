/*****************************************************************************************
Class       : ReceiptAcknowledgementServiceTest
Author      : Aman Bharti
Description : ReceiptAcknowledgementServiceTest
Test Class  : 
Created Date: 14 July 2025
*****************************************************************************************/
@isTest
public class ReceiptAcknowledgementServiceTest {
    @TestSetup
    static void testSetup(){
        Account acc = TestDataFactory.createPersonalAccount('Test class Account', null, '123456789', 'aaa@abc.com');
        insert acc;

        Opportunity opp = TestDataFactory.createOpportunity(acc.id, 'Won - Special Discount', null, null, null, 'New', String.valueOf(system.today()), null);
        insert opp;

        Project__c testProject = TestDataFactory.createProject('Test Project', Date.newinstance(2024, 01, 01), Date.newInstance(2025, 01, 01), Date.newInstance(2025, 01, 15), Date.newInstance(2025, 01, 16), Date.newInstance(2025, 01, 30), Date.newInstance(2025, 02, 01));
        testProject.ProjectNameArabic__c = 'مشروع الاختبار';
        insert testProject;   

        Unit__c testUnit = TestDataFactory.createUnit(testProject.Id, 'test Unit', 'Available');
        insert testUnit;

        SalesOrder__c testOrder = TestDataFactory.createSalesOrder(Acc.Id, Opp.Id, 'Booked', null, testUnit.id, null);
        insert testOrder;

        PaymentPlan__c  pp = TestDataFactory.createPaymentPlan('Test Plan');
        insert pp;
        
        PaymentInstallments__c ppi = TestDataFactory.createPaymentInstallment(pp.id, 1, 100);
        insert ppi;

        InstallmentLines__c ins = TestDataFactory.createInstallmentLines(testOrder.id, 120000, null, null, pp.id, ppi.id);
        insert ins;
        
        SalesOrderOtherCharges__c soc = TestDataFactory.createOtherCharge(testOrder.id, acc.id, 'ADM Fee', false, null, null, null, null, null, 12000);
        insert soc;

        ReceiptAcknowledgement__c testData1 = TestDataFactory.createReceiptAcknowledgement(opp.id, 'Online', 12000, acc.Id, 'Received', null, testOrder.id);
        testData1.New_Maturity_Date__c = Date.Today()+30;
        insert testData1;

        ReceiptAllocation__c rec = TestDataFactory.createReceiptAllocation(testData1.id, acc.id, ins.id, 12000, soc.id);
        insert rec;
    }

    @IsTest
    private static void testGetReceiptAcknowledgementById(){
        Test.StartTest();
            ReceiptAcknowledgement__c recAck = [SELECT Id,PaymentType__c FROM ReceiptAcknowledgement__c LIMIT 1];
            ReceiptAcknowledgementService objReceiptAcknowledgementService = ReceiptAcknowledgementService.getInstance();
            ReceiptAcknowledgement__c ack = objReceiptAcknowledgementService.getReceiptAcknowledgementById(recAck.Id);
        Test.StopTest();
        Assert.areEqual(true, ack != null, 'There must be 1 record');
    }

    @IsTest
    private static void testUpdateReceiptAcknowledgement(){
        Test.StartTest();
            ReceiptAcknowledgement__c recAck = [SELECT Id FROM ReceiptAcknowledgement__c LIMIT 1];
            recAck.PaymentType__c = 'Cheque';
            ReceiptAcknowledgementService objReceiptAcknowledgementService = ReceiptAcknowledgementService.getInstance();
            ReceiptAcknowledgement__c ack = objReceiptAcknowledgementService.updateReceiptAcknowledgement(recAck);
        Test.StopTest();
        Assert.areEqual('Cheque', ack.PaymentType__c, 'Payment type must be Cheque');
    }

    @IsTest
    private static void testGetReceiptAcknowledgementNReceiptAllocationsById(){
        Test.StartTest();
            ReceiptAcknowledgement__c recAck = [SELECT Id FROM ReceiptAcknowledgement__c LIMIT 1];
            recAck.PaymentType__c = 'Cheque';
            ReceiptAcknowledgementService objReceiptAcknowledgementService = ReceiptAcknowledgementService.getInstance();
            List<ReceiptAcknowledgement__c> ackList = objReceiptAcknowledgementService.getReceiptAcknowledgementNReceiptAllocationsById(new Set<Id>{recAck.Id});
        Test.StopTest();
        Assert.areEqual(true, ackList[0].Receipt_Allocations__r.size() > 0, 'Receipt Allocation list should not be empty.');
    }

    @IsTest
    private static void testGetReceiptAckNReceiptAllocationsByReceiptId(){
        Test.StartTest();
            ReceiptAcknowledgement__c recAck = [SELECT Id FROM ReceiptAcknowledgement__c LIMIT 1];
            recAck.PaymentType__c = 'Cheque';
            ReceiptAcknowledgementService objReceiptAcknowledgementService = ReceiptAcknowledgementService.getInstance();
            List<ReceiptAcknowledgement__c> ackList = objReceiptAcknowledgementService.getReceiptAckNReceiptAllocationsByReceiptId(new Set<Id>{recAck.Id});
        Test.StopTest();
        Assert.areEqual(true, ackList[0].Receipt_Allocations__r.size() > 0, 'Receipt Allocation list should not be empty.');
    }

    @IsTest
    private static void testGetReceiptAcknowledgementByIds(){
        Test.StartTest();
            ReceiptAcknowledgement__c recAck = [SELECT Id,PaymentType__c FROM ReceiptAcknowledgement__c LIMIT 1];
            ReceiptAcknowledgementService objReceiptAcknowledgementService = ReceiptAcknowledgementService.getInstance();
            List<ReceiptAcknowledgement__c> ackList = objReceiptAcknowledgementService.getReceiptAcknowledgementByIds(new Set<Id>{recAck.Id});
        Test.StopTest();
        Assert.areEqual(true, !ackList.isEmpty(), 'There must be 1 record');
    }

    @IsTest
    private static void testUpdateReceiptAcknowledgementWithoutTrigger(){
        Test.StartTest();
            ReceiptAcknowledgement__c recAck = [SELECT Id FROM ReceiptAcknowledgement__c LIMIT 1];
            recAck.PaymentType__c = 'Cheque';
            ReceiptAcknowledgementService objReceiptAcknowledgementService = ReceiptAcknowledgementService.getInstance();
            List<ReceiptAcknowledgement__c> ackList = objReceiptAcknowledgementService.updateReceiptAcknowledgementWithoutTrigger(new List<ReceiptAcknowledgement__c>{recAck});
        Test.StopTest();
        Assert.areEqual('Cheque', ackList[0].PaymentType__c, 'Payment type must be Cheque');
    }
    
    @IsTest
    private static void testGetReceiptAcknowledgementBySalesOrders(){ 
        List<SalesOrder__c> salesOrderList = [SELECT Id FROM SalesOrder__c];
        Set<Id> soId = new Set<Id>{salesOrderList[0].Id};
        ReceiptAcknowledgement__c recAck =  [SELECT Id, Name,New_Maturity_Date__c, SAP_Company_Code__c, SAP_Contract_Number__c, MaturityDate__c, VerifyDate__c,
                                             Unit__r.SAP_Unit_Number__c, Amount__c, SalesOrder__r.Unit__r.Project__r.SAPProfitCenter__c,
                                             SAP_Main_Buyer_BP_No__c, BankName__c, ReferenceNumber__c, ReceiptReversalCategory__c,
                                             SAP_Special_GL_Indicator__c, SAP_Wire_GL_Sub_Account__c, SAP_Cheque_GL_Sub_Account__c,
                                             ReversalApprovalStatus__c, ActualReversalDate__c, ReversalComments__c, Reason__c, 
                                             ReceiptPostingDate__c, PaymentType__c, SAP_Document_No__c
                                             FROM ReceiptAcknowledgement__c LIMIT 1];    
        ReceiptAcknowledgementService objReceiptAcknowledgementService = ReceiptAcknowledgementService.getInstance();
        List<ReceiptAcknowledgement__c> ra = objReceiptAcknowledgementService.getReceiptAcknowledgementBySalesOrders(soId);
        objReceiptAcknowledgementService.deleteReceiptAcknowledgementWithoutTrigger(null);
        objReceiptAcknowledgementService.getReceiptAcknowledgementByExternalId(null);
        objReceiptAcknowledgementService.getReceiptAcknowledgementByExternalId(null);
        objReceiptAcknowledgementService.insertReceiptAcknowledgementWithoutTrigger(null);
        objReceiptAcknowledgementService.getReceiptAcknowledgementAndReceiptAllocationsBySOId(salesOrderList[0].Id);
        objReceiptAcknowledgementService.getAllReceiptAcknowledgementBySalesOrders(soId);
        objReceiptAcknowledgementService.createReceiptAcknowledgementObj(100,null,null,null,null,'test','test',false,'test','test');
        objReceiptAcknowledgementService.getSpecialGLReceipts(null);
        objReceiptAcknowledgementService.insertReceiptAcknowledgements(null);
        objReceiptAcknowledgementService.getReceiptAcknowledgementMap(soId);
        objReceiptAcknowledgementService.getReceiptAcknowledgementAndAllocationsByIds(soId);
        objReceiptAcknowledgementService.getReceiptAckIntegrationRecord('Update', recAck);
    }
}