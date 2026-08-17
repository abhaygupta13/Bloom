/**
 * Class: InvoiceAllocationService
 * Purpose: Centralized SOQL/DML helpers for InvoiceAllocation__c.
 *
 * Created By: Bloom Dev
 * Created On: 2025-09-01
 *
 * Description:
 * - Keeps all InvoiceAllocation__c queries and DML in one place.
 * - Bulk-safe and null-safe helpers used by handlers/controllers.
 */
public inherited sharing class InvoiceAllocationService {
    private static InvoiceAllocationService inst;
    public static InvoiceAllocationService getInstance() {
        if (inst == null) inst = new InvoiceAllocationService();
        return inst;
    }
    private InvoiceAllocationService() {}

    /**
     * Inserts allocations in bulk (null/empty-safe). Returns the same list.
     * @param allocations List<InvoiceAllocation__c>
     * @return List<InvoiceAllocation__c> (same reference)
     */
    public List<InvoiceAllocation__c> insertAllocations(List<InvoiceAllocation__c> allocations) {
        if (allocations != null && !allocations.isEmpty()) {
            insert allocations;
        }
        return allocations;
    }

    /**
     * Sums AllocatedAmount__c per Invoice for the given invoices.
     * @param invoices List<Invoice__c> to aggregate allocations for
     * @return Map<Id, Decimal> keyed by Invoice__c Id -> total allocated amount
     */
    public Map<Id, Decimal> sumAllocatedByInvoices(List<Invoice__c> invoices) {
        Map<Id, Decimal> mapAlloc = new Map<Id, Decimal>();
        if (invoices == null || invoices.isEmpty()) return mapAlloc;

        Set<Id> invoiceIds = new Set<Id>();
        for (Invoice__c inv : invoices) if (inv != null) invoiceIds.add(inv.Id);
        if (invoiceIds.isEmpty()) return mapAlloc;

        for (AggregateResult ar : [
            SELECT Invoice__c invId, SUM(AllocatedAmount__c) allocSum
            FROM InvoiceAllocation__c
            WHERE Invoice__c IN :invoiceIds
            GROUP BY Invoice__c
        ]) {
            mapAlloc.put((Id) ar.get('invId'), (Decimal) ar.get('allocSum'));
        }
        return mapAlloc;
    }

    /**
     * Gets all allocations tied to a specific Receipt.
     * @param receiptId Receipt__c Id
     * @return List<InvoiceAllocation__c>
     */
    public List<InvoiceAllocation__c> getByReceipt(Id receiptId) {
        if (receiptId == null) return new List<InvoiceAllocation__c>();
        return [
            SELECT Id,
                   Invoice__c,
                   Invoice__r.SAPInvoiceNumber__c,
                   Invoice__r.Name,
                   AllocatedAmount__c,
                   AllocationDate__c,
                   Notes__c,
                   Invoice__r.CompanyCode__c,
                   Invoice__r.InvoiceYear__c,
                   Invoice__r.SAPContractNumber__c,
            	   Invoice__r.SAPAssignment__c
            FROM InvoiceAllocation__c
            WHERE Receipt__c = :receiptId
            ORDER BY AllocationDate__c DESC, CreatedDate DESC
        ];
    }

    /**
     * Gets allocations for Account + Unit within a date range.
     * @param accountId Account Id
     * @param unitId    Unit__c Id
     * @param startDate Inclusive start date
     * @param endDate   Inclusive end date
     * @return List<InvoiceAllocation__c>
     */
    public List<InvoiceAllocation__c> getByAccountUnitInRange(Id accountId, Id unitId, Date startDate, Date endDate) {
        if (accountId == null || unitId == null || startDate == null || endDate == null) {
            return new List<InvoiceAllocation__c>();
        }
        return [
            SELECT Id,
                   Invoice__c,
                   Invoice__r.Name,
                   Receipt__r.PaymentDate__c,
                   Receipt__r.PaymentMode__c,
                   Receipt__r.AmountReceived__c,
                   AllocatedAmount__c
            FROM InvoiceAllocation__c
            WHERE Invoice__r.Account__c = :accountId
              AND Invoice__r.Unit__c    = :unitId
              AND AllocationDate__c     >= :startDate
              AND AllocationDate__c     <= :endDate
            ORDER BY AllocationDate__c DESC, CreatedDate DESC
        ];
    }
    
    /**
 * Returns the set of Invoice__c Ids referenced by the given InvoiceAllocation__c Ids.
 */
public Set<Id> getInvoiceIdsFromAllocationIds(Set<Id> allocationIds) {
    Set<Id> out = new Set<Id>();
    if (allocationIds == null || allocationIds.isEmpty()) return out;
    for (InvoiceAllocation__c a : [
        SELECT Invoice__c
        FROM InvoiceAllocation__c
        WHERE Id IN :allocationIds
    ]) {
        if (a.Invoice__c != null) out.add(a.Invoice__c);
    }
    return out;
}
}