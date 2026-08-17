/***
Class       : LeasingOrderTriggerHandler
Author      : 
Description : 
TestClass   : 
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
****************************************************************************************************************/
public class LeasingOrderTriggerHandler implements ITriggerHandler{
    
    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return isTriggerDisabled;
    }
    
    public void beforeInsert(List<sObject> newList) {
        LeasingOrderTriggerHelper.beforeFieldUpdates(newList,null);
        LeasingOrderTriggerHelper.applyVatOnCreate((List<LeasingOrder__c>) newList);
    }
    
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        LeasingOrderTriggerHelper.createDocuments((List<LeasingOrder__c>)newList ,(Map<Id,LeasingOrder__c>)newMap );
        LeasingOrderTriggerHelper.afterFieldUpdates((List<LeasingOrder__c>)newList,null);
        LeasingOrderTriggerHelper.createSalesEntries((List<LeasingOrder__c>)newList);
    }
    
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
        LeasingOrderTriggerHelper.beforeFieldUpdates((List<LeasingOrder__c>)newList,(Map<Id,LeasingOrder__c>)oldMap);
        LeasingOrderTriggerHelper.validateSalesEntriesOnLeaseDateChange((List<LeasingOrder__c>)newList,(Map<Id,LeasingOrder__c>)oldMap);
        
    }
    
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,  List<sObject> oldList, Map<Id, sObject> oldMap) {
        LeasingOrderTriggerHelper.afterFieldUpdates((List<LeasingOrder__c>)newList,(Map<Id,LeasingOrder__c>)oldMap);
        LeasingOrderTriggerHelper.sendApprovedLeasingOfferForSigning((List<LeasingOrder__c>)newList,(Map<Id,LeasingOrder__c>)oldMap);
        LeasingOrderTriggerHelper.adjustSalesEntries((List<LeasingOrder__c>)newList,(Map<Id,LeasingOrder__c>)oldMap);
    }
    
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
        
    }
}