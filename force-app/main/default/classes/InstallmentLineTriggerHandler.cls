/***
Class       : InstallmentLineTriggerHandler
Author      : Smaartt
Description : 
TestClass   : InstallmentLineTriggerHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              03/10/23           Initial Version 
****************************************************************************************************************/
public without sharing class InstallmentLineTriggerHandler implements ITriggerHandler{
    
    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return isTriggerDisabled;
    }
    
    public void beforeInsert(List<sObject> newList) {
        InstallmentLineTriggerHelper.handleBeforeInsert((List<InstallmentLines__c>)newList);
        
    }
    
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        InstallmentLineTriggerHelper.handleAfterInsert((List<InstallmentLines__c>)newList);
    }
    
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
        InstallmentLineTriggerHelper.handleBeforeUpdate((List<InstallmentLines__c>)newList,(Map<id,InstallmentLines__c>)trigger.oldMap);
    }
    
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,  List<sObject> oldList, Map<Id, sObject> oldMap) {
        InstallmentLineTriggerHelper.handleAfterUpdate((List<InstallmentLines__c>)newList,(Map<id,InstallmentLines__c>)trigger.oldMap);
        InstallmentLineTriggerHelper.updateReceiptRevisedDate((List<InstallmentLines__c>)newList,(Map<id,InstallmentLines__c>)trigger.oldMap);
    }
    
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
        
    }
    
}