/*
*********************************************************
Apex Class Name    : CancelWorkOrderBatch
Created Date       : Nov 03, 2025
@description       : This batch class cancels the Work Orders
Modification Log   :
Ver   Date         : Author                               Modification
2.0   21-09-2026   : Abhay Gupta                          Optimised the class
*********************************************************
*/
public class CancelWorkOrderBatch extends SobjectBatch implements Schedulable {
    private static final String MTD_WORKORDER_CANCEL_TIME = 'WorkorderCancelTime';
    private static final String CANCELED = 'Canceled';

    public CancelWorkOrderBatch() {
        String workOrderCancelTime = MetadataService.getInstance().getAppSettingTextValue(MTD_WORKORDER_CANCEL_TIME);
        
        String baseQuery = Database.getQueryLocator([SELECT Id FROM WorkOrder WHERE hasappointmentcanceled__c = true AND Status NOT IN ('Closed', 'Canceled')]).getQuery();
        this.query = baseQuery + ' AND Cancel_Time__c < LAST_N_DAYS:' + workOrderCancelTime;
        this.fieldValueMap = new Map<SObjectField, Object>{ WorkOrder.Status => CANCELED };
    }

	public override void performAction(List<sObject> records, Database.BatchableContext bc) {
        List<WorkOrder> workOrdersToUpdate = new List<WorkOrder>();
        for (SObject record : records) {
            for (SObjectField field : fieldValueMap.keySet()) {
                record.put(field, fieldValueMap.get(field));
            }
            workOrdersToUpdate.add((WorkOrder) record);
        }
        if (!workOrdersToUpdate.isEmpty()) {
            WorkOrderService.getInstance().updateWorkOrdersWithoutTrigger(workOrdersToUpdate);
        }
    }
    
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new CancelWorkOrderBatch(), 200);
    }
}