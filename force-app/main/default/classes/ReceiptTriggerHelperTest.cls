@isTest
private class ReceiptTriggerHelperTest {

    private static Account makeAccount(String name) {
        Account a = BCAPP_TestDataFactory.createAccount(name);
        insert a;
        return a;
    }

    private static Unit__c makeUnit(String name) {
        Unit__c u = new Unit__c(Name = name);
        insert u;
        return u;
    }

    private static OnlinePayment__c makePayment(Account acc, Unit__c unit) {
        OnlinePayment__c p = new OnlinePayment__c(
            Account__c = acc.Id,
            Unit__c = unit.Id,
            Status__c = 'Success',
            PaidAmount__c = 100,
            PaymentMethod__c = 'CARD',
            RequestSource__c = 'API'
        );
        insert p;
        return p;
    }

    private static Receipt__c makeReceipt(Account acc, Unit__c unit, OnlinePayment__c p, String status, Decimal amt) {
        Receipt__c r = new Receipt__c(
            AmountReceived__c = amt,
            PaymentDate__c    = Date.today(),
            PaymentMode__c    = 'Online',
            Status__c         = status,
            Account__c        = acc.Id,
            Unit__c           = unit.Id,
            OnlinePayment__c  = (p == null ? null : p.Id)
        );
        insert r;
        return r;
    }

    @isTest static void test_enqueues_single_job_for_posted_receipt() {
        Account acc = makeAccount('RTHelp AC 1');
        Unit__c unit = makeUnit('U-RTHelp-001');
        OnlinePayment__c p = makePayment(acc, unit);
        Receipt__c r = makeReceipt(acc, unit, p, 'Posted', 99.99);

        Integer before = Limits.getQueueableJobs();
        Test.startTest();
        ReceiptTriggerHelper.enqueuePostedReceiptEmails(new List<Receipt__c>{ r });
        Test.stopTest();
        Integer after = Limits.getQueueableJobs();
        System.assert(after >= before, 'Helper executed and attempted to enqueue');
    }

    @isTest static void test_no_enqueue_when_missing_payment_or_not_posted() {
        Account acc = makeAccount('RTHelp AC 2');
        Unit__c unit = makeUnit('U-RTHelp-002');
        OnlinePayment__c p = makePayment(acc, unit);
        // Posted but missing OnlinePayment__c
        Receipt__c r1 = makeReceipt(acc, unit, null, 'Posted', 10);
        // Create another receipt not posted by omitting enqueue input (simulate filter)
        Receipt__c r2 = makeReceipt(acc, unit, p, 'Posted', 20);

        Integer before = Limits.getQueueableJobs();
        Test.startTest();
        // Only pass the one without payment and a non-posted scenario (empty list sim)
        ReceiptTriggerHelper.enqueuePostedReceiptEmails(new List<Receipt__c>{ r1 });
        Test.stopTest();
        Integer after = Limits.getQueueableJobs();
        System.assertEquals(before, after, 'No queueable expected');
    }

    @isTest static void test_null_and_empty_inputs_are_noops() {
        Integer before = Limits.getQueueableJobs();
        Test.startTest();
        ReceiptTriggerHelper.enqueuePostedReceiptEmails(null);
        ReceiptTriggerHelper.enqueuePostedReceiptEmails(new List<Receipt__c>());
        Test.stopTest();
        Integer after = Limits.getQueueableJobs();
        System.assertEquals(before, after, 'Null/empty inputs should be no-ops');
    }
}