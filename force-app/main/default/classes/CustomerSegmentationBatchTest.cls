/*
* @Author : Bloom Holding
* @CreatedDate : 21 April 2025
* @Description : Test Class for CustomerSegmentationBatch
*/
/*****************************************************************************************************
* Version       Author      Date             Comment       
* 1.0           Anjaneya  21APR2025          
*****************************************************************************************************/
@IsTest
public class CustomerSegmentationBatchTest {
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
        SalesTarget__c target2 = TestDataFactory.createSalesTarget('Q1_2025_'+uniqueEmail2, 5000000, 5000000, '2025', 'Q1');
        SalesTarget__c target3 = TestDataFactory.createSalesTarget('Q1_2025_'+uniqueEmail3, 5000000, 5000000, '2025', 'Q1');
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
        SalesOrder__c salesOrder = TestDataFactory.createSalesOrder(acc.Id, opp.Id, 'Sold', Date.today(), unit.Id, 1000000);
        salesOrder.SalesManager__c = user.Id;
        salesOrder.BookingDate__c = Date.newInstance(2025, 01, 01);
        salesOrderList.add(salesOrder);
        SalesOrder__c salesOrder2 = TestDataFactory.createSalesOrder(acc2.Id, opp2.Id, 'Sold', Date.today(), unit2.Id, 2000000);
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
    static void testCategoryWithGoldCustomers() {
        List<SalesOrder__c> salesorderList = [SELECT ID,Name,Account__r.Name,Account__c,SoldDate__c, Account__r.Segment__c,NetAmount__c,
                                              Account__r.Salutation,LastModifiedDate FROM SalesOrder__c ];
        List<SalesOrder__c> updSalesOrder = new  List<SalesOrder__c>();
        List<Account> accList = new List<Account>();
        for(SalesOrder__c so : salesorderList){
            
            updSalesOrder.add(new SalesOrder__c(id=so.id,NetAmount__c =10000000.00));
            accList.add(new Account(id=so.Account__c,Segment__c = so.Account__r.Segment__c));
        }
        
        update updSalesOrder ;
        Test.Starttest();
          CustomerSegmentationBatch batchJob = new CustomerSegmentationBatch();
          Database.executeBatch(batchJob,10); 
        Test.Stoptest();
        List<Account> accListUpdated = [SELECT id , Segment__c FROM Account WHERE ID IN :accList ];
        System.debug('accListUpdated--'+accListUpdated);
        for(Account acc : accListUpdated){
            Assert.areEqual('Gold', acc.Segment__c, 'Expected Gold category Customer');
        }
    }
     @isTest
    static void testCategoryWithSilverCustomers() {
			List<SalesOrder__c> salesorderList = [SELECT ID,Name,Account__r.Name,Account__c,SoldDate__c, Account__r.Segment__c,NetAmount__c,
                                              Account__r.Salutation,LastModifiedDate FROM SalesOrder__c ];
        List<SalesOrder__c> updSalesOrder = new  List<SalesOrder__c>();
        List<Account> accList = new List<Account>();
        for(SalesOrder__c so : salesorderList){
            
            updSalesOrder.add(new SalesOrder__c(id=so.id,NetAmount__c =5000000.00));
            accList.add(new Account(id=so.Account__c,Segment__c = so.Account__r.Segment__c));
        }
        
        update updSalesOrder ;
        Test.Starttest();
          CustomerSegmentationBatch batchJob = new CustomerSegmentationBatch();
          Database.executeBatch(batchJob,10); 
        Test.Stoptest();
        List<Account> accListUpdated = [SELECT id , Segment__c FROM Account WHERE ID IN :accList ];
        System.debug('accListUpdated--'+accListUpdated);
        for(Account acc : accListUpdated){
            Assert.areEqual('Silver', acc.Segment__c, 'Expected Silver category Customer');
        }
    }
     @isTest
    static void testCategoryWithPlatinumCustomers() {
			List<SalesOrder__c> salesorderList = [SELECT ID,Name,Account__r.Name,Account__c,SoldDate__c, Account__r.Segment__c,NetAmount__c,
                                              Account__r.Salutation,LastModifiedDate FROM SalesOrder__c ];
        List<SalesOrder__c> updSalesOrder = new  List<SalesOrder__c>();
        List<Account> accList = new List<Account>();
        for(SalesOrder__c so : salesorderList){
            
            updSalesOrder.add(new SalesOrder__c(id=so.id,NetAmount__c =50000000.00));
            accList.add(new Account(id=so.Account__c,Segment__c = so.Account__r.Segment__c));
        }
        
        update updSalesOrder ;
        Test.Starttest();
          CustomerSegmentationBatch batchJob = new CustomerSegmentationBatch();
          Database.executeBatch(batchJob,10); 
        Test.Stoptest();
        List<Account> accListUpdated = [SELECT id , Segment__c FROM Account WHERE ID IN :accList ];
        System.debug('accListUpdated--'+accListUpdated);
        for(Account acc : accListUpdated){
            Assert.areEqual('Platinum', acc.Segment__c, 'Expected Platinum category Customer');
        }
    }
    
    @isTest
    static void testCategorySegmentationBatchSchedular() {
        Test.startTest();
        String CRON_EXP = '0 0 0 3 9 ? 2042';
        String jobId = System.schedule('testCustomerSegmentationBatchSchedular',
                                       CRON_EXP, 
                                       new CustomerSegmentationBatch());
        Test.stopTest();
    }
}