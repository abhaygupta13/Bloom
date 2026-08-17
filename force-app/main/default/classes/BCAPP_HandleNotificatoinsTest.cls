@IsTest
public class BCAPP_HandleNotificatoinsTest {

        @isTest
    static void testUpdateCaseOwner() {
        RestContext.response = new RestResponse();
        Project__c testProject =BCAPP_TestDataFactory.createProject();
        insert testProject;
        Notifications__c testNotifications =BCAPP_TestDataFactory.createNotifications();
        testNotifications.Project__c= testProject.id;
        testNotifications.RecordTypeId= SObjectType.Notifications__c.getRecordTypeInfosByDeveloperName().get('Events').getRecordTypeId(); 
        insert testNotifications;
        BCAPP_HandleNotificatoins instance=new BCAPP_HandleNotificatoins();
        instance.getNotifications(system.today(),system.today(),new List<String>{testNotifications.Project__c},'events');
        
    }
    
       @isTest
    static void testgetEventDetails() {
        RestContext.response = new RestResponse();

        Project__c testProject =BCAPP_TestDataFactory.createProject();
        insert testProject;
        Notifications__c testNotifications =BCAPP_TestDataFactory.createNotifications();
        testNotifications.Project__c= testProject.id;
        testNotifications.RecordTypeId= SObjectType.Notifications__c.getRecordTypeInfosByDeveloperName().get('Events').getRecordTypeId(); 
        insert testNotifications;
        BCAPP_HandleNotificatoins instance=new BCAPP_HandleNotificatoins();
        map<string,string> mapRequest=new map<string,string>();
        mapRequest.put('eventId',testNotifications.id);
        
        instance.getEventDetails(JSON.Serialize(mapRequest));
        
    }
    
        @isTest
    static void testsgetAlerts() {
        RestContext.response = new RestResponse();

        Account accountRecord =BCAPP_TestDataFactory.createAccount('Test Account');
        insert accountRecord;
        Project__c testProject =BCAPP_TestDataFactory.createProject();
        insert testProject;
        Notifications__c testNotifications =BCAPP_TestDataFactory.createNotifications();
        testNotifications.Project__c= testProject.id;
        testNotifications.Account__c=accountRecord.id;
        testNotifications.RecordTypeId= SObjectType.Notifications__c.getRecordTypeInfosByDeveloperName().get('Alerts').getRecordTypeId(); 
        insert testNotifications;
        BCAPP_HandleNotificatoins instance=new BCAPP_HandleNotificatoins();
        map<string,string> mapRequest=new map<string,string>();
        mapRequest.put('accountId',accountRecord.id);
        
        instance.getAlerts((mapRequest));
        
    }
    
    
    
    
}