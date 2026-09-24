/*
* @Author : Biswajeet Samal
* @CreatedDate : 7th AUG 2024
* @Description : Unit object trigger handler
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           Biswajeet   07AUG2024        Initial draft 
* 2.0           Jayprakash  20AUG2024        Implemented GIS Integration
* 3.0           Abhay       18SEP2026        Renamed method names
*****************************************************************************************************/
public without sharing class ServiceAppointmentTriggerHandler implements ITriggerHandler {
    
    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return isTriggerDisabled;
    }
    
    public void beforeInsert(List<sObject> newList) {
        ServiceAppointmentTriggerHelper.populateSAFieldsFromWorkOrder((List<ServiceAppointment>) newList);
    }
    
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {   
        ServiceAppointmentTriggerHelper.sendNewFSLAppointmentNotification((List<ServiceAppointment>) newList);
    }
    
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
        ServiceAppointmentTriggerHelper.validateServiceAppointmentBeforeUpdate((List<ServiceAppointment>) newList, (Map<Id, ServiceAppointment>) oldMap);
        ServiceAppointmentTriggerHelper.populateSAFields((List<ServiceAppointment>) newList, (Map<Id, ServiceAppointment>)oldMap);
        ServiceAppointmentTriggerHelper.populateOwnerIdOnSA((List<ServiceAppointment>) newList, (Map<Id, ServiceAppointment>)oldMap);
        ServiceAppointmentTriggerHelper.populateWorkTypeIdOnSA((List<ServiceAppointment>) newList, (Map<Id, ServiceAppointment>) oldMap);             
    }
    
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,  List<sObject> oldList, Map<Id, sObject> oldMap) {
        ServiceAppointmentTriggerHelper.updateStatusAndOwnerIdonWorkOrder((List<ServiceAppointment>) newList, (Map<Id, ServiceAppointment>)oldMap);
        ServiceAppointmentTriggerHelper.addContractor((List<ServiceAppointment>) newList, (Map<Id, ServiceAppointment>)oldMap);
        ServiceAppointmentTriggerHelper.sendMailWhenServiceAppointmentScheduled((List<ServiceAppointment>) newList, (Map<Id, ServiceAppointment>)oldMap);
        ServiceAppointmentTriggerHelper.cancelWorkOrder((List<ServiceAppointment>) newList, (Map<Id, ServiceAppointment>) oldMap);
        ServiceAppointmentTriggerHelper.resetMilestoneOnWorkOrder((List<ServiceAppointment>) newList, (Map<Id, ServiceAppointment>) oldMap);
        ServiceAppointmentTriggerHelper.sendSARescheduleNotification((List<ServiceAppointment>) newList, (Map<Id, ServiceAppointment>) oldMap);
    }
    
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
        
    }
}