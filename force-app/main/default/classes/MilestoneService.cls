/***************************************************************************************** 
Class       : MilestoneService
Author      : Prashant Sahu
Description : Milestone service class
Test Class  : MilestoneServiceTest
Created Date: 06 APR 2026
*****************************************************************************************/
public inherited sharing class MilestoneService {

    private static MilestoneService instance;

    private MilestoneService() {
    }

    public static MilestoneService getInstance() { 
        if(instance == null) {
            instance = new MilestoneService();
        }
        return instance;
    }

    // Update Milestones Without Trigger
    public List<Milestone__c> updateMilestonesWithoutTrigger(List<Milestone__c> milestoneList){
        
        if(milestoneList != null && !milestoneList.isEmpty()){
            MilestoneTriggerHandler.isTriggerDisabled = true;
            update milestoneList;
            MilestoneTriggerHandler.isTriggerDisabled = false;
        }        
        return milestoneList;
    }
}