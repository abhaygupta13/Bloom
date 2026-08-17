/*****************************************************************************************
Class       : IntegrationControllerTest
Author      : Vikas Baliyan
Description : Integration Controller Test
Test Class  : 
Created Date: 04 Feb 2025 
*****************************************************************************************/
@isTest
public class IntegrationControllerTest {
    @testSetup
    private static void testData() {
        Project__c project = new Project__c();
        project.Name = 'TEST';
        project.ProjectRegistrationDate__c = Date.today() - 1;
        insert project;
        
        List<BrokerCommission__c> bcList = new List<BrokerCommission__c>();
        for(Integer i = 0; i<20; i++){
            BrokerCommission__c bc = TestDataFactory.createBrokerCommission(25000, 5, null, null, null, project.Id, null, null, null, null);
            bc.FirstApprovalStatus__c = 'Not Approved'; bc.IntegrationStatus__c = 'In Progress';bc.InvoiceDate__c = date.today();
            bcList.add(bc);
        }
        insert bcList;
        Account account = TestDataFactory.createPersonalAccount('name1', 'Emirates_Id', '1234567890','abc@pqr.xyz');
        insert account;
        
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
        
         test.StartTest();
        //Id personAccountRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, 'PersonAccount');
        
        Account acc = new Account(
            RecordTypeId = AccountRecordTypeId ,
            LastName = 'Test Person Account', 
            Phone = '971202520',
            PersonEmail='abc@gmail.com',
            Nationality__c = 'Indian',
            
            PrimaryMobilePhone__pc = '1234567890',
           
            SecondaryMobilePhone__pc = '9876543210',
            
            TertiaryMobilePhone__pc = '1122334455'
        );
        insert acc;
        
        DocumentType__c dc1 = TestDataFactory.createDocumentType('Opportunity', 'Emirates ID');
        dc1.Customer_Type__c = 'Individual';
        insert dc1;
        
        DocumentType__c dc2 = TestDataFactory.createDocumentType('Opportunity', 'Visa');
        dc2.Customer_Type__c = 'Individual';
        insert dc2;
        
        DocumentType__c dc3 = TestDataFactory.createDocumentType('LeasingOrder__c', 'Emirates ID');
        dc3.Customer_Type__c = 'Individual';
        insert dc3;
        
        DocumentType__c dc4 = TestDataFactory.createDocumentType('LeasingOrder__c', 'Visa');
        dc4.Customer_Type__c = 'Individual';
        insert dc4;
        
         DocumentType__c dc5 = TestDataFactory.createDocumentType('LeasingOrder__c', 'Leasing Offer');
        dc5.Customer_Type__c = 'Individual';
        insert dc5;
        
        DocumentType__c dc6 = TestDataFactory.createDocumentType('Opportunity', 'Leasing Offer');
        dc6.Customer_Type__c = 'Individual';
        insert dc6;
        
        
        Opportunity opp = new Opportunity(
            Name='Test Opp',
            StageName='Prospecting',
            OpportunityType__c = 'Leasing',
            CloseDate=System.today().addDays(30),
            AccountId=acc.Id
        );
        insert opp;
        
        Document__c doc = new Document__c(Document_Name__c='testDoc', Opportunity__c=opp.Id);
        insert doc;
        
        //Project__c
        Project__c objProject = new Project__c();
        objProject.Name = 'Test Project';
        objProject.IsAvailableforLeasing__c = true;
        objProject.EjariTawtheeqFee__c = 200;
        objProject.AdminFee__c = 20;
        objProject.LeasingServiceCharge__c = 20;
        objProject.SecurityDeposit__c = 20;
        insert objProject;
        
        Building__c building = TestDataFactory.createBuilding('Building 1', objProject.Id);
        insert building;
        
        Unit__c unitRec = new Unit__c(Name='TestU', LeasingAnnualRent__c=10000,
                                      Project__c= objProject.Id, Building__c = building.Id, LeasingUnitStatus__c = 'Available',
                                      IsAvailableforLeasing__c = true, PropertyUsage__c = 'Commercial' );
        insert unitRec;
        
        LeasingOfferPromotion__c objLeasingOfferPromo = new LeasingOfferPromotion__c();
        objLeasingOfferPromo.Name = 'Test Promo';
        insert objLeasingOfferPromo;
        
        LeasingOfferLines__c objOfferLines = new LeasingOfferLines__c();
        objOfferLines.OfferName__c = objLeasingOfferPromo.Id;
        objOfferLines.OfferValueType__c = '%';
        objOfferLines.OfferValue__c = 1;
        objOfferLines.OfferType__c = 'Additional Discount';
        insert objOfferLines;
        
        // Insert Offer + OfferLine (required for getOfferLineDiscountSum)
        LeasingOffer__c offer = new LeasingOffer__c(Name='TestOffer', LeasingOfferPromotion__c=objLeasingOfferPromo.Id);
        insert offer;
        
        // Insert minimal LeasingOrder
        LeasingOrder__c lo = new LeasingOrder__c(
            Name='Test Contract',
            Opportunity__c = opp.Id,
            Account__c = acc.Id,
            Unit__c = unitRec.Id,
            LeasingStartDate__c = System.today(),
            LeasingEndDate__c = System.today().addYears(1),
            LeasingContractMonths__c=12,
            PaymentTerm__c='4 Installments',
            SecurityDeposit__c = 100,
            ExtraChequeFee__c  = 200,
            AdminFee__c = 100,
            FitOutSecurityDeposit__c  = 300,
            EjariTawtheeqFee__c = 200
            
        );
        insert lo;
        
        // Insert sample escalation
        insert new LeasingEscalationSchedule__c(
            LeasingOrder__c = lo.Id, Year__c = 1,
            AfterDiscount__c = 12000
        );

        LeasingReceiptAcknowledgment__c receipt = new LeasingReceiptAcknowledgment__c(
            LeasingOrder__c = lo.Id,
            Amount__c = 10000
        );
        insert receipt;

                List<LeasingOrdersOtherCharges__c> chargesList = new List<LeasingOrdersOtherCharges__c>();
        for(Integer i=1; i<=2; i++){
            chargesList.add(new LeasingOrdersOtherCharges__c(
                LeasingOrder__c = lo.Id,
                Type__c = 'Admin Fee',
                ChargeAmount__c = 1000 * i,
                VATAmount__c = 5 * i,
                isVATApplied__c = true
                
            ));
        }
        insert chargesList;

        List<PaymentPlanSchedule__c> schedules = new List<PaymentPlanSchedule__c>();
        for(Integer i = 0; i < 3; i++){
            schedules.add(new PaymentPlanSchedule__c(
                Name = 'Schedule ' + i,
                LeasingOrder__c = lo.Id,
                Amount__c = 2000
            ));
        }
        insert schedules;

        LeasingReceiptAllocation__c allocation = new LeasingReceiptAllocation__c(
            LeasingReceiptAcknowledgment__c = receipt.Id,
            LeasingOrder__c = lo.Id,
            PaymentPlanSchedule__c = schedules[0].Id,
            AmountApplied__c = 1000
         );
        insert allocation;
        test.stopTest();
    }
    
