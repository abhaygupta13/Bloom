/***
Class       : LeadTriggerHandler
Author      : Smaartt
Description : 
TestClass   : LeadTriggerHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.     version              Date                Details
1.          V1.0                                Initial Version 
****************************************************************************************************************/
public class LeadTriggerHandler  implements ITriggerHandler{
    
    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return isTriggerDisabled;
    }
    
    public void beforeInsert(List<sObject> newList) {
        LeadTriggerHelper.handleBeforeInsertFieldUpdates((List<Lead>)newList);
    }
    
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        LeadTriggerHelper.sendEmailToLeadOwner((Map<Id, Lead>) newMap);
    }
    
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
        LeadTriggerHelper.handleBeforeUpdateFieldUpdates((List<Lead>)newList,(Map<Id,Lead>)oldMap);
    }
    
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,  List<sObject> oldList, Map<Id, sObject> oldMap) {
    //    LeadTriggerHelper.createNewContactCenterLeadTask((List<Lead>)newList,(Map<Id,Lead>)oldMap); 
    //    LeadTriggerHelper.createQualifiedLeadTask((List<Lead>)newList,(Map<Id,Lead>)oldMap);
    //    LeadTriggerHelper.createLeadManagerTask((List<Lead>)newList,(Map<Id,Lead>)oldMap);
        LeadTriggerHelper.sendEmailOnOwnerUpdate((List<Lead>)newList,(Map<Id,Lead>)oldMap); 
        LeadTriggerHelper.markTaskComplete((List<Lead>)newList, (Map<Id,Lead>)oldMap); 
        LeadTriggerHelper.sendWaitingListUpdateEmail((List<Lead>)newList,(Map<Id,Lead>)oldMap); 
    }
    
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
        
    }
}