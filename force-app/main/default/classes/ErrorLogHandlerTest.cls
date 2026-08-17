@isTest
public class ErrorLogHandlerTest {
    
    @isTest
    static void testLogError() {
        String className = 'TestClass';
        String methodName = 'testMethod';
        Exception ex = new DmlException('Test exception');
        String responseBody = 'Test response body';
        
        Test.startTest();
        ErrorLogHandler.logError(className, methodName, ex, responseBody);
        Test.stopTest();
        
        // Optional: Query to ensure the record is created
        Error_Log__c[] logs = [SELECT Id FROM Error_Log__c LIMIT 1];
    }
    
    @isTest
    static void testLogErrorWithoutException() {
        String className = 'TestClass';
        String methodName = 'testMethod';
        String errorMessage = 'Test error message';
        
        Test.startTest();
        ErrorLogHandler.logErrorWithoutException(className, methodName, errorMessage);
        Test.stopTest();
        
        // Optional: Query to ensure the record is created
        Error_Log__c[] logs = [SELECT Id FROM Error_Log__c LIMIT 1];
    }
    
    @isTest
    static void testLogInfo() {
        String className = 'TestClass';
        String methodName = 'testMethod';
        String infoMessage = 'Test info message';
        
        Test.startTest();
        ErrorLogHandler.logInfo(className, methodName, infoMessage);
        Test.stopTest();
        
        // Optional: Query to ensure the record is created
        Error_Log__c[] logs = [SELECT Id FROM Error_Log__c LIMIT 1];
    }
}