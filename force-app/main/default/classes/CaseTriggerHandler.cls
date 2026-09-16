/***
Class       : CaseTriggerHandler 
Author      : Smaartt
Description : 
TestClass   : CaseTriggerHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date          Author       Details
1.          V1.0              27/04/23                  Initial Version 
2.          V1.1              26/08/24     Jayprakash   Updated to triger framework
****************************************************************************************************************/
public class CaseTriggerHandler implements ITriggerHandler{ 
    
    private static final string CASE_RT_DEV_NAME_SOCIAL_MEDIA { get { return 'Social_Media'; } }
    private static final string POST_SALE_PAYMENT_DEFERRAL_RT { get { return 'Post_Sale_Payment_Deferral'; } }
    private static final string RESALE_PROPERTY_UNDER_CONSTRUCTION_RT { get { return 'Resale_Property_Under_Construction'; } }
    
    private static final string BFM_SERVICE_REQUEST_RT { get { return 'BFMServiceRequest'; } }
    private static final string CONTACT_CENTER_DIGITAL_CASE_RT { get { return 'ContactCenterDigitalCase'; } }
    private static final string DEFAULT_UNIT_RT { get { return 'DefaultUnit'; } }
    private static final string RESALE_PROPERTY_WITH_PPHP_RT { get { return 'Resale_Property_with_Post_Handover_Payment_Plan'; } }
    private static final string RESALE_PROPERTY_COMPLETED_PROJECT_RT { get { return 'Resale_Property_For_Completed_Project'; } }
    /*private static final string ACKNOWLEDGEMENT_RECEIPT_RT { get { return 'Acknowledgment_Receipt'; } }//Pranav
    private static final string PAYMENT_DUE_DATE_UPDATE_RT { get { return 'Payment_Due_Date_Update'; } }//Pranav
    private static final string CHEQUE_REPLACEMENT_REQUEST_RT { get { return 'ChequeReplacementRequest'; } }
    private static final string CHEQUE_WITHDRAWAL_REQUEST_RT { get { return 'ChequeWithdrawalRequest'; } }*/
    private static final string VEHICLE_PARKING_REQUEST_RT { get { return 'VehicleParkingRequest'; } }
    private static final string RESALE_MASTER_RT { get {return 'Resale_Master' ; } }
    private static final string CASE_RT_DEV_NAME_BROKER_REGISTRATION { get { return 'Broker_Registration'; } }
     
