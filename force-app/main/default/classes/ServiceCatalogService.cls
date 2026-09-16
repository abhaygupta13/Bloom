/*
* @Author : EaglesDev
* @CreatedDate : 9th Nov 2024
* @Description :  ServiceCatalog Service class
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           EaglesDev   9th Nov 2024    Initial draft 
*****************************************************************************************************/
public class ServiceCatalogService {
    private static ServiceCatalogService instance;
    
    public ServiceCatalogService() {
    }
    
    public static ServiceCatalogService getInstance() {
      if (instance == null) {
            instance = new ServiceCatalogService();
        }
        return instance;
    }
    public  List<ServiceCatalog__c> getServiceCatalogByLocation(String selectedType, String selectedCategory, String selectedSubCategory,String location){
        return[SELECT Id, Name, Type__c, Category__c, SubCategory__c,RecordTypeDevName__c
               FROM ServiceCatalog__c 
               WHERE Type__c =:selectedType 
               AND Category__c =:selectedCategory 
               AND  SubCategory__c =:selectedSubCategory 
               AND Location__c =:location LIMIT 1];
        
    }
    
    public static List<Service_Catalog__c> fetchServiceCatalogByName(String catalogName){
        return  [select Id,Name,Amount__c  from Service_Catalog__c where Name=:catalogName];
    }
    
    
    public static List<Service_Catalog__c > fetchServices(String serviceId){
        
        return [select Name from Service_Catalog__c  where Id=:serviceId];
    }
    public static List<Service_Catalog_Fields__c> getServiceCatalogFields(String sCatalogId){
        
        return [SELECT Name,Field_API_Name__c,User_Type__c, is_Date__c,is_Decimal__c FROM Service_Catalog_Fields__c  where Service_Catalog__c =:sCatalogId];
    }
    
    public static List<Service_Catalog__c> getServiceCatalogAndrelatedDocuments(){
        return [SELECT Access_To__c,Name,Image_URL__c,
                (select Document_Name__c ,Document_Type__c ,Document_Size__c from Service_Catolog_Documents__r) 
                FROM Service_Catalog__c where Active__c = true];
    }
    
    public static Map<id, Service_Catalog__c> getServiceCatalogAndrelatedDocuments( Set<Id> serviceCatalogIds){
        
        return new Map<id, Service_Catalog__c>([ SELECT Name,
                                                (
                                                    SELECT id, Name, Required_For__c, is_Chiller_Enabled__c
                                                    FROM Service_Catolog_Documents__r
                                                )
                                                FROM Service_Catalog__c
                                                WHERE id IN :serviceCatalogIds
                                               ]
                                              );
    }
    
    public  List<ServiceCatalog__c> getServiceCatalog(String selectedType, String selectedCategory, String selectedSubCategory){
        return[SELECT Id, Name, Type__c, Category__c, SubCategory__c,RecordTypeDevName__c,OwnerId,SubCategoryArabic__c
               FROM ServiceCatalog__c 
               WHERE Type__c =:selectedType 
               AND Category__c =:selectedCategory 
               AND  SubCategory__c =:selectedSubCategory LIMIT 1];
        
    }
    
    public List<ServiceCatalog__c> getServiceCatalogByName(String catalogName){
        return [SELECT Id, Name, Type__c, Category__c, SubCategory__c,RecordTypeDevName__c FROM ServiceCatalog__c WHERE Name =:catalogName];
    }
    
    public List<AggregateResult> getServiceCatalogType(){
        return [SELECT Type__c FROM ServiceCatalog__c WHERE Type__c != null AND Active__c = true GROUP BY Type__c];
    }
    
    public List<AggregateResult> getServiceCatalogCategories(String type,String objectName){
        if(objectName == null){
        return [SELECT Category__c FROM ServiceCatalog__c WHERE Type__c = :type AND Category__c != null AND Active__c = true GROUP BY Category__c];
        }
        return [SELECT Category__c FROM ServiceCatalog__c WHERE Type__c = :type AND Object__c INCLUDES (:objectName) AND Category__c != null AND Active__c = true GROUP BY Category__c];
    }
    
    public List<AggregateResult> getServiceCatalogSubCategories(String type, String category, String objectName){
        if(objectName == null){
        return [SELECT SubCategory__c FROM ServiceCatalog__c WHERE Type__c = :type AND Category__c = :category AND SubCategory__c != null AND Active__c = true  AND IsUISelectable__c =TRUE GROUP BY SubCategory__c ORDER BY SubCategory__c];
        }
        return [SELECT SubCategory__c FROM ServiceCatalog__c WHERE Type__c = :type AND Object__c INCLUDES (:objectName) AND Category__c = :category AND SubCategory__c != null AND Active__c = true  AND IsUISelectable__c =TRUE GROUP BY SubCategory__c ORDER BY SubCategory__c];
    }
    
