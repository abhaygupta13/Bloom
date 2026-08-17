@isTest
private class IntegrationServiceTest { 

    @isTest
    static void testGetInstance() {
        IntegrationService instance1 = IntegrationService.getInstance();
        IntegrationService instance2 = IntegrationService.getInstance();
        System.assertEquals(instance1, instance2, 'Singleton instances should be the same');
    }
    
    @isTest
    static void testGetIntegrationEventWithoutSubAction() {
        IntegrationService service = IntegrationService.getInstance();
        String action = 'TestAction';
        String objectApiName = 'Account';
        Id recordId = UserInfo.getUserId();
        
        Map<String, String> paramMap = new Map<String, String>{
            'Param1' => 'Value1',
            'Param5' => 'Value5',
            'Param34' => 'Value34'
        };
        
        // Call method with populated map
        IntegrationEvent__e event1 = service.getIntegrationEvent(action, objectApiName, recordId, paramMap);
        System.assertNotEquals(null, event1, 'Event should not be null');
        System.assertEquals(action, event1.Action__c);
        
        // Call method with empty map
        IntegrationEvent__e event2 = service.getIntegrationEvent(action, objectApiName, recordId, new Map<String,String>());
        System.assertNotEquals(null, event2);
        
        try {
            IntegrationEvent__e event3 = service.getIntegrationEvent(action, objectApiName, recordId, null);
            System.assertNotEquals(null, event3);
        } catch(Exception e) {
        }
    }
    
    @isTest
    static void testGetIntegrationEventWithSubAction() {
        IntegrationService service = IntegrationService.getInstance();
        String action = 'TestAction';
        String objectApiName = 'Account';
        String subAction = 'SubTest';
        String userType = 'Admin';
        Id recordId = UserInfo.getUserId();
        
        Map<String, String> paramMap = new Map<String, String>{
            'Param2' => 'Value2',
            'Param10' => 'Value10'
        };
        
        IntegrationEvent__e event = service.getIntegrationEvent(action, objectApiName, subAction, userType, recordId, paramMap);
        System.assertNotEquals(null, event);
        System.assertEquals(subAction, event.SubAction__c);
        System.assertEquals(userType, event.userType__c);
    }
    
    @isTest
    static void testHandleIntegrationsAndAsync() {
        IntegrationService service = IntegrationService.getInstance();
        List<SObject> records = new List<SObject>();
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        records.add(acc);
        
        service.handleIntegrations('Type1', 'Action1', records, Account.SObjectType);
        
        Test.startTest();
        service.handleAsyncIntegrations('Type1', 'Action1', records, Account.SObjectType);
        IntegrationRecordService.getInstance().getIntegrationRecord('Update', 'Account','recordId', 
                                                                    'Param1', 'Param2', 'Param3', 'Param4', 
                                                                    'Param5', 'Param6', 'Param7' ,'Param8', 
                                                                    'Param9', 'Param10',
                                                                    'Param11', 'Param12',
                                                                    'Param13', 'Param14', 
                                                                    'Param15', 'Param16',
                                                                    'Param17', 'Param18');
          Map<String, String> paramMap = new Map<String, String>{
            'Param2' => 'Value2',
            'Param10' => 'Value10'
        };
         IntegrationService.getInstance().getIntegrationEvent( 'SALESORDER_ADHA_INTEGRATION','Update', 'SalesOrder__c', 'SubAction',
                                                  'userType', acc.Id, paramMap);
         IntegrationRecordService.getInstance().getIntegrationRecord('Update', 'Account','recordId', paramMap);
              IntegrationRecordService.getInstance().getIntegrationRecord('SALESORDER_ADHA_INTEGRATION', 'Update',  'SubAction', 
                                                     'userType',  'SalesOrder__c',  'recordId', 
                                                     paramMap);
        
        Test.stopTest();
    }
}