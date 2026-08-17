/*****************************************************************************************
Class       : OpenLeadNotificationBatch
Author      : Dhanraj Poojary
Description : Batch to send email to internal team if there is no progress on lead
Test Class  : OpenLeadNotificationBatchTest
Created Date: 17 JUL 2025 
*****************************************************************************************/

public class OpenLeadNotificationBatch implements Database.Batchable<SObject>, Schedulable {
    
    private static final string MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final string MTD_LEAD_OPEN_DAYS_VALUE { get { return 'LeadOpenDaysValue'; } }
    private static final string MTD_SM_BUSINESSHOURS_ID { get { return 'SMBusinessHoursId'; } }
    private static final string MTD_LEAD_OPEN_EMAIL_TEMPLATE_ID { get { return 'OpenLeadETId'; } }
    private static final string MTD_LEAD_OPEN_EMAIL_ADDRESS_VALUE { get { return 'OpenLeadEmailRecepient'; } }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        MetadataService objMetadataService = MetadataService.getInstance();
        Integer leadPastDays = objMetadataService.getAppSettingNumberValue(MTD_LEAD_OPEN_DAYS_VALUE);
        DateTime currentDateTime = DateTime.now();
        DateTime calculationDate = currentDateTime.addDays(-leadPastDays);
        return Database.getQueryLocator([
            SELECT Id, Name, LeadManagerAssignedDate__c, LeadManagerStatus__c, Status, OwnerId, LeadNumber__c, Owner.Name, CreatedDate, Project__c
            FROM Lead
            WHERE Status NOT IN('Closed','Converted')
            AND LeadManagerAssignedDate__c != NULL
            AND LeadTeam__c != 'Leasing'
            AND IsDraftLead__c = false
            AND IsConverted = FALSE 
            ORDER BY LeadManagerAssignedDate__c DESC
        ]);
    }
    
    public void execute(Database.BatchableContext bc, List<Lead> scope) {
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        BusinessHoursService objBHService = BusinessHoursService.getInstance();
        List<String> toAddress = new List<String>();
        Id bloomNoReplySalesOWEId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
        EmailTemplate inactiveLeadNotificationET = objEmailService.getEmailTemplateById(objMetadataService.getAppSettingTextValue(MTD_LEAD_OPEN_EMAIL_TEMPLATE_ID));
        String recepientEmailAddress = objMetadataService.getAppSettingTextValue(MTD_LEAD_OPEN_EMAIL_ADDRESS_VALUE);
        if(recepientEmailAddress != null) toAddress.addAll(recepientEmailAddress.split(','));
        List<Lead> lstLead = new List<Lead>();
        Integer leadPastDays = objMetadataService.getAppSettingNumberValue(MTD_LEAD_OPEN_DAYS_VALUE);
        String emailBody = inactiveLeadNotificationET.HtmlValue;
        String emailSubject = inactiveLeadNotificationET.Subject;
        String leadTable = objEmailService.customLeadTableHeader('',false);
        Id smBusinessHoursId = objMetadataService.getAppSettingTextValue(MTD_SM_BUSINESSHOURS_ID);
        
        for (Lead objLead : scope) {
            DateTime pastDate = objBHService.getPastBusinessDate(smBusinessHoursId,System.Now(),leadPastDays);
            if(objLead.LeadManagerAssignedDate__c <= pastDate){
                leadTable += objEmailService.makeTable(objLead,false);
                lstLead.add(objLead);
            }
        }
        leadTable += '</table>';
        String csv = objEmailService.generateCSV(lstLead);
        Blob csvBlob = Blob.valueOf(csv);
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName('OpenLeads.csv');
        attachment.setBody(csvBlob);
        attachment.setContentType('text/csv');
        emailBody = emailBody.replace('{{LEAD_TABLE}}', leadTable);
        Messaging.SingleEmailMessage email = objEmailService.getSingleEmailMessage(toAddress, emailSubject, emailBody, bloomNoReplySalesOWEId); 
        email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment});
        
        Messaging.SendEmailResult[] results = objEmailService.sendEmail(new List<Messaging.SingleEmailMessage>{email});        
    }
    
    public void finish(Database.BatchableContext bc) {
    }
    
    // Scheduling the batch
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new OpenLeadNotificationBatch(), 2000);
    }
}