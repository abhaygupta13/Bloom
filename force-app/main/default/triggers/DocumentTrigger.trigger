trigger DocumentTrigger on Document__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new DocumentTriggerHandler());
}