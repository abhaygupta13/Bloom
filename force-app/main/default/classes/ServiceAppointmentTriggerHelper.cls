/*
*********************************************************
Apex Class Name    : ServiceAppointmentTriggerHelper 
Created Date       : July 15, 2024
@description       : This class is handling multipal methods of ServiceAppointment trigger.
@author            : Pavitra Chauhan
Modification Log   :
Ver   Date         : Author                               Modification
6.3  10-09-2026   : Abhay Gupta                           Optimized code
*********************************************************
*/
public class ServiceAppointmentTriggerHelper {
    private static String WORKORDER_CREATION_NOTIFICATION_FOR_CUSTOMER = 'WorkOrder Creation Notification for Customer';
    private static String SERVICE_APPOINTMENT_BOOKED_NOTIFICATION_FOR_CONTRACTOR = 'Service Appointment Booked Notification for Contractor';
    private static String SERVICE_APPOINTMENT_BOOKED_NOTIFICATION_FOR_DLP_AGENT = 'Service Appointment Booked Notification for DLP Agent';
    private static String WORKORDER_Rescheduled_NOTIFICATION_FOR_CUSTOMER = 'WorkOrder Rescheduled Notification for Customer';
    private static String SERVICE_APPOINTMENT_Rescheduled_NOTIFICATION_FOR_CONTRACTOR = 'Service Appointment Rescheduled Notification for Contractor';
    private static String SERVICE_APPOINTMENT_Rescheduled_NOTIFICATION_FOR_DLP_AGENT = 'Service Appointment Rescheduled Notification for DLP Agent';
    private static String COMPLETED = 'Completed';
    private static String DISPATCHED = 'Dispatched';
    private static String IN_PROGRESS = 'In Progress';
    private static String CANCELED = 'Canceled';
    private static String RE_SCHEDULED = 'Re Scheduled';
    private static String SCHEDULED = 'Scheduled';
    private static String NOT_CHECKED_IN = 'Not Checked-In';
    private static String BLOOM_NO_REPLY_LABEL = 'Bloom No Reply';
    private static String DLP_LABEL = 'DLP';

    public static void updateFirstAppointment(List<ServiceAppointment> newServiceAppointments) {
        Set<Id> workOrderIds = new Set<Id>();
        Map<Id, Integer> workOrderToSAcount = new Map<Id, Integer>();
        Map<Id, WorkOrder> workOrderMap;
        
        for(ServiceAppointment sa : newServiceAppointments) {
            if(sa.ParentRecordId != null && String.valueOf(sa.ParentRecordId).startsWith('0WO')) {
                sa.Work_Order__c = sa.ParentRecordId;
                workOrderIds.add(sa.ParentRecordId);               
            }            
        }

        if(!workOrderIds.isEmpty()) {
            List<AggregateResult> groupedResults = ServiceAppointmentService.getInstance().getSACountByParentRecordIds(workOrderIds);
            for(AggregateResult ar : groupedResults) {
                workOrderToSAcount.put((Id) ar.get('ParentRecordId'), (Integer) ar.get('total'));
            }
            workOrderMap = new Map<Id, WorkOrder>(WorkOrderService.getInstance().getWorkOrdersByIds(workOrderIds));
        }
        
        for(ServiceAppointment saObj : newServiceAppointments) {
            if(saObj.ParentRecordId != null && !workOrderToSAcount.containsKey(saObj.ParentRecordId)) {
                saObj.Is_First_Appointment__c = true;  
            }

            if(String.isNotBlank(saObj.ParentRecordId) && workOrderMap != null && workOrderMap.containsKey(saObj.ParentRecordId)) {
                WorkOrder workOrderObj = workOrderMap.get(saObj.ParentRecordId);
                saObj.WorkOrder_Unit__c = workOrderObj.Unit__c;
                saObj.Project__c = workOrderObj.Project__c;                 
            }
        }
    }    
    
    public static void updateWorkOrderField(List<ServiceAppointment> newList, Map<Id, ServiceAppointment> oldMap) {
        for(ServiceAppointment sa : newList) {
            if(sa.ParentRecordId != null && oldMap.get(sa.Id).ParentRecordId != sa.ParentRecordId && String.valueOf(sa.ParentRecordId).startsWith('0WO')) {
                sa.Work_Order__c = sa.ParentRecordId;
            }
        }
    }       
    
