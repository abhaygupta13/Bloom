@IsTest
private class IntegrationRecordServiceTest {
    
    @IsTest
    static void testSingletonInstance() {
        // Verify that getInstance() returns the same object (singleton behavior)
        IntegrationRecordService instance1 = IntegrationRecordService.getInstance();
        IntegrationRecordService instance2 = IntegrationRecordService.getInstance();
        System.assertEquals(instance1, instance2, 'Both instances should be same for singleton pattern');
    }

    @IsTest
    static void testInsertIntegrationRecords() {
        IntegrationRecordService service = IntegrationRecordService.getInstance();
        
        // Create sample records
        List<IntegrationRecord__c> records = new List<IntegrationRecord__c>();
        records.add(new IntegrationRecord__c(
            Action__c = 'Update',
            ObjectAPIName__c = 'Account',
            Param1__c = 'Value1'
        ));

        Test.startTest();
        List<IntegrationRecord__c> insertedRecords = service.insertIntegrationRecords(records);
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM IntegrationRecord__c], '1 record should be inserted');
        System.assertNotEquals(null, insertedRecords[0].Id, 'Inserted record should have Id');
    }

    @IsTest
    static void testInsertIntegrationRecordsWithEmptyList() {
        IntegrationRecordService service = IntegrationRecordService.getInstance();
        List<IntegrationRecord__c> emptyList = new List<IntegrationRecord__c>();

        // Should not throw error or insert anything
        Test.startTest();
        List<IntegrationRecord__c> result = service.insertIntegrationRecords(emptyList);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM IntegrationRecord__c], 'No records should be inserted');
        System.assertEquals(0, result.size(), 'Returned list should be empty');
    }

    @IsTest
    static void testGetIntegrationRecord_WithDirectParams() {
        IntegrationRecordService service = IntegrationRecordService.getInstance();

        Test.startTest();
        IntegrationRecord__c record = service.getIntegrationRecord(
            'Create', 'Account', '001XXXX', 
            'P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7', 'P8', 'P9', 'P10', 
            'P11', 'P12', 'P13', 'P14', 'P15', 'P16', 'P17', 'P18'
        );
        Test.stopTest();

        System.assertEquals('Create', record.Action__c);
        System.assertEquals('Account', record.ObjectAPIName__c);
        System.assertEquals('001XXXX', record.RecordId__c);
        System.assertEquals('P1', record.Param1__c);
        System.assertEquals('P18', record.Param18__c);
    }

    @IsTest
    static void testGetIntegrationRecord_WithMapParams() {
        IntegrationRecordService service = IntegrationRecordService.getInstance();

        Map<String, String> paramMap = new Map<String, String>{
            'Param1' => 'Value1',
            'Param5' => 'Value5',
            'Param20' => 'Value20'
        };

        Test.startTest();
        IntegrationRecord__c record = service.getIntegrationRecord('Update', 'Contact', '003XXXX', paramMap);
        Test.stopTest();

        System.assertEquals('Update', record.Action__c);
        System.assertEquals('Contact', record.ObjectAPIName__c);
        System.assertEquals('003XXXX', record.RecordId__c);
        System.assertEquals('Value1', record.Param1__c);
        System.assertEquals('Value5', record.Param5__c);
        System.assertEquals('Value20', record.Param20__c);
    }

    @IsTest
    static void testGetIntegrationRecord_WithExtendedParams() {
        IntegrationRecordService service = IntegrationRecordService.getInstance();

        Map<String, String> paramMap = new Map<String, String>{
            'Param1' => 'Test1',
            'Param10' => 'Test10',
            'Param34' => 'Test34'
        };

        Test.startTest();
        IntegrationRecord__c record = service.getIntegrationRecord(
            'IntegrationType', 'Delete', 'SubActionA', 'Admin', 'Lead', '00QXXXX', paramMap
        );
        Test.stopTest();

        System.assertEquals('IntegrationType', record.Type__c);
        System.assertEquals('Delete', record.Action__c);
        System.assertEquals('SubActionA', record.SubAction__c);
        System.assertEquals('Admin', record.userType__c);
        System.assertEquals('Lead', record.ObjectAPIName__c);
        System.assertEquals('00QXXXX', record.RecordId__c);
        System.assertEquals('Test1', record.Param1__c);
        System.assertEquals('Test34', record.Param34__c);
    }
}