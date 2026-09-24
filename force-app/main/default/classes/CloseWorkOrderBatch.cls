/*
*********************************************************
Apex Class Name    : CloseWorkOrderBatch
Created Date       : July 30, 2024
@description       : This class is used for update to close work Order status when customer is not available.
@author            : Pavitra Chauhan
Modification Log   :
Ver   Date         : Author                               Modification
1.9   28-08-2024   : Pavitra Chauhan                      Initial Version
2.0   21-09-2026   : Abhay Gupta                          Refactored the class and optimized it
*********************************************************
*/
public class CloseWorkOrderBatch extends SobjectBatch implements Schedulable {

    public CloseWorkOrderBatch() {
        this.query = Database.getQueryLocator([SELECT Id FROM WorkOrder WHERE Customer_Availability__c = 'Not Available' 
                                                AND Check_In_Time__c < LAST_N_DAYS:2 
                                                AND Status != 'Closed' 
                                                AND Id NOT IN (
                                                    SELECT ParentRecordId 
                                                    FROM ServiceAppointment WHERE Status != 'Completed' AND Closure_Reason__c != 'Customer not available')
                                                ]).getQuery();
        
        this.fieldValueMap = new Map<SObjectField, Object>{
            WorkOrder.Status => 'Closed',
            WorkOrder.Closure_Reason__c => Constants.CUSTOMER_NOT_AVAILABLE_LABEL,
            WorkOrder.Closure_Comment__c => Constants.CUSTOMER_NOT_AVAILABLE_LABEL
        };
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new CloseWorkOrderBatch(), 200);
    }
}