/*****************************************************************************************
Class       : QMSTokenTriggerHelper
Author      : Aman Bharti
Description : QMSTokenTriggerHelper
Test Class  : 
Created Date: 23 JUL 2026 
*****************************************************************************************/
public without sharing class QMSTokenTriggerHelper {

    private static final string CREATE_SMS_NOTIFICATION { get { return 'QMS Token Create Notification'; } }
    private static final string CLOSURE_SMS_NOTIFICATION { get { return 'QMS Token Closure Notification'; } }


    public static void sendSMSNotification(List<QMSToken__c> newList , Map<Id, QMSToken__c> oldMap){

        NotificationService objNotificationService = NotificationService.getInstance();
        IntegrationRecordService objIntegrationRecordService = IntegrationRecordService.getInstance();

        List<IntegrationRecord__c> integrationRecords = new List<IntegrationRecord__c>();
        Set<String> templateNames = new Set<String>{CREATE_SMS_NOTIFICATION, CLOSURE_SMS_NOTIFICATION};
        Map<String, SMSTemplate__c> smsTemplateMap = objNotificationService.getSMSTemplates(templateNames);

        

        for(QMSToken__c token : newList){
            if(String.isNotBlank(token.MobileNumber__c)){
                List<String> values = new List<String>{token.TokenNumber__c};

                String smsTemplateName;
                if(oldMap == null){
                    smsTemplateName = CREATE_SMS_NOTIFICATION;
                }
                else if(oldMap.get(token.Id).ClosedDate__c == null && token.ClosedDate__c != null){
                    smsTemplateName = CLOSURE_SMS_NOTIFICATION;
                }

                integrationRecords.add(objNotificationService.getSMSIntegrationRecord(token, smsTemplateMap.get(smsTemplateName), values));
            }
        }

        objIntegrationRecordService.insertIntegrationRecords(integrationRecords);
    }
}