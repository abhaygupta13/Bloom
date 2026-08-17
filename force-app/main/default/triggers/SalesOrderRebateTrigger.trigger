trigger SalesOrderRebateTrigger on SalesOrderRebate__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new SalesOrderRebateTriggerHandler());
}