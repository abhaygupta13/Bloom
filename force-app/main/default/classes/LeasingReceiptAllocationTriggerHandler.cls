/***
Class       : LeasingReceiptAllocationTriggerHandler
Author      : 
Description : 
TestClass   : LeasingRcptAllocationTriggerHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              10/10/25           Initial Version 
****************************************************************************************************************/

public without sharing class LeasingReceiptAllocationTriggerHandler implements ITriggerHandler{
    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return isTriggerDisabled;
    }
    
    public void beforeInsert(List<sObject> newList) {
        LeasingReceiptAllocationTriggerHelper.beforeFieldUpdates((List<LeasingReceiptAllocation__c>)newList);
    }
    
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
    
       LeasingReceiptAllocationTriggerHelper.leasingRAAmountUpsert((Map<Id,LeasingReceiptAllocation__c>)newMap, null); 
       LeasingReceiptAllocationTriggerHelper.afterInsertSAPIntegration((List<LeasingReceiptAllocation__c>)newList);
       LeasingReceiptAllocationTriggerHelper.updateCreditBalanceOnLO((List<LeasingReceiptAllocation__c>)newList,null);

    }
    
    
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
        
    }
    
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,  List<sObject> oldList, Map<Id, sObject> oldMap) {
        LeasingReceiptAllocationTriggerHelper.leasingRAAmountUpsert((Map<Id,LeasingReceiptAllocation__c>)newMap, (Map<Id,LeasingReceiptAllocation__c>)oldMap);
        LeasingReceiptAllocationTriggerHelper.reversalIntegration((List<LeasingReceiptAllocation__c>)newList, (Map<Id,LeasingReceiptAllocation__c>)oldMap);
        LeasingReceiptAllocationTriggerHelper.reversalAmountHandling((List<LeasingReceiptAllocation__c>)newList, (Map<Id,LeasingReceiptAllocation__c>)oldMap);
        LeasingReceiptAllocationTriggerHelper.updateCreditBalanceOnLO((List<LeasingReceiptAllocation__c>)newList,null);
    }
    
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        LeasingReceiptAllocationTriggerHelper.leasingRAAmountDlt((List<LeasingReceiptAllocation__c>)oldList, (Map<Id,LeasingReceiptAllocation__c>)oldMap);
    }
    
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
         
    }
    
}