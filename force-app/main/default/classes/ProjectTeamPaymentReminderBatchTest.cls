/*****************************************************************************************
Class       : ProjectTeamPaymentReminderBatchTest
Author      : Dhanraj Poojary
Description : ProjectTeamPaymentReminderBatch Test Class
Test Class  : 
Created Date: 28 AUG 2025 
*****************************************************************************************/

@istest
public class ProjectTeamPaymentReminderBatchTest {
    
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
        project.SendQuaterlyPaymentReminder__c = true;
        update project;
        
        Unit__c u = TestDataFactory.createUnit(project.Id, 'A1-G01', 'Unassigned');
        u.Project__c = project.Id;
        u.RegistrationDate__c = Date.today();
        insert u;
        
        SalesOrder__c salesOrder = TestDataFactory.createSalesOrder(acc.Id, opp.Id, 'Booked', date.newinstance(2024, 10, 10), u.Id, 18181818);
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
        installmentLines1.ClearedAmount__c = 1000;
        installmentLines1.InstallmentAmount__c = 10000;
        installmentLines1.RevisedDate__c = Date.today().addDays(60);
        installmentLinesList.add(installmentLines1);
        InstallmentLines__c installmentLines2 = TestDataFactory.createInstallmentLines(salesOrder.Id, 50500, 20000 , 2, paymentPlan.Id, paymentInstallmentsList[1].Id);
        installmentLinesList.add(installmentLines2);
        insert installmentLinesList;
        
        SalesOrder__c objSalesOrder = [SELECT Id,Contact__c FROM SalesOrder__c LIMIT 1];
        objSalesOrder.Contact__c = con.Id;
        update objSalesOrder;
        
        List<InstallmentLines__c> ilList = [SELECT Id,InstallmentDate__c FROM InstallmentLines__c];
        for(InstallmentLines__c objIL : ilList){
            objIL.InstallmentDate__c = Date.Today().addDays(60);
        }
        update ilList;
    }
    
    @istest
    public static void testmethod1(){
        Test.startTest();      
        String sch = '0 0 23 * * ?';
        System.schedule('ProjectTeamPaymentReminderBatch',sch,new ProjectTeamPaymentReminderBatch());
        Test.stopTest();
    }
}