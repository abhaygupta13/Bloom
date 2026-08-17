trigger InvoiceTrigger on Invoice__c (after insert) {
    TriggerDispatcher.run(new InvoiceTriggerHandler());
}