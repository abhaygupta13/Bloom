/*****************************************************************************************
Class       : SalesOrderOtherChargesTriggerHelperTest
Author      : Vikas Baliyan
Description : SalesOrderOtherChargesTriggerHelperTest
Test Class  : 
Created Date: 29 MAY 2025
*****************************************************************************************/
@isTest
public class SalesOrderOtherChargesTriggerHelperTest {
    
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
        
        Opportunity opp = TestDataFactory.createOpportunity(null, null,null, acc.Id, null, null, null, null);
        insert opp;
        
        Unit__c unit = TestDataFactory.createUnit(projectList[0].Id, 'Test unit', 'Sold');
        insert unit;
        
        SalesOrder__c salesOrder = TestDataFactory.createSalesOrder(acc.Id, opp.Id, 'Sold', date.newinstance(2025, 02, 10), unit.Id, 18181818);
        insert salesOrder;
        
        SalesOrderOtherCharges__c otherCharge = TestDataFactory.createOtherCharge(salesOrder.Id, acc.Id ,'Cheque Bounce Fee', false, null, null, null, 'P099', Date.today().addDays(5), 11000);
        otherCharge.SendtoSAP__c = true;
        insert otherCharge;
    }
    
    @isTest
    static void testHandleBeforeInsert() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
        Test.startTest();
        SalesOrderOtherCharges__c otherCharge = TestDataFactory.createOtherCharge(so.Id, acc.Id ,'Cheque Bounce Fee', false, null, null, null, 'P099', Date.today().addDays(5), 11000);
        otherCharge.SendtoSAP__c = true;    
        insert otherCharge;
        Test.stopTest();
        SalesOrderOtherCharges__c newOtherCharge = [SELECT Id, IntegrationStatus__c FROM SalesOrderOtherCharges__c WHERE Id = :otherCharge.Id];
        Assert.areEqual('In Progress',newOtherCharge.IntegrationStatus__c,'The Integration status should be In Progress');
        List<IntegrationRecord__c> integrationRecList = [SELECT Id, Action__c, RecordId__c, ObjectAPIName__c FROM IntegrationRecord__c WHERE RecordId__c =: otherCharge.Id];
        Assert.areEqual(0 ,integrationRecList.size() ,'There should be 0 Integration record');
    }
    
    @isTest
    static void testHandleBeforeUpdate() {
        Test.startTest();
        SalesOrderOtherCharges__c otherCharge = [SELECT Id, SendtoSAP__c FROM SalesOrderOtherCharges__c LIMIT 1];
        otherCharge.SendtoSAP__c = true;
        update otherCharge;
        Test.stopTest();
        SalesOrderOtherCharges__c updatedOtherCharge = [SELECT Id, IntegrationStatus__c FROM SalesOrderOtherCharges__c WHERE Id = :otherCharge.Id];
        List<IntegrationRecord__c> integrationRecList = [SELECT Id FROM IntegrationRecord__c WHERE RecordId__c =: otherCharge.Id];
        Assert.areEqual('In Progress',updatedOtherCharge.IntegrationStatus__c,'The Integration status should be In Progress');
        Assert.areEqual(0 ,integrationRecList.size() ,'There should be 0 Integration record');
    }
    
    
    @isTest
    static void testHandleAfterUpdate() {
        SalesOrderOtherCharges__c otherCharge = [SELECT Id, SendtoSAP__c FROM SalesOrderOtherCharges__c LIMIT 1];
        otherCharge.SendtoSAP__c = false;
        update otherCharge;
        Test.startTest();
        otherCharge.Reason__c = 'Wrong allocation of payment';
        otherCharge.ReversalCategory__c = 'Reversal of Bounce cheque fees paid';
        otherCharge.IsReversed__c = true;
        otherCharge.SendtoSAP__c = true;
        update otherCharge;
        Test.stopTest();
        SalesOrderOtherCharges__c updatedOtherCharge = [SELECT Id, IntegrationStatus__c FROM SalesOrderOtherCharges__c WHERE Id = :otherCharge.Id];
        List<IntegrationRecord__c> integrationRecList = [SELECT Id FROM IntegrationRecord__c WHERE RecordId__c =: otherCharge.Id];
        Assert.areEqual('In Progress',updatedOtherCharge.IntegrationStatus__c,'The Integration status should be In Progress');
        Assert.areEqual(1 ,integrationRecList.size() ,'There should be 1 Integration record');
    }
    
    @isTest
    static void testHandleAfterUpdateLPF() {
        SalesOrderOtherCharges__c otherCharge = [SELECT Id, SendtoSAP__c FROM SalesOrderOtherCharges__c LIMIT 1];
        otherCharge.SendtoSAP__c = false;
        update otherCharge;
        Test.startTest();
        otherCharge.ReversalCategory__c = 'Reversal of LPF paid';
        otherCharge.Reason__c = 'Wrong allocation of payment';
        otherCharge.IsReversed__c =true;
        otherCharge.TypeOfCharge__c = 'Late Payment Charges';
        otherCharge.SendtoSAP__c = true;
        update otherCharge;
        Test.stopTest();
        SalesOrderOtherCharges__c updatedOtherCharge = [SELECT Id, IntegrationStatus__c FROM SalesOrderOtherCharges__c WHERE Id = :otherCharge.Id];
        List<IntegrationRecord__c> integrationRecList = [SELECT Id FROM IntegrationRecord__c WHERE RecordId__c =: otherCharge.Id];
        Assert.areEqual('In Progress',updatedOtherCharge.IntegrationStatus__c,'The Integration status should be In Progress');
        Assert.areEqual(1 ,integrationRecList.size() ,'There should be 1 Integration record');
    }
}