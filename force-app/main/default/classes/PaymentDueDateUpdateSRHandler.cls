/*****************************************************************************************
Class       : PaymentDueDateUpdateHandler
Author      :  Pranav G
Description : 
test Class  :  
Created Date: 8/15/2025 
*****************************************************************************************/
public inherited sharing class PaymentDueDateUpdateSRHandler{
    private static final String MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final string PAYMENT_DUE_DATE_UPDATE_RT { get { return 'Payment_Due_Date_Update'; } }
    private static final string MTD_NEW_SERVICE_REQUEST_ACKNOWLEDGEMENT_EMAIL_TEMPLATE_ID { get { return 'NewServiceRequestAssignmentId'; } }
    private static final string SERVICE_REQUEST_CUSTOMER_CLOSURE_EMAIL_TEMPLATE_ID { get { return 'PaymentDueDateClosure'; } }
    private static boolean handleCaseClosure = true;

    private static PaymentDueDateUpdateSRHandler instance;

    public PaymentDueDateUpdateSRHandler() {

    }
    
    public static PaymentDueDateUpdateSRHandler getInstance() { 
        if(instance == null) {
            instance = new PaymentDueDateUpdateSRHandler();
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
        try {
    newCase.Payment_Due_Date__c = [
        SELECT Due_Date__c
        FROM InstallmentLines__c
        WHERE SalesOrder__c = :salesOrderObj.Id
        AND Due_Date__c > TODAY
        ORDER BY Due_Date__c ASC
        LIMIT 1
    ].Due_Date__c;
} catch (QueryException e) {
    newCase.Payment_Due_Date__c = null;
}
        newCase.StopEmailsToCustomer__c = stopEmailsToCustomer;
        CaseService caseServiceObj = CaseService.getInstance();
        newCase = caseServiceObj.insertCase(newCase);
        createUpdateDocument(new List<Case>{newcase},salesOrderObj.Id);
        
        return newCase; 
    }

    /*public void sendNewServiceRequestAssignmnmentEmailNotification(case newcase){
        if(!newcase.StopEmailsToCustomer__c){
            MetadataService objMetadataService = MetadataService.getInstance();
            EmailService objEmailService = EmailService.getInstance();
            Id noReplyOWDId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
            List<Messaging.SingleEmailMessage> emailList = new list<Messaging.SingleEmailMessage>(); 
            Id emailTemplateId = objMetadataService.getAppSettingTextValue(MTD_NEW_SERVICE_REQUEST_ACKNOWLEDGEMENT_EMAIL_TEMPLATE_ID);
            Messaging.SingleEmailMessage email = objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(emailTemplateId, noReplyOWDId,  newcase.Id, newcase.ContactId, null,null,null);
            emailList.add(email);
            if(!test.isRunningTest()){
                objEmailService.sendEmail(emailList);  
            } 
        }
    }*/

    public  void createFirstTask(List<Case> listOfCases) {
        ServiceRequestTaskHandler obj = ServiceRequestTaskHandler.getInstance();
        obj.createNewAndCloseCurrentTask(listOfCases); 
    }

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
                CaseService servObj = CaseService.getInstance();
                List<Case> caseClosurelist = servObj.getCaseByIds(new Set<Id>{caseRecord.id});
                if(caseClosureList[0].FinanceDocumentsUploadedManually__c != 'Yes')
                createUpdateDocument(new List<Case>{caseClosurelist[0]},caseClosurelist[0].Sales_Order__c);//Re-attachment documents on finance closure
               ServiceRequestTaskHandler.getInstance().createNewAndCloseCurrentTask(caseClosurelist);                            
        }               
        return response;
    }

    public Map<String, Object> checkRequiredFields(Case caseRecord) {
        Map<String, Object> response = new Map<String, Object>();


            if(caseRecord.Payment_Due_Date__c == Null || caseRecord.Finance_Document_Verified__c == Null){
                response.put('status', 'error');
                 response.put('message', 'Value in Payment Due Date & Finance Document Verified is required.');
                 return response;
            }
            if(caseRecord.Payment_Due_Date__c != Null && caseRecord.Finance_Document_Verified__c == 'Yes'){
                response.put('message', 'Case closed successfully.'); 
            }
        
            if(String.isEmpty(caseRecord.FinanceDocumentsUploadedManually__c)){
                response.put('status', 'error');
                response.put('message', 'Kindly confirm if finance documents uploaded manually');
                return response;
            }

            if(caseRecord.Finance_Document_Verified__c == 'No'){
                response.put('status', 'error');
                response.put('message', 'Finance documents must be verified.');
                return response;
            }
            
            response.put('message', 'Case closed successfully.');   
        
        response.put('status', 'success');
        return response;
    }


    public void createUpdateDocument(List<Case> listOfCases, Id salesOrderId){
        DocumentService objDocumentService = DocumentService.getInstance();
        List<DocumentType__c> caseDocTypeList = objDocumentService.getActiveDocTypesForRecordType('Case',PAYMENT_DUE_DATE_UPDATE_RT);
        List<Document__c> documentList = new List<Document__c>();
        List<Document__c> documentUpdateList = new List<Document__c>();
        Map<String, Document__c> docMap = new Map<String, Document__c>();
        for (Document__c d : [SELECT Id, Document_Name__c, ContentDocumentId__c FROM Document__c WHERE Case__c = :listOfCases[0].Id]) {
            docMap.put(d.Document_Name__c, d);
        }
        for(DocumentType__c objDocumentType :caseDocTypeList){
            if(salesOrderId != NULL) {
                if(objDocumentType.Type__c == 'SOA'){
                    String contentVersionId;
                    String contentDocumentId;
                    contentVersionId = DocumentGenerationPDFHandler.generateAndAttachPdf(salesOrderId, 'generateStatement');
                    if(contentVersionId != NULL && contentVersionId != ''){
                        contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: contentVersionId].ContentDocumentId;
                    }
                    if(docMap != Null && docMap.containsKey(objDocumentType.Type__c) && docMap.get(objDocumentType.Type__c).ContentDocumentId__c != Null){
                        documentUpdateList.add(new Document__c(Case__c = listOfCases[0].Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c, Content_Version_Id__c = contentVersionId, ContentDocumentId__c = contentDocumentId, id=docMap.get(objDocumentType.Type__c).Id));
                    }
                    else{
                        documentList.add(new Document__c(Case__c = listOfCases[0].Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c, Content_Version_Id__c = contentVersionId, ContentDocumentId__c = contentDocumentId));
                    }
                }
            }
        }
        if(!documentList.isEmpty())
        objDocumentService.insertDocuments(documentList);
        
        if(!documentUpdateList.isEmpty())
        objDocumentService.updateDocuments(documentUpdateList);  
    }

    public Messaging.SingleEmailMessage sendClosureEmail(Id orgWideEmailAddressId, Id whatId, List<String> toEmailAddresses, List<String> ccEmailAddresses, List<String> bccEmailAddresses, List<Messaging.EmailFileAttachment> attachments){
        CaseService csService = CaseService.getInstance();
        Case cs = csService.getCaseById(whatId);
        String dt = String.valueOf(cs.payment_due_date__c.day())+'/'+String.valueOf(cs.payment_due_date__c.month())+'/'+String.valueOf(cs.payment_due_date__c.year());
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
       if(!test.isRunningtest()){
            // mail.htmlBody = mail.htmlBody.replace('{CustomerName}',cs.Account_Name__c).replace('{ProjectName}',cs.Projectname__c)
            // .replace('{PaymentDueDate}',dt).replace('{CustomerNameAr}',cs.Account.NameinArabic__c)
            // .replace('{ProjectNameAr}',cs.Unit__r.Project__r.ProjectNameArabic__c).replace('{PaymentDueDateAR}',dt);
            mail.htmlBody = mail.htmlBody.replace('{CustomerName}',cs.Account_Name__c).replace('{Unit_No}',cs.Unit__r.Name)
            .replace('{Due_Date}',dt).replace('{CustomerNameAr}',cs.Account.NameinArabic__c)
            .replace('{Unit_No_Ar}',cs.Unit__r.Name).replace('{Due_Date_Ar}',dt);
        
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