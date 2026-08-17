/*
* Author         : Swapnil Patil
* Created Date   : 21st April 2026
* Description    : DocusignStatusTriggerHandler
*/
/*****************************************************************************************************
* Version       Author                  Date                        Comment
* 1.0           Swapnil Patil           21st April 2026             Initial draft 
*****************************************************************************************************/
public class DocusignStatusTriggerHandler implements ITriggerHandler{ 
    
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
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {

        List<dfsle__EnvelopeStatus__c> newRecords = (List<dfsle__EnvelopeStatus__c>) newList;
        Map<Id, dfsle__EnvelopeStatus__c> oldRecords = (Map<Id, dfsle__EnvelopeStatus__c>) oldMap;

        DocusignStatusTriggerHelper.processAfterUpdate(newRecords, oldRecords);
    }
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) { 
        
    }
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
        
    }
    
    
}