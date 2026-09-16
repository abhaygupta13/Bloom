//============================ MicrosoftAzureB2CUtility =============================
/*
* @Author : Eagles
* @CreatedDate : 8 Nov 2024
* @Name : MicrosoftAzureB2CUtility
* @Description : This utility class provides methods to integrate Salesforce with Microsoft Azure AD B2C.
*                It supports creating, updating, and deactivating Azure B2C user accounts using the
*                Microsoft Graph API.
*/
/*****************************************************************************************************
* Version       Author                  Date             Comment                                                                       
* 1.0           Eagles               8 Nov 2024         Initial draft  
*****************************************************************************************************/

public class MicrosoftAzureB2CUtility {

    public class TokenResponse {
        public String access_token;
        public HttpRequest request;
        public HttpResponse response;
        public TokenResponse(){
            
        }
    }
    
    public static TokenResponse getAccessToken() {
        
        APISetting__mdt  APIInstance = APISetting__mdt.getInstance('Azure_Access_Token');

        String TOKEN_URL = APIInstance.URL__c;//'https://login.microsoftonline.com/8e569186-d6b2-4250-8cef-dc0bede8edb9/oauth2/v2.0/token';
        String CLIENT_ID = APIInstance.Client_Id__c;//'d72b7142-30e6-4630-9b39-4c77af7062f9';
        String CLIENT_SECRET =APIInstance.Client_Secret__c;// '3wo8Q~f5WNkApLmNgUER32~iUtLDTvv9YAcZsb1M';
        String SCOPE =APIInstance.Scope__c;// 'https://graph.microsoft.com/.default';
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        request.setEndpoint(TOKEN_URL);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        
        String body = 'grant_type=client_credentials'
            + '&client_id=' + CLIENT_ID
            + '&client_secret=' + CLIENT_SECRET
            + '&scope=' + SCOPE;
        
        request.setBody(body);
        
        HttpResponse response = http.send(request);

        
        if (response.getStatusCode() == 200) {
            
            Map<String, Object> accessMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            system.debug('accessMap'+accessMap);
            TokenResponse respToken=new TokenResponse();
            // Accessing the values
            respToken.access_token = (String) accessMap.get('access_token');
            respToken.request=request;
            respToken.response=response;            
            return respToken;
        } else {
            // Handle error response
            System.debug('Error: ' + response.getStatus() + ' - ' + response.getBody());
            return null;
        }
    }


    public static TokenResponse getAccessTokenv2() {
    String TOKEN_URL = 'callout:Azure_Named_Credential';

    Http http = new Http();
    HttpRequest request = new HttpRequest();

    request.setEndpoint(TOKEN_URL);
    request.setMethod('POST');
    request.setHeader('Content-Type', 'application/x-www-form-urlencoded');

    String body = 'grant_type=client_credentials';

    request.setBody(body);

    HttpResponse response = http.send(request);

    if (response.getStatusCode() == 200) {
        Map<String, Object> accessMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        System.debug('accessMap: ' + accessMap);

        TokenResponse respToken = new TokenResponse();
        respToken.access_token = (String) accessMap.get('access_token');
        respToken.request = request;
        respToken.response = response;
        return respToken;
    } else {
        // Handle error response
        System.debug('Error: ' + response.getStatus() + ' - ' + response.getBody());
        return null;
    }
    }
    
     @AuraEnabled
    public static String checkAndCreateAzureB2CUser(Id userId) {
        User__c userRecord = [SELECT Account__c,Temporary_Password__c,User_Type__c,Email__c, Azure_UserId__c FROM User__c WHERE Id = :userId LIMIT 1];

        if (String.isBlank(userRecord.Azure_UserId__c)) {
            BCAPP_Utility utiRef = new BCAPP_Utility();
            userRecord.Temporary_Password__c = utiRef.generateRandomPassword();
            createUser(userRecord);
            update userRecord;
            return 'Azure B2C User Created';
        }
        else {
            return ' User already exists';
        }
    }
    
    public static void createUser(User__c rec) {
        BCAPP_Utility utiRef = new BCAPP_Utility();
        List<IntegrationEvent__e> inkEvents = new List<IntegrationEvent__e>();
        IntegrationEvent__e objEvent= new IntegrationEvent__e();
        objEvent.Action__c = 'Insert';
        objEvent.ObjectAPIName__c = 'User__c';
        objEvent.RecordId__c = rec.Id;
        objEvent.Param1__c = 'DisablePasswordExpiration';
        objEvent.Param2__c = 'emailAddress';
        objEvent.Param3__c = Label.AzureUserEmail; //'bloomdevb2c.onmicrosoft.com';
        objEvent.Param4__c = rec.Temporary_Password__c;
        objEvent.Param5__c = 'false';
        objEvent.Param6__c = rec.Email__c;
        objEvent.Param7__c = rec.Account__c;
        objEvent.userType__c = rec.User_Type__c;
        
        inkEvents.add(objEvent);
        // Call method to publish events
        List<Database.SaveResult> results = EventBus.publish(inkEvents);
        // Inspect publishing result for each event
        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                System.debug('Successfully published event.');
            } else {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('Error returned: ' + err.getStatusCode() +' - ' +err.getMessage());
                }
            }
        }
    }
