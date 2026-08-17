/*****************************************************************************************
Class       : LatePaymentFeeInternalNotificationBatch
Author      : Dhanraj Poojary
Description : Batch to send Late Payment Fee details to internal team
Test Class  : LatePaymentFeeInternalNotificationTest
Created Date: 03 JULY 2025 
*****************************************************************************************/

public class LatePaymentFeeInternalNotificationBatch implements Database.Batchable<sObject>, Schedulable,Database.Stateful{
    private static final string MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final string MTD_SALES_ORDER_STATUS_VALUE { get { return 'SalesOrderStatusforPendingPayment'; } }
    private static final string MTD_LATE_PAYMENT_FEE_NOTIFICATION_EMAIL_TEMPLATE_ID { get { return 'LatePaymentFeeInternalEmailTemplateId'; } }
    private static final string MTD_LATE_PAYMENT_FEE_NOTIFICATION_EMAIL_ADDRESS { get { return 'LatePaymentFeeNotificationEmailAddress'; } }
    private static final string LATE_PAYMENT_FEE_VALUE { get { return 'Late Payment Charges'; } }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id,Name,EnableLatePaymentFee__c FROM Project__c WHERE EnableLPFInternalNotification__c = TRUE';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Project__c> scope) {
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        SalesOrderOtherChargesService objSalesOrderOtherChargeService = SalesOrderOtherChargesService.getInstance();
        
        List<String> toAddress = new List<String>();
        Id bloomNoReplySalesOWEId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
        EmailTemplate latePaymentFeeNotificationET = objEmailService.getEmailTemplateById(objMetadataService.getAppSettingTextValue(MTD_LATE_PAYMENT_FEE_NOTIFICATION_EMAIL_TEMPLATE_ID));
        String recepientEmailAddress = objMetadataService.getAppSettingTextValue(MTD_LATE_PAYMENT_FEE_NOTIFICATION_EMAIL_ADDRESS);
        if(recepientEmailAddress != null) toAddress.addAll(recepientEmailAddress.split(','));
        String salesOrderStatusValue = objMetadataService.getAppSettingTextValue(MTD_SALES_ORDER_STATUS_VALUE);
        List<String> salesOrderStatusValueList = salesOrderStatusValue.split(',');
        String emailBody = latePaymentFeeNotificationET.HtmlValue;
        String emailSubject = latePaymentFeeNotificationET.Subject;
        String latePaymentFeeTable = objEmailService.customsalesOrderOtherChargesTableHeader();
        List<Id> projectIdList = new List<Id>();
        Map<Id, Project__c> projectMap = new Map<Id, Project__c>(scope);
        List<SalesOrderOtherCharges__c> saleOrderChargeList = objSalesOrderOtherChargeService.getSalesOrderChargesByProjectIds(projectMap.keySet(),salesOrderStatusValueList,LATE_PAYMENT_FEE_VALUE);
        if(saleOrderChargeList.size() > 0){
            for(SalesOrderOtherCharges__c objSOC : saleOrderChargeList){  
                latePaymentFeeTable += objEmailService.makeTable(objSOC);
            }
            latePaymentFeeTable += '</table>';
            String csv = objEmailService.generateCSV(saleOrderChargeList);
            Blob csvBlob = Blob.valueOf(csv);
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName('LatePaymentFees.csv');
            attachment.setBody(csvBlob);
            attachment.setContentType('text/csv');
            emailBody = emailBody.replace('{{LPF_TABLE}}', latePaymentFeeTable);
            Messaging.SingleEmailMessage email = objEmailService.getSingleEmailMessage(toAddress, emailSubject, emailBody, bloomNoReplySalesOWEId); 
            email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment});
            
            Messaging.SendEmailResult[] results = objEmailService.sendEmail(new List<Messaging.SingleEmailMessage>{email});        
        }
    }
    
    public void finish(Database.BatchableContext BC) {
    }
    
    // Scheduling the batch
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new LatePaymentFeeInternalNotificationBatch(), 50);
    }
}