    public List<ServiceCatalog__c> getServiceCatalogBySubCategories(String subCategory){
        return [SELECT SubCategory__c, AvailableForOwner__c, isNextButtonSelectable__c,ShowUnitAfterAccount__c,isUnitChangeRequired__c,AvailableForTenant__c, AllowDuplicateCases__c, RecordTypeDevName__c FROM ServiceCatalog__c WHERE SubCategory__c =: subCategory];
    }
    
    public  List<ServiceAction__c> getServActionsByCatalogId(Set<Id> serviceCatalogIds){
        return [SELECT Id, 
                FinalTask__c, Order__c, Department__c,
                ServiceCatalog__c, TaskSubType__c, TaskSubject__c, TaskType__c
                FROM ServiceAction__c 
                WHERE ServiceCatalog__c IN :serviceCatalogIds 
               ];
        
    }
    public  List<ServiceAction__c> getFinalServActionsByCatalogId(Set<Id> serviceCatalogIds){
        return [SELECT Id,FinalTask__c, Order__c, 
                ServiceCatalog__c, TaskSubType__c, TaskSubject__c, TaskType__c,Department__c
                FROM ServiceAction__c 
                WHERE ServiceCatalog__c IN :serviceCatalogIds and FinalTask__c = true
               ];
        
    }
    
    public  List<ServiceAction__c> getServActionsByCatalogIdAndOrder(List<String> catalogIdList,List<Integer> orderList){
        System.debug('catalogIdList'+catalogIdList);
        System.debug('orderList'+orderList);
        return [Select Id, AssignToOwner__c,OwnerId,Due_in_days__c, AssignToHOAgent__c,
                FinalTask__c, Order__c, ServiceCatalog__c, SubStatus__c,
                TaskSubType__c, TaskSubject__c, TaskType__c, Department__c, DefaultQueueId__c, SLAHours__c, HandoverStatus__c
                FROM ServiceAction__c 
                WHERE ServiceCatalog__c In :catalogIdList
                AND Order__c IN :orderList];
        
    }
    
    public List<ServiceAction__c> getServActionsByTasks(List<String> taskType, List<String> taskSubType){
        return  [SELECT Id,TaskType__c,TaskSubType__c,AssignToOwner__c,Department__c FROM ServiceAction__c WHERE TaskType__c IN :taskType AND TaskSubType__c IN :taskSubType];
    }
    
