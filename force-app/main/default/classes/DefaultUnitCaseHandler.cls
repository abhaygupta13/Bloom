/*****************************************************************************************
Class       : DefaultUnitCaseHandler
Author      :  Jhilik
Description : 
test Class  : DefaultUnitCaseHandlerTest
Created Date: 2-Jul-2025
*****************************************************************************************/
public inherited sharing class DefaultUnitCaseHandler {
    private static DefaultUnitCaseHandler instance;
    private static final string DEFAULT_UNIT_RT { get { return 'DefaultUnit'; } }
    private static final string MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final string MTD_CFO_FINANCE_DIRECTOR_EMAIL_ADDRESS { get { return 'CFOAndFinanceDirectorEmailAddresses'; } }
    private static final string MTD_FINAL_COURT_JUDGEMENT_NOTIFICATION_EMAIL_TEMPLATE_ID { get { return 'FinalCourtJudgementNotificationTemplate'; } }
    private static final string DEFAULT_NOTICE_EMAIL_TEMPLATE_ID { get { return 'DefaultNoticeTemplateId'; } }
    private static final string MTD_COLLECTION_TEAM_RECEPIENT_LIST { get { return 'CollectionTeamMembersEmails'; } }
    private static final string MTD_COLLECTION_TEAM_EMAIL_ADDRESS { get { return 'CollectionTeamEmailAddress'; } }
    private static final string MTD_FINANCE_TEAM_RECEPIENT_LIST { get { return 'FinanceTeamMembersEmails'; } }
    private static final string MTD_OPERATION_TEAM_RECEPIENT_LIST { get { return 'OperationTeamMembersEmails'; } }
    private static final string MTD_GOVERNMENTRELATION_TEAM_RECEPIENT_LIST { get { return 'GovernmentRelationTeamMembersEmails'; } }
    private static final string MTD_BROKERMANAGEMENT_TEAM_RECEPIENT_LIST { get { return 'BrokerManagementTeamMembersEmails'; } }
    private static final string MTD_REQUEST_ORIGINAL_DOCUMENT_EMAIL_TEMPLATE_ID { get { return 'RequestOriginalDocumentsTemplateId'; } }

    private DefaultUnitCaseHandler() {
    }

    public static DefaultUnitCaseHandler getInstance() { 
        if(instance == null) {
            instance = new DefaultUnitCaseHandler();
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

    public Case createCaseRecord(SalesOrder__c salesOrderObj, ServiceCatalog__c sc, String accountId, String unitId, Handover__c hoRec, String selectedType, String description, String origin, Boolean stopEmailsToCustomer) {
        AccountService accService = AccountService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();

        Case newCase = new Case();
        newCase.AccountId = salesOrderObj != null ? salesOrderObj.Account__c : accountId;
        newCase.RecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, sc.RecordTypeDevName__c);
        newCase.Unit__c = salesOrderObj != null ? salesOrderObj.Unit__c : unitId;
        newCase.Status = 'New';
        newCase.Origin = origin;
        newCase.ServiceCatalog__c = sc.Id;
        newCase.CaseType__c = selectedType;
        newCase.Description = description;
        newCase.Project__c = salesOrderObj.Unit__r.Project__c;
        //newCase.OwnerId = collectionTeamId;
        newCase.CustomerDefaultStatus__c = 'Default Customer';
        //newCase.NumberOfDefaultNoticeRemindersSent__c = 1;
        newCase.Step__c = '0';
        //newCase.TotalInstalmentDue__c = pendingAmount;
        
        if(hoRec != NULL){
            newCase.Handover__c = hoRec.Id;
        } 
        else if(newCase.Unit__c != NULL){
            List<Handover__c> handoverList = HandoverService.getInstance().getHandoverByUnitId(newCase.Unit__c);
            if(handoverList != NULL && handoverList.size() > 0){
                newCase.Handover__c = handoverList[0].Id;
            }
        }

        if (salesOrderObj != null) {
            newCase.Subject = 'DefaultNotice-'+ salesOrderObj.Account__r.Name +'-'+ salesOrderObj.Unit__r.Name;
            newCase.ContactId = accService.getRelatedContact(salesOrderObj.Account__r.Id);
            newCase.CustomerName__c = accService.getRelatedContactName(salesOrderObj.Account__r.Id);
            newCase.Sales_Order__c = salesOrderObj.Id;
            newCase.RequesterContactNumber__c = salesOrderObj.Account__r.isPersonAccount ? salesOrderObj.Account__r.PersonMobilePhone : null;
        }

        Decimal pendingAmount = 0;
        Date oldestInstallmentDueDate = System.today();
        InstallmentLineService objInstallmentLineService = InstallmentLineService.getInstance();
        for(InstallmentLines__c installmentLineRec : objInstallmentLineService.getPastDueDatedInstallmentLinesBySalesOrderId(new Set<Id>{salesOrderObj.Id})){
            pendingAmount += installmentLineRec.PendingAmount__c;
            if(installmentLineRec.Due_Date__c < oldestInstallmentDueDate){
                oldestInstallmentDueDate = installmentLineRec.Due_Date__c;
            }
        }

        newCase.TotalInstalmentDue__c = pendingAmount;
        newCase.DefaultCustomerPaymentOverdueDate__c = oldestInstallmentDueDate;
        newCase.StopEmailsToCustomer__c = stopEmailsToCustomer;
        CaseService caseServiceObj = CaseService.getInstance();
        newCase = caseServiceObj.insertCase(newCase);

        updateDocumentsRecords(salesOrderObj.Id, newCase.Id);
        return newCase; 
    }

    /* public Case createCase(SalesOrder__c salesOrderObj, ServiceCatalog__c sc, Handover__c hoRec, String selectedType, String description, String origin) {
        AccountService accService = AccountService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();

        Case newCase = new Case();
        newCase.AccountId = salesOrderObj != null ? salesOrderObj.Account__c : hoRec.Account__c;
        newCase.RecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, sc.RecordTypeDevName__c);
        newCase.Unit__c = salesOrderObj != null ? salesOrderObj.Unit__c : hoRec.Unit__c;
        newCase.Status = 'New';
        newCase.Origin = origin;
        newCase.ServiceCatalog__c = sc.Id;
        newCase.CaseType__c = selectedType;
        newCase.Description = description;
        newCase.Handover__c = hoRec.Id;
        newCase.Project__c = salesOrderObj.Unit__r.Project__c;
        //newCase.OwnerId = collectionTeamId;
        newCase.CustomerDefaultStatus__c = 'Default Customer';
        //newCase.NumberOfDefaultNoticeRemindersSent__c = 1;
        newCase.Step__c = '0';
        //newCase.TotalInstalmentDue__c = pendingAmount;
        
        if (salesOrderObj != null) {
            newCase.Subject = 'DefaultNotice-'+ salesOrderObj.Account__r.Name +'-'+ salesOrderObj.Unit__r.Name;
            newCase.ContactId = accService.getRelatedContact(salesOrderObj.Account__r.Id);
            newCase.CustomerName__c = accService.getRelatedContactName(salesOrderObj.Account__r.Id);
            newCase.Sales_Order__c = salesOrderObj.Id;
            newCase.RequesterContactNumber__c = salesOrderObj.Account__r.isPersonAccount ? salesOrderObj.Account__r.PersonMobilePhone : null;
        }

        Decimal pendingAmount = 0;
        Date oldestInstallmentDueDate = System.today();
        InstallmentLineService objInstallmentLineService = InstallmentLineService.getInstance();
        for(InstallmentLines__c installmentLineRec : objInstallmentLineService.getPastDueDatedInstallmentLinesBySalesOrderId(new Set<Id>{salesOrderObj.Id})){
            pendingAmount += installmentLineRec.PendingAmount__c;
            if(installmentLineRec.Due_Date__c < oldestInstallmentDueDate){
                oldestInstallmentDueDate = installmentLineRec.Due_Date__c;
            }
        }

        newCase.TotalInstalmentDue__c = pendingAmount;
        newCase.DefaultCustomerPaymentOverdueDate__c = oldestInstallmentDueDate;
        
        return newCase; 
    } */

    public void updateDocumentsRecords(Id salesOrderId, Id caseRecId){
        DocumentService objDocumentService = DocumentService.getInstance();
        List<Document__c> documentListToUpdate = objDocumentService.getAllSalesOrderDocuments(new List<Id>{salesOrderId});
        for(Document__c docRec : documentListToUpdate){
            docRec.Case__c = caseRecId;   
        }
        //update documentListToUpdate;
        objDocumentService.updateDocuments(documentListToUpdate);
    }

    public void updateRelatedDocumentsRecords(List<Case> caseList){
        DocumentService objDocumentService = DocumentService.getInstance();
        Map<Id,Case> soIdToCaseMap = new Map<Id,Case>();
        for(Case caseRec : caseList){
            soIdToCaseMap.put(caseRec.Sales_Order__c, caseRec);
        }
        List<Document__c> documentListToUpdate = objDocumentService.getAllSalesOrderDocuments(new List<Id>(soIdToCaseMap.keySet()));
        for(Document__c docRec : documentListToUpdate){
            docRec.Case__c = soIdToCaseMap.get(docRec.SalesOrder__c).Id;   
        }
        //update documentListToUpdate;
        objDocumentService.updateDocuments(documentListToUpdate);
    }

    public  Map<String, Object> validateCaseForNextReview(Case caseRecord) {
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

            if(Integer.valueOf(caseRecord.Step__c) == 3 && (caseRecord.DefaultNoticeSentBy__c == null || caseRecord.DefaultNoticeSentTime__c == null)){
                response.put('status', 'error');
                response.put('message', 'Please send Default Notice to Customer.');
                return response;
            }

            if(Integer.valueOf(caseRecord.Step__c) == 7){
                if(caseRecord.RefundAmount__c > 0 && !caseRecord.StopEmailsToCustomer__c){
                    EmailService objEmailService = EmailService.getInstance();
                    MetadataService objMetadataService = MetadataService.getInstance();
                    
                    String cfoFinanceDirectorEmailAddresses = objMetadataService.getAppSettingTextValue(MTD_CFO_FINANCE_DIRECTOR_EMAIL_ADDRESS);
                    Id finalCourtJudgementNotificationETId = objMetadataService.getAppSettingTextValue(MTD_FINAL_COURT_JUDGEMENT_NOTIFICATION_EMAIL_TEMPLATE_ID);
                    EmailTemplate finalCourtJudgementNotificationTemplate = objEmailService.getEmailTemplateById(finalCourtJudgementNotificationETId);
                    List<Messaging.SingleEmailMessage> msgList = new List<Messaging.SingleEmailMessage>();
                    Messaging.SingleEmailMessage objEmailMessage = new Messaging.SingleEmailMessage();
                    List<String> toAddresses = cfoFinanceDirectorEmailAddresses.split(',');
                    Id bloomNoReplySalesOWEId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
                    objEmailMessage = getEmailContent(caseRecord, toAddresses, objEmailService, finalCourtJudgementNotificationTemplate, bloomNoReplySalesOWEId);
                    System.debug('objEmailMessage FOUR ::::: '+ objEmailMessage);
                    msgList.add(objEmailMessage);
                    objEmailService.sendEmail(msgList);
                }
                SalesOrder__c soRec = new SalesOrder__c(Id = caseRecord.Sales_Order__c, LegalStatus__c = 'With Legal');
                SalesOrderService objSalesOrderService = SalesOrderService.getInstance();
                objSalesOrderService.updateSalesOrders(new List<SalesOrder__c>{soRec});
                /* response.put('status', 'error');
                response.put('message', 'Please send Default Notice to Customer.');
                return response; */
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

    // Helper method to generate dynamic email content
    private Messaging.SingleEmailMessage getEmailContent(Case caseRec, List<String> toAddresses, EmailService objEmailService, EmailTemplate emailTemplate, Id bloomNoReplySalesOWEId) {
        String emailSubject = emailTemplate.Subject;
        String emailBody = emailTemplate.HtmlValue;
        /* Date installmentDate = pi.Due_Date__c != null ? pi.Due_Date__c : null;
        Datetime installmentDateTime = DateTime.newInstance(installmentDate.year(), installmentDate.month(), installmentDate.day());
        String formattedinstallmentDate = installmentDateTime.format('dd-MM-yyyy');
        String defaultNoticeDate = installmentDateTime.addDays(60).format('dd-MM-yyyy'); */
        
        emailSubject = emailSubject.replace('[Project_Name]', caseRec.Unit__r.Project__r.Name != null ? caseRec.Unit__r.Project__r.Name : '')
            .replace('[Unit_Name]', caseRec.Unit__r.Name != null ? caseRec.Unit__r.Name : '')
            .replace('[Project_Name_Arabic]', caseRec.Unit__r.Project__r.ProjectNameArabic__c != null ? caseRec.Unit__r.Project__r.ProjectNameArabic__c : '');
            emailBody = emailBody.replace('[Customer_Name]', caseRec.Account.Name != null ? caseRec.Account.Name : '')
            .replace('[Customer_NameArabic]', caseRec.Account.NameinArabic__c != null ? caseRec.Account.NameinArabic__c : '')
            .replace('[Project_Name]', caseRec.Unit__r.Project__r.Name != null ? caseRec.Unit__r.Project__r.Name : '')
            .replace('[Project_Name_Arabic]', caseRec.Unit__r.Project__r.ProjectNameArabic__c != null ? caseRec.Unit__r.Project__r.ProjectNameArabic__c : '')
            .replace('[Unit_Name]', caseRec.Unit__r.Name != null ? caseRec.Unit__r.Name : '');
            
            //.replace('[LPF_Amount]',);
            //.replace('[Installment_Date]', formattedinstallmentDate != null ? formattedinstallmentDate : '')
            //.replace('[DefaultNoticeDate]',defaultNoticeDate != null ? defaultNoticeDate : '' );
        


        // Create email message
        return objEmailService.getSingleEmailMessage(toAddresses, caseRec.AccountId, 
                                                          (caseRec.Account.isPersonAccount ? caseRec.Account.PersonContactId : caseRec.ContactId), 
                                                          emailSubject, emailBody, bloomNoReplySalesOWEId);
    }

    public  void handleNextSteps(Case caseRec){
        ServiceRequestTaskHandler obj = ServiceRequestTaskHandler.getInstance();
        obj.createNewAndCloseCurrentTask(new List<Case>{caseRec});
    }

    public void createDocuments(List<Case> listOfCases){
        DocumentService objDocumentService = DocumentService.getInstance();
        List<DocumentType__c> caseDocTypeList = objDocumentService.getActiveDocTypesForRecordType('Case',DEFAULT_UNIT_RT);
        List<Document__c> documentList = new List<Document__c>();
        for(Case caseObj :listOfCases){
            for(DocumentType__c objDocumentType :caseDocTypeList){
                if(objDocumentType.Type__c != 'Default Notice' || (objDocumentType.Type__c == 'Default Notice' && caseObj.Project__c == objDocumentType.Project__c)){
                    documentList.add(new Document__c(Case__c = caseObj.Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c));
                }
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
        String emailTemplateId = objMetadataService.getAppSettingTextValue(DEFAULT_NOTICE_EMAIL_TEMPLATE_ID);
        System.debug('emailTemplateId ::::: '+emailTemplateId);

        String customerEmailId;
        //String emailBody;

        System.debug('caseId ::::: '+caseId);
        try{
            if(emailTemplateId != null){
                EmailTemplate emailTemplate = objEmailService.getEmailTemplateById(emailTemplateId);
                if(emailTemplate == null){
                    return 'Email template not found';
                }
                System.debug('emailTemplate ::::: '+emailTemplate);
                System.debug('emailTemplate.HtmlValue ::::: '+emailTemplate.HtmlValue);
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
            System.debug('ex-->>'+ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        } 
    }

    private String getBody(Case caseRec, String emailBody, String customerEmail){
        /* Date d = Date.today(); 
        String formattedDate = DateTime.newInstance(d.year(),d.month(),d.day()).format('dd/MM/YYYY'); */
        Date dueDate = caseRec.DefaultCustomerPaymentOverdueDate__c;
        String formattedDate2;
        if(dueDate != null) {
            formattedDate2= DateTime.newInstance(dueDate.year(),dueDate.month(),dueDate.day()).format('dd/MM/YYYY');
        }

        emailBody = emailBody.replace('[Customer_Name]', caseRec.Account.Name != null ? caseRec.Account.Name : '')
        .replace('[Customer_NameArabic]', caseRec.Account.NameinArabic__c != null ? caseRec.Account.NameinArabic__c : '')
        .replace('[Project_Name]', caseRec.Unit__r.Project__r.Name != null ? caseRec.Unit__r.Project__r.Name : '')
        .replace('[Project_Name_Arabic]', caseRec.Unit__r.Project__r.ProjectNameArabic__c != null ? caseRec.Unit__r.Project__r.ProjectNameArabic__c : '')
        .replace('[Unit_Name]', caseRec.Unit__r.Name != null ? caseRec.Unit__r.Name : '')
        .replace('[Due_Amount]', caseRec.TotalInstalmentDue__c != null ? String.valueOf(caseRec.TotalInstalmentDue__c) : '')
        .replace('[Due_Date]', formattedDate2 != null ? formattedDate2 : '');
            
        return emailBody;
    }

    public String sendEmail(Id caseId,  List<Map<String,String>> fileList){
        
            CaseService objCaseService = CaseService.getInstance();
            ContactService objContactService = ContactService.getInstance();
            MetadataService objMetadataService = MetadataService.getInstance();
            EmailService objEmailService = EmailService.getInstance();
            String customerEmailId;

        try{
            Case caseRec = objCaseService.getCaseById(caseId);
            String emailTemplateId = objMetadataService.getAppSettingTextValue(DEFAULT_NOTICE_EMAIL_TEMPLATE_ID);
            System.debug('emailTemplateId ::::: '+emailTemplateId);
            Id noReplyBloomSalesOWDId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
            
            String CCEmailAddress = objMetadataService.getAppSettingTextValue(MTD_COLLECTION_TEAM_EMAIL_ADDRESS);
            List<String> CCEmailAddressList = CCEmailAddress != null ? CCEmailAddress.split(',') : null;
            /*String BCCEmailAddress = objMetadataService.getAppSettingTextValue(BCC_EMAIL_ADDRESS);
            List<String> BCCEmailAddressList = BCCEmailAddress != null ? BCCEmailAddress.split(',') : null; */

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
            System.debug('emailSubject ::::: '+ emailSubject);
            
            //fetch the email html body
            emailBody = getBody(caseRec, emailBody, customerEmailId);
            emailSubject = getBody(caseRec, emailSubject, customerEmailId);
            // send email if customer id is not blank
            if(String.isNotBlank(customerEmailId) && !caseRec.StopEmailsToCustomer__c){

                Messaging.SingleEmailMessage email = objEmailService.getSingleEmailMessage(new List<String>{customerEmailId}, caseId, null, emailSubject, emailBody, noReplyBloomSalesOWDId, CCEmailAddressList, null);

                List<Document__c> defaultNoticeDocument = [SELECT Id, Content_Version_Id__c, Document_Name__c FROM Document__c WHERE Document_Name__c IN ('Default Notice','SOA') AND Case__c = :caseId];
                List<Id> contentVersionIds = new List<Id>();
                for(Document__c doc : defaultNoticeDocument){
                    if(doc.Document_Name__c == 'Default Notice' && doc.Content_Version_Id__c == NULL){
                        return 'Default Notice not found';
                    } else if(doc.Document_Name__c == 'SOA' && doc.Content_Version_Id__c == NULL) {
                        return 'Statement of Account not found';
                    }else {
                        contentVersionIds.add(doc.Content_Version_Id__c);
                    }
                }
                List<ContentVersion> contentVersionList = [SELECT VersionData, Title FROM ContentVersion WHERE Id IN :contentVersionIds];
                List<Messaging.EmailFileAttachment> attachmentList = new List<Messaging.EmailFileAttachment>();
                for(ContentVersion cv: contentVersionList){
                    Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                    if(cv.VersionData != null && cv.Title != null){
                        attachment.setFileName(cv.Title);  // Set the file name
                        attachment.setBody(cv.VersionData);  // Set the PDF content as body (Blob)
                        attachment.setContentType('application/pdf');
                        attachment.setInline(false);
                        attachmentList.add(attachment);
                    }
                }
                email.setFileAttachments(attachmentList);

                Messaging.SendEmailResult[] results = objEmailService.sendEmail(new List<Messaging.SingleEmailMessage>{email});
                if (results != null && results.size() > 0 && results[0].isSuccess()){
                    caseRec.DefaultNoticeSentBy__c = UserInfo.getUserId();
                    caseRec.DefaultNoticeSentTime__c = System.now();
                    update caseRec;
                    return 'true';
                }else{
                    return 'false';
                }
            }
            else{
                return 'Customer email not found OR Customer Notifications are stopped for this SR.';
            }

            
        }catch(Exception ex){
            System.debug('ex-->>'+ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    public void sendEmailWithChecklist(List<String> selectedItems, String caseRecordId, String remarks) {
        
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        AccountService accServiceObj = AccountService.getInstance();
        Case caseRecord = CaseService.getInstance().getCaseById(caseRecordId);
        Account accRec = accServiceObj.getAccountById(caseRecord.AccountId);

        Id bloomNoReplySalesOWEId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
        Id installmentFirstPaymentReminderETId = objMetadataService.getAppSettingTextValue(MTD_REQUEST_ORIGINAL_DOCUMENT_EMAIL_TEMPLATE_ID);
        
        //collectionTeamMembersEmail.split(',');
        EmailTemplate originalDocumentEmailTemplate = objEmailService.getEmailTemplateById(installmentFirstPaymentReminderETId);
        List<Messaging.SingleEmailMessage> msgList = new List<Messaging.SingleEmailMessage>();
        Set<String> queueList = new Set<String>();

        Map<String,String> documentNameToTeamNameMap = new Map<String,String>();
        documentNameToTeamNameMap.put('Service Charge Invoices', 'collection');
        documentNameToTeamNameMap.put('Tenancy contract', 'collection');
        documentNameToTeamNameMap.put('Cheque', 'collection');
        documentNameToTeamNameMap.put('Other', 'collection');
        documentNameToTeamNameMap.put('Statement of Account', 'finance');
        documentNameToTeamNameMap.put('Broker Invoice - POP', 'finance');
        documentNameToTeamNameMap.put('Customer Passport (for all owners)', 'operation');
        documentNameToTeamNameMap.put('Customer EID (for all owners)', 'operation');
        documentNameToTeamNameMap.put('Handover Proof Document', 'operation');
        documentNameToTeamNameMap.put('Unit Registration', 'governmentRelation');
        documentNameToTeamNameMap.put('Returned Memo', 'governmentRelation');
        documentNameToTeamNameMap.put('Broker Invoice', 'brokerManagement');
        documentNameToTeamNameMap.put('Broker Signed Agreement', 'brokerManagement');

        // Format the selected items
        String selectedDocumentList = 'The following documents were selected:\n\n';
        for (Integer i = 0; i < selectedItems.size(); i++) {
            selectedDocumentList += (i + 1) + ') ' + selectedItems[i] + '\n';
            queueList.add(documentNameToTeamNameMap.get(selectedItems[i]));
        }

        /* Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{ userEmail });
        email.setSubject('Selected Document Checklist');
        email.setPlainTextBody(body); 
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });*/

        Messaging.SingleEmailMessage objEmailMessage = new Messaging.SingleEmailMessage();
        objEmailMessage = getEmailContent(caseRecord, queueList, selectedDocumentList, remarks, objEmailService, originalDocumentEmailTemplate, bloomNoReplySalesOWEId);
        System.debug('objEmailMessage ONE ::::: '+ objEmailMessage);
        msgList.add(objEmailMessage);
		if(!Test.isRunningTest()){
        	objEmailService.sendEmail(msgList);
        }
    }

    // Helper method to generate dynamic email content
    private Messaging.SingleEmailMessage getEmailContent(Case caseRec, Set<String> queueList, String selectedDocumentList, String remarks, EmailService objEmailService, EmailTemplate emailTemplate, Id bloomNoReplySalesOWEId) {
        String emailSubject = emailTemplate.Subject;
        String emailBody = emailTemplate.HtmlValue;        
        MetadataService objMetadataService = MetadataService.getInstance();
        String collection = objMetadataService.getAppSettingTextValue(MTD_COLLECTION_TEAM_RECEPIENT_LIST);
        String finance = objMetadataService.getAppSettingTextValue(MTD_FINANCE_TEAM_RECEPIENT_LIST);
        String operation = objMetadataService.getAppSettingTextValue(MTD_OPERATION_TEAM_RECEPIENT_LIST);
        String governmentRelation = objMetadataService.getAppSettingTextValue(MTD_GOVERNMENTRELATION_TEAM_RECEPIENT_LIST);
        String brokerManagement = objMetadataService.getAppSettingTextValue(MTD_BROKERMANAGEMENT_TEAM_RECEPIENT_LIST);

        Set<String> toAddresses = new Set<String>();
        for(String queueName : queueList){
            switch on queueName {
                when 'finance' {
                    toAddresses.addAll(finance.split(','));
                }
                when 'operation' {
                    toAddresses.addAll(operation.split(','));
                }
                when 'governmentRelation' { 
                    toAddresses.addAll(governmentRelation.split(','));
                }
                when 'brokerManagement' {
                    toAddresses.addAll(brokerManagement.split(','));
                }
                when else {
                    toAddresses.addAll(collection.split(','));
                }
            }
        }
        List<String> recipientList = new List<String>();
        recipientList.addAll(toAddresses);

        String serialNumber = '';
        if(caseRec != NULL && caseRec.NumberOfDefaultNoticeRemindersSent__c != NULL) {
            serialNumber = String.valueOf(caseRec.NumberOfDefaultNoticeRemindersSent__c) + Utility.getCountingFromNumber(caseRec.NumberOfDefaultNoticeRemindersSent__c);
        }
        System.debug('serialNumber ::::: '+ serialNumber);
        emailSubject = emailSubject.replace('[Project_Name]', caseRec.Unit__r.Project__r.Name != null ? caseRec.Unit__r.Project__r.Name : '')
            .replace('[SerialNumber]', serialNumber)
            .replace('[Unit_Name]', caseRec.Unit__r.Name != null ? caseRec.Unit__r.Name : '')
            .replace('[Project_Name_Arabic]', caseRec.Unit__r.Project__r.ProjectNameArabic__c != null ? caseRec.Unit__r.Project__r.ProjectNameArabic__c : '');
        emailBody = emailBody.replace('[Customer_Name]', caseRec.Account.Name != null ? caseRec.Account.Name : '')
            .replace('[Customer_NameArabic]', caseRec.Account.NameinArabic__c != null ? caseRec.Account.NameinArabic__c : '')
            .replace('[Project_Name]', caseRec.Unit__r.Project__r.Name != null ? caseRec.Unit__r.Project__r.Name : '')
            .replace('[Project_Name_Arabic]', caseRec.Unit__r.Project__r.ProjectNameArabic__c != null ? caseRec.Unit__r.Project__r.ProjectNameArabic__c : '')
            .replace('[Unit_Name]', caseRec.Unit__r.Name != null ? caseRec.Unit__r.Name : '')
            .replace('[Due_Amount]', caseRec.TotalInstalmentDue__c != null ? String.valueOf(caseRec.TotalInstalmentDue__c) : '')
            .replace('[Remarks]', remarks != null ? 'Remarks: '+remarks : '')
            .replace('[Selected_Documents]', selectedDocumentList != null ? selectedDocumentList : '');
            //.replace('[LPF_Amount]',);
            //.replace('[Installment_Date]', formattedinstallmentDate != null ? formattedinstallmentDate : '')
            //.replace('[DefaultNoticeDate]',defaultNoticeDate != null ? defaultNoticeDate : '' );
        

        // Create email message
        return objEmailService.getSingleEmailMessage(recipientList, caseRec.AccountId, 
                                                          (caseRec.Account.isPersonAccount ? caseRec.Account.PersonContactId : caseRec.Contacts_Case_Email__c), 
                                                          emailSubject, emailBody, bloomNoReplySalesOWEId);
    }
}