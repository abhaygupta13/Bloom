trigger Milestonetrigger on Milestone__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new MilestonetriggerHandler()); 
}



/*
(After Update) {
    If(trigger.isupdate && trigger.isAfter){
        Milestoneinstallmentupdation.installmentreviseddateupdation(trigger.new);
    }
}*/