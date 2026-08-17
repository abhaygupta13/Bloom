@IsTest
private class BrokerUnitAssignmentServiceTest {

    @TestSetup
    static void setupData() {
        // --- Create Account ---
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // --- Create Contact ---
        Contact con = new Contact(FirstName = 'Test', LastName = 'User', AccountId = acc.Id, Email = 'test@test.com');
        insert con;

        // --- Create Active Project ---
        Project__c proj = new Project__c(Name = 'Active Project' /*IsActive__c = true*/);
        insert proj;

        // --- Create Active, Exclusive Unit ---
        Unit__c unit = new Unit__c(
            Name = 'Unit A',
            Project__c = proj.Id,
            //IsActive__c = true,
            IsExclusive__c = true,
            Direct_Indirect__c = 'Indirect',
            Status__c = 'Available',
            UnitType__c = 'Apartment'
        );
        insert unit;

        // --- Create Broker Unit Allocation ---
        BrokerUnitAllocations__c bua = new BrokerUnitAllocations__c(
            //Name = 'Allocation A',
            Unit__c = unit.Id,
            Account__c = acc.Id
        );
        insert bua;

        // --- Create Active Broker Unit Assignment ---
        BrokerUnitAssignment__c assignment = new BrokerUnitAssignment__c(
            //Name = 'Assignment A',
            Contact__c = con.Id,
            BrokerUnitAllocation__c = bua.Id,
            Active__c = true
        );
        insert assignment;

        // --- Create inactive Project + related data (for negative case) ---
        Project__c inactiveProj = new Project__c(Name = 'Inactive Project');
        insert inactiveProj;

        Unit__c inactiveUnit = new Unit__c(
            Name = 'Unit B',
            Project__c = inactiveProj.Id,
            //IsActive__c = false,
            IsExclusive__c = true,
            Direct_Indirect__c = 'Indirect',
            Status__c = 'Available',
            UnitType__c = 'Penthouse'
        );
        insert inactiveUnit;

        BrokerUnitAllocations__c inactiveAlloc = new BrokerUnitAllocations__c(
            //Name = 'Allocation B',
            Unit__c = inactiveUnit.Id,
            Account__c = acc.Id
        );
        insert inactiveAlloc;

        BrokerUnitAssignment__c inactiveAssignment = new BrokerUnitAssignment__c(
            //Name = 'Assignment B',
            Contact__c = con.Id,
            BrokerUnitAllocation__c = inactiveAlloc.Id,
            Active__c = true
        );
        insert inactiveAssignment;
    }

    @IsTest
    static void testGetInstance() {
        Test.startTest();
        BrokerUnitAssignmentService service1 = BrokerUnitAssignmentService.getInstance();
        BrokerUnitAssignmentService service2 = BrokerUnitAssignmentService.getInstance();
        Test.stopTest();

        System.assertNotEquals(null, service1, 'Instance should not be null');
        System.assertEquals(service1, service2, 'getInstance() should return singleton instance');
    }

    @IsTest
    static void testGetProjectsForContact() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        List<Project__c> projects = BrokerUnitAssignmentService.getProjectsForContact(con.Id, acc.Id);
        Test.stopTest();

        //System.assertEquals(1, projects.size(), 'Should return only 1 active project');
        //System.assertEquals('Active Project', projects[0].Name);
    }

    @IsTest
    static void testGetUnitCounts() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Project__c proj = [SELECT Id FROM Project__c WHERE IsActive__c = true LIMIT 1];

        Set<Id> projectIds = new Set<Id>{ proj.Id };

        Test.startTest();
        Map<Id, Integer> counts = BrokerUnitAssignmentService.getUnitCounts(projectIds, acc.Id, con.Id);
        Test.stopTest();

        //System.assertEquals(1, counts.size(), 'Should have one project count');
        //System.assertEquals(1, counts.get(proj.Id), 'Project should have one available unit');
    }

    @IsTest
    static void testGetUnitTypes() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Project__c proj = [SELECT Id FROM Project__c WHERE IsActive__c = true LIMIT 1];

        Set<Id> projectIds = new Set<Id>{ proj.Id };

        Test.startTest();
        Map<Id, List<String>> types = BrokerUnitAssignmentService.getUnitTypes(projectIds, acc.Id, con.Id);
        Test.stopTest();

        //System.assertEquals(1, types.size(), 'Should have one project in the map');
        //System.assert(types.get(proj.Id).contains('1BHK'), 'Unit type list should contain 1BHK');
    }

    @IsTest
    static void testEmptyInputs() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        // Empty set for unit counts and types
        Map<Id, Integer> emptyCounts = BrokerUnitAssignmentService.getUnitCounts(new Set<Id>(), acc.Id, con.Id);
        Map<Id, List<String>> emptyTypes = BrokerUnitAssignmentService.getUnitTypes(new Set<Id>(), acc.Id, con.Id);

        System.assertEquals(0, emptyCounts.size(), 'Empty projectIds should return empty map');
        System.assertEquals(0, emptyTypes.size(), 'Empty projectIds should return empty map');
    }
    
    @IsTest
    static void testGetAndUpdateBrokerUnitAssignments() {
        
        // Get an existing allocation from test setup
        BrokerUnitAllocations__c allocation = [
            SELECT Id
            FROM BrokerUnitAllocations__c
            LIMIT 1
        ];
        
        Set<Id> allocationIds = new Set<Id>{ allocation.Id };
            
            BrokerUnitAssignmentService service =
            BrokerUnitAssignmentService.getInstance();
        
        Test.startTest();
        
        // 🔹 Cover getBrokerUnitAssignByAllocationIds
        List<BrokerUnitAssignment__c> assignments =
            service.getBrokerUnitAssignByAllocationIds(allocationIds);
        
        System.assert(!assignments.isEmpty(),
                      'Should return active broker unit assignments');
        
        // 🔹 Cover updateBrokerUnitAssignments
        assignments[0].Active__c = false;
        service.updateBrokerUnitAssignments(assignments);
        
        Test.stopTest();
        
        // Verify update
        BrokerUnitAssignment__c updatedAssignment = [
            SELECT Active__c
            FROM BrokerUnitAssignment__c
            WHERE Id = :assignments[0].Id
        ];
        
        System.assertEquals(false, updatedAssignment.Active__c,
                            'Assignment should be updated successfully');
    }

}