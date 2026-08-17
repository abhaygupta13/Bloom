@IsTest
public class BrokerCommissionTriggerHelperTest {
    @testSetup
    private static void testData() {
        Project__c project = new Project__c();
        project.Name = 'TEST';
        project.ProjectRegistrationDate__c = Date.today() - 1;
        insert project;

        Account account = TestDataFactory.createBrokerAccount('name1', false, '1234567890');
        insert account;

        Contact con = TestDataFactory.createContact('test con',account.id, true, 'abc@gmail.com');
        con.BrokerContactRole__c = 'Admin';
        insert con;
        
        List<BrokerCommission__c> bcList = new List<BrokerCommission__c>();
        for(Integer i = 0; i<20; i++){
            BrokerCommission__c bc = TestDataFactory.createBrokerCommission(25000, 5, null, null, null, project.Id, null,account.id , null, null);
            bc.FirstApprovalStatus__c = 'Not Approved'; bc.IntegrationStatus__c = 'In Progress';bc.InvoiceDate__c = date.today();
            bcList.add(bc);
        }
        insert bcList;
        
        
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
            Project__c=testProject.Id,
            PropertyUsage__c='Residential',
            UnitView__c  ='Beach Side',
            FloorNumber__c='01',
            NumberOfBedrooms__c='3',
            UnitModel__c='1BHK',
            SellingPrice__c= 700000,
            EndDate__c= date.today()+10,
            StartDate__c=date.today()-10
            
        );
        insert testUnit;
        
        PaymentPlan__c  pp = new PaymentPlan__c();
        pp.Name ='July Plan';
        pp.Unit__c= testUnit.id;
        pp.Description__c ='Test Description';
        pp.Description__c = 'Test';
        pp.IsActive__c = 'NO';
        pp.BrokerPortalFlag__c = True;
        pp.Classification__c = Constants.PAYMENT_PLAN_TYPE_STANDARD;
        
        insert pp;
        
        PaymentInstallments__c ppi = new PaymentInstallments__c();
        ppi.BrokerPayoutPercentage__c =100;
        ppi.Description__c = 'test description';
        ppi.InstallmentNumber__c = 1;
        ppi.InstallmentPercentage__c=100;
        ppi.PaymentPlan__c = pp.id;
        ppi.InstallmentPercentage__c=100;
        ppi.Condition_Type__c='P012';
        insert ppi;
        
        Id AccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Account tempAcc=new Account(
            RecordTypeId=AccountRecordTypeId,
            LastName= 'test',
            personEmail='Jana@tesrt.com'
            
        );
        insert tempAcc;
        
        
        Opportunity tempOpp=new Opportunity(
            Name='tempOpp',
            StageName='New',
            CloseDate=system.today(),
            LeadChannel__c='Walk in',
            AccountId=tempAcc.Id,
            WinReason__c='Loyalty'
        );
        insert tempOpp;
        
        SalesOrder__c testOrder = new SalesOrder__c(
            Name = 'Test Order',
            Status__c = 'Booked',
            Unit__c =testUnit.id,
            Account__c = tempAcc.Id,
            Opportunity__c=tempOpp.Id
        );
        insert testOrder;
        
        InstallmentLines__c installmentLines = new InstallmentLines__c();
        installmentLines.PaymentPlan__c = pp.id;
        installmentLines.PaymentInstallments__c =ppi.Id;
        installmentLines.SalesOrder__c = testOrder.id;
        installmentLines.Description__c='4th Installment';
        installmentLines.InstallmentAmount__c = 100000;
        installmentLines.LPCCutOffAmt__c =0;
        installmentLines.MinInvAmtrem__c =100;
        installmentLines.LPCRate__c =12;
        installmentLines.InstallmentPercentage__c = 25;
        installmentLines.BrokerPayoutPercentage__c = 20;
        installmentLines.Description__c = 'Description';
        installmentLines.RevisedDate__c=null;
        installmentLines.GracePeriod__c=1;
        installmentLines.InstallmentAmount__c =70000;
        installmentLines.Inst_inc_tax_in_words__c  = '';
        installmentLines.InstallmentDate__c= Date.today() - 12;
        installmentLines.AmountReceived__c=1500;
        installmentLines.CutOffDate__c=date.today();
        installmentLines.LPCAmount__c=500;
        
        insert installmentLines;

        SalesOrderOtherCharges__c soc = TestDataFactory.createOtherCharge(testOrder.id, tempAcc.id, 'ADM Fee', false, null, null, null, null, null, 12000);
        insert soc;

