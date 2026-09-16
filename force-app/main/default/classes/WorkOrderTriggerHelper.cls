/*
*********************************************************
Apex Class Name    : WorkOrderTriggerHelper 
Created Date       : July 15, 2024
@description       : This class is handling multiple methods of workOrder trigger.
Modification Log   :
Ver   Date         : Author                               Modification
4.8   09-09-2026   : Abhay Gupta                          Optimised the class and removed uncommented code
*********************************************************
*/

public without sharing class WorkOrderTriggerHelper {
    private static final String WORKORDER_CLOSED_NOTIFICATION_FOR_CUSTOMER = 'WorkOrder Closed Notification for Customer';
    private static final String CUSTOMER_NOT_AVAILABLE_WORK_ORDER_CLOSE = 'Customer Not Available Work Order Close';
    private static final String CUSTOMER_NOT_AVAILABLE = 'Customer Not Available';
    private static final String DLP_OUT_OF_SCOPE_FOR_CUSTOMER = 'DLP Out Of Scope For Customer';
    private static final String WORKORDER_ENTITLEMENT = System.Label.WrokorderEntitlementActiveVersionName;
    private static final String NEW_WORK_ORDER_ENTITLEMENT = 'New Work Order Entitlement';
    private static final String OWNER = 'Owner';
    private static final String STAGE_NEW = 'New';
    private static final String REPAIR = 'Repair';
    private static final String REPLACE = 'Replace';
    private static final String PRIORITY_1 = 'Priority 1';
    private static final String PRIORITY_2 = 'Priority 2';
    private static final String PRIORITY_3 = 'Priority 3';
    private static final String EMERGENCY = 'Emergency';
    private static final String WITHIN_1_DAY = '1 Day';
    private static final String WITHIN_2_DAYS = '2 Days';
    private static final String WITHIN_5_DAY = '5 Day';
    private static final String WITHIN_2_HOURS = 'Within 2 hours';
    private static final String WITHIN_5_DAYS = 'Within 5 Days';
    private static final String WITHIN_7_DAYS = 'Within 7 Days';
    private static final String WITHIN_14_DAYS = 'Within 14 Days';
    private static final String WITHIN_2_DAY = 'Within 2 Day';
    private static final String OUT_OF_SCOPE = 'Out of Scope';
    private static final String WARRANTY_POST_DLP = 'Warranty post DLP';
    private static final String CLOSED = 'Closed';
    private static final String NONE = 'None';
    private static final String NOT_AVAILABLE = 'Not Available';
    private static final String CUSTOMER_NOT_AVAILABLE_WHEN_AGENT_VISITED = 'Customer not available when agent visited';
    private static final String CUSTOMER_NOT_AVAILABLE_LABEL = 'Customer not available';
    private static final String OUT_OF_DLP_SCOPE = 'Out of DLP Scope';
    private static final String OUTSIDE_SCOPE = 'Outside Scope';
    private static final String WORK_COMPLETED = 'Work Completed';
    private static final String RESOLVED = 'Resolved';
    private static final String CASE_RESOLVED = 'Case Resolved';
    private static final String COMPLETED_LABEL = 'Completed';
    private static final String UNDER_SCOPE = 'Under Scope';
    private static final String BLOOM_NO_REPLY_LABEL = 'Bloom No Reply';
    
    public static void autoPopulateFields(List<WorkOrder> wrkList){ 
        Set<String> subCategorySet = new Set<String>();
        Set<String> incidentDescriptionSet = new Set<String>();
        Set<String> resolutionTypologySet = new Set<String>();        
        Set<Id> unitIdSet = new Set<Id>();
        
        for(WorkOrder wo : wrkList) {
            wo.Status = STAGE_NEW;
            if (wo.Unit__c != null) { unitIdSet.add(wo.Unit__c); }
            subCategorySet.add(wo.Sub_category__c);
            incidentDescriptionSet.add(wo.Incident_description__c);
            resolutionTypologySet.add(wo.Resolution_Typology__c);
            
            if(wo.Is_Tenet_Request__c == OWNER) {
                wo.Requester_Name__c = wo.Customer_Name__c;
                wo.Requester_Email__c = String.isBlank(wo.Requester_Email__c) ? wo.Customer_Email__c : wo.Requester_Email__c;
                wo.Requester_Phone__c = String.isBlank(wo.Requester_Phone__c) ? wo.Customer_Phone__c : wo.Requester_Phone__c;              
            }                            
        }
                
        Map<Id, Unit__c> unitMap = unitIdSet.isEmpty() ? new Map<Id, Unit__c>() : new Map<Id, Unit__c>(UnitService.getAllUnitsById(unitIdSet));
        for(workOrder wObj: wrkList) {
            Unit__c unit = unitMap.get(wObj.Unit__c);

            if (unit != null) {
                wObj.Unit_Number__c = unit.Name;
                wObj.Longitude =  unit.Location__Longitude__s;
                wObj.Latitude =  unit.Location__Latitude__s;
                
                if(unit.Project__c != null) {
                    wObj.Project__c = unit.Project__c;
                    wObj.Contractor__c = unit.Project__r.Contractor__c;
                }
            }
        }
        populateResolutionDetails(wrkList, getKeyToServiceCatalogueMap(subCategorySet, incidentDescriptionSet));    

    }

    public static void updateResolutionPriority(List<WorkOrder> newWorkOrders, Map<Id, WorkOrder> oldWorkOrders) {
        Set<Id> projectId = new Set<Id>();
        Set<String> subCategorySet = new Set<String>();
        Set<String> incidentDescriptionSet = new Set<String>();
        Set<String> resolutionTypologySet = new Set<String>();        
        Set<Id> unitIdSet = new Set<Id>();
        
        for(WorkOrder wo : newWorkOrders) {
            if(wo.Sub_category__c != null && wo.Sub_category__c != oldWorkOrders.get(wo.id).Sub_category__c) {
                subCategorySet.add(wo.Sub_category__c);
            }
            incidentDescriptionSet.add(wo.Incident_description__c);
            resolutionTypologySet.add(wo.Resolution_Typology__c);            
        }
        
        populateResolutionDetails(newWorkOrders, getKeyToServiceCatalogueMap(subCategorySet, incidentDescriptionSet));
    }

    public static void populateResolutionDetails(List<WorkOrder> workOrderList, Map<String, Service_Catalogue__c> keyToServiceCatalogueMap) {
        for (WorkOrder wo : workOrderList) {
            Service_Catalogue__c serviceCatalog = getServiceCatalogue(wo.Category__c, wo.Sub_category__c, wo.Incident_description__c, wo.Resolution_Typology__c, keyToServiceCatalogueMap);
            if (serviceCatalog != null && String.isNotBlank(serviceCatalog.Resolution_Priority__c)) {
                setResolutionDetails(wo, serviceCatalog.Resolution_Priority__c);
            }
        }
    }

    public static Map<String, Service_Catalogue__c> getKeyToServiceCatalogueMap(Set<String> subCategorySet, Set<String> incidentDescriptionSet) {
        Map<String,Service_Catalogue__c> keyToServiceCatalogueMap = new Map<String,Service_Catalogue__c>();
        List<Service_Catalogue__c> serviceCatalogList = ServiceCatalogService.getInstance().getServiceCatalogBySubCategoryAndIncidentDesc(subCategorySet, incidentDescriptionSet);

        for(Service_Catalogue__c serCatRec : serviceCatalogList) {
            if(String.isNotBlank(serCatRec.Category__c) && String.isNotBlank(serCatRec.Incident_description__c)
                && String.isNotBlank(serCatRec.Resolution_Typology__c) && String.isNotBlank(serCatRec.Sub_category__c)
            ) {
                String keyTemp = (serCatRec.Category__c + serCatRec.Sub_category__c + serCatRec.Incident_description__c + serCatRec.Resolution_Typology__c).toLowerCase();
                keyToServiceCatalogueMap.put(keyTemp, serCatRec);
            }
        }
        return keyToServiceCatalogueMap;
    }

    public static Service_Catalogue__c getServiceCatalogue(String category, String subCategory, String incidentDescription, String resolutionTypology, Map<String, Service_Catalogue__c> keyVsServiceCatalogueMap) {
        if (keyVsServiceCatalogueMap == null || keyVsServiceCatalogueMap.isEmpty()) {
            return null;
        }

        //If a record is not found for matching Typology then pick the one that is available 
        String alternateTypology = resolutionTypology == REPAIR ? REPLACE : REPAIR;
        String key1 = (category + subCategory + incidentDescription + resolutionTypology).toLowerCase();
        String key2 = (category + subCategory + incidentDescription + alternateTypology).toLowerCase();

        Service_Catalogue__c serviceCatalog = keyVsServiceCatalogueMap.get(key1);
        return serviceCatalog != null ? serviceCatalog : keyVsServiceCatalogueMap.get(key2);
    }

    public static void setResolutionDetails(WorkOrder wObj, String priority) {
        if (wObj == null || String.isBlank(priority)) {
            return;
        }

        Map<String, String> priorityMap = new Map<String, String>{'P1' => PRIORITY_1, 'P2' => PRIORITY_2, 'P3' => PRIORITY_3, 'PE' => EMERGENCY};
        Map<String, String> repairMap = new Map<String, String>{'P1' => WITHIN_1_DAY, 'P2' => WITHIN_2_DAYS, 'P3' => WITHIN_5_DAY, 'PE' => WITHIN_2_HOURS};
        Map<String, String> replaceMap = new Map<String, String>{'P1' => WITHIN_5_DAYS, 'P2' => WITHIN_7_DAYS, 'P3' => WITHIN_14_DAYS, 'PE' => WITHIN_2_DAY};

        if (!priorityMap.containsKey(priority)) {
            return;
        }

        wObj.Resolution_Priority__c = priorityMap.get(priority);

        if (wObj.Resolution_Typology__c == REPAIR) {
            wObj.Repair__c = repairMap.get(priority);
        } else if (wObj.Resolution_Typology__c == REPLACE) {
            wObj.Replace__c = replaceMap.get(priority);
        }
    }
    
    public static void updateWorkOrder(List<WorkOrder> workOrderList, Map<Id, WorkOrder> workOrderOldMap) {
        for(WorkOrder wrkObj: workOrderList) {
            WorkOrder oldWO = workOrderOldMap.get(wrkObj.Id);
            if(wrkObj.Type_of_Incident__c != oldWO.Type_of_Incident__c && (wrkObj.Type_of_Incident__c == OUT_OF_SCOPE || wrkObj.Type_of_Incident__c == WARRANTY_POST_DLP)) {
                wrkObj.Status = CLOSED;
            }

            if(((String.isNotBlank(wrkObj.Is_Tenet_Request__c) && wrkObj.Is_Tenet_Request__c != oldWO.Is_Tenet_Request__c) ||
            (wrkObj.Requester_Name__c != oldWO.Requester_Name__c || wrkObj.Requester_Email__c != oldWO.Requester_Email__c || wrkObj.Requester_Phone__c != oldWO.Requester_Phone__c)) && wrkObj.Is_Tenet_Request__c == OWNER) {
                wrkObj.Requester_Name__c = wrkObj.Customer_Name__c;
                
                if(String.isBlank(wrkObj.Requester_Email__c)) {
                    wrkObj.Requester_Email__c = wrkObj.Customer_Email__c;                    
                }
                if(String.isBlank(wrkObj.Requester_Phone__c)) {
                    wrkObj.Requester_Phone__c = wrkObj.Customer_Phone__c;                    
                }                
            }
        }
    }
    
    public static void createServiceAppointment(List<WorkOrder> newList) {
        Set<Id> projectIdSet = new Set<Id>();
        Set<Id> unitIdSet = new Set<Id>();
        List<ServiceAppointment> serviceAppointmentList = new List<ServiceAppointment>();
        
        for(workOrder wo: newList) {
            if(String.isNotBlank(wo.Project__c)) {
                projectIdSet.add(wo.Project__c);                
            }
            if(String.isNotBlank(wo.Unit__c)) {
                unitIdSet.add(wo.Unit__c);                
            }
        }

        Map<Id, Unit__c> unitMap = unitIdSet.isEmpty() ? new Map<Id, Unit__c>() : new Map<Id, Unit__c>(UnitService.getAllUnitsById(unitIdSet));
        Map<Id, ServiceTerritory> relatedStMap = projectIdSet.isEmpty() ? new Map<Id, ServiceTerritory>() 
                                                                        : new Map<Id, ServiceTerritory>(ServiceTerritoryService.getInstance().getServiceTerritorysByProjectIds(projectIdSet));

        Map<String, ServiceTerritory> projectVsServiceTerritoryMap = new Map<String, ServiceTerritory>();
        for(ServiceTerritory st: relatedStMap.values()) {
            projectVsServiceTerritoryMap.put(st.Project__c, st);
        }   
        
        for(workOrder wrkObj: newList) {
            ServiceAppointment newSA = new ServiceAppointment();            
            
            if (String.isNotBlank(wrkObj.Project__c) && projectVsServiceTerritoryMap.containsKey(wrkObj.Project__c)) {
                newSA.ServiceTerritoryId = projectVsServiceTerritoryMap.get(wrkObj.Project__c).Id;
            } 
            if (unitMap.containsKey(wrkObj.Unit__c) && String.isNotBlank(unitMap.get(wrkObj.Unit__c).Name)) {
                newSA.Unit_Number__c = unitMap.get(wrkObj.Unit__c).Name;
            } 
            
            newSa.FSL__Emergency__c = wrkObj.Is_Emergency__c;
            newSa.WorkOrderSubCatagory__c = wrkObj.Sub_category__c;
            newSa.Incident_description__c = wrkObj.Incident_description__c; 
            newSA.ParentRecordId = wrkObj.Id;            
            newSA.Status = NONE;
            newSA.Duration = 1;  
            newSA.EarliestStartTime = System.now();
            newSA.DueDate = System.now().addDays(7); 
            newSa.Longitude = unitMap.get(wrkObj.Unit__c)?.Location__Longitude__s;
            newSa.Latitude = unitMap.get(wrkObj.Unit__c)?.Location__Latitude__s;
            newSA.Subject = String.isNotBlank(wrkObj.Subject) ? wrkObj.Subject : null;
            newSA.Description = String.isNotBlank(wrkObj.Description) ? wrkObj.Description : null;
            serviceAppointmentList.add(newSA); 
        }      
        
        ServiceAppointmentService objServiceAppointmentService = ServiceAppointmentService.getInstance(); 
        serviceAppointmentList = objServiceAppointmentService.insertServiceAppointments(serviceAppointmentList);
    }
    
    public static void processWorkOrders(List<WorkOrder> newWorkOrders, Map<Id, WorkOrder> oldWorkOrders) {
        Set<Id> workOrderIds = new Map<Id, WorkOrder>(newWorkOrders).keySet();
        List<WorkOrder> toProcessWOList = new List<WorkOrder>();
        Set<String> templateNames = new Set<String>{CUSTOMER_NOT_AVAILABLE, WORKORDER_CLOSED_NOTIFICATION_FOR_CUSTOMER, CUSTOMER_NOT_AVAILABLE_WORK_ORDER_CLOSE, DLP_OUT_OF_SCOPE_FOR_CUSTOMER};
        EmailService objEmailService = EmailService.getInstance();
        WorkOrderService objWorkOrderService = WorkOrderService.getInstance();
        ServiceAppointmentService objServiceAppointmentService = ServiceAppointmentService.getInstance();
        ContentService contentServiceObj = ContentService.getInstance();
        UserService objUserService = UserService.getInstance();

        Set<Id> ownerIds = new Set<Id>(); 
        for(WorkOrder wo : newWorkOrders) {
            if(isCustomerNotAvailableWhenCheckedIn(wo, oldWorkOrders.get(wo.Id)) || isCustomerNotAvailableAndWOClosed(wo) || isDLPOutOfScopeAndWOClosed(wo) || isWorkCompletedAndWOClosed(wo)) {
                toProcessWOList.add(wo);
            }
            ownerIds.add(wo.OwnerId);
        }
        
        if(toProcessWOList.isEmpty()) {return;}
        Map<Id, ServiceAppointment> woIdSaMap = new Map<Id, ServiceAppointment>();
        List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
        
        Map<String, EmailTemplate> templateNameVsEmailTemplateMap = EmailService.getInstance().getEmailTemplatesByName(templateNames);
        EmailTemplate mailTemplateCustomerNotAvailable = templateNameVsEmailTemplateMap.get(CUSTOMER_NOT_AVAILABLE);
        EmailTemplate mailTemplateWorkOrderClosedForCustomer = templateNameVsEmailTemplateMap.get(WORKORDER_CLOSED_NOTIFICATION_FOR_CUSTOMER);
        EmailTemplate mailTemplateCustomerNotAvailableWorkOrderClose = templateNameVsEmailTemplateMap.get(CUSTOMER_NOT_AVAILABLE_WORK_ORDER_CLOSE);
        EmailTemplate mailTemplateDlpOutOfScopeForCustomer = templateNameVsEmailTemplateMap.get(DLP_OUT_OF_SCOPE_FOR_CUSTOMER);
        OrgWideEmailAddress orgWideEmail = objEmailService.getOrgWideEmailAddressByDisplayName(BLOOM_NO_REPLY_LABEL);      
        
        Map<Id, ContentDocumentLink> contentDocumentLinkMap = new Map<Id, ContentDocumentLink>();
        if(workOrderIds != null && !workOrderIds.isEmpty()) {
            contentDocumentLinkMap = new Map<Id, ContentDocumentLink> (contentServiceObj.getContentDocumentLinksByLinkedEntityId(workOrderIds));            
        }
        
        Set<Id> contentDocumentIdSet = new Set<Id>();
        for(ContentDocumentLink cdl: contentDocumentLinkMap.Values()) {
            if(String.isNotBlank(cdl.ContentDocumentId)) {
                contentDocumentIdSet.add(cdl.ContentDocumentId);
            }
        }
        
        List<ContentVersion> contentVersionList = new List<ContentVersion>();
        if(!contentDocumentIdSet.isEmpty()) {
            contentVersionList = contentServiceObj.getContentVersionsByLinkedEntityId(contentDocumentIdSet);
        }        
        
        Map<Id, ContentVersion> workOrderContentVersionMap = new Map<Id, ContentVersion>();
        if(!contentVersionList.isEmpty() && !contentDocumentLinkMap.isEmpty()){
            for (ContentDocumentLink cdl : contentDocumentLinkMap.values()) {
                for (ContentVersion cntVr : contentVersionList) {
                    if (cdl.ContentDocumentId == cntVr.ContentDocumentId) {
                        workOrderContentVersionMap.put(cdl.LinkedEntityId, cntVr);
                    }
                }
            } 
        }        
                
        List<ServiceAppointment> saList = new List<ServiceAppointment>();
        if(newWorkOrders != null && !newWorkOrders.isEmpty()) {
            Map<Id, WorkOrder> woIdVsworkOrderMap = new Map<Id, WorkOrder>(newWorkOrders);
            saList = objServiceAppointmentService.getServiceAppointmentsByParentRecordSetIds(woIdVsworkOrderMap.keySet());            
        }
        
        for(ServiceAppointment sa: saList) {
            woIdSaMap.put(sa.ParentRecordId, sa);
        }
        
        Map<Id, User> ownersMap = ownerIds.isEmpty() ? new Map<Id, User>() : new Map<Id, User>(objUserService.getUsersByIds(ownerIds));
        
        Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>(objWorkOrderService.getWorkOrdersByIds(workOrderIds)); 
        for(WorkOrder wo : newWorkOrders) {
            WorkOrder oldWO = oldWorkOrders.get(wo.Id);
            WorkOrder workOrderObj = workOrderMap.get(wo.Id);
            ServiceAppointment servApp = woIdSaMap.get(wo.Id);
            User owner = ownersMap.get(wo.OwnerId);
            ContentVersion contentVersionObj = new  ContentVersion();
            if(!workOrderContentVersionMap.isEmpty()) {
                contentVersionObj = workOrderContentVersionMap.get(wo.Id);                
            }

            if (isCustomerNotAvailableWhenCheckedIn(wo, oldWO) && mailTemplateCustomerNotAvailable != null) {
                mailList.add(DLPEmailHandler.sendEmailProcess(mailTemplateCustomerNotAvailable, workOrderObj, servApp, new List<String>{wo.New_Requester_Email__c}, contentVersionObj, orgWideEmail));                        
            }

            if(isCustomerNotAvailableAndWOClosed(wo) && mailTemplateCustomerNotAvailableWorkOrderClose != null) {
                mailList.add(DLPEmailHandler.sendEmailProcess(mailTemplateCustomerNotAvailableWorkOrderClose, workOrderObj, servApp, new List<String>{wo.New_Requester_Email__c}, contentVersionObj, orgWideEmail));                        
                
            } else if(isDLPOutOfScopeAndWOClosed(wo) && mailTemplateDlpOutOfScopeForCustomer != null) {
                mailList.add(DLPEmailHandler.sendEmailProcess(mailTemplateDlpOutOfScopeForCustomer, workOrderObj, servApp, new List<String>{wo.New_Requester_Email__c}, contentVersionObj, orgWideEmail));                        
                
            } else if(isWorkCompletedAndWOClosed(wo) && mailTemplateWorkOrderClosedForCustomer != null) {
                mailList.add(DLPEmailHandler.sendEmailProcess(mailTemplateWorkOrderClosedForCustomer, workOrderObj, servApp, new List<String>{wo.New_Requester_Email__c, workOrderObj.Owner.Email}, null, orgWideEmail));
            }
        }
                
        if(!Test.IsRunningTest()) {
            List<Messaging.SendEmailResult> mails = objEmailService.sendEmail(mailList);
        }
    }

    public static void closeServiceAppointmentsOnWorkOrderClosure(List<WorkOrder> newWorkOrders, Map<Id, WorkOrder> oldWorkOrders) {
        Map<Id, List<ServiceAppointment>> woIdVsSAListMap = new Map<Id, List<ServiceAppointment>>();
        Map<Id, ServiceAppointment> saMap = new Map<Id, ServiceAppointment>();
        ServiceAppointmentService objServiceAppointmentService = ServiceAppointmentService.getInstance(); 
        List<ServiceAppointment> serviceAppointmentListToUpdate = new List<ServiceAppointment>();

        if(newWorkOrders != null && !newWorkOrders.isEmpty()) {
            Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>(newWorkOrders);
            saMap = new Map<Id, ServiceAppointment>(objServiceAppointmentService.getServiceAppointmentsByParentRecordSetIds(workOrderMap.keySet()));            
        }
        
        for(ServiceAppointment sa: saMap.Values()) {
            if(!woIdVsSAListMap.containsKey(sa.ParentRecordId)) {
                woIdVsSAListMap.put(sa.ParentRecordId, new List<ServiceAppointment>());
            }
            woIdVsSAListMap.get(sa.ParentRecordId).add(sa);
        }

        for (WorkOrder wo : newWorkOrders) {
            WorkOrder oldWO = oldWorkOrders.get(wo.Id);
            List<ServiceAppointment> SAList = woIdVsSAListMap.get(wo.Id);
            if(wo.Status == CLOSED && oldWO.Status != wo.Status && SAList != null) {
                for(ServiceAppointment servAppRec : SAList) {
                    String closureReason = (wo.Closure_Reason__c == WORK_COMPLETED || wo.Closure_Reason__c == null) ? 'Work Closed' : wo.Closure_Reason__c;
                    if(servAppRec.Status != COMPLETED_LABEL) {
                        servAppRec.Status = COMPLETED_LABEL;
                        servAppRec.Closure_Reason__c = closureReason;

                        if(wo.Type_of_Incident__c == OUT_OF_SCOPE) {
                            servAppRec.Job_Status__c = UNDER_SCOPE;
                        }
                    }
                    serviceAppointmentListToUpdate.add(servAppRec);
                }
            }
        }
        
        if(!serviceAppointmentListToUpdate.isEmpty()) {
            serviceAppointmentListToUpdate = objServiceAppointmentService.updateServiceAppointmentsWithoutTrigger(serviceAppointmentListToUpdate);
        }
    }
    
    public static void createEntitlementOnWorkOrder(List<WorkOrder> workOrders) {
        Set<Id> accountIds = new Set<Id>();
        for (WorkOrder wo : workOrders) {
            if (wo.AccountId != null) {
                accountIds.add(wo.AccountId);
            }
        }
        
        if(!accountIds.isEmpty()) {
            EntitlementService objEntitlementService = EntitlementService.getInstance();
            List<Entitlement> entitlementList = objEntitlementService.getEntitlementsByAccountIdSet(accountIds);
            Map<Id, List<Entitlement>> accountIdToExistingEntitlementMap = new Map<Id, List<Entitlement>>();
            for(Entitlement entitlementRec : entitlementList){
                if(!accountIdToExistingEntitlementMap.containsKey(entitlementRec.AccountId)){
                    accountIdToExistingEntitlementMap.put(entitlementRec.AccountId, new List<Entitlement>());
                }
                accountIdToExistingEntitlementMap.get(entitlementRec.AccountId).add(entitlementRec);
            }
            
            SlaProcess ep = new SlaProcess();
            if(String.isNotBlank(WORKORDER_ENTITLEMENT)) {
                ep = SlaProcessService.getInstance().getSlaProcessByName(WORKORDER_ENTITLEMENT);
            }
            
            List<Entitlement> newEntitlements = new List<Entitlement>();
            for (WorkOrder wo : workOrders) {
                if (wo.AccountId != null && !accountIdToExistingEntitlementMap.containsKey(wo.AccountId)) {
                    Entitlement ent = new Entitlement(Name = NEW_WORK_ORDER_ENTITLEMENT, AccountId = wo.AccountId, StartDate = Date.today(), EndDate = Date.today().addYears(1), SlaProcessId = ep?.Id);
                    newEntitlements.add(ent);

                } else if (accountIdToExistingEntitlementMap.containsKey(wo.AccountId)) {
                    wo.EntitlementId = accountIdToExistingEntitlementMap.get(wo.AccountId)[0].Id;
                }
            }
            
            newEntitlements = objEntitlementService.insertEntitlements(newEntitlements);  
            Map<Id, Id> accountToEntitlementIdMap = new Map<Id, Id>();
            for(Entitlement ent : newEntitlements) {
                accountToEntitlementIdMap.put(ent.AccountId, ent.Id);
            }

            for(WorkOrder wo : workOrders) {
                if (wo.AccountId != null && accountToEntitlementIdMap.containsKey(wo.AccountId)) {
                    wo.EntitlementId = accountToEntitlementIdMap.get(wo.AccountId);
                }
            }
        }
    }
    
    private static Boolean isCustomerNotAvailableWhenCheckedIn(WorkOrder wo, WorkOrder oldWO) { 
        return oldWO != null && wo.Check_In__c == true && wo.Customer_Availability__c == NOT_AVAILABLE && oldWO.Check_In__c != wo.Check_In__c && wo.Status != CLOSED; 
    }

    private static Boolean isCustomerNotAvailableAndWOClosed(WorkOrder wo) { 
        return wo.Customer_Availability__c == NOT_AVAILABLE && wo.New_Requester_Email__c != null && wo.Status == CLOSED; 
    }

    private static Boolean isDLPOutOfScopeAndWOClosed(WorkOrder wo) { 
        return wo.Type_of_Incident__c == OUT_OF_SCOPE && wo.New_Requester_Email__c != null && wo.Status == CLOSED; 
    }

    private static Boolean isWorkCompletedAndWOClosed(WorkOrder wo) { 
        return wo.Closure_Reason__c == WORK_COMPLETED && wo.New_Requester_Email__c != null && wo.Status == CLOSED; 
    }
}