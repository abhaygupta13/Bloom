/***
Class       : OnlinePaymentLogTriggerHandler 
Author      : Biswajeet
Description : 
TestClass   : OnlinePaymentLogTriggerHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date          Author       Details
1.          V1.0              27/04/23                  Initial Version 
****************************************************************************************************************/
public without sharing class OnlinePaymentLogTriggerHandler implements ITriggerHandler{ 
    
    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){ 
        return isTriggerDisabled;
    }
    
    public void beforeInsert(List<sObject> newList) {
        
    }
    
    
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        OnlinePaymentLogTriggerHelper.handleAfterInsert((List<OnlinePaymentLog__c>)newList);
    }
    
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
        
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