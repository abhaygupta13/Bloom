/***
Class       : BAWebService
Author      : Biswajeet
Description : 
TestClass   : BAWebServiceTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              25/08/23           Initial Version 
****************************************************************************************************************/
@RestResource(urlMapping='/BAWebService/v1/*') 
global class BAWebService { 
    
    @HttpGet
    global static void doGet(){
        RestRequest req = RestContext.request;
        String requestBodyString;
        switch on req.requestURI.substringAfterLast('/'){
            when 'getNationality'{
                BCAPP_WebServiceHelper.getNationality();
            }
        }
    }
    
    @HttpPost
    global static void doPost(){
        Map<String, Object> returnValue = new Map<String,Object>();
        Savepoint sp;
        try{
            RestRequest req = RestContext.request;
            
            String requestBodyString;
            BCAPP_WrapperUtility.Response response;
            if(RestContext.request.requestBody!=null){
                // Get the request body as a Blob
                Blob requestBodyBlob = RestContext.request.requestBody;
                
                // Convert Blob to String
                requestBodyString = requestBodyBlob.toString();
            }
            BAWebServiceHandler objBAWebServiceHandler = BAWebServiceHandler.getInstance();
            switch on req.requestURI.substringAfterLast('/'){
                when 'getCustomerDetailsForRegistration'{
                    Map<String, Object> data = (Map<String, Object>)JSON.deserializeUntyped(requestBodyString);
                    objBAWebServiceHandler.getCustomerDetailsForRegistration(data);
                }
                when 'appRegistrationRequest'{
                    sp = Database.setSavepoint();
                    Map<String, Object> data = (Map<String, Object>)JSON.deserializeUntyped(requestBodyString);
                    objBAWebServiceHandler.createAppRegistrationRequest(data);
                }
                when 'getAppRegistrationStatus'{
                    Map<String, Object> data = (Map<String, Object>)JSON.deserializeUntyped(requestBodyString);
                    objBAWebServiceHandler.getAppRegistrationStatus(data);
                }
                when 'getMyProfile'{
                    Map<String, Object> data = (Map<String, Object>)JSON.deserializeUntyped(requestBodyString);
                    objBAWebServiceHandler.getMyProfile(data);
                }
                when 'getUnitInstallments'{
                    Map<String, Object> data = (Map<String, Object>)JSON.deserializeUntyped(requestBodyString);
                    objBAWebServiceHandler.getUnitInstallments(data);
                }
                when 'updateCustomer'{
                    Map<String, Object> data = (Map<String, Object>)JSON.deserializeUntyped(requestBodyString);
                    objBAWebServiceHandler.updateCustomer(data);
                }
                when 'downloadDocument'{
                    Map<String, Object> data = (Map<String, Object>)JSON.deserializeUntyped(requestBodyString);
                    objBAWebServiceHandler.downloadDocument(data);
                }
                when 'uploadDocument'{
                    Map<String, Object> data = (Map<String, Object>)JSON.deserializeUntyped(requestBodyString);
                    objBAWebServiceHandler.uploadDocument(data);
                }
                when 'sendOTP' {
                    objBAWebServiceHandler.generateOTP((Map<String, Object>)JSON.deserializeUntyped(requestBodyString));
                }
                when 'verifyOTP' {
                    objBAWebServiceHandler.verifyOTP((Map<String, Object>)JSON.deserializeUntyped(requestBodyString));
                } 
                when 'getListValues' {
                    objBAWebServiceHandler.getListValues((Map<String, Object>)JSON.deserializeUntyped(requestBodyString));
                } 
                when 'getSRs' {
                    objBAWebServiceHandler.getSRs((Map<String, Object>)JSON.deserializeUntyped(requestBodyString));
                }
                when 'doCreateSR' {
                    objBAWebServiceHandler.doCreateSR((Map<String, Object>)JSON.deserializeUntyped(requestBodyString));
                }
                when 'doPostSRFollowUp' {
                    objBAWebServiceHandler.doPostSRFollowUp((Map<String, Object>)JSON.deserializeUntyped(requestBodyString));
                } 
            }
        }catch(Exception e){
            returnValue.put('status', 'error');
            returnValue.put('message', e.getMessage());
            if(sp != NULL){
                Database.rollback(sp);
            }
            BAWebServiceHandler.getInstance().getServerErrorResponse(returnValue);
        }
    }
}