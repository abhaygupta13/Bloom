/*
*********************************************************
Apex Class Name    : ServiceAppointmentTriggerHelper 
Created Date       : July 15, 2024
@description       : This class is handling multipal methods of ServiceAppointment trigger.
@author            : Pavitra Chauhan
Modification Log   :
Ver   Date         : Author                               Modification
6.3  28-08-2024   : Pavitra Chauhan                      Initial Version
*********************************************************
*/
public class ServiceAppointmentTriggerHelper {
    private static String WORKORDER_CREATION_NOTIFICATION_FOR_CUSTOMER = 'WorkOrder Creation Notification for Customer';
    private static String SERVICE_APPOINTMENT_BOOKED_NOTIFICATION_FOR_CONTRACTOR = 'Service Appointment Booked Notification for Contractor';
    private static String SERVICE_APPOINTMENT_BOOKED_NOTIFICATION_FOR_DLP_AGENT = 'Service Appointment Booked Notification for DLP Agent';
    private static String WORKORDER_Rescheduled_NOTIFICATION_FOR_CUSTOMER = 'WorkOrder Rescheduled Notification for Customer';
    private static String SERVICE_APPOINTMENT_Rescheduled_NOTIFICATION_FOR_CONTRACTOR = 'Service Appointment Rescheduled Notification for Contractor';
    private static String SERVICE_APPOINTMENT_Rescheduled_NOTIFICATION_FOR_DLP_AGENT = 'Service Appointment Rescheduled Notification for DLP Agent';
    
    
    //before insert
    public static void updateFirstAppointment(List<ServiceAppointment> newServiceAppointments){
        Set<Id> workOrderIds = new Set<Id>();
        
        for (ServiceAppointment sa : newServiceAppointments) {
            if (sa.ParentRecordId != null && String.valueOf(sa.ParentRecordId).startsWith('0WO')) {
                sa.Work_Order__c = sa.ParentRecordId;
                workOrderIds.add(sa.ParentRecordId);               
            }            
        }
        System.debug('workOrderIds'+workOrderIds);
        Map<Id, Integer> workOrderToSAcount = new Map<Id, Integer>();
        if (!workOrderIds.isEmpty()) {
            List<AggregateResult> groupedResults = [
                SELECT ParentRecordId, COUNT(Id) total 
                FROM ServiceAppointment 
                WHERE ParentRecordId IN :workOrderIds
                GROUP BY ParentRecordId
            ];
            
            System.debug('groupedResults'+groupedResults);
            
            for (AggregateResult ar : groupedResults) {
                workOrderToSAcount.put((Id) ar.get('ParentRecordId'), (Integer) ar.get('total'));
            }
        }
        System.debug('workOrderToSAcount'+workOrderToSAcount);
        
        for (ServiceAppointment sa : newServiceAppointments) {
            if (sa.ParentRecordId != null && !workOrderToSAcount.containsKey(sa.ParentRecordId)) {
                sa.Is_First_Appointment__c = true;  
            }
            System.debug('sa.Is_First_Appointment__c'+sa.Is_First_Appointment__c);
        }
        updateFields(newServiceAppointments);
    }   
    
    //after insert
    public static void updateFields(List<ServiceAppointment> newList){
        Set<Id> workOrderIds = new Set<Id>();
        
        for (ServiceAppointment saObj : newList) {
            if(String.isNotBlank(saObj.ParentRecordId)){
                workOrderIds.add(saObj.ParentRecordId);
            }
        }
        
        if(workOrderIds.isEmpty()) return;
        WorkOrderService objWorkOrderService = WorkOrderService.getInstance();
        Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>(objWorkOrderService.getWorkOrdersBySetIds(workOrderIds));            
        System.debug('workOrderMap >> ' + workOrderMap);
        
        for (ServiceAppointment saObj : newList) {
            if(String.isNotBlank(saObj.ParentRecordId)){
                WorkOrder workOrderObj = workOrderMap.get(saObj.ParentRecordId);
                saObj.WorkOrder_Unit__c = workOrderObj.Unit__c;
                saObj.Project__c = workOrderObj.Project__c;                 
            }
        }
        
    }   
    
    //before update
    public static void updateWorkOrderField(List<ServiceAppointment> newList, Map<Id, ServiceAppointment> oldMap){
        for (ServiceAppointment sa : newList) {
            if (sa.ParentRecordId != null && oldMap.get(sa.Id).ParentRecordId != sa.ParentRecordId && String.valueOf(sa.ParentRecordId).startsWith('0WO')) {
                sa.Work_Order__c = sa.ParentRecordId;
            }
        }
    }       
    
