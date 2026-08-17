/*****************************************************************************************
Class       : ANPRHandler
Author      : prashant sahu
Description : ANPRHandler
Test Class  : 
Created Date: 17 AUG 2026 
*****************************************************************************************/
public inherited sharing class ANPRHandler {
    private static ANPRHandler instance;
    
    private ANPRHandler() {
        
    }
    
    public static ANPRHandler getInstance() { 
        if(instance == null) {
            instance = new ANPRHandler();
        }
        return instance;
    }
     public  void createFirstTask(List<Case> listOfCases) {
        ServiceRequestTaskHandler obj = ServiceRequestTaskHandler.getInstance();
        obj.createNewAndCloseCurrentTask(listOfCases);
    }
}