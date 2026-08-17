/***
Class       : LeasingRATriggerHandler  
Author      : 
Description : Trigger handler class for leasing receipt acknowledgement
TestClass   : 
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              10/08/24           Initial Version 
****************************************************************************************************************/

public without sharing class LeasingRATriggerHandler implements ITriggerHandler{
    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return isTriggerDisabled;
    }
    
    public void beforeInsert(List<sObject> newList) {
        LeasingRATriggerHelper.updateOwnFields((List<LeasingReceiptAcknowledgment__c>)newList, Null,Null);
    }
    
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        LeasingRATriggerHelper.createDocuments((List<LeasingReceiptAcknowledgment__c>)newList,(Map<Id,LeasingReceiptAcknowledgment__c>)newMap);
        LeasingRATriggerHelper.handleReceiptIntegration((Map<Id,LeasingReceiptAcknowledgment__c>)newMap, Null);
        LeasingRATriggerHelper.updateCreditBalanceOnLO((List<LeasingReceiptAcknowledgment__c>)newList,null);
    }
    
    
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
       LeasingRATriggerHelper.updateOwnFields((List<LeasingReceiptAcknowledgment__c>)newList,(Map<Id,LeasingReceiptAcknowledgment__c>)newMap, (Map<Id,LeasingReceiptAcknowledgment__c>)oldMap);
    }
    
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,  List<sObject> oldList, Map<Id, sObject> oldMap) {
        LeasingRATriggerHelper.handleReceiptIntegration((Map<Id,LeasingReceiptAcknowledgment__c>)newMap, (Map<Id,LeasingReceiptAcknowledgment__c>)oldMap);
        LeasingRATriggerHelper.reversalAllocationHandling((List<LeasingReceiptAcknowledgment__c>)newList, (Map<Id,LeasingReceiptAcknowledgment__c>)oldMap);
        LeasingRATriggerHelper.updateCreditBalanceOnLO((List<LeasingReceiptAcknowledgment__c>)newList, (Map<Id,LeasingReceiptAcknowledgment__c>)oldMap);
        LeasingRATriggerHelper.updatePaymentDocNumber((List<LeasingReceiptAcknowledgment__c>)newList, (Map<Id,LeasingReceiptAcknowledgment__c>)oldMap);
    }
    
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
         
    }
    
}