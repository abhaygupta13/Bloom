/***
Class       : EventTriggerHelper
Author      : Rajat Rastogi
Description : Bulkifies the code to handle multiple Event records in a single transaction.
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.      V1.0             	 11/06/2024           Initial Version  
****************************************************************************************************************/ 

public class EventTriggerHelper {
     
    private static final String VALIDATION_Please_UploadLeasing_ADDC_NOC_KHO = 'Please Upload Leasing ADDC NOC before Scheduling KHO Appointment';
    private static final String VALIDATION_Please_UploadLeasing_ADDC_NOC_PHPP = 'Please Upload Leasing ADDC NOC before Scheduling KHO Appointment';
    private static final string ABSENCE_RT_DEV_NAME_Non_Availability { get { return 'Non_Availability'; } }
    private static final string Select_Customer_Availability = 'Please select Customer Availability for CHO on the related Handover';
    private static final string Cannot_Book_Appointment = 'You cannot book an appointment if customer is not available. Please update Customer Availability for CHO if customer is available.';
    private static final string Delete_Existing_Appointment = 'To reschedule new orientation appointment, please set orientation appointment status as Cancelled';
    private static final string Customer_Available = 'Customer Available';
    private static final string Customer_Not_Available = 'Customer Not available';
    private static final string Customer_Deligate_To_Bloom	 = 'Customer Delegate To Bloom';
    private static final string Orientation_Appointment_Status_Cancelled = 'Cancelled';
    private static final string Orientation_Appointment_Status_Scheduled = 'Scheduled';
    private static final string Orientation_Appointment_Status_ReScheduled = 'ReScheduled';
    private static final string SO_STATUS_CANCELLED = 'Cancelled';
    private static final string HO_CHO_Snagging_Report = 'CHO Snagging Report';
    private static final string HO_CHO_DeSnagging_Report = 'CHO Desnagging Report';
    private static final string Orientation_Appointment = 'Home Orientation Appointment';
    private static final string KHO_Appointment = 'KHO Appointment';
    private static final string Signing_Document_Appointment = 'Signing Document Appointment';
    private static final string Handover_Sub_Status_Lease_Agreement = 'Lease Agreement';
    private static final string Leasing_ADDC_NOC = 'Leasing ADDC NOC';
    private static final string Handover_Payment_Type_PHPP = 'PHPP';
    private static final String STATUS_SCHEDULED_STR { get { return 'Scheduled'; } }
    private static final String STATUS_CANCELLED_STR { get { return 'Cancelled'; } }
    private static final String STATUS_RESCHEDULED_STR { get { return 'Rescheduled'; } }
    private static final String STATUS_AVAILABLE_STR { get { return 'Available'; } }
    private static final string APPOINTMENT_STR { get { return 'Appointment'; } }
    private static final string MTD_OWE_NO_REPLY_BLOOM_EMAIL_ID { get { return 'BloomNoReplyOWEmailId'; } }
    private static final String APPOINTMENT_SCHEDULED_EMAIL_TEMPLATE_ID = 'AppointmentScheduledEmailTemplateId';
    private static final String APPOINTMENT_RESCHEDULED_EMAIL_TEMPLATE_ID = 'AppointmentRescheduledEmailTemplateId';
    private static final String APPOINTMENT_CANCELLED_EMAIL_TEMPLATE_ID = 'AppointmentCancelledEmailTemplateId';
    
    
    public static void checkValidationAndUpdateHandover(List<Event> newEventList) {
        DocumentService objDocumentService = DocumentService.getInstance();
        Set<Id> handOverIds = new Set<Id>();
        for (Event evt : newEventList) {
            if (evt.Type != APPOINTMENT_STR && String.isNotBlank(evt.WhatId)) {
                if (evt.WhatId.getSObjectType() == Handover__c.SobjectType) {
                    handOverIds.add(evt.WhatId);
                }
            }
        }
        
        if (!handOverIds.isEmpty()) {
            Map<Id, List<Event>> existingEventsMap = new Map<Id, List<Event>>();
            for (Event evt : [SELECT Id, WhatId FROM Event WHERE WhatId IN :handOverIds]) {
                if (!existingEventsMap.containsKey(evt.WhatId)) {
                    existingEventsMap.put(evt.WhatId, new List<Event>());
                }
                existingEventsMap.get(evt.WhatId).add(evt);
            }
            
            Map<Id,List<String>> documentMap = new Map<Id,List<String>>();
            List<Document__c> handoverDocumentList = objDocumentService.getDocumentsOnHandoversWithAttachments(handoverIds);
            for (Document__c doc : handoverDocumentList) {
                if (!documentMap.containsKey(doc.Handover__c)) {
                    documentMap.put(doc.Handover__c, new List<String>());
                }
                documentMap.get(doc.Handover__c).add(doc.Document_Name__c);
            }
            
            
            Map<Id, Handover__c> handoverMap = new Map<Id, Handover__c>([SELECT Id, Name,Sub_Status__c, Customer_Availability_for_CHO__c, Orientation_Appointment_Status__c, Is_Notice_of_Completion_Sent__c 
                                                                         FROM Handover__c WHERE Id IN :handOverIds]);
            
            for (Event evt : newEventList) {
                Handover__c handover = handoverMap.get(evt.WhatId);
                List<Event> existingEvents = existingEventsMap.get(evt.WhatId);
                Integer existingEvent = (existingEvents == null) ? 0 : existingEvents.size();
                if (handover != null) {
                    if (String.isBlank(handover.Customer_Availability_for_CHO__c)) {
                        evt.addError(Select_Customer_Availability);
                    }
                    else if(handover.Customer_Availability_for_CHO__c !=Customer_Available){
                        evt.addError(HandoverConstants.Cannot_Book_Appointment);
                    }
                    else if(evt.Type == 'Home Orientation Appointment' && (handover.Orientation_Appointment_Status__c == HandoverConstants.Orientation_Appointment_Status_Scheduled ||
                                handover.Orientation_Appointment_Status__c == HandoverConstants.Orientation_Appointment_Status_ReScheduled) &&
                               existingEvent > 0) {
                        evt.addError(HandoverConstants.Delete_Existing_Appointment);
                    }
                    else if(evt.Type == 'KHO Appointment' && (!documentMap.get(evt.WhatId).contains(HandoverConstants.HO_CHO_Snagging_Report) || !documentMap.get(evt.WhatId).contains(HandoverConstants.HO_CHO_DeSnagging_Report))) {
                        evt.addError('Please upload CHO Snagging/DeSangging Reports.');
                    }
                    else if(handover.Sub_Status__c == HandoverConstants.Handover_Sub_Status_Lease_Agreement){
                        if (!documentMap.get(evt.WhatId).contains(HandoverConstants.Leasing_ADDC_NOC)) {
                            evt.addError(VALIDATION_Please_UploadLeasing_ADDC_NOC_PHPP);
                        }
                        
                    }
                    //!existingEvents.isEmpty()
                }
            }
        }
    }
    
