public class CancellationRequestSRHandler {
    private static CancellationRequestSRHandler instance;
    private static final string CANCELLATION_REQUEST_RT { get { return 'CancellationRequest'; } }
    
    
        public static CancellationRequestSRHandler getInstance() { 
        if(instance == null) {
            instance = new CancellationRequestSRHandler();
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
        
  
                    String subjectPrefix = 'Cancellation Request';
        
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
         public String validateEligibility(SalesOrder__c salesOrderObj){
        String message;
            if(salesOrderObj != null && salesOrderObj.Status__c != 'Sold'){
            message = 'This unit is not eligible for the selected service request';
        }
          else if(salesOrderObj != null && salesOrderObj.Unit__r.Status__c == 'Cancelled'){
            message = 'This unit is already Cancelled and not eligible for the selected service request';
        }
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
             ServiceRequestTaskHandler.getInstance().createNewAndCloseCurrentTask(new List<Case>{caseRecord}); 
        }
        
        if (response.get('status') == 'error') {
            return response;
        }
        return response;
    }
    
}