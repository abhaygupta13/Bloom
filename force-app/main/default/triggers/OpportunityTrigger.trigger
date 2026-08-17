trigger OpportunityTrigger on Opportunity  (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new OpportunityTriggerHandler());
}
/*
(after insert) {
    Bypass_Trigger__mdt byt = Bypass_Trigger__mdt.getInstance('Opportunity');
    if(!byt.Insert_ByPass__c)
    OpportunityTriggerHandler.sendDuplicateOppEmail(Trigger.new);
}*/