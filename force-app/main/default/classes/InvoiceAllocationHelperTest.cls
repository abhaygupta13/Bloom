@isTest
private class InvoiceAllocationHelperTest {

    // Test data helpers
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

    private static Invoice__c makeInvoice(Account acc, Unit__c unit, Decimal totalAmt) {
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
            SAPInvoiceNumber__c = 'SAP-' + String.valueOf(Math.abs(Crypto.getRandomInteger())),
            TotalAmount__c = totalAmt,
            DueAmount__c   = totalAmt
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
            Unit__c           = unit.Id
        );
        insert r;
        return r;
    }

    private static InvoiceAllocation__c makeAllocation(Invoice__c inv, Receipt__c rec, Decimal amt, Date allocDate) {
        InvoiceAllocation__c a = new InvoiceAllocation__c(
            Invoice__c         = inv.Id,
            Receipt__c         = rec.Id,
            AllocatedAmount__c = amt,
            AllocationDate__c  = allocDate
        );
        insert a;
        return a;
    }

    @isTest static void test_update_status_unpaid_when_alloc_zero() {
        Account acc = makeAccount('IAH AC 1', 'ACC-IAH-001');
        Unit__c unit = makeUnit('U-IAH-001');
        Invoice__c inv = makeInvoice(acc, unit, 120);
        Receipt__c rec = makeReceipt(acc, unit, 0);
        // Create allocation with zero amount to include invoice in helper scope
        InvoiceAllocation__c alloc = makeAllocation(inv, rec, 0, Date.today());

        Test.startTest();
        InvoiceAllocationHelper.updateInvoiceStatuses(new Set<Id>{ alloc.Id });
        Test.stopTest();

        inv = [SELECT Id, Status__c, TotalAmount__c, DueAmount__c FROM Invoice__c WHERE Id = :inv.Id];
        System.assertEquals('Unpaid', inv.Status__c);
        System.assertEquals(120, inv.DueAmount__c);
    }

    @isTest static void test_update_status_partially_paid() {
        Account acc = makeAccount('IAH AC 2', 'ACC-IAH-002');
        Unit__c unit = makeUnit('U-IAH-002');
        Invoice__c inv = makeInvoice(acc, unit, 150);
        Receipt__c rec = makeReceipt(acc, unit, 150);
        InvoiceAllocation__c a1 = makeAllocation(inv, rec, 50, Date.today().addDays(-1));
        InvoiceAllocation__c a2 = makeAllocation(inv, rec, 25, Date.today());

        Test.startTest();
        InvoiceAllocationHelper.updateInvoiceStatuses(new Set<Id>{ a1.Id, a2.Id });
        Test.stopTest();

        inv = [SELECT Id, Status__c, TotalAmount__c, DueAmount__c FROM Invoice__c WHERE Id = :inv.Id];
        System.assertEquals('Partially Paid', inv.Status__c);
        System.assertEquals(75, inv.DueAmount__c);
    }

    @isTest static void test_update_status_paid() {
        Account acc = makeAccount('IAH AC 3', 'ACC-IAH-003');
        Unit__c unit = makeUnit('U-IAH-003');
        Invoice__c inv = makeInvoice(acc, unit, 200);
        Receipt__c rec = makeReceipt(acc, unit, 200);
        InvoiceAllocation__c a1 = makeAllocation(inv, rec, 120, Date.today().addDays(-2));
        InvoiceAllocation__c a2 = makeAllocation(inv, rec, 80,  Date.today());

        Test.startTest();
        InvoiceAllocationHelper.updateInvoiceStatuses(new Set<Id>{ a1.Id, a2.Id });
        Test.stopTest();

        inv = [SELECT Id, Status__c, TotalAmount__c, DueAmount__c FROM Invoice__c WHERE Id = :inv.Id];
        System.assertEquals('Paid', inv.Status__c);
        System.assertEquals(0, inv.DueAmount__c);
    }

    @isTest static void test_bulk_multiple_invoices_mixed_outcomes() {
        Account acc = makeAccount('IAH AC 4', 'ACC-IAH-004');
        Unit__c unit = makeUnit('U-IAH-004');
        Invoice__c inv1 = makeInvoice(acc, unit, 100);
        Invoice__c inv2 = makeInvoice(acc, unit, 80);
        Receipt__c rec = makeReceipt(acc, unit, 180);

        // inv1 -> partial (60 of 100)
        InvoiceAllocation__c x1 = makeAllocation(inv1, rec, 60, Date.today());
        // inv2 -> paid (80 of 80)
        InvoiceAllocation__c y1 = makeAllocation(inv2, rec, 80, Date.today());

        Test.startTest();
        InvoiceAllocationHelper.updateInvoiceStatuses(new Set<Id>{ x1.Id, y1.Id });
        Test.stopTest();

        inv1 = [SELECT Id, Status__c, DueAmount__c FROM Invoice__c WHERE Id = :inv1.Id];
        inv2 = [SELECT Id, Status__c, DueAmount__c FROM Invoice__c WHERE Id = :inv2.Id];
        System.assertEquals('Partially Paid', inv1.Status__c);
        System.assertEquals(40, inv1.DueAmount__c);
        System.assertEquals('Paid', inv2.Status__c);
        System.assertEquals(0, inv2.DueAmount__c);
    }
}