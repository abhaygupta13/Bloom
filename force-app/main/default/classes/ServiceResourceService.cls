/*
*********************************************************
Apex Class Name    : ServiceResourceService
@description       : This class handles record retrieval and DML operations.
Modification Log   :
Ver   Date         : Author                               Modification
1.2   18-09-2026   : Abhay Gupta                          Optimised the class and removed uncommented code
*********************************************************
*/
public inherited sharing class ServiceResourceService {
    private ServiceResourceService() {}
    
    public static ServiceResourceService getInstance() {
        return new ServiceResourceService();
    }
    
    public List<ServiceResource> getServiceResourcesByRelatedRecordIds(Set<Id> relatedRecordIds) {
        return [SELECT Id, RelatedRecordId FROM ServiceResource WHERE RelatedRecordId IN: relatedRecordIds];            
    }
    
    public List<ServiceResource> getServiceResourceByIds(Set<Id> serviceResourceIds) {
        return [SELECT Id, Name, RelatedRecordId, Is_Contractor__c FROM ServiceResource WHERE Id IN :serviceResourceIds];            
    }
    
}