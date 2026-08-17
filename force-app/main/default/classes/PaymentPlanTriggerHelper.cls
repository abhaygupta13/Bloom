/***
Class       : PaymentPlanTriggerHelper
Author      : Dhanraj Poojary
Description : 
TestClass   : PaymentPlanTriggerHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.       V1.0              04/05/2026           Initial Version 
****************************************************************************************************************/

public without sharing class PaymentPlanTriggerHelper {
    
    private static final string MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final string FINAL_APPROVAL_NOTIFICATION_EMAIL_TEMPLATE_ID { get { return 'RevisedMilestoneFinalApprovalETId'; } }
    private static final string FINAL_APPROVAL_NOTIFICATION_EMAIL_ADDRESS { get { return 'RevisedMilestoneFinalApprovalEmailAddres'; } }
    
    public static void handleAfterUpdate(List<PaymentPlan__c> newList, Map<Id, PaymentPlan__c> oldMap){
        Set<Id> approvedPaymentPlanIds = new Set<Id>();
        for(PaymentPlan__c newRec : newList){          
            PaymentPlan__c oldRec = oldMap.get(newRec.Id);
            
            if(newRec.ApprovalStatus__c == 'Approved' && oldRec.ApprovalStatus__c != 'Approved'){        
                approvedPaymentPlanIds.add(newRec.Id);
            }
        }
        if(!approvedPaymentPlanIds.isEmpty()){
            syncInstallmentLines(approvedPaymentPlanIds);
            sendPaymentPlanApprovalEmail(approvedPaymentPlanIds);
        }
    }
    
    private static void syncInstallmentLines(Set<Id> paymentPlanIds){
        InstallmentLineService installmentService = InstallmentLineService.getInstance();
        PaymentInstallmentService paymentInstallmentService = PaymentInstallmentService.getInstance();
        List<InstallmentLines__c> instLinesToUpdate = new List<InstallmentLines__c>();
        List<PaymentInstallments__c> paymentInstList = new List<PaymentInstallments__c>();
        List<PaymentInstallments__c> paymentInstToUpdate = new List<PaymentInstallments__c>();
        Map<Id, Date> revisedDateMap = new Map<Id, Date>();
        paymentInstList = paymentInstallmentService.getPaymentInstallmentsById(paymentPlanIds);
        
        if(!paymentInstList.isEmpty()){
            for(PaymentInstallments__c payInst : paymentInstList){              
                if(payInst.RevisedDate__c != null && payInst.RevisedDateUpdated__c == true){                  
                    revisedDateMap.put(payInst.Id,payInst.RevisedDate__c);
                    paymentInstToUpdate.add(new PaymentInstallments__c(Id = payInst.Id,RevisedDateUpdated__c = false));
                }
            }
        }
        
        if(!revisedDateMap.isEmpty()){
            instLinesToUpdate = installmentService.getInstallmentsByPaymentInstallmentIds(revisedDateMap.keySet());
        }
        
        if(!instLinesToUpdate.isEmpty()){
            for(InstallmentLines__c instLine : instLinesToUpdate){       
                instLine.RevisedDate__c = revisedDateMap.get(instLine.PaymentInstallments__c);
            }
            
            installmentService.updateInstallmentLinesLists(instLinesToUpdate);
            List<SObject> objList = new List<SObject>();
            objList.addAll(paymentInstToUpdate);
            System.enqueueJob(new AsyncActionQueueable('UPDATE_PAYMENT_INSTALLMENT_WITHOUT_TRIGGER', objList));
        }
    }
    
    private static void sendPaymentPlanApprovalEmail(Set<Id> paymentPlanIds){
        PaymentPlanService objPaymentPlanService = PaymentPlanService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        List<Messaging.SingleEmailMessage> msgList = new List<Messaging.SingleEmailMessage>();
        List<PaymentPlan__c> paymentPlans = objPaymentPlanService.getPaymentPlansByIds(paymentPlanIds);
        if(!paymentPlans.isEmpty()){
            Id bloomNoReplySalesOWEId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
            Id revisedMilestoneApprovalETId = objMetadataService.getAppSettingTextValue(FINAL_APPROVAL_NOTIFICATION_EMAIL_TEMPLATE_ID);
            String recipientEmails = objMetadataService.getAppSettingTextValue(FINAL_APPROVAL_NOTIFICATION_EMAIL_ADDRESS);
            List<String> recipientEmailsList = recipientEmails.split(',');
            for(PaymentPlan__c pp : paymentPlans){
                Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(revisedMilestoneApprovalETId,UserInfo.getUserId(),pp.Id);
                String body = mail.getHtmlBody();
				mail.setHtmlBody(body);
                mail.setToAddresses(recipientEmailsList);
                mail.setOrgWideEmailAddressId(bloomNoReplySalesOWEId);
                mail.setSaveAsActivity(false);
                msgList.add(mail);
            }
            objEmailService.sendEmail(msgList);
        }
    }
}