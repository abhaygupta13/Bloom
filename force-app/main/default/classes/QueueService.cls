/**
* @File Name : QueueService.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : November 8, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | November 8, 2024 |   | Initial Version
**/

public class QueueService {
    private static QueueService instance;

    public static QueueService getInstance() {
        if (instance == null) {
            instance = new QueueService();
        }
        return instance;
    }
	

	public static List<GroupMember> currentUserQueueMember(id ownerId){
		return [  SELECT GroupId 
            FROM GroupMember 
            WHERE GroupId = :ownerId 
            AND UserOrGroupId = :UserInfo.getUserId()];
	}
    //Shruti
    public Group getGroupByDeveloperNameAndType(String developerName, String groupType) {
        List<Group> groups = [
            SELECT Id 
            FROM Group 
            WHERE DeveloperName = :developerName AND Type = :groupType 
            LIMIT 1
        ];
        return groups.isEmpty() ? null : groups[0];
    }
    //Shruti
    public List<GroupMember> getGroupMembersByGroupId(Id groupId) {
        if (groupId == null) {
            return new List<GroupMember>();
        }
        return [
            SELECT UserOrGroupId 
            FROM GroupMember 
            WHERE GroupId = :groupId
        ];
    }
    public Boolean isUserMemberOfQueue(
    String queueDevName,
    Id userId
) {
    Group queue = getGroupByDeveloperNameAndType(
        queueDevName,
        'Queue'
    );

    if (queue == null || userId == null) {
        return false;
    }

    return ![
        SELECT Id
        FROM GroupMember
        WHERE GroupId = :queue.Id
        AND UserOrGroupId = :userId
        LIMIT 1
    ].isEmpty();
}
}