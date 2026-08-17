//============================ BCAPP_WebService =============================
/*
* @Author : Eagles
* @CreatedDate : 23rd OCT 2023
* @Name : BCAPP_WebService 
* @Description : 
*/
/*****************************************************************************************************
* Version       Author                   Date             Comment                                                                       
* 1.0           Eagles               11NOV2023        Initial draft 
*****************************************************************************************************/

@RestResource(urlMapping='/bloomholdingsWebService/V1/*') 

global class BCAPP_WebService { 
    
    @HttpGet
    global static void doGet(){
        RestRequest req = RestContext.request;
        String requestBodyString;
        if(RestContext.request.requestBody!=null){
            // Get the request body as a Blob
            Blob requestBodyBlob = RestContext.request.requestBody;
            requestBodyString = requestBodyBlob.toString();
            BCAPP_WebServiceHelper.captureLogs(requestBodyString,req.requestURI.substringAfterLast('/'));
        }
        
        switch on req.requestURI.substringAfterLast('/'){
            
            when 'getProjects'{
                String headerValue = req.headers.get('isEnableMIP'); 
                Boolean isEnableMIP = (headerValue != null && headerValue.equalsIgnoreCase('true'));
                BCAPP_WebServiceHelper.getProjects(isEnableMIP);
            }
            when 'getNationality'{
                BCAPP_WebServiceHelper.getNationality();
            }
            
            
        }
    }
    
    @HttpPost
    global static void doPost(){
        
        Map<String,Object> returnValue = new Map<String,Object>();
        try{
            RestRequest req = RestContext.request;
            String requestBodyString;
            BCAPP_WrapperUtility.Response response;
            if(RestContext.request.requestBody!=null){
                // Get the request body as a Blob
                Blob requestBodyBlob = RestContext.request.requestBody;
                
                // Convert Blob to String
                requestBodyString = requestBodyBlob.toString();
                if((!req.requestURI.substringAfterLast('/').contains('createAzureUser')) &&
                   (!req.requestURI.substringAfterLast('/').contains('deactivateAzureUser')))
                BCAPP_WebServiceHelper.captureLogs(requestBodyString,req.requestURI.substringAfterLast('/'));
                
            }
            switch on req.requestURI.substringAfterLast('/'){
                when 'getBuildings'{
                    Map<String, Object> data = (Map<String, Object>)JSON.deserializeUntyped(requestBodyString);
                    String projectName = (String)data.get('projectId');
                       Boolean isEnabledMIP = (Boolean)data.get('isEnabledMIP');
                    BCAPP_WebServiceHelper.getBuildings(projectName,isEnabledMIP);
                }
                when 'getUnits'{
                    Map<String, Object> data = (Map<String, Object>)JSON.deserializeUntyped(requestBodyString);
                    String buildingName = (String)data.get('buildingId');
                    BCAPP_WebServiceHelper.getUnits(buildingName);
                }
               
                when 'createLoginHisory'{
                    BCAPP_WebServiceHelper.createLoginHisory(requestBodyString);
                }
                when 'getServiceCatalogs'{
                    BCAPP_WebServiceHelper.getServiceCatalogs();
                }
                when 'getMyPortfolio'{
                    BCAPP_WebServiceHelper.fetchMyPortfolio(requestBodyString);
                }
                when 'createMoveOutRequest'{
                    BCAPP_MoveOutServiceHandler moveOutHandler = new BCAPP_MoveOutServiceHandler();
                    moveOutHandler.MoveOutRequest(requestBodyString);
                }
                when 'getServiceCatalogDocuments'{
                    BCAPP_WebServiceHelper.getRequestDocuments(requestBodyString);
                }
                when 'uploadDocument'{
                    BCAPP_WebServiceHelper.createDocument(requestBodyString);
                }
                when 'getProfile'{
                    BCAPP_WebServiceHelper.getProfile(requestBodyString);
                }
                when 'updateProfile'{
                    BCAPP_WebServiceHelper.updateProfile(requestBodyString);
                }
                when 'updatePassword'{
                    // BCAPP_WebServiceHelper.updatePassword(requestBodyString);
                }
                when 'sendOTPToVerifyEmail'{
                    BCAPP_WebServiceHelper.sendOTPToVerifyEmailTemp(requestBodyString);
                }
                when 'validateEmailOTP'{
                    BCAPP_WebServiceHelper.validateEmailOTPTemp(requestBodyString);
                }  
                when 'sendOTPToVerify'{
                    BCAPP_WebServiceHelper.sendOTPToVerifyEmailTemp(requestBodyString);
                }
                when 'validateOTP'{
                    BCAPP_WebServiceHelper.validateEmailOTPTemp(requestBodyString);
                } 
                when 'getServiceRequestDetails'{
                    BCAPP_WebServiceHelper.getServiceRequestDetails(requestBodyString);
                }
                when 'customerFeedback'{
                    BCAPP_WebServiceHelper.customerFeedback(requestBodyString);
                }
                when 'accountDocuments'{
                    BCAPP_WebServiceHelper.accountDocuments(requestBodyString);
                }
                when 'getNotices'{
                    BCAPP_WebServiceHelper.getNotices(requestBodyString);
                }
                when 'getUserRequests'{
                    BCAPP_WebServiceHelper.getUserRequests(requestBodyString);
                }
                when 'getNotificationOptions'{
                    BCAPP_WebServiceHelper.getNotificationsOptions(requestBodyString);
                }
                when 'getEventDetails'{
                    BCAPP_HandleNotificatoins notificationHandler = new BCAPP_HandleNotificatoins();
                    notificationHandler.getEventDetails(requestBodyString);
                }
                when 'createMoveInRequest'{
                    BCAPP_MoveInServiceHandler moveInHelper = new BCAPP_MoveInServiceHandler();
                    moveInHelper.createMoveInRequest(requestBodyString);
                }  
                when 'createOwnerMoveInRequest'{
                    BCAPP_MoveInServiceHandler moveInHelper = new BCAPP_MoveInServiceHandler();
                    moveInHelper.createMoveInRequest(requestBodyString);
                }  
                when 'createRenewalRequest'{
                    BCAPP_MoveOutServiceHandler moveOutHelper = new BCAPP_MoveOutServiceHandler();
                    moveOutHelper.renewalRequest(requestBodyString);
                }
                when 'createAccessPermitRequest'{
                    BCAPP_AccessPermitHelper accessPermit = new BCAPP_AccessPermitHelper();
                    accessPermit.createAccessPermitRequest(requestBodyString);
                }
                when 'createAzureUser'{
                    BCAPP_WebServiceHelper.createAzureUser(requestBodyString);
                }
                when 'deactivateAzureUser'{
                    BCAPP_WebServiceHelper.deactivateAzureUser(requestBodyString);
                }
                when 'getAccessPermitOptions'{
                    BCAPP_WebServiceHelper.getAccessPermitOptions(requestBodyString);
                }
                 when 'updateServiceRequest'{
                    BCAPP_WebServiceHelper.updateServiceRequest(requestBodyString);
                }
                 when 'createServiceRequest'{
                    BCAPP_WebServiceHelper.createServiceRequest(requestBodyString);
                }
                when 'getFavourites'{
                     BCAPP_WebServiceHelper.getFavourites(requestBodyString);
                }
                 when 'getFMAPPURL'{
                     Map<String,String> data = new Map<String,String>();
                     data.put('url','https://bloomholding--eaglesdev.sandbox.my.salesforce-sites.com/fmapp');
                    BCAPP_WebServiceHelper.makeSuccessResponse(data);

                }
                
                 when 'validateMoveInBusinessRule'{
                    Map<String, Object> data = (Map<String, Object>)JSON.deserializeUntyped(requestBodyString);
                    String unitId = (String)data.get('unitId');
                    //    return BloomholdingsWebServiceHelper.validateMoveInBusinessRule(unitId);
                }
               
                 when 'forgotPasswordOTP'{
                    BCAPP_WebServiceHelper.preLoginOtpFlow(requestBodyString);
                    
                }
                  when 'createVacationRequest'{
                  BCAPP_WebServiceHelper.createVacationRequest(requestBodyString);               
                }
                when 'manageGuestRequest'{
                  BCAPP_GeneralServiceRequestHelper.manageGuestRequest(requestBodyString);
                }
                when 'getGuestRequests'{
                  BCAPP_GeneralServiceRequestHelper.getAllGuestRequest(requestBodyString);
                }
               
            }
        }
        catch(Exception e){          
            // system.debug('errorMessage',e.getMessage());
        }
        
    }
}