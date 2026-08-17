public class WorkOrderService {
    private WorkOrderService() {}

    public static WorkOrderService getInstance() {
        return new WorkOrderService();
    }
    
    //insert WorkOrder without trigger
    public List<WorkOrder> insertWorkOrdersWithoutTrigger(List<WorkOrder> workOrderList){
        if(workOrderList != NULL && !workOrderList.isEmpty()){
            WorkOrderTriggerHandler.isTriggerDisabled = true;
            insert workOrderList;
            WorkOrderTriggerHandler.isTriggerDisabled = false;
        }
        return workOrderList;
    }
    
    //insert WorkOrder with trigger
    public List<WorkOrder> insertWorkOrdersWithTrigger(List<WorkOrder> workOrderList){
        if(workOrderList != NULL && !workOrderList.isEmpty()){
            insert workOrderList;
        }
        return workOrderList;
    }
    
    //Update WorkOrder without trigger
    public List<WorkOrder> updateWorkOrdersWithoutTrigger(List<WorkOrder> workOrderList){
        if(workOrderList != NULL && !workOrderList.isEmpty()){
            WorkOrderTriggerHandler.isTriggerDisabled = true;
            update workOrderList;
            WorkOrderTriggerHandler.isTriggerDisabled = false;
        }
        return workOrderList;
    }    
    
    //Update WorkOrder with trigger
    public List<WorkOrder> updateWorkOrdersWithTrigger(List<WorkOrder> workOrderList){
        if(workOrderList != NULL && !workOrderList.isEmpty()){
            update workOrderList;
        }
        return workOrderList;
    }  
    
    
    //get RecordType by name
    public RecordType getRecordTypeOfCase(String recTypName){
        if(String.isNotBlank(recTypName)){
            return [SELECT Id, Name FROM RecordType WHERE SObjectType =: Constants.Case_LABEL AND IsActive = true AND Name =: recTypName LIMIT 1];            
        } 
        return null;
    }
    
    //get workOrder by Ids
    public List<WorkOrder> getWorkOrdersByIds(List<WorkOrder> workOrderIds){
        if(!workOrderIds.isEmpty() && workOrderIds.size() > 0){
            return [SELECT Id, CaseId, Case.CaseNumber, Contractor__c,Contractor_Email__c,Customer_Phone__c	, Customer_Email__c, Customer_Name__c, Unit__r.Name, Unit__r.SAP_Unit_Number__c,
                    Project__r.Office_Location__c, Status, Project__r.Name, EndDate, StartDate, Unit__c, WorkOrderNumber, Project__r.ProjectNameArabic__c, AccountId, EntitlementId,
                    Owner.Name,Owner.Email, Contractor_Name__c, New_Requester_Phone__c,Type_of_Incident__c,Check_In__c, Check_Out__c, Check_In_Time__c,Check_Out_Time__c, Requester_Name__c, New_Requester_Name__c, New_Requester_Email__c	, Requester_Comment__c, Requester_Phone__c, Requester_Email__c, Is_Tenet_Request__c FROM WorkOrder WHERE Id IN: workOrderIds];            
        } 
        return null;
    }
    
    //get workOrder by Set Ids
    public List<WorkOrder> getWorkOrdersBySetIds(Set<Id> workOrderSetIds){
        if(!workOrderSetIds.isEmpty() && workOrderSetIds.size() > 0){
            return [SELECT Id, CaseId, Case.CaseNumber,Unit_Number__c,hasappointmentcanceled__c,Cancel_Time__c ,Due_Date__c,Resolution_Typology__c,
                    Resolution_Priority__c,CreatedDate,Sub_category__c,Incident_description__c, Customer_Email__c, Contractor__c,Customer_Phone__c, 
                    Customer_Name__c, Unit__r.Name, Unit__r.SAP_Unit_Number__c, AccountId, EntitlementId,
                    Project__r.Office_Location__c, Status, Project__r.Name, EndDate, StartDate, Unit__c, WorkOrderNumber, 
                    Project__r.ProjectNameArabic__c,Is_Emergency__c,Subject,Description,ScheduledAppointmentTimeStarted__c,
                    Owner.Name,Owner.Email, Contractor_Name__c,Contractor_Email__c,Check_In__c,Type_of_Incident__c, Check_Out__c, Check_Out_Time__c, 
                    Check_In_Time__c, New_Requester_Phone__c, New_Requester_Name__c, New_Requester_Email__c, Requester_Name__c, Requester_Comment__c, 
                    Requester_Phone__c, Requester_Email__c, Is_Tenet_Request__c 
                    FROM WorkOrder 
                    WHERE Id IN: workOrderSetIds];            
        } 
        return null;
    }
    
}