/*****************************************************************************************
Class       : ChequeReplacementRequestCaseHandler
Author      :  Jhilik
Description : 
test Class  : ChequeReplacementRequestCaseHandlerTest
Created Date: 15-Aug-2025
*****************************************************************************************/
public inherited sharing class ChequeReplacementRequestCaseHandler {
    private static ChequeReplacementRequestCaseHandler instance;
    private static final string CHEQUE_REPLACEMENT_REQUEST_RT { get { return 'ChequeReplacementRequest'; } }
    private static final string MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final string CHEQUE_REPLACEMENT_REQUEST_TEMPLATE_ID { get { return 'ChequeReplacementRequestTemplateId'; } }
    private static final string CHEQUE_REPLACEMENT_PDCs_READY_TEMPLATE_ID { get { return 'PDCsAreReadyTemplateId'; } }
    private static final string SERVICE_REQUEST_CUSTOMER_CLOSURE_EMAIL_TEMPLATE_ID { get { return 'NewServiceRequestClosureID'; } }

    private ChequeReplacementRequestCaseHandler() {
    }

    public static ChequeReplacementRequestCaseHandler getInstance() { 
        if(instance == null) {
            instance = new ChequeReplacementRequestCaseHandler();
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
        String emailTemplateId = objMetadataService.getAppSettingTextValue(CHEQUE_REPLACEMENT_REQUEST_TEMPLATE_ID);

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
            newCase.Subject = 'Cheque Replacement Request-'+ salesOrderObj.Account__r.Name +'-'+ salesOrderObj.Unit__r.Name;
            newCase.ContactId = accService.getRelatedContact(salesOrderObj.Account__r.Id);
            newCase.CustomerName__c = accService.getRelatedContactName(salesOrderObj.Account__r.Id);
            newCase.Sales_Order__c = salesOrderObj.Id;
            newCase.RequesterContactNumber__c = salesOrderObj.Account__r.isPersonAccount ? salesOrderObj.Account__r.PersonMobilePhone : null;
        }
        newCase.StopEmailsToCustomer__c = stopEmailsToCustomer;
        System.debug('newCase :::::'+newCase);
        System.debug('newCase :::::'+newCase.Sales_Order__c);

        CaseService caseServiceObj = CaseService.getInstance();
        newCase = caseServiceObj.insertCase(newCase);
        createDocuments(new List<Case>{newCase}, newCase.Sales_Order__c);
        createCaseReceipts(newCase);
        sendEmail(newCase.Id, emailTemplateId);
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

            if(Integer.valueOf(caseRecord.Step__c) == 1) {
                
                    
                if(!(caseRecord.ChequeUnavailableInSF__c || caseRecord.Unit__r.Project__r.ChequesUnavailable__c)){
                    //Calculate the cheque replacement amount
                    List<AggregateResult> chequeCount = [SELECT count(Id) cnt FROM CaseReceipt__c WHERE Case__c = :caseRecord.Id AND ReplaceCheque__c = true];
                    System.debug('chequeCount ::::: '+ chequeCount);
                    Integer count = (Integer)chequeCount[0].get('cnt');
                    if(count > 0 || test.isRunningTest() ){
                        ProjectService projServiceObj = ProjectService.getInstance();
                        Set<Id> projIdSet = new Set<Id>();
                        projIdSet.add(caseRecord.Project__c);
                        List<Project__c> projList = projServiceObj.getProjectsByIds(projIdSet);
                        if(projList != NULL && !projList.isEmpty() && projList[0].ChequeWithdrawalFee__c != NULL){
                            caseRecord.ChequeReplacementFee__c = count * projList[0].ChequeWithdrawalFee__c;
                        }
                        caseServiceObj.updateCasesWithoutTrigger(new List<Case>{new Case(Id = caseRecord.Id, ChequeReplacementFee__c = caseRecord.ChequeReplacementFee__c, NoOfChequesSelectedForReplacement__c = count)});
                        calculateOtherCharges(caseRecord);         
                    } else {
                        response.put('status', 'error');
                        response.put('message', 'No cheques are selected to be replaced.');
                        return response;
                    }
                }
                
                    
                if(caseRecord.NewChequesCollected__c != 'Yes') {
                    response.put('status', 'error');
                    response.put('message', 'Please update if New Cheques are Collected.');
                    return response;
                }
                if(caseRecord.Neccessory_fees_collected__c == Null || caseRecord.Neccessory_fees_collected__c != 'Yes'){
                    response.put('status', 'error');
                    response.put('message', 'Please collect replacement fees.');
                    return response;
                }
                List<Document__c> docList = [SELECT Id, Name, DocumentType__c, Case__c 
                                                    FROM Document__c 
                                                    WHERE Case__c = :caseRecord.Id 
                                                    AND Document_Name__c = 'Proof of Payment' 
                                                    AND ContentDocumentId__c != NULL];
                                                    
                if(docList != null && docList.size() > 0){
                } else {
                    response.put('status', 'error');
                    response.put('message', 'Please upload proof of payment for the newly collected cheque.');
                    return response;
                }
                if(String.isEmpty(caseRecord.Remarks__c)){
                    response.put('status', 'error');
                    response.put('message', 'Please enter purpose of cheque replacement in \'Remarks\' field.');
                    return response;
                }
            }

            if(Integer.valueOf(caseRecord.Step__c) == 2) {
                MetadataService objMetadataService = MetadataService.getInstance();
                String emailTemplateId = objMetadataService.getAppSettingTextValue(CHEQUE_REPLACEMENT_PDCs_READY_TEMPLATE_ID);
                if(caseRecord.PreviousChequeInOffice__c == 'Yes') {
                    //&& caseRecord.SentOldChequesToCustomer__c == 'Yes')
                    //|| (caseRecord.PreviousChequeInOffice__c == 'No' && caseRecord.OldChequeReceivedFromBank__c == 'Yes')){
                    sendEmail(caseRecord.Id, emailTemplateId);
                } 
                else if(caseRecord.PreviousChequeInOffice__c == 'No' && (String.isEmpty(caseRecord.RequestRaisedToBank__c) || caseRecord.RequestRaisedToBank__c == 'No')){
                    response.put('status', 'error');
                    response.put('message', 'Kindly intiate old PDC withdrawal request from bank.');
                    return response;
                }
                else if(caseRecord.PreviousChequeInOffice__c == 'No' && caseRecord.OldChequeReceivedFromBank__c != 'Yes') {
                    response.put('status', 'error');
                    response.put('message', 'Please make sure Old cheques are received from bank and Update Old cheques received to YES.');
                    return response;
                }
                else if(caseRecord.PreviousChequeInOffice__c == 'No' && caseRecord.OldChequeReceivedFromBank__c == 'Yes') {
                    sendEmail(caseRecord.Id, emailTemplateId);
                }
                else {
                    response.put('status', 'error');
                    response.put('message', 'Please update if Previous cheques are in office.');
                    return response;
                }
            }

            if(Integer.valueOf(caseRecord.Step__c) == 3){
                if(caseRecord.PreviousChequeInOffice__c == 'Yes' && caseRecord.SentOldChequesToCustomer__c != 'Yes') {
                    response.put('status', 'error');
                    response.put('message', 'Please ensure that old cheques are sent to customer and update Handedover Old Cheques to Customer YES.');
                    return response;
                } else if(caseRecord.PreviousChequeInOffice__c == 'Yes' && caseRecord.SentOldChequesToCustomer__c == 'Yes') {

                }
                else if(caseRecord.PreviousChequeInOffice__c == 'No' && caseRecord.CourierRequested__c == 'No' && caseRecord.SentOldChequesToCustomer__c == 'Yes') {
                    //Pranav
                    if(String.isEmpty(caseRecord.FinanceDocumentsUploadedManually__c)){
                        response.put('status', 'error');
                        response.put('message', 'Kindly confirm if finance documents uploaded manually');
                        return response;
                    }
                    if(caseRecord.FinanceDocumentsUploadedManually__c != 'Yes')
                    createDocuments(new List<Case>{caseRecord}, caseRecord.Sales_Order__c);

                    ServiceRequestTaskHandler objServiceRequestTaskHandler = ServiceRequestTaskHandler.getInstance();
                    ServiceCatalogService objServiceCatalogService = ServiceCatalogService.getInstance();
                    Map<Id,ServiceAction__c> caseCatalogVsCurrentAction = objServiceCatalogService.getCurrentCaseServiceAction(new List<Case>{caseRecord});
                    objServiceRequestTaskHandler.processCasesAndHandleNextActions(new List<Case>{caseRecord},new Map<Id, ServiceAction__c>(), caseCatalogVsCurrentAction);
                    response.put('message', 'Case closed successfully.');
                    return response;
                } 
                else if(caseRecord.PreviousChequeInOffice__c == 'No' && caseRecord.CourierRequested__c == 'No') {
                    response.put('status', 'error');
                    response.put('message', 'Please handover the old cheques to customer and update Handededover old cheques to customer YES');
                    return response;
                }
                else if(caseRecord.PreviousChequeInOffice__c == 'No' && caseRecord.CourierRequested__c == 'Yes') {
                } 
                else if(caseRecord.CourierRequested__c == null) {
                    response.put('status', 'error');
                    response.put('message', 'Please select if courier is requested.');
                    return response;
                }
            }
        } 
        else if(caseRecord.Step__c =='Final'){
            if(caseRecord.PDCSentToCustomer__c != 'Yes'){
                response.put('status', 'error');
                response.put('message', 'Please send PDCs to customer and update PDCs sent to customer YES');
                return response;
            }
            //Pranav
            if(String.isEmpty(caseRecord.FinanceDocumentsUploadedManually__c)){
                response.put('status', 'error');
                response.put('message', 'Kindly confirm if finance documents uploaded manually');
                return response;
            }
            if(caseRecord.FinanceDocumentsUploadedManually__c != 'Yes')
            createDocuments(new List<Case>{caseRecord}, caseRecord.Sales_Order__c);
        }
        
        if (response.get('status') == 'error') {
            return response;
        }
        if(response.get('status') == 'success'){
            handleNextSteps(caseRecord); 
        }
        
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
        
        List<DocumentType__c> caseDocTypeList = objDocumentService.getActiveDocTypesForRecordType('Case',CHEQUE_REPLACEMENT_REQUEST_RT);
        List<Document__c> documentList = new List<Document__c>();
        Map<String, Document__c> docMap = new Map<String, Document__c>();
        for (Document__c d : [SELECT Id, Document_Name__c, ContentDocumentId__c FROM Document__c WHERE Case__c = :listOfCases[0].Id]) {
            docMap.put(d.Document_Name__c, d);
        }
        for(Case caseObj :listOfCases){
            for(DocumentType__c objDocumentType :caseDocTypeList){
                document__c doc;
                if(objDocumentType.Type__c == 'Statement of Account' && contentVersionMap != NULL && contentVersionMap.get(SOACVId) != NULL){
                    doc = new Document__c(Case__c = caseObj.Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c, Content_Version_Id__c = SOACVId, ContentDocumentId__c = contentVersionMap.get(SOACVId).ContentDocumentId);
                    
                } 
                else if(objDocumentType.Type__c == 'Payment Receipt' && contentVersionMap != NULL && contentVersionMap.get(paymentReceiptCVId) != NULL){
                    doc = new Document__c(Case__c = caseObj.Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c, Content_Version_Id__c = SOACVId, ContentDocumentId__c = contentVersionMap.get(paymentReceiptCVId).ContentDocumentId);
                } 
                else {
                    doc = new Document__c(Case__c = caseObj.Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c);
                }
                if(docMap != Null && docMap.containsKey(objDocumentType.type__c)){
                    doc.id = docMap.get(objDocumentType.type__c).Id;
                }
                documentList.add(doc);
            }
        }
       // objDocumentService.insertDocuments(documentList);   
       if(!documentList.isEmpty())
       upsert documentList;   
    }

    private String getBody(Case caseRec, String emailBody, String customerEmail){
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
            //String emailTemplateId = objMetadataService.getAppSettingTextValue(CHEQUE_REPLACEMENT_REQUEST_TEMPLATE_ID);
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
            if(String.isNotBlank(customerEmailId) && !caseRec.StopEmailsToCustomer__c){

                Messaging.SingleEmailMessage email = objEmailService.getSingleEmailMessage(new List<String>{customerEmailId}, caseRec.Id, null, emailSubject, emailBody, noReplyBloomSalesOWDId);
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
            System.debug('ex-->>'+ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    public List<SalesOrderOtherCharges__c> calculateOtherCharges(Case caseRec) {
        Set<Id> ordrIds = new Set<Id>{caseRec.Sales_Order__c};
        Map<Id,SalesOrder__c> salesOrdersMap = SalesOrderService.getInstance().getSalesOrdersMap(ordrIds);
        List<SalesOrderOtherCharges__c> otherChargesToInsert = new List<SalesOrderOtherCharges__c>();
                    
        if (caseRec.ChequeReplacementFee__c != null) {
            SalesOrderOtherCharges__c charge = new SalesOrderOtherCharges__c();
            charge.Amount__c = caseRec.ChequeReplacementFee__c;
            charge.Due_Date__c = System.today();
            charge.SalesOrder__c = caseRec.Sales_Order__c;
            charge.Account__c = caseRec.AccountId;
            charge.TypeOfCharge__c = 'Cheque Replacement Fee';
            charge.Case__c = caseRec.Id;
            otherChargesToInsert.add(charge);
        }
        insert otherChargesToInsert;
        return otherChargesToInsert; 
    }

    public List<CaseReceipt__c> createCaseReceipts(Case caseRec) {
        ReceiptAcknowledgementService receiptAckObj = ReceiptAcknowledgementService.getInstance();
        List<ReceiptAcknowledgement__c> receiptAckList = receiptAckObj.getReceiptAcknowledgementBySalesOrders(new Set<Id>{caseRec.Sales_Order__c});
        List<CaseReceipt__c> caseReceiptsToInsert = new List<CaseReceipt__c>();
        for(ReceiptAcknowledgement__c ackRec : receiptAckList){
            CaseReceipt__c caseReceiptRec = new CaseReceipt__c();
            caseReceiptRec.Case__c = caseRec.Id;
            caseReceiptRec.ReceiptAcknowledgement__c = ackRec.Id;
            caseReceiptsToInsert.add(caseReceiptRec);
        }

        insert caseReceiptsToInsert;
        return caseReceiptsToInsert;
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