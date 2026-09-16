/*****************************************************************************************
Class       : ApprovalController
Author      : Vikas Baliyan
Description : Approval Controller
Test Class  : 
Created Date: 26 NOV 2024 
*****************************************************************************************/
public with sharing class ApprovalController {

    private static final string COMMISSION_INVOICE_FIRST_APPROVAL { get { return 'CommissionInvoiceFirstApproval'; } }
    private static final string COMMISSION_INVOICE_SECOND_APPROVAL { get { return 'CommissionInvoiceSecondApproval'; } }
    private static final string COMMISSION_INVOICE_FINAL_APPROVAL { get { return 'CommissionInvoiceThirdApproval'; } }
    private static final string COMMISSION_SCHEDULE_APPROVAL_PROCESS { get { return 'CommissionScheduleApprovalProcess'; } }
    private static final string RECORD_SEND_FOR_APPROVAL_SUCCESS_STRING { get { return 'Record has been send for approval successfully!'; } }
    private static final string RECORD_SEND_FOR_APPROVAL_FAILED_STRING { get { return 'Request for approval failed!'; } }
    private static final string UPLOAD_BROKER_INVOICE_ERROR_STRING { get { return 'Please upload the Broker Invoice before submitting for Financial Approval.'; } }
    private static final string UNIT_NOT_REGISTERED_ERROR_STRING { get { return 'The unit is not yet registered.'; } }
    private static final string PAYMENT_INITIATED_STRING { get { return 'Payment Initiated'; } }
    private static final string POSTED_STRING { get { return 'Posted'; } }
    private static final string APPROVED_STRING { get { return 'Approved'; } }
    private static final string GENERAL_ENQUIRY_RT { get { return 'GeneralEnquiry'; } }
    
    
    @AuraEnabled
    public static String sendApproval(Id recordId, String comment){
        MetadataService objMetadataService = MetadataService.getInstance();
        BrokerCommissionService objBrokerCommissionServ = BrokerCommissionService.getInstance();
         Id generalEnquiryRTId = Utility.getRecordTypeIdByDevName(
                Case.SObjectType,
                GENERAL_ENQUIRY_RT
            );
        String msg = '';
        try{
            if(recordId.getSObjectType() == BrokerCommission__c.getSObjectType()){
                BrokerCommission__c broker = objBrokerCommissionServ.getBrokerCommissionById(recordId);
                //msg = broker.SalesOrder__r.Unit__r.RegistrationDate__c != null ? '' : UNIT_NOT_REGISTERED_ERROR_STRING;
                msg = broker.Agency__r.Broker_Registration_Expiry_Date__c == null ? 'Broker is not yet registered.' : broker.Agency__r.Broker_Registration_Expiry_Date__c < System.today() ? 'Broker Registration is expired.' : msg;
                msg = broker.Agency__r.RERACertificateExpiryDate__c == null ? 'RERA Certificate is not available for this broker' : broker.Agency__r.RERACertificateExpiryDate__c < System.today() ? 'RERA Certificate is expired.' : msg;
                msg = broker.Agency__r.Trade_License_Expiry_Date__c == null ? 'Trade License is not available for this broker' : broker.Agency__r.Trade_License_Expiry_Date__c < System.today() ? 'Trade License is expired.' : msg ;
                
                Boolean isValidBrokerRegistration = broker.Agency__r.Broker_Registration_Expiry_Date__c != null && broker.Agency__r.Broker_Registration_Expiry_Date__c >= System.today();
                Boolean isValidRERACertificate = broker.Agency__r.RERACertificateExpiryDate__c != null && broker.Agency__r.RERACertificateExpiryDate__c >= System.today();
                Boolean isValidTradeLicense = broker.Agency__r.Trade_License_Expiry_Date__c != null && broker.Agency__r.Trade_License_Expiry_Date__c >= System.today();
                //Boolean isValidUnitRegistration = broker.SalesOrder__r.Unit__r.RegistrationDate__c != null;
                Boolean isValidRecord = isValidBrokerRegistration && isValidRERACertificate && isValidTradeLicense /*&& isValidUnitRegistration*/;

                if(isValidRecord && broker.Status__c == Constants.COMMISSION_INVOICE_STATUS_DRAFT){
                    msg = invokeApprovalProcess(recordId, COMMISSION_INVOICE_FIRST_APPROVAL, comment) ? RECORD_SEND_FOR_APPROVAL_SUCCESS_STRING : RECORD_SEND_FOR_APPROVAL_FAILED_STRING;
                }
                else if(isValidRecord && broker.Status__c == Constants.COMMISSION_INVOICE_STATUS_SHARED){
                    
                    if(broker.BrokerInvoiceNumber__c == null || broker.InvoiceDate__c == null){
                        msg = 'Please update Broker Invoice Number and Invoice Date before sending for approval.';
                        return msg;
                    } 
                    
                    if(validateApproval(recordId)){
                        //Enable show generate combined Document button
                        broker.ShowGenerateCombinedDocument__c = true;
                        objBrokerCommissionServ.updateBrokerCommissions(new List<BrokerCommission__c>{broker});
                        
                        msg = invokeApprovalProcess(recordId, COMMISSION_INVOICE_SECOND_APPROVAL, comment) ? RECORD_SEND_FOR_APPROVAL_SUCCESS_STRING : RECORD_SEND_FOR_APPROVAL_FAILED_STRING;
                        System.enqueueJob(new PDFQueueable(new List<BrokerCommission__c>{broker} ,BrokerCommission__c.SObjectType , 'Broker Form' ));
                    }
                    else{
                        msg = UPLOAD_BROKER_INVOICE_ERROR_STRING;
                    }     
                }
                else if(
                    isValidRecord && broker.Status__c == POSTED_STRING && broker.SecondApprovalStatus__c == APPROVED_STRING && broker.FinalApprovalStatus__c != APPROVED_STRING
                ){
                    msg = invokeApprovalProcess(recordId, COMMISSION_INVOICE_FINAL_APPROVAL, comment) ? RECORD_SEND_FOR_APPROVAL_SUCCESS_STRING : RECORD_SEND_FOR_APPROVAL_FAILED_STRING;
                }
            }
            else if(recordId.getSObjectType() == CommissionSchedule__c.getSObjectType()){
                msg = invokeApprovalProcess(recordId, COMMISSION_SCHEDULE_APPROVAL_PROCESS, comment) ? RECORD_SEND_FOR_APPROVAL_SUCCESS_STRING : RECORD_SEND_FOR_APPROVAL_FAILED_STRING;
            }
           else if(recordId.getSObjectType() == Case.SObjectType){
                                     
                   Case cs = CaseService.getInstance().getCaseById(recordId);
                    if(cs.RecordTypeId == generalEnquiryRTId && cs.SubType__c == 'Customer Type Update') {
    
                   validateCustomerTypeUpdate(cs);
    
                 if(cs.Customer_Sub_Type__c == 'Suqur Al Watan' && !hasUploadedDocument(cs.Id)) {
    
                 throw new AuraHandledException('Please upload a document before submitting the approval request.');
              }
    
        msg = invokeApprovalProcess(cs.Id,'Customer_Type_Update_Approval1','Submitting Case for approval')? RECORD_SEND_FOR_APPROVAL_SUCCESS_STRING: RECORD_SEND_FOR_APPROVAL_FAILED_STRING;
       }
                }
                return msg; 
            }
           catch(AuraHandledException ex){
        throw ex;
    }
    catch(Exception ex){
        throw new AuraHandledException(ex.getMessage());
    }  
        }

    private static Boolean validateApproval(Id recordId){
        DocumentService docService = DocumentService.getInstance();
        List<Document__c> docList = docService.getDocumentBasedonType(recordId, Constants.BROKER_SHARED_INVOICE);
        return !docList.isEmpty() && docList[0].ContentDocumentId__c != null;
    }

    public static Boolean invokeApprovalProcess(Id recordId, String processName, String comments){
        //Create an approval request 
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        if(String.isNotBlank(comments)){   req.setComments(comments); }
        req.setObjectId(recordId);
        req.setProcessDefinitionNameOrId(processName);
        
        // Submit the approval request
        Approval.ProcessResult result = Approval.process(req);
        return result.isSuccess();
    }
    private static void validateCustomerTypeUpdate(Case cs) {
        List<String> missingFields = new List<String>();
    
        if(String.isBlank(cs.Customer_Type__c)){
            missingFields.add('Customer Type');
        }
    
        if(String.isBlank(cs.Customer_Sub_Type__c)){
            missingFields.add('Customer Sub Type');
        }
    
        if(String.isBlank(cs.NameofCorporate__c)){
            missingFields.add('Name of Corporate');
        }
    
        if(!missingFields.isEmpty()){
            throw new AuraHandledException(
                String.join(missingFields, ', ') + ' cannot be blank.'
            );
        }
          
    }
        private static Boolean hasUploadedDocument(Id caseId) {
        List<Document__c> docs =
            DocumentService.getInstance()
                .getExistingDocumentsByCaseId(new Set<Id>{caseId});
    
        for(Document__c doc : docs){
            if(doc.ContentDocumentId__c != null){
                return true;
            }
        }
    
        return false;
    }
}