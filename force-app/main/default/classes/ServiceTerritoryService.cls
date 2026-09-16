/*
*********************************************************
Apex Class Name    : ServiceTerritoryService
Created Date       : Dec 26, 2024
@description       : This class handles record retrieval and DML operations.
Modification Log   :
Ver   Date         : Author                               Modification
4.8   10-09-2026   : Abhay Gupta                          Optimised the class and removed uncommented code
*********************************************************
*/
public inherited sharing class ServiceTerritoryService {
    
    private ServiceTerritoryService() {}
    
    public static ServiceTerritoryService getInstance() {
        return new ServiceTerritoryService();
    }
    
    public List<ServiceTerritory> getServiceTerritorysByProjectIds(Set<Id> projectSetIds) {
        return [SELECT Id, Name, Project__c FROM ServiceTerritory WHERE Project__c IN: projectSetIds];
    }
}