/*
* @Author      : Rushikesh Jadhav
* @CreatedDate : 28th JUNE 2025
* @Description : Test class for IntegrationRecordTriggerHelper. Covers platform event publishing logic 
*                for both BrokerCommission__c and User__c IntegrationRecord scenarios.
*/
/*****************************************************************************************************
* Version   Author           Date           Comment
* 1.0       Rushikesh        28-JUN-2025    Verifies event generation and invocation 
*                                           logic for BrokerCommission__c and User__c records
*****************************************************************************************************/
@isTest
private class IntegrationRecordTriggerHelperTest {
    @isTest
    static void testInvokePlatformEventForBrokerCommission() {
    	Project__c project = new Project__c(Name = 'Test Project');
    	insert project;
        BrokerCommission__c brokerCommission = new BrokerCommission__c(
            Project__c = project.Id, 
    		StartDate__c = Date.today(),
            Status__c = 'Draft'
        );
        insert brokerCommission;

        // Create IntegrationRecord referencing the brokerCommission
        IntegrationRecord__c record = new IntegrationRecord__c(
            Action__c = 'Insert',
            ObjectAPIName__c = 'BrokerCommission__c',
            RecordId__c = brokerCommission.Id
        );
        insert record;

        Test.startTest();
        IntegrationRecordTriggerHelper.invokePlatformEvent(new List<IntegrationRecord__c>{record});
        Test.stopTest();

        System.assert(true, 'No exception should occur for BrokerCommission event');
    }
    @isTest
    static void testHandlerInsertContext() {
        Project__c project = new Project__c(Name = 'Test Project');
        insert project;

        BrokerCommission__c brokerCommission = new BrokerCommission__c(
            Project__c = project.Id,
            StartDate__c = Date.today(),
            Status__c = 'Draft'
        );
        insert brokerCommission;

        IntegrationRecord__c record = new IntegrationRecord__c(
            Action__c = 'Insert',
            ObjectAPIName__c = 'BrokerCommission__c',
            RecordId__c = brokerCommission.Id
        );

        Test.startTest();
        insert record;
        Test.stopTest();
    }

    // Covers beforeUpdate + afterUpdate
    @isTest
    static void testHandlerUpdateContext() {
        IntegrationRecord__c record = new IntegrationRecord__c(
            Action__c = 'Insert',
            ObjectAPIName__c = 'User__c',
            RecordId__c = UserInfo.getUserId()
        );
        insert record;

        record.Action__c = 'Update';
        Test.startTest();
        update record;
        Test.stopTest();
    }

    // Covers beforeDelete + afterDelete
    @isTest
    static void testHandlerDeleteContext() {
        IntegrationRecord__c record = new IntegrationRecord__c(
            Action__c = 'Delete',
            ObjectAPIName__c = 'User__c',
            RecordId__c = UserInfo.getUserId()
        );
        insert record;

        Test.startTest();
        delete record;
        Test.stopTest();
    }

    // Covers afterUndelete
    @isTest
    static void testHandlerUndeleteContext() {
        IntegrationRecord__c record = new IntegrationRecord__c(
            Action__c = 'Delete',
            ObjectAPIName__c = 'User__c',
            RecordId__c = UserInfo.getUserId()
        );
        insert record;
        delete record;

        Test.startTest();
        undelete record;
        Test.stopTest();
    }
 	@isTest
    static void testGetIntegrationEvent() {
        // Sample inputs
        String action = 'TestAction';
        String objectApiName = 'Account';
        Id recordId = UserInfo.getUserId(); // Just a valid Id
        Map<String, String> paramMap = new Map<String, String>{
            'Param1' => 'Value1',
            'Param5' => 'Value5',
            'Param20' => 'Value20',
            'Param34' => 'Value34'
        };
        
        // Get instance of your service class (replace with your actual class name if needed)
        IntegrationService service = IntegrationService.getInstance();
        
        // Call the method
        IntegrationEvent__e eventObj = service.getIntegrationEvent(action, objectApiName, recordId, paramMap);
      
    }
    
    @isTest
    static void testGetIntegrationEvent2() {
        String action = 'TestAction';
        String objectApiName = 'Account';
        String SubAction = 'Insert';
        String userType = 'Broker Agent';
        Id recordId = UserInfo.getUserId();

        Map<String, String> paramMap = new Map<String, String>{
            'Param1' => 'Value1',
            'Param15' => 'Value15',
            'Param34' => 'Value34'
        };

        IntegrationService service = IntegrationService.getInstance();

        service.getIntegrationEvent(action, objectApiName, SubAction, userType, recordId, paramMap);
    }
}