        ReceiptAcknowledgement__c testData1 = TestDataFactory.createReceiptAcknowledgement(tempOpp.id, 'Online', 12000, tempAcc.Id, 'Received', null, testOrder.id);
        insert testData1;

        ReceiptAllocation__c rec = TestDataFactory.createReceiptAllocation(testData1.id, tempAcc.id, installmentLines.id, 12000, null);
        insert rec;
    }
    
     @isTest
    private static void testCreateIntegrationRecord(){
        Test.startTest();
		List<BrokerCommission__c> bcList = [SELECT Id FROM BrokerCommission__c LIMIT 1];
        bcList[0].SecondApprovalStatus__c = 'Approved';
        update bcList;

        Test.stopTest();

        BrokerCommission__c updatedBc = [SELECT Id, IntegrationStatus__c, IntegrationMessage__c FROM BrokerCommission__c WHERE Id = :bcList[0].Id LIMIT 1];
        Assert.areEqual('In Progress', updatedBc.IntegrationStatus__c,'Integration should be In Progress');
        Assert.isTrue(String.isBlank(updatedBc.IntegrationMessage__c),'Integration message should be reset to blank');

        List<IntegrationRecord__c> integrationRecList = [SELECT Id, RecordId__c FROM IntegrationRecord__c WHERE RecordId__c = :updatedBc.Id];
        Assert.areEqual(1, integrationRecList.size(),'One integration record should be created for approved broker commission.');
    }

    @isTest
    private static void testCreateIntegrationRecordForFinalApprovalAndERPDates(){
        List<BrokerCommission__c> bcList = [SELECT Id, SecondApprovalStatus__c, FinalApprovalStatus__c FROM BrokerCommission__c LIMIT 1];
        bcList[0].SecondApprovalStatus__c = 'Approved';
        bcList[0].FinalApprovalStatus__c = 'Approved';

        Test.startTest();
        update bcList;
        Test.stopTest();

        BrokerCommission__c updatedBc = [
            SELECT Id, ERPConditionCreatedDate__c, FirstIntegrationDate__c, ERPPostedDate__c, IntegrationStatus__c
            FROM BrokerCommission__c
            WHERE Id = :bcList[0].Id
            LIMIT 1
        ];
        Assert.areEqual('In Progress', updatedBc.IntegrationStatus__c, 'Integration status should stay In Progress.');

        List<IntegrationRecord__c> integrationRecList = [
            SELECT Id, Action__c, RecordId__c
            FROM IntegrationRecord__c
            WHERE RecordId__c = :updatedBc.Id
        ];
        Assert.areEqual(2, integrationRecList.size(), 'Two integration records should be created (Insert + Update).');
    }

    @isTest
    private static void testUpdateBrokerCommissionStatusDates(){
        List<BrokerCommission__c> reversedCase = [SELECT Id, Status__c, ReversalDate__c FROM BrokerCommission__c LIMIT 1];
        reversedCase[0].Status__c = 'Reversed';

        List<BrokerCommission__c> paymentInitiatedCase = [SELECT Id, Status__c, PaymentInitiatedDate__c FROM BrokerCommission__c LIMIT 1 OFFSET 1];
        paymentInitiatedCase[0].Status__c = 'Payment Initiated';

        Test.startTest();
        update reversedCase;
        update paymentInitiatedCase;
        Test.stopTest();

        BrokerCommission__c reversedRecord = [SELECT Id, ReversalDate__c FROM BrokerCommission__c WHERE Id = :reversedCase[0].Id LIMIT 1];
        BrokerCommission__c paymentInitiatedRecord = [SELECT Id, PaymentInitiatedDate__c FROM BrokerCommission__c WHERE Id = :paymentInitiatedCase[0].Id LIMIT 1];

        Assert.isNotNull(reversedRecord.ReversalDate__c, 'Reversal date should be set when status becomes Reversed.');
        Assert.isNotNull(paymentInitiatedRecord.PaymentInitiatedDate__c, 'Payment initiated date should be set when status becomes Payment Initiated.');
    }

    @isTest
    private static void testSendEmailToRelatedContacts(){  
        Test.startTest();
        List<BrokerCommission__c> bcList = [SELECT Id FROM BrokerCommission__c LIMIT 1];
        bcList[0].Status__c = 'Paid';
        update bcList;
        Test.stopTest();

        BrokerCommission__c updatedBc = [SELECT Id, Status__c FROM BrokerCommission__c WHERE Id = :bcList[0].Id LIMIT 1];
        Assert.areEqual('Paid', updatedBc.Status__c, 'Status should be updated to Paid.');
    }
    
}