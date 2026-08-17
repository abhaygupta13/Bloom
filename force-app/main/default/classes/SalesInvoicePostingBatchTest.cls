/*****************************************************************************************
Class       : SalesInvoicePostingBatchTest
Author      : Biswajeet
Description : Test class for SalesInvoicePostingBatch
Created Date: 24 JUL 2025 
*****************************************************************************************/
@isTest
public class SalesInvoicePostingBatchTest {
    
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
        project.EnableSalesInvoicePosting__c = true;
        insert project;
        
        List<BankAccount__c> bankList = new List<BankAccount__c>();
        BankAccount__c bankAcc = TestDataFactory.createBankAccount('Test Normal Bank', 'Normal', project.Id);
        BankAccount__c bankAcc1 = TestDataFactory.createBankAccount('Test Handover Bank', 'Handover', project.Id);
        bankList.add(bankAcc);
        bankList.add(bankAcc1);
        insert bankList;
        
        Unit__c u = TestDataFactory.createUnit(project.Id, 'A1-G01', 'Unassigned');
        u.Project__c = project.Id;
        u.RegistrationDate__c = Date.today();
        insert u;
        
        SalesOrder__c salesOrder = TestDataFactory.createSalesOrder(acc.Id, opp.Id, 'Booked', date.newinstance(2025, 7, 7), u.Id, 18181818);
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
        insert installmentLinesList;        
    }
    
    @istest
    public static void testmethod1(){
        Account objAccount = [SELECT Id FROM Account LIMIT 1];
        Contact objContact = [SELECT Id FROm Contact LIMIT 1];
        SalesOrder__c objSalesOrder = [SELECT Id,Contact__c FROM SalesOrder__c LIMIT 1];
        objSalesOrder.Contact__c = objContact.Id;
        objSalesOrder.Company_Code__c = '123';
        objSalesOrder.Status__c = 'Sold';
        objSalesOrder.SAP_Contract_No__c = '4738472';
        update objSalesOrder;
        List<InstallmentLines__c> installmentList = [SELECT Id, SalesOrder__r.Unit__r.DARIRegistration__c, ClearedAmount__c, BrokerCommissionCreated__c, InstallmentNumber__c, SalesOrder__r.Broker_Agency__c, SalesOrder__r.Status__c, SalesOrder__r.SoldDate__c,PendingAmount__c,InstallmentDate__c FROM InstallmentLines__c];
        System.debug('installmentline-->>'+installmentList);
        for(InstallmentLines__c objInstallment : installmentList){
            objInstallment.SAP_Condition_Type__c = 'test';
            objInstallment.InstallmentDate__c = Date.today();
        }
        update installmentList;
        Test.startTest();
        SalesInvoicePostingBatch batch = new SalesInvoicePostingBatch();
        Database.executeBatch(batch, 1);
        Test.stopTest();
    }
    
    @isTest
    private static void testSchedule() {
        Test.startTest();
        String sch = '0 0 23 * * ?';
        SalesInvoicePostingBatch batchJob = new SalesInvoicePostingBatch();
        System.schedule('SalesInvoicePostingBatch',sch,batchJob);
        Test.stopTest();
    }
}