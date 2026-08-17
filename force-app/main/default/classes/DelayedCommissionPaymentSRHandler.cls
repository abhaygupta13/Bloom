/*****************************************************************************************
Class       : DelayedCommissionPaymentSRHandler
Author      : Swapnil Patil
Description : 
test Class  : DelayedCommissionPaymentSRHandlerTest
Created Date: 2/19/2026
*****************************************************************************************/
public inherited sharing class DelayedCommissionPaymentSRHandler {
    
    private static DelayedCommissionPaymentSRHandler instance;
    private DelayedCommissionPaymentSRHandler() {
        
    }
    
    public static DelayedCommissionPaymentSRHandler getInstance() { 
        if(instance == null) {
            instance = new DelayedCommissionPaymentSRHandler();
        }
        return instance;
    } 
    
    public  void createFirstTask(List<Case> listOfCases) {
        system.debug('createFirstTask>>>> '+listOfCases);
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
        
        // Fetch latest Case to avoid stale data
        Case latestCase = CaseService.getInstance().getCaseById(caseRecord.Id);
    
        // Update Approval Status on final step
        if (latestCase.ApprovalStatus__c == 'Pending' || latestCase.ApprovalStatus__c == 'Not Approved') {
            latestCase.ApprovalStatus__c = 'Approved';
            latestCase.Status = 'Closed';
        }
    
        List<Case> casesToUpdate = new List<Case>{ latestCase };
        CaseService.getInstance().updateCases(casesToUpdate);
        
        response.put('status', 'success');
        response.put('message', 'Validation successful. Processing next step.');        
        handleNextSteps(caseRecord);
        
        return response;
    } 
    
    public  void handleNextSteps(Case caseRec){
        ServiceRequestTaskHandler obj = ServiceRequestTaskHandler.getInstance();
        obj.createNewAndCloseCurrentTask(new List<Case>{caseRec});
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
            newCase.ApprovalStatus__c = 'Not Approved';
            newCase.Origin = origin;
            newCase.ServiceCatalog__c = sc.Id;
            newCase.CaseType__c = selectedType;
            newCase.Description = description;
            newCase.SubType__c = sc.SubCategory__c;
            newCase.Subject = 'Delayed Commission Payment';
            newCase.Type = 'Delayed Commission Payment';
            newCase.Sales_Order__c = salesOrderObj != null ? salesOrderObj.Id : null;
            
            CaseService caseServiceObj = CaseService.getInstance();
            newCase = caseServiceObj.insertCase(newCase);

            if(newCase != null){
            
                Case latestCase = CaseService.getInstance()
                    .getCaseById(newCase.Id);
            
                if(latestCase.Status == 'New'
                   && latestCase.ServiceCatalog__c != null){
            
                    createFirstTask(new List<Case>{ latestCase });
                       // Refresh case after task creation
                    latestCase = CaseService.getInstance()
                        .getCaseById(newCase.Id);
            
                    // Update approval status
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