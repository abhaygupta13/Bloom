/*
*********************************************************
Apex Class Name    : ServiceReportTriggerHandler
Created Date       : Sept 21, 2026
@description       : This is handler class for Service Report Object
Modification Log   :
Ver   Date         Author                               Modification
1.0   21-09-2026   Abhay Gupta                          Created Trigger Handler class for Service Report
*********************************************************
*/
public without sharing class ServiceReportTriggerHandler implements ITriggerHandler {
    
    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return isTriggerDisabled;
    }    
    
    public void beforeInsert(List<sObject> newList) {
        
    }
    
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {        
        ServiceReportTriggerHelper.updateDocumentOnWorkOrder((List<ServiceReport>) newList);     
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