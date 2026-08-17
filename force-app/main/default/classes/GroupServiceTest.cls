@IsTest
private class GroupServiceTest {

    @TestSetup
    static void setupTestData() {
        // Create a test Group/Public Group
        Group testGroup = new Group(
            Name = 'Test Service Group',
            Type = 'Regular'
        );
        insert testGroup;

        // Create a test User
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            Alias = 'tuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser' + DateTime.now().getTime() + '@example.com'
        );
        insert testUser;

        // Add User as a GroupMember
        GroupMember gm = new GroupMember(
            GroupId = testGroup.Id,
            UserOrGroupId = testUser.Id
        );
        insert gm;
    }

    @IsTest
    static void testGetInstance() {
        Test.startTest();
        GroupService instance1 = GroupService.getInstance();
        GroupService instance2 = GroupService.getInstance();
        Test.stopTest();

        System.assertNotEquals(null, instance1, 'Instance should not be null.');
        System.assertEquals(instance1, instance2, 'getInstance should return the same singleton instance.');
    }

    @IsTest
    static void testGetGroupByNames() {
        GroupService service = GroupService.getInstance();
        Set<String> groupNames = new Set<String>{ 'Test Service Group' };

        Test.startTest();
        List<Group> results = service.getGroupByNames(groupNames);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should find exactly one group with the specified name.');
        System.assertEquals('Test Service Group', results[0].Name);
    }

    @IsTest
    static void testGetGroupMembersByGroupIds() {
        Group testGroup = [SELECT Id FROM Group WHERE Name = 'Test Service Group' LIMIT 1];
        Set<Id> groupIds = new Set<Id>{ testGroup.Id };

        Test.startTest();
        List<GroupMember> results = GroupService.getGroupMembersByGroupIds(groupIds);
        List<GroupMember> emptyNullResults = GroupService.getGroupMembersByGroupIds(null);
        List<GroupMember> emptySetResults = GroupService.getGroupMembersByGroupIds(new Set<Id>());
        Test.stopTest();

        // Check positive scenario
        System.assertEquals(1, results.size(), 'Should retrieve one group member.');
        System.assertEquals(testGroup.Id, results[0].GroupId);

        // Check null and empty safety guards
        System.assertEquals(0, emptyNullResults.size(), 'Passing null should return an empty list.');
        System.assertEquals(0, emptySetResults.size(), 'Passing an empty set should return an empty list.');
    }

    @IsTest
    static void testGetMemberInfoFromGroup() {
        GroupService service = GroupService.getInstance();
        Group testGroup = [SELECT Id FROM Group WHERE Name = 'Test Service Group' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE LastName = 'Testing' LIMIT 1];

        Test.startTest();
        List<GroupMember> results = service.getMemberInfoFromGroup(testUser.Id, testGroup.Id);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return the group member matching user and group/queue ID.');
    }
}