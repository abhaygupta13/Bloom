/*****************************************************************************************
Class       : SalesTargetBatchTest Test
Author      : Vikas Baliyan
Description : SalesTargetBatchTest Test
Test Class  : 
Created Date: 07 JAN 2025 
*****************************************************************************************/
@isTest
public class SalesTargetBatchTest {
    @TestSetup
    static void testData(){
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        String uniqueEmail = String.valueOf(Math.round(Math.random()*1000)) +String.valueOf(System.now().format('ddMMYYYhhmmss')) +'@' + URL.getOrgDomainUrl().getHost();
        String uniqueEmail2 = String.valueOf(Math.round(Math.random()*1000)) +String.valueOf(System.now().format('ddMMYYYhhmmss')) +'@' + URL.getOrgDomainUrl().getHost();
        String uniqueEmail3 = String.valueOf(Math.round(Math.random()*1000)) +String.valueOf(System.now().format('ddMMYYYhhmmss')) +'@' + URL.getOrgDomainUrl().getHost();
        User user = TestDataFactory.createUser(p.Id, uniqueEmail, uniqueEmail, 'test1234', 'user');
        User user2 = TestDataFactory.createUser(p.Id, uniqueEmail2, uniqueEmail2, 'test2', 'user');
        User user3 = TestDataFactory.createUser(p.Id, uniqueEmail3, uniqueEmail3, 'test3', 'user');
        List<User> userList = new List<User>();
        userList.add(user); userList.add(user2); userList.add(user3);
        insert userList; 
        SalesTarget__c target = TestDataFactory.createSalesTarget('Q1_2025_'+uniqueEmail, 5000000, 5000000, '2025', 'Q1');
        target.SalesManager__c = user.Id;
        SalesTarget__c target2 = TestDataFactory.createSalesTarget('Q1_2025_'+uniqueEmail2, 5000000, 5000000, '2025', 'Q1');
        target2.SalesManager__c = user2.Id;
        SalesTarget__c target3 = TestDataFactory.createSalesTarget('Q1_2025_'+uniqueEmail3, 5000000, 5000000, '2025', 'Q1');
        target3.SalesManager__c = user3.Id;
        List<SalesTarget__c> salesTargetList = new List<SalesTarget__c>();
        salesTargetList.add(target); salesTargetList.add(target2); salesTargetList.add(target3);
        insert salesTargetList;

        Project__c project = TestDataFactory.createProject('Project Test', Date.newinstance(2024, 01, 01), Date.newInstance(2025, 01, 01), Date.newInstance(2025, 01, 15), Date.newInstance(2025, 01, 16), Date.newInstance(2025, 01, 30), Date.newInstance(2025, 02, 01));
        insert project;

        List<Account> accList = new List<Account>();
        Account acc = TestDataFactory.createBrokerAccount('test', false, '1122334455');
        Account acc2 = TestDataFactory.createBrokerAccount('test2', false, '1122334455');
        accList.add(acc); accList.add(acc2);
        Insert accList;

        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity opp = TestDataFactory.createOpportunity(null, null,null, acc.Id, null, null, null, null);
        opp.LeadSource = 'Broker';
        Opportunity opp2 = TestDataFactory.createOpportunity(null, null,null, acc2.Id, null, null, null, null);
        opp.LeadSource = 'Broker';
        oppList.add(opp); oppList.add(opp2);
        insert oppList;

        List<Unit__c> unitList = new List<Unit__c>();
        Unit__c unit = TestDataFactory.createUnit(project.Id, 'Test unit', 'Sold');
        Unit__c unit2 = TestDataFactory.createUnit(project.Id, 'Test unit 2', 'Sold');
        unitList.add(unit); unitList.add(unit2);
        insert unitList;


        List<SalesOrder__c> salesOrderList = new List<SalesOrder__c>();
        SalesOrder__c salesOrder = TestDataFactory.createSalesOrder(acc.Id, opp.Id, 'Sold', Date.newInstance(2025, 01, 01), unit.Id, 1000000);
        salesOrder.SalesManager__c = user.Id;
        salesOrder.BookingDate__c = Date.newInstance(2025, 01, 01);
        salesOrderList.add(salesOrder);
        SalesOrder__c salesOrder2 = TestDataFactory.createSalesOrder(acc2.Id, opp2.Id, 'Sold', Date.newInstance(2025, 01, 01), unit2.Id, 2000000);
        salesOrder2.SalesManager__c = user.Id;
        salesOrder2.BookingDate__c = Date.newInstance(2025, 01, 01);
        salesOrderList.add(salesOrder2);
        insert salesOrderList;

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

    @isTest
    private static void testBatchable(){
        Test.StartTest();
            List<SalesTarget__c> salesTargetList = [SELECT Id, ExternalIdentifier__c, DirectTargetAmount__c, IndirectTargetAmount__c, Year__c, Quarter__c FROM SalesTarget__c];
            System.debug('--->>>'+[SELECT Id,Name,SalesManager__c,Resold__c,BookingDate__c FROM SalesOrder__c]);
            SalesTargetController.createSalesTarget(salesTargetList);
            SalesTargetBatch batchJob = new SalesTargetBatch();
            Database.executeBatch(batchJob);
        Test.StopTest();
        User user = [SELECT Id FROM User WHERE FirstName = 'test1234' LIMIT 1];
        List<SalesTarget__c> targetList = [SELECT Id,IndirectPreLaunchAchievedAmount__c FROM SalesTarget__c WHERE SalesManager__c =: user.Id];
        Assert.areEqual(1000000, targetList[0].IndirectPreLaunchAchievedAmount__c, 'There is something wrong in calculation');
    }

    @isTest
    private static void testSchedule() {
        Test.startTest();
            String sch = '0 0 23 * * ?';
            SalesTargetBatch batchJob = new SalesTargetBatch();
            System.schedule('SalesTargetBatch',sch,batchJob);
        Test.stopTest();
        List<AsyncApexJob> batchJobs = [SELECT Id, Status FROM AsyncApexJob WHERE ApexClass.Name = 'SalesTargetBatch' AND JobType = 'BatchApex'];        
        System.assertEquals(1, batchJobs.size(), 'Unexpected number of batch jobs ran: ' + batchJobs);
    }
}