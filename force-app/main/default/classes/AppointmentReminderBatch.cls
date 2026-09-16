/**
 * Class       : AppointmentReminderBatch
 * Author      : Vishwas Kumar
 * Description : Batch and scheduled job to send reminder emails
 *               for appointments scheduled for tomorrow.
 * Test Class  : AppointmentReminderBatchTest
 */

public class AppointmentReminderBatch implements Database.Batchable<sObject>, Schedulable{

    private static final String MTD_APPOINTMENT_REMINDER_EMAIL_TEMPLATE_ID = 'AppointmentReminderEmailTemplateId';
     private static final String STATUS_SCHEDULED_STR { get { return 'Scheduled'; } }
    private static final string APPOINTMENT_STR { get { return 'Appointment'; } }
    private static final string MTD_OWE_NO_REPLY_BLOOM_EMAIL_ID { get { return 'BloomNoReplyOWEmailId'; } }


    public Database.QueryLocator start(Database.BatchableContext bc) { 
        Date reminderDate = Date.today().addDays(1);

        DateTime startOfReminderDate = DateTime.newInstance(reminderDate, Time.newInstance(0, 0, 0, 0));
        DateTime startOfNextDate = startOfReminderDate.addDays(1);

        String query = 'SELECT Id, WhoId, WhatId, OwnerId, StartDateTime, EndDateTime, Location, Type, AppointmentStatus__c, AppointmentSlot__c FROM Event ' +
        'WHERE Type = :APPOINTMENT_STR AND AppointmentStatus__c = :STATUS_SCHEDULED_STR AND StartDateTime >= :startOfReminderDate AND StartDateTime < :startOfNextDate';

       return Database.getQueryLocator(query);
    }

    
    public void execute(Database.BatchableContext bc, List<Event> events) {

        if (!events.isEmpty()) {
            
        	Set<Id> userIds = new Set<Id>();

        	for (Event eventRec : events) { 
            	if (eventRec.OwnerId != null) {
                userIds.add(eventRec.OwnerId);
            	}
        	}

        	sendAppointmentReminderEmail(events,userIds);
        }
    }

    public void finish(Database.BatchableContext bc) {
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new AppointmentReminderBatch(), 100);
    }


    public static void sendAppointmentReminderEmail(List<Event> events, Set<Id> userIds){
        
         Map<String, String> templateFieldValues = new Map<String, String>();
        Map<Id, Contact> contactMap = new Map<Id, Contact>();
        Map<Id, Lead> leadMap = new Map<Id, Lead>();
        Map<Id, Account> accountMap = new Map<Id, Account>();
        Set<Id> contactIds = new Set<Id>();
        Set<Id> leadIds = new Set<Id>();
        
        EmailService objEmailService = EmailService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        Map<Id, User> userMap = UserService.getInstance().getActiveUsersByIds(userIds);
        
         EmailTemplate emailTemplate = objEmailService.getEmailTemplateById(objMetadataService.getAppSettingTextValue(MTD_APPOINTMENT_REMINDER_EMAIL_TEMPLATE_ID));
        Id noReplyBloomOWDId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_EMAIL_ID);
        
        for (Event eventRec : events) {
            if (eventRec.WhoId != null) {
                
                if (eventRec.WhoId.getSObjectType() == Contact.SObjectType) {
                    contactIds.add(eventRec.WhoId);
                }else if (eventRec.WhoId.getSObjectType() == Lead.SObjectType) {
                    leadIds.add(eventRec.WhoId);
                }
            }
        }
        if (!contactIds.isEmpty())
            contactMap = ContactService.getInstance().getContactsByIds(contactIds);
        if (!leadIds.isEmpty())
            leadMap = LeadService.getInstance().getLeadsByIds(leadIds);
        
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        
        for(Event eventRec : events) {
            
            if (eventRec.WhoId.getSObjectType() == Contact.SObjectType) {
                Contact contactRec = contactMap.get(eventRec.WhoId);
                templateFieldValues.put('customerName', String.isBlank(contactRec.Name) ? '' : contactRec.Name);
                templateFieldValues.put('customerNameArabic',  String.isBlank(contactRec.Account.NameinArabic__c) ? contactRec.Name : contactRec.Account.NameinArabic__c);
            } else if (eventRec.WhoId.getSObjectType() == Lead.SObjectType) {
                Lead leadRec = leadMap.get(eventRec.WhoId);
                templateFieldValues.put('customerName', String.isBlank(leadRec.Name) ? '' : leadRec.Name);
                templateFieldValues.put('customerNameArabic', String.isBlank(leadRec.NameArabic__c) ? leadRec.Name : leadRec.NameArabic__c);
            }
             User accountManager = userMap.get(eventRec.OwnerId);
            templateFieldValues.put('accountManagerName', accountManager?.Name);
            templateFieldValues.put('accountManagerPhone', accountManager?.MobilePhone);
            emailList.add(ActivityService.getInstance().createAppointmentNotificationEmail(emailTemplate, eventRec, templateFieldValues));
        }
        objEmailService.sendEmail(emailList);
    }
}