    /**
     * @description Handles event notification logic to customers when Events are created
     * Converted from Flow: Event_Notification_to_Customer
     * @param newEventList List of newly created Event records
     */
    public static void handleEventNotificationToCustomer(List<Event> newEventList) {
        try {
            // Collect Event records related to Handover
            Set<Id> handoverIds = new Set<Id>();
            Map<Id, Event> handoverIdToEventMap = new Map<Id, Event>();
            HandoverService objHandoverService = HandoverService.getInstance();
            HandoverPhaseService objHandoverPhaseService = HandoverPhaseService.getInstance();

            
            for (Event evt : newEventList) {
                if (evt.Type != APPOINTMENT_STR && String.isNotBlank(evt.WhatId)) {
                    if(evt.WhatId.getSObjectType() == Handover__c.SobjectType) {
                        handoverIds.add(evt.WhatId);
                        handoverIdToEventMap.put(evt.WhatId, evt);
                    }
                }
            }
            
            if (handoverIds.isEmpty()) {
                return;
            }
            Map<Id, Handover__c> handoverMap = new Map<Id, Handover__c>(objHandoverService.getHandoverByIds(handoverIds));
            Set<Id> phaseIds = new Set<Id>();
            for (Handover__c ho : handoverMap.values()) {
                if (ho.Handover_Phase__c != null) {
                    phaseIds.add(ho.Handover_Phase__c);
                }
            }
            
            // Get Handover Record Type for comparison
            Id handoverRecordTypeId = Utility.getRecordTypeIdByDevName(Handover__c.SObjectType, 'Handover');
            Map<Id, HandoverPhase__c> phaseMap = new Map<Id, HandoverPhase__c>();
            if (!phaseIds.isEmpty()) {
                phaseMap = new Map<Id, HandoverPhase__c>(objHandoverPhaseService.getHandoverPhaseInfo(phaseIds));
            }
            
            // Lists for DML operations
            List<Handover__c> handoversToUpdate = new List<Handover__c>();
            
          
            
            for (Id handoverId : handoverIds) {
                Event evt = handoverIdToEventMap.get(handoverId);
                Handover__c handover = handoverMap.get(handoverId);
                
                if (handover == null) {
                    continue;
                }
                HandoverPhase__c handoverPhase = phaseMap.get(handover.Handover_Phase__c);
                if (handoverPhase == null) {
                    continue;
                }
                
                // Decision 1: If Appointment Booked with Customer
                if (evt.Type == HandoverConstants.Orientation_Appointment && handover.Customer_Availability_for_CHO__c == HandoverConstants.Customer_Available) {
                    
                    handover.Sub_Status__c = HandoverConstants.Handover_Sub_Status_Settlement_Follow_up;
                    handover.Is_Appointment_Booked__c = true;
                    
                    // Check Orientation Appointment Status
                    if (String.isBlank(handover.Orientation_Appointment_Status__c)) {
                        // Appointment Status Blank - Set to Scheduled
                        handover.Orientation_Appointment_Status__c = HandoverConstants.Orientation_Appointment_Status_Scheduled;
                        handoversToUpdate.add(handover);
                        if (String.isNotBlank(handoverPhase.CHOAppointmentConfirmEmailTempId__c)) {
                            SendEmailInvocable.sendEmail(handoverPhase.CHOAppointmentConfirmEmailTempId__c, handover.Id);
                        }
                        
                    } else if (handover.Orientation_Appointment_Status__c == HandoverConstants.Orientation_Appointment_Status_Cancelled) {
                        // Appointment Status Cancelled - Set to ReScheduled
                        handover.Orientation_Appointment_Status__c = HandoverConstants.Orientation_Appointment_Status_ReScheduled;
                        handoversToUpdate.add(handover);
                        if (String.isNotBlank(handoverPhase.CHOReschedulingappoingmentTempId__c) ) {
                            SendEmailInvocable.sendEmail(handoverPhase.CHOReschedulingappoingmentTempId__c, handover.Id);
                        }
                        
                    }
                    
                } // Decision 2: If Utilities Transfer Completed
                else if(evt.Type == Signing_Document_Appointment) { 
                    if (String.isNotBlank(handoverPhase.AppointmentConfirmSignEmailTempId__c)) {
                        SendEmailInvocable.sendEmail(handoverPhase.AppointmentConfirmSignEmailTempId__c, handover.Id);
                    }
                    
                }
                
                else if(evt.Type == KHO_Appointment && handover.RecordTypeId == handoverRecordTypeId && handover.Is_Notice_of_Completion_Sent__c) { 
                    if (String.isNotBlank(handoverPhase.KHOAppointmentConfirmEmailTempId__c)) {
                        SendEmailInvocable.sendEmail(handoverPhase.KHOAppointmentConfirmEmailTempId__c, handover.Id);
                    }
                    
                }
                
                
                // Decision 3: If Payment Type PHPP
                else if(evt.Type == KHO_Appointment && handover.Sub_Status__c ==Handover_Sub_Status_Lease_Agreement &&
                        handover.Payment_Type__c == Handover_Payment_Type_PHPP && handover.Is_Notice_of_Completion_Sent__c) {
                           
                            if (String.isNotBlank(handoverPhase.KHOAppointmentConfirmEmailTempId__c)) {
                                SendEmailInvocable.sendEmail(handoverPhase.KHOAppointmentConfirmEmailTempId__c, handover.Id);
                            }
                            
                        }
            }
            
            
            if(!handoversToUpdate.isEmpty()){
                update handoversToUpdate;
            }
           
            
        } catch (Exception ex) {
            ErrorLogHandler.logError('EventTriggerHelper', 'handleEventNotificationToCustomer', ex, '');
        }
    }

