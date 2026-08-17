trigger ReceiptTrigger on Receipt__c (after insert) {
    TriggerDispatcher.run(new ReceiptTriggerHandler());
}