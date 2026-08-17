trigger ReceiptAllocationTriggerforDelete on ReceiptAllocation__c (before delete) {
 TriggerDispatcher.run(new ReceiptAllocationTriggerforDeleteHandler());   
 
}