    public Map<Id, ServiceAction__c> getNextCaseServiceAction(List<Case> listOfCases) {
        // Initialize the result map to hold the mapping of case Id to ServiceAction
        Map<Id, ServiceAction__c> catalogVsActionMap = new Map<Id, ServiceAction__c>();
        
        // Create maps for storing necessary details about the cases
        Map<Id, String> mapOfCaseIdAndServiceCatalogId = new Map<Id, String>();
        Map<Id, Integer> mapOfCaseIdAndNextActionNewOrder = new Map<Id, Integer>();
        
        // Collect relevant data from listOfCases
        for (Case caseObj : listOfCases) {
            if (caseObj.ServiceCatalog__c != null && caseObj.Status != 'Closed') {
                mapOfCaseIdAndServiceCatalogId.put(caseObj.Id, caseObj.ServiceCatalog__c);
                if (caseObj.Step__c != 'Final') {
                    Integer nextOrder = Integer.valueOf(caseObj.Step__c) + 1;
                    mapOfCaseIdAndNextActionNewOrder.put(caseObj.Id, nextOrder);
                }
            }
        }
        
        // If there's any next action, fetch the corresponding service actions
        if (!mapOfCaseIdAndNextActionNewOrder.isEmpty()) {
            
            List<ServiceAction__c> serviceActions = getServActionsByCatalogIdAndOrder(
                mapOfCaseIdAndServiceCatalogId.values(), 
                mapOfCaseIdAndNextActionNewOrder.values()
            );
            // Populate the map with the fetched service actions
            if (!serviceActions.isEmpty()) {
                for (ServiceAction__c action : serviceActions) {
                    catalogVsActionMap.put(action.ServiceCatalog__c, action);
                }
            }
        }
        
        return catalogVsActionMap;
    }
    public Map<Id, ServiceAction__c> getPreviousCaseServiceAction(List<Case> listOfCases) {
        
        
        // Initialize the result map to hold the mapping of case Id to ServiceAction
        Map<Id, ServiceAction__c> catalogVsActionMap = new Map<Id, ServiceAction__c>();
        
        // Create maps for storing necessary details about the cases
        Map<Id, String> mapOfCaseIdAndServiceCatalogId = new Map<Id, String>();
        Map<Id, Integer> mapOfCaseIdAndPreviousActionOrder = new Map<Id, Integer>();
        
        // Collect relevant data from listOfCases
        for (Case caseObj : listOfCases) {
            if (caseObj.ServiceCatalog__c != null && caseObj.Status != 'Closed') {
                mapOfCaseIdAndServiceCatalogId.put(caseObj.Id, caseObj.ServiceCatalog__c);
                if (caseObj.Step__c!='Final'
                    && Integer.valueOf(caseObj.Step__c) > 1) {
                        Integer prevOrder = Integer.valueOf(caseObj.Step__c) -1;
                        mapOfCaseIdAndPreviousActionOrder.put(caseObj.Id, prevOrder);
                    }
                else if(caseObj.Step__c=='Final'){
                    
                    List<ServiceAction__c> actions=getFinalServActionsByCatalogId(new Set<Id>{caseObj.ServiceCatalog__c});
                    Integer prevOrder = Integer.valueOf(actions[0].Order__c)-1;
                    mapOfCaseIdAndPreviousActionOrder.put(caseObj.Id, prevOrder);
                }
            }
        }
        
        // If there's any prev action, fetch the corresponding service actions
        if (!mapOfCaseIdAndPreviousActionOrder.isEmpty()) {
            
            List<ServiceAction__c> serviceActions = getServActionsByCatalogIdAndOrder(
                mapOfCaseIdAndServiceCatalogId.values(), 
                mapOfCaseIdAndPreviousActionOrder.values()
            );
            
            // Populate the map with the fetched service actions
            if (!serviceActions.isEmpty()) {
                for (ServiceAction__c action : serviceActions) {
                    catalogVsActionMap.put(action.ServiceCatalog__c, action);
                }
            }
        }
        
        return catalogVsActionMap; 
        
    }
    public Map<Id, ServiceAction__c> getCurrentCaseServiceAction(List<Case> listOfCases) {
        
        
        // Initialize the result map to hold the mapping of case Id to ServiceAction
        Map<Id, ServiceAction__c> catalogVsActionMap = new Map<Id, ServiceAction__c>();
        
        // Create maps for storing necessary details about the cases
        Map<Id, String> mapOfCaseIdAndServiceCatalogId = new Map<Id, String>();
        Map<Id, Integer> mapOfCaseIdAndCurrentActionOrder = new Map<Id, Integer>();
        
        // Collect relevant data from listOfCases
        for (Case caseObj : listOfCases) {
            
            
            if (caseObj.ServiceCatalog__c != null && caseObj.Status != 'Closed') {
                mapOfCaseIdAndServiceCatalogId.put(caseObj.Id, caseObj.ServiceCatalog__c);
                if (caseObj.Step__c!='Final') {
                    Integer currentOrder = Integer.valueOf(caseObj.Step__c);
                    mapOfCaseIdAndCurrentActionOrder.put(caseObj.Id, currentOrder);
                }
                else if(caseObj.Step__c=='Final'){
                    
                    List<ServiceAction__c> actions=getFinalServActionsByCatalogId(new Set<Id>{caseObj.ServiceCatalog__c});
                    Integer currentOrder = Integer.valueOf(actions[0].Order__c);
                    mapOfCaseIdAndCurrentActionOrder.put(caseObj.Id, currentOrder);
                }
            }
        }
        
        
        if (!mapOfCaseIdAndCurrentActionOrder.isEmpty()) {
            
            List<ServiceAction__c> serviceActions = getServActionsByCatalogIdAndOrder(
                mapOfCaseIdAndServiceCatalogId.values(), 
                mapOfCaseIdAndCurrentActionOrder.values() 
            );
            
            // Populate the map with the fetched service actions
            if (!serviceActions.isEmpty()) {
                for (ServiceAction__c action : serviceActions) {
                    catalogVsActionMap.put(action.ServiceCatalog__c, action);
                }
            }
        }
        
        return catalogVsActionMap; 
        
    }
    
    public ServiceCatalog__c getBySubCategory(String normalizedSubType, String subCategory) {
        try {
        return [SELECT Id, Name, RecordTypeDevName__c FROM ServiceCatalog__c WHERE RecordTypeDevName__c = :normalizedSubType AND SubCategory__c = :subCategory LIMIT 1];
        } catch (QueryException qe) {
            return null;
        }
    }

