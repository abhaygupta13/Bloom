/*
* @Author        : Rushikesh Jadhav
* @CreatedDate   : 26th SEP 2025
* @Description   : Trigger Handler for BrokerUnitAssignment__c
*/
public class BrokerUnitAssignmentTriggerHandler implements ITriggerHandler {

    public static Boolean isTriggerDisabled = false;

    public Boolean isDisabled() {
        return isTriggerDisabled;
    }

    public void beforeInsert(List<sObject> newList) {
        // Any before insert logic if needed
    }

    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
        // Call helper to send emails after record is inserted
        List<BrokerUnitAssignment__c> assignments = (List<BrokerUnitAssignment__c>)newList;
        BrokerUnitAssignmentHelper.sendUnitAssignmentEmails(assignments);
    }

    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, 
                             List<sObject> oldList, Map<Id, sObject> oldMap) {
       
    }

    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap, 
                            List<sObject> oldList, Map<Id, sObject> oldMap) {
       
    }

    public void beforeDelete(List<sObject> oldList, Map<Id, sObject> oldMap) {}

    public void afterDelete(List<sObject> oldList, Map<Id, sObject> oldMap) {}

    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {}
}