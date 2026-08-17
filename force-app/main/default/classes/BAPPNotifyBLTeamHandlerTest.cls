@isTest(seeAllData=true)
public class BAPPNotifyBLTeamHandlerTest {
    @isTest
    static void testNotifyBLTeam() {
        // STEP 1: Create test BrokerApplication__c
        BrokerApplication__c app = new BrokerApplication__c(
            Name = 'Test App'
           // ApplicationNumber__c = 'APP-001'
        );
        insert app;

        // STEP 2: Query existing Email Template from org
        EmailTemplate template = [
            SELECT Id FROM EmailTemplate 
            WHERE DeveloperName = 'Notify_BL_Intial_Approval' 
            LIMIT 1
        ];
        System.assertNotEquals(null, template, 'Expected Email Template not found in org.');

        // STEP 3: Query existing Queue (Group) and check it has members
        Group blQueue = [
            SELECT Id FROM Group 
            WHERE DeveloperName = 'Bloom_Legal_BL' AND Type = 'Queue' 
            LIMIT 1
        ];
        System.assertNotEquals(null, blQueue, 'Expected Queue not found in org.');

        List<GroupMember> members = [
            SELECT Id, UserOrGroupId FROM GroupMember 
            WHERE GroupId = :blQueue.Id 
            LIMIT 1
        ];
        System.assert(!members.isEmpty(), 'Queue has no members assigned.');

        // STEP 4: Call handler logic
        Test.startTest();
        BAPPNotifyBLTeamHandler.notifyBLTeam(new List<Id>{app.Id});
        Test.stopTest();

        System.debug('BAPPNotifyBLTeamHandler executed successfully.');
    }
}