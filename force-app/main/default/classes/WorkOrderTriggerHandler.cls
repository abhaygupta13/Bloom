/*
* @Author : Biswajeet Samal
* @CreatedDate : 7th AUG 2024
* @Description : Unit object trigger handler
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           Biswajeet   07AUG2024        Initial draft 
* 2.0           Jayprakash  20AUG2024        Implemented GIS Integration
* 3.0           Abhay       09SEP2026        Optimized the class and removed uncommented code
*****************************************************************************************************/
public without sharing class WorkOrderTriggerHandler implements ITriggerHandler {
    
    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;

    //check if the trigger is disabled from transaction
    public Boolean isDisabled() {
        return isTriggerDisabled;
    }
    
    public void beforeInsert(List<sObject> newList) {
        WorkOrderTriggerHelper.autoPopulateFields((List<WorkOrder>) newList); 
        WorkOrderTriggerHelper.createEntitlementOnWorkOrder((List<WorkOrder>) newList);
    }
    
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        WorkOrderTriggerHelper.createServiceAppointment(newList);
    }
    
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
        WorkOrderTriggerHelper.updateWorkOrder((List<WorkOrder>) newList, (Map<Id, WorkOrder>)oldMap);
        WorkOrderTriggerHelper.updateResolutionPriority((List<WorkOrder>) newList, (Map<Id, WorkOrder>)oldMap);
    }
    
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,  List<sObject> oldList, Map<Id, sObject> oldMap) {
        WorkOrderTriggerHelper.processWorkOrders((List<WorkOrder>) newList, (Map<Id, WorkOrder>)oldMap);
        WorkOrderTriggerHelper.closeServiceAppointmentsOnWorkOrderClosure((List<WorkOrder>) newList, (Map<Id, WorkOrder>)oldMap);
    }
    
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
        
    }
}