/*****************************************************************************************
Class       : QMSTokenAssignmentTriggerHandler
Author      : Aman Bharti
Description : QMSTokenAssignmentTriggerHandler
Test Class  : 
Created Date: 11 MAY 2026 
*****************************************************************************************/
public without sharing class QMSTokenAssignmentTriggerHandler implements ITriggerHandler{
    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return isTriggerDisabled;
    }

    
    public void beforeInsert(List<sObject> newList) {
        QMSTokenAssignmentTriggerHelper.populateAssignedPerson((List<QMSTokenAssignment__c>)newList,null);
    }
    
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
    }
    
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
        QMSTokenAssignmentTriggerHelper.populateAssignedPerson((List<QMSTokenAssignment__c>)newList,  (Map<Id, QMSTokenAssignment__c>)oldMap);
    }
    
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,  List<sObject> oldList, Map<Id, sObject> oldMap) {
    }
    
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
    }
    
    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
        
    }
}