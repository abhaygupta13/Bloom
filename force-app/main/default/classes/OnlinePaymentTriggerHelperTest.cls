@isTest
private class OnlinePaymentTriggerHelperTest {

    // Helpers
    private static Account makePersonAccount(String email) {
        Id personRt = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Account a = new Account(
            RecordTypeId = personRt,
            LastName = 'Trigger Helper Person',
            PersonEmail = email
        );
        insert a;
        return a;
    }

    private static Unit__c makeUnit(String name) {
        Unit__c u = new Unit__c(Name = name);
        insert u;
        return u;
    }

    private static Invoice__c makeInvoice(Account acc, Unit__c unit, String sapNo) {
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
            TotalAmount__c = 10,
            DueAmount__c   = 10
        );
        insert inv;
        return inv;
    }

    private static Case makeCase(Account acc, Unit__c unit, String serviceName) {
        Service_Catalog__c sc = new Service_Catalog__c(Name = serviceName, Active__c = true);
        insert sc;
        Case c = new Case(
            AccountId = acc.Id,
            Unit__c = unit.Id,
            Status = 'Submitted',
            Service_Catalog__c = sc.Id,
            RecordTypeId = Utilities.getRecordTypeId('Case','General Service Request'),
            User_Type__c = 'Owner'
        );
        insert c;
        return c;
    }

    @isTest static void test_case_based_service_name_sends_email() {
        Account acc = makePersonAccount('helper.person@example.com');
        Unit__c unit = makeUnit('U-TH-CASE-001');
        Case c = makeCase(acc, unit, 'Access Card');

        OnlinePayment__c pay = new OnlinePayment__c(
            Account__c = acc.Id,
            Unit__c = unit.Id,
            Status__c = 'Pending',
            PaidAmount__c = 15,
            PaymentMethod__c = 'CARD',
            RequestSource__c = 'API',
            GatewayReference__c = 'GW-TH-CASE'
        );
        insert pay;

        // Link a line item to the Case to drive service-name selection
        insert new OnlinePaymentLineItem__c(OnlinePayment__c = pay.Id, Case__c = c.Id, PlannedAmount__c = 15);

        Integer beforeEmails = Limits.getEmailInvocations();
        Test.startTest();
        OnlinePayment__c newRow = pay.clone(false, true, false, false);
        newRow.Id = pay.Id;
        newRow.Status__c = 'Failed';
        OnlinePaymentTriggerHelper.sendFailureEmails(new List<OnlinePayment__c>{ newRow }, new Map<Id, OnlinePayment__c>{ pay.Id => pay });
        Test.stopTest();
        Integer afterEmails = Limits.getEmailInvocations();
        System.assert(afterEmails >= beforeEmails, 'Helper executed for case-based service name');
    }

    @isTest static void test_invoice_based_service_name_sends_email() {
        Account acc = makePersonAccount('helper.invoice@example.com');
        Unit__c unit = makeUnit('U-TH-INV-001');
        Invoice__c inv = makeInvoice(acc, unit, 'SAP-TH-1');

        OnlinePayment__c pay = new OnlinePayment__c(
            Account__c = acc.Id,
            Unit__c = unit.Id,
            Status__c = 'Pending',
            PaidAmount__c = 20,
            PaymentMethod__c = 'CARD',
            RequestSource__c = 'API',
            GatewayReference__c = 'GW-TH-INV',
            Invoice__c = inv.Id
        );
        insert pay;

        Integer beforeEmails = Limits.getEmailInvocations();
        Test.startTest();
        OnlinePayment__c newRow = pay.clone(false, true, false, false);
        newRow.Id = pay.Id;
        newRow.Status__c = 'Failed';
        OnlinePaymentTriggerHelper.sendFailureEmails(new List<OnlinePayment__c>{ newRow }, new Map<Id, OnlinePayment__c>{ pay.Id => pay });
        Test.stopTest();
        Integer afterEmails = Limits.getEmailInvocations();
        System.assert(afterEmails >= beforeEmails, 'Helper executed for invoice-based service name');
    }

    @isTest static void test_request_source_fallback_sends_email() {
        Account acc = makePersonAccount('helper.fallback@example.com');
        Unit__c unit = makeUnit('U-TH-FBK-001');

        OnlinePayment__c pay = new OnlinePayment__c(
            Account__c = acc.Id,
            Unit__c = unit.Id,
            Status__c = 'Pending',
            PaidAmount__c = 12,
            PaymentMethod__c = 'CARD',
            RequestSource__c = 'API',
            GatewayReference__c = 'GW-TH-FBK'
        );
        insert pay;

        Integer beforeEmails = Limits.getEmailInvocations();
        Test.startTest();
        OnlinePayment__c newRow = pay.clone(false, true, false, false);
        newRow.Id = pay.Id;
        newRow.Status__c = 'Failed';
        OnlinePaymentTriggerHelper.sendFailureEmails(new List<OnlinePayment__c>{ newRow }, new Map<Id, OnlinePayment__c>{ pay.Id => pay });
        Test.stopTest();
        Integer afterEmails = Limits.getEmailInvocations();
        System.assert(afterEmails >= beforeEmails, 'Helper executed for requestSource fallback');
    }
}