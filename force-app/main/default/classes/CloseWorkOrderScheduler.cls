public class CloseWorkOrderScheduler implements Schedulable {

    public void execute(SchedulableContext SC) {
        Database.executeBatch(new CloseWorkOrderBatch(), 200);
    }
}