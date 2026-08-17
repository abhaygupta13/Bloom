@istest

public class QueueServiceTest {
  @IsTest
    static void testcurrentUserQueueMember() {
        QueueService.currentUserQueueMember(userinfo.getuserid());
    }
    

    @isTest
    static void testGetGroupByDeveloperNameAndType() {
        // Create test group record
        Group testGroup = new Group(
            Name = 'TestGroup',
            DeveloperName = 'TestDevName',
            Type = 'Queue'
        );
        insert testGroup;

        QueueService service = new QueueService();
        Group result = service.getGroupByDeveloperNameAndType('TestDevName', 'Queue');

        System.assertNotEquals(null, result, 'Group should be found');
        System.assertEquals(testGroup.Id, result.Id, 'Returned group Id should match');
    }

    @isTest
    static void testGetGroupMembersByGroupId() {
        // Create test group
        Group testGroup = new Group(
            Name = 'TestGroup2',
            DeveloperName = 'TestDevName2',
            Type = 'Queue'
        );
        insert testGroup;

        // Add current user as member of this group
        GroupMember gm = new GroupMember(
            GroupId = testGroup.Id,
            UserOrGroupId = UserInfo.getUserId()
        );
        insert gm;

        QueueService service = new QueueService();
        List<GroupMember> members = service.getGroupMembersByGroupId(testGroup.Id);

    }
      
}