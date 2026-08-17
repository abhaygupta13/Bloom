@isTest
private class BrokerUnitAllocationServiceTest {

    // === Helper: Create Account ===
    private static Account createAccount(String name) {
        Account acc = new Account(Name = name);
        insert acc;
        return acc;
    }

    // === Helper: Create Project ===
    private static Project__c createProject(String name, Boolean isActive, Boolean isPublic, Boolean isAvailable) {
        Date today = System.today();
        Project__c proj = new Project__c(
            Name = name,
            IsPublic__c = isPublic,
            IsAvailableForBroker__c = isAvailable,
            StartDate__c = today.addDays(-2),
            EndDate__c = today.addDays(5)
        );
        insert proj;
        return proj;
    }

    // === Helper: Create Unit ===
    private static Unit__c createUnit(Project__c proj, Boolean isActive, Boolean isExclusive, String status, Boolean isPublic) {
        Date today = System.today();
        Unit__c unit = new Unit__c(
            Name = proj.Name + '-Unit',
            Project__c = proj.Id,
            UnitType__c = 'Apartment',
            IsExclusive__c = isExclusive,
            Direct_Indirect__c = 'Indirect',
            Status__c = status,
            StartDate__c = today.addDays(-1),
            EndDate__c = today.addDays(10),
            IsPublic__c = isPublic
        );
        insert unit;
        return unit;
    }

    // === Helper: Create BrokerUnitAllocation ===
    private static BrokerUnitAllocations__c createAllocation(Account acc, Unit__c unit) {
        BrokerUnitAllocations__c alloc = new BrokerUnitAllocations__c(
            Account__c = acc.Id,
            Unit__c = unit.Id
        );
        insert alloc;
        return alloc;
    }

    @isTest
    static void test_getInstance() {
        Test.startTest();
        BrokerUnitAllocationService.getInstance();
        Test.stopTest();
    }

    @isTest
    static void test_getProjectsForAccount() {
        Account acc = createAccount('Agency Alpha');

        // --- Create Active Project with Allocations ---
        Project__c activeProj = createProject('Project Alpha', true, false, true);
        Unit__c activeUnit = createUnit(activeProj, true, true, 'Available', false);
        createAllocation(acc, activeUnit);

        // --- Public Project without Allocations ---
        Project__c pubProj = createProject('Public Project', true, true, true);
        createUnit(pubProj, true, false, 'Available', true);

        Test.startTest();
        BrokerUnitAllocationService.getProjectsForAccount(acc.Id);
        BrokerUnitAllocationService.getProjectsForAccount(null);
        Test.stopTest();
    }

    @isTest
    static void test_getUnitCounts() {
        Account acc = createAccount('Count Test Agency');
        Project__c proj = createProject('Count Project', true, false, true);
        Unit__c u1 = createUnit(proj, true, true, 'Available', false);
        createAllocation(acc, u1);

        Set<Id> projectIds = new Set<Id>{ proj.Id };

        Test.startTest();
        BrokerUnitAllocationService.getUnitCounts(projectIds, acc.Id);
        BrokerUnitAllocationService.getUnitCounts(new Set<Id>(), acc.Id);
        BrokerUnitAllocationService.getUnitCounts(projectIds, null);
        Test.stopTest();
    }

    @isTest
    static void test_getUnitTypes() {
        Account acc = createAccount('Type Test Agency');
        Project__c proj = createProject('Type Project', true, false, true);
        Unit__c u1 = createUnit(proj, true, true, 'Available', false);
        createAllocation(acc, u1);

        Set<Id> projectIds = new Set<Id>{ proj.Id };

        Test.startTest();
        BrokerUnitAllocationService.getUnitTypes(projectIds, acc.Id);
        BrokerUnitAllocationService.getUnitTypes(new Set<Id>(), acc.Id);
        BrokerUnitAllocationService.getUnitTypes(projectIds, null);
        Test.stopTest();
    }

    @isTest
    static void test_getAssignedProjectIds() {
        Account acc = createAccount('Assigned Agency');
        Project__c proj = createProject('Assigned Project', true, false, true);
        Unit__c u1 = createUnit(proj, true, true, 'Available', false);
        createAllocation(acc, u1);

        Test.startTest();
        BrokerUnitAllocationService.getInstance().getAssignedProjectIds(acc.Id);
        BrokerUnitAllocationService.getInstance().getAssignedProjectIds(null);
        Test.stopTest();
    }
    
    @isTest
    static void test_getAllocationsWithAccount() {
        // --- Test Data ---
        Account acc = createAccount('Allocation Account');
        Project__c proj = createProject('Allocation Project', true, false, true);
        Unit__c unit = createUnit(proj, true, true, 'Available', false);
        
        // Allocation WITH Account
        BrokerUnitAllocations__c allocWithAcc = new BrokerUnitAllocations__c(
            Account__c = acc.Id,
            Unit__c = unit.Id
        );
        insert allocWithAcc;
        
        // Allocation WITHOUT Account
        BrokerUnitAllocations__c allocWithoutAcc = new BrokerUnitAllocations__c(
            Unit__c = unit.Id
        );
        insert allocWithoutAcc;
        
        Set<Id> allocationIds = new Set<Id>{
            allocWithAcc.Id,
                allocWithoutAcc.Id
                };
                    
                    // --- Execute ---
                    Test.startTest();
        Map<Id, BrokerUnitAllocations__c> result = BrokerUnitAllocationService.getInstance().getAllocationsWithAccount(allocationIds);
        Test.stopTest();
    }
    
    @isTest
static void test_getUnitTypes_singleMethod_formulaDriven() {

    // Account
    Account acc = new Account(Name = 'Formula Account');
    insert acc;

    // Active Project
     Project__c proj = createProject('UnitType Project', true, false, true);

    // Unit - IsActive__c derived from dates (FORMULA)
    Unit__c unit = new Unit__c(
        Name = 'Formula Unit',
        Project__c = proj.Id,
        UnitType__c = 'Apartment',
        IsExclusive__c = true,
        Direct_Indirect__c = 'Indirect',
        Status__c = 'Available',

        // These fields drive IsActive__c formula
        StartDate__c = System.today().addDays(-1), // <= TODAY
        EndDate__c = System.today().addDays(5),    // >= TODAY

        IsPublic__c = false
    );
    insert unit;

    // Allocation (dates optional but aligned)
    BrokerUnitAllocations__c alloc = new BrokerUnitAllocations__c(
        Account__c = acc.Id,
        Unit__c = unit.Id,
        StartDate__c = System.today().addDays(-1),
        EndDate__c = System.today().addDays(2)
    );
    insert alloc;

    Set<Id> projectIds = new Set<Id>{ proj.Id };

    Test.startTest();
    BrokerUnitAllocationService.getUnitTypes(projectIds, acc.Id);
    BrokerUnitAllocationService.getUnitTypes(null, acc.Id);
    BrokerUnitAllocationService.getUnitTypes(new Set<Id>(), acc.Id);
    BrokerUnitAllocationService.getUnitTypes(projectIds, null);
    Test.stopTest();
}

}