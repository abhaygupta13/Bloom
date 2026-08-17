/*****************************************************************************************
Class       : TawtheeqEnrollmentSRHandler
Author      :  Jhilik
Description : 
test Class  : TawtheeqEnrollmentSRHandlerTest
Created Date: 23-June-2026
*****************************************************************************************/
public inherited sharing class TawtheeqEnrollmentSRHandler {
    private static TawtheeqEnrollmentSRHandler instance;
    private static final string TAWTHEEQ_ENROLLMENT_RT { get { return 'TawtheeqEnrollment'; } }
    private static final string MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final string FINANCE_QUEUE_ID { get { return 'FinanceQueueId'; } }
    
    public TawtheeqEnrollmentSRHandler() {
    }

    public static TawtheeqEnrollmentSRHandler getInstance() { 
        if(instance == null) {
            instance = new TawtheeqEnrollmentSRHandler();
        }
        return instance;
    }

    public void createFirstTask(List<Case> listOfCases) {
        ServiceRequestTaskHandler obj = ServiceRequestTaskHandler.getInstance();
        obj.createNewAndCloseCurrentTask(listOfCases);
    }

    public String validateEligibility(SalesOrder__c salesOrderObj, Case caseObj){
        String message;
        return message;
    }

    public Case createCaseRecord(SalesOrder__c salesOrderObj, ServiceCatalog__c sc, String accountId, String unitId, Handover__c hoRec, String selectedType, String description, String origin, Boolean stopEmailsToCustomer) {
        AccountService accService = AccountService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        HandoverService objHandoverService = HandoverService.getInstance();
        //String emailTemplateId = objMetadataService.getAppSettingTextValue(CHEQUE_WITHDRAWAL_REQUEST_TEMPLATE_ID);
        String financeQueueId = objMetadataService.getAppSettingTextValue(FINANCE_QUEUE_ID);

        Case newCase = new Case();
        newCase.AccountId = salesOrderObj != null ? salesOrderObj.Account__c : accountId;
        newCase.RecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, sc.RecordTypeDevName__c);
        newCase.Unit__c = salesOrderObj != null ? salesOrderObj.Unit__c : unitId;
        newCase.Status = 'New';
        newCase.Origin = origin;
        newCase.ServiceCatalog__c = sc.Id;
        newCase.CaseType__c = selectedType;
        newCase.Description = description;
        //newCase.OwnerId = financeQueueId;
        if (salesOrderObj != null) {
            newCase.Subject = 'Tawtheeq Enrollment Request -'+ salesOrderObj.Account__r.Name +'-'+ salesOrderObj.Unit__r.Name;
            newCase.ContactId = accService.getRelatedContact(salesOrderObj.Account__c);
            newCase.CustomerName__c = accService.getRelatedContactName(salesOrderObj.Account__c);
            newCase.Sales_Order__c = salesOrderObj.Id;
            newCase.RequesterContactNumber__c = salesOrderObj.Account__r.isPersonAccount ? salesOrderObj.Account__r.PersonMobilePhone : null;
        }
        newCase.StopEmailsToCustomer__c = stopEmailsToCustomer;
        System.debug('newCase.Unit__c ::::: '+ newCase.Unit__c);
        if(hoRec != NULL){
            newCase.Handover__c = hoRec.Id;
            newCase.PaymentReceived__c = hoRec.Property_Enrollment_Under_Tawtheeq__c ? 'Yes' : 'No';
            newCase.AmountReceived__c = hoRec.Property_Enrollment_Under_Tawtheeq_Accou__c;
            newCase.Step__c = '2';
        }
        else if(newCase.Unit__c != NULL){
            List<Handover__c> handoverList = objHandoverService.getHandoverByUnitId(newCase.Unit__c);
            if(handoverList != NULL && handoverList.size() > 0){
                newCase.Handover__c = handoverList[0].Id;
            }
        }
        CaseService caseServiceObj = CaseService.getInstance();
        newCase = caseServiceObj.insertCase(newCase);
        createDocuments(new List<Case>{newCase});
        //sendEmail(newCase.Id, emailTemplateId);
        //objTawtheeqEnrollmentSRHandler.validateCaseForNextReview(caseRec);
        return newCase; 
    }

    public Map<String, Object> validateCaseForNextReview(Case caseRecord) {
        CaseService caseServiceObj = CaseService.getInstance();
        DocumentService objDocumentService = DocumentService.getInstance();
        Map<String, Object> response = new Map<String, Object>();
        response.put('status', 'success');
        response.put('message', 'Case has been updated successfully');
        //List<Document__c> caseDocList = new List<Document__c>();

        if (caseRecord == null) {
            response.put('status', 'error');
            response.put('message', 'Invalid Case ID.');
            return response;
        }

        if(caseRecord.Step__c == '1') {
            List<Document__c> docList = objDocumentService.getCaseDocumentsWithAttachmentsByNames(caseRecord.Id, new List<String>{'Proof of Payment'});
            if(docList == NULL || docList.isEmpty()){
                response.put('status', 'error');
                response.put('message', 'Please upload Proof of Payment before moving to next step.');
                return response;
            }
        }
        else if(caseRecord.Step__c == '2') {
            if((caseRecord.AmountReceived__c == NULL) || (caseRecord.PaymentReceived__c != 'Yes')){
                response.put('status', 'error');
                response.put('message', 'Please update Amount Received and Payment Received fields before moving to next step.');
                return response;
            }
        }
        else if(caseRecord.Step__c == 'Final') {
            /* caseDocList = [SELECT Id, Name, DocumentType__c, Case__c, ContentDocumentId__c
                                                    FROM Document__c 
                                                    WHERE Case__c = :caseRecord.Id 
                                                    AND Document_Name__c = 'Tawtheeq Registration Confirmation' 
                                                    AND ContentDocumentId__c != NULL]; */

            List<Document__c> docList = objDocumentService.getCaseDocumentsWithAttachmentsByNames(caseRecord.Id, new List<String>{'Tawtheeq Registration Confirmation'});
            if(docList == NULL || docList.isEmpty()){
                response.put('status', 'error');
                response.put('message', 'Please upload Signed Tawtheeq Registration Confirmation document.');
                return response;
            }
            List<Document__c> relatedDocList = [SELECT Id, Name, DocumentType__c, Case__c, ContentDocumentId__c, Content_Version_Id__c
                                                    FROM Document__c 
                                                    WHERE (Salesorder__c = :caseRecord.Sales_Order__c OR Handover__c = :caseRecord.Handover__c)
                                                    AND Document_Name__c = 'Tawtheeq Registration Confirmation'];
            for(Document__c docRec : relatedDocList){
                docRec.ContentDocumentId__c = docList[0].ContentDocumentId__c;
                docRec.Content_Version_Id__c = docList[0].Content_Version_Id__c;
            }
            update relatedDocList;
        }
        
        if (response.get('status') == 'error') {
            return response;
        }
        if(response.get('status') == 'success'){
            /* if(caseRecord.Step__c == 'Final') {
                List<Document__c> docList = [SELECT Id, Name, DocumentType__c, Case__c, ContentDocumentId__c
                                                    FROM Document__c 
                                                    WHERE (Salesorder__c = :caseRecord.Sales_Order__c OR Handover__c = :caseRecord.Handover__c)
                                                    AND Document_Name__c = 'Tawtheeq Registration Confirmation' 
                                                    AND ContentDocumentId__c != NULL];
                for(Document__c docRec : docList){
                    docRec.ContentDocumentId__c = caseDocList[0].ContentDocumentId__c;
                }
                update docList;
            } */
            handleNextSteps(caseRecord); 
        }
        
        return response;
    }

    public void handleNextSteps(Case caseRec){
        ServiceRequestTaskHandler obj = ServiceRequestTaskHandler.getInstance();
        obj.createNewAndCloseCurrentTask(new List<Case>{caseRec});
    }

    public void updateCustomerDetails(Id contactId, String email, String mobile){
        Contact con = new Contact(Id = contactId, Email = email, MobilePhone = mobile);
        ContactService.getInstance().updateContactsWithoutTrigger(new List<Contact>{con});
    }

    public void createDocuments(List<Case> listOfCases){
        DocumentService objDocumentService = DocumentService.getInstance();
        String SOACVId;
        String paymentReceiptCVId;
        Map<Id, ContentVersion> contentVersionMap;

        List<DocumentType__c> caseDocTypeList = objDocumentService.getActiveDocTypesForRecordType('Case',TAWTHEEQ_ENROLLMENT_RT);
        List<Document__c> documentList = new List<Document__c>();
        for(Case caseObj :listOfCases){
            for(DocumentType__c objDocumentType :caseDocTypeList){
                documentList.add(new Document__c(Case__c = caseObj.Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c));
            }
        }
        objDocumentService.insertDocuments(documentList);   
    }

    /* public String fetchEmailTemplate(Id caseId){
        CaseService objCaseService = CaseService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        ContactService objContactService = ContactService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();

        Case caseRec = objCaseService.getCaseById(caseId);
        //String emailTemplateId = objMetadataService.getAppSettingTextValue(REGISTRATION_VERIFICATION_EMAIL_TEMPLATE_ID);
        String customerEmailId;
        //String emailBody;

        try{
            if(emailTemplateId != null){
                EmailTemplate emailTemplate = objEmailService.getEmailTemplateById(emailTemplateId);
                if(emailTemplate == null){
                    return 'Email template not found';
                }
                String emailBody = emailTemplate.HtmlValue;
                if(String.isNotBlank(caseId) && caseRec.AccountId != null){
                    if(caseRec.Account.RecordType.DeveloperName == 'PersonAccount'){
                        if(caseRec.Account.PersonEmail != null){
                            customerEmailId = caseRec.Account.PersonEmail;
                        }
                        else{
                            return 'Customer Email not found';
                        }
                    }
                    else{
                        List<Contact> conList = objContactService.getPrimaryContactByAccountId(caseRec.AccountId, true);
                        if(conList.isEmpty()) {
                            return 'Primary contact not found';
                        }
                        customerEmailId = conList.isEmpty() ? '': conList[0].Email;
                    }
                }
                
                Messaging.SingleEmailMessage results = Messaging.renderStoredEmailTemplate(emailTemplateId, null, caseId);
                emailBody = results.getHtmlBody();
                //fetch the email html body
                return getBody(caseRec, emailBody, customerEmailId);

            } else {
                return 'Email template not found';
            }
            
        }catch(System.exception ex){
            throw new AuraHandledException(ex.getMessage());
        } 
          return 'Email template not found';
    }

    public String sendEmail(Id caseId,  List<Map<String,String>> fileList){
        
            CaseService objCaseService = CaseService.getInstance();
            ContactService objContactService = ContactService.getInstance();
            MetadataService objMetadataService = MetadataService.getInstance();
            EmailService objEmailService = EmailService.getInstance();
            String customerEmailId;

        try{
            Case caseRec = objCaseService.getCaseById(caseId);
            String emailTemplateId = objMetadataService.getAppSettingTextValue(REGISTRATION_VERIFICATION_EMAIL_TEMPLATE_ID);
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
            Messaging.SingleEmailMessage result = Messaging.renderStoredEmailTemplate(emailTemplateId, null, caseId);
            String emailBody = result.getHtmlBody();
            String emailSubject = emailTemplate.Subject;
            
            //fetch the email html body
            emailBody = getBody(caseRec, emailBody, customerEmailId);
            emailSubject = getBody(caseRec, emailSubject, customerEmailId);
            // send email if customer id is not blank
            if(String.isNotBlank(customerEmailId)){

                Messaging.SingleEmailMessage email = objEmailService.getSingleEmailMessage(new List<String>{customerEmailId}, caseId, null, emailSubject, emailBody, noReplyBloomSalesOWDId);

                List<ContentDocumentLink> contentDocLink = [SELECT ContentDocumentId, LinkedEntityId, ContentDocument.ContentAssetId FROM ContentDocumentLink WHERE LinkedEntityId =: emailTemplateId];

                List<ContentVersion> contentVersionList = [SELECT Id, ContentDocumentId, Title, FileExtension, VersionNumber, VersionData FROM ContentVersion WHERE ContentDocumentId =: contentDocLink[0].ContentDocumentId ORDER BY VersionNumber DESC LIMIT 1];

                List<Messaging.EmailFileAttachment> attachmentList = new List<Messaging.EmailFileAttachment>();
                for(ContentVersion cv: contentVersionList){
                    Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                    if(cv.VersionData != null && cv.Title != null){
                        attachment.setFileName('KnowYourCustomer.pdf');  // Set the file name
                        attachment.setBody(cv.VersionData);  // Set the PDF content as body (Blob)
                        attachment.setContentType('application/pdf');
                        attachment.setInline(false);
                        attachmentList.add(attachment);
                    }
                }
                email.setFileAttachments(attachmentList);

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
            throw new AuraHandledException(ex.getMessage());
        }
    }

    private static String getBody(Case caseRec, String emailBody, String customerEmail){
        Date d = Date.today(); 
        String formattedDate = DateTime.newInstance(d.year(),d.month(),d.day()).format('dd/MM/YYYY');

        emailBody = emailBody.replace('[Customer_Name]', caseRec.Account.Name != null ? caseRec.Account.Name : '')
            .replace('[Customer_NameArabic]', caseRec.Account.NameinArabic__c != null ? caseRec.Account.NameinArabic__c : '')
            .replace('[App_Name]', caseRec.AppRegistration__c != null ? caseRec.AppRegistration__r.Name : '');
            
        return emailBody;
    } */
}