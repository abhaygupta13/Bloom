/**
 * InvoiceTriggerHandler
 * Layer: Trigger Handler (TriggerDispatcher / ITriggerHandler)
 * Purpose: On invoice creation, populate Account__c and Unit__c lookups.
 * Trigger: InvoiceTrigger (after insert)
 * Sharing: without sharing (no direct queries here)
 */
public without sharing class InvoiceTriggerHandler implements ITriggerHandler {
    public static Boolean isTriggerDisabled = false;
    public Boolean isDisabled() { return isTriggerDisabled; }

    // BEFORE hooks (unused for now)
    public void beforeInsert(List<sObject> newList) {InvoiceTriggerHelper.upsertLookupsForNewInvoices((List<Invoice__c>) newList);}
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap,
                             List<sObject> oldList, Map<Id, sObject> oldMap) {}
    public void beforeDelete(List<sObject> oldList, Map<Id, sObject> oldMap) {}

    // AFTER INSERT → delegate to helper
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
        InvoiceTriggerHelper.upsertLookupsForNewInvoices((List<Invoice__c>) newList);
    }

    // Other AFTER hooks (not used)
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,
                            List<sObject> oldList, Map<Id, sObject> oldMap) {}
    public void afterDelete(List<sObject> oldList, Map<Id, sObject> oldMap) {}
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {}
}