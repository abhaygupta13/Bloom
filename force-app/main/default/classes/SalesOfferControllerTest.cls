@istest
public class SalesOfferControllerTest {
    @istest
    Static void TestMethod1(){
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
            SellingPrice__c= 700000
            
        );
        
        insert testUnit;
        
        PaymentPlan__c  pp = new PaymentPlan__c();
        pp.Name ='July Plan';
        pp.Description__c ='Test Description';
        pp.IsActive__c ='No';
        pp.StandardFlag__c = Constants.YES;
        pp.BookingMemo__c=null;
        pp.Premium__c = 20;
        pp.CustomerSubType__c = 'CORPORATE';
        pp.Project__c = testProject.id;
        pp.PaymentPlanDiscount__c = 2;
        pp.Maximum_No_Of_Units__c = 999.00;
        pp.Minimum_No_Of_Units__c =0.00;
        insert pp;
        
        PaymentInstallments__c paymentInstallment = new PaymentInstallments__c();
        paymentInstallment.InstallmentNumber__c = 1;
        paymentInstallment.InstallmentPercentage__c = 100;
        paymentInstallment.BrokerPayoutPercentage__c = 100;
        paymentInstallment.PaymentPlan__c = pp.id;
        paymentInstallment.Description__c = 'Installment Description';
        paymentInstallment.Condition_Type__c='P012';
        insert paymentInstallment;
        
        pp.IsActive__c ='yes';
        Update pp;
        
        OffersPromotions__c testPromo=new OffersPromotions__c(
            Name='testPromo',
            OfferName__c='testPromo',
            Project__c = testProject.id,
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
        
        SalesOffer__c SO1 = NEW SalesOffer__c();
        SO1.Unit__c = testUnit.id;
        SO1.Payment_Plan__c = pp.Id;
        SO1.OfferType__c = tempOffer1.id;
        SO1.PriceType__c = 'Standard Price';
        SO1.CustomerFirstName__c = 'firstName';
        SO1.CustomerLastName__c = 'lastName';
        SO1.CustomerEmail__c = 'email@gmail.com';
        SO1.Remarks__c = 'remarks'; 
        
        SalesOffer__c SO = NEW SalesOffer__c();
        SO.Unit__c = testUnit.id;
        SO.Payment_Plan__c = pp.Id;
        SO.OfferType__c = tempOffer1.id;
        SO.PriceType__c = 'Standard Price';
        SO.CustomerFirstName__c = 'firstName';
        SO.CustomerLastName__c = 'lastName';
        SO.CustomerEmail__c = 'email@gmail.com';
        SO.Remarks__c = 'remarks';                   
        insert SO;
        
        SalesOfferController.SelectedUnitWrapper testUnitWrapper = new SalesOfferController.SelectedUnitWrapper();
        testUnitWrapper.unitId = testUnit.Id;
        testUnitWrapper.unitName = testUnit.Name;
        testUnitWrapper.paymentPlanIds = new List<Id>(); // or populate with mock plan IDs
        testUnitWrapper.paymentPlanName = 'Test Payment Plan';
        testUnitWrapper.offerTypeId = null; // or mock Offer Type Id if needed
        testUnitWrapper.offerTypeName = 'Test Offer';
        testUnitWrapper.priceType = 'Standard Price';
        
        ContentVersion contentVersion = new ContentVersion(
            Title          = 'a picture',
            PathOnClient   = 'Pic.jpg',
            VersionData    = Blob.valueOf('Test Content'),
            IsMajorVersion = true);
        insert contentVersion;
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        //create ContentDocumentLink  record
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = SO.Id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;               
        Test.startTest();
        SalesOfferController.getUnitModelsByProjectId(testProject.id);
        SalesOfferController.getOfferTypes(testProject.id,'CORPORATE','Direct');
        SalesOfferController.getPaymentPlans(testProject.id,'CORPORATE');
        SalesOfferController.getUnitModelsByProjectId(testProject.id);
        SalesOfferController.getUnits(testProject.id, '1BHK', 'Direct');
        SalesOfferController.getProjects();
        SalesOfferController.generateSalesOffer(
            testProject.Id,
            testUnitWrapper,
            'firstName',
            'lastName',
            'email@gmail.com',
            'remarks',
            'CORPORATE'
        );
        SalesOfferController.getDocumentBySalesOfferId(SO.id);
        SalesOfferController.shareSalesOffer(SO.id);
  		SalesOfferService Instance= SalesOfferService.getInstance();
        Instance.insertSalesOffer(SO1);
        
        Test.stopTest();
    }
}