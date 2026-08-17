@IsTest
public class BrokerUnitAllocationExpiryBatchTest {
    
    @IsTest
    static void test_BrokerUnitAllocationExpiryBatch_Success() {
        Date today = System.today();
        DateTime now = DateTime.now();
        
        // ===== Create Base Data =====
        Account acc = createAccount('Test Account');
        Contact con = createContact(acc, 'Agent', true, 'Agent Contact');
        
        // === Project ===
        Project__c proj = new Project__c(
            Name = 'Expiry Batch Project',
            IsPublic__c = false,
            IsAvailableForBroker__c = true,
            StartDate__c = today.addDays(-10),
            EndDate__c = today.addDays(10)
        );
        insert proj;
        
        // === Unit ===
        Unit__c unit = new Unit__c(
            Name = 'Exclusive Unit',
            Project__c = proj.Id,
            UnitType__c = 'Apartment',
            Status__c = 'Available',
            StartDate__c = today.addDays(-10),
            EndDate__c = today.addDays(10),
            IsExclusive__c = true,
            Direct_Indirect__c = 'Indirect'
        );
        insert unit;
        
        // === Expired Broker Unit Allocation ===
        BrokerUnitAllocations__c expiredAlloc = new BrokerUnitAllocations__c(
            Account__c = acc.Id,
            Unit__c = unit.Id,
            IsActive__c = true,
            EndDate__c = now.addDays(-1)
        );
        insert expiredAlloc;
        
        // === Active (non-expired) Allocation ===
        BrokerUnitAllocations__c activeAlloc = new BrokerUnitAllocations__c(
            Account__c = acc.Id,
            Unit__c = unit.Id,
            IsActive__c = true,
            EndDate__c = now.addDays(5)
        );
        insert activeAlloc;
        
        // === BrokerUnitAssignments related to expired allocation ===
        BrokerUnitAssignment__c expiredAssignment = new BrokerUnitAssignment__c(
            BrokerUnitAllocation__c = expiredAlloc.Id,
            Active__c = true,
            ExpiryDate__c = today.addDays(5)
        );
        insert expiredAssignment;
        
        // === Assignment related to non-expired allocation ===
        BrokerUnitAssignment__c activeAssignment = new BrokerUnitAssignment__c(
            BrokerUnitAllocation__c = activeAlloc.Id,
            Active__c = true,
            ExpiryDate__c = today.addDays(5)
        );
        insert activeAssignment;
        
        // ===== Execute the Batch =====
        Test.startTest();
        Database.executeBatch(new BrokerUnitAllocationExpiryBatch(), 200);
        Test.stopTest();
    }
    
    
    // ===== Optional: Empty scenario for full coverage =====
    @IsTest
    static void test_BrokerUnitAllocationExpiryBatch_NoRecords() {
        Test.startTest();
        Database.executeBatch(new BrokerUnitAllocationExpiryBatch(), 200);
        Test.stopTest();
    }
    
    
    // ===== Helper Methods (from your existing test structure) =====
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
            RecordTypeId = Utility.getRecordTypeIdByDevName(Contact.SObjectType, 'Broker'),
            Email = 'test@test.com'
        );
        insert con;
        return con;
    }
}