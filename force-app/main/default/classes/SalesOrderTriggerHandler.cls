/***
Class       : SalesOrderTriggerHandler
Author      : Rajat Rastogi
Description : 
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.      V1.0                 04/09/2024           Initial Version  
2.      V2.0                 20/05/2024           added  handleBeforeInsertFieldUpdates and handleafterInsertFieldUpdates
****************************************************************************************************************/ 
public without sharing class SalesOrderTriggerHandler implements ITriggerHandler{ 
    
    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return isTriggerDisabled;
    }
    
    public void beforeInsert(List<sObject> newList) {
        SalesOrderTriggerHelper.handleBeforeInsertFieldUpdates((List<SalesOrder__c>)newList);
    }
    
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        SalesOrderTriggerHelper.updateUnitActiveSOAfterInsert((List<SalesOrder__c>)newList);
        SalesOrderTriggerHelper.createDocuments((List<SalesOrder__c>)newList);
        SalesOrderTriggerHelper.handleafterInsertFieldUpdates((List<SalesOrder__c>)newList);
    }
    
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
        SalesOrderTriggerHelper.updateSAPFlag((List<SalesOrder__c>) newList, (Map<Id, SalesOrder__c>)oldMap);
        SalesOrderTriggerHelper.handleBeforeUpdateFieldUpdates((List<SalesOrder__c>) newList, (Map<Id, SalesOrder__c>) oldMap);
    }
    
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,  List<sObject> oldList, Map<Id, sObject> oldMap) {
        
        SalesOrderTriggerHelper.updateUnitActiveSOAfterUpdate((List<SalesOrder__c>)newList, (Map<Id,SalesOrder__c>)oldMap);
        SalesOrderTriggerHelper.updateSalesorderOnHandover((List<SalesOrder__c>)newList, (Map<Id,SalesOrder__c>)oldMap);
    }    
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
        
    }
}