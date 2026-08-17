@isTest
public class LPCGenerationTest {
    @isTest static void LPCGenerationTest(){
        
        List<String>salesorderIds = new List<String>();
        Id AccountRecordTypeId = [Select id,Name from RecordType where Name='Organization Account'].id;
         Account tempAcc=new Account(
            RecordTypeId=AccountRecordTypeId,
            Name= 'test'
            
        );
        
        insert tempAcc;
       
        
        
        Contact tempContact =new Contact(
            LastName='test',
            AccountId= tempAcc.id,
            Email='test@gmail.com'
        );
        insert tempContact;
        Opportunity tempOpp=new Opportunity(
            Name='tempOpp',
            StageName='New',
            CloseDate=system.today(),
            LeadChannel__c='Walk in',
           // LeadSubSource__c='Open House',
            AccountId=tempAcc.Id,
            ContactId=tempContact.id,
            Contact__c=tempContact.id,
            WinReason__c='Loyalty'
        );
        insert tempOpp;
      
        
        
        
        Project__c testProject=new Project__c(
            Name='Test Project'
        );
        insert testProject;
        
        OffersPromotions__c  offername = new OffersPromotions__c();
        offerName.OfferName__c = 'test offer';
        offerName.StartDate__c = system.today();
        offerName.EndDate__c=system.today().addDays(10);
        offerName.Project__c = testProject.id;
        
        
        insert offername;
        
        OfferLines__c offerLine = new OfferLines__c();
        offerLine.OfferName__c = offername.Id;
        offerLine.OfferType__c='Additional Discount';
        offerLine.OfferOn__c= 'Selling Price';
        offerLine.OfferValue__c =20000;
        
        insert offerLine;
        
        String testQuery = 'SELECT Id, Name FROM OfferLines__c WHERE Name = \'test offer\''; 
        
        BookingMemo__c BM = new BookingMemo__c();
        insert BM;
        
        
        MemoLines__c memo = new MemoLines__c();
        memo.BookingMemo__c = BM.id;
        
        
        
        insert memo;
        
        
        
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
            SellingPrice__c= 700000
            
        );
        insert testUnit;
        
        
        
        SalesOrder__c testOrder = new SalesOrder__c(
            Name = 'Test Order',
            Status__c = 'Sold',
            Contact__c=tempContact.id,
            Unit__c =testUnit.id,
            Account__c = tempAcc.Id,
            Opportunity__c=tempOpp.Id
            
            
        );
        insert testOrder;
        List<SalesOrder__c>salesorderprojectname =[select id,ProjectName__c From SalesOrder__c where id=:testOrder.id ];
        System.debug(salesorderprojectname);
        
        salesorderIds.add(testOrder.Name);
        
        PaymentPlan__c paymentPlan = new PaymentPlan__c();
        paymentPlan.Name = 'Test';
        paymentPlan.Description__c = 'Test';
        paymentPlan.BrokerPortalFlag__c = True;
       // paymentPlan.Classification__c = Constants.PAYMENT_PLAN_TYPE_STANDARD;
        insert  paymentPlan;
        
        PaymentInstallments__c paymentInstallment = new PaymentInstallments__c();
            paymentInstallment.InstallmentNumber__c = 2;
            paymentInstallment.InstallmentPercentage__c = 2;
            paymentInstallment.BrokerPayoutPercentage__c = 2;
            paymentInstallment.PaymentPlan__c = paymentPlan.id;
            paymentInstallment.Description__c = 'Installment Description';
            paymentInstallment.Condition_Type__c='P012';
           insert paymentInstallment;
        
         InstallmentLines__c installmentLines = new InstallmentLines__c();
            installmentLines.PaymentPlan__c = paymentPlan.id;
            installmentLines.PaymentInstallments__c = paymentInstallment.Id;
           // installmentLines.InstallmentNumber__c = installmentNo;
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
           // installmentLines.AmountReceived__c =70000;
            installmentLines.InstallmentAmount__c =70000;
           installmentLines.InstallmentDate__c= Date.today() - 12;
           installmentLines.AmountReceived__c=1500;
           installmentLines.CutOffDate__c=date.today();
           installmentLines.LPCAmount__c=500;
           installmentLines.LPCAmountGen__c =100000;
          
