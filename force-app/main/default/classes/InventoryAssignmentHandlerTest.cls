@IsTest
private class InventoryAssignmentHandlerTest {

    // ------------------------------------------------------
    // Helper: Create Account (Broker_Agency RecordType)
    // ------------------------------------------------------
    private static Account createAgency() {
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Broker_Agency' LIMIT 1];
        Account acc = new Account(
            Name = 'Test Broker Agency',
            RecordTypeId = rt.Id
        );
        insert acc;
        return acc;
    }

    // ------------------------------------------------------
    // Helper: Create Contact (Broker RecordType)
    // ------------------------------------------------------
    private static Contact createBrokerContact(Id accountId) {
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Contact' AND DeveloperName = 'Broker' LIMIT 1];
        Contact con = new Contact(
            LastName = 'Admin Contact',
            AccountId = accountId,
            RecordTypeId = rt.Id,
            Email = 'john.doe@test.com',
            BrokerContactRole__c = 'Admin;SuperAdmin', // multi-select picklist,
            IsActive__c = true
        );
        insert con;
        return con;
    }

    // ------------------------------------------------------
    // Helper: Create Units
    // ------------------------------------------------------
    private static List<Unit__c> createUnits(Integer count) {
        List<Unit__c> units = new List<Unit__c>();
        for (Integer i = 0; i < count; i++) {
            units.add(new Unit__c(
                Name = 'Unit ' + i,
                IsPublic__c = true,
                IsExclusive__c = false
            ));
        }
        insert units;
        return units;
    }

    // ------------------------------------------------------
    // Helper: Create Project
    // ------------------------------------------------------
    private static Project__c createProject() {
        Project__c proj = new Project__c(
            Name = 'Test Project'
        );
        insert proj;
        return proj;
    }

    // ------------------------------------------------------
    // TEST 1: Verify Broker Unit Allocations + Assignments
    // ------------------------------------------------------
    @IsTest
    static void testBrokerUnitAllocations() {
        Account agency = createAgency();
        Contact con = createBrokerContact(agency.Id);
        List<Unit__c> units = createUnits(2);

        InventoryAssignmentHandler.AllocationRequest req = new InventoryAssignmentHandler.AllocationRequest();
        req.agencyId = agency.Id;
        req.unitIds = new List<Id>{ units[0].Id, units[1].Id };
        req.startDate = System.now();
        req.endDate = System.now().addDays(10);

        Test.startTest();
        InventoryAssignmentHandler.createBrokerUnitAllocations(new List<InventoryAssignmentHandler.AllocationRequest>{ req });
        Test.stopTest();

        // --- Assertions ---
        List<BrokerUnitAllocations__c> allocations = [SELECT Id, Unit__c, Account__c FROM BrokerUnitAllocations__c];
        List<Unit__c> updatedUnits = [SELECT IsPublic__c, IsExclusive__c FROM Unit__c WHERE Id IN :req.unitIds];
        List<BrokerUnitAssignment__c> assignments = [SELECT Id, BrokerUnitAllocation__c, Contact__c FROM BrokerUnitAssignment__c];

        System.assertEquals(2, allocations.size(), 'Two allocations should be created.');
        System.assertEquals(2, updatedUnits.size(), 'Two units should be updated.');
        System.assertEquals(true, updatedUnits[0].IsExclusive__c, 'Unit should be marked exclusive.');
        System.assertEquals(false, updatedUnits[0].IsPublic__c, 'Unit should not be public.');
        System.assert(assignments.size() > 0, 'Assignments should be created for contacts.');
    }

    // ------------------------------------------------------
    // TEST 2: Verify Project Agency Allocations
    // ------------------------------------------------------
    @IsTest
    static void testProjectAgencyAllocations() {
        Account agency1 = createAgency();
        Account agency2 = createAgency();
        Project__c project = createProject();

        InventoryAssignmentHandler.AllocationRequest req = new InventoryAssignmentHandler.AllocationRequest();
        req.projectId = project.Id;
        req.agencyIds = new List<Id>{ agency1.Id, agency2.Id };

        Test.startTest();
        InventoryAssignmentHandler.createBrokerUnitAllocations(new List<InventoryAssignmentHandler.AllocationRequest>{ req });
        Test.stopTest();

        List<ProjectAgencyAllocation__c> projectAllocations = [
            SELECT Id, Project__c, Account__c, IsActive__c
            FROM ProjectAgencyAllocation__c
            WHERE Project__c = :project.Id
        ];

        System.assertEquals(2, projectAllocations.size(), 'Two project agency allocations should be created.');
        System.assertEquals(true, projectAllocations[0].IsActive__c, 'Allocations should be active.');
    }

    // ------------------------------------------------------
    // TEST 3: Empty / Null Safety
    // ------------------------------------------------------
    @IsTest
    static void testNullSafety() {
        InventoryAssignmentHandler.AllocationRequest req = new InventoryAssignmentHandler.AllocationRequest();
        Test.startTest();
        InventoryAssignmentHandler.createBrokerUnitAllocations(new List<InventoryAssignmentHandler.AllocationRequest>{ req });
        Test.stopTest();

        System.assertEquals(0, [SELECT count() FROM BrokerUnitAllocations__c], 'No allocations expected.');
        System.assertEquals(0, [SELECT count() FROM ProjectAgencyAllocation__c], 'No project allocations expected.');
    }
}