    private static final string ACCESS_PERMIT_RT { get { return 'Access_Permit'; } }
    private static final string MOVE_IN_RT { get { return 'Move_In'; } }
    private static final string MOVE_IN_HOLIDAY_HOMES_RT { get { return 'Move_In_Holiday_Homes'; } }
    private static final string MOVE_IN_OWNER_RT { get { return 'Move_In_Owner'; } }
    private static final string MOVE_OUT_RT { get { return 'Move_Out'; } }
    private static final string RENEWAL { get { return 'Renewal'; } }
    /*private static final string LPF_WAIVER_REQUEST_RT { get { return 'LPFWaiverRequest'; } }
    private static final string SOA_REQUEST_RT { get { return 'SOARequest'; } }
    private static final string PAYMENT_SR_RT { get { return 'Payment_SR'; } }//Pranav
    private static final string POP_SHARE_SR_RT { get { return 'ProofofPaymentShared'; } }// Pranav
    private static final string BANK_ACC_DTAIL_SR_RT { get { return 'BankAccountDetailsInquiry'; } }//Pranav */
    
    
    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){ 
        return isTriggerDisabled;
    }
    
    public void beforeInsert(List<sObject> newList) {
        CaseTriggerHelper.handleBeforeInsert((List<Case>)newList);
        
        /*MetadataService objMetadataService = MetadataService.getInstance();
        Id caseSocialMediaRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, CASE_RT_DEV_NAME_SOCIAL_MEDIA);
        Id accessPermitRecordTypeId = Utilities.getRecordTypeId('Case', BCAPP_Constants.ACCESS_PERMIT);
        Id postSalePaymentDeferralRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,POST_SALE_PAYMENT_DEFERRAL_RT);
        Id resaleUnderConstructionRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,RESALE_PROPERTY_UNDER_CONSTRUCTION_RT);
        Id bfmServiceRequestRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,BFM_SERVICE_REQUEST_RT);
        Id contactCenterDigitalCaseRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,CONTACT_CENTER_DIGITAL_CASE_RT);
        Id defaultUnitRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,DEFAULT_UNIT_RT);
        Id resaleForCompletedProjectRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,RESALE_PROPERTY_COMPLETED_PROJECT_RT);
        Id resaleWithPHPPRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,RESALE_PROPERTY_WITH_PPHP_RT);
        Id brokerRegistrationRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, 'Broker_Registration');

        
        Id acknowledgementRcptRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,ACKNOWLEDGEMENT_RECEIPT_RT);//Pranav
        Id pmntDuDtUpdtRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,PAYMENT_DUE_DATE_UPDATE_RT);//Pranav
        Id chequeReplacementRequestRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,CHEQUE_REPLACEMENT_REQUEST_RT);
        Id chequeWithdrawalRequestRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,CHEQUE_WITHDRAWAL_REQUEST_RT);
        Id caseANPRRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,VEHICLE_PARKING_REQUEST_RT);
        Id accessPermitServiceRequestRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, ACCESS_PERMIT_RT);
        Id moveINServiceRequestRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, MOVE_IN_RT);
        Id moveINHolidayHomesServiceRequestRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, MOVE_IN_HOLIDAY_HOMES_RT);
        Id moveINOwnerServiceRequestRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, MOVE_IN_OWNER_RT);
        Id moveOUTServiceRequestRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, MOVE_OUT_RT);
        Id renewalServiceRequestRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, RENEWAL);
        Id resaleMasterRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, RESALE_MASTER_RT);
        Id LPFRequestRTId = Utility.getRecordTypeIdByDevName(Case.SObjectType,LPF_WAIVER_REQUEST_RT);
        Id SOARequestRTId = Utility.getRecordTypeIdByDevName(Case.SObjectType,SOA_REQUEST_RT);
        Id pymntSrRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,PAYMENT_SR_RT);
        Id popShareSRRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,POP_SHARE_SR_RT);//Pranav
        Id bnkAccDtlSRRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,BANK_ACC_DTAIL_SR_RT);//Pranav
        Id incorrectCommissionRecordTypeId  = Utility.getRecordTypeIdByDevName(Case.SObjectType, 'IncorrectCommissionAmount');
        Id delayedCommissionRecordTypeId    = Utility.getRecordTypeIdByDevName(Case.SObjectType, 'DelayedCommissionPayment');
        Id BrokerAgentDetailsUpdateTypeId  = Utility.getRecordTypeIdByDevName(Case.SObjectType, 'BrokerAgentDetailsUpdate');
        Id BrokerAgencyDetailsUpdateTypeId  = Utility.getRecordTypeIdByDevName(Case.SObjectType, 'Broker_Agency_Details_Update');
        Id otherServiceRequestRecordTypeId  = Utility.getRecordTypeIdByDevName(Case.SObjectType, 'OtherServiceRequest');
        
        List<Case> objCaseList = new  List<Case>();
        for(Case objCase :(List<Case>)newList){
            if(objCase.RecordTypeId != caseSocialMediaRecordTypeId  && objCase.RecordTypeId != postSalePaymentDeferralRecordTypeId && objCase.RecordTypeId != bfmServiceRequestRecordTypeId && objCase.RecordTypeId != contactCenterDigitalCaseRecordTypeId && objCase.RecordTypeId != resaleUnderConstructionRecordTypeId && objCase.RecordTypeId != resaleForCompletedProjectRecordTypeId
               && objCase.RecordTypeId != resaleWithPHPPRecordTypeId
               && objCase.RecordTypeId != acknowledgementRcptRTID//Pranav
               && objCase.RecordTypeId != pmntDuDtUpdtRTID//Pranav
               && objCase.RecordTypeId != popShareSRRTID//Pranav
               && objCase.RecordTypeId != bnkAccDtlSRRTID//Pranav
               && objCase.recordTypeId != chequeReplacementRequestRTID
               && objCase.recordTypeId != chequeWithdrawalRequestRTID
               && objCase.recordTypeId != caseANPRRecordTypeId
               && objCase.recordTypeId != accessPermitServiceRequestRecordTypeId
               && objCase.recordTypeId != moveINServiceRequestRecordTypeId
               && objCase.recordTypeId != moveINHolidayHomesServiceRequestRecordTypeId
               && objCase.recordTypeId != moveINOwnerServiceRequestRecordTypeId
               && objCase.recordTypeId != moveOUTServiceRequestRecordTypeId
               && objCase.recordTypeId != renewalServiceRequestRecordTypeId
               && objCase.RecordTypeId != pymntSrRTID
               && objCase.recordTypeId != LPFRequestRTId
               && objCase.recordTypeId != SOARequestRTId
               && objCase.recordTypeId !=resaleMasterRecordTypeId
               && objCase.RecordTypeId != incorrectCommissionRecordTypeId 
               && objCase.RecordTypeId != delayedCommissionRecordTypeId 
               && objCase.RecordTypeId != BrokerAgentDetailsUpdateTypeId 
               && objCase.RecordTypeId != BrokerAgencyDetailsUpdateTypeId
               && objCase.RecordTypeId != otherServiceRequestRecordTypeId
               && objCase.RecordTypeId != brokerRegistrationRecordTypeId) {
                objCaseList.add(objCase);
            }
        }
        if(!objCaseList.isEmpty()){
            CaseRoundRobin.ownerRRRAssignment((List<Case>) newList);
        }*/
    }
    
    
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        CaseDocumentCreation.DocumentCreation((Map<Id,Case>)newMap);
        
        CaseTriggerHelper.createDocuments((List<Case>) newList);

        
        CaseTriggerHelper.handleAfterInsert(newList);
        //allow 
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Access Permit').getRecordTypeId();
        List<Case> accessPermitCases = new List<Case>();
        for(case rec:(List<Case>)newList){
           if(rec.Status=='Approved'  && rec.recordTypeId==recordTypeId){
                 accessPermitCases.add(rec);
           }
        }
        if(!accessPermitCases.isEmpty()){
            System.enqueueJob(new accessPermitEmailHelperQueuable(newList));
        }
        CaseTriggerHelper.handleSubmittedCases(newList);
        CaseTriggerHelper.handleSendEmailActions(newList,null);
        
    }
    
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
        //CaseTriggerHelper.caseandJointOwnerSharePercentage((List<Case>)newList);
        CaseTriggerHelper.handleAssignment((List<Case>)newList,(Map<Id,Case>)oldMap);
        CaseTriggerHelper.handleBeforeUpdate((List<Case>)newList,(Map<Id,Case>)oldMap);
        
        
        //CaseTriggerHelper.updateDeferralSR((List<Case>)newList,(Map<Id,Case>)oldMap);
    }
    
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {

        CaseTriggerHelper.handleAfterUpdate((List<Case>)newList,(Map<Id,Case>)oldMap);

        MetadataService objMetadataService = MetadataService.getInstance();
        Id caseSocialMediaRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, CASE_RT_DEV_NAME_SOCIAL_MEDIA);
        Id caseBrokerRegistrationRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, CASE_RT_DEV_NAME_BROKER_REGISTRATION);
        Id defaultUnitRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,DEFAULT_UNIT_RT);
        Id accessPermitRecordTypeId = Utilities.getRecordTypeId('Case', BCAPP_Constants.ACCESS_PERMIT);
        Id postSalePaymentDeferralRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,POST_SALE_PAYMENT_DEFERRAL_RT);
        Id bfmServiceRequestRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,BFM_SERVICE_REQUEST_RT);
        Id contactCenterDigitalCaseRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,CONTACT_CENTER_DIGITAL_CASE_RT);
        Id resaleForCompletedProjectRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,RESALE_PROPERTY_COMPLETED_PROJECT_RT);
        Id resaleWithPHPPRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,RESALE_PROPERTY_WITH_PPHP_RT);
        Id resaleUnderConstructionRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,RESALE_PROPERTY_UNDER_CONSTRUCTION_RT);
        Id caseANPRRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,VEHICLE_PARKING_REQUEST_RT);
        Id accessPermitServiceRequestRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, ACCESS_PERMIT_RT);
        Id moveINServiceRequestRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, MOVE_IN_RT);
        Id moveINHolidayHomesServiceRequestRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, MOVE_IN_HOLIDAY_HOMES_RT);
        Id moveINOwnerServiceRequestRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, MOVE_IN_OWNER_RT);
        Id moveOUTServiceRequestRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, MOVE_OUT_RT);
        Id renewalServiceRequestRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, RENEWAL);
        Id resaleMasterRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, RESALE_MASTER_RT);
          
        CaseTriggerHelper.updateCaseApplicantDocuments((List<Case>) newList, (Map<Id, Case>) newMap, (List<Case>) oldList, (Map<Id, Case>) oldMap);

        List<Case> objCaseList = new  List<Case>();
        List<Case> objBrokerCaseList = new List<Case>();
        Map<Id,Case> oldCaseMap = (Map<Id, Case>) oldMap;
        for(Case objCase :(List<Case>)newList){
            if(objCase.RecordTypeId == defaultUnitRecordTypeId && objCase.Status == 'Closed' && oldCaseMap.get(objCase.Id).Status != 'Closed' 
                && objCase.CaseSubClosureReason__c == 'Forwarded to the concerned department'){
                CaseTriggerHelper.handleDefaultUnitCaseClosure((List<Case>) newList);
            }
            if(objCase.RecordTypeId != caseSocialMediaRecordTypeId && objCase.RecordTypeId !=accessPermitRecordTypeId  && objCase.RecordTypeId !=postSalePaymentDeferralRecordTypeId  && objCase.RecordTypeId !=bfmServiceRequestRecordTypeId && objCase.RecordTypeId !=contactCenterDigitalCaseRecordTypeId && objCase.RecordTypeId !=resaleForCompletedProjectRecordTypeId && objCase.RecordTypeId !=resaleWithPHPPRecordTypeId && objCase.RecordTypeId !=resaleUnderConstructionRecordTypeId && objCase.recordTypeId != caseANPRRecordTypeId && objCase.recordTypeId != accessPermitServiceRequestRecordTypeId && objCase.recordTypeId != moveINServiceRequestRecordTypeId && objCase.recordTypeId != moveINHolidayHomesServiceRequestRecordTypeId && objCase.recordTypeId != moveINOwnerServiceRequestRecordTypeId && objCase.recordTypeId != moveOUTServiceRequestRecordTypeId && objCase.recordTypeId != renewalServiceRequestRecordTypeId && objCase.recordTypeId != resaleMasterRecordTypeId){ 
                objCaseList.add(objCase);
            }
            
            // Add for Broker Contact creation
            if (objCase.RecordTypeId == caseBrokerRegistrationRecordTypeId && objCase.TypeofEstablishment__c != null) {
                    Case oldCase = (Case) oldMap.get(objCase.Id);
                    if (oldCase != null) {
                    if (objCase.ApprovalStatus__c == 'Approved' && ((objCase.FinalApprovalStage__c == 'First Approval' && oldCase.ApprovalStatus__c == 'Approved By BBM') || (objCase.FinalApprovalStage__c == 'Second Approval' && oldCase.ApprovalStatus__c == 'Approved By BL'))) {
                        objBrokerCaseList.add(objCase);
                        }   
                    }
                }
            if(!objCaseList.isEmpty()){
                //CaseRoundRobin.caseCountMethod(newList,(Map<Id,Case>)oldMap);
            }
        }

        // Create Broker Contacts
        if (!objBrokerCaseList.isEmpty()) {
            CaseTriggerHelper.createBrokerContacts(objBrokerCaseList); // US-745
        }

           // Collect Case Ids from trigger context
        Set<Id> caseIds = new Set<Id>();
        for (Case cs : (List<Case>) newList) {
            caseIds.add(cs.Id);
        }
        
        // Query once for all conditions
        List<Case> casesWithService = [
            SELECT Id, RecordTypeId, ApprovalStatus__c, AccountId, ContactId, Type, SubType__c, TradeLicenseExpiryDate__c, VATUndertakingIssue_Date__c, IsVATRegistered__c, Address1__c, Address2__c, PhoneNumber__c, TaxRegistrationNumber__c, CommercialLicenseExpiryDate__c, ServiceCatalog__c, ServiceCatalog__r.Category__c, ServiceCatalog__r.SubCategory__c, BrokerContactRole__c, NationalIDExpiryDate__c, PassportExpiryDate__c, BRN_RERA_Expiry_Date__c, AccountNumber__c, BankName__c, BankAddress__c, IBANNumber__c, SwiftCode__c, Broker_Agent__c
            FROM Case
            WHERE Id IN :caseIds
        ];
        
        // Get RecordType Ids
        Id brokerAgencyDetailsRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Broker_Agency_Details_Update').getRecordTypeId();
        Id brokerAgentDetailsRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('BrokerAgentDetailsUpdate').getRecordTypeId();
        
        // Separate lists
        List<Case> casesToApprove = new List<Case>();
        List<Case> brokerCases = new List<Case>();
        List<Case> brokerAgentCases = new List<Case>();
        
        // Single loop — handle all conditions
        for (Case cs : casesWithService) {
            if (cs.ServiceCatalog__r == null) continue;
            
         
            // Create Broker Accounts -> update Account
            if (cs.RecordTypeId == brokerAgencyDetailsRTId && cs.ServiceCatalog__r.Category__c == 'Broker Service Request' && cs.ServiceCatalog__r.SubCategory__c == 'Broker Agency Details Update' && cs.ApprovalStatus__c == 'Approved') {
                brokerCases.add(cs);
            }
            
            // Broker Agent Service Request -> update Contact
  
            if (cs.RecordTypeId == brokerAgentDetailsRTId && cs.ServiceCatalog__r.Category__c == 'Broker Service Request' && cs.ServiceCatalog__r.SubCategory__c == 'Broker Agent Details Update' && cs.ApprovalStatus__c == 'Approved') {
                brokerAgentCases.add(cs);
            }
        }
        

        if (!brokerCases.isEmpty()) {
            System.debug('Agency info Update');
            CaseTriggerHelper.updateBrokerAccounts(brokerCases);
        }
        if (!brokerAgentCases.isEmpty()) {
            CaseTriggerHelper.updateBrokerContactSR(brokerAgentCases);
        }
        //Rushikesh: Send BBM queue notifications
        CaseTriggerHelper.sendBBMQueueEmails(newList);

        //Vehicle Parking Registration logic 
        CaseTriggerHelper.handleVehicleParkingRegistrationReqAfterUpdate((List<Case>)newList, (Map<Id, Case>)oldMap); 
        CaseTriggerHelper.handleSendEmailActions(newList,oldMap);
    }
    
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {  
        
        /* MetadataService objMetadataService = MetadataService.getInstance();
        Id caseSocialMediaRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, CASE_RT_DEV_NAME_SOCIAL_MEDIA);
        
        List<Case> objCaseList = new  List<Case>();
        for(Case objCase :(List<Case>)oldList){
            if(objCase.RecordTypeId != caseSocialMediaRecordTypeId){
                objCaseList.add(objCase);
            }
        }
        if(!objCaseList.isEmpty()){
            CaseRoundRobin.caseCountMethod(null,(Map<Id,Case>)oldMap);
}*/
        
    }
    
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
        
    }
}