/***
Class       : ReviewStepValidatorController
Author      : Sonali S 
Description : 
TestClass   : ReviewStepValidatorControllerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.     version              Date                Details
1.          V1.0              26/02/25          Initial Version 
****************************************************************************************************************/

public without sharing class ReviewStepValidatorController {
    private static final string POST_SALE_PAYMENT_DEFERRAL_RT_DEV_NAME { get { return 'Post_Sale_Payment_Deferral'; } }
    private static final string RESALE_PROPERTY_UNDER_CONSTRUCTION_RT_DEV_NAME { get { return 'Resale_Property_Under_Construction'; } }
    private static final string DEFAULT_UNIT_RT_DEV_NAME { get { return 'DefaultUnit'; } }
    private static final string RESALE_RT_DEV_NAME { get { return 'Resale_Master'; } }
    private static final string RESALE_PROPERTY_COMPLETED_PROJECT_RT_DEV_NAME { get { return 'Resale_Property_For_Completed_Project'; } }
    private static final string RESALE_PROPERTY_WITH_PPHP_RT_DEV_NAME { get { return 'Resale_Property_with_Post_Handover_Payment_Plan'; }}
    private static final string ACKNOWLEDGEMENT_RECEIPT_RT { get { return 'Acknowledgment_Receipt'; } }//Pranav
    private static final string PAYMENT_DUE_DATE_UPDATE_RT { get { return 'Payment_Due_Date_Update'; } }//Pranav
    private static final string CHEQUE_REPLACEMENT_REQUEST_RT { get { return 'ChequeReplacementRequest'; } }
    private static final string CHEQUE_WITHDRAWAL_REQUEST_RT { get { return 'ChequeWithdrawalRequest'; } }
    private static final string LPF_WAIVER_REQUEST_RT { get { return 'LPFWaiverRequest'; } }
    private static final string SOA_REQUEST_RT { get { return 'SOARequest'; } }
    private static final string THIRD_PARTY_FORM_RT { get { return 'ThirdPartyForm'; } }//Pranav
    private static final string PAYMENT_SR_RT { get { return 'Payment_SR'; } }//Pranav
    private static final string POP_SHARE_SR_RT { get { return 'ProofofPaymentShared'; } }//Pranav
    private static final string BANK_ACC_DTAIL_SR_RT { get { return 'BankAccountDetailsInquiry'; } }//Pranav
    private static final string GENERAL_ENQUIRY_RT { get { return 'GeneralEnquiry'; } }
    private static final string KYC_UPDATE_REQUEST_RT { get { return 'KYCUpdateRequest'; } }
    private static final string BROKER_COMMISSION_ISSUE_RT  { get { return 'BrokerCommissionIssue'; } } //BAPP
    private static final string Other_RT  { get { return 'BrokerGeneralServiceRequest'; } } //BAPP
    private static final string BROKER_AGENT_REGISTRATION_UPDATE_RT { get { return 'BrokerAgentRegistrationAndUpdate'; } } //Bapp
    private static final string BROKER_AGENCY_DETAILS_UPDATE_RT { get { return 'BrokerAgencyDetailsUpdate'; } } //Bapp
    private static final string SALES_OPERATION_RT { get { return 'SalesOperationService'; } }
    private static final string COMPLAINT_REQUEST_RT { get { return 'ComplaintRequest'; } }
     private static final string CANCELLATION_REQUEST_RT { get { return 'CancellationRequest'; } }
    private static final string TAWTHEEQ_ENROLLMENT_RT { get { return 'TawtheeqEnrollment'; } }
    private static final String BROKER_AGREEMENT_RENEWAL_RT {get { return 'BrokerAgreementRenewal'; }}
    
    @AuraEnabled
    public static Map<String, Object> validateForNextReview(Id recordId){
        
        Map<String, Object> response = new Map<String, Object>();
        try {
            if (recordId == null) {
                response.put('status', 'error');
                response.put('message', 'Unable to move to next step: Invalid record Id provided.');
                return response;
            }
            
            if(recordId.getSobjectType() == Case.getSobjectType()){
                
                CaseService serviceObj = CaseService.getInstance();   
                Case caseRecord = serviceObj.getCaseById(recordId);
                
                response  = validateForCaseReview((caseRecord));
              
            } else {
                response.put('status', 'error');
                response.put('message', 'Unable to move to next step: Provided Id is not a Case record.');
            }
        } catch (Exception ex) {
            response.put('status', 'error');
            response.put('message', 'Unable to move to next step: ' + ex.getMessage());
            System.debug(LoggingLevel.ERROR, 'Type: ' + ex.getTypeName());
            System.debug(LoggingLevel.ERROR, 'Line: ' + ex.getLineNumber());
            System.debug(LoggingLevel.ERROR, 'Stack: ' + ex.getStackTraceString());
        }
        return response;
    }
     
    public static Map<String, Object> validateForCaseReview(Case caseRec){ 
        Map<String, Object> response = new Map<String, Object>();
      
            if (caseRec == null) {
                response.put('status', 'error');
                response.put('message', 'Unable to move to next step: Case record is null.');
                return response;
            }
        
        
            // Validate owner is not Queue
        if (caseRec.OwnerId != null && String.valueOf(caseRec.OwnerId).startsWith('00G')) {
          response.put('status', 'error');
         response.put('message', 'Assign to yourself before proceeding');
         return response;
       }
            PostSalePaymentDeferalCaseHandler obj = PostSalePaymentDeferalCaseHandler.getInstance();
            ResaleServiceRequestHandler resaleObj = ResaleServiceRequestHandler.getInstance();
            DefaultUnitCaseHandler defaultUnitCaseHandlerobj = DefaultUnitCaseHandler.getInstance();
            AcknowledgmentReceiptSRHandler ackObj = AcknowledgmentReceiptSRHandler.getInstance();//Pranav
            PaymentDueDateUpdateSRHandler pymntUpdtObj = new PaymentDueDateUpdateSRHandler();//Pranav
            ChequeReplacementRequestCaseHandler objChequeReplacementRequestCaseHandler = ChequeReplacementRequestCaseHandler.getInstance();
            ChequeWithdrawalRequestCaseHandler objChequeWithdrawalRequestCaseHandler = ChequeWithdrawalRequestCaseHandler.getInstance();
            ThirdPartyFormSRHandler tpObj = ThirdPartyFormSRHandler.getInstance();//Pranav
            PaymentSRHandler pymntObj = PaymentSRHandler.getInstance();//Pranav
            LPFWaiverRequestCaseHandler objLPFWaiverRequestCaseHandler = LPFWaiverRequestCaseHandler.getInstance();
            SOARequestCaseHandler objSOARequestCaseHandler = SOARequestCaseHandler.getInstance();
            ProofofPaymentSharedSRHandler popShareObj = ProofofPaymentSharedSRHandler.getInstance();//Pranav
            BankAccDetailInquirySRHandler bnkAccDtlObj = BankAccDetailInquirySRHandler.getInstance();//Pranav
            GeneralEnquirySRHandler objGeneralEnquirySRHandler = GeneralEnquirySRHandler.getInstance();
            BrokerAgentRegiAndUpdateSRHandler objBrokerRegistrationSRHandler = BrokerAgentRegiAndUpdateSRHandler.getInstance();
            KYCUpdateRequestSRHandler objKYCUpdateRequestSRHandler = KYCUpdateRequestSRHandler.getInstance();
       		BrokerCommissionSRHandler objDelayedCommissionPaymentSRHandler = BrokerCommissionSRHandler.getInstance();//BAPP
            BrokerCommissionSRHandler objIncorrectCommissionAmountSRHandler = BrokerCommissionSRHandler.getInstance();//BAPP
            OtherSRHandler objOtherSRHandler = OtherSRHandler.getInstance();//BAPP
        	BrokerAgentRegiAndUpdateSRHandler objBrokerAgentDetailsUpdateSRHandler = BrokerAgentRegiAndUpdateSRHandler.getInstance();
			BrokerAgencyDetailsUpdateSRHandler objBrokerAgencyDetailsUpdateSRHandler = BrokerAgencyDetailsUpdateSRHandler.getInstance();
            SalesOperationSRHandler objSalesOperationSRHandler = SalesOperationSRHandler.getInstance();
            CRMComplaintRequestHandler objComplaintRequestHandler = CRMComplaintRequestHandler.getInstance();
            TawtheeqEnrollmentSRHandler objTawtheeqEnrollmentSRHandler = TawtheeqEnrollmentSRHandler.getInstance();
        	BrokerAgreementRenewalSRHandler objBrokerAgreementRenewalSRHandler = BrokerAgreementRenewalSRHandler.getInstance();//US-912
         CancellationRequestSRHandler cancellationrequestObj = CancellationRequestSRHandler.getInstance();
            
            Id postSalePaymentDeferralRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,POST_SALE_PAYMENT_DEFERRAL_RT_DEV_NAME);
            Id resalePropertyUnderConstructionSRrecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,RESALE_PROPERTY_UNDER_CONSTRUCTION_RT_DEV_NAME);
            Id defaultUnitRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,DEFAULT_UNIT_RT_DEV_NAME);
            Id resaleForCompletedProjectRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,RESALE_PROPERTY_COMPLETED_PROJECT_RT_DEV_NAME);
            Id resaleWithPHPPRecordTypeId =  Utility.getRecordTypeIdByDevName(Case.SObjectType,RESALE_PROPERTY_WITH_PPHP_RT_DEV_NAME);
            Id acknowledgementRcptRTID =  Utility.getRecordTypeIdByDevName(Case.SObjectType,ACKNOWLEDGEMENT_RECEIPT_RT);//Pranav
            Id pymntDuDtUpdtRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,PAYMENT_DUE_DATE_UPDATE_RT);//Pranav
            Id chequeReplacementRequestRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,CHEQUE_REPLACEMENT_REQUEST_RT);
            Id chequeWithdrawalRequestRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,CHEQUE_WITHDRAWAL_REQUEST_RT);
            Id thrdPrtyFrmRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,THIRD_PARTY_FORM_RT);//Pranav
            Id pymntSrRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,PAYMENT_SR_RT);//Pranav
            Id LPFRequestRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,LPF_WAIVER_REQUEST_RT);
            Id SOARequestRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,SOA_REQUEST_RT);
            
            Id resaleRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,RESALE_RT_DEV_NAME); 
            Id popShareSrRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,POP_SHARE_SR_RT);//Pranav
            Id bnkAccDtlRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,BANK_ACC_DTAIL_SR_RT);//Pranav
            Id generalEnquiryRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,GENERAL_ENQUIRY_RT);
            Id kycUpdateRequestRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,KYC_UPDATE_REQUEST_RT);
            Id salesOperationRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,SALES_OPERATION_RT);
        	Id brokerCommissionIssueRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType, BROKER_COMMISSION_ISSUE_RT ); //BAPP
            Id otherRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType, Other_RT ); //BAPP
            Id brokerAgencyDetailsUpdateRTId = Utility.getRecordTypeIdByDevName(Case.SObjectType, BROKER_AGENCY_DETAILS_UPDATE_RT); // BAPP
        	Id brokerAgentRegistrationUpdateRTId = Utility.getRecordTypeIdByDevName(Case.SObjectType, BROKER_AGENT_REGISTRATION_UPDATE_RT); // BAPP
            Id complaintRequestRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,COMPLAINT_REQUEST_RT);
            Id tawtheeqEnrollmentRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType, TAWTHEEQ_ENROLLMENT_RT);
        	Id brokerAgreementRenewalRTId = Utility.getRecordTypeIdByDevName(Case.SObjectType, BROKER_AGREEMENT_RENEWAL_RT); //US-912
        Id cancellationRequestRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,CANCELLATION_REQUEST_RT);
        
            if(caseRec.RecordTypeId == postSalePaymentDeferralRecordTypeId){
               response = obj.validateCaseForNextReview(caseRec);  
            }
            else if(caseRec.RecordTypeId == resalePropertyUnderConstructionSRrecordTypeId){
                response = resaleObj.validateUnderConstructionForNextReview(caseRec);
            }
            else if(caseRec.RecordTypeId == defaultUnitRecordTypeId){
                response = defaultUnitCaseHandlerobj.validateCaseForNextReview(caseRec); 
            }
            else if(caseRec.RecordTypeId == resaleForCompletedProjectRecordTypeId){
             response = resaleObj.validateCompletedProjectForNextReview(caseRec); 
            }
            else if(caseRec.RecordTypeId == resaleRecordTypeId){
             response =  resaleObj.validateResaleForNextReview(caseRec);  
            }
            else if(caseRec.RecordTypeId == resaleWithPHPPRecordTypeId){
                response = resaleObj.validatePHPPForNextReview(caseRec);
            }
            //Pranav
            else if(caseRec.RecordTypeId == acknowledgementRcptRTID){
                response = ackObj.validateCaseForNextReview(caseRec);
            }
            //Pranav
            else if(caseRec.RecordTypeId == pymntDuDtUpdtRTID){
                response = pymntUpdtObj.validateCaseForNextReview(caseRec);
            }
            //Pranav
            else if(caseRec.RecordTypeId == thrdPrtyFrmRTID){
                response = tpObj.validateCaseForNextReview(caseRec);
            }
            //Pranav
            else if(caseRec.RecordTypeId == pymntSrRTID){
                response = pymntObj.validateCaseForNextReview(caseRec);
            }
            else if(caseRec.RecordTypeId == chequeReplacementRequestRecordTypeId){
                response = objChequeReplacementRequestCaseHandler.validateCaseForNextReview(caseRec);
            }
            else if(caseRec.RecordTypeId == chequeWithdrawalRequestRecordTypeId){
                response = objChequeWithdrawalRequestCaseHandler.validateCaseForNextReview(caseRec);
            }
            else if(caseRec.RecordTypeId == LPFRequestRecordTypeId){
                response = objLPFWaiverRequestCaseHandler.validateCaseForNextReview(caseRec);
            }
            else if(caseRec.RecordTypeId == SOARequestRecordTypeId){
                response = objSOARequestCaseHandler.validateCaseForNextReview(caseRec);
            }
            //Pranav
            else if(caseRec.RecordTypeId == popShareSrRTID){
                response = popShareObj.validateCaseForNextReview(caseRec);
            }
            //Pranav
            else if(caseRec.RecordTypeId == bnkAccDtlRTID){
                response = bnkAccDtlObj.validateCaseForNextReview(caseRec);
            }
            else if(caseRec.RecordTypeId == generalEnquiryRTID){
                response = objGeneralEnquirySRHandler.validateCaseForNextReview(caseRec);
            } 
            else if(caseRec.RecordTypeId == salesOperationRTID){
                response = objSalesOperationSRHandler.validateCaseForNextReview(caseRec);
            } 
            else if(caseRec.RecordTypeId == complaintRequestRTID){
                response = objComplaintRequestHandler.validateCaseForNextReview(caseRec);
            } 
          else if(caseRec.RecordTypeId == cancellationRequestRTID){
                response = cancellationrequestObj.validateCaseForNextReview(caseRec);
            }
            else if(caseRec.RecordTypeId == kycUpdateRequestRTID){
                response = objKYCUpdateRequestSRHandler.validateCaseForNextReview(caseRec);
            }
        	//BAPP
            else if(caseRec.RecordTypeId == brokerCommissionIssueRTID){
                if(caseRec.SubType__c == 'Incorrect Commission Amount'){
                    response = objIncorrectCommissionAmountSRHandler.validateCaseForNextReview(caseRec);
                } else {
                    response = objDelayedCommissionPaymentSRHandler.validateCaseForNextReview(caseRec);
                }
            }
            else if(caseRec.RecordTypeId == otherRTID){
                response = objOtherSRHandler.validateCaseForNextReview(caseRec);
            }
        	else if(caseRec.RecordTypeId == brokerAgentRegistrationUpdateRTId && caseRec.Subject == 'Broker Agent Details Update'){
                response = objBrokerAgentDetailsUpdateSRHandler.validateCaseForNextReview(caseRec);
            }
        	else if(caseRec.RecordTypeId == brokerAgencyDetailsUpdateRTId){
                response = objBrokerAgencyDetailsUpdateSRHandler.validateCaseForNextReview(caseRec);
            }
            //BAPP
            else if(caseRec.RecordTypeId == brokerAgentRegistrationUpdateRTId && caseRec.Subject == 'Broker New Agent Registration'){
                response = objBrokerRegistrationSRHandler.validateCaseForNextReview(caseRec);
            }
            else if(caseRec.RecordTypeId == tawtheeqEnrollmentRTID){
                response = objTawtheeqEnrollmentSRHandler.validateCaseForNextReview(caseRec);
            }
            else if(caseRec.RecordTypeId == brokerAgreementRenewalRTId){
                response = objBrokerAgreementRenewalSRHandler.validateCaseForNextReview(caseRec);
            }
        	else {
                // Fallback if no matching record type found
                response.put('status', 'error');
                response.put('message', 'Unable to move to next step: No validation logic found for this record type.');
            }
       
        return response; 
    }
      @AuraEnabled(cacheable=true)
    public static Map<String,String> getTeamValues() {
        return Utility.getPicklistValues(ServiceAction__c.SObjectType, 'Department__c');
    }    
  
}