/*****************************************************************************************
Class       : LeasingRASyncBatch
Description : Batch to update SendToSAP__c = true for Leasing Receipt Acknowledgement records 
where HoldDate = Today-1.
Created Date: 22 Dec 2025
*****************************************************************************************/
public without sharing class LeasingRASyncBatch implements Database.Batchable<SObject>,Schedulable  {
    private static final Integer BATCH_SIZE = 20;
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date requiredDate = Date.today().addDays(-1);
        String query = 'SELECT Id, Name, SendToSAP__c ' +
            'FROM LeasingReceiptAcknowledgment__c ' +
            'WHERE HoldDate__c = :requiredDate AND SAPDocumentNumber__c = Null';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<LeasingReceiptAcknowledgment__c> scope) {
        if (scope == null || scope.isEmpty()) {
            return; 
        }
        for (LeasingReceiptAcknowledgment__c rec : scope) {
            rec.SendToSAP__c = true;
        }
        
        LeasingReceiptAcknowledgementService.getInstance().updateLeasingReceiptAcknowledgement(scope);
    }
    
    public void finish(Database.BatchableContext bc) {
    }
    
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new LeasingRASyncBatch(), BATCH_SIZE);
    }
}