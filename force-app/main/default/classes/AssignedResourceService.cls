/*
*********************************************************
Apex Class Name    : AssignedResourceService
Created Date       : Dec 26, 2024
@description       : This class handles record retrieval and DML operations.
Modification Log   :
Ver   Date         : Author                               Modification
4.8   10-09-2026   : Abhay Gupta                          Optimised the class and removed uncommented code
*********************************************************
*/
public inherited sharing class AssignedResourceService {
    private AssignedResourceService() {}
    
    public static AssignedResourceService getInstance() {
        return new AssignedResourceService();
    }
    
    public List<AssignedResource> insertAssignedResources(List<AssignedResource> AssignedResourceList) {
        if(AssignedResourceList != null && !AssignedResourceList.isEmpty()){
            insert AssignedResourceList;
        }
        return AssignedResourceList;
    }  
    
    public List<AssignedResource> getAssignedResourcesByServiceAppointmentIds(Set<Id> serviceAppointmentIds) {
        return [SELECT Id, ServiceResourceId, ServiceResource.RelatedRecordId,ServiceResource.ResourceType, ServiceAppointmentId, ServiceResource.Is_Contractor__c FROM AssignedResource WHERE ServiceAppointmentId IN :serviceAppointmentIds];
    }
}