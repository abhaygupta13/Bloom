global class HandoverPaymentReminderBatchScheduler implements Schedulable {
    
    global void execute(SchedulableContext sc) {
        HandoverPaymentReminderBatch job = new HandoverPaymentReminderBatch();
        Database.executeBatch(job);
    }
}