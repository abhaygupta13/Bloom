@isTest
private class BCAPP_SapInvoiceIngestServiceTest {

    private static Account makeAccount(String name, String acctNumber) {
        Account a = BCAPP_TestDataFactory.createAccount(name);
        a.AccountNumber = acctNumber;
        insert a;
        return a;
    }

    private static OnlinePayment__c makePayment(Account acc) {
        OnlinePayment__c p = new OnlinePayment__c(
            Account__c = acc.Id,
            Status__c = 'Success',
            PaidAmount__c = 99.99,
            PaymentMethod__c = 'CARD',
            RequestSource__c = 'API'
        );
        insert p;
        return p;
    }

    private static BCAPP_SapInvoiceClearingItem sapItem(String invoiceNo, String amount, String status) {
        BCAPP_SapInvoiceClearingItem s = new BCAPP_SapInvoiceClearingItem();
        s.Invoice = invoiceNo;
        s.Amount = amount;
        s.Bukrs = '1000';
        s.Buyer = 'ACC-EXT';
        s.Contract = 'UNIT-EXT';
        s.VerifiedDate = '2024-01-02';
        s.DueDate = '2024-01-05';
        s.MsgTxt = 'Ingested from SAP';
        s.RefDoc = 'REF-XYZ';
        s.Status = status;
        s.FiscalYear = '2024';
        return s;
    }

    @isTest static void test_single_invoice_links_payment_and_lines() {
        Account acc = makeAccount('Ingest AC', 'ACC-ING-001');
        OnlinePayment__c pay = makePayment(acc);
        OnlinePaymentLineItem__c li = new OnlinePaymentLineItem__c(
            OnlinePayment__c = pay.Id,
            PlannedAmount__c = 99.99
        );
        insert li;

        List<BCAPP_SapInvoiceClearingItem> items = new List<BCAPP_SapInvoiceClearingItem>{
            sapItem('SAP-INV-1001', '99.99', 'Paid')
        };

        Test.startTest();
        BCAPP_SapInvoiceIngestService.getInstance().createMiscInvoicesFromSapResponse(
            pay,
            new List<OnlinePaymentLineItem__c>{ li },
            items
        );
        Test.stopTest();

        // Verify invoice upserted
        Invoice__c inv = [
            SELECT Id, SAPInvoiceNumber__c, CompanyCode__c, Status__c, InvoiceDescription__c, Account__c, DueAmount__c
            FROM Invoice__c
            WHERE SAPInvoiceNumber__c = 'SAP-INV-1001'
            LIMIT 1
        ];
        System.assertEquals('SAP-INV-1001', inv.SAPInvoiceNumber__c);
        System.assertEquals('1000', inv.CompanyCode__c);
        System.assertEquals('Paid', inv.Status__c);
        System.assertEquals('Ingested from SAP', inv.InvoiceDescription__c);
        System.assertEquals(acc.Id, inv.Account__c);
        System.assertEquals(0, inv.DueAmount__c, 'Paid should set DueAmount to 0');

        // Verify payment and line item linked when only one invoice
        pay = [SELECT Invoice__c FROM OnlinePayment__c WHERE Id = :pay.Id];
        System.assertEquals(inv.Id, pay.Invoice__c, 'Payment should link to single invoice');

        li = [SELECT Invoice__c FROM OnlinePaymentLineItem__c WHERE Id = :li.Id];
        System.assertEquals(inv.Id, li.Invoice__c, 'Line item should link to single invoice');
    }

    @isTest static void test_multiple_invoices_do_not_link_payment() {
        Account acc = makeAccount('Ingest AC 2', 'ACC-ING-002');
        OnlinePayment__c pay = makePayment(acc);
        OnlinePaymentLineItem__c li = new OnlinePaymentLineItem__c(
            OnlinePayment__c = pay.Id,
            PlannedAmount__c = 50
        );
        insert li;

        List<BCAPP_SapInvoiceClearingItem> items = new List<BCAPP_SapInvoiceClearingItem>{
            sapItem('SAP-INV-2001', '50.00', 'Paid'),
            sapItem('SAP-INV-2002', '25.00', 'Paid')
        };

        Test.startTest();
        BCAPP_SapInvoiceIngestService.getInstance().createMiscInvoicesFromSapResponse(
            pay,
            new List<OnlinePaymentLineItem__c>{ li },
            items
        );
        Test.stopTest();

        // Both invoices should exist
        Integer invCount = [SELECT COUNT() FROM Invoice__c WHERE SAPInvoiceNumber__c IN ('SAP-INV-2001','SAP-INV-2002')];
        System.assertEquals(2, invCount);

        // Payment and line should not be linked when multiple invoices
        pay = [SELECT Invoice__c FROM OnlinePayment__c WHERE Id = :pay.Id];
        System.assertEquals(null, pay.Invoice__c, 'Should not link when multiple invoices created');

        li = [SELECT Invoice__c FROM OnlinePaymentLineItem__c WHERE Id = :li.Id];
        System.assertEquals(null, li.Invoice__c, 'Line item should remain unlinked when multiple invoices');
    }

    @isTest static void test_idempotent_upsert_on_same_invoice_number() {
        Account acc = makeAccount('Ingest AC 3', 'ACC-ING-003');
        OnlinePayment__c pay = makePayment(acc);

        List<BCAPP_SapInvoiceClearingItem> items = new List<BCAPP_SapInvoiceClearingItem>{
            sapItem('SAP-INV-3001', '10.00', 'Paid')
        };

        Test.startTest();
        BCAPP_SapInvoiceIngestService.getInstance().createMiscInvoicesFromSapResponse(pay, null, items);
        // Call again with different amount to ensure upsert (External ID) updates same row
        items[0].Amount = '20.00';
        BCAPP_SapInvoiceIngestService.getInstance().createMiscInvoicesFromSapResponse(pay, null, items);
        Test.stopTest();

        // Only one invoice with that SAP number should exist
        List<Invoice__c> rows = [
            SELECT Id, TotalAmount__c FROM Invoice__c WHERE SAPInvoiceNumber__c = 'SAP-INV-3001'
        ];
        System.assertEquals(1, rows.size());
        // Amount reflects latest upsert (20.00)
        System.assertEquals(20, rows[0].TotalAmount__c);
    }
}