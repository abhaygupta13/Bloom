/*****************************************************************************************
Class       : NotificationService
Author      : Vikas Baliyan
Description : Notification Service
Test Class  : 
Created Date: 26 NOV 2024 
*****************************************************************************************/
public inherited sharing class NotificationService {
    private static final string BLOOM_CUSTOM_NOTIFICATION_ID { get { return 'BloomCustomNotifications'; } }
    private static final string SR_REASSIGNMENT_NOTIFICATION_ID { get { return 'ServiceRequestReAssignmentNotiicationId'; }}
    private static NotificationService instance;
    
    
    private NotificationService() {
        
    }
    
    public static NotificationService getInstance() { 
        if(instance == null) {
            instance = new NotificationService();
        }
        return instance;
    }
    
    public static void sendBellNotification(Set<String> recipientsIds, String targetId){
        MetadataService objMetadataService = MetadataService.getInstance();
        
        //Fetch Email Template id
        Id BloomCustomNotificationsId = objMetadataService.getAppSettingTextValue(BLOOM_CUSTOM_NOTIFICATION_ID);
        
        //Sending custom notification
        Messaging.CustomNotification notification = new Messaging.CustomNotification();        
        notification.setTitle('New Invoice Created');
        notification.setBody('The notifications are coming from INSIDE the Apex!');
        notification.setNotificationTypeId(BloomCustomNotificationsId);
        notification.setTargetId(targetId);
        
        try {
            notification.send(recipientsIds);
        }
        catch (Exception e) {
            throw new AuraHandledException('Error : ' + e.getMessage());
        }
    }
    public void sendCustomNotification(Set<Id> caseIds){
        List<Case> cases = CaseService.getInstance().getCaseByIds(caseIds);
        for(Case caseObj : cases){ 
            //Fetch users to send bell notification 
            Set<String> userToNotifySet = new Set<String>();
            userToNotifySet.add(caseObj.ownerId);
            String body = 'Service Request'+' '+ caseobj.caseNumber+' has been re-assigned to you for further processing.';
            sendBellNotification(userToNotifySet,caseObj.id,'Service Request Reassigned',body,SR_REASSIGNMENT_NOTIFICATION_ID);
        }
    }
    public void sendBellNotification(Set<String> recipientsIds, String targetId,String title,String body,String notificationTypeName){
        MetadataService objMetadataService = MetadataService.getInstance();
        //Fetch Email Template id
        Id notificationTypeId = objMetadataService.getAppSettingTextValue(notificationTypeName);
       //Sending custom notification
        Messaging.CustomNotification notification = new Messaging.CustomNotification();        
        notification.setTitle(title);
        notification.setBody(body);
        notification.setNotificationTypeId(notificationTypeId);
        notification.setTargetId(targetId);
        
        try {
            notification.send(recipientsIds);
        }
        catch (Exception e) {
            throw new AuraHandledException('Error : ' + e.getMessage());
        }
    }

    public IntegrationRecord__c getSMSIntegrationRecord(sObject sObj, SMSTemplate__c template, List<String> values){
        IntegrationRecordService integService = IntegrationRecordService.getInstance();
        Map<String, String> paramMap = new Map<String, String>();

        String objectApiName = sObj.getSObjectType().getDescribe().getName();
        String integrationType = 'SMS_NOTIFICATION_INTEGRATION';
        String action = 'Insert';
        String phoneNumber;

        if (objectApiName == 'Case') {
            phoneNumber = ((Case)sObj).RequesterContactNumber__c;
        }
        else if (objectApiName == 'QMSToken__c') {
            phoneNumber = ((QMSToken__c)sObj).MobileNumber__c;
        }
        else if (objectApiName == 'Lead') {
            phoneNumber = ((Lead)sObj).MobilePhone;
        }

        paramMap.put('Param1', template?.SenderNumber__c);
        paramMap.put('Param2', Utility.formatPhoneNumberWithCountryCode(phoneNumber));
        paramMap.put('LongTextParam1',replaceTemplateParams(template?.Body__c, values));
       
        return integService.getIntegrationRecord(integrationType, action, objectApiName, sObj.Id, paramMap);
    }

    public IntegrationRecord__c getWhatsappIntegrationRecord(sObject sObj, WhatsAppTemplate__c template, List<String> values){

        IntegrationRecordService integService = IntegrationRecordService.getInstance();
        Map<String, String> paramMap = new Map<String, String>();
        String integrationType;
        String action;
        String objectApiName;
        if(sObj.getSObjectType() == Case.getSObjectType()){
            Case caseObj = (Case)sObj;
            integrationType = 'WHATSAPP_NOTIFICATION_INTEGRATION';
            action = 'Insert';
            objectApiName = 'Case';
            paramMap.put('Param1', template.SenderNumber__c);
            paramMap.put('Param2', Utility.formatPhoneNumberWithCountryCode(caseObj.RequesterContactNumber__c));
            paramMap.put('Param3', Utility.getGUID());
            paramMap.put('Param4', template.TemplateAPIName__c);
            paramMap.put('Param5', template.Language__c);
            paramMap.put('LongTextParam1', replaceTemplateParams(template.Body__c.stripHtmlTags(), values));
            paramMap.put('LongTextParam2', replaceTemplateParams(template.DynamicParams__c, values));
        }
        
        return integService.getIntegrationRecord(integrationType, action, objectApiName, sObj.Id, paramMap);
    }

    public static String replaceTemplateParams(String template, List<String> values){

        if(String.isBlank(template) || values == null){
            return template;
        }

        List<Object> params = new List<Object>();
        for(String val : values){
            params.add(val);
        }

        return String.format(template, params);
    }

    public Map<String, SMSTemplate__c> getSMSTemplates(Set<String> templateNames){
        Map<String, SMSTemplate__c> mapData = new Map<String, SMSTemplate__c>();

        for(SMSTemplate__c temp : [
            SELECT Id, SenderNumber__c, Body__c, Name
            FROM SMSTemplate__c
            WHERE Name IN :templateNames
        ]){
            mapData.put(temp.Name, temp);
        }

        return mapData;
    }

    public Map<String, WhatsAppTemplate__c> getWhatsAppTemplates(Set<String> templateNames){
        Map<String, WhatsAppTemplate__c> mapData = new Map<String, WhatsAppTemplate__c>();

        for(WhatsAppTemplate__c temp : [
            SELECT Id, SenderNumber__c, Name, Language__c, Body__c, DynamicParams__c,TemplateAPIName__c
            FROM WhatsAppTemplate__c
            WHERE Name IN :templateNames
        ]){
            mapData.put(temp.Name, temp);
        }

        return mapData;
    }
    
        public Map<String, PushNotificationTemplate__c> getPushNotificationTemplates(Set<String> templateNames) {
        Map<String, PushNotificationTemplate__c> mapData = new Map<String, PushNotificationTemplate__c>();
        
        for (PushNotificationTemplate__c temp : [SELECT Id,DynamicParams__c,Body__c,Name,Language__c,NotificationType__c,SenderBloomPartnersID__c,Title__c 
                                                 FROM PushNotificationTemplate__c WHERE Name IN :templateNames]) {
                                                     mapData.put(temp.Name, temp);
                                                 }
        
        return mapData;
    }

}