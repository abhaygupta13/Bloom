/***
Class       : CustomNotificationService 
Author      : Jhilik
Description : 
TestClass   : CustomNotificationServiceTest
****************************************************************************************************************/
public inherited sharing class CustomNotificationService {

    private static CustomNotificationService instance;
    
    public static CustomNotificationService getInstance() { 
        if(instance == null) {
            instance = new CustomNotificationService();
        }
        return instance;
    }

    public CustomNotificationType getCustomNotificationTypeByName(String customNotificationName) {
        return [SELECT Id, DeveloperName 
             FROM CustomNotificationType 
             WHERE DeveloperName= :customNotificationName];
    }
    
    public static void sendCustomNotification(Set<String> recipientsIds, String targetId, CustomNotificationType notificationType, String title, String body) {

        // Create a new custom notification
        Messaging.CustomNotification notification = new Messaging.CustomNotification();

        // Set the contents for the notification
        notification.setTitle(title);
        notification.setBody(body);

        // Set the notification type and target
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(targetId);
        
        // Actually send the notification
        notification.send(recipientsIds);
    }
}