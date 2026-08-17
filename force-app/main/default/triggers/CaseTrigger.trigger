trigger CaseTrigger on Case (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new CaseTriggerHandler());
}

/*

trigger CaseTrigger on Case (before update,after update,before insert,after insert,before delete,after delete) {
    
    
    Bypass_Trigger__mdt byt = Bypass_Trigger__mdt.getInstance('Case');
    
    if(trigger.isUpdate && trigger.isBefore){
        CaseTriggerHandler.caseandJointOwnerSharePercentage(trigger.new);
        
    }
    if(trigger.isInsert && trigger.isBefore && !byt.Insert_ByPass__c){
        
        CaseRoundRobin.ownerRRRAssignment(trigger.new);
    }
    if(trigger.isInsert && trigger.isafter && !byt.Insert_ByPass__c){
        
        CaseDocumentCreation.DocumentCreation(trigger.newMap);
    }
    if(trigger.isupdate && trigger.isAfter){
        CaseRoundRobin.caseCountMethod(trigger.new,trigger.oldMap);      
        
    }
    if(trigger.isdelete && trigger.isAfter){
        CaseRoundRobin.caseCountMethod(null,trigger.oldMap);
        
    }
}

*/