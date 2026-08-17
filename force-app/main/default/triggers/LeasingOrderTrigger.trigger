trigger LeasingOrderTrigger on LeasingOrder__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
     TriggerDispatcher.run(new LeasingOrderTriggerHandler());
}