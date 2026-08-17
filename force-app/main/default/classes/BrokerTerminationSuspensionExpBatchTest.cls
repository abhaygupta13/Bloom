@isTest
private class BrokerTerminationSuspensionExpBatchTest {
    
    @testSetup
    static void createTestData() {
        
        Account acc = new Account(
            Name = 'Test Broker Account'
        );
        insert acc;
    }
    
    @isTest
    static void testBatchExecution() {
        
        Account acc = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Broker Account'
            LIMIT 1
        ];
        
        Id brokerRtId = Schema.SObjectType.Contact
            .getRecordTypeInfosByName()
            .get('Broker')
            .getRecordTypeId();
        
        Contact broker = new Contact(
            FirstName = 'Test',
            LastName = 'Broker1',
            Email = 'broker1@test.com',
            AccountId = acc.Id,
            RecordTypeId = brokerRtId,
            EID_Expiry_Date__c = System.today(),
            PassportExpiryDate__c = System.today().addDays(30),
            IsSuspended__c = false,
            IsActive__c = true
        );
        insert broker;
        
        Test.startTest();
        Database.executeBatch(
            new BrokerTerminationSuspensionExpiryBatch(),
            1
        );
        Test.stopTest();
        
        Contact result = [
            SELECT IsSuspended__c,
            SuspensionStartDate__c
            FROM Contact
            WHERE Id = :broker.Id
        ];
        
        System.assertEquals(true, result.IsSuspended__c);
        System.assertNotEquals(null, result.SuspensionStartDate__c);
    }
    
    @isTest
    static void testAutoReactivate() {
        
        Account acc = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Broker Account'
            LIMIT 1
        ];
        
        Id brokerRtId = Schema.SObjectType.Contact
            .getRecordTypeInfosByName()
            .get('Broker')
            .getRecordTypeId();
        
        Contact broker = new Contact(
            FirstName = 'Test',
            LastName = 'Broker2',
            Email = 'broker2@test.com',
            AccountId = acc.Id,
            RecordTypeId = brokerRtId,
            IsSuspended__c = true,
            IsActive__c = false,
            SuspensionStartDate__c = System.today().addDays(-5),
            SuspensionEndDate__c = System.today(),
            EID_Expiry_Date__c = System.today().addDays(10),
            PassportExpiryDate__c = System.today().addDays(10)
        );
        insert broker;
        
        Test.startTest();
        Database.executeBatch(
            new BrokerTerminationSuspensionExpiryBatch(),
            1
        );
        Test.stopTest();
        
        Contact result = [
            SELECT IsSuspended__c,
            IsActive__c
            FROM Contact
            WHERE Id = :broker.Id
        ];
        
        System.assertEquals(false, result.IsSuspended__c);
        System.assertEquals(true, result.IsActive__c);
    }
}