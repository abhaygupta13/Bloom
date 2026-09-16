/*****************************************************************************************
Class       : AppointmentControllerTest
    Author      : Vishwas Kumar
    Description : Test class for AppointmentController
    Test Class  :
    Created Date: 06 AUG 2026
     *****************************************************************************************/
@isTest
public class AppointmentControllerTest {
    
    @testSetup
    private static void testData() {
        
        Account personAcc = TestDataFactory.createPersonalAccount('Test Person', '784-1990-1234567-1', '9876543210', 'personacc@test.com');
        insert personAcc;
        
        Account businessAcc = TestDataFactory.createBrokerAccount('Test Business Account', false, '1122334455');
        insert businessAcc;
        
        Contact con = TestDataFactory.createContact('Test Contact', businessAcc.Id, true, 'contact@test.com');
        insert con;
        
        Lead leadRec = TestDataFactory.createLead('Test Lead', '9988776655', 'lead@test.com');
        insert leadRec;
    }
    
    
    @isTest
    private static void testCreateAppointment() {
        Account personAcc = [SELECT Id, PersonContactId FROM Account WHERE Name = 'Test Person' LIMIT 1];
        
        Event appointment = new Event(
            Subject = 'Test Appointment',
        StartDateTime = DateTime.newInstance(2026, 8, 20, 10, 0, 0),
        EndDateTime = DateTime.newInstance(2026, 8, 20, 11, 0, 0),
        AppointmentType__c = 'Sales Enquiry',
        AppointmentMode__c = 'Offline',
        Location__c = 'Bloom Central',
        Location = 'Bloom Central',
        Description = 'Test description'
            );
        
        Test.startTest();
        Event event = AppointmentController.createAppointment(appointment, personAcc.Id);
        Test.stopTest();
        
        List<Event> eventList = [SELECT Id, Subject, WhoId, WhatId FROM Event WHERE Id = :event.Id];
        System.assertEquals(false, eventList.isEmpty(), 'No Event record found');
        System.assertEquals(personAcc.PersonContactId, eventList[0].WhoId, 'WhoId should match the Person Account\'s Contact.');
        System.assertEquals(personAcc.Id, eventList[0].WhatId, 'WhatId should match the Account.');
    }
    
    @isTest
    private static void testCreateAppointment_MissingDateTime() {
        Account personAcc = [SELECT Id FROM Account WHERE Name = 'Test Person' LIMIT 1];
        
        Event appointment = new Event(
            Subject = 'Missing Dates Test',
        EndDateTime = DateTime.newInstance(2026, 8, 20, 11, 0, 0)
            );
        
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            AppointmentController.createAppointment(appointment, personAcc.Id);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assertEquals(true, exceptionThrown, 'Expected an AuraHandledException for missing start date/time.');
    }
    
    @isTest
    private static void testGetAvailableTimes_Success() {
        Date slotDate = Date.today().addDays(1);
        List<AppointmentSlot__c> slots = TestDataFactory.createAppointmentSlots(3, 'Available', UserInfo.getUserId(), slotDate);
        
        Test.startTest();
        List<AppointmentSlot__c> result = AppointmentController.getAvailableSlotsTime(UserInfo.getUserId(), slotDate);
        Test.stopTest();
        
        System.assertEquals(3, result.size(), 'Expected 3 available slots for this user/date.');
    }
    
    @isTest
    private static void testCreateAppointment_LeadSource() {
        Lead leadRec = [SELECT Id FROM Lead WHERE Email = 'lead@test.com' LIMIT 1];
        
        Event appointment = new Event(
            Subject = 'Lead Appointment',
        StartDateTime = DateTime.newInstance(2026, 8, 20, 10, 0, 0),
        EndDateTime = DateTime.newInstance(2026, 8, 20, 11, 0, 0),
        AppointmentType__c = 'Sales Enquiry',
        AppointmentMode__c = 'Offline',
        Location__c = 'Bloom Central',
        Location = 'Bloom Central'
            );
        
        Test.startTest();
        Event result = AppointmentController.createAppointment(appointment, leadRec.Id);
        Test.stopTest();
        
        Event evt = [SELECT Id, WhoId, WhatId FROM Event WHERE Id = :result.Id];
        System.assertEquals(leadRec.Id, evt.WhoId, 'WhoId should equal the Lead.');
        System.assertEquals(null, evt.WhatId, 'WhatId should be null for Lead source.');
    }
    
    @isTest
    private static void testCreateAppointment_ContactSource() {
        Contact con = [SELECT Id, AccountId FROM Contact WHERE Email = 'contact@test.com' LIMIT 1];
        
        Event appointment = new Event(
            Subject = 'Contact Appointment',
        StartDateTime = DateTime.newInstance(2026, 8, 20, 10, 0, 0),
        EndDateTime = DateTime.newInstance(2026, 8, 20, 11, 0, 0),
        AppointmentType__c = 'Sales Enquiry',
        AppointmentMode__c = 'Offline',
        Location__c = 'Bloom Central',
        Location = 'Bloom Central'
            );
        
        Test.startTest();
        Event result = AppointmentController.createAppointment(appointment, con.Id);
        Test.stopTest();
        
        Event evt = [SELECT Id, WhoId, WhatId FROM Event WHERE Id = :result.Id];
        System.assertEquals(con.Id, evt.WhoId, 'WhoId should equal the Contact.');
        System.assertEquals(con.AccountId, evt.WhatId, 'WhatId should equal the Contact\'s Account.');
    }
    
    @isTest
    private static void testCreateAppointment_BusinessAccountSource() {
        Account businessAcc = [SELECT Id FROM Account WHERE Name = 'Test Business Account' LIMIT 1];
        
        Event appointment = new Event(
            Subject = 'Business Account Appointment',
        StartDateTime = DateTime.newInstance(2026, 8, 20, 10, 0, 0),
        EndDateTime = DateTime.newInstance(2026, 8, 20, 11, 0, 0)
            );
        
        Test.startTest();
        Event result = AppointmentController.createAppointment(appointment, businessAcc.Id);
        Test.stopTest();
        
        Event evt = [SELECT Id, WhatId FROM Event WHERE Id = :result.Id];
        System.assertEquals(businessAcc.Id, evt.WhatId, 'WhatId should equal the Business Account.');
    }
    
    @isTest
    private static void testGetAvailableTimes_NullInputs() {
        Test.startTest();
        List<AppointmentSlot__c> result = AppointmentController.getAvailableSlotsTime(null, null);
        Test.stopTest();
        
        System.assertEquals(true, result.isEmpty(), 'Expected empty list when userId/date are null.');
    }
    
    @isTest
    private static void testGetAvailableTimes_NullUserId() {
        Test.startTest();
        List<AppointmentSlot__c> result = AppointmentController.getAvailableSlotsTime(null, Date.today());
        Test.stopTest();
        
        System.assertEquals(true, result.isEmpty(), 'Expected empty list when userId is null.');
    }
    
    @isTest
    private static void testGetAvailableTimes_NullDate() {
        Test.startTest();
        List<AppointmentSlot__c> result = AppointmentController.getAvailableSlotsTime(UserInfo.getUserId(), null);
        Test.stopTest();
        
        System.assertEquals(true, result.isEmpty(), 'Expected empty list when selectedDate is null.');
    }
    
}