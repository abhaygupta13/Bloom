/*
*********************************************************
Apex Class Name    : WorkOrderTriggerHelper 
Created Date       : July 15, 2024
@description       : This class is handling multipal methods of workOrder trigger.
Modification Log   :
Ver   Date         : Author                               Modification
4.7   28-08-2024   : Pavitra Chauhan                      Initial Version
*********************************************************
*/

public class WorkOrderTriggerHelper {
    private static String WORKORDER_CLOSED_NOTIFICATION_FOR_CUSTOMER = 'WorkOrder Closed Notification for Customer';
    private static String CUSTOMER_NOT_AVAILABLE_WORK_ORDER_CLOSE = 'Customer Not Available Work Order Close';
    private static String CUSTOMER_NOT_AVAILABLE = 'Customer Not Available';
    private static String DLP_OUT_OF_SCOPE_FOR_CUSTOMER = 'DLP Out Of Scope For Customer';
    private static String WORKORDER_ENTITLEMENT = System.Label.WrokorderEntitlementActiveVersionName; //'Workorder Entitlement';
    private static String NEW_WORK_ORDER_ENTITLEMENT = 'New Work Order Entitlement';
    
  /*  public static void createCaseFromWorkOrders(List<WorkOrder> workOrders) { 
        List<Case> casesToInsert = new List<Case>();
        Id recTypeId;
        if(Utility.getRecordTypeIdByDevName(Case.SObjectType, Constants.DEFECT_LIABILITY_COMPLAINT) != null){
            recTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, Constants.DEFECT_LIABILITY_COMPLAINT);            
        }
        
        for (WorkOrder workOrder : workOrders) {
            Case newCase = new Case();
            Date dateVal = System.now().date();
            if (String.isNotBlank(recTypeId) && recTypeId != null ) {
                newCase.RecordTypeId = recTypeId;
            }
            if(workOrder.Type_of_Incident__c == Constants.OUT_OF_SCOPE || workOrder.Type_of_Incident__c == Constants.WARRANTY_POST_DLP){
                newCase.Status = Constants.CLOSED;
            } 
            newCase.Work_Order__c = workOrder.Id;
            newCase.Case_Sub_Status__c = '';
            newCase.Bloom_Signed_SPA_Date__c = dateVal;
            newCase.Bloom_Signed_SPA__c = false;
            newCase.Description	 = workOrder.Description;
            casesToInsert.add(newCase);
        }
        CaseService objCaseService = CaseService.getInstance();
        casesToInsert =  objCaseService.insertCaseWithoutTrigger(casesToInsert); 
        
        List<Id> caseIds = new List<Id>();
        List<WorkOrder> woList = new List<WorkOrder>();
        for (Case newCase : casesToInsert) {
            WorkOrder wo = new WorkOrder();
            wo.Id = newCase.Work_Order__c;
            wo.CaseId = newCase.Id;
            wo.Subject = newCase.Subject;
            if(newCase.Type_of_Incident__c == Constants.OUT_OF_SCOPE || newCase.Type_of_Incident__c == Constants.WARRANTY_POST_DLP){
                wo.Status = Constants.CLOSED;
            }
            woList.add(wo);
        }
        WorkOrderService objWorkOrderService = WorkOrderService.getInstance();
        objWorkOrderService.updateWorkOrdersWithoutTrigger(woList);        
    }     
*/
    
