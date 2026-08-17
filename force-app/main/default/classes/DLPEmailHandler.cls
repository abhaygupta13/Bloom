/*
*********************************************************
Apex Class Name    : DLPEmailHandler
Created Date       : August 20, 2024
@description       : This class is used for sending emails.
@author            : Pavitra Chauhan
Modification Log   :
Ver   Date         Author                               Modification
2.0   28-08-2024   Pavitra Chauhan                      Initial Version
*********************************************************
*/
public class DLPEmailHandler {
    
    public static String meetingDate = '';
    public static String meetingTime = '';
    public static List<ContentVersion> fileData = new List<ContentVersion>();
    
    public static Messaging.SingleEmailMessage sendEmailProcess(EmailTemplate mailTemplate, WorkOrder workOrder, ServiceAppointment ServiceAppointmentObj, List<String> toAddress, ContentVersion contentVersionObj, OrgWideEmailAddress orgWideEmail){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<Attachment> attachmentListOnActivity = new  List<Attachment>();
        String body;
        String Subject = mailTemplate.Subject;
        
        try{
            System.debug('mailTemplate >> ' + mailTemplate);
            System.debug('workOrder >> ' + workOrder);            
            System.debug('ServiceAppointmentObj >> ' + ServiceAppointmentObj);
                      
            if(contentVersionObj != NULL && contentVersionObj.Title != null){
                List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
                
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName(contentVersionObj.Title);
                attachment.setBody(contentVersionObj.VersionData);
                attachment.setContentType('application/pdf');
                emailAttachments.add(attachment);
                
                mail.setFileAttachments(emailAttachments);                
            }
            
            if(orgWideEmail.Id != null){
                mail.setOrgWideEmailAddressId(orgWideEmail.Id);
            }
            
            
            
            System.debug('toAddress1' + toAddress);
            if(toAddress.size() > 0){
                mail.setToAddresses(toAddress);
            }else{
                mail.setToAddresses(new List<String>{workOrder.Customer_Email__c});
            }           
            
            
            if(mailTemplate.TemplateType == 'text'){
                mail.setPlainTextBody(String.valueOf(mailTemplate.Body));
            }else{
                mail.setHtmlBody(getDynamicBody(mailTemplate.HtmlValue, workOrder, ServiceAppointmentObj));
            }
            mail.setSubject(getDynamicSubject(mailTemplate.Subject, workOrder));
            mail.setUseSignature(true);
            
            mail.setwhatid(workOrder.Id);
            mail.setSaveAsActivity(true);            
        }catch(Exception ex){
            ErrorLogHandler.logError('DLPEmailHandler','sendEmailProcess', ex, ex.getStackTraceString());
        }
        return mail;  
    }
    
    private static String getDynamicSubject(String subject, WorkOrder workOrder){
        subject = subject.replace('[Unit_Number]',String.isNotBlank(workOrder.Unit__r.Name) ? workOrder.Unit__r.Name :'N/A');//workOrder.Unit__r.SAP_Unit_Number__c
        subject = subject.replace('[WorkOrder_Number]', String.isNotBlank(workOrder.WorkOrderNumber)?workOrder.WorkOrderNumber : 'N/A');
        subject = subject.replace('[Unit_Code_Arabic]',String.isNotBlank(workOrder.Unit__r.Name) ? workOrder.Unit__r.Name :'N/A');//workOrder.Unit__r.SAP_Unit_Number__c
        subject = subject.replace('[Project_Name_Arabic]',String.isNotBlank(workOrder.Project__r.ProjectNameArabic__c)? workOrder.Project__r.ProjectNameArabic__c : String.isNotBlank(workOrder.Project__r.Name)? workOrder.Project__r.Name : 'N/A');
        subject = subject.replace('[Project_Name]',String.isNotBlank(workOrder.Project__r.Name)? workOrder.Project__r.Name : 'N/A');
        return subject;
    }
    