    public static void createServiceResourceAbsence(List<Event> newEventList) {
       Id NonAvailabilityRecTypeId = Utility.getRecordTypeIdByDevName(ResourceAbsence.SObjectType, ABSENCE_RT_DEV_NAME_Non_Availability);

        List<ResourceAbsence> absencesToInsert = new List<ResourceAbsence>();
        Set<Id> handOverIds = new Set<Id>();

        // Step 1: Collect relevant Event records
        for (Event evt : newEventList) {
            System.debug('newEventList'+newEventList);
            if (evt.Type == 'Home Orientation Appointment' && evt.WhatId != null) {
                String sObjectName = String.valueOf(evt.WhatId.getSObjectType());
                if (sObjectName.equalsIgnoreCase(Constants.HANDOVER_SOBJECT)) {
                    handOverIds.add(evt.WhatId);
                }
            }
        }

        if (!handOverIds.isEmpty()) {
            // Step 2: Query Handover records with HO_Agent_Assigned_User__c
            Map<Id, Id> handoverToUserMap = new Map<Id, Id>();
            for (Handover__c ho : [
                SELECT Id, HO_Agent_Assigned_User__c
                FROM Handover__c
                WHERE Id IN :handOverIds
            ]) {
                if (ho.HO_Agent_Assigned_User__c != null) {
                    handoverToUserMap.put(ho.Id, ho.HO_Agent_Assigned_User__c);
                    
                }
            }

            // Step 3: Query ServiceResource linked to HO_Agent_Assigned_User__c
            Set<Id> userIds = new Set<Id>(handoverToUserMap.values());
            Map<Id, Id> userToServiceResourceMap = new Map<Id, Id>();
            for (ServiceResource sr : [
                SELECT Id, RelatedRecordId FROM ServiceResource WHERE RelatedRecordId IN :userIds
            ]) {
                userToServiceResourceMap.put(sr.RelatedRecordId, sr.Id);
                System.debug('userToServiceResourceMap'+userToServiceResourceMap);
            }

            // Step 4: Create ResourceAbsence records
            for (Event evt : newEventList) {
                if (evt.Type == 'Home Orientation Appointment' && evt.WhatId != null) {
                    Id hoId = evt.WhatId;
                    Id userId = handoverToUserMap.get(hoId);
                    Id srId = userToServiceResourceMap.get(userId);

                    if (srId != null && evt.StartDateTime != null && evt.EndDateTime != null) {
                        ResourceAbsence abs = new ResourceAbsence();
                        abs.ResourceId  = srId;
                        abs.Related_Event_ID__c = evt.Id;
                        abs.RecordTypeId = NonAvailabilityRecTypeId;
                        abs.Start = evt.StartDateTime;
                        abs.End = evt.EndDateTime;
                        abs.Type = 'Meeting'; 
                        abs.Description = 'Home Orientation Appointment';

                        absencesToInsert.add(abs);
                        system.debug('absencesToInsert'+absencesToInsert);
                    }
                }
            }

            // Step 5: Insert ResourceAbsence records
            if (!absencesToInsert.isEmpty()) {
                System.debug('absencesToInsert'+absencesToInsert.size());
                insert absencesToInsert;
            }
        }
    }

