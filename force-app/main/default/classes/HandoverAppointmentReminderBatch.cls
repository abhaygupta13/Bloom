/***
Class       : HandoverAppointmentReminderBatch
Author      : Rajat Rastogi
Description : HandoverAppointmentReminderBatchTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version            Date                Details
1.      V1.0               25/06/2024          Initial Version  
2.      V1.1               03/08/2026          Optimized queries, null checks, and removed unused logic
****************************************************************************************************************/ 

public without sharing class HandoverAppointmentReminderBatch implements Database.Batchable<SObject>, Schedulable {
    
    private static final String Appointment_Booked_Reminder_After_Five_Days = 'Appointment Booked Reminder After Five Days';
    private static final String Appointment_Booked_Reminder_After_Ten_Days = 'Appointment Booked Reminder After Ten Days';
    private static final String Appointment_Booked_Reminder_after_15_days = 'Appointment Booked Reminder after 15 days';
    private static final String Handover_Sub_Status_Book_Appointment_with_Customer = 'Book Appointment with Customer';
    private static String Customer_Not_Available = 'Customer Not available';
    private static final String NoReplyEmailAddress = 'NoReplyEmailAddress';
    private static final String OrgWideEmailAddress = 'OrgWideEmailAddress';
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        Set<Id> eventWhatIds = new Set<Id>();
        for (Event evt : [SELECT WhatId FROM Event WHERE WhatId != NULL]) {
            eventWhatIds.add(evt.WhatId);
        }
        return Database.getQueryLocator([
            SELECT Id, Name,Contact__c,StopAllEmailCommunication__c,Handover_Phase__r.StopThirdHandoverAppointmentReminder__c,Project__r.BloomPhoneArabic__c,Handover_Phase__r.ApppintmentReminderStop__c,Unit_Plot_Number__c,Unit__r.DoorNumber__c,LocationName__c,NOC_Expiry_Date__c,Project__r.Handover_Community_Guidelines_Arabic__c,Project__r.Handover_Community_Guidelines_English__c,CRM_Team_Assigned_User__c,BloomPhone__c,BloomEmail__c,CustomerEmail__c,ProjectName__c,ProjectNameArabic__c,Unit__c,Unit__r.SAP_Unit_Number__c,Sub_Status__c, Is_Orientation_Letter_Sent__c,Orientation_Letter_Sent_Date__c,Customer_Email__c, 
            Customer_Availability_for_CHO__c, Date_of_Customer_Contacted__c,HO_Agent_Assigned_User__c,Customer_Name__c, Project__r.Name, Account_Manager_Name__c,
            Account_Manager_Email__c,Account_Manager_Phone__c,Project__c,Project__r.ProjectNameArabic__c,Customer_Name_Arabic__c,Promise_to_Pay_Date__c, Project__r.Office_Location__c,
            Account_Manager_Name_Arabic__c,Notice_of_Completion_Date__c,Home_Orientation_Invitation_Date__c,Settlement_Follow_Up_Date__c,Sales_Order__r.Account__r.PersonMailingCountry,
            Sales_Order__r.Account__r.Phone,Sales_Order__r.Account__r.MobileCountryCode__pc,Project_Name_Arabic__c,Project_Name__c,AccountManagerEmail__c,
            Location__c,Customer_Number__c,Bloom_Email__c,Bloom_Phone__c,
            Address__c, NOC_Date__c,SettlementFollowUpDate__c,
            HomeOrientationInvitationDate__c,HO_DD_MM_YYYY__c,Location_Name__c,Date__c,Unit_Code__c
            FROM Handover__c
            WHERE Is_Orientation_Letter_Sent__c = TRUE AND Handover_Phase__r.ApppintmentReminderStop__c=false AND StopAllEmailCommunication__c=false
            AND Sub_Status__c =:Handover_Sub_Status_Book_Appointment_with_Customer
            AND 
            (Customer_Availability_for_CHO__c!='Customer available'
             AND Home_Orientation_Invitation_Date__c != NULL
            ) 
            AND Id NOT IN :eventWhatIds]);
    }
    
    public void execute(Database.BatchableContext BC, List<Handover__c> handoverList) {
        try {
            HandoverService handoverService = HandoverService.getInstance();
            MetadataService metadataService = MetadataService.getInstance();
            
            String noReply = metadataService.getAppSettingTextValue(NoReplyEmailAddress);
            String owea = metadataService.getAppSettingTextValue(OrgWideEmailAddress);
            
            // Fetch email templates dynamically outside loop
            Map<String, EmailTemplate> emailTemplateMap = new Map<String, EmailTemplate>();
            for (EmailTemplate empTemp : [
                SELECT Id, Name, HTMLValue, Subject 
                FROM EmailTemplate 
                WHERE Name IN (:Appointment_Booked_Reminder_After_Five_Days, :Appointment_Booked_Reminder_After_Ten_Days, :Appointment_Booked_Reminder_after_15_days) 
                AND IsActive = true
            ]) {
                emailTemplateMap.put(empTemp.Name, empTemp); 
            }
            
            EmailTemplate reminder1 = emailTemplateMap.get(Appointment_Booked_Reminder_After_Five_Days);
            EmailTemplate reminder2 = emailTemplateMap.get(Appointment_Booked_Reminder_After_Ten_Days);
            EmailTemplate reminder3 = emailTemplateMap.get(Appointment_Booked_Reminder_after_15_days);
            
            List<Handover__c> handoverListToUpdate = new List<Handover__c>();
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            Date today = Date.today();
              System.debug('handoverList'+handoverList);            
            for (Handover__c handover : handoverList) {
                
                if (handover.Home_Orientation_Invitation_Date__c == null) {
                    continue;
                }
               
                Integer daysDifference = handover.Home_Orientation_Invitation_Date__c.daysBetween(today);
                Boolean stopThirdReminder = handover.Handover_Phase__r.StopThirdHandoverAppointmentReminder__c;
                
                EmailTemplate selectEmailTemplate = null;
                Boolean isFifteenDays = false;
                
                if (daysDifference == 5) {
                    selectEmailTemplate = reminder1;
                } else if (daysDifference == 10) {
                    selectEmailTemplate = reminder2;
                } else if (daysDifference == 15 && !stopThirdReminder) {
                    selectEmailTemplate = reminder3;
                    isFifteenDays = true;
                }
                
                
                if (selectEmailTemplate != null) {
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    
                    if (String.isNotBlank(noReply)) {
                        email.setReplyTo(noReply);
                    }
                    if (String.isNotBlank(owea)) {
                        email.setOrgWideEmailAddressId(owea);
                    }
                    if (String.isNotBlank(handover.Contact__c)) {
                        email.setTargetObjectId(handover.Contact__c);
                        
                    }else if (String.isNotBlank(handover.CustomerEmail__c)) {
                        
                        email.setToAddresses(new String[] { handover.CustomerEmail__c });
                    }
                    
                    if (isFifteenDays && String.isNotBlank(handover.HO_Agent_Assigned_User__c)) {
                        email.setCcAddresses(new String[] { handover.HO_Agent_Assigned_User__c });
                    }
                    
                    email.setSubject(HandoverEmailHelper.getDynamicSubject(selectEmailTemplate.Subject, handover));
                    email.setHtmlBody(HandoverEmailHelper.getDynamicBody(selectEmailTemplate.HtmlValue, handover));
                    email.setWhatId(handover.Id);
                    email.setSaveAsActivity(true);
                    emails.add(email);
                    
                    if (isFifteenDays) {
                        handover.Customer_Availability_for_CHO__c =Customer_Not_Available;
                        handover.OwnerId = handover.HO_Agent_Assigned_User__c;
                        handoverListToUpdate.add(handover);
                    }
                }
            }
            
            
            if (!emails.isEmpty()) {
                Messaging.SendEmailResult[] results = Messaging.sendEmail(emails, false);
                for (Messaging.SendEmailResult res : results) {
                    if (!res.isSuccess()) {
                        ErrorLogHandler.logErrorWithoutException(
                            'HandoverAppointmentReminderBatch', 
                            'sendEmailProcess failed', 
                            res.getErrors()[0].getMessage()
                        );
                    }
                }
            }
            
            
            handoverService.updateHandoverWithoutTrigger(handoverListToUpdate);
            
            
        } catch (Exception ex) {
            ErrorLogHandler.logError('HandoverAppointmentReminderBatch', 'execute', ex, '');
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        // Any post-processing logic can be done here
    }
    
    public void execute(SchedulableContext SC) {
       
        Database.executeBatch(new HandoverAppointmentReminderBatch(), 200);
    }
}