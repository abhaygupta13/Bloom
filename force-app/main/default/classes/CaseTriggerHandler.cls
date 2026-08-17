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
    private static final string CASE_RT_DEV_NAME_BROKER_REGISTRATION { get { return 'BrokerAgentRegistrationAndUpdate'; } }
    private static final string Broker_Agreement_Renewal { get { return 'BrokerAgreementRenewal'; } }
     
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
        Id brokerAgreementRenewalRTId = Utility.getRecordTypeIdByDevName(Case.SObjectType, Broker_Agreement_Renewal);
        Id brokerAgreementRenewalTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Broker Agreement Renewal').getRecordTypeId();
        List<Case> accessPermitCases = new List<Case>();
        List<Case> brokerAgreementRenewalCases = new List<Case>();
        for(case rec:(List<Case>)newList){
           if(rec.Status=='Approved'  && rec.recordTypeId==recordTypeId){
                 accessPermitCases.add(rec);
           }
            if (rec.RecordTypeId == brokerAgreementRenewalRTId) {
                brokerAgreementRenewalCases.add(rec);
            }
           
        }
        if (!brokerAgreementRenewalCases.isEmpty()) {
            BrokerAgreementRenewalSRHandler.generateBrokerAgreement(brokerAgreementRenewalCases);
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
        List<Case> closedDefaultUnitCases = new List<Case>();
        
        for(Case objCase :(List<Case>)newList){
            if(objCase.RecordTypeId == defaultUnitRecordTypeId && objCase.Status == 'Closed' && oldCaseMap.get(objCase.Id).Status != 'Closed' 
                && objCase.CaseSubClosureReason__c == 'Forwarded to the concerned department'){
                closedDefaultUnitCases.add(objCase);
            }
            if(objCase.RecordTypeId != caseSocialMediaRecordTypeId && objCase.RecordTypeId !=accessPermitRecordTypeId  && objCase.RecordTypeId !=postSalePaymentDeferralRecordTypeId  && objCase.RecordTypeId !=bfmServiceRequestRecordTypeId && objCase.RecordTypeId !=contactCenterDigitalCaseRecordTypeId && objCase.RecordTypeId !=resaleForCompletedProjectRecordTypeId && objCase.RecordTypeId !=resaleWithPHPPRecordTypeId && objCase.RecordTypeId !=resaleUnderConstructionRecordTypeId && objCase.recordTypeId != caseANPRRecordTypeId && objCase.recordTypeId != accessPermitServiceRequestRecordTypeId && objCase.recordTypeId != moveINServiceRequestRecordTypeId && objCase.recordTypeId != moveINHolidayHomesServiceRequestRecordTypeId && objCase.recordTypeId != moveINOwnerServiceRequestRecordTypeId && objCase.recordTypeId != moveOUTServiceRequestRecordTypeId && objCase.recordTypeId != renewalServiceRequestRecordTypeId && objCase.recordTypeId != resaleMasterRecordTypeId){ 
                objCaseList.add(objCase);
            }
            
            // Add for Broker Contact creation
            if (objCase.RecordTypeId == caseBrokerRegistrationRecordTypeId && objCase.TypeofEstablishment__c != null && objCase.SubType__c == 'Broker New Agent Registration') {
                    Case oldCase = (Case) oldMap.get(objCase.Id);
                    if (oldCase != null) {
                    if (objCase.ApprovalStatus__c == 'Approved' && objCase.FinalApprovalStage__c == 'Second Approval' && objCase.SubStatus__c == 'Closed' &&
                        (oldCase.ApprovalStatus__c != 'Approved' || oldCase.FinalApprovalStage__c != 'Second Approval' || oldCase.SubStatus__c != 'Closed')) {
                        objBrokerCaseList.add(objCase);
                        }   
                    }
                }
            if(!objCaseList.isEmpty()){
                //CaseRoundRobin.caseCountMethod(newList,(Map<Id,Case>)oldMap);
            }
        }

        if(!closedDefaultUnitCases.isEmpty()){
            CaseTriggerHelper.handleDefaultUnitCaseClosure(closedDefaultUnitCases);
        }

        // Create Broker Contacts
        if (!objBrokerCaseList.isEmpty()) {
            // Fetch record type metadata
            //Map<Id, RecordType> recordTypeMap = new Map<Id, RecordType>([SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Case']);
            // Do not modify trigger records — pass recordTypeMap to helper
            //CaseTriggerHelper.createBrokerContacts(objBrokerCaseList, recordTypeMap);
            CaseTriggerHelper.createBrokerContacts(objBrokerCaseList); // US-745
        }

           // Collect Case Ids from trigger context
        Set<Id> caseIds = new Set<Id>();
        for (Case cs : (List<Case>) newList) {
            caseIds.add(cs.Id);
        }
        
        // Query once for all conditions
        List<Case> casesWithService = [
            SELECT Id, RecordTypeId, ApprovalStatus__c,ParentId,AccountId, ContactId, Type, SubType__c, TradeLicenseExpiryDate__c, VATUndertakingIssue_Date__c, IsVATRegistered__c, Address1__c, Address2__c, PhoneNumber__c, TaxRegistrationNumber__c, CommercialLicenseExpiryDate__c, ServiceCatalog__c, ServiceCatalog__r.Category__c, ServiceCatalog__r.SubCategory__c, BrokerContactRole__c, NationalIDExpiryDate__c, PassportExpiryDate__c, BRN_RERA_Expiry_Date__c, AccountNumber__c, BankName__c, BankAddress__c, IBANNumber__c, SwiftCode__c, Broker_Agent__c,PostApprovalAction__c, AgencyName__c,AgencyType__c
            FROM Case
            WHERE Id IN :caseIds
        ];
        
        // Get RecordType Ids
        Id brokerAgencyDetailsRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('BrokerAgencyDetailsUpdate').getRecordTypeId();
        Id brokerAgentDetailsRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('BrokerAgentRegistrationAndUpdate').getRecordTypeId();
        Id brokerCommissionRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('BrokerCommissionIssue').getRecordTypeId();
        Id brokerOtherRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('BrokerGeneralServiceRequest').getRecordTypeId();
        Id brokerAgreementRenewalRTId = Utility.getRecordTypeIdByDevName(Case.SObjectType, Broker_Agreement_Renewal);
        
        // Separate lists
        List<Case> casesToApprove = new List<Case>();
        List<Case> brokerCases = new List<Case>();
        List<Case> childCases = new List<Case>();
        List<Case> brokerAgentCases = new List<Case>();
        Set<Id> parentCaseIds = new Set<Id>();
        Set<Id> childCaseIds = new Set<Id>();

        
        // Single loop — handle all conditions
        for (Case cs : casesWithService) {
            if (cs.ServiceCatalog__r == null) continue;
            
            Case oldCase = (Case) oldMap.get(cs.Id);

            // Update Account from ParentCase when child case Approved
            if (cs.RecordTypeId == brokerAgreementRenewalRTId && cs.ServiceCatalog__r.Category__c == 'Broker Service Request' && cs.ServiceCatalog__r.SubCategory__c == 'Broker Agreement Renewal' && cs.ApprovalStatus__c == 'Approved' &&
                oldCase.ApprovalStatus__c != cs.ApprovalStatus__c) {
                    if(cs.ParentId !=null){
                    ParentCaseIds.add(cs.ParentId);
                    }
                    childCaseIds.add(cs.Id);
                    system.debug('ParentCaseIds-->'+ParentCaseIds);
                }

            
         
            // Create Broker Accounts -> update Account
            if (cs.RecordTypeId == brokerAgencyDetailsRTId && cs.ServiceCatalog__r.Category__c == 'Broker Service Request' && cs.ServiceCatalog__r.SubCategory__c == 'Broker Agency Details Update' && cs.ApprovalStatus__c == 'Approved' &&
                oldCase.ApprovalStatus__c != cs.ApprovalStatus__c) {
                childCases.add(cs);
                    
                    Boolean createsChildCase = false;
                    if ((cs.PostApprovalAction__c == 'Generate Renewal Agreement' && (cs.SubType__c == 'Bank Details Update' || cs.SubType__c == 'Trade License Expiry Update' ||
                                                                                      cs.SubType__c == 'VAT Details Update' || cs.SubType__c == 'Legal Documents Update')) || 
                        cs.SubType__c == 'Agency Name or Type Update'|| cs.SubType__c == 'Broker Agreement Renewal Complete Details Update') {
                            
                            createsChildCase = true;
                        }
                    
                    // Only update Account if no child case is created
                    if (!createsChildCase) {
                        brokerCases.add(cs);
                    }
                }
            
            // Broker Agent Service Request -> update Contact
  
            if (cs.RecordTypeId == brokerAgentDetailsRTId && cs.ServiceCatalog__r.Category__c == 'Broker Service Request' && cs.ServiceCatalog__r.SubCategory__c == 'Broker Agent Details Update' && cs.ApprovalStatus__c == 'Approved') {
                system.debug('Cs-->'+cs);
                brokerAgentCases.add(cs);
            }
        }
        
         Boolean updateAgreementRenewalStatus = false;
        if (!brokerCases.isEmpty()) {
            CaseTriggerHelper.updateBrokerAccounts(brokerCases,updateAgreementRenewalStatus);
        }
        if (!brokerAgentCases.isEmpty()) {
            CaseTriggerHelper.updateBrokerContactSR(brokerAgentCases);
        }
        if (!childCases.isEmpty()) {
            BrokerAgreementRenewalSRHandler.createChildCases(childCases);
        }
        if (!ParentCaseIds.isEmpty()) {
             updateAgreementRenewalStatus = true;
            list<case> caseRecords = CaseService.getInstance().getCaseByIds(ParentCaseIds);
            CaseTriggerHelper.updateBrokerAccounts(caseRecords,updateAgreementRenewalStatus);
        }
        if (!childCaseIds.isEmpty()) {
            list<case> caseRecords = CaseService.getInstance().getCaseByIds(childCaseIds);
            BrokerAgreementRenewalSRHandler.moveSignedAgreementdToAccount(caseRecords);
        }
        // Send BBM queue notifications
        CaseTriggerHelper.sendBBMQueueEmails(newList);

        //Vehicle Parking Registration logic 
        CaseTriggerHelper.handleVehicleParkingRegistrationReqAfterUpdate((List<Case>)newList, (Map<Id, Case>)oldMap); 
        CaseTriggerHelper.handleSendEmailActions(newList,oldMap);

        // BAPP Complete tasks when broker cases are closed
        Set<Id> brokerRecordTypeIds = new Set<Id>{
            brokerAgentDetailsRTId, brokerAgencyDetailsRTId, brokerCommissionRTId, brokerOtherRTId
        };
        List<Case> brokerCasesForTaskCompletion = new List<Case>();
        for (Case cs : (List<Case>) newList) {
            if (brokerRecordTypeIds.contains(cs.RecordTypeId)) {
                brokerCasesForTaskCompletion.add(cs);
            }
        }
        if (!brokerCasesForTaskCompletion.isEmpty()) {
            CaseTriggerHelper.completeRelatedTasks(
                brokerCasesForTaskCompletion,
                (Map<Id, Case>) oldMap
            );
        }
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