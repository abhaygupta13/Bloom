/**
 * Class: InvoiceAllocationHelper
 * Purpose: Recalculate Invoice status and due amount when InvoiceAllocation__c records change.
 *
 * Created By: Bloom Dev
 * Created On: 2025-09-01
 *
 * Description:
 * - Contains NO inline SOQL/DML. Uses service classes for data access & persistence.
 * - Logic is unchanged: derive impacted invoices, recompute allocated totals, set Status__c and DueAmount__c.
 */
public without sharing class InvoiceAllocationHelper {

    // Optional: centralize status strings
    private static final String ST_UNPAID         = 'Unpaid';
    private static final String ST_PARTIALLY_PAID = 'Partially Paid';
    private static final String ST_PAID           = 'Paid';

    /**
     * Recomputes invoice Status__c and DueAmount__c for invoices impacted by the given allocations.
     * @param allocationIds Set<Id> of InvoiceAllocation__c that were inserted/updated/deleted.
     */
    public static void updateInvoiceStatuses(Set<Id> allocationIds) {
        if (allocationIds == null || allocationIds.isEmpty()) return;

        // 1) Find the impacted Invoice Ids (via service)
        Set<Id> invoiceIds = InvoiceAllocationService.getInstance()
            .getInvoiceIdsFromAllocationIds(allocationIds);
        if (invoiceIds.isEmpty()) return;

        // 2) Load invoices via service (no child subquery) + get allocated sums via aggregate service
        List<Invoice__c> invoices = InvoiceService.getInstance().getByIds(new List<Id>(invoiceIds));
        if (invoices.isEmpty()) return;

        Map<Id, Decimal> allocationMap =
            InvoiceAllocationService.getInstance().sumAllocatedByInvoices(invoices);

        // 3) Recalculate status & due for each invoice
        List<Invoice__c> toUpdate = new List<Invoice__c>();
        for (Invoice__c inv : invoices) {
            Decimal total     = (inv.TotalAmount__c == null) ? 0 : inv.TotalAmount__c;
            Decimal allocated = allocationMap.containsKey(inv.Id) ? allocationMap.get(inv.Id) : 0;

            String newStatus;
            if (allocated == 0) {
                newStatus = ST_UNPAID;
            } else if (allocated < total) {
                newStatus = ST_PARTIALLY_PAID;
            } else {
                newStatus = ST_PAID;
            }

            inv.Status__c    = newStatus;
            inv.DueAmount__c = total - allocated;
            toUpdate.add(inv);
        }

        if (!toUpdate.isEmpty()) {
            // 4) Persist via service (no inline DML)
            InvoiceService.getInstance().updateInvoices(toUpdate);
        }
    }
}