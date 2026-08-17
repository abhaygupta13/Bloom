global class HandoverSLABatchScheduler implements Schedulable {
    
    global void execute(SchedulableContext sc) {
        HandoverSLABatch job = new HandoverSLABatch();
        Database.executeBatch(job, 200);
    }
}