/************************************************************************************************
Class       : SrQueryDetailsController
Author      : Pranav G
Description : 
TestClass   : 
------------------------------------------------------------------------------------------------*/
public without sharing class SrQueryDetailsController {

    private static final string THIRD_PARTY_FORM_RT { get { return 'ThirdPartyForm'; } }
    private static final string PAYMENT_SR_RT { get { return 'Payment_SR'; } }
    private static final string POP_SHARE_SR_RT { get { return 'ProofofPaymentShared'; } }//Pranav
    private static final string BANK_ACC_DTAIL_SR_RT { get { return 'BankAccountDetailsInquiry'; } }

    @AuraEnabled
    public static Map<String, String> sendClarificationEmail(String recordId , String descriptionEn, String descriptionAr){
        Map<String, String> response = new Map<String, String>();
        ThirdPartyFormSRHandler tpObj = ThirdPartyFormSRHandler.getInstance();
        PaymentSRHandler pymntObj = PaymentSRHandler.getInstance();
        ProofofPaymentSharedSRHandler popShareObj = ProofofPaymentSharedSRHandler.getInstance();
        BankAccDetailInquirySRHandler bnkAccDtlObj = BankAccDetailInquirySRHandler.getInstance();

        Id thrdPrtyFrmRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,THIRD_PARTY_FORM_RT);
        Id pymntRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,PAYMENT_SR_RT);
        Id popShareRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,POP_SHARE_SR_RT);
        Id bnkAccDtlRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,BANK_ACC_DTAIL_SR_RT);

        Id recId = (Id)recordId;
        if(recId.getSobjectType() == Case.getSobjectType()){
            List<String> remarkList = new List<String>{descriptionEn, descriptionAr};
            CaseService serviceObj = CaseService.getInstance();   
            Case caseRecord = serviceObj.getCaseById(recordId);
            
            if(caseRecord.RecordTypeId == thrdPrtyFrmRTID){
                response = tpObj.sendClarificationEmail(caseRecord, remarkList, null);           
            }
            if(caseRecord.RecordTypeId == pymntRTID){
                response = pymntObj.sendClarificationEmail(caseRecord, remarkList);           
            } 
            if(caseRecord.RecordTypeId == popShareRTID){
                response = popShareObj.sendClarificationEmail(caseRecord, remarkList, null);           
            }
            if(caseRecord.RecordTypeId == bnkAccDtlRTID){
                response = bnkAccDtlObj.sendClarificationEmail(caseRecord, remarkList, null);           
            }  
            
            System.debug('response ONE ::::: '+ response);
        }
        return response;
    }

    @AuraEnabled
    public static Map<String, String> sendThirdPartyForm(String recordId, String type){
        Map<String, String> response = new Map<String, String>();
        ThirdPartyFormSRHandler tpObj = ThirdPartyFormSRHandler.getInstance();
        PaymentSRHandler pymntObj = PaymentSRHandler.getInstance();
        ProofofPaymentSharedSRHandler popShareObj = ProofofPaymentSharedSRHandler.getInstance();
        BankAccDetailInquirySRHandler bnkAccDtlObj = BankAccDetailInquirySRHandler.getInstance();
        System.debug('type>>'+type);

        Id thrdPrtyFrmRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,THIRD_PARTY_FORM_RT);
        Id pymntRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,PAYMENT_SR_RT);
        Id popShareRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,POP_SHARE_SR_RT);
        Id bnkAccDtlRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,BANK_ACC_DTAIL_SR_RT);

        Id recId = (Id)recordId;
        if(recId.getSobjectType() == Case.getSobjectType()){
            CaseService serviceObj = CaseService.getInstance();   
            Case caseRecord = serviceObj.getCaseById(recordId);
            
            if(caseRecord.RecordTypeId == thrdPrtyFrmRTID){
                response = tpObj.sendClarificationEmail(caseRecord, null, type);           
            }
            //if(caseRecord.RecordTypeId == pymntRTID){
            //    response = pymntObj.sendClarificationEmail(caseRecord, null, );        
            //} 
            if(caseRecord.RecordTypeId == popShareRTID){
                response = popShareObj.sendClarificationEmail(caseRecord, null, type);        
            }
            if(caseRecord.RecordTypeId == bnkAccDtlRTID){
                response = bnkAccDtlObj.sendClarificationEmail(caseRecord, null, type);           
            } 
            caseRecord.TPFType__c = type;
            if(response.get('status') != null && response.get('status') == 'success')
            update caseRecord; 
            
            System.debug('response ONE ::::: '+ response);
        }
        return response;
    }
}