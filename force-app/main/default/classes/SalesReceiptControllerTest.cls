/***
Class       : SalesReceiptControllerTest
Author      : Dhanraj Poojary
Description : 
TestClass   : Test Class for SalesReceiptController
****************************************************************************************************************/

@isTest
public class SalesReceiptControllerTest {
    
    @isTest
    static void testSalesReceiptController_WithADM_MergedIntoInstallment1() {
        
        Project__c proj = new Project__c(Name = 'Test Project');
        insert proj;
        
        BuildingSection__c bs = new BuildingSection__c(
            Name = 'BS',
            BuildingSectionCode__c = 'BS-01',
            Project__c = proj.Id
        );
        insert bs;
        
        Unit__c unit = new Unit__c(
            Name = 'Unit 1',
            Status__c = 'Booked',
            UnitType__c = 'Apartment',
            BuildingSectionName__c = bs.Id,
            Project__c = proj.Id,
            PropertyUsage__c = 'Residential',
            SellingPrice__c = 700000,
            StartDate__c = Date.today().addDays(-5),
            EndDate__c = Date.today().addDays(5)
        );
        insert unit;
        
        PaymentPlan__c plan = new PaymentPlan__c(
            Name = 'Plan',
            Unit__c = unit.Id,
            Description__c ='Test Description',
            Classification__c = Constants.PAYMENT_PLAN_TYPE_STANDARD
        );
        insert plan;
        
        PaymentInstallments__c pi1 = new PaymentInstallments__c(
            PaymentPlan__c = plan.Id,
            InstallmentNumber__c = 1,
            InstallmentPercentage__c = 25,
            Description__c = 'Installment Description'
        );
        insert pi1;
        
        PaymentInstallments__c pi2 = new PaymentInstallments__c(
            PaymentPlan__c = plan.Id,
            InstallmentNumber__c = 2,
            InstallmentPercentage__c = 25,
            Description__c = 'Installment Description'
        );
        insert pi2;
        
        Id paRT = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('PersonAccount')
            .getRecordTypeId();
        
        Account acc = new Account(
            RecordTypeId = paRT,
            LastName = 'Customer',
            PersonEmail = 'test@bloomholding.com'
        );
        insert acc;
        
        Opportunity opp = new Opportunity(
            Name = 'Opp',
            StageName = 'New',
            CloseDate = Date.today(),
            AccountId = acc.Id,
            WinReason__c = 'Bloom Brand'
        );
        insert opp;
        
        OffersPromotions__c offer = new OffersPromotions__c(
            Name = 'ADM Offer',
            OfferName__c = 'testPromo',
            Project__c = proj.Id,
            ADM_Fee_Included__c = true,
            StartDate__c = Date.today().addDays(-1),
            EndDate__c = Date.today().addDays(5)
        );
        insert offer;
        
        OfferLines__c tempOffer=new OfferLines__c(
            OfferType__c='Rebate',
            LowerBound__c=60,
            UpperBound__c=90,
            OfferValue__c=3,
            OfferName__c=offer.Id,
            OfferOn__c='PM Fee',
            BudgetTaskName__c='Service Charges'
        );
        insert tempOffer;
        
        SalesOffer__c soffer = new SalesOffer__c();
        soffer.Unit__c = unit.Id;
        soffer.Payment_Plan__c = plan.Id;
        soffer.OfferType__c = tempOffer.Id;
        soffer.PriceType__c = 'Standard Price';
        soffer.CustomerFirstName__c = 'First';
        soffer.CustomerLastName__c = 'Last';
        soffer.CustomerEmail__c = 'test@gmail.com';
        soffer.Remarks__c = 'Test';
        insert soffer;
        
        SalesOrder__c so = new SalesOrder__c(
            Name = 'SO-1',
            Unit__c = unit.Id,
            Account__c = acc.Id,
            Opportunity__c = opp.Id,
            Status__c = 'Booked',
            Offer__c = offer.Id
        );
        insert so;
        
        InstallmentLines__c inst1 = new InstallmentLines__c(
            SalesOrder__c = so.Id,
            PaymentPlan__c = plan.Id,
            PaymentInstallments__c = pi1.Id,
            InstallmentAmount__c = 100000,
            InstallmentPercentage__c = 25,
            InstallmentNumber__c = 1,
            Description__c = 'Test'
        );
        insert inst1;
        
        InstallmentLines__c inst2 = new InstallmentLines__c(
            SalesOrder__c = so.Id,
            PaymentPlan__c = plan.Id,
            PaymentInstallments__c = pi2.Id,
            InstallmentAmount__c = 100000,
            InstallmentPercentage__c = 25,
            InstallmentNumber__c = 2,
            Description__c = 'Test'
        );
        insert inst2;
        
        ReceiptAcknowledgement__c ackInst = new ReceiptAcknowledgement__c(
            SalesOrder__c = so.Id,
            Opportunity__c = opp.Id,
            PaymentType__c='Cheque',
            Amount__c = 90000,
            Status__c = 'Cleared',
            MaturityDate__c = Date.today(),
            ReferenceNumber__c = '546321'
        );
        insert ackInst;
        
        ReceiptAcknowledgement__c ackADM = new ReceiptAcknowledgement__c(
            SalesOrder__c = so.Id,
            Opportunity__c = opp.Id,
            PaymentType__c='Cheque',
            Amount__c = 10000,
            Status__c = 'Received',
            MaturityDate__c = Date.today(),
            ReferenceNumber__c = '546321'
        );
        insert ackADM;
        
        SalesOrderOtherCharges__c admCharge = new SalesOrderOtherCharges__c(
            SalesOrder__c = so.Id,
            Account__c = acc.Id,
            TypeOfCharge__c = 'ADM Fee',
            Amount__c = 10000,
            Due_Date__c = Date.today()
        );
        insert admCharge;
        
        // Installment #1 receipt
        ReceiptAllocation__c raInstallment1 = new ReceiptAllocation__c(
            SalesOrder__c = so.Id,
            Account__c = acc.Id,
            ReceiptAcknowledgement__c = ackInst.Id,
            InstallmentLine__c = inst1.Id,
            AmountApplied__c = 90000
        );
        insert raInstallment1;
        
        // ADM receipt (MERGES)
        ReceiptAllocation__c raADM = new ReceiptAllocation__c(
            SalesOrder__c = so.Id,
            Account__c = acc.Id,
            ReceiptAcknowledgement__c = ackADM.Id,
            SalesOrderOtherCharges__c = admCharge.Id,
            AmountApplied__c = 10000
        );
        insert raADM;
        
        // Installment #2 receipt (no ADM)
        ReceiptAllocation__c raInstallment2 = new ReceiptAllocation__c(
            SalesOrder__c = so.Id,
            Account__c = acc.Id,
            ReceiptAcknowledgement__c = ackInst.Id,
            InstallmentLine__c = inst2.Id,
            AmountApplied__c = 50000
        );
        insert raInstallment2;
        
        Test.setCurrentPage(Page.ReceiptAcknowledgementPDF);
        ApexPages.currentPage().getParameters().put('id', so.Id);       
        Test.startTest();
        SalesReceiptController controller = new SalesReceiptController();
        Test.stopTest();
        SalesReceiptController.SalesOrderWrapper sow = controller.salesOrderWrapperList[0];
    }
    @IsTest
static void testGenerateAndAttachPdf() {

    // -------------------------------------------------
    // 1. Project
    // -------------------------------------------------
    Project__c proj = new Project__c(
        Name = 'Test Project PDF'
    );
    insert proj;


    // -------------------------------------------------
    // 2. Building Section
    // -------------------------------------------------
    BuildingSection__c bs = new BuildingSection__c(
        Name = 'BS PDF',
        BuildingSectionCode__c = 'BS-PDF',
        Project__c = proj.Id
    );
    insert bs;


    // -------------------------------------------------
    // 3. Unit
    // -------------------------------------------------
    Unit__c unit = new Unit__c(
        Name = 'Unit PDF',
        Status__c = 'Booked',
        UnitType__c = 'Apartment',
        BuildingSectionName__c = bs.Id,
        Project__c = proj.Id,
        PropertyUsage__c = 'Residential',
        SellingPrice__c = 700000,
        StartDate__c = Date.today().addDays(-5),
        EndDate__c = Date.today().addDays(5)
    );
    insert unit;


    // -------------------------------------------------
    // 4. Payment Plan
    // -------------------------------------------------
    PaymentPlan__c plan = new PaymentPlan__c(
        Name = 'PDF Plan',
        Unit__c = unit.Id,
        Description__c = 'PDF Test Plan',
        Classification__c =
            Constants.PAYMENT_PLAN_TYPE_STANDARD
    );
    insert plan;


    // -------------------------------------------------
    // 5. Payment Installment
    // -------------------------------------------------
    PaymentInstallments__c pi = new PaymentInstallments__c(
        PaymentPlan__c = plan.Id,
        InstallmentNumber__c = 1,
        InstallmentPercentage__c = 25,
        Description__c = 'PDF Installment'
    );
    insert pi;


    // -------------------------------------------------
    // 6. Person Account
    // -------------------------------------------------
    Id paRT = Schema.SObjectType.Account
        .getRecordTypeInfosByDeveloperName()
        .get('PersonAccount')
        .getRecordTypeId();

    Account acc = new Account(
        RecordTypeId = paRT,
        LastName = 'PDF Customer',
        PersonEmail = 'pdf@test.com'
    );
    insert acc;


    // -------------------------------------------------
    // 7. Opportunity
    // -------------------------------------------------
    Opportunity opp = new Opportunity(
        Name = 'PDF Opportunity',
        StageName = 'New',
        CloseDate = Date.today(),
        AccountId = acc.Id,
        WinReason__c = 'Bloom Brand'
    );
    insert opp;


    // -------------------------------------------------
    // 8. Offer
    // -------------------------------------------------
    OffersPromotions__c offer =
        new OffersPromotions__c(
            Name = 'PDF Offer',
            OfferName__c = 'PDF Offer',
            Project__c = proj.Id,
            ADM_Fee_Included__c = false,
            StartDate__c = Date.today().addDays(-1),
            EndDate__c = Date.today().addDays(5)
        );
    insert offer;


    // -------------------------------------------------
    // 9. Sales Order
    // -------------------------------------------------
    SalesOrder__c so = new SalesOrder__c(
        Name = 'SO-PDF-1',
        Unit__c = unit.Id,
        Account__c = acc.Id,
        Opportunity__c = opp.Id,
        Status__c = 'Booked',
        Offer__c = offer.Id
    );
    insert so;


    // -------------------------------------------------
    // 10. Installment Line
    // -------------------------------------------------
    InstallmentLines__c inst =
        new InstallmentLines__c(
            SalesOrder__c = so.Id,
            PaymentPlan__c = plan.Id,
            PaymentInstallments__c = pi.Id,
            InstallmentAmount__c = 100000,
            InstallmentPercentage__c = 25,
            InstallmentNumber__c = 1,
            Description__c = 'PDF Test'
        );
    insert inst;


    // -------------------------------------------------
    // 11. Receipt Acknowledgement
    // -------------------------------------------------
    ReceiptAcknowledgement__c ack =
        new ReceiptAcknowledgement__c(
            SalesOrder__c = so.Id,
            Opportunity__c = opp.Id,
            PaymentType__c = 'Cheque',
            Amount__c = 90000,
            Status__c = 'Cleared',
            MaturityDate__c = Date.today(),
            ReferenceNumber__c = '567890'
        );
    insert ack;


    // -------------------------------------------------
    // 12. Receipt Allocation
    // -------------------------------------------------
    ReceiptAllocation__c ra =
        new ReceiptAllocation__c(
            SalesOrder__c = so.Id,
            Account__c = acc.Id,
            ReceiptAcknowledgement__c = ack.Id,
            InstallmentLine__c = inst.Id,
            AmountApplied__c = 90000
        );
    insert ra;


    // -------------------------------------------------
    // 13. Set VF Page
    // -------------------------------------------------
    Test.setCurrentPage(Page.SalesReceiptPDFPage);

    ApexPages.currentPage()
        .getParameters()
        .put('id', so.Id);


    // -------------------------------------------------
    // 14. Call method
    // -------------------------------------------------
    Test.startTest();

    String contentVersionId =
        SalesReceiptController.generateAndAttachPdf(
            so.Id
        );

    Test.stopTest();


    // -------------------------------------------------
    // 15. Validate returned ContentVersion Id
    // -------------------------------------------------
    System.assertNotEquals(
        null,
        contentVersionId,
        'ContentVersion Id should be returned.'
    );


    // -------------------------------------------------
    // 16. Validate ContentVersion
    // -------------------------------------------------
    ContentVersion cv = [
        SELECT Id,
               Title,
               PathOnClient,
               ContentDocumentId,
               VersionData
        FROM ContentVersion
        WHERE Id = :contentVersionId
        LIMIT 1
    ];

    System.assertEquals(
        'Receipt-Acknowledgment-' + so.Name,
        cv.Title,
        'Incorrect receipt file title.'
    );

    System.assertEquals(
        'Receipt-Acknowledgment-' + so.Name + '.pdf',
        cv.PathOnClient,
        'Incorrect receipt file name.'
    );

    System.assertNotEquals(
        null,
        cv.ContentDocumentId,
        'ContentDocumentId should be created.'
    );

    System.assertNotEquals(
        null,
        cv.VersionData,
        'PDF content should be created.'
    );


    // -------------------------------------------------
    // 17. Validate ContentDocumentLink
    // -------------------------------------------------
    ContentDocumentLink cdl = [
        SELECT Id,
               ContentDocumentId,
               LinkedEntityId,
               ShareType,
               Visibility
        FROM ContentDocumentLink
        WHERE ContentDocumentId = :cv.ContentDocumentId
        AND LinkedEntityId = :so.Id
        LIMIT 1
    ];

    System.assertEquals(
        cv.ContentDocumentId,
        cdl.ContentDocumentId
    );

    System.assertEquals(
        so.Id,
        cdl.LinkedEntityId
    );

    System.assertEquals(
        'V',
        cdl.ShareType
    );

    System.assertEquals(
        'AllUsers',
        cdl.Visibility
    );
}
}