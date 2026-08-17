/*****************************************************************************************
Class       : ProjectSalesTargetService
Author      : Aman Bharti
Description : Project Sales Target Service
Test Class  : 
Created Date: 03 OCT 2025
*****************************************************************************************/
public inherited sharing class ProjectSalesTargetService {

    private static ProjectSalesTargetService instance;
    
    private ProjectSalesTargetService() {
        
    }
    
    public static ProjectSalesTargetService getInstance() { 
        if(instance == null) {
            instance = new ProjectSalesTargetService();
        }
        return instance;
    }
    
    public List<ProjectSalesTarget__c> updateProjectSalesTargets(List<ProjectSalesTarget__c> projectSalesTargetList){
        if(projectSalesTargetList != NULL && !projectSalesTargetList.isEmpty()){
            update projectSalesTargetList;
        }
        return projectSalesTargetList;
    }
}