    public static void updateServiceResourceAbsenceOnEventChange(List<Event> newEventList, Map<Id, Event> oldEventMap) {
        List<ResourceAbsence> absencesToUpdate = new List<ResourceAbsence>();
        Set<Id> changedEventIds = new Set<Id>();
        // Step 1: Identify events where StartDateTime or EndDateTime changed
        for (Event evt : newEventList) {
            Event oldEvt = oldEventMap.get(evt.Id);

            if (evt.Type == 'Home Orientation Appointment'
                && evt.WhatId != null
                && oldEvt != null
                && (evt.StartDateTime != oldEvt.StartDateTime || evt.EndDateTime != oldEvt.EndDateTime)) {
                    
                changedEventIds.add(evt.Id);
            }
        }

        if (!changedEventIds.isEmpty()) {
            // Step 2: Query related ResourceAbsence records
            Map<Id, ResourceAbsence> eventToAbsenceMap = new Map<Id, ResourceAbsence>();
            for (ResourceAbsence abs : [
                SELECT Id, Start, End, Related_Event_ID__c
                FROM ResourceAbsence
                WHERE Related_Event_ID__c IN :changedEventIds
            ]) {
                eventToAbsenceMap.put(abs.Related_Event_ID__c, abs);
            }

            // Step 3: Update absences where event time changed
            for (Event evt : newEventList) {
                if (changedEventIds.contains(evt.Id)) {
                    ResourceAbsence abs = eventToAbsenceMap.get(evt.Id);
                    if (abs != null) {
                        abs.Start = evt.StartDateTime;
                        abs.End = evt.EndDateTime;
                        absencesToUpdate.add(abs);
                    }
                }
            }

            // Step 4: Perform update
            if (!absencesToUpdate.isEmpty()) {
                update absencesToUpdate;
            }
        }
    }

