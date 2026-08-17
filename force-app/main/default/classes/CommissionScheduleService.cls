/*****************************************************************************************
Class       : CommissionScheduleService
Author      : Aman Bharti
Description : CommissionSchedule Service 
Test Class  : 
Created Date: 01 APR 2026 
*****************************************************************************************/
public inherited sharing class CommissionScheduleService {
    private static CommissionScheduleService instance;
    private CommissionScheduleService() { }
    
    public static CommissionScheduleService getInstance() {
        if(instance == null) {
            instance = new CommissionScheduleService();
        }
        return instance;
    }

    public List<CommissionSchedule__c> getCommissionSchedule(){
        return [SELECT Id,BrokerAccount__c FROM CommissionSchedule__c WHERE BrokerAccount__c != null AND ApprovalStatus__c = 'Approved'];
    }
}