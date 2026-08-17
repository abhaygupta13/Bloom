/***
Class       : approvalProcessSubmitHandler
Author      : Smaartt
Description : 
TestClass   : approvalProcessSubmitHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.     version              Date                Details
1.          V1.0              10/08/23           Initial Version 
****************************************************************************************************************/


public class approvalProcessSubmitHandler {
    
    private static final string Broker_Registration_RT { get { return 'BrokerAgentRegistrationAndUpdate'; } } //Bapp
    private static final string GENERAL_ENQUIRY_RT { get { return 'GeneralEnquiry'; } }
    
    @AuraEnabled
    public static void callApprovalProcess(String recid){
        
        Id recordId = (Id)recid;
        
        if(recordId.getSObjectType() == Case.SObjectType){
            submitCaseApproval(recordId);
        }
        else if(recordId.getSObjectType() == SalesOrder__c.SObjectType){
            submitSalesOrderApproval(recordId);
        }
    }
    
    public static void submitCaseApproval(Id caseId){
        CaseService caseService = CaseService.getInstance();
        
        Case cs = caseService.getCaseById(caseId);
        
        Id brokerRegistrationRTId = Utility.getRecordTypeIdByDevName(
            Case.SObjectType,
            Broker_Registration_RT
        );
        
        Id generalEnquiryRTId = Utility.getRecordTypeIdByDevName(
            Case.SObjectType,
            GENERAL_ENQUIRY_RT
        );
         
        if(cs.RecordTypeId == brokerRegistrationRTId &&
           cs.SubType__c == 'Broker New Agent Registration') {
               
               if(cs.OwnerId != null &&
                  String.valueOf(cs.OwnerId).startsWith('00G')) {
                      
                      throw new AuraHandledException(
                          'Assign to yourself before proceeding'
                      );
                  }
               
               processCasesForApproval(new Set<Id>{caseId});
           }
    }
    
    public static void submitSalesOrderApproval(Id salesOrderId){
        
        list<SalesOrder__c>SalesOrderInfo=[select id,name,Status__c,SalesManager__c, SalesManager__r.Name,SalesManager__r.Manager.Id,SalesManager__r.Manager.Name  from SalesOrder__c where id=:salesOrderId];
        List<Id> param1=new List<Id>();
        param1.add(SalesOrderInfo[0].SalesManager__r.Manager.Id);
        String str='Error';
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(salesOrderId);
        if(SalesOrderInfo[0].Status__c=='Booked'){
            req1.setNextApproverIds(param1);
        }
        req1.setSubmitterId(UserInfo.getUserId()); 
        req1.setProcessDefinitionNameOrId(System.Label.SalesOrderCancellationApprovalLabel);
        req1.setSkipEntryCriteria(true);
        try{
            Approval.ProcessResult result = Approval.process(req1);
            //str='Success';
            
        }
        catch(Exception ex){
            
            throw new Auraexception(ex);
            
        }
        
        // return str;
        //return 'abc';
    }
    
    @AuraEnabled
    public static void updateSalesOrder(SalesOrder__c salesOrder){
        if(salesOrder != null ){
            salesOrder.Cancellation_Requested_By__c = UserInfo.getUserId();
        }
        update salesOrder; 
    }
    
    //BAPP
    public static void processCasesForApproval(Set<Id> caseIds) {
        if (caseIds == null || caseIds.isEmpty()) {
            return;
        }
        
        List<Case> casesToUpdate = new List<Case>();
        List<Case> fetchedCases = new List<Case>();
        
        Group BLQueue;
        try {
            BLQueue = QueueService.getInstance()
                .getGroupByDeveloperNameAndType('Bloom_Legal_BL', 'Queue');
        } catch (Exception e) {
            System.debug('Queue "Bloom_Legal_BL" not found: ' + e.getMessage());
            BLQueue = null;
        }
        
        // STEP 1: Prepare updates
        for (Id caseId : caseIds) {
            casesToUpdate.add(new Case(
                Id = caseId,
                SendToBL__c = true,
                SubStatus__c = 'Approved by BBM',
                FinalApprovalStage__c = 'Second Approval',             
                OwnerId = (BLQueue != null ? BLQueue.Id : null)
            ));
        }
        
        // STEP 2: Bulk update
        if (!casesToUpdate.isEmpty()) {
            caseService.getInstance().updateUnits(casesToUpdate);
        }
        
        // STEP 3: Fetch and process tasks
        for (Id caseId : caseIds) {
            Case c = CaseService.getInstance().getCaseById(caseId);
            if (c != null) {
                fetchedCases.add(c);
            }
        }
        
        if (!fetchedCases.isEmpty()) {
            BrokerAgentRegiAndUpdateSRHandler.updatetask(fetchedCases);
        }
    }


        @AuraEnabled(cacheable=true)
    public static String getCaseRecordTypeDeveloperName(Id caseId) {
    
        try {
            Case cs = CaseService.getInstance().getCaseById(caseId);
            return cs.RecordType.DeveloperName;
    
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
}