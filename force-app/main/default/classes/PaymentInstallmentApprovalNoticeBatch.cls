/*****************************************************************************************
Class       : PaymentInstallmentApprovalNoticeBatch
Author      : Dhanraj Poojary
Description : Batch to send details of Payment Installments to be approved for Revised Date
Test Class  : PaymentInstallmentApprovalNoticeTest
Created Date: 22 AUG 2025 
*****************************************************************************************/

public class PaymentInstallmentApprovalNoticeBatch implements Database.Batchable<sObject>, Schedulable{
    private static final string MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final string MTD_PAYMENT_INSTALLMENT_APPROVAL_EMAIL_TEMPLATE_ID { get { return 'PaymentInstallmentApprovalETId'; } }
    private static final string MTD_PAYMENT_INSTALLMENT_APPROVAL_EMAIL_ADDRESS { get { return 'PaymentInstallmentApprovalEmailAddress'; } }
    
    public Database.QueryLocator start(Database.BatchableContext bc) { 
        String query = 'SELECT Id,Name,RevisedDate__c,RevisedDateVerified__c,RevisedDateVerifiedBy__c,RevisedDateVerifiedDate__c,RevisedDateVerifiedRemarks__c,Project__c,InstallmentNumber__c,InstallmentDate__c,PaymentPlan__c,Payment_Plan_Name__c,InstallmentPercentage__c FROM PaymentInstallments__c WHERE RevisedDate__c != NULL AND RevisedDateVerified__c = FALSE';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<PaymentInstallments__c> scope){
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        
        List<String> toAddress = new List<String>();
        Id bloomNoReplySalesOWEId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
        EmailTemplate paymentInstallmentApprovalNotificationET = objEmailService.getEmailTemplateById(objMetadataService.getAppSettingTextValue(MTD_PAYMENT_INSTALLMENT_APPROVAL_EMAIL_TEMPLATE_ID));
        String recepientEmailAddress = objMetadataService.getAppSettingTextValue(MTD_PAYMENT_INSTALLMENT_APPROVAL_EMAIL_ADDRESS);
        if(recepientEmailAddress != null) toAddress.addAll(recepientEmailAddress.split(','));
        String emailSubject = paymentInstallmentApprovalNotificationET.Subject;
        String emailBody = paymentInstallmentApprovalNotificationET.HtmlValue;
        
        String installmentTable = objEmailService.customPaymentPlanTableHeader();
        
        for(PaymentInstallments__c objPI : scope){
            installmentTable += objEmailService.makeTable(objPI);
        }
        installmentTable += '</table>';
        emailBody = emailBody.replace('{{INSTALLMENT_TABLE}}', installmentTable);
        Messaging.SingleEmailMessage email = objEmailService.getSingleEmailMessage(toAddress, emailSubject, emailBody, bloomNoReplySalesOWEId); 
        Messaging.SendEmailResult[] results = objEmailService.sendEmail(new List<Messaging.SingleEmailMessage>{email});        
    }
    
    public void finish(Database.BatchableContext bc){
    }
    
    // Scheduling the batch
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new PaymentInstallmentApprovalNoticeBatch(), 2000);
    }
}