    public static void sendMailWhenServiceAppointmentScheduled(List<ServiceAppointment> scheduledAppointments, Map<Id, ServiceAppointment> saOldMap) {
        Set<String> templateNames = new Set<String>{SERVICE_APPOINTMENT_BOOKED_NOTIFICATION_FOR_CONTRACTOR, WORKORDER_CREATION_NOTIFICATION_FOR_CUSTOMER, SERVICE_APPOINTMENT_BOOKED_NOTIFICATION_FOR_DLP_AGENT, SERVICE_APPOINTMENT_Rescheduled_NOTIFICATION_FOR_CONTRACTOR, WORKORDER_Rescheduled_NOTIFICATION_FOR_CUSTOMER, SERVICE_APPOINTMENT_Rescheduled_NOTIFICATION_FOR_DLP_AGENT};

        ContentVersion contentVersionObj = new ContentVersion();
        Set<Id> workOrderIds = new Set<Id>();
        List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
        Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>();
        
        for(ServiceAppointment sa : scheduledAppointments) {
            if(sa.ParentRecordId != null) {
                workOrderIds.add(sa.ParentRecordId);
            }
        }  
        
        if(workOrderIds.isEmpty()) {return;}
        WorkOrderService objWorkOrderService = WorkOrderService.getInstance();
        workOrderMap = new Map<Id, WorkOrder>(objWorkOrderService.getWorkOrdersByIds(workOrderIds));            
        if(workOrderMap.isEmpty()) {return;}
        EmailService objEmailService = EmailService.getInstance();
        Map<String, EmailTemplate> templateNameVsEmailTemplateMap = objEmailService.getEmailTemplatesByName(templateNames);
        
        EmailTemplate mailTemplateContractor = templateNameVsEmailTemplateMap.get(SERVICE_APPOINTMENT_BOOKED_NOTIFICATION_FOR_CONTRACTOR);            
        EmailTemplate mailTemplateCustomer = templateNameVsEmailTemplateMap.get(WORKORDER_CREATION_NOTIFICATION_FOR_CUSTOMER);            
        EmailTemplate mailTemplateDLP = templateNameVsEmailTemplateMap.get(SERVICE_APPOINTMENT_BOOKED_NOTIFICATION_FOR_DLP_AGENT);
        EmailTemplate rescheduledTemplateContractor = templateNameVsEmailTemplateMap.get(SERVICE_APPOINTMENT_Rescheduled_NOTIFICATION_FOR_CONTRACTOR);            
        EmailTemplate rescheduledTemplateCustomer = templateNameVsEmailTemplateMap.get(WORKORDER_Rescheduled_NOTIFICATION_FOR_CUSTOMER);            
        EmailTemplate rescheduledTemplateDLP = templateNameVsEmailTemplateMap.get(SERVICE_APPOINTMENT_Rescheduled_NOTIFICATION_FOR_DLP_AGENT);
        OrgWideEmailAddress orgWideEmail = objEmailService.getOrgWideEmailAddressByDisplayName(BLOOM_NO_REPLY_LABEL);
        
        for(ServiceAppointment srvApp: scheduledAppointments) {
            WorkOrder workOrderObj = workOrderMap.get(srvApp.ParentRecordId);
            
            //Send email to contractor when service appointment is created (booked).
            if(String.isNotBlank(workOrderObj.Contractor_Email__c) && srvApp != null && mailTemplateContractor != null &&
                String.isNotBlank(srvApp.ParentRecordId) && String.isNotBlank(srvApp.Status) && srvApp.Status != saOldMap.get(srvApp.Id).Status &&
                srvApp.Status == SCHEDULED) {                  
                    mailList.add(DLPEmailHandler.sendEmailProcess(mailTemplateContractor, workOrderObj, srvApp, new List<String>{workOrderObj.Contractor_Email__c}, contentVersionObj, orgWideEmail));
            }
            
            //Send email to customer when service appointment is created (booked).
            if(workOrderObj.New_Requester_Email__c != null && srvApp != null && mailTemplateCustomer != null && String.isNotBlank(srvApp.ParentRecordId) && String.isNotBlank(srvApp.Status) && srvApp.Status != saOldMap.get(srvApp.Id).Status && srvApp.Status == SCHEDULED) {
                mailList.add(DLPEmailHandler.sendEmailProcess(mailTemplateCustomer, workOrderObj, srvApp, new List<String>{workOrderObj.New_Requester_Email__c}, contentVersionObj, orgWideEmail));                        
            }       
            
            //Send email to owner (DLP agent) when service appointment is created (booked).
            if(String.isNotBlank(workOrderObj.Owner.Email) && srvApp != null && mailTemplateDLP != null && String.isNotBlank(srvApp.ParentRecordId) && String.isNotBlank(srvApp.Status) && srvApp.Status != saOldMap.get(srvApp.Id).Status && srvApp.Status == SCHEDULED) {                    
                mailList.add(DLPEmailHandler.sendEmailProcess(mailTemplateDLP, workOrderObj, srvApp, new List<String>{workOrderObj.Owner.Email}, contentVersionObj, orgWideEmail));
            }
            
            //Send email to contractor when service appointment is rescheduled.
            if(String.isNotBlank(workOrderObj.Contractor_Email__c) && srvApp != null && rescheduledTemplateContractor != null && srvApp.SchedStartTime != null && srvApp.SchedStartTime != saOldMap.get(srvApp.Id).SchedStartTime && srvApp.SchedEndTime != null && srvApp.SchedEndTime != saOldMap.get(srvApp.Id).SchedEndTime && String.isNotBlank(srvApp.ParentRecordId) && 
                String.isNotBlank(srvApp.Status) && (srvApp.Status == DISPATCHED || srvApp.Status == NOT_CHECKED_IN)) {                  
                    mailList.add(DLPEmailHandler.sendEmailProcess(rescheduledTemplateContractor, workOrderObj, srvApp, new List<String>{workOrderObj.Contractor_Email__c}, contentVersionObj, orgWideEmail));
            }
            
            //Send email to customer when service appointment is rescheduled
            if(workOrderObj.New_Requester_Email__c != null && srvApp != null && rescheduledTemplateCustomer != null && 
                srvApp.SchedStartTime != null && srvApp.SchedStartTime != saOldMap.get(srvApp.Id).SchedStartTime && srvApp.SchedEndTime != null && 
                srvApp.SchedEndTime != saOldMap.get(srvApp.Id).SchedEndTime && String.isNotBlank(srvApp.ParentRecordId) && 
                String.isNotBlank(srvApp.Status) && (srvApp.Status == DISPATCHED || srvApp.Status == NOT_CHECKED_IN)) {
                    mailList.add(DLPEmailHandler.sendEmailProcess(rescheduledTemplateCustomer, workOrderObj, srvApp, new List<String>{workOrderObj.New_Requester_Email__c}, contentVersionObj, orgWideEmail));                        
            }       
            
            //Send email to owner (DLP agent) when service appointment is rescheduled
            if(String.isNotBlank(workOrderObj.Owner.Email) && srvApp != null && rescheduledTemplateDLP != null && 
                srvApp.SchedStartTime != null && srvApp.SchedStartTime != saOldMap.get(srvApp.Id).SchedStartTime && srvApp.SchedEndTime != null && 
                srvApp.SchedEndTime != saOldMap.get(srvApp.Id).SchedEndTime && String.isNotBlank(srvApp.ParentRecordId) && 
                String.isNotBlank(srvApp.Status) && (srvApp.Status == DISPATCHED || srvApp.Status == NOT_CHECKED_IN)) {                    
                    mailList.add(DLPEmailHandler.sendEmailProcess(rescheduledTemplateDLP, workOrderObj, srvApp, new List<String>{workOrderObj.Owner.Email}, contentVersionObj, orgWideEmail));
            } 
        }

        List<Messaging.SendEmailResult> results = objEmailService.sendEmail(mailList);
    }
    
