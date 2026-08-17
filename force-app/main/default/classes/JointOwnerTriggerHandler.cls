/***
Class       : JointOwnerTriggerHandler
Author      : Smaartt
Description : 
TestClass   : JointOwnerTriggerHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              27/04/23           Initial Version 
1.          V2.0              27/10/23          Added method for giving error while deleteing jointowner record 
associated with salesorder having status other then Booked.
2.          V1.1              26/08/24     Jayprakash   Updated to triger framework
****************************************************************************************************************/

public class JointOwnerTriggerHandler implements ITriggerHandler{
    
    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return isTriggerDisabled;
    }
    
    public void beforeInsert(List<sObject> newList) {
        JointOwnerTriggerHelper.handleBeforeInsertFieldUpdates((List<JointOwner__c>)newList);
    }
    
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        JointOwnerTriggerHelper.updateJointOwnerDetails((List<JointOwner__c>)newList);
        JointOwnerTriggerHelper.updateJointOwnerSequence((List<JointOwner__c>)newList, null);
    }
    
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
        JointOwnerTriggerHelper.handleBeforeUpdateFieldUpdates((List<JointOwner__c>)newList, (Map<Id, JointOwner__c>)oldMap);
    }
    
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,  List<sObject> oldList, Map<Id, sObject> oldMap) {
        JointOwnerTriggerHelper.updateJointOwnerSequence((List<JointOwner__c>)newList, (Map<Id, JointOwner__c>)oldMap);}
    
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) { JointOwnerTriggerHelper.errorMessageOnJointOwnerDelete((Map<Id, JointOwner__c>)oldMap); }
    
    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {}
    
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {}
}