    //before insert
    public static void autoPopulateFields(List<WorkOrder> wrkList){  
        set<Id> projectId = new set<Id>();
        //Set<String> locationSet = new Set<String>();
        Set<String> categorySet = new Set<String>(); // NEW CHANGES
        Set<String> problemCodeSet = new Set<String>(); // NEW CHANGES
        Set<String> subCategorySet = new Set<String>();
        Set<String> incidentDescriptionSet = new Set<String>();
        Set<String> resolutionTypologySet = new Set<String>();        
        Set<Id> unitIdSet = new Set<Id>();
        
        for(WorkOrder wo : wrkList) {
            unitIdSet.add(wo.Unit__c);
           // wo.Status = Constants.SCHEDULED; // NEW CHANGES
           wo.Status = Constants.STAGE_NEW;
            //locationSet.add(wo.Location__c);
            subCategorySet.add(wo.Sub_category__c);
            incidentDescriptionSet.add(wo.Incident_description__c);
            resolutionTypologySet.add(wo.Resolution_Typology__c);
            
            if(String.isNotBlank(wo.Is_Tenet_Request__c) && wo.Is_Tenet_Request__c == 'Owner'){
                wo.Requester_Name__c = wo.Customer_Name__c;               
                //wo.Requester_Comment__c = wo.Customer_Comment__c; 
                if(String.isBlank(wo.Requester_Email__c)){
                    wo.Requester_Email__c = wo.Customer_Email__c;                    
                }
                if(String.isBlank(wo.Requester_Phone__c)){
                    wo.Requester_Phone__c = wo.Customer_Phone__c;                    
                }                
            }                            
        }
        
        if(unitIdSet.isEmpty() && subCategorySet.isEmpty() && incidentDescriptionSet.isEmpty() && resolutionTypologySet.isEmpty()){// && locationSet.isEmpty()
            //  return null;
        } 
        //Category,Sub Category,Incident Description,Resolution Typology to be used as => Key
        Map<String,Service_Catalogue__c> keyToServiceCatalogueMap = new Map<String,Service_Catalogue__c>();
        List<Service_Catalogue__c> serviceCatalogList = [SELECT Id, Name, Location__c, Replace__c, Repair__c, Closure_Reason__c, Category__c, Sub_category__c, 
                                                         Incident_description__c, Resolution_Priority__c, Resolution_Typology__c, Problem_Code__c
                                                         FROM Service_Catalogue__c
                                                         WHERE Sub_category__c IN :subCategorySet //Location__c IN :locationSet AND
                                                         AND Incident_description__c IN :incidentDescriptionSet
                                                         /*As per new chnages if a record is not found for matching Typology then pick the one that is available
                                                         AND Resolution_Typology__c IN :resolutionTypologySet 
                                                         */
                                                         //AND Category__c IN :categorySet  // NEW CHANGES
                                                         //AND Problem_Code__c IN :problemCodeSet  // NEW CHANGES
                                                        ];

        for(Service_Catalogue__c serCatRec : serviceCatalogList){
            if(String.isNotBlank(serCatRec.Category__c) && String.isNotBlank(serCatRec.Incident_description__c)
            && String.isNotBlank(serCatRec.Resolution_Typology__c) && String.isNotBlank(serCatRec.Sub_category__c)
            ){
                String keyTemp = (serCatRec.Category__c+serCatRec.Sub_category__c+serCatRec.Incident_description__c+serCatRec.Resolution_Typology__c).toLowerCase();
                keyToServiceCatalogueMap.put(keyTemp, serCatRec);
            }
        }
        
        Map<Id, Unit__c> unitMap = new Map<Id, Unit__c>();
        if(UnitService.getAllUnitsById(unitIdSet) != null){
            unitMap = new Map<Id, Unit__c>(UnitService.getAllUnitsById(unitIdSet)); 
        }
        for(workOrder wObj: wrkList){
            if (unitMap.containsKey(wObj.Unit__c)) {
                
                // wObj.Street = unitMap.get(wObj.Unit__c).Location__Longitude__s + ',' + unitMap.get(wObj.Unit__c).Location__Latitude__s;
                wObj.Longitude =  unitMap.get(wObj.Unit__c).Location__Longitude__s;
                wObj.Latitude =  unitMap.get(wObj.Unit__c).Location__Latitude__s;
                
                if(unitMap.get(wObj.Unit__c).Project__c != null){
                    wObj.Project__c = UnitMap.get(wObj.Unit__c).Project__c;
                    projectId.add(wObj.Project__c);
                }
                if (String.isNotBlank(unitMap.get(wObj.Unit__c).Name)) {
            wObj.Unit_Number__c = unitMap.get(wObj.Unit__c).Name;
        }
            }
        }
        
        //Commented as per new functionality
        Map<Id, Project__c> projectMap = new Map<Id, Project__c>();
        System.debug('projectId > ' + projectId);
        ProjectService objProjectService = ProjectService.getInstance();
        
        if(objProjectService.getProjectsByIds(projectId) != null){
            projectMap = new Map<Id, Project__c>(objProjectService.getProjectsByIds(projectId));            
        }
        
        for(workOrder wObj: wrkList){
            String key1 = '';
            String key2 = '';
            if (projectMap.containsKey(wObj.Project__c)) {
                if(projectMap.get(wObj.Project__c).Contractor__c != null){
                    wObj.Contractor__c = projectMap.get(wObj.Project__c).Contractor__c;
                }
            }

            //As per new chnages if a record is not found for matching Typology then pick the one that is available 
            Service_Catalogue__c serCatRec = new Service_Catalogue__c();
            //keyToServiceCatalogueMap.put(serCatRec.Category__c+serCatRec.Sub_category__c+serCatRec.Incident_description__c+serCatRec.Resolution_Typology__c, serCatRec);
            key1 = (wObj.Category__c+wObj.Sub_category__c+wObj.Incident_description__c+wObj.Resolution_Typology__c).toLowerCase();
            if(wObj.Resolution_Typology__c == 'Repair'){
                key2 = (wObj.Category__c+wObj.Sub_category__c+wObj.Incident_description__c+'Replace').toLowerCase();
            } else {
                key2 = (wObj.Category__c+wObj.Sub_category__c+wObj.Incident_description__c+'Repair').toLowerCase();
            }
           
            if(keyToServiceCatalogueMap.containsKey(key1)) {
                serCatRec = keyToServiceCatalogueMap.get(key1);
            } else if(keyToServiceCatalogueMap.containsKey(key2)){
                serCatRec = keyToServiceCatalogueMap.get(key2);
            }

            if (serCatRec != NULL && String.isNotBlank(serCatRec.Resolution_Priority__c)) {
                switch on serCatRec.Resolution_Priority__c {
                    when 'P1' {
                        wObj.Resolution_Priority__c = Constants.PRIORITY_1;
                        if(wObj.Resolution_Typology__c == Constants.REPAIR){
                            wObj.Repair__c = Constants.WITHIN_1_DAY;
                        }else if(wObj.Resolution_Typology__c == Constants.REPLACE){
                            wObj.Replace__c = Constants.WITHIN_5_DAYS;
                        }
                    }
                    when 'P2' {
                        wObj.Resolution_Priority__c = Constants.PRIORITY_2;
                        if(wObj.Resolution_Typology__c == Constants.REPAIR){
                            wObj.Repair__c = Constants.WITHIN_2_DAYS;
                        }else if(wObj.Resolution_Typology__c == Constants.REPLACE){
                            wObj.Replace__c = Constants.WITHIN_7_DAYS;
                        }
                    }
                    when 'P3' {
                        wObj.Resolution_Priority__c = Constants.PRIORITY_3;
                        if(wObj.Resolution_Typology__c == Constants.REPAIR){
                            wObj.Repair__c = Constants.WITHIN_5_DAY;
                        }else if(wObj.Resolution_Typology__c == Constants.REPLACE){
                            wObj.Replace__c = Constants.WITHIN_14_DAYS;
                        }
                    } 
                    when 'PE' {//PE  Emergency    
                        wObj.Resolution_Priority__c = Constants.EMERGENCY;
                        if(wObj.Resolution_Typology__c == Constants.REPAIR){
                            wObj.Repair__c = Constants.WITHIN_2_HOURS;
                        }else if(wObj.Resolution_Typology__c == Constants.REPLACE){
                            wObj.Replace__c = Constants.WITHIN_2_DAY;
                        }
                    }
                }
            } 

            /*for(Service_Catalogue__c serCatObj: serviceCatalogList){
                
                if(String.isNotBlank(serCatObj.Category__c) && String.isNotBlank(serCatObj.Incident_description__c) &&
                   String.isNotBlank(serCatObj.Resolution_Typology__c) && String.isNotBlank(serCatObj.Sub_category__c) &&
                   String.isNotBlank(serCatObj.Problem_Code__c)  // NEW CHANGES
                   ){ 
            
                       if(wObj.Category__c == serCatObj.Category__c && //wObj.Location__c == serCatObj.Location__c &&
                          wObj.Sub_category__c == serCatObj.Sub_category__c && wObj.Incident_description__c == serCatObj.Incident_description__c &&
                          wObj.Resolution_Typology__c == serCatObj.Resolution_Typology__c //&&
                          //wObj.Problem_Code__c == serCatObj.Problem_Code__c // NEW CHANGES
                         ){
                              
                              //wObj.Problem_Code__c = serCatObj.Problem_Code__c; // NEW CHANGES
                              //wObj.Resolution_Priority__c = Constants.EMERGENCY; // NEW CHANGES
                              System.debug('wObj.Resolution_Priority__c >> ' + wObj.Resolution_Priority__c);
                              System.debug('serCatObj.Resolution_Priority__c >> ' + serCatObj.Resolution_Priority__c);
                             
                              if (String.isNotBlank(serCatObj.Resolution_Priority__c)) 
                              {
                                  switch on serCatObj.Resolution_Priority__c {
                                      when 'P1' {
                                          wObj.Resolution_Priority__c = Constants.PRIORITY_1;
                                          if(wObj.Resolution_Typology__c == Constants.REPAIR){
                                              wObj.Repair__c = Constants.WITHIN_1_DAY;
                                          }else if(wObj.Resolution_Typology__c == Constants.REPLACE){
                                              wObj.Replace__c = Constants.WITHIN_5_DAYS;
                                          }
                                      }
                                      when 'P2' {
                                          wObj.Resolution_Priority__c = Constants.PRIORITY_2;
                                          if(wObj.Resolution_Typology__c == Constants.REPAIR){
                                              wObj.Repair__c = Constants.WITHIN_2_DAYS;
                                          }else if(wObj.Resolution_Typology__c == Constants.REPLACE){
                                              wObj.Replace__c = Constants.WITHIN_7_DAYS;
                                          }
                                      }
                                      when 'P3' {
                                          wObj.Resolution_Priority__c = Constants.PRIORITY_3;
                                          if(wObj.Resolution_Typology__c == Constants.REPAIR){
                                              wObj.Repair__c = Constants.WITHIN_5_DAY;
                                          }else if(wObj.Resolution_Typology__c == Constants.REPLACE){
                                              wObj.Replace__c = Constants.WITHIN_14_DAYS;
                                          }
                                      } 
                                      when 'PE' {//PE  Emergency    
                                          wObj.Resolution_Priority__c = Constants.EMERGENCY;
                                          if(wObj.Resolution_Typology__c == Constants.REPAIR){
                                              wObj.Repair__c = Constants.WITHIN_2_HOURS;
                                          }else if(wObj.Resolution_Typology__c == Constants.REPLACE){
                                              wObj.Replace__c = Constants.WITHIN_2_DAY;
                                          }
                                      }
                                  }
                              }                                  
                          }                           
                   }                    
            }*/
        }        
    }
     public static void updateResolutionPriority(List<WorkOrder> newWorkOrders, Map<Id, WorkOrder> oldWorkOrders){
           set<Id> projectId = new set<Id>();
        //Set<String> locationSet = new Set<String>();
        Set<String> categorySet = new Set<String>(); // NEW CHANGES
        Set<String> problemCodeSet = new Set<String>(); // NEW CHANGES
        Set<String> subCategorySet = new Set<String>();
        Set<String> incidentDescriptionSet = new Set<String>();
        Set<String> resolutionTypologySet = new Set<String>();        
        Set<Id> unitIdSet = new Set<Id>();
        
        for(WorkOrder wo : newWorkOrders) {
            if(wo.Sub_category__c!=null && wo.Sub_category__c!=oldWorkOrders.get(wo.id).Sub_category__c){
                 subCategorySet.add(wo.Sub_category__c);
                System.debug('subCategorySet'+subCategorySet);
            }
           
            incidentDescriptionSet.add(wo.Incident_description__c);
            System.debug('incidentDescriptionSet'+incidentDescriptionSet);
            resolutionTypologySet.add(wo.Resolution_Typology__c);
              System.debug('resolutionTypologySet'+resolutionTypologySet);
            
                               
        }
        
        if( subCategorySet.isEmpty() && incidentDescriptionSet.isEmpty() && resolutionTypologySet.isEmpty()){// && locationSet.isEmpty()
            //  return null;
        } 
        //Category,Sub Category,Incident Description,Resolution Typology to be used as => Key
        Map<String,Service_Catalogue__c> keyToServiceCatalogueMap = new Map<String,Service_Catalogue__c>();
        List<Service_Catalogue__c> serviceCatalogList = [SELECT Id, Name, Location__c, Replace__c, Repair__c, Closure_Reason__c, Category__c, Sub_category__c, 
                                                         Incident_description__c, Resolution_Priority__c, Resolution_Typology__c, Problem_Code__c
                                                         FROM Service_Catalogue__c
                                                         WHERE Sub_category__c IN :subCategorySet 
                                                         AND Incident_description__c IN :incidentDescriptionSet                                                       
                                                        ];
       System.debug('serviceCatalogList'+serviceCatalogList);
        for(Service_Catalogue__c serCatRec : serviceCatalogList){
            if(String.isNotBlank(serCatRec.Category__c) && String.isNotBlank(serCatRec.Incident_description__c)
            && String.isNotBlank(serCatRec.Resolution_Typology__c) && String.isNotBlank(serCatRec.Sub_category__c)
            ){
                String keyTemp = (serCatRec.Category__c+serCatRec.Sub_category__c+serCatRec.Incident_description__c+serCatRec.Resolution_Typology__c).toLowerCase();
                keyToServiceCatalogueMap.put(keyTemp, serCatRec);
                System.debug('keyToServiceCatalogueMap'+keyToServiceCatalogueMap);
            }
        }
        
       
        for(workOrder wObj: newWorkOrders){
            String key1 = '';
            String key2 = '';
           
            //As per new chnages if a record is not found for matching Typology then pick the one that is available 
            Service_Catalogue__c serCatRec = new Service_Catalogue__c();
            //keyToServiceCatalogueMap.put(serCatRec.Category__c+serCatRec.Sub_category__c+serCatRec.Incident_description__c+serCatRec.Resolution_Typology__c, serCatRec);
            key1 = (wObj.Category__c+wObj.Sub_category__c+wObj.Incident_description__c+wObj.Resolution_Typology__c).toLowerCase();
            if(wObj.Resolution_Typology__c == 'Repair'){
                key2 = (wObj.Category__c+wObj.Sub_category__c+wObj.Incident_description__c+'Replace').toLowerCase();
            } else {
                key2 = (wObj.Category__c+wObj.Sub_category__c+wObj.Incident_description__c+'Repair').toLowerCase();
            }
           
            if(keyToServiceCatalogueMap.containsKey(key1)) {
                serCatRec = keyToServiceCatalogueMap.get(key1);
            } else if(keyToServiceCatalogueMap.containsKey(key2)){
                serCatRec = keyToServiceCatalogueMap.get(key2);
            }

            if (serCatRec != NULL && String.isNotBlank(serCatRec.Resolution_Priority__c)) {
                switch on serCatRec.Resolution_Priority__c {
                    when 'P1' {
                        wObj.Resolution_Priority__c = Constants.PRIORITY_1;
                        if(wObj.Resolution_Typology__c == Constants.REPAIR){
                            wObj.Repair__c = Constants.WITHIN_1_DAY;
                        }else if(wObj.Resolution_Typology__c == Constants.REPLACE){
                            wObj.Replace__c = Constants.WITHIN_5_DAYS;
                        }
                    }
                    when 'P2' {
                        wObj.Resolution_Priority__c = Constants.PRIORITY_2;
                        if(wObj.Resolution_Typology__c == Constants.REPAIR){
                            wObj.Repair__c = Constants.WITHIN_2_DAYS;
                        }else if(wObj.Resolution_Typology__c == Constants.REPLACE){
                            wObj.Replace__c = Constants.WITHIN_7_DAYS;
                        }
                    }
                    when 'P3' {
                        wObj.Resolution_Priority__c = Constants.PRIORITY_3;
                        if(wObj.Resolution_Typology__c == Constants.REPAIR){
                            wObj.Repair__c = Constants.WITHIN_5_DAY;
                        }else if(wObj.Resolution_Typology__c == Constants.REPLACE){
                            wObj.Replace__c = Constants.WITHIN_14_DAYS;
                        }
                    } 
                    when 'PE' {//PE  Emergency    
                        wObj.Resolution_Priority__c = Constants.EMERGENCY;
                        if(wObj.Resolution_Typology__c == Constants.REPAIR){
                            wObj.Repair__c = Constants.WITHIN_2_HOURS;
                        }else if(wObj.Resolution_Typology__c == Constants.REPLACE){
                            wObj.Replace__c = Constants.WITHIN_2_DAY;
                        }
                    }
                }
            } 
        }
        }
    
    
    //before update
    public static void updateWorkOrder(List<WorkOrder> workOrderList, Map<Id, WorkOrder> workOrderOldMap ){
        Map<Id,Id> woIdToEntitlementIdMap = new Map<Id,Id>();
        for(WorkOrder wrkObj: workOrderList){
            if(wrkObj.Type_of_Incident__c != workOrderOldMap.get(wrkObj.Id).Type_of_Incident__c && (wrkObj.Type_of_Incident__c == Constants.OUT_OF_SCOPE || wrkObj.Type_of_Incident__c == Constants.WARRANTY_POST_DLP)){
                wrkObj.Status = Constants.CLOSED;
            }

            if(wrkObj.Status == Constants.CLOSED && workOrderOldMap.get(wrkObj.Id).Status != wrkObj.Status && wrkObj.Closure_Reason__c == Constants.WORK_COMPLETED){
                woIdToEntitlementIdMap.put(wrkObj.Id, wrkObj.EntitlementId);
                wrkObj.ScheduledAppointmentTimeStarted__c = false;
            }

            if(((String.isNotBlank(wrkObj.Is_Tenet_Request__c) && wrkObj.Is_Tenet_Request__c != workOrderOldMap.get(wrkObj.Id).Is_Tenet_Request__c) ||
                (wrkObj.Requester_Name__c != workOrderOldMap.get(wrkObj.Id).Requester_Name__c || wrkObj.Requester_Email__c != workOrderOldMap.get(wrkObj.Id).Requester_Email__c || wrkObj.Requester_Phone__c != workOrderOldMap.get(wrkObj.Id).Requester_Phone__c)) &&
               wrkObj.Is_Tenet_Request__c == 'Owner'){
                   wrkObj.Requester_Name__c = wrkObj.Customer_Name__c;
                   //wrkObj.Requester_Comment__c = wrkObj.Customer_Comment__c;                
                   
                   if(String.isBlank(wrkObj.Requester_Email__c)){
                       wrkObj.Requester_Email__c = wrkObj.Customer_Email__c;                    
                   }
                   if(String.isBlank(wrkObj.Requester_Phone__c)){
                       wrkObj.Requester_Phone__c = wrkObj.Customer_Phone__c;                    
                   }                
               } 
            
            /*    // update Replace, Repair based on Resolution Typology 
System.debug('wrkObj >> ' + wrkObj);
if(String.isNotBlank(wrkObj.Resolution_Typology__c) && wrkObj.Resolution_Typology__c != workOrderOldMap.get(wrkObj.Id).Resolution_Typology__c && String.isNotBlank(wrkObj.Scope__c) && wrkObj.Scope__c == Constants.UNDER_SCOPE){
System.debug('wrkObj.Resolution_Priority__c >> ' + wrkObj.Resolution_Priority__c);
if (String.isNotBlank(wrkObj.Resolution_Priority__c)) {
switch on wrkObj.Resolution_Priority__c {
when 'Priority 1' {
if(wrkObj.Resolution_Typology__c == Constants.REPAIR){
wrkObj.Repair__c = Constants.WITHIN_1_DAY;
wrkObj.Replace__c = '';
}else if(wrkObj.Resolution_Typology__c == Constants.REPLACE){
wrkObj.Replace__c = Constants.WITHIN_5_DAYS;
wrkObj.Repair__c = '';
}
}
when 'Priority 2' {
if(wrkObj.Resolution_Typology__c == Constants.REPAIR){
wrkObj.Repair__c = Constants.WITHIN_2_DAYS;
wrkObj.Replace__c = '';
}else if(wrkObj.Resolution_Typology__c == Constants.REPLACE){
wrkObj.Replace__c = Constants.WITHIN_7_DAYS;
wrkObj.Repair__c = '';
}
}
when 'Priority 3' {
if(wrkObj.Resolution_Typology__c == Constants.REPAIR){
wrkObj.Repair__c = Constants.WITHIN_5_DAY;
wrkObj.Replace__c = '';
}else if(wrkObj.Resolution_Typology__c == Constants.REPLACE){
wrkObj.Replace__c = Constants.WITHIN_14_DAYS;
wrkObj.Repair__c = '';
}
} 
when 'Emergency' {                                         
if(wrkObj.Resolution_Typology__c == Constants.REPAIR){
wrkObj.Repair__c = Constants.WITHIN_2_HOURS;
wrkObj.Replace__c = '';
}else if(wrkObj.Resolution_Typology__c == Constants.REPLACE){
wrkObj.Replace__c = Constants.WITHIN_2_DAY;
wrkObj.Repair__c = '';
}
}
}
}
System.debug('after wrkObj >> ' + wrkObj);
} */
        }

        if(!woIdToEntitlementIdMap.isEmpty()){
            completeMilestone(woIdToEntitlementIdMap.keySet());
        }
    }
    
