/***
Class       : LeasingEscalationScheduleService
Author      : 
Description : 
TestClass   : 
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
****************************************************************************************************************/
public inherited sharing class LeasingEscalationScheduleService {
    
    private static LeasingEscalationScheduleService instance;
    
    private LeasingEscalationScheduleService() {
        
    }
    
    public static LeasingEscalationScheduleService getInstance() { 
        if(instance == null) {
            instance = new LeasingEscalationScheduleService();
        }
        return instance;
    }
    
    public List<LeasingEscalationSchedule__c> getEscalationSchedulesByContractId(Id contractId){
        return [SELECT Id,Year__c,AnnualRent__c,Escalation__c,TotalRent__c,AfterDiscount__c FROM LeasingEscalationSchedule__c
                WHERE LeasingOrder__c = :contractId  ORDER BY Year__c];
    }
    
    public List<LeasingEscalationSchedule__c> insertLeasingEscalationSchedule(List<LeasingEscalationSchedule__c> escalationScheduleList){
        if(escalationScheduleList != NULL && !escalationScheduleList.isEmpty()){
            insert escalationScheduleList;
        }
        return escalationScheduleList; 
    } 
    
    public void deleteEscSchedules(List<LeasingEscalationSchedule__c> escalationScheduleList){
        if(escalationScheduleList != NULL && !escalationScheduleList.isEmpty()){
            delete escalationScheduleList;
        }
    }    
}