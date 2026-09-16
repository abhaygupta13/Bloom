/*****************************************************************************************
Class       : SalesOrderRebateTriggerHandler
Author      : Dhanraj
Description : SalesOrderRebateTriggerHandler
Test Class  : 
Created Date: 10 JUL 2026 
*****************************************************************************************/

public with sharing class SalesOrderRebateTriggerHandler implements ITriggerHandler{
    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return isTriggerDisabled;
    }
    
    public void beforeInsert(List<sObject> newList) {
        SalesOrderRebateTriggerHelper.handleBeforeInsert((List<SalesOrderRebate__c>)newList);
    }
    
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        SalesOrderRebateTriggerHelper.handleAfterInsert((List<SalesOrderRebate__c>)newList);
    }
    
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
        SalesOrderRebateTriggerHelper.handleBeforeUpdate((List<SalesOrderRebate__c>)newList, (Map<Id,SalesOrderRebate__c>)oldMap);
    }
    
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,  List<sObject> oldList, Map<Id, sObject> oldMap) {
        SalesOrderRebateTriggerHelper.handleAfterUpdate((List<SalesOrderRebate__c>)newList,(Map<Id,SalesOrderRebate__c>)oldMap);
    }
    
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
    }
    
    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
    }
    
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
    }
}