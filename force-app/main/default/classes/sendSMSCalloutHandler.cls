/***
Class       : sendSMSCalloutHandler
Author      : Smaartt
Description : 
TestClass   : sendSMSCalloutHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.        V1.0              19/01/24           Initial Version 
****************************************************************************************************************/

public class sendSMSCalloutHandler {    
    
    public static list<SMSTransaction__c> smslist; 
    
    @future(callout=true)
    public static void sendSMS(set<id> smsIds){
        smslist = new list<SMSTransaction__c>();
        List<Integration_Details__mdt> SmsInfo = [SELECT End_Point_URL__c,Password__c,User_Name__c FROM Integration_Details__mdt Where DeveloperName='SMS'];
       System.debug('SmsInfo'+SmsInfo);
        if(SmsInfo.size()>0){
            string endpointUrl = SmsInfo[0].End_Point_URL__c;
            
            String currentEndPoint = endpointUrl +'/login/user/';
            System.debug('currentEndPoint'+currentEndPoint);
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
            gen.writeStringField('username', SmsInfo[0].User_Name__c);
            gen.writeStringField('password', SmsInfo[0].Password__c);
            gen.writeEndObject();
            
            // Get the JSON string.
            String requestBody = gen.getAsString();
            
            HttpRequest request = new HttpRequest();
            request.setEndpoint(currentEndPoint);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setBody(requestBody);
            
            Http http = new Http();            
            try {
                
                HttpResponse response = http.send(request);
                System.debug('response'+response.getBody());            
                if (response.getStatusCode() == 200) {         
                    Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                    string tokenValue = (String) jsonResponse.get('token');
                    System.debug('Token: ' + tokenValue);
                    
                    if(!string.isBlank(tokenValue)){
                        for(SMSTransaction__c sms : [Select Id,Name,Phone_Number__c,Status__c,Message__c From SMSTransaction__c where id=:smsIds]){
                            sendSMSHelper(sms,tokenValue,endpointUrl);
                        }
                        update smslist;
                        
                    }
                    
                } else {
                    System.debug('HTTP Request failed with status code: ' + response.getStatusCode() + ' and message: ' + response.getStatus());
                }
            } catch (Exception e) {
                System.debug('Exception caught: ' + e.getMessage());
            }
            
        }
        
    }   
    public static void sendSMSHelper(SMSTransaction__c sms,string tokenValue,string endpointUrl){  
        if(!string.isBlank(sms.Phone_Number__c) && !string.isBlank(sms.Message__c)){
            String endpoint =  endpointUrl +'/campaigns/submissions/sms/nb';
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
            gen.writeStringField('msgCategory','4.6');
            gen.writeStringField('contentType','3.1');
            gen.writeStringField('senderAddr','AD-BLOOM');
            gen.writeStringField('dndCategory','Campaign');
            gen.writeStringField('priority','1');
            gen.writeStringField('clientTxnId',sms.Name);
            gen.writeStringField('recipient',sms.Phone_Number__c);
            gen.writeStringField('msg',sms.Message__c);
            gen.writeEndObject();
            // Get the JSON string.
            String requestBody = gen.getAsString();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('POST');
            request.setHeader('Authorization',tokenValue);
            request.setHeader('Content-Type', 'application/json');
            request.setBody(requestBody);
            Http http = new Http();
            
            //Send the request and get the response
            HttpResponse response = http.send(request);
            //System.debug('response'+response);
            if (response.getStatusCode() == 201) {
                sms.Status__c ='Success';
                
            } else {
                sms.Status__c ='Failed';
            }
            smslist.add(sms);
            
        }
    }
    
}