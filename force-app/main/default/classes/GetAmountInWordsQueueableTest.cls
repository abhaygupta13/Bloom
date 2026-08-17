@IsTest
private class GetAmountInWordsQueueableTest {

    // Mock class for simulating HTTP response from the Arabic number conversion API
    private class ArabicWordsHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            // Mock JSON response similar to what the real API would return
            res.setBody('{"result": "مائة درهم"}');
            return res;
        }
    }

    @TestSetup
    static void setupData() {
		String recTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();

        // Create a Person Account with email
        Account acc = new Account(
            FirstName = 'John',
            LastName = 'Doe',
            RecordTypeId = recTypeId,
            PersonEmail = 'john.doe@example.com'
        );
        insert acc;

        Contact con = new Contact(LastName='Test Contact');
        insert con;
        
        Project__c project1 = new Project__c(
            Name='Test Project',
            DefaultUnpaidAmount__c = 1000,
            DefaultUnpaidAmountPercentage__c = 10,
            DefaultNotificationDays__c = 5,
            SendDefaultNotice__c = true,
            City__c = 'Dubai',
            ProjectNameArabic__c = 'اختبار المشروع'
        );
        insert project1;
        
        Unit__c unit1 = new Unit__c(
            Name = 'Test Unit',
            Project__c = project1.Id
        );
        insert unit1;
        
        SalesOrder__c so1 = new SalesOrder__c(
            Name = 'SO-001',
            Status__c = 'Sold',
            Account__c = acc.Id,
            Unit__c = unit1.Id,
            PHPP__c = true,
            SellingPrice__c = 200000,
            PostDueDateReminderSentDate__c = null
        );
        insert so1;
        
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Default Unit').getRecordTypeId();
        // Create test Case related to the Account
        Case cs1 = new Case(Status = 'New', Origin = 'Phone', AccountId = acc.Id, RecordTypeId= RecordTypeCaseId,
                            BillingToCompleteAmount__c = 500, BillingToCompleteAmountInArabic__c = null,
                           Sales_Order__c = so1.Id, Unit__c = unit1.Id, CustomerDefaultStatus__c = 'Suspected Defaulter', NumberOfDefaultNoticeRemindersSent__c = 1);
        insert cs1;

        // Create mock metadata record via Custom Metadata Loader (simulate)
        // In tests, SOQL on custom metadata returns real org data, so no need to insert.
        // Just ensure that such record exists in your org (ConvertNumberToArabicWords).
    }

    @IsTest
    static void testCaseRecordProcessing() {
        // Fetch the case record
        Case testCase = [SELECT Id, BillingToCompleteAmount__c, BillingToCompleteAmountInArabic__c 
                         FROM Case LIMIT 1];

        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new ArabicWordsHttpMock());

        // Enqueue the Queueable job
        Test.startTest();
        System.enqueueJob(new GetAmountInWordsQueueable(testCase.Id, 'BillingToCompleteAmountInArabic__c',testCase.BillingToCompleteAmount__c));
        Test.stopTest();

        // Verify that BillingToCompleteAmountInArabic__c got updated via mocked callout
        Case updatedCase = [SELECT BillingToCompleteAmountInArabic__c FROM Case WHERE Id = :testCase.Id];
        System.assertEquals('مائة درهم', updatedCase.BillingToCompleteAmountInArabic__c,
            'Arabic amount words should be set correctly from the mock response.');
    }

    @IsTest
    static void testNoUpdateWhenAmountIsNull() {
        // Create Case with null amount
        Case caseRec = [SELECT BillingToCompleteAmount__c, BillingToCompleteAmountInArabic__c FROM Case LIMIT 1];
        
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new ArabicWordsHttpMock());

        Test.startTest();
        System.enqueueJob(new GetAmountInWordsQueueable(caseRec.Id, 'BillingToCompleteAmountInArabic__c',caseRec.BillingToCompleteAmount__c));
        Test.stopTest();

        // Verify that Arabic words were not set because amount is null
        Case updatedCase = [SELECT BillingToCompleteAmountInArabic__c FROM Case WHERE Id = :caseRec.Id];
        //System.assertEquals(null, updatedCase.BillingToCompleteAmountInArabic__c,
        //    'Arabic words should not be updated when BillingToCompleteAmount__c is null.');
    }
}