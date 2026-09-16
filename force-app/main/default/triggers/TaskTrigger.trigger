trigger TaskTrigger on Task  (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new TaskTriggerHandler());
}
/*
    if(trigger.isUpdate && trigger.isAfter){
        TaskTriggerHandler.taskCreationOnLeadConversion(trigger.newMap);
        TaskTriggerHandler.updatLeadStatusOnTaskComplete(trigger.new);
        
        
    }
    if(trigger.isInsert && trigger.isAfter){
        
        //  TaskTriggerHandler.sendEmailOnTaskOverDue(trigger.new);
    }
    if(trigger.isUpdate && trigger.isAfter){
        //   TaskTriggerHandler.sendEmailOnTaskNotContactable(trigger.new);
        //TaskTriggerHandler.sendEmailOnTaskOverDue(trigger.new);
    }
    if(trigger.isUpdate && trigger.isUpdate){
        // TaskTriggerHandler.sendEmailOnTaskNotContactable(trigger.new);
    }
    
    
}
*/