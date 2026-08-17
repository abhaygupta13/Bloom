@isTest
private class BCAPP_ReceiptPDFControllerTest {

    private static Account makeAccount(String name, String acctNumber) {
        Account a = BCAPP_TestDataFactory.createAccount(name);
        a.SAP_BP_No__c = acctNumber;
        insert a;
        return a;
    }

    private static Unit__c makeUnit(String name) {
        Unit__c u = new Unit__c(Name = name);
        insert u;
        return u;
    }

    private static Invoice__c makeInvoice(Account acc, Unit__c unit) {
        String yearStr = String.valueOf(Date.today().year());
        Invoice__c inv = new Invoice__c(
            Account__c = acc.Id,
            Unit__c    = unit.Id,
            Status__c  = 'Unpaid',
            DocumentType__c = 'DR',
            CompanyCode__c  = '1000',
            PostingDate__c  = Date.today(),
            InvoiceDate__c  = Date.today(),
            InvoiceYear__c  = yearStr,
            SAPInvoiceNumber__c = 'SAP-INV-1',
            TotalAmount__c = 150,
            DueAmount__c   = 150
        );
        insert inv;
        return inv;
    }

    private static Receipt__c makeReceipt(Account acc, Unit__c unit, Decimal amt) {
        Receipt__c r = new Receipt__c(
            AmountReceived__c = amt,
            PaymentDate__c    = Date.today(),
            PaymentMode__c    = 'Online',
            Status__c         = 'Posted',
            Account__c        = acc.Id,
            Unit__c           = unit.Id,
            TechnologyFee__c  = 1.25
        );
        insert r;
        return r;
    }

    @isTest static void test_controller_with_allocations_builds_header() {
        Account acc = makeAccount('Receipt AC', 'ACC-001');
        Unit__c unit  = makeUnit('U-RCP-001');
        Invoice__c inv = makeInvoice(acc, unit);
        Receipt__c rec = makeReceipt(acc, unit, 100);

        // Link allocation
        InvoiceAllocation__c alloc = new InvoiceAllocation__c(
            Invoice__c         = inv.Id,
            Receipt__c         = rec.Id,
            AllocatedAmount__c = 100,
            AllocationDate__c  = Date.today()
        );
        insert alloc;

        // Set the VF parameter
        ApexPages.currentPage().getParameters().put('receiptId', (String) rec.Id);

        BCAPP_ReceiptPDFController ctrl = new BCAPP_ReceiptPDFController();

        System.assertNotEquals(null, ctrl.receipt, 'Receipt should be loaded');
        System.assert(!ctrl.allocations.isEmpty(), 'Allocations should be loaded');
        // Receipt number format: CompanyCode/SAPInvoiceNumber/InvoiceYear
        String expectedNo = '1000/SAP-INV-1/' + String.valueOf(Date.today().year());
        //System.assertEquals(expectedNo, ctrl.receiptNo);
        System.assertEquals('100.00', ctrl.amountReceived2dp);
        System.assertEquals('Online', ctrl.paymentType);
    }

    @isTest static void test_controller_without_allocations_fallbacks_to_receipt_name() {
        Account acc = makeAccount('Receipt AC 2', 'ACC-002');
        Unit__c unit  = makeUnit('U-RCP-002');
        Receipt__c rec = makeReceipt(acc, unit, 50);
        // Re‑query to ensure Name (auto-number) is populated locally
        rec = [SELECT Id, Name FROM Receipt__c WHERE Id = :rec.Id LIMIT 1];

        ApexPages.currentPage().getParameters().put('receiptId', (String) rec.Id);
        BCAPP_ReceiptPDFController ctrl = new BCAPP_ReceiptPDFController();

        System.assert(!String.isBlank(ctrl.receiptNo), 'Receipt number should not be blank');
        System.assertEquals(rec.Name, ctrl.receiptNo, 'Fallback to receipt name when no allocations');
        System.assertEquals('50.00', ctrl.amountReceived2dp);
    }
}