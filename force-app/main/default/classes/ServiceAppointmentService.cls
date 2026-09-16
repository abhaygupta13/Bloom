/*
*********************************************************
Apex Class Name    : ServiceAppointmentService
Created Date       : Dec 26, 2024
@description       : This class handles record retrieval and DML operations.
Modification Log   :
Ver   Date         : Author                               Modification
4.8   10-09-2026   : Abhay Gupta                          Optimised the class and removed uncommented code
*********************************************************
*/
public inherited sharing class ServiceAppointmentService {
    private ServiceAppointmentService() {}
    
     public static ServiceAppointmentService getInstance() {
        return new ServiceAppointmentService();
    }
    
    public List<ServiceAppointment> insertServiceAppointmentsWithoutTrigger(List<ServiceAppointment> serviceAppointmentList) {
        if(serviceAppointmentList != null && !serviceAppointmentList.isEmpty()) {
            ServiceAppointmentTriggerHandler.isTriggerDisabled = true;
            insert serviceAppointmentList;
            ServiceAppointmentTriggerHandler.isTriggerDisabled = false;
        }
        return serviceAppointmentList;
    }    
    
    public List<ServiceAppointment> insertServiceAppointments(List<ServiceAppointment> serviceAppointmentList) {
        if(serviceAppointmentList != null && !serviceAppointmentList.isEmpty()) {
            insert serviceAppointmentList;
        }
        return serviceAppointmentList;
    }
    
    public List<ServiceAppointment> updateServiceAppointmentsWithoutTrigger(List<ServiceAppointment> serviceAppointmentList) {
        if(serviceAppointmentList != null && !serviceAppointmentList.isEmpty()) {
            ServiceAppointmentTriggerHandler.isTriggerDisabled = true;
            update serviceAppointmentList;
            ServiceAppointmentTriggerHandler.isTriggerDisabled = false;
        }
        return serviceAppointmentList;
    }

    public List<ServiceAppointment> updateServiceAppointments(List<ServiceAppointment> serviceAppointmentList) {
        if(serviceAppointmentList != null && !serviceAppointmentList.isEmpty()) {
            update serviceAppointmentList;
        }
        return serviceAppointmentList;
    }
    
    public List<ServiceAppointment> getServiceAppointmentsByIds(Set<Id> serviceAppointmentSetIds) {
        return [SELECT Id, Status, OwnerId, (SELECT Id FROM ServiceResources), ParentRecordId, SchedStartTime, SchedEndTime FROM ServiceAppointment WHERE Id IN: serviceAppointmentSetIds];
    }
    
    public List<ServiceAppointment> getServiceAppointmentsByParentRecordSetIds(Set<Id> parentRecordIds) {
        return [SELECT Id, ParentRecordId, SchedStartTime, SchedEndTime, Work_Order__r.Scope__c, Status, Job_Status__c, Closure_Reason__c FROM ServiceAppointment WHERE ParentRecordId IN: parentRecordIds ORDER BY CreatedDate ASC];
    }

    public List<ServiceAppointment> getSAByParentRecordIdsOrderByCreatedDateDesc(Set<Id> parentRecordIds) {
        return [SELECT Id, Job_Status__c, Status, Closure_Reason__c FROM ServiceAppointment WHERE ParentRecordId IN :parentRecordIds ORDER BY CreatedDate DESC];
    }

    public List<AggregateResult> getSACountByParentRecordIds(Set<Id> parentRecordIds) {
        return [SELECT ParentRecordId, COUNT(Id) total FROM ServiceAppointment WHERE ParentRecordId IN :parentRecordIds GROUP BY ParentRecordId];
    }
}