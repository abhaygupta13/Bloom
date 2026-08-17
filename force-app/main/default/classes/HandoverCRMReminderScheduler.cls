global class HandoverCRMReminderScheduler implements Schedulable {
    
    global void execute(SchedulableContext sc) {
        HandoverAppointmentReminderBatch job = new HandoverAppointmentReminderBatch();
        Database.executeBatch(job);
    }
}