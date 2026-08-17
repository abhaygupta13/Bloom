/*
* @Author : Biswajeet Samal
* @CreatedDate : 7th AUG 2024
* @Description : AppRegistrationTriggerHandler
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           Biswajeet   07AUG2024        Initial draft 
*****************************************************************************************************/
public class AppRegistrationTriggerHandler  implements ITriggerHandler{
    
    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return isTriggerDisabled;
    }
    
    public void beforeInsert(List<sObject> newList) {
        AppRegistrationTriggerHelper.beforeInsert((List<AppRegistration__c>)newList);
    }
    
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        AppRegistrationTriggerHelper.createDocuments((List<AppRegistration__c>)newList);
        AppRegistrationTriggerHelper.afterInsert((List<AppRegistration__c>)newList);
    }
    
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
        AppRegistrationTriggerHelper.beforeUpdate((List<AppRegistration__c>)newList, (Map<Id, AppRegistration__c>)oldMap);
    }
    
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,  List<sObject> oldList, Map<Id, sObject> oldMap) {
        AppRegistrationTriggerHelper.afterUpdate((List<AppRegistration__c>)newList, (Map<Id, AppRegistration__c>)oldMap);
    }
    
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
        
    }
}