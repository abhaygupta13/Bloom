public class LeasingOtherChargesTriggerHandler implements ITriggerHandler{
    
    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return isTriggerDisabled;
    }
    
    public void beforeInsert(List<sObject> newList) {
        LeasingOtherChargesTriggerHelper.beforeInsertActions((List<LeasingOrdersOtherCharges__c>) newList);
        LeasingOtherChargesTriggerHelper.applyVatOnCreate((List<LeasingOrdersOtherCharges__c>) newList);
    }
    
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        LeasingOtherChargesTriggerHelper.afterInsertActions((List<LeasingOrdersOtherCharges__c>)newList,(Map<Id,LeasingOrdersOtherCharges__c>)newMap);
        LeasingOtherChargesTriggerHelper.createDocuments((List<LeasingOrdersOtherCharges__c>)newList ,(Map<Id,LeasingOrdersOtherCharges__c>)newMap );
    }
    
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
        LeasingOtherChargesTriggerHelper.beforeFieldUpdates((List<LeasingOrdersOtherCharges__c>)newList,(Map<Id,LeasingOrdersOtherCharges__c>)oldMap);
    }
    
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,  List<sObject> oldList, Map<Id, sObject> oldMap) {
        LeasingOtherChargesTriggerHelper.afterFieldUpdates((List<LeasingOrdersOtherCharges__c>)newList,(Map<Id,LeasingOrdersOtherCharges__c>)oldMap);
    }
    
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
        
    }
}