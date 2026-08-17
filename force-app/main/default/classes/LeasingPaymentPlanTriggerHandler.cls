public class LeasingPaymentPlanTriggerHandler implements ITriggerHandler{
    
    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return isTriggerDisabled;
    }
    
    public void beforeInsert(List<sObject> newList) {
        LeasingPaymentScheduleTriggerHelper.applyVatOnCreate((List<PaymentPlanSchedule__c>)newList,null);
    }
    
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        LeasingPaymentScheduleTriggerHelper.createDocuments((List<PaymentPlanSchedule__c>)newList ,(Map<Id,PaymentPlanSchedule__c>)newMap );
    }
    
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
        LeasingPaymentScheduleTriggerHelper.beforeFieldUpdates((List<PaymentPlanSchedule__c>)newList,(Map<Id,PaymentPlanSchedule__c>)oldMap);
        
    }
    
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,  List<sObject> oldList, Map<Id, sObject> oldMap) {
        LeasingPaymentScheduleTriggerHelper.afterFieldUpdates((List<PaymentPlanSchedule__c>)newList,(Map<Id,PaymentPlanSchedule__c>)oldMap);
    }
    
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
        
    }
}