/*
*********************************************************
Apex Class Name    : ServiceAppointmentController
Created Date       : July 15, 2024
@description       : This is class is used for....
@author            : Pavitra Chauhan
Modification Log   :
Ver   Date         : Author                               Modification
3.1   28-08-2024   : Pavitra Chauhan                      Initial Version
*********************************************************
*/

public without sharing class ServiceAppointmentController {
    @AuraEnabled
    public static String createServiceAppointment(DateTime startDateTime, DateTime endDateTime, String resType, Id workOrderId) {
        System.debug('Method createServiceAppointment called with parameters:');
        System.debug('startDateTime: ' + startDateTime);
        System.debug('endDateTime: ' + endDateTime);
        System.debug('resType: ' + resType);
        System.debug('workOrderId: ' + workOrderId); 
        
        WorkOrder work = [SELECT Id,Check_In__c,Check_In_Time__c,Unit__r.Name,Sub_category__c,Incident_description__c FROM WorkOrder Where Id =: workOrderId Limit 1];
        work.Check_In__c = false;
        work.Check_In_Time__c = null;
        update work;
        
        DateTime stDateTime = startDateTime;
        DateTime edDateTime = endDateTime;
        
        ServiceAppointment sa = new ServiceAppointment();
        sa.Status = Constants.NONE;
        sa.Duration = 1;  // NEW CHANGES
        sa.ParentRecordId = workOrderId;
        sa.EarliestStartTime = startDateTime;
        sa.WorkOrderSubCatagory__c = work.Sub_category__c;
        sa.Incident_description__c = work.Incident_description__c;
        //sa.SchedStartTime = stDateTime.addMinutes(1);
        //sa.SchedEndTime = edDateTime.addMinutes(-1);
        if (work.Unit__c != null && String.isNotBlank(work.Unit__r.Name)) {
            sa.Unit_Number__c = work.Unit__r.Name;
        }
        sa.SchedStartTime = stDateTime; // NEW CHANGES
        sa.SchedEndTime = edDateTime; // NEW CHANGES

        sa.DueDate = endDateTime;
        sa.Created_By_DLP_Agent__c = true;
        insert sa;
        System.debug('Inserted ServiceAppointment: ' + sa);
        
        List<ServiceAppointment> serviceAppointments = [
            SELECT Id, Status,Job_Status__c, Closure_Reason__c, Work_Order__r.Scope__c 
            FROM ServiceAppointment 
            WHERE ParentRecordId = :workOrderId 
            ORDER BY CreatedDate ASC
        ];
        System.debug('Fetched ServiceAppointments: ' + serviceAppointments);
        
        String serviceAppointmentId;
        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            System.debug('Processing ServiceAppointment: ' + serviceAppointment);
            if (serviceAppointment.Status == Constants.IN_PROGRESS && serviceAppointment.Work_Order__r.Scope__c == 'Under Scope') {
                serviceAppointmentId = serviceAppointment.Id;
                System.debug('Matching ServiceAppointment found with ID: ' + serviceAppointmentId);
                break;
            }
        }
        
        if (String.isBlank(serviceAppointmentId)) {
            System.debug('No matching ServiceAppointment found. Deleting created ServiceAppointment.');
            delete sa;
            return 'already created';
        }
        
        List<AssignedResource> assignedResource = [
            SELECT Id, ServiceResourceId, ServiceResource.Is_Contractor__c 
            FROM AssignedResource 
            WHERE ServiceAppointmentId = :serviceAppointmentId
        ];
        System.debug('Fetched AssignedResources: ' + assignedResource);
        
        List<AssignedResource> assResource = new List<AssignedResource>();
        for (AssignedResource ar : assignedResource) {
            System.debug('Processing AssignedResource: ' + ar);
            if ((ar.ServiceResource.Is_Contractor__c == false && resType == Constants.SELF) ||
                (ar.ServiceResource.Is_Contractor__c == true && resType == Constants.CONTRACTOR) || resType == 'Both') {
                    AssignedResource assRes = new AssignedResource();
                    assRes.ServiceAppointmentId = sa.Id;
                    assRes.ServiceResourceId = ar.ServiceResourceId;
                    assResource.add(assRes);
                    System.debug('Created new AssignedResource: ' + assRes);
                }
        }
        
        if (assResource.isEmpty()) {
            System.debug('No AssignedResources created. Returning empty.');
            return 'empty';
        }
        TriggerControl.bypassStatusUpdate = true;
        System.debug( System.now() + ' << TriggerControl.bypassStatusUpdate ---- >>>>' + TriggerControl.bypassStatusUpdate);
        
        insert assResource;
        System.debug('Inserted AssignedResources: ' + assResource);
        
        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            System.debug('Updating ServiceAppointment: ' + serviceAppointment);
            
            if (serviceAppointment.Status == Constants.NONE) {
                serviceAppointment.Status = 'Scheduled';
            }
            if (serviceAppointment.Status == Constants.IN_PROGRESS) {
                serviceAppointment.Status = 'Completed';
                serviceAppointment.Job_Status__c= Constants.Schedule_Appointment;
                serviceAppointment.Closure_Reason__c = 'Re Scheduled';
            } 
        }
        System.debug('first Update ServiceAppointment: ' + serviceAppointments);
        
        
        try {           
            ServiceAppointmentService objServiceAppointmentService = ServiceAppointmentService.getInstance();
            serviceAppointments = objServiceAppointmentService.updateServiceAppointmentsWithoutTrigger(serviceAppointments);
            System.debug('after Update ServiceAppointment: ' + serviceAppointments);
            for (ServiceAppointment serviceAppointment : serviceAppointments) {
                if (serviceAppointment.Status == 'Scheduled') {
                    serviceAppointment.Status = 'Dispatched';
                }                
            }
            System.debug('second Update ServiceAppointment: ' + serviceAppointments);
            update serviceAppointments;
        } catch (DmlException e) {
            System.debug('Error updating ServiceAppointments: ' + e.getMessage());
            throw new AuraHandledException('Failed to update ServiceAppointment: ' + e.getMessage());
        } finally {
            TriggerControl.bypassStatusUpdate = false; 
        }       
     
        return 'Success';
    }
    
    
    @AuraEnabled
    public static String checkIn(String contentDocumentId, String customerAvailablity, String agentComments, Id workOrderId) {
        System.debug(contentDocumentId + '<<== customerAvailablity ==>> ' + customerAvailablity + '<== workOrderId ==> ' + workOrderId);
        
        WorkOrder wo = new WorkOrder();
        wo.Id = workOrderId;
        wo.Customer_Absence_Image_Id__c = contentDocumentId;
        wo.Customer_Availability__c = customerAvailablity;
        wo.Status = Constants.IN_PROGRESS;
        wo.AgentsComments__c = agentComments;
        wo.Check_In__c = true;
        wo.Check_In_Time__c	= System.now();
        System.debug( ' wo ==>> ' + wo);
        
        WorkOrderService objWorkOrderService = WorkOrderService.getInstance();
        String entitlementRecordId = '';
        if(customerAvailablity == 'Not Available'){
            entitlementRecordId = objWorkOrderService.getWorkOrdersBySetIds(new Set<Id>{workOrderId})[0].EntitlementId;
            System.debug( ' entitlementRecordId ==>> ' + entitlementRecordId);
            wo.ScheduledAppointmentTimeStarted__c = false;
            wo.EntitlementId = null;
        }
        List<WorkOrder> updatedWo = objWorkOrderService.updateWorkOrdersWithTrigger(new List<WorkOrder>{wo});
        System.debug( ' updatedWo ==>> ' + updatedWo);
        ServiceAppointment serviceAppointments = [Select Id, Status,Job_Status__c, Closure_Reason__c From ServiceAppointment where ParentRecordId =: workOrderId ORDER BY CreatedDate DESC Limit 1];
       List<WorkOrder>workOrderList = objWorkOrderService.getWorkOrdersBySetIds(new Set<Id>{workOrderId});
       System.debug( ' workOrderList ==>> ' + workOrderList[0].Due_Date__c);
        if(customerAvailablity == 'Not Available'){
            //step by step
            //serviceAppointments.Status = 'In Progress';
            serviceAppointments.Check_in_time__c =  System.now();
            //update serviceAppointments;
            //step by step
            serviceAppointments.Status = 'Completed';
            serviceAppointments.Closure_Reason__c = 'Customer not available';
            serviceAppointments.Job_Status__c = Constants.CHECK_IN;
            update serviceAppointments;
            wo.EntitlementId = entitlementRecordId;
            List<WorkOrder> updatedWorkOrders = objWorkOrderService.updateWorkOrdersWithTrigger(new List<WorkOrder>{wo});
        }else if(customerAvailablity == 'Available'){
            serviceAppointments.Status = 'In Progress';
            serviceAppointments.Check_in_time__c =  System.now();
             serviceAppointments.Job_Status__c = Constants.CHECK_IN;
           
            update serviceAppointments;
            for(WorkOrder workobj: workOrderList){
                if(workobj.Due_Date__c==null){
                    updateDueDate(New List<WorkOrder>{workobj});  
                }
            }
        }
        
        return 'Success';
    }
      public static void updateDueDate(List<WorkOrder>workOrderList) {
        Map<String, DLP_Resolution_Settings__mdt> metadataMap = new Map<String, DLP_Resolution_Settings__mdt>();
        for (DLP_Resolution_Settings__mdt meta : [SELECT Resolution_Priority__c, Repair_Resolution__c,Is_Business_Hours__c,Business_Hours_Id__c,Repair_Resolution_SLA_Type__c, Replace_Resolution__c, Replace_Resolution_SLA_Type__c
                                                  FROM DLP_Resolution_Settings__mdt]){
                                                      metadataMap.put(meta.Resolution_Priority__c, meta);
                                                  }
        
        List<WorkOrder> updatedWorkOrders = new List<WorkOrder>();

        for (WorkOrder wo : workOrderList) {
          System.debug('metadataMap'+workOrderList);
            if (wo.Resolution_Typology__c != null) {
                                    WorkOrder updatedWO = new WorkOrder();
                                    updatedWO.id = wo.Id;
                
                                    if (metadataMap.containsKey(wo.Resolution_Priority__c)) {
                                         DLP_Resolution_Settings__mdt meta = metadataMap.get(wo.Resolution_Priority__c);
                                        if(meta.Is_Business_Hours__c == false){
                                            if (wo.Resolution_Typology__c == Constants.REPAIR) {
                                                if(meta.Repair_Resolution_SLA_type__c == Constants.HOURS){
                                                    updatedWO.Due_Date__c = System.now().addHours(Integer.valueOf(meta.Repair_Resolution__c)).format(); 
                                                }
                                                else{
                                                    updatedWO.Due_Date__c = System.now().addDays(Integer.valueOf(meta.Repair_Resolution__c)).format();
                                                }
                                            } else if (wo.Resolution_Typology__c == Constants.REPLACE) {
                                                if(meta.Replace_Resolution_SLA_type__c == Constants.HOURS){
                                                    updatedWO.Due_Date__c = System.now().addHours(Integer.valueOf(meta.Replace_Resolution__c)).format(); 
                                                }
                                                else{
                                                    updatedWO.Due_Date__c = System.now().addDays(Integer.valueOf(meta.Replace_Resolution__c)).format();
                                                }
                                            }
                                            updatedWorkOrders.add(updatedWO);
                                        } 
                                        else{
                                            if(wo.Resolution_Typology__c == Constants.REPAIR){
                                                if (meta.Repair_Resolution_SLA_type__c == Constants.HOURS){
                                                    updatedWO.Due_Date__c = String.valueOf(BusinessHours.add(
                                                        meta.Business_Hours_Id__c, System.now(), 
                                                        Integer.valueOf(meta.Repair_Resolution__c)*60*60*1000).format());
                                                }
                                                else{
                                                    updatedWO.Due_Date__c = String.valueOf(BusinessHours.add(
                                                        meta.Business_Hours_Id__c,System.now(), 
                                                        Integer.valueOf(meta.Repair_Resolution__c)*24*60*60*1000).format());
                                                }
                                            }
                                            else if(wo.Resolution_Typology__c == Constants.REPLACE){
                                                if (meta.Replace_Resolution_SLA_type__c == Constants.HOURS){
                                                    updatedWO.Due_Date__c = String.valueOf(BusinessHours.add(
                                                        meta.Business_Hours_Id__c, System.now(), 
                                                        Integer.valueOf(meta.Replace_Resolution__c)*60*60*1000).format());
                                                }
                                                else{
                                                    updatedWO.Due_Date__c = String.valueOf(BusinessHours.add(
                                                        meta.Business_Hours_Id__c,System.now(), 
                                                        Integer.valueOf(meta.Replace_Resolution__c)*24*60*60*1000).format());
                                                }
                                            }
                                            updatedWorkOrders.add(updatedWO);
                                        }
                                    }
                                }
        }
        
        if (!updatedWorkOrders.isEmpty()) {
            WorkOrderService objWorkOrderService = WorkOrderService.getInstance();
            objWorkOrderService.updateWorkOrdersWithoutTrigger(updatedWorkOrders);
        }
     }
  
    
    @AuraEnabled
    public static String checkScope(String contentDocumentId, String agentComments, String scope, Id workOrderId, String resolutionTypology) {
        System.debug(workOrderId + ' scope >> ' + scope +  ' resolutionTypology >> ' + resolutionTypology);
        WorkOrderService objWorkOrderService = WorkOrderService.getInstance();
        ServiceAppointment serviceAppointments = [Select Id, Status,Job_Status__c, Closure_Reason__c From ServiceAppointment where ParentRecordId =: workOrderId ORDER BY CreatedDate DESC Limit 1];

        WorkOrder wo = new WorkOrder();
        wo.Id = workOrderId;
        String entitlementRecordId = '';
        if(scope == Constants.OUTSIDE_SCOPE) {
            entitlementRecordId = objWorkOrderService.getWorkOrdersBySetIds(new Set<Id>{workOrderId})[0].EntitlementId;
            System.debug( ' entitlementRecordId ==>> ' + entitlementRecordId);
            wo.ScheduledAppointmentTimeStarted__c = false;
            wo.EntitlementId = null; 
            List<WorkOrder> updatedWoList = objWorkOrderService.updateWorkOrdersWithTrigger(new List<WorkOrder>{wo});
        }
        // wo.Customer_Absence_Image_Id__c = contentDocumentId;
        if(scope == Constants.OUTSIDE_SCOPE){
            wo.Status = Constants.CLOSED;
            wo.AgentsComments__c = agentComments;
            wo.Type_of_Incident__c = Constants.OUT_OF_SCOPE; 
            wo.Closure_Reason__c = Constants.OUT_OF_SCOPE; // NEW CHANGES
            wo.Closure_Comment__c = Constants.OUT_OF_SCOPE; // NEW CHANGES   
            wo.EntitlementId = entitlementRecordId;
        }else if(scope == Constants.UNDER_SCOPE){
            wo.Rectification__c = Constants.PENDING;
            wo.Scope__c = Constants.UNDER_SCOPE; //scope;
            if(String.isNotBlank(resolutionTypology)){ // NEW CHANGES
                wo.Resolution_Typology__c = resolutionTypology;
            }
            serviceAppointments.Job_Status__c= Constants.UNDER_SCOPE;
            update serviceAppointments;
        }
        System.debug(' wo ==>> ' + wo); 
        
        List<WorkOrder> updatedWo = objWorkOrderService.updateWorkOrdersWithTrigger(new List<WorkOrder>{wo});
        
        if(scope == Constants.OUTSIDE_SCOPE) {
            WorkOrderImageController.generateAndAttachPdf(workOrderId); 
        }
        // Update ServiceAppointment
        /*if(scope == Constants.OUTSIDE_SCOPE){
            ServiceAppointment serviceAppointments = [Select Id, Status, Closure_Reason__c From ServiceAppointment where ParentRecordId =: workOrderId ORDER BY CreatedDate DESC Limit 1];
            
            if(serviceAppointments.Status != 'In Progress'){
                serviceAppointments.Status = 'In Progress';
                update serviceAppointments;
            }
            if(serviceAppointments.Status != 'Completed'){
                serviceAppointments.Closure_Reason__c = 'Out of Scope';
                serviceAppointments.Status = 'Completed';
                update serviceAppointments;
            }
        }*/
       
        
        return Constants.SUCCESS;       
        
    }
    
    @AuraEnabled
    public static String checkRectification(String contentDocumentId, String agentComments, Id workOrderId) {
         ServiceAppointment serviceAppointments = [Select Id, Status, Job_Status__c From ServiceAppointment where ParentRecordId =: workOrderId ORDER BY CreatedDate DESC Limit 1];

        WorkOrder wo = new WorkOrder();
        wo.Id = workOrderId;
        // wo.Customer_Absence_Image_Id__c = contentDocumentId;
        wo.Rectification__c = Constants.COMPLETED_LABEL;
        wo.AgentsComments__c = agentComments;
        //update wo;
        WorkOrderService objWorkOrderService = WorkOrderService.getInstance(); 
        List<WorkOrder> updatedWo = objWorkOrderService.updateWorkOrdersWithTrigger(new List<WorkOrder>{wo});
         serviceAppointments.Job_Status__c= Constants.After_Rectification;
        update serviceAppointments;
        return 'Success'; 
    }
    
    @AuraEnabled
    public static String checkOut(String rating, String comment,Id workOrderId,String signedBy) {
        ServiceAppointment serviceAppointments = [Select Id, Status,Job_Status__c, Closure_Reason__c From ServiceAppointment where ParentRecordId =: workOrderId ORDER BY CreatedDate DESC Limit 1];
        if(serviceAppointments.Status == 'Completed'){
            return 'Already checked out';
        }
        /*if(serviceAppointments.Status == 'Dispatched'){
return 'Already Work order Completed';
}*/
        WorkOrder wo = new WorkOrder();
        wo.Id = workOrderId;
        wo.Customer_Comment__c = comment;
        wo.Rating__c = rating;
        wo.Signed_By__c = signedBy;
        wo.Closure_Comment__c = Constants.WORK_COMPLETED;
        wo.Closure_Reason__c = Constants.WORK_COMPLETED;
        WorkOrderService objWorkOrderService = WorkOrderService.getInstance();
        List<WorkOrder> updatedWo = objWorkOrderService.updateWorkOrdersWithTrigger(new List<WorkOrder>{wo});        
            serviceAppointments.Job_Status__c =Constants.Check_Out;
         update serviceAppointments;
        /*if(serviceAppointments.Status != Constants.IN_PROGRESS){
            serviceAppointments.Status = Constants.IN_PROGRESS;
            update serviceAppointments;
        }
        if(serviceAppointments.Status != 'Completed' && serviceAppointments.Status == Constants.IN_PROGRESS && serviceAppointments.Status != 'Dispatched'){
            serviceAppointments.Status = 'Completed';
            serviceAppointments.Closure_Reason__c = 'Work Closed';
            update serviceAppointments;
        }
        else{
            return 'Already ';
        }*/
        
        return 'Success';        
    }  
    
    @InvocableMethod
    public static void createServiceAppointmentWhenCustomerNotAvailable(List<String> workOrderIds){
        ServiceAppointment saObj = [SELECT Id,Job_Status__c, Status FROM ServiceAppointment WHERE ParentRecordId IN :workOrderIds ORDER BY CreatedDate DESC LIMIT 1];
        System.debug('saObj ==>> ' + saObj);
        //for(ServiceAppointment saObj: SAlist){
        if(String.isNotBlank(saObj.Status) && saObj.Status != Constants.NONE){
            
            //return null;
            
            //}
            
            Set<Id> workOrderIdSet = new Set<Id>();
            for (String workOrderId : workOrderIds) {
                workOrderIdSet.add(Id.valueOf(workOrderId));
            }
            
            Set<Id> projectIds = new Set<Id>();
            Set<Id> unitIdSet = new Set<Id>();
            WorkOrderService objWorkOrderService = WorkOrderService.getInstance();
            List<WorkOrder> workOrders = objWorkOrderService.getWorkOrdersBySetIds(workOrderIdSet);
            List<ServiceAppointment> serviceAppointmentList = new List<ServiceAppointment>();
            
            for(workOrder wo: workOrders){
                if(String.isNotBlank(wo.Project__c)){
                    projectIds.add(wo.Project__c);                
                }
                if(String.isNotBlank(wo.Unit__c)){
                    unitIdSet.add(wo.Unit__c);                
                }
            }
            Map<Id, Unit__c> unitMap = new Map<Id, Unit__c>();
            if(UnitService.getAllUnitsById(unitIdSet) != null){
                unitMap = new Map<Id, Unit__c>(UnitService.getAllUnitsById(unitIdSet)); 
            }
            
            ServiceTerritoryService objServiceTerritoryService = ServiceTerritoryService.getInstance();
            Map<Id, ServiceTerritory> relatedStMap = new Map<Id, ServiceTerritory>();
            if(objServiceTerritoryService.getServiceTerritorysByProjectIds(projectIds) != null){
                relatedStMap = new Map<Id, ServiceTerritory>(objServiceTerritoryService.getServiceTerritorysByProjectIds(projectIds));     
            }
            Map<String, ServiceTerritory> sortedStMap2 = new Map<String, ServiceTerritory>();
            
            for(ServiceTerritory st: relatedStMap.values()){
                sortedStMap2.put(st.Project__c, st);
            }   
            
            for(workOrder wrkObj: workOrders){
                 if( wrkObj.hasappointmentcanceled__c==true){
                    wrkObj.hasappointmentcanceled__c= false;
                    wrkObj.Cancel_Time__c = null;
                }
                
                ServiceAppointment newSA = new ServiceAppointment();            
                
                if (String.isNotBlank(wrkObj.Project__c) && sortedStMap2.containsKey(wrkObj.Project__c)) {
                    newSA.ServiceTerritoryId = sortedStMap2.get(wrkObj.Project__c).Id;
                } 
                
                newSa.FSL__Emergency__c = wrkObj.Is_Emergency__c;
                newSA.ParentRecordId = wrkObj.Id;            
                newSA.WorkOrderSubCatagory__c = wrkObj.Sub_category__c;
                newSA.Status = Constants.NONE;  
                newSA.Duration = 1;  // NEW CHANGES
                newSA.Incident_description__c = wrkObj.Incident_description__c;
                newSA.EarliestStartTime = System.now();            
                newSA.DueDate = System.now().addDays(7); 
                newSa.Longitude = unitMap.get(wrkObj.Unit__c).Location__Longitude__s;
                newSa.Latitude = unitMap.get(wrkObj.Unit__c).Location__Latitude__s;
                if (String.isNotBlank(wrkObj.Unit_Number__c)) {
                  newSa.Unit_Number__c = wrkObj.Unit_Number__c;
                }
               
                if (String.isNotBlank(wrkObj.Subject)) {
                    newSA.Subject = wrkObj.Subject;
                }
                if (String.isNotBlank(wrkObj.Description)) {
                    newSA.Description = wrkObj.Description;
                }                
                serviceAppointmentList.add(newSA); 
            }      
            
            System.debug('serviceAppointmentList ==>> ' + serviceAppointmentList);
            ServiceAppointmentService objServiceAppointmentService = ServiceAppointmentService.getInstance(); 
            serviceAppointmentList = objServiceAppointmentService.insertServiceAppointmentsWithTrigger(serviceAppointmentList);
            if(workOrders.size()>0){
                update workOrders;
            }
        }
    }
    
    @AuraEnabled
    public static void saveSign(Id recordId, String strSignElement) {
        Blob decodedData = EncodingUtil.base64Decode(strSignElement);
        
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Signature';
        cv.PathOnClient = 'Signature.png';
        cv.VersionData = decodedData;
        cv.IsMajorVersion = true;
        insert cv;
        
        // Query ContentDocumentId from ContentVersion
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        cdl.LinkedEntityId = recordId; // Link to the specified record
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;
        WorkOrderImageController.generateAndAttachPdf(recordId);        
    }
    
   
    
}