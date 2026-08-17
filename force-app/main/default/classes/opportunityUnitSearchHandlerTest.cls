@isTest
public class opportunityUnitSearchHandlerTest {
    
    @isTest 
    static void opportunityUnitSearchHandlerMethod(){
        opportunityUnitSearchHandler.getAllProjects();
        Project__c testProject=new Project__c(
            Name='Test Project',
            IsAvailableForSales__c = true
        );
        insert testProject;
        
        
        
        BuildingSection__c testBuilding=new BuildingSection__c(
            Name='Test Building',
            BuildingSectionCode__c='BL-CAS',
            Project__c=testProject.Id
            
        );
        insert testBuilding;
        DateTime lockExpiryTime = DateTime.now().addDays(10);
        
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
            StartDate__c=date.today()-10,
            LockExpiryTime__c = lockExpiryTime
            
        );
        insert testUnit;
        
        
        Unit__c testUnit1=new Unit__c(
            Name='test Unit1',
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
            StartDate__c=date.today()-10,
            LockExpiryTime__c = lockExpiryTime
            
            
        );
        insert testUnit1;
        
        
        
        
        PaymentPlan__c  pp = new PaymentPlan__c();
        pp.Name ='July Plan';
        pp.Unit__c= testUnit.id;
        pp.Description__c ='Test Description';
        pp.Description__c = 'Test';
        pp.IsActive__c = 'NO';
        pp.BrokerPortalFlag__c = True;
        pp.CustomerSubType__c ='CORPORATE';
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
            personEmail='Jana@tesrt.com',
            CustomerSubType__c ='CORPORATE'
            
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
        OffersPromotions__c testOffer=new OffersPromotions__c(
            Name='testOffer',
            Unit__c=testUnit.id,
            OfferName__c='testOffer',
            Project__c=testProject.id,
            StartDate__c=system.today(),
            EndDate__c=system.today().addDays(2),
            BuildingSectionName__c=testBuilding.id
            
            
            
        );
        insert testOffer;
        
        OfferLines__c tempOffer=new OfferLines__c(
            OfferType__c='Voucher',
            LowerBound__c=60,
            UpperBound__c=90,
            OfferName__c=testOffer.Id,
            OfferOn__c = 'Selling Price',
            BudgetTaskName__c ='ADM Fee',
            
            DiscountType__c = 'Additional Discount',
            OfferValue__c = 10,
            Nationality__c=null
            
        );
        insert tempOffer;
        
        
        
        
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
        
        testUnit.Status__c ='Booked';
        testUnit.LockedBy__c = Userinfo.getUserId();
        update testUnit;
        
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
        installmentLines.InstallmentDate__c= Date.today() - 12;
        installmentLines.AmountReceived__c=1500;
        installmentLines.CutOffDate__c=date.today();
        installmentLines.LPCAmount__c=500;
        
        insert installmentLines;
        
        
        CommissionLineItem__c cli= new CommissionLineItem__c();
        cli.CommissionAmount__c = 20000;
        cli.CommissionPercentage__c = 30;
        cli.CommissionType__c ='Referral';
        cli.Unit__c =testUnit.id;
        cli.SalesOrder__c =testOrder.id;
        cli.InstallmentLine__c=installmentLines.id;
        
        
        insert cli;
        
        
        
        list<String>unitIds=new list<String>();
        unitIds.add(testUnit.id);
        set<id>unitIdSet=new set<id>();
        unitIdSet.add(testUnit.id);
        salesOfferUtilityHandler.SaleOfferInputParam testparam= new salesOfferUtilityHandler.SaleOfferInputParam();
        testparam.unitId=testUnit.id;
        testparam.amount=100;
        testparam.designId=testBuilding.id;
        testparam.offerId =tempOpp.Id;
        testparam.multiPurposeAmountApplicable =true;
        testparam.selectedPayments = new list<ID>{pp.Id};
            System.debug(testparam.selectedPayments);
        list<salesOfferUtilityHandler.SaleOfferInputParam>testparamlist=new list<salesOfferUtilityHandler.SaleOfferInputParam>();
        testparamlist.add(testparam);
        
        salesOfferUtilityHandler.PaymentPlanWrapper testplan=new salesOfferUtilityHandler.PaymentPlanWrapper();
        testplan.isSelected= true;
        testplan.paymentPlanDiscountAmount =10;
        testplan.discountAmount=0;
        
        map<Unit__c,SalesOfferUtilityHandler.PaymentPlanWrapper> unitPaymentPlanWrapper = new map<Unit__c,SalesOfferUtilityHandler.PaymentPlanWrapper>();
        
        // opportunityUnitSearchHandler.reserveUnit(testparamlist, tempOpp.id, 'RESERVE', Opportunity.WinReason__c.getDescribe().getPicklistValues()[0].getValue(), null, true);
        
