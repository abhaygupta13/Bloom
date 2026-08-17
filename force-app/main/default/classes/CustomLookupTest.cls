@isTest
public class CustomLookupTest {
    static testMethod void myUnitTest() {
        Test.startTest();
        Project__c project = new Project__c(Name = 'Test Project');
        insert project;
        
        BuildingSection__c  phase = new BuildingSection__c (
            Name = 'Phase 1',
            Project__c = project.Id,
            BuildingSectionCode__c = 'BL-CAS'
        );
        insert phase;
        
        
        Unit__c unit = new Unit__c(
            Name = 'Unit 101',
            Project__c = project.Id,
            BuildingSectionName__c  = phase.Id
        );
        insert unit;
        
         Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Create a custom User record (user__c)
        user__c customUser = new user__c(
            Name = 'Test User', 
            Email__c = 'testuser@example.com', 
            user_account__c = acc.Id,
            Username__c = 'testuser@example.com'
        );
        insert customUser;
        
        Unit_Allocation__c unitAllocation= BCAPP_TestDataFactory.createUnitAllocation();
        unitAllocation.Unit__c=unit.id;
        unitAllocation.User__c=customUser.id;
        unitAllocation.Account__c=acc.id;
        insert unitAllocation;
        Test.stopTest();
        
        CustomLookup.searchLookupData('test','SalesOrder__c','');
        CustomLookup.searchDefaultRecord('','SalesOrder__c');
        CustomLookup.searchLookupData('','Unit__c',acc.id);
         CustomLookup.searchLookupData('','Amenities__c',unit.id);
        CustomLookup.getSalesordetail('');
    }
}