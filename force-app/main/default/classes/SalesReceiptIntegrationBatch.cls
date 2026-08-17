/*****************************************************************************************
Class       : SalesReceiptIntegrationBatch
Author      : Biswajeet
Description : Receipt Integration Batch
Test Class  : SalesReceiptIntegrationBatchTest
Created Date: 24 JUL 2025 
*****************************************************************************************/
public class SalesReceiptIntegrationBatch implements Database.Batchable<SObject>, Schedulable {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id, SendtoSAP__c, ReceiptPostingDate__c  FROM ReceiptAcknowledgement__c
                                         WHERE SalesOrder__r.Status__c NOT IN  ('Cancelled','Book Cancelled')  
                                         AND Finance_Verified__c = true AND SAP_Document_No__c = NULL
                                         AND ((Due_Date__c <= TODAY AND ReceiptPostingDate__c = NULL) OR
                                         (ReceiptPostingDate__c <= TODAY AND Due_Date__c <= TODAY))
                                         AND PaymentType__c NOT IN ('Security Cheque', 'Transfer of rights - Resale') 
                                         AND Status__c  != 'Reversed' AND SAP_Condition_Type__c != 'P145']);
    }
    
    public void execute(Database.BatchableContext bc, List<ReceiptAcknowledgement__c> raList) {
        
        List<ReceiptAcknowledgement__c> raUpdateList = new List<ReceiptAcknowledgement__c>();
        for (ReceiptAcknowledgement__c ra : raList){
            if(ra.SendtoSAP__c == true){
                ra.SendtoSAP__c = false;
                raUpdateList.add(ra);
            } 
        }
        ReceiptAcknowledgementService.getInstance().updateReceiptAcknowledgementWithoutTrigger(raUpdateList);
        
        for (ReceiptAcknowledgement__c ra : raList){
            ra.SendtoSAP__c = true;
        }
        ReceiptAcknowledgementService.getInstance().updateReceiptAcknowledgements(raList);
    }
    
    public void finish(Database.BatchableContext bc) {
        
    }
    
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new SalesReceiptIntegrationBatch(), 1);
    }
}