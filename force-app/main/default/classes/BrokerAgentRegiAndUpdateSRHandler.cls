/*****************************************************************************************
Class       : BrokerAgentRegiAndUpdateSRHandler
Author      : Swapnil Patil
Description : Handles Broker Registration Service Request lifecycle
test Class  : BrokerAgentRegiAndUpdateSRHandlerTest
Created Date: 3/25/2026
*****************************************************************************************/
public inherited sharing class BrokerAgentRegiAndUpdateSRHandler {
    
    private static final string MTD_SERVICE_REQUEST_CLOSURE_EMAIL_TEMPLATE_ID { get { return 'ServiceRequestClosureId'; } }
    private static final string MTD_TeamApproves_EMAIL_TEMPLATE_ID { get { return 'BAPPBLTeamApprovesSR'; } }
    private static final String MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    
    private static Group bloomQueue;
    
    private static Group getBloomQueue() {
        if (bloomQueue == null) {
            try {
                bloomQueue = QueueService.getInstance()
                    .getGroupByDeveloperNameAndType(
                        'Bloom_Broker_Management_BBM',
                        'Queue'
                    );
            } catch (Exception e) {
                bloomQueue = null;
            }
        }
        return bloomQueue;
    }
    
    private static BrokerAgentRegiAndUpdateSRHandler instance;
    private BrokerAgentRegiAndUpdateSRHandler() {}
    
    public static BrokerAgentRegiAndUpdateSRHandler getInstance() { 
        if(instance == null) {
            instance = new BrokerAgentRegiAndUpdateSRHandler();
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
        // Fetch latest Case to avoid stale data
        Case latestCase = CaseService.getInstance().getCaseById(caseRecord.Id);
        
        // --- Determine if this is the Final Approval Step ---
        Boolean isFinalStep = false;
        if (latestCase.SubType__c == 'Broker New Agent Registration') {
            if (latestCase.SendToBL__c == true) {
                isFinalStep = (latestCase.Step__c == 'Final');
            } else {
                isFinalStep = (latestCase.Step__c == '1');
            }
        } else {
            // Broker Agent Details Update is always a single-step case
            isFinalStep = true;
        }
        
        // --- Manual Approval Status Check ---
        if (isFinalStep && (latestCase.ApprovalStatus__c == 'Pending' || latestCase.ApprovalStatus__c == 'Not Approved')) {
            response.put('status', 'error');
            response.put('message', 'Please select the Approval Status (Approved or Rejected) on the Case before completing the task.');
            return response;
        }
        
        if (latestCase.ApprovalStatus__c == 'Rejected') {
            latestCase.Status = 'Closed';
            List<Case> casesToUpdate = new List<Case>{ latestCase };
            CaseService.getInstance().updateCases(casesToUpdate);
            handleNextSteps(latestCase);
            response.put('status', 'success');
            response.put('message', 'Case has been rejected and the task is completed.');
            return response;
        }
        
        caseRecord = latestCase;
         
        // -------------------------------------------------------------
        // Sub-Type Specific Validations
        // -------------------------------------------------------------
        
        // --- Validation for "Broker New Agent Registration" ---
        List<String> missingFields = new List<String>();
        if (caseRecord.SubType__c == 'Broker New Agent Registration' && caseRecord.Origin != 'Portal') {
            if (String.isBlank(caseRecord.First_Name__c)) missingFields.add('First Name');
            if (String.isBlank(caseRecord.Last_Name__c)) missingFields.add('Last Name');
            if (String.isBlank(caseRecord.Email_Address__c)) missingFields.add('Email Address');
            if (String.isBlank(caseRecord.Title__c)) missingFields.add('Title');
            if (String.isBlank(caseRecord.Country__c)) missingFields.add('Country');
            if (String.isBlank(caseRecord.TypeofEstablishment__c)) {
                missingFields.add('Type of Establishment');
            } else {
                if (caseRecord.TypeofEstablishment__c == 'Domestic') {
                    if (String.isBlank(caseRecord.NationalID__c)) missingFields.add('Emirates ID');
                    if (caseRecord.NationalIDExpiryDate__c == null) missingFields.add('National ID Expiry Date');
                } else if (caseRecord.TypeofEstablishment__c == 'International') {
                    if (String.isBlank(caseRecord.PassportNumber__c)) missingFields.add('Passport Number');
                    if (caseRecord.PassportExpiryDate__c == null) missingFields.add('Passport Expiry Date');
                }
            }
            // Add this check here:
            if (caseRecord.BrokerContactRole__c != null && caseRecord.BrokerContactRole__c.contains('Agent')) {
                if (String.isBlank(caseRecord.BRN_RERA_Number__c)) missingFields.add('BRN/RERA Number');
                if (caseRecord.BRN_RERA_Expiry_Date__c == null) missingFields.add('BRN/RERA Expiry Date');
            }
        }
        
        else if (caseRecord.SubType__c == 'Broker Agent Details Update' && caseRecord.Origin != 'Portal') {
            if (caseRecord.ContactId == null) missingFields.add('Contact');
            if (String.isBlank(caseRecord.TypeofEstablishment__c)) {
                missingFields.add('Type of Establishment');
            } else {
                if (caseRecord.TypeofEstablishment__c == 'Domestic') {
                    if (caseRecord.NationalIDExpiryDate__c == null) missingFields.add('National ID Expiry Date');
                } else if (caseRecord.TypeofEstablishment__c == 'International') {
                    if (caseRecord.PassportExpiryDate__c == null) missingFields.add('Passport Expiry Date');
                }
            }
        }
        
        if (!missingFields.isEmpty()) {
            response.put('status', 'error');
            response.put('message', 'Please populate the following required fields: ' + String.join(missingFields, ', ') + '.');
            return response;
        }
        // --- Document Upload Check ---
        List<Document__c> caseDocs = DocumentService.getInstance().getDocumentsByCaseIds(new Set<Id>{caseRecord.Id});
        Boolean docsMissing = caseDocs.isEmpty();
        for (Document__c doc : caseDocs) {
            if (doc.ContentDocumentId__c == null) {
                docsMissing = true;
                break;
            }
        }
        if (docsMissing) {
            response.put('status', 'error');
            response.put('message', 'Please upload all the required documents before proceeding.');
            return response;
        }
        if (caseRecord.SubType__c == 'Broker New Agent Registration') {
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
            
            if (caseRecord.SendToBL__c ) {
                response.put('status', 'success');
                response.put('message', 'Validation successful.'); 
                List<Case> listOfCase = new List<Case>();
                if(caseRecord.Step__c == '2'){
                    caseRecord.SubStatus__c = 'Approved by BL';
                    caseRecord.FinalApproved__c = False;
                    if (getBloomQueue() != null) {
                        caseRecord.OwnerId = getBloomQueue().Id;
                    }
                    
                    if (caseRecord.BBMId__c != null) {
                        
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
        }
         else if (caseRecord.SubType__c == 'Broker Agent Details Update') {
            // Complete task and process next actions
            handleNextSteps(caseRecord);
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
            BrokerAgentRegiAndUpdateSRHandler NShandler = BrokerAgentRegiAndUpdateSRHandler.getInstance();
            
            for (Case Cs : listOfCases) {
                NShandler.handleNextSteps(Cs);
            }
        }
    }
    
    public class Requests {
        @InvocableVariable public String recordId;
    }
    
    public Case createCaseRecord(SalesOrder__c salesOrderObj, ServiceCatalog__c sc, String accountId, String unitId, String selectedType, String description, String origin, String brokerContactRole, String finalBrokerContactRole, String typeOfEstablishment, Boolean stopEmailsToCustomer) {
        
        Case newCase;
        try {
            If (newCase == null){
                newCase = new Case();
                newCase.AccountId = salesOrderObj != null ? salesOrderObj.Account__c : accountId;
                newCase.Project__c = salesOrderObj != null ? salesOrderObj.Project__c : null;
                newCase.RecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, sc.RecordTypeDevName__c);
                newCase.Unit__c = salesOrderObj != null ? salesOrderObj.Unit__c : unitId;
                newCase.Status = 'New';
                newCase.Draft__c = true;
                newCase.Origin = origin;
                newCase.ApprovalStatus__c = 'Not Approved';
                newCase.ServiceCatalog__c = sc.Id;
                newCase.CaseType__c = selectedType;
                newCase.Description = description;
                newCase.Type = sc.Category__c;
                newCase.SubType__c = sc.SubCategory__c;
                if(sc.SubCategory__c == 'Broker New Agent Registration'){
                    newCase.Subject = 'Broker New Agent Registration';
                }else if(sc.SubCategory__c == 'Broker Agent Details Update'){
                    newCase.Subject = 'Broker Agent Details Update';
                }
                if (getBloomQueue() != null) {
                    newCase.OwnerId = getBloomQueue().Id;
                }
                
                newCase.Sales_Order__c = salesOrderObj != null ? salesOrderObj.Id : null;
                if(sc.SubCategory__c == 'Broker New Agent Registration'){
                    newCase.BrokerContactRole__c = brokerContactRole;
                }else if(sc.SubCategory__c == 'Broker Agent Details Update'){
                    newCase.BrokerContactRole__c = finalBrokerContactRole;
                }
                newCase.TypeofEstablishment__c = typeOfEstablishment;
                newCase.StopEmailsToCustomer__c = stopEmailsToCustomer;
                
                List<Case> inserted = CaseService.getInstance().insertCaseWithTrigger(new List<Case>{ newCase });
                
                Case caseToUpdate = new Case(
                    Id = inserted[0].Id,
                    ApprovalStatus__c = 'Pending',
                    Draft__c = false
                );
                
                CaseService.getInstance().updateCase(caseToUpdate);
                
                newCase.Id = inserted[0].Id;
                
                /* CaseService caseServiceObj = CaseService.getInstance();
newCase = caseServiceObj.insertCase(newCase);

Case latestCase = CaseService.getInstance().getCaseById(newCase.Id);

if(latestCase.Status == 'New' && latestCase.ServiceCatalog__c != null){

createFirstTask(new List<Case>{ latestCase });
latestCase = CaseService.getInstance().getCaseById(newCase.Id);

latestCase.ApprovalStatus__c = 'Pending';
latestCase.Draft__c = false;

CaseService.getInstance().updateCase(latestCase); */
            }
            
        } catch (Exception e) {
            throw e;
        }
        return newCase; 
    }
    
}