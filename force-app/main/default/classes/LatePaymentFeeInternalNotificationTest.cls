/*****************************************************************************************
Class       : LatePaymentFeeInternalNotificationTest
Author      : Dhanraj Poojary
Description : LatePaymentFeeInternalNotificationBatch Test Class
Test Class  : 
Created Date: 03 JULY 2025 
*****************************************************************************************/

@isTest
public class LatePaymentFeeInternalNotificationTest {
    @TestSetup
    static void setupTestData(){
        // Test data for Project__c and related Units
        Account acc = TestDataFactory.createBrokerAccount('test', false, '1122334455');
        insert acc;
        
        Contact con = TestDataFactory.createContact('test', acc.Id, true, 'test@gmail.com');
        insert con;
        
        Opportunity opp = TestDataFactory.createOpportunity(null, null,null, acc.Id, null, null, null, null);
        insert opp;
        
        //Test data for Project__c and related Units
        Project__c project = TestDataFactory.createProject('ProjectTest', Date.today() - 1);
        insert project;
        
        Unit__c u = TestDataFactory.createUnit(project.Id, 'A1-G01', 'Unassigned');
        u.Project__c = project.Id;
        u.RegistrationDate__c = Date.today();
        insert u;
        
        SalesOrder__c salesOrder = TestDataFactory.createSalesOrder(acc.Id, opp.Id, 'Sold', date.newinstance(2024, 10, 10), u.Id, 18181818);
        insert salesOrder;
        
        PaymentPlan__c paymentPlan = TestDataFactory.createPaymentPlan('Test Plan');
        insert paymentPlan;
        paymentPlan.Project__c = project.Id;
        update paymentPlan;
        
        List<PaymentInstallments__c> paymentInstallmentsList = new List<PaymentInstallments__c>();
        PaymentInstallments__c paymentInstallments1 = TestDataFactory.createPaymentInstallment(paymentPlan.Id, 1, 6);
        PaymentInstallments__c paymentInstallments2 = TestDataFactory.createPaymentInstallment(paymentPlan.Id, 2, 6);
        paymentInstallmentsList.add(paymentInstallments1); paymentInstallmentsList.add(paymentInstallments2);
        insert paymentInstallmentsList;
        
        List<InstallmentLines__c> installmentLinesList = new List<InstallmentLines__c>();
        InstallmentLines__c installmentLines1 = TestDataFactory.createInstallmentLines(salesOrder.Id, 50500, 20000 , 1, paymentPlan.Id, paymentInstallmentsList[0].Id);
        installmentLinesList.add(installmentLines1);
        InstallmentLines__c installmentLines2 = TestDataFactory.createInstallmentLines(salesOrder.Id, 50500, 20000 , 2, paymentPlan.Id, paymentInstallmentsList[1].Id);
        installmentLinesList.add(installmentLines2);
        insert installmentLinesList;
    }
    
    @istest
    public static void testmethod1(){
        Account objAccount = [SELECT Id FROM Account LIMIT 1];
        Contact objContact = [SELECT Id FROm Contact LIMIT 1];
        SalesOrder__c objSalesOrder = [SELECT Id,Account__c,Contact__c FROM SalesOrder__c LIMIT 1];
        objSalesOrder.Contact__c = objContact.Id;
        objSalesOrder.LPFCalculationStopped__c = false;
        update objSalesOrder;
        
        Project__c objProject = [SELECT Id, Name, LPFAnnualPercentage__c, LPFSAPConditionCode__c FROM Project__c LIMIT 1];
        objProject.LPFAnnualPercentage__c = 12;
        objProject.LPFSAPConditionCode__c = 'P099';
        objproject.EnableLPFInternalNotification__c = true;
        update objProject;
        
        List<InstallmentLines__c> installmentList = [SELECT Id, SalesOrder__r.Unit__r.DARIRegistration__c, ClearedAmount__c, BrokerCommissionCreated__c, InstallmentNumber__c, SalesOrder__r.Broker_Agency__c, SalesOrder__r.Status__c, SalesOrder__r.SoldDate__c,PendingAmount__c,InstallmentDate__c FROM InstallmentLines__c];
        System.debug('installmentline-->>'+installmentList);
        
        for(InstallmentLines__c objInstallment : installmentList){
            objInstallment.InstallmentDate__c = Date.today().addDays(-4);
        }
        update installmentList;
        
        SalesOrderOtherCharges__c objSOC = new SalesOrderOtherCharges__c(
            Installment_Line__c = installmentList[0].Id, StartDate__c = Date.today().addDays(-3),
            TypeOfCharge__c = 'Late Payment Charges', Account__c = objSalesOrder.Account__c,
            SalesOrder__c = objSalesOrder.Id, SAP_Condition_Type__c = objProject.LPFSAPConditionCode__c, Amount__c = 2000);
        insert objSOC;
        
        Test.startTest();
        LatePaymentFeeInternalNotificationBatch scheduler = new LatePaymentFeeInternalNotificationBatch();
        scheduler.execute(null);
        Test.stopTest();
    }
}