/*****************************************************************************************
Class       : ReceiptAcknowledgementTriggerHandlerTest
Author      : Aman Bharti
Description : ReceiptAcknowledgementTriggerHandlerTest
Test Class  : 
Created Date: 14 July 2025
*****************************************************************************************/
@isTest
public class ReceiptAcknowledgementTriggerHandlerTest {
    @TestSetup
    static void testSetup(){
        
        Account acc = TestDataFactory.createPersonalAccount('Test class Account', null, '123456789', 'aaa@abc.com');
        insert acc;
        
        Opportunity opp = TestDataFactory.createOpportunity(acc.id, 'Won - Special Discount', null, null, null, 'New', String.valueOf(system.today()), null);
        insert opp;
        
        Project__c testProject = TestDataFactory.createProject('Test Project', Date.newinstance(2024, 01, 01), Date.newInstance(2025, 01, 01), Date.newInstance(2025, 01, 15), Date.newInstance(2025, 01, 16), Date.newInstance(2025, 01, 30), Date.newInstance(2025, 02, 01));
        testProject.ProjectNameArabic__c = 'مشروع الاختبار';
        insert testProject;        
        
        BuildingSection__c testBuilding = TestDataFactory.createbuildingSection('Test Building', 'BL-CAS', testProject.Id);
        insert testBuilding;
        
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
        insert testData1;
        
        ReceiptAllocation__c rec = TestDataFactory.createReceiptAllocation(testData1.id, acc.id, ins.id, 12000, soc.id);
        insert rec;
    }
    
    @isTest
    private static void testUpdateInstallmentOtherCharges(){
        Test.StartTest();
        ReceiptAcknowledgement__c recAck = [SELECT Id FROM ReceiptAcknowledgement__c LIMIT 1];
        ReceiptAcknowledgementTriggerHelper.updateInstallmentOtherCharges(new Set<Id>{recAck.Id});
        InstallmentLines__c installment = [SELECT Id,AmountReceived__c FROM InstallmentLines__c LIMIT 1];
        Test.StopTest();
        Assert.areEqual(12000,installment.AmountReceived__c,'Amount Received must be 12000');
    }
    
    @isTest
    private static void testUnApplyReceiptsBeforeDelete(){
        Test.StartTest();
        ReceiptAcknowledgement__c recAck = [SELECT Id FROM ReceiptAcknowledgement__c LIMIT 1];
        Map<Id, ReceiptAcknowledgement__c> recAckMap = new Map<Id, ReceiptAcknowledgement__c>{recAck.Id => recAck};
            ReceiptAcknowledgementTriggerHelper.unApplyReceiptsBeforeDelete(recAckMap);
        delete recAck;
        List<ReceiptAcknowledgement__c> recAckList = [SELECT Id FROM ReceiptAcknowledgement__c];
        Test.StopTest();
        Assert.areEqual(true,recAckList.isEmpty(),'recAckList must be empty');
    }
    
    @isTest
    private static void testSendChequeBounceNotification(){
        Test.StartTest();
        ReceiptAcknowledgement__c recAck = [SELECT Id FROM ReceiptAcknowledgement__c LIMIT 1];
        Map<Id, ReceiptAcknowledgement__c> oldRecAckMap = new Map<Id, ReceiptAcknowledgement__c>{recAck.Id => recAck};
            ReceiptAcknowledgement__c newAckRec = oldRecAckMap.get(recAck.Id);
        newAckRec.Amount__c = 13000;
        newAckRec.Status__c = 'Cleared';
        newAckRec.ReceiptReversalCategory__c = 'Bounced Cheque';
        newAckRec.Reason__c = 'Irregular signature';
        newAckRec.ReversalComments__c = 'Test remarks';
        newAckRec.ActualReversalDate__c = Date.today();
        newAckRec.Finance_Verified__c = true;
        newAckRec.SendtoSAP__c = true;
        update newAckRec;
        
        Map<Id, ReceiptAcknowledgement__c> newRecAckMap = new Map<Id, ReceiptAcknowledgement__c>{newAckRec.Id => newAckRec};
            ReceiptAcknowledgementTriggerHelper.sendChequeBounceNotification(newRecAckMap, oldRecAckMap);
        List<ReceiptAcknowledgement__c> recAckList = [SELECT Id,Amount__c FROM ReceiptAcknowledgement__c];
        Test.StopTest();
        Assert.areEqual(13000, recAckList[0].Amount__c, 'Amount must be 13000');
    }
    
    @isTest
    private static void testCreateReceiptAckIntegrationRecord(){
        Test.StartTest();
        ReceiptAcknowledgement__c recAck = [SELECT Id FROM ReceiptAcknowledgement__c LIMIT 1];
        recAck.Amount__c = 13000;
        recAck.Status__c = 'Cleared';
        recAck.ReceiptReversalCategory__c = 'Bounced Cheque';
        recAck.Reason__c = 'Irregular signature';
        recAck.ReversalComments__c = 'Test remarks';
        recAck.ActualReversalDate__c = Date.today();
        recAck.Finance_Verified__c = true;
        recAck.SendtoSAP__c = true;
        recAck.ReversalApprovalStatus__c = 'Approved';
        update recAck;
        List<IntegrationRecord__c> intRecordList = [SELECT Id FROM IntegrationRecord__c];
        Test.StopTest();
        Assert.areEqual(false,intRecordList.isEmpty(),'There must be atleast one record');
    }
    
    @isTest
    private static void testUpdateReceiptAckIntegrationRecord(){
        Test.StartTest();
        SalesOrderOtherCharges__c objSOC = [SELECT Id FROM SalesOrderOtherCharges__c LIMIT 1];
        objSOC.TypeOfCharge__c = 'Late Payment Charges';
        objSOC.ReversalCategory__c = 'Reversal of LPF paid';
        update objSOC;
        ReceiptAcknowledgement__c recAck = [SELECT Id FROM ReceiptAcknowledgement__c LIMIT 1];
        recAck.Amount__c = 13000;
        recAck.Status__c = 'Cleared';
        recAck.ReceiptReversalCategory__c = 'Bounced Cheque';
        recAck.Reason__c = 'Irregular signature';
        recAck.ReversalComments__c = 'Test remarks';
        recAck.ActualReversalDate__c = Date.today();
        recAck.Finance_Verified__c = true;
        recAck.Other_Charges_1__c = objSOC.Id;
        recAck.ReversalApprovalStatus__c = 'Approved';
        update recAck;
        List<IntegrationRecord__c> intRecordList = [SELECT Id FROM IntegrationRecord__c];
        Test.StopTest();
    }
}