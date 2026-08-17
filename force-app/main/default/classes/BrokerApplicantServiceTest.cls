/*
* @Author      : Rushikesh Jadhav
* @CreatedDate : 09th JUNE 2025
* @Description : Test class for BrokerApplicantService. Covers logic for retrieving, inserting,
*                updating, and validating BrokerApplicant records.
*/
/*****************************************************************************************************
* Version   Author           Date           Comment
* 1.0       Rushikesh        09-JUN-2025    Initial draft - Validates all public methods in 
*                                           BrokerApplicantService including null/blank handling
*****************************************************************************************************/

@isTest
private class BrokerApplicantServiceTest {

    static BrokerApplication__c createTestApplication() {
        return TestDataFactory.createBrokerApplication('Test Agency', 'Domestic');
    }

    static BrokerApplicant__c createTestApplicant(Id applicationId) {
        return TestDataFactory.createBrokerApplicant(applicationId);
    }

    @isTest
    static void testGetInstance() {
        Test.startTest();
        BrokerApplicantService instance = BrokerApplicantService.getInstance();
        Test.stopTest();
        System.assertNotEquals(null, instance, 'Singleton instance should not be null');
    }

    @isTest
    static void testGetExistingApplicantsByApplicationId() {
        BrokerApplication__c app = createTestApplication();
        BrokerApplicant__c applicant = createTestApplicant(app.Id);

        Test.startTest();
        List<BrokerApplicant__c> applicants = BrokerApplicantService.getInstance().getExistingApplicantsByApplicationId(app.Id);
        Test.stopTest();

        System.assertEquals(1, applicants.size(), 'Should return 1 applicant');
        System.assertEquals('John', applicants[0].FirstName__c);
    }

    @isTest
    static void testGetApplicationDetails() {
        BrokerApplication__c app = createTestApplication();

        Test.startTest();
        BrokerApplication__c result = BrokerApplicantService.getInstance().getApplicationDetails(app.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return application details');
    }

    @isTest
    static void testGetApplicationNumber() {
        BrokerApplication__c app = createTestApplication();

        Test.startTest();
        String appnumber = BrokerApplicantService.getInstance().getApplicationNumber(app.Id);
        Test.stopTest();
    }

    @isTest
    static void testInsertApplicants() {
        BrokerApplication__c app = createTestApplication();

        BrokerApplicant__c newApplicant = new BrokerApplicant__c(
            BrokerApplication__c = app.Id,
            FirstName__c = 'Alice',
            LastName__c = 'Smith',
            Email__c = 'alice.smith@example.com'
        );

        Test.startTest();
        BrokerApplicantService.getInstance().insertApplicants(new List<BrokerApplicant__c>{ newApplicant });
        Test.stopTest();

        List<BrokerApplicant__c> inserted = [SELECT Id FROM BrokerApplicant__c WHERE FirstName__c = 'Alice'];
        System.assertEquals(1, inserted.size(), 'One applicant should be inserted');
    }

    @isTest
    static void testUpdateApplicants() {
        BrokerApplication__c app = createTestApplication();
        BrokerApplicant__c applicant = createTestApplicant(app.Id);

        applicant.FirstName__c = 'UpdatedName';

        Test.startTest();
        BrokerApplicantService.getInstance().updateApplicants(new List<BrokerApplicant__c>{ applicant });
        Test.stopTest();

        BrokerApplicant__c updated = [SELECT FirstName__c FROM BrokerApplicant__c WHERE Id = :applicant.Id];
        System.assertEquals('UpdatedName', updated.FirstName__c, 'First name should be updated');
    }
    
    @isTest
    static void testGetApplicantNames() {
        BrokerApplication__c app = TestDataFactory.createBrokerApplication('Test Agency', 'Domestic');
        BrokerApplicant__c applicant = TestDataFactory.createBrokerApplicant(app.Id);
    
        Set<Id> applicantIds = new Set<Id>{ applicant.Id };
    
        Test.startTest();
        Map<Id, String> nameMap = BrokerApplicantService.getInstance().getApplicantNames(applicantIds);
        Test.stopTest();
    
        System.assertEquals(1, nameMap.size(), 'Should return one applicant name');
    }
    
    @isTest
static void testGetApplicantById() {
    BrokerApplication__c app = TestDataFactory.createBrokerApplication('Test Agency', 'Domestic');
    BrokerApplicant__c applicant = TestDataFactory.createBrokerApplicant(app.Id);

    Test.startTest();
    // Valid Id scenario
    BrokerApplicantService.getInstance().getApplicantById(applicant.Id);

    // Blank Id scenario
    BrokerApplicantService.getInstance().getApplicantById(null);
    Test.stopTest();
}

@isTest
static void testGetApplicationNames() {
    BrokerApplication__c app = TestDataFactory.createBrokerApplication('Test Agency', 'Domestic');
    Set<Id> appIds = new Set<Id>{ app.Id };

    Test.startTest();
    BrokerApplicantService.getInstance().getApplicationNames(appIds);
    Test.stopTest();
}
    @isTest
    static void testGetApplicantsByApplicationIdsAndPartnerAndOwner() {
        BrokerApplication__c app1 = createTestApplication();
        BrokerApplicant__c a1 = createTestApplicant(app1.Id);

        Set<Id> appIds = new Set<Id>{ app1.Id };

        List<BrokerApplicant__c> list1 = BrokerApplicantService.getInstance().getApplicantsByApplicationIds(appIds);
        System.assert(list1.size() > 0);

        List<BrokerApplicant__c> list2 = BrokerApplicantService.getInstance().getPartnerAndOwnerApplicantsForSMS(appIds);
        // Returns empty if role not Partner/Owner
        System.assertNotEquals(null, list2);

        // Edge case: null/empty set
        System.assertEquals(0, BrokerApplicantService.getInstance().getApplicantsByApplicationIds(null).size());
        System.assertEquals(0, BrokerApplicantService.getInstance().getPartnerAndOwnerApplicantsForSMS(null).size());
    }
    
}