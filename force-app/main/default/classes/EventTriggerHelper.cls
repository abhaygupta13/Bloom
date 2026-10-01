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

public without sharing class EventTriggerHelper {
    
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
    private static final String APPOINTMENT_SCHEDULED_STR { get { return 'Appointment Scheduled'; } }
    private static final String APPOINTMENT_CANCELLED_STR { get { return 'Appointment Cancelled'; } }
    private static final String APPOINTMENT_RESCHEDULED_STR { get { return 'Appointment Rescheduled'; } }
    private static final String APPOINTMENT_LEAD_SMS_NOTIFICATION { get { return 'Lead Appointment Confirmation SMS'; } }
    private static final String APPOINTMENT_DETAILS_CHANGED_STR { get { return 'Appointment Details Changed'; } }
    private static final string MTD_OWE_NO_REPLY_BLOOM_EMAIL_ID { get { return 'BloomNoReplyOWEmailId'; } }
    private static final String APPOINTMENT_SCHEDULED_EMAIL_TEMPLATE_ID = 'AppointmentScheduledEmailTemplateId';
    private static final String APPOINTMENT_RESCHEDULED_EMAIL_TEMPLATE_ID = 'AppointmentRescheduledEmailTemplateId';
    private static final String APPOINTMENT_CANCELLED_EMAIL_TEMPLATE_ID = 'AppointmentCancelledEmailTemplateId';
    private static final String MTD_Lead_Appointment_Booked_EMAIL_TEMPLATE_ID = 'LeadAppointmentBookedEmailTemplateId';
    private static final String MTD_Lead_Appointment_Cancelled_EMAIL_TEMPLATE_ID = 'LeadAppointmentCancelledEmailTemplateId';
    
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
    
    public static void handleBeforeInsert(List<Event> newEventList) {
        Set<Id> leadIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Map<Id, Lead> leadMap = new Map<Id, Lead>();
        Map<Id, Contact> contactMap = new Map<Id, Contact>();
        Map<Id, Account> accountMap = new Map<Id, Account>();
        Map<Id, User> userMap = new Map<Id, User>();
        Map<Id, String> attendeeEmailMap = new Map<Id, String>();
        Set<Id> appointmentWhoIds = new Set<Id>();
        
        for(Event newEvent : newEventList) {
            if(newEvent.Type == APPOINTMENT_STR && newEvent.AppointmentStatus__c == STATUS_SCHEDULED_STR && newEvent.WhoId != null) {
                appointmentWhoIds.add(newEvent.WhoId);
                if(newEvent.AppointmentMode__c == 'Online' && newEvent.StartDateTime > System.now()) {
                    newEvent.IntegrationStatus__c = 'In Progress';
                }
                if (newEvent.WhoId.getSObjectType() == Lead.SObjectType) {
                    leadIds.add(newEvent.WhoId);
                } else if (newEvent.WhoId.getSObjectType() == Contact.SObjectType) {
                    contactIds.add(newEvent.WhoId);
                } else if (newEvent.WhatId != null && newEvent.WhatId.getSObjectType() == Account.SObjectType) {
                    accountIds.add(newEvent.WhatId);
                }
            }
        }
        if (!leadIds.isEmpty()) {
            leadMap = new Map<Id, Lead>(LeadService.getInstance().getLeadByIds(leadIds));
        }
        
        if (!contactIds.isEmpty()) {
            contactMap = ContactService.getInstance().getContactsByIds(contactIds);
        }
        
        if (!accountIds.isEmpty()) {
           accountMap = new Map<Id, Account>(AccountService.getInstance().getAccountsByIds(accountIds));
        }
        
        Set<Id> existingAppointmentWhoIds = ActivityService.getInstance().getExistingAppointmentWhoIds(appointmentWhoIds);
        for(Event newEvent : newEventList) {
            if(newEvent.WhoId != null && existingAppointmentWhoIds.contains(newEvent.WhoId)) {
                newEvent.addError('An appointment already exists for this customer.'); 
            }
            if(newEvent.WhoId != null && newEvent.WhoId.getSObjectType() == Lead.SObjectType && leadMap != NULL && leadMap.containskey(newEvent.WhoId)){
                newEvent.AttendeeEmail__c = leadMap.get(newEvent.WhoId).Email;
            }
            if(newEvent.WhoId != null && newEvent.WhoId.getSObjectType() == Contact.SObjectType && contactMap != NULL && contactMap.containskey(newEvent.WhoId)){
                newEvent.AttendeeEmail__c = contactMap.get(newEvent.WhoId).Email;
            }
            if (newEvent.WhatId != null && newEvent.WhatId.getSObjectType() == Account.SObjectType && accountMap != null && accountMap.containsKey(newEvent.WhatId) && accountMap.get(newEvent.WhatId).IsPersonAccount) {
                newEvent.AttendeeEmail__c = accountMap.get(newEvent.WhatId).PersonEmail;
            }
        }
    }
    
    public static void handleBeforeUpdate(List<Event> newEventList, Map<Id, Event> oldEventMap) {
        for (Event newEvent : newEventList) {
            Event oldEvent = oldEventMap.get(newEvent.Id);
            
            if (newEvent.Type == APPOINTMENT_STR && newEvent.AppointmentStatus__c == STATUS_CANCELLED_STR
                && newEvent.AppointmentStatus__c != oldEvent.AppointmentStatus__c
                && newEvent.AppointmentMode__c == 'Online' && newEvent.StartDateTime > System.now()
                && newEvent.WhoId != null) {
                    
                    newEvent.IntegrationStatus__c = 'In Progress';
                }
        }
    }
    
    /**
* @description Handles Event after-insert processing for scheduled appointments.
* Updates the related Appointment Slot status to Scheduled and sends the
* scheduled appointment notification for newly created appointment Events.
*
* @param newEventList Newly inserted Event records.
*/
    public static void handleAfterInsert(List<Event> newEventList) {
        List<AppointmentSlot__c> slotsToUpdate = new List<AppointmentSlot__c>();
        List<Event> appointmentEvents = new List<Event>();
        List<Event> onlineAppointmentEvents = new List<Event>();
        
        for(Event newEvent : newEventList){
            
            if(newEvent.Type == APPOINTMENT_STR && newEvent.AppointmentStatus__c == STATUS_SCHEDULED_STR && newEvent.WhoId != null){

                if (newEvent.StartDateTime >= newEvent.EndDateTime) {
                    newEvent.addError('Appointment start time must be earlier than the end time.');
                } else if (newEvent.StartDateTime < System.now()) {
                    newEvent.addError('Appointment start time must be in the future.');
                }else {
                    appointmentEvents.add(newEvent);
                }
          
                if(newEvent.AppointmentSlot__c != null){
                    slotsToUpdate.add( new AppointmentSlot__c(Id = newEvent.AppointmentSlot__c, Status__c = STATUS_SCHEDULED_STR));
                }

                if(newEvent.AppointmentMode__c == 'Online'){
                    onlineAppointmentEvents.add(newEvent);
                }
            }
        }
        AppointmentSlotService.getInstance().updateAppointmentSlots(slotsToUpdate);
        
        if (!appointmentEvents.isEmpty()) {
            sendAppointmentNotification(appointmentEvents, null);
        }
        if (!onlineAppointmentEvents.isEmpty()) {
            createEventIntegrationRecords(appointmentEvents);
        }
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
        List<Event> appointmentEvents = new List<Event>();
        List<Event> onlineCancelledEvents = new List<Event>();
        
        for (Event newEvent : newEventList){
            Event oldEvent = oldEventMap.get(newEvent.Id);
            if(newEvent.Type == APPOINTMENT_STR && newEvent.WhoId != null) {
                if (newEvent.AppointmentSlot__c != null && newEvent.AppointmentStatus__c != oldEvent.AppointmentStatus__c) {
                    slotsToUpdate.add(new AppointmentSlot__c(Id = newEvent.AppointmentSlot__c, Status__c = newEvent.StartDateTime > System.now() ? STATUS_AVAILABLE_STR : newEvent.AppointmentStatus__c));
                }
                Boolean hasAppointmentDetailsChanged = (newEvent.AppointmentStatus__c != oldEvent.AppointmentStatus__c) || (newEvent.OwnerId != oldEvent.OwnerId && newEvent.OwnerId.getSObjectType() == User.SObjectType) 
                    || (newEvent.StartDateTime != oldEvent.StartDateTime) || (newEvent.EndDateTime != oldEvent.EndDateTime);
                
                if(hasAppointmentDetailsChanged){
                    appointmentEvents.add(newEvent);
                }
                if(newEvent.AppointmentMode__c == 'Online' && String.isNotBlank(newEvent.MeetingLink__c) && newEvent.MeetingLink__c != oldEvent.MeetingLink__c){ 
                    appointmentEvents.add(newEvent);
                }
                
                if(newEvent.AppointmentStatus__c == STATUS_CANCELLED_STR && newEvent.AppointmentStatus__c != oldEvent.AppointmentStatus__c && newEvent.AppointmentMode__c == 'Online') {
                    onlineCancelledEvents.add(newEvent);
                }
            }
        }
        AppointmentSlotService.getInstance().updateAppointmentSlots(slotsToUpdate);
        if (!appointmentEvents.isEmpty()) {
            sendAppointmentNotification(appointmentEvents, oldEventMap);
        }
        if(!onlineCancelledEvents.isEmpty()) {
            createEventIntegrationRecords(onlineCancelledEvents);
        }
    }
    
    /**
* @description Sends appointment email and push notifications based on the appointment status and appointment changes. For newly inserted appointments, sends the scheduled notification.
* For updated appointments, handles cancelled, rescheduled, owner changed, and start/end date-time changed scenarios. Retrieves the related Contact or Lead details, prepares the required
* notification values, and sends the applicable email and/or push notification.
*
* @param events Appointment Event records that require notification processing.
* @param oldEventMap Previous versions of the Event records, keyed by Id. This parameter is null for after-insert processing.
*/
    public static void sendAppointmentNotification(List<Event> events, Map<Id, Event> oldEventMap){
        
        Map<Id, Contact> contactMap = new Map<Id, Contact>();
        Map<Id, Lead> leadMap = new Map<Id, Lead>();
        Map<Id, Account> accountMap = new Map<Id, Account>();
        Set<Id> contactIds = new Set<Id>();
        Set<Id> leadIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        
        EmailService objEmailService = EmailService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        Id leadAppointmentBookedEmailTemplateId = objMetadataService.getAppSettingTextValue(MTD_Lead_Appointment_Booked_EMAIL_TEMPLATE_ID);
        Id leadAppointmentCancelledEmailTemplateId = objMetadataService.getAppSettingTextValue(MTD_Lead_Appointment_Cancelled_EMAIL_TEMPLATE_ID);
        EmailTemplate appointmentScheduledTemplate = objEmailService.getEmailTemplateById(objMetadataService.getAppSettingTextValue(APPOINTMENT_SCHEDULED_EMAIL_TEMPLATE_ID));
        EmailTemplate appointmentCancelledTemplate = objEmailService.getEmailTemplateById(objMetadataService.getAppSettingTextValue(APPOINTMENT_CANCELLED_EMAIL_TEMPLATE_ID));
        EmailTemplate appointmentRescheduledTemplate = objEmailService.getEmailTemplateById(objMetadataService.getAppSettingTextValue(APPOINTMENT_RESCHEDULED_EMAIL_TEMPLATE_ID));
        
        Id noReplyBloomOWDId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_EMAIL_ID);
        
        Set<String> notificationTypes = new Set<String>{APPOINTMENT_SCHEDULED_STR, APPOINTMENT_CANCELLED_STR, APPOINTMENT_RESCHEDULED_STR, APPOINTMENT_DETAILS_CHANGED_STR};
            
        NotificationService objNotificationService = NotificationService.getInstance();
        Map<String, SMSTemplate__c> smsTemplateMap = objNotificationService.getSMSTemplates(new Set<String>{APPOINTMENT_LEAD_SMS_NOTIFICATION});
        Map<String, PushNotificationTemplate__c> templateMap = NotificationService.getInstance().getPushNotificationTemplates(notificationTypes);
        
        for (Event objEvent : events) {
            if (objEvent.WhoId.getSObjectType() == Contact.SObjectType) {
                contactIds.add(objEvent.WhoId);
            }else if (objEvent.WhoId.getSObjectType() == Lead.SObjectType) {
                leadIds.add(objEvent.WhoId);
            }
            
            if(objEvent.OwnerId.getSObjectType() == User.SObjectType) {
               userIds.add(objEvent.OwnerId); 
            }
        }
        if (!contactIds.isEmpty()) {
            contactMap = ContactService.getInstance().getContactsByIds(contactIds);
        }
        if (!leadIds.isEmpty()) {
            leadMap = LeadService.getInstance().getLeadsByIds(leadIds);
        }
        
        Map<Id, User> userMap = UserService.getInstance().getActiveUsersByIds(userIds);
        EmailTemplate emailTemplate = null;
        PushNotificationTemplate__c notificationTemplate = null;    
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        List<PushNotification__c> pushNotificationRecords = new List<PushNotification__c>();
        List<IntegrationRecord__c> integrationRecords = new List<IntegrationRecord__c>();
        String customerName = '';
        String customerNameArabic = '';
        for(Event newEvent : events) {
            Messaging.SingleEmailMessage internalEmail;
            Event oldEvent = oldEventMap != null ? oldEventMap.get(newEvent.Id) : null;
            if (oldEvent == null && newEvent.AppointmentStatus__c == STATUS_SCHEDULED_STR) {
                emailTemplate = appointmentScheduledTemplate;
                notificationTemplate =  templateMap.get(APPOINTMENT_SCHEDULED_STR);
            }else if(oldEvent != null && newEvent.AppointmentStatus__c == STATUS_CANCELLED_STR && newEvent.AppointmentStatus__c != oldEvent.AppointmentStatus__c){
                emailTemplate = appointmentCancelledTemplate;
                notificationTemplate =  templateMap.get(APPOINTMENT_CANCELLED_STR);
            }else if(oldEvent != null && newEvent.AppointmentStatus__c == STATUS_RESCHEDULED_STR && newEvent.AppointmentStatus__c != oldEvent.AppointmentStatus__c){
                emailTemplate = appointmentRescheduledTemplate;
                notificationTemplate =  templateMap.get(APPOINTMENT_RESCHEDULED_STR);
            }else if(oldEvent != null && (newEvent.OwnerId != oldEvent.OwnerId || newEvent.StartDateTime != oldEvent.StartDateTime || newEvent.EndDateTime != oldEvent.EndDateTime)) {
                notificationTemplate =  templateMap.get(APPOINTMENT_DETAILS_CHANGED_STR);
            }
            else if(String.isNotBlank(newEvent.MeetingLink__c) && newEvent.MeetingLink__c != oldEvent.MeetingLink__c){
                emailTemplate = appointmentScheduledTemplate;
            }

            if (newEvent.WhoId.getSObjectType() == Contact.SObjectType) {
                
                Contact contactRec = contactMap.get(newEvent.WhoId);
                if (notificationTemplate != null) {
                    pushNotificationRecords.add(sendMobileAppPushNotification(newEvent, notificationTemplate, contactRec, userMap));
                }
                customerName = String.isBlank(contactRec.Name) ? '' : contactRec.Name;
                customerNameArabic = String.isBlank(contactRec.Account.NameinArabic__c) ? contactRec.Name : contactRec.Account.NameinArabic__c;
                
            } else if (newEvent.WhoId.getSObjectType() == Lead.SObjectType) {
                Lead leadRec = leadMap.get(newEvent.WhoId);
                if (notificationTemplate != null) {
                    pushNotificationRecords.add(sendMobileAppPushNotification(newEvent, notificationTemplate, leadRec, userMap));
                }
                if (newEvent.AppointmentStatus__c == STATUS_SCHEDULED_STR && oldEvent == null) { 
                    
                        List<String> notificationValues = new List<String>();
                        notificationValues.add(newEvent.StartDateTime != null ? newEvent.StartDateTime.format('EEEE, dd/MMM') : '');
                        notificationValues.add(newEvent.StartDateTime != null ? newEvent.StartDateTime.format('hh:mm a') : '');
                        integrationRecords.add(objNotificationService.getSMSIntegrationRecord(leadRec, smsTemplateMap.get(APPOINTMENT_LEAD_SMS_NOTIFICATION), notificationValues));
                        
                    if(leadRec.LeadSource == 'Government Entity' && leadRec.leadsubsource__c == 'ADHA' && leadRec.ApplicationNumber__c != null){
                        internalEmail = Messaging.renderStoredEmailTemplate(leadAppointmentBookedEmailTemplateId, leadRec.Id, null);
                        internalEmail.setTreatTargetObjectAsRecipient(false);
                        internalEmail.setSaveAsActivity(true);
                        internalEmail.setOrgWideEmailAddressId(noReplyBloomOWDId);
                        internalEmail.setToAddresses(new List<String>{ leadRec.Owner.Email });
                        internalEmail.htmlBody = internalEmail.htmlBody.replace('{LeadOwner}', leadRec.Owner.Name);
                        internalEmail.htmlBody = internalEmail.htmlBody.replace('{Date}', newEvent.StartDateTime != null ? newEvent.StartDateTime.format('EEEE, dd/MMMM') : '');
                        internalEmail.htmlBody = internalEmail.htmlBody.replace('{Time}', newEvent.StartDateTime != null ? newEvent.StartDateTime.format('hh:mm a') : '');
                        emailList.add(internalEmail);
                    }
                }
                if (newEvent.AppointmentStatus__c == STATUS_CANCELLED_STR) { 
                    if(leadRec.LeadSource == 'Government Entity' && leadRec.leadsubsource__c == 'ADHA' && leadRec.ApplicationNumber__c != null){
                        internalEmail = Messaging.renderStoredEmailTemplate(leadAppointmentCancelledEmailTemplateId, leadRec.Id, null);
                        internalEmail.setTreatTargetObjectAsRecipient(false);
                        internalEmail.setSaveAsActivity(true);
                        internalEmail.setOrgWideEmailAddressId(noReplyBloomOWDId);
                        internalEmail.setToAddresses(new List<String>{ leadRec.Owner.Email });
                        internalEmail.htmlBody = internalEmail.htmlBody.replace('{LeadOwner}', leadRec.Owner.Name);
                        internalEmail.htmlBody = internalEmail.htmlBody.replace('{Date}', newEvent.StartDateTime != null ? newEvent.StartDateTime.format('EEEE, dd/MMMM') : '');
                        internalEmail.htmlBody = internalEmail.htmlBody.replace('{Time}', newEvent.StartDateTime != null ? newEvent.StartDateTime.format('hh:mm a') : '');
                        emailList.add(internalEmail);
                        
                    }
                }
                
                customerName = String.isBlank(leadRec.Name) ? '' : leadRec.Name;
                customerNameArabic = String.isBlank(leadRec.NameArabic__c) ? leadRec.Name : leadRec.NameArabic__c;
                if(newEvent.AppointmentMode__c == 'Online' && String.isBlank(newEvent.MeetingLink__c)) {
                    continue;
                }
            }
            
            if(emailTemplate != null) {
                System.debug('emailTemplate'+emailTemplate);
                User accountManager = userMap.get(newEvent.OwnerId);
                emailList.add(ActivityService.getInstance().createAppointmentNotificationEmail(emailTemplate, newEvent, customerName, customerNameArabic, noReplyBloomOWDId, accountManager));
            }
            
        }
        objEmailService.sendEmail(emailList);
        PushNotificationService.getInstance().insertPushNotifications(pushNotificationRecords);
        IntegrationRecordService.getInstance().insertIntegrationRecords(integrationRecords);
    }
    
    /**
* Creates a push notification record for an appointment based on the specified notification type and populates the notification values with the relevant
* appointment date, time, and location.
*
* @param objEvent     Event record containing the appointment details.
* @param notificationTemplate Push notification template.
* @param objectType  Type of object associated with the appointment.
* @param userMap  Map of User records keyed by User Id, used to retrieve the assigned user name.
* @return   PushNotification__c record containing the notification details.
*/
    private static PushNotification__c sendMobileAppPushNotification(Event objEvent, PushNotificationTemplate__c notificationTemplate, sObject objectType, Map<Id, User> userMap) {
        List<String> notificationValues = new List<String>();
        
        String appointmentDate = objEvent.StartDateTime != null ? objEvent.StartDateTime.format('yyyy-MMM-dd') : '';
        String appointmentTime = (objEvent.StartDateTime != null && objEvent.EndDateTime != null) ? objEvent.StartDateTime.format('h:mm a') : '';
        String agentName = userMap.get(objEvent.OwnerId).Name;
        
        if (notificationTemplate.Name == APPOINTMENT_SCHEDULED_STR) {
            notificationValues.add(appointmentDate);
            notificationValues.add(appointmentTime);
            notificationValues.add(agentName);
        } else if (notificationTemplate.Name == APPOINTMENT_CANCELLED_STR) {
            notificationValues.add(appointmentDate);
            notificationValues.add(appointmentTime);
        } else if (notificationTemplate.Name == APPOINTMENT_RESCHEDULED_STR) {
            notificationValues.add(appointmentDate);
            notificationValues.add(appointmentTime);
            notificationValues.add(agentName);
        } else if (notificationTemplate.Name == APPOINTMENT_DETAILS_CHANGED_STR) {
            notificationValues.add(agentName);
            notificationValues.add(appointmentDate);
            notificationValues.add(appointmentTime);
        }
        
        return PushNotificationService.getInstance().getPushNotificationRecord(objectType, notificationTemplate, notificationValues);
    }
    
    /**
* @description Creates integration records for the provided Event records.
*
* The method collects the Event owner IDs, retrieves the corresponding active User records, prepares an integration record for each Event
* using ActivityService, and inserts all generated integration records in a single bulk operation.
*
* @param events List of Event records for which integration records need to be created.
*/
    public static void createEventIntegrationRecords(List<Event> events) {
        List<IntegrationRecord__c> integrationRecordsToInsert = new List<IntegrationRecord__c>();
        Set<Id> userIds = new Set<Id>();
        Map<Id, User> userMap = new Map<Id, User>();
        
        for (Event objEvent : events) {
            userIds.add(objEvent.OwnerId);
        }
        
        if (!userIds.isEmpty()) {
            userMap = UserService.getInstance().getActiveUsersByIds(userIds);
        }
        
        for (Event objEvent : events) {
            String emailId = objEvent.OwnerId != null ? userMap.get(objEvent.OwnerId).Email : null;
            String timeZone = objEvent.OwnerId != null ? userMap.get(objEvent.OwnerId).TimeZoneSidKey : null;
            
            integrationRecordsToInsert.add(ActivityService.getInstance().getEventIntegrationRecord(objEvent, emailId, timeZone));
        }
        
        if (!integrationRecordsToInsert.isEmpty()) 
        {
            IntegrationRecordService.getInstance().insertIntegrationRecords(integrationRecordsToInsert);
        }
    }
}