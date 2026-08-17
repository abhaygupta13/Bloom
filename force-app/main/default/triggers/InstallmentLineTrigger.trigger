trigger InstallmentLineTrigger on InstallmentLines__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
        TriggerDispatcher.run(new InstallmentLineTriggerHandler());
    }

/**
 * 
 * trigger InstallmentLineTrigger on InstallmentLines__c (before insert,after insert,before update,after update) {
    
    
        if(trigger.isUpdate && trigger.isBefore){
            InstallmentLineTriggerHandler.updateInstTaxAmountinwords(trigger.new,trigger.oldMap);
        
    }
     if(trigger.isInsert && trigger.isBefore){
            InstallmentLineTriggerHandler.updateInstTaxAmountinwordsOninsert(trigger.new);
        
    }

}
 */