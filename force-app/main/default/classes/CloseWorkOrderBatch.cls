/*
*********************************************************
Apex Class Name    : CloseWorkOrderBatch
Created Date       : July 30, 2024
@description       : This class is used for update to close work Order status when customer is not available.
@author            : Pavitra Chauhan
Modification Log   :
Ver   Date         : Author                               Modification
1.9   28-08-2024   : Pavitra Chauhan                      Initial Version
*********************************************************
*/
public class CloseWorkOrderBatch implements Database.Batchable<SObject> {
    
    // Start method to define the query
    public Database.QueryLocator start(Database.BatchableContext BC) {
        // Query to find WorkOrders where Customer_Availability__c is 'Customer not available'
        // and no ServiceAppointment has been created in the last 48 hours.
        
       //Datetime cutoffDate = System.now().addDays(-2);
       /*Datetime startDate = System.today().addDays(-2); 
       Datetime endDate = System.today().addDays(-1);

       String query = 'SELECT Id FROM WorkOrder WHERE Customer_Availability__c = \'Not Available\' ' +'AND Id IN (' +' SELECT ParentRecordId FROM ServiceAppointment ' +
            ' WHERE CreatedDate >= :startDate AND CreatedDate < :endDate' +')'; // NEW CHANGES
        */

        String query = 'SELECT Id FROM WorkOrder WHERE Customer_Availability__c = \'Not Available\' AND Check_In_Time__c < LAST_N_DAYS:2 AND Status != \'Closed\' AND Id NOT IN (SELECT ParentRecordId FROM ServiceAppointment WHERE Status != \'Completed\' AND Closure_Reason__c != \'Customer not available\')';
        System.debug('Start Query ::::: '+query);
        return Database.getQueryLocator(query);
    }

    // Execute method to perform the update
    public void execute(Database.BatchableContext BC, List<SObject> scope) {
        System.debug('scope >> ' + scope);
        List<WorkOrder> workOrdersToUpdate = new List<WorkOrder>();
        
        for (SObject sObj : scope) {
            WorkOrder wo = (WorkOrder) sObj;
            wo.Status = 'Closed'; // Update the status to 'Closed'
            wo.Closure_Reason__c = Constants.CUSTOMER_NOT_AVAILABLE_LABEL; // NEW CHANGES
            wo.Closure_Comment__c = Constants.CUSTOMER_NOT_AVAILABLE_LABEL; // NEW CHANGES
            workOrdersToUpdate.add(wo);
        }
        
        // Update the WorkOrders
        if (!workOrdersToUpdate.isEmpty()) {
            update workOrdersToUpdate;
        }
    }

    // Finish method (optional)
    public void finish(Database.BatchableContext BC) {
        // Optional: Send email notification or perform other actions when batch is done
    }
}