/*****************************************************************************************
Class       : LeadReshuffleBatch
Author      : Dhanraj Poojary
Modified By : Prashant Sahu
Description : Batch to monitor the Sales Lead Action SLA and automatically
reshuffle leads when the configured Lead Reshuffle SLA is
breached. The SLA duration is configurable through the
LeadReshuffleHours App Setting (Custom Metadata).
Leads are reassigned using Round Robin for a maximum of
two reshuffles. After the second reshuffle, the lead is
assigned to the Head of Sales and a new 1-hour SLA begins.
Test Class  : LeadReshuffleBatchTest
Created Date: 21 Jul 2025
Modified Date: 24 Jul 2026
*****************************************************************************************/

public without sharing class LeadReshuffleBatch implements Database.Batchable<SObject>, Schedulable {
    
    private static final string MTD_LEAD_PAST_HOURS_VALUE { get { return 'LeadReshuffleHours'; } }
    private static final string MTD_SM_BUSINESSHOURS_ID { get { return 'SMBusinessHoursId'; } }
    private static final string MTD_LEAD_RESHUFFLE_CREATED_DATE { get { return 'LeadReshuffleCreatedDate'; } }
    private static final String MTD_SALES_MANAGER_PROFILE_ID {get { return 'SalesManagerProfileIds'; }}
    private static final String MTD_HEAD_OF_SALES_USER_ID { get { return 'HeadOfSalesUserId'; } }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        MetadataService objMetadataService = MetadataService.getInstance();
        Date leadReshuffleCreatedDate = objMetadataService.getAppSettingDateValue(MTD_LEAD_RESHUFFLE_CREATED_DATE);
        Id salesManagerProfileId = (Id)objMetadataService.getAppSettingTextValue(MTD_SALES_MANAGER_PROFILE_ID);
        
        return Database.getQueryLocator([
            SELECT Id, LeadManagerAssignedDate__c, Status, LeadTeam__c, CreatedById, OwnerId, ReshuffleCount__c FROM Lead 
            WHERE Status NOT IN ('Closed', 'Converted') 
            AND LeadManagerAssignedDate__c != NULL 
            AND IsConverted = FALSE AND IsDraftLead__c = FALSE 
            AND LeadTeam__c = 'Sales' 
            AND Owner.ProfileId = :salesManagerProfileId 
            AND CreatedDate >= :leadReshuffleCreatedDate ]);  //FOR TESTING HARDCODE ID PUT //Id ='00QFV008NyTvlVs2IJ' AND
    }
    
    public void execute(Database.BatchableContext bc, List<Lead> scope) {
        
        MetadataService objMetadataService = MetadataService.getInstance();
        LeadService objLeadService = LeadService.getInstance();
        BusinessHoursService objBHService = BusinessHoursService.getInstance();
        
        Integer leadPastHours = objMetadataService.getAppSettingNumberValue(MTD_LEAD_PAST_HOURS_VALUE);  //IN METADATA VALUE => 3
        //   Integer leadPastHours = 1; //for testing 
        
        Id smBusinessHoursId = objMetadataService.getAppSettingTextValue(MTD_SM_BUSINESSHOURS_ID);
        Id headOfSalesId = objMetadataService.getAppSettingTextValue(MTD_HEAD_OF_SALES_USER_ID);  //added 
        
        
        Set<Id> reshuffleLeadIds = new Set<Id>();
        List<Lead> leadUpdateList = new List<Lead>();
        List<Lead> finalLeadtoUpdate = new List<Lead>();
        for (Lead objLead : scope) {
            
            if (objBHService.hasExceededNoOfHour(smBusinessHoursId,objLead.LeadManagerAssignedDate__c,leadPastHours)&& objLead.CreatedById != objLead.OwnerId) {
                Integer reshuffleCount = objLead.ReshuffleCount__c == null ? 0 : Integer.valueOf(objLead.ReshuffleCount__c);
                if (reshuffleCount < 2) {
                    reshuffleLeadIds.add(objLead.Id); 
                } else {
                    objLead.OwnerId = headOfSalesId;
                    objLead.ReshuffleCount__c = 3;
                    objLead.LeadManagerAssignedDate__c = System.now();      // Start Head of Sales 1-hour SLA
                    finalLeadtoUpdate.add(objLead);
                } 
            }
        }
        if(!reshuffleLeadIds.isEmpty()){
            leadUpdateList = AssignmentRuleHandler.salesLeadReshuffle(reshuffleLeadIds);
            for(Lead ld : leadUpdateList){
                Integer reshuffleCount = ld.ReshuffleCount__c == null ? 0 : Integer.valueOf(ld.ReshuffleCount__c);
                ld.ReshuffleCount__c = reshuffleCount + 1;
            }
            if(leadUpdateList !=  null && !leadUpdateList.isEmpty()){
                finalLeadtoUpdate.addAll(leadUpdateList);
            }
            objLeadService.updateLeadsWithoutDuplicateRule(finalLeadtoUpdate);   
        }
    }
    
    public void finish(Database.BatchableContext bc) {
    }
    
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new LeadReshuffleBatch(), 200);
    }
    
}