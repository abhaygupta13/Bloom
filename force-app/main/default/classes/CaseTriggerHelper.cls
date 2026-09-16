/*
* @Author : Jayprakash Bharti
* @CreatedDate : 26th AUG 2024
* @Description : Case object trigger helper
*/
/*****************************************************************************************************
* Version       Author          Date             Comment
* 1.0           Jayprakash      26AUG2024
*  2.0          Eaglesdev       13Jul2025.       handleSendEmailActions
*****************************************************************************************************/

public without sharing class CaseTriggerHelper {
    
    private static final string POST_SALE_PAYMENT_DEFERRAL_RT_DEV_NAME { get { return 'Post_Sale_Payment_Deferral'; } }
    private static final string VEHICLE_PARKING_REQUEST_RT_DEV_NAME { get { return 'VehicleParkingRequest'; } }
    private static final string BFM_SERVICE_REQUEST_RT { get { return 'BFMServiceRequest'; } }
    private static final string DEFAULT_UNIT_RT_DEV_NAME { get { return 'DefaultUnit'; } }
    private static final string RESALE_PROPERTY_UNDER_CONSTRUCTION_RT { get { return 'Resale_Property_Under_Construction'; } }
    private static final string RESALE_MASTER_RT_DEV_NAME { get {return 'Resale_Master' ; } }
    
    private static final string ACKNOWLEDGEMENT_RECEIPT_RT { get { return 'Acknowledgment_Receipt'; } }//Pranav
    private static final string PAYMENT_DUE_DATE_UPDATE_RT { get { return 'Payment_Due_Date_Update'; } }//Pranav
    private static final string THIRD_PARTY_FORM_RT { get { return 'ThirdPartyForm'; } }//Pranav
    private static final string PAYMENT_SR_RT { get { return 'Payment_SR'; } }//Pranav
    private static final string LPF_WAIVER_REQUEST_RT { get { return 'LPFWaiverRequest'; } }//Pranav
    private static final string BROKER_REGISTRATION_RT_DEV_NAME { get { return 'Broker_Registration'; } }
    private static final string BROKER_RT_NAME { get { return 'Broker'; } }
    
    
    private static final string RESALE_PROPERTY_WITH_PPHP_RT { get { return 'Resale_Property_with_Post_Handover_Payment_Plan'; } }
    private static final string RESALE_PROPERTY_COMPLETED_PROJECT_RT { get { return 'Resale_Property_For_Completed_Project'; } }
    private static final string RESALE_MASTER_RT { get {return 'Resale_Master' ; } }
    private static final string CHEQUE_REPLACEMENT_REQUEST_RT { get { return 'ChequeReplacementRequest'; } }
    private static final string CHEQUE_WITHDRAWAL_REQUEST_RT { get { return 'ChequeWithdrawalRequest'; } }
    private static final string POP_SHARE_SR_RT { get { return 'ProofofPaymentShared'; } }//Pranav
    private static final string BANK_ACC_DTAIL_SR_RT { get { return 'BankAccountDetailsInquiry'; } }//Pranav
    private static final string COMMUNITY_GSR_RT { get { return 'Community General Service Request'; } }//eagles
    private static final string MOVEIN_RT { get { return 'Move In'; } }//eagles
    private static final String BROKER_REGISTRATION_RT {get { return 'Broker_Registration'; }}//BAPP
    private static final String INCORRECT_COMMISSION_AMOUNT_RT {get { return 'IncorrectCommissionAmount'; }}//BAPP
    private static final String DELAYED_COMMISSION_PAYMENT_RT {get { return 'DelayedCommissionPayment'; }}//BAPP
    private static final String OTHER_SERVICE_REQUEST_RT {get { return 'OtherServiceRequest'; }}//BAPP
    private static final String BROKER_AGENCY_DETAILS_UPDATE_RT {get { return 'Broker_Agency_Details_Update'; }}//BAPP
    private static final String BROKER_AGENT_DETAILS_UPDATE_RT {get { return 'BrokerAgentDetailsUpdate'; }}//BAPP
    private static final string GENERAL_ENQUIRY_RT { get { return 'GeneralEnquiry'; } } //samiksha
    private static final string SALES_OPERATION_RT { get { return 'SalesOperationService'; } }
    private static final string COMMON_AREA_REQUEST_RT { get { return 'Common_Area_Request'; } }
    private static final string MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final string MTD_CRM_TEAM_NOTIFICATION_TEMPLATE_ID { get { return 'DefaultServiceRequestClosedNotification'; } }
    private static final string TAWTHEEQ_ENROLLMENT_RT { get { return 'TawtheeqEnrollment'; } }
    private static final string CLOSED_STR { get { return 'Closed'; } }
    private static final string CANCELLED_STR { get { return 'Cancelled'; } }
      private static final string COMPLAINT_REQUEST_RT { get { return 'ComplaintRequest'; } }
     private static final string BROKER_GENERAL_REQUEST_RT { get { return 'Broker_General_Services'; } }
    
    public static void handleBeforeUpdate(List<Case> newCases, Map<Id,Case> oldCaseMap){
        MetadataService objMetadataService = MetadataService.getInstance();
        Map<Id,ServiceCatalog__c> serviceCatalogMap = new Map<Id,ServiceCatalog__c>(ServiceCatalogService.getInstance().getServiceCatalogByIds());
        Map<String, String> priorityMap = BFMServiceRequestHandler.getInstance().getPriorityBySubCategory();
        
        Id postSalePaymentDeferralRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,POST_SALE_PAYMENT_DEFERRAL_RT_DEV_NAME);
        Id resaleUnderConstructionRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,RESALE_PROPERTY_UNDER_CONSTRUCTION_RT);
        Id bfmServiceRequestRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,BFM_SERVICE_REQUEST_RT);
        Id bfmcommonAreaSRRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,COMMON_AREA_REQUEST_RT);
        Id defaultUnitRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,DEFAULT_UNIT_RT_DEV_NAME);
        Id resaleForCompletedProjectRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,RESALE_PROPERTY_COMPLETED_PROJECT_RT);
        Id resaleWithPHPPRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,RESALE_PROPERTY_WITH_PPHP_RT);
        Id acknowledgementRcptRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,ACKNOWLEDGEMENT_RECEIPT_RT);//Pranav
        Id pmntDuDtUpdtRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,PAYMENT_DUE_DATE_UPDATE_RT);//Pranav
        Id chequeReplacementRequestRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,CHEQUE_REPLACEMENT_REQUEST_RT);
        Id chequeWithdrawalRequestRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,CHEQUE_WITHDRAWAL_REQUEST_RT);
        Id resaleMasterRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, RESALE_MASTER_RT);
        Id pymntSrRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,PAYMENT_SR_RT);
        Id popShareSRRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,POP_SHARE_SR_RT);
        Id bnkAccDtlRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,BANK_ACC_DTAIL_SR_RT);
        Id generalEnquiryRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,GENERAL_ENQUIRY_RT);
        Id salesOperationRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,SALES_OPERATION_RT);
        
        for (Case caseRecord : newCases) {
            if (
                !String.isEmpty(caseRecord.SubStatus__c) 
                && (caseRecord.RecordTypeId == postSalePaymentDeferralRecordTypeId
                    ||caseRecord.RecordTypeId == resaleUnderConstructionRecordTypeId
                    ||caseRecord.RecordTypeId == defaultUnitRecordTypeId
                    ||caseRecord.RecordTypeId == resaleForCompletedProjectRecordTypeId
                    ||caseRecord.RecordTypeId == resaleWithPHPPRecordTypeId
                    ||caseRecord.RecordTypeId == acknowledgementRcptRTID
                    ||caseRecord.RecordTypeId == pmntDuDtUpdtRTID
                    ||caseRecord.RecordTypeId == chequeReplacementRequestRTID
                    ||caseRecord.RecordTypeId == chequeWithdrawalRequestRTID
                    ||caseRecord.RecordTypeId == resaleMasterRecordTypeId
                    ||caseRecord.RecordTypeId == pymntSrRTID
                    ||caseRecord.RecordTypeId == popShareSRRTID
                    ||caseRecord.RecordTypeId == bnkAccDtlRTID
                    ||caseRecord.RecordTypeId == generalEnquiryRTID
                    ||caseRecord.RecordTypeId == salesOperationRTID
                   )
                && oldCaseMap.get(caseRecord.Id).SubStatus__c != caseRecord.SubStatus__c
                && caseRecord.Status == 'New' 
                
            ) {
                caseRecord.Status ='In Progress';
            }

            if(caseRecord.RecordTypeId != bfmServiceRequestRecordTypeId && caseRecord.RecordTypeId != bfmcommonAreaSRRecordTypeId && caseRecord.ServiceCatalog__c != NULL && oldCaseMap.get(caseRecord.Id).ServiceCatalog__c != caseRecord.ServiceCatalog__c && serviceCatalogMap != NULL && serviceCatalogMap.containsKey(caseRecord.ServiceCatalog__c)){
                caseRecord.Type = serviceCatalogMap.get(caseRecord.ServiceCatalog__c).Category__c;
                caseRecord.SubType__c = serviceCatalogMap.get(caseRecord.ServiceCatalog__c).SubCategory__c;
            }

            if(String.isNotBlank(caseRecord.Nationality__c) && caseRecord.Nationality__c != oldCaseMap.get(caseRecord.Id).Nationality__c 
                    && (caseRecord.RecordTypeId == resaleUnderConstructionRecordTypeId
                    || caseRecord.RecordTypeId == resaleForCompletedProjectRecordTypeId
                    || caseRecord.RecordTypeId == resaleWithPHPPRecordTypeId
                    || caseRecord.RecordTypeId == resaleMasterRecordTypeId)){
                caseRecord.NationalityInArabic__c = objMetadataService.getNationalityInArabic(caseRecord.Nationality__c);
            }

            Boolean isCaseClosed = caseRecord.BFMRequestStatus__c == 'COMPLETED' || caseRecord.BFMRequestStatus__c == 'CLOSED';
            if(oldCaseMap.get(caseRecord.Id).BFMRequestStatus__c != caseRecord.BFMRequestStatus__c && (caseRecord.RecordTypeId == bfmServiceRequestRecordTypeId || caseRecord.RecordTypeId == bfmcommonAreaSRRecordTypeId) && isCaseClosed && oldCaseMap.get(caseRecord.Id).Status != 'Closed' ){
                caseRecord.Status = 'Closed';
            }
            if(String.isNotBlank(caseRecord.SubCategory__c) && priorityMap.containsKey(caseRecord.SubCategory__c) && caseRecord.SubCategory__c != oldCaseMap.get(caseRecord.Id).SubCategory__c && caseRecord.RecordTypeId == bfmServiceRequestRecordTypeId){
                caseRecord.Priority = priorityMap.get(caseRecord.SubCategory__c);
            }
            
        }
    }
    
    public static void handleAssignment(List<Case> newCases, Map<Id, Case> oldCaseMap) {
        
        List<Customer_Document__c> requestDocumentList = new List<Customer_Document__c>();
        
        Set<Id> serviceCatalogIds = new Set<Id>();
        
        for (Case caseRecord : newCases) {
            if (
                caseRecord.Service_Catalog__c != null &&
                caseRecord.Status == 'Submitted' &&
                oldCaseMap.get(caseRecord.Id).Status != 'Submitted'
            ) {
                if (caseRecord.Service_Catalog__c != null) {
                    serviceCatalogIds.add(caseRecord.Service_Catalog__c);
                }
            }
        }
        
        if (!serviceCatalogIds.isEmpty()) {
            List<Action_Items__c> taskManagers = [
                SELECT Id, Service_Catalog__c, On_Submit__c, OwnerId
                FROM Action_Items__c
                WHERE Service_Catalog__c IN :serviceCatalogIds
            ];
            
            Map<id, Service_Catalog__c> mapServiceCatelog  = ServiceCatalogService.getServiceCatalogAndrelatedDocuments(serviceCatalogIds);
            
            Map<Id, Action_Items__c> taskManagerMap = new Map<Id, Action_Items__c>();
            
            for (Action_Items__c taskManager : taskManagers) {
                if (taskManager.On_Submit__c == true) {
                    taskManagerMap.put(taskManager.Service_Catalog__c, taskManager);
                }
            }
            
            for (Case caseRecord : newCases) {
                if (
                    caseRecord.Status == 'Submitted' &&
                    serviceCatalogIds.contains(caseRecord.Service_Catalog__c)
                ) {
                    if (taskManagerMap.containsKey(caseRecord.Service_Catalog__c)) {
                        Action_Items__c taskManager = taskManagerMap.get(
                            caseRecord.Service_Catalog__c
                        );
                        
                        //caseRecord.ownerId = taskManager.OwnerId;
                    }
                }
            }
        }
    }
    
    public static void handleSubmittedCases(List<Case> newCases) {
        
        
        List<Customer_Document__c> requestDocumentList = new List<Customer_Document__c>();
        
        UnitService unitSer = new UnitService();
        
        Set<Id> serviceCatalogIds = new Set<Id>();
        
        Map<Id, Id> caseUnits = new Map<Id, Id>();
        
        Map<ID, Unit__c> units = new Map<ID, Unit__c>();
        
        for (Case caseRecord : newCases) {
            serviceCatalogIds.add(caseRecord.Service_Catalog__c);
            
            if (caseRecord.Unit__c != null) {
                caseUnits.put(caseRecord.Id, caseRecord.Unit__c);
            }
        }
        
        if (!caseUnits.isEmpty()) {
            units = unitSer.getUnitDetails(caseUnits.values());
        }
        
        if (!serviceCatalogIds.isEmpty()) {
            List<Action_Items__c> taskManagers = [
                SELECT Id, Service_Catalog__c, On_Submit__c, OwnerId
                FROM Action_Items__c
                WHERE Service_Catalog__c IN :serviceCatalogIds
            ];
            
            
            
            Map<id, Service_Catalog__c> mapServiceCatelog  = ServiceCatalogService.getServiceCatalogAndrelatedDocuments(serviceCatalogIds);
            
            
            Map<Id, Action_Items__c> taskManagerMap = new Map<Id, Action_Items__c>();
            
            for (Action_Items__c taskManager : taskManagers) {
                if (taskManager.On_Submit__c == true) {
                    taskManagerMap.put(taskManager.Service_Catalog__c, taskManager);
                }
            }
            
            for (Case caseRecord : newCases) {
                Service_Catalog__c serviceCatelog = mapServiceCatelog.get(
                    caseRecord.Service_Catalog__c
                );
                
                if (serviceCatelog!=null &&
                    serviceCatelog.Service_Catolog_Documents__r!=null && serviceCatelog.Service_Catolog_Documents__r.size() > 0) {
                        for (
                            Service_Catolog_Documents__c document : serviceCatelog.Service_Catolog_Documents__r
                        ) {
                            if (
                                document.Required_For__c != null &&
                                new List<String>(document.Required_For__c.split(';'))
                                .contains(newCases[0].User_Type__c)
                            ) {
                                Customer_Document__c doc = new Customer_Document__c();
                                
                                doc.Name = document.name;
                                
                                doc.Service_Catolog_Documents__c = document.Id;
                                
                                doc.Case__c = caseRecord.Id;
                                
                                if (document.is_Chiller_Enabled__c) {
                                    if (
                                        caseUnits.get(caseRecord.id) != null &&
                                        units.get(caseUnits.get(caseRecord.id)) != null &&
                                        units.get(caseUnits.get(caseRecord.id)).is_Chiller_Enabled__c
                                    ) {
                                        requestDocumentList.add(doc);
                                    }
                                } else {
                                    requestDocumentList.add(doc);
                                }
                            }
                        }
                    }
            }
        }
        
        if (!requestDocumentList.isEmpty()) {
            insert requestDocumentList;
                                           }
                                       }
    
    public static void handleAfterInsert(List<Case> newList){
        
        ServiceRequestHandler objServiceRequestHandler = ServiceRequestHandler.getInstance();
        
        Id vehicleRegistrationServiceRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,VEHICLE_PARKING_REQUEST_RT_DEV_NAME);
        Id postSalePaymentDeferralRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,POST_SALE_PAYMENT_DEFERRAL_RT_DEV_NAME);
        Id defaultUnitRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,DEFAULT_UNIT_RT_DEV_NAME);
        Id generalEnquiryRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,GENERAL_ENQUIRY_RT);
        Id acnowledgementReceiptRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,ACKNOWLEDGEMENT_RECEIPT_RT);//Pranav
        Id pymntDuDtUpdtRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,PAYMENT_DUE_DATE_UPDATE_RT);//Pranav
        Id resaleMasterRecordTypeId =  Utility.getRecordTypeIdByDevName(Case.SObjectType,RESALE_MASTER_RT_DEV_NAME);
        Id thrdPrtyFrmRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,THIRD_PARTY_FORM_RT);//Pranav
        Id ptmntSrRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,PAYMENT_SR_RT);//Pranav
        Id lpfWaiverRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,LPF_WAIVER_REQUEST_RT);//Pranav
        Id popShareSRRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,POP_SHARE_SR_RT);//Pranav
        Id bnkAccDtlRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,BANK_ACC_DTAIL_SR_RT);//Pranav
        Id salesOperationRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,SALES_OPERATION_RT);
        Id tawtheeqEnrollmentRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,TAWTHEEQ_ENROLLMENT_RT); 
        Id commonAreaRequestRTId = Utility.getRecordTypeIdByDevName(Case.SObjectType,COMMON_AREA_REQUEST_RT); 
         Id complaintRequestID = Utility.getRecordTypeIdByDevName(Case.SObjectType,COMPLAINT_REQUEST_RT);
        Id brokergeneralRequestID = Utility.getRecordTypeIdByDevName(Case.SObjectType,BROKER_GENERAL_REQUEST_RT);
        
        List<Case> vehicleRegistrationServiceCaseList = new List<Case>();
        List<Case> postSalePaymentDeferralCaseList = new List<Case>();
        List<Case> defaultUnitCaseList = new List<Case>();
        List<Case> resaleCaseList = new List<Case>();
        List<Case> serviceRequestAcknowledgementList = new List<Case>();
        List<Case> generalEnquiryList = new List<Case>();
         List<Case> complaintRequestList = new List<Case>();
         List<Case> brokerGeneralRequestList = new List<Case>();
        
        for(Case objCase :newList){
            if(objCase.RecordTypeId == postSalePaymentDeferralRecordTypeId){
                postSalePaymentDeferralCaseList.add(objCase);
            }
            else if(objCase.RecordTypeId == defaultUnitRecordTypeId){
                defaultUnitCaseList.add(objCase);
            }
            else if(objCase.RecordTypeId == resaleMasterRecordTypeId){
                resaleCaseList.add(objCase);
            }
            else if(objCase.RecordTypeId == vehicleRegistrationServiceRecordTypeId){
                vehicleRegistrationServiceCaseList.add(objCase);
            }
            else if(objCase.RecordTypeId == generalEnquiryRTID){
                generalEnquiryList.add(objCase);
            }
                else if(objCase.RecordTypeId == complaintRequestID){
                complaintRequestList.add(objCase);
            }
               else if(objCase.RecordTypeId == brokergeneralRequestID){
                brokerGeneralRequestList.add(objCase);
            }
            
            if(objCase.RecordTypeId == postSalePaymentDeferralRecordTypeId 
                || objCase.RecordTypeId == resaleMasterRecordTypeId
                || objCase.RecordTypeId == lpfWaiverRTID
                || objCase.RecordTypeId == acnowledgementReceiptRTID
                || objCase.RecordTypeId == pymntDuDtUpdtRTID
                || objCase.RecordTypeId == thrdPrtyFrmRTID
                || objCase.RecordTypeId == generalEnquiryRTID
                || objCase.RecordTypeId == ptmntSrRTID
                || objCase.RecordTypeId == popShareSRRTID
                || objCase.RecordTypeId == bnkAccDtlRTID
                || objCase.RecordTypeId == tawtheeqEnrollmentRTID
                || objCase.RecordTypeId == commonAreaRequestRTId
              || objCase.RecordTypeId == complaintRequestID
                ){
                   serviceRequestAcknowledgementList.add(objCase);
               }
            
        } 
        
        objServiceRequestHandler.serviceRequestAcknowledgementEmailNotification(serviceRequestAcknowledgementList);
        
        //Payment deferral SRsalesorder
        if(!postSalePaymentDeferralCaseList.isEmpty()){
            PostSalePaymentDeferalCaseHandler obj = PostSalePaymentDeferalCaseHandler.getInstance();
            obj.createDocuments(postSalePaymentDeferralCaseList); 
            obj.createCaseInstallments(postSalePaymentDeferralCaseList);
        }
        if(!resaleCaseList.isEmpty()){
            ResaleServiceRequestHandler.getInstance().createDocuments(resaleCaseList);
        }
        if(!defaultUnitCaseList.isEmpty()){
            DefaultUnitCaseHandler.getInstance().createDocuments(defaultUnitCaseList);
        }
        if(!vehicleRegistrationServiceCaseList.isEmpty()){
            CommunitySiteController.invokeANPRApprovaProcess(vehicleRegistrationServiceCaseList);
        }     
         if(!generalEnquiryList.isEmpty()){
            //GeneralEnquirySRHandler.getInstance().createFirstTask(generalEnquiryList);
            GeneralEnquirySRHandler.getInstance().createDocumentPlaceholder(generalEnquiryList);
        } 
         if(!brokerGeneralRequestList.isEmpty()){
            BrokerGeneralSRHandler.getInstance().createFirstTask(brokerGeneralRequestList);
            
        } 
        
    }

    public static void handleAfterUpdate(List<Case> newList, Map<Id,Case> oldMap){

        List<Case> serviceRequestList = new List<Case>();
          List<Case> complaintCases = new List<Case>();
        Set<String> eligibleStatusSet = new Set<String>{CLOSED_STR, CANCELLED_STR};

        Id commonAreaRequestRTId = Utility.getRecordTypeIdByDevName(Case.SObjectType,COMMON_AREA_REQUEST_RT);
          Id complaintRequestID = Utility.getRecordTypeIdByDevName(Case.SObjectType,COMPLAINT_REQUEST_RT);
        
        for(Case objCase :newList){
            if(objCase.RecordTypeId == commonAreaRequestRTId && objCase.RequesterEmail__c != null && objCase.Status != oldMap.get(objCase.Id).Status && eligibleStatusSet.contains(objCase.Status)){
                serviceRequestList.add(objCase);
            }
        }
         
        if(!serviceRequestList.isEmpty()){
            ServiceRequestHandler.getInstance().serviceRequestClosureEmailNotification(serviceRequestList);
        } 
              
        if(!complaintCases.isEmpty()){
    CRMComplaintRequestHandler.getInstance().sendComplaintClosureEmails(complaintCases);
}
    }
    
    
    public static void handleVehicleParkingRegistrationReqAfterUpdate(List<Case> caseList, Map<Id,Case> oldMap){
        Id vehicleRegistrationServiceRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,VEHICLE_PARKING_REQUEST_RT_DEV_NAME);
        
        //Case id set where Vehicle Registration Status is Approved
        Set<Id> caseVRSApprovedIdSet = new Set<Id>();
        Set<Id> caseVRSRejectedIdSet = new Set<Id>();
        Set<Id> unitIdSet = new Set<Id>();
        
        for(Case c : caseList){
            if(c.RecordTypeId == vehicleRegistrationServiceRecordTypeId && c.VehicleRegistrationStatus__c == 'Approved' && oldMap.get(c.Id).VehicleRegistrationStatus__c != 'Approved'){
                caseVRSApprovedIdSet.add(c.Id);
            }
            if(c.RecordTypeId == vehicleRegistrationServiceRecordTypeId && c.VehicleRegistrationStatus__c == 'Rejected' && oldMap.get(c.Id).VehicleRegistrationStatus__c != 'Rejected'){
                caseVRSRejectedIdSet.add(c.Id);
            }
        }
        
        if(!caseVRSApprovedIdSet.isEmpty()){
            CaseService objCaseService = CaseService.getInstance();
            VehicleParkingService objVehicleParkingService = VehicleParkingService.getInstance();
            Map<Id, Case> caseMap = new Map<Id, Case>(objCaseService.getCasesNVehicleParkingDetailsByIds(caseVRSApprovedIdSet));
            List<VehicleParking__c> vehicleParkingList = new List<VehicleParking__c>();
            for(case c : caseMap.values()){
                if(c.VehicleParkingDetails__r.isEmpty()){
                    continue;
                }
                for(VehicleParkingDetails__c vpd : c.VehicleParkingDetails__r){
                    vehicleParkingList.add(new VehicleParking__c(VehicleMakeModel__c = vpd.VehicleMakeModel__c, VehiclePlateNumber__c = vpd.VehiclePlateNumber__c, Status__c = 'Active', Unit__c = vpd.Unit__c, StartDate__c = Date.today()));
                    unitIdSet.add(vpd.Unit__c);
                }
            }
            
            //Update old Vehicle Parking records to Inactive under respective units
            if(!unitIdSet.isEmpty()){
                CommunitySiteController.inactiveVehicleParkingByUnitIds(unitIdSet);
            }
            
            //Create new Vehicle Parking records under respective units
            if(!vehicleParkingList.isEmpty()){
                objVehicleParkingService.insertVehicleParkingRecord(vehicleParkingList);
            }
        }
        
        if(!caseVRSApprovedIdSet.isEmpty() ||  !caseVRSRejectedIdSet.isEmpty()){
            CommunitySiteController.invokeApprovedNRejectedEmail(caseVRSApprovedIdSet, caseVRSRejectedIdSet);
        }
    }
    
    public static void handleBeforeInsert(List<Case> listOfCases){
        Id bfmServiceRequestRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,BFM_SERVICE_REQUEST_RT);
        Id bfmcommonAreaSRRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,COMMON_AREA_REQUEST_RT);
        
        Id brokerRegistrationRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, BROKER_REGISTRATION_RT);//BAPP
        Id incorrectCommissionAmountRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, INCORRECT_COMMISSION_AMOUNT_RT);//BAPP
        Id delayedCommissionPaymentRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, DELAYED_COMMISSION_PAYMENT_RT);//BAPP
        Id otherServiceRequestRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, OTHER_SERVICE_REQUEST_RT);//BAPP
        Id brokerAgencyDetailsUpdateRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, BROKER_AGENCY_DETAILS_UPDATE_RT);//BAPP
        Id brokerAgentDetailsUpdateRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, BROKER_AGENT_DETAILS_UPDATE_RT);//BAPP
        AccountService accServiceObj = AccountService.getInstance();
        ContactService conServiceObj = ContactService.getInstance();
        UserService userServiceObj = UserService.getInstance();
        User currentUser = userServiceObj.getUsersById(UserInfo.getUserId());
        Set<String> emailSet = new Set<String>();
        Map<String, Id> emailToAccountMap = new Map<String, Id>();
        Map<String, Id> emailToContactAccountMap = new Map<String, Id>();
        Map<Id,ServiceCatalog__c> serviceCatalogMap = new Map<Id,ServiceCatalog__c>(ServiceCatalogService.getInstance().getServiceCatalogByIds());
        Map<String, String> priorityMap = BFMServiceRequestHandler.getInstance().getPriorityBySubCategory();

        for(Case caseObj : listOfCases){
            if (caseObj.RecordTypeId != bfmServiceRequestRecordTypeId &&
                caseObj.RecordTypeId != bfmcommonAreaSRRecordTypeId &&
                caseObj.RecordTypeId != brokerRegistrationRecordTypeId &&
                caseObj.RecordTypeId != incorrectCommissionAmountRecordTypeId &&
                caseObj.RecordTypeId != delayedCommissionPaymentRecordTypeId &&
                caseObj.RecordTypeId != otherServiceRequestRecordTypeId &&
                caseObj.RecordTypeId != brokerAgencyDetailsUpdateRecordTypeId &&
                caseObj.RecordTypeId != brokerAgentDetailsUpdateRecordTypeId &&
                caseObj.ServiceCatalog__c != null &&
                serviceCatalogMap != null &&
                serviceCatalogMap.containsKey(caseObj.ServiceCatalog__c)) {
                    caseObj.Type = serviceCatalogMap.get(caseObj.ServiceCatalog__c).Category__c;
                    caseObj.SubType__c = serviceCatalogMap.get(caseObj.ServiceCatalog__c).SubCategory__c;
                }
            if(caseObj.RecordTypeId != null && caseObj.SuppliedEmail != null){
                emailSet.add(caseObj.SuppliedEmail);
            }
            if(String.isNotBlank(caseObj.SubCategory__c) && priorityMap.containsKey(caseObj.SubCategory__c) && caseObj.RecordTypeId == bfmServiceRequestRecordTypeId){
                caseObj.Priority = priorityMap.get(caseObj.SubCategory__c);
            }
            if(caseObj.RecordTypeId == bfmcommonAreaSRRecordTypeId){
                populateRequesterDetails(caseObj, currentUser);
            }

        }
        if(!emailSet.isEmpty() || test.isRunningTest()){
            for (Account acc : accServiceObj.getAccountByEmails(emailSet)) {
                emailToAccountMap.put(acc.PersonEmail, acc.Id);
            }
            for (Contact con : conServiceObj.getContactByEmails(emailSet)) {
                if (con.AccountId != null) {
                    emailToContactAccountMap.put(con.Email, con.AccountId);
                }
            }
            // Assign AccountId to Cases
            for (Case caseObj : listOfCases) {
                if (caseObj.SuppliedEmail != null && caseObj.RecordTypeId != null) {
                    if (emailToAccountMap.containsKey(caseObj.SuppliedEmail)) {
                        caseObj.AccountId = emailToAccountMap.get(caseObj.SuppliedEmail);
                    } else if (emailToContactAccountMap.containsKey(caseObj.SuppliedEmail)) {
                        caseObj.AccountId = emailToContactAccountMap.get(caseObj.SuppliedEmail);
                    }
                }
            }
        }
    }
    
    // BAPP : To create Document Placeholders for Cases with 'Broker_Registration' Record Type - Role-based and Type of Establishment logic
    public static void createDocuments(List<Case> newList) {
        if (newList.isEmpty()) return;
        
        DocumentService objDocumentService = DocumentService.getInstance();
        
        // Fetch DocumentTypes for Case object
        List<DocumentType__c> caseDocTypeList = objDocumentService.getDocTypes('Case');
        
        // Get RecordType Id for 'Broker_Registration'
        Id brokerRegRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('Broker_Registration')
            .getRecordTypeId();
        
        Id brokerAgencyDetailsRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('Broker_Agency_Details_Update')
            .getRecordTypeId();
        
        Id agentDetailUpdateRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('BrokerAgentDetailsUpdate')
            .getRecordTypeId();
        
        Id delayedCommissionRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('DelayedCommissionPayment')
            .getRecordTypeId();
        
        Id incorrectCommissionAmountRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('IncorrectCommissionAmount')
            .getRecordTypeId();
        
        Id otherServiceRequestRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('OtherServiceRequest')
            .getRecordTypeId();
        
        // Collect Case Ids
        Set<Id> caseIds = new Set<Id>();
        for (Case cs : newList) {
            if (cs.RecordTypeId == brokerRegRTId 
                || cs.RecordTypeId == brokerAgencyDetailsRTId 
                || cs.RecordTypeId == agentDetailUpdateRTId
                || cs.RecordTypeId == delayedCommissionRTId
                || cs.RecordTypeId == incorrectCommissionAmountRTId
                || cs.RecordTypeId == otherServiceRequestRTId) {
                    caseIds.add(cs.Id);
                }
        }
        
        // Fetch existing Case documents
        Map<Id, List<Document__c>> existingDocsMap = new Map<Id, List<Document__c>>();
        if (!caseIds.isEmpty()) {
            List<Document__c> existingDocs = objDocumentService.getCaseDocuments(caseIds);
            for (Document__c doc : existingDocs) {
                if (doc.Case__c != null) {
                    if (!existingDocsMap.containsKey(doc.Case__c)) {
                        existingDocsMap.put(doc.Case__c, new List<Document__c>());
                    }
                    existingDocsMap.get(doc.Case__c).add(doc);
                }
            }
        }
        
        List<Document__c> documentList = new List<Document__c>();
        
        // Process incoming cases
        for (Case cs : newList) {
            
            // ---- Logic for Broker_Registration & Agent_Detail_Update ----
            if (cs.RecordTypeId == brokerRegRTId || cs.RecordTypeId == agentDetailUpdateRTId) {
                
                if (!String.isBlank(cs.BrokerContactRole__c)) {
                    Set<String> caseRoles = new Set<String>();
                    for (String role : cs.BrokerContactRole__c.split(';')) {
                        caseRoles.add(role.trim());
                    }
                    
                    // Collect existing DocumentType Ids for this case
                    Set<Id> existingDocTypeIds = new Set<Id>();
                    if (existingDocsMap.containsKey(cs.Id)) {
                        for (Document__c existingDoc : existingDocsMap.get(cs.Id)) {
                            existingDocTypeIds.add(existingDoc.DocumentType__c);
                        }
                    }
                    
                    // Loop through DocumentTypes
                    for (DocumentType__c dt : caseDocTypeList) {
                        if (String.isBlank(dt.BrokerContactRole__c)) continue;
                        
                        Set<String> docRoles = new Set<String>();
                        for (String role : dt.BrokerContactRole__c.split(';')) {
                            docRoles.add(role.trim());
                        }
                        
                        Set<String> intersection = new Set<String>(caseRoles);
                        intersection.retainAll(docRoles);
                        
                        // Check if Case.TypeOfEstablishment__c exists in DocumentType multi-picklist
                        Boolean typeMatch = false;
                        if (!String.isBlank(cs.TypeOfEstablishment__c) && !String.isBlank(dt.TypeOfEstablishment__c)) {
                            for (String t : dt.TypeOfEstablishment__c.split(';')) {
                                if (cs.TypeOfEstablishment__c.trim() == t.trim()) {
                                    typeMatch = true;
                                    break;
                                }
                            }
                        }
                        
                        if (!intersection.isEmpty() &&
                            typeMatch &&
                            !existingDocTypeIds.contains(dt.Id)) {
                                
                                documentList.add(new Document__c(
                                    Case__c = cs.Id,
                                    DocumentType__c = dt.Id,
                                    Document_Name__c = dt.Type__c
                                ));
                        }
                    }
                }
            }
            
            // ---- Logic for Broker_Agency_Details_Update ----
            else if (cs.RecordTypeId == brokerAgencyDetailsRTId) {
                
                Set<Id> existingDocTypeIds = new Set<Id>();
                if (existingDocsMap.containsKey(cs.Id)) {
                    for (Document__c existingDoc : existingDocsMap.get(cs.Id)) {
                        existingDocTypeIds.add(existingDoc.DocumentType__c);
                    }
                }
                
                for (DocumentType__c dt : caseDocTypeList) {
                    if (dt.RecordTypeDevName__c == 'Broker_Agency_Details_Update' &&
                        dt.ObjectType__c == 'Case' &&
                        dt.TypeOfEstablishment__c != null &&
                        !existingDocTypeIds.contains(dt.Id)) {
                            
                            // match case type with doc type multi-picklist
                            Boolean typeMatch = false;
                            if (!String.isBlank(cs.TypeOfEstablishment__c)) {
                                for (String t : dt.TypeOfEstablishment__c.split(';')) {
                                    if (cs.TypeOfEstablishment__c.trim() == t.trim()) {
                                        typeMatch = true;
                                        break;
                                    }
                                }
                            }
                            
                            if (typeMatch) {
                                
                                documentList.add(new Document__c(
                                    Case__c = cs.Id,
                                    DocumentType__c = dt.Id,
                                    Document_Name__c = dt.Type__c
                                ));
                            }
                        }
                }
            }
            
            // ---- Logic for DelayedCommissionPayment ----
            else if (cs.RecordTypeId == delayedCommissionRTId) {
                
                Set<Id> existingDocTypeIds = new Set<Id>();
                if (existingDocsMap.containsKey(cs.Id)) {
                    for (Document__c existingDoc : existingDocsMap.get(cs.Id)) {
                        existingDocTypeIds.add(existingDoc.DocumentType__c);
                    }
                }
                
                for (DocumentType__c dt : caseDocTypeList) {
                    if (dt.RecordTypeDevName__c == 'DelayedCommissionPayment' &&
                        dt.ObjectType__c == 'Case' &&
                        String.isBlank(dt.TypeOfEstablishment__c) &&
                        !existingDocTypeIds.contains(dt.Id)) {
                                                        
                            documentList.add(new Document__c(
                                Case__c = cs.Id,
                                DocumentType__c = dt.Id,
                                Document_Name__c = dt.Type__c
                            ));
                        }
                }
            }
            // ---- Logic for IncorrectCommissionAmount ----
            else if (cs.RecordTypeId == incorrectCommissionAmountRTId) {
                
                Set<Id> existingDocTypeIds = new Set<Id>();
                if (existingDocsMap.containsKey(cs.Id)) {
                    for (Document__c existingDoc : existingDocsMap.get(cs.Id)) {
                        existingDocTypeIds.add(existingDoc.DocumentType__c);
                    }
                }
                
                for (DocumentType__c dt : caseDocTypeList) {
                    if (dt.RecordTypeDevName__c == 'IncorrectCommissionAmount' &&
                        dt.ObjectType__c == 'Case' &&
                        String.isBlank(dt.TypeOfEstablishment__c) &&
                        !existingDocTypeIds.contains(dt.Id)) {
                                                        
                            documentList.add(new Document__c(
                                Case__c = cs.Id,
                                DocumentType__c = dt.Id,
                                Document_Name__c = dt.Type__c
                            ));
                        }
                }
            }
            // ---- Logic for OtherServiceRequest ----
            else if (cs.RecordTypeId == otherServiceRequestRTId) {
                
                Set<Id> existingDocTypeIds = new Set<Id>();
                if (existingDocsMap.containsKey(cs.Id)) {
                    for (Document__c existingDoc : existingDocsMap.get(cs.Id)) {
                        existingDocTypeIds.add(existingDoc.DocumentType__c);
                    }
                }
                
                for (DocumentType__c dt : caseDocTypeList) {
                    if (dt.RecordTypeDevName__c == 'OtherServiceRequest' &&
                        dt.ObjectType__c == 'Case' &&
                        String.isBlank(dt.TypeOfEstablishment__c) &&
                        !existingDocTypeIds.contains(dt.Id)) {
                                                        
                            documentList.add(new Document__c(
                                Case__c = cs.Id,
                                DocumentType__c = dt.Id,
                                Document_Name__c = dt.Type__c
                            ));
                        }
                }
            }
        }
                
        if (!documentList.isEmpty()) {
            objDocumentService.insertDocuments(documentList);
        } else {
            System.debug('No matching documents for Cases.');
        }
    }
    
    
    
    public static void updateCaseApplicantDocuments(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
        List<Case> updatedCases = new List<Case>();
        
        for (Case newRec : (List<Case>) newList) {
            Case oldRec = (Case) oldMap.get(newRec.Id);
            
            String newRole = String.isBlank(newRec.BrokerContactRole__c) ? '' : newRec.BrokerContactRole__c.trim();
            String oldRole = String.isBlank(oldRec.BrokerContactRole__c) ? '' : oldRec.BrokerContactRole__c.trim();
            
            String newType = String.valueOf(newRec.TypeofEstablishment__c);
            String oldType = String.valueOf(oldRec.TypeofEstablishment__c);
            
            // If either Role or Type of Establishment changed, re-process
            if (newRole != oldRole || newType != oldType) {
                updatedCases.add(newRec);
            }
        }
        
        if (!updatedCases.isEmpty()) {
            createDocuments(updatedCases);
        }
    }
    
    public static void createBrokerContacts(List<Case> caseList) {
    
        List<Contact> toInsert = new List<Contact>();
        List<Contact> toUpdate = new List<Contact>();
        Set<String> nationalIds = new Set<String>();
        Set<Id> accountIds = new Set<Id>();
        Id brokerRTId = Utilities.getRecordTypeId('Contact', BROKER_RT_NAME);
        
        for (Case cs : caseList) {
            if (String.isNotBlank(cs.NationalID__c)) {
                nationalIds.add(cs.NationalID__c.trim());
            }
            if (cs.AccountId != null) {
                accountIds.add(cs.AccountId);
            }
        }
        
        ContactService objConService = ContactService.getInstance();
        List<Contact> existingContacts = objConService.getContactsByNationalIds(nationalIds, accountIds);
        Map<String, Contact> existingMap = new Map<String, Contact>();
        
        for (Contact c : existingContacts) {
            String key = c.NationalIdNumber__c + '_' + c.AccountId;
            existingMap.put(key, c);
        }
        
        for (Case cs : caseList) {
            if (String.isBlank(cs.NationalID__c)) {
                continue;
            }
            String key = cs.NationalID__c.trim() + '_' + cs.AccountId;
            
            Contact con;
                if (existingMap.containsKey(key)) {
                    con = existingMap.get(key);
                toUpdate.add(con);
                } else {
                    con = new Contact();
                    con.RecordTypeId = brokerRTId;
                    toInsert.add(con);
                
                // Add to map to prevent duplicate inserts in same transaction
                    existingMap.put(key, con);
                }
                
            con.IsActive__c = true;
            con.BrokerContactRole__c = cs.BrokerContactRole__c;
            con.Title = cs.Title__c;
            con.FirstName = cs.First_Name__c;
            con.MiddleName = cs.MiddleName__c;
            con.LastName = cs.Last_Name__c;
            con.PrimaryMobilePhone__c = cs.PhoneNumber__c;
            con.Email = cs.Email_Address__c;
            con.NationalIdNumber__c = cs.NationalID__c;
            con.NationalIdExpiryDate__c = cs.NationalIDExpiryDate__c;
            con.PassportNumber__c = cs.PassportNumber__c;
            con.PassportExpiryDate__c = cs.PassportExpiryDate__c;
            con.Birthdate = cs.DateOfBirth__c;
            con.Nationality__c = cs.Country__c;
            con.CountryOfResidence__c = 'United Arab Emirates';
            //con.CountryOfResidence__c = cs.Country__c;
            con.TypeofEstablishment__c = cs.TypeofEstablishment__c;
            con.CaseId__c = cs.Id;
            con.BRN_RERA_Number__c = cs.BRN_RERA_Number__c;
            con.BRN_RERA_Expiry_Date__c = cs.BRN_RERA_Expiry_Date__c;
            con.AccountId = cs.AccountId;
            con.ShareHoldingPercentage__c = cs.ShareHoldingPercentage__c;
            con.Designation__c = cs.Designation__c;
            con.PrimaryMobileCountryCode__c = cs.Mobile_Country_Code__c;
        }
        
        objConService.insertContacts(toInsert);
        objConService.updateContacts(toUpdate);
    }
    
    public static void updateBrokerAccounts(List<Case> brokerCases) {
        if (brokerCases.isEmpty()) return;
        // Collect Account Ids from Cases
        Set<Id> accountIds = new Set<Id>();
        for (Case cs : brokerCases) {
            if (cs.AccountId != null) {
                accountIds.add(cs.AccountId);
            }
        }
        
        if (accountIds.isEmpty()) return;
        
        // Query Accounts with parent BankAccount relationship
        Map<Id, Account> accountMap = AccountService.getAccountsMapByIds(accountIds);
        
        List<Account> accountsToUpdate = new List<Account>();
        List<BankAccount__c> bankAccountsToUpdate = new List<BankAccount__c>();
        List<Account> accountsForDocuments = new List<Account>();
        
        Map<Id, Id> caseToAccountMap = new Map<Id, Id>();
        for (Case cs : brokerCases) {	
            if (cs.AccountId == null) continue;
            
            Account acc = accountMap.get(cs.AccountId);
            if (acc == null) continue;
            
            caseToAccountMap.put(cs.Id, cs.AccountId);
            
            // ---- Account-level updates ----
            if (cs.Type == 'Trade License Expiry Update') {
                acc.Trade_License_Expiry_Date__c = cs.TradeLicenseExpiryDate__c;
                accountsForDocuments.add(acc);
                
            } else if (cs.Type == 'VAT Details Update') {
                acc.VATUndertakingIssueDate__c = cs.VATUndertakingIssue_Date__c;
                acc.TaxRegistrationNumber__c = cs.TaxRegistrationNumber__c;
                if(cs.IsVATRegistered__c == true){
                    acc.Is_VAT_Registered__c = 'Yes';
                }else{
                    acc.Is_VAT_Registered__c = 'No';
                }
                
                accountsForDocuments.add(acc);
                
            } else if (cs.Type == 'Agency Address Update') {
                acc.Phone__c = cs.PhoneNumber__c;
                
                // Combine Address1 + Address2 into BillingStreet
                String address1 = cs.Address1__c != null ? cs.Address1__c.trim() : '';
                String address2 = cs.Address2__c != null ? cs.Address2__c.trim() : '';
                
                if (!String.isBlank(address1) && !String.isBlank(address2)) {
                    acc.BillingStreet = address1 + '\n' + address2;
                } else if (!String.isBlank(address1)) {
                    acc.BillingStreet = address1;
                } else if (!String.isBlank(address2)) {
                    acc.BillingStreet = address2;
                }
                
            } else if (cs.Type == 'Commercial License Expiry Update') {
                acc.CommercialLicenseExpiryDate__c = cs.CommercialLicenseExpiryDate__c;
                accountsForDocuments.add(acc);
            }
            
            else if(cs.Type == 'Legal Documents Update'){
                accountsForDocuments.add(acc);
            }
            
            accountsToUpdate.add(acc);
            
            // ---- BankAccount (Parent) updates ----
            if (cs.Type == 'Bank Details Update' && acc.BankAccount__c != null) {
                BankAccount__c bankAcc = new BankAccount__c(
                    Id = acc.BankAccount__c,
                    AccountNumberCorporate__c = cs.AccountNumber__c,
                    Name = cs.BankName__c,
                    BankAddress__c = cs.BankAddress__c,
                    IBANNoCorporate__c = cs.IBANNumber__c,
                    SwiftCodeCorporate__c = cs.SwiftCode__c
                );
                bankAccountsToUpdate.add(bankAcc);
                accountsForDocuments.add(acc);
            }
        }
        
        if (!accountsToUpdate.isEmpty()) {
            AccountService.updateExistingAccounts(accountsToUpdate);
        }
        if (!bankAccountsToUpdate.isEmpty()) {
            BankAccountService.updateExistingBankAccounts(bankAccountsToUpdate);
        }
        if (!accountsForDocuments.isEmpty()) {
            System.enqueueJob(new BAPPCopyDocumentsJob(caseToAccountMap,'Account'));
        }
        
    }
    
    // Update Agent Details
    public static void updateBrokerContactSR(List<Case> brokerCases) {
        if (brokerCases.isEmpty()) return;        
        Set<Id> contactIds = new Set<Id>();
        
        for (Case cs : brokerCases) {
            if (cs.Broker_Agent__c != null) {
                contactIds.add(cs.Broker_Agent__c);
            } else if (cs.ContactId != null) {
                contactIds.add(cs.ContactId);
            }
        }
        
        if (contactIds.isEmpty()) return;
        
        // Query existing Contacts
        Map<Id, Contact> contactMap = ContactService.fetchContactsByIds(contactIds);
        
        List<Contact> contactsToUpdate = new List<Contact>();
        Map<Id, Id> caseToContactMap = new Map<Id, Id>();
        
        for (Case cs : brokerCases) {
            Id targetContactId = (cs.Broker_Agent__c != null) ? cs.Broker_Agent__c : cs.ContactId;
            if (targetContactId == null) continue;
            
            Contact con = contactMap.get(targetContactId);
            if (con == null) continue;
            
            if (cs.Type == 'Agent Details Update') {
                // con.RecordTypeId = brokerContactRTId;
                con.CaseId__c = cs.Id;
                con.BrokerContactRole__c = cs.BrokerContactRole__c;
                //con.Phone = cs.PhoneNumber__c;
                con.NationalIdExpiryDate__c = cs.NationalIDExpiryDate__c;
                con.PassportExpiryDate__c = cs.PassportExpiryDate__c;
                //con.MobileCountryCode__c = cs.Mobile_Country_Code__c;
                con.BRN_RERA_Expiry_Date__c = cs.BRN_RERA_Expiry_Date__c;
                con.AccountId = cs.AccountId;
                
                contactsToUpdate.add(con);
                
                caseToContactMap.put(cs.Id, targetContactId);
                
            }
        }
        
        if (!contactsToUpdate.isEmpty()) {
            ContactService.updateExistingContacts(contactsToUpdate);
        }
        if (!caseToContactMap.isEmpty()) {
            System.enqueueJob(new BAPPCopyDocumentsJob(caseToContactMap, 'Contact'));
        }
        
    }
    
    
    //BCAPP phase 2 change - to handle emails and push notification actions
    public static void handleSendEmailActions(List<sObject> newCases,Map<Id,sObject> oldMap) {
        
        Set<Id> catalogIds = new Set<Id>();
        List<Case> caseWithSendEmailActions = new List<Case>();
        for(sObject sObj:newCases){
            Case rec = (Case)sobj;
            Set<String> validRTIds = new Set<String>{
                Utilities.getRecordTypeId('Case', COMMUNITY_GSR_RT),
                    Utilities.getRecordTypeId('Case', MOVEIN_RT)
                    };
                        if (rec.Service_Catalog__c != null && validRTIds.contains(rec.RecordTypeId)){
                            caseWithSendEmailActions.add(rec);
                        }  
        }
        if (!caseWithSendEmailActions.isEmpty()) {
            BCAPP_SendNotificationAction notifyHandler = new BCAPP_SendNotificationAction(caseWithSendEmailActions,oldMap);
            notifyHandler.handleSendEmailActionItems();
            notifyHandler.handlePushNotificationActionItems();
        }        
        
    }
    public static void sendBBMQueueEmails(List<Case> casesToSend) {
        if (casesToSend == null || casesToSend.isEmpty()) return;
        
        // Get BBM Queue users
        Group brokerTeamQueue = QueueService.getInstance()
            .getGroupByDeveloperNameAndType('Broker_Mangement_Team', 'Regular');
        if (brokerTeamQueue == null) return;
        
        List<GroupMember> members = QueueService.getInstance().getGroupMembersByGroupId(brokerTeamQueue.Id);
        if (members.isEmpty()) return;
        
        Set<Id> userIds = new Set<Id>();
        for (GroupMember gm : members) userIds.add(gm.UserOrGroupId);
        
        // Fetch active users
        List<User> users = UserService.getInstance().getActiveUsersWithEmailByIds(userIds);
        if (users.isEmpty()) return;
        
        // Collect user emails
        List<String> toEmails = new List<String>();
        for (User u : users) toEmails.add(u.Email);
        
        // Fetch email template
        EmailTemplate template = EmailTemplateService.getEmailTemplateByDeveloperName('BAPPCommissionUpdates');
        if (template == null) return;
        
        // Get Org-Wide Email Address ID ✅
        String orgWideEmail = MetadataService.getInstance().getAppSettingTextValue('BAPPOrgWideEmailAddress');
        
        // Re-query cases with related Account fields
        List<Id> caseIds = new List<Id>();
        for (Case c : casesToSend) caseIds.add(c.Id);
        
        List<Case> fullCases = CaseService.getInstance().getCaseDetailsWithBrokerAppNumber(caseIds);
        
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        
        for (Case cs : fullCases) {
            Boolean shouldSend = false;
            
            if ((cs.Type == 'Bank Details Update' || cs.Type == 'VAT Details Update' ||
                 cs.Type == 'Trade License Expiry Update' || cs.Type == 'Commercial License Expiry Update') &&
                cs.ApprovalStatus__c == 'Approved') {
                    shouldSend = true;
                } else if (cs.Type == 'Agent Details Update' && cs.ApprovalStatus__c == 'Approved') {
                    List<String> roles = cs.BrokerContactRole__c != null ? cs.BrokerContactRole__c.split(';') : new List<String>();
                    if (roles.contains('AuthorizedSignatoryOfficer')) shouldSend = true;
                }
            
            if (!shouldSend) continue;
            
            // Prepare dynamic HTML by replacing placeholders
            String htmlBody = template.HtmlValue
                .replace('{{CaseType}}', cs.Type != null ? cs.Type : '')
                .replace('{{Account Name}}', cs.Account != null && cs.Account.Name != null ? cs.Account.Name : '');
            
            // Build SingleEmailMessage using EmailService
            Messaging.SingleEmailMessage mail = EmailService.getInstance().getSingleEmailMessage(
                toEmails,       // send to users' emails
                null,           // whatId is null for Users
                null,           // targetObjectId is null (no merge fields tied to User)
                template.Subject,
                htmlBody,
                orgWideEmail  
            );
            mail.setSaveAsActivity(false);  // required for Users
            emailsToSend.add(mail);
        }
        
        if (!emailsToSend.isEmpty()) {
            EmailService.getInstance().sendEmail(emailsToSend);
        }
    }

    public static void handleDefaultUnitCaseClosure(List<Case> defaultUnitCaseList){
        //Send Email to Handover CRM Assigned User
        //Update status of existing Handovers
        HandoverService objHandoverService = HandoverService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        // objUserService = UserService.getInstance();

        //Set<Id> crmAssignedUserIdSet = new Set<Id>();
        List<String> toAddresses = new List<String>();
        Set<Id> handoverIdSet = new Set<Id>();
        for(Case caseRec : defaultUnitCaseList){
            handoverIdSet.add(caseRec.Handover__c);
        }

        Map<Id,Handover__c> handoverMap = new Map<Id, Handover__c>(objHandoverService.getHandoverByIds(handoverIdSet));

        Id crmTeamNotificationETId = objMetadataService.getAppSettingTextValue(MTD_CRM_TEAM_NOTIFICATION_TEMPLATE_ID);
        EmailTemplate crmTeamNotificationTemplate = objEmailService.getEmailTemplateById(crmTeamNotificationETId);
        List<Messaging.SingleEmailMessage> msgList = new List<Messaging.SingleEmailMessage>();
        Id bloomNoReplySalesOWEId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);

        List<Handover__c> handoverListToUpdate = new List<Handover__c>();
        for(Handover__c handoverRec : handoverMap.values()){
            toAddresses.add(handoverRec.CRM_Team_Assigned_User__r.Email);
            Messaging.SingleEmailMessage objEmailMessage = objEmailService.getSingleEmailMessageWithoutTargetObjectId(crmTeamNotificationETId, bloomNoReplySalesOWEId, handoverRec.Id, toAddresses, null, null);
            msgList.add(objEmailMessage);

            if(handoverRec.Sub_Status__c == 'Potential Defaulter'){
                handoverRec.Sub_Status__c = handoverRec.Previous_HO_Status__c;
                handoverListToUpdate.add(handoverRec);
            }
        }
        
        objEmailService.sendEmail(msgList);
        objHandoverService.updateHandovers(handoverListToUpdate);
    }

    private static void populateRequesterDetails( Case caseObj, User userObj ){
        if(String.isBlank(caseObj.RequesterName__c)){
            caseObj.RequesterName__c = UserInfo.getName();
        }

        if(String.isBlank(caseObj.RequesterEmail__c)){
            caseObj.RequesterEmail__c = UserInfo.getUserEmail();
        }

        if(String.isBlank(caseObj.RequesterContactNumber__c)){
            caseObj.RequesterContactNumber__c = userObj.Phone;
        }
    }
}