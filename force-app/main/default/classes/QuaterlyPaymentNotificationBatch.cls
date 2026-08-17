/*****************************************************************************************
Class       : QuaterlyPaymentNotificationBatch
Author      : Dhanraj Poojary
Description : Batch to send details of upcoming Payment Installments Quaterly
Test Class  : QuaterlyPaymentNotificationBatch
Created Date: 17 JAN 2025 
*****************************************************************************************/

public class QuaterlyPaymentNotificationBatch implements Database.Batchable<sObject>, Schedulable,Database.Stateful{
    private static final string MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final string MTD_INSTALLMENT_QUATERLY_PAYMENT_REMINDER_NOTIFICATION_EMAIL_TEMPLATE_ID { get { return 'InstallmentQuaterlyReminderETId'; } }
    private static final string MTD_SALES_ORDER_STATUS_VALUE { get { return 'SalesOrderStatusforPendingPayment'; } }
    private static final string MTD_INSTALLMENT_QUATERLY_REMINDER_EMAIL_ADDRESS_VALUE { get { return 'InstallmentQuaterlyReminderEmailAddress'; } }
    private static final string MTD_INSTALLMENT_QUATERLY_REMINDER_DAYS_VALUE { get { return 'InstallmentQuaterlyReminderDays'; } }
    
    public Database.QueryLocator start(Database.BatchableContext bc) { 
        String query = 'SELECT Id,Name,SendQuaterlyPaymentReminder__c FROM Project__c WHERE SendQuaterlyPaymentReminder__c = TRUE';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Project__c> scope){
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        InstallmentLineService objInstallmentService = InstallmentLineService.getInstance();
        List<String> toAddress = new List<String>();
        Id bloomNoReplySalesOWEId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
        EmailTemplate installmentQuaterlyNotificationET = objEmailService.getEmailTemplateById(objMetadataService.getAppSettingTextValue(MTD_INSTALLMENT_QUATERLY_PAYMENT_REMINDER_NOTIFICATION_EMAIL_TEMPLATE_ID));
        String recepientEmailAddress = objMetadataService.getAppSettingTextValue(MTD_INSTALLMENT_QUATERLY_REMINDER_EMAIL_ADDRESS_VALUE);
        if(recepientEmailAddress != null) toAddress.addAll(recepientEmailAddress.split(','));
        
        String salesOrderStatusValue = objMetadataService.getAppSettingTextValue(MTD_SALES_ORDER_STATUS_VALUE);
        List<String> salesOrderStatusValueList = salesOrderStatusValue.split(',');
        Integer quaterlyReminderDays = objMetadataService.getAppSettingNumberValue(MTD_INSTALLMENT_QUATERLY_REMINDER_DAYS_VALUE);
        Date quaterlyDays = Date.Today().addDays(quaterlyReminderDays);
        String emailBody = installmentQuaterlyNotificationET.HtmlValue;
        String emailSubject = installmentQuaterlyNotificationET.Subject;
        String installmentTable = objEmailService.customUnitILTableHeader(true);
        List<Id> projectIdList = new List<Id>();
        Date currentDate = Date.today();
        Map<Id, Project__c> projectMap = new Map<Id, Project__c>(scope);

        List<InstallmentLines__c> installmentList = objInstallmentService.getInstallmentLinesByProjectIds(projectMap.keySet(), salesOrderStatusValueList, currentDate, quaterlyDays);
        
        if(installmentList.size() > 0){
            for(InstallmentLines__c pi : installmentList){  
                installmentTable += objEmailService.makeTable(pi, true);
            }
            installmentTable += '</table>';
            String csv = objEmailService.generateCSV(installmentList, true);
            Blob csvBlob = Blob.valueOf(csv);
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName('UpcomingInstallments.csv');
            attachment.setBody(csvBlob);
            attachment.setContentType('text/csv');
            emailBody = emailBody.replace('{{INSTALLMENT_TABLE}}', installmentTable);
            Messaging.SingleEmailMessage email = objEmailService.getSingleEmailMessage(toAddress, emailSubject, emailBody, bloomNoReplySalesOWEId); 
            email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment});
            
            Messaging.SendEmailResult[] results = objEmailService.sendEmail(new List<Messaging.SingleEmailMessage>{email});        
        }
    }
    
    public void finish(Database.BatchableContext bc){
    }
    
    // Scheduling the batch
    public void execute(SchedulableContext sc) {
        QuaterlyPaymentNotificationBatch batch = new QuaterlyPaymentNotificationBatch();
        Database.executeBatch(batch, 100);
    }
}