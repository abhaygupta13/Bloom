/*****************************************************************************************
Class       : BankAccDetailInquirySRHandler
Author      : Pranav G
Description : 
test Class  : 
Created Date: 8/29/2025 
*****************************************************************************************/
public inherited sharing class BankAccDetailInquirySRHandler {
    private static final String MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final string BANK_ACC_DTAIL_SR_RT { get { return 'BankAccountDetailsInquiry'; } }
    private static final string MTD_NEW_SERVICE_REQUEST_ACKNOWLEDGEMENT_EMAIL_TEMPLATE_ID { get { return 'NewServiceRequestAssignmentId'; } }
    private static final string CLARIFICATION_EMAIL_TEMPLATE_ID { get { return 'clarificationEmailTemplate'; } }
    private static final string SERVICE_REQUEST_CUSTOMER_CLOSURE_EMAIL_TEMPLATE_ID { get { return 'NewServiceRequestClosureID'; } }
    private static final string THIRD_PARTY_FORM_REQUEST_EMAIL_TEMPLATE_ID { get { return 'thirdpartyform'; } }
    private static final string BANK_DETAILS_EMAIL_TEMPLATE_ID { get { return 'BankDetailsEmail'; } }
    private static boolean financeScenario = false;

    private static BankAccDetailInquirySRHandler instance;

    public BankAccDetailInquirySRHandler() {

    }
    
    public static BankAccDetailInquirySRHandler getInstance() { 
        if(instance == null) {
            instance = new BankAccDetailInquirySRHandler();
        }
        return instance;
    }

    public String validateEligibility(SalesOrder__c salesOrderObj){
        String message;
        if(salesOrderObj != null && salesOrderObj.Status__c != 'Sold'){
            message = 'The status must be sold to raise the selected service request';
        }
        else if(salesOrderObj !=null && salesOrderObj.IsDefaulted__c == true){
            message = 'A selected service request cannot be created for a defaulted unit';
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
        //newCase.POPUploaded__c = 'No';
        newCase.StopEmailsToCustomer__c = stopEmailsToCustomer;
        CaseService caseServiceObj = CaseService.getInstance();
        newCase = caseServiceObj.insertCase(newCase);
        createDocuments(new List<Case>{newcase});
        String profileName = [Select id, name from Profile where Id =: UserInfo.getProfileId()].Name;
        if(profileName == 'Finance Team')
        financeScenario = true;
        if(financeScenario)
        createFirstTask(new List<Case>{caseServiceObj.getCaseById(newCase.Id)});

        Messaging.SingleEmailMessage email = sendCustomerEmail(newCase.id,'BankDetals', null, null);
        emailList.add(email);
        if(!test.isRunningTest() && !emailList.isEmpty())emlService.sendEmail(emailList);
        // if(financeScenario){
        //     newCase.Step__c = 'Final';
        //     update newCase;
        // }
        return newCase; 
    }

    public void createDocuments(List<Case> listOfCases){
        DocumentService objDocumentService = DocumentService.getInstance();
        List<DocumentType__c> caseDocTypeList = objDocumentService.getDocTypes('Case',BANK_ACC_DTAIL_SR_RT);
        List<Document__c> documentList = new List<Document__c>();
        for(Case caseObj :listOfCases){
            for(DocumentType__c objDocumentType :caseDocTypeList){
                documentList.add(new Document__c(Case__c = caseObj.Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c));
            }
        }
        objDocumentService.insertDocuments(documentList);
        autoCreateDocument(listOfCases,listOfCases[0].Sales_Order__c); 
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

    public void createFirstTask(List<Case> listOfCases) {
        ServiceRequestTaskHandler obj = ServiceRequestTaskHandler.getInstance();
        listOfCases[0].step__c = financeScenario == true ? '3' : listOfCases[0].step__c;
        obj.createNewAndCloseCurrentTask(listOfCases);
    }

    public Map<String, Object> validateCaseForNextReview(Case caseRecord) {
        List<Messaging.SingleEmailMessage> emailList = new list<Messaging.SingleEmailMessage>();
        EmailService emlService = EmailService.getInstance();
        CaseService service = Caseservice.getInstance();
        Map<String, Object> response = new Map<String, Object>();
        
        if (caseRecord == null) {
            response.put('status', 'error');
            response.put('message', 'Invalid Case ID.');
            return response;
        }
        if(caseRecord.Step__c =='4'){
            forceCloseCurrentTaks(caseRecord);
            caseRecord.Step__c ='Final';
        }
        if(caseRecord.Step__c =='1'){
            if(caseRecord.POPUploaded__c != 'Yes'){
                response.put('status', 'error');
                response.put('message', 'Kindly upload Proof of Payment and mark \'POP Uploaded\' as yes');
                return response;
            }
            response = validateDocs(caseRecord, new Set<String>{'Proof of Payment'});
            if(response.get('status') == 'error'){
                        return response;
            }
            createFirstTask(new List<Case>{caseRecord});
        }
        if(caseRecord.Step__c =='Final'){

            if(String.isEmpty(caseRecord.POPUploaded__c) || caseRecord.POPUploaded__c != 'Yes'){
                response.put('status', 'error');
                response.put('message', 'Kindly upload Proof of Payment and mark \'POP Uploaded\' as ye');
                return response;
            } else{
                
                    response = validateDocs(caseRecord, new Set<String>{'Proof of Payment'});
                    if(response.get('status') == 'error'){
                        return response;
                    } 
                             
            }

            if(String.isEmpty(caseRecord.IsThirdPartyNeeded__c)){
                response.put('status', 'error');
                response.put('message', 'Kindly confirm if 3rd Party data needed or not.');
                return response;               
            }
            if(caseRecord.IsThirdPartyNeeded__c == 'No'){
                response = finaliValidation(caseRecord);
                if(response.get('status') == 'error'){
                    return response;
                }
            }else{
                response = validateDocs(caseRecord, new Set<String>{'Third Party Form','Third Party EID'});
                if(response.get('status') != 'error'){
                    response = finaliValidation(caseRecord);
                    if(response.get('status') == 'error'){
                        return response;
                    }
                } else{
                    forceCloseCurrentTaks(caseRecord);
                    caseRecord.step__c = '2';
                    if(!test.isRunningTest()){
                        AssignmentRuleService objAssignmentRuleService = AssignmentRuleService.getInstance();
                        AssignmentRule__c objAssignmentRule = objAssignmentRuleService.getAssignmentRuleAndUsers('Case', 'CRM Case Assignment','Sales');
                        if(objAssignmentRule != NULL){
                            List<AssignmentUser__c> assignmentUserList = objAssignmentRuleService.getAvailableAssignmentUsers(objAssignmentRule.AssignmentUsers__r);
                            List<Case> caseList = objAssignmentRuleService.assignRecordOwner(new list<Case>{caseRecord}, objAssignmentRule, assignmentUserList);
                            service.updateCasesWithoutTrigger(caseList); 
                        }
                    }
                    caserecord = service.getCaseById(caseRecord.Id);
                    createFirstTask(new List<Case>{caseRecord});
                    
                }
            }
        }
        if(caseRecord.Step__c =='3'){
            if(String.isEmpty(caseRecord.TPFType__c)){
                response.put('status', 'error');
                response.put('message', 'Please send third party form to the Customer.');
                return response;
            }
            response = validateDocs(caseRecord, new Set<String>{'Third Party Form','Third Party EID'});
            if(response.get('status') == 'error'){
                        return response;
            }
            else{
                forceCloseCurrentTaks(caseRecord);
                caseRecord.step__c = '1';
                createFirstTask(new List<Case>{caseRecord});
            }
        }

        if(response.get('message') != 'Case closed successfully.'){
            response.put('message', 'Case moved to next review successfully.');    
        }
        response.put('status', 'success');   
        return response;
    }

    public Map<String,Object> finaliValidation ( case caseRecord){
        Map<String, Object> response = new Map<String, Object>();
        if(String.isEmpty(caseRecord.Payment_Booked__c) || caseRecord.Payment_Booked__c == 'No'
        || String.isEmpty(caseRecord.Finance_document_verified__c) || caseRecord.Finance_document_verified__c == 'No'){
            response.put('status', 'error');
            response.put('message', 'Payment should be booked along with Finance document verification');
            return response;
        }
        if(String.isEmpty(caseRecord.FinanceDocumentsUploadedManually__c)){
            response.put('status', 'error');
            response.put('message', 'Kindly confirm if finance documents uploaded manually');
            return response;
        }
        if(caseRecord.FinanceDocumentsUploadedManually__c != 'Yes')
        autoCreateDocument(new List<Case>{caseRecord},caseRecord.Sales_Order__c);
       
        createFirstTask(new List<Case>{caseRecord});
        response.put('message', 'Case closed successfully.'); 
        return response;
    }

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
        CaseService csService = CaseService.getInstance();
        Case cs = csService.getCaseById(whatId);
        
        AccountService accService = AccountService.getInstance();
        List<String> toAddress = new List<String>{accService.getRelatedContactEmail(cs.AccountId)};
        
        MetadataService objMetadataService = MetadataService.getInstance();
        
        Id noReplyOWDId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
        EmailService emlService = EmailService.getInstance();
        Id emailTemplateId;
        String emailtemplate = scenario == 'TPForm' ? THIRD_PARTY_FORM_REQUEST_EMAIL_TEMPLATE_ID : scenario == 'Closure' ? SERVICE_REQUEST_CUSTOMER_CLOSURE_EMAIL_TEMPLATE_ID
            : scenario == 'Enquiry' ? CLARIFICATION_EMAIL_TEMPLATE_ID :  scenario == 'BankDetals' ? BANK_DETAILS_EMAIL_TEMPLATE_ID :'';
        
        system.debug('requiredEmailTemplate>>'+emailtemplate);
        emailTemplateId = objMetadataService.getAppSettingTextValue(emailtemplate);
        Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(emailTemplateId, null, whatId);
        if(!cs.StopEmailsToCustomer__c){
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
            mail.htmlBody = mail.htmlBody.contains('{Bank_Name}') && !String.isEmpty(cs.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.BankNameCorporate__c) ? mail.htmlBody.replace('{Bank_Name}',cs.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.BankNameCorporate__c):mail.htmlBody;
            mail.htmlBody = mail.htmlBody.contains('{Account_Name}') && !String.isEmpty(cs.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.Name) ? mail.htmlBody.replace('{Account_Name}',cs.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.Name):mail.htmlBody;           
            mail.htmlBody = mail.htmlBody.contains('{Acc_No}') && !String.isEmpty(cs.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.AccountNumberCorporate__c) ? mail.htmlBody.replace('{Acc_No}',cs.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.AccountNumberCorporate__c):mail.htmlBody;
            mail.htmlBody = mail.htmlBody.contains('{IBAN}') && !String.isEmpty(cs.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.IBANNoCorporate__c) ? mail.htmlBody.replace('{IBAN}',cs.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.IBANNoCorporate__c):mail.htmlBody;
            mail.htmlBody = mail.htmlBody.contains('{Swift_Code}') && !String.isEmpty(cs.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.SwiftCodeCorporate__c) ? mail.htmlBody.replace('{Swift_Code}',cs.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.SwiftCodeCorporate__c):mail.htmlBody;
            
            mail.setSaveAsActivity(true);
            mail.setTreatTargetObjectAsRecipient(false);
            if(scenario == 'Closure'){
                List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
                for(Messaging.EmailFileAttachment attachment : emlService.getCaseAttachments(cs.Id)){
                    if(attachment.getFileName().contains('SOA') || attachment.getFileName().contains('Payment Receipt')){
                        attachments.add(attachment);
                    }
                }
                mail.setFileAttachments(attachments);
            }
            if(scenario == 'BankDetals' || scenario == 'TPForm' || scenario == 'Enquiry'){
            //if(scenario == 'BankDetals' || scenario == 'TPForm'){
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
                mail.setFileAttachments(atList);
            }      
            if(test.isRunningTest()){
                return null;
            }
        }
        return mail;
    }

    public Map<String, String> sendClarificationEmail(case cs, List<String> descriptions, String type){
        Map<String, String> result = new Map<String, String>();
        List<Messaging.SingleEmailMessage> emailList = new list<Messaging.SingleEmailMessage>();
        EmailService emlService = EmailService.getInstance();
         Messaging.SingleEmailMessage email;
        if(type == Null){
            email = sendCustomerEmail(cs.id,'Enquiry',descriptions, cs.TPFType__c);
        } else{
            email = sendCustomerEmail(cs.id,'TPForm',descriptions, type);
        }
        if(email != null) emailList.add(email);
        if(!test.isRunningTest() && !emailList.isEmpty())emlService.sendEmail(emailList);

        if(email != NULL){
            result.put('status','success'); 
            result.put('message', 'Email Sent Successfully.'); 
        }          
        return result;
    }
}