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
    
    public static void checkValidationAndUpdateHandover(List<Event> newEventList) {
        DocumentService objDocumentService = DocumentService.getInstance();
        Set<Id> handOverIds = new Set<Id>();
        for (Event evt : newEventList) {
            System.debug('evt.WhatId ::::: '+ evt.WhatId);
            if (String.isNotBlank(evt.WhatId)) {
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
                        evt.addError(HandoverConstants.Select_Customer_Availability);
                    }
                    else if(handover.Customer_Availability_for_CHO__c != HandoverConstants.Customer_Available){
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
                    /*else if(handover.Sub_Status__c == HandoverConstants.Handover_Status_Mortgage_Cheque_Clearance){
                        Document__c doc = documentMap.get(handover.Id).get(HandoverConstants.Leasing_ADDC_NOC);
                        if (doc == null || doc.ContentDocumentId__c == null) {
                            evt.addError(VALIDATION_Please_UploadLeasing_ADDC_NOC_KHO);
                        }
                        
                    }*/
                    else if(handover.Sub_Status__c == HandoverConstants.Handover_Sub_Status_Lease_Agreement){
                        //Document__c doc = documentMap.get(handover.Id).get(HandoverConstants.Leasing_ADDC_NOC);
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
            /* Map<String, Object> response = new Map<String, Object>();
            response.put('status', 'success');
            response.put('message', 'Handover Status Updated.'); */

            for (Event evt : newEventList) {
                if (String.isNotBlank(evt.WhatId)) {                    
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
            
          //  List<SendEmailInvocable.EmailRequest> emailRequests = new List<SendEmailInvocable.EmailRequest>();
            
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
                        
                        // Send Appointment Booked Email
                      //  SendEmailInvocable.EmailRequest emailReq = new SendEmailInvocable.EmailRequest();
                      //  emailReq.recordId = handover.Id;
                      //  emailReq.templateName = HandoverConstants.Appointment_Booked_Template;
                     //   emailRequests.add(emailReq);
                        
                    } else if (handover.Orientation_Appointment_Status__c == HandoverConstants.Orientation_Appointment_Status_Cancelled) {
                        // Appointment Status Cancelled - Set to ReScheduled
                        handover.Orientation_Appointment_Status__c = HandoverConstants.Orientation_Appointment_Status_ReScheduled;
                        handoversToUpdate.add(handover);
                        if (String.isNotBlank(handoverPhase.CHOReschedulingappoingmentTempId__c) ) {
                        SendEmailInvocable.sendEmail(handoverPhase.CHOReschedulingappoingmentTempId__c, handover.Id);
                    }
                        
                        // Send Appointment Reschedule Email
                      //  SendEmailInvocable.EmailRequest emailReq = new SendEmailInvocable.EmailRequest();
                     //   emailReq.recordId = handover.Id;
                     //   emailReq.templateName = HandoverConstants.Home_Orientation_Appointment_Rescheduling;
                    //    emailRequests.add(emailReq);
                    }
                } // Decision 2: If Utilities Transfer Completed
                else if(evt.Type == HandoverConstants.KHO_Appointment && handover.RecordTypeId == handoverRecordTypeId && handover.Is_Notice_of_Completion_Sent__c) {
                    
                    // Update Handover Sub Status
                    /* response = HandoverHandler.validateHandoverNextStep(handover, false);
                    if(response.get('status') == 'error'){
                        evt.addError(response.get('message'));
                    }
                    handover.Sub_Status__c = HandoverConstants.Handover_Sub_Status_Handover_Completed;
                    handoversToUpdate.add(handover); */
                    
                    if (String.isNotBlank(handoverPhase.KHOAppointmentConfirmEmailTempId__c)) {
                    SendEmailInvocable.sendEmail(handoverPhase.KHOAppointmentConfirmEmailTempId__c, handover.Id);
                }
                    
                    // Send KHO Appointment Scheduled Email
                   // SendEmailInvocable.EmailRequest emailReq = new SendEmailInvocable.EmailRequest();
                  //  emailReq.recordId = handover.Id;
                  //  emailReq.templateName = HandoverConstants.KHO_Appointment_Scheduled_Template;
                  //  emailRequests.add(emailReq);
                } // Decision 3: If Payment Type PHPP
                else if(evt.Type == HandoverConstants.KHO_Appointment && handover.Sub_Status__c == HandoverConstants.Handover_Sub_Status_Lease_Agreement &&
                        handover.Payment_Type__c == HandoverConstants.Handover_Payment_Type_PHPP && handover.Is_Notice_of_Completion_Sent__c) {
                    
                    // Update Handover Sub Status
                    /* response = HandoverHandler.validateHandoverNextStep(handover, false);
                    if(response.get('status') == 'error'){
                        evt.addError(response.get('message'));
                    }
                    handover.Sub_Status__c = HandoverConstants.Handover_Sub_Status_PHPP_Handover_Keys;
                    handoversToUpdate.add(handover); */
                     if (String.isNotBlank(handoverPhase.KHOAppointmentConfirmEmailTempId__c)) {
                    SendEmailInvocable.sendEmail(handoverPhase.KHOAppointmentConfirmEmailTempId__c, handover.Id);
                }
                    // Send PHPP KHO Appointment Scheduled Email
                  //  SendEmailInvocable.EmailRequest emailReq = new SendEmailInvocable.EmailRequest();
                 //   emailReq.recordId = handover.Id;
                 //   emailReq.templateName = HandoverConstants.KHO_Appointment_Scheduled_Template;
                 //   emailRequests.add(emailReq);
                }
            }
            
            //update handovers
            //objHandoverService.objHandoverService(handoversToUpdate);
            if(!handoversToUpdate.isEmpty()){
                update handoversToUpdate;
            }
            
            // Send emails
           // if (!emailRequests.isEmpty()) {
          //      SendEmailInvocable.sendEmail(emailRequests);
          //  }
            
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
   
}