    private static String getDynamicBody(String body, WorkOrder workOrder, ServiceAppointment ServiceAppointmentObj){
        body = body.replace('[WorkOrder_Number]', String.isNotBlank(workOrder.WorkOrderNumber)?workOrder.WorkOrderNumber : 'N/A');
        body = body.replace('[Unit_Number]', String.isNotBlank(workOrder.Unit__r.Name)?workOrder.Unit__r.Name : 'N/A');
        body = body.replace('[Date_and_Time]', ServiceAppointmentObj.SchedStartTime != null?ServiceAppointmentObj.SchedStartTime.format('yyyy-MM-dd HH:mm:ss') : 'N/A');
        body = body.replace('[Closed_Date]', ServiceAppointmentObj.SchedEndTime	 != null?ServiceAppointmentObj.SchedEndTime.format('yyyy-MM-dd HH:mm:ss') : 'N/A');
        body = body.replace('[DLP_Agent_Name]', String.isNotBlank(workOrder.Owner.Name)?workOrder.Owner.Name : 'N/A');     
        body = body.replace('[Project_Name]',String.isNotBlank(workOrder.Project__r.Name)? workOrder.Project__r.Name : 'N/A');
        body = body.replace('[Contractor_Name]',String.isNotBlank(workOrder.Contractor_Name__c) ? workOrder.Contractor_Name__c : 'N/A');
        body = body.replace('[Customer_Name]',String.isNotBlank(workOrder.New_Requester_Name__c) ? workOrder.New_Requester_Name__c : 'N/A');
        body = body.replace('[DD-MM-YYYY]',String.isNotBlank(meetingDate) ? meetingDate : 'N/A');
        body = body.replace('[TIME_SLOT_FROM_TO]',String.isNotBlank(meetingTime) ? meetingTime : 'N/A');
        body = body.replace('[Location]',String.isNotBlank(workOrder.Project__r.Office_Location__c) ? workOrder.Project__r.Office_Location__c : 'N/A');
        
        // arabic
        body = body.replace('[Customer_Name_Arabic]',String.isNotBlank(workOrder.New_Requester_Name__c) ? workOrder.New_Requester_Name__c :  String.isNotBlank(workOrder.New_Requester_Name__c) ? workOrder.New_Requester_Name__c : 'N/A');
        body = body.replace('[Project_Name_Arabic]',String.isNotBlank(workOrder.Project__r.ProjectNameArabic__c)? workOrder.Project__r.ProjectNameArabic__c : String.isNotBlank(workOrder.Project__r.Name)? workOrder.Project__r.Name : 'N/A');
        body = body.replace('[Unit_Code_Arabic]',String.isNotBlank(workOrder.Unit__r.Name) ? workOrder.Unit__r.Name :'N/A');//workOrder.Unit__r.SAP_Unit_Number__c
        body = body.replace('[DD-MM-YYYY_Arabic]',String.isNotBlank(meetingDate) ? meetingDate : 'N/A');
        body = body.replace('[TIME_SLOT_FROM_TO_Arabic]',String.isNotBlank(meetingTime) ? meetingTime : 'N/A');
        body = body.replace('[Location_Arabic]',String.isNotBlank(workOrder.Project__r.Office_Location__c) ? workOrder.Project__r.Office_Location__c : 'N/A');
        body = body.replace('[BloomPhone]', System.Label.HandoverBloomPhone);
        body = body.replace('[BloomEmail]', System.Label.HandoverBloomEmail); 
        return body;
    }
    
    @InvocableMethod
    public static void sendEmailAndLogActivity(List<SendEmailRequest> requests) {
        String template;
        String TargetObjectId;
        String whatId;
        List<String> toAddress;
        for (SendEmailRequest request : requests) {
            if (request.templateName != null && request.TargetObjectId != null && request.whatId !=null && request.toAddress !=null) {
                template = request.templateName;
                TargetObjectId = request.TargetObjectId;
                whatId = request.whatId;
                toAddress = request.toAddress;

            }
        }
        system.debug('template-->'+template);
        system.debug('TargetObjectId-->'+TargetObjectId);
        EmailTemplate et = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE Name = :template LIMIT 1];
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setTemplateId(et.Id);
        email.setTargetObjectId(TargetObjectId);
        email.setwhatid(whatId);
        email.setTreatTargetObjectAsRecipient(false);
        email.setToAddresses(toAddress);
        email.setSaveAsActivity(true); 
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        
    }
    
    public class SendEmailRequest {
        @InvocableVariable(required = true)
        public String templateName;
        
        @InvocableVariable(required = true)
        public String TargetObjectId;
        
        @InvocableVariable(required = true)
        public String whatId;
        
        @InvocableVariable(required = true)
        public List<String> toAddress;
    }
}