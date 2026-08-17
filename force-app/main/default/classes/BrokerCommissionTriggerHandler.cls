/*****************************************************************************************
Class       : BrokerCommissionTriggerHandler
Author      : Vikas Baliyan
Description : Broker Commission Trigger Handler
Test Class  : 
Created Date: 10 DEC 2024 
*****************************************************************************************/

public without sharing class BrokerCommissionTriggerHandler implements ITriggerHandler{
    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return isTriggerDisabled;
    }

    
    public void beforeInsert(List<sObject> newList) {
        
    }
    
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        BrokerCommissionTriggerHelper.createDocuments((List<BrokerCommission__c>)newList);
    }
    
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
        BrokerCommissionTriggerHelper.updateBrokerCommission((List<BrokerCommission__c>)newList, (Map<Id, BrokerCommission__c>)newMap, (Map<Id, BrokerCommission__c>)oldMap);
    }
    
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,  List<sObject> oldList, Map<Id, sObject> oldMap) {
        BrokerCommissionTriggerHelper.createIntegrationRecord((List<BrokerCommission__c>)newList, (Map<Id, BrokerCommission__c>)oldMap);
        BrokerCommissionTriggerHelper.sendEmailToRelatedContacts((List<BrokerCommission__c>)newList, (Map<Id, BrokerCommission__c>)oldMap);
        //BrokerCommissionTriggerHelper.invokeThirdApprovalProcess((List<BrokerCommission__c>)newList, (Map<Id, BrokerCommission__c>)oldMap);
    }
    
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
    }
    
    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
        
    }
}