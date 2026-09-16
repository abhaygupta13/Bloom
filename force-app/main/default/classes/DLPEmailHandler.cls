/*
*********************************************************
Apex Class Name    : DLPEmailHandler
Created Date       : December 26, 2024
@description       : This class is used for sending emails.
@author            : Pavitra Chauhan
Modification Log   :
Ver   Date         Author                               Modification
2.0   10-09-2026   Abhay Gupta                          Optimised the class and removed commented code
*********************************************************
*/
public class DLPEmailHandler {
    private static final String TEXT_TEMPLATE_TYPE = 'text';
    private static final String CONTENT_TYPE_APPLICATION_PDF = 'application/pdf';

    public static String meetingDate = '';
    public static String meetingTime = '';
    
    public static Messaging.SingleEmailMessage sendEmailProcess(EmailTemplate mailTemplate, WorkOrder workOrder, ServiceAppointment ServiceAppointmentObj, List<String> toAddress, ContentVersion contentVersionObj, OrgWideEmailAddress orgWideEmail) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<Attachment> attachmentListOnActivity = new  List<Attachment>();
        String body;

        try {
            String subject = mailTemplate.Subject;

            setAttachment(mail, contentVersionObj);
            setOrgWideEmail(mail, orgWideEmail);
            setRecipients(mail, toAddress, workOrder.Customer_Email__c);          
            
            if(mailTemplate.TemplateType == TEXT_TEMPLATE_TYPE) {
                mail.setPlainTextBody(String.valueOf(mailTemplate.Body));
            } else {
                mail.setHtmlBody(getDynamicBody(mailTemplate.HtmlValue, workOrder, ServiceAppointmentObj));
            }

            mail.setSubject(getDynamicSubject(mailTemplate.Subject, workOrder));
            mail.setUseSignature(true);
            mail.setwhatid(workOrder.Id);
            mail.setSaveAsActivity(true);   

        } catch(Exception ex) {
            ErrorLogHandler.logError('DLPEmailHandler', 'sendEmailProcess', ex, ex.getStackTraceString());
        }
        return mail;  
    }

    private static void setAttachment(Messaging.SingleEmailMessage mail, ContentVersion contentVersionObj) {
        if (contentVersionObj != null && contentVersionObj.Title != null && contentVersionObj.VersionData != null) {
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName(contentVersionObj.Title);
            attachment.setBody(contentVersionObj.VersionData);
            attachment.setContentType(CONTENT_TYPE_APPLICATION_PDF);
            mail.setFileAttachments(new List<Messaging.EmailFileAttachment>{attachment});
        }
    }

    private static void setOrgWideEmail(Messaging.SingleEmailMessage mail, OrgWideEmailAddress orgWideEmail) {
        if (orgWideEmail != null && orgWideEmail.Id != null) {
            mail.setOrgWideEmailAddressId(orgWideEmail.Id);
        }
    }

    private static void setRecipients(Messaging.SingleEmailMessage mail, List<String> toAddress, String customerEmail) {
        mail.setToAddresses(toAddress != null && !toAddress.isEmpty() ? toAddress : new List<String>{customerEmail});
    }
    
    private static String getDynamicSubject(String subject, WorkOrder workOrder) {
        subject = subject.replace('[Unit_Number]',String.isNotBlank(workOrder.Unit__r.Name) ? workOrder.Unit__r.Name :'N/A');
        subject = subject.replace('[WorkOrder_Number]', String.isNotBlank(workOrder.WorkOrderNumber) ? workOrder.WorkOrderNumber : 'N/A');
        subject = subject.replace('[Unit_Code_Arabic]',String.isNotBlank(workOrder.Unit__r.Name) ? workOrder.Unit__r.Name :'N/A');
        subject = subject.replace('[Project_Name_Arabic]',String.isNotBlank(workOrder.Project__r.ProjectNameArabic__c) ? workOrder.Project__r.ProjectNameArabic__c : String.isNotBlank(workOrder.Project__r.Name) ? workOrder.Project__r.Name : 'N/A');
        subject = subject.replace('[Project_Name]',String.isNotBlank(workOrder.Project__r.Name) ? workOrder.Project__r.Name : 'N/A');
        return subject;
    }
    
    private static String getDynamicBody(String body, WorkOrder workOrder, ServiceAppointment ServiceAppointmentObj) {
        body = body.replace('[WorkOrder_Number]', String.isNotBlank(workOrder.WorkOrderNumber) ? workOrder.WorkOrderNumber : 'N/A');
        body = body.replace('[Unit_Number]', String.isNotBlank(workOrder.Unit__r.Name) ? workOrder.Unit__r.Name : 'N/A');
        body = body.replace('[Date_and_Time]', ServiceAppointmentObj.SchedStartTime != null ? ServiceAppointmentObj.SchedStartTime.format('yyyy-MM-dd HH:mm:ss') : 'N/A');
        body = body.replace('[Closed_Date]', ServiceAppointmentObj.SchedEndTime != null ? ServiceAppointmentObj.SchedEndTime.format('yyyy-MM-dd HH:mm:ss') : 'N/A');
        body = body.replace('[DLP_Agent_Name]', String.isNotBlank(workOrder.Owner.Name) ? workOrder.Owner.Name : 'N/A');
        body = body.replace('[Project_Name]', String.isNotBlank(workOrder.Project__r.Name) ? workOrder.Project__r.Name : 'N/A');
        body = body.replace('[Contractor_Name]',String.isNotBlank(workOrder.Contractor_Name__c) ? workOrder.Contractor_Name__c : 'N/A');
        body = body.replace('[Customer_Name]',String.isNotBlank(workOrder.New_Requester_Name__c) ? workOrder.New_Requester_Name__c : 'N/A');
        body = body.replace('[DD-MM-YYYY]',String.isNotBlank(meetingDate) ? meetingDate : 'N/A');
        body = body.replace('[TIME_SLOT_FROM_TO]',String.isNotBlank(meetingTime) ? meetingTime : 'N/A');
        body = body.replace('[Location]',String.isNotBlank(workOrder.Project__r.Office_Location__c) ? workOrder.Project__r.Office_Location__c : 'N/A');
        
        // arabic
        body = body.replace('[Customer_Name_Arabic]',String.isNotBlank(workOrder.New_Requester_Name__c) ? workOrder.New_Requester_Name__c :  String.isNotBlank(workOrder.New_Requester_Name__c) ? workOrder.New_Requester_Name__c : 'N/A');
        body = body.replace('[Project_Name_Arabic]',String.isNotBlank(workOrder.Project__r.ProjectNameArabic__c) ? workOrder.Project__r.ProjectNameArabic__c : String.isNotBlank(workOrder.Project__r.Name)? workOrder.Project__r.Name : 'N/A');
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

        for(SendEmailRequest request: requests) {
            if (request.templateName != null && request.TargetObjectId != null && request.whatId != null && request.toAddress != null) {
                template = request.templateName;
                TargetObjectId = request.TargetObjectId;
                whatId = request.whatId;
                toAddress = request.toAddress;
            }
        }

        EmailTemplate et = EmailTemplateService.getEmailTemplateByName(template);
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
        @InvocableVariable(required = true) public String templateName;
        @InvocableVariable(required = true) public String TargetObjectId;
        @InvocableVariable(required = true) public String whatId;
        @InvocableVariable(required = true) public List<String> toAddress;
    }
}