/*****************************************************************************************
Class       : CommunitySiteController
Author      : Aman Bharti
Description : Vehicle Parking Controller
Test Class  : CommunitySiteControllerTest
Created Date: 16 July 2025 
*****************************************************************************************/

public without sharing class CommunitySiteController {
    
    private static final String VEHICLE_PARKING_REQUEST_RT { get { return 'VehicleParkingRequest'; } }
    private static final String WEB_STR { get { return 'Web';}}
    private static final String VEHICLE_PARKING_REGISTRATION_APPROVAL { get { return 'VehicleParkingRegistration'; } }
    private static final String BLOOM_NO_REPLY_SALES_OW_EMAIL_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final String VEHICLE_REGISTRATION_URL { get { return 'VehicleRegistrationURL'; } }
    private static final String VEHICLE_REGISTRATION_APPROVED_EMAIL_TEMPID { get { return 'VehicleRegistrationApprovedTempId'; } }
    private static final String VEHICLE_REGISTRATION_REJECTED_EMAIL_TEMPID { get { return 'VehicleRegistrationRejectedTempId'; } }
    private static final String TITLE_DEED_DOCUMENT_STR { get { return 'Title Deed Document'; } }
    private static final String TAWTHEEQ_EJARI_DOCUMENT_STR { get { return 'Tawtheeq /Ejari Document'; } }
    private static final String VEHICLE_PARKING_APPROVAL_PROCESS_SUBMITTER { get { return 'VehicleParkingApprovalProcessSubmitter'; } }
    private static final String ACTIVE_STR { get { return 'Active'; } }
    private static final String INACTIVE_STR { get { return 'Inactive'; } }
    private static final string BLOOM_CUSTOM_NOTIFICATION_ID { get { return 'BloomCustomNotifications'; } }
    
    
    
    @AuraEnabled(cacheable=true)
    public static List<Unit_Allocation__c> getUnitsForCustomer(Id customerId){
        Set<String> userTypeSet = new Set<String>{'Owner','Tenant'};
            UnitAllocationService service = new UnitAllocationService();
        return service.fetchUnitAllocationByAccIds(userTypeSet, new Set<Id>{customerId}, true, true);
    }
    
    @AuraEnabled(cacheable=false)
    public static Boolean hasActiveVehicleRequest(Id accountId, Id unitId){
        
        CaseService caseServiceObj = CaseService.getInstance();
        List<Case> activeVehicleReqList =  caseServiceObj.getActiveVehicleParkingRequest(accountId, unitId, 'In Progress');
        return activeVehicleReqList.size() > 0 ? true : false;
    }
    
    
    //Create Case and related Vehicle Parking Details record
    @AuraEnabled
    public static void createVehicleDetails(String allDetails) {
        CaseService caseServiceObj = CaseService.getInstance();
        ContentService objContentService = ContentService.getInstance();
        VehicleParkingService objVehicleParkingService = VehicleParkingService.getInstance();
        
        Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(allDetails);
        List<VehicleParkingDetails__c> vehicles = (List<VehicleParkingDetails__c>) JSON.deserialize(JSON.serialize(data.get('vehicles')),List<VehicleParkingDetails__c>.class);        
        //insert case record
        Case c = caseServiceObj.insertCase(createVehicleParkingCaseObj(data));
        
        //Attach document to case record based on the tenant or owner
        String docName = fetchDocumentName(data);
        List<Document__c> docs = createDocuments(c, docName);
        Map<String, Object> file = (Map<String, Object>)data.get('files');
        if (!docs.isEmpty()) {
            
            ContentVersion cv = objContentService.CreateContentVersionObj((String)file.get('filename'), (String)file.get('filename'), EncodingUtil.base64Decode((String)file.get('base64')),'C');
            cv.FirstPublishLocationId = docs[0].Id;
            objContentService.createContentVersion(new List<ContentVersion>{cv});
        }
        
        //update case id with newely created case
        for(VehicleParkingDetails__c vehicleDetail : vehicles ){
            vehicleDetail.Case__c = c.Id;
        }
        
        //insert vehicle Parking details with case id
        objVehicleParkingService.createVehicleParkingDetailRecord(vehicles);
    }
    
    public static List<Document__c> createDocuments(Case caseRec, String docName){
        DocumentService objDocumentService = DocumentService.getInstance();
        List<DocumentType__c> caseDocTypeList = objDocumentService.getDocTypes('Case', VEHICLE_PARKING_REQUEST_RT);
        List<Document__c> documentList = new List<Document__c>();
        for(DocumentType__c objDocumentType :caseDocTypeList){
            if(objDocumentType.Type__c == docName){
                documentList.add(new Document__c(Case__c = caseRec.Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c));
            }
        }
        return objDocumentService.insertDocuments(documentList);   
    }
    
    public static void invokeANPRApprovaProcess(List<Case> caseList){
        if (caseList == null || caseList.isEmpty()) return;
        MetadataService objMetadataService = MetadataService.getInstance();
        
        List<Approval.ProcessSubmitRequest> approvalList = new List<Approval.ProcessSubmitRequest>();
        for(Case c : caseList){
            //Create an approval request 
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(c.Id);
            req.setProcessDefinitionNameOrId(VEHICLE_PARKING_REGISTRATION_APPROVAL);
            req.setSubmitterId(objMetadataService.getAppSettingTextValue(VEHICLE_PARKING_APPROVAL_PROCESS_SUBMITTER));
            approvalList.add(req);
        }
        // Submit the approval request
        if (!approvalList.isEmpty()) {
            Approval.ProcessResult[] results = Approval.process(approvalList);
        }
    }
    
    public static void inactiveVehicleParkingByUnitIds(Set<Id> unitIds){
        VehicleParkingService objVehicleParkingService = VehicleParkingService.getInstance();
        List<VehicleParking__c> vpToUpdateList = new List<VehicleParking__c>();
        for(VehicleParking__c vp : objVehicleParkingService.getVehicleParkingByUnitIds(unitIds, ACTIVE_STR)){
            vp.Status__c = INACTIVE_STR;
            vp.EndDate__c = Date.today();
            vpToUpdateList.add(vp);
        }
        update vpToUpdateList;
    }
    
    public static void invokeApprovedNRejectedEmail(Set<Id> approvedCaseIds, Set<Id> rejectedCaseIds){
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        AccountService objAccountService = AccountService.getInstance();
        CaseService objCaseService = CaseService.getInstance();
        Set<Id> allCaseIds = new Set<Id>();
        allCaseIds.addAll(approvedCaseIds);
        allCaseIds.addAll(rejectedCaseIds);
        List<Case> caseList = objCaseService.getCaseByIds(allCaseIds);
        Id noReplyBloomSalesOWDId = objMetadataService.getAppSettingTextValue(BLOOM_NO_REPLY_SALES_OW_EMAIL_ID);
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        Map<Id, ProcessInstanceStep> caseIdToStepMap = new Map<Id, ProcessInstanceStep>();
        
        for(ProcessInstanceStep step :[SELECT Id,Comments,StepStatus,CreatedDate,Actor.Name,ProcessInstance.TargetObjectId FROM ProcessInstanceStep WHERE ProcessInstance.TargetObjectId IN : rejectedCaseIds AND StepStatus = 'Rejected' ORDER BY CreatedDate DESC]){
            caseIdToStepMap.put(step.ProcessInstance.TargetObjectId, step);
        }
        
        Set<Id> accSet = new Set<Id>();
        for(case c : caseList){
            if(!c.Account.isPersonAccount){
                accSet.add(c.AccountId);
            }
        }
        Map<Id, Account> accMap = new Map<Id, Account>(objAccountService.getAccountsWithPrimrayContact(accSet));
        String baseLink = objMetadataService.getAppSettingTextValue(VEHICLE_REGISTRATION_URL);
        Id approvedTempId = objMetadataService.getAppSettingTextValue(VEHICLE_REGISTRATION_APPROVED_EMAIL_TEMPID);
        Id rejectedTempId = objMetadataService.getAppSettingTextValue(VEHICLE_REGISTRATION_REJECTED_EMAIL_TEMPID);
        EmailTemplate approvedEmailTemp = objEmailService.getEmailTemplateById(approvedTempId);
        EmailTemplate rejectedEmailTemp = objEmailService.getEmailTemplateById(rejectedTempId);
        for(case c : caseList){
            String emailBody;
            String emailSubject;
            if(c.VehicleRegistrationStatus__c == 'Approved'){
                emailBody = approvedEmailTemp.HtmlValue;
                emailSubject = approvedEmailTemp.Subject;
            }
            else if(c.VehicleRegistrationStatus__c == 'Rejected'){
                emailBody = rejectedEmailTemp.HtmlValue;
                emailSubject = rejectedEmailTemp.Subject;
            }else{
                continue;
            }
            emailBody = emailBody.replace('[Link]', '<a href="' + baseLink + c.AccountId + '">Click here</a>'); 
            emailBody = emailBody.replace('[Reason]', caseIdToStepMap.containsKey(c.Id) ? caseIdToStepMap.get(c.Id).Comments : ''); 
            emailBody = emailBody.replace('[RequesterName]', c.Account.Name);
            emailBody = emailBody.replace('[RequesterArabicName]', c.Account.NameinArabic__c != null ? c.Account.NameinArabic__c : ''); 
            
            emails.add(objEmailService.getSingleEmailMessage(null, c.AccountId, (c.Account.isPersonAccount == true ?  c.Account.PersonContactId : !accMap.get(c.AccountId).Contacts.isEmpty() ? accMap.get(c.AccountId).Contacts[0].id : ''), emailSubject, emailBody, noReplyBloomSalesOWDId));
        }
        objEmailService.sendEmail(emails);
    }
    //create vehicle parking case record
    private static Case createVehicleParkingCaseObj(Map<String, Object> data){
        MetadataService objMetadataService = MetadataService.getInstance();
        Case newCase = new Case();
        newCase.RecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, VEHICLE_PARKING_REQUEST_RT);
        newCase.Origin = WEB_STR;
        newCase.AccountId = (String)data.get('accId');
        newCase.Unit__c = (String)data.get('unitId');
        newCase.Project__c = (String)data.get('projectId');
        newCase.Subject = 'ANPR Request-'+(String)data.get('accName')+'-'+(String)data.get('unitNumber');
        newCase.Status = 'In Progress';
        newCase.TawtheeqContractStartDate__c = String.isNotBlank((String) data.get('tawtheeqStartDate')) ? Date.valueOf((String) data.get('tawtheeqStartDate')) : null ;
        newCase.TawtheeqContractEndDate__c = String.isNotBlank((String) data.get('tawtheeqEndDate')) ? Date.valueOf((String) data.get('tawtheeqEndDate')) : null ;
        return newCase;
    }
    
    private static String fetchDocumentName(Map<String, Object> data) {
        Boolean isTenant = (data.get('isTenant') != null) && Boolean.valueOf(String.valueOf(data.get('isTenant')));
        Boolean isOwner = (data.get('isOwner') != null) && Boolean.valueOf(String.valueOf(data.get('isOwner')));
        if (isTenant) return TAWTHEEQ_EJARI_DOCUMENT_STR;
        if (isOwner) return TITLE_DEED_DOCUMENT_STR;
        return '';
    }
    
    @AuraEnabled(cacheable=true)
    public static Unit__c getUnitNVehicleParkingsByUnitIds(Id unitId){
        UnitService objUnitService = new UnitService();
        return objUnitService.getUnitNVehicleParkingsByUnitIds(unitId);
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getCountryRegionValues() {
        List<String> countryOptions = new List<String>();
        Schema.DescribeFieldResult fieldDescribe =  VehicleParkingDetails__c.CountryRegion__c.getDescribe();
        
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            if (entry.isActive()) {
                countryOptions.add(entry.getValue());
            }
        }
        System.debug('Country/Region Picklist Values: ' + countryOptions);
        
        return countryOptions;
    }
}