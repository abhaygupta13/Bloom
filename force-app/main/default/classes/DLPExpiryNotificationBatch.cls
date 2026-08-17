/*
*********************************************************
Apex Class Name    : DLPExpiryNotificationBatch
Created Date       : november 30, 2025
@description       : This class is used for send DLP Expiry Notification for customer.
@author            : Antriksh jain

*********************************************************
*/
public class DLPExpiryNotificationBatch implements Database.Batchable<sObject>, Schedulable {
    
    private static final String MDT_HANDOVER_ORG_WIDE_EMAIL_ADDRESS_ID = 'BloomNoReplySalesOWEmailId';
    
    private static final String MDT_DLP_EXPIRY_EMAIL_TEMPLATE_ID = 'DLPExpiryNotificationEmailTempId'; 

    public Database.QueryLocator start(Database.BatchableContext BC) {
        
        Date dlpExpNotificationSendDate = Date.today().addMonths(1);
        
        String query = 'SELECT Id, Name,Unit__c,Contact__c,HasDLPExpiryEmailSent__c ' + 
                       'FROM Handover__c ' +
                       'WHERE NOC_Expiry_Date__c =: dlpExpNotificationSendDate AND HasDLPExpiryEmailSent__c = false';
        
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Handover__c> scope) {
        HandoverService objHandoverService = HandoverService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        MetadataService MetadataService = MetadataService.getInstance();
        
        
        Id orgWideEmailAddressId = MetadataService.getAppSettingTextValue(MDT_HANDOVER_ORG_WIDE_EMAIL_ADDRESS_ID);
        Id DLPExpiryNotificationEmailTempId = MetadataService.getAppSettingTextValue(MDT_DLP_EXPIRY_EMAIL_TEMPLATE_ID);
       

        List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
        List<Handover__c> handoversToUpdate = new List<Handover__c>();

        for (Handover__c ho : scope) {
           if (ho.Contact__c != null && !ho.HasDLPExpiryEmailSent__c) {
        mailList.add(objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(DLPExpiryNotificationEmailTempId, orgWideEmailAddressId, ho.Unit__c, ho.Contact__c,null,null,null));
        ho.HasDLPExpiryEmailSent__c = true;
        handoversToUpdate.add(ho);
    }
        }  
            objEmailService.sendEmail(mailList);
            objHandoverService.updateHandoversWithoutTrigger(handoversToUpdate);
        
    }

    public void finish(Database.BatchableContext BC) {}

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new DLPExpiryNotificationBatch(), 50);
    }
}