@IsTest
public class CaseAsyncTriggerHelperTest {

    @testSetup
    static void setupData() {

        Account acc1 = TestDataFactory.createBrokerAccount(
        'Test Account 1',
        false,
        '1122334455'
    );
    insert acc1;

    Account acc2 = TestDataFactory.createBrokerAccount(
        'Test Account 2',
        false,
        '2233445566'
    );
    insert acc2;

        Id generalEnquiryRTId = Utility.getRecordTypeIdByDevName(
            Case.SObjectType,
            'GeneralEnquiry'
        );

        Case case1 = new Case(
            Subject = 'Customer Type Update',
            Status = 'New',
            RecordTypeId = generalEnquiryRTId,
            SubType__c = 'Customer Type Update',
            AccountId = acc1.Id,
            Customer_Type__c = 'Resident',
            Customer_Sub_Type__c = 'Suqur Al Watan',
            NameofCorporate__c = 'Ministry of Interior'
        );

        Case case2 = new Case(
            Subject = 'Customer Type Update 2',
            Status = 'New',
            RecordTypeId = generalEnquiryRTId,
            SubType__c = 'Customer Type Update',
            AccountId = acc2.Id,
            Customer_Type__c = 'GCC',
            Customer_Sub_Type__c = 'CORPORATE',
            NameofCorporate__c = 'ADNOC'
        );

        CaseService.getInstance().insertCaseWithoutTrigger(
            new List<Case>{ case1, case2 }
        );
    }

@IsTest
static void testProcessApprovedCustomerTypeUpdateCases() {

    Case testCase = [
        SELECT Id,
               AccountId,
               Status,
               Customer_Type__c,
               Customer_Sub_Type__c,
               NameofCorporate__c
        FROM Case
        WHERE Subject = 'Customer Type Update'
        LIMIT 1
    ];

    Test.startTest();

    CaseAsyncTriggerHelper.processApprovedCustomerTypeUpdateCases(
        new Set<Id>{ testCase.Id }
    );

    Test.stopTest();

    Case updatedCase = [
        SELECT Status
        FROM Case
        WHERE Id = :testCase.Id
    ];

    System.assertEquals(
        'Closed',
        updatedCase.Status,
        'Case should be closed after processing.'
    );

    Account acc = [
        SELECT Id,
               CustomerType__c,
               CustomerSubType__c,
               CorporateWealthName__c
        FROM Account
        WHERE Id = :testCase.AccountId
    ];

    System.assertEquals(
        'Resident',
        acc.CustomerType__c,
        'Customer Type should be updated on Account.'
    );

    System.assertEquals(
        'Suqur Al Watan',
        acc.CustomerSubType__c,
        'Customer Sub Type should be updated on Account.'
    );

    System.assertEquals(
        'Ministry of Interior',
        acc.CorporateWealthName__c,
        'Corporate Name should be updated on Account.'
    );
}

    @IsTest
    static void testProcessApprovedCustomerTypeUpdateCases_NoAccount() {

        Id generalEnquiryRTId = Utility.getRecordTypeIdByDevName(
            Case.SObjectType,
            'GeneralEnquiry'
        );

        Case cs = new Case(
            Subject = 'No Account Case',
            Status = 'New',
            RecordTypeId = generalEnquiryRTId,
            SubType__c = 'Customer Type Update',
            Customer_Type__c = 'Resident',
            Customer_Sub_Type__c = 'CORPORATE'
        );

        CaseService.getInstance().insertCaseWithoutTrigger(
            new List<Case>{ cs }
        );

        Test.startTest();

        CaseAsyncTriggerHelper.processApprovedCustomerTypeUpdateCases(
            new Set<Id>{ cs.Id }
        );

        Test.stopTest();

        cs = [
            SELECT Status
            FROM Case
            WHERE Id = :cs.Id
        ];

        System.assertEquals(
            'Closed',
            cs.Status
        );
    }

    @IsTest
    static void testProcessApprovedCustomerTypeUpdateCases_EmptySet() {

        Test.startTest();

        CaseAsyncTriggerHelper.processApprovedCustomerTypeUpdateCases(
            new Set<Id>()
        );

        Test.stopTest();

        System.assert(true);
    }
}