@isTest
private class InvoiceTriggerHelperTest {

    // --- helpers ---
    private static Account makeAccount(String name, String acctNumber) {
        Account a = BCAPP_TestDataFactory.createAccount(name);
        a.SAP_BP_No__c = acctNumber;
        insert a;
        return a;
    }

    private static Invoice__c baseInvoice() {
        String yearStr = String.valueOf(Date.today().year());
        return new Invoice__c(
            Status__c         = 'Unpaid',
            DocumentType__c   = 'DR',
            CompanyCode__c    = '1000',
            PostingDate__c    = Date.today(),
            InvoiceDate__c    = Date.today(),
            InvoiceYear__c    = yearStr,
            SAPInvoiceNumber__c = 'HLP-' + String.valueOf(Math.abs(Crypto.getRandomInteger())),
            TotalAmount__c    = 100,
            DueAmount__c      = 100
        );
    }

    @isTest static void test_populates_account_when_missing() {
        Account acc = makeAccount('Helper AC', 'ACC-H-001');

        Invoice__c inv = baseInvoice();
        inv.CustomerNumber__c    = 'ACC-H-001';
        inv.SAPContractNumber__c = null;
        inv.SAPUnitNumber__c     = null;
        insert inv;

        Test.startTest();
        InvoiceTriggerHelper.upsertLookupsForNewInvoices(new List<Invoice__c>{ inv });
        Test.stopTest();

        inv = [SELECT Id, Account__c FROM Invoice__c WHERE Id = :inv.Id];
        System.assertEquals(acc.Id, inv.Account__c, 'Account__c should be set from CustomerNumber__c');
    }

    @isTest static void test_does_not_overwrite_existing_account() {
        Account accKeep = makeAccount('Keep AC', 'ACC-KEEP');
        Account accOther = makeAccount('Other AC', 'ACC-OTHER');

        Invoice__c inv = baseInvoice();
        inv.Account__c           = accKeep.Id; // already populated
        inv.CustomerNumber__c    = 'ACC-OTHER'; // should be ignored because Account__c not null
        inv.SAPContractNumber__c = null;
        inv.SAPUnitNumber__c     = null;
        insert inv;

        Test.startTest();
        InvoiceTriggerHelper.upsertLookupsForNewInvoices(new List<Invoice__c>{ inv });
        Test.stopTest();

        inv = [SELECT Id, Account__c FROM Invoice__c WHERE Id = :inv.Id];
        System.assertEquals(accKeep.Id, inv.Account__c, 'Existing Account__c must not be overwritten');
    }

    @isTest static void test_bulk_mixed_updates() {
        Account acc1 = makeAccount('Bulk AC1', 'ACC-B1');

        // 1) Should update (valid customer number)
        Invoice__c i1 = baseInvoice();
        i1.CustomerNumber__c = 'ACC-B1';
        // 2) No keys → unchanged
        Invoice__c i2 = baseInvoice();
        // 3) Non-matching customer number → unchanged
        Invoice__c i3 = baseInvoice();
        i3.CustomerNumber__c = 'ACC-NOPE';
        insert new List<Invoice__c>{ i1, i2, i3 };

        Test.startTest();
        InvoiceTriggerHelper.upsertLookupsForNewInvoices(new List<Invoice__c>{ i1, i2, i3 });
        Test.stopTest();

        Map<Id, Invoice__c> out = new Map<Id, Invoice__c>([
            SELECT Id, Account__c FROM Invoice__c WHERE Id IN :new List<Id>{ i1.Id, i2.Id, i3.Id }
        ]);
        System.assertEquals(acc1.Id, out.get(i1.Id).Account__c, 'i1 should be updated');
        System.assertEquals(null, out.get(i2.Id).Account__c,     'i2 should remain null');
        System.assertEquals(null, out.get(i3.Id).Account__c,     'i3 should remain null');
    }

    @isTest static void test_noop_on_null_or_empty_input() {
        // Should not throw
        Test.startTest();
        InvoiceTriggerHelper.upsertLookupsForNewInvoices(null);
        InvoiceTriggerHelper.upsertLookupsForNewInvoices(new List<Invoice__c>());
        Test.stopTest();
        System.assert(true, 'No exception expected for null/empty input');
    }
}