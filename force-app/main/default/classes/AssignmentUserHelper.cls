/*
* @Author        : Prashant Sahu
* @CreatedDate   : 8 MAY 2026
* @Description   : Helper class for AssignmentUser__c trigger operations.
*                  Updates User BusinessHour__c field based on
*                  AssignmentUser__c BusinessHours__c value.
*/
/*****************************************************************************************************
* Version       Author          Date            Comment                   Method
* 1.0           Prashant Sahu   8 MAY 2026       AssignmentUserHelper     handleAfterInsert /handleAfterUpdate /updateUsers
******************************************************************************************/
public class AssignmentUserHelper {
    
    public static void handleAfterInsert(List<AssignmentUser__c> newList){
        Map<Id, Id> userToBHMap = new Map<Id, Id>();
        for(AssignmentUser__c rec : newList){
            if(rec.User__c != null && rec.BusinessHours__c != null){
                userToBHMap.put(rec.User__c, rec.BusinessHours__c);
            }
        }
        if(userToBHMap.isEmpty()){
            return;
        }
        updateUsers(userToBHMap);
    }

    public static void handleAfterUpdate(List<AssignmentUser__c> newList,Map<Id, AssignmentUser__c> oldMap){
        Map<Id, Id> userToBHMap = new Map<Id, Id>();
        for(AssignmentUser__c rec : newList){
            if(rec.User__c != null && rec.BusinessHours__c != null){
                AssignmentUser__c oldRec = oldMap.get(rec.Id);
                if(oldRec.BusinessHours__c != rec.BusinessHours__c){
                    userToBHMap.put(rec.User__c, rec.BusinessHours__c);
                }
            }
        }
        if(userToBHMap.isEmpty()){
            return;
        }
        updateUsers(userToBHMap);
    }

    private static void updateUsers(Map<Id, Id> userToBHMap){
        if(userToBHMap.isEmpty()){
            return;
        }
        List<User> usersToUpdate = [ SELECT Id, BusinessHour__c FROM User WHERE Id IN :userToBHMap.keySet() ];
        for(User u : usersToUpdate){
            u.BusinessHour__c = userToBHMap.get(u.Id);
        }
        if(!usersToUpdate.isEmpty()){
            update usersToUpdate;
        }
    }
}