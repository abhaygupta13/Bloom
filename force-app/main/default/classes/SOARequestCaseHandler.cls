/*****************************************************************************************
Class       : SOARequestCaseHandler
Author      :  Jhilik
Description : 
test Class  : SOARequestCaseHandlerTest
Created Date: 29-Aug-2025
*****************************************************************************************/
public inherited sharing class SOARequestCaseHandler {
    private static SOARequestCaseHandler instance;
    private static final string SOA_REQUEST_RT { get { return 'SOARequest'; } }
    private static final string MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final string CHEQUE_WITHDRAWAL_REQUEST_TEMPLATE_ID { get { return 'ChequeReplacementRequestTemplateId'; } }
    private static final string CHEQUE_WITHDRAWAL_PDCs_READY_TEMPLATE_ID { get { return 'PDCsAreReadyTemplateId'; } } 
    private static final string MTD_NEW_SERVICE_REQUEST_ACKNOWLEDGEMENT_EMAIL_TEMPLATE_ID { get { return 'NewServiceRequestAssignmentId'; } }

    private SOARequestCaseHandler() {
    }

    public static SOARequestCaseHandler getInstance() { 
        if(instance == null) {
            instance = new SOARequestCaseHandler();
        }
        return instance;
    }

    public String validateEligibility(SalesOrder__c salesOrderObj, Case caseObj){
        String message;
        return message;
    }

    public Case createCaseRecord(SalesOrder__c salesOrderObj, ServiceCatalog__c sc, String accountId, String unitId, String selectedType, String description, String origin, Boolean stopEmailsToCustomer) {
        AccountService accService = AccountService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        String emailTemplateId = objMetadataService.getAppSettingTextValue(CHEQUE_WITHDRAWAL_REQUEST_TEMPLATE_ID);

        Case newCase = new Case();
        newCase.AccountId = salesOrderObj != null ? salesOrderObj.Account__c : accountId;
        newCase.RecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, sc.RecordTypeDevName__c);
        newCase.Unit__c = salesOrderObj != null ? salesOrderObj.Unit__c : unitId;
        newCase.Status = 'New';
        newCase.Origin = origin;
        newCase.ServiceCatalog__c = sc.Id;
        newCase.CaseType__c = selectedType;
        newCase.Description = description;
        
        if (salesOrderObj != null) {
            newCase.Subject = 'SOA Request-'+ salesOrderObj.Account__r.Name +'-'+ salesOrderObj.Unit__r.Name;
            newCase.ContactId = accService.getRelatedContact(salesOrderObj.Account__r.Id);
            //newCase.CustomerName__c = accService.getRelatedContactName(salesOrderObj.Account__r.Id);
            newCase.Sales_Order__c = salesOrderObj.Id;
            //newCase.RequesterContactNumber__c = salesOrderObj.Account__r.isPersonAccount ? salesOrderObj.Account__r.PersonMobilePhone : null;
        }
        newCase.StopEmailsToCustomer__c = stopEmailsToCustomer;
        System.debug('newCase :::::'+newCase);
        System.debug('newCase :::::'+newCase.Sales_Order__c);

        CaseService caseServiceObj = CaseService.getInstance();
        newCase = caseServiceObj.insertCase(newCase);
        createDocuments(new List<Case>{newCase}, newCase.Sales_Order__c);
        sendNewServiceRequestAssignmnmentEmailNotification(new List<Case>{newCase});
        
        return newCase; 
    } 

    public  Map<String, Object> validateCaseForNextReview(Case caseRecord) {
        CaseService caseServiceObj = CaseService.getInstance();
        Map<String, Object> response = new Map<String, Object>();
        response.put('status', 'success');
        response.put('message', 'Case has been updated successfully');

        if (caseRecord == null) {
            response.put('status', 'error');
            response.put('message', 'Invalid Case ID.');
            return response;
        }

        if(caseRecord.Step__c !='Final'){
            if(Integer.valueOf(caseRecord.Step__c) < 1){
               response.put('status', 'error');
               response.put('message', 'Invalid Case Step.');
               return response;
            }

            // if(Integer.valueOf(caseRecord.Step__c) == 1 && caseRecord.IssuesWithFinancialDocument__c == null) {
            //     response.put('status', 'error');
            //     response.put('message', 'Please select if there is any issue with Financial Document');
            //     return response;
            // }
        } else {
            if(caseRecord.IssuesWithFinancialDocument__c == null) {
                response.put('status', 'error');
                response.put('message', 'Please select if there is any issue with Financial Document');
                return response;
            }

            if(caseRecord.FinancialDocumentAvailableInSF__c == null) {
                response.put('status', 'error');
                response.put('message', 'Please confirm if financial document available in SF');
                return response;
            }

            if(caseRecord.FinancialDocumentAvailableInSF__c == 'Yes' && caseRecord.Finance_Document_Verified__c != 'Yes'){
                response.put('status', 'error');
                response.put('message', 'Please update if Financial Document is verified.');
                return response;
            }

            if(caseRecord.FinancialDocumentAvailableInSF__c == 'No' && caseRecord.DocumentUploadedFromSAP__c != 'Yes'){
                response.put('status', 'error');
                response.put('message', 'Please confirm if financial document uploaded from SAP');
                return response;
            }

            if(caseRecord.DocumentUploadedFromSAP__c == 'Yes' && caseRecord.Finance_Document_Verified__c != 'Yes'){
                response.put('status', 'error');
                response.put('message', 'Please update if Financial Document is verified.');
                return response;
            }

            if(String.isEmpty(caseRecord.FinanceDocumentsUploadedManually__c) || (caseRecord.DocumentUploadedFromSAP__c == 'Yes' && caseRecord.FinanceDocumentsUploadedManually__c == 'No')){
                response.put('status', 'error');
                response.put('message', 'Kindly confirm if finance documents uploaded manually');
                return response;
            }

            response.put('message', 'Case closed successfully.');
            if(caseRecord.FinanceDocumentsUploadedManually__c != 'Yes'){
                createDocuments(new List<Case>{caseRecord}, caseRecord.Sales_Order__c); 
                }
        }
        
        if (response.get('status') == 'error') {
            return response;
        }
        if(response.get('status') == 'success'){
            handleNextSteps(caseRecord); 
        }
        
        if(response.get('message') != 'Case closed successfully.'){
            response.put('message', 'Case moved to next review successfully.');    
        }
        response.put('status', 'success');   
        return response;
    }

    public  void handleNextSteps(Case caseRec){
        ServiceRequestTaskHandler obj = ServiceRequestTaskHandler.getInstance();
        obj.createNewAndCloseCurrentTask(new List<Case>{caseRec});
    }

    public void createDocuments(List<Case> listOfCases, Id salesOrderId){
        DocumentService objDocumentService = DocumentService.getInstance();
        String SOACVId;
        String paymentReceiptCVId;
        Map<Id, ContentVersion> contentVersionMap;
        if(salesOrderId != NULL) {
            SOACVId = DocumentGenerationPDFHandler.generateAndAttachPdf(salesOrderId, 'generateStatement');
            paymentReceiptCVId = DocumentGenerationPDFHandler.generateAndAttachPdf(salesOrderId, 'generateReceipt');
            System.debug('SOACVId ::::: '+ SOACVId);
            List<Id> contentVersionIdList = new List<Id>();
            if((SOACVId != NULL && SOACVId != '') || (paymentReceiptCVId != NULL && paymentReceiptCVId != '')){
                contentVersionIdList.add(SOACVId);
                contentVersionIdList.add(paymentReceiptCVId);
                contentVersionMap = new Map<Id,ContentVersion>([SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersionIdList]);
            }
        }
        
        List<DocumentType__c> caseDocTypeList = objDocumentService.getActiveDocTypesForRecordType('Case', SOA_REQUEST_RT);
        List<Document__c> documentList = new List<Document__c>();
        Map<String, Document__c> docMap = new Map<String, Document__c>();
        for (Document__c d : [SELECT Id, Document_Name__c, ContentDocumentId__c FROM Document__c WHERE Case__c = :listOfCases[0].Id]) {
            docMap.put(d.Document_Name__c, d);
        }

        for(Case caseObj :listOfCases){
            for(DocumentType__c objDocumentType :caseDocTypeList){
                if(objDocumentType.Type__c == 'Statement of Account' && contentVersionMap != NULL && contentVersionMap.get(SOACVId) != NULL){
                    Document__c doc = new Document__c(Case__c = caseObj.Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c, Content_Version_Id__c = SOACVId, ContentDocumentId__c = contentVersionMap.get(SOACVId).ContentDocumentId);
                    if(docMap != Null && docMap.containsKey(objDocumentType.Type__c)){
                        doc.Id = docMap.get(objDocumentType.Type__c).Id;
                    }
                    documentList.add(doc);
                } 
                // else if(objDocumentType.Type__c == 'Payment Receipt' && contentVersionMap != NULL && contentVersionMap.get(paymentReceiptCVId) != NULL){
                //     documentList.add(new Document__c(Case__c = caseObj.Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c, Content_Version_Id__c = SOACVId, ContentDocumentId__c = contentVersionMap.get(paymentReceiptCVId).ContentDocumentId));
                // } 
                // else {
                //     documentList.add(new Document__c(Case__c = caseObj.Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c));
                // }
            }
        }
        //objDocumentService.insertDocuments(documentList);
        upsert documentList;
    }

    
    
    public void sendNewServiceRequestAssignmnmentEmailNotification(List<Case> caseList){
        if(!caseList[0].StopEmailsToCustomer__c){
            MetadataService objMetadataService = MetadataService.getInstance();
            EmailService objEmailService = EmailService.getInstance();
            Id noReplyOWDId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
            List<Messaging.SingleEmailMessage> emailList = new list<Messaging.SingleEmailMessage>(); 
            Id emailTemplateId = objMetadataService.getAppSettingTextValue(MTD_NEW_SERVICE_REQUEST_ACKNOWLEDGEMENT_EMAIL_TEMPLATE_ID);
            Messaging.SingleEmailMessage email = objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(emailTemplateId, noReplyOWDId,  caseList[0].Id, caseList[0].ContactId, null,null,null);
            emailList.add(email);
            if(!test.isRunningTest()){
                objEmailService.sendEmail(emailList);  
            } 
        }
    }
    
    public Messaging.SingleEmailMessage sendClosureEmail(Id emailTemplateId, Id orgWideEmailAddressId, Id whatId, List<String> toEmailAddresses, List<String> ccEmailAddresses, List<String> bccEmailAddresses, List<Messaging.EmailFileAttachment> attachments){
        CaseService csService = CaseService.getInstance();
        Case cs = csService.getCaseById(whatId);
        EmailService emlService = EmailService.getInstance();
        //Id emailTemplateId;
        //MetadataService objMetadataService = MetadataService.getInstance();
        //emailTemplateId = objMetadataService.getAppSettingTextValue(SERVICE_REQUEST_CUSTOMER_CLOSURE_EMAIL_TEMPLATE_ID);
        Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(emailTemplateId, null, whatId);
        if(String.isNotBlank(orgWideEmailAddressId)){  mail.setOrgWideEmailAddressId(orgWideEmailAddressId); }
        if(toEmailAddresses != NULL && !toEmailAddresses.isEmpty() ){ mail.setToAddresses(toEmailAddresses); }
        if(ccEmailAddresses != NULL && !ccEmailAddresses.isEmpty() ){ mail.setCCAddresses(ccEmailAddresses); }
        if(bccEmailAddresses != NULL && !bccEmailAddresses.isEmpty() ){ mail.setBCCAddresses(bccEmailAddresses); }
        mail.Subject = mail.Subject.replace('{SR_Name}',cs.Subject);
        if(!test.isRunningTest()){
            mail.htmlBody = mail.htmlBody.replace('{SR_Subject_EN}',cs.ServiceCatalog__r.SubCategory__c).replace('{Sr_Name_EN}',cs.Subject)
            .replace('{SR_Subject_AR}',cs.ServiceCatalog__r.SubCategoryArabic__c).replace('{Sr_Name_AR}',cs.Subject)
            .replace('{CustomerName}',cs.Account_Name__c).replace('{CustomerNameAr}',cs.Account.NameinArabic__c);
        }
        mail.setSaveAsActivity(true);
        mail.setTreatTargetObjectAsRecipient(false);
        if(attachments != null)
        mail.setFileAttachments(attachments);
        
        if(test.isRunningTest()){
            return null;
        }
        return mail;
    }
}