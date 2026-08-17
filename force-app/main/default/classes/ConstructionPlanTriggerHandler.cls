/***
Class       : ConstructionPlanTriggerHandler
Author      : Smaartt
Description : 
TestClass   : ConstructionPlanTriggerHelperTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              23/08/24           Initial Version 
****************************************************************************************************************/
public without sharing class ConstructionPlanTriggerHandler implements ITriggerHandler {
    
    public static Boolean TriggerDisabled = false; 
    
    public Boolean isDisabled() {
        return TriggerDisabled;
    }
    
    public void beforeInsert(List<sObject> newList) {
        // Add any logic needed before inserting records if required
    }
    
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
        // Add any logic needed after inserting records if required
    }
    
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
        // Add any logic needed before updating records if required
    }
    
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
        ConstructionPlanTriggerHelper.sendEmailOnConstructPlanUpdate((List<Construction_Plan__c>) newList, (Map<Id, Construction_Plan__c>) oldMap);
    }
    
    public void beforeDelete(List<sObject> oldList, Map<Id, sObject> oldMap) {
        // Add any logic needed before deleting records if required
    }
    
    public void afterDelete(List<sObject> oldList, Map<Id, sObject> oldMap) {
        // Add any logic needed after deleting records if required
    }
    
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
        // Add any logic needed after undeleting records if required
    }
}