        opportunityUnitSearchHandler.getUnitDetails(testBuilding.id,'Direct', tempOpp.Id);
        
        opportunityUnitSearchHandler.prepareBuildingsNames(testProject.Id);
        opportunityUnitSearchHandler.getAllProjects();
        opportunityUnitSearchHandler.getAllBuildings(testProject.id);
        opportunityUnitSearchHandler.getsObjectType(testUnit.id);
        opportunityUnitSearchHandler.getsObjectType(testOrder.id);
        opportunityUnitSearchHandler.getsObjectType(tempOpp.id);
        opportunityUnitSearchHandler.UnitBookTimeExtendApproval(tempOpp.id,new List<String>{testUnit.id});
        opportunityUnitSearchHandler.autoUpdateUnitBookExtendTimeApproval(new List<String>{tempOpp.id});
        opportunityUnitSearchHandler.GetUnitBookTimeExtApprovStatus(tempOpp.id);
        opportunityUnitSearchHandler.getWinReasonPickList();
        Map<String,String>stringmap = new Map<String,String>();
        stringMap.put(testUnit.id,'Standard Price');
        opportunityUnitSearchHandler.UpdateUnitSellingPrice(stringMap);
        
        opportunityUnitSearchHandler.getOfferLinesQuery('select id,name from OfferLines__c');
        opportunityUnitSearchHandler.getVFDomainURL();
        String message = opportunityUnitSearchHandler.validateRegistrationAllowed(tempOpp.id);
        System.assertEquals(message!='',true);
        opportunityUnitSearchHandler.getCustomerInfo(tempOpp.id);
        opportunityUnitSearchHandler.updateUserField(testUnit.id,3);
        
        opportunityUnitSearchHandler.lockUnits(New List<String>{testUnit1.id});
        opportunityUnitSearchHandler.getOpportunityDetailsbyId(tempOpp.id);
        map<id,SalesOfferUtilityHandler.SalesOfferDetails> result= opportunityUnitSearchHandler.generateSalesOffer(testparamlist,tempOpp.id,4);
        System.debug(result);
        
        PaymentPlan__c tempPaymentPlan= new PaymentPlan__c(
            Name='testPayPlan',
            Description__c='test'
            
            
        );
        insert tempPaymentPlan;
        
        UnitVsPayment unitVsPayment =new UnitVsPayment();
        unitVsPayment.unitId=testUnit.Id;
        unitVsPayment.paymentId=tempPaymentPlan.id;
        
        String unitVsPaymentJson ='['+ JSON.serialize(unitVsPayment)+']';
        
        
        
