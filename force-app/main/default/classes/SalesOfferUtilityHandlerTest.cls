@isTest
public class SalesOfferUtilityHandlerTest {
    @isTest static void SalesOfferUtilityHandlerTestMethod(){
        Set<id>projectIds = new Set<id>();
       
        

        Project__c testProject=new Project__c(
        	Name='Test Project'
        );
        insert testProject;
        projectIds.add(testProject.id);
        
        BookingMemo__c BM = new BookingMemo__c();
        insert BM;
        
        
        MemoLines__c memo = new MemoLines__c();
        memo.BookingMemo__c = BM.id;
        if(memo.AdditionalDiscountPercentage__c>0){
            memo.AdditionalDiscountPercentage__c = 1;
        }
        
        
        insert memo;
        
        
        
        BuildingSection__c testBuilding=new BuildingSection__c(
        	Name='Test Building',
            BuildingSectionCode__c='BL-CAS',
            Project__c=testProject.Id,
            PropertyManagementFee__c=500
            
            
        );
        
        insert testBuilding;
        Set<Id> buildingIds = new Set<Id>();
        buildingIds.add(testBuilding.id);
        
        
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
            SellingPrice__c=700000,
            //MarketLeaseRent__c=3000,
            AnticipatedServiceCharges__c=400,
            SaleableArea__c=400
            
           
        );
        insert testUnit;
        Opportunity tempOpp=new Opportunity(
        	Name='tempOpp',
            StageName='New',
            CloseDate=system.today(),
            LeadChannel__c='Walk in',
            AgentType__c='Direct',
         
            BookingType__c = 'Online',
            DealType__c = 'Standard'
        );
        insert tempOpp;
        
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
        
        OffersPromotions__c testPromo=new OffersPromotions__c(
        	Name='testPromo',
            OfferName__c='testPromo',
            Project__c=testProject.id,
            StartDate__c=system.today(),
            EndDate__c=system.today().addDays(2),
            BuildingSectionName__c=null,
            BrokerPortalFlag__c =false,
            BookingMemo__c=null,
            Customer_Sub_Type__c='CORPORATE',
            Direct_Indirect__c='Direct'
            
        );
        insert testPromo;
        OfferLines__c tempOffer=new OfferLines__c(
        	OfferType__c='Rebate',
            LowerBound__c=60,
            UpperBound__c=90,
            OfferValue__c=3,
            OfferName__c=testPromo.Id,
            OfferOn__c='PM Fee',
            BudgetTaskName__c='Service Charges'
        );
        insert tempOffer;
        
        OfferLines__c tempOffer1=new OfferLines__c(
        	OfferType__c='Additional Discount',
            OfferValue__c=3,
            OfferName__c=testPromo.Id,
            OfferOn__c='Selling Price',
            BudgetTaskName__c='Discount',
            DiscountType__c= 'Additional Discount'
        );
        insert tempOffer1;
        
        list<OfferLines__c>offerList=new list<OfferLines__c>();
        offerList.add(tempOffer);
        offerList.add(tempOffer1);
        
        Lead testLead=new Lead(
        	LastName='test',
            MobileCountryCode__c='971',
            Email='testmail@gmail.com',
            Lead_Channel__c='Call',
            MobilePhone='588888888'
        );
        insert testLead;
        
        PaymentPlan__c  pp = new PaymentPlan__c();
        pp.Name ='July Plan';
        pp.Description__c ='Test Description';
        pp.IsActive__c ='No';
         pp.StandardFlag__c = Constants.YES;
        pp.BookingMemo__c=null;
        pp.Premium__c = 20;
        pp.PaymentPlanDiscount__c = 2;
        pp.Maximum_No_Of_Units__c = 999.00;
        pp.Minimum_No_Of_Units__c =0.00;
        insert pp;
        