            insert installmentLines;
        
      System.debug(installmentLines);
        
        InstallmentLines__c installmentLines1 = new InstallmentLines__c();
            installmentLines1.PaymentPlan__c = paymentPlan.id;
            installmentLines1.PaymentInstallments__c = paymentInstallment.Id;
           // installmentLines.InstallmentNumber__c = installmentNo;
            installmentLines1.SalesOrder__c = testOrder.id;
            installmentLines1.Description__c='4th Installment';
            installmentLines1.InstallmentAmount__c = 100000;
            installmentLines1.LPCCutOffAmt__c =-50000;
            installmentLines1.MinInvAmtrem__c =100;
            installmentLines1.LPCRate__c =12;
            installmentLines1.InstallmentPercentage__c = 25;
            installmentLines1.BrokerPayoutPercentage__c = 20;
            installmentLines1.Description__c = 'Description';
           installmentLines1.RevisedDate__c=null;
            installmentLines1.GracePeriod__c=1;
           // installmentLines.AmountReceived__c =70000;
            installmentLines1.InstallmentAmount__c =70000;
           installmentLines1.InstallmentDate__c= Date.today() - 12;
           installmentLines1.AmountReceived__c=1500;
           installmentLines1.CutOffDate__c=date.today();
           
          
          
            insert installmentLines1;
        
        
         Id installmentNumberId = installmentLines.id;
        Id installmentNumberId1 = installmentLines1.id;
        Date dueDate = Date.today();
        Date dueDate1 = Date.today()-10;
        Integer daysSinceDue = 10;
        Decimal gracePeriod = 5;
        Decimal gracePeriod1 = 0;
        Date cutOffDate = Date.today().addDays(-3);
        Decimal lpcCutOffAmt = 1000;
        Decimal minInvAmtRem = 500;
        Decimal lpcRate = 0.10;
        Decimal installmentAmt = 1500;
        
        ReceiptAcknowledgement__c newReceiptAcknowledgement = new ReceiptAcknowledgement__c();
         newReceiptAcknowledgement.PaymentType__c = 'Online';
        newReceiptAcknowledgement.Amount__c = 100000;
        newReceiptAcknowledgement.SalesOrder__c = testOrder.id;
        newReceiptAcknowledgement.Opportunity__c = tempOpp.id;
        newReceiptAcknowledgement.Account__c = tempAcc.id;
        newReceiptAcknowledgement.Remarks__c = 'Test Remark';
        newReceiptAcknowledgement.CustomerBankAccount__c = '1234567890';
        newReceiptAcknowledgement.ReferenceNumber__c = '1234567890';
        newReceiptAcknowledgement.MortgageCheque__c = true;
        newReceiptAcknowledgement.MaturityDate__c = Date.today();
        
        insert newReceiptAcknowledgement;
        
        
        
         ReceiptAllocation__c newReceiptAllocation = new ReceiptAllocation__c();
        newReceiptAllocation.ReceiptAcknowledgement__c = newReceiptAcknowledgement.id;
        newReceiptAllocation.AmountApplied__c = 10000;
        newReceiptAllocation.SalesOrder__c = testOrder.id;
        newReceiptAllocation.Account__c = tempAcc.id;
        newReceiptAllocation.DateOfApplication__c = Date.today();
        newReceiptAllocation.InstallmentLine__c=installmentLines.id;
        insert newReceiptAllocation;
        
         ReceiptAllocation__c newReceiptAllocation1 = new ReceiptAllocation__c();
        newReceiptAllocation1.ReceiptAcknowledgement__c =newReceiptAcknowledgement.id;
        newReceiptAllocation1.AmountApplied__c = 0;
        
