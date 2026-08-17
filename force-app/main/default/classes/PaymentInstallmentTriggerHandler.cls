/***
Class       : PaymentInstallmentTriggerHandler
Author      : Dhanraj Poojary
Description : 
TestClass   : PaymentInstallmentTriggerHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.       V1.0              20/08/25           Initial Version 
****************************************************************************************************************/

public without sharing class PaymentInstallmentTriggerHandler implements ITriggerHandler{
    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return isTriggerDisabled;
    }
    
    public void beforeInsert(List<sObject> newList) {
    }
    
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
    }
    
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
    }
    
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,  List<sObject> oldList, Map<Id, sObject> oldMap) {
        PaymentInstallmentTriggerHelper.handleAfterUpdate((List<PaymentInstallments__c>)newList,(Map<Id,PaymentInstallments__c>)trigger.oldMap);
    }
    
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
    }
    
    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
    }
    
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
    }
}