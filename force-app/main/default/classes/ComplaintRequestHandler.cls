/*****************************************************************************************
Class       : ComplaintRequestHandler
Author      :  Samiksha Mahajan
Description : 
test Class  : ComplaintRequestHandlerTest
Created Date: 18-June-2026
*****************************************************************************************/
public class ComplaintRequestHandler {
    private static ComplaintRequestHandler instance;
    private static final string COMPLAINT_REQUEST_RT { get { return 'ComplaintRequest'; } }
    
        public static ComplaintRequestHandler getInstance() { 
        if(instance == null) {
            instance = new ComplaintRequestHandler();
        }
        return instance;
    }
    
        public  void createFirstTask(List<Case> listOfCases) {
            System.debug('=== Complaint createFirstTask called ===');
    System.debug(listOfCases);
        ServiceRequestTaskHandler obj = ServiceRequestTaskHandler.getInstance();
        obj.createNewAndCloseCurrentTask(listOfCases);
    }
    
     public Case createCaseRecord(SalesOrder__c salesOrderObj, ServiceCatalog__c sc, Id accountId, Id unitId, String selectedType, String description, String origin) {
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
        system.debug('I am here');
        if (caseRecord == null) {
            response.put('status', 'error');
            response.put('message', 'Invalid Case ID.');
            return response;
        }
        
          
        
        if (response.get('status') == 'error') {
            return response;
        }
         
         if (caseRecord.Resolved__c == true){
             caseRecord.Step__c = 'Final';
             ServiceRequestTaskHandler.getInstance().createNewAndCloseCurrentTask(new List<Case>{caseRecord});
         }
         else{             
             ServiceRequestTaskHandler.getInstance().createNewAndCloseCurrentTask(new List<Case>{caseRecord});
         }
         if(response.get('status') == 'success'){
            return response;
        }
        return response;
     }
}