/*****************************************************************************************
Class       : AppointmentReminderBatchTest
Author      : Vishwas Kumar
Description : AppointmentReminderBatch Test Class
Created Date: 27/08/2026
*****************************************************************************************/

@IsTest
public class AppointmentReminderBatchTest {

    @TestSetup
    static void setupTestData() {

        // Create Lead
        Lead testLead = TestDataFactory.createLead('Test Customer', '0501234567','testcustomer@example.com');
        insert testLead;

        // Create appointment for tomorrow
        Event testEvent = TestDataFactory.createEvent(testLead.Id, System.now().addDays(1), System.now().addDays(1).addHours(1), 'Test Location');
        testEvent.Type = 'Appointment';
        testEvent.AppointmentStatus__c = 'Scheduled';
        testEvent.OwnerId = UserInfo.getUserId();

        insert testEvent;
    }


    @IsTest
    static void testAppointmentReminderBatch() {

        Test.startTest();
        AppointmentReminderBatch batch = new AppointmentReminderBatch();
        Database.executeBatch(batch, 100);
        Test.stopTest();
        // Verify that the appointment exists
        List<Event> appointmentList = [SELECT Id, WhoId, OwnerId, StartDateTime, EndDateTime, Location, Type, AppointmentStatus__c FROM Event WHERE Type = 'Appointment' AND AppointmentStatus__c = 'Scheduled'];

        System.assertEquals(1, appointmentList.size(), 'One scheduled appointment should exist.');

        System.assertEquals('Appointment', appointmentList[0].Type, 'Event type should be Appointment.');

        System.assertEquals('Scheduled', appointmentList[0].AppointmentStatus__c, 'Appointment status should be Scheduled.');
    }


    @IsTest
    static void testAppointmentReminderBatchNoMatchingAppointment() {

        // Create an appointment which should NOT be picked up
        Lead testLead = TestDataFactory.createLead('Test Customer 2','0501234568','testcustomer2@example.com');
        insert testLead;

        Event testEvent = TestDataFactory.createEvent(testLead.Id,System.now().addDays(2),System.now().addDays(2).addHours(1),'Test Location');
        testEvent.Type = 'Appointment';
        testEvent.AppointmentStatus__c = 'Scheduled';
        testEvent.OwnerId = UserInfo.getUserId();

        insert testEvent;

        Test.startTest();
        AppointmentReminderBatch batch = new AppointmentReminderBatch();
        Database.executeBatch(batch, 100);
        Test.stopTest();

        List<Event> appointmentList = [SELECT Id FROM Event WHERE Id = :testEvent.Id];

        System.assertEquals(1, appointmentList.size(), 'The appointment should still exist.');
    }


    @IsTest
    static void testSchedule() {

        Test.startTest();
        String sch = '0 0 23 * * ?';

        System.schedule('AppointmentReminderBatch', sch, new AppointmentReminderBatch());
        Test.stopTest();

        CronTrigger cronJob = [ SELECT Id, CronExpression, TimesTriggered, State FROM CronTrigger WHERE CronJobDetail.Name = 'AppointmentReminderBatch' LIMIT 1];

        System.assertEquals(sch, cronJob.CronExpression, 'Appointment reminder batch should be scheduled with the expected cron expression.');
    }
}