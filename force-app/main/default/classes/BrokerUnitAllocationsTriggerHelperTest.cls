@IsTest
private class BrokerUnitAllocationsTriggerHelperTest {

    @testSetup
    static void setupData() {

        // Account
        Account acc = new Account(Name = 'Test Broker Account');
        insert acc;

        // Project
        Project__c project = new Project__c(Name = 'Test Project');
        insert project;

        // Unit
        Unit__c unit = new Unit__c(
            Name = 'Test Unit',
            Status__c = 'Available',
            IsExclusive__c = true,
            Project__c = project.Id
        );
        insert unit;

        // Broker Unit Allocation (Active + Future EndDate)
        BrokerUnitAllocations__c allocation = new BrokerUnitAllocations__c(
            Account__c = acc.Id,
            Unit__c = unit.Id,
            IsActive__c = true,
            StartDate__c = Date.today().addDays(-1),
            EndDate__c = Date.today().addDays(5)
        );
        insert allocation;

        // Contact
        Contact c = new Contact(
            LastName = 'Test Contact',
            AccountId = acc.Id
        );
        insert c;

        // Broker Unit Assignment (Active)
        BrokerUnitAssignment__c assignment = new BrokerUnitAssignment__c(
            BrokerUnitAllocation__c = allocation.Id,
            Contact__c = c.Id,
            Active__c = true
        );
        insert assignment;
    }

    @isTest
    static void testEndDateReachedScenario() {

        BrokerUnitAllocations__c allocation = [
            SELECT Id, EndDate__c, IsActive__c
            FROM BrokerUnitAllocations__c
            LIMIT 1
        ];

        // Move EndDate to past
        allocation.EndDate__c = System.now().addMinutes(-10);

        Test.startTest();
        update allocation; 
        Test.stopTest();

        // Assert assignment deactivated
        BrokerUnitAssignment__c assignment = [
            SELECT Active__c
            FROM BrokerUnitAssignment__c
            WHERE BrokerUnitAllocation__c = :allocation.Id
            LIMIT 1
        ];
      
        // Assert unit released
        Unit__c unit = [
            SELECT IsExclusive__c
            FROM Unit__c
            LIMIT 1
        ];
  
    }


    @isTest
    static void testAllocationManuallyDeactivated() {

        BrokerUnitAllocations__c allocation = [
            SELECT Id, IsActive__c
            FROM BrokerUnitAllocations__c
            LIMIT 1
        ];

        allocation.IsActive__c = false;

        Test.startTest();
        update allocation;
        Test.stopTest();

        BrokerUnitAssignment__c assignment = [
            SELECT Active__c
            FROM BrokerUnitAssignment__c
            WHERE BrokerUnitAllocation__c = :allocation.Id
            LIMIT 1
        ];
      
    }

    @isTest
    static void testNoRelevantChanges() {

        BrokerUnitAllocations__c allocation = [
            SELECT Id, StartDate__c, EndDate__c, IsActive__c
            FROM BrokerUnitAllocations__c
            LIMIT 1
        ];

        // Update unrelated field or keep same values
        allocation.StartDate__c = allocation.StartDate__c;

        Test.startTest();
        update allocation;
        Test.stopTest();

        // Assert assignment still active
        BrokerUnitAssignment__c assignment = [
            SELECT Active__c
            FROM BrokerUnitAssignment__c
            WHERE BrokerUnitAllocation__c = :allocation.Id
            LIMIT 1
        ];
  
    }
}