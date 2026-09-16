/*
 * @Author : Vishwas Kumar
 * @CreatedDate : 6th AUG 2026
 * @Description : AppointmentController
 */
/*****************************************************************************************************
 * Version       Author      Date             Comment
 * 1.0           Vishwas   06AUG2026        Initial draft
 *****************************************************************************************************/
public with sharing class AppointmentController {
    
    private static final string APPOINTMENT_STR { get { return 'Appointment'; } }
    private static final string AVAILABLE_STR { get { return 'Available'; } }
    
    
    /**
     * @description Creates and inserts a new Event from the appointment popup's data.
     * @param       appointment Partial Event record built by the LWC (Subject, StartDateTime,
     *              EndDateTime, Description, AppointmentType__c, AppointmentMode__c,
     *              Location__c, Location).
     * @param       recordId Id of the source record (Account/Lead/Contact) used to resolve
     *              WhoId/WhatId prefill values.
     * @return      The newly inserted Event.
     */
    @AuraEnabled
    public static Event createAppointment(Event appointment, Id recordId) {
        try {
            appointment.Type = APPOINTMENT_STR;
            appointment.WhoId = getAppointmentPrefillContext(recordId).get('whoId');
            appointment.WhatId = getAppointmentPrefillContext(recordId).get('whatId');
            
            return ActivityService.getInstance().insertEvent(appointment);
            
        } catch (AuraHandledException err) {
            throw err;
        } catch (Exception e) {
            throw new AuraHandledException('Could not create appointment: ' + e.getMessage());
        }
    }
    
    /**
     * @description Resolves WhoId/WhatId prefill values for the appointment popup
     *              based on the source record (Account, Lead, or Contact).
     * @param       recordId Id of the record the action was launched from.
     * @return      Map with 'whoId' and 'whatId' keys.
     */
    private static Map<String, Id> getAppointmentPrefillContext(Id recordId) {
        
        Map<String, Id> context = new Map<String, Id>();
        
        if (recordId.getSObjectType() == Account.SObjectType) {
            AccountService objAccountService = AccountService.getInstance();
            context.put('whoId', objAccountService.getAccountById(recordId).PersonContactId);
            context.put('whatId', recordId);
        } else if (recordId.getSObjectType() == Lead.SObjectType) {
            LeadService leadService = LeadService.getInstance();
            context.put('whoId', leadService.getLeadById(recordId).Id);
            context.put('whatId', null);
        } else if (recordId.getSObjectType() == Contact.SObjectType) {
            ContactService objContactService = ContactService.getInstance();
            Contact contactRec = objContactService.getContactById(recordId);
            context.put('whatId', contactRec.AccountId);
            context.put('whoId', contactRec.Id);
        }
        
        return context;
    }
    
    /**
     * @description Retrieves available appointment slots for a given user on a specific date.
     * @param userId Id of the sales agent/user whose availability is being checked
     * @param selectedDate The date to check for available appointment slots
     * @return List of AppointmentSlot__c records that are marked 'Available' for that user and date
     */
    @AuraEnabled
    public static List<AppointmentSlot__c> getAvailableSlotsTime(Id userId, Date selectedDate) {
        try {
            if (userId == null || selectedDate == null)
                return new List<AppointmentSlot__c>();
            
            return AppointmentSlotService.getInstance().getAppointmentSlotsByUserAndDate(userId, selectedDate, AVAILABLE_STR);
        } catch (Exception e) {
            throw new AuraHandledException('Could not retrieve available appointment slots:' + e.getMessage());
        }
    }
    
}