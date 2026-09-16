/*****************************************************************************************
Class       : BrokerCommissionTriggerHelper
Author      : Vikas Baliyan
Description : Broker Commission Trigger Helper
Test Class  : 
Created Date: 10 DEC 2024 
*****************************************************************************************/
public without sharing class BrokerCommissionTriggerHelper {
    private static final string IR_FIRST_APPROVAL_ACTION { get { return 'IR_First_Approval_Action'; } }
    private static final string IR_SECOND_APPROVAL_ACTION { get { return 'IR_Second_Approval_Action'; } }
    private static final string IR_OBJECT_API_NAME { get { return 'IR_Object_API_Name'; } }
    private static final string IR_BROKER_SAP_BR_ROLE { get { return 'IR_Broker_SAP_BR_Role'; } }
    private static final string IR_TRANSACTION_TYPE { get { return 'IR_Transaction_Type'; } }
    private static final string IR_TAXABLE { get { return 'IR_Taxable'; } }
    private static final string IR_NON_TAXABLE { get { return 'IR_Non_Taxable'; } }
    private static final string IR_PARAM14 { get { return 'IR_Param14'; } }
    private static final string IR_TAX_GROUP_TAXABLE { get { return 'IR_Tax_Group_Taxable'; } }
    private static final string IRTAXGROUPNONTAXABLE { get { return 'IR_Tax_Group_Non_Taxable'; } }
    private static final string IR_FIRST_INSTALLMENT { get { return 'IR_First_Installment'; } }
    private static final string IR_SECOND_INSTALLMENT { get { return 'IR_Second_Installment'; } }
    private static final string IR_THIRD_INSTALLMENT { get { return 'IR_Third_Installment'; } }
    private static final string INVOICE_PAID_EMAIL_TEMPLATE_ID { get { return 'CommissionInvoicePaidTempId'; } }
    private static final string BLOOM_NO_REPLY_OW_EMAIL_ID { get { return 'BAPPOrgWideEmailAddress'; } }
    private static final string INVOICE_PAID_CC_EMAIL { get { return 'CommissionInvoicePaidCCEmails'; } }
    private static final string INVOICE_PAID_BCC_EMAIL { get { return 'CommissionInvoicePaidBCCEmails'; } }
    private static final string COMMISSION_INVOICE_THIRD_APPROVAL { get { return 'CommissionInvoiceThirdApproval'; } }
    private static final string BROKER_COMMISSION_STR { get { return 'Broker Commission'; } }
    private static final string APPROVED_STR { get { return 'Approved'; } }
    private static final string PAID_STR { get { return 'Paid'; } }
    private static final string INSERT_STR { get { return 'Insert'; } }
    private static final string UPDATE_STR { get { return 'Update'; } }
    private static final string REVERSED_STR { get { return 'Reversed'; } }
    private static final string BROKER_FORM_STR { get { return 'Broker Form'; } }
    private static final string PAYMENT_INITIATED_STR { get { return 'Payment Initiated'; } }
    private static final string YES_STR { get { return 'Yes'; } }
    private static final string BAPP_COMMISSION_RELEASED_TO_BROKER_AGENCY_TEMP_ID { get { return 'BAPPCommissionReleasedToTheBrokerAgency'; } }
    
    public static void createDocuments(List<BrokerCommission__c> newList){     
        DocumentService objDocumentService = DocumentService.getInstance();
        List<DocumentType__c> brokerCommiDocTypeList = objDocumentService.getDocTypes(BROKER_COMMISSION_STR);
        List<Document__c> documentList = new List<Document__c>();
        for(BrokerCommission__c brokerCommission :newList){
            for(DocumentType__c objDocumentType :brokerCommiDocTypeList){
                documentList.add(new Document__c(BrokerCommission__c = brokerCommission.Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c));
            }
        }
        objDocumentService.insertDocuments(documentList);   
    }
    
    public static void createIntegrationRecord(List<BrokerCommission__c> newList, Map<Id, BrokerCommission__c> oldMap){
        MetadataService objMetadataService = MetadataService.getInstance();
        IntegrationRecordService integService = IntegrationRecordService.getInstance();
        BrokerCommissionService ObjbrokerCommissionService = BrokerCommissionService.getInstance();
        List<IntegrationRecord__c> integrationRecordsToInsert = new List<IntegrationRecord__c>();
        List<BrokerCommission__c> brokerCommissionList = new List<BrokerCommission__c>();
        Set<Id> brokerIdSet = new Set<Id>();
        for(BrokerCommission__c broker : newList){
            if((oldMap.get(broker.Id).SecondApprovalStatus__c != APPROVED_STR && broker.SecondApprovalStatus__c == APPROVED_STR) || (oldMap.get(broker.Id).FinalApprovalStatus__c != APPROVED_STR && broker.FinalApprovalStatus__c == APPROVED_STR)){
                brokerIdSet.add(broker.Id);
            }
        }
        List<BrokerCommission__c> brokerList = ObjbrokerCommissionService.getBrokerRecordsByidSet(brokerIdSet);
        for(BrokerCommission__c broker : brokerList){
            if(oldMap.get(broker.Id).SecondApprovalStatus__c != APPROVED_STR && broker.SecondApprovalStatus__c == APPROVED_STR){
                integrationRecordsToInsert.add(getIntegrationRecord(broker, INSERT_STR));  
            }
            if(oldMap.get(broker.Id).FinalApprovalStatus__c != APPROVED_STR && broker.FinalApprovalStatus__c == APPROVED_STR){
                brokerCommissionList.add(broker);
                integrationRecordsToInsert.add(getIntegrationRecord(broker, UPDATE_STR));  
            }
        }
        if(!brokerCommissionList.isEmpty()){
            System.enqueueJob(new PDFQueueable(brokerCommissionList ,BrokerCommission__c.SObjectType , BROKER_FORM_STR ));  
        }
        
        if(!integrationRecordsToInsert.isEmpty()){
            integService.insertIntegrationRecords(integrationRecordsToInsert);
        }    
        
    } 
    
    public static IntegrationRecord__c getIntegrationRecord(BrokerCommission__c broker, String action){
        IntegrationRecordService integService = IntegrationRecordService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        Boolean isVATRegistered = broker.Agency__r.Is_VAT_Registered__c == YES_STR ? true : false;
        
        DateTime invoiceDate;
        if(broker.InvoiceDate__c != NULL){
            invoiceDate = DateTime.newInstance(broker.InvoiceDate__c, Time.newInstance(0, 0, 0, 0));
        }
        return integService.getIntegrationRecord(
            action == INSERT_STR ? objMetadataService.getAppSettingTextValue(IR_FIRST_APPROVAL_ACTION) : objMetadataService.getAppSettingTextValue(IR_SECOND_APPROVAL_ACTION),
            objMetadataService.getAppSettingTextValue(IR_OBJECT_API_NAME),
            String.valueOf(broker.Id), 
            String.valueOf(broker.SalesOrder__r.Company_Code__c),
            String.valueOf(broker.SalesOrder__r.SAP_Contract_No__c),
            String.valueOf(broker.SalesOrder__r.Unit__r.SAP_Unit_Number__c), 
            String.valueOf(broker.SalesOrder__r.Unit__r.SAP_Business_Entity_No__c), 
            String.valueOf(broker.SalesOrder__r.Unit__r.SAP_Building_No__c), 
            String.valueOf(broker.SalesOrder__r.Unit__r.SAP_Broker_bp__c), 
            objMetadataService.getAppSettingTextValue(IR_BROKER_SAP_BR_ROLE),
            objMetadataService.getAppSettingTextValue(IR_TRANSACTION_TYPE),
            String.valueOf(broker.InstallmentLine__r.InstallmentNumber__c == 1 ? objMetadataService.getAppSettingTextValue(IR_FIRST_INSTALLMENT) : broker.InstallmentLine__r.InstallmentNumber__c == 2 ? objMetadataService.getAppSettingTextValue(IR_SECOND_INSTALLMENT) : broker.InstallmentLine__r.InstallmentNumber__c == 3 ? objMetadataService.getAppSettingTextValue(IR_THIRD_INSTALLMENT) : ''),
            action == INSERT_STR ? String.valueOf((System.now()).format('yyyy-MM-dd\'T\'HH:mm:ss')) :  broker.FirstIntegrationDate__c != null ? String.valueOf((broker.FirstIntegrationDate__c).format('yyyy-MM-dd\'T\'HH:mm:ss')) : '',
            action == INSERT_STR ? String.valueOf(broker.CommissionAmount__c) : String.valueOf((invoiceDate).format('yyyy-MM-dd\'T\'HH:mm:ss')),
            action == INSERT_STR ? String.valueOf(broker.CommissionPercentage__c) : String.valueOf(broker.CommissionAmount__c),
            action == INSERT_STR ? (isVATRegistered ? objMetadataService.getAppSettingTextValue(IR_TAXABLE):objMetadataService.getAppSettingTextValue(IR_NON_TAXABLE)) : String.valueOf(broker.CommissionPercentage__c),
            action == INSERT_STR ? objMetadataService.getAppSettingTextValue(IR_PARAM14) : (isVATRegistered ? objMetadataService.getAppSettingTextValue(IR_TAXABLE):objMetadataService.getAppSettingTextValue(IR_NON_TAXABLE)), 
            action == INSERT_STR ? (isVATRegistered ? objMetadataService.getAppSettingTextValue(IR_TAX_GROUP_TAXABLE):objMetadataService.getAppSettingTextValue(IRTAXGROUPNONTAXABLE)) : objMetadataService.getAppSettingTextValue(IR_PARAM14),
            action == INSERT_STR ? '' : (isVATRegistered ? objMetadataService.getAppSettingTextValue(IR_TAX_GROUP_TAXABLE):objMetadataService.getAppSettingTextValue(IRTAXGROUPNONTAXABLE)),
            action == INSERT_STR ? '' : String.valueOf(broker.BrokerInvoiceNumber__c),
            action == INSERT_STR ? '' : String.valueOf((System.now()).format('yyyy-MM-dd\'T\'HH:mm:ss'))
        );
    }
    
    public static void sendEmailToRelatedContacts(List<BrokerCommission__c> newList, Map<Id, BrokerCommission__c> oldMap){
        MetadataService objMetadataService = MetadataService.getInstance();
        ContactService objContactService = ContactService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        Set<Id> accIdSet = new Set<Id>();
        List<BrokerCommission__c> paidBrokerCommissionsList = new List<BrokerCommission__c>();
        try{
            for(BrokerCommission__c broker : newList){
                if(oldMap.get(broker.Id).Status__c != PAID_STR && broker.Status__c == PAID_STR && broker.Agency__c != null){
                    accIdSet.add(broker.Agency__c);
                    paidBrokerCommissionsList.add(broker);
                }
            }
            List<Contact> conList = objContactService.getBrokerAgentByRoles(accIdSet);
            Id noReplyBloomSalesOWDId = objMetadataService.getAppSettingTextValue(BLOOM_NO_REPLY_OW_EMAIL_ID);
            Id invoicePaidEmailTemplateId = objMetadataService.getAppSettingTextValue(BAPP_COMMISSION_RELEASED_TO_BROKER_AGENCY_TEMP_ID);
            List<String> ccEmailAddressList = objMetadataService.getAppSettingTextValue(INVOICE_PAID_CC_EMAIL) != null ? (objMetadataService.getAppSettingTextValue(INVOICE_PAID_CC_EMAIL)).split(',') : null;
            List<String> bccEmailAddressList = objMetadataService.getAppSettingTextValue(INVOICE_PAID_BCC_EMAIL) != null ? (objMetadataService.getAppSettingTextValue(INVOICE_PAID_BCC_EMAIL)).split(',') : null;
            // List of email to send
            List<Messaging.SingleEmailMessage> msgList =new List<Messaging.SingleEmailMessage>();    
            if(!conList.isEmpty()){
                Map<Id, List<Contact>> AccIdToContactsMap = new Map<Id, List<Contact>>();
                for (Contact con : conList) {
                    if (!AccIdToContactsMap.containsKey(con.AccountId)) {
                        AccIdToContactsMap.put(con.AccountId, new List<Contact>());
                    }
                    AccIdToContactsMap.get(con.AccountId).add(con);
                }
                
                for(BrokerCommission__c bc :paidBrokerCommissionsList){
                    List<Contact> relatedContacts = AccIdToContactsMap.get(bc.Agency__c);
                    if (relatedContacts != null && !relatedContacts.isEmpty()){
                        for(Contact con : relatedContacts){
                            msgList.add(objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(invoicePaidEmailTemplateId, noReplyBloomSalesOWDId, bc.Id,con.Id ,null , ccEmailAddressList, bccEmailAddressList));
                        }
                    }
                }
            }
            else{
                for(BrokerCommission__c bc :paidBrokerCommissionsList){
                    msgList.add(objEmailService.getSingleEmailMessageWithoutTargetObjectId(invoicePaidEmailTemplateId, noReplyBloomSalesOWDId, bc.Id, ccEmailAddressList, bccEmailAddressList, null));
                }
            }
            
            // Sending email
            Messaging.SendEmailResult[] results = objEmailService.sendEmail(msgList);
        } catch (Exception ex) {
            ErrorLogHandler.logError('BrokerCommissionTriggerHelper', 'sendEmailToRelatedContacts', ex,'');
        }     
    }
    
    public static void updateBrokerCommission(List<BrokerCommission__c> newList, Map<Id, BrokerCommission__c> newMap, Map<Id, BrokerCommission__c> oldMap){
        for(BrokerCommission__c broker : newList){
            List<BrokerCommission__c> brokerCommissionList = new List<BrokerCommission__c>();
            if(oldMap.get(broker.Id).Status__c != REVERSED_STR && broker.Status__c == REVERSED_STR){
                broker.ReversalDate__c = System.Today();
            }
            else if(oldMap.get(broker.Id).Status__c != PAYMENT_INITIATED_STR && broker.Status__c == PAYMENT_INITIATED_STR){
                broker.PaymentInitiatedDate__c = System.Today();
            }
            else if(oldMap.get(broker.Id).FinalApprovalStatus__c != APPROVED_STR && broker.FinalApprovalStatus__c == APPROVED_STR){
                brokerCommissionList.add(broker);
            }
            
            if(oldMap.get(broker.Id).SecondApprovalStatus__c != APPROVED_STR && broker.SecondApprovalStatus__c == APPROVED_STR && broker.FinalApprovalStatus__c != APPROVED_STR){
                broker.ERPConditionCreatedDate__c = System.now();
                broker.FirstIntegrationDate__c = System.now();
                broker.IntegrationStatus__c = 'In Progress';
            }
            else if(broker.SecondApprovalStatus__c == APPROVED_STR && oldMap.get(broker.Id).FinalApprovalStatus__c != APPROVED_STR && broker.FinalApprovalStatus__c == APPROVED_STR){
                broker.ERPPostedDate__c = System.now();
                broker.IntegrationStatus__c = 'In Progress';
            }

            if(!brokerCommissionList.isEmpty()){
                System.enqueueJob(new PDFQueueable(brokerCommissionList ,BrokerCommission__c.SObjectType , BROKER_FORM_STR ));
            }
        }
    }
    
}