    // On after upadate send mail to DLP, customer and contractor while ServiceAppointment's status getting scheduled
    /*public static void sendMailWhenServiceAppointmentScheduled(List<ServiceAppointment> scheduledAppointments, Map<Id, ServiceAppointment> saOldMap){
try{
ContentVersion contentVersionObj = new ContentVersion();
Set<Id> workOrderIds = new Set<Id>();
List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>();

for (ServiceAppointment sa : scheduledAppointments) {
if ((String.isNotBlank(sa.Status) && sa.Status != saOldMap.get(sa.Id).Status && sa.Status == Constants.SCHEDULED && String.isNotBlank(sa.ParentRecordId)) ||

(sa.SchedStartTime != null && sa.SchedStartTime != saOldMap.get(sa.Id).SchedStartTime && sa.SchedEndTime != null && 
sa.SchedEndTime != saOldMap.get(sa.Id).SchedEndTime && String.isNotBlank(sa.ParentRecordId) && String.isNotBlank(sa.Status) && sa.Status == Constants.DISPATCHED))
{
workOrderIds.add(sa.ParentRecordId);
}
}  

if(workOrderIds.isEmpty()) return;  

WorkOrderService objWorkOrderService = WorkOrderService.getInstance();
workOrderMap = new Map<Id, WorkOrder>(objWorkOrderService.getWorkOrdersBySetIds(workOrderIds));            
System.debug('workOrderMap >> ' + workOrderMap);
if(workOrderMap.isEmpty()) return;    
EmailService objEmailService = EmailService.getInstance();

EmailTemplate mailTemplateContractor = EmailUtil.getEmailTemplateByName(SERVICE_APPOINTMENT_BOOKED_NOTIFICATION_FOR_CONTRACTOR);            
EmailTemplate mailTemplateCustomer = EmailUtil.getEmailTemplateByName(WORKORDER_CREATION_NOTIFICATION_FOR_CUSTOMER);            
EmailTemplate mailTemplateDLP = EmailUtil.getEmailTemplateByName(SERVICE_APPOINTMENT_BOOKED_NOTIFICATION_FOR_DLP_AGENT); 
OrgWideEmailAddress orgWideEmail = objEmailService.getOrgWideEmailAddressByDisplayName(Constants.BLOOM_NO_REPLY_LABEL);


for(ServiceAppointment srvApp: scheduledAppointments){
WorkOrder workOrderObj = workOrderMap.get(srvApp.ParentRecordId);
System.debug('workOrderObj >> ' + workOrderObj);

System.debug('1111111111111 Contractor_Email__c >> ' + workOrderObj.Contractor_Email__c + '<< srvApp >> ' +srvApp +' << mailTemplateContractor >> ' + mailTemplateContractor);
System.debug('2222222222222 workOrderObj.New_Requester_Email__c >> ' + workOrderObj.New_Requester_Email__c + '<< mailTemplateCustomer >> ' +mailTemplateCustomer);
System.debug('3333333333333 workOrderObj.Owner.Email >> ' + workOrderObj.Owner.Email + '<< mailTemplateDLP >> ' +mailTemplateDLP);

//Send email to contractor when service appointment is created (booked).
if(String.isNotBlank(workOrderObj.Contractor_Email__c) && srvApp != null && mailTemplateContractor != null){                  
mailList.add(DLPEmailHandler.sendEmailProcess(mailTemplateContractor, workOrderObj, srvApp, new List<String>{workOrderObj.Contractor_Email__c}, contentVersionObj, orgWideEmail));
System.debug('1. mailList not null >> ' + mailList);                
}
System.debug('1a. mailList not null >> ' + mailList);         

//Send email to customer when service appointment is created (booked).
if(workOrderObj.New_Requester_Email__c != null && srvApp != null && mailTemplateCustomer != null){
mailList.add(DLPEmailHandler.sendEmailProcess(mailTemplateCustomer, workOrderObj, srvApp, new List<String>{workOrderObj.New_Requester_Email__c}, contentVersionObj, orgWideEmail));                        
System.debug('2. mailList not null >> ' +mailList);
}       
System.debug('2a. mailList not null >> ' + mailList);

//Send email to owner (DLP agent) when service appointment is created (booked).
if(String.isNotBlank(workOrderObj.Owner.Email) && srvApp != null && mailTemplateDLP != null){                    
mailList.add(DLPEmailHandler.sendEmailProcess(mailTemplateDLP, workOrderObj, srvApp, new List<String>{workOrderObj.Owner.Email}, contentVersionObj, orgWideEmail));
System.debug('4. mailList not null >> ' + mailList );                
}
System.debug('4a. mailList not null >> ' + mailList );                

}



for (Messaging.SingleEmailMessage mail : mailList) {
// Get the list of ToAddresses
List<String> toAddresses = mail.getToAddresses();

// Print each ToAddress
if (toAddresses != null && !toAddresses.isEmpty()) {
for (String address : toAddresses) {
System.debug('ToAddress: ' + address);
}
} else {
System.debug('No ToAddresses found for this email.');
}
}
System.debug('mailList >> ' + mailList);
if(!mailList.isEmpty()){
List<Messaging.SendEmailResult> results = objEmailService.sendEmail(mailList);
System.debug('mailList results >> ' + results);
}
}catch(Exception ex){
System.debug('Exception type caught: ' + ex.getTypeName());    
System.debug('Message: ' + ex.getMessage());    
System.debug('Cause: ' + ex.getCause());    
System.debug('Line number: ' + ex.getLineNumber());    
System.debug('Stack trace: ' + ex.getStackTraceString());

}

}*/
    public static void sendMailWhenServiceAppointmentScheduled(List<ServiceAppointment> scheduledAppointments, Map<Id, ServiceAppointment> saOldMap){
        try{
            ContentVersion contentVersionObj = new ContentVersion();
            Set<Id> workOrderIds = new Set<Id>();
            List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
            Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>();
            
            for (ServiceAppointment sa : scheduledAppointments) {
                if( sa.ParentRecordId != null){
                    workOrderIds.add(sa.ParentRecordId);
                }
            }  
            
            if(workOrderIds.isEmpty()) return;  
            WorkOrderService objWorkOrderService = WorkOrderService.getInstance();
            workOrderMap = new Map<Id, WorkOrder>(objWorkOrderService.getWorkOrdersBySetIds(workOrderIds));            
            System.debug('workOrderMap >> ' + workOrderMap);
            if(workOrderMap.isEmpty()) return;    
            EmailService objEmailService = EmailService.getInstance();
            
            EmailTemplate mailTemplateContractor = EmailUtil.getEmailTemplateByName(SERVICE_APPOINTMENT_BOOKED_NOTIFICATION_FOR_CONTRACTOR);            
            EmailTemplate mailTemplateCustomer = EmailUtil.getEmailTemplateByName(WORKORDER_CREATION_NOTIFICATION_FOR_CUSTOMER);            
            EmailTemplate mailTemplateDLP = EmailUtil.getEmailTemplateByName(SERVICE_APPOINTMENT_BOOKED_NOTIFICATION_FOR_DLP_AGENT);
            EmailTemplate rescheduledTemplateContractor = EmailUtil.getEmailTemplateByName(SERVICE_APPOINTMENT_Rescheduled_NOTIFICATION_FOR_CONTRACTOR);            
            EmailTemplate rescheduledTemplateCustomer = EmailUtil.getEmailTemplateByName(WORKORDER_Rescheduled_NOTIFICATION_FOR_CUSTOMER);            
            EmailTemplate rescheduledTemplateDLP = EmailUtil.getEmailTemplateByName(SERVICE_APPOINTMENT_Rescheduled_NOTIFICATION_FOR_DLP_AGENT);
            
            OrgWideEmailAddress orgWideEmail = objEmailService.getOrgWideEmailAddressByDisplayName(Constants.BLOOM_NO_REPLY_LABEL);
            
            
            for(ServiceAppointment srvApp: scheduledAppointments){
                WorkOrder workOrderObj = workOrderMap.get(srvApp.ParentRecordId);
                System.debug('workOrderObj >> ' + workOrderObj);
                System.debug('1111111111111 Contractor_Email__c >> ' + workOrderObj.Contractor_Email__c + '<< srvApp >> ' +srvApp +' << mailTemplateContractor >> ' + mailTemplateContractor);
                System.debug('2222222222222 workOrderObj.New_Requester_Email__c >> ' + workOrderObj.New_Requester_Email__c + '<< mailTemplateCustomer >> ' +mailTemplateCustomer);
                System.debug('3333333333333 workOrderObj.Owner.Email >> ' + workOrderObj.Owner.Email + '<< mailTemplateDLP >> ' +mailTemplateDLP);
                
                //Send email to contractor when service appointment is created (booked).
                if(String.isNotBlank(workOrderObj.Contractor_Email__c) && srvApp != null && mailTemplateContractor != null &&
                   String.isNotBlank(srvApp.ParentRecordId) && String.isNotBlank(srvApp.Status) && srvApp.Status != saOldMap.get(srvApp.Id).Status &&
                   srvApp.Status == Constants.SCHEDULED){                  
                       mailList.add(DLPEmailHandler.sendEmailProcess(mailTemplateContractor, workOrderObj, srvApp, new List<String>{workOrderObj.Contractor_Email__c}, contentVersionObj, orgWideEmail));
                       System.debug('1. mailList not null >> ' + mailList);                
                   }
                System.debug('1a. mailList not null >> ' + mailList);         
                
                //Send email to customer when service appointment is created (booked).
                if(workOrderObj.New_Requester_Email__c != null && srvApp != null && mailTemplateCustomer != null && String.isNotBlank(srvApp.ParentRecordId) && String.isNotBlank(srvApp.Status) && srvApp.Status != saOldMap.get(srvApp.Id).Status && srvApp.Status == Constants.SCHEDULED){
                    mailList.add(DLPEmailHandler.sendEmailProcess(mailTemplateCustomer, workOrderObj, srvApp, new List<String>{workOrderObj.New_Requester_Email__c}, contentVersionObj, orgWideEmail));                        
                    System.debug('2. mailList not null >> ' +mailList);
                }       
                System.debug('2a. mailList not null >> ' + mailList);
                
                //Send email to owner (DLP agent) when service appointment is created (booked).
                if(String.isNotBlank(workOrderObj.Owner.Email) && srvApp != null && mailTemplateDLP != null && String.isNotBlank(srvApp.ParentRecordId) && String.isNotBlank(srvApp.Status) && srvApp.Status != saOldMap.get(srvApp.Id).Status && srvApp.Status == Constants.SCHEDULED){                    
                    mailList.add(DLPEmailHandler.sendEmailProcess(mailTemplateDLP, workOrderObj, srvApp, new List<String>{workOrderObj.Owner.Email}, contentVersionObj, orgWideEmail));
                    System.debug('4. mailList not null >> ' + mailList );                
                }
                System.debug('4a. mailList not null >> ' + mailList ); 
                
                
                //Send email to contractor when service appointment is rescheduled.
                if(String.isNotBlank(workOrderObj.Contractor_Email__c) && srvApp != null && rescheduledTemplateContractor != null && srvApp.SchedStartTime != null && srvApp.SchedStartTime != saOldMap.get(srvApp.Id).SchedStartTime && srvApp.SchedEndTime != null && srvApp.SchedEndTime != saOldMap.get(srvApp.Id).SchedEndTime && String.isNotBlank(srvApp.ParentRecordId) && 
                   String.isNotBlank(srvApp.Status) && (srvApp.Status == Constants.DISPATCHED || srvApp.Status == Constants.Not_Checked_In)){                  
                       mailList.add(DLPEmailHandler.sendEmailProcess(rescheduledTemplateContractor, workOrderObj, srvApp, new List<String>{workOrderObj.Contractor_Email__c}, contentVersionObj, orgWideEmail));
                       System.debug('1. mailList not null >> ' + mailList);                
                   }
                System.debug('1a. mailList not null >> ' + mailList);         
                
                //Send email to customer when service appointment is rescheduled
                if(workOrderObj.New_Requester_Email__c != null && srvApp != null && rescheduledTemplateCustomer != null && 
                   srvApp.SchedStartTime != null && srvApp.SchedStartTime != saOldMap.get(srvApp.Id).SchedStartTime && srvApp.SchedEndTime != null && 
                   srvApp.SchedEndTime != saOldMap.get(srvApp.Id).SchedEndTime && String.isNotBlank(srvApp.ParentRecordId) && 
                   String.isNotBlank(srvApp.Status) && (srvApp.Status == Constants.DISPATCHED || srvApp.Status == Constants.Not_Checked_In)){
                       mailList.add(DLPEmailHandler.sendEmailProcess(rescheduledTemplateCustomer, workOrderObj, srvApp, new List<String>{workOrderObj.New_Requester_Email__c}, contentVersionObj, orgWideEmail));                        
                       System.debug('2. mailList not null >> ' +mailList);
                   }       
                System.debug('2a. mailList not null >> ' + mailList);
                
                //Send email to owner (DLP agent) when service appointment is rescheduled
                if(String.isNotBlank(workOrderObj.Owner.Email) && srvApp != null && rescheduledTemplateDLP != null && 
                   srvApp.SchedStartTime != null && srvApp.SchedStartTime != saOldMap.get(srvApp.Id).SchedStartTime && srvApp.SchedEndTime != null && 
                   srvApp.SchedEndTime != saOldMap.get(srvApp.Id).SchedEndTime && String.isNotBlank(srvApp.ParentRecordId) && 
                   String.isNotBlank(srvApp.Status) && (srvApp.Status == Constants.DISPATCHED || srvApp.Status == Constants.Not_Checked_In)){                    
                       mailList.add(DLPEmailHandler.sendEmailProcess(rescheduledTemplateDLP, workOrderObj, srvApp, new List<String>{workOrderObj.Owner.Email}, contentVersionObj, orgWideEmail));
                       System.debug('4. mailList not null >> ' + mailList );                
                   }
                System.debug('4a. mailList not null >> ' + mailList );                
                
                
            }
            
            
            
            for (Messaging.SingleEmailMessage mail : mailList) {
                // Get the list of ToAddresses
                List<String> toAddresses = mail.getToAddresses();
                
                // Print each ToAddress
                if (toAddresses != null && !toAddresses.isEmpty()) {
                    for (String address : toAddresses) {
                        System.debug('ToAddress: ' + address);
                    }
                } else {
                    System.debug('No ToAddresses found for this email.');
                }
            }
            System.debug('mailList >> ' + mailList);
            if(!mailList.isEmpty()){
                List<Messaging.SendEmailResult> results = objEmailService.sendEmail(mailList);
                System.debug('mailList results >> ' + results);
            }
        }catch(Exception ex){
            System.debug('Exception type caught: ' + ex.getTypeName());    
            System.debug('Message: ' + ex.getMessage());    
            System.debug('Cause: ' + ex.getCause());    
            System.debug('Line number: ' + ex.getLineNumber());    
            System.debug('Stack trace: ' + ex.getStackTraceString());
            
        }
        
    }
    
