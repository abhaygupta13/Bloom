@IsTest
public class LeasingDocumentsPDFHandlerTest {

    /* Reusing same pattern from LeasingOrderServiceTest */

    private static LeasingOrder__c createOrderWithFullData() {

        // Account
        Account acc = new Account(Name = 'PDF Test Account');
        insert acc;

        // Opportunity
        Opportunity opp = new Opportunity(
            Name = 'PDF Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = acc.Id
        );
        insert opp;

        // Unit
        Unit__c unitRec = new Unit__c(
            Name = 'PDF Unit'
        );
        insert unitRec;

        // Leasing Order
        LeasingOrder__c lo = new LeasingOrder__c(
            Name = 'PDF Leasing Order',
            Opportunity__c = opp.Id,
            Unit__c = unitRec.Id,
            Account__c = acc.Id,
            RentalAmountAfterDiscount__c = 10000
        );
        insert lo;

        // Payment Plan Schedules
        List<PaymentPlanSchedule__c> schedules = new List<PaymentPlanSchedule__c>{
            new PaymentPlanSchedule__c(
                LeasingOrder__c = lo.Id,
                ClearedAmount__c = 5000
            ),
            new PaymentPlanSchedule__c(
                LeasingOrder__c = lo.Id,
                ClearedAmount__c = 2000
            )
        };
        insert schedules;

        // Other Charges
        List<LeasingOrdersOtherCharges__c> charges = new List<LeasingOrdersOtherCharges__c>{
            new LeasingOrdersOtherCharges__c(
                LeasingOrder__c = lo.Id,
                ClearedAmount__c = 2000,
                ChargeAmount__c = 100,
                Type__c = 'Service Charge Fee'
            ),
            new LeasingOrdersOtherCharges__c(
                LeasingOrder__c = lo.Id,
                ClearedAmount__c = 1000,
                ChargeAmount__c = 100,
                Type__c = 'Admin Fee'
            )
        };
        insert charges;

        // Required Document for PDF generation
        Document__c doc = new Document__c(
            LeasingOrder__c = lo.Id,
            Document_Name__c = 'Statement of Account'
        );
        insert doc;

        return lo;
    }

    @IsTest
    static void testConstructor() {

        LeasingOrder__c lo = createOrderWithFullData();

        Test.setCurrentPage(Page.LeasingStatementOfAccountPDF);
        ApexPages.currentPage().getParameters().put('id', lo.Id);

        Test.startTest();
        LeasingDocumentsPDFHandler handler = new LeasingDocumentsPDFHandler();
        Test.stopTest();

        // Assertions
        System.assertEquals(2, handler.paymentPlans.size());
        System.assertEquals(2, handler.otherCharges.size());

        System.assertEquals(7000, handler.totalInstallmentCollection);

        //System.assertEquals(3000, handler.totalOCCollection);

        //System.assertEquals(10000, handler.totalCollection);

        System.assertNotEquals(null, handler.todayDate);
    }

    @IsTest
    static void testFormatDate() {

        Date testDate = Date.newInstance(2026, 2, 15);

        String formatted =
            LeasingDocumentsPDFHandler.formatDate(testDate);

        System.assertNotEquals('', formatted);

        String blank =
            LeasingDocumentsPDFHandler.formatDate(null);

        System.assertEquals('', blank);
    }

    @IsTest
    static void testGetLeasingOrderDetailInfo() {

        LeasingOrder__c lo = createOrderWithFullData();

        Test.startTest();
        List<LeasingOrder__c> result =
            LeasingDocumentsPDFHandler.getLeasingorderDetailIfo(lo.Id);
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals(2, result[0].Payment_Plan_Schedules__r.size());
        System.assertEquals(2, result[0].Leasing_Orders_Other_Charges__r.size());
    }

    @IsTest
    static void testGenerateAndAttachPdf() {

        LeasingOrder__c lo = createOrderWithFullData();

        Test.startTest();
        String contentVersionId =
            LeasingDocumentsPDFHandler.generateAndAttachPdf(lo.Id);
        Test.stopTest();

        System.assertNotEquals(null, contentVersionId);
    }
}