    public static void addContractor(List<ServiceAppointment> ServiceAppointmentList, Map<Id,ServiceAppointment> oldServiceAppointment) {
        Set<Id> workOrderIds = new Set<Id>();
        set<Id> userIds = new Set<Id>();
        Set<Id> saIds = new Set<Id>();
        for(ServiceAppointment sa: ServiceAppointmentList) {
            if(String.isNotBlank(sa.ParentRecordId) && sa.Status != COMPLETED) {
                workOrderIds.add(sa.ParentRecordId);
                saIds.add(sa.Id);
            }
        }

        WorkOrderService objWorkOrderService = WorkOrderService.getInstance();
        Map<Id, WorkOrder> workOrderMap = workOrderIds.isEmpty() ? new Map<Id, WorkOrder>() : new Map<Id, WorkOrder>(objWorkOrderService.getWorkOrdersByIds(workOrderIds));
       
        for(Id key : workOrderMap.keySet()) {
            userIds.add(workOrderMap.get(key).Contractor__c);
        }
        
        ServiceResourceService objServiceResourceService = ServiceResourceService.getInstance();
        List<ServiceResource> serviceResourceList = objServiceResourceService.getServiceResourcesByRelatedRecordIds(userIds);                
                       
        List<AssignedResource> assignedResourceList = new List<AssignedResource>();
        List<AssignedResource> existingARs = [SELECT Id, ServiceAppointmentId, ServiceResourceId,ServiceResource.Is_Contractor__c  FROM AssignedResource WHERE ServiceAppointmentId IN :saIds];
      
        Map<Id, Id> contractorAssignedMap = new Map<Id, Id>();
        if(!existingARs.isEmpty()) {     
            for(AssignedResource ar : existingARs) {
                if(ar.ServiceResource.Is_Contractor__c) {
                    contractorAssignedMap.put(ar.ServiceAppointmentId, ar.ServiceResourceId);
                }
            }
        }

        for(ServiceAppointment sa: ServiceAppointmentList) {
            if(sa.Status == SCHEDULED && sa.Status != oldServiceAppointment.get(sa.Id).Status && serviceResourceList != null  && !contractorAssignedMap.containsKey(sa.Id) ) {                
                for(ServiceResource sr : serviceResourceList) {
                    if(sr.RelatedRecordId == workOrderMap.get(sa.ParentRecordId).Contractor__c) {
                        AssignedResource assRes = new AssignedResource();
                        assRes.ServiceResourceId = sr.Id;
                        assRes.ServiceAppointmentId = sa.Id;
                        assignedResourceList.add(assRes);
                    }
                }                        
            }
        }
       
        AssignedResourceService objAssignedResourceService = AssignedResourceService.getInstance();
        assignedResourceList = objAssignedResourceService.insertAssignedResourcesWithoutTrigger(assignedResourceList);
    }    
    
