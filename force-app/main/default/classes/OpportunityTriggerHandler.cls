/***
Class       : OpportunityTriggerHandler
Author      : Smaartt
Description : Sending Email on Duplicate Opportunity insertion checking by Email and phone from Existing open opportuniteis..
TestClass   : OpportunityTriggerHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version_DevInitials     Date                Details
1.          V1.0              09/08/23           Initial Version 
2.          V2.0              26/10/23           Added Custom label with receipients information and Bulkified 
Existing open Opportunties query.

****************************************************************************************************************/
public class OpportunityTriggerHandler implements ITriggerHandler{
    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return isTriggerDisabled;
    }
    
    public void beforeInsert(List<sObject> newList) {
    }
    
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        OpportunityTriggerHelper.createDocuments((List<Opportunity>) newList);
    }
    
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
        
    }
    
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,  List<sObject> oldList, Map<Id, sObject> oldMap) {
        OpportunityTriggerHelper.updateSalesOrdersADHAStatus((List<Opportunity>) newList ,(Map<id,Opportunity>) oldMap );
    }
    
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
    }
    
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
        
    }
    
}