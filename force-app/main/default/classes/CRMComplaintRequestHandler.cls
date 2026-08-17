/*****************************************************************************************
Class       : CRMComplaintRequestHandler
Author      :  Samiksha Mahajan
Description : 
test Class  : CRMComplaintRequestHandlerTest
Created Date: 18-June-2026
*****************************************************************************************/
public class CRMComplaintRequestHandler {
    private static CRMComplaintRequestHandler instance;
    private static final string COMPLAINT_REQUEST_RT { get { return 'ComplaintRequest'; } }
    private static final string MTD_COMPLAINT_CLOSURE_EMAIL_TEMPLATE_ID {get { return 'ComplaintClosureId';}}
    private static final String MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
     private static final string MTD_COMPLAINT_ASSIGNMENT_EMAIL_TEMPLATE_ID {get { return 'ComplaintAssignmentId';}}
    
        public static CRMComplaintRequestHandler getInstance() { 
        if(instance == null) {
            instance = new CRMComplaintRequestHandler();
        }
        return instance;
    }
    
        public  void createFirstTask(List<Case> listOfCases) {
        ServiceRequestTaskHandler obj = ServiceRequestTaskHandler.getInstance();
        obj.createNewAndCloseCurrentTask(listOfCases);
    }
    
     public Case createCaseRecord(SalesOrder__c salesOrderObj, ServiceCatalog__c sc, Id accountId, Id unitId, String selectedType, String description, String origin, Boolean stopEmailsToCustomer) {
        AccountService accService = AccountService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        
        Case newCase = new Case();
        newCase.AccountId = salesOrderObj != null ? salesOrderObj.Account__c : accountId;
        newCase.Project__c = salesOrderObj != null ? salesOrderObj.Project__c : null;
        newCase.RecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, sc.RecordTypeDevName__c);
        newCase.Unit__c = salesOrderObj != null ? salesOrderObj.Unit__c : unitId;
        newCase.Origin = origin;
        newCase.ServiceCatalog__c = sc.Id;
        newCase.CaseType__c = selectedType;
        newCase.Description = description;
        newCase.SubType__c = sc.SubCategory__c;    
        newCase.Status = 'New';
        
        Map<String, String> subTypeToSubject = new Map<String, String>{
            'Sales' => 'Complaint Request - Sales'
                
                };
                    
                    String subjectPrefix = subTypeToSubject.containsKey(newCase.SubType__c) ? subTypeToSubject.get(newCase.SubType__c)  : 'Complaint Request';
        
        if (salesOrderObj != null ) {
            newCase.Subject = subjectPrefix + ' - ' + salesOrderObj.Account__r.Name +'-'+ salesOrderObj.Unit__r.Name;
            newCase.ContactId = accService.getRelatedContact(salesOrderObj.Account__r.Id);
            newCase.CustomerName__c = accService.getRelatedContactName(salesOrderObj.Account__r.Id);
            newCase.Sales_Order__c = salesOrderObj.Id;
            newCase.RequesterContactNumber__c = salesOrderObj.Account__r.isPersonAccount ? salesOrderObj.Account__r.PersonMobilePhone : null;
        }       
        else if(salesOrderObj == null){
            Datetime todaysDateTime = DateTime.newInstance(System.today().year(), System.today().month(), System.today().day());
            String formattedinstallmentDate = todaysDateTime.format('dd-MM-yyyy');
            newCase.Subject = subjectPrefix + ' - ' + formattedinstallmentDate;
        }
        newCase.StopEmailsToCustomer__c = stopEmailsToCustomer;
        newCase = CaseService.getInstance().insertCase(newCase);
        return newCase; 
    }
    
     public String validateEligibility(SalesOrder__c salesOrderObj, Case caseObj){
        String message;
        return message;
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
               
        if(response.get('status') == 'success'){
       //     caseRecord.Step__c = '2';
             ActivityService activityService = ActivityService.getInstance();
       List<Task> prevTask = activityService.fetchOpenTaskForCase(caseRecord);
       activityService.closeTasks(prevTask);
             ServiceRequestTaskHandler.getInstance().createNewAndCloseCurrentTask(new List<Case>{caseRecord}); 
            AssignmentRuleHandler.crmComplaintCaseAssignment(new List<Id>{caseRecord.Id});
        }
        
        if (response.get('status') == 'error') {
            return response;
        }
        return response;
    }
    
 public void sendComplaintClosureEmails(List<Case> caseList) {

    MetadataService objMetadataService = MetadataService.getInstance();
    EmailService objEmailService = EmailService.getInstance();
    AccountService accService = AccountService.getInstance();

    Id noReplyOWDId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
    Id emailTemplateId = objMetadataService.getAppSettingTextValue(MTD_COMPLAINT_CLOSURE_EMAIL_TEMPLATE_ID);

    List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();

    for(Case caseObj : caseList){
        String customerEmail = accService.getRelatedContactEmail(caseObj.AccountId);

        List<String> toAddress = new List<String>{ customerEmail };

        Messaging.SingleEmailMessage email = objEmailService.getSingleEmailMessageWithoutTargetObjectId(emailTemplateId,noReplyOWDId,caseObj.Id,toAddress,null,null);

        if(email != null){
            emailList.add(email);
        }
    }

    if(!emailList.isEmpty()){
        objEmailService.sendEmail(emailList);
    }
}
    public void sendComplaintAssignmentEmails(List<Task> taskList) {

    if(taskList == null || taskList.isEmpty()){
        return;
    }

    MetadataService objMetadataService = MetadataService.getInstance();
    EmailService objEmailService = EmailService.getInstance();

    Id noReplyOWDId =
        objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);

    Id emailTemplateId =
        objMetadataService.getAppSettingTextValue(MTD_COMPLAINT_ASSIGNMENT_EMAIL_TEMPLATE_ID);

    List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();

    for(Task tsk : taskList){

        if(tsk.WhatId == null){
            continue;
        }

        List<String> toAddress = objEmailService.getOwnerEmails(tsk.OwnerId);

        if(toAddress == null || toAddress.isEmpty()){
            continue;
        }

        Messaging.SingleEmailMessage email =
            objEmailService.getSingleEmailMessageWithoutTargetObjectId(
                emailTemplateId,
                noReplyOWDId,
                tsk.WhatId,
                toAddress,
                null,
                null
            );

        if(email != null){
            emailList.add(email);
        }
    }

    if(!emailList.isEmpty()){
        objEmailService.sendEmail(emailList);
    }
}
}