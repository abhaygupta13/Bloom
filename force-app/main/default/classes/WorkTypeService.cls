public with sharing class WorkTypeService {
    public WorkTypeService() {}
    
    //get WorkType by name
    public static WorkType getWorkTypeRecord(String wtName){
        if(String.isNotBlank(wtName)){
            return [SELECT Id, Name FROM WorkType WHERE Name = :wtName LIMIT 1];            
        } 
        return null;
    }
    
}