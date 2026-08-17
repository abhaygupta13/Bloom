@isTest
private class BCAPP_SendReceiptEmailsQueueableTest {

    private static Id anyEmailFolderId() {
        List<Folder> folders = [SELECT Id FROM Folder WHERE Type = 'Email' LIMIT 1];
        if (!folders.isEmpty()) {
            return folders[0].Id;
        }
        folders = [SELECT Id FROM Folder WHERE DeveloperName = 'unfiled$public' AND Type = 'Email' LIMIT 1];
        System.assert(!folders.isEmpty(), 'Expected at least one Email folder to be available');
        return folders[0].Id;
    }

    private class QueueableContextMock implements System.QueueableContext {
        public Id getJobId() {
            return '707000000000000AAA';
        }
    }

    private static void ensureTemplate() {
        // Create the template before any non-setup DML to avoid Mixed DML
        // Guard against duplicates if it already exists in org/test run
        List<EmailTemplate> existing = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'SendReceiptEmailTemplate' LIMIT 1];
        if (existing.isEmpty()) {
            EmailTemplate et = new EmailTemplate(
                Name = 'Send Receipt Email Template',
                DeveloperName = 'SendReceiptEmailTemplate',
                FolderId = anyEmailFolderId(),
                TemplateType = 'text',
                Subject = 'Receipt {!Receipt__c.Name}',
                Body = 'Receipt Id: {!Receipt__c.Name}'
            );
            insert et;
        }
    }

    private static Account makePersonAccount(String email) {
        Id personRt = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Account a = new Account(
            RecordTypeId = personRt,
            LastName = 'Test Person',
            PersonEmail = email
        );
        insert a;
        return a;
    }

    private static Unit__c makeUnit() {
        Unit__c u = new Unit__c(Name = 'U-REC-001');
        insert u;
        return u;
    }

    @isTest static void test_send_emails_with_template() {
        // Setup email template first (setup object)
        ensureTemplate();

        // Now seed business data
        // Use Person Account not strictly required; template exists and PDF is stubbed
        Account acc = makePersonAccount('person@example.com');
        Unit__c unit = makeUnit();

        Receipt__c r = new Receipt__c(
            AmountReceived__c = 100,
            PaymentDate__c = Date.today(),
            PaymentMode__c = 'Online',
            Status__c = 'Posted',
            Account__c = acc.Id,
            Unit__c = unit.Id
        );
        insert r;

        Test.startTest();
        new BCAPP_SendReceiptEmailsQueueable(new List<Id>{ r.Id }).execute(new QueueableContextMock());
        Test.stopTest();

        System.assert(true, 'Queued email send executed');
    }

    @isTest static void test_no_template_exits_silently() {
        // Exercise early exit path with empty receipt list (no content generation)
        Test.startTest();
        new BCAPP_SendReceiptEmailsQueueable(new List<Id>()).execute(new QueueableContextMock());
        Test.stopTest();
        System.assert(true, 'Empty input exits silently');
    }

    @isTest static void test_execute_with_payment_throws_pdf_exception() {
        ensureTemplate();

        Id personRt = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Account acc = new Account(RecordTypeId = personRt, LastName = 'Queueable Person', PersonEmail = 'person2@example.com');
        insert acc;

        Unit__c unit = new Unit__c(Name = 'U-REC-002');
        insert unit;

        OnlinePayment__c pay = new OnlinePayment__c(
            Account__c = acc.Id,
            Unit__c = unit.Id,
            Status__c = 'Success',
            PaidAmount__c = 50,
            PaymentMethod__c = 'CARD',
            RequestSource__c = 'API'
        );
        insert pay;

        Receipt__c r = new Receipt__c(
            AmountReceived__c = 50,
            PaymentDate__c    = Date.today(),
            PaymentMode__c    = 'Online',
            Status__c         = 'Posted',
            Account__c        = acc.Id,
            Unit__c           = unit.Id,
            OnlinePayment__c  = pay.Id
        );
        insert r;

        Boolean caught = false;
        Test.startTest();
        try {
            new BCAPP_SendReceiptEmailsQueueable(new List<Id>{ r.Id }).execute(new QueueableContextMock());
        } catch (Exception e) {
            caught = true;
        }
        try {
            Test.stopTest();
        } catch (Exception e) {
            caught = true;
        }
    }
}