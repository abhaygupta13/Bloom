@IsTest
public class LeasingOtherChargeTaxInvoicePDFHdlrTest {

    @testSetup
    static void setupData() {

        Account acc = new Account(Name = 'Test Account', UAEVATRegisterNumber__c = 'VAT-OC-123');
        insert acc;

         Company__c lc = new Company__c(Name = 'Test Leasing Company', LeasingVAT__c = 5);
        insert lc;

        Project__c proj = new Project__c(Name = 'Test Project', Leasing_Company__c = lc.Id);
        insert proj;

        Unit__c unitRec = new Unit__c(Name = 'Test Unit', SAP_Unit_Number__c = 'SAP-U-001');
        insert unitRec;

        LeasingOrder__c order = new LeasingOrder__c(Name = 'Test Leasing Order', Status__c = 'Leased',Account__c = acc.Id,
                                                    Project__c = proj.Id,Unit__c = unitRec.Id,PropertyName__c = 'Bloom Central');
        insert order;

        LeasingOrdersOtherCharges__c otherCharge = new LeasingOrdersOtherCharges__c(LeasingOrder__c = order.Id,Type__c = 'Admin Fee',
                                                                                    ChargeAmount__c = 500,RefDocno__c = 'OC-INV-001',
                                                                                    VATAmount__c = 25,isVATApplied__c = true);
        insert otherCharge;

        Document__c doc = new Document__c(LeasingOrdersOtherCharges__c = otherCharge.Id,Document_Name__c = 'Tax Invoice');
        insert doc;
    }

    @IsTest
    static void testConstructorExecution() {

        LeasingOrdersOtherCharges__c oc = [SELECT Id FROM LeasingOrdersOtherCharges__c LIMIT 1];

        // Set Visualforce page context
        Test.setCurrentPage(Page.LeasingOtherChargeTaxInvoice);
        ApexPages.currentPage().getParameters().put('id', oc.Id);

        Test.startTest();
        LeasingOtherChargeTaxInvoicePDFHandler handler =
        new LeasingOtherChargeTaxInvoicePDFHandler();
        Test.stopTest();

        // Assertions – constructor logic
        System.assertEquals(false, handler.hasError);
        System.assertEquals('OC-INV-001', handler.invoiceNo);
        System.assertNotEquals(null, handler.invoiceDate);
        System.assertEquals(500, handler.amount);
        System.assertEquals(25, handler.vatAmount);
        System.assertEquals(525, handler.totalAmount);
        System.assertNotEquals(null, handler.amountInWords);
        System.assertEquals('Test Leasing Company', handler.leasingCompanyName);
        System.assertEquals('Test Account', handler.customerName);
        //System.assertEquals('SAP-OC-001', handler.customerAccNumber);
    }

    @IsTest
    static void testGenerateAndAttachPdf() {

        LeasingOrdersOtherCharges__c oc = [SELECT Id FROM LeasingOrdersOtherCharges__c LIMIT 1];

        Test.startTest();
        String contentVersionId =
        LeasingOtherChargeTaxInvoicePDFHandler.generateAndAttachPdf(oc.Id);
        Test.stopTest();

        System.assertNotEquals(null,contentVersionId,'ContentVersion should be created');
        ContentVersion cv = [SELECT Id, Title FROM ContentVersion WHERE Id = :contentVersionId];
        System.assertEquals('Tax Invoice', cv.Title);
    }

    @IsTest
    static void testValidationWithoutRefDocno() {
        LeasingOrdersOtherCharges__c oc = [SELECT Id, RefDocno__c FROM LeasingOrdersOtherCharges__c LIMIT 1];
        oc.RefDocno__c = null;
        update oc;

        Test.setCurrentPage(Page.LeasingOtherChargeTaxInvoice);
        ApexPages.currentPage().getParameters().put('id', oc.Id);

        Test.startTest();
        LeasingOtherChargeTaxInvoicePDFHandler handler = new LeasingOtherChargeTaxInvoicePDFHandler();
        System.assertEquals(true, handler.hasError);
        System.assert(String.isNotBlank(handler.errorMessage));

        try {
            LeasingOtherChargeTaxInvoicePDFHandler.generateAndAttachPdf(oc.Id);
            System.assert(false, 'Expected AuraHandledException was not thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null);
        }
        Test.stopTest();
    }
}