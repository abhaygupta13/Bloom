/*****************************************************************************************
Class       : SalesOperationSRHandler
Author      :  Samiksha
Description : 
test Class  :
Created Date: 17-04-2026
*****************************************************************************************/
public inherited sharing class SalesOperationSRHandler {
    
    private static SalesOperationSRHandler instance;
    private static final string SALES_OPERATION_RT { get { return 'SalesOperationService'; } }
    private static final string MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    
                            
    public SalesOperationSRHandler() {}
    
    public static SalesOperationSRHandler getInstance() { 
        if(instance == null) {
            instance = new SalesOperationSRHandler();
        }
        return instance;
    }
    
    public  void createFirstTask(List<Case> listOfCases) {
        ServiceRequestTaskHandler obj = ServiceRequestTaskHandler.getInstance();
        obj.createNewAndCloseCurrentTask(listOfCases);
    }
    
    public String validateEligibility(SalesOrder__c salesOrderObj, Case caseObj){
        String message;
        return message;
    }
    
    public Case createCaseRecord(SalesOrder__c salesOrderObj, ServiceCatalog__c sc, Id accountId, Id unitId, String selectedType, String description, String origin, Boolean stopEmailsToCustomer) {
        AccountService accService = AccountService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        
        Case newCase = new Case();
        newCase.AccountId = salesOrderObj != null ? salesOrderObj.Account__c : accountId;
        newCase.Project__c = salesOrderObj != null ? salesOrderObj.Project__c : null;
        newCase.RecordTypeId = Utility.getRecordTypeIdByDevName(Case.SObjectType, sc.RecordTypeDevName__c);
      //newCase.Sales_Order__c = salesOrderObj != null ? salesOrderObj.Id;
        newCase.Unit__c = salesOrderObj != null ? salesOrderObj.Unit__c : unitId;
        newCase.Origin = origin;
        newCase.ServiceCatalog__c = sc.Id;
        newCase.CaseType__c = selectedType;
        newCase.Description = description;
        newCase.SubType__c = sc.SubCategory__c;    
        newCase.Status = 'New';
         Map<String, String> subTypeToSubject = new Map<String, String>{
            'Document Controller' => 'Document Controller',
                'Data Analystics' => 'Data Analystics',
                'Office Manager' => 'Office Manager',
                'Broker Management' => 'Broker Management',
                'Sales Operation' => 'Sales Operation',
                'Post Sales Operation' => 'Post Sales Operation',
                'Customer Finance' => 'Customer Finance'
                };
                    
                String subjectPrefix = subTypeToSubject.containsKey(newCase.SubType__c) ? subTypeToSubject.get(newCase.SubType__c)  : 'Sales Operation Service';
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
        
        if(caseRecord.Step__c !='Final'){
                response.put('status', 'error');
                response.put('message', 'Invalid Case Step.');
                return response;
            
            }
        if(caseRecord.CaseClosureRemarks__c == null){
            response.put('status', 'error');
             response.put('message', 'Case Closure Remarks are mandatory.');
             return response;
        }
        
        if(response.get('status') == 'success'){
            handleNextSteps(caseRecord); 
        }
        
        if (response.get('status') == 'error') {
            return response;
        }
        return response;
    }
    
    public  void handleNextSteps(Case caseRec){
        ServiceRequestTaskHandler.getInstance().createNewAndCloseCurrentTask(new List<Case>{caseRec});
    }
    
  
 
}