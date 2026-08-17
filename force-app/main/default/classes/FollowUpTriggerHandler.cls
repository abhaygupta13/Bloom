/***
Class       : FollowUpTriggerHandler 
Author      : Jhilik
Description : 
TestClass   : FollowUpTriggerHandlerTest
****************************************************************************************************************/
public without sharing class FollowUpTriggerHandler implements ITriggerHandler {
    public FollowUpTriggerHandler() {

    }

    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){ 
        return isTriggerDisabled;
    }
    
    public void beforeInsert(List<sObject> newList) {
        //FollowUpTriggerHelper.handleBeforeInsert((List<FollowUp__c>)newList);
    }

    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        FollowUpTriggerHelper.handleAfterInsert((List<FollowUp__c>)newList, (Map<Id,FollowUp__c>)newMap);
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