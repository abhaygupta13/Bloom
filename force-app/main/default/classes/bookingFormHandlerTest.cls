@isTest
public class bookingFormHandlerTest {
    @isTest static void bookingFormHandlerTestMethod(){
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
            StartDate__c=date.today()-10
            
        );
        insert testUnit1;
        
        
        list<id>UnitList=new list<id>();
        UnitList.add(testUnit.id);
        
        
        Account tempAcc=new Account(
            
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
        
        OffersPromotions__c testOffer=new OffersPromotions__c(
            Name='testOffer',
            OfferName__c='testOffer',
            Project__c=testProject.id,
            StartDate__c=system.today(),
            EndDate__c=system.today().addDays(2)
        );
        insert testOffer;
        
        OffersPromotions__c testOffer1=new OffersPromotions__c(
            Name='testOffer1',
            OfferName__c='testOffer1',
            Project__c=testProject.id,
            StartDate__c=system.today(),
            EndDate__c=system.today().addDays(2)
        );
        insert testOffer1;
        
        
        PaymentPlan__c tempPaymentPlan= new PaymentPlan__c(
            Name='testPayPlan',
            Description__c='test'
        );
        insert tempPaymentPlan;
        
        PaymentPlan__c tempPaymentPlan1= new PaymentPlan__c(
            Name='testPayPlan1',
            Description__c='test'
        );
        insert tempPaymentPlan1;
        
        /*SalesOfferUtilityHandler.SalesOfferDetails testSalesOfferDetails = new SalesOfferUtilityHandler.SalesOfferDetails();
        string todayDate=String.valueOf(system.today());
        string customerName='Name';*/
        //Map<String,String>unitVspaymentMap=new Map<String,String>();
        //unitVspaymentMap.put(testUnit.Id,tempPaymentPlan.id);
        //
        UnitVsPayment unitVsPayment =new UnitVsPayment();
        unitVsPayment.unitId=testUnit.Id;
        unitVsPayment.paymentId=tempPaymentPlan.id;
        /*bookingFormHandlerTest.UnitVsPayment record1 = new bookingFormHandlerTest.UnitVsPayment(
            unitId = testUnit.Id,
            paymentId = tempPaymentPlan.id
        );
        unitVsPaymentList.add(record1);*/
        String unitVsPaymentJson ='['+ JSON.serialize(unitVsPayment)+']';
        
        PageReference pageRef = Page.BookingForm;
        Test.setCurrentPage(pageRef);   
        ApexPages.currentPage().getParameters().put('id',tempOpp.Id);
        ApexPages.currentPage().getParameters().put('selectedUnits', testUnit.Id);
        ApexPages.currentPage().getParameters().put('customerName', 'Test Customer');
        ApexPages.currentPage().getParameters().put('currentOffer', testOffer.Id);
        ApexPages.currentPage().getParameters().put('selectedPayments', tempPaymentPlan.id);
        ApexPages.currentPage().getParameters().put('unitVsPaymentMap', unitVsPaymentJson);
        
        String opportunityId = tempOpp.id;
        bookingFormHandler bkFormHandler = new bookingFormHandler();
        bkFormHandler.getUnitDetails(UnitList);
        bkFormHandler.getOppDetails();
        bkFormHandler.todayDate=String.valueOf(system.today());
    }
    public class UnitVsPayment {
        public String unitId { get; set; }
        public String paymentId { get; set; }
    }

}