    //after Update
    public static void addContractor(List<ServiceAppointment> ServiceAppointmentList, Map<Id,ServiceAppointment> oldServiceAppointment){
        
        Set<Id> workOrderIds = new Set<Id>();
        set<Id> userIds = new Set<Id>();
         Set<Id> saIds = new Set<Id>();
        for(ServiceAppointment sa: ServiceAppointmentList) {
            System.debug('sa.Status -- '+ sa.Status + '--' + oldServiceAppointment.get(sa.Id).Status + '--' + sa.ParentRecordId + '--'+sa.Is_First_Appointment__c );
            if(String.isNotBlank(sa.ParentRecordId)  && sa.Status != 'Completed'){
                workOrderIds.add(sa.ParentRecordId);
                 saIds.add(sa.Id);
            }
        }
        Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>();
        WorkOrderService objWorkOrderService = WorkOrderService.getInstance();
        
        //System.debug('WorkOrderService.getWorkOrdersBySetIds(workOrderIds)'+objWorkOrderService.getWorkOrdersBySetIds(workOrderIds));  
        if(objWorkOrderService.getWorkOrdersBySetIds(workOrderIds) != null){
            workOrderMap = new Map<Id, WorkOrder>(objWorkOrderService.getWorkOrdersBySetIds(workOrderIds));
        }
       
        for (Id key : workOrderMap.keySet()) {
            userIds.add(workOrderMap.get(key).Contractor__c);
            
        }
        
        ServiceResourceService objServiceResourceService = ServiceResourceService.getInstance();
        List<ServiceResource> serviceResourceList = objServiceResourceService.getServiceResourcesByRelatedRecordIds(userIds);                
                       
        List<AssignedResource> assignedResourceList = new List<AssignedResource>();
        List<AssignedResource> existingARs = [SELECT Id, ServiceAppointmentId, ServiceResourceId,ServiceResource.Is_Contractor__c  FROM AssignedResource WHERE ServiceAppointmentId IN :saIds];
      
        Map<Id, Id> contractorAssignedMap = new Map<Id, Id>();
        if(!existingARs.isEmpty()){     
            for(AssignedResource ar : existingARs) {
                if(ar.ServiceResource.Is_Contractor__c) {
                    contractorAssignedMap.put(ar.ServiceAppointmentId, ar.ServiceResourceId);
                    
                }
            }
            
        }
        for(ServiceAppointment sa: ServiceAppointmentList) {
         
            if(sa.Status == Constants.SCHEDULED && sa.Status != oldServiceAppointment.get(sa.Id).Status && serviceResourceList != null  && !contractorAssignedMap.containsKey(sa.Id) ) {                
                for(ServiceResource sr : serviceResourceList){
                    
                    if(sr.RelatedRecordId == workOrderMap.get(sa.ParentRecordId).Contractor__c){
                       
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
        if (allAppointments == null || allAppointments.isEmpty()) {
            return; 
        }
        
        Set<Id> serviceAppointmentIds = new Set<Id>();
        for (ServiceAppointment sa : allAppointments) {
            if (sa.Id != null) {// oldMap
                serviceAppointmentIds.add(sa.Id);
            }
        }
        
        if (!serviceAppointmentIds.isEmpty()) {
            updateOwner(serviceAppointmentIds);
        }
    }
    
    
    
    
    
    @future
    public static void updateOwner(Set<Id> serviceAppointmentIds) {
        ServiceAppointmentService objServiceAppointmentService = ServiceAppointmentService.getInstance(); 
        List<ServiceAppointment> serApp = objServiceAppointmentService.getServiceAppointmentsByIds(serviceAppointmentIds);
        System.debug('serApp >> ' + serApp);
        
        Set<Id> serviceAppointmentIdsSet = new Set<Id>();
        Set<Id> workOrderIds = new Set<Id>();
        
        for(ServiceAppointment sa : serApp) {  
            System.debug('sa.Status >> ' + sa.Status + ', sa.ParentRecordId >> ' + sa.ParentRecordId);
            
            if(String.isNotBlank(sa.Status) && String.isNotBlank(sa.ParentRecordId) && 
               (sa.Status == Constants.SCHEDULED || sa.Status == Constants.DISPATCHED)) 
            {
                serviceAppointmentIdsSet.add(sa.Id);
                workOrderIds.add(sa.ParentRecordId);
            }
        }
        
        System.debug('workOrderIds >> ' + workOrderIds);
        System.debug('ServiceAppointmentIds >> ' + serviceAppointmentIdsSet);
        
        if (serviceAppointmentIdsSet.isEmpty() || workOrderIds.isEmpty()) {
            return; 
        }
        
        // Get all Assigned Resources related to Service Appointments
        AssignedResourceService objAssignedResourceService = AssignedResourceService.getInstance();
        Map<Id, AssignedResource> assRes = new Map<Id, AssignedResource>(
            objAssignedResourceService.getAssignedResourcesByServiceAppointmentSetIds(serviceAppointmentIdsSet)
        );
        System.debug('assRes Map: ' + assRes);        
        
        // Collect ServiceResourceIds
        Set<Id> serviceResourceIds = new Set<Id>();
        for (AssignedResource ar : assRes.values()) {
            if (ar.ServiceResourceId != null) {
                serviceResourceIds.add(ar.ServiceResourceId);
            }           
        }
        
        // Query ServiceResource Names and Related User IDs
        
        ServiceResourceService objServiceResourceService = ServiceResourceService.getInstance();
        Map<Id, ServiceResource> serviceResourceMap = new Map<Id, ServiceResource>(
            objServiceResourceService.getServiceResourcesBySetIds(serviceResourceIds)
        );                
        System.debug('serviceResourceMap >> ' + serviceResourceMap);
        
        /* use for debug
        for (AssignedResource ar : assRes.values()) {
            String serviceResourceName = serviceResourceMap.containsKey(ar.ServiceResourceId) 
                ? serviceResourceMap.get(ar.ServiceResourceId).Name 
                : 'Unknown';
            
            System.debug('AssignedResource Id: ' + ar.Id 
                         + ' | ServiceResourceId: ' + ar.ServiceResourceId 
                         + ' | ServiceResource Name: ' + serviceResourceName
                         + ' | ServiceAppointmentId: ' + ar.ServiceAppointmentId);
        }
        */
        
        // Get all Work Orders related to the Service Appointments
        WorkOrderService objWorkOrderService = WorkOrderService.getInstance();
        Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>(
            objWorkOrderService.getWorkOrdersBySetIds(workOrderIds)
        );
        System.debug('workOrderMap >> ' + workOrderMap);
        
        Map<Id,ServiceAppointment> appointmentsToUpdate = new Map<Id,ServiceAppointment>();
        Map<Id,WorkOrder> workOrdersToUpdate = new Map<Id,WorkOrder>();
        
        for (ServiceAppointment sa : serApp) { 
            for (AssignedResource asr : assRes.Values()) {
                System.debug('serviceResourceMap.get(asr.ServiceResourceId).Is_Contractor__c -->> ' + serviceResourceMap.get(asr.ServiceResourceId).Is_Contractor__c);
                Id newOwnerId;
                if(serviceResourceMap.get(asr.ServiceResourceId).Is_Contractor__c == false){
                    newOwnerId = serviceResourceMap.get(asr.ServiceResourceId).RelatedRecordId;
                    System.debug('newOwnerId >> ' + newOwnerId); 
                    if (newOwnerId != null) {
                        sa.OwnerId = newOwnerId; // Update Service Appointment Owner
                        appointmentsToUpdate.put(sa.Id,sa);
                        
                        WorkOrder workOrder = workOrderMap.get(sa.ParentRecordId);
                        if (workOrder != null) {
                            workOrder.OwnerId = newOwnerId; // Update Work Order Owner
                            workOrder.Status = Constants.SCHEDULED;
                            workOrdersToUpdate.put(workOrder.Id, workOrder);
                        }
                    }
                    
                }
                
            }            
        }
        
        System.debug('workOrdersToUpdate >> ' + workOrdersToUpdate);        
        System.debug('appointmentsToUpdate >> ' + appointmentsToUpdate);
        
        // Perform updates safely
        if (!workOrdersToUpdate.isEmpty()) { 
            objWorkOrderService.updateWorkOrdersWithoutTrigger(workOrdersToUpdate.values());
        }
        if (!appointmentsToUpdate.isEmpty()) {
            objServiceAppointmentService.updateServiceAppointmentsWithoutTrigger(appointmentsToUpdate.values());
        }               
    }
    
    //after Update
    public static void statusUpdate(List<ServiceAppointment> allAppointments, Map<Id, ServiceAppointment> oldMap) {
        try {
            WorkType wrkTypeObj = new WorkType();
            if (WorkTypeService.getWorkTypeRecord(Constants.DLP_LABEL) != null) {
                wrkTypeObj = WorkTypeService.getWorkTypeRecord(Constants.DLP_LABEL);
            }
            
            List<ServiceAppointment> appointmentsToUpdate = new List<ServiceAppointment>();
            
            for (ServiceAppointment sa : allAppointments) {
                System.debug('sa.Status >> ' + sa.Status + ' << oldMap Status >> ' + oldMap.get(sa.Id).Status);
                if (String.isNotBlank(sa.Status) && sa.Status != oldMap.get(sa.Id).Status && sa.Status == Constants.SCHEDULED && oldMap.get(sa.Id).Status != 'Dispatched' && 
                    String.isNotBlank(sa.ParentRecordId)) {
                        
                        ServiceAppointment srv = new ServiceAppointment(Id = sa.Id);
                        srv.Status = 'Dispatched';
                        if (wrkTypeObj != null) {
                            srv.WorkTypeId = wrkTypeObj.Id;
                        }
                        appointmentsToUpdate.add(srv);
                    }
            }
            
            System.debug('appointmentsToUpdate: >> ' + appointmentsToUpdate); 
            if (!appointmentsToUpdate.isEmpty()) {
                ServiceAppointmentService objServiceAppointmentService = ServiceAppointmentService.getInstance();
                appointmentsToUpdate = objServiceAppointmentService.updateServiceAppointmentsWithoutTrigger(appointmentsToUpdate);
            }
        } catch (DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
    }
    
    
    //after Update
    public static void throwErrorOnUpdate(List<ServiceAppointment> newAppointments, Map<Id, ServiceAppointment> oldMap) {
        Set<Id> workOrderIds = new Set<Id>();
        
        for(ServiceAppointment saObj :newAppointments){
            if(saObj.status == 'In Progress' && saObj.SchedStartTime != null && saObj.SchedStartTime != oldMap.get(saObj.Id).SchedStartTime && saObj.SchedEndTime != null && saObj.SchedEndTime != oldMap.get(saObj.Id).SchedEndTime && String.isNotBlank(saObj.ParentRecordId) ){
                workOrderIds.add(saObj.ParentRecordId);
            }
        }
        
        if(workOrderIds.isEmpty()) return;
        WorkOrderService objWorkOrderService = WorkOrderService.getInstance();
        Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>(objWorkOrderService.getWorkOrdersBySetIds(workOrderIds));            
        System.debug('workOrderMap >> ' + workOrderMap);
        
        for (ServiceAppointment saObj : newAppointments) {
            if(String.isNotBlank(saObj.ParentRecordId)){
                WorkOrder workOrderObj = workOrderMap.get(saObj.ParentRecordId);
                if(workOrderObj.status == Constants.IN_PROGRESS && workOrderObj.Check_In__c == true && workOrderObj.Check_In_Time__c != null && workOrderObj.Check_Out__c == false){
                    saObj.addError('You can not Re-scheduled Appintment after check In.');                    
                }               
            }
        }
        
    }
    public static void updateCancelledFlag(List<ServiceAppointment>Appointments, Map<Id, ServiceAppointment> saOldMap){
        Set<Id> workOrderIds = new Set<Id>();  
        WorkOrderService objWorkOrderService = WorkOrderService.getInstance();         
        for (ServiceAppointment sa : Appointments) {
            if(sa.ParentRecordId != null && sa.Status != saOldMap.get(sa.Id).Status && sa.Status=='Canceled') {
                workOrderIds.add(sa.ParentRecordId);
            }
        }
                  
        if(workOrderIds != NULL && workOrderIds.size() > 0){
            List<WorkOrder> workOrdersToUpdate = objWorkOrderService.getWorkOrdersBySetIds(workOrderIds); //[SELECT Id,hasappointmentcanceled__c,Cancel_Time__c, EntitlementId FROM WorkOrder WHERE Id IN :workOrderIds];
            Map<Id,Id> woIdToEntitlementIdMap = new Map<Id,Id>();
            for (WorkOrder wo : workOrdersToUpdate) {
                wo.hasappointmentcanceled__c = true; 
                wo.Cancel_Time__c = system.now();
                woIdToEntitlementIdMap.put(wo.Id, wo.EntitlementId);
                wo.ScheduledAppointmentTimeStarted__c = false;
                wo.EntitlementId = null;
            }
            objWorkOrderService.updateWorkOrdersWithTrigger(workOrdersToUpdate);

            List<WorkOrder> woListToUpdate  = new List<WorkOrder>();
            for(Id woId : woIdToEntitlementIdMap.keySet()){
                WorkOrder wo = new WorkOrder();
                wo.Id = woId;
                wo.EntitlementId = woIdToEntitlementIdMap.get(woId);
                woListToUpdate.add(wo);
            }  
            objWorkOrderService.updateWorkOrdersWithTrigger(woListToUpdate);
        }
    }

    public static void onReschedule(List<ServiceAppointment> allAppointments, Map<Id, ServiceAppointment> oldMap) {
        Set<Id> workOrderIds = new Set<Id>();
        WorkOrderService objWorkOrderService = WorkOrderService.getInstance();
        try {
            
            for (ServiceAppointment sa : allAppointments) {
                if (String.isNotBlank(sa.Status) && sa.Status != oldMap.get(sa.Id).Status && sa.Status == 'Completed' && sa.Closure_Reason__c == 'Re Scheduled' && 
                    String.isNotBlank(sa.ParentRecordId)) {
                    workOrderIds.add(sa.ParentRecordId);
                }
            }
            if(workOrderIds != NULL && workOrderIds.size() > 0){
                List<WorkOrder> workOrdersToUpdate = objWorkOrderService.getWorkOrdersBySetIds(workOrderIds);
                Map<Id,Id> woIdToEntitlementIdMap = new Map<Id,Id>();
                /*for (WorkOrder wo : workOrdersToUpdate) {
                    woIdToEntitlementIdMap.put(wo.Id, wo.EntitlementId);
                    wo.ScheduledAppointmentTimeStarted__c = false;
                    wo.EntitlementId = null;
                }
                
                objWorkOrderService.updateWorkOrdersWithTrigger(workOrdersToUpdate);

                List<WorkOrder> woListToUpdate  = new List<WorkOrder>();
                for(Id woId : woIdToEntitlementIdMap.keySet()){
                    WorkOrder wo = new WorkOrder();
                    wo.Id = woId;
                    wo.EntitlementId = woIdToEntitlementIdMap.get(woId);
                    woListToUpdate.add(wo);
                }  
                objWorkOrderService.updateWorkOrdersWithTrigger(woListToUpdate); */

                List<WorkOrder> woListToUpdate  = new List<WorkOrder>();
                List<WorkOrder> woListToUpdateTWO  = new List<WorkOrder>();

                for(WorkOrder wo : workOrdersToUpdate){
                    woIdToEntitlementIdMap.put(wo.Id, wo.EntitlementId);
                    WorkOrder wrkObj = new WorkOrder();
                    wrkObj.Id = wo.Id;
                    wrkObj.ScheduledAppointmentTimeStarted__c = false;
                    wrkObj.EntitlementId = null;
                    woListToUpdate.add(wrkObj);
                }
                objWorkOrderService.updateWorkOrdersWithTrigger(woListToUpdate);

                for(Id woId : woIdToEntitlementIdMap.keySet()){
                    WorkOrder wo = new WorkOrder();
                    wo.Id = woId;
                    wo.EntitlementId = woIdToEntitlementIdMap.get(woId);
                    woListToUpdateTWO.add(wo);
                }  
                objWorkOrderService.updateWorkOrdersWithTrigger(woListToUpdateTWO);
            }
        } catch (DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
    }
}