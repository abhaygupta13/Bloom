public class AssignedResourceService {
    private AssignedResourceService() {}
    
    public static AssignedResourceService getInstance() {
        return new AssignedResourceService();
    }
    
    //Insert AssignedResource without trigger
    public List<AssignedResource> insertAssignedResourcesWithoutTrigger(List<AssignedResource> AssignedResourceList){
        if(AssignedResourceList != NULL && !AssignedResourceList.isEmpty()){
            //AssignedResourceTriggerHandler.isTriggerDisabled = true;
            insert AssignedResourceList;
            //AssignedResourceTriggerHandler.isTriggerDisabled = false;
        }
        return AssignedResourceList;
    }
    
    //Insert AssignedResource with trigger
    public List<AssignedResource> insertAssignedResourcesWithTrigger(List<AssignedResource> AssignedResourceList){
        if(AssignedResourceList != NULL && !AssignedResourceList.isEmpty()){
            insert AssignedResourceList;
        }
        return AssignedResourceList;
    }
    
    //Update AssignedResource without trigger
    public List<AssignedResource> updateServiceAppointmentsWithoutTrigger(List<AssignedResource> AssignedResourceList){
        if(AssignedResourceList != NULL && !AssignedResourceList.isEmpty()){
            //AssignedResourceTriggerHandler.isTriggerDisabled = true;
            update AssignedResourceList;
            //AssignedResourceTriggerHandler.isTriggerDisabled = false;
        }
        return AssignedResourceList;
    }    
    
    //Update AssignedResource
    public List<AssignedResource> updateUnits(List<AssignedResource> AssignedResourceList){
        if(AssignedResourceList != NULL && !AssignedResourceList.isEmpty()){
            update AssignedResourceList;
        }
        return AssignedResourceList;
    } 
    
     //get AssignedResources by ServiceAppointmentIds
    public List<AssignedResource> getAssignedResourcesByServiceAppointmentSetIds(Set<Id> serviceAppointmentIds){
        if(!serviceAppointmentIds.isEmpty() && serviceAppointmentIds.size() > 0){
            return [SELECT Id, ServiceResource.RelatedRecordId,ServiceResource.ResourceType, ServiceAppointmentId, ServiceResource.Is_Contractor__c FROM
                    AssignedResource WHERE ServiceAppointmentId IN :serviceAppointmentIds];            
        } 
        return null;
    }
}