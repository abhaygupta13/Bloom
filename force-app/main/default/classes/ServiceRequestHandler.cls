/*
* @Author : Biswajeet
* @CreatedDate : 26th AUG 2024
* @Description : Service Request Handler for generic methods
*/
/*****************************************************************************************************
* Version       Author          Date             Comment
* 1.0           Biswajeet      26AUG2024
*****************************************************************************************************/
public class ServiceRequestHandler {
    
    private static final String MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final string MTD_NEW_SERVICE_REQUEST_ACKNOWLEDGEMENT_EMAIL_TEMPLATE_ID { get { return 'NewServiceRequestAssignmentId'; } }
    private static final string MTD_SERVICE_REQUEST_CLOSURE_EMAIL_TEMPLATE_ID { get { return 'ServiceRequestClosureId'; } }
    private static final string MTD_SERVICE_REQUEST_CANCELLATION_EMAIL_TEMPLATE_ID { get { return 'ServiceRequestCancellationEmailTempId'; } }
    private static final string COMMON_AREA_REQUEST_RT { get { return 'Common_Area_Request'; } }
    private static final string SR_CREATE_SMS_NOTIFICATION { get { return 'BFM SR Create Notification'; } }
    private static final string SR_CLOSURE_SMS_NOTIFICATION { get { return 'BFM SR Closure Notification'; } }
    private static final string MTD_SERVICE_REQUEST_ASSIGNMENT_EMAIL_TEMPLATE_ID { get { return 'ServiceRequestAssignmentId'; } }
    private static final string SERVICE_REQUEST_STR { get { return 'Service Request'; } }
    
    private static boolean handleCaseClosure = true;
    
    
    private static ServiceRequestHandler instance;
    
    public ServiceRequestHandler() {
        
    }
    
    public static ServiceRequestHandler getInstance() { 
        if(instance == null) {
            instance = new ServiceRequestHandler();
        }
        return instance;
    }
    
    public void serviceRequestAcknowledgementEmailNotification(List<Case> caseList){
        if(!caseList.isEmpty() && caseList != NULL){
            MetadataService objMetadataService = MetadataService.getInstance();
            EmailService objEmailService = EmailService.getInstance();
            Id noReplyOWDId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
            List<Messaging.SingleEmailMessage> emailList = new list<Messaging.SingleEmailMessage>(); 
            Id emailTemplateId = objMetadataService.getAppSettingTextValue(MTD_NEW_SERVICE_REQUEST_ACKNOWLEDGEMENT_EMAIL_TEMPLATE_ID);
            Id commonAreaRequestRTId = Utility.getRecordTypeIdByDevName(Case.SObjectType,COMMON_AREA_REQUEST_RT); 

            for(Case objCase :caseList){
                if(!objCase.StopEmailsToCustomer__c){
                    if(objCase.ContactId != NULL){
                        Messaging.SingleEmailMessage email = objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(emailTemplateId, noReplyOWDId,  objCase.Id, objCase.ContactId, null,null,null);
                        emailList.add(email);
                    }else if(objCase.SuppliedEmail != NULL){
                        Messaging.SingleEmailMessage email = objEmailService.getSingleEmailMessageWithoutTargetObjectId(emailTemplateId, noReplyOWDId,  objCase.Id, new List<String>{objCase.SuppliedEmail}, null,null);
                        emailList.add(email);
                    }
                    else if(objCase.RecordTypeId == commonAreaRequestRTId && objCase.RequesterEmail__c != null){
                        Messaging.SingleEmailMessage email = objEmailService.getSingleEmailMessageWithoutTargetObjectId(emailTemplateId, noReplyOWDId,  objCase.Id, new List<String>{objCase.RequesterEmail__c}, null,null);
                        emailList.add(email);
                        sendSMSNotification(objCase, SR_CREATE_SMS_NOTIFICATION);
                    }
                }
            }
            objEmailService.sendEmail(emailList);  
        }
    }

