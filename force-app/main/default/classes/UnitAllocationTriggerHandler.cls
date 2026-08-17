/*****************************************************************************************
Class       : UnitAllocationTriggerHandler
Author      : Vikas Baliyan
Description : Unit Allocation Trigger Handler
Test Class  : 
Created Date: 18 APR 2025 
*****************************************************************************************/

public without sharing class UnitAllocationTriggerHandler implements ITriggerHandler{
    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return isTriggerDisabled;
    }

    
    public void beforeInsert(List<sObject> newList) {
        
    }
    
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        UnitAllocationTriggerHelper.updateActiveTenant((List<Unit_Allocation__c>)newList, null);
    }
    
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
    }
    
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,  List<sObject> oldList, Map<Id, sObject> oldMap) {
        UnitAllocationTriggerHelper.updateActiveTenant((List<Unit_Allocation__c>)newList,  (Map<Id, Unit_Allocation__c>)oldMap);
    }
    
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
    }
    
    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
        
    }
}