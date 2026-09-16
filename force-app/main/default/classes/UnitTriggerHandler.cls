/*
* @Author : Biswajeet Samal
* @CreatedDate : 7th AUG 2024
* @Description : Unit object trigger handler
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           Biswajeet   07AUG2024        Initial draft 
* 2.0           Jayprakash  20AUG2024        Implemented GIS Integration
*****************************************************************************************************/
public class UnitTriggerHandler implements ITriggerHandler{
    
    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return isTriggerDisabled;
    }
    
    public void beforeInsert(List<sObject> newList) {
        UnitTriggerHelper.handleBeforeInsert((List<Unit__c>) newList);  
    }
    
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        UnitTriggerHelper.createDocuments((List<Unit__c>) newList);        
    }
    
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
        UnitTriggerHelper.handleBeforeUpdate((List<Unit__c>) newList, (Map<Id,Unit__c>) oldMap);
    }
    
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,  List<sObject> oldList, Map<Id, sObject> oldMap) {
        UnitTriggerHelper.assignHandoverToHOAgent((List<Unit__c>) newList, (Map<Id,Unit__c>) oldMap);
        UnitTriggerHelper.handleAfterUpdate((List<Unit__c>) newList, (Map<Id,Unit__c>) oldMap);
        UserService objUserService = UserService.getInstance();
        if(!objUserService.hasBypassIntegration()){
            UnitTriggerHelper.doPushToGIS((List<Unit__c>)newList,(Map<Id,Unit__c>)oldMap);
        }
    }
    
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
        
    }
}