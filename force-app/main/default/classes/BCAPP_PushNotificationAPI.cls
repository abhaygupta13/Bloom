//============================ BCAPP_PushNotificationAPI =============================
/*
* @Author : Eagles
* @CreatedDate : 06th May 2025
* @Name : BCAPP_PushNotificationAPI
* @Description : This Apex class provides utility methods to send Push notification using the Infobip API. 
*               
*/
/*****************************************************************************************************
* Version       Author                  Date             Comment                                                                       
* 1.0           Eagles               06 May 2025        Initial draft 
*****************************************************************************************************/
public with sharing class BCAPP_PushNotificationAPI implements Queueable, Database.AllowsCallouts{
    
    
    List<PushNotificationParams> notifyparams;
    APISetting__mdt apiSetting;
    public BCAPP_PushNotificationAPI (List<PushNotificationParams> notifyparams){
        this.notifyparams = notifyparams;
        this.apiSetting = APISetting__mdt.getInstance('Infobip_Push_Notification');
    }
    
    public void execute(QueueableContext context) {
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(apiSetting.URL__c);
        request.setMethod(apiSetting.httpMethod__c);
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', apiSetting.Authorization__c); 
        
        // Default options, can be overridden by caller
        Map<String, Object> defaultOptions = new Map<String, Object>{
            'soundEnabled' => true,
                'soundName' => 'default',
                'vibrationEnabled' => true,
                'contentAvailable' => true,
                'isSilent' => false,
                'badge' => 1,
                'category' => 'mm_accept_decline',
                'showMirroredPush' => false,
                'mirroredPushStyle' => 'BANNER',
                'mirroredPushDismissTitle' => 'Dismiss',
                'mirroredPushOpenTitle' => 'View'
                };
                    for(PushNotificationParams params:notifyparams){
                        if (String.isBlank(params.pushRegistrationId)) {
                            System.debug('Skipping push: No pushRegistrationId.');
                            continue;
       					 }
                        // Merge provided options
                        if (params.options != null) {
                            for (String key : params.options.keySet()) {
                                defaultOptions.put(key, params.options.get(key));
                            }
                        }
                        
                        // Add scheduled time if available
                        if (params.scheduledTime != null) {
                            defaultOptions.put('sendAt', params.scheduledTime.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));
                        }
                        
                        Map<String, Object> content = new Map<String, Object>{
                            'title' => params.title,
                                'text' => params.message,
                                'type' => 'TEXT'
                                };
                                    
                                    Map<String, Object> messageMap = new Map<String, Object>{
                                        'sender' => apiSetting.Client_Id__c,
                                            'destinations' => new List<Object>{
                                                new Map<String, Object>{
                                                    'pushRegistrationId' => params.pushRegistrationId,
                                                        'type' => 'REGISTRATION'
                                                        }
                                            },
                                                'content' => content,
                                                'options' => defaultOptions
                                                };
                                                    
                                                    Map<String, Object> payload = new Map<String, Object>{
                                                        'messages' => new List<Object>{ messageMap }
                                                    };
                                                        
                                                        // Optional custom payload
                                                        if (!String.isBlank(params.moduleName) || !String.isBlank(params.caseNumber) || !String.isBlank(params.status)) {
                                                            Map<String, Object> customPayload = new Map<String, Object>{
                                                                'module' => params.moduleName,
                                                                    'caseId' => params.caseNumber,
                                                                    'status' => params.status,
                                                                    'custom'=> params.message,
                                                                    'deeplink'=> params.deepLinkUrl
                                                                    };
                                                                        defaultOptions.put('customPayload', customPayload);
                                                            
                                                        }
                        
                        request.setBody(JSON.serialize(payload));
                        System.debug('---->>>>JSON.serialize(payload)--->>>'+JSON.serialize(payload));
                        try {
                            HttpResponse response = http.send(request);
                            if (response.getStatusCode() == 200 || response.getStatusCode() == 202) {
                                if(params.accountId != null){
                                    Notifications__c  pushNotify = new Notifications__c();
                               		pushNotify.Account__c = params.accountId;
                                    pushNotify.Name = params.title;
                                    pushNotify.Description__c = params.message;
                                    pushNotify.Publish_Date_Time__c = DateTime.Now();
                                    pushNotify.Status__c = 'Published';
                                    pushNotify.RecordTypeId =  Utilities.getRecordTypeId('Notifications__c','Alerts');
                                    insert pushNotify;
                                }
                                
                                System.debug('Push notification sent successfully.');
                            } else {
                                System.debug('Failed to send notification: ' + response.getStatusCode() + ', Body: ' + response.getBody());
                            }
                        } catch (Exception e) {
                            System.debug('Error sending push notification: ' + e.getMessage());
                        }
                        
                    }
    }
    
    public class PushNotificationParams {
        public String pushRegistrationId;
        public String title;
        public String message;
        public String moduleName;
        public String caseNumber;
        public String status;
        public String deepLinkUrl;
        public Datetime scheduledTime;
        public String accountId;
        public Map<String, Object> options;
        public PushNotificationParams(String pushRegistrationId,String title,String message,String caseNumber,String status){
            this.pushRegistrationId = pushRegistrationId;
            this.title = title;
            this.message = message;
            this.caseNumber = caseNumber;
            this.status = status;
        }
        public PushNotificationParams(){
            
        }
    }
}