public class GroupService {
    
    private static GroupService instance;
    public static GroupService getInstance() {
        if(instance == null) {
             instance = new GroupService();
         }
         return instance;
    }
    
    public List<Group> getGroupByNames(Set<String> allGroupNames ){
        
        return [SELECT Name FROM Group WHERE Name IN :allGroupNames];
        
    }
    
    /**
     * Fetches GroupMember records for the given Group Ids.
     */
    public static List<GroupMember> getGroupMembersByGroupIds(Set<Id> groupIds) {
        if (groupIds == null || groupIds.isEmpty()) {
            return new List<GroupMember>();
        }
        return [
            SELECT GroupId, UserOrGroupId, UserOrGroup.Email
            FROM GroupMember
            WHERE GroupId IN :groupIds
        ];
    }
    
     public List<GroupMember>getMemberInfoFromGroup(Id userId, Id queueId) {
       
        return [SELECT Id FROM GroupMember WHERE GroupId = :queueId AND UserOrGroupId = :userId LIMIT 1];
    }
   

}