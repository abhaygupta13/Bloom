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
        List<User> usersToUpdate = [
            SELECT Id, BusinessHour__c
            FROM User
            WHERE Id IN :userToBHMap.keySet()
        ];
        for(User usObj : usersToUpdate){
            usObj.BusinessHour__c = userToBHMap.get(usObj.Id);
        }
        if(!usersToUpdate.isEmpty()){
            update usersToUpdate;
        }
    }
}