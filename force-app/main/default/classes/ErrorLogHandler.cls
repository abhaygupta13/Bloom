/***
Class       : ErrorLogHandler
Author      : Rajat Rastogi
Description : 
TestClass   : ErrorLogHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.      V1.0             	 07/06/2024           Initial Version  
****************************************************************************************************************/ 

public class ErrorLogHandler {
	public static void logError(String className, String methodName, Exception ex, String responseBody){
        	Error_Log__c errorLog = new Error_Log__c();
            errorLog.Error_Cause__c = String.valueOf(ex.getCause());
            errorLog.Error_Message__c = ex.getMessage();
            errorLog.Error_Trace__c = ex.getStackTraceString();
            errorLog.Error_Type__c = ex.getTypeName();
            errorLog.Line_Number__c   = ex.getLineNumber();
            errorLog.Class_Name__c = className;
            errorLog.Method_Name__c = MethodName;
        	errorlog.responseBody__c = responseBody;	// if needed
        	errorlog.Type__c = 'Exception';
            insert errorLog;
    }
    
    public static void logErrorWithoutException(String className, String methodName, String errorMessage){
        	Error_Log__c errorLog = new Error_Log__c();
            errorLog.Error_Message__c = errorMessage;
            errorLog.Class_Name__c = className;
            errorLog.Method_Name__c = MethodName;
        	errorlog.Type__c = 'Error';
            insert errorLog;
    }
    
    public static void logInfo(String className, String methodName, String info){
        	Error_Log__c errorLog = new Error_Log__c();
            errorLog.Error_Message__c = info;
            errorLog.Class_Name__c = className;
            errorLog.Method_Name__c = MethodName;
        	errorlog.Type__c = 'Info';
            insert errorLog;
    }
}