/*
* @Author      : Rushikesh Jadhav
* @CreatedDate : 09th JUNE 2025
* @Description : Test class for BAPPWebService Apex REST controller that handles broker application and applicant submission,
*                as well as tracking application status.
*/
/*****************************************************************************************************
* Version   Author           Date           Comment
* 1.0       Rushikesh        09-JUN-2025    Initial draft - Tests for submitBrokerApplication, submitBrokerApplicant,
*                                           trackMyApplication, and unsupported endpoint logic
*****************************************************************************************************/
@isTest
private class BAPPWebServiceTest {

    @testSetup
    static void setupTestData() {
        // Create a Broker Application
       TestDataFactory.createBrokerApplication('Test Agency', 'Domestic');
    }

    @isTest
    static void testDoPost_SubmitBrokerApplicant() {
        BrokerApplication__c app = [SELECT Id FROM BrokerApplication__c LIMIT 1];

        Map<String, Object> body = new Map<String, Object>{
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
                    'lastName' => 'User',
                    'phoneNumber' => '1234567890',
                    'email' => 'test.user@example.com',
                    'nationalId' => 'NID987654',
                    'nationalIdExpiryDate' => String.valueOf(Date.today().addYears(1)),
                    'dateOfBirth' => Date.today().addYears(-30),
                    'passportNumber' => 'P123456',
                    'passportExpiryDate' => String.valueOf(Date.today().addYears(1)),
                    'shareHoldingPercentage' => 40,
                    'country' => 'United Arab Emirates',
      				'countryCode' => '971',
                    'designation' => 'Manager',
                    'typeOfEstablishment' => 'Domestic'
                }
            }
        };

        String jsonBody = JSON.serialize(body);

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri = '/services/apexrest/brokerAppWebService/V1/submitBrokerApplicant';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(jsonBody);

        Test.startTest();
        BAPPWebService.doPost();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('success'));
    }
    @isTest
    static void testDoPost_SubmitBrokerApplication() {
        // Fetch test BrokerApplication created in testSetup
        BrokerApplication__c app = [SELECT Id FROM BrokerApplication__c LIMIT 1];
    
        // Build valid request body
        Map<String, Object> payload = new Map<String, Object>{
            'applicationId' => app.Id,
            'currentScreen' => 'screen 4',
            'registrationStatus' => 'Draft',
            'isRfiUpdate' => false,
            'typeOfEstablishment' => 'Domestic'
        };
    
        // Prepare REST context
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/brokerAppWebService/V1/submitBrokerApplication';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        RestContext.request = req;
    
        RestResponse res = new RestResponse();
        RestContext.response = res;
    
        Test.startTest();
        BAPPWebService.doPost();
        Test.stopTest();
    
        System.assertEquals(200, RestContext.response.statusCode, 'Expected 200 OK for valid input');
    }

    @isTest
    static void testDoGet_TrackMyApplication() {
        // Application must exist with a known ApplicationNumber
        BrokerApplication__c app = [SELECT ApplicationNumber__c FROM BrokerApplication__c LIMIT 1];
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri = '/services/apexrest/brokerAppWebService/V1/trackMyApplication';
        RestContext.request.httpMethod = 'GET';
        RestContext.request.params.put('applicationNumber', app.ApplicationNumber__c.replace('BA-', ''));

        Test.startTest();
        BAPPWebService.doGet();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testDoPost_UnsupportedEndpoint() {
        // Simulate unsupported endpoint
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri = '/services/apexrest/brokerAppWebService/V1/unknownEndpoint';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf('{}');

        Test.startTest();
        BAPPWebService.doPost();  
        Test.stopTest();

        // No assert needed — just ensuring it doesn’t crash
    }
    
    // === Helper: Common POST Setup ===
    private static void setupPostContext(String endpoint, Object bodyObj) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/brokerAppWebService/V1' + endpoint;
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        if (bodyObj != null) {
            req.requestBody = Blob.valueOf(JSON.serialize(bodyObj));
        }
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    // === Helper: Common GET Setup ===
    private static void setupGetContext(String endpoint, Map<String, String> params) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/brokerAppWebService/V1' + endpoint;
        req.httpMethod = 'GET';
        if (params != null) {
            for (String key : params.keySet()) {
                req.addParameter(key, params.get(key));
            }
        }
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    // === POST Endpoints ===

    @isTest
    static void testDoPost_SubmitBrokerCaseApplicant() {
        setupPostContext('/submitBrokerCaseApplicant', new Map<String, Object>{ 'key' => 'value' });
        Test.startTest();
        BAPPWebService.doPost();
        Test.stopTest();
    }

    @isTest
    static void testDoPost_GetApplicantProfile() {
        setupPostContext('/getApplicantProfile', new Map<String, Object>{ 'contactId' => '003XXXXXXXXXXXX' });
        Test.startTest();
        BAPPWebService.doPost();
        Test.stopTest();
    }

    @isTest
    static void testDoPost_SubmitLead() {
        setupPostContext('/submitLead', new Map<String, Object>{ 'leadName' => 'Test Lead' });
        Test.startTest();
        BAPPWebService.doPost();
        Test.stopTest();
    }

    @isTest
    static void testDoPost_FilterLeads() {
        setupPostContext('/filterLeads', null);
        Test.startTest();
        BAPPWebService.doPost();
        Test.stopTest();
    }

    @isTest
    static void testDoPost_SubmitCaseServiceRequest() {
        setupPostContext('/submitCaseServiceRequest', null);
        Test.startTest();
        BAPPWebService.doPost();
        Test.stopTest();
    }

    @isTest
    static void testDoPost_GetUnitListing() {
        setupPostContext('/getUnitListing', new Map<String, Object>{ 'accountId' => '001XXXXXXXXXXXX' });
        Test.startTest();
        BAPPWebService.doPost();
        Test.stopTest();
    }

    @isTest
    static void testDoPost_SubmitContactCase() {
        setupPostContext('/submitContactCase', new Map<String, Object>{ 'contactId' => '003XXXXXXXXXXXX' });
        Test.startTest();
        BAPPWebService.doPost();
        Test.stopTest();
    }

    @isTest
    static void testDoPost_SubmitAgencyCase() {
        setupPostContext('/submitAgencyCase', new Map<String, Object>{ 'agencyId' => '001XXXXXXXXXXXX' });
        Test.startTest();
        BAPPWebService.doPost();
        Test.stopTest();
    }


    // === GET Endpoints ===

    @isTest
    static void testDoGet_TrackMyApplication_Valid() {
        BrokerApplication__c app = [SELECT ApplicationNumber__c FROM BrokerApplication__c LIMIT 1];
        Map<String, String> params = new Map<String, String>{ 'applicationNumber' => app.ApplicationNumber__c.replace('BA-', '') };
        setupGetContext('/trackMyApplication', params);
        Test.startTest();
        BAPPWebService.doGet();
        Test.stopTest();
    }

    @isTest
    static void testDoGet_TrackMyApplication_MissingNumber() {
        setupGetContext('/trackMyApplication', new Map<String, String>{ 'applicationNumber' => '' });
        Test.startTest();
        BAPPWebService.doGet();
        Test.stopTest();
    }

    @isTest
    static void testDoGet_GetTeamMember_MissingAccountId() {
        setupGetContext('/getTeamMember', new Map<String, String>());
        Test.startTest();
        BAPPWebService.doGet();
        Test.stopTest();
    }

    @isTest
    static void testDoGet_GetTeamMember_WithAccountId() {
        setupGetContext('/getTeamMember', new Map<String, String>{ 'accountId' => '001XXXXXXXXXXXX' });
        Test.startTest();
        BAPPWebService.doGet();
        Test.stopTest();
    }

    @isTest
    static void testDoGet_SearchLead() {
        Map<String, String> params = new Map<String, String>{
            'searchKey' => 'John',
            'accountId' => '001XXXXXXXXXXXX',
            'contactId' => '003XXXXXXXXXXXX',
            'duplicateSearch' => 'true'
        };
        setupGetContext('/searchLead', params);
        Test.startTest();
        BAPPWebService.doGet();
        Test.stopTest();
    }

    @isTest
    static void testDoGet_GetLeads() {
        setupGetContext('/getLeads', null);
        Test.startTest();
        BAPPWebService.doGet();
        Test.stopTest();
    }

    @isTest
    static void testDoGet_GetSalesOrder() {
        setupGetContext('/getSalesOrder', null);
        Test.startTest();
        BAPPWebService.doGet();
        Test.stopTest();
    }

    @isTest
    static void testDoGet_LeadStatusCount() {
        setupGetContext('/leadStatusCount', null);
        Test.startTest();
        BAPPWebService.doGet();
        Test.stopTest();
    }

    @isTest
    static void testDoGet_GetProjectAgencyAllocation_MissingAccountId() {
        setupGetContext('/getProjectAgencyAllocation', new Map<String, String>());
        Test.startTest();
        BAPPWebService.doGet();
        Test.stopTest();
    }

    @isTest
    static void testDoGet_GetProjectAgencyAllocation_Valid() {
        setupGetContext('/getProjectAgencyAllocation', new Map<String, String>{ 'accountId' => '001XXXXXXXXXXXX' });
        Test.startTest();
        BAPPWebService.doGet();
        Test.stopTest();
    }

    @isTest
    static void testDoGet_GetProjects_MissingParams() {
        setupGetContext('/getProjects', new Map<String, String>());
        Test.startTest();
        BAPPWebService.doGet();
        Test.stopTest();
    }


    @isTest
    static void testDoGet_BrokerSummaryCount() {
        setupGetContext('/brokerSummaryCount', null);
        Test.startTest();
        BAPPWebService.doGet();
        Test.stopTest();
    }

    @isTest
    static void testDoGet_GetServiceRequests() {
        setupGetContext('/getServiceRequests', null);
        Test.startTest();
        BAPPWebService.doGet();
        Test.stopTest();
    }
}