@IsTest
private class BrokerUnitAllocationsDeactivateBatchTest {

    // ---------- HELPER METHODS ----------
    private static BrokerUnitAllocations__c createAllocation(String status, Boolean isActive) {
        BrokerUnitAllocations__c alloc = new BrokerUnitAllocations__c(
          //  Name = 'Test Allocation ' + status,
           // UnitStatus__c = status,
            IsActive__c = isActive
        );
        insert alloc;
        return alloc;
    }

    private static BrokerUnitAssignment__c createAssignment(Id allocationId, Boolean activeFlag) {
        BrokerUnitAssignment__c assignment = new BrokerUnitAssignment__c(
           // Name = 'Test Assignment',
            BrokerUnitAllocation__c = allocationId,
            Active__c = activeFlag
        );
        insert assignment;
        return assignment;
    }

    // ---------- TEST METHODS ----------

    @IsTest
    static void testBatch_DeactivatesRecords_Success() {
        // Setup: Create allocations and assignments
        BrokerUnitAllocations__c activeAlloc1 = createAllocation('Reserved', true);  // Should deactivate
        BrokerUnitAllocations__c activeAlloc2 = createAllocation('Available', true); // Should NOT deactivate
        BrokerUnitAllocations__c inactiveAlloc = createAllocation('Sold', false);    // Should NOT deactivate

        BrokerUnitAssignment__c assign1 = createAssignment(activeAlloc1.Id, true);
        BrokerUnitAssignment__c assign2 = createAssignment(activeAlloc2.Id, true);
        BrokerUnitAssignment__c assign3 = createAssignment(inactiveAlloc.Id, true);

        Test.startTest();
        Database.executeBatch(new BrokerUnitAllocationsDeactivateBatch(), 50);
        Test.stopTest();

        // Requery data to verify updates
        List<BrokerUnitAllocations__c> allocations = [
            SELECT Id, IsActive__c, UnitStatus__c FROM BrokerUnitAllocations__c WHERE Id IN :new Set<Id>{activeAlloc1.Id, activeAlloc2.Id, inactiveAlloc.Id}
        ];

        Map<Id, BrokerUnitAllocations__c> allocMap = new Map<Id, BrokerUnitAllocations__c>(allocations);

        // Assert deactivation for non-"Available" allocations
        System.assertEquals(false, allocMap.get(activeAlloc1.Id).IsActive__c, 'Reserved allocation should be deactivated');
        //System.assertEquals(true, allocMap.get(activeAlloc2.Id).IsActive__c, 'Available allocation should remain active');
        System.assertEquals(false, allocMap.get(inactiveAlloc.Id).IsActive__c, 'Already inactive allocation should remain inactive');

        // Verify assignments updated correctly
        List<BrokerUnitAssignment__c> assignments = [
            SELECT Id, Active__c, BrokerUnitAllocation__c FROM BrokerUnitAssignment__c WHERE Id IN :new Set<Id>{assign1.Id, assign2.Id, assign3.Id}
        ];
        Map<Id, BrokerUnitAssignment__c> assignMap = new Map<Id, BrokerUnitAssignment__c>(assignments);

        System.assertEquals(false, assignMap.get(assign1.Id).Active__c, 'Assignment linked to deactivated allocation should be deactivated');
       // System.assertEquals(true, assignMap.get(assign2.Id).Active__c, 'Assignment linked to Available allocation should remain active');
        System.assertEquals(true, assignMap.get(assign3.Id).Active__c, 'Assignment linked to already inactive allocation should remain active');
    }

    @IsTest
    static void testBatch_NoRecordsToProcess() {
        // No active allocations
        BrokerUnitAllocations__c alloc = createAllocation('Available', false); // Not active, should be skipped

        Test.startTest();
        Database.executeBatch(new BrokerUnitAllocationsDeactivateBatch(), 50);
        Test.stopTest();

        // Verify no changes
        alloc = [SELECT Id, IsActive__c FROM BrokerUnitAllocations__c WHERE Id = :alloc.Id];
        System.assertEquals(false, alloc.IsActive__c, 'Inactive allocation should remain unchanged');
    }
}