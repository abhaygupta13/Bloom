/**
 * Class: OnlinePaymentLineItemService
 * Purpose: Centralized SOQL/DML operations for OnlinePaymentLineItem__c.
 *
 * Created By: Bloom Dev
 * Created On: 2025-09-01
 *
 * Description:
 * - Provides read/update helpers for OnlinePaymentLineItem__c.
 * - Used by request helpers/controllers to avoid inline SOQL/DML.
 * - Bulk-safe and null-safe methods.
 */
public inherited sharing class OnlinePaymentLineItemService {

    private static OnlinePaymentLineItemService instance;

    /** Singleton accessor. */
    public static OnlinePaymentLineItemService getInstance() {
        if (instance == null) {
            instance = new OnlinePaymentLineItemService();
        }
        return instance;
    }

    // ---- SELECT helpers ----

    /**
     * Returns line items for a given OnlinePayment__c Id.
     * @param paymentId OnlinePayment__c.Id
     * @return List of OnlinePaymentLineItem__c (Id only)
     */
    public List<OnlinePaymentLineItem__c> getOnlinePaymentLineItemsByPaymentId(String paymentId) {
        return [
            SELECT Id, OnlinePayment__c, Invoice__c, Case__c, PlannedAmount__c
            FROM OnlinePaymentLineItem__c
            WHERE OnlinePayment__c = :paymentId
        ];
    }

    // ---- DML helpers ----

     /**
     * Updates the provided line items (null/bulk safe) and returns them.
     * This is the method to be used everywhere (called from helpers).
     *
     * Example:
     *   OnlinePaymentLineItemService.getInstance().updateonlinePaymentLineItems(items);
     */
    public List<OnlinePaymentLineItem__c> updateonlinePaymentLineItems(List<OnlinePaymentLineItem__c> onlinePaymentLineItems) {
        if (onlinePaymentLineItems != null && !onlinePaymentLineItems.isEmpty()) {
            update onlinePaymentLineItems;
        }
        return onlinePaymentLineItems;
    }
    
    /** Inserts line items in bulk (null/empty-safe). Returns the same list. */
    public List<OnlinePaymentLineItem__c> insertLineItems(List<OnlinePaymentLineItem__c> items) {
        if (items != null && !items.isEmpty()) {
            insert items;
        }
        return items;
    }
    
    /** Map OnlinePayment__c Id → related Case (if any), for deriving service name. */
    public Map<Id, Case> getPrimaryCaseByPaymentIds(Set<Id> paymentIds) {
        Map<Id, Case> out = new Map<Id, Case>();
        if (paymentIds == null || paymentIds.isEmpty()) return out;

        for (OnlinePaymentLineItem__c li : [
            SELECT OnlinePayment__c,
                   Case__r.Id,
                   Case__r.Service_Catalog__r.Name
            FROM OnlinePaymentLineItem__c
            WHERE OnlinePayment__c IN :paymentIds
        ]) out.put(li.OnlinePayment__c, li.Case__r);

        return out;
    }
    
    
    /** Line items for Service payment posting (needs invoice fields). */
    public List<OnlinePaymentLineItem__c> getLinesForServicePayment(Id paymentId) {
        return [
            SELECT Invoice__r.SAPInvoiceNumber__c,
                   Invoice__r.CompanyCode__c,
                   Invoice__r.InvoiceYear__c,
                   Invoice__r.CustomerNumber__c,
                   Invoice__r.Unit__r.SAP_Contract_No__c,
            	   Invoice__r.SAPContractNumber__c
            FROM OnlinePaymentLineItem__c
            WHERE OnlinePayment__c = :paymentId
        ];
    }

    /** Line items for Misc payment posting (needs case/unit company code). */
    public List<OnlinePaymentLineItem__c> getLinesForMiscPayment(Id paymentId) {
        return [
            SELECT Case__r.CaseNumber,
                   Case__r.Unit__r.SAP_Contract_No__c,
                   Case__r.Unit__r.SAP_Company_Code__c
            FROM OnlinePaymentLineItem__c
            WHERE OnlinePayment__c = :paymentId
        ];
    }
}