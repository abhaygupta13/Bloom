/*****************************************************************************************
Class       : ContactCenterLeadAssignmentBatch
Author      : Biswajeet
Description : Lead Assignment Batch 
Test Class  : ContactCenterLeadAssignmentBatchTest
Created Date: 29 AUG 2024
*****************************************************************************************/
public class ContactCenterLeadAssignmentBatch implements Database.Batchable<sObject>, Schedulable{
    
    private static final string MTD_CONTACT_CENTER_DIGITAL_QUEUE_ID { get { return 'ContactCenterDigitalQueueId'; } }    
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        MetadataService objMetadataService = MetadataService.getInstance();
        
        Id contactCenterDigitalQueueId = objMetadataService.getAppSettingTextValue(MTD_CONTACT_CENTER_DIGITAL_QUEUE_ID);
        
        Set<Id> ownerIds = new Set<Id> {contactCenterDigitalQueueId};
            
            String query = 'SELECT Id, Name, RoundRobinNumber__c, OwnerId, CreatedById FROM Lead WHERE OwnerId IN :ownerIds';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Lead> scope){
        Set<Id> contactCenterDigitalLeadrecordIds = new Set<ID>();
        
        MetadataService objMetadataService = MetadataService.getInstance();
        Id contactCenterDigitalQueueId = objMetadataService.getAppSettingTextValue(MTD_CONTACT_CENTER_DIGITAL_QUEUE_ID);
        
        for(Lead leadObj : scope){
            if(leadObj.ownerId == contactCenterDigitalQueueId){
                contactCenterDigitalLeadrecordIds.add(leadObj.id); 
            }
        }
        
        if(!contactCenterDigitalLeadrecordIds.isEmpty()){
            AssignmentRuleHandler.salesDigitalLeadAssignment(new List<Id>(contactCenterDigitalLeadrecordIds));  
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        
    }
    
    public void execute(SchedulableContext sc){
        Database.executeBatch(new ContactCenterLeadAssignmentBatch(), 1);
    }
}