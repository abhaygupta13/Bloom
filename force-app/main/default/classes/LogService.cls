/*
* @Author : Biswajeet Samal
* @CreatedDate : 7th AUG 2024
* @Description : Log Service class
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                              
* 1.0           Biswajeet   07AUG2024        Initial draft 
* 2.0           Jayprakash  20AUG2024        Implemented GIS Integration
*****************************************************************************************************/
public class LogService {
    
    private static LogService instance;
    
    private LogService() {
        
    }
    
    public static LogService getInstance() {
        if(instance == null) {
            instance = new LogService();
        }
        return instance;
    }
    
    public Integration_Logs__c getIntegrationLog(HttpRequest request,HttpResponse response, String integrationType, String integrationSystem){
        Integration_Logs__c log = new Integration_Logs__c();
        log.Type__c = integrationType;
        log.External_System__c = integrationSystem;
        log.Method__c = request.getMethod();
        string req = String.valueOf(request);
        string res = String.valueOf(response.getBody());
        /*
        if(req.length()>255)
            log.Request__c = req.substring(0, 224); 
        else*/
            log.Request__c = req;
        
       /* if(res.length()>255)
            log.Response__c = res.substring(0, 224); 
        else*/
            log.Response__c = res;
        
        log.Status__c = response.getStatus();//  Failed /Success
        log.Status_code__c = String.valueOf(response.getStatusCode());
        return log;
    }
    
    public Integration_Logs__c getExceptionLog(Exception exp, String integrationType, String integrationSystem){
        Integration_Logs__c log = new Integration_Logs__c();
        log.Type__c = integrationType;
        log.External_System__c = integrationSystem;
        log.Error__c = exp.getMessage();
        return log;
    }
    
    //Insert integration logs
    public List<Integration_Logs__c> insertIntegrationLogs(List<Integration_Logs__c> integrationLogList){
        if(integrationLogList != NULL && !integrationLogList.isEmpty()){
            insert integrationLogList;
        }
        return integrationLogList;
    }
}