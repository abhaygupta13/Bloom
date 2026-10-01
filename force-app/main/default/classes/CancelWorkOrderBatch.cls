public class CancelWorkOrderBatch implements Database.Batchable<sObject>, Schedulable{
     private static final string MTD_WORKORDER_CANCEL_TIME { get { return 'WorkorderCancelTime'; } }

    public Database.QueryLocator start(Database.BatchableContext BC) {
     MetadataService objMetadataService = MetadataService.getInstance();
     String workOrderCancelTime = objMetadataService.getAppSettingTextValue(MTD_WORKORDER_CANCEL_TIME);
     Set<String> excludedStatuses = new Set<String>{'Closed', 'Canceled'};
     String excludedStatusStr = '\'' + String.join(new List<String>(excludedStatuses), '\',\'') + '\'';
        
       String query =
            'SELECT Id FROM WorkOrder ' +
            'WHERE hasappointmentcanceled__c = true ' +
            'AND Cancel_Time__c < LAST_N_DAYS:' + workOrderCancelTime + ' ' +
            'AND Status NOT IN (' + excludedStatusStr + ')';
        
        return Database.getQueryLocator(query);
    }

    // Execute method to perform the update
    public void execute(Database.BatchableContext BC, List<SObject> scope) {
        List<WorkOrder> workOrdersToUpdate = new List<WorkOrder>();
        
        for (SObject sObj : scope) {
            WorkOrder wo = (WorkOrder) sObj;
            wo.Status = 'Canceled'; // Update the status to 'Closed'
           
            workOrdersToUpdate.add(wo);
        }
        
        // Update the WorkOrders
        if (!workOrdersToUpdate.isEmpty()) {
            WorkOrderService objWorkOrderService = WorkOrderService.getInstance();
            objWorkOrderService.updateWorkOrdersWithoutTrigger(workOrdersToUpdate);
        }
       
    }

    // Finish method (optional)
    public void finish(Database.BatchableContext BC) {
        // Optional: Send email notification or perform other actions when batch is done
    }
      public void execute(SchedulableContext sc) {
        Database.executeBatch(new CancelWorkOrderBatch(), 200);
    }
}