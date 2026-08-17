/*****************************************************************************************
Class       : UnitAllocationTriggerHandlerTest
Author      : Vikas Baliyan
Description : UnitAllocationTriggerHandlerTest Class
Test Class  : 
Created Date: 24 APR 2025 
*****************************************************************************************/

@IsTest
public class UnitAllocationTriggerHandlerTest {
    
    @TestSetup
    private static void createTestData() {
        Account acc = TestDataFactory.createBrokerAccount('test', false, '1122334455');
        insert acc;

        Project__c project = TestDataFactory.createProject('Project Test', Date.newinstance(2024, 01, 01), Date.newInstance(2025, 01, 01), Date.newInstance(2025, 01, 15), Date.newInstance(2025, 01, 16), Date.newInstance(2025, 01, 30), Date.newInstance(2025, 02, 01));
        insert project;

        Unit__c unit = TestDataFactory.createUnit(project.Id, 'Test unit', 'Sold');
        insert unit;

        Unit_Allocation__c ua = TestDataFactory.createUnitAllocation(false, acc.Id, unit.Id);
        ua.User_Type__c = 'Tenant';
        insert ua;
    }

    @IsTest
    private static void testUpdateActiveTenant() {
        Test.startTest();
            List<Unit_Allocation__c> uaList = [SELECT Id,Active__c, User_Type__c,Account__c, Unit__c FROM Unit_Allocation__c LIMIT 1];
        	uaList[0].Active__c = true;
        	update uaList;
        Test.stopTest();
        List<Unit__c> unitList = [SELECT Id,ActiveTenant__c FROM Unit__c];
        Assert.areEqual(true,unitList[0].ActiveTenant__c != null,'Their should be an error msg');
    }
}