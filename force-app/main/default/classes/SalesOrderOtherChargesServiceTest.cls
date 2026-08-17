/*****************************************************************************************
Class       : SalesOrderOtherChargesServiceTest
Author      : Vikas Baliyan
Description : SalesOrderOtherChargesServiceTest
Test Class  : 
Created Date: 30 MAY 2025
*****************************************************************************************/
@isTest
public class SalesOrderOtherChargesServiceTest {
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

        SalesOrderOtherCharges__c otherCharge = TestDataFactory.createOtherCharge(salesOrder.Id, acc.Id ,'Service Charge', false, null, null, null, 'P099', Date.today().addDays(5), 11000);
        insert otherCharge;
    }

    @isTest
    static void testInsertSalesOrderOtherCharges(){
        SalesOrder__c salesOrder = [SELECT Id FROM SalesOrder__c LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        SalesOrderOtherCharges__c otherCharge = TestDataFactory.createOtherCharge(salesOrder.Id, acc.Id ,'Service Charge', false, null, null, null, 'P099', Date.today().addDays(5), 11000);
        Test.startTest();
            SalesOrderOtherChargesService objSaleOrderOtherCharges = SalesOrderOtherChargesService.getInstance();
            objSaleOrderOtherCharges.insertSalesOrderOtherCharges(new List<SalesOrderOtherCharges__c>{otherCharge});
        Test.stopTest();
        List<SalesOrderOtherCharges__c> otherChargesList = [SELECT Id FROM SalesOrderOtherCharges__c];
        Assert.areEqual(2, otherChargesList.size(),'There must be  records');
    }

    @isTest
    static void testCreateSalesOrderOtherChargesObj(){
        SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
            SalesOrderOtherChargesService objSaleOrderOtherCharges = SalesOrderOtherChargesService.getInstance();
            SalesOrderOtherCharges__c otherChargeRec = objSaleOrderOtherCharges.createSalesOrderOtherChargesObj(so.Id, acc.Id, null, 5000, 'Service Charge', null, null, 'P099', Date.today().addDays(5));
        Test.stopTest();
        Assert.areEqual('Service Charge', otherChargeRec.TypeOfCharge__c,'Type Of Charge must be equal to Service Charge');
    }

    @isTest
    static void testGetSalesOrderOtherChargesByIds(){
        SalesOrderOtherCharges__c otherCharges = [SELECT Id FROM SalesOrderOtherCharges__c LIMIT 1];
        Test.startTest();
            SalesOrderOtherChargesService objSaleOrderOtherCharges = SalesOrderOtherChargesService.getInstance();
            List<SalesOrderOtherCharges__c> otherChargesList = objSaleOrderOtherCharges.getSalesOrderOtherChargesByIds(new Set<Id>{otherCharges.Id});
        Test.stopTest();
        Assert.areEqual(1, otherChargesList.size(),'There should be 1 record');
    }

    @isTest
    static void testUpdateOtherCharge(){
        SalesOrderOtherCharges__c otherCharge = [SELECT Id, SAP_Condition_Type__c FROM SalesOrderOtherCharges__c LIMIT 1];
        otherCharge.SAP_Condition_Type__c = 'P011';
        Test.startTest();
            SalesOrderOtherChargesService objSaleOrderOtherCharges = SalesOrderOtherChargesService.getInstance();
            SalesOrderOtherCharges__c otherCharges = objSaleOrderOtherCharges.updateOtherCharge(otherCharge);
        Test.stopTest();
        Assert.areEqual('P011', otherCharges.SAP_Condition_Type__c,'Condition type should be P010');
    }

    @isTest
    static void testUpdateOtherChargesWithoutTrigger(){
        SalesOrderOtherCharges__c otherCharges = [SELECT Id, SAP_Condition_Type__c FROM SalesOrderOtherCharges__c LIMIT 1];
        otherCharges.SAP_Condition_Type__c = 'P010';
        Test.startTest();
            SalesOrderOtherChargesService objSaleOrderOtherCharges = SalesOrderOtherChargesService.getInstance();
            List<SalesOrderOtherCharges__c> otherChargesList = objSaleOrderOtherCharges.updateOtherChargesWithoutTrigger(new List<SalesOrderOtherCharges__c>{otherCharges});
        Test.stopTest();
        Assert.areEqual('P010', otherChargesList[0].SAP_Condition_Type__c,'Condition type should be P010');
    }

    @isTest
    static void testGetSalesOrderChargesByIdWithBank(){
        SalesOrderOtherCharges__c otherCharges = [SELECT Id, SAP_Condition_Type__c FROM SalesOrderOtherCharges__c LIMIT 1];
        Test.startTest();
            SalesOrderOtherChargesService objSaleOrderOtherCharges = SalesOrderOtherChargesService.getInstance();
            SalesOrderOtherCharges__c otherCharge = objSaleOrderOtherCharges.getSalesOrderChargesByIdWithBank(otherCharges.Id);
        Test.stopTest();
        Assert.areEqual(True, otherCharge != null ,'There should be 1 record');
    }

    @isTest
    static void testGetSalesOrderChargesBySalesOrder(){
        SalesOrder__c salesOrder = [SELECT Id FROM SalesOrder__c LIMIT 1];
        Test.startTest();
            SalesOrderOtherChargesService objSaleOrderOtherCharges = SalesOrderOtherChargesService.getInstance();
            List<SalesOrderOtherCharges__c> otherChargesList = objSaleOrderOtherCharges.getSalesOrderChargesBySalesOrder(salesOrder.Id);
        Test.stopTest();
        Assert.areEqual(1, otherChargesList.size(),'There should be 1 record');
    }

    @isTest
    static void testUpsertSalesOrderOtherCharges(){
        SalesOrderOtherCharges__c otherCharges = [SELECT Id, SAP_Condition_Type__c FROM SalesOrderOtherCharges__c LIMIT 1];
        otherCharges.SAP_Condition_Type__c = 'P010';
        Test.startTest();
            SalesOrderOtherChargesService objSaleOrderOtherCharges = SalesOrderOtherChargesService.getInstance();
            List<SalesOrderOtherCharges__c> otherChargesList = objSaleOrderOtherCharges.upsertSalesOrderOtherCharges(new List<SalesOrderOtherCharges__c>{otherCharges});
        Test.stopTest();
        Assert.areEqual('P010', otherChargesList[0].SAP_Condition_Type__c,'Condition type should be P010');
    }
}