        opportunityUnitSearchHandler.getAllUnitsById(unitIdSet);
        opportunityUnitSearchHandler.sendSalesOfferPDF(testparamlist, tempOpp.id, 'test', testUnit.id);
        //opportunityUnitSearchHandler.sendBookingAgreementPDF(testparamlist, tempOpp.id, 'test', testUnit.id);
        opportunityUnitSearchHandler.sendBookingAgreementAttachment(tempOpp.id,'test',new list<id>{testUnit.id},new list<id>{tempPaymentPlan.id},new list<id>{testOffer.id},unitVsPaymentJson);
        opportunityUnitSearchHandler.UpdateUnitBookTimeExtApprovStatus(tempOpp.id,new List<String>{testUnit.id},5,'Approved');
        
        
    }
    @isTest 
    static void opportunityUnitSearchHandlerMethod2(){
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
        
        
        
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Sales Manager'];
        User testUser = new User(
            Alias = 'standt',
            Email = 'standarduser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'standarduser@testorg9847588474.com'
        );
        insert testUser;
        
        
        //list<User> sm=[select id, name from User where UserName='standarduser@testorg9847588474.com'];
        DateTime lockExpiryTime = DateTime.now().addDays(10);
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
            AssignedToUser__c=testUser.id,
            LockExpiryTime__c = lockExpiryTime
        );
        insert testUnit;    
        
        Unit__c testUnit1=new Unit__c(
            Name='test Unit1',
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
            AssignedToUser__c=testUser.id,
            LockExpiryTime__c = lockExpiryTime
        );
        insert testUnit1;        
        
        
        // Id AccountRecordTypeId = [Select id,Name from RecordType where Name='PersonAccount'].id;
        Id AccountRecordTypeId =Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Account tempAcc=new Account(
            RecordTypeId= AccountRecordTypeId,
            LastName= 'test',
            personEmail='Jana@email.com',
            CustomerSubType__c ='CORPORATE'
            
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
        OffersPromotions__c testOffer=new OffersPromotions__c(
            Name='testOffer',
            OfferName__c='testOffer',
            Project__c=testProject.id,
            StartDate__c=system.today(),
            EndDate__c=system.today().addDays(2)
            
        );
        insert testOffer;
        
        
        
        
        
        PaymentPlan__c  pp = new PaymentPlan__c();
        pp.Name ='July Plan';
        pp.Description__c ='Test Description';
        pp.IsActive__c ='No';
        pp.Premium__c=20;
        pp.PaymentPlanDiscount__c=2;
        pp.StandardFlag__c='YES';
        pp.CustomerSubType__c ='CORPORATE';
        insert pp;
        
        BuildingSectionMapping__c mappingRecord = new BuildingSectionMapping__c();
        mappingRecord.BuildingSectionName__c = testBuilding.id;
        mappingRecord.PaymentPlan__c = pp.id;
        insert mappingRecord;
        
        
        PaymentInstallments__c ppi = new PaymentInstallments__c();
        ppi.BrokerPayoutPercentage__c =100;
        ppi.Description__c = 'test description';
        ppi.InstallmentNumber__c = 1;
        ppi.InstallmentPercentage__c=100;
        ppi.PaymentPlan__c = pp.id;
        ppi.Condition_Type__c='P012';
        insert ppi;
        
        pp.IsActive__c= 'Yes';
        update pp;
        
        testUnit.Status__c ='Booked';
        testUnit.LockedBy__c = Userinfo.getUserId();
        update testUnit;
        
        
        
        
        
        list<String>unitIds=new list<String>();
        unitIds.add(testUnit.id);
        set<id>unitIdSet=new set<id>();
        unitIdSet.add(testUnit.id);
        salesOfferUtilityHandler.SaleOfferInputParam testparam= new salesOfferUtilityHandler.SaleOfferInputParam();
        System.debug('unitId'+testUnit.id);
        testparam.unitId= testUnit1.id;
        testparam.amount=100;
        testparam.designId=testBuilding.id;
        testparam.offerId =tempOpp.Id;
        testparam.multiPurposeAmountApplicable =true;
        testparam.selectedPayments = new list<ID>{pp.Id};
            list<salesOfferUtilityHandler.SaleOfferInputParam>testparamlist=new list<salesOfferUtilityHandler.SaleOfferInputParam>();
        testparamlist.add(testparam);
        
        salesOfferUtilityHandler.PaymentPlanWrapper testplan=new salesOfferUtilityHandler.PaymentPlanWrapper();
        // testplan.isSelected= false;
        testplan.paymentPlanDiscountAmount =10;
        testplan.discountAmount=0;
        
        map<Unit__c,SalesOfferUtilityHandler.PaymentPlanWrapper> unitPaymentPlanWrapper = new map<Unit__c,SalesOfferUtilityHandler.PaymentPlanWrapper>();
        //opportunityUnitSearchHandler.sendBookingAgreementPDF(testparamlist, tempOpp.id, 'test', testUnit.id);
        /* PaymentPlan__c tempPaymentPlan= new PaymentPlan__c(
Name='testPayPlan',
Description__c='test'


);
insert tempPaymentPlan;*/
        
        //opportunityUnitSearchHandler.sendBookingAgreementAttachment(tempOpp.id,'test',new list<id>{testUnit.id},new list<id>{tempPaymentPlan.id},new list<id>{testOffer.id});
        
        
        opportunityUnitSearchHandler.reserveUnit(testparamlist, tempOpp.id,'BOOKING', 'Won - Special Discount','',false,4);
        
        
    }
    @isTest 
    static void opportunityUnitSearchHandlerSubmitApprovalMethod(){
        
        
        Project__c testProject=new Project__c(
            Name='Test Project'
        );
        insert testProject;
        
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Sales Manager'];
        User testUser = new User(
            Alias = 'standt',
            Email = 'standarduser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'standarduser@testorg9847588474.com'
        );
        insert testUser;
        
        User testUser1 = new User(
            Alias = 'standtf',
            Email = 'standardsssuser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'standarduser@testorg9afwsfsfsfs847588474.com',
            ManagerId = testUser.Id
        );
        insert testUser1;
        
        
        BuildingSection__c testBuilding=new BuildingSection__c(
            Name='Test Building',
            BuildingSectionCode__c='BL-CAS',
            Project__c=testProject.Id
            
        );
        insert testBuilding;
        System.runAs(testUser1) {
            Unit__c testUnit=new Unit__c(
                Name='test Unit',
                Status__c='Available',
                UnitType__c='Townhouse',
                BuildingSectionName__c=testBuilding.id,
                //Project__c=testProject.Id,
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
            
            opportunityUnitSearchHandler.submitforApproval(testUnit);
        }
        
    }
    
    public class UnitVsPayment {
        public String unitId { get; set; }
        public String paymentId { get; set; }
    }
    
}