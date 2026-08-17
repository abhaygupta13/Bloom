/*****************************************************************************************
Class       : PostSalePayDefTaskHandler
Author      : Sonali S
Description : 
test Class: PostSalePayDefTaskHandlerTest
Created Date: 
*****************************************************************************************/

public inherited sharing class PostSalePayDefTaskHandler {
    private static final String MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final string MTD_SERVICE_REQUEST_ASSIGNMENT_EMAIL_TEMPLATE_ID { get { return 'ServiceRequestAssignmentId'; } }
    private static final string MTD_SERVICE_REQUEST_REASSIGNMENT_EMAIL_TEMPLATE_ID { get { return 'ServiceRequestReAssignmentId'; } }
    private static final string MTD_SERVICE_REQUEST_CLOSURE_EMAIL_TEMPLATE_ID { get { return 'ServiceRequestClosureId'; } }
    private static final string MTD_COMPLAINT_ASSIGNMENT_EMAIL_TEMPLATE_ID {get { return 'ComplaintAssignmentId';}}
    private static final string MTD_COMPLAINT_REASSIGNMENT_EMAIL_TEMPLATE_ID {get { return 'ComplaintReAssignmentId';}}
    private static final string MTD_COMPLAINT_CLOSURE_EMAIL_TEMPLATE_ID {get { return 'ComplaintClosureId';}}
    
    private static PostSalePayDefTaskHandler instance;
    
    private PostSalePayDefTaskHandler() {
        
    }
    public static PostSalePayDefTaskHandler getInstance() { 
        if(instance == null) {
            instance = new PostSalePayDefTaskHandler();
        }
        return instance;
    }  
    public  void createNewAndCloseCurrentTask(List<Case> listOfCases){
        ServiceCatalogService servObj = ServiceCatalogService.getInstance();
        Map<Id,ServiceAction__c> caseCatalogVsNextAction  = servObj.getNextCaseServiceAction(listOfCases);
        Map<Id,ServiceAction__c> caseCatalogVsCurrentAction = servObj.getCurrentCaseServiceAction(listOfCases);
        processCasesAndHandleNextActions(listOfCases,caseCatalogVsNextAction,caseCatalogVsCurrentAction);
    }
    public  void openOldAndCloseCurrentTask(Id caseId,String commentBody,String reason){
        CaseService caseObjService = CaseService.getInstance();
        List<Case> caseList =   caseObjService.getCaseByIds(new Set<Id>{caseId});
        ServiceCatalogService servObj = ServiceCatalogService.getInstance();
        Map<Id,ServiceAction__c> caseCatalogVsNextAction  = servObj.getPreviousCaseServiceAction(caseList);
        processCasesAndHandlePrevActions(caseList,caseCatalogVsNextAction,commentBody,reason);
    }  
    public void processCasesAndHandlePrevActions(List<Case> listOfCases, Map<Id, ServiceAction__c> caseCatalogVsPrevAction,String commentBody,String reason) {
        
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
            if(hasCatalogActions && caseCatalogVsPrevAction.containsKey(caseObj.ServiceCatalog__c)){
                ServiceAction__c action = caseCatalogVsPrevAction.get(caseObj.ServiceCatalog__c);
                Task tsk = objActivityService.fetchTaskFromServiceAction(action,caseobj.id);
                tsk.Status = 'Open';
                tasksToUpdate.add(tsk);  
                
                caseToUpdate.Step__c = String.valueOf(Integer.valueOf(action.Order__c));
                caseToUpdate.Status = 'In Progress';  
                caseToUpdate.PendingWith__c = action.Department__c;
                caseToUpdate.OwnerId = tsk.OwnerId;
                casesToUpdate.add(caseToUpdate);

                caseIds.add(caseobj.id);
                
                CaseAssignmentHistory__c historyObj = new CaseAssignmentHistory__c();
                historyObj.Case__c = caseobj.id;
                historyObj.AssignedBy__c = caseVsOpenTasks.get(caseObj.Id)[0].OwnerId;
                historyObj.OwnerId = tsk.OwnerId;
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
              emailList.add(email);  
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
        
        ActivityService objActivityService = ActivityService.getInstance(); 
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
       
        Id noReplyOWDId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
        List<Case> casesToUpdate = new List<Case>();
        List<Messaging.SingleEmailMessage> emailList = new list<Messaging.SingleEmailMessage>(); 
        List<CaseAssignmentHistory__c> caseAssignHistoryToLog = new  List<CaseAssignmentHistory__c>();   
        
        Boolean hasNextCatalogActions = !caseCatalogVsNextAction.isEmpty();
        Boolean hasOpenActions = !caseCatalogVsCurrentAction.isEmpty();
        
        for (Case caseObj : listOfCases) {
            Case caseToUpdate = new Case(Id = caseObj.Id); 
            
            if (hasNextCatalogActions && caseCatalogVsNextAction.containsKey(caseObj.ServiceCatalog__c)) {
                ServiceAction__c nextAction = caseCatalogVsNextAction.get(caseObj.ServiceCatalog__c);   
                Task tsk = new Task();
                List<Task> tsks= objActivityService.fetchOpenTaskFromServiceAction(nextAction,caseobj.id); 
                //if there are no existing tasks for this service action, only then create a new task
                if(tsks.isEmpty()){
                    tsk = objActivityService.createTaskFromServiceAction(nextAction);
                    tsk.WhatId = caseObj.Id; 
                    tsk.Type = 'Other';
                    tsk.ActivityDate = nextAction.Due_in_days__c != null  ? System.now().date().addDays(Integer.valueOf(nextAction.Due_in_days__c)): System.now().date();
                    tsk.OwnerId = nextAction.AssignToOwner__c ? caseObj.OwnerId : nextAction.OwnerId;
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
                caseToUpdate.Status = 'In Progress';  
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
                    Messaging.SingleEmailMessage email = objEmailService.getSingleEmailMessageWithoutTargetObjectId(emailTemplateId, noReplyOWDId, caseobj.Id,toAddress, null, null);
                    emailList.add(email);
               
                
            } else {
                caseToUpdate.PendingWith__c = '';
                caseToUpdate.Status = 'Closed'; 
                ServiceAction__c currentAction = caseCatalogVsCurrentAction.get(caseObj.ServiceCatalog__c);
                List<Task> currentTaskList= objActivityService.fetchOpenTaskFromServiceAction(currentAction,caseobj.id);
                if(!currentTaskList.isEmpty()){
                    tasksToUpdate.addAll(currentTaskList);
                }
                AccountService accService = AccountService.getInstance();
                String customerEmail = accService.getRelatedContactEmail(caseObj.AccountId);
                List<String> toAddress = new List<String>{customerEmail};
                    Id emailTemplateId;
                if(caseobj.CaseType__c =='Service Request'){
                    emailTemplateId = objMetadataService.getAppSettingTextValue(MTD_SERVICE_REQUEST_CLOSURE_EMAIL_TEMPLATE_ID); 
                }
                else if(caseobj.CaseType__c =='Complaint') {
                    emailTemplateId = objMetadataService.getAppSettingTextValue(MTD_COMPLAINT_CLOSURE_EMAIL_TEMPLATE_ID);
                }
                Messaging.SingleEmailMessage email = objEmailService.getSingleEmailMessageWithoutTargetObjectId(emailTemplateId, noReplyOWDId, caseobj.Id, toAddress, null, null);
                emailList.add(email);
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
}