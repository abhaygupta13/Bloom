/*****************************************************************************************
Class       : ThirdPartyFormSRHandler
Author      : Pranav G
Description : 
test Class  : ThirdPartyFormSRHandler
Created Date: 8/20/2025 
*****************************************************************************************/
public inherited sharing class ThirdPartyFormSRHandler {
    private static final String MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final string THIRD_PARTY_FORM_RT { get { return 'ThirdPartyForm'; } }
    private static final string MTD_NEW_SERVICE_REQUEST_ACKNOWLEDGEMENT_EMAIL_TEMPLATE_ID { get { return 'NewServiceRequestAssignmentId'; } }
    private static final string SERVICE_REQUEST_CUSTOMER_CLOSURE_EMAIL_TEMPLATE_ID { get { return 'NewServiceRequestClosureID'; } }
    private static final string THIRD_PARTY_FORM_REQUEST_EMAIL_TEMPLATE_ID { get { return 'thirdpartyform'; } }
    private static final string CLARIFICATION_EMAIL_TEMPLATE_ID { get { return 'clarificationEmailTemplate'; } }
    
    
    
    
    private static ThirdPartyFormSRHandler instance;

    public ThirdPartyFormSRHandler() {

    }
    
    public static ThirdPartyFormSRHandler getInstance() { 
        if(instance == null) {
            instance = new ThirdPartyFormSRHandler();
        }
        return instance;
    }

    public String validateEligibility(SalesOrder__c salesOrderObj){
        String message;
        if(salesOrderObj != null && salesOrderObj.Status__c != 'Sold'){
            message = 'The status must be sold to raise the selected service request';
        }
        else if(salesOrderObj !=null && salesOrderObj.IsDefaulted__c == true){
            message = 'A Third Party form request cannot be created for a defaulted unit';
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
        List<Messaging.SingleEmailMessage> emailList = new list<Messaging.SingleEmailMessage>();
        EmailService emlService = EmailService.getInstance();
        
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
        createDocuments(new List<Case>{newcase});
        if(test.isRunningTest())
        Messaging.SingleEmailMessage email = sendCustomerEmail(newCase.id,'TPForm', null,null);
        return newCase; 
    }

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

    public void createDocuments(List<Case> listOfCases){
        DocumentService objDocumentService = DocumentService.getInstance();
        List<DocumentType__c> caseDocTypeList = objDocumentService.getDocTypes('Case',THIRD_PARTY_FORM_RT);
        List<Document__c> documentList = new List<Document__c>();
        for(Case caseObj :listOfCases){
            for(DocumentType__c objDocumentType :caseDocTypeList){
                documentList.add(new Document__c(Case__c = caseObj.Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c));
            }
        }
        objDocumentService.insertDocuments(documentList);   
        autoCreateDocument(listOfCases,listOfCases[0].Sales_Order__c); 
    }

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
            if(caseRecord.Step__c =='Final'){//For finance closure
                CaseService servObj = CaseService.getInstance();
                List<Case> thrdPrtyCaseList = servObj.getCaseByIds(new Set<Id>{caseRecord.id});
                if(thrdPrtyCaseList[0].FinanceDocumentsUploadedManually__c != 'Yes')
                autoCreateDocument(new List<Case>{thrdPrtyCaseList[0]},thrdPrtyCaseList[0].Sales_Order__c);//Re-attachment documents on finance closure

                createFirstTask(thrdPrtyCaseList);
            }
        }
        if(caseRecord.Step__c !='Final'){// For CRM to Finance assignment
            if(response.get('status')=='success'){ 
                createFirstTask(new list<Case>{caseRecord});
            }
        }
        
        return response;
    }

    public Map<String, Object> checkRequiredFields(Case caseRecord) {
        Map<String, Object> response = new Map<String, Object>();
        
        if(caseRecord.Step__c == '1'){
            if(String.isEmpty(caseRecord.TPFType__c)){
                response.put('status', 'error');
                response.put('message', 'Please send third party form to the Customer.');
                return response;
            }
            if (String.isEmpty(caseRecord.DocumentsVerifiedUploaded__c) || caseRecord.DocumentsVerifiedUploaded__c == 'No') {
                   response.put('status', 'error');
                   response.put('message', 'The case is not valid to move to the next step. Required documents must be verified and uploaded.');
                   return response;
            }
            else{
                response = validateDocs(caseRecord);
                if (response.get('status') == 'error') {
                    return response;
                }
            }
        }
        if(caseRecord.Step__c == 'Final'){
            if(caseRecord.Payment_Booked__c != 'Yes' || caseRecord.Payment_Booked__c == Null || caseRecord.Finance_Document_Verified__c != 'Yes' || caseRecord.Finance_Document_Verified__c == Null){
                response.put('status', 'error');
                response.put('message', 'The case is not valid to move to the next step. Payment Booked should be marked as Yes along with verification of Finance documents.');
                return response;
            }
            if(String.isEmpty(caseRecord.FinanceDocumentsUploadedManually__c)){
                response.put('status', 'error');
                response.put('message', 'Kindly confirm if finance documents uploaded manually');
                return response;
            }
            if (response.get('status') == 'error') {
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
    
    public static Map<String, Object> validateDocs(Case caseRecord){
        Map<String, Object> response = new Map<String, Object>();
        DocumentService docService = DocumentService.getInstance();
        for(Document__c doc : docService.getCaseDocumentsByName(caseRecord.id,new Set<String>{'Third Party EID','Third Party Form'})){
            if(doc.ContentDocumentId__c == Null){
                response.put('status', 'error');
                response.put('message', 'Please upload '+ doc.Document_Name__c +' before proceeding to submit for next review.');
                return response; 
            }
        }
        return response;
    }
    
    public void autoCreateDocument(List<Case> listOfCases, Id salesOrderId){
        DocumentService objDocumentService = DocumentService.getInstance();
        List<Document__c> documentUpdateList = new List<Document__c>();
        for(Document__c doc : objDocumentService.getCaseDocumentsByName(listOfCases[0].id,new Set<String>{'SOA','Payment Receipt'})){
            String contentVersionId;
            String contentDocumentId;
            String docType = doc.Document_Name__c == 'SOA' ? 'generateStatement' : 'generateReceipt';
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
    
    public Messaging.SingleEmailMessage sendCustomerEmail(Id whatId, String scenario, List<String> descriptions, String customerType){
        //List<Messaging.SingleEmailMessage> emailList = new list<Messaging.SingleEmailMessage>();
        
        CaseService csService = CaseService.getInstance();
        Case cs = csService.getCaseById(whatId);
        
        AccountService accService = AccountService.getInstance();
        List<String> toAddress = new List<String>{accService.getRelatedContactEmail(cs.AccountId)};
        
        MetadataService objMetadataService = MetadataService.getInstance();
        
        Id noReplyOWDId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
        EmailService emlService = EmailService.getInstance();
        Id emailTemplateId;
        String emailtemplate = scenario == 'TPForm' ? THIRD_PARTY_FORM_REQUEST_EMAIL_TEMPLATE_ID : scenario == 'Closure' ? SERVICE_REQUEST_CUSTOMER_CLOSURE_EMAIL_TEMPLATE_ID
            : scenario == 'Enquiry' ? CLARIFICATION_EMAIL_TEMPLATE_ID : '';
        
        system.debug('requiredEmailTemplate>>'+emailtemplate);
        emailTemplateId = objMetadataService.getAppSettingTextValue(emailtemplate);
        Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(emailTemplateId, null, whatId);
        if(String.isNotBlank(noReplyOWDId)  && scenario != 'TPForm' && scenario != 'Enquiry'){  mail.setOrgWideEmailAddressId(noReplyOWDId); }
        if(toAddress != NULL && !toAddress.isEmpty() ){ mail.setToAddresses(toAddress); }
        
        mail.Subject = mail.Subject.replace('{SR_Name}',cs.Subject);
        mail.htmlBody = mail.htmlBody.contains('{SR_Subject_EN}') && !String.isEmpty(cs.ServiceCatalog__r.SubCategory__c) ? mail.htmlBody.replace('{SR_Subject_EN}',cs.ServiceCatalog__r.SubCategory__c) :mail.htmlBody;
        mail.htmlBody = mail.htmlBody.contains('{Sr_Name_EN}') && !String.isEmpty(cs.Subject) ? mail.htmlBody.replace('{Sr_Name_EN}',cs.Subject) :mail.htmlBody;
        mail.htmlBody = mail.htmlBody.contains('{SR_Subject_AR}') && !String.isEmpty(cs.ServiceCatalog__r.SubCategoryArabic__c) ? mail.htmlBody.replace('{SR_Subject_AR}',cs.ServiceCatalog__r.SubCategoryArabic__c) :mail.htmlBody;
        mail.htmlBody = mail.htmlBody.contains('{Sr_Name_AR}') && !String.isEmpty(cs.Subject) ? mail.htmlBody.replace('{Sr_Name_AR}',cs.Subject) :mail.htmlBody;
        mail.htmlBody = mail.htmlBody.contains('{CustomerName}') && !String.isEmpty(cs.Account_Name__c) ? mail.htmlBody.replace('{CustomerName}',cs.Account_Name__c):mail.htmlBody;
        mail.htmlBody = mail.htmlBody.contains('{CustomerNameAr}') && !String.isEmpty(cs.Account.NameinArabic__c) ? mail.htmlBody.replace('{CustomerNameAr}',cs.Account.NameinArabic__c):mail.htmlBody;
        mail.htmlBody = mail.htmlBody.contains('{CRM_Comments_En}') && !String.isEmpty(descriptions[0]) ? mail.htmlBody.replace('{CRM_Comments_En}',descriptions[0]):mail.htmlBody;
        mail.htmlBody = mail.htmlBody.contains('{CRM_Comments_Ar}') && !String.isEmpty(descriptions[1]) ? mail.htmlBody.replace('{CRM_Comments_Ar}',descriptions[1]):mail.htmlBody;
            
        
        mail.setSaveAsActivity(true);
        mail.setTreatTargetObjectAsRecipient(false);
        if(scenario == 'Closure'){
           // List<Messaging.EmailFileAttachment> attachments = emlService.getCaseAttachments(cs.Id);
            List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
            for(Messaging.EmailFileAttachment attachment : emlService.getCaseAttachments(cs.Id)){
            //    if(attachment.getFileName().contains('SOA') || attachment.getFileName().contains('Payment Receipt')){
                      if(attachment.getFileName().contains('Payment Receipt')){
                    System.debug('File>>'+attachment);
                    System.debug('FileName>>'+attachment.getFileName());
                    attachments.add(attachment);
                }
            }
            mail.setFileAttachments(attachments);
        }
        if(scenario == 'BankDetals' || scenario == 'TPForm'|| scenario == 'Enquiry'){
        // if(scenario == 'BankDetals' || scenario == 'TPForm'){
            list<Messaging.EmailFileAttachment> atList = new list<Messaging.EmailFileAttachment>();
            list<StaticResource> srList = [SELECT Id, Name, Body FROM StaticResource WHERE Name IN ('TP_Frm_Ind','TP_Frm_Org') ];
            for(StaticResource sr : srList){
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                if(sr.name == 'TP_Frm_Ind' && (scenario == 'BankDetals' || customerType == 'Individual')){
                    efa.setFileName('Third Party Form - Individual' + '.pdf');
                    efa.setBody(sr.Body);
                    efa.setContentType('application/pdf');
                    atList.add(efa);
                } else if(sr.name == 'TP_Frm_Org' && (scenario == 'BankDetals' || customerType == 'Company')){
                    efa.setFileName('Third Party Form - Company' + '.pdf');
                    efa.setBody(sr.Body);
                    efa.setContentType('application/pdf');
                    atList.add(efa);
                } 
                
            }
            //mail.setFileAttachments(new List<Messaging.EmailFileAttachment>{efa});
            mail.setFileAttachments(atList);
            // User u = [Select id, email from user where id =: cs.ownerId];
            // mail.setReplyTo(u.email);
        }
       
        if(test.isRunningTest()){
            return null;
        }
        //emailList.add(mail);
        //if(!emailList.isEmpty())emlService.sendEmail(emailList);
        return mail;
    }

    public Map<String, String> sendClarificationEmail(case cs, List<String> descriptions, String type){
        Map<String, String> result = new Map<String, String>();
        List<Messaging.SingleEmailMessage> emailList = new list<Messaging.SingleEmailMessage>();
        EmailService emlService = EmailService.getInstance();
        Messaging.SingleEmailMessage email;
        if(!cs.StopEmailsToCustomer__c){
            if(type == Null){
                email = sendCustomerEmail(cs.id,'Enquiry',descriptions, cs.TPFType__c);
            } else{
                email = sendCustomerEmail(cs.id,'TPForm',descriptions, type);
            }
            emailList.add(email);
            if(!test.isRunningTest() && !emailList.isEmpty())emlService.sendEmail(emailList);
        }
        if(email != NULL){
            result.put('status','success'); 
            result.put('message', 'Email Sent Successfully.'); 
        }
            
        return result;

    }

}