    public static void deleteServiceResourceAbsenceOnEventDelete(List<Event> deletedEventList) {
        // Collect IDs of Events that were deleted and are of the relevant type
        Set<Id> deletedHomeOrientationEventIds = new Set<Id>();

        for (Event evt : deletedEventList) {
            if (evt.Type == 'Home Orientation Appointment' && evt.WhatId != null) {
                deletedHomeOrientationEventIds.add(evt.Id);
            }
        }

        if (!deletedHomeOrientationEventIds.isEmpty()) {
            // Query related ResourceAbsence records for deletion
            List<ResourceAbsence> absencesToDelete = [
                SELECT Id
                FROM ResourceAbsence
                WHERE Related_Event_ID__c IN :deletedHomeOrientationEventIds
            ];

            if (!absencesToDelete.isEmpty()) {
                delete absencesToDelete;
            }
        }
    }
    
    /**
     * @description - Common entry point for Event after-insert processing.
     * Events are evaluated once and routed to the appropriate
     * feature-specific handler.
     *
     * @param newEventList Newly inserted Event records.
     */
    public static void handleAfterInsert(List<Event> newEventList){
        List<AppointmentSlot__c> slotsToUpdate = new List<AppointmentSlot__c>();
        List<Event> appointmentEvents = new List<Event>();
        Set<Id> usersIds = new Set<Id>();
        
        for(Event event : newEventList){

            if(event.Type == APPOINTMENT_STR && event.AppointmentSlot__c != null && event.AppointmentStatus__c == STATUS_SCHEDULED_STR){
                slotsToUpdate.add( new AppointmentSlot__c(Id = event.AppointmentSlot__c, Status__c = STATUS_SCHEDULED_STR));
            }
            
            if(event.Type == APPOINTMENT_STR && event.AppointmentStatus__c == STATUS_SCHEDULED_STR){
                usersIds.add(event.OwnerId);
                appointmentEvents.add(event);
            }
        }
        AppointmentSlotService.getInstance().updateAppointmentSlots(slotsToUpdate);
        
        if (!appointmentEvents.isEmpty())
            sendAppointmentStatusNotificationEmail(appointmentEvents, usersIds);
        
        
    }
    
