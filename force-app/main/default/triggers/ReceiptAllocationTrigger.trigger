trigger ReceiptAllocationTrigger on ReceiptAllocation__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new ReceiptAllocationTriggerHandler());
}


/*
    try {    
        new ReceiptAllocationTriggerHandler().run('ReceiptAllocation__c');
    } catch(Exception e) {   
        throw e;
    } 
 }
*/