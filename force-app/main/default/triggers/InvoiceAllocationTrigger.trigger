trigger InvoiceAllocationTrigger on InvoiceAllocation__c (after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new InvoiceAllocationTriggerHandler());
}