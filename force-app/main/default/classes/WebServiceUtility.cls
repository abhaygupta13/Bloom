/*
* @Author: Shruti Kulkarni
* @CreatedDate: 3rd June 2025
* @Description: Class created to build and utilize the generic methods needed for common services like OTP Generation, OPT verification, etc.
*/
/*****************************************************************************************************
* Version       Author      	   Date             Comment                                                                       
* 1.1           Shruti Kulkarni    3rd June 2025    Initial Draft
*****************************************************************************************************/
@RestResource(urlMapping='/webServiceUtility/V1/*')
global class WebServiceUtility {
    @HttpPost //Handles HTTP POST requests and delegates to the appropriate helper method.
    global static void doPost() {
        RestRequest req = RestContext.request;
        String requestBodyString;

        if(RestContext.request.requestBody != null){
            requestBodyString = RestContext.request.requestBody.toString();
        }

        switch on req.requestURI.substringAfterLast('/') {
            when 'SendOtpToVerify' {
                OTPHandler.generateAndSendOTP(requestBodyString);
            }
            when 'VerifyOTP' {
                OTPHandler.verifyOTP(requestBodyString);
            }        
        }
    }
}