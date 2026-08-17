/**
 * OnlinePaymentTriggerHandler
 * Layer: Trigger Handler (TriggerDispatcher / ITriggerHandler)
 * Purpose: Detect OnlinePayment__c records whose Status__c transitioned to 'Failed'
 *          and delegate failure-notification emails.
 *
 * Key Behavior:
 *  - Filters only records changing to Failed in this transaction.
 *  - Delegates querying & email composition to helper/services.
 *
 * Trigger: OnlinePaymentTrigger (after update)
 * Sharing Model: without sharing (handler itself does not query; helper uses selectors)
 * Dependencies: OnlinePaymentTriggerHelper, OnlinePaymentService, OnlinePaymentLineItemService, Messaging
 * SOQL/DML Location: No SOQL/DML here; selectors perform queries
 * Bulkification: Iterates Trigger.new; passes sets to services; one Messaging.sendEmail call
 * Error Handling: None thrown; helper skips records missing required fields
 * Last Reviewed: 2025-09-01
 */
public without sharing class OnlinePaymentTriggerHandler implements ITriggerHandler {

    public static Boolean isTriggerDisabled = false;public Boolean isDisabled() { return isTriggerDisabled; }

    // ---- BEFORE hooks (unused) ----
    public void beforeInsert(List<sObject> newList) {} public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap,List<sObject> oldList, Map<Id, sObject> oldMap) {} public void beforeDelete(List<sObject> oldList, Map<Id, sObject> oldMap) {} public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {}

    /**
     * After Update - main entry point.
     * Delegates to helper to send emails for records that flipped to 'Failed'.
     */
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,
                                List<sObject> oldList, Map<Id, sObject> oldMap) {
            if (isTriggerDisabled) return;
            OnlinePaymentTriggerHelper.sendFailureEmails(
                (List<OnlinePayment__c>) newList,
                (Map<Id, OnlinePayment__c>) oldMap
            );
        }
    // ---- AFTER hooks (unused) ----
    public void afterDelete(List<sObject> oldList, Map<Id, sObject> oldMap) {} public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {}
}