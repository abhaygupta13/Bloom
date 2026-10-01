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
public without sharing class ServiceAppointmentTriggerHelper {
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
    private static String WO_ID_PREFIX = '0WO';
    private static String SA_RESCHEDULE_NOTIF_DEV_NAME = 'Service_Appointment_Reschedule';

    public static void populateSAFieldsFromWorkOrder(List<ServiceAppointment> newServiceAppointments) {
        
        Set<Id> workOrderIds = new Set<Id>();
        Map<Id, Integer> workOrderToSAcount = new Map<Id, Integer>();
        Map<Id, WorkOrder> workOrderMap;
        
        for(ServiceAppointment sa : newServiceAppointments) {
            if(sa.ParentRecordId != null && String.valueOf(sa.ParentRecordId).startsWith(WO_ID_PREFIX)) {
                sa.Work_Order__c = sa.ParentRecordId;
                workOrderIds.add(sa.ParentRecordId);               
            }            
        }

        if(!workOrderIds.isEmpty()) {
            List<AggregateResult> groupedResults = ServiceAppointmentService.getInstance().getSACountByParentIds(workOrderIds);
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
    
    public static void sendNewFSLAppointmentNotification(List<ServiceAppointment> newList) {
        List<ServiceAppointment> newFromMobileSAs = new List<ServiceAppointment>();

        for (ServiceAppointment sa : newList) {
            if (sa.Status == DISPATCHED && sa.Created_By_DLP_Agent__c && !String.isBlank(sa.OwnerId)) {
                newFromMobileSAs.add(sa);
            }
        }

        if (newFromMobileSAs.isEmpty()) { return; }
        CustomNotificationType notification = CustomNotificationService.getInstance().getCustomNotificationTypeByName(SA_RESCHEDULE_NOTIF_DEV_NAME);
        if (notification != null) {
            for (ServiceAppointment sa: newFromMobileSAs) {
				CustomNotificationService.sendCustomNotification(new Set<String>{ sa.OwnerId }, sa.Id, notification, sa.AppointmentNumber, 'New Service Appointment is assigned to you.');
            }
        }
    }
    
    public static void validateServiceAppointmentBeforeUpdate(List<ServiceAppointment> newList, Map<Id, ServiceAppointment> oldMap) {
        isSARescheduledWhileInProgress(newList, oldMap);
        
    }
    
    private static void isSARescheduledWhileInProgress(List<ServiceAppointment> newList, Map<Id, ServiceAppointment> oldMap) {
        Set<Id> workOrderIds = new Set<Id>();
        
        for(ServiceAppointment saObj :newList) {
            if(saObj.status == IN_PROGRESS && saObj.SchedStartTime != null && saObj.SchedStartTime != oldMap.get(saObj.Id).SchedStartTime && saObj.SchedEndTime != null && saObj.SchedEndTime != oldMap.get(saObj.Id).SchedEndTime && String.isNotBlank(saObj.ParentRecordId) ) {
                workOrderIds.add(saObj.ParentRecordId);
            }
        }
        
        if(!workOrderIds.isEmpty()) {
            Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>(WorkOrderService.getInstance().getWorkOrdersByIds(workOrderIds));            
            
            for(ServiceAppointment saObj : newList) {
                WorkOrder workOrderObj = workOrderMap.get(saObj.ParentRecordId);
                if(workOrderObj.status == IN_PROGRESS && workOrderObj.Check_In__c == true && workOrderObj.Check_In_Time__c != null && workOrderObj.Check_Out__c == false) {
                    saObj.addError('You can not Re-scheduled Appintment after check In.');                    
                }               
            }
        }
    }
    
    public static void populateSAFields(List<ServiceAppointment> newList, Map<Id, ServiceAppointment> oldMap) {
        Set<Id> workOrderIds = new Set<Id>();
        for(ServiceAppointment sa : newList) {
            if(sa.ParentRecordId != null && oldMap.get(sa.Id).ParentRecordId != sa.ParentRecordId && String.valueOf(sa.ParentRecordId).startsWith(WO_ID_PREFIX)) {
                sa.Work_Order__c = sa.ParentRecordId;
                workOrderIds.add(sa.ParentRecordId);
            }
        }
        
        if(!workOrderIds.isEmpty()) {
            Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>(WorkOrderService.getInstance().getWorkOrdersByIds(workOrderIds));
            
            for(ServiceAppointment saObj : newList) {
                if(workOrderMap != null && workOrderMap.containsKey(saObj.ParentRecordId)) {
                    WorkOrder workOrderObj = workOrderMap.get(saObj.ParentRecordId);
                    saObj.WorkOrder_Unit__c = workOrderObj.Unit__c;
                    saObj.Project__c = workOrderObj.Project__c;                 
                }
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
                srvApp.Status == DISPATCHED) {                  
                    mailList.add(objEmailService.sendDLPEmail(mailTemplateContractor, workOrderObj, srvApp, new List<String>{workOrderObj.Contractor_Email__c}, contentVersionObj, orgWideEmail));
            }
            
            //Send email to customer when service appointment is created (booked).
            if(workOrderObj.New_Requester_Email__c != null && srvApp != null && mailTemplateCustomer != null && String.isNotBlank(srvApp.ParentRecordId) && String.isNotBlank(srvApp.Status) && srvApp.Status != saOldMap.get(srvApp.Id).Status && srvApp.Status == DISPATCHED) {
                mailList.add(objEmailService.sendDLPEmail(mailTemplateCustomer, workOrderObj, srvApp, new List<String>{workOrderObj.New_Requester_Email__c}, contentVersionObj, orgWideEmail));                        
            }       
            
            //Send email to owner (DLP agent) when service appointment is created (booked).
            if(String.isNotBlank(workOrderObj.Owner.Email) && srvApp != null && mailTemplateDLP != null && String.isNotBlank(srvApp.ParentRecordId) && String.isNotBlank(srvApp.Status) && srvApp.Status != saOldMap.get(srvApp.Id).Status && srvApp.Status == DISPATCHED) {                    
                mailList.add(objEmailService.sendDLPEmail(mailTemplateDLP, workOrderObj, srvApp, new List<String>{workOrderObj.Owner.Email}, contentVersionObj, orgWideEmail));
            }
            
            //Send email to contractor when service appointment is rescheduled.
            if(String.isNotBlank(workOrderObj.Contractor_Email__c) && srvApp != null && rescheduledTemplateContractor != null && srvApp.SchedStartTime != null && srvApp.SchedStartTime != saOldMap.get(srvApp.Id).SchedStartTime && srvApp.SchedEndTime != null && srvApp.SchedEndTime != saOldMap.get(srvApp.Id).SchedEndTime && String.isNotBlank(srvApp.ParentRecordId) && 
                String.isNotBlank(srvApp.Status) && (srvApp.Status == DISPATCHED || srvApp.Status == NOT_CHECKED_IN)) {                  
                    mailList.add(objEmailService.sendDLPEmail(rescheduledTemplateContractor, workOrderObj, srvApp, new List<String>{workOrderObj.Contractor_Email__c}, contentVersionObj, orgWideEmail));
            }
            
            //Send email to customer when service appointment is rescheduled
            if(workOrderObj.New_Requester_Email__c != null && srvApp != null && rescheduledTemplateCustomer != null && 
                srvApp.SchedStartTime != null && srvApp.SchedStartTime != saOldMap.get(srvApp.Id).SchedStartTime && srvApp.SchedEndTime != null && 
                srvApp.SchedEndTime != saOldMap.get(srvApp.Id).SchedEndTime && String.isNotBlank(srvApp.ParentRecordId) && 
                String.isNotBlank(srvApp.Status) && (srvApp.Status == DISPATCHED || srvApp.Status == NOT_CHECKED_IN)) {
                    mailList.add(objEmailService.sendDLPEmail(rescheduledTemplateCustomer, workOrderObj, srvApp, new List<String>{workOrderObj.New_Requester_Email__c}, contentVersionObj, orgWideEmail));                        
            }       
            
            //Send email to owner (DLP agent) when service appointment is rescheduled
            if(String.isNotBlank(workOrderObj.Owner.Email) && srvApp != null && rescheduledTemplateDLP != null && 
                srvApp.SchedStartTime != null && srvApp.SchedStartTime != saOldMap.get(srvApp.Id).SchedStartTime && srvApp.SchedEndTime != null && 
                srvApp.SchedEndTime != saOldMap.get(srvApp.Id).SchedEndTime && String.isNotBlank(srvApp.ParentRecordId) && 
                String.isNotBlank(srvApp.Status) && (srvApp.Status == DISPATCHED || srvApp.Status == NOT_CHECKED_IN)) {                    
                    mailList.add(objEmailService.sendDLPEmail(rescheduledTemplateDLP, workOrderObj, srvApp, new List<String>{workOrderObj.Owner.Email}, contentVersionObj, orgWideEmail));
            } 
        }

        objEmailService.sendEmail(mailList);
    }
    
    public static void addContractor(List<ServiceAppointment> ServiceAppointmentList, Map<Id,ServiceAppointment> oldServiceAppointment) {
        AssignedResourceService objAssignedResourceService = AssignedResourceService.getInstance();
        Set<Id> workOrderIds = new Set<Id>();
        set<Id> userIds = new Set<Id>();
        Map<Id, ServiceAppointment> toConsiderSAMap = new Map<Id, ServiceAppointment>();
        for(ServiceAppointment sa: ServiceAppointmentList) {
            if(String.isNotBlank(sa.ParentRecordId) && sa.Status == SCHEDULED && sa.Status != oldServiceAppointment.get(sa.Id).Status) {
                workOrderIds.add(sa.ParentRecordId);
                toConsiderSAMap.put(sa.Id, sa);
            }
        }

        Map<Id, WorkOrder> workOrderMap = workOrderIds.isEmpty() ? new Map<Id, WorkOrder>() : new Map<Id, WorkOrder>(WorkOrderService.getInstance().getWorkOrdersByIds(workOrderIds));
       
        for(Id key : workOrderMap.keySet()) {
            userIds.add(workOrderMap.get(key).Contractor__c);
        }
        
        ServiceResourceService objServiceResourceService = ServiceResourceService.getInstance();
        List<ServiceResource> serviceResourceList = objServiceResourceService.getServiceResourcesByRelatedRecordIds(userIds);                
                       
        List<AssignedResource> assignedResourceList = new List<AssignedResource>();
        List<AssignedResource> existingARs = objAssignedResourceService.getAssignedResourcesByServiceAppointmentIds(toConsiderSAMap.keySet());
      
        Map<Id, Id> contractorAssignedMap = new Map<Id, Id>();
        if(!existingARs.isEmpty()) {     
            for(AssignedResource ar : existingARs) {
                if(ar.ServiceResource.Is_Contractor__c) {
                    contractorAssignedMap.put(ar.ServiceAppointmentId, ar.ServiceResourceId);
                }
            }
        }

        for(ServiceAppointment sa: toConsiderSAMap.values()) {
            if(serviceResourceList != null && !contractorAssignedMap.containsKey(sa.Id)) {                
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
       
        objAssignedResourceService.insertAssignedResources(assignedResourceList);
    }    
    
    public static void populateOwnerIdOnSA(List<ServiceAppointment> newList, Map<Id, ServiceAppointment> oldMap) {
        Set<Id> serviceAppointmentIds = getScheduledAppointmentIds(newList, oldMap);

        if(!serviceAppointmentIds.isEmpty()) {
            Map<Id, Id> appointmentOwnerMap = getSAIdVsOwnerIdMap(serviceAppointmentIds);

            for (ServiceAppointment sa : newList) {
                Id ownerId = appointmentOwnerMap.get(sa.Id);
                if (ownerId != null) {
                    sa.OwnerId = ownerId;
                }
            }
        }
    }

    public static void updateStatusAndOwnerIdonWorkOrder(List<ServiceAppointment> newList, Map<Id, ServiceAppointment> oldMap) {
        Set<Id> serviceAppointmentIds = getScheduledAppointmentIds(newList, oldMap);

        if (!serviceAppointmentIds.isEmpty()) {
            updateStatusAndOwnerIdonWO(serviceAppointmentIds);
        }
    }

    private static Set<Id> getScheduledAppointmentIds(List<ServiceAppointment> newList, Map<Id, ServiceAppointment> oldMap) {
        Set<Id> serviceAppointmentIds = new Set<Id>();

        for(ServiceAppointment sa : newList) {
            ServiceAppointment oldSA = oldMap.get(sa.Id);

            if (sa.ParentRecordId != null && (sa.Status == SCHEDULED || sa.Status == DISPATCHED) && oldSA.Status != sa.Status) {
                serviceAppointmentIds.add(sa.Id);
            }
        }
        return serviceAppointmentIds;
    }

    private static Map<Id, Id> getSAIdVsOwnerIdMap(Set<Id> serviceAppointmentIds) {
        List<AssignedResource> assignedResources = AssignedResourceService.getInstance().getAssignedResourcesByServiceAppointmentIds(serviceAppointmentIds);

        Set<Id> serviceResourceIds = new Set<Id>();
        Map<Id, Set<Id>> appointmentResourceMap = new Map<Id, Set<Id>>();

        for(AssignedResource ar : assignedResources) {
            if (ar.ServiceResourceId != null) {
                serviceResourceIds.add(ar.ServiceResourceId);
                if(!appointmentResourceMap.containsKey(ar.ServiceAppointmentId)) {
                	appointmentResourceMap.put(ar.ServiceAppointmentId, new Set<Id>());
                }
                appointmentResourceMap.get(ar.ServiceAppointmentId).add(ar.ServiceResourceId);
            }
        }

        if (!serviceResourceIds.isEmpty()) {
            Map<Id, ServiceResource> serviceResourceMap = new Map<Id, ServiceResource>(ServiceResourceService.getInstance().getServiceResourceByIds(serviceResourceIds));

            Map<Id, Id> appointmentOwnerMap = new Map<Id, Id>();
            for (Id appointmentId : appointmentResourceMap.keySet()) {
                Set<Id> serviceResourcesIds = appointmentResourceMap.get(appointmentId);
                
                for(Id srId: serviceResourcesIds) {
                    ServiceResource sr = serviceResourceMap.get(srId);
                    if (sr != null && !sr.Is_Contractor__c && sr.RelatedRecordId != null) {
                        appointmentOwnerMap.put(appointmentId, sr.RelatedRecordId);
                        continue;
                    }
                }
            }
            return appointmentOwnerMap;
        }

        return new Map<Id, Id>();
    }

    private static void updateStatusAndOwnerIdonWO(Set<Id> serviceAppointmentIds) {
        WorkOrderService objWorkOrderService = WorkOrderService.getInstance();

        List<ServiceAppointment> appointments = ServiceAppointmentService.getInstance().getServiceAppointmentsByIds(serviceAppointmentIds);
        Map<Id, Id> appointmentOwnerMap = getSAIdVsOwnerIdMap(serviceAppointmentIds);
        Set<Id> workOrderIds = new Set<Id>();

        Map<Id, WorkOrder> workOrdersToUpdate = new Map<Id, WorkOrder>();
        for (ServiceAppointment sa : appointments) {
            Id ownerId = appointmentOwnerMap.get(sa.Id);

            if (ownerId != null && sa.ParentRecordId != null) {
                workOrdersToUpdate.put(sa.ParentRecordId, new WorkOrder(Id = sa.ParentRecordId, OwnerId = ownerId, Status = SCHEDULED));
            }
        }

        if (!workOrdersToUpdate.isEmpty()) {
            objWorkOrderService.updateWorkOrdersWithoutTrigger(workOrdersToUpdate.values());
        }
    }
    
    public static void populateWorkTypeIdOnSA(List<ServiceAppointment> allAppointments, Map<Id, ServiceAppointment> oldMap) {
        WorkType wrkTypeObj = new WorkType();
        wrkTypeObj = WorkTypeService.getWorkTypeRecord(DLP_LABEL);
        
        for(ServiceAppointment sa : allAppointments) {
            if(sa.Status != oldMap.get(sa.Id).Status && sa.Status == SCHEDULED && oldMap.get(sa.Id).Status != DISPATCHED && String.isNotBlank(sa.ParentRecordId)) {  
                sa.Status = DISPATCHED;
                if(wrkTypeObj != null) {
                    sa.WorkTypeId = wrkTypeObj.Id;
                }
            }
        }
    }

    public static void cancelWorkOrder(List<ServiceAppointment> newList, Map<Id, ServiceAppointment> oldMap) {
        Set<Id> workOrderIds = new Set<Id>();
        WorkOrderService objWorkOrderService = WorkOrderService.getInstance();
        for(ServiceAppointment sa : newList) {
            if(sa.ParentRecordId != null && sa.Status != oldMap.get(sa.Id).Status && sa.Status == CANCELED) {
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

    public static void resetMilestoneOnWorkOrder(List<ServiceAppointment> allAppointments, Map<Id, ServiceAppointment> oldMap) {
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

    public static void sendSARescheduleNotification(List<ServiceAppointment> newList, Map<Id, ServiceAppointment> oldMap) {
        List<ServiceAppointment> rescheduledSAs   = new List<ServiceAppointment>();

        for (ServiceAppointment sa : newList) {
            ServiceAppointment oldSA = oldMap.get(sa.Id);

            Boolean isRescheduledStatus = (sa.Status == DISPATCHED || sa.Status == NOT_CHECKED_IN);
            Boolean schedStartChanged = (sa.SchedStartTime != oldSA.SchedStartTime);
            Boolean schedEndChanged = (sa.SchedEndTime   != oldSA.SchedEndTime);

            if (isRescheduledStatus && schedStartChanged && schedEndChanged) {
                rescheduledSAs.add(sa);
            }
        }

        if (rescheduledSAs.isEmpty()) { return; }
        CustomNotificationType notification = CustomNotificationService.getInstance().getCustomNotificationTypeByName(SA_RESCHEDULE_NOTIF_DEV_NAME);
        if (notification != null) {
            for (ServiceAppointment sa : rescheduledSAs) {
                if (!String.isBlank(sa.OwnerId)) {
                    CustomNotificationService.sendCustomNotification(new Set<String>{ sa.OwnerId }, sa.Id, notification, sa.AppointmentNumber, 'Your Service Appointment is Rescheduled.');
                }
            }
        }
    }
}