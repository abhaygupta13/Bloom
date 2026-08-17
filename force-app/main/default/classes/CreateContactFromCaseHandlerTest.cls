@IsTest
private class CreateContactFromCaseHandlerTest {

    // ---------- Helper Method to Get RecordTypeId Safely ----------
    private static Id getRecordTypeId(String objectName, String developerName) {
        Map<String, Schema.RecordTypeInfo> rtMap =
            Schema.getGlobalDescribe()
                .get(objectName)
                .getDescribe()
                .getRecordTypeInfosByDeveloperName();

        if (rtMap.containsKey(developerName)) {
            return rtMap.get(developerName).getRecordTypeId();
        }
        // fallback
        return Schema.getGlobalDescribe().get(objectName).getDescribe().getRecordTypeInfos()[0].getRecordTypeId();
    }

    // ---------- Helper Method to Create Test Data ----------
    private static Case createTestCase() {
        // Create Account first
        Id accRTId = getRecordTypeId('Account', 'Broker_Agency');
        Account acc = new Account(
            Name = 'Test Broker Agency',
            RecordTypeId = accRTId
        );
        insert acc;

        // Create Case record (Broker_Registration)
        Id caseRTId = getRecordTypeId('Case', 'Broker_Registration');
        Case c = new Case(
            RecordTypeId = caseRTId,
            AccountId = acc.Id,
            Subject = 'Create Contact Flow Test',
            BrokerContactRole__c = 'Admin',
            Title__c = 'Mr.',
            First_Name__c = 'John',
            MiddleName__c = 'A',
            Last_Name__c = 'Doe',
            PhoneNumber__c = '9876543210',
            Email_Address__c = 'john.doe@test.com',
            NationalID__c = 'NID12345',
            NationalIDExpiryDate__c = System.today().addYears(2),
            PassportNumber__c = 'PASS12345',
            PassportExpiryDate__c = System.today().addYears(5),
            DateOfBirth__c = Date.newInstance(1990, 5, 15),
            Country__c = 'India',
            TypeofEstablishment__c = 'Domestic',
            BRN_RERA_Number__c = 'BRN001',
            BRN_RERA_Expiry_Date__c = System.today().addYears(1),
            ShareHoldingPercentage__c = 50,
            Designation__c = 'Manager',
            Mobile_Country_Code__c = '91'
        );
        insert c;

        return c;
    }

    // ---------- TEST METHOD ----------
    @IsTest
    static void testCreateContacts_Success() {
        // Step 1: Create Case
        Case testCase = createTestCase();

        // Step 2: Prepare request wrapper
        CreateContactFromCaseHandler.Request req = new CreateContactFromCaseHandler.Request();
        req.caseId = testCase.Id;

        // Step 3: Execute Invocable Method
        Test.startTest();
        List<CreateContactFromCaseHandler.Response> results =
            CreateContactFromCaseHandler.createContacts(new List<CreateContactFromCaseHandler.Request>{ req });
        Test.stopTest();

        // Step 4: Assertions
        System.assertEquals(1, results.size(), 'One contact should be created');
        Id contactId = results[0].contactId;
        System.assertNotEquals(null, contactId, 'Contact Id should not be null');

        // Step 5: Validate contact details
        Contact createdContact = [
            SELECT Id, FirstName, LastName, Email, AccountId, CaseId__c, IsActive__c,
                   BrokerContactRole__c, PassportNumber__c, Emirates_Id__c
            FROM Contact
            WHERE Id = :contactId
            LIMIT 1
        ];

        System.assertEquals('John', createdContact.FirstName, 'First name should match');
        System.assertEquals('Doe', createdContact.LastName, 'Last name should match');
        System.assertEquals('john.doe@test.com', createdContact.Email, 'Email should match');
        System.assertEquals(testCase.AccountId, createdContact.AccountId, 'Account should be linked');
        System.assertEquals(testCase.Id, createdContact.CaseId__c, 'Case should be linked');
        System.assertEquals(true, createdContact.IsActive__c, 'Contact should be active');
    }

    // ---------- TEST: Empty or Invalid Case ----------
    @IsTest
    static void testCreateContacts_InvalidCaseId() {
        // Create an invalid request (case not in DB)
        CreateContactFromCaseHandler.Request req = new CreateContactFromCaseHandler.Request();
        req.caseId = '500000000000000AAA'; // Fake Id

        Test.startTest();
        List<CreateContactFromCaseHandler.Response> results =
            CreateContactFromCaseHandler.createContacts(new List<CreateContactFromCaseHandler.Request>{ req });
        Test.stopTest();

        // Since no Case found, no contact should be created
        System.assertEquals(0, [SELECT COUNT() FROM Contact], 'No contacts should be created for invalid case');
        System.assertEquals(0, results.size(), 'No response should be returned for invalid case');
    }
}