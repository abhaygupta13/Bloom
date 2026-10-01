/*****************************************************************************************
Class       : PushNotificationTriggerHelper
Author      : Ashish Rana
Description : Helper class for creating integration records for push notifications.
Created Date: 06/08/2026
*****************************************************************************************/

public class PushNotificationTriggerHelper {
    
    public static void createIntegrationRecords(List<PushNotification__c> newList){
        List<IntegrationRecord__c> integrationRecords = new List<IntegrationRecord__c>();
        for (PushNotification__c pushNotification : newList) {
            IntegrationRecord__c integrationRecord = new IntegrationRecord__c();
            String recipient;
            integrationRecord.Type__c = 'PUSH_NOTIFICATION_INTEGRATION';
            integrationRecord.Action__c = 'Insert';
            integrationRecord.ObjectAPIName__c = pushNotification.ObjectAPIName__c;
            integrationRecord.RecordId__c = pushNotification.RecordId__c;
            integrationRecord.Param1__c = pushNotification.SenderBloomPartnersID__c;
            integrationRecord.Param2__c = pushNotification.Title__c;
            integrationRecord.Param3__c = pushNotification.Body__c;
            integrationRecord.Param4__c = pushNotification.NotificationType__c;
            
            if (pushNotification.Contact__c != null) {
                recipient = String.valueOf(pushNotification.Contact__c);
            } else if (String.isNotBlank(pushNotification.Email__c)) {
                recipient = pushNotification.Email__c;
            }
            integrationRecord.LongTextParam1__c = recipient != null ? JSON.serialize(new List<String>{recipient}) : null;
            integrationRecords.add(integrationRecord);
        }
        IntegrationRecordService.getInstance().insertIntegrationRecords(integrationRecords);
    }
}