        newReceiptAllocation1.SalesOrder__c = testOrder.id;
        newReceiptAllocation1.Account__c = tempAcc.id;
        newReceiptAllocation1.DateOfApplication__c = Date.today();
        newReceiptAllocation1.InstallmentLine__c=installmentLines1.id;
        insert newReceiptAllocation1;
       
       
        LPCGeneration.genLpcs('testProject','Y');
        LPCGeneration.genLpcs('Test Project','N');
       
    }
    @isTest static void LPCGenerationTest2(){
        
        List<String>salesorderIds = new List<String>();
        Id AccountRecordTypeId = [Select id,Name from RecordType where Name='Organization Account'].id;
         Account tempAcc=new Account(
            RecordTypeId=AccountRecordTypeId,
            Name= 'test'
            
        );
        
        insert tempAcc;
       
        
        
        Contact tempContact =new Contact(
            LastName='test',
            AccountId=tempAcc.id,
            Email='test@gmail.com'
        );
        insert tempContact;
        Opportunity tempOpp=new Opportunity(
            Name='tempOpp',
            StageName='New',
            CloseDate=system.today(),
            LeadChannel__c='Walk in',
           // LeadSubSource__c='Open House',
            AccountId=tempAcc.Id,
            ContactId=tempContact.id,
            Contact__c=tempContact.id,
            WinReason__c='Loyalty'
        );
        insert tempOpp;
      
        
        
        
        Project__c testProject=new Project__c(
            Name='Test Project'
        );
        insert testProject;
        
        OffersPromotions__c  offername = new OffersPromotions__c();
        offerName.OfferName__c = 'test offer';
        offerName.StartDate__c = system.today();
        offerName.EndDate__c=system.today().addDays(10);
        offerName.Project__c = testProject.id;
        
        
        insert offername;
        
        OfferLines__c offerLine = new OfferLines__c();
        offerLine.OfferName__c = offername.Id;
        offerLine.OfferType__c='Additional Discount';
        offerLine.OfferOn__c= 'Selling Price';
        offerLine.OfferValue__c =20000;
        
        insert offerLine;
        
        String testQuery = 'SELECT Id, Name FROM OfferLines__c WHERE Name = \'test offer\''; 
        
        BookingMemo__c BM = new BookingMemo__c();
        insert BM;
        
        
        MemoLines__c memo = new MemoLines__c();
        memo.BookingMemo__c = BM.id;
        
        
        
        insert memo;
        
        
        
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
            SellingPrice__c= 700000
            
        );
        insert testUnit;
        
        
        
        SalesOrder__c testOrder = new SalesOrder__c(
            Name = 'Test Order',
            Status__c = 'Sold',
            Contact__c=tempContact.id,
            Unit__c =testUnit.id,
            Account__c = tempAcc.Id,
            Opportunity__c=tempOpp.Id
            
            
        );
        insert testOrder;
        List<SalesOrder__c>salesorderprojectname =[select id,ProjectName__c From SalesOrder__c where id=:testOrder.id ];
        System.debug(salesorderprojectname);
        
        salesorderIds.add(testOrder.Name);
        
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
        
       pp.IsActive__c = 'Yes';
        Update pp;
       
         InstallmentLines__c installmentLines = new InstallmentLines__c();
            installmentLines.PaymentPlan__c = pp.id;
            installmentLines.PaymentInstallments__c = ppi.Id;
           // installmentLines.InstallmentNumber__c = installmentNo;
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
           // installmentLines.AmountReceived__c =70000;
            installmentLines.InstallmentAmount__c =70000;
           installmentLines.InstallmentDate__c= Date.today() - 12;
           installmentLines.AmountReceived__c=1500;
           installmentLines.CutOffDate__c=date.today();
           installmentLines.LPCAmount__c=500;
           installmentLines.LPCAmountGen__c =100000;
          
            insert installmentLines;
        
      System.debug(installmentLines);
        
        InstallmentLines__c installmentLines1 = new InstallmentLines__c();
            installmentLines1.PaymentPlan__c = pp.id;
            installmentLines1.PaymentInstallments__c = ppi.Id;
           // installmentLines.InstallmentNumber__c = installmentNo;
            installmentLines1.SalesOrder__c = testOrder.id;
            installmentLines1.Description__c='4th Installment';
            installmentLines1.InstallmentAmount__c = 100000;
            installmentLines1.LPCCutOffAmt__c =-50000;
            installmentLines1.MinInvAmtrem__c =100;
            installmentLines1.LPCRate__c =12;
            installmentLines1.InstallmentPercentage__c = 25;
            installmentLines1.BrokerPayoutPercentage__c = 20;
            installmentLines1.Description__c = 'Description';
           installmentLines1.RevisedDate__c=null;
            installmentLines1.GracePeriod__c=1;
           // installmentLines.AmountReceived__c =70000;
            installmentLines1.InstallmentAmount__c =70000;
           installmentLines1.InstallmentDate__c= Date.today() - 12;
           installmentLines1.AmountReceived__c=1500;
           installmentLines1.CutOffDate__c=date.today();
           
          
          
            insert installmentLines1;
        
        
         Id installmentNumberId = installmentLines.id;
        Id installmentNumberId1 = installmentLines1.id;
        Date dueDate = Date.today();
        Date dueDate1 = Date.today()-10;
        Integer daysSinceDue = 10;
        Decimal gracePeriod = 0;
        Decimal gracePeriod1 = 0;
        Date cutOffDate = Date.today().addDays(-3);
        Decimal lpcCutOffAmt = 1000;
        Decimal minInvAmtRem = 500;
        Decimal lpcRate = 0.10;
        Decimal installmentAmt = 1500;
        
        ReceiptAcknowledgement__c newReceiptAcknowledgement = new ReceiptAcknowledgement__c();
         newReceiptAcknowledgement.PaymentType__c = 'Online';
        newReceiptAcknowledgement.Amount__c = 10000;
        newReceiptAcknowledgement.SalesOrder__c = testOrder.id;
        newReceiptAcknowledgement.Opportunity__c = tempOpp.id;
        newReceiptAcknowledgement.Account__c = tempAcc.id;
        newReceiptAcknowledgement.Remarks__c = 'Test Remark';
        newReceiptAcknowledgement.CustomerBankAccount__c = '1234567890';
        newReceiptAcknowledgement.ReferenceNumber__c = '1234567890';
        newReceiptAcknowledgement.MortgageCheque__c = true;
        newReceiptAcknowledgement.MaturityDate__c = Date.today();
        
        insert newReceiptAcknowledgement;
        
        
        
         ReceiptAllocation__c newReceiptAllocation = new ReceiptAllocation__c();
        newReceiptAllocation.ReceiptAcknowledgement__c = newReceiptAcknowledgement.id;
        newReceiptAllocation.AmountApplied__c = 10000;
        newReceiptAllocation.SalesOrder__c = testOrder.id;
        newReceiptAllocation.Account__c = tempAcc.id;
        newReceiptAllocation.DateOfApplication__c = Date.today();
        newReceiptAllocation.InstallmentLine__c=installmentLines.id;
        insert newReceiptAllocation;
        
         ReceiptAllocation__c newReceiptAllocation1 = new ReceiptAllocation__c();
        newReceiptAllocation1.ReceiptAcknowledgement__c =newReceiptAcknowledgement.id;
        newReceiptAllocation1.AmountApplied__c = 0;
        
        newReceiptAllocation1.SalesOrder__c = testOrder.id;
        newReceiptAllocation1.Account__c = tempAcc.id;
        newReceiptAllocation1.DateOfApplication__c = Date.today();
        newReceiptAllocation1.InstallmentLine__c=installmentLines1.id;
        insert newReceiptAllocation1;
       
       
      
        LPCGeneration.genLpcssalesorder(salesorderIds);
      LPCGeneration.calcLpcForInv(installmentLines.id, DueDate, DayssinceDue, GracePeriod, CutOffDate, LPCCutOffAmt, MinInvAmtrem, LPCRate,null);
     //LPCGeneration.calcLpcForInv(installmentLines.id, DueDate, DayssinceDue, GracePeriod, CutOffDate, LPCCutOffAmt, MinInvAmtrem, LPCRate, InstallmentAmt);
     
         LPCGeneration.ReplaceNull(20,22);
    }
    


}