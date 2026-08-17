/*****************************************************************************************
Class       : BrokerAgentDetailsUpdateSRHandler
Author      : Rushikesh Jadhav
Description : Handles Broker Agent Service Request lifecycle
Created Date: 3/25/2026
*****************************************************************************************/
public inherited sharing class BrokerAgentDetailsUpdateSRHandler {
    
    private static BrokerAgentDetailsUpdateSRHandler instance;
    private BrokerAgentDetailsUpdateSRHandler() {
        
    }
    
    public static BrokerAgentDetailsUpdateSRHandler getInstance() { 
        if(instance == null) {
            instance = new BrokerAgentDetailsUpdateSRHandler();
        }
        return instance;
    }

    public static void handle(List<Id> caseIds){

        if(caseIds == null || caseIds.isEmpty()){
            return;
        }
    
        List<Case> caseList = CaseService.getInstance()
            .getCaseByIds(new Set<Id>(caseIds));
    
        if(caseList.isEmpty()){
            return;
        }
    
        Id brokerAgentDetailsUpdateRTId = 
            Utility.getRecordTypeIdByDevName(
                Case.SObjectType, 
                'BrokerAgentRegistrationAndUpdate'
            );
    
        List<Case> filteredCases = new List<Case>();
    
        for(Case c : caseList){
            if(c.RecordTypeId == brokerAgentDetailsUpdateRTId
               && c.Status  == 'New'){
                filteredCases.add(c);
            }
        }
    	System.debug('filteredCases >> '+filteredCases);
        if(!filteredCases.isEmpty()){
            ServiceRequestTaskHandler.getInstance()
                .createNewAndCloseCurrentTask(filteredCases);
        }
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
        if (latestCase.ApprovalStatus__c == 'Pending') {
            latestCase.ApprovalStatus__c = 'Approved';
        }
    
        List<Case> casesToUpdate = new List<Case>{ latestCase };
        CaseService.getInstance().updateCases(casesToUpdate);
    
        // Complete task and process next actions
        handleNextSteps(latestCase);
    
        response.put('status', 'success');
        response.put('message', 'Validation successful. Case approved and task completed.');
        //handleNextSteps(caseRecord);
        return response;
        
    } 

    public  void handleNextSteps(Case caseRec){
        ServiceRequestTaskHandler obj = ServiceRequestTaskHandler.getInstance();
        obj.createNewAndCloseCurrentTask(new List<Case>{caseRec});
    }
    public  void createFirstTask(List<Case> listOfCases) {
        ServiceRequestTaskHandler obj = ServiceRequestTaskHandler.getInstance();
        obj.createNewAndCloseCurrentTask(listOfCases); 
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
            newCase.Subject = 'Broker Agent Details Update';
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