    //Update the new owner on Service Appointment and Work Order on after update.
    public static void newAppontmentSchedule(List<ServiceAppointment> allAppointments, Map<Id,ServiceAppointment> oldMap) {
        if(allAppointments == null || allAppointments.isEmpty()) {
            return; 
        }
        
        Set<Id> serviceAppointmentIds = new Map<Id, ServiceAppointment>(allAppointments).keySet();
        if(!serviceAppointmentIds.isEmpty()) {
            updateOwner(serviceAppointmentIds);
        }
    }
    
    @future
    public static void updateOwner(Set<Id> serviceAppointmentIds) {
        ServiceAppointmentService objServiceAppointmentService = ServiceAppointmentService.getInstance(); 
        List<ServiceAppointment> serApp = objServiceAppointmentService.getServiceAppointmentsByIds(serviceAppointmentIds);
        
        Set<Id> serviceAppointmentIdsSet = new Set<Id>();
        Set<Id> workOrderIds = new Set<Id>();
        
        for(ServiceAppointment sa : serApp) {  
            if(String.isNotBlank(sa.Status) && String.isNotBlank(sa.ParentRecordId) && 
               (sa.Status == SCHEDULED || sa.Status == DISPATCHED)) 
            {
                serviceAppointmentIdsSet.add(sa.Id);
                workOrderIds.add(sa.ParentRecordId);
            }
        }
        
        if(serviceAppointmentIdsSet.isEmpty() || workOrderIds.isEmpty()) {
            return; 
        }
        
        // Get all Assigned Resources related to Service Appointments
        AssignedResourceService objAssignedResourceService = AssignedResourceService.getInstance();
        Map<Id, AssignedResource> assRes = new Map<Id, AssignedResource>(
            objAssignedResourceService.getAssignedResourcesByServiceAppointmentIds(serviceAppointmentIdsSet)
        );
        
        // Collect ServiceResourceIds
        Set<Id> serviceResourceIds = new Set<Id>();
        for(AssignedResource ar : assRes.values()) {
            if(ar.ServiceResourceId != null) {
                serviceResourceIds.add(ar.ServiceResourceId);
            }           
        }
        
        // Query ServiceResource Names and Related User IDs
        ServiceResourceService objServiceResourceService = ServiceResourceService.getInstance();
        Map<Id, ServiceResource> serviceResourceMap = new Map<Id, ServiceResource>(
            objServiceResourceService.getServiceResourcesBySetIds(serviceResourceIds)
        );                
        
        // Get all Work Orders related to the Service Appointments
        WorkOrderService objWorkOrderService = WorkOrderService.getInstance();
        Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>(
            objWorkOrderService.getWorkOrdersByIds(workOrderIds)
        );
        
        Map<Id,ServiceAppointment> appointmentsToUpdate = new Map<Id,ServiceAppointment>();
        Map<Id,WorkOrder> workOrdersToUpdate = new Map<Id,WorkOrder>();
        
        for(ServiceAppointment sa : serApp) { 
            for(AssignedResource asr : assRes.Values()) {
                Id newOwnerId;
                if(serviceResourceMap.get(asr.ServiceResourceId).Is_Contractor__c == false) {
                    newOwnerId = serviceResourceMap.get(asr.ServiceResourceId).RelatedRecordId;
                    if(newOwnerId != null) {
                        sa.OwnerId = newOwnerId; // Update Service Appointment Owner
                        appointmentsToUpdate.put(sa.Id,sa);
                        
                        WorkOrder workOrder = workOrderMap.get(sa.ParentRecordId);
                        if(workOrder != null) {
                            workOrder.OwnerId = newOwnerId; // Update Work Order Owner
                            workOrder.Status = SCHEDULED;
                            workOrdersToUpdate.put(workOrder.Id, workOrder);
                        }
                    }
                }
            }            
        }
        
        // Perform updates safely
        if(!workOrdersToUpdate.isEmpty()) { 
            objWorkOrderService.updateWorkOrdersWithoutTrigger(workOrdersToUpdate.values());
        }
        if(!appointmentsToUpdate.isEmpty()) {
            objServiceAppointmentService.updateServiceAppointmentsWithoutTrigger(appointmentsToUpdate.values());
        }               
    }
    
