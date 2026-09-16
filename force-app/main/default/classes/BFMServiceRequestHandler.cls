/*****************************************************************************************
Class       : BFMServiceRequestHandler
Author      : Vikas Baliyan
Description : 
test Class: 
Created Date: 04 MAR 2025
*****************************************************************************************/
public inherited sharing class BFMServiceRequestHandler { 
    
    private static final string BFM_SERVICE_REQUEST { get { return 'BFM Service Request'; } }
    private static final string COMMON_AREA_REQUEST { get { return 'Common_Area_Request'; } }
    private static final string BFM_TEAM { get { return 'BFM Team'; } }
    private static final String MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final string MTD_BFM_CASE_CLOSURE_EMAIL_TEMP_ID { get { return 'BFMCaseClosureEmailTempId'; } }
    private static final string MTD_BFM_CASE_CREATION_EMAIL_TEMP_ID { get { return 'BFMCaseCreationEmailTempId'; } }
    private static final string COMPLETED_STR { get { return 'COMPLETED'; } }
    private static final string CLOSED_STR { get { return 'CLOSED'; } }
    private static final string BFM_SR_CREATE_NOTIFICATION { get { return 'BFM SR Create Notification'; } }
    private static final string BFM_SR_CLOSURE_NOTIFICATION { get { return 'BFM SR Closure Notification'; } }
    private static final string BFM_SERVICE_REQUEST_RT_DEV_Name { get { return 'BFMServiceRequest'; } }
    private static final string MTD_BFM_CASE_CREATION_INTERNAL_EMAIL_TEMP_ID { get { return 'BFMCaseCreationEmailForInternalUsers'; } }
    
    private static BFMServiceRequestHandler instance;
    
    private BFMServiceRequestHandler() {
        
    }
    
    public static BFMServiceRequestHandler getInstance() { 
        if(instance == null) {
            instance = new BFMServiceRequestHandler();
        }
        return instance;
    }
    
    // check case record eligibility
    public String validateEligibility(Case caseObj){
        String message;
        List<String> missingFields = new List<String>();
        if (caseObj.AccountId == null){missingFields.add('Account Name');}
        
        if (!missingFields.isEmpty()) {
            return 'Conversion is not allowed. The following fields are required: ' + String.join(missingFields, ', ') + '.';
        }
        return message;
    }
    
    // Convert case record type
    public  Map<String, String> convertToBFMServiceRequest(Id recordID, ServiceCatalog__c sc, Id accountId, Id unitId,String type,String description,String origin) {
        Map<String, String> response = new Map<String, String>();
        Case caseObj = new Case();
        AccountService accService = AccountService.getInstance();
        CaseService caseServiceObj = CaseService.getInstance(); 
        caseObj.id = recordID;
        caseObj.RecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,sc.RecordTypeDevName__c);
        caseObj.ServiceCatalog__c = sc.id;
        
        String requesterContactNumber = '';
        String requesterEmail = '';
        if(accountId != null){
            Account acc = accService.getAccountById(accountId);
            if(acc.IsPersonAccount){
                requesterContactNumber = acc.PersonMobilePhone;
                requesterEmail = acc.PersonEmail;
            }
            else{
                ContactService contactObj = ContactService.getInstance();
                List<Contact> conList = contactObj.getPrimaryContactByAccountId(acc.Id, true);
                if(!conList.isEmpty()){
                    requesterContactNumber = conList[0].MobilePhone;
                    requesterEmail = conList[0].Email;
                }
            }
            caseObj.RequesterName__c = acc.Name;
        }
        caseObj.RequesterContactNumber__c = requesterContactNumber;
        caseObj.RequesterEmail__c = requesterEmail;
        caseObj.AccountId = accountId;
        caseObj.Description = description;
        caseObj.Origin = origin;
        caseObj.CaseType__c = type;
        if(unitId != null){caseObj.Unit__c = unitId;}
        case updatedCase = caseServiceObj.updateCase(caseObj);
        if(updatedCase != null){
            response.put('status', 'success');
            response.put('message', 'Case Record updated successfully.');            
        }
        return response;
    }
    
    //Auto assign priority bases on category and subcategory from metadata
    public Map<String, String> getPriorityBySubCategory(){
        Map<String, String> subCategoryToPriorityMap = new Map<String, String>();
        
        MetadataService objMetadataService = MetadataService.getInstance();
        
        for (BFMSubcategoryPriorityMapping__mdt mapping : objMetadataService.getBFMSubcategoryPriorityMapping()) {
            if (String.isNotBlank(mapping.SubCategory__c)) {
                subCategoryToPriorityMap.put(mapping.SubCategory__c, mapping.Priority__c);
            }
        }
        
        return subCategoryToPriorityMap;
    }
    
    //Validate BFM Case before sending to nectar
    public String validateBFMEligibility(Case caseObj){
        String message;
        List<String> missingFields = new List<String>();
        if (caseObj.Subject == null){missingFields.add('Subject');}
        if (caseObj.RequesterRemarks__c == null) {missingFields.add('Requester Remarks');}
        if (caseObj.RequesterName__c == null) {missingFields.add('Requester Name');}
        if (caseObj.Origin == 'Email' && caseObj.RequesterEmail__c == null) {missingFields.add('Requester Email');}
        if (caseObj.Origin != 'Email' && caseObj.RequesterContactNumber__c == null) {missingFields.add('Requester Contact Number');}
        if (caseObj.Priority == null) {missingFields.add('Priority');}
        if (caseObj.Type == null) {missingFields.add('Type');}
        if (caseObj.SubType__c == null) {missingFields.add('Sub Type');}
        if (caseObj.Category__c == null) {missingFields.add('Category');}
        if (caseObj.SubCategory__c == null) {missingFields.add('Sub Category');}
        if (caseObj.Origin == null) {missingFields.add('Origin');}
        if (caseObj.Area__c == null) {missingFields.add('Area');}
        if (caseObj.Type == 'BFM Community Request' && caseObj.Unit__c == null) {missingFields.add('Unit');}
        
        if (!missingFields.isEmpty()) {
            return 'The following fields are required: ' + String.join(missingFields, ', ') + '.';
        }   
        return message;
    }
    
    public IntegrationRecord__c getIntegrationRecordObj(Case caseRec){
        IntegrationRecordService integService = IntegrationRecordService.getInstance();
        BFMContractService contractService = BFMContractService.getInstance();
        List<BFMContract__c> contractList = contractService.getBFMContractWithinRange(caseRec.Unit__c);
        String integrationType = '';
        String param4;
        String param5;
        String param6;
        if (caseRec.Type == 'BFM Community Request') {
            integrationType = 'BFM_COMMUNITY_SR';
            param4 = caseRec.Unit__r != null && caseRec.Unit__r.Building__r != null ? caseRec.Unit__r.Building__r.Name : '';
            param5 = caseRec.Unit__r != null ? caseRec.Unit__r.ADMAddressingNumber__c : '';
            param6 = caseRec.RequesterName__c;
        } else if (caseRec.Type == 'Common Area Request') {
            integrationType = 'COMMON_AREA_SR';
            param4 = caseRec.CommonArea__r != null  ? caseRec.CommonArea__r.CommonAreaName__c : '';
            param5 = caseRec.CommonArea__r != null ? caseRec.CommonArea__r.Name : '';
            param6 = caseRec.RequesterName__c == null ? caseRec.CreatedBy.Name : caseRec.RequesterName__c;
        }
        
        List<String> CommunicationChannel = new List<String>();
        if(String.isNotBlank(caseRec.RequesterContactNumber__c)){
            CommunicationChannel.addAll(new List<String>{'SMS', 'WhatsApp'});
        }
        if(String.isNotBlank(caseRec.RequesterEmail__c)){
            CommunicationChannel.add('Email');
        }
        
        Map<String, String> paramMap = new Map<String, String>();
        paramMap.put('Param1', caseRec.SubType__c);
        paramMap.put('Param2', caseRec.Subject);
        paramMap.put('Param3', caseRec.RequesterRemarks__c);
        paramMap.put('Param4', param4);
        paramMap.put('Param5', param5);
        paramMap.put('Param6', param6);
        paramMap.put('Param7', caseRec.RequesterContactNumber__c != null ? String.valueOf(caseRec.RequesterContactNumber__c) : String.valueOf(caseRec.CaseNumber));
        paramMap.put('Param8', String.valueOf(caseRec.RequesterEmail__c));
        paramMap.put('Param9', caseRec.Priority);
        paramMap.put('Param10', caseRec.Category__c);
        paramMap.put('Param11', caseRec.SubCategory__c);
        paramMap.put('Param12', '');
        paramMap.put('Param13', caseRec.Origin);
        paramMap.put('Param14', caseRec.InAMC__c ? 'TRUE' : 'FALSE');
        paramMap.put('Param15', caseRec.InScope__c ? 'TRUE' : 'FALSE');
        paramMap.put('Param16', caseRec.Area__c);
        paramMap.put('Param17', UserInfo.getName());
        paramMap.put('Param18', caseRec.Account != null && caseRec.Account.IsBFMVIPCustomer__c ? 'TRUE' : 'FALSE');
        paramMap.put('Param19', caseRec.CaseNumber);
        paramMap.put('Param20', integrationType == 'COMMON_AREA_SR' ? '' : contractList != null && !contractList.isEmpty() && contractList[0].ContractSpecification__c != null ? contractList[0].ContractSpecification__c.toUpperCase() : '');
        paramMap.put('LongTextParam1', caseRec.Description);
        paramMap.put('Param22', caseRec.Type);
        paramMap.put('Param23', String.join(CommunicationChannel, ';'));
        
        return integService.getIntegrationRecord(integrationType, 'Insert', 'Case', caseRec.Id, paramMap);
    }
    
    public String handleSendToBFM(Id recordId){
        CaseService caseServiceObj = CaseService.getInstance();
        Case caseRec = caseServiceObj.getCaseById(recordId);
        String message = validateBFMEligibility(caseRec);
        if(!String.isBlank(message)){
            return message;
        }
        IntegrationRecordService integService = IntegrationRecordService.getInstance();
        IntegrationRecord__c integrationRecord = getIntegrationRecordObj(caseRec);
        
        // insert integration record
        integService.insertIntegrationRecords(new List<IntegrationRecord__c>{integrationRecord});
        
        // update case record to in-progress
        caseRec.IntegrationStatus__c = 'In Progress';
        caseRec.Status = 'In Progress';
        caseRec.SubStatus__c = 'Submitted to Nectar';
        
        if(caseRec.RecordType.DeveloperName == COMMON_AREA_REQUEST){
            caseRec.PendingWith__c = BFM_TEAM;
        }
        caseServiceObj.updateCaseWithoutTrigger(new List<Case>{caseRec});
        return '';
    }
    
    public void handleSubmitCaseComment(Id caseId, String commentBody){
        if (String.isBlank(commentBody)) {
            throw new AuraHandledException('Comment cannot be empty.');
        }
        CaseService caseServiceObj = CaseService.getInstance();
        Case caseObj = caseServiceObj.getCaseById(caseId);
        caseObj.Comments = commentBody;
        
        //update case obj
        caseServiceObj.updateCase(caseObj);
        
        if(caseObj.RecordType.DeveloperName == COMMON_AREA_REQUEST && caseObj.AssignTeam__c != 'BFM Team'){
            return;
        }
        //create integration event record
        IntegrationRecordService integService = IntegrationRecordService.getInstance();
        IntegrationRecord__c integrationRecord = integService.getIntegrationRecord(
            'Update',
            'Case',
            String.valueOf(caseId),
            String.valueOf(caseObj.BFMServiceRequestId__c),
            caseObj.Comments,
            '','','','','','','','','','','','','','','',''
        );
        
        // insert integration record
        integService.insertIntegrationRecords(new List<IntegrationRecord__c>{integrationRecord});
    }
    
    public Case createCaseRecord(
        SalesOrder__c salesOrderObj,
        ServiceCatalog__c sc,
        Id accountId,
        Id unitId,
        String type,
        String description,
        String origin,
        Id commonAreaId,
        Boolean stopCustomerCommunication
    ) {
        BFMContractService bfmContractobj = BFMContractService.getInstance();
        AccountService accService = AccountService.getInstance();
        User userObj = UserService.getInstance().getUsersById(UserInfo.getUserId());
        Case newCase = new Case();
        newCase.StopEmailsToCustomer__c = stopCustomerCommunication;
        
        String inAMC = 'false';
        if (salesOrderObj != null || unitId != null) {
            Id unitToCheck = (salesOrderObj != null) ? salesOrderObj.Unit__c : unitId;
            inAMC = bfmContractobj.getBFMContractWithinRange(unitToCheck).size() > 0 ? 'true' : 'false';
        }
        
        String requesterContactNumber = '';
        String requesterEmail = '';
        Account acc;
        
        if (accountId != null) {
            acc = accService.getAccountById(accountId);
            if (acc.IsPersonAccount) {
                requesterContactNumber = acc.PersonMobilePhone;
                requesterEmail = acc.PersonEmail;
            } else {
                ContactService contactService = ContactService.getInstance();
                List<Contact> conList = contactService.getPrimaryContactByAccountId(acc.Id, true);
                if (!conList.isEmpty()) {
                    requesterContactNumber = conList[0].MobilePhone;
                    requesterEmail = conList[0].Email;
                }
            }
        }

        if(commonAreaId != null){
            List<CommonArea__c> commonAreaList = CommonAreaService.getInstance().getCommonAreaByIds(new Set<Id>{commonAreaId});
            newCase.CommonArea__c = commonAreaList[0].Id;
            newCase.Community__c = commonAreaList[0].Community__c;
        }
        
        newCase.RequesterName__c = acc != null ? acc.Name : UserInfo.getName();
        newCase.RequesterEmail__c = String.isNotBlank(requesterEmail) ? requesterEmail : UserInfo.getUserEmail();
        newCase.RequesterContactNumber__c = String.isNotBlank(requesterContactNumber) ? requesterContactNumber : userObj.Phone;
    
        newCase.AccountId = (salesOrderObj != null) ? salesOrderObj.Account__c : accountId;
        newCase.RecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, sc.RecordTypeDevName__c);
        newCase.Unit__c = (salesOrderObj != null) ? salesOrderObj.Unit__c : unitId;
        newCase.Subject = sc.SubCategory__c;
        newCase.CaseType__c = type;
        newCase.ContactId = (accountId != null) ? accService.getRelatedContact(accountId) : null;
        
        if (salesOrderObj != null) {
            newCase.Sales_Order__c = salesOrderObj.Id;
        }
        
        newCase.InAMC__c = (inAMC == 'true');
        newCase.Status = 'New';
        newCase.Origin = origin;
        newCase.ServiceCatalog__c = sc.Id;
        newCase.Description = description;
        
        CaseService caseServiceObj = CaseService.getInstance();
        newCase = caseServiceObj.insertCase(newCase);
        return newCase;
    }
    
    public void sendBFMCaseCreationORClosureEmail(List<Id> caseIds){
        CaseService objCaseService = CaseService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        List<Case> caseList = objCaseService.getCaseByIds(new Set<Id>(caseIds));
        
        Id noReplyOWDId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
        Id bfmCaseClosureEmailTemplateId = objMetadataService.getAppSettingTextValue(MTD_BFM_CASE_CLOSURE_EMAIL_TEMP_ID);
        Id bfmCaseCreationEmailTemplateId = objMetadataService.getAppSettingTextValue(MTD_BFM_CASE_CREATION_EMAIL_TEMP_ID);
        
        for(Case caseObj : caseList){
            if(caseObj.StopEmailsToCustomer__c || ((caseObj.RecordType.DeveloperName == BFM_SERVICE_REQUEST_RT_DEV_Name || caseObj.RecordType.DeveloperName == COMMON_AREA_REQUEST) && String.isBlank(caseObj.RequesterEmail__c))){
                continue;
            }
            
            Id emailTemplateId = (caseObj.BFMRequestStatus__c == COMPLETED_STR || caseObj.BFMRequestStatus__c == CLOSED_STR) ? bfmCaseClosureEmailTemplateId : bfmCaseCreationEmailTemplateId;    
            
            Messaging.SingleEmailMessage objMail = objEmailService.getSingleEmailMessageWithoutTargetObjectId(emailTemplateId, noReplyOWDId, caseObj.Id, new List<String>{caseObj.RequesterEmail__c}, null, null);
            emailList.add(objMail);
        }
        objEmailService.sendEmail(emailList);
    } 
    
    // to send the SMS and whatsapp notification to requester
    public void sendBFMCaseCreationORClosureNotification(List<Id> caseIds){
        CaseService objCaseService  = CaseService.getInstance();
        NotificationService objNotificationService = NotificationService.getInstance();
        
        List<Case> caseList = objCaseService.getCaseByIds(new Set<Id>(caseIds));
        List<IntegrationRecord__c> integrationRecords = new List<IntegrationRecord__c>();
        Set<String> templateNames = new Set<String>{BFM_SR_CREATE_NOTIFICATION, BFM_SR_CLOSURE_NOTIFICATION};
        Map<String, SMSTemplate__c> smsTemplateMap = objNotificationService.getSMSTemplates(templateNames);
        Map<String, WhatsAppTemplate__c> whatsappTemplateMap = objNotificationService.getWhatsAppTemplates(templateNames);
        Id bfmRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, BFM_SERVICE_REQUEST_RT_DEV_Name);
        Id commonAreaRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, COMMON_AREA_REQUEST);
        for(Case caseObj : caseList){
            if(caseObj.StopEmailsToCustomer__c || (String.isBlank(caseObj.RequesterContactNumber__c) && (caseObj.RecordTypeId == bfmRecordTypeId || caseObj.RecordTypeId == commonAreaRecordTypeId))){
                continue;
            }
            List<String> values = new List<String>{caseObj.RequesterName__c,caseObj.BFMServiceRequestId__c};
            String templateName;
            
            if(caseObj.BFMRequestStatus__c == COMPLETED_STR || caseObj.BFMRequestStatus__c == CLOSED_STR){
                templateName = BFM_SR_CLOSURE_NOTIFICATION;
            }
            else{
                templateName = BFM_SR_CREATE_NOTIFICATION;
            }

            integrationRecords.add(objNotificationService.getSMSIntegrationRecord(caseObj, smsTemplateMap.get(templateName), values));
            integrationRecords.add(objNotificationService.getWhatsappIntegrationRecord(caseObj, whatsappTemplateMap.get(templateName), values));
        }
        IntegrationRecordService objIntegrationRecordService = IntegrationRecordService.getInstance();
        objIntegrationRecordService.insertIntegrationRecords(integrationRecords);
    }

    /*public void sendBFMCaseCreationInternalEmail(Case objCase){
        if(objCase.Unit__r.Project__c != null && String.isNotBlank(objCase.Unit__r.Project__r.FMRecipientEmail__c)){
            CaseService objCaseService = CaseService.getInstance();
            EmailService objEmailService = EmailService.getInstance();
            MetadataService objMetadataService = MetadataService.getInstance();
            Id noReplyOWDId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
            Id bfmCaseCreationInternalEmailTemplateId = objMetadataService.getAppSettingTextValue(MTD_BFM_CASE_CREATION_INTERNAL_EMAIL_TEMP_ID);

            List<String> receiverEmailAddress = objCase.Unit__r.Project__r.FMRecipientEmail__c.split(',');
            Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(bfmCaseCreationInternalEmailTemplateId, null, objCase.Id);

            String htmlBody = mail.getHtmlBody();
            htmlBody = htmlBody.replace('[DoorNumber]', objCase.Unit__r.ADMAddressingNumber__c != null ? objCase.Unit__r.ADMAddressingNumber__c : '');

            Messaging.SingleEmailMessage objMail = objEmailService.getSingleEmailMessage(receiverEmailAddress, objCase.Id, mail.getSubject(), htmlBody, noReplyOWDId);
            objEmailService.sendEmail(new List<Messaging.SingleEmailMessage>{objMail});
        }
    }*/
}