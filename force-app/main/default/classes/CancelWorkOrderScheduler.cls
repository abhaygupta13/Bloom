public class CancelWorkOrderScheduler implements Schedulable {

    public void execute(SchedulableContext SC) {
        Database.executeBatch(new CancelWorkOrderBatch(), 200);
    }
}