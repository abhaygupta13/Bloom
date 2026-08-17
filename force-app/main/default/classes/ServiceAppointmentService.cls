public class ServiceAppointmentService {
    private ServiceAppointmentService() {}
    
     public static ServiceAppointmentService getInstance() {
        return new ServiceAppointmentService();
    }
    
    //Insert ServiceAppointment without trigger
    public List<ServiceAppointment> insertServiceAppointmentsWithoutTrigger(List<ServiceAppointment> serviceAppointmentList){
        if(serviceAppointmentList != NULL && !serviceAppointmentList.isEmpty()){
            ServiceAppointmentTriggerHandler.isTriggerDisabled = true;
            insert serviceAppointmentList;
            ServiceAppointmentTriggerHandler.isTriggerDisabled = false;
        }
        return serviceAppointmentList;
    }    
    
    
    //Insert ServiceAppointment with trigger
    public List<ServiceAppointment> insertServiceAppointmentsWithTrigger(List<ServiceAppointment> serviceAppointmentList){
        if(serviceAppointmentList != NULL && !serviceAppointmentList.isEmpty()){
            insert serviceAppointmentList;
        }
        return serviceAppointmentList;
    }
    
    //Update ServiceAppointment without trigger
    public List<ServiceAppointment> updateServiceAppointmentsWithoutTrigger(List<ServiceAppointment> serviceAppointmentList){
        if(serviceAppointmentList != NULL && !serviceAppointmentList.isEmpty()){
            ServiceAppointmentTriggerHandler.isTriggerDisabled = true;
            update serviceAppointmentList;
            ServiceAppointmentTriggerHandler.isTriggerDisabled = false;
        }
        return serviceAppointmentList;
    }    
    
    //Update ServiceAppointment with trigger
    public List<ServiceAppointment> updateUnits(List<ServiceAppointment> serviceAppointmentList){
        if(serviceAppointmentList != NULL && !serviceAppointmentList.isEmpty()){
            update serviceAppointmentList;
        }
        return serviceAppointmentList;
    }
    
    //get ServiceAppointments by Ids
    public List<ServiceAppointment> getServiceAppointmentsByIds(Set<Id> serviceAppointmentSetIds){
        if(!serviceAppointmentSetIds.isEmpty() && serviceAppointmentSetIds.size() > 0){
            return [SELECT Id, Status, OwnerId, (SELECT Id FROM ServiceResources), ParentRecordId, SchedStartTime, SchedEndTime FROM ServiceAppointment WHERE Id IN: serviceAppointmentSetIds];  // NEW CHANGES          
        } 
        return null;
    }
    
    //get ServiceAppointments by parentRecordIds
    public List<ServiceAppointment> getServiceAppointmentsByParentRecordIds(List<sObject> parentRecordIds){
        if(!parentRecordIds.isEmpty() && parentRecordIds.size() > 0){
            return [SELECT Id, ParentRecordId,Job_Status__c, SchedStartTime, SchedEndTime, Status FROM ServiceAppointment WHERE ParentRecordId IN: parentRecordIds];            
        } 
        return null;
    }
    
    //get ServiceAppointments by parentRecordIds
    public List<ServiceAppointment> getServiceAppointmentsByParentRecordSetIds(Set<Id> parentRecordIds){
        if(!parentRecordIds.isEmpty() && parentRecordIds.size() > 0){
            return [SELECT Id, ParentRecordId, SchedStartTime, SchedEndTime FROM ServiceAppointment WHERE ParentRecordId IN: parentRecordIds ORDER BY CreatedDate ASC];            
        } 
        return null;
    }
}