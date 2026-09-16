//============================ BCAPP_CaseController =============================
/*
* @Author : Eagles
* @CreatedDate : 26 Sept 2024
* @Name : BCAPP_CaseController
* @Description : This class is used to create the master data once request is Approved.
*/
/*****************************************************************************************************
* Version       Author                  Date             Comment
* 1.0           Eagles               26 Sept 2024       Initial draft  */

public without sharing class BCAPP_CaseController {
    private static final string POST_SALE_PAYMENT_DEFERRAL_RT { get { return 'Post_Sale_Payment_Deferral'; } }
    private static final string RESALE_PROPERTY_WITH_PPHP_RT { get { return 'Resale_Property_with_Post_Handover_Payment_Plan'; } }
    private static final string RESALE_PROPERTY_COMPLETED_PROJECT_RT { get { return 'Resale_Property_For_Completed_Project'; } }
    private static final string RESALE_PROPERTY_UNDER_CONSTRUCTION_RT { get { return 'Resale_Property_Under_Construction'; } }
    private static final string ACKNOWLEDGEMENT_RECEIPT_RT { get { return 'Acknowledgment_Receipt'; } }//Pranav
    private static final string PAYMENT_DUE_DATE_UPDATE_RT { get { return 'Payment_Due_Date_Update'; } }//Pranav
    private static final string THIRD_PARTY_FORM_RT { get { return 'ThirdPartyForm'; } }//Pranav
    private static final string PAYMENT_SR_RT { get { return 'Payment_SR'; } }//Pranav
    private static final string LPF_WAIVER_REQUEST_RT { get { return 'LPFWaiverRequest'; } }
    private static final string SOA_REQUEST_RT { get { return 'SOARequest'; } }
    private static final string POP_SHARE_SR_RT { get { return 'ProofofPaymentShared'; } }//Pranav
    private static final string BANK_ACC_DTAIL_SR_RT { get { return 'BankAccountDetailsInquiry'; } }//Pranav
    private static final string KYC_UPDATE_REQUEST_RT { get { return 'KYCUpdateRequest'; } }
    private static final string TAWTHEEQ_ENROLLMENT_RT { get { return 'TawtheeqEnrollment'; } }
    private static final String BROKER_GENERAL_SERVICES_RT {get { return 'Broker_General_Services'; }}

    @AuraEnabled
    public static Boolean updateCaseOwner(Id caseId) {
        try {
            // Get Record Type Ids
            Id postSalePaymentDeferralRT = Utility.getRecordTypeIdByDevName(Case.SObjectType, POST_SALE_PAYMENT_DEFERRAL_RT);
            Id resaleUnderConstructionRT = Utility.getRecordTypeIdByDevName(Case.SObjectType, RESALE_PROPERTY_UNDER_CONSTRUCTION_RT);
            Id resaleWithPHPP_RT = Utility.getRecordTypeIdByDevName(Case.SObjectType, RESALE_PROPERTY_WITH_PPHP_RT);
            Id resaleCompletedProjectRT = Utility.getRecordTypeIdByDevName(Case.SObjectType, RESALE_PROPERTY_COMPLETED_PROJECT_RT);
            Id acknowledgementRcptRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,ACKNOWLEDGEMENT_RECEIPT_RT);//Pranav
            Id pymntDuDtUpdtRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,PAYMENT_DUE_DATE_UPDATE_RT);//Pranav
            Id thrdPrtyFrmRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,THIRD_PARTY_FORM_RT);//Pranav
            Id pymntRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,PAYMENT_SR_RT);//Pranav
            Id LPFRequestRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,LPF_WAIVER_REQUEST_RT);
            Id SOARequestRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType,SOA_REQUEST_RT);
            Id popShareSrRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,POP_SHARE_SR_RT);//Pranav
            Id bnkAccDtlRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType,BANK_ACC_DTAIL_SR_RT);//Pranav
            Id caseDelayedCommissionPaymentRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, 'DelayedCommissionPayment' ); // BAPP Broker
            Id caseIncorrectCommissionAmountRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, 'IncorrectCommissionAmount' ); // BAPP Broker
            Id caseOtherServiceRequestRecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, 'OtherServiceRequest' ); // BAPP Broker
            Id KYCUpdateRequestRTId = Utility.getRecordTypeIdByDevName(Case.SObjectType, KYC_UPDATE_REQUEST_RT);
            Id tawtheeqEnrollmentRTID = Utility.getRecordTypeIdByDevName(Case.SObjectType, TAWTHEEQ_ENROLLMENT_RT);
            Id brokerGeneralServicesRT = Utility.getRecordTypeIdByDevName(Case.SObjectType,BROKER_GENERAL_SERVICES_RT);
            // Initialize services and retrieve case
            CaseService caseService = CaseService.getInstance();
            ActivityService activityService = ActivityService.getInstance();
            Case caseObj = caseService.getCaseById(caseId);
            Integer step;
            
            // Determine step
            if (caseObj.Step__c == 'Final') {
                if (caseObj.RecordTypeId == postSalePaymentDeferralRT ||
                    caseObj.RecordTypeId == acknowledgementRcptRTID ||
                    caseObj.RecordTypeId == pymntDuDtUpdtRTID ||
                    caseObj.RecordTypeId == thrdPrtyFrmRTID ||
                    caseObj.RecordTypeId == SOARequestRecordTypeId ||
                    caseObj.RecordTypeId == LPFRequestRecordTypeId ||
                    caseObj.RecordTypeId == popShareSrRTID ||
                    caseObj.RecordTypeId == bnkAccDtlRTID ||
                    caseObj.RecordTypeId == KYCUpdateRequestRTId ||
                    caseObj.RecordTypeId == brokerGeneralServicesRT
                    ) {
                        step = 2;
                } else if (caseObj.RecordTypeId == resaleUnderConstructionRT) {
                    step = 6;
                } else if (caseObj.RecordTypeId == resaleWithPHPP_RT) {
                    step = (caseObj.City__c == 'Abu Dhabi') ? 7 : (caseObj.City__c == 'Dubai') ? 6 : null;
                } else if (caseObj.RecordTypeId == resaleCompletedProjectRT) {
                    step = (caseObj.City__c == 'Abu Dhabi') ? 7 : (caseObj.City__c == 'Dubai') ? 4 : null;
                }
                //Pranav
                else if(caseObj.RecordTypeId == pymntRTID || caseObj.RecordTypeId == tawtheeqEnrollmentRTID){
                    step = 3;
                }
                
            } else {
                step = Integer.valueOf(caseObj.Step__c);
            }
            
            // Get open tasks
            List<Task> openTasks = activityService.getOpenTaskForCaseByOrder(caseObj, step);
            // Update case owner
            // BAPP Broker: If the Case record type is 'DelayedCommissionPayment', 'IncorrectCommissionAmount', or 'OtherServiceRequest'
            // and the current status is 'New', then update the status to 'In Progress'.
            Case updatedCase = new Case(Id = caseId, OwnerId = UserInfo.getUserId(), Status = (caseObj.Status == 'New' && (caseObj.RecordTypeId == caseDelayedCommissionPaymentRecordTypeId || caseObj.RecordTypeId == caseIncorrectCommissionAmountRecordTypeId || caseObj.RecordTypeId == caseOtherServiceRequestRecordTypeId)) ? 'In Progress' : caseObj.Status);
            caseService.updateCase(updatedCase);
            
            // Update task owner and log assignment history if tasks found
            if (!openTasks.isEmpty()) {
                Task taskToUpdate = new Task(Id = openTasks[0].Id, OwnerId = UserInfo.getUserId());
                
                CaseAssignmentHistory__c history = new CaseAssignmentHistory__c(
                    Case__c = openTasks[0].WhatId,
                    AssignedBy__c = UserInfo.getUserId(),
                    OwnerId = UserInfo.getUserId(),
                    AssignmentDate__c = System.now(),
                    Reason__c = 'Assigned from Queue to User'
                );
                
                CaseAssignmentHistoryService.getInstance().insertCaseAssignmentHistory(
                    new List<CaseAssignmentHistory__c>{ history }
                );
                activityService.updateTask(taskToUpdate);
            }
            
            return true;
        } catch (Exception e) {
               System.debug('===== UPDATE CASE OWNER ERROR =====');
    System.debug('Message: ' + e.getMessage());
    System.debug('Type: ' + e.getTypeName());
    System.debug('Line: ' + e.getLineNumber());
    System.debug('Stack: ' + e.getStackTraceString());

            throw new AuraHandledException('Failed to update case owner: ' + e.getMessage());
        }
    }
    @AuraEnabled
    public static Boolean checkDocumentsAndSubmit(Id caseId) {
        CustomerDocumentService cDocumentService = new CustomerDocumentService();
        CaseService cService = CaseService.getInstance();
        List<Customer_Document__c> documents = cDocumentService.getCustomerDocuments(
            caseId
        ); //[SELECT Id FROM Customer_Document__c WHERE Case__c = :caseId ];
        
        if (documents.isEmpty()) {
            return false;
        }
        
        Set<Id> documentIds = new Set<Id>();
        for (Customer_Document__c doc : documents) {
            documentIds.add(doc.Id); 
        }
        
        List<ContentDocumentLink> contentLinks = ContentService.getContentDocumentLink(
            documentIds
        );
        Set<Id> documentsWithFiles = new Set<Id>();
        for (ContentDocumentLink link : contentLinks) {
            documentsWithFiles.add(link.LinkedEntityId);
        }
        
        if (documentsWithFiles.size() == documents.size()) {
            // All documents have files, so update the Case status to 'Submitted'
            Case caseRecord = new Case();
            caseRecord.Id = caseId;
            caseRecord.Status = 'Submitted';
            // update caseRecord;
            cService.updateCase(caseRecord);
            return true;
        } else {
            // Not all documents have files
            return false;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getCaseDetails(Id caseId) {
        CaseService cService = CaseService.getInstance();
        Case caseRecord = cService.getCaseById(caseId);
        String caseStatus = caseRecord.Status;
        
        // Checking if the case is assigned to a queue
        Boolean isAssignedToQueue = String.valueOf(caseRecord.OwnerId)
            .startsWith('00G');
        // Check if the current user is a member of the assigned queue
        Boolean isCurrentUserQueueMember =
            QueueService.currentUserQueueMember(caseRecord.OwnerId).size() > 0;
        
        return new Map<String, Object>{
            'caseStatus' => caseStatus,
                'isAssignedToQueue' => isAssignedToQueue,
                'isCurrentUserQueueMember' => isCurrentUserQueueMember,
                'caseOwnerId' => caseRecord.OwnerId,
                'currentUserId' => UserInfo.getUserId()
                };
                    }
    public static void handleRenew(case caseRecord, List<String> lstEmails) {
        User_Service uService = new User_Service();
        UnitAllocationService uaService = new UnitAllocationService();
        
        List<User__c> userList = new List<User__c>();
        userList = uService.getUsersByAzure(caseRecord.AccountID);
        
        Account eachAccount = new Account();
        eachAccount.Id = caseRecord.AccountID;
        eachAccount.EJARI_Tawteeq_end_date__c = caseRecord.EJARI_Tawteeq_end_date__c;
        eachAccount.Total_Number_of_Adults_Occupants__c = caseRecord.Total_Number_of_Adults_Occupants__c;
        eachAccount.Total_Number_of_Child_Occupants__c = caseRecord.Total_Number_of_Child_Occupants__c;
        update eachAccount;
        
        Service_Contract__c contract = new Service_Contract__c();
        contract.Customer_Name__c = caseRecord.AccountID;
        contract.Unit_Number__c = caseRecord.Unit__c;
        contract.EJARI_Tawteeq_end_date__c = caseRecord.EJARI_Tawteeq_end_date__c;
        contract.EJARI_Tawteeq_number__c = caseRecord.EJARI_Tawteeq_number__c;
        contract.EJARI_Tawteeq_start_date__c = caseRecord.EJARI_Tawteeq_start_date__c;
        contract.Emergency_contact_01__c = caseRecord.Emergency_contact_01__c;
        contract.Emergency_contact_02__c = caseRecord.Emergency_contact_02__c;
        contract.Move_In_Date__c = caseRecord.Move_In_Date__c;
        contract.Occupant_with_special_needs__c = caseRecord.Occupant_with_special_needs__c;
        contract.Special_Needs_Comments__c = caseRecord.Special_Needs_Comments__c;
        contract.Total_Number_of_Adults_Occupants__c = caseRecord.Total_Number_of_Adults_Occupants__c;
        contract.Total_Number_of_Child_Occupants__c = caseRecord.Total_Number_of_Child_Occupants__c;
        ServiceContractService.insertService(contract);
        
        List<Unit_Allocation__c> unitAllocation = new List<Unit_Allocation__c>();
        unitAllocation = uaService.fetchUnitAllocationDetailsbyUnit(
            caseRecord.Unit__c,
            userList[0].Account__c
        );
        // unitAllocation[0].Start_Date__c = unitAllocation[0].End_Date__c +1;
        unitAllocation[0].End_Date__c = caseRecord.EJARI_Tawteeq_end_date__c;
        uaService.updateUnitAllocation(unitAllocation[0]);
    }
    public static void handleMoveOut(case caseRecord, List<String> lstEmails) {
        UnitAllocationService uaService = new UnitAllocationService();
        User_Service uService = new User_Service();
        List<User__c> userList = new List<User__c>();
        userList = uService.getUsersByAzure(
            caseRecord.Account.Azure_UserPrincipal_Id__c
        );
        if (userList.size() > 0) {
            userList[0].Is_Azure_Active__c = false;
            uService.updateUser(userList[0]);
        }
        
        List<Unit_Allocation__c> unitAllocation = new List<Unit_Allocation__c>();
        unitAllocation = uaService.fetchUnitAllocationDetailsbyUnit(
            caseRecord.Unit__c,
            caseRecord.AccountId
        );
        
        // unitAllocation[0].Active__c=false;
        unitAllocation[0].End_Date__c = caseRecord.Move_Out_Date__c;
        uaService.updateUnitAllocation(unitAllocation[0]);
        UnitService unitService = new UnitService();
        List<Unit__c> units = new List<Unit__c>{
            new Unit__c(Id = caseRecord.Unit__c, Occupancy_Type__c = 'Available')
                };
                    unitService.updateUnits(units);
        
        List<Service_Contract__c> lstContracts = ServiceContractService.lstSContrscts(
            caseRecord.AccountId
        );
        lstContracts[0].Move_Out_Date__c = caseRecord.Move_Out_Date__c;
        ServiceContractService.updateService(lstContracts[0]);
        
        sendApprovalEmail(
            'Approval_of_Move_Out_request_to_applicant',
            lstEmails,
            true,
            caseRecord.iD
        );
        BCAPP_PushNotificationAPI.PushNotificationParams nParams = new BCAPP_PushNotificationAPI.PushNotificationParams(caseRecord.deviceRegistrationId__c,'Approved','Move In Approved',caseRecord.CaseNumber,'Approved');

        List<BCAPP_PushNotificationAPI.PushNotificationParams> notifyParams = new List<BCAPP_PushNotificationAPI.PushNotificationParams>{nParams};

        System.enqueueJob(new BCAPP_PushNotificationAPI(notifyParams));
    }
    public static void handleMoveIn(case caseRecord, List<String> lstEmails) {
        CaseService cService = CaseService.getInstance();
        User_Service uService = new User_Service();
        List<User__c> userList = new List<User__c>();
        BCAPP_Utility utiRef = new BCAPP_Utility();
        string emailAddress=caseRecord.Email_Address__c;
        if(emailAddress==null || emailAddress==''){
            emailAddress=caseRecord.Representative_Email__c;
        }
        if(emailAddress!=null && emailAddress!='')
            userList = uService.getUsersByEmail(emailAddress);
        
        if (userList.size() == 0) {
            cService.updateCase(caseRecord);
            //email template name logic needs to be changed.
            Account acRecord = new Account();
            if (caseRecord.User_Type__c == 'Holiday Homes') {
                acRecord.Name = caseRecord.Operator_Name__c;
                acRecord.Holiday_Homes__c = true;
                acRecord.Phone = caseRecord.Operator_Office_Number__c;
                acRecord.Operator_License_Number__c = caseRecord.Operator_License_Number__c;
                acRecord.Operator_license_Exp_Dtae__c = caseRecord.Operator_license_Exp_Dtae__c;
                acRecord.recordtypeid = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                    .get('OrganizationAccount')
                    .getRecordTypeId();
                acRecord.Move_In_Date__c = caseRecord.Move_In_Date__c;
                AccountService accService = AccountService.getInstance();
                accService.createAccount(acRecord);
                acRecord.EJARI_Tawteeq_number__c = caseRecord.EJARI_Tawteeq_number__c;
                acRecord.EJARI_Tawteeq_start_date__c = caseRecord.EJARI_Tawteeq_start_date__c;
                acRecord.EJARI_Tawteeq_end_date__c = caseRecord.EJARI_Tawteeq_end_date__c;
                acRecord.Emirates_ID_number__c = caseRecord.Emirates_ID_number__c;
                acRecord.Emirates_ID_expiry_date__c = caseRecord.Emirates_ID_expiry_date__c;
                acRecord.Emergency_contact_01__c = caseRecord.Emergency_contact_01__c;
                acRecord.Emergency_contact_02__c = caseRecord.Emergency_contact_02__c;
                acRecord.Operator_Office_Number__c = caseRecord.Operator_Office_Number__c;
                
                Service_Contract__c contract = new Service_Contract__c();
                contract.Customer_Name__c = acRecord.Id;
                contract.EJARI_Tawteeq_end_date__c = caseRecord.EJARI_Tawteeq_end_date__c;
                //contract.Move_Out_Date__c = caseRecord.EJARI_Tawteeq_end_date__c;
                contract.EJARI_Tawteeq_number__c = caseRecord.EJARI_Tawteeq_number__c;
                contract.EJARI_Tawteeq_start_date__c = caseRecord.EJARI_Tawteeq_start_date__c;
                contract.Emergency_contact_01__c = caseRecord.Emergency_contact_01__c;
                contract.Emergency_contact_02__c = caseRecord.Emergency_contact_02__c;
                contract.Move_In_Date__c = caseRecord.Move_In_Date__c;
                contract.Unit_Number__c = caseRecord.Unit__c;
                ServiceContractService.insertService(contract);
            } else if (caseRecord.User_Type__c == 'Tenant') {
                acRecord.FirstName = caseRecord.First_Name__c;
                acRecord.LastName = caseRecord.Last_Name__c;
                acRecord.PersonEmail = caseRecord.Email_Address__c;
                acRecord.Tenant__c = true;
                acRecord.EJARI_Tawteeq_start_date__c = caseRecord.EJARI_Tawteeq_start_date__c;
                acRecord.EJARI_Tawteeq_end_date__c = caseRecord.EJARI_Tawteeq_end_date__c;
                acRecord.Move_In_Date__c = caseRecord.Move_In_Date__c;
                acRecord.Emirates_ID_expiry_date__c = caseRecord.Emirates_ID_expiry_date__c;
                acRecord.Emergency_contact_01__c = caseRecord.Emergency_contact_01__c;
                acRecord.Emergency_contact_02__c = caseRecord.Emergency_contact_02__c;
                acRecord.MobilePhone__pc = caseRecord.Mobile_Number__c;
                acRecord.Nationality__c = caseRecord.Nationality__c;
                acRecord.Occupant_with_special_needs__c = caseRecord.Occupant_with_special_needs__c;
                acRecord.Special_Needs_Comments__c = caseRecord.Special_Needs_Comments__c;
                acRecord.Total_Number_of_Adults_Occupants__c = caseRecord.Total_Number_of_Adults_Occupants__c;
                acRecord.NumberOfPets__c = caseRecord.NumberOfPets__c;
                acRecord.Total_Number_of_Child_Occupants__c = caseRecord.Total_Number_of_Child_Occupants__c;
                acRecord.EJARI_Tawteeq_number__c = caseRecord.EJARI_Tawteeq_number__c;
                acRecord.Emirates_ID_number__c = caseRecord.Emirates_ID_number__c;
                acRecord.recordtypeid = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                    .get('PersonAccount')
                    .getRecordTypeId();
                AccountService accService = AccountService.getInstance();
                accService.createAccount(acRecord);
                
                Service_Contract__c contract = new Service_Contract__c();
                contract.Customer_Name__c = acRecord.Id;
                contract.EJARI_Tawteeq_end_date__c = caseRecord.EJARI_Tawteeq_end_date__c;
                contract.EJARI_Tawteeq_number__c = caseRecord.EJARI_Tawteeq_number__c;
                //contract.Move_Out_Date__c = caseRecord.EJARI_Tawteeq_end_date__c;
                contract.EJARI_Tawteeq_start_date__c = caseRecord.EJARI_Tawteeq_start_date__c;
                contract.Emergency_contact_01__c = caseRecord.Emergency_contact_01__c;
                contract.Emergency_contact_02__c = caseRecord.Emergency_contact_02__c;
                contract.Move_In_Date__c = caseRecord.Move_In_Date__c;
                contract.Occupant_with_special_needs__c = caseRecord.Occupant_with_special_needs__c;
                contract.Special_Needs_Comments__c = caseRecord.Special_Needs_Comments__c;
                contract.Total_Number_of_Adults_Occupants__c = caseRecord.Total_Number_of_Adults_Occupants__c;
                contract.NumberOfPets__c = caseRecord.NumberOfPets__c;
                contract.Total_Number_of_Child_Occupants__c = caseRecord.Total_Number_of_Child_Occupants__c;
                contract.Unit_Number__c = caseRecord.Unit__c;
                ServiceContractService.insertService(contract);
            } else if (caseRecord.User_Type__c == 'Owner') {
                acRecord.FirstName = caseRecord.First_Name__c;
                acRecord.LastName = caseRecord.Last_Name__c;
                acRecord.Owner__c = true;
                acRecord.Move_In_Date__c = caseRecord.Move_In_Date__c;
                acRecord.Emirates_ID_expiry_date__c = caseRecord.Emirates_ID_expiry_date__c;
                acRecord.Emergency_contact_01__c = caseRecord.Emergency_contact_01__c;
                acRecord.Emergency_contact_02__c = caseRecord.Emergency_contact_02__c;
                acRecord.Nationality__c = caseRecord.Nationality__c;
                acRecord.Total_Number_of_Adults_Occupants__c = caseRecord.Total_Number_of_Adults_Occupants__c;
                acRecord.NumberOfPets__c = caseRecord.NumberOfPets__c;
                acRecord.Total_Number_of_Child_Occupants__c = caseRecord.Total_Number_of_Child_Occupants__c;
                acRecord.NumberOfPets__c = caseRecord.NumberOfPets__c;
                acRecord.Occupant_with_special_needs__c = caseRecord.Occupant_with_special_needs__c;
                acRecord.PersonEmail = caseRecord.Email_Address__c;
                acRecord.MobilePhone__pc = caseRecord.PhoneNumber__c;
                acRecord.Special_Needs_Comments__c = caseRecord.Special_Needs_Comments__c;
                acRecord.Emirates_ID_number__c = caseRecord.Emirates_ID_number__c;
                acRecord.recordtypeid = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                    .get('PersonAccount')
                    .getRecordTypeId();
                
                if(caseRecord.AccountId == null){
                    AccountService accService = AccountService.getInstance();
                    accService.createAccount(acRecord); 
                }
                else{
                acRecord.Id = caseRecord.AccountId;
                }
                
                Service_Contract__c contract = new Service_Contract__c();
                contract.Customer_Name__c = acRecord.Id;
                //  contract.EJARI_Tawteeq_end_date__c = caseRecord.EJARI_Tawteeq_end_date__c;
                //contract.Move_Out_Date__c = caseRecord.EJARI_Tawteeq_end_date__c;
                //  contract.EJARI_Tawteeq_number__c =      caseRecord.EJARI_Tawteeq_number__c;
                contract.Unit_Number__c = caseRecord.Unit__c;
                contract.Emergency_contact_01__c = caseRecord.Emergency_contact_01__c;
                contract.Emergency_contact_02__c = caseRecord.Emergency_contact_02__c;
                contract.Move_In_Date__c = caseRecord.Move_In_Date__c;
                contract.Occupant_with_special_needs__c = caseRecord.Occupant_with_special_needs__c;
                contract.Special_Needs_Comments__c = caseRecord.Special_Needs_Comments__c;
                contract.Total_Number_of_Adults_Occupants__c = caseRecord.Total_Number_of_Adults_Occupants__c;
                contract.Total_Number_of_Child_Occupants__c = caseRecord.Total_Number_of_Child_Occupants__c;
                contract.NumberOfPets__c = caseRecord.NumberOfPets__c;
                ServiceContractService.insertService(contract);
            }
            List<Customer_Document__c> CustomerDocuments = new List<Customer_Document__c>();
            for (Customer_Document__c docs : caseRecord.Customer_Documents__r) {
                docs.Account__c = acRecord.id;
                CustomerDocuments.add(docs);
            }
            CustomerDocumentService cDocumentService = new CustomerDocumentService();
            if (CustomerDocuments.size() > 0) {
                cDocumentService.updateCustomerDocument(CustomerDocuments);
            }
            User__c userRecord = new User__c();
            userRecord.Email__c = caseRecord.Email_Address__c;
            userRecord.AppType__c = 'Community App';
            if (caseRecord.User_Type__c == 'Holiday Homes') {
                userRecord.Email__c = caseRecord.Representative_Email__c;
                userRecord.Name = caseRecord.Representative_Name__c;
            } else if (caseRecord.User_Type__c == 'Tenant') {
                userRecord.Name =
                    caseRecord.First_Name__c +
                    ' ' +
                    caseRecord.Last_Name__c;
                userRecord.Email__c = caseRecord.Email_Address__c;
            } else if (caseRecord.User_Type__c == 'Owner') {
                userRecord.Name =
                    caseRecord.First_Name__c +
                    ' ' +
                    caseRecord.Last_Name__c;
            }
            
            userRecord.Account__c = acRecord.id;
            userRecord.User_Account__c = acRecord.id;
            userRecord.Is_Azure_Active__c = true;
            userRecord.User_Type__c = caseRecord.User_Type__c;
            userRecord.isActive__c = true;
            userRecord.name__c = userRecord.Name;
            userRecord.Username__c = userRecord.Email__c;
            userRecord.Temporary_Password__c = utiRef.generateRandomPassword();
            uService.createUser(userRecord);
            MicrosoftAzureB2CUtility.createUser(userRecord);
            acRecord.User__c = userRecord.Id;
            //update acRecord;
            AccountService aService = AccountService.getInstance();
            aService.updateAccount(acRecord);
            
            Unit_Allocation__c unitAllocation = new Unit_Allocation__c();
            unitAllocation.Unit__c = caseRecord.Unit__c;
            unitAllocation.Start_Date__c = caseRecord.EJARI_Tawteeq_start_date__c;
            unitAllocation.End_Date__c = caseRecord.EJARI_Tawteeq_end_date__c;
            unitAllocation.User__c = userRecord.Id;
            
            unitAllocation.Active__c = true;
            unitAllocation.User_Type__c = caseRecord.User_Type__c;
            unitAllocation.Account__c = acRecord.id;
            //insert unitAllocation;
            UnitAllocationService uaService = new UnitAllocationService();
            uaService.createUnitAllocation(unitAllocation);
            UnitService unitService = new UnitService();
            List<Unit__c> units = new List<Unit__c>{
                new Unit__c(Id = caseRecord.Unit__c, Occupancy_Type__c = 'Leased')
                    };
                        unitService.updateUnits(units);
            
            caseRecord.User__c = userRecord.id;
            caseRecord.AccountId = acRecord.id;
            caseRecord.User_Temp_Password__c = userRecord.Temporary_Password__c;
            cService.updateCase(caseRecord);
            
            BCAPP_PushNotificationAPI.PushNotificationParams nParams = new BCAPP_PushNotificationAPI.PushNotificationParams(caseRecord.deviceRegistrationId__c,'Approved','Move In Approved',caseRecord.CaseNumber,'Approved');

            List<BCAPP_PushNotificationAPI.PushNotificationParams> notifyParams = new List<BCAPP_PushNotificationAPI.PushNotificationParams>{nParams};



            System.enqueueJob(new BCAPP_PushNotificationAPI(notifyParams));
            
        } else {
            Unit_Allocation__c unitAllocation = new Unit_Allocation__c();
            unitAllocation.Unit__c = caseRecord.Unit__c;
            unitAllocation.Start_Date__c = system.today();
            unitAllocation.End_Date__c = system.today().addyears(1) - 1;
            unitAllocation.User__c = userList[0].Id;
            
            unitAllocation.Active__c = true;
            unitAllocation.User_Type__c = caseRecord.User_Type__c;
            unitAllocation.Account__c = userList[0].Account__c;
            UnitAllocationService uaService = new UnitAllocationService();
            uaService.createUnitAllocation(unitAllocation);
            UnitService unitService = new UnitService();
            List<Unit__c> units = new List<Unit__c>{
                new Unit__c(Id = caseRecord.Unit__c, Occupancy_Type__c = 'Leased')
                    };
                        unitService.updateUnits(units);
            sendApprovalEmail(
                Label.Move_In_Case_Updates_Approved_Owner,
                lstEmails,
                true,
                caseRecord.iD
            );
            if (userList != null && userList.size() > 0) {
                caseRecord.User__c = userList[0].Id;
                caseRecord.AccountId = userList[0].Account__c;
                
                cService.updateCase(caseRecord);
            }
        }
    } 
    
    @AuraEnabled
    public static string updateCaseStatus(
        Id caseId,
        String status,
        string comments
    ) {
        //  try {
        
        CaseService cService = CaseService.getInstance();
         BCAPP_Utility utilit_ref = BCAPP_Utility.getInstance();
        //Case caseRecord = [SELECT Account.PersonEmail,Recordtype.name,Representative_Email__c,AccountId,Representative_Name__c,(select id,Account__c from Customer_Documents__r),CaseNumber,PhoneNumber__c,User_Type__c,Unit__c,Account.Azure_UserPrincipal_Id__c,Service_Catalog__r.Name,Last_Name__c,First_Name__c,Unit__r.Name,Email_Address__c,Id,Contacts_Case_Email__c, Status FROM Case WHERE Id = :caseId LIMIT 1];
        Case caseRecord = cService.getCaseRecordWithDocuments(caseId);
        if (status != 'Approved')
            caseRecord.Status = status; // Set the status to Approved
        
        if (String.isNotBlank(comments))
            caseRecord.Return_Comments__c = comments; // Set the status to Approved
        
        List<String> lstEmails = new List<String>();
        
        if (caseRecord.Email_Address__c != null)
            lstEmails.add(caseRecord.Email_Address__c);
        else
            lstEmails.add(caseRecord.Representative_Email__c);
        
        BCAPP_Utility utility_ref = BCAPP_Utility.getInstance();
        
        if (status == 'Approved') {
            if (
                caseRecord.Service_Catalog__r.Name != 'Access Permit' &&
                caseRecord.Status != 'Submitted to Community Management'
            ) {
                if (caseRecord.Unit__r.Is_Lease_Hold__c) {
                    caseRecord.Status = 'Submitted to Community Management';
                    Group groupDetail = [
                        SELECT Id
                        FROM Group
                        WHERE Type = 'Queue' AND Name = 'Community Management'
                        LIMIT 1
                    ];
                    caseRecord.OwnerId = groupDetail.Id;
                    update caseRecord;
                    return null;
                }
            } else {
                caseRecord.Status = 'Approved';
            }
            
            caseRecord.Status = 'Approved'; // Set the status to Approved
            
            if(caseRecord.Service_Catalog__r.Name == 'Amenities'){

                caseRecord.Status = 'Confirmed';

            }

         
            
            /* if (caseRecord.Service_Catalog__r.Name == 'Access Permit') {
            sendApprovalEmail(
            'Bloom_Welcome_Email_Access_Permit',
            lstEmails,
            true,
            caseRecord.iD
            );
            } else*/ if (caseRecord.Service_Catalog__r.Name == 'Move Out') {
                List<Unit__c> units = UnitService.fetchUnitDetailsById(
                    caseRecord.Unit__c
                );
                if (!units.isEmpty()) {
                    if (units[0].Occupancy_Type__c == 'Available') {
                        return 'Move Out Request already Approved.';
                    }
                }
                
                handleMoveOut(caseRecord, lstEmails);
            } else if (caseRecord.Service_Catalog__r.Name == 'Move In') {
                List<Unit__c> units = UnitService.fetchUnitDetailsById(
                    caseRecord.Unit__c
                );
                if (!units.isEmpty()) {
                    if (units[0].Occupancy_Type__c == 'Leased') {
                        return 'Selected Unit is already Lease.';
                    }
                }
                
                handleMoveIn(caseRecord, lstEmails);
            } else if (caseRecord.Service_Catalog__r.Name == 'Renewal') {
                handleRenew(caseRecord, lstEmails);
            }
            cService.updateCase(caseRecord);
        } else if (status == 'Rejected') {
        
            BCAPP_PushNotificationAPI.PushNotificationParams nParams = new BCAPP_PushNotificationAPI.PushNotificationParams();

            if(caseRecord.AccountId!=null){

                    List<User__c> customer = utilit_ref.getUserbyAccountId(caseRecord.AccountId);

                    nParams.pushRegistrationId = customer[0].deviceRegistrationId__c;

                }

            

            nParams.title = 'Request number '+caseRecord.CaseNumber+'Move In Rejected';

            nParams.message = caseRecord.Return_Comments__c;

            nParams.caseNumber = caseRecord.CaseNumber;

            nParams.status = 'Rejected';

            List<BCAPP_PushNotificationAPI.PushNotificationParams> notifyParams = new List<BCAPP_PushNotificationAPI.PushNotificationParams>();

            notifyParams.add(nParams);

            System.enqueueJob(new BCAPP_PushNotificationAPI(notifyParams));
            
            cService.updateCase(caseRecord);
            //  sendApprovalEmail(Label.Case_Updates_Rejected,lstEmails,false,caseRecord.iD);
            ///   if(caseRecord.PhoneNumber__c!=null)
            //   SMS_Utility.sendSMS(caseRecord.PhoneNumber__c,'Request number '+caseRecord.CaseNumber+' is Rejected.');//'Request number '+caseRecord.CaseNumber +' for Move In Request is completed.welcome Letter has been sent on email.');
        } else if (status == 'Returned To Customer') {
        Boolean isMoveIn = true;
            //  SMS_Utility.sendSMS(caseRecord.PhoneNumber__c,'Request number '+caseRecord.CaseNumber+' is Retuned .');//'Request number '+caseRecord.CaseNumber +' for Move In Request is completed.welcome Letter has been sent on email.');
            
            cService.updateCase(caseRecord);
            // sendApprovalEmail(Label.Case_Updates_ReturnToCustomer,lstEmails,false,caseRecord.iD);
        
        cService.updateCase(caseRecord);
        
        sendApprovalEmail(Label.Case_Updates_ReturnToCustomer,lstEmails,false,caseRecord.iD);

            BCAPP_PushNotificationAPI.PushNotificationParams nParams = new BCAPP_PushNotificationAPI.PushNotificationParams();

            nParams.pushRegistrationId = caseRecord.deviceRegistrationId__c;

            if(caseRecord.Service_Catalog__r.Name == 'Renewal'){

                isMoveIn = false;

                if(caseRecord.AccountId!=null){

                    List<User__c> customer = utilit_ref.getUserbyAccountId(caseRecord.AccountId);

                    nParams.pushRegistrationId = customer[0].deviceRegistrationId__c;

                }

               

            }

            nParams.title = isMoveIn ?'Move In Request':'Renewal Request';
            nParams.message = caseRecord.Return_Comments__c;
            nParams.caseNumber = caseRecord.CaseNumber;
            nParams.status = 'Returned To Customer';

            if(isMoveIn){
                if(caseRecord.User_Type__c=='Holiday Homes'){
                    nParams.deepLinkUrl = 'bloom-community-app://holiday-home-owner/holiday-move-in?&rfiId='+caseRecord.Id+'&expires='+DateTime.now().getTime()/1000;
                }
                else{
                   nParams.deepLinkUrl ='bloom-community-app://tenant/tenant-move-in?&rfiId='+caseRecord.Id+'&expires='+DateTime.now().getTime()/1000;
                }
            }
            else{
                nParams.deepLinkUrl = 'bloom-community-app://move-out-and-renew?type=renew&rfiId='+caseRecord.Id+'&expires='+DateTime.now().getTime() / 1000;
            }
            List<BCAPP_PushNotificationAPI.PushNotificationParams> notifyParams = new List<BCAPP_PushNotificationAPI.PushNotificationParams>();
            notifyParams.add(nParams);
            System.enqueueJob(new BCAPP_PushNotificationAPI(notifyParams));
            }
              cService.updateCase(caseRecord);
           return null;
        /*  } catch (Exception e) {
throw new AuraHandledException('Failed to update case status: ' + e.getMessage());
}*/
    }
    
    public static void sendApprovalEmail(
        string developerName,
        List<string> recipientEmail,
        boolean isAttachment,
        id recordId
    ) {
        // Create the content for the PDF
        String pdfContent = 'Request has been approved';
        // Create a Blob from the text to be attached as a PDF
        Blob pdfBlob;
        Case record=[SELECT Id,recordType.Name,ParentId,createdby.name FROM Case WHERE
                     id=:recordId];
        // Create a Blob from the text to be attached as a PDF
        if(record.RecordType.Name.contains('Access Permit') && 
           record.parentId == NULL ){
               pdfBlob=PdfGeneratorControllerSample.generateSitePdf(recordId);
           }else{
               pdfBlob = PdfGeneratorControllerSample.generatePdf(recordId);
           }
        String permitType;
        Case eachCase = [
            SELECT Service_Catalog__r.Name
            FROM Case
            WHERE ID = :recordId
        ];
        if (eachCase.Service_Catalog__r.Name == 'Access Permit') {
            permitType = 'Access Permit';
        } else if (eachCase.Service_Catalog__r.Name == 'Move Out') {
            permitType = 'Move Out Permit';
        } else {
            permitType = 'Move In Permit';
        }
        // Create an email template
        EmailTemplate emailTemplate = [
            SELECT Id, DeveloperName
            FROM EmailTemplate
            WHERE DeveloperName = :developerName
            LIMIT 1
        ];
        
        // Set up the SingleEmailMessage object
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        OrgWideEmailAddress[] orgWideEmails = [
            SELECT Id, Address
            FROM OrgWideEmailAddress
            WHERE Address =  :Label.BCAPP_OrgWideEmailAddress
            LIMIT 1
        ];
        
        if (!orgWideEmails.isEmpty())
            email.setOrgWideEmailAddressId(orgWideEmails[0].Id);
        
        // Set the "To" email address
        email.setToAddresses(recipientEmail);
        email.setTargetObjectId(
            [SELECT id FROM contact WHERE email != NULL LIMIT 1].Id
        );
        email.setWhatId(recordId);
        email.setTreatTargetObjectAsRecipient(false);
        
        // Set the email template to use
        email.setTemplateId(emailTemplate.Id);
        
        // Set the email to be sent
        email.setSaveAsActivity(true);
        
        if (isAttachment) {
            // Create an attachment from the Blob (PDF)
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName(permitType + '.pdf');
            attachment.setBody(pdfBlob);
            attachment.setContentType('application/pdf');
            
            // Attach the PDF to the email
            email.setFileAttachments(
                new List<Messaging.EmailFileAttachment>{ attachment }
            );
        }
        // Send the email
        
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
    }
}