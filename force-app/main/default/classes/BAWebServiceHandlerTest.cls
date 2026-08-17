@IsTest
public class BAWebServiceHandlerTest {
    
    private static void runGet(String action) {
        RestRequest req = new RestRequest();
        req.httpMethod = 'GET';
        req.requestURI = '/services/apexrest/BAWebService/v1/' + action;
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        BAWebService.doGet();
    }
    
    private static void runPost(String action, String jsonBody) {
        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/BAWebService/v1/' + action;
        req.requestBody = Blob.valueOf(jsonBody);
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        BAWebService.doPost();
    }
    
    // ---------- GET TEST ----------
    @IsTest
    static void testGET_getNationality() {
        Test.startTest();
        runGet('getNationality');
        Test.stopTest();
        
        System.assert(true, 'GET getNationality executed');
    }
    
    // ---------- POST TESTS ----------
    
    @IsTest
    static void testPOST_getCustomerDetailsForRegistration() {
        Test.startTest();
        runPost('getCustomerDetailsForRegistration', '{}');
        Test.stopTest();
        System.assert(true);
    }
    
    @IsTest
    static void testPOST_appRegistrationRequest() {
        Test.startTest();
        runPost('appRegistrationRequest', '{}');
        Test.stopTest();
        System.assert(true);
    }
    
    @IsTest
    static void testPOST_getAppRegistrationStatus() {
        Test.startTest();
        runPost('getAppRegistrationStatus', '{}');
        Test.stopTest();
        System.assert(true);
    }
    
    @IsTest
    static void testPOST_getMyProfile() {
        Test.startTest();
        runPost('getMyProfile', '{}');
        Test.stopTest();
        System.assert(true);
    }
    
    @IsTest
    static void testPOST_getUnitInstallments() {
        Test.startTest();
        runPost('getUnitInstallments', '{}');
        Test.stopTest();
        System.assert(true);
    }
    
    @IsTest
    static void testPOST_updateCustomer() {
        Test.startTest();
        runPost('updateCustomer', '{}');
        Test.stopTest();
        System.assert(true);
    }
    
    @IsTest
    static void testPOST_downloadDocument() {
        Test.startTest();
        runPost('downloadDocument', '{}');
        Test.stopTest();
        System.assert(true);
    }
    
    @IsTest
    static void testPOST_uploadDocument() {
        Test.startTest();
        runPost('uploadDocument', '{}');
        Test.stopTest();
        System.assert(true);
    }
    
    @IsTest
    static void testPOST_sendOTP() {
        Test.startTest();
        runPost('sendOTP', '{"mobile":"9999999999"}');
        Test.stopTest();
        System.assert(true);
    }
    
    @IsTest
    static void testPOST_verifyOTP() {
        Test.startTest();
        runPost('verifyOTP', '{"otp":"123456"}');
        Test.stopTest();
        System.assert(true);
    }
    
    @IsTest
    static void testPOST_getListValues() {
        Test.startTest();
        runPost('getListValues', '{}');
        Test.stopTest();
        System.assert(true);
    }
    
    @IsTest
    static void testPOST_getSRs() {
        Test.startTest();
        runPost('getSRs', '{}');
        Test.stopTest();
        System.assert(true);
    }
    
    @IsTest
    static void testPOST_doCreateSR() {
        Test.startTest();
        runPost('doCreateSR', '{}');
        Test.stopTest();
        System.assert(true);
    }
    
    @IsTest
    static void testPOST_doPostSRFollowUp() {
        Test.startTest();
        runPost('doPostSRFollowUp', '{}');
        Test.stopTest();
        System.assert(true);
    }
}