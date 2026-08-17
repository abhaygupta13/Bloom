/*****************************************************************************************
Class       : KYCUpdateRequestSRHandler
Author      :  Jhilik
Description : 
test Class  : KYCUpdateRequestSRHandlerTest
Created Date: 31-Oct-2025
*****************************************************************************************/
public inherited sharing class KYCUpdateRequestSRHandler {
    private static KYCUpdateRequestSRHandler instance;
    private static final string KYC_UPDATE_REQUEST_RT { get { return 'KYCUpdateRequest'; } }
    private static final string MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final string REGISTRATION_VERIFICATION_EMAIL_TEMPLATE_ID { get { return 'RegistrationVerificationEmailTemplateId'; } }

    public KYCUpdateRequestSRHandler() {

    }

    public static KYCUpdateRequestSRHandler getInstance() { 
        if(instance == null) {
            instance = new KYCUpdateRequestSRHandler();
        }
        return instance;
    }

    public  void createFirstTask(List<Case> listOfCases) {
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
        //String emailTemplateId = objMetadataService.getAppSettingTextValue(CHEQUE_WITHDRAWAL_REQUEST_TEMPLATE_ID);

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
            newCase.Subject = 'KYC Update Request-'+ salesOrderObj.Account__r.Name +'-'+ salesOrderObj.Unit__r.Name;
            newCase.ContactId = accService.getRelatedContact(salesOrderObj.Account__c);
            newCase.CustomerName__c = accService.getRelatedContactName(salesOrderObj.Account__c);
            newCase.Sales_Order__c = salesOrderObj.Id;
            newCase.RequesterContactNumber__c = salesOrderObj.Account__r.isPersonAccount ? salesOrderObj.Account__r.PersonMobilePhone : null;
        }
        newCase.StopEmailsToCustomer__c = stopEmailsToCustomer;

        CaseService caseServiceObj = CaseService.getInstance();
        newCase = caseServiceObj.insertCase(newCase);
        createDocuments(new List<Case>{newCase});
        //sendEmail(newCase.Id, emailTemplateId);

        return newCase; 
    } 

    public Case createCaseRecordFromAppRegistrationTrigger(AppRegistration__c appRegRec, ServiceCatalog__c sc, String accountId, String selectedType, String description, String origin) {
        AccountService accService = AccountService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        //String emailTemplateId = objMetadataService.getAppSettingTextValue(CHEQUE_WITHDRAWAL_REQUEST_TEMPLATE_ID);
        Case newCase = new Case();
        newCase.RecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, sc.RecordTypeDevName__c);
        newCase.Status = 'New';
        newCase.Origin = origin;
        newCase.ServiceCatalog__c = sc.Id;
        newCase.CaseType__c = selectedType;
        newCase.Description = description;
        newCase.PhoneNumber__c = appRegRec.MobilePhone__c;
        newCase.Email_Address__c = appRegRec.Email__c;
        newCase.AppRegistration__c = appRegRec.Id;

        if(accountId != null){
            newCase.AccountId = accountId;
            newCase.CustomerName__c = accService.getRelatedContactName(accountId);     
            newCase.Subject = 'KYC Update Request-'+ newCase.CustomerName__c;//salesOrderObj.Account__r.Name +'-'+ salesOrderObj.Unit__r.Name;
            newCase.ContactId = accService.getRelatedContact(accountId);
        } else {
            newCase.Subject = 'KYC Update Request-'+ appRegRec.Name;
        }

        CaseService caseServiceObj = CaseService.getInstance();
        newCase = caseServiceObj.insertCase(newCase);
        createDocuments(new List<Case>{newCase});
        //sendEmail(newCase.Id, emailTemplateId);

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

        /* if(Integer.valueOf(caseRecord.Step__c) < 1){
            response.put('status', 'error');
            response.put('message', 'Invalid Case Step.');
            return response;
        } */

        if(caseRecord.Step__c == '1') {
            List<Document__c> docList = [SELECT Id, Name, DocumentType__c, Case__c 
                                                    FROM Document__c 
                                                    WHERE Case__c = :caseRecord.Id 
                                                    AND Document_Name__c = 'Signed KYC' 
                                                    AND ContentDocumentId__c != NULL];

            if(docList == null || docList.size() == 0) {
                response.put('status', 'error');
                response.put('message', 'Please upload Signed KYC document.');
                return response;
            }
            if((caseRecord.Email_Address__c == NULL || caseRecord.Email_Address__c == '') && (caseRecord.PhoneNumber__c == NULL || caseRecord.PhoneNumber__c == '')){
                response.put('status', 'error');
                response.put('message', 'Please update Email Address/Phone Number');
                return response;
            }
        }
        if(caseRecord.Step__c =='Final'){
            if(caseRecord.ApprovalStatus__c == NULL || (caseRecord.ApprovalStatus__c != 'Approved' && caseRecord.ApprovalStatus__c != 'Rejected')){
                response.put('status', 'error');
                response.put('message', 'Please update Approval Status.');
                return response;
            } else if(caseRecord.AppRegistration__c != NULL) {
                AppRegistrationService objAppRegistrationService = AppRegistrationService.getInstance();
                List<AppRegistration__c> appRegList = objAppRegistrationService.getAppRegistrationById(caseRecord.AppRegistration__c);

                if(caseRecord.ApprovalStatus__c == 'Approved') {
                    if(caseRecord.Email_Address__c != NULL || appRegList[0].Email__c != NULL){
                        //String email = appRegList[0].Email__c == NULL ? caseRecord.Email_Address__c : appRegList[0].Email__c;
                        String email = appRegList[0].Email__c;
                        String mobile = appRegList[0].MobileCountryCode__c != null ? appRegList[0].MobileCountryCode__c + appRegList[0].MobilePhone__c : appRegList[0].MobilePhone__c;
                        try {
                            updateAppRegistration(caseRecord.AppRegistration__c, caseRecord.ApprovalStatus__c, email);
                            updateCustomerDetails(caseRecord.ContactId, email, mobile);
                        } catch(Exception ex){
                            //throw new AuraHandledException(ex.getMessage());
                            response.put('status', 'error');
                            response.put('message', ex.getMessage());
                            return response;
                        }
                    } else {
                        response.put('status', 'error');
                        response.put('message', 'Please enter Email Address.');
                        return response;
                    }
                } else if(caseRecord.ApprovalStatus__c == 'Rejected') {
                    updateAppRegistration(caseRecord.AppRegistration__c, caseRecord.ApprovalStatus__c, '');
                }
            }
        }
        
        if (response.get('status') == 'error') {
            return response;
        }
        if(response.get('status') == 'success'){
            handleNextSteps(caseRecord); 
        }
        
        return response;
    }

    public void handleNextSteps(Case caseRec){
        ServiceRequestTaskHandler obj = ServiceRequestTaskHandler.getInstance();
        obj.createNewAndCloseCurrentTask(new List<Case>{caseRec});
    }

    public void updateAppRegistration(Id appRegistrationId, String status, String email){
        AppRegistration__c appReg = new AppRegistration__c(Id = appRegistrationId, Status__c = status/*, Email__c = email*/);
        update appReg;
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

        List<DocumentType__c> caseDocTypeList = objDocumentService.getActiveDocTypesForRecordType('Case',KYC_UPDATE_REQUEST_RT);
        List<Document__c> documentList = new List<Document__c>();
        for(Case caseObj :listOfCases){
            for(DocumentType__c objDocumentType :caseDocTypeList){
                documentList.add(new Document__c(Case__c = caseObj.Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c));
            }
        }
        objDocumentService.insertDocuments(documentList);   
    }

    public String fetchEmailTemplate(Id caseId){
        CaseService objCaseService = CaseService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        ContactService objContactService = ContactService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();

        Case caseRec = objCaseService.getCaseById(caseId);
        String emailTemplateId = objMetadataService.getAppSettingTextValue(REGISTRATION_VERIFICATION_EMAIL_TEMPLATE_ID);
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
            if(String.isNotBlank(customerEmailId) && !caseRec.StopEmailsToCustomer__c){

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
                return 'Customer email not found OR Customer Notifications are stopped for this SR.';
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
    }
}