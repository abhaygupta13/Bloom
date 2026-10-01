/*****************************************************************************************
Class       : DocumentTypeService
Author      : Jayesh 
Description : Document Type Object Service Class
TestClass   : DocumentTypeServiceTest
Created Date: 05 Dec 2024
------------------------------------------------------------------------------------------
-- History --
------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.      V1.0             05Dec2024            Initial Version 
*****************************************************************************************/
public inherited sharing class PushNotificationService {
    
    private static PushNotificationService instance;
    
    private PushNotificationService() { }
    
    public static PushNotificationService getInstance() {
        if(instance == null) {
            instance = new PushNotificationService();
        }
        return instance;
        
    }
    
    public static String replaceTemplateParams(String template, List<String> values){
        List<Object> params = new List<Object>();
        for(String val : values){
            params.add(val);
        }
        
        return String.format(template, params);
    }
    
    public PushNotification__c insertPushNotification(PushNotification__c objPushNotification){
        if(objPushNotification != NULL ){
            objPushNotification = insertPushNotifications(new List<PushNotification__c>{objPushNotification})[0];
        }
        return objPushNotification;
    }
    
    public List<PushNotification__c> insertPushNotifications(List<PushNotification__c> pushNotificationList){
        if(pushNotificationList != NULL && !pushNotificationList.isEmpty()){
            insert pushNotificationList;
        }
        return pushNotificationList;
    }
    
    public PushNotification__c getPushNotificationRecord(sObject sObj, PushNotificationTemplate__c template,List<String> values){
        PushNotification__c pushNotification = new PushNotification__c();
        String objectApiName;
        pushNotification.Type__c = template.Name;   
        pushNotification.Title__c = replaceTemplateParams(template.Title__c.stripHtmlTags(), values);
        pushNotification.NotificationType__c  = template.NotificationType__c;
        pushNotification.SenderBloomPartnersID__c = template.SenderBloomPartnersID__c;
        
        
        List<String> recipients = new List<String>();
        
        if (sObj.getSObjectType() == Lead.getSObjectType()) {
            Lead leadObj = (Lead)sObj;
            Boolean isADHALead = leadObj.Lead_Channel__c == 'API Integration' && leadObj.LeadSource == 'Government Entity' && leadObj.leadsubsource__c == 'ADHA' && leadObj.ApplicationNumber__c != null;
            pushNotification.ObjectAPIName__c = 'Lead';
            pushNotification.RecordId__c = leadObj.Id;
            pushNotification.Body__c =  replaceTemplateParams(template.Body__c.stripHtmlTags(), values);
            
            if (leadObj.BrokerAgent__c != null && !isADHALead) {
                pushNotification.Contact__c = leadObj.BrokerAgent__c;
            }

            if (isADHALead && String.isNotBlank(leadObj.Email)) {
                 pushNotification.Email__c = leadObj.Email;
            }
            
        } else if (sObj.getSObjectType() == Case.getSObjectType()) {
            Case caseObj = (Case)sObj;
            pushNotification.ObjectAPIName__c = 'Case';
            pushNotification.RecordId__c = caseObj.Id;
            pushNotification.Body__c = replaceTemplateParams(template.Body__c.stripHtmlTags(), values);
            
            if(template.Name == 'Service Request Resolved'){
                if (caseObj.ContactId != null) {
                    pushNotification.Contact__c = caseObj.ContactId; /// send to Respective User
                } 
            }
        }
        else if (sObj.getSObjectType() == Account.getSObjectType()) {
            Account accountObj = (Account)sObj;
            pushNotification.ObjectAPIName__c = 'Account';
            pushNotification.RecordId__c = accountObj.Id;
            pushNotification.Title__c = replaceTemplateParams(template.Title__c.stripHtmlTags(), values);
            pushNotification.Body__c = replaceTemplateParams(template.Body__c.stripHtmlTags(), values);
            
            if(template.Name == 'Account Suspended'){
                //pushNotification.Contact__c = accountObj.Age;
            }
            else{
                for (Contact con : accountObj.Contacts) {
                    if (con.BrokerContactRole__c != null &&
                        con.BrokerContactRole__c.contains('SuperAdmin')) {
                            pushNotification.Contact__c = con.Id;
                            break;
                        }
                }
            }
        }
        else if (sObj.getSObjectType() == Contact.getSObjectType()) {
            Contact contactObj = (Contact)sObj;
            pushNotification.ObjectAPIName__c = 'Contact';
            pushNotification.RecordId__c = contactObj.Id;
            pushNotification.Body__c = replaceTemplateParams(template.Body__c.stripHtmlTags(), values);
            pushNotification.Contact__c = contactObj.Id;
        }
        else if(sObj.getSObjectType() == BrokerCommission__c.getSObjectType()){
            BrokerCommission__c brokerCommissionObj = (BrokerCommission__c)sObj;
            pushNotification.ObjectAPIName__c = 'BrokerCommission__c';
            pushNotification.RecordId__c = brokerCommissionObj.Id;
            pushNotification.Body__c =  replaceTemplateParams(template.Body__c.stripHtmlTags(), values);
            
            if (brokerCommissionObj.Agent__c != null) {
                pushNotification.Contact__c = brokerCommissionObj.Agent__c;
            }
        }
        
        else if (sObj.getSObjectType() == SalesOrder__c.getSObjectType()) {
            SalesOrder__c salesOrderObj = (SalesOrder__c)sObj;
            pushNotification.ObjectAPIName__c = 'SalesOrder__c';
            pushNotification.RecordId__c = salesOrderObj.Id;
            pushNotification.Body__c = replaceTemplateParams(template.Body__c.stripHtmlTags(), values);
        }  
        return pushNotification;
    }

    public PushNotification__c getApprovalProcessPushNotificationRecord(Id recordId, String recipientEmail, PushNotificationTemplate__c template, List<String> values) {
        PushNotification__c pushNotification = new PushNotification__c();
        pushNotification.Type__c = template.Name;
        pushNotification.Title__c = replaceTemplateParams(template.Title__c.stripHtmlTags(), values);
        pushNotification.Body__c = replaceTemplateParams(template.Body__c.stripHtmlTags(), values);
        pushNotification.NotificationType__c = template.NotificationType__c;
        pushNotification.SenderBloomPartnersID__c = template.SenderBloomPartnersID__c;
        pushNotification.ObjectAPIName__c = 'Approval Process';
        pushNotification.RecordId__c = recordId;
        pushNotification.Email__c = recipientEmail;

        return pushNotification;
    }
}