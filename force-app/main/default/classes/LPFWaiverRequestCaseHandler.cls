/*****************************************************************************************
Class       : LPFWaiverRequestCaseHandler
Author      :  Jhilik
Description : 
test Class  : LPFWaiverRequestCaseHandlerTest
Created Date: 29-Aug-2025
*****************************************************************************************/
public inherited sharing class LPFWaiverRequestCaseHandler {
    private static LPFWaiverRequestCaseHandler instance;
    private static final string LPF_WAIVER_REQUEST_RT { get { return 'LPFWaiverRequest'; } }
    private static final string MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final string CHEQUE_WITHDRAWAL_REQUEST_TEMPLATE_ID { get { return 'ChequeReplacementRequestTemplateId'; } }
    private static final string CHEQUE_WITHDRAWAL_PDCs_READY_TEMPLATE_ID { get { return 'PDCsAreReadyTemplateId'; } } 
    private static final string MTD_NEW_SERVICE_REQUEST_ACKNOWLEDGEMENT_EMAIL_TEMPLATE_ID { get { return 'NewServiceRequestAssignmentId'; } }

    private LPFWaiverRequestCaseHandler() {
    }

    public static LPFWaiverRequestCaseHandler getInstance() { 
        if(instance == null) {
            instance = new LPFWaiverRequestCaseHandler();
        }
        return instance;
    }

    public  void createFirstTask(List<Case> listOfCases) {
        System.debug('::::: Inside createFirstTask ::::: ');
        ServiceRequestTaskHandler obj = ServiceRequestTaskHandler.getInstance();
        obj.createNewAndCloseCurrentTask(listOfCases);
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
            newCase.Subject = 'LPF Waiver Request-'+ salesOrderObj.Account__r.Name +'-'+ salesOrderObj.Unit__r.Name;
            newCase.ContactId = accService.getRelatedContact(salesOrderObj.Account__r.Id);
            newCase.Sales_Order__c = salesOrderObj.Id;
        }
        newCase.StopEmailsToCustomer__c = stopEmailsToCustomer;
        System.debug('newCase :::::'+newCase);
        System.debug('newCase :::::'+newCase.Sales_Order__c);

        CaseService caseServiceObj = CaseService.getInstance();
        newCase = caseServiceObj.insertCase(newCase);
        createDocuments(new List<Case>{newCase}, newCase.Sales_Order__c);
        
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

        if(caseRecord.Step__c =='1'){
             if(caseRecord.LPFWaiverRequestApprovalStatus__c == null){
                response.put('status', 'error');
                response.put('message', 'Please check if LPF Waiver Request was Approved.');
                return response;
            }else if(caseRecord.LPFWaiverRequestApprovalStatus__c == 'Rejected'){
                autoCreateDocument(new List<Case>{caseRecord},caseRecord.Sales_Order__c);
                forceCloseCurrentTaks(caseRecord);
                caseRecord.step__c = 'Final';
                handleNextSteps(caseRecord);
                response.put('message', 'Case closed successfully.'); 
                return response;
            }
            else if(caseRecord.LPFWaiverRequestApprovalStatus__c == 'Approved'){
                if(!caseRecord.LPFCompoundedLPFOnOtherCharges__c){
                    response = validateDocs(caseRecord, new Set<String>{'Memo'});
                    if(response.get('status') == 'error'){
                        return response;
                    } 
                }
                handleNextSteps(caseRecord); 
            }

        }


        if(caseRecord.Step__c == 'Final'){
            if(String.isEmpty(caseRecord.Finance_document_verified__c) || caseRecord.Finance_document_verified__c == 'No'){
                response.put('status', 'error');
                response.put('message', 'Kindly verify the Finance documents.');
                return response;
            }
            else{
                if(String.isEmpty(caseRecord.FinanceDocumentsUploadedManually__c)){
                    response.put('status', 'error');
                    response.put('message', 'Kindly confirm if finance documents uploaded manually');
                    return response;
                }

                 if(caseRecord.FinanceDocumentsUploadedManually__c != 'Yes')
                 autoCreateDocument(new List<Case>{caseRecord},caseRecord.Sales_Order__c);
                if(!test.isRunningTest())
                handleNextSteps(caseRecord);
                response.put('message', 'Case closed successfully.'); 
                return response;
            }
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
            SOACVId = SalesSOAPDFController.generateAndAttachPdf(salesOrderId);
            paymentReceiptCVId = SalesReceiptController.generateAndAttachPdf(salesOrderId);
            System.debug('SOACVId ::::: '+ SOACVId);
            List<Id> contentVersionIdList = new List<Id>();
            if((SOACVId != NULL && SOACVId != '') || (paymentReceiptCVId != NULL && paymentReceiptCVId != '')){
                contentVersionIdList.add(SOACVId);
                contentVersionIdList.add(paymentReceiptCVId);
                contentVersionMap = new Map<Id,ContentVersion>([SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersionIdList]);
            }
        }
        
        List<DocumentType__c> caseDocTypeList = objDocumentService.getActiveDocTypesForRecordType('Case', LPF_WAIVER_REQUEST_RT);
        List<Document__c> documentList = new List<Document__c>();
        for(Case caseObj :listOfCases){
            for(DocumentType__c objDocumentType :caseDocTypeList){
                if(objDocumentType.Type__c == 'Statement of Account' && contentVersionMap != NULL && contentVersionMap.get(SOACVId) != NULL){
                    documentList.add(new Document__c(Case__c = caseObj.Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c, Content_Version_Id__c = SOACVId, ContentDocumentId__c = contentVersionMap.get(SOACVId).ContentDocumentId));
                } 
                else if(objDocumentType.Type__c == 'Payment Receipt' && contentVersionMap != NULL && contentVersionMap.get(paymentReceiptCVId) != NULL){
                    documentList.add(new Document__c(Case__c = caseObj.Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c, Content_Version_Id__c = SOACVId, ContentDocumentId__c = contentVersionMap.get(paymentReceiptCVId).ContentDocumentId));
                } 
                else {
                    documentList.add(new Document__c(Case__c = caseObj.Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c));
                }
            }
        }
        objDocumentService.insertDocuments(documentList);   
    }

    /*private String getBody(Case caseRec, String emailBody, String customerEmail){
        Date d = Date.today(); 
        String formattedDate = DateTime.newInstance(d.year(),d.month(),d.day()).format('dd/MM/YYYY');

        emailBody = emailBody.replace('[Customer_Name]', caseRec.Account.Name != null ? caseRec.Account.Name : '')
            .replace('[Customer_NameArabic]', caseRec.Account.NameinArabic__c != null ? caseRec.Account.NameinArabic__c : '')
            .replace('[Project_Name]', caseRec.Unit__r.Project__r.Name != null ? caseRec.Unit__r.Project__r.Name : '')
            .replace('[Project_Name_Arabic]', caseRec.Unit__r.Project__r.ProjectNameArabic__c != null ? caseRec.Unit__r.Project__r.ProjectNameArabic__c : '')
            .replace('[Unit_Name]', caseRec.Unit__r.Name != null ? caseRec.Unit__r.Name : '')
            .replace('[Due_Amount]', caseRec.TotalInstalmentDue__c != null ? String.valueOf(caseRec.TotalInstalmentDue__c) : '')
            .replace('[Service_Request_Name]', caseRec.ServiceCatalog__r.SubCategory__c != null ? caseRec.ServiceCatalog__r.SubCategory__c : '')
            .replace('[Service_Request_Name_Arabic]', caseRec.ServiceCatalog__r.SubCategoryArabic__c != null ? caseRec.ServiceCatalog__r.SubCategoryArabic__c : '');
                
        return emailBody;
    }

    public String sendEmail(Id caseId, Id emailTemplateId){
        
            CaseService objCaseService = CaseService.getInstance();
            ContactService objContactService = ContactService.getInstance();
            MetadataService objMetadataService = MetadataService.getInstance();
            EmailService objEmailService = EmailService.getInstance();
            String customerEmailId;

        try{
            Case caseRec = objCaseService.getCaseById(caseId);
            //String emailTemplateId = objMetadataService.getAppSettingTextValue(CHEQUE_WITHDRAWAL_REQUEST_TEMPLATE_ID);
            System.debug('emailTemplateId ::::: '+emailTemplateId);
            Id noReplyBloomSalesOWDId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);

            // fetch the customer id for email send
            if(String.isNotBlank(caseId) && caseRec.AccountId != null){
                if(caseRec.Account.RecordType.DeveloperName == 'PersonAccount'){
                    customerEmailId = caseRec.Account.PersonEmail;
                }
                else{
                    List<Contact> conList = objContactService.getPrimaryContactByAccountId(caseRec.AccountId, true);
                    if(conList.isEmpty()) {
                        return 'Primary contact not found';
                    }
                    customerEmailId = conList.isEmpty() ? '': conList[0].Email;
                }
            }

            EmailTemplate emailTemplate = objEmailService.getEmailTemplateById(emailTemplateId);
            Messaging.SingleEmailMessage result = Messaging.renderStoredEmailTemplate(emailTemplateId, null, caseRec.Id);
            String emailSubject = emailTemplate.Subject;
            System.debug('emailSubject ::::: '+ emailSubject);
            String emailBody = result.getHtmlBody();
            //fetch the email html body
            emailBody = getBody(caseRec, emailBody, customerEmailId);
            emailSubject = getBody(caseRec, emailSubject, customerEmailId);

            // send email if customer id is not blank
            if(String.isNotBlank(customerEmailId)){

                Messaging.SingleEmailMessage email = objEmailService.getSingleEmailMessage(new List<String>{customerEmailId}, caseRec.Id, null, emailSubject, emailBody, noReplyBloomSalesOWDId);
                Messaging.SendEmailResult[] results = objEmailService.sendEmail(new List<Messaging.SingleEmailMessage>{email});
                if (results != null && results.size() > 0 && results[0].isSuccess()){
                    return 'true';
                }else{
                    return 'false';
                }
            }
            else{
                return 'Customer email not found';
            }

            
        }catch(Exception ex){
            System.debug('ex-->>'+ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }
    }*/

    

    /*public void sendNewServiceRequestAssignmnmentEmailNotification(List<Case> caseList){
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
    }*/

    public static Map<String, Object> validateDocs(Case caseRecord, Set<String> documents){
        Map<String, Object> response = new Map<String, Object>();
        DocumentService docService = DocumentService.getInstance();
        for(Document__c doc : docService.getCaseDocumentsByName(caseRecord.id,documents)){
            if(doc.ContentDocumentId__c == Null){
                response.put('status', 'error');
                response.put('message', 'Please upload '+ doc.Document_Name__c +' before proceeding to submit for next review.');
                return response; 
            }
        }
        return response;
    }

    public void forceCloseCurrentTaks( Case caseRecord){
        ServiceCatalogService servObj = ServiceCatalogService.getInstance();
        ActivityService objActivityService = ActivityService.getInstance();
        Map<Id,ServiceAction__c> caseCatalogVsCurrentAction = servObj.getCurrentCaseServiceAction(new List<Case>{caseRecord});
        ServiceAction__c currentAction = caseCatalogVsCurrentAction.get(caseRecord.ServiceCatalog__c);
        List<Task> currentTaskList = objActivityService.fetchOpenTaskFromServiceAction(currentAction,caseRecord.id);
        
        if(!currentTaskList.isEmpty()){
            objActivityService.closeTasks(currentTaskList);
        }

    }

    public void autoCreateDocument(List<Case> listOfCases, Id salesOrderId){
        DocumentService objDocumentService = DocumentService.getInstance();
        List<Document__c> documentUpdateList = new List<Document__c>();
        for(Document__c doc : objDocumentService.getCaseDocumentsByName(listOfCases[0].id,new Set<String>{'Statement of Account'})){
            String contentVersionId;
            String contentDocumentId;
            String docType = doc.Document_Name__c == 'Statement of Account' ? 'generateStatement' : 'generateReceipt';
            contentVersionId = DocumentGenerationPDFHandler.generateAndAttachPdf(salesOrderId, docType);
            System.debug('version>>'+contentVersionId);
            if(contentVersionId != NULL && contentVersionId != ''){
                contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: contentVersionId].ContentDocumentId;
                System.debug('document>>'+contentDocumentId);
            }
            documentUpdateList.add(new Document__c(Content_Version_Id__c = contentVersionId, ContentDocumentId__c = contentDocumentId, id=doc.Id));
        }
        
        if(!documentUpdateList.isEmpty())
            update documentUpdateList;
        
    }
    
    /*public Messaging.SingleEmailMessage sendClosureEmail(Id emailTemplateId, Id orgWideEmailAddressId, Id whatId, List<String> toEmailAddresses, List<String> ccEmailAddresses, List<String> bccEmailAddresses, List<Messaging.EmailFileAttachment> attachments){
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
        mail.setFileAttachments(attachments);
        if(test.isRunningTest()){
            return null;
        }
        return mail;
    }*/
}