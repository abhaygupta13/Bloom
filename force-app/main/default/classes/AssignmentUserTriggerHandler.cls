public class AssignmentUserTriggerHandler implements ITriggerHandler {

    public static Boolean isTriggerDisabled = false;

    public Boolean isDisabled(){
        return isTriggerDisabled;
    }

    public void beforeInsert(List<sObject> newList) {}

    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
        AssignmentUserHelper.handleAfterInsert(  (List<AssignmentUser__c>) newList);
    }

    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap,
                             List<sObject> oldList, Map<Id, sObject> oldMap) {}

    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {        
        AssignmentUserHelper.handleAfterUpdate( (List<AssignmentUser__c>)newList, (Map<Id, AssignmentUser__c>)oldMap );       
    }

    public void beforeDelete(List<sObject> oldList, Map<Id, sObject> oldMap) {}

    public void afterDelete(List<sObject> oldList, Map<Id, sObject> oldMap) {}

    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {}
}