/*
*********************************************************
Apex Class Name    : WorkOrderService
Created Date       : Dec 26, 2024
@description       : This class handles record retrieval and DML operations.
Modification Log   :
Ver   Date         : Author                               Modification
4.8   10-09-2026   : Abhay Gupta                          Optimised the class and removed uncommented code
*********************************************************
*/
public inherited sharing class WorkOrderService {
    private WorkOrderService() {}

    public static WorkOrderService getInstance() {
        return new WorkOrderService();
    }
    
    public List<WorkOrder> updateWorkOrdersWithoutTrigger(List<WorkOrder> workOrderList) {
        if(workOrderList != null && !workOrderList.isEmpty()) {
            WorkOrderTriggerHandler.isTriggerDisabled = true;
            update workOrderList;
            WorkOrderTriggerHandler.isTriggerDisabled = false;
        }
        return workOrderList;
    }
    
    public List<WorkOrder> updateWorkOrders(List<WorkOrder> workOrderList) {
        if(workOrderList != null && !workOrderList.isEmpty()) {
            update workOrderList;
        }
        return workOrderList;
    }  

    public List<WorkOrder> getWorkOrdersByIds(Set<Id> workOrderSetIds) {
        return [    
                    SELECT
                        AccountId,
                        CaseId,
                        Case.CaseNumber,
                        Check_In__c,
                        Check_In_Time__c,
                        Check_Out__c,
                        Check_Out_Time__c,
                        Contractor__c,
                        Contractor_Email__c,
                        Contractor_Name__c,
                        CreatedDate,
                        Customer_Email__c,
                        Customer_Name__c,
                        Customer_Phone__c,
                        Description,
                        Due_Date__c,
                        EndDate,
                        EntitlementId,
                        hasappointmentcanceled__c,
                        Incident_description__c,
                        Is_Emergency__c,
                        Is_Tenet_Request__c,
                        New_Requester_Email__c,
                        New_Requester_Name__c,
                        New_Requester_Phone__c,
                        Owner.Name,
                        Owner.Email,
                        Project__c,
                        Project__r.Name,
                        Project__r.Office_Location__c,
                        Project__r.ProjectNameArabic__c,
                        Requester_Comment__c,
                        Requester_Email__c,
                        Requester_Name__c,
                        Requester_Phone__c,
                        Resolution_Priority__c,
                        Resolution_Typology__c,
                        ScheduledAppointmentTimeStarted__c,
                        StartDate,
                        Status,
                        Subject,
                        Sub_category__c,
                        Type_of_Incident__c,
                        Unit_Number__c,
                        Unit__c,
                        Unit__r.Name,
                        Unit__r.SAP_Unit_Number__c,
                        WorkOrderNumber,
                        Cancel_Time__c
                    FROM WorkOrder
                    WHERE Id IN :workOrderSetIds
                ];
    }
}