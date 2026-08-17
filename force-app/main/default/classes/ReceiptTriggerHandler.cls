/**
 * ReceiptTriggerHandler
 * Layer: Trigger Handler (TriggerDispatcher / ITriggerHandler)
 * Purpose: On receipt creation, enqueue emails for receipts that are Posted and linked to an OnlinePayment__c.
 *
 * Key Behavior:
 *  - Filters newly inserted receipts (no updates/deletes).
 *  - Delegates email work to ReceiptTriggerHelper → SendReceiptEmailsQueueable (no SOQL here).
 *
 * Trigger: ReceiptTrigger (after insert)
 * Sharing Model: without sharing (no direct data access in the handler)
 * Dependencies: ReceiptTriggerHelper, SendReceiptEmailsQueueable
 * SOQL/DML Location: None (selectors/queueable handle queries & email)
 * Bulkification: Operates on Trigger.new list; helper handles chunking/queueing
 * Error Handling: No exceptions thrown; helper safely no-ops on empty input
 * Last Reviewed: 2025-09-01
 */
public without sharing class ReceiptTriggerHandler implements ITriggerHandler {

    public static Boolean isTriggerDisabled = false;
    public Boolean isDisabled() { return isTriggerDisabled; }

    // ---- BEFORE hooks (unused, kept for framework completeness) ----
    public void beforeInsert(List<sObject> newList) {}
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap,
                             List<sObject> oldList, Map<Id, sObject> oldMap) {}
    public void beforeDelete(List<sObject> oldList, Map<Id, sObject> oldMap) {}

    /**
     * After Insert
     * Delegates to helper to enqueue emails for receipts that are Posted and tied to an OnlinePayment__c.
     */
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
        if (isTriggerDisabled) return;
        ReceiptTriggerHelper.enqueuePostedReceiptEmails((List<Receipt__c>) newList);
    }

    // ---- Other AFTER hooks (not used for receipt emails) ----
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,
                            List<sObject> oldList, Map<Id, sObject> oldMap) {}
    public void afterDelete(List<sObject> oldList, Map<Id, sObject> oldMap) {}
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {}
}