    @isTest
    private static void testInvokePlatformEventInsert(){
        List<BrokerCommission__c> bcList = [SELECT Id FROM BrokerCommission__c LIMIT 1];
        bcList[0].SecondApprovalStatus__c = 'Approved';
        update bcList;
        Test.startTest();
        IntegrationController.reTriggerPlatformEvent(bcList[0].Id);
        Test.stopTest();
        List<IntegrationRecord__c> integrationRecList = [SELECT Id FROM IntegrationRecord__c WHERE RecordId__c =: bcList[0].Id];
        Assert.areEqual(2,integrationRecList.size(),'There should be 2 records of Integration Record');
    }
    
    @isTest
    private static void testInvokePlatformEventUpdate(){
        List<BrokerCommission__c> bcList = [SELECT Id FROM BrokerCommission__c LIMIT 1];
        bcList[0].SecondApprovalStatus__c = 'Approved';
        bcList[0].FinalApprovalStatus__c = 'Approved';
        update bcList;
        Test.startTest();
        IntegrationController.reTriggerPlatformEvent(bcList[0].Id);
        Test.stopTest();
        List<IntegrationRecord__c> integrationRecList = [SELECT Id,Param1__c FROM IntegrationRecord__c WHERE RecordId__c =: bcList[0].Id];
        Assert.areEqual(3,integrationRecList.size(),'There should be 3 records of Integration Record');
        integrationRecList[0].Param1__c = 'test';
        update integrationRecList;
        delete integrationRecList[0];
    }
    
    @isTest
    private static void testInvokePlatformEventAcount(){
        List<Account> accList = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        IntegrationController.reTriggerPlatformEvent(accList[0].Id);
        Test.stopTest();
    }
    
    @isTest
    private static void testInvokePlatformEventInstallment(){
        List<InstallmentLines__c> installList = [SELECT Id FROM InstallmentLines__c LIMIT 1];
        Test.startTest();
        IntegrationController.reTriggerPlatformEvent(installList[0].Id);
        Test.stopTest();
    }

    @isTest
    private static void testInvokePlatformEventSalesOrderOtherCharges(){
        List<SalesOrderOtherCharges__c> otherChargesList = [SELECT Id FROM SalesOrderOtherCharges__c LIMIT 1];
        Test.startTest();
            IntegrationController.reTriggerPlatformEvent(otherChargesList[0].Id);
        Test.stopTest();
    }

    @isTest
    private static void testInvokePlatformEventReceipt(){
        List<ReceiptAcknowledgement__c> recAckList = [SELECT Id FROM ReceiptAcknowledgement__c LIMIT 1];
        Test.startTest();
            IntegrationController.reTriggerPlatformEvent(recAckList[0].Id);
        Test.stopTest();
    }
    
    @isTest
    static void testLeasingOrderData(){
        LeasingOrder__c lo = [Select id, Account__c from LeasingOrder__c limit1];
        PaymentPlanSchedule__c pps = [Select Id from PaymentPlanSchedule__c limit 1];
        LeasingOrdersOtherCharges__c loc = [Select Id from LeasingOrdersOtherCharges__c limit 1];
        LeasingReceiptAcknowledgment__c lra = [Select Id from LeasingReceiptAcknowledgment__c limit 1];
        LeasingReceiptAllocation__c lca = [Select id from LeasingReceiptAllocation__c limit 1];
        Test.startTest();
        IntegrationController.reTriggerPlatformEvent(lo.Id);
        IntegrationController.reTriggerPlatformEvent(pps.Id);
        IntegrationController.reTriggerPlatformEvent(loc.Id);
        IntegrationController.reTriggerPlatformEvent(lra.Id);
        IntegrationController.reTriggerPlatformEvent(lca.Id);
        Test.stopTest();
    }
}