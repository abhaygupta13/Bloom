/*
*********************************************************
Apex Class Name    : ServiceAppointmentController
Created Date       : July 15, 2024
@description       : This is class is used for....
@author            : Pavitra Chauhan
Modification Log   :
Ver   Date         : Author                               Modification
3.2   09-09-2026   : Abhay Gupta                          Optimised code and updating entitlementId on WO while creating new SA
*********************************************************
*/

public without sharing class ServiceAppointmentController {
    private static String ALREADY_CHECKED_OUT = 'Already checked out';
    private static String UNDER_SCOPE = 'Under Scope';
    private static String NONE = 'None';
    private static String IN_PROGRESS = 'In Progress';
    private static String SELF = 'Self';
    private static String CONTRACTOR = 'Contractor';
    private static String SCHEDULED = 'Scheduled';
    private static String COMPLETED = 'Completed';
    private static String COMPLETED_LABEL = 'Completed';
    private static String SCHEDULE_APPOINTMENT = 'Schedule Appointment';
    private static String NOT_AVAILABLE = 'Not Available';
    private static String CHECK_IN = 'Check-In';
    private static String STATUS_AVAILABLE = 'Available';
    private static String SUCCESS = 'Success';
    private static String OUTSIDE_SCOPE = 'Outside Scope';
    private static String CLOSED = 'Closed';
    private static String OUT_OF_SCOPE = 'Out of Scope';
    private static String PENDING = 'Pending';
    private static String AFTER_RECTIFICATION = 'After Rectification';
    private static String WORK_COMPLETED = 'Work Completed';
    private static String CHECK_OUT = 'Check-Out';
    private static String REPAIR = 'Repair';
    private static String REPLACE = 'Replace';
    private static String HOURS = 'Hours';

    @AuraEnabled
    public static String createServiceAppointment(DateTime startDateTime, DateTime endDateTime, String resType, Id workOrderId) {
        try {
            WorkOrderService objWorkOrderService = WorkOrderService.getInstance();
            ServiceAppointmentService objServiceAppointmentService = ServiceAppointmentService.getInstance();
            AssignedResourceService objAssignedResourceService = AssignedResourceService.getInstance();

            List<WorkOrder> woList = objWorkOrderService.getWorkOrdersByIds(new Set<Id> { workOrderId });
            WorkOrder wo = woList != null && !woList.isEmpty() ? woList[0] : null;
            if(wo == null) {
                return 'WorkOrder not found';
            }
            wo.Check_In__c = false;
            wo.Check_In_Time__c = null;
            objWorkOrderService.updateWorkOrders(new List<WorkOrder> { wo });
                    
            ServiceAppointment sa = buildServiceAppointment(wo, startDateTime, endDateTime);
            objServiceAppointmentService.insertServiceAppointments(new List<ServiceAppointment> { sa });
            
            List<ServiceAppointment> serviceAppointments = objServiceAppointmentService.getServiceAppointmentsByParentIds(new Set<Id> { workOrderId });
            
            String serviceAppointmentId;
            for (ServiceAppointment serviceAppointment : serviceAppointments) {
                if (serviceAppointment.Status == IN_PROGRESS && serviceAppointment.Work_Order__r.Scope__c == UNDER_SCOPE) {
                    serviceAppointmentId = serviceAppointment.Id;
                    break;
                }
            }
            
            if (String.isBlank(serviceAppointmentId)) {
                objServiceAppointmentService.deleteServiceAppointments(new List<ServiceAppointment> { sa });
                return 'already created';
            }
            
            List<AssignedResource> assignedResource = objAssignedResourceService.getAssignedResourcesByServiceAppointmentIds(new Set<Id> { serviceAppointmentId });
            
            List<AssignedResource> assResource = new List<AssignedResource>();
            for (AssignedResource ar : assignedResource) {
                if ((ar.ServiceResource.Is_Contractor__c == false && resType == SELF) 
                    || (ar.ServiceResource.Is_Contractor__c == true && resType == CONTRACTOR) 
                    || resType == 'Both'
                ) {
                    assResource.add(new AssignedResource(ServiceAppointmentId = sa.Id, ServiceResourceId = ar.ServiceResourceId));
                }
            }
            
            if (assResource.isEmpty()) {
                return 'empty';
            }
            TriggerControl.bypassStatusUpdate = true;
            objAssignedResourceService.insertAssignedResources(assResource);
            
            Boolean shouldUpdateEntitlementId = false;
            serviceAppointments = objServiceAppointmentService.getServiceAppointmentsByParentIds(new Set<Id> { workOrderId });
            for (ServiceAppointment serviceAppointment : serviceAppointments) {
                if (serviceAppointment.Status == NONE) {
                    serviceAppointment.Status = SCHEDULED;
                }
                if (serviceAppointment.Status == IN_PROGRESS) {
                    serviceAppointment.Status = COMPLETED;
                    serviceAppointment.Job_Status__c= SCHEDULE_APPOINTMENT;
                    serviceAppointment.Closure_Reason__c = 'Re Scheduled';
                    shouldUpdateEntitlementId = true;
                } 
            }
            
            serviceAppointments = objServiceAppointmentService.updateServiceAppointmentsWithoutTrigger(serviceAppointments);
            for (ServiceAppointment serviceAppointment : serviceAppointments) {
                if (serviceAppointment.Status == 'Scheduled') {
                    serviceAppointment.Status = 'Dispatched';
                }                
            }
            objServiceAppointmentService.updateServiceAppointments(serviceAppointments);

            if(shouldUpdateEntitlementId) {
                updateEntitlementIdOnWorkOrder(new Set<Id>{ workOrderId });
            } 
            TriggerControl.bypassStatusUpdate = false;
            return 'Success';

        } catch (Exception ex) {
            throw new AuraHandledException('Error: ' + ex.getMessage());
        }
    }

    private static ServiceAppointment buildServiceAppointment(WorkOrder wo, Datetime startDateTime, Datetime endDateTime) {
        ServiceAppointment sa = new ServiceAppointment();
        sa.Status = NONE;
        sa.Duration = 1;
        sa.ParentRecordId = wo.Id;
        sa.EarliestStartTime = startDateTime;
        sa.DueDate = endDateTime;
        sa.SchedStartTime = startDateTime;
        sa.SchedEndTime = endDateTime;
        sa.WorkOrderSubCatagory__c = wo.Sub_category__c;
        sa.Incident_description__c = wo.Incident_description__c;
        sa.Created_By_DLP_Agent__c = true;
        sa.Unit_Number__c = wo.Unit__c != null && wo.Unit__r != null && String.isNotBlank(wo.Unit__r.Name) ? wo.Unit__r.Name : null;
        return sa;
    }

    private static void updateEntitlementIdOnWorkOrder(Set<Id> woIds) {
        if (woIds == null || woIds.isEmpty()) {
            return;
        }
    
        WorkOrderService objWorkOrderService = WorkOrderService.getInstance();
        List<WorkOrder> workOrdersToUpdate = objWorkOrderService.getWorkOrdersByIds(woIds);
    
        List<WorkOrder> clearEntitlementWOList = new List<WorkOrder>();
        List<WorkOrder> restoreEntitlementWOList = new List<WorkOrder>();
        for (WorkOrder wo : workOrdersToUpdate) {
            if (wo.EntitlementId != null) {
                clearEntitlementWOList.add(new WorkOrder(Id = wo.Id, ScheduledAppointmentTimeStarted__c = false, EntitlementId = null));
                restoreEntitlementWOList.add(new WorkOrder(Id = wo.Id, EntitlementId = wo.EntitlementId));
            }
        }
    
        if (!clearEntitlementWOList.isEmpty()) {
            objWorkOrderService.updateWorkOrders(clearEntitlementWOList);
            objWorkOrderService.updateWorkOrders(restoreEntitlementWOList);
        }
    }
    
    @AuraEnabled
    public static String checkIn(String contentDocumentId, String customerAvailablity, String agentComments, Id workOrderId) {
        try {
            WorkOrderService objWorkOrderService = WorkOrderService.getInstance();
            ServiceAppointmentService objServiceAppointmentService = ServiceAppointmentService.getInstance();
            Boolean isCustomerNotAvailable = customerAvailablity == NOT_AVAILABLE;
            Datetime checkInTime = System.now();

            WorkOrder wo = buildCheckInWorkOrder(contentDocumentId, customerAvailablity, agentComments, workOrderId, checkInTime);
            
            String entitlementRecordId = '';
            if(isCustomerNotAvailable) {
                entitlementRecordId = objWorkOrderService.getWorkOrdersByIds(new Set<Id>{workOrderId})[0].EntitlementId;
                wo.ScheduledAppointmentTimeStarted__c = false;
                wo.EntitlementId = null;
            }
            objWorkOrderService.updateWorkOrders(new List<WorkOrder>{wo});

            List<ServiceAppointment> saList = objServiceAppointmentService.getSAByParentIdsOrderByCreatedDateDesc(new Set<Id>{ workOrderId });
            ServiceAppointment serviceAppointment = saList != null && !saList.isEmpty() ? saList[0] : null;

            List<WorkOrder> workOrderList = objWorkOrderService.getWorkOrdersByIds(new Set<Id>{ workOrderId });
            if(isCustomerNotAvailable) {
                processCustomerNotAvailableCheckIn(serviceAppointment, wo, entitlementRecordId);

            } else if(customerAvailablity == STATUS_AVAILABLE) {
                processCustomerAvailableCheckIn(serviceAppointment, workOrderId);
            }
            
            return SUCCESS;

        } catch (Exception ex) {
            throw new AuraHandledException('Error: ' + ex.getMessage());
        }
    }

    private static WorkOrder buildCheckInWorkOrder(String contentDocumentId, String customerAvailablity, String agentComments, Id workOrderId, Datetime checkInTime) {
        return new WorkOrder(
            Id = workOrderId,
            Customer_Absence_Image_Id__c = contentDocumentId,
            Customer_Availability__c = customerAvailablity,
            Status = IN_PROGRESS,
            AgentsComments__c = agentComments,
            Check_In__c = true,
            Check_In_Time__c = checkInTime
        );
    }

    private static void processCustomerNotAvailableCheckIn(ServiceAppointment serviceAppointment, WorkOrder wo, String entitlementRecordId) {
        serviceAppointment.Check_in_time__c = Datetime.now();
        serviceAppointment.Status = COMPLETED_LABEL;
        serviceAppointment.Closure_Reason__c = 'Customer not available';
        serviceAppointment.Job_Status__c = CHECK_IN;
        ServiceAppointmentService.getInstance().updateServiceAppointments(new List<ServiceAppointment>{serviceAppointment});

        wo.EntitlementId = entitlementRecordId;
        WorkOrderService.getInstance().updateWorkOrders(new List<WorkOrder>{wo});
    }

    private static void processCustomerAvailableCheckIn(ServiceAppointment serviceAppointment, Id workOrderId) {
        serviceAppointment.Status = IN_PROGRESS;
        serviceAppointment.Check_in_time__c = Datetime.now();
        serviceAppointment.Job_Status__c = CHECK_IN;
        ServiceAppointmentService.getInstance().updateServiceAppointments(new List<ServiceAppointment>{serviceAppointment});

        WorkOrder wo = WorkOrderService.getInstance().getWorkOrdersByIds(new Set<Id>{workOrderId})[0];
        if (wo.Due_Date__c == null) {
            updateDueDate(new List<WorkOrder>{wo});
        }
    }

    private static void updateDueDate(List<WorkOrder> workOrderList) {
        Map<String, DLP_Resolution_Settings__mdt> metadataMap = new Map<String, DLP_Resolution_Settings__mdt>();
        for (DLP_Resolution_Settings__mdt meta : MetadataService.getInstance().getDLPResolutionSettings()) {
            metadataMap.put(meta.Resolution_Priority__c, meta);
        }
        
        List<WorkOrder> updatedWorkOrders = new List<WorkOrder>();
        for (WorkOrder wo : workOrderList) {
            if (String.isBlank(wo.Resolution_Typology__c)) {
                continue;
            }
            if (metadataMap.get(wo.Resolution_Priority__c) != null) {
                String dueDate = calculateDueDate(wo, metadataMap.get(wo.Resolution_Priority__c));
                if (String.isNotBlank(dueDate)) {
                    updatedWorkOrders.add(new WorkOrder(Id = wo.Id, Due_Date__c = dueDate));
                }
            }
        }
        
        WorkOrderService.getInstance().updateWorkOrdersWithoutTrigger(updatedWorkOrders);
    }

    private static String calculateDueDate(WorkOrder wo, DLP_Resolution_Settings__mdt meta) {
        Decimal resolution;
        String slaType;

        if (wo.Resolution_Typology__c == REPAIR) {
            resolution = Integer.valueOf(meta.Repair_Resolution__c);
            slaType = meta.Repair_Resolution_SLA_Type__c;
        } else if (wo.Resolution_Typology__c == REPLACE) {
            resolution = Integer.valueOf(meta.Replace_Resolution__c);
            slaType = meta.Replace_Resolution_SLA_Type__c;
        } else {
            return null;
        }

        if (resolution == null || String.isBlank(slaType)) {
            return null;
        }

        Datetime startDateTime = System.now();
        Long milliseconds = slaType == HOURS ? (Long)(resolution * 60 * 60 * 1000) : (Long)(resolution * 24 * 60 * 60 * 1000);

        Datetime dueDateTime = meta.Is_Business_Hours__c ? BusinessHours.add(meta.Business_Hours_Id__c, startDateTime, milliseconds)
                                                        : (slaType == HOURS ? startDateTime.addHours(Integer.valueOf(resolution)) : startDateTime.addDays(Integer.valueOf(resolution)));
        return dueDateTime.format();
    }
    
    @AuraEnabled
    public static String checkScope(String contentDocumentId, String agentComments, String scope, Id workOrderId, String resolutionTypology) {
        try {
            WorkOrderService objWorkOrderService = WorkOrderService.getInstance();
            ServiceAppointmentService objServiceAppointmentService = ServiceAppointmentService.getInstance();
            List<ServiceAppointment> saList = objServiceAppointmentService.getServiceAppointmentsByParentIds(new Set<Id>{ workOrderId });
            ServiceAppointment serviceAppointment = (saList != null && !saList.isEmpty()) ? saList[0] : null;

            WorkOrder wo = new WorkOrder();
            wo.Id = workOrderId;
            String entitlementRecordId = '';
            if(scope == OUTSIDE_SCOPE) {
                entitlementRecordId = objWorkOrderService.getWorkOrdersByIds(new Set<Id>{workOrderId})[0].EntitlementId;
                wo.ScheduledAppointmentTimeStarted__c = false;
                wo.EntitlementId = null; 
                List<WorkOrder> updatedWoList = objWorkOrderService.updateWorkOrders(new List<WorkOrder>{wo});
            }

            if(scope == OUTSIDE_SCOPE) {
                wo.Status = CLOSED;
                wo.AgentsComments__c = agentComments;
                wo.Type_of_Incident__c = OUT_OF_SCOPE; 
                wo.Closure_Reason__c = OUT_OF_SCOPE;
                wo.Closure_Comment__c = OUT_OF_SCOPE;
                wo.Scope__c = OUTSIDE_SCOPE;
                wo.EntitlementId = entitlementRecordId;

            } else if(scope == UNDER_SCOPE) {
                wo.Rectification__c = PENDING;
                wo.Scope__c = UNDER_SCOPE;
                if(String.isNotBlank(resolutionTypology)) {
                    wo.Resolution_Typology__c = resolutionTypology;
                }
                serviceAppointment.Job_Status__c = UNDER_SCOPE;
                objServiceAppointmentService.updateServiceAppointments(new List<ServiceAppointment>{serviceAppointment});
            }
            
            List<WorkOrder> updatedWo = objWorkOrderService.updateWorkOrders(new List<WorkOrder>{wo});
            if(scope == OUTSIDE_SCOPE) {
                WorkOrderImageController.generateAndAttachPdf(workOrderId); 
            }

            return SUCCESS;

        } catch (Exception ex) {
            throw new AuraHandledException('Error: ' + ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static String checkRectification(String contentDocumentId, String agentComments, Id workOrderId) {
        try {
            WorkOrderService objWorkOrderService = WorkOrderService.getInstance();
            ServiceAppointmentService objServiceAppointmentService = ServiceAppointmentService.getInstance();

            WorkOrder wo = new WorkOrder();
            wo.Id = workOrderId;
            wo.Rectification__c = COMPLETED_LABEL;
            wo.AgentsComments__c = agentComments;
            List<WorkOrder> updatedWo = objWorkOrderService.updateWorkOrders(new List<WorkOrder>{ wo });

            List<ServiceAppointment> saList = objServiceAppointmentService.getSAByParentIdsOrderByCreatedDateDesc(new Set<Id>{ workOrderId });
            ServiceAppointment sa = (saList != null && !saList.isEmpty()) ? saList[0] : null;

            if(sa != null) {
                sa.Job_Status__c = AFTER_RECTIFICATION;
                objServiceAppointmentService.updateServiceAppointments(new List<ServiceAppointment>{sa});
            }
            return SUCCESS;

        } catch (Exception ex) {
            throw new AuraHandledException('Error: ' + ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static String checkOut(String rating, String comment, Id workOrderId, String signedBy) {
        try {
            WorkOrderService objWorkOrderService = WorkOrderService.getInstance();
            ServiceAppointmentService objServiceAppointmentService = ServiceAppointmentService.getInstance();

            List<ServiceAppointment> saList = objServiceAppointmentService.getSAByParentIdsOrderByCreatedDateDesc(new Set<Id>{ workOrderId });
            ServiceAppointment serviceAppointment = (saList != null && !saList.isEmpty()) ? saList[0] : null;

            if(serviceAppointment != null && serviceAppointment.Status == COMPLETED) {
                return ALREADY_CHECKED_OUT;
            }

            WorkOrder wo = new WorkOrder();
            wo.Id = workOrderId;
            wo.Customer_Comment__c = comment;
            wo.Rating__c = rating;
            wo.Signed_By__c = signedBy;
            wo.Closure_Comment__c = WORK_COMPLETED;
            wo.Closure_Reason__c = WORK_COMPLETED;

            List<WorkOrder> updatedWo = objWorkOrderService.updateWorkOrders(new List<WorkOrder>{ wo });        
            serviceAppointment.Job_Status__c = CHECK_OUT;
            objServiceAppointmentService.updateServiceAppointments(new List<ServiceAppointment>{serviceAppointment});
            
            return SUCCESS;
            
        } catch (Exception ex) {
            throw new AuraHandledException('Error: ' + ex.getMessage());
        }
    }  
    
    @AuraEnabled
    public static void saveSign(Id recordId, String strSignElement) {
        try {
            ContentService objContentVersion = ContentService.getInstance();
            Blob decodedData = EncodingUtil.base64Decode(strSignElement);
            
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Signature';
            cv.PathOnClient = 'Signature.png';
            cv.VersionData = decodedData;
            cv.IsMajorVersion = true;
            objContentVersion.insertContentVersion(cv);
            
            // Query ContentDocumentId from ContentVersion
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
            cdl.LinkedEntityId = recordId; // Link to the specified record
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers';
            objContentVersion.insertContentDocumentLink(new List<ContentDocumentLink>{cdl});

            WorkOrderImageController.generateAndAttachPdf(recordId);

        } catch (Exception ex) {
            throw new AuraHandledException('Error: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static String createSAWhenCustomerAvailable(Id recordId) {
        System.debug('Record: '+recordId);
        try {
            WorkOrderService objWorkOrderService = WorkOrderService.getInstance();
            ServiceAppointmentService objServiceAppointmentService = ServiceAppointmentService.getInstance();

            Set<Id> workOrderIdSet = new Set<Id>{recordId};
            List<ServiceAppointment> saList = objServiceAppointmentService.getSAByParentIdsOrderByCreatedDateDesc(workOrderIdSet);

            if (saList == null || saList.isEmpty() || saList[0].Status == NONE) { return 'SA_ALREADY_PRESENT'; }

            List<WorkOrder> workOrders = objWorkOrderService.getWorkOrdersByIds(workOrderIdSet);
            Set<Id> projectIds = new Set<Id>();
            Set<Id> unitIdSet = new Set<Id>();

            for (WorkOrder wo : workOrders) {
                if (wo.Project__c != null) {
                    projectIds.add(wo.Project__c);
                }
                if (wo.Unit__c != null) {
                    unitIdSet.add(wo.Unit__c);
                }
            }

            Map<Id, Unit__c> unitMap = new Map<Id, Unit__c>();
            if(!unitIdSet.isEmpty()) {
                List<Unit__c> units = UnitService.getAllUnitsById(unitIdSet);
                if (units != null) {
                    unitMap = new Map<Id, Unit__c>(units);
                }
            }

            Map<Id, ServiceTerritory> serviceTerritoryMap = new Map<Id, ServiceTerritory>();
            if(!projectIds.isEmpty()) {
                List<ServiceTerritory> serviceTerritories = ServiceTerritoryService.getInstance().getServiceTerritorysByProjectIds(projectIds);
                if (serviceTerritories != null) {
                    for (ServiceTerritory st : serviceTerritories) {
                        serviceTerritoryMap.put(st.Project__c, st);
                    }
                }
            }

            Datetime now = System.now();
            List<ServiceAppointment> serviceAppointmentList = new List<ServiceAppointment>();
            for (WorkOrder wo : workOrders) {
                if (wo.hasappointmentcanceled__c) {
                    wo.hasappointmentcanceled__c = false;
                    wo.Cancel_Time__c = null;
                }

                ServiceAppointment newSA = new ServiceAppointment();
                newSA.FSL__Emergency__c = wo.Is_Emergency__c;
                newSA.ParentRecordId = wo.Id;
                newSA.WorkOrderSubCatagory__c = wo.Sub_category__c;
                newSA.Status = NONE;
                newSA.Duration = 1;
                newSA.Incident_description__c = wo.Incident_description__c;
                newSA.EarliestStartTime = now;
                newSA.DueDate = now.addDays(7);
                newSA.Subject = wo.Subject;
                newSA.Description = wo.Description;
                newSA.Unit_Number__c = wo.Unit_Number__c;

                Unit__c unit = unitMap.get(wo.Unit__c);
                if(unit != null) {
                    newSA.Longitude = unit.Location__Longitude__s;
                    newSA.Latitude = unit.Location__Latitude__s;
                }

                ServiceTerritory serviceTerritory = serviceTerritoryMap.get(wo.Project__c);
                if (serviceTerritory != null) {
                    newSA.ServiceTerritoryId = serviceTerritory.Id;
                }

                serviceAppointmentList.add(newSA);
            }
            objServiceAppointmentService.insertServiceAppointments(serviceAppointmentList);
            objWorkOrderService.updateWorkOrders(workOrders);
            return 'SA_CREATED';
            
        } catch(Exception ex) {
            throw new AuraHandledException('Error: ' + ex.getMessage());
        }
    }
}