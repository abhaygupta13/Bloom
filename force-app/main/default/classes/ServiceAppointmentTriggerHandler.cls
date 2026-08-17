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
public class ServiceAppointmentTriggerHandler implements ITriggerHandler{
    
    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return isTriggerDisabled;
    }
    
    public void beforeInsert(List<sObject> newList) {
        ServiceAppointmentTriggerHelper.updateFirstAppointment((List<ServiceAppointment>) newList);
    }
    
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {   
        
    }
    
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
        ServiceAppointmentTriggerHelper.updateWorkOrderField((List<ServiceAppointment>) newList, (Map<Id, ServiceAppointment>)oldMap);
    }
    
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,  List<sObject> oldList, Map<Id, sObject> oldMap) {
        ServiceAppointmentTriggerHelper.newAppontmentSchedule((List<ServiceAppointment>) newList, (Map<Id, ServiceAppointment>)oldMap);
        ServiceAppointmentTriggerHelper.addContractor((List<ServiceAppointment>) newList, (Map<Id, ServiceAppointment>)oldMap);
        ServiceAppointmentTriggerHelper.sendMailWhenServiceAppointmentScheduled((List<ServiceAppointment>) newList, (Map<Id, ServiceAppointment>)oldMap);
        ServiceAppointmentTriggerHelper.throwErrorOnUpdate((List<ServiceAppointment>) newList, (Map<Id, ServiceAppointment>) oldMap);
        ServiceAppointmentTriggerHelper.updateCancelledFlag((List<ServiceAppointment>) newList, (Map<Id, ServiceAppointment>) oldMap);
        System.debug(+ System.now() + '<< TriggerControl.bypassStatusUpdate _________>>>>' + TriggerControl.bypassStatusUpdate);
        if(TriggerControl.bypassStatusUpdate) {
            System.debug('skip to execute statusUpdate method logic');
            return;
        }else{
            ServiceAppointmentTriggerHelper.statusUpdate((List<ServiceAppointment>) newList, (Map<Id, ServiceAppointment>) oldMap);             
        }
        ServiceAppointmentTriggerHelper.onReschedule((List<ServiceAppointment>) newList, (Map<Id, ServiceAppointment>) oldMap);
    }
    
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
        
    }
}