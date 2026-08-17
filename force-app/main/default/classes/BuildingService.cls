/*
* @Author : Bloom Properties
* @CreatedDate : 
* @Description :  Building Service class
*/
/*****************************************************************************************************
* Version       Author             Date             Comment                                                                       
* 1.0           Bloom Properties   12 Aug 2025     Initial draft 
*****************************************************************************************************/
public inherited sharing class BuildingService {
    
    private static BuildingService instance;
    
    private BuildingService() {
        
    }
    
    public static BuildingService getInstance() { 
        if(instance == null) {
            instance = new BuildingService();
        }
        return instance;
    }
    
    public List<Building__c> getBuildingsForLeasing(String projectId){
        return  [Select Id,Name,Project__c from Building__c where Project__c   =: projectId ORDER BY Name];
    }
}