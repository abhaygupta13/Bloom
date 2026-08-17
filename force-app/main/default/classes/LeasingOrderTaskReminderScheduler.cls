public class LeasingOrderTaskReminderScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new LeasingOrderTaskReminderBatch(), 200);
    }
}