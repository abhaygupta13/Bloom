/***
Class       : ServiceRequestController 
Author      : Sonali S
Description : 
TestClass   : ServiceRequestControllerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.     version              Date                Details
1.          V1.0              26/02/25          Initial Version 
****************************************************************************************************************/
public without sharing class ServiceRequestController {
    
    private static final string POST_SALE_PAYMENT_DEFERRAL { get { return 'Postpone/Defer Payment'; } }
    private static final string DEFAULT_CUSTOMER { get { return 'Default Customer'; } }
    private static final string CHEQUE_REPLACEMENT_REQUEST { get { return 'Cheque Replacement Request'; } }
    private static final string CHEQUE_WITHDRAWAL_REQUEST { get { return 'Cheque Withdrawal Request'; } }
    private static final string BFM_SERVICE_REQUEST { get { return 'BFM Service Request'; } }
    private static final string COMMON_AREA_SERVICE_REQUEST { get { return 'Common Area Service Request'; } }
    private static final string COMMUNITY_SERVICE_REQUEST { get { return 'Community Services'; } }
    private static final string SERVICE_REQUEST { get { return 'Service Request'; } }
    private static final string FINANCIAL_PAYMENT_SERVICE_CATEGORY{ get { return 'Financial - Payment Service'; } }
    private static final string GENERAL_ENQUIRY_CATEGORY { get { return 'General Enquiry'; } }
    private static final string BFM_SERVICE_CATEGORY{ get { return 'BFM Service'; } }
    private static final string RESALE_CATEGORY { get { return 'Resale'; } }
    private static final string RESALE_SUB_CATEGORY { get { return 'Resale'; } }
    //private static final string ACKNOWLEDGEMENT_RECEIPT_SUB_CATEGORY  { get { return 'Acknowledgement Receipt'; } }//Pranav
    private static final string ACKNOWLEDGEMENT_RECEIPT_SUB_CATEGORY  { get { return 'Receipt Booking Query'; } }//Pranav
    private static final string PAYMENT_DUE_DATE_UPDATE_SUB_CATEGORY  { get { return 'Payment Due Date Update'; } }//Pranav
    private static final string THIRD_PARTY_FORM_SUB_CATEGORY  { get { return 'Third Party Form'; } }//Pranav
    private static final string PAYMENT_SR_SUB_CATEGORY { get { return 'Payment'; } }//Pranav
    private static final string LPF_WAIVER_REQUEST { get { return 'LPF Waiver Request'; } }
    private static final string SOA_REQUEST { get { return 'SOA Request'; } }
    private static final string POPSHARE_SR_SUB_CATEGORY { get { return 'Proof of Payment Shared'; } }//Pranav
    private static final string BANK_ACC_DTAIL_SUB_CATEGORY { get { return 'Bank Account Details Inquiry'; } }//Pranav
    private static final string GENERAL_ENQUIRY_SUB_CATEGORY { get { return 'General Enquiry'; } }
    private static final string KYC_UPDATE_REQUEST { get { return 'KYC Update Request'; } } 
    private static final string CUSTOMER_SERVICE_REQUEST_CATEGORY { get { return 'Customer Service Request'; } }
    private static final string ADM_APPLICATIONS_REGISTRATION_SUB_CATEGORY { get { return 'ADM Applications Registration'; }}
    private static final string CONSTRUCTION_UPDATE_SUB_CATEGORY { get { return 'Construction Update'; } }
    private static final string HANDOVER_UPDATE_SUB_CATEGORY { get { return 'Handover Update'; } }
    private static final string HASSANTUK_SUB_CATEGORY { get { return 'Hassantuk'; } }
    private static final string PROPERTY_ENROLLMENT_SUB_CATEGORY{ get { return 'Property Enrollment'; } }
    private static final string TAQA_SUB_CATEGORY { get { return 'TAQA'; } }
    private static final string SPA_SUB_CATEGORY { get { return 'SPA'; } }
    private static final string SITE_VISIT_PROPERTY_VIEWING_SUB_CATEGORY{ get { return 'Site Visit/Property Viewing'; } }
    private static final string LETTER_SUB_CATEGORY { get { return 'Letter'; } }
    private static final string OTHER_SUB_CATEGORY { get { return 'Other'; } }
    private static final string GENERAL_PAYMENT_ENQUIRY_SUB_CATEGORY { get { return 'General Payment Enquiry'; } } //Samiksha
    private static final string FLOOR_PLAN_COPY_SUB_CATEGORY { get { return 'Floor Plan Copy'; } }
    private static final string CONTACT_DETAILS_SUB_CATEGORY{ get { return 'Contact Details'; } }
    private static final string SPA_PRE_REGISTRATION_SUB_CATEGORY { get { return 'SPA Pre-Registration'; } }
    private static final string TITLE_MORTGAGE_DEED_SUB_CATEGORY { get { return 'Title Deed/Mortgage Deed'; } }
    private static final string RENT_SECURITY_DEPOSIT_REFUND_SUB_CATEGORY { get { return 'Rent Security Deposit Refund'; } } 
    private static final string RENT_REFUND_SUB_CATEGORY { get { return 'Rent Refund'; } }
    private static final string SALES_OPERATION_CATEGORY { get { return 'Sales Operation Service'; } }
    private static final String DOCUMENT_CONTROLLER_SUB_CATEGORY { get { return 'Document Controller'; } }
    private static final String DATA_ANALYSTICS_SUB_CATEGORY { get { return 'Data Analystics'; } }
    private static final String OFFICE_MANAGER_SUB_CATEGORY { get { return 'Office Manager'; } }
    private static final String BROKER_MANAGEMENT_SUB_CATEGORY { get { return 'Broker Management'; } }
    private static final String SALES_OPERATION_SUB_CATEGORY { get { return 'Sales Operation'; } }
    private static final String POST_SALES_OPERATION_SUB_CATEGORY { get { return 'Post Sales Operation'; } }
    private static final String CUSTOMER_FINANCE_SUB_CATEGORY { get { return 'Customer Finance'; } }
    private static final String LEAD_MANAGEMENT_SUB_CATEGORY { get { return 'Leads Management'; } }
    private static final String COMMUNICATION_SUB_CATEGORY { get { return 'Communication'; } }
    private static final String CUSTOMER_TYPE_UPDATE_SUB_CATEGORY { get { return 'Customer Type Update'; } }
    private static final String DATA_CLEANSING_SUB_CATEGORY { get { return 'Data Cleansing'; } }
    private static final string CRM_REQUESTS_CATEGORY { get { return 'CRM Services'; } }
    private static final string TAWTHEEQ_ENROLLMENT_SUB_CATEGORY { get { return 'Tawtheeq Enrollment'; } }
  private static final string COMPLAINT_REQUEST_RT { get { return 'ComplaintRequest'; } }
   private static final string COMPLAINT_REQUEST_TYPE { get { return 'Complaint'; } }
     private static final string BROKER_MANAGEMENT_REQUEST_CATEGORY { get { return 'Broker Management Services'; } }
    private static final string BROKER_ENQUIRY_SUB_CATEGORY { get { return 'Broker Enquiry'; } }
     private static final string HANDOVER_SERVICES_REQUEST_CATEGORY { get { return 'Handover Service Request'; } }
    private static final string HANDOVER_SUB_CATEGORY { get { return 'Handover'; } }
    private static final string SPECIAL_SERVICES_REQUEST_CATEGORY { get { return 'Special Services'; } }
    private static final string DOWNGRADE_SUB_CATEGORY { get { return 'Downgrade'; } }
    private static final string UPGRADE_SUB_CATEGORY { get { return 'Upgrade'; } }
    private static final string CANCELLATION_SUB_CATEGORY { get { return 'Cancellation'; } }
  
   
    
    @AuraEnabled(cacheable=true)
    public static List<sobject> getRelatedUnits(Id recordId){
        String q = 'Select Id, Name, Active_Sales_Order__c, ActiveTenant__c, Active_Sales_Order__r.Name, Active_Sales_Order__r.Account__c FROM Unit__c ';
        String whereClause;
        if(recordId.getSObjectType() == Account.getSobjectType()){
            whereClause = 'WHERE (Active_Sales_Order__r.Account__c = \''+recordId+'\' OR ActiveTenant__c = \''+recordId+'\')';
        }else if(recordId.getSObjectType() == SalesOrder__c.getSobjectType()){
            whereClause = 'WHERE Active_Sales_Order__c = \''+recordId+'\'';
        }else if(recordId.getSObjectType() == Unit__c.getSobjectType()){
            whereClause = 'WHERE Id = \''+recordId+'\'';
        }
        if (String.isNotEmpty(whereClause)) {
            q += whereClause;
        }
        List<sobject> sobjectList = Database.query(q);
        
        if(sobjectList != NULL && !sobjectList.isEmpty()) return sobjectList;
        return null;
    }
    
    @AuraEnabled
    public static List<ServiceCatalog__c> getServiceCatalog(String selectedType, String selectedCategory, String selectedSubCategory){
        ServiceCatalogService serviceObj = ServiceCatalogService.getInstance();
        return serviceObj.getServiceCatalog(selectedType,selectedCategory,selectedSubCategory);
    }
    
    @AuraEnabled
    public static String validateEligibility(Id recordId, String subCategory, String accountRecId, String unitId, Boolean isTenantUnit){
        PostSalePaymentDeferalCaseHandler obj = PostSalePaymentDeferalCaseHandler.getInstance();
        DefaultUnitCaseHandler defaultUnitCaseHandlerobj = DefaultUnitCaseHandler.getInstance();
        ResaleServiceRequestHandler resaleObj = ResaleServiceRequestHandler.getInstance();
        ServiceCatalogService servObj = ServiceCatalogService.getInstance();
        CaseService caseServiceObj = CaseService.getInstance();
        SalesOrderService objSalesOrderService = SalesOrderService.getInstance();
        AcknowledgmentReceiptSRHandler ackObj = AcknowledgmentReceiptSRHandler.getInstance();//Pranav
        PaymentDueDateUpdateSRHandler pmtDuDtdObj = PaymentDueDateUpdateSRHandler.getInstance();//Pranav
        ChequeReplacementRequestCaseHandler objChequeReplacementRequestCaseHandler = ChequeReplacementRequestCaseHandler.getInstance();
        ChequeWithdrawalRequestCaseHandler objChequeWithdrawalRequestCaseHandler = ChequeWithdrawalRequestCaseHandler.getInstance();
        ThirdPartyFormSRHandler thFormObj = ThirdPartyFormSRHandler.getInstance();//Pranav
        PaymentSRHandler pymntSrObj = PaymentSRHandler.getInstance();//Pranav
        ProofofPaymentSharedSRHandler popShareSrObj = ProofofPaymentSharedSRHandler.getInstance();//Pranav
        BankAccDetailInquirySRHandler bnkAccDtlSrObj = BankAccDetailInquirySRHandler.getInstance();//Pranav
            
        List<ServiceCatalog__c> serviceCatalogList = servObj.getServiceCatalogBySubCategories(subCategory);
        Boolean isAvailableForTenant = serviceCatalogList[0].AvailableForTenant__c;
        Boolean isAvailableForOwner = serviceCatalogList[0].AvailableForOwner__c;
        Boolean isComplaintRecordType = true;
        String message;
        
        if(serviceCatalogList == null || serviceCatalogList.isEmpty()) {
            return 'Configuration for this Category/Sub Category not found. Please contact System Administrator.';
        }
        
         if (String.isNotBlank(recordId) && recordId.getSObjectType() == Case.SObjectType) {
              Case caseObj = caseServiceObj.getCaseById(recordId);

            isComplaintRecordType =caseObj.RecordTypeId == Utility.getRecordTypeIdByDevName(Case.SObjectType,COMPLAINT_REQUEST_RT); }
        System.debug('accountRecId ::::: '+ accountRecId);
        if(!serviceCatalogList[0].AllowDuplicateCases__c) {
            String caseNumber = checkForOpenCase(serviceCatalogList[0], recordId, accountRecId, unitId);
            if(caseNumber != null){
                return 'An open service request ('+ caseNumber +') already exists for selected account, unit, category and sub category.';
            }
        }
       
    List<String> subCategoryList = new List<String>{DEFAULT_CUSTOMER, CHEQUE_REPLACEMENT_REQUEST, CHEQUE_WITHDRAWAL_REQUEST, 
        LPF_WAIVER_REQUEST, SOA_REQUEST, RESALE_SUB_CATEGORY, GENERAL_ENQUIRY_SUB_CATEGORY,
        KYC_UPDATE_REQUEST, ADM_APPLICATIONS_REGISTRATION_SUB_CATEGORY, 
        CONSTRUCTION_UPDATE_SUB_CATEGORY, HANDOVER_UPDATE_SUB_CATEGORY, HASSANTUK_SUB_CATEGORY, 
                                                        PROPERTY_ENROLLMENT_SUB_CATEGORY, TAQA_SUB_CATEGORY, SPA_SUB_CATEGORY, 
                                                        SITE_VISIT_PROPERTY_VIEWING_SUB_CATEGORY, LETTER_SUB_CATEGORY, 
                                                        OTHER_SUB_CATEGORY, GENERAL_PAYMENT_ENQUIRY_SUB_CATEGORY,FLOOR_PLAN_COPY_SUB_CATEGORY,
        CONTACT_DETAILS_SUB_CATEGORY,SPA_PRE_REGISTRATION_SUB_CATEGORY,TITLE_MORTGAGE_DEED_SUB_CATEGORY,
        RENT_SECURITY_DEPOSIT_REFUND_SUB_CATEGORY,RENT_REFUND_SUB_CATEGORY,DOCUMENT_CONTROLLER_SUB_CATEGORY,DATA_ANALYSTICS_SUB_CATEGORY,OFFICE_MANAGER_SUB_CATEGORY,BROKER_MANAGEMENT_SUB_CATEGORY,
                                                         SALES_OPERATION_SUB_CATEGORY,POST_SALES_OPERATION_SUB_CATEGORY,CUSTOMER_FINANCE_SUB_CATEGORY,LEAD_MANAGEMENT_SUB_CATEGORY,COMMUNICATION_SUB_CATEGORY,CUSTOMER_TYPE_UPDATE_SUB_CATEGORY,DATA_CLEANSING_SUB_CATEGORY,
                                                        TAWTHEEQ_ENROLLMENT_SUB_CATEGORY,BROKER_ENQUIRY_SUB_CATEGORY,HANDOVER_SUB_CATEGORY,DOWNGRADE_SUB_CATEGORY,CANCELLATION_SUB_CATEGORY,UPGRADE_SUB_CATEGORY };
           List<String> complaintSubCategories = new List<String>();
        

for (ServiceCatalog__c record : [SELECT SubCategory__c FROM ServiceCatalog__c WHERE Type__c = 'Complaint' AND SubCategory__c != null]) {
    complaintSubCategories.add(record.SubCategory__c);
}
        subCategoryList.addAll(complaintSubCategories);
            
        if(subCategory == POST_SALE_PAYMENT_DEFERRAL && String.isBlank(recordId)){
            return 'No active Sales Order is linked to this unit, Please choose other Account/Unit to proceed.';
        }
        
        if (
            (subCategory == POST_SALE_PAYMENT_DEFERRAL && String.isBlank(recordId)) ||
            /*(!subCategoryList.contains(subCategory) && !isAvailableForTenant && isTenantUnit) ||*/
            (!subCategoryList.contains(subCategory) && !isAvailableForOwner && !isTenantUnit)
            
        ) {
            return 'This unit is not eligible for the selected service request';
        }
        
        if (String.isNotBlank(recordId)) {
            Schema.SObjectType sObjectType = recordId.getSObjectType();
            
            if (sObjectType == Salesorder__c.SObjectType) {
                if (subCategory == POST_SALE_PAYMENT_DEFERRAL) {
                    message = obj.validateEligibility(objSalesOrderService.getSalesOrdersById(recordId), null);
                } else if (subCategory == RESALE_SUB_CATEGORY) {
                    message = resaleObj.validateEligibility(objSalesOrderService.getSalesOrdersById(recordId), null);
                } else if (subCategory == DEFAULT_CUSTOMER) {
                    message = defaultUnitCaseHandlerobj.validateEligibility(objSalesOrderService.getSalesOrdersById(recordId), null);
                } else if (subCategory == ACKNOWLEDGEMENT_RECEIPT_SUB_CATEGORY) {//Pranav
                    message = ackObj.validateEligibility(objSalesOrderService.getSalesOrdersById(recordId));
                } else if (subCategory == PAYMENT_DUE_DATE_UPDATE_SUB_CATEGORY) {//Pranav
                    message = pmtDuDtdObj.validateEligibility(objSalesOrderService.getSalesOrdersById(recordId));
                }  else if (subCategory == THIRD_PARTY_FORM_SUB_CATEGORY) {//Pranav
                    message = thFormObj.validateEligibility(objSalesOrderService.getSalesOrdersById(recordId));
                } else if (subCategory == PAYMENT_SR_SUB_CATEGORY) {//Pranav
                    message = pymntSrObj.validateEligibility(objSalesOrderService.getSalesOrdersById(recordId));
                } else if (subCategory == CHEQUE_REPLACEMENT_REQUEST) {
                    message = objChequeReplacementRequestCaseHandler.validateEligibility(objSalesOrderService.getSalesOrdersById(recordId), null);
                } else if (subCategory == CHEQUE_WITHDRAWAL_REQUEST) {
                    message = objChequeWithdrawalRequestCaseHandler.validateEligibility(objSalesOrderService.getSalesOrdersById(recordId), null);
                } else if (subCategory == POPSHARE_SR_SUB_CATEGORY) {//Pranav
                    message = popShareSrObj.validateEligibility(objSalesOrderService.getSalesOrdersById(recordId));
                } else if (subCategory == BANK_ACC_DTAIL_SUB_CATEGORY) {//Pranav
                    message = bnkAccDtlSrObj.validateEligibility(objSalesOrderService.getSalesOrdersById(recordId));
                }
            } else if (sObjectType == Case.SObjectType) {
                if (subCategory == POST_SALE_PAYMENT_DEFERRAL) {
                    message = obj.validateEligibility(null, caseServiceObj.getCaseById(recordId));
                } else if (subCategory == BFM_SERVICE_REQUEST || subcategory == COMMON_AREA_SERVICE_REQUEST) {
                    BFMServiceRequestHandler bfmObj = BFMServiceRequestHandler.getInstance();
                    message = bfmObj.validateEligibility(caseServiceObj.getCaseById(recordId));
                } else if (subCategory == DEFAULT_CUSTOMER) {
                    message = defaultUnitCaseHandlerobj.validateEligibility(objSalesOrderService.getSalesOrdersById(recordId), null);
                }
                else if (subCategory == RESALE_SUB_CATEGORY) {
                    message = resaleObj.validateEligibility(null, caseServiceObj.getCaseById(recordId));
                }
                /*else if (subCategory == RESALE_PROPERTY_UNDER_CONSTRUCTION_SUB_CATEGORY
                         ||subCategory == RESALE_PROPERTY_COMPLETED_PROJECT_SUB_CATEGORY
                         ||subCategory == RESALE_PROPERTY_WITH_PPHP_SUB_CATEGORY) {
                             message = resaleObj.validateEligibility(null, caseServiceObj.getCaseById(recordId));
                }*/
            }
        }
        return message;
    }
    
    public static String checkForOpenCase(ServiceCatalog__c serviceCatalogRec, String recordId, String accountRecId, String unitId){
        String result;
        List<String> recordTypeDevNameList = new List<String>();
        List<String> resaleRecordTypeDevNameList = new List<String>{'Resale','Resale_Master','Resale_Property_with_Post_Handover_Payment_Plan','Resale_Property_For_Completed_Project','Resale_Property_Under_Construction'};
            if(serviceCatalogRec.RecordTypeDevName__c.contains('Resale')){
                recordTypeDevNameList.addAll(resaleRecordTypeDevNameList);
            } else { 
                recordTypeDevNameList.add(serviceCatalogRec.RecordTypeDevName__c);
            }
        if((String.isNotBlank(recordId) || String.isNotBlank(unitId)) && String.isNotBlank(accountRecId)){
            CaseService caseObj = CaseService.getInstance();
            List<Case> caseList = caseObj.getCaseBySalesOrderUnitAccountId(recordId,unitId,accountRecId);
            for(Case c : caseList){
                if(!caseList.isEmpty() && recordTypeDevNameList.contains(c.RecordType.DeveloperName)){
                    result = c.CaseNumber;
                    break;
                }
            }     
        } else if (String.isNotBlank(accountRecId)) {
            CaseService caseObj = CaseService.getInstance();
            List<Case> caseList = caseObj.getCaseByAccountId(accountRecId);
            for(Case c : caseList){
                if(!caseList.isEmpty() && recordTypeDevNameList.contains(c.RecordType.DeveloperName)){
                    result = c.CaseNumber;
                    break;
                }
            }      
        }
        return result;
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String,String> getOriginValues() {
        return Utility.getPicklistValues(Case.SObjectType, 'Origin');
    }    
    
    @AuraEnabled
    public static Map<String, String> convertToRequestComplaint(String selectedType, String selectedCategory, String selectedSubCategory, String selectedAccount, String selectedUnit,Id recordID,String description,String origin){ 
        Map<String, String> result = new Map<String, String>();
        ServiceCatalogService servObj = ServiceCatalogService.getInstance();
        if(recordId.getSobjectType() == Case.getSobjectType() && selectedSubCategory == POST_SALE_PAYMENT_DEFERRAL){
            PostSalePaymentDeferalCaseHandler obj = PostSalePaymentDeferalCaseHandler.getInstance();
            List<ServiceCatalog__c> scs = servObj.getServiceCatalog(selectedType,selectedCategory,selectedSubCategory); 
            if(scs.isEmpty()){
                result.put('status', 'error');
                result.put('message', 'No Active Service Catalog Found. You Cannaot Change Record Type');
                return result;
            }
            result = obj.convertToComplaint(recordID,scs[0], selectedAccount, selectedUnit,selectedType,description,origin); 
        }
        else if(recordId.getSobjectType() == Case.getSobjectType() && (selectedSubCategory == BFM_SERVICE_REQUEST || selectedSubCategory == COMMON_AREA_SERVICE_REQUEST)){
            BFMServiceRequestHandler obj = BFMServiceRequestHandler.getInstance();
            List<ServiceCatalog__c> scs = servObj.getServiceCatalog(selectedType,selectedCategory,selectedSubCategory);
            if(scs.isEmpty()){
                result.put('status', 'error');
                result.put('message', 'No Active Service Catalog Found. You Cannaot Change Record Type'); 
                return result;
            }
            result = obj.convertToBFMServiceRequest(recordID,scs[0], selectedAccount, selectedUnit,selectedType,description,origin);   
        }
        return result;
        
    }
    
    @AuraEnabled
    public static Map<String, String> createCaseRecord(
        Id recordId,
        String selectedType,
        String selectedCategory,
        String selectedSubCategory,
        String accountId,
        String unitId,
        String description,
        String origin,
        Boolean stopEmailsToCustomer
    ) {
        
        Map<String, String> result = new Map<String, String>();
        ServiceCatalogService servObj = ServiceCatalogService.getInstance();
        SalesOrderService objSalesOrderService = SalesOrderService.getInstance();
        PostSalePaymentDeferalCaseHandler obj = PostSalePaymentDeferalCaseHandler.getInstance();
        BFMServiceRequestHandler objBFM = BFMServiceRequestHandler.getInstance();
        DefaultUnitCaseHandler objDefaultUnitCaseHandler = DefaultUnitCaseHandler.getInstance();
        ResaleServiceRequestHandler resaleObj = ResaleServiceRequestHandler.getInstance();
        AcknowledgmentReceiptSRHandler ackObj = AcknowledgmentReceiptSRHandler.getInstance();//Pranav
        PaymentDueDateUpdateSRHandler pmtDuDtdObj = PaymentDueDateUpdateSRHandler.getInstance();//Pranav
        ChequeReplacementRequestCaseHandler objChequeReplacementRequestCaseHandler = ChequeReplacementRequestCaseHandler.getInstance();
        ChequeWithdrawalRequestCaseHandler objChequeWithdrawalRequestCaseHandler = ChequeWithdrawalRequestCaseHandler.getInstance();
        ThirdPartyFormSRHandler thFormObj = ThirdPartyFormSRHandler.getInstance();//Pranav
        PaymentSRHandler pymntSrObj = PaymentSRHandler.getInstance();//Pranav
        LPFWaiverRequestCaseHandler objLPFWaiverRequestCaseHandler = LPFWaiverRequestCaseHandler.getInstance();
        SOARequestCaseHandler objSOARequestCaseHandler = SOARequestCaseHandler.getInstance();
        ProofofPaymentSharedSRHandler popShareSrObj = ProofofPaymentSharedSRHandler.getInstance();//Pranav
        BankAccDetailInquirySRHandler bnkAccDtlSrObj = BankAccDetailInquirySRHandler.getInstance();//Pranav
        GeneralEnquirySRHandler generalEnquiryObj = GeneralEnquirySRHandler.getInstance();
        KYCUpdateRequestSRHandler objKYCUpdateRequestSRHandler = KYCUpdateRequestSRHandler.getInstance();
        SalesOperationSRHandler objSalesOperationSRHandler = SalesOperationSRHandler.getInstance();
        TawtheeqEnrollmentSRHandler objTawtheeqEnrollmentSRHandler = TawtheeqEnrollmentSRHandler.getInstance();
        CRMComplaintRequestHandler complaintRequestObj = CRMComplaintRequestHandler.getInstance();
        
        Case newCase;
        try {
            if (String.isNotBlank(recordId) && recordId.getSobjectType() == Salesorder__c.getSobjectType()){
                if(selectedType == SERVICE_REQUEST && selectedCategory == FINANCIAL_PAYMENT_SERVICE_CATEGORY && selectedSubCategory == POST_SALE_PAYMENT_DEFERRAL) {
                    List<ServiceCatalog__c> scs = servObj.getServiceCatalog(selectedType, selectedCategory, selectedSubCategory); 
                    newCase = obj.createCaseRecord(objSalesOrderService.getSalesOrdersById(recordId), scs[0], accountId, unitId, selectedType, description, origin, stopEmailsToCustomer);  
                } 
                else if (selectedType == SERVICE_REQUEST && selectedCategory == BFM_SERVICE_CATEGORY && selectedSubCategory == BFM_SERVICE_REQUEST) {     
                    List<ServiceCatalog__c> scs = servObj.getServiceCatalog(selectedType, selectedCategory, selectedSubCategory);
                    newCase = objBFM.createCaseRecord(objSalesOrderService.getSalesOrdersById(recordId), scs[0], accountId, unitId,selectedType, description, origin, null, stopEmailsToCustomer);
                } 
                else if (selectedType == SERVICE_REQUEST && selectedCategory == COMMUNITY_SERVICE_REQUEST && selectedSubCategory == COMMON_AREA_SERVICE_REQUEST) {     
                    List<ServiceCatalog__c> scs = servObj.getServiceCatalog(selectedType, selectedCategory, selectedSubCategory);
                    newCase = objBFM.createCaseRecord(objSalesOrderService.getSalesOrdersById(recordId), scs[0], accountId, unitId,selectedType, description, origin, null, stopEmailsToCustomer);
                } 
                
                else if (selectedType == SERVICE_REQUEST && selectedCategory == RESALE_CATEGORY && selectedSubCategory == RESALE_SUB_CATEGORY) {
                    List<ServiceCatalog__c> scs = servObj.getServiceCatalog(selectedType, selectedCategory, selectedSubCategory);
                    newCase = resaleObj.createCaseRecord(objSalesOrderService.getSalesOrdersById(recordId), scs[0], accountId, unitId, selectedType, description, origin, stopEmailsToCustomer);
                    System.debug('newCase'+newCase);
                }           
                else if(selectedType == SERVICE_REQUEST && selectedCategory == FINANCIAL_PAYMENT_SERVICE_CATEGORY && selectedSubCategory == DEFAULT_CUSTOMER){
                    List<ServiceCatalog__c> scs = servObj.getServiceCatalog(selectedType, selectedCategory, selectedSubCategory);
                    newCase = objDefaultUnitCaseHandler.createCaseRecord(objSalesOrderService.getSalesOrdersById(recordId), scs[0], accountId, unitId, null, selectedType, description, origin, stopEmailsToCustomer);
                    if(newCase != null){
                        //objDefaultUnitCaseHandler.createFirstTask(new List<Case>{newCase}); 
                    }     
                } else if (selectedType == SERVICE_REQUEST && selectedCategory == FINANCIAL_PAYMENT_SERVICE_CATEGORY && selectedSubCategory == ACKNOWLEDGEMENT_RECEIPT_SUB_CATEGORY) { //Pranav                   
                    List<ServiceCatalog__c> scs = servObj.getServiceCatalog(selectedType, selectedCategory, selectedSubCategory);
                    newCase = ackObj.createCaseRecord(objSalesOrderService.getSalesOrdersById(recordId), scs[0], accountId, unitId, selectedType, description, origin, stopEmailsToCustomer);                   
                } 
                else if (selectedType == SERVICE_REQUEST && selectedCategory == FINANCIAL_PAYMENT_SERVICE_CATEGORY && selectedSubCategory == PAYMENT_DUE_DATE_UPDATE_SUB_CATEGORY) { //Pranav
                    List<ServiceCatalog__c> scs = servObj.getServiceCatalog(selectedType, selectedCategory, selectedSubCategory);
                    newCase = pmtDuDtdObj.createCaseRecord(objSalesOrderService.getSalesOrdersById(recordId), scs[0], accountId, unitId, selectedType, description, origin, stopEmailsToCustomer);    
                }
                else if (selectedType == SERVICE_REQUEST && selectedCategory == FINANCIAL_PAYMENT_SERVICE_CATEGORY && selectedSubCategory == THIRD_PARTY_FORM_SUB_CATEGORY) {   //Pranav
                    List<ServiceCatalog__c> scs = servObj.getServiceCatalog(selectedType, selectedCategory, selectedSubCategory);
                    newCase = thFormObj.createCaseRecord(objSalesOrderService.getSalesOrdersById(recordId), scs[0], accountId, unitId, selectedType, description, origin, stopEmailsToCustomer);    
                }
                else if (selectedType == SERVICE_REQUEST && selectedCategory == FINANCIAL_PAYMENT_SERVICE_CATEGORY && selectedSubCategory == PAYMENT_SR_SUB_CATEGORY) {   //Pranav
                    List<ServiceCatalog__c> scs = servObj.getServiceCatalog(selectedType, selectedCategory, selectedSubCategory);
                    newCase = pymntSrObj.createCaseRecord(objSalesOrderService.getSalesOrdersById(recordId), scs[0], accountId, unitId, selectedType, description, origin, stopEmailsToCustomer);    
                }
                else if(selectedType == SERVICE_REQUEST && selectedCategory == FINANCIAL_PAYMENT_SERVICE_CATEGORY && selectedSubCategory == CHEQUE_REPLACEMENT_REQUEST){
                    List<ServiceCatalog__c> scs = servObj.getServiceCatalog(selectedType, selectedCategory, selectedSubCategory);
                    newCase = objChequeReplacementRequestCaseHandler.createCaseRecord(objSalesOrderService.getSalesOrdersById(recordId), scs[0], accountId, unitId, selectedType, description, origin, stopEmailsToCustomer);
                }
                else if(selectedType == SERVICE_REQUEST && selectedCategory == FINANCIAL_PAYMENT_SERVICE_CATEGORY && selectedSubCategory == CHEQUE_WITHDRAWAL_REQUEST){
                    List<ServiceCatalog__c> scs = servObj.getServiceCatalog(selectedType, selectedCategory, selectedSubCategory);
                    newCase = objChequeWithdrawalRequestCaseHandler.createCaseRecord(objSalesOrderService.getSalesOrdersById(recordId), scs[0], accountId, unitId, selectedType, description, origin, stopEmailsToCustomer);
                }
                else if (selectedType == SERVICE_REQUEST && selectedCategory == FINANCIAL_PAYMENT_SERVICE_CATEGORY && selectedSubCategory == LPF_WAIVER_REQUEST) {
                    List<ServiceCatalog__c> scs = servObj.getServiceCatalog(selectedType, selectedCategory, selectedSubCategory);
                    newCase = objLPFWaiverRequestCaseHandler.createCaseRecord(objSalesOrderService.getSalesOrdersById(recordId), scs[0], accountId, unitId, selectedType, description, origin, stopEmailsToCustomer);    
                }
                else if (selectedType == SERVICE_REQUEST && selectedCategory == FINANCIAL_PAYMENT_SERVICE_CATEGORY && selectedSubCategory == SOA_REQUEST) {
                    List<ServiceCatalog__c> scs = servObj.getServiceCatalog(selectedType, selectedCategory, selectedSubCategory);
                    newCase = objSOARequestCaseHandler.createCaseRecord(objSalesOrderService.getSalesOrdersById(recordId), scs[0], accountId, unitId, selectedType, description, origin, stopEmailsToCustomer);    
                }
                else if (selectedType == SERVICE_REQUEST && selectedCategory == FINANCIAL_PAYMENT_SERVICE_CATEGORY && selectedSubCategory == POPSHARE_SR_SUB_CATEGORY) {   //Pranav
                    List<ServiceCatalog__c> scs = servObj.getServiceCatalog(selectedType, selectedCategory, selectedSubCategory);
                    newCase = popShareSrObj.createCaseRecord(objSalesOrderService.getSalesOrdersById(recordId), scs[0], accountId, unitId, selectedType, description, origin, stopEmailsToCustomer);    
                }
                else if (selectedType == SERVICE_REQUEST && selectedCategory == FINANCIAL_PAYMENT_SERVICE_CATEGORY && selectedSubCategory == BANK_ACC_DTAIL_SUB_CATEGORY) {   //Pranav
                    List<ServiceCatalog__c> scs = servObj.getServiceCatalog(selectedType, selectedCategory, selectedSubCategory);
                    newCase = bnkAccDtlSrObj.createCaseRecord(objSalesOrderService.getSalesOrdersById(recordId), scs[0], accountId, unitId, selectedType, description, origin, stopEmailsToCustomer); 
                }
                else if(selectedType == SERVICE_REQUEST && selectedCategory == FINANCIAL_PAYMENT_SERVICE_CATEGORY && selectedSubCategory == GENERAL_PAYMENT_ENQUIRY_SUB_CATEGORY){ //Samiksha
                    List<ServiceCatalog__c> scs = servObj.getServiceCatalog(selectedType, selectedCategory, selectedSubCategory);                    
                    newCase = generalEnquiryObj.createCaseRecord(objSalesOrderService.getSalesOrdersById(recordId), scs[0], accountId, unitId, selectedType,description, origin, stopEmailsToCustomer); 
                }
                else if(selectedType == SERVICE_REQUEST && selectedCategory == GENERAL_ENQUIRY_CATEGORY){
                    List<ServiceCatalog__c> scs = servObj.getServiceCatalog(selectedType, selectedCategory, selectedSubCategory);
                    newCase = generalEnquiryObj.createCaseRecord(objSalesOrderService.getSalesOrdersById(recordId), scs[0], accountId, unitId, selectedType,description, origin, stopEmailsToCustomer); 
                }
                 else if(selectedType == SERVICE_REQUEST && selectedCategory == HANDOVER_SERVICES_REQUEST_CATEGORY){
                    List<ServiceCatalog__c> scs = servObj.getServiceCatalog(selectedType, selectedCategory, selectedSubCategory);
                    newCase = generalEnquiryObj.createCaseRecord(objSalesOrderService.getSalesOrdersById(recordId), scs[0], accountId, unitId, selectedType,description, origin, stopEmailsToCustomer); 
                }
                else if(selectedType == SERVICE_REQUEST && selectedCategory == SPECIAL_SERVICES_REQUEST_CATEGORY){
                    List<ServiceCatalog__c> scs = servObj.getServiceCatalog(selectedType, selectedCategory, selectedSubCategory);
                    newCase = generalEnquiryObj.createCaseRecord(objSalesOrderService.getSalesOrdersById(recordId), scs[0], accountId, unitId, selectedType,description, origin, stopEmailsToCustomer); 
                }
                 else if(selectedType == COMPLAINT_REQUEST_TYPE){
                    List<ServiceCatalog__c> scs = servObj.getServiceCatalog(selectedType, selectedCategory, selectedSubCategory);
                    newCase = complaintRequestObj.createCaseRecord(objSalesOrderService.getSalesOrdersById(recordId), scs[0], accountId, unitId, selectedType,description, origin, stopEmailsToCustomer); 
                }
                else if(selectedType == SERVICE_REQUEST && selectedCategory == SALES_OPERATION_CATEGORY){
                    List<ServiceCatalog__c> scs = servObj.getServiceCatalog(selectedType, selectedCategory, selectedSubCategory);
                    newCase = objSalesOperationSRHandler.createCaseRecord(objSalesOrderService.getSalesOrdersById(recordId), scs[0], accountId, unitId, selectedType,description, origin, stopEmailsToCustomer); 
                }
                else if(selectedType == SERVICE_REQUEST && selectedCategory == CUSTOMER_SERVICE_REQUEST_CATEGORY && selectedSubCategory == KYC_UPDATE_REQUEST){
                    List<ServiceCatalog__c> scs = servObj.getServiceCatalog(selectedType, selectedCategory, selectedSubCategory);
                    newCase = objKYCUpdateRequestSRHandler.createCaseRecord(objSalesOrderService.getSalesOrdersById(recordId), scs[0], accountId, unitId, selectedType,description, origin, stopEmailsToCustomer); 
                }
                else if(selectedType == SERVICE_REQUEST && selectedCategory == CRM_REQUESTS_CATEGORY && selectedSubCategory == TAWTHEEQ_ENROLLMENT_SUB_CATEGORY) {
                    List<ServiceCatalog__c> scs = servObj.getServiceCatalog(selectedType, selectedCategory, selectedSubCategory); 
                    newCase = objTawtheeqEnrollmentSRHandler.createCaseRecord(objSalesOrderService.getSalesOrdersById(recordId), scs[0], accountId, unitId, null, selectedType, description, origin, stopEmailsToCustomer);  
                }
            }
            else if (String.isNotBlank(recordId) && recordId.getSobjectType() == CommonArea__c.getSobjectType() && selectedType == SERVICE_REQUEST && selectedCategory == COMMUNITY_SERVICE_REQUEST && selectedSubCategory == COMMON_AREA_SERVICE_REQUEST){
                List<ServiceCatalog__c> scs = servObj.getServiceCatalog(selectedType, selectedCategory, selectedSubCategory);
                newCase = objBFM.createCaseRecord(null, scs[0], accountId, unitId,selectedType, description, origin, recordId, stopEmailsToCustomer);
            }
            else if (recordId == null) { // triggered from homepage
                List<ServiceCatalog__c> scs = servObj.getServiceCatalog(selectedType, selectedCategory, selectedSubCategory);
                
                if (selectedSubCategory == POST_SALE_PAYMENT_DEFERRAL) {
                    newCase = obj.createCaseRecord(null, scs[0], accountId, unitId, selectedType, description, origin, stopEmailsToCustomer);
                } 
                else if (selectedSubCategory == BFM_SERVICE_REQUEST) {
                    newCase = objBFM.createCaseRecord(null, scs[0], accountId, unitId, selectedType, description, origin, null, stopEmailsToCustomer);
                }
                 else if(selectedType == COMPLAINT_REQUEST_TYPE){
                  //  List<ServiceCatalog__c> scs = servObj.getServiceCatalog(selectedType, selectedCategory, selectedSubCategory);
                    newCase = complaintRequestObj.createCaseRecord(null, scs[0], accountId, unitId, selectedType,description, origin, stopEmailsToCustomer); 
                }
                else if (selectedSubCategory == COMMON_AREA_SERVICE_REQUEST) {
                    newCase = objBFM.createCaseRecord(null, scs[0], accountId, unitId, selectedType, description, origin, null, stopEmailsToCustomer);
                }
                else if(selectedSubCategory == RESALE_SUB_CATEGORY){
                    newCase = resaleObj.createCaseRecord(null, scs[0], accountId, unitId, selectedType, description, origin, stopEmailsToCustomer);                   
                }
                else if(selectedType == SERVICE_REQUEST && selectedCategory == GENERAL_ENQUIRY_CATEGORY){
                    newCase = generalEnquiryObj.createCaseRecord(null, scs[0], accountId, unitId, selectedType, description, origin, stopEmailsToCustomer);
                }
                else if(selectedType == SERVICE_REQUEST && selectedCategory == SALES_OPERATION_CATEGORY){
                    newCase = objSalesOperationSRHandler.createCaseRecord(null, scs[0], accountId, unitId, selectedType, description, origin, stopEmailsToCustomer);
                }
                else if(selectedType == SERVICE_REQUEST && selectedCategory == CUSTOMER_SERVICE_REQUEST_CATEGORY && selectedSubCategory == KYC_UPDATE_REQUEST){
                    newCase = objKYCUpdateRequestSRHandler.createCaseRecord(null, scs[0], accountId, unitId, selectedType, description, origin, stopEmailsToCustomer); 
                }
                else if(selectedType == SERVICE_REQUEST && selectedCategory == CRM_REQUESTS_CATEGORY && selectedSubCategory == TAWTHEEQ_ENROLLMENT_SUB_CATEGORY) {
                    newCase = objTawtheeqEnrollmentSRHandler.createCaseRecord(null, scs[0], accountId, unitId, null, selectedType, description, origin, stopEmailsToCustomer);  
                }
                    else if(selectedType == SERVICE_REQUEST && selectedCategory == BROKER_MANAGEMENT_REQUEST_CATEGORY && selectedSubCategory == BROKER_ENQUIRY_SUB_CATEGORY) {
                    newCase = BrokerGeneralSRHandler.getInstance().createCaseRecord(null, scs[0], accountId, unitId, selectedType, description, origin, stopEmailsToCustomer);
                }
            }
            
            if (newCase != null) {
                result.put('status', 'success');
                result.put('message', 'Case created successfully');
                result.put('caseId', newCase.Id);
            } else {
                result.put('status', 'error');
                result.put('message', 'Failed to create Case');
            }
        } catch (Exception ex) {
            system.debug(' in catch'+ ex.getMessage());
            result.put('status', 'error');
            result.put('message', 'Failed to create Case: ' + ex.getMessage());
            result.put('message', 'Failed to create Case: ' +ex.getMessage()+' '+ ex.getLineNumber());
        }
        System.debug('result'+result); 
        return result;
    }
    
    @AuraEnabled
    public static String sendToBFM(Id recordId){
        try {
            BFMServiceRequestHandler bfmObj = BFMServiceRequestHandler.getInstance();
            return bfmObj.handleSendToBFM(recordId);
        } catch (Exception e) {
            throw new AuraHandledException('Error: '+ e.getMessage()); 
        }
    }
    
    
    // send comments to BFM
    @AuraEnabled
    public static void submitCaseComment(Id caseId, String commentBody){
        try {
            BFMServiceRequestHandler bfmObj = BFMServiceRequestHandler.getInstance();
            bfmObj.handleSubmitCaseComment(caseId, commentBody);
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }
    
    //get type options
    @AuraEnabled(cacheable=true)
    public static Map<String,String> getTypes() {
        return Utility.getPicklistValues(ServiceCatalog__c.SObjectType, 'Type__c');
    }    
    
    // get category based on Type
    @AuraEnabled(cacheable=true)
    public static List<String> getCategories(String type,Id recordId) { 
        
        ServiceCatalogService objServiceCatalogService = ServiceCatalogService.getInstance();
        List<String> categoryList = new List<String>();
        String objectName;
        if(recordId != null){
            if (recordId.getSObjectType() == Account.SObjectType) {
                objectName = 'Account';
            } 
            else if (recordId.getSObjectType() == SalesOrder__c.SObjectType) {
                objectName = 'Sales Order';
            }
            else if(recordId.getSObjectType() == Unit__c.getSobjectType()){
                objectName = 'Unit';
            }
            else if(recordId.getSObjectType() == Community__c.getSobjectType()){  	
                objectName = 'Community';  
            }
        }
        Boolean isOperationUser = false;
        
        List<GroupMember> gmList = [SELECT Id FROM GroupMember WHERE UserOrGroupId = :UserInfo.getUserId() AND Group.Name = 'Operation Team'];
        if (!gmList.isEmpty()) {
            isOperationUser = true;
        }
        for (AggregateResult ar : objServiceCatalogService.getServiceCatalogCategories(type,objectName)) {
            
            //categoryList.add((String)ar.get('Category__c'));
            String category = (String) ar.get('Category__c');
            
            if (category == 'Sales Operation Service') {
                if (isOperationUser) {
                    categoryList.add(category);
                }
            } else {
                categoryList.add(category);
            }
        }
        return categoryList;
    }
    
    // get SubCategory based on Type and Category
    @AuraEnabled(cacheable=true) 
    public static List<String> getSubCategories(String type, String category,Id recordId) {
        ServiceCatalogService objServiceCatalogService = ServiceCatalogService.getInstance();
        List<String> subCategoryList = new List<String>();
        String objectName;
        if(recordId != null){
            if (recordId.getSObjectType() == Account.SObjectType) {
                objectName = 'Account';
            } 
            else if (recordId.getSObjectType() == SalesOrder__c.SObjectType) {
                objectName = 'Sales Order';
            }
            else if(recordId.getSObjectType() == Unit__c.getSobjectType()){
                objectName = 'Unit';
            }
            else if(recordId.getSObjectType() == Community__c.getSobjectType()){  	
                objectName = 'Community';  
            }
        }
        for (AggregateResult ar : objServiceCatalogService.getServiceCatalogSubCategories(type,category,objectName)) {
            subCategoryList.add((String)ar.get('SubCategory__c'));
        }
        return subCategoryList;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<ServiceCatalog__c> getSubCategoriesforSubmit(String subCategory){
        ServiceCatalogService objServiceCatalogService = ServiceCatalogService.getInstance();
        return objServiceCatalogService.getServiceCatalogBySubCategories(subCategory);
    }
    
    @AuraEnabled(cacheable=true)
    public static String fetchDefaultNoticeEmailTemplate(Id recordId){
        DefaultUnitCaseHandler objDefaultUnitCaseHandler = DefaultUnitCaseHandler.getInstance();
        return objDefaultUnitCaseHandler.fetchEmailTemplate(recordId);
    }
    
    @AuraEnabled
    public static String sendDefaultNoticeEmail(Id recordId,  List<Map<String,String>> fileList){
        DefaultUnitCaseHandler objDefaultUnitCaseHandler = DefaultUnitCaseHandler.getInstance();
        return objDefaultUnitCaseHandler.sendEmail(recordId, fileList);
    }
    
    @AuraEnabled
    public static void sendOriginalDocumentChecklist(List<String> selectedItems, String caseRecordId, String remarks) {
        DefaultUnitCaseHandler objDefaultUnitCaseHandler = DefaultUnitCaseHandler.getInstance();
        objDefaultUnitCaseHandler.sendEmailWithChecklist(selectedItems, caseRecordId, remarks);
    }
    
    @AuraEnabled(cacheable=true)
    public static String fetchRegistrationVerificationEmailTemplate(Id recordId){
        KYCUpdateRequestSRHandler objKYCUpdateRequestSRHandler = KYCUpdateRequestSRHandler.getInstance();
        return objKYCUpdateRequestSRHandler.fetchEmailTemplate(recordId);
    }
    
    
    @AuraEnabled
    public static String sendRegistrationVerificationEmail(Id recordId,  List<Map<String,String>> fileList){
        KYCUpdateRequestSRHandler objKYCUpdateRequestSRHandler = KYCUpdateRequestSRHandler.getInstance();
        return objKYCUpdateRequestSRHandler.sendEmail(recordId, fileList);
    }
    
    @AuraEnabled
    public static void reassignCase(Id caseId, Id newOwnerId) {
        if(caseId == null || newOwnerId == null){
            throw new AuraHandledException('Missing required parameters.');
        }
        
        // Update case owner
        Case cse = new Case(Id = caseId, OwnerId = newOwnerId);
        CaseService.getInstance().updateCase(cse);
        
        // Query related tasks
        //List<Task> tasks = [SELECT Id, OwnerId FROM Task WHERE WhatId = :caseId AND Status != 'Completed' Order By CreatedDate DESC LIMIT 1];
        ActivityService objActivityService = ActivityService.getInstance();
        List<Task> tasks = objActivityService.fetchLatestOpenTaskOnCase(caseId);
        
        for(Task t : tasks){
            t.OwnerId = newOwnerId;
        }
        if(!tasks.isEmpty()){
            //update tasks
            objActivityService.updateTasks(tasks);
        }
    }
    @AuraEnabled(cacheable=true)
    public static String getRelatedAccount(Id recordId) {
        Id accountId;
        if (recordId.getSObjectType() == Account.SObjectType) {
            accountId = recordId;
        }  
        if (recordId.getSObjectType() == SalesOrder__c.SObjectType) {
            SalesOrderService salesOrderObj = SalesOrderService.getInstance();
            SalesOrder__c so = salesOrderObj.getSalesOrdersById(recordId);
            if(so != null){
                accountId = so.Account__r.Id;
            }
        }
        return accountId;
    }
    
    @AuraEnabled(cacheable=true)  
    public static List<SalesOrder__c> getRelatedUnitsbyAccountId(Id recordId) {
        Id accountId;
        Id unitId;
        SalesOrderService salesOrderObj = SalesOrderService.getInstance();
        if (recordId.getSObjectType() == Account.SObjectType) {
            accountId = recordId;
        }  
        if (recordId.getSObjectType() == SalesOrder__c.SObjectType) {       
            SalesOrder__c so = salesOrderObj.getSalesOrdersById(recordId);
            if(so != null){
                accountId = so.Account__r.Id;
            }
        }
        List<SalesOrder__c> solist= salesOrderObj.getSalesOrdersByAccountIds(accountId);
        return solist;
    }
    
    
}