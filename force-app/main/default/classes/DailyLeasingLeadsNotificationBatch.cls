/*****************************************************************************************
Class       : DailyLeasingLeadsNotificationBatch
Author      : Dhanraj Poojary
Description : Batch to send payment reminder notification of Payment Installments
Test Class  : DailyLeasingLeadsNotificationBatchTest
Created Date: 03 JUN 2025 
*****************************************************************************************/

public class DailyLeasingLeadsNotificationBatch implements Database.Batchable<sObject>, Schedulable,Database.Stateful{
    private static final string MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final string MTD_LEASING_DAILY_REMINDER_EMAIL_TEMPLATE_ID { get { return 'LeasingLeadsDailyReminderETId'; } }
    
    public DailyLeasingLeadsNotificationBatch() {        
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) { 
        String query = 'SELECT Id,Name FROM Project__c';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Project__c> scope) {
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        LeadService objLeadService = LeadService.getInstance();
        Id bloomNoReplySalesOWEId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
        EmailTemplate leasingLeadDailyNotificationET = objEmailService.getEmailTemplateById(objMetadataService.getAppSettingTextValue(MTD_LEASING_DAILY_REMINDER_EMAIL_TEMPLATE_ID));
        List<String> projectList = new List<String>();
        List<String> leadManagerStatusList = new List<String>{'Follow Up','Waiting List'};
            
        for(Project__c objProject : scope){  
           projectList.add(objProject.Name);
        }
        List<Lead> leadList = objLeadService.getLeadByProject(projectList,leadManagerStatusList);
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
                
                String leadFollowUpTable = '';
                String leadWaitingListTable = '';
                String emailBody = leasingLeadDailyNotificationET.HtmlValue;
                String emailSubject = leasingLeadDailyNotificationET.Subject;
                
                if(!lstFollowUpLead.isEmpty()){
                    leadFollowUpTable = objEmailService.customLeadTableHeader('Follow Up Leads');
                    for(Lead objLead : lstFollowUpLead){
                        leadFollowUpTable += objEmailService.makeTable(objLead);
                    }
                    leadFollowUpTable += '</table>';
                } else {
                    leadFollowUpTable = '<p>No Follow Up Leads</p>';
                }
                
                if(!lstWaitingListLead.isEmpty()){
                    leadWaitingListTable = objEmailService.customLeadTableHeader('Waiting List Leads');
                    for(Lead objLead : lstWaitingListLead){
                        leadWaitingListTable += objEmailService.makeTable(objLead);
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
                Messaging.SendEmailResult[] results = objEmailService.sendEmail(
                    new List<Messaging.SingleEmailMessage>{email}
                );
            }
        }
    }
    
    public void finish(Database.BatchableContext bc){
    }
    
    // Scheduling the batch
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new DailyLeasingLeadsNotificationBatch(), 100);
    }
}