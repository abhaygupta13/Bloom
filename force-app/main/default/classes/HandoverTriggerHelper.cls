/***
Class       : HandoverTriggerHelper
Author      : Rajat Rastogi
Description : 
TestClass   : HandoverTriggerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.      V1.0             	 11/06/2024           Initial Version  
****************************************************************************************************************/ 

public without sharing class HandoverTriggerHelper {
    
    // All Validation constant
    private static final String VALIDATION_HANDOVER_ALREADY_THERE = 'Handover already exist for this SalesOrder';
    private static final String HANDOVER_SUB_STATUS_QA_DE_SNAGGING = 'QA De-Snagging';
    private static final String Handover_Potentail_Defaulter = 'Potential Defaulter';
    private static final String STATUS_API_NAME = 'Sub_Status__c';
    private static final String Task_Subject = 'Please generate the Bank NOC for Unit';
    private static final String STATUS_IN_PROGRESS = 'In Progress';
    private static final String STATUS_COMPLETED = 'Completed';
    private static final String Please_assign_the_handover_to_Treasury_Team = 'Please assign the handover to Treasury Team';
    private static final String Task_SubjectForDeveloperNOC = 'Please Upload the Developer NOC for Unit';
    private static final String UNIT_TYPE_APARTMENT = 'Apartment';
    private static final String UNIT_TYPE_TOWNHOUSE = 'Townhouse';
    private static final String UNIT_TYPE_VILLA = 'Villa';
    private static final String Handover_Payment_Type_PHPP = 'PHPP';
    // All Handover SLA status constant
    private static final String CREATED_QA_SNAGGING = 'Created - QA Snagging Completed';  
    private static final String QA_SNAGGING_DE_SNAGGING = 'QA Snagging Completed - QA De-Snagging Completed';  
    private static final String DE_SNAGGING_HOME_ORIENTATION = 'QA De-Snagging Completed - Home Orientation Sent';  
    private static final String HOME_ORIENTATION_APPOINTMENT = 'Home Orientation Sent - Appointment Booked with Customer';  
    private static final String APPOINTMENT_PRE_CHO = 'Appointment Booked with Customer - Pre CHO Check Completed';  
    private static final String PRE_CHO_CHO_SNAGGING = 'Pre CHO Check Completed - CHO Snagging Completed';  
    private static final String CHO_SNAGGING_DE_SNAGGING = 'CHO Snagging Completed - CHO De-Snagging Completed';  
    private static final String DE_SNAGGING_NOTICE = 'CHO De-Snagging Completed - Notice of Completion sent';  
    private static final String NOTICE_SETTLEMENT = 'Notice of Completion sent - Settlement Follow up';  
    private static final String SETTLEMENT_FINANCE = 'Settlement Follow up - Finance Verified';  
    private static final String FINANCE_MORTGAGE_INITIATED = 'Finance Verified - Mortgage Release Initiated';  
    private static final String MORTGAGE_INITIATED_DOCUMENT_UPLOADED = 'Mortgage Release Initiated - Mortgage Release Document Uploaded';  
    private static final String DOCUMENT_UPLOADED_MORTGAGE_COMPLETED = 'Mortgage Release Document Uploaded - Mortgage Release Completed';  
    private static final String MORTGAGE_COMPLETED_ECSCOWLETTER = 'Mortgage Release Completed - Escrow Letter Generated'; 
    private static final String ECSCOWLETTER_TITLE_DEED = 'Escrow Letter Generated - Title Deed Registration Completed';
    private static final String TITLE_DEED_UTILITIES = 'Title Deed Registration Completed - Utilities Transfer Completed';  
    private static final String UTILITIES_KHO_APPOINTMENT = 'Utilities Transfer Completed - KHO Appointment Scheduled';  
    private static final String KHO_APPOINTMENT_HANDOVER = 'KHO Appointment Scheduled - Handover Completed';  
    private static final String FINANCE_PROPERTY_REGISTRATION = 'Finance Verified - Property Registration Completed';  
    private static final String PROPERTY_REGISTRATION_LEASE = 'Property Registration Completed - Lease Agreement';  
    private static final String LEASE_PHPP_KHO = 'Lease Agreement - PHPP - KHO Appointment Scheduled';  
    private static final String PHPP_KHO_KEY_HANDOVER = 'PHPP - KHO Appointment Scheduled - Key Handed Over PHPP';  
    private static final String PHPP_COMP_PENDING_PHPP_FINANCE_CLEARANCE = 'PHPP Completion Pending - PHPP Finance Clearance';
    //All handover SLA goal value constant.
    private static final Integer SLA_5 = 5;  
    private static final Integer SLA_7 = 7;  
    private static final Integer SLA_15 = 15; 
    private static final Integer SLA_14 = 14;
    private static final Integer SLA_10 = 10;  
    private static final Integer SLA_30 = 30;  
    private static final Integer SLA_2 = 2; 
    private static final Integer SLA_3 = 3;
    private static final Integer SLA_1 = 1;
    private static final Integer SLA_1000 = 1000;
    
    private static final string HANDOVER_DUE_DATE_BUFFER { get { return 'HandoverDueDateBufferTimeInDays'; } }
    private static final string MDT_DEFAULT_BUSINESSHOURSID { get { return 'DefaultBusinessHoursId'; } }
    /************************************** START - HANDOVER CONSTANTS ***********************************************/
    
    //private static final String HandoverPHPPRecordType = 'Handover_PHPP';
    
    
    /*********** HANDOVER STATUS *******************/
    private static final String HANDOVER_Created = 'Created';
    
    private static final String HANDOVER_STATUS_QA_Snagging = 'QA Snagging';
    //private static final String Handover_Sub_Status_NOC_Internal_Follow_Up = 'NOC Internal Follow Up';
    private static final String Handover_Sub_Status_Generate_Bank_NOC = 'Generate Bank NOC';
    private static final String Handover_Sub_Status_Generate_Developer_NOC = 'Generate Developer NOC';

    private static final String Handover_Payment_Type_Mortgage = 'Mortgage';
    
    private static final String Customer_Available = 'Customer Available';
    private static final String Customer_Not_Available = 'Customer Not available';
    private static final String Customer_Deligate_To_Bloom	 = 'Customer Delegate To Bloom';
    private static final String Orientation_Appointment_Status_Cancelled = 'Cancelled';
    private static final String Orientation_Appointment_Status_Scheduled = 'Scheduled';
    private static final String Orientation_Appointment_Status_ReScheduled = 'ReScheduled';
    
    /************************************ HANDOVER Queue  ************************/
    private static final String FINANCE_QUEUE = 'Handover_Finance_Queue';
    private static final String HO_COLLECTION_QUEUE = 'Handover_Collection_Team_Queue';
    private static final String HO_OPERATION_QUEUE = 'Handover_Operation_Team_Queue';
    private static final String Handover_Leasing_Team_Queue = 'Handover_Leasing_Team_Queue';
    private static final String Handover_Government_Relations_Queue = 'Handover_Government_Relations_Queue';
    private static final String Handover_Treasury_Queue = 'Handover_Treasury_Queue';
    private static final String Handover_Service_Charge_Confirm_Community_Queue = 'Service_Charge_Confirm_Community_Queue';
    
    private static final String KHO_Appointment_Scheduled = 'KHO Appointment Scheduled';
    
    private static final String Handover_HOAgent_Profiles = 'Handover_HOAgent_Profiles';
    private static final String profilesToSkipValidations = 'profilesToSkipValidations';
    
    private static final String Orientation_Appointment = 'Home Orientation Appointment';
    private static final String KHO_Appointment = 'KHO Appointment';
    
    /************************************** END - HANDOVER CONSTANTS ***********************************************/
    
    private static final string BLOOM_CUSTOM_NOTIFICATION_DEV_NAME { get { return 'Bloom_Custom_Notifications'; } }
    private static final string HANDOVER_ASSIGN_TO_OWNER_TEMPLATE_ID { get { return 'HandoverAssignToOwnerTemplateId'; } }
    private static final string HANDOVER_INITIATE_CANCELLATION_TEMPLATE_ID { get { return 'HandoverInitiateCancellationTemplateId'; } }
    private static final string MTD_OWE_NO_REPLY_SALES_IT_ID { get { return 'NoReplySalesIT'; } }
    private static final string MTD_HANDOVER_OPERATION_TEAM_QUEUE_ID { get { return 'Handover_Operation_Team_Queue'; } }

    public static void beforeInsert(List<Handover__c> newList){
        HandoverService objHandoverService = HandoverService.getInstance();
        UnitService objUnitService = UnitService.getInstance();
        Set<Id> unitIds = new Set<Id>();
        
        List<ServiceCatalog__c> serviceCatalogList = ServiceCatalogService.getInstance().getServiceCatalogByProcessFlowTypeAndRecordType('Handover','Non PHPP');
        
        for(Handover__c objHandover : newList){
            if(objHandover.Unit__c != null){
                unitIds.add(objHandover.Unit__c);
            }
        }
        
        if(!unitIds.isEmpty() && unitIds != NULL){
            List<Handover__c> objHandoverList = objHandoverService.getHandoversByUnitIds(unitIds);
            Map<Id, Unit__c> objUnitMap = new Map<Id, Unit__c>(objUnitService.getUnitsByIds(unitIds));
            
            Map<Id, Handover__c> unitToHandoverMap = new Map<Id, Handover__c>();
            for (Handover__c objHandover : objHandoverList) {
                unitToHandoverMap.put(objHandover.Unit__c, objHandover);
            }
            
            for (Handover__c objHandover : newList) {
                if (unitToHandoverMap.containsKey(objHandover.Unit__c)) {
                    objHandover.addError(VALIDATION_HANDOVER_ALREADY_THERE);
                }else{
                    objHandover.Account__c = objUnitMap.get(objHandover.Unit__c).Active_Sales_Order__r.Account__c;
                    objHandover.Name = 'HO-' + objUnitMap.get(objHandover.Unit__c).SAP_Unit_Number__c;
                    objHandover.Sales_Order__c = objUnitMap.get(objHandover.Unit__c).Active_Sales_Order__c;
                    objHandover.Project__c = objUnitMap.get(objHandover.Unit__c).Project__c;
                    objHandover.Handover_Phase__c = objUnitMap.get(objHandover.Unit__c).HandoverPhase__c;
                    objHandover.ServiceCatalog__c = serviceCatalogList != null && !serviceCatalogList.isEmpty() ? serviceCatalogList[0].Id : null;
                }
                if(objHandover.Sales_Order__c == NULL){
                    objHandover.Sub_Status__c = 'QA Snagging';
                    objHandover.ServiceCatalog__c = serviceCatalogList != null && !serviceCatalogList.isEmpty() ? serviceCatalogList[0].Id : null;
                }
            }
        }
    }
    
    public static void setInitialDocumentOnHandover(List<Handover__c> newList) {
        
        DocumentService objDocumentService = DocumentService.getInstance();
        ContentService objContentService = ContentService.getInstance();
        
        Set<Id> salesOrderIds = new Set<Id>();
        Set<Id> handoverIds = new Set<Id>();
        for (Handover__c objHandover : newList) {
            if(objHandover.Sales_Order__c != NULL){
                salesOrderIds.add(objHandover.Sales_Order__c);
            }
            handoverIds.add(objHandover.Id);
        }
        
        Map<Id, Id> salesDocToHandoverDocMap = new Map<Id, Id>();
        
        Map<Id, Map<String, Document__c>> salesOrderIdToDocumentTypeMap = objDocumentService.getDocumentsByParentIds(salesOrderIds, SalesOrder__c.SobjectType);
        Map<Id, Map<String, Document__c>> handoverIdToDocumentTypeMap = objDocumentService.getDocumentsByParentIds(handoverIds, Handover__c.SobjectType);
        
        List<ContentDocumentLink> cdLinkList = new List<ContentDocumentLink>();
        
        for (Handover__c objHandover : newList) {
            if(objHandover.Sales_Order__c != NULL){
                Map<String, Document__c> salesOrderDocMap = salesOrderIdToDocumentTypeMap.get(objHandover.Sales_Order__c);
                Map<String, Document__c> handoverDocMap = handoverIdToDocumentTypeMap.get(objHandover.Id);
                if(salesOrderDocMap!=null){
                for (String docType : salesOrderDocMap.keySet()) {
                    if(handoverDocMap.containsKey(docType)){
                        salesDocToHandoverDocMap.put(salesOrderDocMap.get(docType).Id, handoverDocMap.get(docType).Id);
                        
                    }
                }
                }
            }
        }
        
        for(ContentDocumentLink cdLink :objContentService.getContentDocumentByLinkedEntityIds(salesDocToHandoverDocMap.keySet())){  
            Id newDocId = salesDocToHandoverDocMap.get(cdLink.LinkedEntityId);
           
            if (newDocId != null) {
                cdLinkList.add(new ContentDocumentLink(
                    ContentDocumentId = cdLink.ContentDocumentId,
                    LinkedEntityId = newDocId,
                    ShareType = 'V',
                    Visibility = 'AllUsers'
                ));
            }
        }
        objContentService.createContentDocumentLink(cdLinkList);
    }
    
    public static void autopopulateFeesForUnitCategory(Map<Id, Handover__c> oldHOMap, List<Handover__c> newHOList) {
        HandoverService handoverService = HandoverService.getInstance();
        Map<Id, Handover__c> handoverToUpdate = new Map<Id, Handover__c>();
        Set<Id> filteredHandoverIds = new Set<Id>();
        List<Handover__c> handoverUpdateList = new List<Handover__c>();
        
        for (Handover__c objHandover : newHOList) {
            if (objHandover.UnitCategory__c != null && objHandover.Project__c != null && objHandover.UnitCategory__c != oldHOMap.get(objHandover.Id).UnitCategory__c) {
                filteredHandoverIds.add(objHandover.Id);
            }
        }
        
        if (filteredHandoverIds.isEmpty()) return;
        
        List<Handover__c> handoverList = handoverService.getHandoverWithProjectAndUnit(filteredHandoverIds);
        Map<Id, Handover__c> handoverMap = new Map<Id, Handover__c>(handoverList);
        for (Handover__c objHandover : newHOList) {
            if(handoverMap.containsKey(objHandover.Id)){
                Handover__c objHO = handoverMap.get(objhandover.Id);
                String unitType = objHO.Unit__r.UnitType__c == UNIT_TYPE_VILLA || objHO.Unit__r.UnitType__c == UNIT_TYPE_TOWNHOUSE ? UNIT_TYPE_VILLA : UNIT_TYPE_APARTMENT;
                
                switch on objHandover.UnitCategory__c {
                    when 'Registered Unit' {
                        objHandover.Title_Deed_Fee__c = (unitType == UNIT_TYPE_VILLA && objHO.Project__r.RegisteredUnitTitleDeedFeeVilla__c != null) ? objHO.Project__r.RegisteredUnitTitleDeedFeeVilla__c : (unitType != UNIT_TYPE_VILLA && objHO.Project__r.RegisteredUnitTitleDeedFeeApt__c != null)
                        ? objHO.Project__r.RegisteredUnitTitleDeedFeeApt__c : null;
                    }
                    when 'Registered Unit with Mortgage' {
                        objHandover.Admin_fees__c = (unitType == UNIT_TYPE_VILLA && objHO.Project__r.MortgageUnitAdminFeeVilla__c != null) ? objHO.Project__r.MortgageUnitAdminFeeVilla__c : (unitType != UNIT_TYPE_VILLA && objHO.Project__r.MortgageUnitAdminFeeApt__c != null)
                        ? objHO.Project__r.MortgageUnitAdminFeeApt__c : null;
                        objHandover.Title_Deed_Fee__c = (unitType == UNIT_TYPE_VILLA && objHO.Project__r.MortgageUnitTitleDeedFeeVilla__c != null) ? objHO.Project__r.MortgageUnitTitleDeedFeeVilla__c : (unitType != UNIT_TYPE_VILLA && objHO.Project__r.RegisteredUnitTitleDeedFeeApt__c != null)
                        ? objHO.Project__r.RegisteredUnitTitleDeedFeeApt__c : null;
                    }
                    when 'Resale Unit' {
                        Decimal percentageValue = (unitType == UNIT_TYPE_VILLA ? objHO.Project__r.ResaleUnitADMFeeVilla__c : objHO.Project__r.ResaleUnitADMFeeApt__c);
                        if (percentageValue != null && objHO.Sales_Order__r.NetAmount__c != null) {
                            objHandover.ADM_Registrations_Fee__c = (objHO.Sales_Order__r.NetAmount__c * percentageValue) / 100;
                        }
                        objHandover.Admin_fees__c = (unitType == UNIT_TYPE_VILLA && objHO.Project__r.ResaleUnitAdminFeeVilla__c != null) ? objHO.Project__r.ResaleUnitAdminFeeVilla__c : (unitType != UNIT_TYPE_VILLA && objHO.Project__r.ResaleUnitAdminFeeApt__c != null)
                        ? objHO.Project__r.ResaleUnitAdminFeeApt__c : null;
                        objHandover.EvaluationFees__c = (unitType == UNIT_TYPE_VILLA && objHO.Project__r.ResaleUnitEvaluationFeeVilla__c != null) ? objHO.Project__r.ResaleUnitEvaluationFeeVilla__c : (unitType != UNIT_TYPE_VILLA && objHO.Project__r.ResaleUnitEvaluationFeeApt__c != null)
                        ? objHO.Project__r.ResaleUnitEvaluationFeeApt__c : null;
                    }
                    when 'Resale with Mortgage' {
                        Decimal percentageValue = (unitType == UNIT_TYPE_VILLA ? objHO.Project__r.ResaleWithMortgageADMFeeVilla__c : objHO.Project__r.ResaleWithMortgageADMFeeApt__c);
                        if (percentageValue != null && objHO.Sales_Order__r.NetAmount__c != null) {
                            objHandover.ADM_Registrations_Fee__c = (objHO.Sales_Order__r.NetAmount__c * percentageValue) / 100;
                        }
                        objHandover.EvaluationFees__c = (unitType == UNIT_TYPE_VILLA && objHO.Project__r.ResaleWithMortgageEvaluationFeeVilla__c != null) ? objHO.Project__r.ResaleWithMortgageEvaluationFeeVilla__c : (unitType != UNIT_TYPE_VILLA && objHO.Project__r.ResaleWithMortgageEvaluationFeeApt__c != null)
                        ? objHO.Project__r.ResaleWithMortgageEvaluationFeeApt__c : null;
                        objHandover.Admin_fees__c = (unitType == UNIT_TYPE_VILLA && objHO.Project__r.ResaleWithMortgageAdminFeeVilla__c != null) ? objHO.Project__r.ResaleWithMortgageAdminFeeVilla__c : (unitType != UNIT_TYPE_VILLA && objHO.Project__r.ResaleWithMortgageAdminFeeApt__c != null)
                        ? objHO.Project__r.ResaleWithMortgageAdminFeeApt__c : null;
                    }
                    when 'New Sale' {
                        Decimal percentageValue = (unitType == UNIT_TYPE_VILLA ? objHO.Project__r.NewSaleADMFeeVilla__c : objHO.Project__r.NewSaleADMFeeApt__c);
                        if (percentageValue != null && objHO.Sales_Order__r.NetAmount__c != null) {
                            objHandover.ADM_Registrations_Fee__c = (objHO.Sales_Order__r.NetAmount__c * percentageValue) / 100;
                        }
                        objHandover.Admin_fees__c = (unitType == UNIT_TYPE_VILLA && objHO.Project__r.NewSaleAdminFeeVilla__c != null) ? objHO.Project__r.NewSaleAdminFeeVilla__c : (unitType != UNIT_TYPE_VILLA && objHO.Project__r.NewSaleAdminFeeApt__c != null)
                        ? objHO.Project__r.NewSaleAdminFeeApt__c : null;
                        objHandover.EvaluationFees__c = (unitType == UNIT_TYPE_VILLA && objHO.Project__r.NewSaleEvaluationFeeVilla__c != null) ? objHO.Project__r.NewSaleEvaluationFeeVilla__c : (unitType != UNIT_TYPE_VILLA && objHO.Project__r.NewSaleEvaluationFeeApt__c != null)
                        ? objHO.Project__r.NewSaleEvaluationFeeApt__c : null;
                    }
                    when 'New Sale with Mortgage' {
                        Decimal percentageValue = (unitType == UNIT_TYPE_VILLA ? objHO.Project__r.NewSaleWithMortgageADMFeeVilla__c : objHO.Project__r.NewSaleWithMortgageADMFeeApt__c);
                        if (percentageValue != null && objHO.Sales_Order__r.NetAmount__c != null) {
                            objHandover.ADM_Registrations_Fee__c = (objHO.Sales_Order__r.NetAmount__c * percentageValue) / 100;
                        }
                        objHandover.Admin_fees__c = (unitType == UNIT_TYPE_VILLA && objHO.Project__r.NewSaleWithMortgageAdminFeeVilla__c != null) ? objHO.Project__r.NewSaleWithMortgageAdminFeeVilla__c : (unitType != UNIT_TYPE_VILLA && objHO.Project__r.NewSaleWithMortgageAdminFeeApt__c != null)
                        ? objHO.Project__r.NewSaleWithMortgageAdminFeeApt__c : null;
                        objHandover.EvaluationFees__c = (unitType == UNIT_TYPE_VILLA && objHO.Project__r.NewSaleWithMortgageEvaluationFeeVilla__c != null) ? objHO.Project__r.NewSaleWithMortgageEvaluationFeeVilla__c : (unitType != UNIT_TYPE_VILLA && objHO.Project__r.NewSaleWithMortgageEvaluationFeeApt__c != null)
                        ? objHO.Project__r.NewSaleWithMortgageEvaluationFeeApt__c : null;
                    }
                }            
            }
        }
    }
    
    public static void createDocuments(List<Handover__c> newList){     
        DocumentService objDocumentService = DocumentService.getInstance();
        List<DocumentType__c> handoverDocTypeList = objDocumentService.getDocTypes('Handover');
        List<Document__c> documentList = new List<Document__c>();
        
        for(Handover__c objHandover :newList){
            Map<String,DocumentType__c> documentNameToDocumentTypeMap = new Map<String,DocumentType__c>();
            for(DocumentType__c objDocumentType : handoverDocTypeList){
                if(!documentNameToDocumentTypeMap.containsKey(objDocumentType.Type__c)){
                    documentNameToDocumentTypeMap.put(objDocumentType.Type__c, objDocumentType);
                    documentList.add(new Document__c(Handover__c = objHandover.Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c));
                }
            }
        }
        objDocumentService.insertDocuments(documentList);   
    }
    
   /* public static void deleteCancellationEvent(Map<Id, Handover__c> newHOMap, Map<Id, Handover__c> oldHOMap){
        ActivityService handoverActivityService = ActivityService.getInstance();
        Set<Id> whatId = newHOMap.keySet();
        Map<Id, Event> eventMap = new Map<Id, Event>();
        List<Event> eventToDelete = new  List<Event>();
        List<Event> eventList = handoverActivityService.getEventByWhatId(whatId);// add new
        for (Event evt : eventList) {
            if (evt.WhatId != null) {
                eventMap.put(evt.WhatId, evt);
            }
        }
        if (eventMap != null && !eventMap.isEmpty()) {
            for(Handover__c HOObj : newHOMap.values()){
                if(HOObj.Orientation_Appointment_Status__c == Orientation_Appointment_Status_Cancelled && HOObj.Orientation_Appointment_Status__c != oldHOMap.get(HOObj.Id).Orientation_Appointment_Status__c){
                       if(eventMap.containsKey(HOObj.Id)){
                           eventToDelete.add(eventMap.get(HOObj.Id));  
                       }
                   }
            }
        }
       
            handoverActivityService.deleteEvents(eventToDelete);
            
         
    }*/
    
       public static void deleteCancellationEvent(Map<Id, Handover__c> newHOMap, Map<Id, Handover__c> oldHOMap) {
    Set<Id> cancelledHandoverIds = new Set<Id>();
    Set<Id> phaseIds = new Set<Id>();

    // Step 1: Collect only Handover records where status changed to Cancelled
    for (Handover__c hoObj : newHOMap.values()) {
        Handover__c oldHo = (oldHOMap != null) ? oldHOMap.get(hoObj.Id) : null;
        if (hoObj.Orientation_Appointment_Status__c == Orientation_Appointment_Status_Cancelled 
            && (oldHo == null || hoObj.Orientation_Appointment_Status__c != oldHo.Orientation_Appointment_Status__c)) {
            cancelledHandoverIds.add(hoObj.Id);
            if (hoObj.Handover_Phase__c != null) {
                phaseIds.add(hoObj.Handover_Phase__c);
            }
        }
    }

    // Early exit if no relevant status changes
    if (cancelledHandoverIds.isEmpty()) {
        return;
    }

    ActivityService handoverActivityService = ActivityService.getInstance();
    HandoverPhaseService objHandoverPhaseService = HandoverPhaseService.getInstance();

    // Step 2: Query and delete related events
    List<Event> eventList = handoverActivityService.getEventByWhatId(cancelledHandoverIds);
    List<Event> eventsToDelete = new List<Event>();

    if (eventList != null && !eventList.isEmpty()) {
        for (Event evt : eventList) {
            // Delete only Home Orientation Appointment events
            if (evt.Type == 'Home Orientation Appointment' || evt.Type == HandoverConstants.Orientation_Appointment) {
                eventsToDelete.add(evt);
            }
        }
    }

  
        handoverActivityService.deleteEvents(eventsToDelete);
    

    // Step 3: Send Cancellation Emails 
    if (!phaseIds.isEmpty()) {
        Map<Id, HandoverPhase__c> phaseMap = new Map<Id, HandoverPhase__c>(objHandoverPhaseService.getHandoverPhaseInfo(phaseIds));
        
        for (Id hoId : cancelledHandoverIds) {
            Handover__c ho = newHOMap.get(hoId);
            if (ho.Handover_Phase__c != null && phaseMap.containsKey(ho.Handover_Phase__c)) {
                HandoverPhase__c phase = phaseMap.get(ho.Handover_Phase__c);
                if (phase != null && String.isNotBlank(phase.ChoAppointmentCanceledEmailTempId__c)) {
                    SendEmailInvocable.sendEmail(phase.ChoAppointmentCanceledEmailTempId__c, ho.Id);
                }
            }
        }
    }
}
    
    public static void beforeUpdateCall(List<Handover__c> newHOList, Map<Id, Handover__c> oldHOMap){
        ActivityService objActivityService = ActivityService.getInstance(); 
        HandoverService handoverService = HandoverService.getInstance();
        SalesOrderService salesOrderService = SalesOrderService.getInstance();
        ProjectService objProjectService = ProjectService.getInstance();
        Map<Id, Handover__c> handoverMapToGenerateDeveloperNOC = new Map<Id, Handover__c>();
        
        //Id HORecordTypeId = Utility.getRecordTypeIdByDevName(Handover__c.SObjectType, HandoverPHPPRecordType);
        Set<Id> salesOrderId = new Set<Id>();
        set<id>projectIds = new set<id>();
        for(Handover__c HOObj : newHOList){
            salesOrderId.add(HOObj.Sales_Order__c);
            projectIds.add(HOObj.Project__c);
            if(oldHOMap.get(HOObj.Id).Sub_Status__c != HOObj.Sub_Status__c){
                HOObj.Previous_HO_Status__c = oldHOMap.get(HOObj.Id).Sub_Status__c;
            }
        }
        Map<Id, Project__c> projectMap = new Map<Id, Project__c>(objProjectService.getProjectsByIds(projectIds));
        Map<Id, InstallmentLines__c> latestInstallmentLinesMap = new Map<Id, InstallmentLines__c>();
        List<SalesOrder__c> salesOrderMap = salesOrderService.getSalesOrdersWithInstallment(salesOrderId);
        for (SalesOrder__c salesOrder : salesOrderMap) {
            if (!salesOrder.InstallmentLines__r.isEmpty()) {
                latestInstallmentLinesMap.put(salesOrder.Id, salesOrder.InstallmentLines__r[0]);
            }
        }

        List<ServiceCatalog__c> serviceCatalogList = ServiceCatalogService.getInstance().getServiceCatalogByProcessFlowType('Handover');
        Map<String,ServiceCatalog__c> handoverTypeToServiceCatalogMap = new Map<String,ServiceCatalog__c>();
        for(ServiceCatalog__c scRec: serviceCatalogList){
            handoverTypeToServiceCatalogMap.put(scRec.RecordTypeDevName__c, scRec);
        }
        for(Handover__c HOObj : newHOList){
            if(HOObj.Sub_Status__c != oldHOMap.get(HOObj.Id).Sub_Status__c){
                if(oldHOMap.get(HOObj.Id).Sub_Status__c == HANDOVER_SUB_STATUS_QA_DE_SNAGGING && HOObj.Sales_Order__c == NULL){
                    HOObj.ServiceCatalog__c = handoverTypeToServiceCatalogMap.get('Unsold').Id;
                }
                if(HOObj.Sub_Status__c == Handover_Sub_Status_Generate_Developer_NOC){
                    handoverMapToGenerateDeveloperNOC.put(HOObj.Id, HOObj);
                }
            }
            if(HOObj.Payment_Type__c != oldHOMap.get(HOObj.Id).Payment_Type__c){
                if(HOObj.Payment_Type__c == Handover_Payment_Type_PHPP){
                    //HOObj.RecordTypeId = HORecordTypeId;
                    HOObj.HandoverType__c = 'PHPP';
                    HOObj.ServiceCatalog__c = handoverTypeToServiceCatalogMap.get('PHPP').Id;
                }
                else {
                    //HOObj.RecordTypeId = HORecordTypeId;
                    HOObj.HandoverType__c = 'Non PHPP';
                    HOObj.ServiceCatalog__c = handoverTypeToServiceCatalogMap.get('Non PHPP').Id;
                }
            } 

            if(oldHOMap.get(HOObj.Id).Sales_Order__c == NULL && HOObj.Sales_Order__c != NULL){
                if(HOObj.Payment_Type__c == Handover_Payment_Type_PHPP){
                    HOObj.ServiceCatalog__c = handoverTypeToServiceCatalogMap.get('PHPP').Id;
                } else {
                    HOObj.ServiceCatalog__c = handoverTypeToServiceCatalogMap.get('Non PHPP').Id;
                }
            }
            if(HOObj.Is_Property_keys_given__c && oldHOMap.get(HOObj.Id).Is_Property_keys_given__c != HOObj.Is_Property_keys_given__c) {
                HOObj.Key_Handed_Over_Date__c = System.today();
            }
        }

        if(!handoverMapToGenerateDeveloperNOC.isEmpty()){
            generateDeveloperNOC(handoverMapToGenerateDeveloperNOC);
        } 
    }
     
    public static void updateInstallmentLineItems(Map<Id, Handover__c> oldHOMap, List<Handover__c> newHOList){
        
        InstallmentLineService installmentService = InstallmentLineService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        
        Map<Id, Handover__c> salesOrderIdToHandoverMap = new Map<Id, Handover__c>();
        Map<Id, InstallmentLines__c> handoverLinesBySalesOrder = new Map<Id, InstallmentLines__c>();
        Set<Id> handoverPhaseIdSet = new Set<Id>();
        
        for (Handover__c newHORec : newHOList) {
            if (newHORec.Notice_of_Completion_Date__c != NULL && newHORec.Notice_of_Completion_Date__c != oldHOMap.get(newHORec.Id).Notice_of_Completion_Date__c) {
                salesOrderIdToHandoverMap.put(newHORec.Sales_Order__c, newHORec);
            }
            if(newHORec.Handover_Phase__c != NULL){
                handoverPhaseIdSet.add(newHORec.Handover_Phase__c);
            }
        }
        
        Map<Id,HandoverPhase__c> hoPhaseMap = new Map<Id,HandoverPhase__c>([SELECT Id, HandoverInstallmentRevisedDateBuffer__c FROM HandoverPhase__c WHERE Id IN :handoverPhaseIdSet]);

        if(!salesOrderIdToHandoverMap.isEmpty()){
            List<InstallmentLines__c> installmentLinesList = installmentService.getHandoverInstallmentLinesBySalesOrderIds(salesOrderIdToHandoverMap.keySet());
            
            if (!installmentLinesList.isEmpty()) {
                for (InstallmentLines__c line : installmentLinesList) {
                    if (line.Type__c == 'Handover') {
                        handoverLinesBySalesOrder.put(line.SalesOrder__c, line);
                    }
                }
            }
            
            List<InstallmentLines__c> linesToUpdate = new List<InstallmentLines__c>();
          

            //Integer handoverDueDateBuffer = objMetadataService.getAppSettingNumberValue(HANDOVER_DUE_DATE_BUFFER);
            for (Handover__c hoRec : salesOrderIdToHandoverMap.values()) {
                Integer handoverDueDateBuffer = hoRec.HandoverInstallmentRevisedDateBuffer__c != NULL && hoRec.HandoverInstallmentRevisedDateBuffer__c > 0 ? (Integer)hoRec.HandoverInstallmentRevisedDateBuffer__c : (Integer)hoPhaseMap.get(hoRec.Handover_Phase__c).HandoverInstallmentRevisedDateBuffer__c;
                InstallmentLines__c handoverLine = handoverLinesBySalesOrder.get(hoRec.Sales_Order__c);
                if (handoverLine != NULL && handoverDueDateBuffer != NULL) {
                    Date newRevisedDate = hoRec.Notice_of_Completion_Date__c.addDays(handoverDueDateBuffer);
                   
                    handoverLine.RevisedDate__c = newRevisedDate;
                    handoverLine.Send_to_SAP__c = true;  
                    linesToUpdate.add(handoverLine);
                  
                }
            }
            installmentService.updateInstallmentLines(linesToUpdate);
        }
    }
    
    public static void updateKeyHandoverStatusOnUnit(Map<Id, Handover__c> oldHOMap, List<Handover__c> newHOList) {
        List<Unit__c> objUnitList = new List<Unit__c>();
        UnitService objUnitService = UnitService.getInstance();
        for (Handover__c objHandover : newHOList) {
            if (oldHOMap.get(objHandover.Id).Is_Property_keys_given__c != objHandover.Is_Property_keys_given__c) {
                objUnitList.add(new Unit__c(Id = objHandover.Unit__c, Is_Property_keys_given__c = objHandover.Is_Property_keys_given__c));
            }
            /* if (oldHOMap.get(objHandover.Id).Key_Handed_Over_Date__c != objHandover.Key_Handed_Over_Date__c) {
                objUnitList.add(new Unit__c(Id = objHandover.Unit__c,KeyHandoverDate__c = objHandover.Key_Handed_Over_Date__c));
            } */
        }
        objUnitService.updateUnitsWithoutTrigger(objUnitList);
    }
    
     public static void updateHoAgentAssignedUser(Map<Id, Handover__c> oldHOMap, List<Handover__c> newHOList) {
        HandoverService objHandoverService = HandoverService.getInstance(); 
        
        Map<Id, Handover__c> statusChangedHandoversMap = new Map<Id, Handover__c>();
        for (Handover__c objHandover : newHOList) {
            if (oldHOMap != null && !oldHOMap.isEmpty() && oldHOMap.get(objHandover.Id).Sub_Status__c != objHandover.Sub_Status__c && objHandover.Sub_Status__c == HANDOVER_SUB_STATUS_QA_DE_SNAGGING) {
                statusChangedHandoversMap.put(objHandover.Id, objHandover);
                
            } else if((oldHOMap == null || oldHOMap.isEmpty()) && (objHandover.Sub_Status__c == HANDOVER_STATUS_QA_Snagging || objHandover.Sub_Status__c == HANDOVER_SUB_STATUS_QA_DE_SNAGGING)){
                statusChangedHandoversMap.put(objHandover.Id, objHandover);
            }
        }
        
        List<Handover__c> handoversToAssignCRMUserList = new List<Handover__c>();
        if (!statusChangedHandoversMap.keySet().isEmpty()) {
            Map<Id, Handover__c> detailedHandoverMap = new Map<Id, Handover__c>(objHandoverService.getHandoverByIds(statusChangedHandoversMap.keySet()));
            
            for (Handover__c objHandover : statusChangedHandoversMap.values()) {
                if (objHandover.Unit__c != null && objHandover.HO_Agent_Assigned_User__c == null) {
                    if(detailedHandoverMap.get(objHandover.Id) != null && detailedHandoverMap.get(objHandover.Id).Unit__r.HO_Agent__c != null) {
                        objHandover.HO_Agent_Assigned_User__c = detailedHandoverMap.get(objHandover.Id).Unit__r.HO_Agent__c;  
                        objHandover.OwnerId = detailedHandoverMap.get(objHandover.Id).Unit__r.HO_Agent__c;
                    }
                } 
                
                if (objHandover.CRM_Team_Assigned_User__c == null) {
                    handoversToAssignCRMUserList.add(objHandover);
                }
            }
            
            if(!handoversToAssignCRMUserList.isEmpty()) {
                AssignmentRuleHandler.crmHandoverAssignment(handoversToAssignCRMUserList);
            }
        }
    }
        
    public static void updateContactId(List<Handover__c> newList, Map<Id, Handover__c> oldMap) {
         AccountService objAccountService = AccountService.getInstance();
        Set<Id> accIds = new Set<Id>();
        for (Handover__c ho : newList) { 
            Id oldAccId = (oldMap != null) ? oldMap.get(ho.Id).Account__c : null;
            if (ho.Account__c != null && ho.Account__c != oldAccId) {
                accIds.add(ho.Account__c);
            } else if (ho.Account__c == null) {
                ho.Contact__c = null;
            }
        }

        if (accIds.isEmpty()) return;

        Map<Id, Account> accData = new Map<Id, Account>(objAccountService.getAccountWithLatesetContact(accIds));

        for (Handover__c ho : newList) {
            if (accData.containsKey(ho.Account__c)) {
                Account acc = accData.get(ho.Account__c);
                ho.Contact__c = acc.IsPersonAccount ? acc.PersonContactId : 
                                (!acc.Contacts.isEmpty() ? acc.Contacts[0].Id : null);
            }
        }
    }
    
    public static void notifyOwners(List<Handover__c> newList, Map<Id, Handover__c> oldMap){
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        Id bloomNoReplySalesOWEId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_SALES_IT_ID);
        Id handoverAssignToOwnerETId = objMetadataService.getAppSettingTextValue(HANDOVER_ASSIGN_TO_OWNER_TEMPLATE_ID);
        Id handoverInitiateCancellationETId = objMetadataService.getAppSettingTextValue(HANDOVER_INITIATE_CANCELLATION_TEMPLATE_ID);
        Id handoverOperationTeamQueueId = objMetadataService.getAppSettingTextValue(MTD_HANDOVER_OPERATION_TEAM_QUEUE_ID);
        List<Messaging.SingleEmailMessage> msgList = new List<Messaging.SingleEmailMessage>();
        Set<Id> ownerIdSet = new Set<Id>();
        Map<Id, User> ownersMap = new Map<Id, User>();
        Map<Id,Handover__c> handoversForCancellation = new Map<Id,Handover__c>();

        for(Handover__c hoRec : newList){
            if(oldMap == NULL || (oldMap != NULL && (oldMap.get(hoRec.Id).OwnerId != hoRec.OwnerId))){
                ownerIdSet.add(hoRec.OwnerId);
            }
            if(oldMap != NULL && hoRec.Sub_Status__c == 'Initiate Cancellation' && (oldMap.get(hoRec.Id).Sub_Status__c != hoRec.Sub_Status__c)){
                handoversForCancellation.put(hoRec.Id, hoRec);
            }
        }

        if (!ownerIdSet.isEmpty()) {
            ownersMap = UserService.getInstance().getActiveUsersByIds(ownerIdSet);
        }

        List<FeedItem> postList = new List<FeedItem>();
        CustomNotificationType notificationType = CustomNotificationService.getInstance().getCustomNotificationTypeByName(BLOOM_CUSTOM_NOTIFICATION_DEV_NAME);
        List<String> handoverOperationTeamMemberEmails = objEmailService.getOwnerEmails(handoverOperationTeamQueueId);
        for(Handover__c hoRec : newList){
            if(hoRec.OwnerId != NULL && ownersMap.containsKey(hoRec.OwnerId) && ownersMap.get(hoRec.OwnerId) != NULL && ownersMap.get(hoRec.OwnerId).Email != NULL){
                Messaging.SingleEmailMessage objEmailMessage = new Messaging.SingleEmailMessage();
                objEmailMessage = objEmailService.getSingleEmailMessageWithoutTargetObjectId(handoverAssignToOwnerETId, bloomNoReplySalesOWEId, hoRec.Id, new List<String>{ownersMap.get(hoRec.OwnerId).Email}, null, null);
                msgList.add(objEmailMessage);
                
                
                CustomNotificationService.sendCustomNotification(new Set<String>{ownersMap.get(hoRec.OwnerId).Id}, hoRec.Id, notificationType, 'Handover Assign', 'Handover '+ hoRec.Name + ' is assigned to you.');

                FeedItem post = new FeedItem();
                post.Body = 'Handover '+ hoRec.Name + ' is assigned to you.';
                post.Type = 'TextPost';
                post.ParentId = hoRec.Id;
                post.Title = 'Handover Assign';//+ hoRec.Name + ' is assigned to you.';
                postList.add(post);
            }

            if(handoversForCancellation.containsKey(hoRec.Id)){
                Messaging.SingleEmailMessage objEmailMessage = new Messaging.SingleEmailMessage();
                objEmailMessage = objEmailService.getSingleEmailMessageWithoutTargetObjectId(handoverInitiateCancellationETId, bloomNoReplySalesOWEId, hoRec.Id, handoverOperationTeamMemberEmails, null, null);
                msgList.add(objEmailMessage);
                
                
                CustomNotificationService.sendCustomNotification(new Set<String>{handoverOperationTeamQueueId}, hoRec.Id, notificationType, 'Handover Assign', 'Handover '+ hoRec.Name + ' is canceled.'); //Handover {!$Record.Name} is canceled.

                FeedItem post = new FeedItem();
                post.Body = 'Handover '+ hoRec.Name + ' is cancelled.';
                post.Type = 'TextPost';
                post.ParentId = hoRec.Id;
                post.Title = 'Handover Assign';//+ hoRec.Name + ' is assigned to you.';
                postList.add(post);
            }
        }

        insert postList;
        objEmailService.sendEmail(msgList);
    }

   public static void notifyCustomers(List<Handover__c> newList, Map<Id, Handover__c> oldMap){
        List<Handover__c> handoverRecordsToUpdate = new List<Handover__c>();
         HandoverPhaseService objHandoverPhaseService = HandoverPhaseService.getInstance();
       
        Set<Id> phaseIds = new Set<Id>();
        for (Handover__c hoRec : newList) {
            if (oldMap != null && oldMap.get(hoRec.Id).Sub_Status__c != hoRec.Sub_Status__c && hoRec.Handover_Phase__c != null) {
                phaseIds.add(hoRec.Handover_Phase__c);
            }
        }
        Map<Id, HandoverPhase__c> phaseMap = new Map<Id,HandoverPhase__c>();
        phaseMap = new Map<Id, HandoverPhase__c>(objHandoverPhaseService.getHandoverPhaseInfo(phaseIds));
        
        
        for (Handover__c hoRec : newList) {
              HandoverPhase__c handoverPhase = phaseMap.get(hoRec.Handover_Phase__c);
            if(handoverPhase==null) continue;
            
                Handover__c handoverRecord = new Handover__c(Id = hoRec.Id);
            
               switch on hoRec.Sub_Status__c {
                when 'Title Deed Registration Completed', 'Transfer Utilities' {
                    if (!hoRec.Is_Title_Deed_Registration__c && String.isNotBlank(handoverPhase.HOTitleDeedEmailTempID__c)) {
                        SendEmailInvocable.sendEmail(handoverPhase.HOTitleDeedEmailTempID__c, hoRec.Id);
                        handoverRecord.Is_Title_Deed_Registration__c = true;
                        handoverRecordsToUpdate.add(handoverRecord);
                    }
                }
                when 'Utilities Transfer Completed', 'Mortgage Cheque Clearance', 'Handover Signing Document (KHO) Appointment' {
                    if (!hoRec.KeyHandoverInvitationSent__c && String.isNotBlank(handoverPhase.KeyHandoverInvitationEmailTempId__c)) {
                        SendEmailInvocable.sendEmail(handoverPhase.KeyHandoverInvitationEmailTempId__c, hoRec.Id);
                    }
                }
                   when 'Register Title Deed' {
                    if (!hoRec.IsOustandingPaymentconfirmedsent__c && String.isNotBlank(handoverPhase.HOOutstandingConfirmationTempId__c)) {
                        SendEmailInvocable.sendEmail(handoverPhase.HOOutstandingConfirmationTempId__c, hoRec.Id);
                    }
                }
                   when 'Handover Signing Document' {
                    if (!hoRec.IsHandoverSigningInvitationSent__c && String.isNotBlank(handoverPhase.SignHoDOCInvitationTempId__c)) {
                        SendEmailInvocable.sendEmail(handoverPhase.SignHoDOCInvitationTempId__c, hoRec.Id);
                    }
                }
                when 'Handover Completed' {
                    if (!hoRec.CongratulationOnHandoverEmailsent__c && String.isNotBlank(handoverPhase.HOCongratulationEmailTempId__c)) {
                        SendEmailInvocable.sendEmail(handoverPhase.HOCongratulationEmailTempId__c, hoRec.Id);
                    }
                }
                when 'CHO Snagging Completed', 'CHO De-Snagging' {
                    if (!hoRec.PropertyHomeOrientationReport_Sent__c && 
                        hoRec.Customer_Availability_for_CHO__c == 'Customer Available' && 
                        String.isNotBlank(handoverPhase.CHOAttendedbyCustomerEmailTempId__c)) {

                        SendEmailInvocable.sendEmail(handoverPhase.CHOAttendedbyCustomerEmailTempId__c, hoRec.Id);

                    } else if (!hoRec.PropertyHomeOrientationByBloom__c && 
                               hoRec.Customer_Availability_for_CHO__c == 'Customer Delegate to BLoom' && 
                               String.isNotBlank(handoverPhase.ChoCustomerNotattendedEmailTempId__c)) {

                        SendEmailInvocable.sendEmail(handoverPhase.ChoCustomerNotattendedEmailTempId__c, hoRec.Id);

                    } else if (!hoRec.PropertyHomeOrientationWOCustomer__c && 
                               hoRec.Customer_Availability_for_CHO__c == 'Customer Not available' && 
                               String.isNotBlank(handoverPhase.HomeOrientationByBloomEmailTempId__c)) {

                        SendEmailInvocable.sendEmail(handoverPhase.HomeOrientationByBloomEmailTempId__c, hoRec.Id);
                    }
                }
            }
        }
    


    HandoverService handoverServiceObj = HandoverService.getInstance();
   
        handoverServiceObj.updateHandovers(handoverRecordsToUpdate);
    
}


    public static void generateDeveloperNOC(Map<Id,Handover__c> handoverMapToGenerateAndSendNOC){
       // Map<Id,String> hoIdToDrawloopNextValueMap = new Map<Id,String>();
        Map<String,DocumentType__c> unitTypeToDocTypeMap = new Map<String,DocumentType__c>();
        List<DocumentType__c> docTypeList = [ SELECT Id, DeliveryOption__c, DocGenPackage__c, ObjectType__c, Active__c, Type__c, 
			Project__r.Name, Project__c, ProcessType__c, Customer_Type__c, //Docusign_Envelope_Configuration_Document__c,
			Docusign_Envelope_Docusign_Id__c, Docusign_Envelope_Template__c, Docusign_Envelope_Template__r.dfsle__DocuSignId__c, 
			Document_Digital_Name__c, Document_Output_Name__c, Docusign_Envelope__c, UnitType__c
			FROM DocumentType__c 
			WHERE Active__c = true
				  AND isDocGen__c = true
				  AND ObjectType__c = 'Handover'
                  AND Type__c = 'Developer NOC' LIMIT 1
		];

        if(docTypeList != NULL && docTypeList.size() > 0){
            Map<String, Document__c> handoverIdToDocumentMap = new Map<String, Document__c>();
            List<Document__c> docList = [SELECT Id, SalesOrder__c, Document_Name__c, Handover__c
                                            FROM Document__c 
                                            WHERE Handover__c IN :handoverMapToGenerateAndSendNOC.keySet() 
                                            AND Document_Name__c = 'Developer NOC'];
            for(Document__c docRec : docList){
                handoverIdToDocumentMap.put(docRec.Handover__c, docRec);
            }
            
            for(Handover__c hoRec : handoverMapToGenerateAndSendNOC.values()){
                DocumentType__c docTypeRec = docTypeList[0];
                if(docTypeRec.DeliveryOption__c != null && docTypeRec.DocGenPackage__c != null && docTypeRec.Type__c != null) {
                    String drawloopNextVal =  'SFHandover__c:'+hoRec.Id+';SFDocument__c:'+handoverIdToDocumentMap.get(hoRec.Id).Id+';DDPId:'+docTypeRec.DocGenPackage__c+';Deploy:'+docTypeRec.DeliveryOption__c;
                    hoRec.Drawloop_Next_1__c = drawloopNextVal;
                }
            }
        }
    }

    public static void updateRelatedSalesorder(Map<Id, Handover__c> oldHOMap, List<Handover__c> newHOList){
        SalesOrderService objSalesOrderService = SalesOrderService.getInstance();
        List<SalesOrder__c> salesOrdersToUpdate = new List<SalesOrder__c>();
        for (Handover__c objHandover : newHOList) {
            if (oldHOMap != NULL && !oldHOMap.isEmpty()) {
                if(oldHOMap.get(objHandover.Id).Sales_Order__c != objHandover.Sales_Order__c) {
                    salesOrdersToUpdate.add(new SalesOrder__c(Id= objHandover.Sales_Order__c, Handover__c = objHandover.Id));
                }
            } else if(objHandover.Sales_Order__c != NULL){
                salesOrdersToUpdate.add(new SalesOrder__c(Id= objHandover.Sales_Order__c, Handover__c = objHandover.Id));
            }
            //salesOrdersToUpdate.add(soRec);
        }
        objSalesOrderService.updateSalesOrdersWithoutTrigger(salesOrdersToUpdate);
    }
}