/*
* @Author       : Rushikesh Jadhav
* @CreatedDate  : 26th SEP 2025
* @Description  : Test class for BAPPGetProjectsHandler.
*/
/*****************************************************************************************************
* Version     Author             Date           Comment
* 1.0         Rushikesh Jadhav   26SEP2025      Initial draft – unit tests for BAPPGetProjectsHandler
*****************************************************************************************************/
@IsTest
private class BAPPGetProjectsHandlerTest {
    
    @IsTest
    static void testHandleGetProjects_Success() {
        Date today = Date.today();

        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Project
        Project__c proj1 = new Project__c(
            Name = 'Project 1',
            IsAvailableForBroker__c = true,
            StartDate__c = today.addDays(-1),
            EndDate__c = today.addDays(5)
        );
        insert proj1;

        // Create Project Allocation
        ProjectAgencyAllocation__c paa1 = new ProjectAgencyAllocation__c(
            Account__c = acc.Id, 
            Project__c = proj1.Id,
            IsActive__c = true
        );
        insert paa1;

        // Create Unit (ensure formula IsActive__c evaluates TRUE)
        Unit__c unit1 = new Unit__c(
            Name = 'Unit-1',
            Project__c = proj1.Id,
            Status__c = 'Available',
            StartDate__c = today.addDays(-1),
            EndDate__c = today.addDays(5)
        );
        insert unit1;

        // Create Broker Unit Allocation
        BrokerUnitAllocations__c bua1 = new BrokerUnitAllocations__c(
            Account__c = acc.Id, 
            Unit__c = unit1.Id,
            IsActive__c = true
        );
        insert bua1;

        // Call Handler
        Test.startTest();
        RestContext.response = new RestResponse();
        BAPPGetProjectsHandler.handleGetProjects(acc.Id);
        Test.stopTest();
    }
    @IsTest
    static void testMissingAccountId() {
        Date today = Date.today();

        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Project
        Project__c proj1 = new Project__c(
            Name = 'Project 1',
            IsAvailableForBroker__c = true,
            StartDate__c = today.addDays(-1),
            EndDate__c = today.addDays(5)
        );
        insert proj1;

        // Create Project Allocation
        ProjectAgencyAllocation__c paa1 = new ProjectAgencyAllocation__c(
            Account__c = acc.Id, 
            Project__c = proj1.Id,
            IsActive__c = true
        );
        insert paa1;

        // Create Unit (ensure formula IsActive__c evaluates TRUE)
        Unit__c unit1 = new Unit__c(
            Name = 'Unit-1',
            Project__c = proj1.Id,
            Status__c = 'Available',
            StartDate__c = today.addDays(-1),
            EndDate__c = today.addDays(5)
        );
        insert unit1;

        // Create Broker Unit Allocation
        BrokerUnitAllocations__c bua1 = new BrokerUnitAllocations__c(
            Account__c = acc.Id, 
            Unit__c = unit1.Id,
            IsActive__c = true
        );
        insert bua1;

        // Call Handler
        Test.startTest();
        RestContext.response = new RestResponse();
        BAPPGetProjectsHandler.handleGetProjects(null);
        Test.stopTest();
    }
}