/*
* @Author : Raza Chandankeri
* @CreatedDate : 11th JUN 2025
* @Description : BrokerApplicationTriggerHandler
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           Raza        11JUN2025        Initial draft 
*****************************************************************************************************/
public class BrokerApplicationTriggerHandler implements ITriggerHandler {
    
    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return isTriggerDisabled;
    }
    
    public void beforeInsert(List<sObject> newList) {
    }
    
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        BrokerApplicationTriggerHelper.createDocuments((List<BrokerApplication__c>)newList);
    }
    
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
    }
    
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,  List<sObject> oldList, Map<Id, sObject> oldMap) {
        List<BrokerApplication__c> bAppApprovedList = New List<BrokerApplication__c>();
        BrokerApplication__c oldApp; 
        for (BrokerApplication__c bApp :(List<BrokerApplication__c>) newList){
             oldApp = (BrokerApplication__c) oldMap.get(bApp.Id);
            if (bApp.ApprovalStatus__c == 'Approved'&& oldApp.ApprovalStatus__c != 'Approved'){
                bAppApprovedList.add(bApp);
            }
            
        }
        BrokerApplicationTriggerHelper.checkExistingAndCreateAccount(bAppApprovedList);

        
    }
    
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
        
    }
}