       list<PaymentInstallments__c> installments=new  list<PaymentInstallments__c>();
        installments.add(new PaymentInstallments__c(Description__c= '1' ,InstallmentNumber__c=1 , InstallmentPercentage__c=10 , BrokerPayoutPercentage__c=50, PaymentPlan__c =pp.id,InstallmentDate__c =System.today(),Condition_Type__c='P012'));
        installments.add(new PaymentInstallments__c(Description__c= '2' ,InstallmentNumber__c=2 , InstallmentPercentage__c=40 , BrokerPayoutPercentage__c=50, PaymentPlan__c =pp.id,InstallmentDate__c =System.today(),Condition_Type__c='P012'));
        installments.add(new PaymentInstallments__c(Description__c= '3' ,InstallmentNumber__c=3 , InstallmentPercentage__c=25 ,  PaymentPlan__c =pp.id,InstallmentDate__c =System.today(),Condition_Type__c='P012'));
        installments.add(new PaymentInstallments__c(Description__c= '4' ,InstallmentNumber__c=4 , InstallmentPercentage__c=25 ,  PaymentPlan__c =pp.id,InstallmentDate__c =System.today(),Condition_Type__c='P012'));
        insert installments;
        
        pp.IsActive__c = 'Yes';
        update pp;
        
        
         PaymentPlan__c  pp1 = new PaymentPlan__c();
        pp1.Name ='July Plan';
        pp1.Description__c ='Test Description';
        pp1.IsActive__c ='No';
         pp1.Maximum_No_Of_Units__c = 999.00;
        pp1.Minimum_No_Of_Units__c =0.00;
         pp1.StandardFlag__c = Constants.YES;
        insert pp1;

        
        
        BuildingSectionMapping__c testBuildMap=new BuildingSectionMapping__c(
        	BuildingSectionName__c=testBuilding.Id,
            PaymentPlan__c=pp.Id
            
        );
        insert testBuildMap;
        
         BuildingSectionMapping__c testBuildMap1= new BuildingSectionMapping__c(
        	BuildingSectionName__c=testBuilding.Id,
            PaymentPlan__c=pp1.Id
             
        );
        insert testBuildMap1;
        
        Map<Id,Set<Id>> buildingToPaymentPlanIds = new Map<Id,Set<Id>>();
        
        Set<Id> paymentplanidsbuilding = new Set<Id>();
        paymentplanidsbuilding.add(testBuildMap1.PaymentPlan__c);
        
        buildingToPaymentPlanIds.put(testBuildMap1.id,paymentplanidsbuilding);
        
        
        
        
        
        map<Id,Id> unitIdToOffer=new map<Id,Id>();
         unitIdToOffer.put(testUnit.Id ,testPromo.Id);
        Map<id,boolean>unitIdToAdmIncludedValue = new Map<id,boolean>();
       
        unitIdToAdmIncludedValue.put(testUnit.id,false);
        map<Id,boolean> unitToMultiPurposeAmountApplicableMap=new map<Id,boolean>();
        unitToMultiPurposeAmountApplicableMap.put(testUnit.Id,true);
        set<Id> paymentPlanIds=new set<Id>();
        paymentPlanIds.add(pp.id);
        map<Id,set<Id>> unitToSelectedPaymentPlanMap=new map<Id,set<Id>>();
        unitToSelectedPaymentPlanMap.put(testUnit.Id,paymentPlanIds);
        
        set<ID> unitIds=new set<ID>();
        unitIds.add(testUnit.Id);
        