    //after insert
    public static void createServiceAppointment(List<WorkOrder> workOrders){
        Set<Id> projectIds = new Set<Id>();
        Set<Id> unitIdSet = new Set<Id>();
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
            ServiceAppointment newSA = new ServiceAppointment();            
            
            if (String.isNotBlank(wrkObj.Project__c) && sortedStMap2.containsKey(wrkObj.Project__c)) {
                newSA.ServiceTerritoryId = sortedStMap2.get(wrkObj.Project__c).Id;
            } 
            if (unitMap.containsKey(wrkObj.Unit__c) && String.isNotBlank(unitMap.get(wrkObj.Unit__c).Name)) {
    newSA.Unit_Number__c = unitMap.get(wrkObj.Unit__c).Name;
            } 
            
            newSa.FSL__Emergency__c = wrkObj.Is_Emergency__c;
            newSa.WorkOrderSubCatagory__c = wrkObj.Sub_category__c;
            newSa.Incident_description__c = wrkObj.Incident_description__c; 
            newSA.ParentRecordId = wrkObj.Id;            
            newSA.Status = Constants.NONE;
            newSA.Duration = 1;  // NEW CHANGES    
            newSA.EarliestStartTime = System.now();            
            newSA.DueDate = System.now().addDays(7); 
            //  newSa.FSL__InternalSLRGeolocation__Latitude__s = unitMap.get(wrkObj.Unit__c).Location__Latitude__s;
            //  newSa.FSL__InternalSLRGeolocation__Longitude__s = unitMap.get(wrkObj.Unit__c).Location__Longitude__s;
            newSa.Longitude = unitMap.get(wrkObj.Unit__c).Location__Longitude__s;
            newSa.Latitude = unitMap.get(wrkObj.Unit__c).Location__Latitude__s;
            if (String.isNotBlank(wrkObj.Subject)) {
                newSA.Subject = wrkObj.Subject;
            }
            if (String.isNotBlank(wrkObj.Description)) {
                newSA.Description = wrkObj.Description;
            }
            
            serviceAppointmentList.add(newSA); 
        }      
        
