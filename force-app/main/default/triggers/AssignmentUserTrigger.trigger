trigger AssignmentUserTrigger on AssignmentUser__c ( before insert, before update, after insert, after update ) {
    TriggerDispatcher.run(new AssignmentUserTriggerHandler());   
}