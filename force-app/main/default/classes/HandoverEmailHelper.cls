/***
Class       : HandoverRoundRobin
Author      : Rajat Rastogi
Description : 
TestClass   : HandoverTriggerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.      V1.0             	 11/06/2024           Initial Version  
****************************************************************************************************************/ 
public without sharing class HandoverEmailHelper {
    
    public static String meetingDate = '';
    public static String meetingTime = '';
    public static List<ContentVersion> fileData = new List<ContentVersion>();
    private static final string MDT_HANDOVER_ORG_WIDE_EMAIL_ADDRESS_ID { get { return 'OrgWideEmailAddress'; } }
    
    // this method is used for single mail
    public static String sendEmailProcess(Id templateId, Id handoverId, List<String> toAddress, List<String> ccAddress, List<String> documentsListToAttach){
        try{
            MetadataService HandoverMetadataService = MetadataService.getInstance();
            String noreply = HandoverMetadataService.getAppSettingTextValue(HandoverConstants.NoReplyEmailAddress);
            String owea = HandoverMetadataService.getAppSettingTextValue(HandoverConstants.OrgWideEmailAddress);
            DocumentService DocumentService = DocumentService.getInstance();
            HandoverService HandoverService = HandoverService.getInstance();
            HandoverPhaseService objHandoverPhaseService = HandoverPhaseService.getInstance();
            EmailTemplate mailTemplate = [SELECT Id, Name,DeveloperName, Subject, Body, HTMLValue, TemplateType FROM EmailTemplate WHERE Id = :templateId
                                          AND IsActive = true LIMIT 1];
            
            // If any field is added in below query then add it to HandoverAppointmentReminderBatch and HandoverPaymentReminderBatch also
           // String templateDevName = mailTemplate.DeveloperName;
            String templateName = mailTemplate.Name;            
            Handover__c handover = HandoverService.getHandoverById(handoverId);
            HandoverPhase__c phaseRec = objHandoverPhaseService.getHandoverPhaseDetails(handover.Handover_Phase__c);
            System.debug('handover'+handover);
          /*  if(templateName.equalsIgnoreCase(Constants.Appointment_Booked_Template) || templateName.equalsIgnoreCase(Constants.KHO_Appointment_Scheduled_Template) ||
               templateName.equalsIgnoreCase(Constants.Home_Orientation_Appointment_Rescheduling)){
                   
                   Event meeting = new Event();
                   List<Event> events = [SELECT Id, Subject, WhatId,StartDateTime, EndDateTime, Time__c,Location,  FORMAT(CreatedDate) FROM Event
                                         WHERE WhatId =: handoverId ORDER BY createdDate ASC ];
                   if((templateName.equalsIgnoreCase(Constants.Appointment_Booked_Template) || templateName.equalsIgnoreCase(Constants.Home_Orientation_Appointment_Rescheduling)) && events.size()>0){
                       meeting = events[0];
                   }else if( templateName.equalsIgnoreCase(Constants.KHO_Appointment_Scheduled_Template)){
                       meeting = events[events.size()-1];
                   }
                   if( meeting != null && meeting.StartDateTime!= null){
                       meetingDate = meeting.StartDateTime.format('dd-MM-yyyy');
                   }
                   if( meeting != null & meeting.StartDateTime!= null){
                       meetingTime = meeting.StartDateTime.format('hh:mm a') + ' - ' + events[0].EndDateTime.format('hh:mm a');
                   }
               }*/
            Boolean isHomeOrientationMeeting = (templateId == phaseRec.CHOAppointmentConfirmEmailTempId__c);
                                               
            Boolean isKHOMeeting = (templateId == phaseRec.KeyHandoverInvitationEmailTempId__c);
            
            if (isHomeOrientationMeeting || isKHOMeeting) {
                Event meeting = new Event();
                List<Event> events = [
                    SELECT Id, Subject, WhatId, StartDateTime, EndDateTime, Time__c, Location, FORMAT(CreatedDate) 
                    FROM Event
                    WHERE WhatId = :handoverId 
                    ORDER BY CreatedDate ASC
                ];

                if (isHomeOrientationMeeting && !events.isEmpty()) {
                    meeting = events[0];
                } else if (isKHOMeeting && !events.isEmpty()) {
                    meeting = events[events.size() - 1];
                }
                if (meeting != null && meeting.StartDateTime != null) {
                    meetingDate = meeting.StartDateTime.format('dd-MM-yyyy');
                    if (meeting.EndDateTime != null) {
                        meetingTime = meeting.StartDateTime.format('hh:mm a') + ' - ' + meeting.EndDateTime.format('hh:mm a');
                    }
                }
            }
            
            String body;
            String Subject;
            Subject = mailTemplate.Subject;
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            List<Messaging.EmailFileAttachment> attachmentList = new  List<Messaging.EmailFileAttachment>();
            List<Attachment> attachmentListOnActivity = new  List<Attachment>();
            
            if(!documentsListToAttach.isEmpty()){
                List<Document__c> documentList = DocumentService.getDocumentsForHandover(documentsListToAttach, handover);
               
                Map<Id,ContentVersion> contDocIdTocontentVersionMap = new Map<Id,ContentVersion> ();
                List<Id> documentsId = new List<Id>();
                for(Document__c doc: documentList){
                    documentsId.add(doc.ContentDocumentId__c);
                }
                if(!documentList.isEmpty()){
                    fileData = [SELECT Id, Title, VersionData, ContentDocumentId, FileExtension
                                FROM ContentVersion WHERE ContentDocumentId IN : documentsId];
                    if(!fileData.isEmpty()){
                        for(ContentVersion cv: fileData){
                            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                            attachment.setFileName(cv.Title);
                            attachment.setBody(cv.VersionData);
                            attachment.setInline(false);
                            if(cv.FileExtension == 'pdf'){
                                attachment.setContentType('application/pdf');
                            }else if(cv.FileExtension == 'png'){
                                attachment.setContentType('image/png');
                            }else if(cv.FileExtension == 'jpeg' || cv.FileExtension == 'jpg'){
                                attachment.setContentType('image/jpeg');
                            }
                            attachmentList.add(attachment);
                        }
                        
                        mail.setFileAttachments(attachmentList);
                    }
                }    
            }
            
            if(toAddress.size()>0){
                mail.setToAddresses(toAddress);
            }else{
                mail.setToAddresses(new List<String>{handover.CustomerEmail__c});
            }
            
            if(ccAddress.size()>0){
                mail.setBccAddresses(ccAddress);
            }
            mail.setSubject(getDynamicSubject(mailTemplate.Subject, handover));
            mail.setUseSignature(true);
            if(mailTemplate.TemplateType == 'text'){
                mail.setPlainTextBody(String.valueOf(mailTemplate.Body));
            }else{
                mail.setHtmlBody(getDynamicBody(mailTemplate.HtmlValue, handover));
            }
            
            mail.setwhatid(handoverId);
            mail.setSaveAsActivity(true);
            
            if ( noreply !=null) {
                mail.setReplyTo(noreply);
            }
            
            if ( owea !=null) {
                mail.setOrgWideEmailAddressId(owea);
            }
            
            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
           
            if (results[0].isSuccess()) {
                List<EmailMessage> msgRec = [SELECT Id FROM EmailMessage ORDER BY CreatedDate DESC LIMIT 1];
                if (!msgRec.isEmpty()) {
                    Id recId = msgRec[0].Id;
                    if(!fileData.isEmpty()){
                        for(ContentVersion cv: fileData){
                            System.debug('Title: ' + cv.Title + ', FileExtension: ' + cv.FileExtension);
                            
                            Attachment attachment = new Attachment();
                            attachment.ParentId = recId;
                            String baseName = cv.Title;
                            String extension = (cv.FileExtension != null) ? cv.FileExtension.toLowerCase() : 'pdf';
                            
                            // Repeatedly remove the extension if it's duplicated
                            while (baseName.toLowerCase().endsWith('.' + extension + '.' + extension)) {
                                baseName = baseName.substring(0, baseName.length() - (extension.length() + 1));
                            }
                            
                            // If it ends with extension once, leave it. If not, add it.
                            if (!baseName.toLowerCase().endsWith('.' + extension)) {
                                baseName += '.' + extension;
                            }
                            
                            attachment.Name = baseName;
                            
                            attachment.Body = cv.VersionData;
                            attachmentListOnActivity.add(attachment);
                        }
                        Database.insert(attachmentListOnActivity,false);
                    }
                }
                try {
                    Handover__c ho = new Handover__c();
                    ho.Id = handoverId;
                    
                    if (templateId == phaseRec.HOCongratulationEmailTempId__c) {               
                        ho.CongratulationOnHandoverEmailsent__c = true;
                    } else if (templateId == phaseRec.CHOAttendedbyCustomerEmailTempId__c) {
                        ho.PropertyHomeOrientationReport_Sent__c = true;
                    } else if (templateId == phaseRec.KeyHandoverInvitationEmailTempId__c) {
                        ho.KeyHandoverInvitationSent__c = true;
                    } else if (templateId == phaseRec.ChoCustomerNotattendedEmailTempId__c) {
                        ho.PropertyHomeOrientationByBloom__c = true;
                    } else if (templateId == phaseRec.ChoDesnaggingEmailTempId__c) {                 
                         ho.HasCHODesnaggingemailsent__c = true;
                    } 
                   
                    
                    update ho;
                } catch (Exception e) {
                    ErrorLogHandler.logError('HandoverEmailHelper', 'sendEmailProcess - updateEmailFlag', e, '');
                }
                
                
                return 'SUCCESS';
            }else{
                String message = 'HandoverId - ' + handoverId + 'Template - ' + templateName + ' Mail Error - '; 
                ErrorLogHandler.logErrorWithoutException('HandoverEmailHelper','sendEmailProcess failed',message + String.valueOf(results[0].getErrors()[0].getMessage()));
                return 'FAILED';
            }
            
        }catch(Exception ex){
            ErrorLogHandler.logError('HandoverEmailHelper','sendEmailProcess',ex,'');
            return 'Mail not Send';
        }
    }
    
    
    
    public static String getDynamicSubject(String subject, Handover__c handover){
        subject = subject.replace('{{{Handover__c.Unit_Code__c}}}',String.isNotBlank(handover.Unit_Code__c) ? handover.Unit_Code__c :'N/A');
        subject = subject.replace('{{{Handover__c.Name}}}', String.isNotBlank(handover.Name)?handover.Name : 'N/A');
        subject = subject.replace('{{{Handover__c.Project_Name_Arabic__c}}}',String.isNotBlank(handover.ProjectNameArabic__c)? handover.ProjectNameArabic__c : String.isNotBlank(handover.ProjectName__c)? handover.ProjectName__c : 'N/A');
        subject = subject.replace('{{{Handover__c.Project_Name__c}}}',String.isNotBlank(handover.ProjectName__c)? handover.ProjectName__c : 'N/A');
        
        
        return subject;
    }
    

    public static String getDynamicBody(String body, Handover__c handover){
   
        body = body.replace('{{{Handover__c.Name}}}', String.isNotBlank(handover.Name)?handover.Name : 'N/A');//Done
        body = body.replace('{{{Handover__c.Customer_Name__c}}}',String.isNotBlank(handover.Customer_Name__c) ? handover.Customer_Name__c : 'N/A');// Done
        body = body.replace('{!Handover__c.Sub_Status__c}', String.isNotBlank(handover.Sub_Status__c) ? handover.Sub_Status__c : 'N/A');// done
        body = body.replace('{{{Handover__c.Unit_Code__c}}}',String.isNotBlank(handover.Unit_Code__c) ? handover.Unit_Code__c :'N/A');
        body = body.replace('{{{Handover__c.Project_Name__c}}}',String.isNotBlank(handover.ProjectName__c)? handover.ProjectName__c : 'N/A');
        body = body.replace('{{{Handover__c.Account_Manager_Name__c}}}',String.isNotBlank(handover.Account_Manager_Name__c)? handover.Account_Manager_Name__c : 'N/A');// Done
        body = body.replace('{{{Handover__c.AccountManagerEmail__c}}}',String.isNotBlank(handover.Account_Manager_Email__c)? handover.Account_Manager_Email__c : 'N/A');
        body = body.replace('{{{Handover__c.Account_Manager_Phone__c}}}',String.isNotBlank(handover.Account_Manager_Phone__c)? handover.Account_Manager_Phone__c : 'N/A');// done
        body = body.replace('[DD-MM-YYYY]',String.isNotBlank(meetingDate) ? meetingDate : 'N/A');
        body = body.replace('{{{Handover__c.HO_DD_MM_YYYY__c}}}', handover.HO_DD_MM_YYYY__c != null ? String.valueOf(handover.HO_DD_MM_YYYY__c) : 'N/A');
        body = body.replace('[TIME_SLOT_FROM_TO]',String.isNotBlank(meetingTime) ? meetingTime : 'N/A');
        body = body.replace('{{{Handover__c.Location__c}}}',String.isNotBlank(handover.Location__c) ? handover.Location__c : 'N/A');
        body = body.replace('{{{Handover__c.Location_Name__c}}}', String.isNotBlank(handover.Location_Name__c) ? handover.Location_Name__c : 'N/A'); 
        body = body.replace('{{{Handover__c.Date__c}}}', handover.Date__c != null ? String.valueOf(handover.Date__c) : 'N/A');
        body = body.replace('{{{Handover__c.Customer_Email__c}}}', String.isNotBlank(handover.CustomerEmail__c)? handover.CustomerEmail__c : 'N/A');// done
        body = body.replace('{{{Handover__c.Promise_to_Pay_Date__c}}}',handover.Promise_to_Pay_Date__c != null ? String.valueOf(handover.Promise_to_Pay_Date__c) : 'N/A');
        body = body.replace('{{{Handover__c.Customer_Number__c}}}',handover.Customer_Number__c  != null ? String.valueOf(handover.Customer_Number__c) : 'N/A');
        body = body.replace('{{{Handover__c.Address__c}}}',handover.Address__c != null ? String.valueOf(handover.Address__c) : 'N/A');
        body = body.replace('{{{Handover__c.Project__r.Handover_Community_Guidelines_English__c}}}',handover.Project__r.Handover_Community_Guidelines_English__c != null ? String.valueOf(handover.Project__r.Handover_Community_Guidelines_English__c) : 'N/A');
        body = body.replace('{{{Handover__c.Project__r.Handover_Community_Guidelines_Arabic__c}}}',handover.Project__r.Handover_Community_Guidelines_Arabic__c != null ? String.valueOf(handover.Project__r.Handover_Community_Guidelines_Arabic__c) : 'N/A');
         body = body.replace('{{{Handover__c.Unit__r.DoorNumber__c}}}',handover.Unit__r.DoorNumber__c != null ? String.valueOf(handover.Unit__r.DoorNumber__c) : 'N/A');
        body = body.replace('{{{Handover__c.Unit_Plot_Number__c}}}',handover.Unit_Plot_Number__c != null ? String.valueOf(handover.Unit_Plot_Number__c) : 'N/A');
       
        body = body.replace('{{{Handover__c.NOC_Expiry_Date__c}}}',handover.NOC_Expiry_Date__c != null ? String.valueOf(handover.NOC_Expiry_Date__c) : 'N/A');
       

        
        if(handover.SettlementFollowUpDate__c != null){
            body = body.replace('{{{Handover__c.SettlementFollowUpDate__c}}}', String.valueOf(handover.SettlementFollowUpDate__c) != null ? String.valueOf(handover.SettlementFollowUpDate__c) : 'N/A');
        }
        if(handover.NOC_Date__c != null){
            body = body.replace('{{{Handover__c.NOC_Date__c}}}', String.valueOf(handover.NOC_Date__c) != null ? String.valueOf(handover.NOC_Date__c) : 'N/A');
            
        }
        if(handover.HomeOrientationInvitationDate__c != null){
            body = body.replace('{{{Handover__c.HomeOrientationInvitationDate__c}}}', String.valueOf(handover.HomeOrientationInvitationDate__c) != null ? String.valueOf(handover.HomeOrientationInvitationDate__c) : 'N/A');
        }
        
        // arabic
        body = body.replace('{{{Handover__c.Customer_Name_Arabic__c}}}',String.isNotBlank(handover.Customer_Name_Arabic__c) ? handover.Customer_Name_Arabic__c :  String.isNotBlank(handover.Customer_Name__c) ? handover.Customer_Name__c : 'N/A');// done
        body = body.replace('{{{Handover__c.Project_Name_Arabic__c}}}',String.isNotBlank(handover.ProjectNameArabic__c)? handover.ProjectNameArabic__c : String.isNotBlank(handover.ProjectName__c)? handover.ProjectName__c : 'N/A');
        body = body.replace('{{{Handover__c.Unit_Code__c}}}',String.isNotBlank(handover.Unit_Code__c) ? handover.Unit_Code__c :'N/A');
        body = body.replace('{{{Handover__c.Account_Manager_Name_Arabic__c}}}',String.isNotBlank(handover.Account_Manager_Name_Arabic__c)? handover.Account_Manager_Name_Arabic__c : String.isNotBlank(handover.Account_Manager_Name__c)? handover.Account_Manager_Name__c : 'N/A');// done
        body = body.replace('{{{Handover__c.AccountManagerEmail__c}}}', String.isNotBlank(handover.AccountManagerEmail__c)? handover.AccountManagerEmail__c : 'N/A');
        body = body.replace('{{{Handover__c.Account_Manager_Phone__c}}}',String.isNotBlank(handover.Account_Manager_Phone__c)? handover.Account_Manager_Phone__c : 'N/A');// done
        body = body.replace('[DD-MM-YYYY_Arabic]',String.isNotBlank(meetingDate) ? meetingDate : 'N/A');
        body = body.replace('[TIME_SLOT_FROM_TO_Arabic]',String.isNotBlank(meetingTime) ? meetingTime : 'N/A');
        body = body.replace('{{{Handover__c.Location__c}}}',String.isNotBlank(handover.LocationName__c) ? handover.LocationName__c : 'N/A');// done
        body = body.replace('{{{Handover__c.Bloom_Phone__c}}}', String.isNotBlank(handover.BloomPhone__c) ? handover.BloomPhone__c : 'N/A');
       body = body.replace('{{{Handover__c.Project__r.BloomPhoneArabic__c}}}', String.isNotBlank(handover.Project__r.BloomPhoneArabic__c) ? handover.Project__r.BloomPhoneArabic__c : 'N/A');
        body = body.replace('{{{Handover__c.Bloom_Email__c}}}', String.isNotBlank(handover.BloomEmail__c) ? handover.BloomEmail__c : 'N/A');
        
        return body;
    }
}