trigger ReceiptAcknowledgeTriggerforDelete on ReceiptAcknowledgement__c (before insert, after insert, before update, after update, before delete, after delete) {
    TriggerDispatcher.run(new ReceiptAcknowledgeDeleteHandler());   
}