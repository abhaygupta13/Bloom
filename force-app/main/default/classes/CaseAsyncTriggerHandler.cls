/***
Class       : CaseAsyncTriggerHandler
Author      : Smaartt
Description : 
TestClass   : CaseAsyncTriggerHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.     version              Date                Details
1.          V1.0                                Initial Version 
****************************************************************************************************************/
public without sharing class CaseAsyncTriggerHandler implements IAsyncTriggerHandler{
    
    private static final string DIGITAL_CASE_CREATED_BY_IDS { get { return 'DigitalCaseCreatedByIds'; } }
    private static final string CASE_RT_DEV_NAME_SOCIAL_MEDIA { get { return 'Social_Media'; } }
    private static final string POST_SALE_PAYMENT_DEFERRAL_RT { get { return 'Post_Sale_Payment_Deferral'; } }
    private static final string CASE_RT_DEV_NAME_CONTACT_CENTER_DIGITAL { get { return 'ContactCenterDigitalCase'; } }
    private static final string CASE_RT_DEV_NAME_BFM_SERVICE_REQUEST { get { return 'BFMServiceRequest'; } }
    private static final string CASE_RT_IDS { get { return 'ComplaintCaseRecordTypeIds'; } }
    private static final string DEFAULT_UNIT_RT { get { return 'DefaultUnit'; } }
    private static final string RESALE_RT_DEV_NAME { get { return 'Resale_Master'; } }
    private static final string RESALE_PROPERTY_WITH_PPHP_RT { get { return 'Resale_Property_with_Post_Handover_Payment_Plan'; } }
    private static final string RESALE_PROPERTY_COMPLETED_PROJECT_RT { get { return 'Resale_Property_For_Completed_Project'; } }
    private static final string RESALE_PROPERTY_UNDER_CONSTRUCTION_RT { get { return 'Resale_Property_Under_Construction'; } }
    
    private static final string ACKNOWLEDGEMENT_RECEIPT_RT { get { return 'Acknowledgment_Receipt'; } }//Pranav
    private static final string PAYMENT_DUE_DATE_UPDATE_RT { get { return 'Payment_Due_Date_Update'; } }//Pranav
    private static final string THIRD_PARTY_FORM_RT { get { return 'ThirdPartyForm'; } }//Pranav
    private static final string PAYMENT_SR_RT { get { return 'Payment_SR'; } }//Pranav
    private static final string CHEQUE_REPLACEMENT_REQUEST_RT { get { return 'ChequeReplacementRequest'; } }
    private static final string CHEQUE_WITHDRAWAL_REQUEST_RT { get { return 'ChequeWithdrawalRequest'; } }
    private static final string ANPR_CASE_RT { get { return 'VehicleParkingRequest'; } }
    private static final string ACCESS_PERMIT_RT { get { return 'Access_Permit'; } }
    private static final string MOVE_IN_RT { get { return 'Move_In'; } }
    private static final string MOVE_IN_HOLIDAY_HOMES_RT { get { return 'Move_In_Holiday_Homes'; } }
    private static final string MOVE_IN_OWNER_RT { get { return 'Move_In_Owner'; } }
    private static final string MOVE_OUT_RT { get { return 'Move_Out'; } }
    private static final string Renewal { get { return 'Renewal'; } }
    private static final string LPF_WAIVER_REQUEST_RT { get { return 'LPFWaiverRequest'; } }
    private static final string SOA_REQUEST_RT { get { return 'SOARequest'; } }
    private static final string POP_SHARE_SR_RT { get { return 'ProofofPaymentShared'; } }//Pranav
    private static final string BANK_ACC_DTAIL_SR_RT { get { return 'BankAccountDetailsInquiry'; } }//Pranav
    private static final string GENERAL_ENQUIRY_RT { get { return 'GeneralEnquiry'; } }
    private static final string KYC_UPDATE_REQUEST_RT { get { return 'KYCUpdateRequest'; } }
    private static final string GENERAL_SERVICE_REQUEST_RT { get { return 'General_Service_Request'; } }
    private static final string FINANCIAL_SERVICE_REQUEST_RT { get { return 'Financial_Services'; } }
    private static final string HANDOVER_SERVICE_REQUEST_RT { get { return 'Handover_Service_Request'; } }
    private static final string SPECIAL_SERVICES_RT { get { return 'Special_Services'; } }
    private static final string COMPLETED_STR { get { return 'COMPLETED'; } }
    private static final string CLOSED_STR { get { return 'CLOSED'; } }
    private static final string SALES_OPERATION_RT { get { return 'SalesOperationService'; } }
    private static final string BROKER_AGENT_REGISTRATION_UPDATE_RT { get { return 'BrokerAgentRegistrationAndUpdate'; } } //Bapp 
    private static final string CASE_RT_DEV_NAME_BROKER_COMMISSION_ISSUE  { get { return 'BrokerCommissionIssue'; } } //BAPP Broker Generic Case
    private static final string CASE_RT_DEV_NAME_OTHER_SERVICE_REQUEST  { get { return 'BrokerGeneralServiceRequest'; } }  //BAPP Broker Generic Case
    private static final string BROKER_AGENCY_DETAILS_UPDATE_RT { get { return 'BrokerAgencyDetailsUpdate'; } } //Bapp
    private static final String SUPER_APP_STR = 'Super App';
    private static final string COMPLAINT_REQUEST_RT { get { return 'ComplaintRequest'; } }
     private static final string CANCELLATION_REQUEST_RT { get { return 'CancellationRequest'; } }
    private static final string TAWTHEEQ_ENROLLMENT_RT { get { return 'TawtheeqEnrollment'; } }
    private static final string BROKER_AGREEMENT_RENEWAL_RT { get { return 'BrokerAgreementRenewal'; } } //US-912
    private static final Set<String> BROKER_AGENCY_DETAILS_UPDATE_SUBTYPES = new Set<String>{'Trade License Expiry Update','Commercial License Expiry Update','VAT Details Update','Bank Details Update','Agency Address Update','Legal Documents Update','Agency Name or Type Update','Broker Agreement Renewal Complete Details Update'};
    
    //Use this variable to disable this trigger from transaction
    public static Boolean isAsyncTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return isAsyncTriggerDisabled;
    }
    
    public void changeEventCapture(List<sObject> newList) {
        EmailService objEmailService = EmailService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        CaseService objCaseService = CaseService.getInstance();
        BFMServiceRequestHandler objBFMServiceRequestHandler = BFMServiceRequestHandler.getInstance();
        
        Id caseSocialMediaRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, CASE_RT_DEV_NAME_SOCIAL_MEDIA);
        Id caseContactCenterDigitalRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, CASE_RT_DEV_NAME_CONTACT_CENTER_DIGITAL);
        Id caseBFMServiceRequestRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, CASE_RT_DEV_NAME_BFM_SERVICE_REQUEST);
        Id postSalePaymentDeferralRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, POST_SALE_PAYMENT_DEFERRAL_RT);
        Id defaultUnitRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,DEFAULT_UNIT_RT);
        
        Id acnowledgementReceiptRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,ACKNOWLEDGEMENT_RECEIPT_RT);//Pranav
        Id pymntDuDtUpdtRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,PAYMENT_DUE_DATE_UPDATE_RT);//Pranav
        Id tpFormRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,THIRD_PARTY_FORM_RT);//Pranav
        Id chequeReplacementRequestRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,CHEQUE_REPLACEMENT_REQUEST_RT);
        Id chequeWithdrawalRequestRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,CHEQUE_WITHDRAWAL_REQUEST_RT);
        Id anprServiceRequestRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, ANPR_CASE_RT);
        Id accessPermitServiceRequestRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, ACCESS_PERMIT_RT);
        Id moveINServiceRequestRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, MOVE_IN_RT);
        Id moveINHolidayHomesServiceRequestRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, MOVE_IN_HOLIDAY_HOMES_RT);
        Id moveINOwnerServiceRequestRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, MOVE_IN_OWNER_RT);
        Id moveOUTServiceRequestRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, MOVE_OUT_RT);
        Id renewalServiceRequestRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, Renewal);
        Id resaleRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,RESALE_RT_DEV_NAME);
        Id resaleUndeConstructionRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,RESALE_PROPERTY_UNDER_CONSTRUCTION_RT);
        Id resaleForCompletedProjectRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,RESALE_PROPERTY_COMPLETED_PROJECT_RT);
        Id resalePHPPRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,RESALE_PROPERTY_WITH_PPHP_RT);
        Id LPFRequestRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,LPF_WAIVER_REQUEST_RT);
        Id SOARequestRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,SOA_REQUEST_RT);
        Id popShareRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,POP_SHARE_SR_RT);//Pranav
        Id bnkAccDtlRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,BANK_ACC_DTAIL_SR_RT);//Pranav
        Id generalEnquiryID = Utility.getRecordTypeIdByDevName(Case.SObjectType,GENERAL_ENQUIRY_RT);
        Id KYCUpdateRequestRTId = Utility.getRecordTypeIdByDevName(Case.SObjectType, KYC_UPDATE_REQUEST_RT);
        Id complaintRequestID = Utility.getRecordTypeIdByDevName(Case.SObjectType,COMPLAINT_REQUEST_RT);
          Id cancellationRequestID = Utility.getRecordTypeIdByDevName(Case.SObjectType,CANCELLATION_REQUEST_RT);
        Id generalServiceRequestRTId = Utility.getRecordTypeIdByDevName(Case.SObjectType, GENERAL_SERVICE_REQUEST_RT);
        Id financialServiceRequestRTId = Utility.getRecordTypeIdByDevName(Case.SObjectType, FINANCIAL_SERVICE_REQUEST_RT);
        Id handoverServiceRequestRTId = Utility.getRecordTypeIdByDevName(Case.SObjectType, HANDOVER_SERVICE_REQUEST_RT);
        Id specialServicesRTId = Utility.getRecordTypeIdByDevName(Case.SObjectType, SPECIAL_SERVICES_RT);
        Id salesOperationID = Utility.getRecordTypeIdByDevName(Case.SObjectType,SALES_OPERATION_RT);
        Id brokerAgentRegistrationAndUpdateRTId = Utility.getRecordTypeIdByDevName(Case.SObjectType, BROKER_AGENT_REGISTRATION_UPDATE_RT); // BAPP Agent Update
        Id caseBrokerCommissionIssueRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, CASE_RT_DEV_NAME_BROKER_COMMISSION_ISSUE ); //BAPP Broker Commision Case
        Id caseOtherServiceRequestRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, CASE_RT_DEV_NAME_OTHER_SERVICE_REQUEST ); //BAPP Broker Generic Case
        Id brokerAgencyDetailsUpdateRTId = Utility.getRecordTypeIdByDevName(Case.SObjectType, BROKER_AGENCY_DETAILS_UPDATE_RT); // BAPP
        Id tawtheeqEnrollmentRTId = Utility.getRecordTypeIdByDevName(Case.SObjectType, TAWTHEEQ_ENROLLMENT_RT);
        String digitalCaseCreatedByIds = objMetadataService.getAppSettingTextValue(DIGITAL_CASE_CREATED_BY_IDS);
     //   String complaintCaseRecordTypeIds =  objMetadataService.getAppSettingTextValue(CASE_RT_IDS);
        Id brokerBrokerAgreementRenewalRTId = Utility.getRecordTypeIdByDevName(Case.SObjectType, BROKER_AGREEMENT_RENEWAL_RT); //US-912
        
        List<Id> digitalCaseCreatedByUserIdList = digitalCaseCreatedByIds.split(',');
        
   //     List<Id> complaintCaseRecordTypeIdList = complaintCaseRecordTypeIds.split(',');
        
        List<CaseChangeEvent> objLeadChangeEventList =  (List<CaseChangeEvent>)newList;
        
        List<Id> digitalCaseIds = new List<Id>();
        List<Id> bfmEmailToCaseIds = new List<Id>();
        List<Id> complaintCaseIds = new List<Id>();
        List<Id> crmCaseIdList = new List<Id>();
        List<Id> resaleCaseIdList = new List<Id> ();
        List<Id> acknowledgementRcptIds = new List<Id>();//Pranav
        List<Id> pymntDuDtUpdtIds = new List<Id>();//Pranav
        List<Id> tpFormIds = new List<Id>();//Pranav
        List<Id> postSalePaymentDeferralIdList = new List<Id>();
        List<Id> defaultUnitIdList = new List<Id>();
        List<Id> chequeReplacementRequestIdList = new List<Id>();
        List<Id> chequeWithdrawalRequestIdList = new List<Id>();
        List<Id> anprCaseIds = new List<Id>();
        List<Id> communityAppServiceRequestCaseIds = new List<Id>();
        List<Id> LPFWaiverRequestIdList = new List<Id>();
        List<Id> SOARequestIdList = new List<Id>();
        List<Id> popShareIds = new List<Id>();//Pranav
        List<Id> bnkAccDtlIds = new List<Id>();//Pranav
        List<Id> generalEnquiryCaseIds = new List<Id>();
        List<Id> BAPPGenericCaseIds = new List<Id>(); //BAPP Broker Generic Case
        List<Id> brokerRegistrationCaseIds = new List<Id>(); // BAPP Regist Update
        List<Id> brokerAgentCaseIds = new List<Id>(); // BAPP Agent Update
        List<Id> brokerAgencyUpdateCaseIds = new List<Id>(); //BAPP Agency
        List<Id> brokerCommissionIssueCaseIds = new List<Id>(); //BAPP Agency
        List<Id> brokerGeneralServiceRequestCaseIds = new List<Id>(); //BAPP Other
        List<Id> kycUpdateRequestIds = new List<Id>();
        List<Id> superAppKYCUpdateRequestIds = new List<Id>();
        List<Id> generalServiceRequestIds = new List<Id>();
        List<Id> financialServiceRequestIds = new List<Id>();
        List<Id> handoverServiceRequestIds = new List<Id>();
        List<Id> specialServicesIds = new List<Id>();
        List<Id> bfmCaseSentEmailIdList = new List<Id>();
        List<Id> salesOperationCaseIds = new List<Id>();
        List<Id> caseCancelledIds = new List<Id>();
        List<Id> resaleCaseCancelledIds = new List<Id>();
        List<Id> approvedCaseIds = new List<Id>();
        List<Id> bfmCommonAreaBLCCaseIds = new List<Id>();
        List<Id> bfmCommonAreaDLPCaseIds = new List<Id>();
        List<Id> complaintRequestCaseIds = new List<Id>();
         List<Id> cancellationRequestCaseIds = new List<Id>();
        List<Id> tawtheeqEnrollmentCaseIds = new List<Id>();
        List<Id> submittedCaseIds = new List<Id>();
        Set<Id> draftSubmittedCaseIds = new Set<Id>();
         List<Id> caseClosedIds = new List<Id>();
        List<Id> brokerAgreementRenewalCaseIds = new List<Id>();//US-912

        Set<Id> communityCaseRTIds = new Set<Id>{accessPermitServiceRequestRecordTypeId, moveINServiceRequestRecordTypeId, moveINHolidayHomesServiceRequestRecordTypeId,
                                                moveINOwnerServiceRequestRecordTypeId, moveOUTServiceRequestRecordTypeId, renewalServiceRequestRecordTypeId};
        
        for (CaseChangeEvent event : objLeadChangeEventList) {
            //Get event header fields
            EventBus.ChangeEventHeader header = event.ChangeEventHeader;
            switch on header.changeType {
                when 'CREATE'{
                    if(digitalCaseCreatedByUserIdList.contains(event.CreatedById) && (event.RecordTypeId == caseSocialMediaRecordTypeId || event.RecordTypeId == caseContactCenterDigitalRecordTypeId)){
                        digitalCaseIds.addAll(header.getRecordIds());
                    }
                    else if(digitalCaseCreatedByUserIdList.contains(event.CreatedById) && event.RecordTypeId == caseBFMServiceRequestRecordTypeId){
                        bfmEmailToCaseIds.addAll(header.getRecordIds());
                    }
                  /*  else if(complaintCaseRecordTypeIdList.contains(event.RecordTypeId)){
                        complaintCaseIds.addAll(header.getRecordIds());
                    }*/
                    else if(event.RecordTypeId == postSalePaymentDeferralRecordTypeId){
                        postSalePaymentDeferralIdList.addAll(header.getRecordIds());  
                        crmCaseIdList.addAll(header.getRecordIds());
                    }
                    else if(event.RecordTypeId == resaleRecordTypeId){
                        resaleCaseIdList.addAll(header.getRecordIds()); 
                    }
                    else if(event.RecordTypeId == defaultUnitRecordTypeId) {
                        defaultUnitIdList.addAll(header.getRecordIds());  
                        crmCaseIdList.addAll(header.getRecordIds());
                    }
                    //Pranav
                    else if(event.RecordTypeId == acnowledgementReceiptRTID) {
                        acknowledgementRcptIds.addAll(header.getRecordIds());  
                        crmCaseIdList.addAll(header.getRecordIds());
                    }
                    //Pranav
                    else if(event.RecordTypeId == pymntDuDtUpdtRTID) {
                        pymntDuDtUpdtIds.addAll(header.getRecordIds());  
                        crmCaseIdList.addAll(header.getRecordIds());
                    }
                    //Pranav
                    else if(event.RecordTypeId == tpFormRTID) {
                        tpFormIds.addAll(header.getRecordIds());  
                        crmCaseIdList.addAll(header.getRecordIds());
                    }
                    //Pranav
                    else if(event.RecordTypeId == popShareRTID) {
                        popShareIds.addAll(header.getRecordIds());  
                        crmCaseIdList.addAll(header.getRecordIds());
                    }
                    //Pranav
                    else if(event.RecordTypeId == bnkAccDtlRTID) {
                        bnkAccDtlIds.addAll(header.getRecordIds());  
                        crmCaseIdList.addAll(header.getRecordIds());
                    }
                    else if(event.RecordTypeId == chequeReplacementRequestRecordTypeId) {
                        chequeReplacementRequestIdList.addAll(header.getRecordIds());  
                        crmCaseIdList.addAll(header.getRecordIds());
                    }
                    else if(event.RecordTypeId == chequeWithdrawalRequestRecordTypeId) {
                        chequeWithdrawalRequestIdList.addAll(header.getRecordIds());  
                        crmCaseIdList.addAll(header.getRecordIds());
                    }
                    else if(event.RecordTypeId == anprServiceRequestRecordTypeId){
                        anprCaseIds.addAll(header.getRecordIds());
                    }
                    else if(event.RecordTypeId == accessPermitServiceRequestRecordTypeId || event.RecordTypeId == moveINServiceRequestRecordTypeId 
                            || event.RecordTypeId == moveINHolidayHomesServiceRequestRecordTypeId || event.RecordTypeId == moveINOwnerServiceRequestRecordTypeId
                            || event.RecordTypeId == moveOUTServiceRequestRecordTypeId || event.RecordTypeId == renewalServiceRequestRecordTypeId){
                                communityAppServiceRequestCaseIds.addAll(header.getRecordIds());
                            }
                    else if(event.RecordTypeId == LPFRequestRecordTypeId) {
                        LPFWaiverRequestIdList.addAll(header.getRecordIds());  
                        crmCaseIdList.addAll(header.getRecordIds());
                    }
                    else if(event.RecordTypeId == SOARequestRecordTypeId) {
                        SOARequestIdList.addAll(header.getRecordIds());  
                        crmCaseIdList.addAll(header.getRecordIds());
                    }
                    else if(event.RecordTypeId == generalEnquiryID) {
                        crmCaseIdList.addAll(header.getRecordIds());
                    }
                    else if(event.RecordTypeId == salesOperationID) {
                        salesOperationCaseIds.addAll(header.getRecordIds());
                        crmCaseIdList.addAll(header.getRecordIds());
                    }
                     else if(event.RecordTypeId == complaintRequestID) {                        
                        complaintRequestCaseIds.addAll(header.getRecordIds()); 
                        //crmCaseIdList.addAll(header.getRecordIds());
                    }
                    else if (event.RecordTypeId == KYCUpdateRequestRTId && event.Origin == SUPER_APP_STR) {
                        superAppKYCUpdateRequestIds.addAll(header.getRecordIds());  
                    }
                    else if (event.RecordTypeId == KYCUpdateRequestRTId && event.Origin != SUPER_APP_STR) {
                        kycUpdateRequestIds.addAll(header.getRecordIds()); 
                    }
                    else if (event.RecordTypeId == generalServiceRequestRTId) {
                        generalServiceRequestIds.addAll(header.getRecordIds());  
                        crmCaseIdList.addAll(header.getRecordIds());
                    }
                    else if (event.RecordTypeId == financialServiceRequestRTId) {
                        financialServiceRequestIds.addAll(header.getRecordIds());  
                        crmCaseIdList.addAll(header.getRecordIds());
                    }
                    else if (event.RecordTypeId == handoverServiceRequestRTId) {
                        handoverServiceRequestIds.addAll(header.getRecordIds());  
                        crmCaseIdList.addAll(header.getRecordIds());
                    }
                    else if (event.RecordTypeId == specialServicesRTId) {
                        specialServicesIds.addAll(header.getRecordIds());  
                        crmCaseIdList.addAll(header.getRecordIds());
                    }
                    //BAPP Broker Generic Case
                    else if (event.RecordTypeId == caseBrokerCommissionIssueRecordTypeId && (event.SubType__c == 'Delayed Commission Payment' || event.SubType__c == 'Incorrect Commission Amount')) {
                        brokerCommissionIssueCaseIds.addAll(header.getRecordIds());
                        //crmCaseIdList.addAll(header.getRecordIds());
                        BAPPGenericCaseIds.addAll(header.getRecordIds());
                    }
                    else if (event.RecordTypeId == caseOtherServiceRequestRecordTypeId) {
                        brokerGeneralServiceRequestCaseIds.addAll(header.getRecordIds());
                        //crmCaseIdList.addAll(header.getRecordIds());
                        BAPPGenericCaseIds.addAll(header.getRecordIds());
                    }
                    else if (event.Draft__c == false && event.RecordTypeId == brokerAgentRegistrationAndUpdateRTId) {
                        if (event.SubType__c == 'Broker Agent Details Update') {
                            brokerAgentCaseIds.addAll(header.getRecordIds());
                        } else if (event.SubType__c == 'Broker New Agent Registration') {
                            brokerRegistrationCaseIds.addAll(header.getRecordIds());
                        }
                    }
                    else if (event.Draft__c == false && event.RecordTypeId == brokerAgencyDetailsUpdateRTId) {
                        brokerAgencyUpdateCaseIds.addAll(header.getRecordIds());
                    }
                    else if (event.RecordTypeId == tawtheeqEnrollmentRTId) {
                        tawtheeqEnrollmentCaseIds.addAll(header.getRecordIds());
                        crmCaseIdList.addAll(header.getRecordIds());
                    }
                    else if (event.RecordTypeId == brokerBrokerAgreementRenewalRTId) {//US-912
                        brokerAgreementRenewalCaseIds.addAll(header.getRecordIds());
                        System.debug('brokerAgreementRenewalCaseIds =======>'+brokerAgreementRenewalCaseIds);
                    }
                }
                when 'UPDATE'{
                    if (header.changedFields.contains('Draft__c') && event.Draft__c == false)
                    {
                        for(String recordId : header.getRecordIds()){
                            draftSubmittedCaseIds.add((Id) recordId);
                        }
                    }
                    Boolean isBFMCaseCreation = header.changedFields.contains('BFMServiceRequestId__c') && event.BFMServiceRequestId__c != null;
                    Boolean isBFMCaseClosure = header.changedFields.contains('BFMRequestStatus__c') && event.BFMRequestStatus__c != null && (event.BFMRequestStatus__c == COMPLETED_STR || event.BFMRequestStatus__c == CLOSED_STR);
                    Boolean isCaseCancelled = header.changedFields.contains('Status') && event.Status == 'Cancelled';
                    Boolean isCaseClosed = header.changedFields.contains('Status') && event.Status == 'Closed';
                    System.debug('isCaseCancelled'+isCaseCancelled);
                    
                    Boolean isApprovalApproved = header.changedFields.contains('ApprovalStatus__c') && (event.ApprovalStatus__c == 'Approved' || event.ApprovalStatus__c == 'Rejected');
                    
                    if(isBFMCaseCreation || isBFMCaseClosure){
                        bfmCaseSentEmailIdList.addAll(header.getRecordIds());
                    }
                    if(isCaseCancelled){
                        caseCancelledIds.addAll(header.getRecordIds());
                        if(event.RecordTypeId == resaleRecordTypeId
                           ||event.RecordTypeId ==resaleUndeConstructionRecordTypeId
                           ||event.RecordTypeId ==resaleForCompletedProjectRecordTypeId
                           ||event.RecordTypeId ==resalePHPPRecordTypeId){
                            resaleCaseCancelledIds.addAll(header.getRecordIds());
                        }
                    }
                    if(isApprovalApproved){
                        approvedCaseIds.addAll(header.getRecordIds());
                    }
                      if(isCaseClosed){
                          caseClosedIds.addAll(header.getRecordIds());}
                    //common area
                    if (header.changedFields.contains('AssignTeam__c')) {
                        if(event.AssignTeam__c == 'BFM Team'){
                            BFMServiceRequestHandler.getInstance().handleSendToBFM(header.getRecordIds()[0]);
                        }
                        else if(event.AssignTeam__c == 'BLC Team'){
                            bfmCommonAreaBLCCaseIds.addAll(header.getRecordIds());
                        }
                        else if(event.AssignTeam__c == 'DLP Team'){
                            bfmCommonAreaDLPCaseIds.addAll(header.getRecordIds());
                        }
                    }
                    //Community Case Assignemnt only when status is submitted
                    if(header.changedFields.contains('Status') && event.Status == 'Submitted'){
                        submittedCaseIds.addAll(header.getRecordIds());
                    }
                    
                }
                when 'DELETE'{
                    
                }
                when 'UNDELETE'{
                    
                }
            }
        }
        
        if (!draftSubmittedCaseIds.isEmpty()) {
            Map<Id, Case> caseMap = CaseService.getInstance().getCaseMapByIds(draftSubmittedCaseIds);
            for (Case c : caseMap.values()) {
                System.debug('BROKER_AGENT_REGISTRATION_UPDATE_RT =======>' + c.RecordType.DeveloperName + 'CSubject >>' + c.Subject);
                if (c.RecordType.DeveloperName == BROKER_AGENT_REGISTRATION_UPDATE_RT && c.SubType__c == 'Broker Agent Details Update') {
                    brokerAgentCaseIds.add(c.Id);
                }
                else if (c.RecordType.DeveloperName == BROKER_AGENCY_DETAILS_UPDATE_RT && BROKER_AGENCY_DETAILS_UPDATE_SUBTYPES.contains(c.SubType__c)) {
                    brokerAgencyUpdateCaseIds.add(c.Id);
                }
                else if (c.RecordType.DeveloperName == BROKER_AGENT_REGISTRATION_UPDATE_RT && c.SubType__c == 'Broker New Agent Registration') {
                    System.debug('BROKER_AGENT_REGISTRATION_UPDATE_RT Inside else if =======>');
                    brokerRegistrationCaseIds.add(c.Id);
                }
            }
        }

        if(!submittedCaseIds.isEmpty()){
            Map<Id, Case> caseMap = CaseService.getInstance().getCaseMapByIds(new Set<Id>(submittedCaseIds));
            for (Case c : caseMap.values()) {
                if (communityCaseRTIds.contains(c.RecordTypeId)) {
                    communityAppServiceRequestCaseIds.add(c.Id);
                }
            }
        }
        
        if(!approvedCaseIds.isEmpty()){
            CaseAsyncTriggerHelper.processApprovedCustomerTypeUpdateCases(new Set<Id>(approvedCaseIds));
        }
        if(!caseCancelledIds.isEmpty()){
            ServiceRequestTaskHandler.getInstance().closeAllOpenTasksOnCancel(new Set<Id>(caseCancelledIds));
        }
   
        if(!resaleCaseCancelledIds.isEmpty()){
            ResaleServiceRequestHandler.getInstance().cancelDraftSalesOrders(new Set<Id>(resaleCaseCancelledIds));    
        }
        if(!bfmCaseSentEmailIdList.isEmpty()){
            objBFMServiceRequestHandler.sendBFMCaseCreationORClosureEmail(bfmCaseSentEmailIdList);
            objBFMServiceRequestHandler.sendBFMCaseCreationORClosureNotification(bfmCaseSentEmailIdList);
        }
        if(!digitalCaseIds.isEmpty()){
            AssignmentRuleHandler.salesDigitalCaseAssignment(digitalCaseIds);
        }  
        
        if(!bfmEmailToCaseIds.isEmpty()){
            AssignmentRuleHandler.bfmEmailToCaseCaseAssignment(bfmEmailToCaseIds);
        }

        if(!bfmCommonAreaBLCCaseIds.isEmpty()){
            AssignmentRuleHandler.bfmCommonAreaBLCCaseAssignment(bfmCommonAreaBLCCaseIds);
        }
        if(!bfmCommonAreaDLPCaseIds.isEmpty()){
            AssignmentRuleHandler.bfmCommonAreaDLPCaseAssignment(bfmCommonAreaDLPCaseIds);
        }

        if(!anprCaseIds.isEmpty()){
            AssignmentRuleHandler.anprCaseAssignment(anprCaseIds);
        }    
        
        if(!communityAppServiceRequestCaseIds.isEmpty()){
            AssignmentRuleHandler.communityAppServiceRequestAssignment(communityAppServiceRequestCaseIds);
        }
        
        if(!complaintCaseIds.isEmpty()){
            AssignmentRuleHandler.salesComplaintCaseAssignment(complaintCaseIds);
        }
         if(!complaintRequestCaseIds.isEmpty()){
            AssignmentRuleHandler.crmComplaintCaseAssignment(complaintRequestCaseIds);
        }      
        //BAPP Broker Generic Case
        if (!BAPPGenericCaseIds.isEmpty()) {
            AssignmentRuleHandler.genericCaseAssignmentBAPP(BAPPGenericCaseIds);
        }
        if (!brokerAgentCaseIds.isEmpty()) {
            AssignmentRuleHandler.genericCaseAssignmentBAPP(brokerAgentCaseIds);
        }
        if (!brokerAgencyUpdateCaseIds.isEmpty()) {
            AssignmentRuleHandler.genericCaseAssignmentBAPP(brokerAgencyUpdateCaseIds);
        }
        if (!brokerRegistrationCaseIds.isEmpty()) {
            AssignmentRuleHandler.genericCaseAssignmentBAPP(brokerRegistrationCaseIds);
        }
        
        CaseService servObj = CaseService.getInstance();
        
        //CRM common assignment rule
        if(!crmCaseIdList.isEmpty()){
            AssignmentRuleHandler.crmCaseAssignment(crmCaseIdList); 
        }
        
        if(!postSalePaymentDeferralIdList.isEmpty()){
            List<Case> postSalePaymentDeferralCaseList = servObj.getCaseByIds(new Set<Id>(postSalePaymentDeferralIdList));
            PostSalePaymentDeferalCaseHandler.getInstance().createFirstTask(postSalePaymentDeferralCaseList); 
        }
        if(!resaleCaseIdList.isEmpty()){
            AssignmentRuleHandler.crmResaleCaseAssignment(resaleCaseIdList);
            List<Case> resaleCaseList = servObj.getCaseByIds(new Set<Id>(resaleCaseIdList));
            ServiceRequestTaskHandler.getInstance().createNewAndCloseCurrentTask(resaleCaseList);  
        }
        if(!defaultUnitIdList.isEmpty()){
            List<Case> defaultCaseList = servObj.getCaseByIds(new Set<Id>(defaultUnitIdList));
            DefaultUnitCaseHandler.getInstance().createFirstTask(defaultCaseList); 
        }
        //Pranav
        if(!acknowledgementRcptIds.isEmpty()){
            List<Case> acknowledgementReceiptList = servObj.getCaseByIds(new Set<Id>(acknowledgementRcptIds));
            AcknowledgmentReceiptSRHandler.getInstance().createFirstTask(acknowledgementReceiptList); 
        }
        //Pranav
        if(!pymntDuDtUpdtIds.isEmpty()){
            List<Case> pymntDuDtUpdtList = servObj.getCaseByIds(new Set<Id>(pymntDuDtUpdtIds));
            PaymentDueDateUpdateSRHandler.getInstance().createFirstTask(pymntDuDtUpdtList); 
        }
        //Pranav
        if(!tpFormIds.isEmpty()){
            List<Case> tpFormList = servObj.getCaseByIds(new Set<Id>(tpFormIds));
            ThirdPartyFormSRHandler.getInstance().createFirstTask(tpFormList); 
        }
        //Pranav
        if(!popShareIds.isEmpty()){
            List<Case> pmntSrList = servObj.getCaseByIds(new Set<Id>(popShareIds));
            if(pmntSrList[0].step__c != '4')
                ProofofPaymentSharedSRHandler.getInstance().createFirstTask(pmntSrList); 
        }
        //Pranav
        if(!bnkAccDtlIds.isEmpty()){
            List<Case> pmntSrList = servObj.getCaseByIds(new Set<Id>(bnkAccDtlIds));
            if(pmntSrList[0].step__c != '4')
                BankAccDetailInquirySRHandler.getInstance().createFirstTask(pmntSrList); 
        }
        
        if(!chequeReplacementRequestIdList.isEmpty()){
            List<Case> chequeReplacementRequestList = servObj.getCaseByIds(new Set<Id>(chequeReplacementRequestIdList));
            ChequeReplacementRequestCaseHandler.getInstance().createFirstTask(chequeReplacementRequestList); 
        }
        
        if(!chequeWithdrawalRequestIdList.isEmpty()){
            List<Case> chequeWithdrawalRequestList = servObj.getCaseByIds(new Set<Id>(chequeWithdrawalRequestIdList));
            ChequeWithdrawalRequestCaseHandler.getInstance().createFirstTask(chequeWithdrawalRequestList); 
        }
        
        if(!salesOperationCaseIds.isEmpty()){
            List<Case> salesOperationCaseList = servObj.getCaseByIds(new Set<Id>(salesOperationCaseIds));
            SalesOperationSRHandler.getInstance().createFirstTask(salesOperationCaseList); 
        }
       /* if(!complaintRequestCaseIds.isEmpty()){
            List<Case> complaintRequestCaseList = servObj.getCaseByIds(new Set<Id>(complaintRequestCaseIds));
            ComplaintRequestHandler.getInstance().createFirstTask(complaintRequestCaseList); 
        }*/
        
        if(!LPFWaiverRequestIdList.isEmpty()){
            List<Case> lpfWaiverRequestList = servObj.getCaseByIds(new Set<Id>(LPFWaiverRequestIdList));
            LPFWaiverRequestCaseHandler.getInstance().createFirstTask(lpfWaiverRequestList); 
        }
        
        if(!SOARequestIdList.isEmpty()){
            List<Case> soaRequestList = servObj.getCaseByIds(new Set<Id>(SOARequestIdList));
            SOARequestCaseHandler.getInstance().handleNextSteps(soaRequestList[0]); 
        }
        
        if(!kycUpdateRequestIds.isEmpty()){
            AssignmentRuleHandler.crmCaseAssignment(kycUpdateRequestIds); 
            List<Case> kycUpdateRequestCaseList = servObj.getCaseByIds(new Set<Id>(kycUpdateRequestIds));
            KYCUpdateRequestSRHandler.getInstance().createFirstTask(kycUpdateRequestCaseList);
        }
        
        if(!brokerCommissionIssueCaseIds.isEmpty()){
            List<Case> brokerDelayedCommissionList = servObj.getCaseByIds(new Set<Id>(brokerCommissionIssueCaseIds));
            BrokerCommissionSRHandler.getInstance().handleNextSteps(brokerDelayedCommissionList[0]);
        }
        
        if(!brokerGeneralServiceRequestCaseIds.isEmpty()){
            List<Case> brokerGeneralServiceRequestList = servObj.getCaseByIds(new Set<Id>(brokerGeneralServiceRequestCaseIds));
            OtherSRHandler.getInstance().handleNextSteps(brokerGeneralServiceRequestList[0]); 
        }
        if(!brokerRegistrationCaseIds.isEmpty()){
            List<Case> brokerRegistrationList = servObj.getCaseByIds(new Set<Id>(brokerRegistrationCaseIds));
            BrokerAgentRegiAndUpdateSRHandler.getInstance().handleNextSteps(brokerRegistrationList[0]);
        }
        if(!brokerAgentCaseIds.isEmpty()){
            List<Case> brokerAgentCaseList = servObj.getCaseByIds(new Set<Id>(brokerAgentCaseIds));
            BrokerAgentRegiAndUpdateSRHandler.getInstance().createFirstTask(brokerAgentCaseList);
        }
        if(!brokerAgencyUpdateCaseIds.isEmpty()){
            List<Case> brokerAgencyUpdateList = servObj.getCaseByIds(new Set<Id>(brokerAgencyUpdateCaseIds));
            BrokerAgencyDetailsUpdateSRHandler.getInstance().createFirstTask(brokerAgencyUpdateList);
        }
        if(!superAppKYCUpdateRequestIds.isEmpty()){
            AssignmentRuleHandler.superAppCaseAssignment(superAppKYCUpdateRequestIds); 
            List<Case> kycUpdateRequestCaseList = servObj.getCaseByIds(new Set<Id>(superAppKYCUpdateRequestIds));
            KYCUpdateRequestSRHandler.getInstance().createFirstTask(kycUpdateRequestCaseList); 
        }
        if(!tawtheeqEnrollmentCaseIds.isEmpty()){
            List<Case> tawtheeqEnrollmentCaseList = servObj.getCaseByIds(new Set<Id>(tawtheeqEnrollmentCaseIds));
            TawtheeqEnrollmentSRHandler obj = TawtheeqEnrollmentSRHandler.getInstance();
            obj.createFirstTask(tawtheeqEnrollmentCaseList); 
        }
        if(!brokerAgreementRenewalCaseIds.isEmpty()){
            List<Case> brokerAgreementRenewalList = servObj.getCaseByIds(new Set<Id>(brokerAgreementRenewalCaseIds));
            BrokerAgreementRenewalSRHandler obj = BrokerAgreementRenewalSRHandler.getInstance();
            obj.createFirstTask(brokerAgreementRenewalList); 
            }
        }
}