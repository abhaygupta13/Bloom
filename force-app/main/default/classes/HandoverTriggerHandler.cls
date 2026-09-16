/***
Class       : HandoverTriggerHandler
Author      : Rajat Rastogi
Description : 
TestClass   : HandoverTriggerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.      V1.0             	 11/06/2024           Initial Version  
****************************************************************************************************************/ 
public class HandoverTriggerHandler implements ITriggerHandler{
    
    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return isTriggerDisabled;
    }
    
    public void beforeInsert(List<sObject> newList) {
        HandoverTriggerHelper.beforeInsert((List<Handover__c>) newList);  
        HandoverTriggerHelper.updateContactId((List<Handover__c>) newList, null);
        HandoverTriggerHelper.updateHoAgentAssignedUser(null, (List<Handover__c>) newList);
    }
    
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) { 
        HandoverTriggerHelper.createDocuments((List<Handover__c>) newList); 
        //HandoverTriggerHelper.createHandoverSla((List<Handover__c>) newList);
        HandoverTriggerHelper.setInitialDocumentOnHandover((List<Handover__c>) newList);  
        HandoverTriggerHelper.notifyOwners((List<Handover__c>) newList, NULL);
        //HandoverTriggerHelper.updateHoAgentAssignedUser(new Map<Id, Handover__c>(), (List<Handover__c>) newList);
        HandoverTriggerHelper.updateRelatedSalesorder(new Map<Id, Handover__c>(), (List<Handover__c>) newList);
    }
    
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
        HandoverTriggerHelper.beforeUpdateCall((List<Handover__c>) newList,  (Map<Id, Handover__c>)oldMap);
        HandoverTriggerHelper.updateContactId((List<Handover__c>) newList, (Map<Id, Handover__c>)oldMap);
        //HandoverTriggerHelper.handoverAssignmentBasedOnSubStatus((List<Handover__c>) newList, (Map<Id, Handover__c>)oldMap);
        HandoverTriggerHelper.deleteCancellationEvent((Map<Id, Handover__c>) newMap, (Map<Id, Handover__c>)oldMap);
        HandoverTriggerHelper.autopopulateFeesForUnitCategory((Map<Id, Handover__c>)oldMap, (List<Handover__c>) newList);
        //HandoverTriggerHelper.createDeveloperNocTask((Map<Id, Handover__c>)oldMap, (List<Handover__c>) newList);
        //HandoverTriggerHelper.validationErrorForHOStatus((Map<Id, Handover__c>) newMap, (Map<Id, Handover__c>)oldMap);
        HandoverTriggerHelper.updateHoAgentAssignedUser((Map<Id, Handover__c>)oldMap, (List<Handover__c>) newList);
    }
    
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,  List<sObject> oldList, Map<Id, sObject> oldMap) {
        //HandoverTriggerHelper.validationCheckinPHPPcase((Map<Id, Handover__c>) newMap, (Map<Id, Handover__c>)oldMap);
        
        //HandoverTriggerHelper.updateExistingHandoverSla((Map<Id, Handover__c>)oldMap, (List<Handover__c>) newList);
        HandoverTriggerHelper.updateKeyHandoverStatusOnUnit((Map<Id, Handover__c>)oldMap, (List<Handover__c>) newList);
        //HandoverTriggerHelper.updateHoAgentAssignedUser((Map<Id, Handover__c>)oldMap, (List<Handover__c>) newList);
        //HandoverTriggerHelper.updateHOPreviousStatus((Map<Id, Handover__c>) newMap, (Map<Id, Handover__c>)oldMap);
        HandoverTriggerHelper.updateInstallmentLineItems((Map<Id, Handover__c>)oldMap, (List<Handover__c>) newList);
        HandoverTriggerHelper.notifyOwners((List<Handover__c>) newList, (Map<Id, Handover__c>)oldMap);
        HandoverTriggerHelper.notifyCustomers((List<Handover__c>) newList, (Map<Id, Handover__c>)oldMap);
        HandoverTriggerHelper.updateRelatedSalesorder((Map<Id, Handover__c>)oldMap, (List<Handover__c>) newList);
    }
    
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
        
    }
    
}