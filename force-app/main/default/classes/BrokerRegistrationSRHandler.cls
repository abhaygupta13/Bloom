/*****************************************************************************************
Class       : BrokerRegistrationSRHandler
Author      : Swapnil Patil
Description : Handles Broker Registration Service Request lifecycle
test Class  : BrokerRegistrationSRHandlerTest
Created Date: 3/25/2026
*****************************************************************************************/
public inherited sharing class BrokerRegistrationSRHandler {
    
    private static final string MTD_SERVICE_REQUEST_CLOSURE_EMAIL_TEMPLATE_ID { get { return 'ServiceRequestClosureId'; } }
    private static final string MTD_TeamApproves_EMAIL_TEMPLATE_ID { get { return 'BLTeamApprovesSR'; } }
    private static final String MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    
    private static BrokerRegistrationSRHandler instance;
    private BrokerRegistrationSRHandler() {}
    
    public static BrokerRegistrationSRHandler getInstance() { 
        if(instance == null) {
            instance = new BrokerRegistrationSRHandler();
        }
        return instance;
    } 
    
    public  void createFirstTask(List<Case> cases) {
        if (cases == null || cases.isEmpty()) return;
        ServiceRequestTaskHandler.getInstance().createNewAndCloseCurrentTask(cases);
    }
    
    public Map<String, Object> validateCaseForNextReview(Case caseRecord) {
        Map<String, Object> response = new Map<String, Object>();
        
        if (caseRecord == null) {
            response.put('status', 'error');
            response.put('message', 'Invalid Case record.');
            return response;
        }
        
        if (caseRecord.Status == 'Closed') {
            response.put('status', 'error');
            response.put('message', 'Cannot proceed. Case is already Closed.');
            return response;
        }
        
        if (caseRecord.ServiceCatalog__c == null) {
            response.put('status', 'error');
            response.put('message', 'Service Catalog is missing.');
            return response;
        }
        
        if (caseRecord.Step__c == null) {
            response.put('status', 'error');
            response.put('message', 'Step value is missing.');
            return response;
        }
        
        if (!caseRecord.SendToBL__c ) {
            response.put('status', 'success');
            response.put('message', 'Validation successful.'); 
            List<Case> listOfCase = new List<Case>();
            if(caseRecord.Step__c == '1'){
                caseRecord.ApprovalStatus__c = 'Approved';
                caseRecord.FinalApprovalStage__c  = 'Second Approval';
                caseRecord.Step__c  = 'Final';
            }
            ListofCase.add(caseRecord);
            caseService.getInstance().updateUnits(ListofCase);
            directcompleteBBM(listOfCase);
            return response;
        }
        
        Group bloomQueue;
        try {
            bloomQueue = QueueService.getInstance().getGroupByDeveloperNameAndType('Bloom_Broker_Management_BBM','Queue');
        } catch (Exception e) {
            bloomQueue = null;
        }
        System.debug('outsideifforsendtobl');
        if (caseRecord.SendToBL__c ) {
            System.debug('Insideifforsendtobl');
            response.put('status', 'success');
            response.put('message', 'Validation successful.'); 
            List<Case> listOfCase = new List<Case>();
            if(caseRecord.Step__c == '2'){
                caseRecord.SubStatus__c = 'Approved by BL';
                caseRecord.FinalApproved__c = False;
                caseRecord.OwnerId = bloomQueue.Id;
             
                if (caseRecord.BBMId__c != null && !caseRecord.StopEmailsToCustomer__c) {
                    
                    EmailService objEmailService = EmailService.getInstance();
                    MetadataService objMetadataService = MetadataService.getInstance();
                    
                    Id emailTemplateId = objMetadataService.getAppSettingTextValue(MTD_TeamApproves_EMAIL_TEMPLATE_ID);
                    
                    Id noReplyOWDId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
                    
                    List<String> toAddress = objEmailService.getOwnerEmails(caseRecord.BBMId__c);
                    
                    Messaging.SingleEmailMessage email = objEmailService.getSingleEmailMessageWithoutTargetObjectId(
                        emailTemplateId, noReplyOWDId, caseRecord.Id, toAddress, null, null );
                    
                    if (email != null) {
                        objEmailService.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
                    }
                }
                
            }
            else if(caseRecord.Step__c == 'Final'){
                caseRecord.ApprovalStatus__c = 'Approved';
            }
            ListofCase.add(caseRecord);
            caseService.getInstance().updateUnits(ListofCase);
            updatetask(listOfCase);
            return response;
        }
        
        response.put('status', 'success');
        response.put('message', 'Validation successful. Processing next step.');        
        
        return response;
    } 
    
    public void handleNextSteps(Case caseRec){
            ServiceRequestTaskHandler obj = ServiceRequestTaskHandler.getInstance();
            obj.createNewAndCloseCurrentTask(new List<Case>{caseRec});
    }
    
    Public static void directcompleteBBM(List<Case> listOfCases){
        ServiceCatalogService servObj = ServiceCatalogService.getInstance();
        Map<Id,ServiceAction__c> caseCatalogVsNextAction  = new Map<Id,ServiceAction__c>();
        Map<Id,ServiceAction__c> caseCatalogVsCurrentAction = servObj.getCurrentCaseServiceAction(listOfCases);
        
        ServiceRequestTaskHandler obj = ServiceRequestTaskHandler.getInstance();
        obj.processCasesAndHandleNextActions(listOfCases, caseCatalogVsNextAction, caseCatalogVsCurrentAction);
    }
    
    Public static void updatetask(List<Case> listOfCases){
        ServiceCatalogService servObj = ServiceCatalogService.getInstance();
        Map<Id,ServiceAction__c> caseCatalogVsNextAction  = servObj.getNextCaseServiceAction(listOfCases);
        Map<Id,ServiceAction__c> caseCatalogVsCurrentAction = servObj.getCurrentCaseServiceAction(listOfCases);
        List<Task> tasksToUpdate = new List<Task>();
        ActivityService objActivityService = ActivityService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        Id noReplyOWDId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
        EmailService objEmailService = EmailService.getInstance();
        List<String> toAddress =  new List<String>();
        List<Messaging.SingleEmailMessage> emailList = new list<Messaging.SingleEmailMessage>(); 
        Messaging.SingleEmailMessage email;
        
        Boolean hasNextCatalogActions = !caseCatalogVsNextAction.isEmpty();
        Boolean hasOpenActions = !caseCatalogVsCurrentAction.isEmpty();
        
        System.debug('caseCatalogVsNextAction----'+caseCatalogVsNextAction);
        System.debug('caseCatalogVsCurrentAction----'+caseCatalogVsCurrentAction);
        
        for (Case caseObj : listOfCases) {
            if(hasOpenActions && caseCatalogVsCurrentAction.containsKey(caseObj.ServiceCatalog__c)) {
                ServiceAction__c currentAction = caseCatalogVsCurrentAction.get(caseObj.ServiceCatalog__c);
                Task tskToUpdate = new Task();  
                List<Task> currentTaskList= objActivityService.fetchOpenTaskFromServiceAction(currentAction,caseobj.id);
                if(!currentTaskList.isEmpty()){
                    tasksToUpdate.addAll(currentTaskList);
                    
                    for (Task tsk : currentTaskList) {
                        toAddress = objEmailService.getOwnerEmails(tsk.OwnerId);
                    }
                    
                }
            }
            Id emailTemplateId = objMetadataService.getAppSettingTextValue(MTD_SERVICE_REQUEST_CLOSURE_EMAIL_TEMPLATE_ID);
            
            email = objEmailService.getSingleEmailMessageWithoutTargetObjectId(emailTemplateId, noReplyOWDId, caseobj.Id, toAddress, null, null);
            if(email != Null) emailList.add(email);
        }
        
        if(!tasksToUpdate.isEmpty()) objActivityService.closeTasks(tasksToUpdate);
        if(!emailList.isEmpty())objEmailService.sendEmail(emailList);
        if (!listOfCases.isEmpty()) {
            BrokerRegistrationSRHandler NShandler = BrokerRegistrationSRHandler.getInstance();
            
            for (Case Cs : listOfCases) {
                NShandler.handleNextSteps(Cs);
            }
        }
    }
    
    public class Requests {
        @InvocableVariable public String recordId;
    }
    
    public Case createCaseRecord(SalesOrder__c salesOrderObj, ServiceCatalog__c sc, String accountId, String unitId, String selectedType, String description, String origin) {
        
        Case newCase;
        try {
            newCase = new Case();
            newCase.AccountId = salesOrderObj != null ? salesOrderObj.Account__c : accountId;
            newCase.Project__c = salesOrderObj != null ? salesOrderObj.Project__c : null;
            newCase.RecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, sc.RecordTypeDevName__c);
            newCase.Unit__c = salesOrderObj != null ? salesOrderObj.Unit__c : unitId;
            newCase.Status = 'New';
            newCase.Origin = origin;
            newCase.ApprovalStatus__c = 'Not Approved';
            newCase.ServiceCatalog__c = sc.Id;
            newCase.CaseType__c = selectedType;
            newCase.Description = description;
            newCase.SubType__c = sc.SubCategory__c;
            newCase.Type = sc.Category__c;
            newCase.Subject = 'Broker Registration';
            newCase.Sales_Order__c = salesOrderObj != null ? salesOrderObj.Id : null;
            
            CaseService caseServiceObj = CaseService.getInstance();
            newCase = caseServiceObj.insertCase(newCase);

            if(newCase != null){
            
                Case latestCase = CaseService.getInstance()
                    .getCaseById(newCase.Id);
            
                if(latestCase.Status == 'New'
                   && latestCase.ServiceCatalog__c != null){
            
                    createFirstTask(new List<Case>{ latestCase });
                    latestCase = CaseService.getInstance()
                        .getCaseById(newCase.Id);
            
                    latestCase.ApprovalStatus__c = 'Pending';
            
                    CaseService.getInstance()
                        .updateCase(latestCase);
                }
            }
        } catch (Exception e) {
            throw e;
        }
        return newCase; 
    }
}