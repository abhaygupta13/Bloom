/*
* @Author      : Rushikesh Jadhav
* @CreatedDate : 9th JUNE 2025
* @Description : Test class for BAPPSubmitBrokerApplicantHandler.
*/
/*****************************************************************************************************
* Version   Author           Date           Comment                                                                       
* 1.0       Rushikesh        09-JUN-2025    Initial draft - Tests screen 4 submission logic for broker applicant handler,
*                                           including valid applicant creation and REST response validation.
*****************************************************************************************************/
@isTest
public class BAPPSubmitBrokerApplicantHandlerTest {

    @testSetup
    static void setupData() {
        // Use TestDataFactory to create a broker application
        TestDataFactory.createBrokerApplication('Test Agency', 'Domestic');
    }

    @isTest
    static void testHandleBrokerApplicant_FullFlow() {
        BrokerApplication__c app = [SELECT Id FROM BrokerApplication__c WHERE Name = 'Test Agency' LIMIT 1];

        Map<String, Object> inputMap = new Map<String, Object>{
            'applicationId' => app.Id,
            'registrationStatus' => 'Submitted',
            'currentScreen' => 'screen 4',
            'isRfiUpdate' => true,
            'typeOfEstablishment' => 'Domestic',
            'companyPersonnel' => new List<Object>{
                new Map<String, Object>{
                    'role' => 'Admin',
                    'title' => 'Mr.',
                    'firstName' => 'Test',
                    'lastName' => 'Handler',
                    'phoneNumber' => '1234567890',
                    'email' => 'handler@example.com',
                    'nationalId' => 'HANDLER123',
                    'nationalIdExpiryDate' => String.valueOf(Date.today().addYears(1)),
                    'dateOfBirth' => String.valueOf(Date.today().addYears(-30)),
                    'passportNumber' => 'P12345',
                    'passportExpiryDate' => String.valueOf(Date.today().addYears(1)),
                    'country' => 'United Arab Emirates',
                    'countryCode' => '971',
                    'shareHoldingPercentage' => 20,
                    'designation' => 'Manager',
                    'typeOfEstablishment' => 'Domestic'
                }
            }
        };

        String requestBody = JSON.serialize(inputMap);

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestBody = Blob.valueOf(requestBody);

        Test.startTest();
        BAPPSubmitBrokerApplicantHandler.handleBrokerApplicant(requestBody);
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode, 'Should return 200 on success');
        System.assert(RestContext.response.responseBody.toString().contains('success'), 'Response should indicate success');
    }

    @isTest
    static void testValidApplicantCreation() {
        BrokerApplication__c app = [SELECT Id FROM BrokerApplication__c WHERE Name = 'Test Agency' LIMIT 1];

        BAPPSubmitBrokerApplicantHandler.ApplicantRequest req = new BAPPSubmitBrokerApplicantHandler.ApplicantRequest();
        req.applicationId = app.Id;
        req.registrationStatus = 'Submitted';
        req.isRfiUpdate = true;
        req.currentScreen = 'screen 4';
        req.typeOfEstablishment = 'domestic';

        BAPPSubmitBrokerApplicantHandler.BrokerApplicantData applicant = new BAPPSubmitBrokerApplicantHandler.BrokerApplicantData();
        applicant.role = 'Admin';
        applicant.title = 'Mr.';
        applicant.firstName = 'Test';
        applicant.lastName = 'User';
        applicant.phoneNumber = '1234567890';
        applicant.email = 'test@example.com';
        applicant.nationalId = 'NID123456';
        applicant.nationalIdExpiryDate = String.valueOf(Date.today().addYears(1));
        applicant.dateOfBirth = String.valueOf(Date.today().addYears(-30));
        applicant.shareHoldingPercentage = 50;
        applicant.country = 'United Arab Emirates';
        applicant.countryCode = '971';

        req.companyPersonnel = new List<BAPPSubmitBrokerApplicantHandler.BrokerApplicantData>{ applicant };

        Test.startTest();
        Map<String, Object> result = BAPPSubmitBrokerApplicantHandler.createOrUpdateApplicants(req);
        Test.stopTest();

        System.assertEquals('success', result.get('status'), 'Expected successful status');
        System.assertNotEquals(null, result.get('applicationId'), 'Application Id should be present');
    }
    
    @isTest
    static void testMissingRequiredFields() {
        BrokerApplication__c app = [SELECT Id FROM BrokerApplication__c WHERE Name = 'Test Agency' LIMIT 1];

        BAPPSubmitBrokerApplicantHandler.ApplicantRequest req = new BAPPSubmitBrokerApplicantHandler.ApplicantRequest();
        req.applicationId = app.Id;
        req.registrationStatus = 'Draft';
        req.isRfiUpdate = false;

        BAPPSubmitBrokerApplicantHandler.BrokerApplicantData applicant = new BAPPSubmitBrokerApplicantHandler.BrokerApplicantData();
        applicant.role = '';

        req.companyPersonnel = new List<BAPPSubmitBrokerApplicantHandler.BrokerApplicantData>{ applicant };

        Test.startTest();
        Map<String, Object> result = BAPPSubmitBrokerApplicantHandler.createOrUpdateApplicants(req);
        Test.stopTest();

        System.assertEquals('error', result.get('status'), 'Expected error status');
        System.assert(result.containsKey('errors'), 'Should return validation errors');
    }
    
    @isTest
    static void testUpdateExistingApplicant() {
        BrokerApplication__c app = [SELECT Id FROM BrokerApplication__c WHERE Name = 'Test Agency' LIMIT 1];

        // Create applicant using factory
        BrokerApplicant__c existing = TestDataFactory.createBrokerApplicant(app.Id);

        BAPPSubmitBrokerApplicantHandler.ApplicantRequest req = new BAPPSubmitBrokerApplicantHandler.ApplicantRequest();
        req.applicationId = app.Id;
        req.registrationStatus = 'Draft';
        req.isRfiUpdate = true;
        req.currentScreen = 'screen 4';
        req.typeOfEstablishment = 'domestic';

        BAPPSubmitBrokerApplicantHandler.BrokerApplicantData applicant = new BAPPSubmitBrokerApplicantHandler.BrokerApplicantData();
        applicant.applicantId = existing.Id;
        applicant.role = 'Admin';
        applicant.title = 'Mr.';
        applicant.firstName = 'Updated';
        applicant.lastName = 'User';
        applicant.phoneNumber = '9999999999';
        applicant.email = 'updated@example.com';
        applicant.nationalId = 'NEWNID123';
        applicant.nationalIdExpiryDate = String.valueOf(Date.today().addYears(1));
        applicant.dateOfBirth = String.valueOf(Date.today().addYears(-35));
        applicant.country = 'United Arab Emirates';
        applicant.countryCode = '971';
        applicant.shareHoldingPercentage = 15;

        req.companyPersonnel = new List<BAPPSubmitBrokerApplicantHandler.BrokerApplicantData>{ applicant };

        Test.startTest();
        Map<String, Object> result = BAPPSubmitBrokerApplicantHandler.createOrUpdateApplicants(req);
        Test.stopTest();

        System.assertEquals('success', result.get('status'), 'Update existing applicant should succeed');
    }
    @isTest
    static void testInternationalApplicantCreation() {
        BrokerApplication__c app = [SELECT Id FROM BrokerApplication__c LIMIT 1];

        BAPPSubmitBrokerApplicantHandler.BrokerApplicantData intlApplicant = new BAPPSubmitBrokerApplicantHandler.BrokerApplicantData();
        intlApplicant.role = 'admin';
        intlApplicant.title = 'Mr.';
        intlApplicant.firstName = 'Global';
        intlApplicant.lastName = 'User';
        intlApplicant.phoneNumber = '+971501234567';
        intlApplicant.email = 'global@example.com';
        intlApplicant.dateOfBirth = String.valueOf(Date.newInstance(1990, 1, 1));
        intlApplicant.passportNumber = 'P987654321';
        intlApplicant.passportExpiryDate = String.valueOf(Date.today().addYears(2));
        intlApplicant.country = 'United Arab Emirates';
        intlApplicant.countryCode = '971';
        intlApplicant.shareHoldingPercentage = 50;
        intlApplicant.typeOfEstablishment = 'international';

        BAPPSubmitBrokerApplicantHandler.ApplicantRequest req = new BAPPSubmitBrokerApplicantHandler.ApplicantRequest();
        req.applicationId = app.Id;
        req.registrationStatus = 'Submitted';
        req.isRfiUpdate = true;
        req.currentScreen = 'screen 4';
        req.typeOfEstablishment = 'international';
        req.companyPersonnel = new List<BAPPSubmitBrokerApplicantHandler.BrokerApplicantData>{ intlApplicant };

        Test.startTest();
        Map<String, Object> result = BAPPSubmitBrokerApplicantHandler.createOrUpdateApplicants(req);
        Test.stopTest();

        System.assertEquals('success', result.get('status'), 'International applicant creation should succeed');
    }
    @isTest
    static void testSuperAdminFlagLogic() {
        BrokerApplication__c app = [SELECT Id FROM BrokerApplication__c WHERE Name = 'Test Agency' LIMIT 1];

        // Use factory to insert existing SuperAdmin
        BrokerApplicant__c superAdmin = TestDataFactory.createBrokerApplicant(app.Id);
        superAdmin.Email__c = 'super@example.com';
        superAdmin.IsSuperAdmin__c = true;
        update superAdmin;

        BAPPSubmitBrokerApplicantHandler.ApplicantRequest req = new BAPPSubmitBrokerApplicantHandler.ApplicantRequest();
        req.applicationId = app.Id;
        req.registrationStatus = 'Draft';
        req.isRfiUpdate = true;
        req.currentScreen = 'screen 4';
        req.typeOfEstablishment = 'domestic';

        BAPPSubmitBrokerApplicantHandler.BrokerApplicantData applicant = new BAPPSubmitBrokerApplicantHandler.BrokerApplicantData();
        applicant.role = 'Admin';
        applicant.title = 'Ms.';
        applicant.firstName = 'NonSuper';
        applicant.lastName = 'Admin';
        applicant.phoneNumber = '7777777777';
        applicant.email = 'nonsuper@example.com';
        applicant.nationalId = 'NID0002';
        applicant.nationalIdExpiryDate = String.valueOf(Date.today().addYears(1));
        applicant.dateOfBirth = String.valueOf(Date.today().addYears(-28));
        applicant.shareHoldingPercentage = 10;
        applicant.country = 'United Arab Emirates';
        applicant.countryCode = '971';

        req.companyPersonnel = new List<BAPPSubmitBrokerApplicantHandler.BrokerApplicantData>{ applicant };

        Test.startTest();
        Map<String, Object> result = BAPPSubmitBrokerApplicantHandler.createOrUpdateApplicants(req);
        Test.stopTest();

        List<BrokerApplicant__c> records = [
            SELECT Id, IsSuperAdmin__c FROM BrokerApplicant__c 
            WHERE Email__c = 'nonsuper@example.com'
        ];
        System.assertEquals(false, records[0].IsSuperAdmin__c, 'Should not be SuperAdmin');
    }
    @isTest
    static void testPartialSuccess() {
        BrokerApplication__c app = [SELECT Id FROM BrokerApplication__c WHERE Name = 'Test Agency' LIMIT 1];

        BAPPSubmitBrokerApplicantHandler.ApplicantRequest req = new BAPPSubmitBrokerApplicantHandler.ApplicantRequest();
        req.applicationId = app.Id;
        req.registrationStatus = 'Draft';
        req.isRfiUpdate = true;
        req.currentScreen = 'screen 4';
        req.typeOfEstablishment = 'domestic';

        BAPPSubmitBrokerApplicantHandler.BrokerApplicantData validApplicant = new BAPPSubmitBrokerApplicantHandler.BrokerApplicantData();
        validApplicant.role = 'Admin';
        validApplicant.title = 'Ms.';
        validApplicant.firstName = 'Valid';
        validApplicant.lastName = 'User';
        validApplicant.phoneNumber = '1231231234';
        validApplicant.email = 'valid@example.com';
        validApplicant.nationalId = 'VALIDNID';
        validApplicant.nationalIdExpiryDate = String.valueOf(Date.today().addYears(1));
        validApplicant.dateOfBirth = String.valueOf(Date.today().addYears(-25));
        validApplicant.shareHoldingPercentage = 20;
        validApplicant.country = 'United Arab Emirates';
        validApplicant.countryCode = '971';

        BAPPSubmitBrokerApplicantHandler.BrokerApplicantData badApplicant = new BAPPSubmitBrokerApplicantHandler.BrokerApplicantData();
        badApplicant.role = '';

        req.companyPersonnel = new List<BAPPSubmitBrokerApplicantHandler.BrokerApplicantData>{ validApplicant, badApplicant };

        Test.startTest();
        Map<String, Object> result = BAPPSubmitBrokerApplicantHandler.createOrUpdateApplicants(req);
        Test.stopTest();

        System.assertEquals('partial_success', result.get('status'), 'Should return partial_success for mixed valid and invalid applicants');
        System.assert(result.containsKey('errors'));
        System.assert(result.containsKey('data'));
    }
    
    @isTest
    static void testMakeServerErrorResponse() {
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        Exception ex;
        try {
            throw new AuraHandledException(
                'Insert failed. First exception on row 0; first error: ' +
                'DUPLICATES_DETECTED, Applicant with same Emirates/National ID already exists.: []'
            );
        } catch (Exception e) {
            ex = e;
        }
        Test.startTest();
        BAPPSubmitBrokerApplicantHandler.makeServerErrorResponse(ex);
        Test.stopTest();
    }
}