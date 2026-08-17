/*****************************************************************************************
Class       : OpportunityAutoCloseBatch
Author      : Dhanraj Poojary
Description : Batch to close opportunity without Sales Order
Test Class  : OpportunityAutoCloseBatchTest
Created Date: 16 JUL 2025 
*****************************************************************************************/

public class OpportunityAutoCloseBatch implements Database.Batchable<SObject>, Schedulable {
    
    private static final string MTD_OPPORTUNITY_AUTO_CLOSE_DAYS_VALUE { get { return 'OpportunityAutoCloseDays'; } }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        MetadataService objMetadataService = MetadataService.getInstance();
        Integer autoCloseDays = objMetadataService.getAppSettingNumberValue(MTD_OPPORTUNITY_AUTO_CLOSE_DAYS_VALUE);
        Date autoCloseDate = System.today().addDays(-autoCloseDays);
        return Database.getQueryLocator([
            SELECT Id, StageName,
            (SELECT Id FROM OpportunityUnitsOpportunity__r LIMIT 1)
            FROM Opportunity
            WHERE OpportunityType__c != 'Leasing'
            AND StageName NOT IN ('Closed Lost', 'Closed Won')
            AND CreatedDate < :autoCloseDate
        ]);
    }
    
    public void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        OpportunityService objOpportunityService = OpportunityService.getInstance();
        Set<Id> oppIds = new Set<Id>();
        Set<Id> oppIdsWithOrders = new Set<Id>();
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        
        for (Opportunity opp : scope) {
            if (opp.OpportunityUnitsOpportunity__r == null || opp.OpportunityUnitsOpportunity__r.isEmpty()) {
                opp.StageName = 'Closed Lost';
                opp.LossReason__c = 'Auto Closed';
                opp.LossComments__c = 'No Sales Order was created in last 30 days';
                oppsToUpdate.add(opp);
            }
        }
        objOpportunityService.updateOpportunitiesWithoutTrigger(oppsToUpdate);
    }
    
    public void finish(Database.BatchableContext bc) {
        
    }
    
    // Scheduling the batch
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new OpportunityAutoCloseBatch(), 200);
    }
}