    //after Update
    public static void statusUpdate(List<ServiceAppointment> allAppointments, Map<Id, ServiceAppointment> oldMap) {
        WorkType wrkTypeObj = new WorkType();
        wrkTypeObj = WorkTypeService.getWorkTypeRecord(DLP_LABEL);
        
        List<ServiceAppointment> appointmentsToUpdate = new List<ServiceAppointment>();
        for(ServiceAppointment sa : allAppointments) {
            if(String.isNotBlank(sa.Status) && sa.Status != oldMap.get(sa.Id).Status && sa.Status == SCHEDULED && oldMap.get(sa.Id).Status != DISPATCHED && String.isNotBlank(sa.ParentRecordId)) {  
                ServiceAppointment srv = new ServiceAppointment(Id = sa.Id);
                srv.Status = DISPATCHED;
                if(wrkTypeObj != null) {
                    srv.WorkTypeId = wrkTypeObj.Id;
                }
                appointmentsToUpdate.add(srv);
            }
        }
        
        if(!appointmentsToUpdate.isEmpty()) {
            ServiceAppointmentService objServiceAppointmentService = ServiceAppointmentService.getInstance();
            appointmentsToUpdate = objServiceAppointmentService.updateServiceAppointmentsWithoutTrigger(appointmentsToUpdate);
        }
    }
    
