@IsTest
private class BrokerUnitAssignmentExpiryBatchTest {
    
    @IsTest
    static void test_BrokerUnitAssignmentExpiryBatch_Success() {
        Date today = System.today();
        
        // ===== Create Base Data =====
        Account acc = createAccount('Test Account');
        Contact con = createContact(acc, 'Agent', true, 'Agent Contact');
        
        // === Project ===
        Project__c proj = new Project__c(
            Name = 'Test Project',
            IsPublic__c = false,
            IsAvailableForBroker__c = true,
            StartDate__c = today.addDays(-5),
            EndDate__c = today.addDays(10)
        );
        insert proj;
        
        // === Unit ===
        Unit__c unit = new Unit__c(
            Name = 'Unit-Test',
            Project__c = proj.Id,
            UnitType__c = 'Apartment',
            Status__c = 'Available',
            StartDate__c = today.addDays(-5),
            EndDate__c = today.addDays(10),
            IsExclusive__c = true,
            Direct_Indirect__c = 'Indirect'
        );
        insert unit;
        
        // === Broker Unit Allocation ===
        BrokerUnitAllocations__c bua = new BrokerUnitAllocations__c(
            Account__c = acc.Id,
            Unit__c = unit.Id
        );
        insert bua;
        
        // === Expired Assignment ===
        BrokerUnitAssignment__c expiredAssign = new BrokerUnitAssignment__c(
            BrokerUnitAllocation__c = bua.Id,
            Active__c = true,
            ExpiryDate__c = today.addDays(-1)
        );
        insert expiredAssign;
        
        // === Non-expired Assignment (should remain Active) ===
        BrokerUnitAssignment__c activeAssign = new BrokerUnitAssignment__c(
            BrokerUnitAllocation__c = bua.Id,
            Active__c = true,
            ExpiryDate__c = today.addDays(5)
        );
        insert activeAssign;
        
        // ===== Run Batch =====
        Test.startTest();
        Database.executeBatch(new BrokerUnitAssignmentExpiryBatch(), 200);
        Test.stopTest();        
    }
    
    // Helper methods (copied from reference test class)
    private static Account createAccount(String name) {
        Account acc = new Account(
            Name = name,
            AddressLine01__c = 'Address Line 1',
            AddressLine02__c = 'Address Line 2',
            RecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, 'Broker_Agency')
        );
        insert acc;
        return acc;
    }
    
    private static Contact createContact(Account acc, String role, Boolean isActive, String lastName) {
        Contact con = new Contact(
            LastName = lastName,
            AccountId = acc.Id,
            BrokerContactRole__c = role,
            IsActive__c = isActive,
            RecordTypeId = Utility.getRecordTypeIdByDevName(Contact.SObjectType, 'Broker')
        );
        insert con;
        return con;
    }
}