    public List<ServiceCatalog__c> getServiceCatalogForBloomApp(){
        return [SELECT Id,Name,SuperAppName__c FROM ServiceCatalog__c WHERE IsAvailableForSuperApp__c = true];
    }

    public ServiceCatalog__c getServiceCatalogById(Id scId){
        return [SELECT Id,Name,RecordTypeDevName__c FROM ServiceCatalog__c WHERE Id =: scId];
    }

    public List<ServiceCatalog__c> getServiceCatalogByIds() {
        return [SELECT Id, Name, SubCategory__c, Category__c FROM ServiceCatalog__c];
    }

    public List<ServiceCatalog__c> getServiceCatalogByProcessFlowType(String processFlowType) {
        return [SELECT Id, Name, RecordTypeDevName__c, 
                (SELECT Id, OwnerId, AssignToHOAgent__c, SLAHours__c, HandoverStatus__c, TaskSubject__c, Due_in_days__c,
                        Department__c, TaskSubType__c, TaskType__c, FinalTask__c, Order__c
                    FROM Service_Actions__r) 
                FROM ServiceCatalog__c 
                WHERE ProcessFlowType__c = :processFlowType];
    }

    public List<ServiceCatalog__c> getServiceCatalogByProcessFlowTypeAndRecordType(String processFlowType, String recordTypeDevName) {
        return [SELECT Id, Name, RecordTypeDevName__c, 
                (SELECT Id, OwnerId, AssignToHOAgent__c, SLAHours__c, HandoverStatus__c, TaskSubject__c, Due_in_days__c,
                        Department__c, TaskSubType__c, TaskType__c, FinalTask__c, Order__c
                    FROM Service_Actions__r) 
                FROM ServiceCatalog__c 
                WHERE ProcessFlowType__c = :processFlowType
                AND RecordTypeDevName__c = :recordTypeDevName];
    }

    public Map<Id,Map<String,ServiceAction__c>> getCurrentAndNextHandoverServiceAction(List<Handover__c> listOfHandovers) {
        Map<Id,Map<String,ServiceAction__c>> serviceCatalogIdToHanoverStatusToServiceActionMap = new Map<Id,Map<String,ServiceAction__c>>();
        Map<Id, String> mapOfHandoverIdAndServiceCatalogId = new Map<Id, String>();
        List<String> handoverStatuses = new List<String>();
        
        // Collect relevant data from listOfHandovers
        for (Handover__c handoverObj : listOfHandovers) {
            if (handoverObj.ServiceCatalog__c != null){ //&& handoverObj.Sub_Status__c != 'Handover Completed') {
                mapOfHandoverIdAndServiceCatalogId.put(handoverObj.Id, handoverObj.ServiceCatalog__c);
                if(handoverObj.Previous_HO_Status__c != NULL) handoverStatuses.add(handoverObj.Previous_HO_Status__c);
                if(handoverObj.Sub_Status__c != NULL) handoverStatuses.add(handoverObj.Sub_Status__c);
                //if(handoverObj.Next_Step__c != NULL) handoverStatuses.add(handoverObj.Next_Step__c);
                handoverStatuses.add('QA Snagging');
                handoverStatuses.add('Pre CHO Check');
            }
        }
        
        // If there's any next action, fetch the corresponding service actions
        if (!handoverStatuses.isEmpty()) {
            
            List<ServiceAction__c> serviceActions = getServActionsByCatalogIdAndHandoverStatus(
                mapOfHandoverIdAndServiceCatalogId.values(), 
                handoverStatuses
            );
            
            for(ServiceAction__c saRec : serviceActions){
                if(!serviceCatalogIdToHanoverStatusToServiceActionMap.containsKey(saRec.ServiceCatalog__c)){
                    serviceCatalogIdToHanoverStatusToServiceActionMap.put(saRec.ServiceCatalog__c, new Map<String,ServiceAction__c>());
                }
                if(!serviceCatalogIdToHanoverStatusToServiceActionMap.get(saRec.ServiceCatalog__c).containsKey(saRec.HandoverStatus__c)){
                    serviceCatalogIdToHanoverStatusToServiceActionMap.get(saRec.ServiceCatalog__c).put(saRec.HandoverStatus__c, saRec);
                }
            }
        }
        
        return serviceCatalogIdToHanoverStatusToServiceActionMap;
    }

