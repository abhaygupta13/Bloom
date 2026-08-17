/*****************************************************************************************
Class       : BrokerAgencyDetailsUpdateSRHandler
Author      : Rushikesh Jadhav
Description : Handles Broker Agency Service Request lifecycle
Created Date: 3/25/2026
*****************************************************************************************/
public inherited sharing class BrokerAgencyDetailsUpdateSRHandler {
    
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
    
    private static BrokerAgencyDetailsUpdateSRHandler instance;
    private BrokerAgencyDetailsUpdateSRHandler() {
        
    }
    
    public static BrokerAgencyDetailsUpdateSRHandler getInstance() { 
        if(instance == null) {
            instance = new BrokerAgencyDetailsUpdateSRHandler();
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
                'BrokerAgencyDetailsUpdate'
            );
        
        List<Case> filteredCases = new List<Case>();
        
        for(Case c : caseList){
            if(c.RecordTypeId == brokerAgentDetailsUpdateRTId
               && c.Status == 'New'){
                   filteredCases.add(c);
               }
        }
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
        // -------------------------------------------------------------
        // Sub-Type Specific Validations
        // -------------------------------------------------------------
        if (String.isBlank(latestCase.SubType__c)) {
            response.put('status', 'error');
            response.put('message', 'Please select an appropriate Sub-Type before proceeding.');
            return response;
        }
        // --- Manual Approval Status Check ---
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
        
        List<String> missingFields = new List<String>();
        if (latestCase.Origin != 'Portal') {
            if (latestCase.SubType__c == 'Trade License Expiry Update') {
                if (latestCase.TradeLicenseExpiryDate__c == null) missingFields.add('Trade License Expiry Date');
            } 
            else if (latestCase.SubType__c == 'Commercial License Expiry Update') {
                if (latestCase.CommercialLicenseExpiryDate__c == null) missingFields.add('Commercial License Expiry Date');
            } 
            else if (latestCase.SubType__c == 'VAT Details Update') {
                if (latestCase.IsVATRegistered__c == null) {
                    missingFields.add('Is VAT Registered');
                } else {
                    if (latestCase.IsVATRegistered__c == true && String.isBlank(latestCase.TaxRegistrationNumber__c)) {
                        missingFields.add('Tax Registration Number');
                    } else if (latestCase.IsVATRegistered__c == false && latestCase.VATUndertakingIssue_Date__c == null) {
                        missingFields.add('VAT Undertaking Issue Date');
                    }
                }
            } 
            else if (latestCase.SubType__c == 'Bank Details Update') {
                if (String.isBlank(latestCase.BankName__c)) missingFields.add('Bank Name');
                if (String.isBlank(latestCase.AccountNumber__c)) missingFields.add('Account Number');
                if (String.isBlank(latestCase.BankAddress__c)) missingFields.add('Bank Address');
                if (String.isBlank(latestCase.IBANNumber__c)) missingFields.add('IBAN Number');
                if (String.isBlank(latestCase.SwiftCode__c)) missingFields.add('Swift Code');
            } 
            // Commented out Address validation as it's not strictly mandatory but ready if needed:
            
            else if (latestCase.SubType__c == 'Agency Address Update') {
                if (String.isBlank(latestCase.PhoneNumber__c)) missingFields.add('Phone Number');
                if (String.isBlank(latestCase.Address1__c)) missingFields.add('Address Line 1');
            }
            
        }
        if (!missingFields.isEmpty()) {
            response.put('status', 'error');
            response.put('message', 'Please populate the following required fields: ' + String.join(missingFields, ', ') + '.');
            return response;
        }
         // --- Document Upload Validations ---
        if (latestCase.SubType__c == 'Bank Details Update') {
            List<Document__c> caseDocs = DocumentService.getInstance().getDocumentsByCaseIds(new Set<Id>{latestCase.Id});
            Boolean hasBankLetter = false;
            for (Document__c doc : caseDocs) {
                if (doc.Document_Name__c == 'Bank confirmation letter' && doc.ContentDocumentId__c != null) {
                    hasBankLetter = true;
                    break;
                }
            }
            if (!hasBankLetter) {
                response.put('status', 'error');
                response.put('message', 'Please upload the Bank confirmation letter document before proceeding.');
                return response;
            }
        } 
        else if (latestCase.SubType__c == 'Legal Documents Update') {
            List<Document__c> caseDocs = DocumentService.getInstance().getDocumentsByCaseIds(new Set<Id>{latestCase.Id});
            Boolean hasAtLeastOneDoc = false;
            for (Document__c doc : caseDocs) {
                if (doc.ContentDocumentId__c != null) {
                    hasAtLeastOneDoc = true;
                    break;
                }
            }
            if (!hasAtLeastOneDoc) {
                response.put('status', 'error');
                response.put('message', 'Please upload legal documents before proceeding.');
                return response;
            }
        }
        
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
    
    public Case createCaseRecord(SalesOrder__c salesOrderObj, ServiceCatalog__c sc, String accountId, String unitId, String selectedType, String description, String origin, String typeOfEstablishment, Boolean stopEmailsToCustomer) {
        
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
                newCase.ApprovalStatus__c = 'Not Approved';
                newCase.Origin = origin;
                newCase.ServiceCatalog__c = sc.Id;
                newCase.CaseType__c = selectedType;
                newCase.Description = description;
                //newCase.SubType__c = sc.SubCategory__c;
                newCase.Type = sc.Category__c;
                newCase.Subject = 'Broker Agency Details Update';
                newCase.Sales_Order__c = salesOrderObj != null ? salesOrderObj.Id : null;
                newCase.TypeofEstablishment__c = typeOfEstablishment;
                newCase.StopEmailsToCustomer__c = stopEmailsToCustomer;
                if (getBloomQueue() != null) {
                    newCase.OwnerId = getBloomQueue().Id;
                }
                
                List<Case> inserted = CaseService.getInstance().insertCaseWithTrigger(new List<Case>{ newCase });
                
                Case caseToUpdate = new Case(
                    Id = inserted[0].Id,
                    ApprovalStatus__c = 'Pending',
                    Draft__c = false
                );

                CaseService.getInstance().updateCase(caseToUpdate);
                
                newCase.Id = inserted[0].Id;
            }
        } catch (Exception e) {
            throw e;
        }
        return newCase; 
    }
    
}