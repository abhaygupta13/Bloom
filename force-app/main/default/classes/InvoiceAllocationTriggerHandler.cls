public without sharing class InvoiceAllocationTriggerHandler implements ITriggerHandler {

    // Flip to true inside a transaction to bypass this handler.
    public static Boolean isTriggerDisabled = false;

    public Boolean isDisabled() {return isTriggerDisabled;} 

    // ========== BEFORE HOOKS (unused here) ==========
    public void beforeInsert(List<sObject> newList) {}
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {}
    public void beforeDelete(List<sObject> oldList, Map<Id, sObject> oldMap) {}

    // ========== AFTER HOOKS ==========
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
        //InvoiceAllocationHelper.updateInvoiceStatuses(newMap.keySet());
    }

    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,List<sObject> oldList, Map<Id, sObject> oldMap) {
        // Recalc for changed/added allocations
       // InvoiceAllocationHelper.updateInvoiceStatuses(newMap.keySet());
    }

    public void afterDelete(List<sObject> oldList, Map<Id, sObject> oldMap) {
        // Recalc for removed allocations
        //InvoiceAllocationHelper.updateInvoiceStatuses(oldMap.keySet());
    }

    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
        // Recalc for restored allocations
        //InvoiceAllocationHelper.updateInvoiceStatuses(newMap.keySet());
    }
}