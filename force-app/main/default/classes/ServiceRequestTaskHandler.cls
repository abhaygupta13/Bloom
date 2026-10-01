/*****************************************************************************************
Class       : ServiceRequestTaskHandler 
Author      : Sonali S
Description : 
test Class: ServiceRequestTaskHandlerTest
Created Date: 
*****************************************************************************************/

public inherited sharing class ServiceRequestTaskHandler {
    private static final String MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final string MTD_SERVICE_REQUEST_ASSIGNMENT_EMAIL_TEMPLATE_ID { get { return 'ServiceRequestAssignmentId'; } }
    private static final string MTD_SERVICE_REQUEST_REASSIGNMENT_EMAIL_TEMPLATE_ID { get { return 'ServiceRequestReAssignmentId'; } }
    private static final string MTD_SERVICE_REQUEST_CLOSURE_EMAIL_TEMPLATE_ID { get { return 'ServiceRequestClosureId'; } }
    private static final string MTD_COMPLAINT_ASSIGNMENT_EMAIL_TEMPLATE_ID {get { return 'ComplaintAssignmentId';}}
    private static final string MTD_COMPLAINT_REASSIGNMENT_EMAIL_TEMPLATE_ID {get { return 'ComplaintReAssignmentId';}}
    private static final string MTD_COMPLAINT_CLOSURE_EMAIL_TEMPLATE_ID {get { return 'ComplaintClosureId';}}
    private static final string ACKNOWLEDGEMENT_RECEIPT_RT { get { return 'Acknowledgment_Receipt'; } }//Pranav
    private static final string PAYMENT_DUE_DATE_UPDATE_RT { get { return 'Payment_Due_Date_Update'; } }//Pranav
    private static final string THIRD_PARTY_FORM_RT { get { return 'ThirdPartyForm'; } }//Pranav
    private static final string PAYMENT_SR_RT { get { return 'Payment_SR'; } }//Pranav
    private static final string LPF_WAIVER_REQUEST_RT { get { return 'LPFWaiverRequest'; } }
    private static final string SOA_REQUEST_RT { get { return 'SOARequest'; } }
    private static final string SERVICE_REQUEST_CUSTOMER_CLOSURE_EMAIL_TEMPLATE_ID { get { return 'NewServiceRequestClosureID'; } }
    private static final string LPF_WAIVER_REJECTION_EMAIL_TEMPLATE_ID { get { return 'LPFWaiver_Rejection'; } }
    private static final string CHEQUE_REPLACEMENT_REQUEST_RT { get { return 'ChequeReplacementRequest'; } }
    private static final string CHEQUE_WITHDRAWAL_REQUEST_RT { get { return 'ChequeWithdrawalRequest'; } }
    private static final string POP_SHARE_SR_RT { get { return 'ProofofPaymentShared'; } }//Pranav
    private static final string BANK_ACC_DTAIL_SR_RT { get { return 'BankAccountDetailsInquiry'; } }//Pranav
    private static final string GENERAL_ENQUIRY_RT { get { return 'GeneralEnquiry'; } }
    private static final string SALES_OPERATION_CATEGORY { get { return 'SalesOperationService'; } }
    private static final string RESALE_MASTER_RT { get { return 'Resale_Master'; } }
    private static final string RESALE_COMPLETED_RT { get { return 'Resale_Property_For_Completed_Project'; } }
    private static final string RESALE_UNDER_CONSTRUCTION_RT { get { return 'Resale_Property_Under_Construction'; } }
    private static final string RESALE_PHPP_RT { get { return 'Resale_Property_with_Post_Handover_Payment_Plan'; } }
    private static final string RESALE_RT { get { return 'Resale'; } }
    private static final string TAWTHEEQ_ENROLLMENT_RT { get { return 'TawtheeqEnrollment'; } }
    private static final string TAWTHEEQ_ENROLLMENT_SR_CLOSURE_LEASING_ETID { get { return 'TawtheeqEnrollmentSRClosureTemplate'; } }
    private static final string LEASING_TEAM_QUEUEID { get { return 'Handover_Leasing_Team_Queue'; } }
    private static final string SUPER_APP_STR { get { return 'Super App'; } }
    private static final string KYC_UPDATE_REQUEST_RT { get { return 'KYCUpdateRequest'; } }
    private static final string SUPER_APP_OPERATION_TEAM_CASE_ASSIGNMENT { get { return 'Super App Operation Team Case Assignment'; } }
    private static final string PROCESS_TYPE_SALES { get { return 'Sales'; } }
     private static final string VEHICLE_PARKING_REQUEST_RT_DEV_NAME { get { return 'VehicleParkingRequest'; } }
    private static final string POST_SALE_PAYMENT_DEFERRAL_RT { get { return 'Post_Sale_Payment_Deferral'; } }

    
    private static ServiceRequestTaskHandler instance; 
    
    private ServiceRequestTaskHandler() {
        
    }
    public static ServiceRequestTaskHandler getInstance() { 
        if(instance == null) {
            instance = new ServiceRequestTaskHandler();
        }
        return instance;
    }  
    public  void createNewAndCloseCurrentTask(List<Case> listOfCases){
        ServiceCatalogService servObj = ServiceCatalogService.getInstance();
        Map<Id,ServiceAction__c> caseCatalogVsNextAction  = servObj.getNextCaseServiceAction(listOfCases);
        Map<Id,ServiceAction__c> caseCatalogVsCurrentAction = servObj.getCurrentCaseServiceAction(listOfCases);
        processCasesAndHandleNextActions(listOfCases,caseCatalogVsNextAction,caseCatalogVsCurrentAction);
    }
    public  void openOldAndCloseCurrentTask(Id caseId,String commentBody,String reason,Id userId){
        CaseService caseObjService = CaseService.getInstance();
        List<Case> caseList =   caseObjService.getCaseByIds(new Set<Id>{caseId});
        ServiceCatalogService servObj = ServiceCatalogService.getInstance();
        Map<Id,ServiceAction__c> caseCatalogVsNextAction  = servObj.getPreviousCaseServiceAction(caseList);
        processCasesAndHandlePrevActions(caseList,caseCatalogVsNextAction,commentBody,reason,userId);
    }  
    public void processCasesAndHandlePrevActions(List<Case> listOfCases, Map<Id, ServiceAction__c> caseCatalogVsPrevAction,String commentBody,String reason,Id userId) {
        
        ActivityService objActivityService = ActivityService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        Id noReplyOWDId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
        
        Map<Id, List<Task>> caseVsOpenTasks = objActivityService.fetchOpenTaskByCaseList(listOfCases);  
        
        Boolean hasOpenTasks = !caseVsOpenTasks.isEmpty();
        Boolean hasCatalogActions = !caseCatalogVsPrevAction.isEmpty();
        
        List<Case> casesToUpdate = new List<Case>();
        List<Task> tasksToUpdate = new List<Task>(); 
        List<Messaging.SingleEmailMessage> emailList = new list<Messaging.SingleEmailMessage>(); 
        List<CaseAssignmentHistory__c> caseAssignHistoryToLog = new  List<CaseAssignmentHistory__c>();
        Set<Id> caseIds = new Set<Id>();
        
        for(Case caseobj : listOfCases){
            Case caseToUpdate = new Case(Id = caseObj.Id);
            /*if (caseVsOpenTasks.containsKey(caseobj.Id)) {
                List<Task> openTasks = caseVsOpenTasks.get(caseobj.Id);    
                for (Task currentTask : openTasks) {
                       //currentTask.Status = 'Completed'; 
                    currentTask.OwnerId = caseobj.OwnerId;
                         tasksToUpdate.add(currentTask);
                }
            }*/
            if(hasCatalogActions && caseCatalogVsPrevAction.containsKey(caseObj.ServiceCatalog__c)){
                ServiceAction__c action = caseCatalogVsPrevAction.get(caseObj.ServiceCatalog__c);
                
                Task tsk = objActivityService.fetchTaskFromServiceAction(action,caseobj.id);
                tsk.Status = 'Open';
                tsk.OwnerId = (userId != null) ? userId : tsk.OwnerId;
                tasksToUpdate.add(tsk);  
                
                caseToUpdate.Step__c = String.valueOf(Integer.valueOf(action.Order__c));
                caseToUpdate.Status = 'In Progress';  
                caseToUpdate.PendingWith__c = action.Department__c;
                caseToUpdate.OwnerId = (userId != null) ? userId : tsk.OwnerId;
                casesToUpdate.add(caseToUpdate);
                
                caseIds.add(caseobj.id);
                
                CaseAssignmentHistory__c historyObj = new CaseAssignmentHistory__c();
                historyObj.Case__c = caseobj.id;
                // historyObj.AssignedBy__c = caseVsOpenTasks.get(caseObj.Id)[0].OwnerId;
                Id assignedById = caseVsOpenTasks.get(caseObj.Id)[0].OwnerId;
                if (String.valueOf(assignedById).startsWith('005')) {
                    historyObj.AssignedBy__c = assignedById;
                }
                historyObj.OwnerId = (userId != null) ? userId : tsk.OwnerId;
                //  historyObj.OwnerId = tsk.OwnerId;
                historyObj.AssignmentDate__c = system.now();
                historyObj.Description__c = commentBody;
                historyObj.Reason__c = reason;
                caseAssignHistoryToLog.add(historyObj); 
                
                List<String> toAddress =  objEmailService.getOwnerEmails(tsk.OwnerId);
                Id emailTemplateId;
                
                if(caseobj.CaseType__c =='Service Request'){
                    emailTemplateId = objMetadataService.getAppSettingTextValue(MTD_SERVICE_REQUEST_REASSIGNMENT_EMAIL_TEMPLATE_ID);
                }
                else if(caseobj.CaseType__c =='Complaint') {
                    emailTemplateId = objMetadataService.getAppSettingTextValue(MTD_COMPLAINT_REASSIGNMENT_EMAIL_TEMPLATE_ID);
                }
                Messaging.SingleEmailMessage email = objEmailService.getSingleEmailMessageWithoutTargetObjectId(emailTemplateId, noReplyOWDId, caseobj.Id, toAddress, null, null);
                
            }
        }
        ActivityService servObj = ActivityService.getInstance();
        CaseService caseService = CaseService.getInstance();  
        CaseAssignmentHistoryService assignObj = CaseAssignmentHistoryService.getInstance();
        NotificationService notificationServiceObj = NotificationService.getInstance(); 
        
        if(!tasksToUpdate.isEmpty()) servObj.updateTasks(tasksToUpdate); 
        if(!casesToUpdate.isEmpty()) caseService.updateCases(casesToUpdate);  
        if(!caseAssignHistoryToLog.isEmpty()) assignObj.insertCaseAssignmentHistory(caseAssignHistoryToLog);
        if(!emailList.isEmpty())objEmailService.sendEmail(emailList); 
        if(!caseIds.isEmpty()) notificationServiceObj.sendCustomNotification(caseIds); 
    }
    
    public void processCasesAndHandleNextActions(List<Case> listOfCases, Map<Id, ServiceAction__c> caseCatalogVsNextAction,  Map<Id,ServiceAction__c> caseCatalogVsCurrentAction) {
        
        List<Task> taskToInsert = new List<Task>(); 
        List<Task> tasksToUpdate = new List<Task>();
        Set<Id> attachmentCaseIds = new Set<Id>();//Pranav 
        
        ActivityService objActivityService = ActivityService.getInstance(); 
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        
        Id noReplyOWDId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
        
        //Pranav
        attachmentCaseIds.add(Utility.getRecordTypeIdByDevName(Case.SObjectType,ACKNOWLEDGEMENT_RECEIPT_RT));
        attachmentCaseIds.add(Utility.getRecordTypeIdByDevName(Case.SObjectType,PAYMENT_DUE_DATE_UPDATE_RT));
        attachmentCaseIds.add(Utility.getRecordTypeIdByDevName(Case.SObjectType,THIRD_PARTY_FORM_RT));
        attachmentCaseIds.add(Utility.getRecordTypeIdByDevName(Case.SObjectType,PAYMENT_SR_RT));
        attachmentCaseIds.add(Utility.getRecordTypeIdByDevName(Case.SObjectType,POP_SHARE_SR_RT));
        attachmentCaseIds.add(Utility.getRecordTypeIdByDevName(Case.SObjectType,BANK_ACC_DTAIL_SR_RT));
        attachmentCaseIds.add(Utility.getRecordTypeIdByDevName(Case.SObjectType,GENERAL_ENQUIRY_RT));
        attachmentCaseIds.add(Utility.getRecordTypeIdByDevName(Case.SObjectType,POST_SALE_PAYMENT_DEFERRAL_RT));
        
        List<Case> casesToUpdate = new List<Case>();
        List<Messaging.SingleEmailMessage> emailList = new list<Messaging.SingleEmailMessage>(); 
        List<CaseAssignmentHistory__c> caseAssignHistoryToLog = new  List<CaseAssignmentHistory__c>();   
        
        Boolean hasNextCatalogActions = !caseCatalogVsNextAction.isEmpty();
        Boolean hasOpenActions = !caseCatalogVsCurrentAction.isEmpty();

        Set<Id> superAppKYCRequestIds = new Set<Id>();
        Map<Id, Case> updatedKycCaseMap = new Map<Id, Case>();
        Id KYCUpdateRequestRTId = Utility.getRecordTypeIdByDevName(Case.SObjectType, KYC_UPDATE_REQUEST_RT);

        for(Case caseObj : listOfCases){
            if(caseObj.RecordTypeId == KYCUpdateRequestRTId && caseObj.Origin == SUPER_APP_STR){
                superAppKYCRequestIds.add(caseObj.Id);
            }
        }

        if(superAppKYCRequestIds != null && !superAppKYCRequestIds.isEmpty()){
            updatedKycCaseMap = AssignmentRuleHandler.assignCasesToNextOwner(superAppKYCRequestIds, SUPER_APP_OPERATION_TEAM_CASE_ASSIGNMENT, PROCESS_TYPE_SALES);
        }
        
        for (Case caseObj : listOfCases) {
            Case caseToUpdate = new Case(Id = caseObj.Id); 
            
            if (hasNextCatalogActions && caseCatalogVsNextAction.containsKey(caseObj.ServiceCatalog__c)) {
                ServiceAction__c nextAction = caseCatalogVsNextAction.get(caseObj.ServiceCatalog__c);   
                Task tsk = new Task();
                List<Task> tsks= objActivityService.fetchOpenTaskFromServiceAction(nextAction,caseobj.id); 
                List<Task> closedTasksForDept = objActivityService.fetchClosedTaskByDept(nextAction.Department__c,caseobj.id);
                //if there are no existing tasks for this service action, only then create a new task
                if(tsks.isEmpty()){
                    if(superAppKYCRequestIds != null && updatedKycCaseMap.containsKey(caseObj.Id) && nextAction.Order__c == 2){
                        caseObj.OwnerId = updatedKycCaseMap.get(caseObj.Id).OwnerId;
                    }
                    tsk = objActivityService.createTaskFromServiceAction(nextAction);
                    tsk.WhatId = caseObj.Id; 
                    tsk.Type = 'Other';
                    tsk.Department__c = nextAction.Department__c;
                    tsk.ActivityDate = nextAction.Due_in_days__c != null  ? System.now().date().addDays(Integer.valueOf(nextAction.Due_in_days__c)): System.now().date();
                    // Assign new dept task to user of existing dept task
                    
                    if(!closedTasksForDept.isEmpty()){
                        tsk.OwnerId =  closedTasksForDept[0].OwnerId;
                    }
                    else{
                        tsk.OwnerId = nextAction.AssignToOwner__c ? caseObj.OwnerId : nextAction.OwnerId;
                        if(nextAction.Department__c =='CRM'
                           &&caseToUpdate.CRMAgent__c ==null
                          ){
                              if (tsk.OwnerId != null && String.valueOf(tsk.OwnerId).startsWith('005')) {
                                  caseToUpdate.CRMAgent__c = tsk.OwnerId;
                              }
                          }
                        
                    }
                    taskToInsert.add(tsk); 
                }
                else{
                    tsk=tsks[0];  
                }
                
                if(hasOpenActions && caseCatalogVsCurrentAction.containsKey(caseObj.ServiceCatalog__c)) {
                    ServiceAction__c currentAction = caseCatalogVsCurrentAction.get(caseObj.ServiceCatalog__c);
                    Task tskToUpdate = new Task();  
                    List<Task> currentTaskList= objActivityService.fetchOpenTaskFromServiceAction(currentAction,caseobj.id);
                    if(!currentTaskList.isEmpty()){
                        tasksToUpdate.addAll(currentTaskList);
                    }
                }
                caseToUpdate.Step__c = nextAction.FinalTask__c ? 'Final' : String.valueOf(Integer.valueOf(nextAction.Order__c));
                if(Integer.valueOf(nextAction.Order__c)>=1){
                    caseToUpdate.Status = 'In Progress';  
                }
                caseToUpdate.PendingWith__c = nextAction.Department__c;
                caseToUpdate.OwnerId = tsk.OwnerId;
                
                CaseAssignmentHistory__c historyObj = new CaseAssignmentHistory__c();
                historyObj.Case__c = caseobj.id;
                historyObj.OwnerId = tsk.OwnerId;
                historyObj.AssignmentDate__c = system.now();
                historyObj.Reason__c = 'Process Assigned';
                caseAssignHistoryToLog.add(historyObj); 
                
                List<String> toAddress =  objEmailService.getOwnerEmails(tsk.OwnerId);
                Id emailTemplateId;
                if(caseobj.CaseType__c =='Service Request'){
                    emailTemplateId = objMetadataService.getAppSettingTextValue(MTD_SERVICE_REQUEST_ASSIGNMENT_EMAIL_TEMPLATE_ID);
                }
                else if(caseobj.CaseType__c =='Complaint') {
                    emailTemplateId = objMetadataService.getAppSettingTextValue(MTD_COMPLAINT_ASSIGNMENT_EMAIL_TEMPLATE_ID);
                }
                if(emailTemplateId != null){
                    Messaging.SingleEmailMessage email = objEmailService.getSingleEmailMessageWithoutTargetObjectId(emailTemplateId, noReplyOWDId, caseobj.Id,toAddress, null, null);
                    List<Messaging.EmailFileAttachment> attachments = objEmailService.getCaseAttachments(caseobj.Id);
                    if(attachments != null && !attachments.isEmpty() && (caseobj.SubType__c == 'Rent Security Deposit Refund' || caseobj.SubType__c == 'Rent Refund')){
                        email.setFileAttachments(attachments);}
                    
                    emailList.add(email);
                }
                
                
            } else {
                caseToUpdate.PendingWith__c = '';
                caseToUpdate.Status = 'Closed';
                caseToUpdate.SubStatus__c = 'Closed';//Pranav 
                ServiceAction__c currentAction = caseCatalogVsCurrentAction.get(caseObj.ServiceCatalog__c);
                List<Task> currentTaskList= objActivityService.fetchOpenTaskFromServiceAction(currentAction,caseobj.id);
                if(!currentTaskList.isEmpty()){
                    tasksToUpdate.addAll(currentTaskList);
                }
                /* if(caseobj.RecordTypeId == Utility.getRecordTypeIdByDevName(Case.SObjectType,RESALE_RT) ||
                   caseobj.RecordTypeId == Utility.getRecordTypeIdByDevName(Case.SObjectType,RESALE_MASTER_RT) ||
                   caseobj.RecordTypeId == Utility.getRecordTypeIdByDevName(Case.SObjectType,RESALE_COMPLETED_RT) ||
                   caseobj.RecordTypeId == Utility.getRecordTypeIdByDevName(Case.SObjectType,RESALE_UNDER_CONSTRUCTION_RT) ||
                   caseobj.RecordTypeId == Utility.getRecordTypeIdByDevName(Case.SObjectType,RESALE_PHPP_RT)){
                       ResaleServiceRequestHandler.getInstance().updateHandoverRecords(listOfCases);
                   } */
                AccountService accService = AccountService.getInstance();
                if(caseObj.AccountId != null && !caseObj.StopEmailsToCustomer__c){
                    String customerEmail = accService.getRelatedContactEmail(caseObj.AccountId);
                    List<String> jointOwnerEmail = SalesOrderService.getinstance().getJointOwnerEmails(caseObj.Sales_Order__c);
                    List<String> toAddress = new List<String>{customerEmail};
                        Id emailTemplateId;
                    if(caseobj.CaseType__c =='Service Request'){
                        emailTemplateId = objMetadataService.getAppSettingTextValue(MTD_SERVICE_REQUEST_CLOSURE_EMAIL_TEMPLATE_ID); 
                    }
                    else if(caseobj.CaseType__c =='Complaint') {
                        emailTemplateId = objMetadataService.getAppSettingTextValue(MTD_COMPLAINT_CLOSURE_EMAIL_TEMPLATE_ID);
                    }
                    if(emailTemplateId != NULL){
                        //Pranav
                        Messaging.SingleEmailMessage email;
                        //if(caseobj.RecordTypeId == acknowledgementRcptRTID){
                        if(attachmentCaseIds.contains(caseobj.RecordTypeId)){
                            List<Messaging.EmailFileAttachment> attachments = objEmailService.getCaseAttachments(caseobj.Id);
                            if(attachments != null){
                                if(Utility.getRecordTypeIdByDevName(Case.SObjectType,ACKNOWLEDGEMENT_RECEIPT_RT) == caseobj.RecordTypeId){
                                    AcknowledgmentReceiptSRHandler ackObj = AcknowledgmentReceiptSRHandler.getInstance();
                                    List<Messaging.EmailFileAttachment> filteredAttachments = new List<Messaging.EmailFileAttachment>();
                                    
                                    for(Messaging.EmailFileAttachment att : attachments){
                                        if(att != null && att.getFileName() != null && 
                                           att.getFileName().toLowerCase().contains('payment receipt')){
                                               filteredAttachments.add(att);
                                           }
                                    }
                                    
                                    /*if(!filteredAttachments.isEmpty()){
                                        email.setFileAttachments(filteredAttachments);
                                    }*/
                                    email = ackObj.sendClosureEmail(noReplyOWDId, caseobj.Id, toAddress, null, null,filteredAttachments);
                                }else if(Utility.getRecordTypeIdByDevName(Case.SObjectType,PAYMENT_DUE_DATE_UPDATE_RT) == caseobj.RecordTypeId){
                                    PaymentDueDateUpdateSRHandler ackObj = PaymentDueDateUpdateSRHandler.getInstance();
                                    List<Messaging.EmailFileAttachment> filteredAttachments = new List<Messaging.EmailFileAttachment>();
                                    
                                    for(Messaging.EmailFileAttachment att : attachments){
                                        if(att != null && att.getFileName() != null && 
                                           !att.getFileName().toLowerCase().contains('soa')){
                                               filteredAttachments.add(att);
                                           }
                                    }
                                    
                                    /*if(!filteredAttachments.isEmpty()){
                                        email.setFileAttachments(filteredAttachments);
                                    }*/
                                    email = ackObj.sendClosureEmail(noReplyOWDId, caseobj.Id, toAddress, null, null,filteredAttachments);
                                }else if(Utility.getRecordTypeIdByDevName(Case.SObjectType,THIRD_PARTY_FORM_RT) == caseobj.RecordTypeId){
                                    ThirdPartyFormSRHandler tpObj = ThirdPartyFormSRHandler.getInstance();
                                    email = tpObj.sendCustomerEmail(caseobj.Id,'Closure',null,null);
                                }else if(Utility.getRecordTypeIdByDevName(Case.SObjectType,PAYMENT_SR_RT) == caseobj.RecordTypeId){
                                    PaymentSRHandler pymntObj = PaymentSRHandler.getInstance();
                                    email = pymntObj.sendCustomerEmail(caseobj.Id,'Closure',null);
                                }
                                else if(Utility.getRecordTypeIdByDevName(Case.SObjectType,POP_SHARE_SR_RT) == caseobj.RecordTypeId){
                                    ProofofPaymentSharedSRHandler pymntObj = ProofofPaymentSharedSRHandler.getInstance();
                                    email = pymntObj.sendCustomerEmail(caseobj.Id,'Closure',null, null);
                                }
                                else if(Utility.getRecordTypeIdByDevName(Case.SObjectType,BANK_ACC_DTAIL_SR_RT) == caseobj.RecordTypeId){
                                    BankAccDetailInquirySRHandler pymntObj = BankAccDetailInquirySRHandler.getInstance();
                                    email = pymntObj.sendCustomerEmail(caseobj.Id,'Closure',null, null);
                                }
                                else if(Utility.getRecordTypeIdByDevName(Case.SObjectType,GENERAL_ENQUIRY_RT) == caseobj.RecordTypeId){
                                    email = objEmailService.getSingleEmailMessageWithoutTargetObjectId(emailTemplateId,noReplyOWDId,caseobj.Id,toAddress,null,null);
                                    if(attachments != null && !attachments.isEmpty()){                                 
                                        
                                        if(caseobj.SubType__c == 'Rent Refund' || caseobj.SubType__c == 'Rent Security Deposit Refund'){
                                            
                                            List<Messaging.EmailFileAttachment> filteredAttachments = new List<Messaging.EmailFileAttachment>();
                                            
                                            for(Messaging.EmailFileAttachment att : attachments){
                                                if(att != null && att.getFileName() != null && 
                                                   att.getFileName().toLowerCase().contains('debit advice')){
                                                       filteredAttachments.add(att);
                                                   }
                                            }
                                            
                                            if(!filteredAttachments.isEmpty()){
                                                email.setFileAttachments(filteredAttachments);
                                            }          
                                        } 
                                        else{
                                            email.setFileAttachments(attachments);
                                        }                             
                                    }
                                }
                                 else if(caseObj.RecordTypeId == Utility.getRecordTypeIdByDevName(Case.SObjectType,POST_SALE_PAYMENT_DEFERRAL_RT) ){
                                PostSalePaymentDeferalCaseHandler postSaleObj = PostSalePaymentDeferalCaseHandler.getInstance();
                                List<Messaging.EmailFileAttachment> filteredAttachments = new List<Messaging.EmailFileAttachment>();
                                email = objEmailService.getSingleEmailMessageWithoutTargetObjectId(emailTemplateId,noReplyOWDId,caseobj.Id,toAddress,null,null);
                                
                                for(Messaging.EmailFileAttachment att : attachments){
                                    if(att != null && att.getFileName() != null && 
                                       att.getFileName().toLowerCase().contains('payment deferral fees receipt')){
                                           filteredAttachments.add(att);
                                       }
                                }
                                
                                if(!filteredAttachments.isEmpty()){
                                    email.setFileAttachments(filteredAttachments);
                                }
                                
                                
                            }
                            }
                           
                        } else if(((caseObj.RecordTypeId == Utility.getRecordTypeIdByDevName(Case.SObjectType,CHEQUE_REPLACEMENT_REQUEST_RT)) ) ){
                            //&& caseObj.PreviousChequeInOffice__c == 'Yes'){
                            System.debug('::::: Email with Attachment ::::: ');
                            Id emailTempId = objMetadataService.getAppSettingTextValue(SERVICE_REQUEST_CUSTOMER_CLOSURE_EMAIL_TEMPLATE_ID);
                            List<Messaging.EmailFileAttachment> attachments = objEmailService.getCaseAttachmentsByDocName(caseobj.Id, new List<String>{'Payment Receipt'});
                            if(attachments != null){
                                ChequeReplacementRequestCaseHandler objChequeReplacementRequestHandler = ChequeReplacementRequestCaseHandler.getInstance(); 
                                email = objChequeReplacementRequestHandler.sendClosureEmail(emailTempId, noReplyOWDId, caseobj.Id, toAddress, null, null,attachments);
                            }
                        }
                        else if(((caseObj.RecordTypeId == Utility.getRecordTypeIdByDevName(Case.SObjectType,CHEQUE_WITHDRAWAL_REQUEST_RT)))){
                            //&& caseObj.PreviousChequeInOffice__c == 'Yes'){
                            System.debug('::::: Email with Attachment ::::: ');
                            Id emailTempId = objMetadataService.getAppSettingTextValue(SERVICE_REQUEST_CUSTOMER_CLOSURE_EMAIL_TEMPLATE_ID);
                            // List<Messaging.EmailFileAttachment> attachments = objEmailService.getCaseAttachmentsByDocName(caseobj.Id, new List<String>{'Payment Receipt'});
                            //   if(attachments != null){
                            ChequeReplacementRequestCaseHandler objChequeReplacementRequestHandler = ChequeReplacementRequestCaseHandler.getInstance(); 
                            email = objChequeReplacementRequestHandler.sendClosureEmail(emailTempId, noReplyOWDId, caseobj.Id, toAddress, null, null,null);
                            // }
                        }
                        else if((caseObj.RecordTypeId == Utility.getRecordTypeIdByDevName(Case.SObjectType,LPF_WAIVER_REQUEST_RT) && caseObj.LPFWaiverRequestApprovalStatus__c == 'Approved')) {
                            Id emailTempId = objMetadataService.getAppSettingTextValue(SERVICE_REQUEST_CUSTOMER_CLOSURE_EMAIL_TEMPLATE_ID);
                            if(caseObj.FinanceDocumentsUploadedManually__c != 'Yes'){
                                ChequeReplacementRequestCaseHandler.getInstance().createDocuments(new List<Case>{caseObj},caseObj.Sales_Order__c);}
                            List<Messaging.EmailFileAttachment> attachments = objEmailService.getCaseAttachmentsByDocName(caseobj.Id, new List<String>{'Statement of Account'});
                            if(attachments != null){
                                ChequeReplacementRequestCaseHandler objChequeReplacementRequestHandler = ChequeReplacementRequestCaseHandler.getInstance();
                                //if(!test.isRunningTest()) 
                                email = objChequeReplacementRequestHandler.sendClosureEmail(emailTempId, noReplyOWDId, caseobj.Id, toAddress, null, null,attachments);
                            }
                        } else if((caseObj.RecordTypeId == Utility.getRecordTypeIdByDevName(Case.SObjectType,SOA_REQUEST_RT)) 
                                  || (caseObj.RecordTypeId == Utility.getRecordTypeIdByDevName(Case.SObjectType,LPF_WAIVER_REQUEST_RT) && caseObj.LPFWaiverRequestApprovalStatus__c == 'Approved')) {
                            Id emailTempId = objMetadataService.getAppSettingTextValue(SERVICE_REQUEST_CUSTOMER_CLOSURE_EMAIL_TEMPLATE_ID);
                              if(caseObj.FinanceDocumentsUploadedManually__c != 'Yes'){
                                      SOARequestCaseHandler.getInstance().createDocuments(new List<Case>{caseObj},caseObj.Sales_Order__c);
                              }
                             List<Messaging.EmailFileAttachment> attachments = objEmailService.getCaseAttachmentsByDocName(caseobj.Id, new List<String>{'Statement of Account'});
                            if(attachments != null){
                                SOARequestCaseHandler objChequeReplacementRequestHandler = SOARequestCaseHandler.getInstance(); 
                                email = objChequeReplacementRequestHandler.sendClosureEmail(emailTempId, noReplyOWDId, caseobj.Id, toAddress, jointOwnerEmail, null,attachments);
                            }
                        } else if(caseObj.RecordTypeId == Utility.getRecordTypeIdByDevName(Case.SObjectType,LPF_WAIVER_REQUEST_RT) && caseObj.LPFWaiverRequestApprovalStatus__c == 'Rejected') {
                            Id emailTempId = objMetadataService.getAppSettingTextValue(LPF_WAIVER_REJECTION_EMAIL_TEMPLATE_ID);
                            // List<Messaging.EmailFileAttachment> attachments = objEmailService.getCaseAttachmentsByDocName(caseobj.Id, new List<String>{'Statement of Account'});
                            // if(attachments != null){
                            SOARequestCaseHandler objChequeReplacementRequestHandler = SOARequestCaseHandler.getInstance(); 
                            email = objChequeReplacementRequestHandler.sendClosureEmail(emailTempId, noReplyOWDId, caseobj.Id, toAddress, null, null,null);
                            // }
                        } else if (caseObj.RecordTypeId != Utility.getRecordTypeIdByDevName(Case.SObjectType,SALES_OPERATION_CATEGORY)){
                            email = objEmailService.getSingleEmailMessageWithoutTargetObjectId(emailTemplateId, noReplyOWDId, caseobj.Id, toAddress, null, null);
                        }
                       

                        if(caseObj.RecordTypeId == Utility.getRecordTypeIdByDevName(Case.SObjectType,TAWTHEEQ_ENROLLMENT_RT)) {
                            Id emailTempId = objMetadataService.getAppSettingTextValue(TAWTHEEQ_ENROLLMENT_SR_CLOSURE_LEASING_ETID);
                            Id queueId = objMetadataService.getAppSettingTextValue(LEASING_TEAM_QUEUEID);
                            List<String> queueMemberEmails = new List<String>();
                            List<GroupMember> groupMemberList = GroupService.getGroupMembersByGroupIds(new Set<Id>{queueId});
                            for(GroupMember groupMemberRec : groupMemberList){
                                if(groupMemberRec.UserOrGroupId.getSObjectType() == User.sObjectType){
                                    queueMemberEmails.add(groupMemberRec.UserOrGroup.Email);
                                }
                            }
                            emailList.add(objEmailService.getSingleEmailMessageWithoutTargetObjectId(emailTempId, noReplyOWDId, caseobj.Id, queueMemberEmails, null, null));
                        }
                        if(email != Null)
                            emailList.add(email);
                    }
                }
            }
            
            casesToUpdate.add(caseToUpdate);
        }
        
        ActivityService servObj = ActivityService.getInstance();
        CaseService caseService = CaseService.getInstance(); 
        CaseAssignmentHistoryService assignObj = CaseAssignmentHistoryService.getInstance(); 
        
        if(!taskToInsert.isEmpty()) servObj.insertTasks(taskToInsert);
        if(!tasksToUpdate.isEmpty()) servObj.closeTasks(tasksToUpdate);  
        if(!casesToUpdate.isEmpty()) caseService.updateCases(casesToUpdate);    
        if(!caseAssignHistoryToLog.isEmpty()) assignObj.insertCaseAssignmentHistory(caseAssignHistoryToLog);
        if(!emailList.isEmpty())objEmailService.sendEmail(emailList);
    } 
    
    public void closeAllOpenTasksOnCancel(Set<Id> caseIds) {
        if (caseIds == null || caseIds.isEmpty()) return;
        
        ActivityService activityService = ActivityService.getInstance();
        CaseService caseObjService = CaseService.getInstance();
        
        
        List<Case> caseList = caseObjService.getCaseByIds(caseIds);
        Map<Id, List<Task>> caseVsTasks = activityService.fetchOpenTaskByCaseList(caseList);
        
        List<Task> tasksToClose = new List<Task>();
        
        for (List<Task> taskList : caseVsTasks.values()) {
            for (Task t : taskList) {
                t.Status = 'Completed'; 
                tasksToClose.add(t);
            }
        }
        
        if (!tasksToClose.isEmpty()) {
            activityService.closeTasks(tasksToClose); 
        }
    }
    public void closeAllOpenTasks(Set<Id> caseIds) {
        if (caseIds == null || caseIds.isEmpty()) return;
        ActivityService activityService = ActivityService.getInstance();
        List<Task> taskList = activityService.getOpenTasksBywhatIds(caseIds);
        activityService.closeTasks(taskList); 
    }
    public void reassignCurrentTask(Id caseId,String commentBody,String reason,Id userId) {
        ActivityService activityService = ActivityService.getInstance();
        CaseService caseService = CaseService.getInstance();
        
        List<Case> caseList = caseService.getCaseByIds(new Set<Id>{caseId});
        
        if (caseList.isEmpty()) return;
        
        Map<Id, List<Task>> caseVsTasks =
            activityService.fetchOpenTaskByCaseList(caseList);
        
        List<Task> tasksToUpdate = new List<Task>();
        List<Case> casesToUpdate = new List<Case>();
        List<CaseAssignmentHistory__c> historyList = new List<CaseAssignmentHistory__c>();
        
        for (Case c : caseList) {
            
            if (caseVsTasks.containsKey(c.Id)) {
                
                for (Task t : caseVsTasks.get(c.Id)) {
                    
                    t.OwnerId = userId;
                    t.Status = 'Open';
                    tasksToUpdate.add(t);
                    
                    casesToUpdate.add(new Case(
                        Id = c.Id,
                        OwnerId = userId
                    ));
                    
                    CaseAssignmentHistory__c history = new CaseAssignmentHistory__c();
                    history.Case__c = c.Id;
                    history.OwnerId = userId;
                    history.AssignmentDate__c = System.now();
                    history.Description__c = commentBody;
                    history.Reason__c = reason;
                    
                    historyList.add(history);
                }
            }
        }
        
        if (!tasksToUpdate.isEmpty()) {
            activityService.updateTasks(tasksToUpdate);
        }
        
        if (!casesToUpdate.isEmpty()) {
            caseService.updateCases(casesToUpdate);
        }
        
        if (!historyList.isEmpty()) {
            CaseAssignmentHistoryService.getInstance()
                .insertCaseAssignmentHistory(historyList);
        }
    }
    public Boolean isSameDepartment(Id caseId, String selectedDept) {
        
        List<Case> caseList = CaseService.getInstance().getCaseByIds(new Set<Id>{caseId});
        if (caseList.isEmpty()) return false;
        
        ServiceCatalogService service = ServiceCatalogService.getInstance();
        Map<Id, ServiceAction__c> currMap = service.getCurrentCaseServiceAction(caseList);
        
        if (currMap.isEmpty()) return false;
        
        String currentDept = currMap.values()[0].Department__c;
        
        return currentDept == selectedDept;
    }
    @TestVisible
    private Map<String, Id> getRecordTypeMap(){
        return new Map<String, Id>{
            ACKNOWLEDGEMENT_RECEIPT_RT => Utility.getRecordTypeIdByDevName(Case.SObjectType, ACKNOWLEDGEMENT_RECEIPT_RT),
                PAYMENT_DUE_DATE_UPDATE_RT => Utility.getRecordTypeIdByDevName(Case.SObjectType, PAYMENT_DUE_DATE_UPDATE_RT),
                THIRD_PARTY_FORM_RT => Utility.getRecordTypeIdByDevName(Case.SObjectType, THIRD_PARTY_FORM_RT),
                PAYMENT_SR_RT => Utility.getRecordTypeIdByDevName(Case.SObjectType, PAYMENT_SR_RT),
                POP_SHARE_SR_RT => Utility.getRecordTypeIdByDevName(Case.SObjectType, POP_SHARE_SR_RT),
                BANK_ACC_DTAIL_SR_RT => Utility.getRecordTypeIdByDevName(Case.SObjectType, BANK_ACC_DTAIL_SR_RT),
                GENERAL_ENQUIRY_RT => Utility.getRecordTypeIdByDevName(Case.SObjectType, GENERAL_ENQUIRY_RT)
                };
                    }
}