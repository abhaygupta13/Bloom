/*****************************************************************************************
Class       : QMSTokenTriggerHandler
Author      : Aman Bharti
Description : QMSTokenTriggerHandler
Test Class  : 
Created Date: 23 JUL 2026 
*****************************************************************************************/
public without sharing class QMSTokenTriggerHandler implements ITriggerHandler{
    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return isTriggerDisabled;
    }

    
    public void beforeInsert(List<sObject> newList) {
    }
    
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        QMSTokenTriggerHelper.sendSMSNotification((List<QMSToken__c>)newList,null);
    }
    
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
    }
    
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,  List<sObject> oldList, Map<Id, sObject> oldMap) {
        QMSTokenTriggerHelper.sendSMSNotification((List<QMSToken__c>)newList,  (Map<Id, QMSToken__c>)oldMap);
    }
    
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
    }
    
    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
        
    }
}