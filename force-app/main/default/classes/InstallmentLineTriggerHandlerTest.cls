@isTest
public class InstallmentLineTriggerHandlerTest {
    @isTest static void InstallmentLineTriggerHandlerTestMethod(){
        
        
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
        insert ppi;
        
        pp.IsActive__c = 'Yes';
        Update pp;
        
        SalesOrder__c testOrder = new SalesOrder__c(
            Name = 'Test Order',
            Status__c = 'Booked',
            Unit__c =testUnit.id,
            Account__c = tempAcc.Id,
            Opportunity__c=tempOpp.Id
            
            
        );
        insert testOrder;
        
        Set<Id> salesOrderSet = new Set<Id>();
        salesOrderSet.add(testOrder.Id);
        
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
        installmentLines.Send_to_SAP__c = true;
        installmentLines.GracePeriod__c=1;
        installmentLines.InstallmentAmount__c =70000;
        installmentLines.Inst_inc_tax_in_words__c  = '';
        installmentLines.InstallmentDate__c= Date.today() - 12;
        installmentLines.AmountReceived__c=1500;
        installmentLines.CutOffDate__c=date.today();
        installmentLines.LPCAmount__c=500;
        
        insert installmentLines;
        Map<id,InstallmentLines__c> installMap = new Map<id,InstallmentLines__c>();
        installMap.put(installmentLines.id,installmentLines);
        
        InstallmentLineService instLin = InstallmentLineService.getInstance();
        instLin.getInstallmentLinesBySalesOrder(salesOrderSet);
        instLin.getHOAndPHPPInstallmentLinesBySalesOrderIds(salesOrderSet);
        instLin.getDPInstallmentLinesBySalesOrder(salesOrderSet);
            
        InstallmentLineTriggerHelper.handleBeforeUpdate(New List<InstallmentLines__c>{installmentLines},installMap);
        
    }
    @isTest static void InstallmentLineTriggerHandlerTestMethod2(){
        
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
        insert ppi;
        
        pp.IsActive__c = 'Yes';
        Update pp;
        
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
        installmentLines.Send_to_SAP__c = true;
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
        
        
        
        InstallmentLineTriggerHelper.handleBeforeInsert(New List<InstallmentLines__c>{installmentLines});
        
    }
    @isTest static void InstallmentLineTriggerHandlerTestMethod3(){
        
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
        insert ppi;
        
        pp.IsActive__c = 'Yes';
        Update pp;
        
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
        Test.startTest();
        
        installmentLines.Send_to_SAP__c = true;
        update installmentLines;
        installmentLines.RevisedDate__c = System.today()+60;
        update installmentLines;
        
        Test.stopTest();
        
        InstallmentLineTriggerHelper.handleBeforeInsert(New List<InstallmentLines__c>{installmentLines});
        
    }
    @isTest static void testDeletion(){
        
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
        insert ppi;
        
        pp.IsActive__c = 'Yes';
        Update pp;
        
        SalesOrder__c testOrder = new SalesOrder__c(
            Name = 'Test Order',
            Status__c = 'Booked',
            Unit__c =testUnit.id,
            Account__c = tempAcc.Id,
            Opportunity__c=tempOpp.Id,
            Resale__c = false 
            
            
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
        Test.startTest();
        delete installmentLines;
        Test.stopTest();     
    }
    
    @isTest
    static void testHandleAfterUpdate1(){
        
        Project__c testProject = new Project__c(
            Name='Test Project'
        );
        insert testProject;
        
        BuildingSection__c testBuilding = new BuildingSection__c(
            Name='Test Building',
            BuildingSectionCode__c='BL-CAS',
            Project__c=testProject.Id
        );
        insert testBuilding;
        
        Unit__c testUnit = new Unit__c(
            Name='test Unit',
            Status__c='Available',
            UnitType__c='Townhouse',
            BuildingSectionName__c=testBuilding.Id,
            Project__c=testProject.Id,
            PropertyUsage__c='Residential',
            UnitView__c='Beach Side',
            FloorNumber__c='01',
            NumberOfBedrooms__c='3',
            UnitModel__c='1BHK',
            SellingPrice__c=700000,
            EndDate__c=Date.today()+10,
            StartDate__c=Date.today()-10
        );
        insert testUnit;
        
        PaymentPlan__c pp = new PaymentPlan__c(
            Name='July Plan',
            Unit__c=testUnit.Id,
            Description__c='Test',
            IsActive__c='NO',
            BrokerPortalFlag__c=true,
            Classification__c=Constants.PAYMENT_PLAN_TYPE_STANDARD
        );
        insert pp;
        
        BuildingSectionMapping__c mappingRecord = new BuildingSectionMapping__c();
        mappingRecord.BuildingSectionName__c = testBuilding.Id;
        mappingRecord.PaymentPlan__c = pp.Id;
        insert mappingRecord;
        
        Id accountRecordTypeId =
            Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('PersonAccount')
            .getRecordTypeId();
        
        Account tempAcc = new Account(
            RecordTypeId=accountRecordTypeId,
            LastName='Test',
            personEmail='test@gmail.com'
        );
        insert tempAcc;
        
        Opportunity opp = new Opportunity(
            Name='Test Opp',
            StageName='New',
            CloseDate=Date.today(),
            LeadChannel__c='Walk in',
            AccountId=tempAcc.Id,
            WinReason__c='Loyalty'
        );
        insert opp;
        
        PaymentInstallments__c ppi = new PaymentInstallments__c(
            BrokerPayoutPercentage__c=100,
            Description__c='Test',
            InstallmentNumber__c=1,
            InstallmentPercentage__c=100,
            PaymentPlan__c=pp.Id,
            Condition_Type__c='P012'
        );
        insert ppi;
        
        pp.IsActive__c = 'Yes';
        update pp;
        
        SalesOrder__c so = new SalesOrder__c(
            Name='SO Test',
            Status__c='Booked',
            Unit__c=testUnit.Id,
            Account__c=tempAcc.Id,
            Opportunity__c=opp.Id
        );
        insert so;
        
        // MAIN INSTALLMENT
        InstallmentLines__c ins = new InstallmentLines__c(
            PaymentPlan__c = pp.Id,
            PaymentInstallments__c = ppi.Id,
            SalesOrder__c = so.Id,
            Description__c = 'Handover Installment',
            InstallmentAmount__c = 10000,
            LPCCutOffAmt__c = 0,          // was missing
            MinInvAmtrem__c = 100,         // was missing
            LPCRate__c = 12,               // was missing
            InstallmentPercentage__c = 25,
            BrokerPayoutPercentage__c = 20,
            InstallmentDate__c = Date.today()+30,
            RevisedDate__c = Date.today()+30,
            GracePeriod__c = 1,            // was missing
            Inst_inc_tax_in_words__c = '', // was missing
            AmountReceived__c = 1500,      // was missing
            CutOffDate__c = Date.today(),  // was missing
            LPCAmount__c = 500,            // was missing
            Type__c = 'Handover',
            Send_to_SAP__c = false
        );
        insert ins;
        
        // POST HANDOVER INSTALLMENT
        InstallmentLines__c postHO = new InstallmentLines__c(
            PaymentPlan__c = pp.Id,
            PaymentInstallments__c = ppi.Id,
            SalesOrder__c = so.Id,
            Description__c = 'Post HO',
            InstallmentAmount__c = 5000,
            LPCCutOffAmt__c = 0,          // was missing
            MinInvAmtrem__c = 100,         // was missing
            LPCRate__c = 12,               // was missing
            InstallmentPercentage__c = 10,
            BrokerPayoutPercentage__c = 20,
            InstallmentDate__c = Date.today()+90,
            GracePeriod__c = 1,            // was missing
            Inst_inc_tax_in_words__c = '', // was missing
            AmountReceived__c = 0,         // was missing
            CutOffDate__c = Date.today(),  // was missing
            LPCAmount__c = 0,              // was missing
            Type__c = 'Post Handover Installment',
            Send_to_SAP__c = false
        );
        insert postHO;
        
        // RECEIPT ACKNOWLEDGEMENT
        ReceiptAcknowledgement__c ra = new ReceiptAcknowledgement__c(
            Account__c = tempAcc.Id,
            Opportunity__c = opp.Id,
            SalesOrder__c = so.Id,
            Amount__c = 1000,
            PaymentType__c = 'Cheque',
            ReferenceNumber__c = '564372',
            Status__c = 'Received'       
        );
        insert ra;
        
        // RECEIPT ALLOCATION 
        ReceiptAllocation__c alloc = new ReceiptAllocation__c(
            InstallmentLine__c = ins.Id,
            ReceiptAcknowledgement__c = ra.Id,
            Account__c = tempAcc.Id,
            AmountApplied__c = 1000      
        );
        insert alloc;
        
        Test.startTest();
        ins.Send_to_SAP__c = true;
        ins.RevisedDate__c = Date.today()+60;
        ins.SAP_Document_No__c = 'SAP123';
        
        update ins;
        Test.stopTest();
        
        // Verify post handover installment updated
        InstallmentLines__c updatedPostHO = [
            SELECT Id, RevisedDate__c, Send_to_SAP__c
            FROM InstallmentLines__c
            WHERE Id = :postHO.Id
        ];
        System.assertEquals(true, updatedPostHO.Send_to_SAP__c);
        
        // Verify receipt acknowledgement updated
        ReceiptAcknowledgement__c updatedRA = [
            SELECT Id, SendtoSAP__c
            FROM ReceiptAcknowledgement__c
            WHERE Id = :ra.Id
        ];
        System.assertEquals(true, updatedRA.SendtoSAP__c);
    }
}