// This is for the Name Update
// Class MicrosoftAzureB2CUtility 
// Method Name : updateUserName 
// Added the addtional Attribute as SubAction__c as 'Name'

    public static void updateUserName(User__c rec) {
        
        
        List<IntegrationEvent__e> inkEvents = new List<IntegrationEvent__e>();
        IntegrationEvent__e objEvent= new IntegrationEvent__e();
        objEvent.Action__c = 'Update';
        objEvent.ObjectAPIName__c = 'User__c';
        objEvent.SubAction__c='Name';
        objEvent.RecordId__c = rec.Id;
        objEvent.Param1__c = 'DisablePasswordExpiration';
            objEvent.Param2__c = 'emailAddress';
        objEvent.Param3__c = Label.AzureUserEmail;  //'bloomdevb2c.onmicrosoft.com';
        objEvent.Param5__c = 'false';
        objEvent.Param6__c = 'false';
        inkEvents.add(objEvent);
        // Call method to publish events
        List<Database.SaveResult> results = EventBus.publish(inkEvents);
        // Inspect publishing result for each event
        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                System.debug('Successfully published event.');
            } else {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('Error returned: ' + err.getStatusCode() +' - ' +err.getMessage());
                }
            }
        }
    }
   
// This is for the Email Address Update
//  Class MicrosoftAzureB2CUtility 
// Method Name : updateUser 
// Added the addtional Attribute as SubAction__c as 'Email Address'

    
    public static void updateUser(User__c rec) {
      
        
        List<IntegrationEvent__e> inkEvents = new List<IntegrationEvent__e>();
        IntegrationEvent__e objEvent= new IntegrationEvent__e();
        objEvent.Action__c = 'Update';
        objEvent.ObjectAPIName__c = 'User__c';
        objEvent.SubAction__c='EmailUpdate';
        objEvent.RecordId__c = rec.Id;
        objEvent.Param1__c = 'DisablePasswordExpiration';
        objEvent.Param2__c = rec.Email__c;
        objEvent.Param3__c = Label.AzureUserEmail; //'bloomdevb2c.onmicrosoft.com';
         objEvent.Param4__c = 'emailAddress';
        objEvent.Param5__c = 'false';
        objEvent.Param6__c = '';
        inkEvents.add(objEvent);
        // Call method to publish events
        List<Database.SaveResult> results = EventBus.publish(inkEvents);
        // Inspect publishing result for each event
        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                System.debug('Successfully published event.');
            } else {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('Error returned: ' + err.getStatusCode() +' - ' +err.getMessage());
                }
            }
        }
    }
    
     // Method to deactivate a user by userId (or userPrincipalName)
    public static HttpResponse deactivateUser(id caseId,string principalId) {
        List<Integration_Logs__c> IntegrationLogList=new List<Integration_Logs__c>();

        TokenResponse tokenResp=   getAccessToken();
            if(tokenResp==null){
                return null;
            }
    
        String accessToken = getAccessToken().access_token; // Call the method to get the access token

        APISetting__mdt  APIInstance = APISetting__mdt.getInstance('Azure_User_Deactivation');

        // Graph API endpoint to update the user
        String endpoint = APIInstance.URL__c + principalId;//caseRecord.Account.Azure_UserPrincipal_Id__c;

        // Graph API endpoint to update the user
      //  String endpoint = 'https://graph.microsoft.com/v1.0/users/' + caseRecord.Account.Azure_UserPrincipal_Id__c;

        // Create a new HTTP request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('PATCH');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setHeader('Content-Type', 'application/json');

        // Set the request body to disable the user
        String requestBody = '{"accountEnabled": false}';
        req.setBody(requestBody);

        // Send the HTTP request
        Http http = new Http();
        try {
        LogService logInstance = LogService.getInstance();

            HttpResponse response = http.send(req);


        try {
             response = http.send(req);
            Integration_Logs__c logInstanceInstance= logInstance.getIntegrationLog(req,response,'Outbound','Azure');
            if(caseId!=null)
            logInstanceInstance.Case__c=caseId;
            IntegrationLogList.add(logInstanceInstance);

        } catch (Exception exp) {
            
            Integration_Logs__c logInstanceInstanceError= logInstance.getExceptionLog(exp, 'Outbound', 'Azure');
            if(caseId!=null)
                logInstanceInstanceError.Case__c=caseId;
            IntegrationLogList.add(logInstanceInstanceError);

        }
        logInstance.insertIntegrationLogs(IntegrationLogList);   

        return response;
        } catch (Exception e) {
            System.debug('Error occurred while deactivating user: ' + e.getMessage());
            return null;

        }
    }
    
    
}