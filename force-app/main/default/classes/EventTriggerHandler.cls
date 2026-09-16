/***
Class       : EventTriggerHandler
Author      : Rajat Rastogi
Description : 
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.      V1.0             	 11/06/2024           Initial Version  
****************************************************************************************************************/ 

public class EventTriggerHandler implements ITriggerHandler{
    
    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return isTriggerDisabled;
    }
    
    public void beforeInsert(List<sObject> newList) {
        EventTriggerHelper.checkValidationAndUpdateHandover((List<Event>) newList);        
        
    }
    
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
         EventTriggerHelper.createServiceResourceAbsence((List<Event>) newList);
         EventTriggerHelper.handleEventNotificationToCustomer((List<Event>) newList);
        EventTriggerHelper.handleAfterInsert((List<Event>) newList);

    }
    
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
        EventTriggerHelper.updateServiceResourceAbsenceOnEventChange((List<Event>) newList,(Map<id,Event>)oldMap);
    }
    
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,  List<sObject> oldList, Map<Id, sObject> oldMap) {
        EventTriggerHelper.handleAfterUpdate((List<Event>) newList, (Map<Id, Event>) oldMap);
    }
    
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
         EventTriggerHelper.deleteServiceResourceAbsenceOnEventDelete((List<Event>) oldList);
    }
    
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
        
    }
    
}