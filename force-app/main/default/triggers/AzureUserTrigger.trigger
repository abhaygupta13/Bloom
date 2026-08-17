trigger AzureUserTrigger on User__c (before insert, before update, before delete,after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new AzureUserTriggerHandler());
}