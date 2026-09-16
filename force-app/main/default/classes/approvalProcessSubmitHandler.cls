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
    
    @AuraEnabled
    public static void callApprovalProcess(String recid){
        list<SalesOrder__c>SalesOrderInfo=[select id,name,Status__c,SalesManager__c, SalesManager__r.Name,SalesManager__r.Manager.Id,SalesManager__r.Manager.Name  from SalesOrder__c where id=:recid];
        List<Id> param1=new List<Id>();
        param1.add(SalesOrderInfo[0].SalesManager__r.Manager.Id);
        String str='Error';
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(recid);
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

}