/*
* @Author : Raza Chandankeri
* @CreatedDate : 11th JUN 2025
* @Description : BrokerApplicantTriggerHandler
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           Raza        11JUN2025        Initial draft 
*****************************************************************************************************/
public class BrokerApplicantTriggerHandler implements ITriggerHandler {
    
    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return isTriggerDisabled;
    }
    
    public void beforeInsert(List<sObject> newList) {
    }
    
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        BrokerApplicantTriggerHelper.createDocuments((List<BrokerApplicant__c>)newList);
    }
    
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
    }
    
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,  List<sObject> oldList, Map<Id, sObject> oldMap) {
        BrokerApplicantTriggerHelper.updateDocument((List<BrokerApplicant__c>) newList,(Map<Id, BrokerApplicant__c>) newMap,(List<BrokerApplicant__c>) oldList,(Map<Id, BrokerApplicant__c>) oldMap);
    }
    
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
        
    }
}