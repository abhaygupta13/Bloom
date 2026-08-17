/***
Class       : RoundRobinUserTriggerHandler
Author      : Smaartt
Description : 
TestClass   : RoundRobinUserTriggerHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              27/04/23           Initial Version 
****************************************************************************************************************/
public class RoundRobinUserTriggerHandler  implements ITriggerHandler{
    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return isTriggerDisabled;
    }
    
    public void beforeInsert(List<sObject> newList) {
        RoundRobinUserTriggerHelper.updateRoundRobinId((List<Round_Robin_User__c>) newList);
        RoundRobinUserTriggerHelper.Populate_RoundRobinUserName((List<Round_Robin_User__c>) newList);
        RoundRobinUserTriggerHelper.RoundRobinUserInsert((List<Round_Robin_User__c>) newList);
    }
    
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
    }
    
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
        
    }
    
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,  List<sObject> oldList, Map<Id, sObject> oldMap) {
        
    }
    
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        RoundRobinUserTriggerHelper.updateRoundRobinId_delete((Map<Id, Round_Robin_User__c>) oldmap);
    }
    
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
        
    }
    
}