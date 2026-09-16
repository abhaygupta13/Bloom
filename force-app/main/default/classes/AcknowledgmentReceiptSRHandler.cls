/*****************************************************************************************
Class       : AcknowledgmentReceiptHandler
Author      :  Pranav G
Description : 
test Class  :  
Created Date: 8/13/2025 
*****************************************************************************************/
public inherited sharing class AcknowledgmentReceiptSRHandler{
    
    private static final String MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final string ACKNOWLEDGEMENT_RECEIPT_RT { get { return 'Acknowledgment_Receipt'; } }
    private static final string MTD_NEW_SERVICE_REQUEST_ACKNOWLEDGEMENT_EMAIL_TEMPLATE_ID { get { return 'NewServiceRequestAssignmentId'; } }
    private static final string SERVICE_REQUEST_CUSTOMER_CLOSURE_EMAIL_TEMPLATE_ID { get { return 'NewServiceRequestClosureID'; } }
    private static boolean handleCaseClosure = true;

    private static AcknowledgmentReceiptSRHandler instance;

    public AcknowledgmentReceiptSRHandler() {

    }
    
    public static AcknowledgmentReceiptSRHandler getInstance() { 
        if(instance == null) {
            instance = new AcknowledgmentReceiptSRHandler();
        }
        return instance;
    }

    public String validateEligibility(SalesOrder__c salesOrderObj){
        String message;
        if(salesOrderObj != null && salesOrderObj.Status__c != 'Sold'){
            message = 'This unit is not eligible for the selected service request';
        }
        else if(salesOrderObj !=null && salesOrderObj.IsDefaulted__c == true){
            message = 'A Acknowldgement receipt request cannot be created for a defaulted unit';
        }
        
        return message;
    }

    public Case createCaseRecord(
        SalesOrder__c salesOrderObj,
        ServiceCatalog__c sc,
        String accountId,
        String unitId,
        String selectedType,
        String description,
        String origin,
        Boolean stopEmailsToCustomer
    ) {
        AccountService accService = AccountService.getInstance();
        
        Case newCase = new Case();
        
        newCase.AccountId = (salesOrderObj != null) ? salesOrderObj.Account__c : accountId;
        newCase.RecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, sc.RecordTypeDevName__c);
        newCase.Unit__c = (salesOrderObj != null) ? salesOrderObj.Unit__c : unitId;
        
        if (salesOrderObj != null) {
            newCase.Subject = sc.SubCategory__c + '-' + salesOrderObj.Unit__r.Name;
            newCase.ContactId = accService.getRelatedContact(salesOrderObj.Account__r.Id);
            newCase.Sales_Order__c = salesOrderObj.Id;
        } 
        
        newCase.Status = 'New';
        newCase.Origin = origin;
        newCase.Description = description;
        newCase.ServiceCatalog__c = sc.Id;
        newCase.CaseType__c = selectedType;
        newCase.StopEmailsToCustomer__c = stopEmailsToCustomer;
        
        CaseService caseServiceObj = CaseService.getInstance();
        newCase = caseServiceObj.insertCase(newCase);
        createUpdateDocument(new List<Case>{newcase},salesOrderObj.Id);
        return newCase; 
    } 

    /*public void sendNewServiceRequestAssignmnmentEmailNotification(Case newCase){
        if(!newcase.StopEmailsToCustomer__c){
            MetadataService objMetadataService = MetadataService.getInstance();
            EmailService objEmailService = EmailService.getInstance();
            Id noReplyOWDId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
            List<Messaging.SingleEmailMessage> emailList = new list<Messaging.SingleEmailMessage>(); 
            Id emailTemplateId = objMetadataService.getAppSettingTextValue(MTD_NEW_SERVICE_REQUEST_ACKNOWLEDGEMENT_EMAIL_TEMPLATE_ID);
            Messaging.SingleEmailMessage email = objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(emailTemplateId, noReplyOWDId,  newCase.Id, newCase.ContactId, null,null,null);
                emailList.add(email);
            if(!test.isRunningTest()){
                objEmailService.sendEmail(emailList);  
            } 
        }
    }*/

    public  Map<String, Object> validateCaseForNextReview(Case caseRecord) {
        Map<String, Object> response = new Map<String, Object>();
        if (caseRecord == null) {
            response.put('status', 'error');
            response.put('message', 'Invalid Case ID.');
            return response;
        }
        if(caseRecord.Step__c !='Final' 
           && Integer.valueOf(caseRecord.Step__c) <1){
               response.put('status', 'error');
               response.put('message', 'Invalid Case Step.');
               return response;
        }
        
        response = checkRequiredFields(caseRecord);
        if (response.get('status') == 'error') {
            return response;
        }
        else{
            if(caseRecord.Step__c =='Final'){//For finance closure
                CaseService servObj = CaseService.getInstance();
                List<Case> caseClosureList = servObj.getCaseByIds(new Set<Id>{caseRecord.id});
                if(caseClosureList[0].FinanceDocumentsUploadedManually__c != 'Yes')
                createUpdateDocument(new List<Case>{caseClosureList[0]},caseClosureList[0].Sales_Order__c);//Re-attachment documents on finance closure
                
                createFirstTask(caseClosureList);
            }
        }
        if(caseRecord.Step__c !='Final'){// For CRM to Finance assignment
            if(response.get('status')=='success' && handleCaseClosure){
                createFirstTask(new list<Case>{caseRecord});
            }
        }
        
        return response;
    }

    public Map<String, Object> checkRequiredFields(Case caseRecord) {
        Map<String, Object> response = new Map<String, Object>();
        
        if(caseRecord.Step__c == '1'){
            if (String.isEmpty(caseRecord.Payment_Booked__c) || String.isEmpty(caseRecord.Finance_Document_Verified__c)) {
                   response.put('status', 'error');
                   response.put('message', 'The case is not valid to move to the next step. Please select whether the payment has been booked or not along with document verification check.');
                   return response;
            }
            if(caseRecord.Payment_Booked__c == 'Yes'){
                if(String.isEmpty(caseRecord.FinanceDocumentsUploadedManually__c)){
                    response.put('status', 'error');
                    response.put('message', 'Kindly confirm if finance documents uploaded manually');
                    return response;
                }
                if(caseRecord.Finance_Document_Verified__c == 'Yes'){
                    ServiceRequestTaskHandler obj = ServiceRequestTaskHandler.getInstance();
                    CaseService servObj = CaseService.getInstance();
                    ServiceCatalogService servCatObj = ServiceCatalogService.getInstance();
                    List<Case> crmCaseClosureList = servObj.getCaseByIds(new Set<Id>{caseRecord.id});
                    Map<Id,ServiceAction__c> caseCurrentAction = servCatObj.getCurrentCaseServiceAction(crmCaseClosureList);
                    
                    if(crmCaseClosureList[0].FinanceDocumentsUploadedManually__c != 'Yes')
                    createUpdateDocument(new List<Case>{crmCaseClosureList[0]},crmCaseClosureList[0].Sales_Order__c);//Re-attachment documents on finance closure

                    obj.processCasesAndHandleNextActions(crmCaseClosureList,new Map<Id, ServiceAction__c>(),caseCurrentAction);
                    response.put('message', 'Case closed successfully.'); 
                    handleCaseClosure = false;                
                }
            }
        }
        if(caseRecord.Step__c == 'Final'){
            if(caseRecord.Payment_Booked__c != 'Yes' || caseRecord.Finance_document_verified__c != 'Yes'){
                response.put('status', 'error');
                response.put('message', 'The case is not valid to move to the next step. Payment Booked should be marked as Yes along with verification of Finance Documents.');
                return response;
            }
            if(String.isEmpty(caseRecord.FinanceDocumentsUploadedManually__c)){
                response.put('status', 'error');
                response.put('message', 'Kindly confirm if finance documents uploaded manually');
                return response;
            }
            response.put('message', 'Case closed successfully.');   
        }
        else if(response.get('message') != 'Case closed successfully.'){
            response.put('message', 'Case moved to next review successfully.');    
        }
        response.put('status', 'success');
        return response;
    }

    public  void createFirstTask(List<Case> listOfCases) {
        ServiceRequestTaskHandler obj = ServiceRequestTaskHandler.getInstance();
        obj.createNewAndCloseCurrentTask(listOfCases); 
    }

    public void createUpdateDocument(List<Case> listOfCases, Id salesOrderId){
        DocumentService objDocumentService = DocumentService.getInstance();
        List<DocumentType__c> caseDocTypeList = objDocumentService.getActiveDocTypesForRecordType('Case',ACKNOWLEDGEMENT_RECEIPT_RT);
        List<Document__c> documentList = new List<Document__c>();
        List<Document__c> documentUpdateList = new List<Document__c>();
        Map<String, Document__c> docMap = new Map<String, Document__c>();
        for (Document__c d : [SELECT Id, Document_Name__c, ContentDocumentId__c FROM Document__c WHERE Case__c = :listOfCases[0].Id]){
            docMap.put(d.Document_Name__c, d);
        }
        for(DocumentType__c objDocumentType :caseDocTypeList){            
            List<String> generatedDocData;
            if(salesOrderId != NULL) {
                if(objDocumentType.Type__c == 'SOA'){
                    generatedDocData = generateContentDoc('generateStatement',salesOrderId);
                    if(docMap != Null && docMap.containsKey(objDocumentType.Type__c) && docMap.get(objDocumentType.Type__c).ContentDocumentId__c != Null){
                        documentUpdateList.add(new Document__c(Case__c = listOfCases[0].Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c, Content_Version_Id__c = generatedDocData[0], ContentDocumentId__c = generatedDocData[1], id=docMap.get(objDocumentType.Type__c).Id));
                    }
                    else{
                        documentList.add(new Document__c(Case__c = listOfCases[0].Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c, Content_Version_Id__c = generatedDocData[0], ContentDocumentId__c = generatedDocData[1]));
                    }
                } else {
                    generatedDocData = generateContentDoc('generateReceipt',salesOrderId);
                    if(docMap != Null && docMap.containsKey(objDocumentType.Type__c) && docMap.get(objDocumentType.Type__c).ContentDocumentId__c != Null){
                        documentUpdateList.add(new Document__c(Case__c = listOfCases[0].Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c, Content_Version_Id__c = generatedDocData[0], ContentDocumentId__c = generatedDocData[1], id=docMap.get(objDocumentType.Type__c).Id));
                    }
                    else{
                        documentList.add(new Document__c(Case__c = listOfCases[0].Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c, Content_Version_Id__c = generatedDocData[0], ContentDocumentId__c = generatedDocData[1]));
                    }
                }
            }
        }
        if(!documentList.isEmpty())
        objDocumentService.insertDocuments(documentList);
        
        if(!documentUpdateList.isEmpty())
        objDocumentService.updateDocuments(documentUpdateList);
    }

    public List<string> generateContentDoc(String docType, String soId){
        List<String> docData = new list<String>();
        String contentVersionId;
        String contentDocumentId;
        contentVersionId = DocumentGenerationPDFHandler.generateAndAttachPdf(soId, docType);
        docData.add(contentVersionId);
        System.debug('contentVersionId ::::: '+ contentVersionId);
        if(contentVersionId != NULL && contentVersionId != ''){
            contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: contentVersionId].ContentDocumentId;
            docData.add(contentDocumentId);
        }
        return docData;
    }

    public Messaging.SingleEmailMessage sendClosureEmail(Id orgWideEmailAddressId, Id whatId, List<String> toEmailAddresses, List<String> ccEmailAddresses, List<String> bccEmailAddresses, List<Messaging.EmailFileAttachment> attachments){
        CaseService csService = CaseService.getInstance();
        Case cs = csService.getCaseById(whatId);
        EmailService emlService = EmailService.getInstance();
        Id emailTemplateId;
        MetadataService objMetadataService = MetadataService.getInstance();
        emailTemplateId = objMetadataService.getAppSettingTextValue(SERVICE_REQUEST_CUSTOMER_CLOSURE_EMAIL_TEMPLATE_ID);
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
    }
}