    public void serviceRequestAssignmentEmailNotification(Set<Id> caseIds){
        List<Case> caseList = CaseService.getInstance().getCaseByIds(caseIds);
        List<Messaging.SingleEmailMessage> emailList = new list<Messaging.SingleEmailMessage>();

        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        
        Id noReplyOWDId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
        for(Case caseObj : caseList){
            List<String> toAddress = objEmailService.getOwnerEmails(caseObj.OwnerId);
            Id emailTemplateId;
            if(caseobj.CaseType__c == SERVICE_REQUEST_STR){
                emailTemplateId = objMetadataService.getAppSettingTextValue(MTD_SERVICE_REQUEST_ASSIGNMENT_EMAIL_TEMPLATE_ID);
            }
            if(emailTemplateId != null){
                Messaging.SingleEmailMessage email = objEmailService.getSingleEmailMessageWithoutTargetObjectId(emailTemplateId, noReplyOWDId, caseobj.Id,toAddress, null, null);
                emailList.add(email);
            }
        }
        objEmailService.sendEmail(emailList);
    }

    public void serviceRequestClosureEmailNotification(List<Case> caseList){
        if(caseList != NULL && !caseList.isEmpty()){
            
            MetadataService objMetadataService = MetadataService.getInstance();
            EmailService objEmailService = EmailService.getInstance();

            List<Messaging.SingleEmailMessage> emailList = new list<Messaging.SingleEmailMessage>(); 

            Id noReplyOWDId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
            Id closureEmailTemplateId = objMetadataService.getAppSettingTextValue(MTD_SERVICE_REQUEST_CLOSURE_EMAIL_TEMPLATE_ID);
            Id cancellationEmailTemplateId = objMetadataService.getAppSettingTextValue(MTD_SERVICE_REQUEST_CANCELLATION_EMAIL_TEMPLATE_ID);
            Id commonAreaRequestRTId = Utility.getRecordTypeIdByDevName(Case.SObjectType,COMMON_AREA_REQUEST_RT); 

            for(Case objCase :caseList){

                if(objCase.StopEmailsToCustomer__c){
                    continue;
                }
                Id emailTemplateId;

                if(objCase.Status == 'Closed'){
                    emailTemplateId = closureEmailTemplateId;
                }
                else if(objCase.Status == 'Cancelled'){
                    emailTemplateId = cancellationEmailTemplateId;
                }

                if(emailTemplateId != null){
                    Messaging.SingleEmailMessage email = objEmailService.getSingleEmailMessageWithoutTargetObjectId(emailTemplateId, noReplyOWDId,  objCase.Id, new List<String>{objCase.RequesterEmail__c}, null,null);
                    emailList.add(email);
                }
                sendSMSNotification(objCase, SR_CLOSURE_SMS_NOTIFICATION);
            }
            objEmailService.sendEmail(emailList);  
        }
    }

    public void sendSMSNotification(Case caseObj, String smsTemplateName){
        if(String.isNotBlank(caseObj.RequesterContactNumber__c)){
            NotificationService objNotificationService = NotificationService.getInstance();
            IntegrationRecordService objIntegrationRecordService = IntegrationRecordService.getInstance();
    
            List<IntegrationRecord__c> integrationRecords = new List<IntegrationRecord__c>();
            Set<String> templateNames = new Set<String>{SR_CREATE_SMS_NOTIFICATION, SR_CLOSURE_SMS_NOTIFICATION};
            Map<String, SMSTemplate__c> smsTemplateMap = objNotificationService.getSMSTemplates(templateNames);
            List<String> values = new List<String>{caseObj.RequesterName__c,caseObj.CaseNumber};
            
            integrationRecords.add(objNotificationService.getSMSIntegrationRecord(caseObj, smsTemplateMap.get(smsTemplateName), values));
            objIntegrationRecordService.insertIntegrationRecords(integrationRecords);
        }
    }
}