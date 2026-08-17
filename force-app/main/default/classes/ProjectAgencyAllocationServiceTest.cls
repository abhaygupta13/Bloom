/*
* @Author       : Rushikesh Jadhav
* @CreatedDate  : 26th SEP 2025
* @Description  : Test class for ProjectAgencyAllocationService.
*/
/*****************************************************************************************************
* Version     Author             Date           Comment
* 1.0         Rushikesh Jadhav   26SEP2025      Initial draft – unit tests for project agency allocation service
*****************************************************************************************************/
@IsTest
public class ProjectAgencyAllocationServiceTest {

    // Helper method to create test data
    private static Map<String, SObject> createTestData() {
        Map<String, SObject> data = new Map<String, SObject>();

        // Create Account (Broker Agency)
        Account acc = new Account(Name = 'Test Broker Agency', Phone = '0501234567');
        insert acc;
        data.put('account', acc);

        // Create active Project
        Project__c project = new Project__c(
            Name = 'Test Project',
            //IsActive__c = true,
            IsAvailableForBroker__c = true
        );
        insert project;
        data.put('project', project);

        // Create inactive Project (for negative testing)
        Project__c inactiveProject = new Project__c(
            Name = 'Inactive Project',
            //IsActive__c = false,
            IsAvailableForBroker__c = false
        );
        insert inactiveProject;
        data.put('inactiveProject', inactiveProject);

        // Create active ProjectAgencyAllocation
        ProjectAgencyAllocation__c activeAlloc = new ProjectAgencyAllocation__c(
            Account__c = acc.Id,
            Project__c = project.Id,
            IsActive__c = true
        );
        insert activeAlloc;
        data.put('activeAlloc', activeAlloc);

        // Create inactive ProjectAgencyAllocation
        ProjectAgencyAllocation__c inactiveAlloc = new ProjectAgencyAllocation__c(
            Account__c = acc.Id,
            Project__c = inactiveProject.Id,
            IsActive__c = false
        );
        insert inactiveAlloc;
        data.put('inactiveAlloc', inactiveAlloc);

        // Create Unit and BrokerUnitAllocation for assigned project test
        Unit__c unit = new Unit__c(
            Name = 'Unit A-101',
            Project__c = project.Id,
            //IsActive__c = true,
            Status__c = 'Available'
        );
        insert unit;
        data.put('unit', unit);

        BrokerUnitAllocations__c brokerAlloc = new BrokerUnitAllocations__c(
            Account__c = acc.Id,
            Unit__c = unit.Id
        );
        insert brokerAlloc;
        data.put('brokerAlloc', brokerAlloc);

        return data;
    }

    // Test getAllocationsByAccount()
    @IsTest
    static void testGetAllocationsByAccount() {
        Map<String, SObject> data = createTestData();
        Account acc = (Account) data.get('account');

        Test.startTest();
        ProjectAgencyAllocationService service = ProjectAgencyAllocationService.getInstance();

        // Valid account should return 1 active allocation
        List<ProjectAgencyAllocation__c> allocations = service.getAllocationsByAccount(acc.Id);
        Test.stopTest();

        System.assertNotEquals(null, allocations, 'List should not be null');
        System.assertEquals(1, allocations.size(), 'Should return only 1 active allocation');
        System.assertEquals('Test Project', allocations[0].Project__r.Name);
    }

    // Test getAllocationsByAccount() with null Id
    @IsTest
    static void testGetAllocationsByAccount_NullId() {
        Test.startTest();
        ProjectAgencyAllocationService service = ProjectAgencyAllocationService.getInstance();
        List<ProjectAgencyAllocation__c> allocations = service.getAllocationsByAccount(null);
        Test.stopTest();

        System.assertEquals(0, allocations.size(), 'Should return empty list when accountId is null');
    }

}