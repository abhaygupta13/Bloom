@istest
public class installmentMilestoneUpdationCtlrTest {
    @istest
    static void milestoneInstallmentUpdationTestmethod(){
        List<milestone__c> mlist = new List<milestone__c>();
        milestone__c m = new milestone__c();
        m.Milestone_Date__c = date.valueof(system.now());
        m.Milestone_Status__c = 'Reached';
        m.Name = 'Test milestone';
        insert m;
       
          
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
        
        BuildingSectionMapping__c mappingRecord = new BuildingSectionMapping__c();
        mappingRecord.BuildingSectionName__c = testBuilding.id;
        mappingRecord.PaymentPlan__c = pp.id;
        insert mappingRecord;
        
        
        
        
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
       
        
        PaymentInstallments__c ppi = new PaymentInstallments__c();
        ppi.BrokerPayoutPercentage__c =100;
        ppi.Description__c = 'test description';
        ppi.InstallmentNumber__c = 1;
        ppi.InstallmentPercentage__c=100;
        ppi.PaymentPlan__c = pp.id;
        ppi.InstallmentPercentage__c=100;
        ppi.Condition_Type__c='P012';
        ppi.Milestone__c = m.id;
        insert ppi;
        
       pp.IsActive__c = 'Yes';
        Update pp;
        
        SalesOrder__c testOrder = new SalesOrder__c(
            Name = 'Test Order',
            Status__c = 'Sold',
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
        ReceiptAcknowledgement__c testRecAck1= new ReceiptAcknowledgement__c(
        Opportunity__c=tempOpp.id,
            PaymentType__c='Cheque',
            Amount__c=100,
            Account__c= tempAcc.id,
            Status__c = 'Received',
            MaturityDate__c = System.today().addDays(3),
            SalesOrder__c = testOrder.id 
            );
        insert testRecAck1;
            
            
            ReceiptAllocation__c newReceiptAllocation = new ReceiptAllocation__c();
        newReceiptAllocation.ReceiptAcknowledgement__c =testRecAck1.id;
        newReceiptAllocation.AmountApplied__c = 10000;
        newReceiptAllocation.SalesOrder__c = testOrder.id;
        newReceiptAllocation.Account__c = tempAcc.id;
        newReceiptAllocation.DateOfApplication__c = Date.today();
        newReceiptAllocation.InstallmentLine__c = installmentLines.id;
        Insert newReceiptAllocation;
        
       
            testRecAck1.Milestone__c = m.id;
          
            update testRecAck1;
            
       
   
        
        installmentMilestoneUpdationCtlr.Installments(m.id);
      
    }
}