public class BrokerUnitAllocationsTriggerHandler implements ITriggerHandler {

    public static Boolean isTriggerDisabled = false;

    public Boolean isDisabled() {
        return isTriggerDisabled;
    }

    public void beforeInsert(List<sObject> newList) {
        // Any before insert logic if needed
    }

    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
  
    }

    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, 
                             List<sObject> oldList, Map<Id, sObject> oldMap) {
       
    }
    
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {    
        BrokerUnitAllocationsTriggerHelper.handleAfterUpdate(
            (List<BrokerUnitAllocations__c>) newList,
            (Map<Id, BrokerUnitAllocations__c>) newMap,
            (List<BrokerUnitAllocations__c>) oldList,
            (Map<Id, BrokerUnitAllocations__c>) oldMap
        );
    }

    public void beforeDelete(List<sObject> oldList, Map<Id, sObject> oldMap) {}

    public void afterDelete(List<sObject> oldList, Map<Id, sObject> oldMap) {}

    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {}
}