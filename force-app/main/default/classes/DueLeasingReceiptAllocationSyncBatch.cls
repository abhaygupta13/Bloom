/***
Class       : DueLeasingReceiptAllocationSyncBatch
Author      : Bloom Holding 
Description : It creates Receipt Allocation for today's due receipt with due payment plan schedule
TestClass   : 
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
****************************************************************************************************************/
public  class DueLeasingReceiptAllocationSyncBatch implements Database.Batchable<SObject>, Schedulable {
    public DueLeasingReceiptAllocationSyncBatch() {

    }

    public Database.QueryLocator start (Database.BatchableContext BC){
        String today = String.valueOf(Date.today());
        String query = 
            'Select Id, SendtoSAP__c, LeasingOrder__c, LeasingOrder__r.IntegrationMessage__c '+
            'FROM LeasingReceiptAllocation__c WHERE InvoiceDocNo__c != Null ' +
            'AND LeasingReceiptAcknowledgment__r.SAPDocumentNumber__c = null '+
            'AND LeasingOrder__r.IntegrationStatus__c NOT IN (\'In Progress\', \'Failed\') '+
            'AND LeasingReceiptAcknowledgment__r.OnHold__c = false '+
            'AND LeasingReceiptAcknowledgment__r.Withdrawal__c = false '+
            'AND LeasingReceiptAcknowledgment__r.Replacement__c = false '+
            'AND LeasingReceiptAcknowledgment__r.VerifyDate__c = '+ today ;
         return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<LeasingReceiptAllocation__c> allocations) {
       For(LeasingReceiptAllocation__c allocation : allocations){
            if(allocation.LeasingOrder__r.IntegrationMessage__c != null)
            allocation.SendtoSAP__c = true;
       }
       LeasingReceiptAllocationService.getInstance().updateLeasingReceiptAllocations(allocations);
    }

    public void finish(Database.BatchableContext bc){

    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new DueLeasingReceiptAllocationSyncBatch(), 20);
    }
}