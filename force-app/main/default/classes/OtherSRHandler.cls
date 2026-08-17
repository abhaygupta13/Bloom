/*****************************************************************************************
Class       : OtherSRHandler
Author      : Swapnil Patil
Description : 
test Class  : OtherSRHandlerTest
Created Date: 2/20/2026
*****************************************************************************************/
public inherited sharing class OtherSRHandler {
    
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
     
    private static OtherSRHandler instance;
    private OtherSRHandler() {
        
    }
    
    public static OtherSRHandler getInstance() { 
        if(instance == null) {
            instance = new OtherSRHandler();
        }
        return instance;
    } 
    
    public  void createFirstTask(List<Case> listOfCases) {
        ServiceRequestTaskHandler obj = ServiceRequestTaskHandler.getInstance();
        obj.createNewAndCloseCurrentTask(listOfCases); 
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
        
         Case latestCase = CaseService.getInstance().getCaseById(caseRecord.Id);
        
        if (latestCase.ApprovalStatus__c == 'Pending' || latestCase.ApprovalStatus__c == 'Not Approved') {
            response.put('status', 'error');
            response.put('message', 'Please select the Approval Status (Approved or Rejected) on the Case before completing the task.');
            return response;
        }
        
        if (latestCase.ApprovalStatus__c == 'Rejected') {
            latestCase.Status = 'Closed';
            CaseService.getInstance().updateCases(new List<Case>{ latestCase });
            handleNextSteps(latestCase);
            response.put('status', 'success');
            response.put('message', 'Case has been rejected and the task is completed.');
            return response;
        }
        
        // If Approved
        latestCase.Status = 'Closed';
        CaseService.getInstance().updateCases(new List<Case>{ latestCase });
        
        response.put('status', 'success');
        response.put('message', 'Validation successful. Case approved and task completed.');
        handleNextSteps(latestCase);
        
        return response;
    }
    
    public  void handleNextSteps(Case caseRec){
        ServiceRequestTaskHandler obj = ServiceRequestTaskHandler.getInstance();
        obj.createNewAndCloseCurrentTask(new List<Case>{caseRec});
    } 
    
    public Case createCaseRecord(SalesOrder__c salesOrderObj, ServiceCatalog__c sc, String accountId, String unitId, String selectedType, String description, String origin, Boolean stopEmailsToCustomer) {
        
        Case newCase;
        try {
            newCase = new Case();
            newCase.AccountId = salesOrderObj != null ? salesOrderObj.Account__c : accountId;
            newCase.Project__c = salesOrderObj != null ? salesOrderObj.Project__c : null;
            newCase.RecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, sc.RecordTypeDevName__c);
            newCase.Unit__c = salesOrderObj != null ? salesOrderObj.Unit__c : unitId;
            newCase.Status = 'New';
            newCase.Origin = origin;
            newCase.ServiceCatalog__c = sc.Id;
            newCase.CaseType__c = selectedType;
            newCase.Description = description;
            newCase.SubType__c = sc.SubCategory__c;
            newCase.Sales_Order__c = salesOrderObj != null ? salesOrderObj.Id : null;
            newCase.SubType__c = sc.SubCategory__c;
            newCase.ApprovalStatus__c   = 'Not Approved';
            newCase.Subject = 'Broker Service Request';
            newCase.Type = 'Broker Service Request';
            if (getBloomQueue() != null) {
                newCase.OwnerId = getBloomQueue().Id;
            }
            newCase.StopEmailsToCustomer__c = stopEmailsToCustomer;
            List<Case> inserted = CaseService.getInstance().insertCaseWithTrigger(new List<Case>{ newCase });
            
            Case created = CaseService.getInstance().getCaseById(inserted[0].Id);
            
            Case latestCase = CaseService.getInstance().getCaseById(created.Id);
            latestCase.ApprovalStatus__c = 'Pending';
            CaseService.getInstance().updateCase(latestCase);
        } catch (Exception e) {
            throw e;
        }
        return newCase; 
    }
}