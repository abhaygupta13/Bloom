/*****************************************************************************************
Class       : SalesOrderOtherChargesTriggerHandler
Author      : Vikas Baliyan
Description : SalesOrderOtherChargesTriggerHandler
Test Class  : 
Created Date: 14 MAY 2025 
*****************************************************************************************/

public with sharing class SalesOrderOtherChargesTriggerHandler implements ITriggerHandler{
    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return isTriggerDisabled;
    }
    
    public void beforeInsert(List<sObject> newList) {
        SalesOrderOtherChargesTriggerHelper.handleBeforeInsert((List<SalesOrderOtherCharges__c>)newList);
    }
    
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        SalesOrderOtherChargesTriggerHelper.handleAfterInsert((List<SalesOrderOtherCharges__c>)newList);
    }
    
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
        SalesOrderOtherChargesTriggerHelper.handleBeforeUpdate((List<SalesOrderOtherCharges__c>)newList, (Map<Id,SalesOrderOtherCharges__c>)oldMap);
    }
    
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,  List<sObject> oldList, Map<Id, sObject> oldMap) {
        SalesOrderOtherChargesTriggerHelper.handleAfterUpdate((List<SalesOrderOtherCharges__c>)newList,(Map<Id,SalesOrderOtherCharges__c>)oldMap);
    }
    
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
    }
    
    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
        
    }
}