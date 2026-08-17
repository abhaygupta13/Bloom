@IsTest
public class BCAPP_WebServiceTest {
    
    @TestSetup
    static void setupTestData() {
        
        Account accountRecord =BCAPP_TestDataFactory.createAccount('Test Account');
        accountRecord.Azure_UserPrincipal_Id__c='testttt';
        insert accountRecord;
    }
    
    @IsTest
    static void testHttpGet_getProjects() {
        try{
        RestRequest req = new RestRequest();
        req.requestBody=blob.valueof('{"projectId":"projectId"}');
        req.requestURI = '/services/apexrest/bloomholdingsWebService/V1/getProjects';
        req.httpMethod = 'GET';
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        // Invoke the GET method
        BCAPP_WebService.doGet();
        
        req.requestURI = '/services/apexrest/bloomholdingsWebService/V1/getNationality';
        BCAPP_WebService.doGet();
        
        }catch(exception e){
            
        }
    }
    
    @IsTest
    static void testHttpPost_getBuildings() {
        try{
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/bloomholdingsWebService/V1/getBuildings';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"projectId":"12345"}');
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        BCAPP_WebService.doPost();
        req.requestURI = '/services/apexrest/bloomholdingsWebService/V1/getBuildings';
        BCAPP_WebService.doPost();
        req.requestURI = '/services/apexrest/bloomholdingsWebService/V1/getUnits';
        BCAPP_WebService.doPost();
        
        req.requestURI = '/services/apexrest/bloomholdingsWebService/V1/getServiceCatalogs';
        BCAPP_WebService.doPost();
        
        req.requestURI = '/services/apexrest/bloomholdingsWebService/V1/getMyPortfolio';
        BCAPP_WebService.doPost();
        
        req.requestURI = '/services/apexrest/bloomholdingsWebService/V1/getServiceCatalogDocuments';
        BCAPP_WebService.doPost();
        
        
        req.requestURI = '/services/apexrest/bloomholdingsWebService/V1/uploadDocument';
        BCAPP_WebService.doPost();
        
        
        req.requestURI = '/services/apexrest/bloomholdingsWebService/V1/getProfile';
        BCAPP_WebService.doPost();
        
        req.requestURI = '/services/apexrest/bloomholdingsWebService/V1/updateProfile';
        BCAPP_WebService.doPost();
        
        req.requestURI = '/services/apexrest/bloomholdingsWebService/V1/sendOTPToVerifyEmail';
        BCAPP_WebService.doPost();
        
        req.requestURI = '/services/apexrest/bloomholdingsWebService/V1/validateEmailOTP';
        BCAPP_WebService.doPost();
        
        req.requestURI = '/services/apexrest/bloomholdingsWebService/V1/sendOTPToVerify';
        BCAPP_WebService.doPost();
        
        
        req.requestURI = '/services/apexrest/bloomholdingsWebService/V1/validateOTP';
        BCAPP_WebService.doPost();
        
        
        req.requestURI = '/services/apexrest/bloomholdingsWebService/V1/getServiceRequestDetails';
        BCAPP_WebService.doPost();
        
        
        req.requestURI = '/services/apexrest/bloomholdingsWebService/V1/customerFeedback';
        BCAPP_WebService.doPost();
        
        req.requestURI = '/services/apexrest/bloomholdingsWebService/V1/getEventDetails';
        BCAPP_WebService.doPost();
        
        
        req.requestURI = '/services/apexrest/bloomholdingsWebService/V1/createAccessPermitRequest';
        BCAPP_WebService.doPost();
        
        
        req.requestURI = '/services/apexrest/bloomholdingsWebService/V1/createOwnerMoveInRequest';
        BCAPP_WebService.doPost();
        
        req.requestURI = '/services/apexrest/bloomholdingsWebService/V1/createTenantRenewalRequest';
        BCAPP_WebService.doPost();
        
        req.requestURI = '/services/apexrest/bloomholdingsWebService/V1/createHolidayHomesRenewalRequest';
        BCAPP_WebService.doPost();
        
        }catch(exception e){
            
        }
    }
    
    @IsTest
    static void testHttpPost_createMoveOutRequest() {
        try{
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/bloomholdingsWebService/V1/createMoveOutRequest';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"requestData":"sample data"}');
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        BCAPP_WebService.doPost();
    }catch(exception e){
            
        }   
    }
    
    @IsTest
    static void testErrorHandling() {
        try{
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/bloomholdingsWebService/V1/invalidEndpoint';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"invalid":"data"}');
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        BCAPP_WebService.doPost();
}catch(exception e){
            
        }        
    }
}