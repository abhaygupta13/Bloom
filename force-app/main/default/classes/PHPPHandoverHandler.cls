/***
Class       : PHPPHandoverHandler
Author      : Jhilik
Description : 
TestClass   : PHPPHandoverHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.     version              Date                      Details
1.          V1.0                02-03-2026                Initial Version 
****************************************************************************************************************/
public inherited sharing  class PHPPHandoverHandler {
    private static PHPPHandoverHandler instance;
    private static final String Handover_Payment_Type_PHPP = 'PHPP';
    private static final String Handover_Payment_Type_Mortgage = 'Mortgage';
    private static final String profilesToSkipValidations = 'profilesToSkipValidations';

    
    private static final String HO_QA_Snagging_Report = 'QA Snagging Report';
    private static final String HO_QA_DeSnagging_Report = 'QA Desnagging Report';
    private static final String HO_CHO_Snagging_Report = 'CHO Snagging Report';
    private static final String HO_CHO_DeSnagging_Report = 'CHO Desnagging Report';
    private static final String Title_Deed = 'Title Deed';
    private static final String ADDC_NOC = 'ADDC NOC';
  
    private static final String Emirates_Id = 'Emirates Id';
    private static final String Passport = 'Passport';
    private static final String SPA = 'SPA';
    private static final String MortgageValue = 'Mortgage Value';
    private static final String Mortgage_Cheque_Copy = 'Mortgage Cheque Copy';
    private static final String Mortgage_Contract = 'Mortgage Contract';
    private static final String BloomTitleDeed = 'Bloom Title Deed';
    private static final String BankNOC = 'Bank NOC';
    private static final String DeveloperNOC = 'Developer NOC';
    private static final String Leasing_ADDC_NOC = 'Leasing ADDC NOC';
    private static final String HO_Undertaking_Letter = 'HO Undertaking Letter';
    private static final String Handover_Sub_Status_Lease_Agreement = 'Lease Agreement';
    private static final String TawtheeqRegistrationConfirmation = 'Tawtheeq Registration Confirmation';
    private static final String HandoverPaymentAttachment = 'Handover Payment Attachment';
    private static final String HandoverServiceChargeClerance = 'Service Charge Clearance Letter';

    private static final String Orientation_Appointment = 'Home Orientation Appointment';
    private static final String KHO_Appointment = 'KHO Appointment';

    public static String Customer_Available = 'Customer Available';
    public static String Customer_Not_Available = 'Customer Not available';
    public static String Customer_Deligate_To_Bloom	 = 'Customer Delegate To Bloom';

    public static String Leasing_type_Owner_Occupied = 'Owner Occupied';

    private static final string MTD_OWE_NO_REPLY_SALES_IT_ID { get { return 'NoReplySalesIT'; } }
    private static final string HANDOVER_ASSIGN_TO_OWNER_TEMPLATE_ID { get { return 'HandoverTaskAssignmentNotificationETId'; } }
    private static final string BLOOM_CUSTOM_NOTIFICATION_DEV_NAME { get { return 'Bloom_Custom_Notifications'; } }

    private static final Map<String, String> nonPHPPStatusFlow = new Map<String, String>{
        'New' => 'QA Snagging',
        'QA Snagging' => 'QA De-Snagging',
        'QA De-Snagging' => 'Upload SOA',
        'Upload SOA' => 'Upload SPA',
        'Upload SPA' => 'Send Handover Notice',
        'Send Handover Notice' => 'Book Appointment with Customer',
        'Book Appointment with Customer' => 'Settlement Follow up',
        'Settlement Follow up' => 'Settlement Confirmation',
        'Settlement Confirmation' => 'Generate Bank NOC',
        'Generate Bank NOC' => 'Upload Mortgage Release Documents',
        'Upload Mortgage Release Documents' => 'ADREC Approval and Mortgage Release',
        'ADREC Approval and Mortgage Release' => 'Generate Developer NOC',
        'Generate Developer NOC' => 'Developer NOC Internal Follow Up',
        'Developer NOC Internal Follow Up' => 'Register Title Deed',
        'Register Title Deed' => 'Transfer Utilities',
        'Transfer Utilities' => 'Mortgage Cheque Clearance',
        'Mortgage Cheque Clearance' => 'Handover Signing Document (KHO) Appointment',
        'Handover Signing Document (KHO) Appointment' => 'Handover Signing Document',
        'Handover Signing Document' => 'Handover Completed'
    };

    private static final Map<String, String> PHPPStatusFlow = new Map<String, String>{
        'New' => 'QA Snagging',
        'QA Snagging' => 'QA De-Snagging',
        'QA De-Snagging' => 'Upload SOA',
        'Upload SOA' => 'Upload SPA',
        'Upload SPA' => 'Send Handover Notice',
        'Send Handover Notice' => 'Book Appointment with Customer',
        'Book Appointment with Customer' => 'Settlement Follow up',
        'Settlement Follow up' => 'Settlement Confirmation',
        'Settlement Confirmation' => 'HO Undertaking Letter',
        'HO Undertaking Letter' => 'PHPP Handover Keys',
        'PHPP Handover Keys' => 'Handover Completed'
    };

    private static final Map<String, String> unsoldUnitiStatusFlow = new Map<String, String>{
        'New' => 'QA Snagging',
        'QA Snagging' => 'QA De-Snagging',
        'QA De-Snagging' => 'Handover Keys to BAM',
        'Handover Keys to BAM' => 'Handover Completed'
    };

    public PHPPHandoverHandler() {
    }

    public static PHPPHandoverHandler getInstance() { 
        if(instance == null) {
            instance = new PHPPHandoverHandler();
        }
        return instance;
    }

    /* public void createFirstTask(List<Handover__c> listOfHandovers) {
        System.debug('::::: Inside createFirstTask ::::: ');
        HandoverHandler obj = HandoverHandler.getInstance();
        obj.createNewAndCloseCurrentTask(listOfHandovers);
    } */

    public Map<String,Object> validateHOTeamTasks(Handover__c handoverRecord, List<Task> openTaskList){
        //List<String> parallelTasks = new List<String>{'Pre CHO Check','CHO Snagging','CHO De-Snagging'};
        Map<String, Object> response = new Map<String, Object>();
        response.put('status', 'success');
        response.put('message', 'Task has been closed.');

        String lastChar = openTaskList[0].SubType__c.substring(openTaskList[0].SubType__c.length() - 1);
        if(lastChar != '1'){
            DocumentService objDocumentService = DocumentService.getInstance();
            Map<String, Document__c> documentMap = new Map<String, Document__c>();
            List<Document__c> handoverDocumentList = objDocumentService.getDocumentsOnHandoverWithAttachments(handoverRecord.Id);
            for (Document__c doc : handoverDocumentList) {
                documentMap.put(doc.Document_Name__c, doc);
            }

            if(lastChar == '2'){
                if (!documentMap.containsKey(HO_CHO_Snagging_Report)) {
                    response.put('status', 'error');
                    response.put('message', 'Please upload CHO Snagging Report');
                    return response;
                }            
            } 
            else if(lastChar == '3'){
                if (!documentMap.containsKey(HO_CHO_DeSnagging_Report)) {
                    response.put('status', 'error');
                    response.put('message', 'Please upload CHO Desnagging Report');
                    return response;
                }
            }
        }
        response = createNextHOTask(handoverRecord, openTaskList[0]);
        return response;
    }

    public Map<String,Object> createNextHOTask(Handover__c handoverRecord, Task currentOpenTask){
        Map<String, Object> response = new Map<String, Object>();
        response.put('status', 'success');
        response.put('message', 'Task has been closed.');

        String lastChar = currentOpenTask.SubType__c.substring(currentOpenTask.SubType__c.length() - 1);
        String nextStep = String.valueOf(Integer.valueOf(lastChar)+1);
        
        ActivityService objActivityService = ActivityService.getInstance();
        ServiceCatalogService servObj = ServiceCatalogService.getInstance();

        List<Task> taskToInsert = new List<Task>(); 
        List<Task> tasksToReopen = new List<Task>();
        List<User> userList = new List<User>();
        if(handoverRecord.HO_Agent_Assigned_User__c != NULL){
            userList = [SELECT Id, Name, BusinessHour__c FROM User WHERE Id = :handoverRecord.HO_Agent_Assigned_User__c];
        }
        
        Map<Id,Map<String,ServiceAction__c>> serviceCatalogIdToActionOrderToServiceActionMap = servObj.getHOTaskServiceActions(new List<Handover__c>{handoverRecord});

        if(!serviceCatalogIdToActionOrderToServiceActionMap.isEmpty() 
                && serviceCatalogIdToActionOrderToServiceActionMap.containsKey(handoverRecord.ServiceCatalog__c)
                && serviceCatalogIdToActionOrderToServiceActionMap.get(handoverRecord.ServiceCatalog__c).containsKey(nextStep)) {
                
            ServiceAction__c currentAction = serviceCatalogIdToActionOrderToServiceActionMap.get(handoverRecord.ServiceCatalog__c).get(nextStep);
            List<Task> existingClosedTask = objActivityService.fetchCompletedTaskFromServiceAction(currentAction, handoverRecord.id);
            if(existingClosedTask.isEmpty()){
                Task tsk = new Task();
                tsk.Subject = currentAction.TaskSubject__c;
                //tsk.Order__c = currentAction.Order__c;
                tsk.FinalTask__c = currentAction.FinalTask__c;
                tsk.Type__c = currentAction.TaskType__c;
                tsk.SubType__c = currentAction.TaskSubType__c;
                tsk.WhatId = handoverRecord.Id; 
                tsk.Type = 'Other';
                tsk.Department__c = currentAction.Department__c;
                tsk.ActivityDate = currentAction.Due_in_days__c != null  ? System.now().date().addDays(Integer.valueOf(currentAction.Due_in_days__c)): System.now().date();
                tsk.SLAHours__c = currentAction.SLAHours__c;
                tsk.OwnerId = handoverRecord.HO_Agent_Assigned_User__c;
                tsk.AssignedDateTime__c  = System.now();
                if(userList != NULL && userList.size() > 0 && userList[0].BusinessHour__c != NULL){
                    tsk.BusinessHours__c = userList[0].BusinessHour__c;
                }
                taskToInsert.add(tsk);
                
            }
            /* else if(!existingClosedTask.isEmpty()){
                existingClosedTask[0].Status = 'Open';
                existingClosedTask[0].OwnerId = handoverRecord.HO_Agent_Assigned_User__c;
                tasksToReopen.add(existingClosedTask[0]);  
            } */
        }

        objActivityService.closeTasks(new List<Task>{currentOpenTask});
        if(!taskToInsert.isEmpty()) objActivityService.insertTasks(taskToInsert); 
        if(!tasksToReopen.isEmpty()) objActivityService.updateTasks(tasksToReopen);
        if(lastChar == '2'){
            if(!handoverRecord.PropertyHomeOrientationReport_Sent__c && handoverRecord.Customer_Availability_for_CHO__c == 'Customer Available') {
                SendEmailInvocable.EmailRequest emailReq = new SendEmailInvocable.EmailRequest();
                emailReq.templateName = 'Handover Completion Customer Attended';
                emailReq.recordId = handoverRecord.Id;
                SendEmailInvocable.sendEmail(new List<SendEmailInvocable.EmailRequest>{emailReq});
            } else if(!handoverRecord.PropertyHomeOrientationByBloom__c && handoverRecord.Customer_Availability_for_CHO__c == 'Customer Delegate to BLoom'){
                SendEmailInvocable.EmailRequest emailReq = new SendEmailInvocable.EmailRequest();
                emailReq.templateName = 'Handover Completion Customer Not Attended';
                emailReq.recordId = handoverRecord.Id;
                SendEmailInvocable.sendEmail(new List<SendEmailInvocable.EmailRequest>{emailReq});
            } else if(!handoverRecord.PropertyHomeOrientationWOCustomer__c && handoverRecord.Customer_Availability_for_CHO__c == 'Customer Not available'){
                SendEmailInvocable.EmailRequest emailReq = new SendEmailInvocable.EmailRequest();
                emailReq.templateName = 'Home Orientation By Bloom';
                emailReq.recordId = handoverRecord.Id;
                SendEmailInvocable.sendEmail(new List<SendEmailInvocable.EmailRequest>{emailReq});
            }
        }
        else if(lastChar == '3' && !handoverRecord.HasCHODesnaggingemailsent__c){
            SendEmailInvocable.EmailRequest emailReq = new SendEmailInvocable.EmailRequest();
            emailReq.templateName = 'CHO Desnagging Communication Email Template';
            emailReq.recordId = handoverRecord.Id;
            SendEmailInvocable.sendEmail(new List<SendEmailInvocable.EmailRequest>{emailReq});
        }

        if(!taskToInsert.isEmpty() || !tasksToReopen.isEmpty()){
            notifyOwners(new Map<Id,List<Id>>{handoverRecord.Id => new List<Id>{handoverRecord.HO_Agent_Assigned_User__c}});
        }
        return response;
    }

    public Map<String, Object> validatePHPPHandoverForNextReview(Handover__c handoverRecord, Boolean updateHandover) {
        HandoverService handoverServiceObj = HandoverService.getInstance();
        DocumentService objDocumentService = DocumentService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        Map<String, Object> response = new Map<String, Object>();
        Boolean handoverToUpdate = false;
        response.put('status', 'success');
        response.put('message', 'Handover has been updated successfully');
        Boolean createTawtheeqEnrollmentSR = false;

        List<String> excludedHandoverStagesList = String.isNotBlank(handoverRecord.Handover_Phase__r.ExcludedHandoverStages__c) ? handoverRecord.Handover_Phase__r.ExcludedHandoverStages__c.split(';') : new List<String>();
        System.debug('excludedHandoverStagesList ::::: '+ excludedHandoverStagesList);
        List<String> profilesToSkipValidations = objMetadataService.getAppSettingTextValue(profilesToSkipValidations).split(',');

        if (handoverRecord == null) {
            response.put('status', 'error');
            response.put('message', 'Invalid Handover Record ID.');
            return response;
        }

        if(!profilesToSkipValidations.contains(handoverRecord.Current_USer_Profile__c) || Test.isRunningTest()){
            response = commonValidationChecks(handoverRecord);
        
            if(response.get('status') == 'success'){
                if(handoverRecord.Sub_Status__c == HandoverConstants.Handover_Sub_Status_Settlement_Confirmation){
                    handoverRecord.Payment_Settled__c = true;
                    if(handoverRecord.Payment_Type__c == Handover_Payment_Type_PHPP) {
                        handoverRecord.Payment_Date__c = Date.today();
                    }
                    handoverToUpdate = true;
                }

                if(handoverRecord.Sub_Status__c == HandoverConstants.Handover_Sub_Status_Upload_Signed_Tawtheeq_Agreement && handoverRecord.Payment_Type__c == Handover_Payment_Type_PHPP){

                    SalesOrderService salesOrderService = SalesOrderService.getInstance();
                    Map<Id, InstallmentLines__c> latestInstallmentLinesMap = new Map<Id, InstallmentLines__c>();
                    List<SalesOrder__c> salesOrderMap = salesOrderService.getSalesOrdersWithInstallment(new Set<Id>{handoverRecord.Sales_Order__c});
                    for (SalesOrder__c salesOrder : salesOrderMap) {
                        if (!salesOrder.InstallmentLines__r.isEmpty()) {
                            latestInstallmentLinesMap.put(salesOrder.Id, salesOrder.InstallmentLines__r[0]);
                        }
                    }

                    handoverRecord.Payment_Settled__c = true; 
                    handoverRecord.Lease_Start_Date__c = Date.today();
                    if(handoverRecord.Lease_Type__c == Leasing_type_Owner_Occupied){
                        handoverRecord.Lease_Amount__c = 1; 
                    }
                        
                    InstallmentLines__c latestInstallment = latestInstallmentLinesMap.get(handoverRecord.Sales_Order__c);
                    if(latestInstallment!=null){
                        handoverRecord.Lease_End_Date__c = latestInstallment.InstallmentDate__c.addDays(60);
                    }
                    handoverToUpdate = true;
                }

                if(handoverRecord.Sub_Status__c == HandoverConstants.Handover_Sub_Status_Lease_Agreement && handoverRecord.Payment_Type__c == Handover_Payment_Type_PHPP){
                    handoverRecord.Leasing_Agent__c = UserInfo.getUserId();
                    handoverToUpdate = true;
                }

                if(handoverRecord.Sub_Status__c == HandoverConstants.Handover_Sub_Status_ADREC_Approval_and_Mortgage_Release){
                    handoverRecord.Payment_Settled__c = true;
                    handoverToUpdate = true;
                }

                if(handoverToUpdate) {
                    handoverServiceObj.updateHandover(handoverRecord);
                }
            }
        }
        
        if (response.get('status') == 'error') {
            return response;
        }
        if(response.get('status') == 'success'){
            ActivityService objActivityService = ActivityService.getInstance();
            Map<String,Task> subjectToTaskMap = new  Map<String,Task>();
            Map<Id,Task> ownerIdToTaskMap = new Map<Id,Task>();
            List<Task> openTaskList = objActivityService.getOpenTasksBywhatIds(new Set<Id>{handoverRecord.Id});

            if (handoverRecord.Sub_Status__c == HandoverConstants.Handover_Sub_Status_Settlement_Confirmation) {
                if(handoverRecord.Property_Enrollment_Under_Tawtheeq__c && handoverRecord.Property_Enrollment_Under_Tawtheeq_Accou__c > 0){
                    createTawtheeqEnrollmentSR = true;
                }
            }

            for(Task taskRec : openTaskList){
                subjectToTaskMap.put(taskRec.Subject, taskRec);
                ownerIdToTaskMap.put(taskRec.OwnerId, taskRec);
            }
            if(updateHandover){
                //handleNextSteps(handoverRecord, updateHandover); 
            } 
            else if(!updateHandover && !ownerIdToTaskMap.isEmpty() && ownerIdToTaskMap.containsKey(UserInfo.getUserId())) {
                
                if(!subjectToTaskMap.isEmpty() && subjectToTaskMap.containsKey(handoverRecord.Sub_Status__c) && subjectToTaskMap.get(handoverRecord.Sub_Status__c).OwnerId == UserInfo.getUserId()) {
                    //handoverRecord.Sub_Status__c = handoverRecord.Next_Step__c;
                    if(handoverRecord.Sales_Order__c != NULL) {
                        //if(handoverRecord.Payment_Type__c == 'PHPP'){
                            handoverRecord.Sub_Status__c = determineNextStageForHandover(PHPPStatusFlow, handoverRecord.Sub_Status__c, excludedHandoverStagesList);
                        /* } else {
                            handoverRecord.Sub_Status__c = determineNextStageForHandover(nonPHPPStatusFlow, handoverRecord.Sub_Status__c, excludedHandoverStagesList);
                        } */
                    } else {
                        handoverRecord.Sub_Status__c = determineNextStageForHandover(unsoldUnitiStatusFlow, handoverRecord.Sub_Status__c, excludedHandoverStagesList);
                    }
                    update handoverRecord;
                }
                else {
                    objActivityService.closeTasks(new List<Task>{ownerIdToTaskMap.get(UserInfo.getUserId())});
                }
                if(createTawtheeqEnrollmentSR){
                    createTawtheeqEnrollmentCase(handoverRecord);
                }
            }
            else if(!updateHandover) {

                response.put('status', 'error');
                response.put('message', 'Please try again after assigning the task to yourself by Clicking on Assign To Me button.');
                return response;
            }
        }
        return response;
    }

    public Map<String, Object> validateNonPHPPHandoverForNextReview(Handover__c handoverRecord, Boolean updateHandover) {
        HandoverService handoverServiceObj = HandoverService.getInstance();
        DocumentService objDocumentService = DocumentService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        Map<String, Object> response = new Map<String, Object>();
        response.put('status', 'success');
        response.put('message', 'Handover has been updated successfully');
        Boolean createTawtheeqEnrollmentSR = false;

        List<String> excludedHandoverStagesList = String.isNotBlank(handoverRecord.Handover_Phase__r.ExcludedHandoverStages__c) ? handoverRecord.Handover_Phase__r.ExcludedHandoverStages__c.split(';') : new List<String>();
        System.debug('excludedHandoverStagesList ::::: '+ excludedHandoverStagesList);
        List<String> profilesToSkipValidations = objMetadataService.getAppSettingTextValue(profilesToSkipValidations).split(',');

        if (handoverRecord == null) {
            response.put('status', 'error');
            response.put('message', 'Invalid Handover Record ID.');
            return response;
        }
        
        if(!profilesToSkipValidations.contains(handoverRecord.Current_USer_Profile__c)){
            response = commonValidationChecks(handoverRecord);
        }
        
        if (response.get('status') == 'error') {
            return response;
        }
        if(response.get('status') == 'success'){
            ActivityService objActivityService = ActivityService.getInstance();
            Map<String,Task> subjectToTaskMap = new  Map<String,Task>();
            Map<Id,Task> ownerIdToTaskMap = new Map<Id,Task>();
            List<Task> openTaskList = objActivityService.getOpenTasksBywhatIds(new Set<Id>{handoverRecord.Id});
            
            if (handoverRecord.Sub_Status__c == HandoverConstants.Handover_Sub_Status_Settlement_Confirmation) {
                if(handoverRecord.Property_Enrollment_Under_Tawtheeq__c && handoverRecord.Property_Enrollment_Under_Tawtheeq_Accou__c > 0){
                    createTawtheeqEnrollmentSR = true;
                }
            }

            /* if (handoverRecord.Sub_Status__c == HandoverConstants.Handover_Sub_Status_Upload_Mortgage_Release_Documents) {
                Id salesOrderId = handoverRecord.Sales_Order__c;
                List<Document__c> docList = objDocumentService.getSalesOrderDocumentsByName(new List<String>{salesOrderId} , BloomTitleDeed);
            } */

            for(Task taskRec : openTaskList){
                subjectToTaskMap.put(taskRec.Subject, taskRec);
                ownerIdToTaskMap.put(taskRec.OwnerId, taskRec);
            }

            if(updateHandover){
                handleNextSteps(handoverRecord, updateHandover); 
            } 
            else if(!updateHandover && !ownerIdToTaskMap.isEmpty() && ownerIdToTaskMap.containsKey(UserInfo.getUserId())) {
                
                if(!subjectToTaskMap.isEmpty() && subjectToTaskMap.containsKey(handoverRecord.Sub_Status__c) && subjectToTaskMap.get(handoverRecord.Sub_Status__c).OwnerId == UserInfo.getUserId()) {
                    if(handoverRecord.Payment_Type__c == 'Cash'){
                        //handoverRecord.Sub_Status__c = HandoverConstants.Handover_Sub_Status_Handover_Signing_Document_Appointment;
                        excludedHandoverStagesList.add(HandoverConstants.Handover_Sub_Status_Mortgage_Cheque_Clearance);
                    }

                    //handoverRecord.Sub_Status__c = handoverRecord.Next_Step__c;
                    if(handoverRecord.Sales_Order__c != NULL) {
                        /* if(handoverRecord.Payment_Type__c == 'PHPP'){
                            handoverRecord.Sub_Status__c = determineNextStageForHandover(PHPPStatusFlow, handoverRecord.Sub_Status__c, excludedHandoverStagesList);
                        } else { */
                            handoverRecord.Sub_Status__c = determineNextStageForHandover(nonPHPPStatusFlow, handoverRecord.Sub_Status__c, excludedHandoverStagesList);
                        //}
                    } else {
                        handoverRecord.Sub_Status__c = determineNextStageForHandover(unsoldUnitiStatusFlow, handoverRecord.Sub_Status__c, excludedHandoverStagesList);
                    }
                    update handoverRecord;
                } else {
                    objActivityService.closeTasks(new List<Task>{ownerIdToTaskMap.get(UserInfo.getUserId())});
                }
                if(createTawtheeqEnrollmentSR){
                    createTawtheeqEnrollmentCase(handoverRecord);
                }
            } 
            else if(!updateHandover) {

                response.put('status', 'error');
                response.put('message', 'Please try again after assigning the task to yourself by Clicking on Assign To Me button.');
                return response;
            }
        }
        
        return response;
    }

    public Map<String, Object> commonValidationChecks(Handover__c handoverRecord) {
        DocumentService objDocumentService = DocumentService.getInstance();
        ActivityService objActivityService = ActivityService.getInstance();
        ProjectService objProjectService = ProjectService.getInstance();
        Map<String, Object> response = new Map<String, Object>();
        response.put('status', 'success');
        response.put('message', 'Handover has been updated successfully');
        Map<Id, Project__c> projectMap = new Map<Id, Project__c>(objProjectService.getProjectsByIds(new Set<Id>{handoverRecord.Project__c}));
        Map<String, Document__c> documentMap = new Map<String, Document__c>();
        List<Document__c> handoverDocumentList = objDocumentService.getDocumentsOnHandoverWithAttachments(handoverRecord.Id);
        
        for (Document__c doc : handoverDocumentList) {
            documentMap.put(doc.Document_Name__c, doc);
        }

        Set<String> meetingTypes = new Set<String>{Orientation_Appointment,KHO_Appointment};
        List<Event> eventList = objActivityService.getEventByWhatIdAndType(new Set<Id>{handoverRecord.Id}, meetingTypes);
        Map<String,Event> eventTypeToEventMap = new Map<String,Event>();
        for(Event evt : eventList){
            eventTypeToEventMap.put(evt.Type, evt);
        }
        //if(handoverRecord.Is_Manual__c == Constants.YES){
            if (handoverRecord.Sub_Status__c == HandoverConstants.Handover_Sub_Status_QA_Snagging) {            
                if (!documentMap.containsKey(HO_QA_Snagging_Report)) {
                    response.put('status', 'error');
                    response.put('message', 'Please upload QA Snagging Report');
                    return response;
                } 
            }
        
            if (handoverRecord.Sub_Status__c == HandoverConstants.Handover_Sub_Status_QA_DeSnagging) {
                if (!documentMap.containsKey(HO_QA_DeSnagging_Report)) {
                    response.put('status', 'error');
                    response.put('message', 'Please upload QA Desnagging Report');
                    return response;
                }                     
            }

            if (handoverRecord.Sub_Status__c == HandoverConstants.Handover_Sub_Status_Upload_SOA) {            
                if (!documentMap.containsKey('SOA')) {
                    response.put('status', 'error');
                    response.put('message', 'Please upload SOA before moving to next step.');
                    return response;
                } 
            }
        
            if (handoverRecord.Sub_Status__c == HandoverConstants.Handover_Sub_Status_Upload_SPA) {
                if (!documentMap.containsKey(SPA)) {
                    response.put('status', 'error');
                    response.put('message', 'Please upload SPA before moving to next step.');
                    return response;
                }                     
            }
            
            
            if (handoverRecord.Sub_Status__c == HandoverConstants.Handover_Sub_Status_CHO_Snagging) {
                if (!documentMap.containsKey(HO_CHO_Snagging_Report)) {
                    response.put('status', 'error');
                    response.put('message', 'Please upload CHO Snagging Report');
                    return response;
                } 
            }
            
            if (handoverRecord.Sub_Status__c == HandoverConstants.Handover_Sub_Status_CHO_DeSnagging) {
                if (!documentMap.containsKey(HO_CHO_DeSnagging_Report)) {
                    response.put('status', 'error');
                    response.put('message', 'Please upload CHO Desnagging Report');
                    return response;
                }
            }
        //}

        if (handoverRecord.Sub_Status__c == HandoverConstants.Handover_Sub_Status_Send_CHO_and_NOC) {
            if(!handoverRecord.Is_Notice_of_Completion_Sent__c){
                response.put('status', 'error');
                response.put('message', 'Please send CHO and NOC before completing the task.');
                return response;
            }
            if (!documentMap.containsKey(HO_QA_DeSnagging_Report)) {
                response.put('status', 'error');
                response.put('message', 'Please Complete QA-Desnagging Process Before Moving Forward');
                return response;
            }
            
        }
        
        /* if(handoverRecord.Sub_Status__c == HandoverConstants.Sub_Status_Home_Orientation_Sent && handoverRecord.Unit_is_Ready__c != True){
            //handoverRecord.addError(VALIDATION_You_havenot_sent_the_Home_Orientation);
            response.put('status', 'error');
            response.put('message', 'Invalid Handover Record ID.');
            return response;
        } */

        if(handoverRecord.Sub_Status__c == HandoverConstants.Handover_Sub_Status_Upload_Signed_Tawtheeq_Agreement && handoverRecord.Payment_Type__c!='Mortgage' ){
            if(!documentMap.containsKey(TawtheeqRegistrationConfirmation)){
                response.put('status', 'error');
                response.put('message', 'Please Upload Tawtheeq Registration Confirmation before closing this task.');
                return response;
            } 
        }
        
        if(handoverRecord.Sub_Status__c == HandoverConstants.Handover_Sub_Status_Mortgage_Cheque_Clearance && handoverRecord.Payment_Type__c=='Mortgage' ){
            if (!documentMap.containsKey(HandoverPaymentAttachment)) {
                response.put('status', 'error');
                    response.put('message', 'Please Upload Handover Payment Attachment Before Closing This Task');
                    return response;
            }
            if(!handoverRecord.Payment_Settled__c || handoverRecord.Payment_Date__c == NULL){
                response.put('status', 'error');
                response.put('message', 'Please check payment settlement details before closing this task.');
                return response;
            }
        }
        
        if(handoverRecord.Sub_Status__c == HandoverConstants.Handover_Sub_Status_Book_Appointment_with_Customer &&
            (eventTypeToEventMap == NULL || !eventTypeToEventMap.containsKey(Orientation_Appointment))
            && (String.isBlank(handoverRecord.Customer_Availability_for_CHO__c) || handoverRecord.Is_Appointment_Booked__c == false) ){
            response.put('status', 'error');
            response.put('message', 'Please Schedule Meeting and Update Customer Availablity Before Closing This Task.');
            return response;
        }
        
        if(handoverRecord.Sub_Status__c == HandoverConstants.Handover_Sub_Status_Pre_CHO_Check && 
        (handoverRecord.Customer_Availability_for_CHO__c == Customer_Deligate_To_Bloom || handoverRecord.Customer_Availability_for_CHO__c == Customer_Not_Available)){
        }
        else{
            if(handoverRecord.Sub_Status__c == HandoverConstants.Handover_Sub_Status_Pre_CHO_Check && handoverRecord.Is_Appointment_Booked__c !=true){
                response.put('status', 'error');
                response.put('message', 'Please Schedule Meeting and Update Customer Availablity Before Closing This Task.');
                return response;
            }
        }
        
        if(handoverRecord.Sub_Status__c == HandoverConstants.Handover_Sub_Status_Settlement_Follow_up && handoverRecord.Is_Notice_of_Completion_Sent__c == false ){
            response.put('status', 'error');
            response.put('message', 'Please send NOC before closing this task.');
            return response;
        }
        
        Project__c proj = projectMap.get(handoverRecord.Project__c);
        if (handoverRecord.Sub_Status__c == HandoverConstants.Handover_Sub_Status_Generate_Bank_NOC && handoverRecord.Payment_Type__c != Handover_Payment_Type_PHPP) { //&& !proj.IsByPassHOStatus__c
            if(!documentMap.containsKey(BankNOC)) {
                response.put('status', 'error');
                response.put('message', 'Please generate Bank NOC.');
                return response;
            }
        }
        if (handoverRecord.Sub_Status__c == HandoverConstants.Handover_Sub_Status_Upload_Mortgage_Release_Documents) {
            if(!documentMap.containsKey(BloomTitleDeed)) {
                response.put('status', 'error');
                response.put('message', 'Please Upload Bloom Title Deed Document Before Closing This Task.');
                return response;
            }
            /* else {
                Id salesOrderId = handoverRecord.Sales_Order__c;
                List<Document__c> docList = objDocumentService.getSalesOrderDocumentsByName(new List<String>{salesOrderId} , BloomTitleDeed);
                docList[0].Content_Version_Id__c = documentMap.get(BloomTitleDeed).Content_Version_Id__c;
                docList[0].ContentDocumentId__c = documentMap.get(BloomTitleDeed).ContentDocumentId__c;
                objDocumentService.updateDocument(docList[0]);
            } */
        }
        
        if (handoverRecord.Sub_Status__c == HandoverConstants.Handover_Sub_Status_Settlement_Follow_up) {
            if(handoverRecord.Payment_Type__c == NULL){
                response.put('status', 'error');
                response.put('message', 'Please add Payment Type Before Closing This Task.');
                return response;
            }
            if(handoverRecord.Payment_Type__c == Handover_Payment_Type_Mortgage){ // Added by Moneeb 
                if(!documentMap.containsKey(Mortgage_Contract) || !documentMap.containsKey(Mortgage_Cheque_Copy) || !documentMap.containsKey(Emirates_Id) || !documentMap.containsKey(Passport)) {
                    response.put('status', 'error');
                    response.put('message', 'Please Upload the Mortgage Contract, Mortgage Cheque Copy, EmiratesId and Passport Copy.');
                    return response;
                }
            }else{
                if(!documentMap.containsKey(Emirates_Id) || !documentMap.containsKey(Passport)){
                    response.put('status', 'error');
                    response.put('message', 'Please Upload the EmiratesId and Passport Copy.');
                    return response;
                }
            }
        }

        if (handoverRecord.Sub_Status__c == HandoverConstants.Handover_Sub_Status_Settlement_Confirmation && handoverRecord.Payment_Type__c != 'Mortgage') {
            if(!handoverRecord.Payment_Settled__c || handoverRecord.Payment_Date__c == NULL){
                response.put('status', 'error');
                response.put('message', 'Please check payment settlement details before closing this task.');
                return response;
            }
        }
        
        if (handoverRecord.Sub_Status__c == HandoverConstants.Handover_Sub_Status_Register_Title_Deed) {
            if(!documentMap.containsKey(Title_Deed)){
                response.put('status', 'error');
                response.put('message', 'Please Upload Title Deed Document Before Completing This Task.');
                return response;
            }
            else if (!documentMap.containsKey(DeveloperNOC)) {
                response.put('status', 'error');
                response.put('message', 'Please Developer NOC Document Before Completing This Task.');
                return response;
            }            
            else {
                Id salesOrderId = handoverRecord.Sales_Order__c;
                List<Document__c> docList = objDocumentService.getSalesOrderDocumentsByName(new List<String>{salesOrderId} , Title_Deed);
                docList[0].Content_Version_Id__c = documentMap.get(Title_Deed).Content_Version_Id__c;
                docList[0].ContentDocumentId__c = documentMap.get(Title_Deed).ContentDocumentId__c;
                objDocumentService.updateDocument(docList[0]);
            }            
        } 
        if (handoverRecord.Sub_Status__c == HandoverConstants.Handover_Sub_Status_Upload_Signed_Tawtheeq_Agreement) {
            if (!documentMap.containsKey(TawtheeqRegistrationConfirmation)) {
                response.put('status', 'error');
                    response.put('message', 'Please Upload Tawtheeq Registration Confirmation Document Before Completing This Task.');
                    return response;
            }
        }
        if (handoverRecord.Sub_Status__c == HandoverConstants.Handover_Sub_Status_HO_Undertaking_Letter) {
            if (!documentMap.containsKey(HO_Undertaking_Letter)) {
                response.put('status', 'error');
                response.put('message', 'Please upload the HO Undertaking Letter Before Completing This Task.');
                return response;
            }
        }
        if (handoverRecord.Sub_Status__c == HandoverConstants.Handover_Sub_Status_Transfer_Utilities) {
            if (!documentMap.containsKey(ADDC_NOC)) {
                response.put('status', 'error');
                response.put('message', 'Please upload the ADDC NOC Document Before Completing This Task.');
                return response;
            }
        }
        if (handoverRecord.Sub_Status__c == HandoverConstants.Handover_Sub_Status_Mortgage_Cheque_Clearance && handoverRecord.Payment_Type__c != HandoverConstants.Handover_Payment_Type_Cash) {
            if(handoverRecord.Payment_Date__c == NULL && !handoverRecord.Payment_Settled__c){
                response.put('status', 'error');
                response.put('message', 'Please add Payment Date and Payment Settled Before Closing This Task.');
                return response;
            }
            if (!documentMap.containsKey(ADDC_NOC)) {
                response.put('status', 'error');
                response.put('message', 'Please upload the ADDC NOC Document Before Completing This Task.');
                return response;
            }
        }
        if (handoverRecord.Sub_Status__c == HandoverConstants.Handover_Sub_Status_Handover_Signing_Document_Appointment){
            System.debug('eventList ::::: '+ eventList);
            //Document__c doc = documentMap.get(Leasing_ADDC_NOC);
            if(eventTypeToEventMap == NULL || !eventTypeToEventMap.containsKey(KHO_Appointment)){  
                response.put('status', 'error');
                response.put('message', 'Please book an appointment before closing this task.');
                return response;                                                                  
            }
        }
        String documentPattern = 'Lease Agreement';
        Boolean patternMatched = false;
        if (handoverRecord.Sub_Status__c == Handover_Sub_Status_Lease_Agreement && handoverRecord.Payment_Type__c == Handover_Payment_Type_PHPP) {
            for (String docName : documentMap.keySet()) {
                if (docName.contains(documentPattern)) {
                    patternMatched = true;
                }
            }
            if(!patternMatched){
                response.put('status', 'error');
                response.put('message', 'Please Upload Lease Agreement Documents.');
                return response;
            }
        }

        if(handoverRecord.Sub_Status__c == HandoverConstants.Handover_Sub_Status_PHPP_Handover_Keys) {
            if (!documentMap.containsKey(HO_CHO_Snagging_Report)) {
                response.put('status', 'error');
                response.put('message', 'Please upload CHO Snagging Report');
                return response;
            }  
            if (!documentMap.containsKey(HO_CHO_DeSnagging_Report)) {
                response.put('status', 'error');
                response.put('message', 'Please upload CHO Desnagging Report');
                return response;
            }
        }

        /* if(handoverRecord.Early_Settlement__c != oldHOMap.get(handoverRecord.Id).Early_Settlement__c 
            && handoverRecord.Sub_Status__c == HandoverConstants.Handover_Sub_Status_PHPP_Handover_Keys 
            && handoverRecord.Payment_Type__c == Handover_Payment_Type_PHPP) { 
                //ho.addError(VALIDATION_Complete_KHO_Process); 
            response.put('status', 'error');
            response.put('message', 'Please Complete the KHO Process Before Closing This Task.');
            return response;
        } */

        return response;
    }


    public void handleNextSteps(Handover__c handoverRecord, Boolean updateHandover){
        HandoverHandler objHandoverHandler = HandoverHandler.getInstance();
        objHandoverHandler.createNewAndCloseCurrentTask(new List<Handover__c>{handoverRecord}, updateHandover);
    }

    public void notifyOwners(Map<Id, List<Id>> handoverIdToTaskOwnerIdList){
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        HandoverService handoverServiceObj = HandoverService.getInstance();
        
        Id bloomNoReplySalesOWEId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_SALES_IT_ID);
        Id handoverAssignToOwnerETId = objMetadataService.getAppSettingTextValue(HANDOVER_ASSIGN_TO_OWNER_TEMPLATE_ID);
        
        List<Messaging.SingleEmailMessage> msgList = new List<Messaging.SingleEmailMessage>();
        CustomNotificationType notificationType = CustomNotificationService.getInstance().getCustomNotificationTypeByName(BLOOM_CUSTOM_NOTIFICATION_DEV_NAME);
        
        for(Id handoverId : handoverIdToTaskOwnerIdList.keySet()){
            List<Id> ownerIds = handoverIdToTaskOwnerIdList.get(handoverId);
            
            if(ownerIds == null || ownerIds.isEmpty()) continue;
            
            for(Id ownerId : ownerIds){
                if(ownerId == null) continue;
                
                List<String> recipientEmails = objEmailService.getOwnerEmails(ownerId);
                
                if(recipientEmails != null && !recipientEmails.isEmpty()){
                    // Send email notification
                    Messaging.SingleEmailMessage objEmailMessage = objEmailService.getSingleEmailMessageWithoutTargetObjectId(
                        handoverAssignToOwnerETId, 
                        bloomNoReplySalesOWEId, 
                        handoverId, 
                        recipientEmails, 
                        null, 
                        null
                    );
                    msgList.add(objEmailMessage);
                }
            }
        }
        
        if(!msgList.isEmpty()){
            objEmailService.sendEmail(msgList);
        }
    }

    public String determineNextStageForHandover(Map<String, String> stageMap, String currentStage, List<String> excludedHandoverStagesList){
        System.debug('stageMap ::::: '+ stageMap);
        System.debug('currentStage ::::: '+ currentStage);
        System.debug('excludedHandoverStagesList ::::: '+ excludedHandoverStagesList);
        String nextStage = stageMap.containsKey(currentStage) ? stageMap.get(currentStage) : '';

        while (String.isNotBlank(nextStage) && !excludedHandoverStagesList.isEmpty() && excludedHandoverStagesList.contains(nextStage)) {
            nextStage = determineNextStageForHandover(stageMap, nextStage, excludedHandoverStagesList);
        }

        return nextStage;
    }

    public void createTawtheeqEnrollmentCase(Handover__c handoverRecord){
        ServiceCatalogService servObj = ServiceCatalogService.getInstance();
        SalesOrderService objSalesOrderService = SalesOrderService.getInstance();
        TawtheeqEnrollmentSRHandler objTawtheeqEnrollmentSRHandler = TawtheeqEnrollmentSRHandler.getInstance();
        List<ServiceCatalog__c> scs = servObj.getServiceCatalog('Service Request', 'CRM Services', 'Tawtheeq Enrollment');
        objTawtheeqEnrollmentSRHandler.createCaseRecord(objSalesOrderService.getSalesOrdersById(handoverRecord.Sales_Order__c), scs[0], handoverRecord.Account__c, handoverRecord.Unit__c, handoverRecord, 'Service Request', '', 'System Generated', false); //salesOrderMap.get(hoRec.Sales_Order__c)
    }

    
}