        ServiceAppointmentService objServiceAppointmentService = ServiceAppointmentService.getInstance(); 
        serviceAppointmentList = objServiceAppointmentService.insertServiceAppointmentsWithTrigger(serviceAppointmentList);
    }
    
    //after update
    public static void processWorkOrders(List<WorkOrder> newWorkOrders, Map<Id, WorkOrder> oldWorkOrders) {   
        Set<Id> workOrderIds = new Set<Id>(); 
        Set<Id> ownerIds = new Set<Id>();  
        Set<String> contentDocumentIds = new Set<String>();
        List<Case> caseUpdate = new List<Case>();
        Map<Id, ServiceAppointment> woIdSaMap = new Map<Id, ServiceAppointment>();
        List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
        EmailService objEmailService = EmailService.getInstance();
        WorkOrderService objWorkOrderService = WorkOrderService.getInstance();
        //List<ServiceAppointment> serviceAppointmentListToUpdate = new List<ServiceAppointment>();
        
        EmailTemplate mailTemplateCustomerNotAvailable = EmailUtil.getEmailTemplateByName(CUSTOMER_NOT_AVAILABLE); 
        EmailTemplate mailTemplateWorkOrderClosedForCustomer = EmailUtil.getEmailTemplateByName(WORKORDER_CLOSED_NOTIFICATION_FOR_CUSTOMER);
        EmailTemplate mailTemplateCustomerNotAvailableWorkOrderClose = EmailUtil.getEmailTemplateByName(CUSTOMER_NOT_AVAILABLE_WORK_ORDER_CLOSE);
        EmailTemplate mailTemplateDlpOutOfScopeForCustomer = EmailUtil.getEmailTemplateByName(DLP_OUT_OF_SCOPE_FOR_CUSTOMER);
        OrgWideEmailAddress orgWideEmail = objEmailService.getOrgWideEmailAddressByDisplayName(Constants.BLOOM_NO_REPLY_LABEL);
        
        Map<Id, WorkOrder> workOrderMap = new Map<Id, WorkOrder>();        
        if(objWorkOrderService.getWorkOrdersByIds(newWorkOrders) != null){
            workOrderMap = new Map<Id, WorkOrder>(objWorkOrderService.getWorkOrdersByIds(newWorkOrders));
        }         
        
        for (WorkOrder wo : newWorkOrders) {
            workOrderIds.add(wo.Id);
            ownerIds.add(wo.OwnerId);
        }
        
        Map<Id, ContentDocumentLink> contentDocumentLinkMap = new Map<Id, ContentDocumentLink>();
        ContentService contentServiceObj = ContentService.getInstance();
        if(contentServiceObj.getContentDocumentLinksByLinkedEntityId(workOrderIds) != null){
            contentDocumentLinkMap = new Map<Id, ContentDocumentLink> (contentServiceObj.getContentDocumentLinksByLinkedEntityId(workOrderIds));            
        }
        System.debug('contentDocumentLinkMap >> ' + contentDocumentLinkMap);   
        
        Set<Id> contentDocumentLinkIds = new Set<Id>();
        for(ContentDocumentLink cdl: contentDocumentLinkMap.Values()){
            if(String.isNotBlank(cdl.ContentDocumentId)){
                contentDocumentLinkIds.add(cdl.ContentDocumentId);
            }            
        }
        
        List<ContentVersion> contentVersionList = new List<ContentVersion>();
        if(contentServiceObj.getContentVersionsByLinkedEntityId(contentDocumentLinkIds) != null){
            contentVersionList = contentServiceObj.getContentVersionsByLinkedEntityId(contentDocumentLinkIds);            
        }        
        System.debug('contentVersionList >> ' + contentVersionList);   
        
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
        System.debug('workOrderContentVersionMap >> ' + workOrderContentVersionMap);
        
        
        Map<Id, ServiceAppointment> saMap = new Map<Id, ServiceAppointment>();
        ServiceAppointmentService objServiceAppointmentService = ServiceAppointmentService.getInstance(); 
        if(objServiceAppointmentService.getServiceAppointmentsByParentRecordIds(newWorkOrders) != null){
            saMap = new Map<Id, ServiceAppointment>(objServiceAppointmentService.getServiceAppointmentsByParentRecordIds(newWorkOrders));            
        }
        
        for(ServiceAppointment sa: saMap.Values()){
            woIdSaMap.put(sa.ParentRecordId, sa);
        }
        System.debug('woIdSaMap >> ' + woIdSaMap);   
        
        UserService objUserService = UserService.getInstance();
        Map<Id, User> ownersMap = new Map<Id, User>();
        if(objUserService.getUsersByIds(ownerIds) != null){
            ownersMap = new Map<Id, User>(objUserService.getUsersByIds(ownerIds));  
        }        
        
        for (WorkOrder wo : newWorkOrders) {
            System.debug('new WorkOrder >> ' + wo);                
            WorkOrder oldWO = oldWorkOrders.get(wo.Id);
            WorkOrder workOrderObj = workOrderMap.get(wo.Id);
            ServiceAppointment servApp = woIdSaMap.get(wo.Id);
            User owner = ownersMap.get(wo.OwnerId);
            ContentVersion contentVersionObj = new  ContentVersion();
            if(!workOrderContentVersionMap.isEmpty()){
                contentVersionObj = workOrderContentVersionMap.get(wo.Id);                
            }
            System.debug('contentVersionObj >> ' + contentVersionObj);
            System.debug('servApp >> ' + servApp);
            if (wo.Check_In__c == true && wo.Customer_Availability__c == Constants.NOT_AVAILABLE && oldWO.Check_In__c != wo.Check_In__c && wo.Status != Constants.CLOSED) {
                //workOrderIds.add(wo.Id);
                contentDocumentIds.add(wo.Customer_Absence_Image_Id__c); 
                mailList.add(DLPEmailHandler.sendEmailProcess(mailTemplateCustomerNotAvailable, workOrderObj, servApp, new List<String>{wo.New_Requester_Email__c}, contentVersionObj, orgWideEmail));                        
                System.debug('W1. mailList not null >> ' + mailList != null);              
            }
           // if(wo.CaseId != null){
                if(wo.Status == Constants.CLOSED && wo.Customer_Availability__c == Constants.NOT_AVAILABLE){
                    Case cs = new Case();
                    cs.Status = Constants.CLOSED;
                    cs.Closure_Comment__c = Constants.CUSTOMER_NOT_AVAILABLE_WHEN_AGENT_VISITED;
                    cs.Closure_Reason__c = Constants.CUSTOMER_NOT_AVAILABLE_LABEL;
                    cs.Id = wo.CaseId;
                    caseUpdate.add(cs);   
                    if(wo.New_Requester_Email__c != null  && mailTemplateCustomerNotAvailableWorkOrderClose != null){
                    mailList.add(DLPEmailHandler.sendEmailProcess(mailTemplateCustomerNotAvailableWorkOrderClose, workOrderObj, servApp, new List<String>{wo.New_Requester_Email__c}, contentVersionObj, orgWideEmail));                        
                    }                     
                }else if(wo.Status == Constants.CLOSED && wo.Type_of_Incident__c == Constants.OUT_OF_SCOPE){
                    Case cs = new Case();
                    cs.Status = Constants.CLOSED;
                    cs.Closure_Comment__c = Constants.OUT_OF_DLP_SCOPE;
                    cs.Closure_Reason__c = Constants.OUT_OF_SCOPE;
                    cs.Id = wo.CaseId;
                    caseUpdate.add(cs); 
                    if(wo.New_Requester_Email__c != null  && mailTemplateDlpOutOfScopeForCustomer != null){
                        mailList.add(DLPEmailHandler.sendEmailProcess(mailTemplateDlpOutOfScopeForCustomer, workOrderObj, servApp, new List<String>{wo.New_Requester_Email__c}, contentVersionObj, orgWideEmail));                        
                        System.debug('W3. mailList not null >> ' + mailList != null);                        
                    }
                }else if(wo.Status == Constants.CLOSED && wo.Type_of_Incident__c == Constants.WARRANTY_POST_DLP){
                    Case cs = new Case();
                    cs.Status = Constants.CLOSED;
                    cs.Closure_Comment__c = Constants.OUT_OF_DLP_SCOPE;
                    cs.Closure_Reason__c = Constants.OUT_OF_SCOPE;
                    cs.Id = wo.CaseId;
                    caseUpdate.add(cs);
                } else if(wo.Status == Constants.CLOSED && wo.Scope__c == Constants.OUTSIDE_SCOPE){
                    Case cs = new Case();
                    cs.Status = Constants.CLOSED;
                    cs.Closure_Comment__c = Constants.OUT_OF_DLP_SCOPE;
                    cs.Closure_Reason__c = Constants.OUT_OF_SCOPE;
                    cs.Id = wo.CaseId;
                    caseUpdate.add(cs);
                } else if(wo.Status == Constants.CLOSED && wo.Closure_Reason__c == Constants.WORK_COMPLETED){
                    Case cs = new Case();
                    cs.Status = Constants.RESOLVED;
                    cs.Resolution_Comments__c = Constants.WORK_COMPLETED;
                    cs.Closure_Comment__c = Constants.CASE_RESOLVED;
                    cs.Closure_Reason__c = Constants.WORK_COMPLETED;
                    cs.Id = wo.CaseId;
                    caseUpdate.add(cs);
                    if(wo.New_Requester_Email__c != null && mailTemplateWorkOrderClosedForCustomer != null ){
                        //Work order marked as completed &amp; closed and related cases will be closed automatically. Then customer receives Email confirmation for case resolved.
                        mailList.add(DLPEmailHandler.sendEmailProcess(mailTemplateWorkOrderClosedForCustomer, workOrderObj, servApp, new List<String>{wo.New_Requester_Email__c,workOrderObj.Owner.Email}, null, orgWideEmail));
                    }
                }
            //}

            /*if(wo.Status == Constants.CLOSED && oldWO.Status != wo.Status && servApp.Status != Constants.COMPLETED_LABEL){
                servApp.Status = Constants.COMPLETED_LABEL;
                if(wo.Closure_Reason__c != NULL){
                    servApp.Closure_Reason__c = wo.Closure_Reason__c == Constants.WORK_COMPLETED  ? 'Work Closed' : wo.Closure_Reason__c;
                } else {
                    servApp.Closure_Reason__c = 'Work Closed';
                }
                serviceAppointmentListToUpdate.add(servApp);
            }*/
        }
        
        CaseService objCaseService = CaseService.getInstance();
        //caseUpdate = objCaseService.updateCaseWithoutTrigger(caseUpdate);
        
        //serviceAppointmentListToUpdate = objServiceAppointmentService.updateServiceAppointmentsWithoutTrigger(serviceAppointmentListToUpdate);
        if(!Test.IsRunningTest()){
            List<Messaging.SendEmailResult> mails = objEmailService.sendEmail(mailList);
        }
    }

    public static void closeServiceAppointmentsOnWorkOrderClosure(List<WorkOrder> newWorkOrders, Map<Id, WorkOrder> oldWorkOrders){
        Map<Id, List<ServiceAppointment>> woIdSaMap = new Map<Id, List<ServiceAppointment>>();
        Map<Id, ServiceAppointment> saMap = new Map<Id, ServiceAppointment>();
        ServiceAppointmentService objServiceAppointmentService = ServiceAppointmentService.getInstance(); 
        List<ServiceAppointment> serviceAppointmentListToUpdate = new List<ServiceAppointment>();
        Map<Id,Id> woIdToEntitlementIdMap = new Map<Id,Id>();
        
        if(objServiceAppointmentService.getServiceAppointmentsByParentRecordIds(newWorkOrders) != null){
            saMap = new Map<Id, ServiceAppointment>(objServiceAppointmentService.getServiceAppointmentsByParentRecordIds(newWorkOrders));            
        }
        
        for(ServiceAppointment sa: saMap.Values()){
            if(!woIdSaMap.containsKey(sa.ParentRecordId)){
                woIdSaMap.put(sa.ParentRecordId, new List<ServiceAppointment>());
            }
            woIdSaMap.get(sa.ParentRecordId).add(sa);
        }
        System.debug('woIdSaMap >> ' + woIdSaMap);

        for (WorkOrder wo : newWorkOrders) {
            WorkOrder oldWO = oldWorkOrders.get(wo.Id);
            List<ServiceAppointment> servAppList = woIdSaMap.get(wo.Id);
            System.debug('servAppList >> ' + servAppList);
            if(wo.Status == Constants.CLOSED && oldWO.Status != wo.Status && servAppList != NULL){
                 if(wo.Closure_Reason__c == Constants.WORK_COMPLETED){
                    woIdToEntitlementIdMap.put(wo.Id, wo.EntitlementId);
                } 

                for(ServiceAppointment servAppRec : servAppList){
                    if(servAppRec.Status != Constants.COMPLETED_LABEL){
                        servAppRec.Status = Constants.COMPLETED_LABEL;
                        if(wo.Closure_Reason__c != NULL){
                            servAppRec.Closure_Reason__c = wo.Closure_Reason__c == Constants.WORK_COMPLETED  ? 'Work Closed' : wo.Closure_Reason__c;
                        } else {
                            servAppRec.Closure_Reason__c = 'Work Closed';
                        }
                        if(wo.Type_of_Incident__c == Constants.OUT_OF_SCOPE){
                            servAppRec.Job_Status__c= Constants.UNDER_SCOPE;
                        }
                    }
                    serviceAppointmentListToUpdate.add(servAppRec);
                }
            }
        }

        if(!woIdToEntitlementIdMap.isEmpty()){
            completeMilestone(woIdToEntitlementIdMap.keySet());
            updateEntitlementIdOnWorkOrder(woIdToEntitlementIdMap);
        } 
        
        serviceAppointmentListToUpdate = objServiceAppointmentService.updateServiceAppointmentsWithoutTrigger(serviceAppointmentListToUpdate);
    }
    
    public static void createEntitlementOnWorkOrder(List<WorkOrder> workOrders) {
        Set<Id> accountIds = new Set<Id>();
        for (WorkOrder wo : workOrders) {
            if (wo.AccountId != null) {
                accountIds.add(wo.AccountId);
            }
        }
        
        if(accountIds.isEmpty()) return;
        //Map<Id, Entitlement> existingEntitlements = new Map<Id, Entitlement>();
        EntitlementService objEntitlementService = EntitlementService.getInstance();
        /*if(objEntitlementService.getEntitlementsByAccountId(accountIds) != null){
            existingEntitlements = new Map<Id, Entitlement>(objEntitlementService.getEntitlementsByAccountId(accountIds));            
        }*/
        List<Entitlement> entitlementList = objEntitlementService.getEntitlementsByAccountId(accountIds);
        Map<Id, List<Entitlement>> accountIdToExistingEntitlementMap = new Map<Id, List<Entitlement>>();
        for(Entitlement entitlementRec : entitlementList){
            if(!accountIdToExistingEntitlementMap.containsKey(entitlementRec.AccountId)){
                accountIdToExistingEntitlementMap.put(entitlementRec.AccountId, new List<Entitlement>());
            }
            accountIdToExistingEntitlementMap.get(entitlementRec.AccountId).add(entitlementRec);
        }
        
        SlaProcessService objSlaProcessService = SlaProcessService.getInstance();
        SlaProcess ep = new SlaProcess();
        ep = objSlaProcessService.getSlaProcessByName(WORKORDER_ENTITLEMENT);
        
        List<Entitlement> newEntitlements = new List<Entitlement>();
        for (WorkOrder wo : workOrders) {
            if (wo.AccountId != null && !accountIdToExistingEntitlementMap.containsKey(wo.AccountId)) {
                Entitlement ent = new Entitlement(
                    Name = NEW_WORK_ORDER_ENTITLEMENT,
                    AccountId = wo.AccountId,
                    StartDate = Date.today(),
                    EndDate = Date.today().addYears(1),
                    SlaProcessId = ep.Id
                );
                newEntitlements.add(ent);
                //existingEntitlements.put(wo.AccountId, ent);
            }
            else if (accountIdToExistingEntitlementMap.containsKey(wo.AccountId)){
                wo.EntitlementId = accountIdToExistingEntitlementMap.get(wo.AccountId)[0].Id;
            }
        }
        
        newEntitlements = objEntitlementService.insertEntitlementsWithTrigger(newEntitlements);  
        Map<Id, Id> accountToEntitlementIdMap = new Map<Id, Id>();
        for (Entitlement ent : newEntitlements) {
            accountToEntitlementIdMap.put(ent.AccountId, ent.Id);
        }
        for (WorkOrder wo : workOrders) {
            if (wo.AccountId != null && accountToEntitlementIdMap.containsKey(wo.AccountId)) {
                wo.EntitlementId = accountToEntitlementIdMap.get(wo.AccountId);
            }
        }
    }

    public static void completeMilestone(Set<Id> workorderIds){
        List<EntityMilestone> milestoneList = [SELECT Id, StartDate, IsViolated , TimeRemainingInMins, ParentEntityId, CompletionDate FROM EntityMilestone WHERE ParentEntityId IN :workorderIds AND CompletionDate = NULL];
        for(EntityMilestone milestoneRec : milestoneList){
            milestoneRec.CompletionDate = System.now();
        }
        update milestoneList;
    }

     @future
    public static void updateEntitlementIdOnWorkOrder(Map<Id,Id> woIdToEntitlementIdMap) {
        WorkOrderService objWorkOrderService = WorkOrderService.getInstance();  
        List<WorkOrder> woListToUpdate  = new List<WorkOrder>();
        List<WorkOrder> woListToUpdateTWO  = new List<WorkOrder>();

        for(Id woId : woIdToEntitlementIdMap.keySet()){
            WorkOrder wrkObj = new WorkOrder();
            wrkObj.Id = woId;
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

    /*public static void updateDueDate(List<WorkOrder> workOrderList, Map<Id, WorkOrder> workOrderOldMap) {
List<WorkOrder> updatedWorkOrders = new List<WorkOrder>();
for (WorkOrder wo : workOrderList) {
boolean isNewRecord = workOrderOldMap == null || !workOrderOldMap.containsKey(wo.Id);
if (isNewRecord || (wo.Resolution_Typology__c != null && 
!wo.Resolution_Typology__c.equals(workOrderOldMap.get(wo.Id).Resolution_Typology__c))) {
WorkOrder updatedWO = new WorkOrder();
updatedWO.id = wo.Id;
if (wo.Resolution_Priority__c == Constants.PRIORITY_1) {
if (wo.Resolution_Typology__c == Constants.REPAIR) {
updatedWO.Due_Date__c = Constants.WITHIN_1_DAY;
} else if (wo.Resolution_Typology__c == Constants.REPLACE) {
updatedWO.Due_Date__c = Constants.WITHIN_5_DAYS;
}
} else if (wo.Resolution_Priority__c == Constants.PRIORITY_2) {
if (wo.Resolution_Typology__c == Constants.REPAIR) {
updatedWO.Due_Date__c = Constants.WITHIN_2_DAYS;
} else if (wo.Resolution_Typology__c == Constants.REPLACE) {
updatedWO.Due_Date__c = Constants.WITHIN_7_DAYS;
}
} else if (wo.Resolution_Priority__c == Constants.PRIORITY_3) {
if (wo.Resolution_Typology__c == Constants.REPAIR) {
updatedWO.Due_Date__c = Constants.WITHIN_5_DAY;
} else if (wo.Resolution_Typology__c == Constants.REPLACE) {
updatedWO.Due_Date__c = Constants.WITHIN_14_DAYS;
}
} else if (wo.Resolution_Priority__c == 'Emergency') {
if (wo.Resolution_Typology__c == Constants.REPAIR) {
updatedWO.Due_Date__c = Constants.WITHIN_2_HOURS;
} else if (wo.Resolution_Typology__c == Constants.REPLACE) {
updatedWO.Due_Date__c = Constants.WITHIN_2_DAY;
}
}
updatedWorkOrders.add(updatedWO);
}
}

if (!updatedWorkOrders.isEmpty()) {
WorkOrderService objWorkOrderService = WorkOrderService.getInstance();
objWorkOrderService.updateWorkOrdersWithoutTrigger(updatedWorkOrders);
}
}*/
    
  /*  public static void updateDueDate(List<WorkOrder> workOrderList, Map<Id, WorkOrder> workOrderOldMap) {
        Map<String, DLP_Resolution_Settings__mdt> metadataMap = new Map<String, DLP_Resolution_Settings__mdt>();
        for (DLP_Resolution_Settings__mdt meta : [SELECT Resolution_Priority__c, Repair_Resolution__c,Is_Business_Hours__c,Business_Hours_Id__c,Repair_Resolution_SLA_Type__c, Replace_Resolution__c, Replace_Resolution_SLA_Type__c
                                                  FROM DLP_Resolution_Settings__mdt]){
                                                      metadataMap.put(meta.Resolution_Priority__c, meta);
                                                  }
        List<WorkOrder> updatedWorkOrders = new List<WorkOrder>();
        for (WorkOrder wo : workOrderList) {
            boolean isNewRecord = workOrderOldMap == null || !workOrderOldMap.containsKey(wo.Id);
            if (isNewRecord || (wo.Resolution_Typology__c != null && 
                                !wo.Resolution_Typology__c.equals(workOrderOldMap.get(wo.Id).Resolution_Typology__c))) {
                                    WorkOrder updatedWO = new WorkOrder();
                                    updatedWO.id = wo.Id;
                                    if (metadataMap.containsKey(wo.Resolution_Priority__c)) {
                                        DLP_Resolution_Settings__mdt meta = metadataMap.get(wo.Resolution_Priority__c);
                                        if(meta.Is_Business_Hours__c == false){
                                            if (wo.Resolution_Typology__c == Constants.REPAIR) {
                                                if(meta.Repair_Resolution_SLA_type__c == Constants.HOURS){
                                                    updatedWO.Due_Date__c = wo.CreatedDate.addHours(Integer.valueOf(meta.Repair_Resolution__c)).format(); 
                                                }
                                                else{
                                                    updatedWO.Due_Date__c = wo.CreatedDate.addDays(Integer.valueOf(meta.Repair_Resolution__c)).format();
                                                }
                                            } else if (wo.Resolution_Typology__c == Constants.REPLACE) {
                                                if(meta.Replace_Resolution_SLA_type__c == Constants.HOURS){
                                                    updatedWO.Due_Date__c = wo.CreatedDate.addHours(Integer.valueOf(meta.Replace_Resolution__c)).format(); 
                                                }
                                                else{
                                                    updatedWO.Due_Date__c = wo.CreatedDate.addDays(Integer.valueOf(meta.Replace_Resolution__c)).format();
                                                }
                                            }
                                            updatedWorkOrders.add(updatedWO);
                                        } 
                                        else{
                                            if(wo.Resolution_Typology__c == Constants.REPAIR){
                                                if (meta.Repair_Resolution_SLA_type__c == Constants.HOURS){
                                                    updatedWO.Due_Date__c = String.valueOf(BusinessHours.add(
                                                        meta.Business_Hours_Id__c, wo.CreatedDate, 
                                                        Integer.valueOf(meta.Repair_Resolution__c)*60*60*1000).format());
                                                }
                                                else{
                                                    updatedWO.Due_Date__c = String.valueOf(BusinessHours.add(
                                                        meta.Business_Hours_Id__c,wo.CreatedDate, 
                                                        Integer.valueOf(meta.Repair_Resolution__c)*24*60*60*1000).format());
                                                }
                                            }
                                            else if(wo.Resolution_Typology__c == Constants.REPLACE){
                                                if (meta.Replace_Resolution_SLA_type__c == Constants.HOURS){
                                                    updatedWO.Due_Date__c = String.valueOf(BusinessHours.add(
                                                        meta.Business_Hours_Id__c, wo.CreatedDate, 
                                                        Integer.valueOf(meta.Replace_Resolution__c)*60*60*1000).format());
                                                }
                                                else{
                                                    updatedWO.Due_Date__c = String.valueOf(BusinessHours.add(
                                                        meta.Business_Hours_Id__c,wo.CreatedDate, 
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
    }*/
    
}