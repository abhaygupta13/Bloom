/*****************************************************************************************
Class       : DailyLeadsNotificationBatch
Author      : Dhanraj Poojary
Description : Batch to send lead notification in specific Lead Manager Status
Test Class  : DailyLeadsNotificationBatchTest
Created Date: 03 JUN 2025 
*****************************************************************************************/

public class DailyLeadsNotificationBatch implements Database.Batchable<sObject>, Schedulable,Database.Stateful{
    private static final string MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final string MTD_LEASING_DAILY_REMINDER_EMAIL_TEMPLATE_ID { get { return 'LeasingLeadsDailyReminderETId'; } }
    private static final string MTD_LEASING_TEAM_PROFILE_IDS { get { return 'LeasingTeamProfileIds'; } }
    private static final string MTD_LEAD_MANAGER_STATUS_VALUE { get { return 'LeadManagerStatus'; } }
    
    public DailyLeadsNotificationBatch() {        
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) { 
        MetadataService objMetadataService = MetadataService.getInstance();
        String leadTeamProfileIdValue = objMetadataService.getAppSettingTextValue(MTD_LEASING_TEAM_PROFILE_IDS);
        List<String> leadTeamProfileIdValueList = leadTeamProfileIdValue.split(',');
        String query = 'SELECT Id,Name FROM User WHERE ProfileId IN :leadTeamProfileIdValueList';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<User> scope) {
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        LeadService objLeadService = LeadService.getInstance();
        Id bloomNoReplySalesOWEId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
        EmailTemplate leasingLeadDailyNotificationET = objEmailService.getEmailTemplateById(objMetadataService.getAppSettingTextValue(MTD_LEASING_DAILY_REMINDER_EMAIL_TEMPLATE_ID));
        String leadManagerStatusValue = objMetadataService.getAppSettingTextValue(MTD_LEAD_MANAGER_STATUS_VALUE);
        List<String> leadManagerStatusList = leadManagerStatusValue.split(',');
        Map<Id, User> userMap = new Map<Id, User>(scope);
        List<Lead> leadList = objLeadService.getLeadByOwnerId(userMap.keyset(),leadManagerStatusList);
        Map<String, List<Lead>> ownerLeadMap = new Map<String, List<Lead>>();
        if(!leadList.isEmpty()){
            for(Lead objLead : leadList){
                if(String.isNotBlank(objLead.Owner.Email)){
                    if(!ownerLeadMap.containsKey(objLead.Owner.Email)){
                        ownerLeadMap.put(objLead.Owner.Email, new List<Lead>());
                    }
                    ownerLeadMap.get(objLead.Owner.Email).add(objLead);
                }
            }
            
            for(String ownerEmail : ownerLeadMap.keySet()){
                List<Lead> ownerLeads = ownerLeadMap.get(ownerEmail);
                List<Lead> lstFollowUpLead = new List<Lead>();
                List<Lead> lstWaitingListLead = new List<Lead>();
                
                for(Lead objLead : ownerLeads){
                    if(objLead.LeadManagerStatus__c == 'Follow Up'){
                        lstFollowUpLead.add(objLead);
                    } else if(objLead.LeadManagerStatus__c == 'Waiting List'){
                        lstWaitingListLead.add(objLead);
                    }
                }
                
                if(!lstFollowUpLead.isEmpty() || !lstWaitingListLead.isEmpty()) {
                    String leadFollowUpTable = '';
                    String leadWaitingListTable = '';
                    String emailBody = leasingLeadDailyNotificationET.HtmlValue;
                    String emailSubject = leasingLeadDailyNotificationET.Subject;
                    
                    if(!lstFollowUpLead.isEmpty()){
                        leadFollowUpTable = objEmailService.customLeadTableHeader('Follow Up Leads',true);
                        for(Lead objLead : lstFollowUpLead){
                            leadFollowUpTable += objEmailService.makeTable(objLead,true);
                        }
                        leadFollowUpTable += '</table>';
                    } else {
                        leadFollowUpTable = '<p>No Follow Up Leads</p>';
                    }
                    
                    if(!lstWaitingListLead.isEmpty()){
                        leadWaitingListTable = objEmailService.customLeadTableHeader('Waiting List Leads',true);
                        for(Lead objLead : lstWaitingListLead){
                            leadWaitingListTable += objEmailService.makeTable(objLead,true);
                        }
                        leadWaitingListTable += '</table>';
                    } else {
                        leadWaitingListTable = '<p>No Waiting List Leads</p>';
                    }
                    
                    emailBody = emailBody.replace('{{LEAD_FOLLOWUP_TABLE}}', leadFollowUpTable);
                    emailBody = emailBody.replace('{{LEAD_WAITING_TABLE}}', leadWaitingListTable);
                    
                    Messaging.SingleEmailMessage email = objEmailService.getSingleEmailMessage(
                        new List<String>{ownerEmail},
                        emailSubject,
                        emailBody,
                        bloomNoReplySalesOWEId
                    );
                    objEmailService.sendEmail(new List<Messaging.SingleEmailMessage>{email});
                }
            }
        }
    }
    
    public void finish(Database.BatchableContext bc){
    }
    
    // Scheduling the batch
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new DailyLeadsNotificationBatch(), 1);
    }
}