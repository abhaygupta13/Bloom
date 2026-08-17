/*
* @Author : Jayprakash Bharti
* @CreatedDate : 20th AUG 2024
* @Description : 
*/
/*****************************************************************************************************
* Version       Author      Date             Comment       
* 1.0           Jayprakash  20AUG2024        Test  GIS Integration Implementation
*****************************************************************************************************/
@isTest
public class LogServiceTest {
    
    @isTest static void getIntegrationLogTest(){
        LogService logInstance = LogService.getInstance();
        List<Integration_Logs__c> integrationLogList = new List<Integration_Logs__c>();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('End_Point_URL__c');
        request.setMethod('POST');
        request.setBody('requestBody');
        
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setStatusCode(200);
        response.setBody('jsonData');
        
        integrationLogList.add(logInstance.getIntegrationLog(request,response,'Outbound','GIS'));
    }
    @isTest static void getExceptionLogTest(){
        LogService logInstance = LogService.getInstance();
        List<Integration_Logs__c> integrationLogList = new List<Integration_Logs__c>();
       
        Exception exception1 = new System.MathException();
        exception1.setMessage('my message');
        
        integrationLogList.add(logInstance.getExceptionLog(exception1,'Outbound','GIS'));
        logInstance.insertIntegrationLogs(integrationLogList);
    }
    
}