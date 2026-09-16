@isTest
public class SalesReceiptIntegrationBatchTest {
     @isTest static void SalesReceiptIntegrationBatchTestMethod(){
      Project__c testProject=new Project__c(
            Name='Test Project'
        );
        insert testProject;
    
        BuildingSection__c testBuilding=new BuildingSection__c(
            Name='Test Building',
            BuildingSectionCode__c='BL-CAS',
            Project__c=testProject.Id
        );
        insert testBuilding;
        Unit__c testUnit=new Unit__c(
            Name='test Unit',
            Status__c='Available',
            UnitType__c='Townhouse',
            BuildingSectionName__c=testBuilding.id,
            Project__c=testProject.Id
        );
        insert testUnit;
        
        Account tempAcc=new Account(
            Name ='test'
        );
        insert tempAcc;
        
        testUnit.Status__c ='Booked';
        testUnit.LockedBy__c = Userinfo.getUserId();
        update testUnit;
        
        
        SalesOrder__c testOrder = new SalesOrder__c(
            Name = 'Test Order',
            Unit__c =testUnit.id,
            Account__c =tempAcc.Id,
            Status__c='Sold'
            
        );
        insert testOrder;
        
        PaymentPlan__c tempPayPlan=new PaymentPlan__c(
            Name='Test Payment',
            Description__c='test'
            
        );
        insert tempPayPlan;
        
        PaymentInstallments__c tempPayInstall=new PaymentInstallments__c(
            InstallmentNumber__c=1,
            PaymentPlan__c=tempPayPlan.id,
            InstallmentPercentage__c=10,
            Description__c='test',
            Condition_Type__c='P012'
        );
        insert tempPayInstall;
        
        InstallmentLines__c tempInstLines= new InstallmentLines__c(
            SalesOrder__c=testOrder.id,
            Description__c='test',
            PaymentInstallments__c=tempPayInstall.id,
            PaymentPlan__c=tempPayPlan.Id,
            AmountReceived__c=200,
            InstallmentAmount__c=2000
        );
        insert tempInstLines;
        
        Document__c newDoc=new Document__c();
        newDoc.Document_Name__c='Test';
        
        Opportunity tempOpp=new Opportunity(
            Name='tempOpp',
            StageName='New',
            CloseDate=system.today(),
            LeadChannel__c='Walk in',
            AccountId=tempAcc.Id
        );
        insert tempOpp;
        ReceiptAcknowledgement__c testRecAck= new ReceiptAcknowledgement__c(
            Opportunity__c=tempOpp.id,
            SalesOrder__c=testOrder.id,
            PaymentType__c='Cheque',
            Amount__c=100,
            ReferenceNumber__c='456732',
            Account__c=tempAcc.id,
            Finance_Verified__c=true,
            MaturityDate__c=  Date.today().addDays(-1)
        );
        insert testRecAck;
        
        ReceiptAcknowledgement__c testRecAck1= new ReceiptAcknowledgement__c(
            Opportunity__c=tempOpp.id,
            PaymentType__c='Cheque',
            Amount__c=100,
            Account__c=tempAcc.id,
            ReferenceNumber__c = '435678',
            SalesOrder__c = testOrder.id
        );
         
           Test.startTest();        
         SalesReceiptIntegrationBatch batch = new SalesReceiptIntegrationBatch();
        Database.executeBatch(batch, 200);        
        Test.stopTest();
     } 
     @IsTest
    static void testCloseWorkOrderScheduler() {
        Test.startTest();        
        // Execute the scheduler
        SalesReceiptIntegrationBatch scheduler = new SalesReceiptIntegrationBatch();
        scheduler.execute(null);
        Test.stopTest();
    }

}