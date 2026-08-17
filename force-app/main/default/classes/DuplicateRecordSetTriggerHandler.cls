/***
Class       : DuplicateRecordSetTriggerHandler
Author      : Biswajeet
Description : Duplicate Record Set object trigger handler
****************************************************************************************************************/
public class DuplicateRecordSetTriggerHandler implements ITriggerHandler{
    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return isTriggerDisabled;
    }
    
    public void beforeInsert(List<sObject> newList) {
    }
    
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        DuplicateRecordSetTriggerHelper.sendDuplicateLeadEmail((List<DuplicateRecordSet>) newList);
    }
    
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
        
    }
    
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,  List<sObject> oldList, Map<Id, sObject> oldMap) {
        DuplicateRecordSetTriggerHelper.sendDuplicateLeadEmail((List<DuplicateRecordSet>) newList);
    }
    
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
    }
    
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
        
    }
    
}