    public static void throwErrorOnUpdate(List<ServiceAppointment> newAppointments, Map<Id, ServiceAppointment> oldMap) {
        Set<Id> workOrderIds = new Set<Id>();
        
        for(ServiceAppointment saObj :newAppointments) {
            if(saObj.status == IN_PROGRESS && saObj.SchedStartTime != null && saObj.SchedStartTime != oldMap.get(saObj.Id).SchedStartTime && saObj.SchedEndTime != null && saObj.SchedEndTime != oldMap.get(saObj.Id).SchedEndTime && String.isNotBlank(saObj.ParentRecordId) ) {
                workOrderIds.add(saObj.ParentRecordId);
            }
        }
        
        if(!workOrderIds.isEmpty()) {
            Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>(WorkOrderService.getInstance().getWorkOrdersByIds(workOrderIds));            
            
            for(ServiceAppointment saObj : newAppointments) {
                WorkOrder workOrderObj = workOrderMap.get(saObj.ParentRecordId);
                if(workOrderObj.status == IN_PROGRESS && workOrderObj.Check_In__c == true && workOrderObj.Check_In_Time__c != null && workOrderObj.Check_Out__c == false) {
                    saObj.addError('You can not Re-scheduled Appintment after check In.');                    
                }               
            }
        }
    }

    public static void updateCancelledFlag(List<ServiceAppointment> Appointments, Map<Id, ServiceAppointment> saOldMap) {
        Set<Id> workOrderIds = new Set<Id>();
        WorkOrderService objWorkOrderService = WorkOrderService.getInstance();
        for(ServiceAppointment sa : Appointments) {
            if(sa.ParentRecordId != null && sa.Status != saOldMap.get(sa.Id).Status && sa.Status == CANCELED) {
                workOrderIds.add(sa.ParentRecordId);
            }
        }
                  
        if(!workOrderIds.isEmpty()) {
            List<WorkOrder> workOrdersToUpdate = objWorkOrderService.getWorkOrdersByIds(workOrderIds);
            Map<Id,Id> woIdToEntitlementIdMap = new Map<Id,Id>();
            for(WorkOrder wo : workOrdersToUpdate) {
                wo.hasappointmentcanceled__c = true; 
                wo.Cancel_Time__c = System.now();
                woIdToEntitlementIdMap.put(wo.Id, wo.EntitlementId);
                wo.ScheduledAppointmentTimeStarted__c = false;
                wo.EntitlementId = null;
            }
            objWorkOrderService.updateWorkOrders(workOrdersToUpdate);

            List<WorkOrder> woListToUpdate  = new List<WorkOrder>();
            for(Id woId : woIdToEntitlementIdMap.keySet()) {
                WorkOrder wo = new WorkOrder();
                wo.Id = woId;
                wo.EntitlementId = woIdToEntitlementIdMap.get(woId);
                woListToUpdate.add(wo);
            }  
            objWorkOrderService.updateWorkOrders(woListToUpdate);
        }
    }

    public static void onReschedule(List<ServiceAppointment> allAppointments, Map<Id, ServiceAppointment> oldMap) {
        Set<Id> workOrderIds = new Set<Id>();
        WorkOrderService objWorkOrderService = WorkOrderService.getInstance();

        for(ServiceAppointment sa : allAppointments) {
            if(sa.Status != oldMap.get(sa.Id).Status && sa.Status == COMPLETED && sa.Closure_Reason__c == RE_SCHEDULED && String.isNotBlank(sa.ParentRecordId)) {
                workOrderIds.add(sa.ParentRecordId);
            }
        }

        if(!workOrderIds.isEmpty()) {
            List<WorkOrder> workOrdersToUpdate = objWorkOrderService.getWorkOrdersByIds(workOrderIds);
            Map<Id,Id> woIdToEntitlementIdMap = new Map<Id,Id>();
            List<WorkOrder> woListToUpdate  = new List<WorkOrder>();
            List<WorkOrder> woListToUpdateTWO  = new List<WorkOrder>();

            for(WorkOrder wo : workOrdersToUpdate) {
                woIdToEntitlementIdMap.put(wo.Id, wo.EntitlementId);
                WorkOrder wrkObj = new WorkOrder();
                wrkObj.Id = wo.Id;
                wrkObj.ScheduledAppointmentTimeStarted__c = false;
                wrkObj.EntitlementId = null;
                woListToUpdate.add(wrkObj);
            }
            objWorkOrderService.updateWorkOrders(woListToUpdate);

            for(Id woId : woIdToEntitlementIdMap.keySet()) {
                WorkOrder wo = new WorkOrder();
                wo.Id = woId;
                wo.EntitlementId = woIdToEntitlementIdMap.get(woId);
                woListToUpdateTWO.add(wo);
            }  
            objWorkOrderService.updateWorkOrders(woListToUpdateTWO);
        }
    }
}