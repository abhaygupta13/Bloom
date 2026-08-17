public class ServiceTerritoryService {
    private ServiceTerritoryService() {}
    
    public static ServiceTerritoryService getInstance() {
        return new ServiceTerritoryService();
    }
    
    //get ServiceTerritory by Ids 
    public List<ServiceTerritory> getServiceTerritorysByIds(Set<Id> ServiceTerritorySetIds){
        if(!ServiceTerritorySetIds.isEmpty() && ServiceTerritorySetIds.size() > 0){
            return [SELECT Id, Name, Project__c FROM ServiceTerritory WHERE Id IN: ServiceTerritorySetIds];            
        } 
        return null;
    }
    
    //get ServiceTerritory by ProjectIds
    public List<ServiceTerritory> getServiceTerritorysByProjectIds(Set<Id> projectSetIds){
        if(!projectSetIds.isEmpty() && projectSetIds.size() > 0){
            return [SELECT Id, Name, Project__c FROM ServiceTerritory WHERE Project__c IN: projectSetIds];            
        } 
        return null;
    }
}