trigger JointOwnerTrigger on JointOwner__c(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new JointOwnerTriggerHandler());
}

/*trigger JointOwnerTrigger on JointOwner__c (before insert, before update,before delete,after delete) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert || trigger.isUpdate) {
        
        }
    }
    if(trigger.isBefore && trigger.isDelete){
        JointOwnerTriggerHandler.errorMessageOnJointOwnerDelete(Trigger.old);
    }
}
*/