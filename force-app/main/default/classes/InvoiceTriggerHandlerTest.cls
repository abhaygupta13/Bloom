@isTest
private class InvoiceTriggerHandlerTest {

    private static Account makeAccount(String name, String acctNumber) {
        Account a = BCAPP_TestDataFactory.createAccount(name);
        a.SAP_BP_No__c = acctNumber;
        insert a;
        return a;
    }

    private static Unit__c makeUnit(String name, String sapUnitNumber) {
        Unit__c u = new Unit__c(
            Name = name,
            CommunitySAPUnitNumber__c = sapUnitNumber
        );
        insert u;
        return u;
    }

    private static Invoice__c makeBareInvoice(String custNo, String sapContractNo, String sapUnitNo) {
        String yearStr = String.valueOf(Date.today().year());
        Invoice__c inv = new Invoice__c(
            // Keys for trigger helper
            CustomerNumber__c    = custNo,
            SAPContractNumber__c = sapContractNo,
            SAPUnitNumber__c     = sapUnitNo,
            // Required business fields
            Status__c         = 'Unpaid',
            DocumentType__c   = 'DR',
            CompanyCode__c    = '1000',
            PostingDate__c    = Date.today(),
            InvoiceDate__c    = Date.today(),
            InvoiceYear__c    = yearStr,
            SAPInvoiceNumber__c = 'TRG-' + String.valueOf(Math.abs(Crypto.getRandomInteger())),
            TotalAmount__c    = 100,
            DueAmount__c      = 100
        );
        return inv;
    }

    @isTest static void test_populates_account_on_insert() {
        Account acc = makeAccount('InvTrig AC', 'ACC-T-001');
        // Unit mapping cannot be verified here due to non-writable SAP fields on Unit__c
        Invoice__c inv = makeBareInvoice('ACC-T-001', 'UNIT-001', 'UNIT-001');

        Test.startTest();
        insert inv; // after insert handler should populate Account__c
        Test.stopTest();

        inv = [SELECT Id, Account__c, Unit__c FROM Invoice__c WHERE Id = :inv.Id];
        System.assertEquals(acc.Id, inv.Account__c, 'Account__c should be populated by trigger');
        System.assertEquals(null, inv.Unit__c,   'Unit__c remains null without writable SAP fields');
    }

    @isTest static void test_no_lookup_when_keys_missing() {
        Invoice__c inv = makeBareInvoice(null, null, null);
        Test.startTest();
        insert inv;
        Test.stopTest();
        inv = [SELECT Id, Account__c, Unit__c FROM Invoice__c WHERE Id = :inv.Id];
        System.assertEquals(null, inv.Account__c);
        System.assertEquals(null, inv.Unit__c);
    }

    @isTest static void test_only_account_lookup() {
        Account acc = makeAccount('InvTrig AC2', 'ACC-T-002');
        Invoice__c inv = makeBareInvoice('ACC-T-002', null, null);
        Test.startTest();
        insert inv;
        Test.stopTest();
        inv = [SELECT Id, Account__c, Unit__c FROM Invoice__c WHERE Id = :inv.Id];
        System.assertEquals(acc.Id, inv.Account__c);
        System.assertEquals(null, inv.Unit__c);
    }

    @isTest static void test_preserves_pre_set_unit_lookup() {
        // If Unit__c is already set on insert, helper should not overwrite
        Unit__c unit = makeUnit('U-TRG-KEEP', 'KEEP-001');
        Invoice__c inv = makeBareInvoice('ACC-T-003', 'ANY', 'ANY');
        inv.Unit__c = unit.Id; // pre-populate
        Test.startTest();
        insert inv;
        Test.stopTest();
        inv = [SELECT Id, Unit__c FROM Invoice__c WHERE Id = :inv.Id];
        System.assertEquals(unit.Id, inv.Unit__c);
    }

    @isTest static void test_populates_unit_lookup_when_available() {
        Account acc = makeAccount('InvTrig AC3', 'ACC-T-004');
        Unit__c unit = makeUnit('U-TRG-MAP', 'UNIT-MAP-001');
        Invoice__c inv = makeBareInvoice('ACC-T-004', 'UNIT-MAP-001', 'UNIT-MAP-001');

        Test.startTest();
        insert inv;
        Test.stopTest();

        inv = [SELECT Id, Account__c, Unit__c FROM Invoice__c WHERE Id = :inv.Id];
        System.assertEquals(acc.Id, inv.Account__c);
        System.assertEquals(unit.Id, inv.Unit__c);
    }

    @isTest static void test_handler_interface_hooks_are_safe_noops() {
        InvoiceTriggerHandler handler = new InvoiceTriggerHandler();
        List<sObject> emptyList = new List<sObject>();
        Map<Id, sObject> emptyMap = new Map<Id, sObject>();
        Boolean originalFlag = InvoiceTriggerHandler.isTriggerDisabled;

        Test.startTest();
        handler.beforeInsert(emptyList);
        handler.beforeUpdate(emptyList, emptyMap, emptyList, emptyMap);
        handler.beforeDelete(emptyList, emptyMap);
        handler.afterUpdate(emptyList, emptyMap, emptyList, emptyMap);
        handler.afterDelete(emptyList, emptyMap);
        handler.afterUnDelete(emptyList, emptyMap);
        Boolean disabledBefore = handler.isDisabled();
        InvoiceTriggerHandler.isTriggerDisabled = true;
        Boolean disabledAfter = handler.isDisabled();
        Test.stopTest();

        InvoiceTriggerHandler.isTriggerDisabled = originalFlag;
        System.assertEquals(false, disabledBefore, 'Handler should report enabled by default');
        System.assertEquals(true, disabledAfter, 'Handler should reflect static disabled flag');
    }
}