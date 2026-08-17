/**
 * Class: ReceiptService
 * Purpose: Centralized SOQL/DML helpers for Receipt__c.
 *
 * Notes:
 * - Encapsulates all queries and DML for Receipt__c.
 * - Provides insert and fetch utilities (by Id, by OnlinePayment, by multiple Ids).
 * - Bulk-safe and null-safe.
 */
public inherited sharing class ReceiptService {

    // Singleton
    private static ReceiptService inst;
    public static ReceiptService getInstance() {
        if (inst == null) inst = new ReceiptService();
        return inst;
    }
    private ReceiptService() {}

    // ---------------- DML ----------------

    /** Inserts a single Receipt__c and returns the inserted record (Id populated). */
    public Receipt__c insertReceipt(Receipt__c receipt) {
        if (receipt == null) return null;
        insert receipt;
        return receipt;
    }

    // ---------------- Selectors ----------------

    /**
     * Fetches the latest (by LastModifiedDate DESC) receipt per OnlinePayment__c,
     * keyed by OnlinePayment Id.
     * Input can be a mixed/partial list; nulls and records without Id are ignored.
     */
    public Map<Id, Receipt__c> getReceiptsByPaymentIds(List<OnlinePayment__c> payments) {
        Map<Id, Receipt__c> out = new Map<Id, Receipt__c>();
        if (payments == null || payments.isEmpty()) return out;

        Set<Id> payIds = new Set<Id>();
        for (OnlinePayment__c p : payments) if (p != null && p.Id != null) payIds.add(p.Id);
        if (payIds.isEmpty()) return out;

        // We can't use "new Map<Id, Receipt__c>([...])" here because the desired key is OnlinePayment__c, not Receipt__c.Id.
        for (Receipt__c r : [
            SELECT Id, Name, OnlinePayment__c
            FROM Receipt__c
            WHERE OnlinePayment__c IN :payIds
            ORDER BY LastModifiedDate DESC
        ]) {
            // Last one wins per OnlinePayment__c (because of DESC ordering above).
            out.put(r.OnlinePayment__c, r);
        }
        return out;
    }

    /** Overload: same as above but accepts OnlinePayment Ids directly. */
    public Map<Id, Receipt__c> getReceiptsByPaymentIds(List<Id> paymentIds) {
        Map<Id, Receipt__c> out = new Map<Id, Receipt__c>();
        if (paymentIds == null || paymentIds.isEmpty()) return out;
        Set<Id> payIds = new Set<Id>(paymentIds);

        for (Receipt__c r : [
            SELECT Id, Name, OnlinePayment__c
            FROM Receipt__c
            WHERE OnlinePayment__c IN :payIds
            ORDER BY LastModifiedDate DESC
        ]) {
            out.put(r.OnlinePayment__c, r);
        }
        return out;
    }

    /** Fetches a single Receipt__c by Id (rich field set for PDFs/emails). */
    public Receipt__c getById(Id receiptId) {
        if (receiptId == null) return null;
        return [
            SELECT Id, Name, AmountReceived__c, PaymentDate__c, PaymentMode__c,
                   SAPDocumentNo__c, Status__c, GatewayReference__c,
                   Account__c, Unit__c, OnlinePayment__c,
                   Account__r.Name, Account__r.AccountNumber, Account__r.SAP_BP_No__c,
                   Unit__r.Name, Unit__r.ProjectName__c, Unit__r.SAP_Contract_No__c, TechnologyFee__c
            FROM Receipt__c
            WHERE Id = :receiptId
            LIMIT 1
        ];
    }

    /**
     * Bulk fetch receipts by Ids, keyed by Receipt Id.
     * (Here we CAN use the direct Map constructor because the key is the record Id.)
     */
    public Map<Id, Receipt__c> getByIds(List<Id> ids) {
        if (ids == null || ids.isEmpty()) return new Map<Id, Receipt__c>();
        return new Map<Id, Receipt__c>([
            SELECT Id, Name, AmountReceived__c, OnlinePayment__c
            FROM Receipt__c
            WHERE Id IN :ids
        ]);
    }
}