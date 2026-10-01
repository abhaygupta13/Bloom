@IsTest
public class PaymentPlanInvoicePDFHandlerTest {

    @testSetup
    static void setupData() {

        Account acc = new Account(Name = 'Test Account', UAEVATRegisterNumber__c = 'VAT123');
        insert acc;

        Company__c lc = new Company__c(Name = 'Test Leasing Company');
        insert lc;

        Project__c proj = new Project__c(Name = 'Test Project',Leasing_Company__c = lc.Id);
        insert proj;

        Unit__c unitRec = new Unit__c(Name = 'Unit-101', SAP_Unit_Number__c = 'SAP-U-001');
        insert unitRec;

        LeasingOrder__c order = new LeasingOrder__c(Name = 'Test Leasing Order',Account__c = acc.Id,Project__c = proj.Id,
                                                    Unit__c = unitRec.Id,PropertyName__c = 'Abu Dhabi');
        insert order;

        PaymentPlanSchedule__c schedule = new PaymentPlanSchedule__c(Name = 'Schedule 1',LeasingOrder__c = order.Id,Amount__c = 1000,
                                                                     PaymentStartDate__c = Date.today(), RefDocno__c = 'INV-001');
        insert schedule;

        Document__c doc = new Document__c(PaymentPlanSchedule__c = schedule.Id,Document_Name__c = 'Tax Invoice');
        insert doc;
    }

    @IsTest
    static void testConstructorExecution() {

        PaymentPlanSchedule__c schedule = [SELECT Id FROM PaymentPlanSchedule__c LIMIT 1];

        // Set VF page context
        Test.setCurrentPage(Page.PaymentPlanTaxInvoicePDF);
        ApexPages.currentPage().getParameters().put('id', schedule.Id);

        Test.startTest();
        PaymentPlanInvoicePDFHandler handler = new PaymentPlanInvoicePDFHandler();
        Test.stopTest();

        // Assertions – constructor populated values
        System.assertEquals(false, handler.hasError);
        System.assertEquals('INV-001', handler.invoiceNo);
        System.assertNotEquals(null, handler.invoiceDate);
        System.assertEquals(1000, handler.amount);
        //System.assertEquals(50, handler.vatAmount);
        //System.assertEquals(1050, handler.totalAmount);
        System.assertNotEquals(null, handler.amountInWords);
        System.assertEquals('Test Leasing Company', handler.leasingCompanyName);
    }

    @IsTest
    static void testGenerateAndAttachPdf() {

        PaymentPlanSchedule__c schedule = [SELECT Id FROM PaymentPlanSchedule__c LIMIT 1];

        Test.startTest();
        String contentVersionId =PaymentPlanInvoicePDFHandler.generateAndAttachPdf(schedule.Id);
        Test.stopTest();

        System.assertNotEquals(null,contentVersionId,'ContentVersion should be created');
        ContentVersion cv = [SELECT Id, Title FROM ContentVersion WHERE Id = :contentVersionId];
        System.assertEquals('Tax Invoice', cv.Title);
    }

    @IsTest
    static void testValidationWithoutRefDocno() {
        PaymentPlanSchedule__c schedule = [SELECT Id, RefDocno__c FROM PaymentPlanSchedule__c LIMIT 1];
        schedule.RefDocno__c = null;
        update schedule;

        Test.setCurrentPage(Page.PaymentPlanTaxInvoicePDF);
        ApexPages.currentPage().getParameters().put('id', schedule.Id);

        Test.startTest();
        PaymentPlanInvoicePDFHandler handler = new PaymentPlanInvoicePDFHandler();
        System.assertEquals(true, handler.hasError);
        System.assert(String.isNotBlank(handler.errorMessage));

        try {
            PaymentPlanInvoicePDFHandler.generateAndAttachPdf(schedule.Id);
            System.assert(false, 'Expected AuraHandledException was not thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null);
        }
        Test.stopTest();
    }
}