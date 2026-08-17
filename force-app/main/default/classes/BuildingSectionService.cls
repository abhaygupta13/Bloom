/*
* @Author : EaglesDev
* @CreatedDate : 9th Nov 2024
* @Description :  BuildingSection Service class
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           EaglesDev   9th Nov 2024    Initial draft 
*****************************************************************************************************/

public inherited sharing class BuildingSectionService {
    
    private static BuildingSectionService instance;
    
    public BuildingSectionService() {
        
    }
    
    public static BuildingSectionService getInstance() { 
        if(instance == null) {
            instance = new BuildingSectionService();
        }
        return instance;
    }
    
    public List<BuildingSection__c> getBuildingsByProject(String projectName){
        return [select Name,Project__r.City__c from BuildingSection__c where Project__c=:projectName AND isEnabledMIP__c=true];
    }
    
    public List<BuildingSection__c> getBuildingsForLeasing(String projectId){
        return  [Select Id,Name from BuildingSection__c where Project__c   =: projectId ORDER BY Name];
    }
    public List<BuildingSection__c> getBuildingsByProject(String projectName,Boolean isEnableMIP){
        
         String query = 'select Name,Project__r.City__c from BuildingSection__c where Project__c=:projectName';
    
        if (isEnableMIP != null && isEnableMIP) {
            query += ' AND isEnabledMIP__c = true';
        }
        
        return Database.query(query);
    }

}