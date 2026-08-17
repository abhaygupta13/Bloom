trigger RoundRobinUserTrigger on Round_Robin_User__c  (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new RoundRobinUserTriggerHandler());
}

/*
     if(trigger.isBefore && trigger.isInsert){
      RoundRobinUserTriggerHandler.updateRoundRobinId(trigger.new);
         RoundRobinUserTriggerHandler.Populate_RoundRobinUserName(trigger.new);
         RoundRobinUserTriggerHandler.RoundRobinUserInsert(trigger.new);
    }
    if(trigger.isInsert && trigger.isAfter){
       
    }
    if(trigger.isUpdate && trigger.isAfter){
        
    }
    if(Trigger.isAfter && Trigger.isDelete){
        RoundRobinUserTriggerHandler.updateRoundRobinId_delete(trigger.oldmap);
    }
}*/