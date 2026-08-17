@isTest
private class OnlinePaymentServiceTest {

    // ---- helpers ----
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

    private static Invoice__c makeInvoice(Account acc, Unit__c unit, String sapNo, Decimal total) {
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
            SAPInvoiceNumber__c = sapNo,
            TotalAmount__c = total,
            DueAmount__c   = total
        );
        insert inv;
        return inv;
    }

    private static OnlinePayment__c makePayment(Account acc, Unit__c unit, String status, Decimal amount, String method) {
        OnlinePayment__c p = new OnlinePayment__c(
            Account__c = acc.Id,
            Unit__c = unit != null ? unit.Id : null,
            Status__c = status,
            PaidAmount__c = amount,
            PaymentMethod__c = method,
            RequestSource__c = 'API',
            GatewayReference__c = 'GW-' + String.valueOf(Math.abs(Crypto.getRandomInteger()))
        );
        insert p;
        return p;
    }

    @isTest static void test_insert_and_get_payment_by_id() {
        Account acc = makeAccount('OPS AC 1', 'OPS-001');
        Unit__c unit = makeUnit('U-OPS-001');

        OnlinePayment__c p = new OnlinePayment__c(
            Account__c = acc.Id,
            Unit__c = unit.Id,
            Status__c = 'Pending',
            PaidAmount__c = 123.45,
            PaymentMethod__c = 'CARD',
            RequestSource__c = 'API',
            GatewayReference__c = 'GW-1'
        );

        Test.startTest();
        p = OnlinePaymentService.getInstance().insertPayment(p);
        Test.stopTest();

        System.assertNotEquals(null, p.Id, 'Inserted payment should have Id');
        OnlinePayment__c fetched = OnlinePaymentService.getInstance().getPaymentById(p.Id);
        System.assertEquals(p.Id, fetched.Id);
        System.assertEquals('Pending', fetched.Status__c);
        System.assertEquals(123.45, fetched.PaidAmount__c);
    }

    @isTest static void test_update_payment() {
        Account acc = makeAccount('OPS AC 2', 'OPS-002');
        Unit__c unit = makeUnit('U-OPS-002');
        OnlinePayment__c p = makePayment(acc, unit, 'Pending', 50, 'CARD');

        p.Status__c = 'Success';
        p.ResponseMessage__c = 'OK';

        Test.startTest();
        OnlinePaymentService.getInstance().updatePayment(p);
        Test.stopTest();

        OnlinePayment__c got = [SELECT Status__c, ResponseMessage__c FROM OnlinePayment__c WHERE Id = :p.Id];
        System.assertEquals('Success', got.Status__c);
        System.assertEquals('OK', got.ResponseMessage__c);
    }

    @isTest static void test_get_line_items_by_payment() {
        Account acc = makeAccount('OPS AC 3', 'OPS-003');
        Unit__c unit = makeUnit('U-OPS-003');
        OnlinePayment__c p = makePayment(acc, unit, 'Pending', 75, 'CARD');

        OnlinePaymentLineItem__c li1 = new OnlinePaymentLineItem__c(
            OnlinePayment__c = p.Id,
            PlannedAmount__c = 50
        );
        OnlinePaymentLineItem__c li2 = new OnlinePaymentLineItem__c(
            OnlinePayment__c = p.Id,
            PlannedAmount__c = 25
        );
        insert new List<OnlinePaymentLineItem__c>{ li1, li2 };

        List<OnlinePaymentLineItem__c> got = OnlinePaymentService.getInstance().getLineItemsByPayment(p.Id);
        System.assertEquals(2, got.size());
        for (OnlinePaymentLineItem__c row : got) System.assertEquals(p.Id, row.OnlinePayment__c);
    }

    @isTest static void test_get_successful_payments_by_account() {
        Account acc = makeAccount('OPS AC 4', 'OPS-004');
        Unit__c unit = makeUnit('U-OPS-004');
        // Success and non-success payments
        OnlinePayment__c p1 = makePayment(acc, unit, 'Pending', 10, 'CARD');
        OnlinePayment__c p2 = makePayment(acc, unit, 'Success', 20, 'CARD');
        OnlinePayment__c p3 = makePayment(acc, unit, 'Success', 30, 'CARD');

        Test.startTest();
        List<OnlinePayment__c> succAll = OnlinePaymentService.getInstance().getSuccessfulPaymentsByAccount(acc.Id, 10);
        List<OnlinePayment__c> succOne = OnlinePaymentService.getInstance().getSuccessfulPaymentsByAccount(acc.Id, 1);
        Test.stopTest();

        System.assertEquals(2, succAll.size(), 'Only Success should be returned');
        System.assertEquals(1, succOne.size(), 'Limit respected');
        System.assertEquals('Success', succOne[0].Status__c);
    }

    @isTest static void test_get_by_ids_for_email_and_get_for_payment_posting() {
        Account acc = makeAccount('OPS AC 5', 'OPS-005');
        Unit__c unit = makeUnit('U-OPS-005');
        Invoice__c inv = makeInvoice(acc, unit, 'SAP-OPS-1', 99);

        OnlinePayment__c p = new OnlinePayment__c(
            Account__c = acc.Id,
            Unit__c = unit.Id,
            Status__c = 'Success',
            PaidAmount__c = 99,
            PaymentMethod__c = 'CARD',
            RequestSource__c = 'API',
            GatewayReference__c = 'GW-EMAIL',
            Invoice__c = inv.Id
        );
        insert p;

        // getByIdsForEmail
        Map<Id, OnlinePayment__c> mapRes = OnlinePaymentService.getInstance().getByIdsForEmail(new Set<Id>{ p.Id });
        System.assertEquals(true, mapRes.containsKey(p.Id));
        OnlinePayment__c em = mapRes.get(p.Id);
        System.assertEquals(acc.Id, em.Account__c);
        System.assertEquals(inv.Id, em.Invoice__c);

        // getForPaymentPosting
        OnlinePayment__c post = OnlinePaymentService.getInstance().getForPaymentPosting(p.Id);
        System.assertEquals('Success', post.Status__c);
        System.assertEquals(acc.SAP_BP_No__c, post.Account__r.SAP_BP_No__c);
        System.assertEquals(inv.Id, post.Invoice__c);
        System.assertEquals('SAP-OPS-1', post.Invoice__r.SAPInvoiceNumber__c);
    }
}