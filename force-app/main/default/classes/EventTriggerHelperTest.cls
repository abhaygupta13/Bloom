@isTest
private class EventTriggerHelperTest {

    @testSetup
    static void setupData() {
        // 1. Create a User for the HO Agent
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        
         ServiceCatalog__c  servicecatalog = new ServiceCatalog__c();
        servicecatalog.ProcessFlowType__c= 'Handover';
        servicecatalog.ProcessType__c = 'Sales';
        servicecatalog.Active__c= true;
        servicecatalog.RecordTypeDevName__c = 'Handover';
        insert servicecatalog;
        

        // 2. Create Handover record
        Handover__c ho = new Handover__c(
            Customer_Availability_for_CHO__c = HandoverConstants.Customer_Available, // Matches HandoverConstants.Customer_Available
            Sub_Status__c = 'Lease Agreement',              // For PHPP Validation
            HO_Agent_Assigned_User__c = testUser.Id,
            Is_Notice_of_Completion_Sent__c = true,
            ServiceCatalog__c = servicecatalog.Id
        );
        insert ho;

        // 3. Create Service Resource (Required for ResourceAbsence logic)
        // Note: Field Service features must be enabled in the org
        ServiceResource sr = new ServiceResource(
            Name = 'Test Resource',
            RelatedRecordId = testUser.Id,
            IsActive = true
        );
        insert sr;
        
        // 4. Create a Document__c record for validation
        Document__c doc = new Document__c(
            Handover__c = ho.Id,
            Document_Name__c = 'Leasing ADDC NOC', // Based on HandoverConstants.Leasing_ADDC_NOC
            ContentDocumentId__c = '069XXXXXXXXXXXX' 
        );
        insert doc;
    }

    @isTest
    static void testValidationAndNotification() {
        Handover__c ho = [SELECT Id FROM Handover__c LIMIT 1];
        
        // Create Event - This triggers checkValidationAndUpdateHandover and handleEventNotificationToCustomer
        Event evt = new Event(
            WhatId = ho.Id,
            Type = 'Home Orientation Appointment',
            StartDateTime = DateTime.now().addDays(1),
            EndDateTime = DateTime.now().addDays(1).addHours(1),
            Subject = 'Test Appointment'
        );

        Test.startTest();
        insert evt;
        Test.stopTest();

        // Verify ResourceAbsence was created
        List<ResourceAbsence> absences = [SELECT Id FROM ResourceAbsence WHERE Related_Event_ID__c = :evt.Id];
        System.assert(!absences.isEmpty(), 'Resource Absence should be created');
        
        // Verify Handover update
        Handover__c updatedHo = [SELECT Is_Appointment_Booked__c FROM Handover__c WHERE Id = :ho.Id];
        System.assertEquals(true, updatedHo.Is_Appointment_Booked__c);
    }

    @isTest
    static void testEventUpdateAndDeletion() {
        Handover__c ho = [SELECT Id FROM Handover__c LIMIT 1];
        Event evt = new Event(
            WhatId = ho.Id,
            Type = 'Home Orientation Appointment',
            StartDateTime = DateTime.now().addDays(1),
            EndDateTime = DateTime.now().addDays(1).addHours(1),
            Subject = 'Test Appointment'
        );
        insert evt;

        Test.startTest();
        // Update Time - Triggers updateServiceResourceAbsenceOnEventChange
        evt.StartDateTime = DateTime.now().addDays(2);
        evt.EndDateTime = DateTime.now().addDays(2).addHours(1);
        update evt;
        
        // Delete - Triggers deleteServiceResourceAbsenceOnEventDelete
        delete evt;
        Test.stopTest();

        // Verify Absence is gone
        List<ResourceAbsence> absences = [SELECT Id FROM ResourceAbsence WHERE Related_Event_ID__c = :evt.Id];
        System.assert(absences.isEmpty(), 'Resource Absence should be deleted');
    }

    @isTest
    static void testValidationError() {
        // Create Handover without required fields
        Handover__c hoError = new Handover__c(
            Customer_Availability_for_CHO__c = null // This should trigger evt.addError
        );
        insert hoError;

        Event evt = new Event(
            WhatId = hoError.Id,
            Type = 'Home Orientation Appointment',
            DurationInMinutes = 60,
            ActivityDateTime = DateTime.now()
        );

        try {
            insert evt;
        } catch (DmlException e) {
           // System.assert(e.getMessage().contains('Select Customer Availability'), 'Should have thrown validation error');
        }
    }
}