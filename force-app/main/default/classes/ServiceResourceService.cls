public class ServiceResourceService {
    private ServiceResourceService() {}
    
    public static ServiceResourceService getInstance() {
        return new ServiceResourceService();
    }
    
    //get ServiceResource by parentRecordIds
    public List<ServiceResource> getServiceResourcesByRelatedRecordIds(Set<Id> relatedRecordIds){
        if(!relatedRecordIds.isEmpty() && relatedRecordIds.size() > 0){
            return [SELECT Id, RelatedRecordId FROM ServiceResource WHERE RelatedRecordId IN: relatedRecordIds];            
        } 
        return null;
    }
    
    //get ServiceResource by Set Ids
    public List<ServiceResource> getServiceResourcesBySetIds(Set<Id> serviceResourceIds){
        if(!serviceResourceIds.isEmpty() && serviceResourceIds.size() > 0){
            return [SELECT Id, Name, RelatedRecordId, Is_Contractor__c FROM ServiceResource WHERE Id IN :serviceResourceIds];            
        } 
        return null;
    }
    
}