    /**
     * @description - Handles appointment status changes.
     * When an appointment is cancelled or rescheduled, the related
     *  slot is updated based on whether the appointment is in the future or has already started/passed.
     *
     *  Future cancelled or rescheduled appointments make the slot available. Past or current appointments are marked according to their new status.
     *
     * @param newEventList Updated appointments.
     * @param oldEventMap Previous versions of the appointments, keyed by Id.
     */
    public static void handleAfterUpdate(List<Event> newEventList, Map<Id, Event> oldEventMap) {
        List<AppointmentSlot__c> slotsToUpdate = new List<AppointmentSlot__c>();
        Set<Id> userIds = new Set<Id>();
        List<Event> appointmentEvents = new List<Event>();
        
        for (Event newEvent : newEventList){
            Boolean validAppointmentStatus = newEvent.AppointmentStatus__c == STATUS_RESCHEDULED_STR || newEvent.AppointmentStatus__c == STATUS_CANCELLED_STR;
            if (newEvent.Type == APPOINTMENT_STR && newEvent.AppointmentSlot__c != null && newEvent.AppointmentStatus__c != oldEventMap.get(newEvent.Id).AppointmentStatus__c) {
                slotsToUpdate.add(new AppointmentSlot__c(Id = newEvent.AppointmentSlot__c, Status__c = newEvent.StartDateTime > System.now() ? STATUS_AVAILABLE_STR : newEvent.AppointmentStatus__c));
            }
            
            if(newEvent.Type == APPOINTMENT_STR && newEvent.AppointmentStatus__c != oldEventMap.get(newEvent.Id).AppointmentStatus__c && validAppointmentStatus){
                appointmentEvents.add(newEvent);
                userIds.add(newEvent.OwnerId);
            }
        }
        AppointmentSlotService.getInstance().updateAppointmentSlots(slotsToUpdate);
        if (!appointmentEvents.isEmpty())
            sendAppointmentStatusNotificationEmail(appointmentEvents, userIds);
    }
    
    /**
     * @description - Sends an email notification to the customer based on the appointment status. Determines whether the appointment is scheduled,
     * cancelled, or rescheduled, retrieves the customer details from the related Contact or Lead, renders the corresponding email template,
     * replaces appointment and customer information in the email body, and sends the notification to the customer.
     *
     * @param events  Updated appointment events for which notifications should be sent.
     * @param userIds IDs of the appointment owners used to retrieve account manager details.
     */
    public static void sendAppointmentStatusNotificationEmail(List<Event> events, Set<Id> userIds){
        
        Map<String, String> templateFieldValues = new Map<String, String>();
        Map<Id, Contact> contactMap = new Map<Id, Contact>();
        Map<Id, Lead> leadMap = new Map<Id, Lead>();
        Map<Id, Account> accountMap = new Map<Id, Account>();
        Set<Id> contactIds = new Set<Id>();
        Set<Id> leadIds = new Set<Id>();
        
        EmailService objEmailService = EmailService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        Map<Id, User> userMap = UserService.getInstance().getActiveUsersByIds(userIds);
        
        EmailTemplate appointmentScheduledTemplate = objEmailService.getEmailTemplateById(objMetadataService.getAppSettingTextValue(APPOINTMENT_SCHEDULED_EMAIL_TEMPLATE_ID));
        EmailTemplate appointmentCancelledTemplate = objEmailService.getEmailTemplateById(objMetadataService.getAppSettingTextValue(APPOINTMENT_CANCELLED_EMAIL_TEMPLATE_ID));
        EmailTemplate appointmentRescheduledTemplate = objEmailService.getEmailTemplateById(objMetadataService.getAppSettingTextValue(APPOINTMENT_RESCHEDULED_EMAIL_TEMPLATE_ID));
        Id noReplyBloomOWDId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_EMAIL_ID);
        templateFieldValues.put('NoReplyBloomEmail', noReplyBloomOWDId);

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
        
        EmailTemplate emailTemplate = null;
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        
        for(Event eventRec : events) {
            if (eventRec.Type == APPOINTMENT_STR) {
                if (eventRec.AppointmentStatus__c == STATUS_SCHEDULED_STR) {
                emailTemplate = appointmentScheduledTemplate;
            }else if(eventRec.AppointmentStatus__c == STATUS_CANCELLED_STR){
                emailTemplate = appointmentCancelledTemplate;
            }else if(eventRec.AppointmentStatus__c == STATUS_RESCHEDULED_STR){
                emailTemplate = appointmentRescheduledTemplate;
            }
            
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
    }
        objEmailService.sendEmail(emailList);
    }
}