        Set<Id> buidlingIds=new Set<Id>();
        buidlingIds.add(testBuilding.id);
        Map<id,String> finishTypeMap = new Map<id,String>();
        finishTypeMap.put(testUnit.id,'Standard Price');
          
        
        SalesOfferUtilityHandler.getApplicableOfferLines(offerList, testUnit, tempOpp, testLead, 3, 300);
        SalesOfferUtilityHandler.generateSalesOfferMap(unitIdToOffer, unitToMultiPurposeAmountApplicableMap, unitToSelectedPaymentPlanMap,null, tempOpp.Id,4,finishTypeMap,unitIdToAdmIncludedValue);
        SalesOfferUtilityHandler.generateSalesOfferMap(unitIdToOffer, unitToMultiPurposeAmountApplicableMap, unitToSelectedPaymentPlanMap,null, testLead.Id,4,finishTypeMap,unitIdToAdmIncludedValue);
    	SalesOfferUtilityHandler.getAllUnitsById(unitIds);
        SalesOfferUtilityHandler.getPaymentPlanByBuidlingIds(buidlingIds);
       SalesOfferUtilityHandler.getPaymentPlanIdsByBuidlingIds(buildingToPaymentPlanIds,null);
        SalesOfferUtilityHandler.getPaymentPlanIdsByBuidlingIds(null,null);
         SalesOfferUtilityHandler.getActiveOffersAndPromotions(projectIds,buidlingIds);
    }
     @isTest static void SalesOfferUtilityHandlerTestMethod1(){
       Set<id>projectIds = new Set<id>();
       
        

        Project__c testProject=new Project__c(
        	Name='Test Project'
        );
        insert testProject;
        projectIds.add(testProject.id);
        
        BookingMemo__c BM = new BookingMemo__c();
        insert BM;
        
        
        MemoLines__c memo = new MemoLines__c();
        memo.BookingMemo__c = BM.id;
        if(memo.AdditionalDiscountPercentage__c>0){
            memo.AdditionalDiscountPercentage__c = 1;
        }
        
        
        insert memo;
        
        
        
        BuildingSection__c testBuilding=new BuildingSection__c(
        	Name='Test Building',
            BuildingSectionCode__c='BL-CAS',
            Project__c=testProject.Id,
            PropertyManagementFee__c=500
            
            
        );
        
        insert testBuilding;
        Set<Id> buildingIds = new Set<Id>();
        buildingIds.add(testBuilding.id);
        
        
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
            SellingPrice__c=700000,
            //MarketLeaseRent__c=3000,
            AnticipatedServiceCharges__c=400,
            SaleableArea__c=400
            
           
        );
        insert testUnit;
        Opportunity tempOpp=new Opportunity(
        	Name='tempOpp',
            StageName='New',
            CloseDate=system.today(),
            LeadChannel__c='Walk in',
            AgentType__c='Direct',
         
            BookingType__c = 'Online',
            DealType__c = 'Standard'
        );
        insert tempOpp;
        
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
        
        OffersPromotions__c testPromo=new OffersPromotions__c(
        	Name='testPromo',
            OfferName__c='testPromo',
            Project__c=testProject.id,
            StartDate__c=system.today(),
            EndDate__c=system.today().addDays(2),
            BuildingSectionName__c=testBuilding.id,
            BrokerPortalFlag__c =false,
            BookingMemo__c=null,
            Customer_Sub_Type__c='CORPORATE',
            Direct_Indirect__c='Direct'
            
        );
        insert testPromo;
        OfferLines__c tempOffer=new OfferLines__c(
        	OfferType__c='Rebate',
            LowerBound__c=60,
            UpperBound__c=90,
            OfferValue__c=3,
            OfferName__c=testPromo.Id,
            OfferOn__c='PM Fee',
            BudgetTaskName__c='Service Charges'
        );
        insert tempOffer;
        
        OfferLines__c tempOffer1=new OfferLines__c(
        	OfferType__c='Additional Discount',
            OfferValue__c=3,
            OfferName__c=testPromo.Id,
            OfferOn__c='Selling Price',
            BudgetTaskName__c='Discount',
            DiscountType__c= 'Additional Discount'
        );
        insert tempOffer1;
        
        list<OfferLines__c>offerList=new list<OfferLines__c>();
        offerList.add(tempOffer);
        offerList.add(tempOffer1);
        
        Lead testLead=new Lead(
        	LastName='test',
            MobileCountryCode__c='971',
            Email='testmail@gmail.com',
            Lead_Channel__c='Call',
            MobilePhone='588888888'
        );
        insert testLead;
        
        PaymentPlan__c  pp = new PaymentPlan__c();
        pp.Name ='July Plan';
        pp.Description__c ='Test Description';
        pp.IsActive__c ='No';
         pp.StandardFlag__c = Constants.YES;
        pp.BookingMemo__c=null;
        pp.Premium__c = 20;
        pp.PaymentPlanDiscount__c = 2;
         pp.Maximum_No_Of_Units__c = 999.00;
        pp.Minimum_No_Of_Units__c =0.00;
        insert pp;
        
       list<PaymentInstallments__c> installments=new  list<PaymentInstallments__c>();
        installments.add(new PaymentInstallments__c(Description__c= '1' ,InstallmentNumber__c=1 , InstallmentPercentage__c=10 , BrokerPayoutPercentage__c=50, PaymentPlan__c =pp.id,InstallmentDate__c =System.today(),Condition_Type__c='P012'));
        installments.add(new PaymentInstallments__c(Description__c= '2' ,InstallmentNumber__c=2 , InstallmentPercentage__c=40 , BrokerPayoutPercentage__c=50, PaymentPlan__c =pp.id,InstallmentDate__c =System.today(),Condition_Type__c='P012'));
        installments.add(new PaymentInstallments__c(Description__c= '3' ,InstallmentNumber__c=3 , InstallmentPercentage__c=25 ,  PaymentPlan__c =pp.id,InstallmentDate__c =System.today(),Condition_Type__c='P012'));
        installments.add(new PaymentInstallments__c(Description__c= '4' ,InstallmentNumber__c=4 , InstallmentPercentage__c=25 ,  PaymentPlan__c =pp.id,InstallmentDate__c =System.today(),Condition_Type__c='P012'));
        insert installments;
        
        pp.IsActive__c = 'Yes';
        update pp;
        
        
         PaymentPlan__c  pp1 = new PaymentPlan__c();
        pp1.Name ='July Plan';
        pp1.Description__c ='Test Description';
        pp1.IsActive__c ='No';
          pp1.Maximum_No_Of_Units__c = 999.00;
        pp1.Minimum_No_Of_Units__c =0.00;
         pp1.StandardFlag__c = Constants.YES;
        insert pp1;

        
        
        BuildingSectionMapping__c testBuildMap=new BuildingSectionMapping__c(
        	BuildingSectionName__c=testBuilding.Id,
            PaymentPlan__c=pp.Id
            
        );
        insert testBuildMap;
        
         BuildingSectionMapping__c testBuildMap1= new BuildingSectionMapping__c(
        	BuildingSectionName__c=testBuilding.Id,
            PaymentPlan__c=pp1.Id
             
        );
        insert testBuildMap1;
        
        Map<Id,Set<Id>> buildingToPaymentPlanIds = new Map<Id,Set<Id>>();
        
        Set<Id> paymentplanidsbuilding = new Set<Id>();
        paymentplanidsbuilding.add(testBuildMap1.PaymentPlan__c);
        
        buildingToPaymentPlanIds.put(testBuildMap1.id,paymentplanidsbuilding);
        
        
        
        
        
        map<Id,Id> unitIdToOffer=new map<Id,Id>();
        unitIdToOffer.put(testUnit.Id ,testPromo.Id);
        map<Id,boolean> unitToMultiPurposeAmountApplicableMap=new map<Id,boolean>();
        unitToMultiPurposeAmountApplicableMap.put(testUnit.Id,true);
        set<Id> paymentPlanIds=new set<Id>();
        paymentPlanIds.add(pp.id);
        map<Id,set<Id>> unitToSelectedPaymentPlanMap=new map<Id,set<Id>>();
        unitToSelectedPaymentPlanMap.put(testUnit.Id,paymentPlanIds);
        
        set<ID> unitIds=new set<ID>();
        unitIds.add(testUnit.Id);
        
        Set<Id> buidlingIds=new Set<Id>();
        buidlingIds.add(testBuilding.id);
         Map<id,String> finishTypeMap = new Map<id,String>();
        finishTypeMap.put(testUnit.id,'Standard Price');
         Map<id,boolean>unitIdToAdmIncludedValue = new Map<id,boolean>();
       
        unitIdToAdmIncludedValue.put(testUnit.id,false);
     
           SalesOfferUtilityHandler.generateSalesOfferMap(unitIdToOffer, unitToMultiPurposeAmountApplicableMap, unitToSelectedPaymentPlanMap,null, tempOpp.Id,4,finishTypeMap,unitIdToAdmIncludedValue);
        SalesOfferUtilityHandler.generateSalesOfferMap(unitIdToOffer, unitToMultiPurposeAmountApplicableMap, unitToSelectedPaymentPlanMap,null, testLead.Id,4,finishTypeMap,unitIdToAdmIncludedValue);
    	
     }}