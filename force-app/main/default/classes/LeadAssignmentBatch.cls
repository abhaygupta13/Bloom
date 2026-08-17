/*****************************************************************************************
Class       : LeadAssignmentBatch
Author      : Biswajeet
Description : Lead Assignment Batch 
Test Class  : LeadAssignmentBatchTest
Created Date: 29 AUG 2024
Modified By : Prashant Sahu
Modified On : 05 AUG 2026
Modification: Added ADHA Lead Queue assignment support using
AadhaSalesLeadQueueId App Setting.
*****************************************************************************************/
public class LeadAssignmentBatch implements Database.Batchable<sObject>, Schedulable{
    
    private static final string MTD_SALES_QUALIFIED_LEAD_DIGITAL_QUEUE_ID { get { return 'SalesQualifiedLeadDigitalQueueId'; } }
    private static final string MTD_LEASING_QUALIFIED_LEAD_DIGITAL_QUEUE_ID { get { return 'LeasingQualifiedLeadDigitalQueueId'; } }
    private static final String MTD_ADHA_SALES_LEAD_QUEUE_ID {get { return 'AadhaSalesLeadQueueId'; }} 
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        MetadataService objMetadataService = MetadataService.getInstance();
        
        Id salesQualifiedLeadDigitalQueueId =  objMetadataService.getAppSettingTextValue(MTD_SALES_QUALIFIED_LEAD_DIGITAL_QUEUE_ID);
        Id leasingQualifiedLeadDigitalQueueId =  objMetadataService.getAppSettingTextValue(MTD_LEASING_QUALIFIED_LEAD_DIGITAL_QUEUE_ID);
        Id adhaSalesLeadQueueId =objMetadataService.getAppSettingTextValue(MTD_ADHA_SALES_LEAD_QUEUE_ID); 
        
        Set<Id> ownerIds = new Set<Id> {salesQualifiedLeadDigitalQueueId, leasingQualifiedLeadDigitalQueueId,adhaSalesLeadQueueId};  
        Set<String> excludedStatuses = new Set<String>{'Closed', 'Converted'};
            
            String query = 'SELECT Id, Name, RoundRobinNumber__c, OwnerId, CreatedById ' +'FROM Lead ' +'WHERE OwnerId IN :ownerIds ' 
            +'AND IsConverted = false ' +'AND Status NOT IN :excludedStatuses';
        
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Lead> scope){
        
        Set<Id> salesQualifiedLeadrecordIds = new Set<ID>();
        Set<Id> leasingQualifiedLeadrecordIds = new Set<ID>();
        Set<Id> adhaLeadRecordIds = new Set<Id>();
        
        MetadataService objMetadataService = MetadataService.getInstance();
        
        Id salesQualifiedLeadDigitalQueueId =  objMetadataService.getAppSettingTextValue(MTD_SALES_QUALIFIED_LEAD_DIGITAL_QUEUE_ID);
        Id leasingQualifiedLeadDigitalQueueId =  objMetadataService.getAppSettingTextValue(MTD_LEASING_QUALIFIED_LEAD_DIGITAL_QUEUE_ID);
        Id adhaSalesLeadQueueId = objMetadataService.getAppSettingTextValue(MTD_ADHA_SALES_LEAD_QUEUE_ID);
        
        for(Lead leadObj : scope){
            if(leadObj.ownerId == salesQualifiedLeadDigitalQueueId){
                salesQualifiedLeadrecordIds.add(leadObj.id); 
            }else if(leadObj.ownerId == leasingQualifiedLeadDigitalQueueId){
                leasingQualifiedLeadrecordIds.add(leadObj.id);
            }
            else if (leadObj.OwnerId == adhaSalesLeadQueueId) {
                adhaLeadRecordIds.add(leadObj.Id);
            } 
        }
        
        if(!salesQualifiedLeadrecordIds.isEmpty()){
            AssignmentRuleHandler.salesDigitalQualifiedLeadAssignment(new List<Id>(salesQualifiedLeadrecordIds));  
        }
        if(!leasingQualifiedLeadrecordIds.isEmpty()){
            AssignmentRuleHandler.leasingQualifiedLeadAssignment(new List<Id>(leasingQualifiedLeadrecordIds));  
        }
        if (!adhaLeadRecordIds.isEmpty()) {
            AssignmentRuleHandler.adhaLeadAssignment(new List<Id>(adhaLeadRecordIds)); 
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        
    }
    
    public void execute(SchedulableContext sc){
        Database.executeBatch(new LeadAssignmentBatch(), 1);
    }
}