    public  List<ServiceAction__c> getServActionsByCatalogIdAndHandoverStatus(List<String> catalogIdList, List<String> handoverStatusList){
        System.debug('catalogIdList'+catalogIdList);
        System.debug('handoverStatusList ::::: '+handoverStatusList);
        return [Select Id, AssignToOwner__c,OwnerId,Due_in_days__c, AssignToHOAgent__c,
                FinalTask__c, Order__c, ServiceCatalog__c, SubStatus__c,
                TaskSubType__c, TaskSubject__c, TaskType__c, Department__c, DefaultQueueId__c, SLAHours__c, HandoverStatus__c
                FROM ServiceAction__c 
                WHERE ServiceCatalog__c In :catalogIdList
                AND HandoverStatus__c IN :handoverStatusList];
    }

    public Map<Id,Map<String,ServiceAction__c>> getHOTaskServiceActions(List<Handover__c> listOfHandovers) {
        Map<Id,Map<String,ServiceAction__c>> serviceCatalogIdToActionOrderToServiceActionMap = new Map<Id,Map<String,ServiceAction__c>>();
        List<String> serviceCatalogIdList = new List<String>();
        
        // Collect relevant data from listOfHandovers
        for (Handover__c handoverObj : listOfHandovers) {
            if (handoverObj.ServiceCatalog__c != null){
                serviceCatalogIdList.add(handoverObj.ServiceCatalog__c);
            }
        }
        
        // If there's any next action, fetch the corresponding service actions
        if (!serviceCatalogIdList.isEmpty()) {
            
            List<ServiceAction__c> serviceActions = [Select Id, AssignToOwner__c,OwnerId,Due_in_days__c, AssignToHOAgent__c,
                                                        FinalTask__c, Order__c, ServiceCatalog__c, SubStatus__c,
                                                        TaskSubType__c, TaskSubject__c, TaskType__c, Department__c, DefaultQueueId__c, 
                                                        SLAHours__c, HandoverStatus__c
                                                        FROM ServiceAction__c 
                                                        WHERE ServiceCatalog__c IN :serviceCatalogIdList
                                                        AND TaskSubType__c LIKE 'Handover Team Task 2.%'];
            
            for(ServiceAction__c saRec : serviceActions){
                String lastChar =  saRec.TaskSubType__c.substring(saRec.TaskSubType__c.length() - 1);
                if(!serviceCatalogIdToActionOrderToServiceActionMap.containsKey(saRec.ServiceCatalog__c)){
                    serviceCatalogIdToActionOrderToServiceActionMap.put(saRec.ServiceCatalog__c, new Map<String,ServiceAction__c>());
                }
                if(!serviceCatalogIdToActionOrderToServiceActionMap.get(saRec.ServiceCatalog__c).containsKey(lastChar)){
                    serviceCatalogIdToActionOrderToServiceActionMap.get(saRec.ServiceCatalog__c).put(lastChar, saRec);
                }
            }
        }
        
        return serviceCatalogIdToActionOrderToServiceActionMap;
    }

    public  List<ServiceCatalog__c> getServiceCatalogForBloomApp(String selectedType, String selectedCategory, String selectedSubCategory){
        return[SELECT Id, Name, Type__c, Category__c, SubCategory__c,RecordTypeDevName__c,OwnerId,SubCategoryArabic__c
               FROM ServiceCatalog__c 
               WHERE Type__c =:selectedType 
               AND Category__c =:selectedCategory 
               AND  SubCategory__c =:selectedSubCategory AND IsAvailableForSuperApp__c = true LIMIT 1];
        
    }
    
    public ServiceCatalog__c getServiceCatalogByNameAndSubCategory( String serviceCatalogName, String subCategory){
        return [ SELECT Id, Name, SubCategory__c, Category__c FROM ServiceCatalog__c WHERE Name = :serviceCatalogName AND SubCategory__c = :subCategory LIMIT 1 ];
    }
    
    public List<ServiceCatalog__c> getServiceCatalogBySubCategory(String subCategory){
        return [SELECT Id, Name, RecordTypeDevName__c FROM ServiceCatalog__c WHERE SubCategory__c =: subCategory];
    }
    
    public List<Service_Catalogue__c> getServiceCatalogBySubCategoryAndIncidentDesc(Set<String> subCategorySet, Set<String> incidentDescriptionSet) {
        if(subCategorySet.isEmpty() || incidentDescriptionSet.isEmpty()) {
            return new List<Service_Catalogue__c>();
        }
        
        return [   
                    SELECT Id, Name, Location__c, Replace__c, Repair__c, Closure_Reason__c, Category__c, Sub_category__c, 
                            Incident_description__c, Resolution_Priority__c, Resolution_Typology__c, Problem_Code__c
                    FROM Service_Catalogue__c
                    WHERE Sub_category__c IN :subCategorySet 
                    AND Incident_description__c IN :incidentDescriptionSet
                ];
    }
}