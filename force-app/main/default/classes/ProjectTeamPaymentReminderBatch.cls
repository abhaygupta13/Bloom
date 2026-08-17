/*****************************************************************************************
Class       : ProjectTeamPaymentReminderBatch
Author      : Dhanraj Poojary
Description : Batch to send details of upcoming Payment Installments where due date is 2 months from current date
Test Class  : ProjectTeamPaymentReminderBatchTest
Created Date: 28 AUG 2025 
*****************************************************************************************/

public class ProjectTeamPaymentReminderBatch implements Database.Batchable<SObject>, Schedulable{
    private static final string MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final string MTD_PROJECT_TEAM_PAYMENT_REMINDER_EMAIL_TEMPLATE_ID { get { return 'ProjectTeamPaymentReminderETId'; } }
    private static final string MTD_ACTIVE_SALES_ORDER_STATUS_VALUE { get { return 'ActiveSalesOrderStatus'; } }
    private static final string MTD_PROJECT_TEAM_PAYMENT_REMINDER_EMAILID { get { return 'ProjectTeamPaymentReminderEmailIds'; } }
    private static final string MTD_PROJECT_TEAM_PAYMENT_REMINDER_DAYS_VALUE { get { return 'ProjectTeamPaymentReminderDays'; } }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        MetadataService ms = MetadataService.getInstance();
        List<String> activeStatuses = ms.getAppSettingTextValue(MTD_ACTIVE_SALES_ORDER_STATUS_VALUE).split(',');
        Integer reminderDays = ms.getAppSettingNumberValue(MTD_PROJECT_TEAM_PAYMENT_REMINDER_DAYS_VALUE);
        Date dueDate = Date.today().addDays(reminderDays);
        
        return Database.getQueryLocator([SELECT SalesOrder__r.Unit__r.Project__c,SalesOrder__r.Unit__r.Project__r.Name,Due_Date__c FROM InstallmentLines__c WHERE SalesOrder__r.Status__c IN :activeStatuses AND Due_Date__c = :dueDate AND Type__c != 'Down Payment']);
    }
    
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        MetadataService ms = MetadataService.getInstance();
        EmailService es = EmailService.getInstance();
        Id orgWideEmailId = ms.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
        EmailTemplate template = es.getEmailTemplateById(ms.getAppSettingTextValue(MTD_PROJECT_TEAM_PAYMENT_REMINDER_EMAIL_TEMPLATE_ID));
        List<String> toAddresses = new List<String>();
        String recipients = ms.getAppSettingTextValue(MTD_PROJECT_TEAM_PAYMENT_REMINDER_EMAILID);
        if (recipients != null) {
            toAddresses.addAll(recipients.split(','));
        }

        Map<Id, String> projectNames = new Map<Id, String>();
        Map<Id, Set<Date>> projectDueDates = new Map<Id, Set<Date>>();
        
        for (SObject sob : scope) {
            InstallmentLines__c il = (InstallmentLines__c) sob;
            Id projectId = il.SalesOrder__r.Unit__r.Project__c;
            Date dueDate = il.Due_Date__c;
            if (!projectDueDates.containsKey(projectId)) {
                projectDueDates.put(projectId, new Set<Date>());
                projectNames.put(projectId,il.SalesOrder__r.Unit__r.Project__r.Name);
            }
            projectDueDates.get(projectId).add(dueDate);
        }
        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        for (Id projectId : projectDueDates.keySet()) {
            
            String projectName = projectNames.get(projectId);
            String projectUrl = System.Url.getOrgDomainUrl().toExternalForm() + '/' + projectId;
            
            String projectLink = '<a href="' + projectUrl + '">' + projectName + '</a>';
            
            List<String> formattedDates = new List<String>();
            for (Date d : projectDueDates.get(projectId)) {
                formattedDates.add(d.format());
            }
            
            String emailBody = template.HtmlValue;
            emailBody = emailBody.replace('[Project_Name]', projectLink);
            emailBody = emailBody.replace('[Due_Date]', String.join(formattedDates, ', '));
            
            emails.add(es.getSingleEmailMessage(toAddresses,template.Subject,emailBody,orgWideEmailId));
        }
        
        if (!emails.isEmpty()) {
            es.sendEmail(emails);
        }
    }
    
    
    public void finish(Database.BatchableContext bc){
    }
    
    // Scheduling the batch
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new ProjectTeamPaymentReminderBatch(), 200);
    }
}