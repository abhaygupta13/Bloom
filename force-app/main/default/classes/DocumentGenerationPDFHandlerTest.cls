@isTest
public class DocumentGenerationPDFHandlerTest {
    @isTest static void DocumentGenerationPDFHandlerTestMethod() {
        // Create Project
        Project__c testProject = new Project__c(Name='Test Project');
        insert testProject;

        // Create Building Section
        BuildingSection__c testBuilding = new BuildingSection__c(
            Name='Test Building',
            BuildingSectionCode__c='BL-CAS',
            Project__c=testProject.Id
        );
        insert testBuilding;

        // Create Unit
        Unit__c testUnit = new Unit__c(
            Name='test Unit',
            Status__c='Booked',
            UnitType__c='Townhouse',
            BuildingSectionName__c=testBuilding.Id,
            Project__c=testProject.Id,
            PropertyUsage__c='Residential',
            UnitView__c='Beach Side',
            FloorNumber__c='01',
            NumberOfBedrooms__c='3',
            UnitModel__c='1BHK',
            SellingPrice__c=700000,
            StartDate__c=Date.today().addDays(-10),
            EndDate__c=Date.today().addDays(10),
            LockExpiryTime__c=DateTime.now().addDays(10),
            LockedBy__c=UserInfo.getUserId()
        );
        insert testUnit;

        // Create Payment Plan
        PaymentPlan__c pp = new PaymentPlan__c(
            Name='July Plan',
            Unit__c=testUnit.Id,
            Description__c='Test',
            //IsActive__c='Yes',
            BrokerPortalFlag__c=true,
            CustomerSubType__c='CORPORATE',
            Classification__c=Constants.PAYMENT_PLAN_TYPE_STANDARD
        );
        insert pp;

        // Map Building Section to Payment Plan
        insert new BuildingSectionMapping__c(
            BuildingSectionName__c=testBuilding.Id,
            PaymentPlan__c=pp.Id
        );

        // Create Person Account
        Id rtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Account tempAcc = new Account(
            RecordTypeId=rtId,
            LastName='Test',
            PersonEmail='Jana@tesrt.com',
            CustomerSubType__c='CORPORATE'
        );
        insert tempAcc;

        // Create Opportunity
        Opportunity tempOpp = new Opportunity(
            Name='tempOpp',
            StageName='New',
            CloseDate=System.today(),
            LeadChannel__c='Walk in',
            AccountId=tempAcc.Id,
            WinReason__c='Loyalty'
        );
        insert tempOpp;

        // Create Payment Installments
        PaymentInstallments__c ppi = new PaymentInstallments__c(
            BrokerPayoutPercentage__c=100,
            Description__c='test description',
            InstallmentNumber__c=1,
            InstallmentPercentage__c=100,
            PaymentPlan__c=pp.Id,
            Condition_Type__c='P012'
        );
        insert ppi;

        OffersPromotions__c testOffer=new OffersPromotions__c(
            Name='testOffer',
            OfferName__c='testOffer',
            Project__c=testProject.id,
            StartDate__c=system.today(),
            EndDate__c=system.today().addDays(2),
            ADM_Fee_Included__c=true
        );
        insert testOffer;
        
        // Create Sales Order
        SalesOrder__c testOrder = new SalesOrder__c(
            Name='Test Order',
            Status__c='Booked',
            Unit__c=testUnit.Id,
            Account__c=tempAcc.Id,
            Opportunity__c=tempOpp.Id,
            Bloom_Signed_SPA_Date__c=Date.today(),
            Offer__c=testOffer.Id
        );
        insert testOrder;

        // Create Installment Line
        InstallmentLines__c installment = new InstallmentLines__c(
            SalesOrder__c=testOrder.Id,
            PaymentPlan__c=pp.Id,
            PaymentInstallments__c=ppi.Id,
            InstallmentAmount__c=70000,
            InstallmentDate__c=Date.today().addDays(-12),
            InstallmentPercentage__c=25,
            LPCAmount__c=500,
            Description__c = 'Test',
            InstallmentNumber__c = 1
        );
        insert installment;
        
        InstallmentLines__c installment1 = new InstallmentLines__c(
            SalesOrder__c=testOrder.Id,
            PaymentPlan__c=pp.Id,
            PaymentInstallments__c=ppi.Id,
            InstallmentAmount__c=70000,
            InstallmentDate__c=Date.today().addDays(-12),
            InstallmentPercentage__c=25,
            LPCAmount__c=500,
            Description__c = 'Test',
            InstallmentNumber__c = 2
        );
        insert installment1;

        // Create Receipt Acknowledgement
        ReceiptAcknowledgement__c ack = new ReceiptAcknowledgement__c(
            PaymentType__c='Online',
            Opportunity__c=tempOpp.Id,
            Amount__c=1200000,
            MaturityDate__c=Date.today(),
            SalesOrder__c=testOrder.Id,
            Status__c='Cleared'
        );
        insert ack;
        
        ReceiptAcknowledgement__c ack1 = new ReceiptAcknowledgement__c(
            PaymentType__c='Online',
            Opportunity__c=tempOpp.Id,
            Amount__c=1200000,
            MaturityDate__c=Date.today(),
            SalesOrder__c=testOrder.Id,
            Status__c='Received'
        );
        insert ack1;
        
        // Create Sales Order Other Charge
        SalesOrderOtherCharges__c otherCharge = new SalesOrderOtherCharges__c(
            SalesOrder__c=testOrder.Id,
            Account__c=tempAcc.Id,
            TypeOfCharge__c = 'ADM Fee',
            Amount__c=10000,
            Due_Date__c=Date.today()
        );
        insert otherCharge;

        // Create Receipt Allocation for Installment
        ReceiptAllocation__c recInstallment = new ReceiptAllocation__c(
            ReceiptAcknowledgement__c=ack.Id,
            Account__c=tempAcc.Id,
            SalesOrder__c=testOrder.Id,
            AmountApplied__c=12000,
            InstallmentLine__c=installment.Id
        );
        insert recInstallment;

        // Create Receipt Allocation for Other Charges
        ReceiptAllocation__c recOtherCharge = new ReceiptAllocation__c(
            ReceiptAcknowledgement__c=ack1.Id,
            Account__c=tempAcc.Id,
            AmountApplied__c=12000,
            SalesOrder__c=testOrder.Id,
            InstallmentLine__c = installment.id,
            SalesOrderOtherCharges__c=otherCharge.Id,
            TypeOfInvoice__c = 'ADM'
        );
        insert recOtherCharge;
        
        ReceiptAllocation__c recOtherCharge1 = new ReceiptAllocation__c(
            ReceiptAcknowledgement__c=ack1.Id,
            Account__c=tempAcc.Id,
            AmountApplied__c=12000,
            SalesOrder__c=testOrder.Id,
            InstallmentLine__c = installment.id
        );
        insert recOtherCharge1;

        // Set current page with ID
        PageReference pageRef = Page.ReceiptAcknowledgementPDF;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('id', testOrder.Id);

        Test.startTest();
        // Test method calls
        List<Salesorder__c> lines = DocumentGenerationPDFHandler.getSalesorderDetailIfo(testOrder.Id);

        DocumentGenerationPDFHandler handler = new DocumentGenerationPDFHandler();
        System.assertNotEquals(null, handler.salesOrderWrapperList);
        System.assert(handler.salesOrderWrapperList.size() > 0, 'Expected at least one sales order wrapper');

        String dateStr = DocumentGenerationPDFHandler.formatDate(Date.today());
        System.assertNotEquals(null, dateStr);

        String currencyStr = DocumentGenerationPDFHandler.formatCurrency(788);
        System.assertEquals('788.00', currencyStr);

        String contentId = DocumentGenerationPDFHandler.generateAndAttachPdf(testOrder.Id, 'generateReceipt');
        System.assertNotEquals(null, contentId);
        Test.stopTest();
    }
}