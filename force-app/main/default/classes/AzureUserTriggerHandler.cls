/*
* @Author : Akshay Khairnar
* @CreatedDate : 11 Jul 2025
* @Description : AzureUserTriggerHandler
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           Biswajeet   07AUG2024        Initial draft 
*****************************************************************************************************/
public without sharing class AzureUserTriggerHandler implements ITriggerHandler {
    
    public static Boolean isTriggerDisabled = false;
    
    public Boolean isDisabled() {
        return isTriggerDisabled;
    }
    
    public void beforeInsert(List<SObject> newList) {
        AzureUserTriggerHelper.handleBeforeInsert((List<User__c>)newList);
    }
    
    public void afterInsert(List<SObject> newList, Map<Id, SObject> newMap) {
        AzureUserTriggerHelper.handleAfterInsert((List<User__c>)newList);
    }
    
    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) {
        AzureUserTriggerHelper.handleBeforeUpdate((List<User__c>)newList,(Map<Id,User__c>)oldMap);
    }
    
    public void afterUpdate(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) {
        AzureUserTriggerHelper.handleAfterUpdate((List<User__c>)newList,(Map<Id,User__c>)oldMap);
        AzureUserTriggerHelper.sendWelcomeEmail((List<User__c>)newList,(Map<Id,User__c>)oldMap);
    }
    
    public void beforeDelete(List<SObject> oldList, Map<Id, SObject> oldMap) {
        
    }
    
    public void afterDelete(List<SObject> oldList, Map<Id, SObject> oldMap) {
        
    }
    
    public void afterUnDelete(List<SObject> newList, Map<Id, SObject> newMap) {
        
    }
}