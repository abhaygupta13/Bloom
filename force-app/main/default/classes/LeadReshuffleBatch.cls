/*****************************************************************************************
Class       : LeadReshuffleBatch
Author      : Dhanraj Poojary
Description : Batch to reshuffle leads if thereis no activity for more than 2 hours
Test Class  : LeadReshuffleBatchTest
Created Date: 21 JUL 2025 
*****************************************************************************************/

public class LeadReshuffleBatch implements Database.Batchable<SObject>, Schedulable {
    
    private static final string MTD_LEAD_PAST_HOURS_VALUE { get { return 'LeadReshuffleHours'; } }
    private static final string MTD_SM_BUSINESSHOURS_ID { get { return 'SMBusinessHoursId'; } }
    private static final string MTD_LEAD_RESHUFFLE_CREATED_DATE { get { return 'LeadReshuffleCreatedDate'; } }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        MetadataService objMetadataService = MetadataService.getInstance();
        Date leadReshuffleCreatedDate = objMetadataService.getAppSettingDateValue(MTD_LEAD_RESHUFFLE_CREATED_DATE);
        return Database.getQueryLocator([
            SELECT Id, LeadManagerAssignedDate__c, LeadManagerStatus__c, Status, LeadTeam__c, CreatedById, OwnerId
            FROM Lead
            WHERE Status NOT IN('Closed','Converted')
            AND LeadManagerStatus__c = 'New'
            AND LeadManagerAssignedDate__c != NULL
            AND IsConverted = FALSE
            AND IsDraftLead__c = false
            AND LeadTeam__c = 'Sales'
            AND CreatedDate >= :leadReshuffleCreatedDate
        ]);
    }
    
    public void execute(Database.BatchableContext bc, List<Lead> scope) {
        MetadataService objMetadataService = MetadataService.getInstance();
        AssignmentRuleService objAssignmentService = AssignmentRuleService.getInstance();
        LeadService objLeadService = LeadService.getInstance();
        BusinessHoursService objBHService = BusinessHoursService.getInstance();
        Integer leadPastHours = objMetadataService.getAppSettingNumberValue(MTD_LEAD_PAST_HOURS_VALUE);
        Id smBusinessHoursId = objMetadataService.getAppSettingTextValue(MTD_SM_BUSINESSHOURS_ID);
        Set<Id> reshuffleLeadIds = new Set<Id>();
        List<Lead> leadUpdateList = new List<Lead>();
        for (Lead objLead : scope) {
            if (objBHService.hasExceededNoOfHours(smBusinessHoursId,objLead.LeadManagerAssignedDate__c,leadPastHours) && objLead.CreatedById != objLead.OwnerId) {
                reshuffleLeadIds.add(objLead.Id);
            }
        }
        if(!reshuffleLeadIds.isEmpty()){
            leadUpdateList = AssignmentRuleHandler.salesLeadReshuffle(reshuffleLeadIds);
            objLeadService.updateLeadsWithoutDuplicateRule(leadUpdateList); 
        }
    }
    
    public void finish(Database.BatchableContext bc) {
    }
    
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new LeadReshuffleBatch(), 200);
    }
}