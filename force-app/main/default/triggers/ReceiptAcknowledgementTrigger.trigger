trigger ReceiptAcknowledgementTrigger on ReceiptAcknowledgement__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new ReceiptAcknowledgementTriggerHandler());
}

/*
trigger ReceiptAcknowledgementTrigger on ReceiptAcknowledgement__c (before insert, after insert,before update, after update,before delete) {
    
    try {    
        new ReceiptAcknowledgementTriggerHandler().run('ReceiptAcknowledgement__c');
    } catch(Exception e) {   
        
        throw e;
    } 
}

*/