trigger LeadTrigger on Lead  (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new LeadTriggerHandler());
}
/*
    if(trigger.isBefore && trigger.isInsert){
        LeadDuplicateCheckHandler.handleDuplicateLeads(Trigger.new);
    
    }
    if(trigger.isAfter && trigger.isInsert){
        LeadTriggerHandler.createLeadTask(trigger.new);
    }
    if(trigger.isUpdate && trigger.isAfter){
        LeadTriggerHandler.createLeadTaskOnStatusUpdate(trigger.new,trigger.oldMap);
        
    }
     if(trigger.isUpdate && trigger.isBefore){
         LeadRoundRobin.ownerRRRAssignment(trigger.new,trigger.oldMap); 
       } 
      if(trigger.isupdate && trigger.isAfter){
       LeadRoundRobin.LeadCountMethod(trigger.new,trigger.oldMap);
      
   
    }
      if(trigger.isdelete && trigger.isAfter){
       LeadRoundRobin.LeadCountMethod(null,trigger.oldMap);
   
    }
}*/