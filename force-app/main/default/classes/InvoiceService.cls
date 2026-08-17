/**
 * Class: InvoiceService
 * Purpose: Centralized SOQL helpers for Invoice__c.
 *
 * Created By: Bloom Dev
 * Created On: 2025-09-01
 *
 * Description:
 * - Provides read/query utilities for Invoice__c.
 * - All invoice-related queries must be routed through this service.
 * - No business logic here — only data access.
 */
public inherited sharing class InvoiceService {
    
    // --- Singleton ---
    private static InvoiceService inst;
    public static InvoiceService getInstance() {
        if (inst == null) inst = new InvoiceService();
        return inst;
    }
    private InvoiceService() {}
    
    // ======================================================
    // Selectors
    // ======================================================

    /**
     * Returns unpaid or partially paid invoices for a given Account + Unit.
     */
    public List<Invoice__c> getUnpaidOrPartialByAccountUnit(Id accountId, Id unitId) {
        if (accountId == null || unitId == null) return new List<Invoice__c>();
        return [
            SELECT Id, Name, SAPInvoiceNumber__c, TotalAmount__c, DueAmount__c,
                   Status__c, InvoiceDate__c, InvoiceDescription__c,PeriodStartDate__c, PeriodEndDate__c
            FROM Invoice__c
            WHERE Account__c = :accountId
              AND Unit__c    = :unitId
              AND Status__c IN ('Unpaid', 'Partially Paid')
            ORDER BY InvoiceDate__c ASC, Name ASC
        ];
    }
    
    /**
     * Fetch a single Invoice__c by Id.
     */
    public Invoice__c getById(Id invoiceId) {
        if (invoiceId == null) return null;
        return [
            SELECT Id, Name, SAPInvoiceNumber__c, TotalAmount__c, DueAmount__c,
                   Status__c, InvoiceDate__c, InvoiceDescription__c, Unit__c, Account__c,PeriodStartDate__c, PeriodEndDate__c
            FROM Invoice__c
            WHERE Id = :invoiceId
            LIMIT 1
        ];
    }

    /**
     * Bulk fetch invoices by Ids.
     */
    public List<Invoice__c> getByIds(List<Id> ids) {
        if (ids == null || ids.isEmpty()) return new List<Invoice__c>();
        return [
            SELECT Id, Name, SAPInvoiceNumber__c, TotalAmount__c, DueAmount__c, Status__c
            FROM Invoice__c
            WHERE Id IN :ids
        ];
    }

    /**
     * Bulk fetch as Map<Id, Invoice__c>.
     */
    public Map<Id, Invoice__c> getByIdsAsMap(List<Id> ids) {
        if (ids == null || ids.isEmpty()) return new Map<Id, Invoice__c>();
        return new Map<Id, Invoice__c>([
            SELECT Id, Name, SAPInvoiceNumber__c, TotalAmount__c, DueAmount__c, Status__c
            FROM Invoice__c
            WHERE Id IN :ids
        ]);
    }
    
    /**
     * Calculates total due across unpaid/partially paid invoices for an Account + Unit.
     * Uses DueAmount__c (actual outstanding).
     */
    public AggregateResult sumTotalDueByAccountUnit(Id accountId, Id unitId) {
        if (accountId == null || unitId == null) return null;
        return [
            SELECT SUM(DueAmount__c) totalDue
            FROM Invoice__c
            WHERE Account__c = :accountId
              AND Unit__c    = :unitId
              AND Status__c IN ('Unpaid', 'Partially Paid')
        ];
    }
    
    /**
     * Fetch invoices by Account + Unit within a date range (inclusive).
     * Auto-corrects swapped dates.
     */
    public List<Invoice__c> getByAccountUnitInRange(Id accountId, Id unitId, Date startDate, Date endDate) {
        if (accountId == null || unitId == null || startDate == null || endDate == null) {
            return new List<Invoice__c>();
        }
        if (startDate > endDate) {
            Date tmp = startDate; startDate = endDate; endDate = tmp;
        }
        return [
            SELECT Id, Name, InvoiceDate__c, SAPInvoiceNumber__c,
                   InvoiceDescription__c, TotalAmount__c, DueAmount__c, Status__c
            FROM Invoice__c
            WHERE Account__c     = :accountId
              AND Unit__c        = :unitId
              AND InvoiceDate__c >= :startDate
              AND InvoiceDate__c <= :endDate
            ORDER BY InvoiceDate__c ASC, Name ASC
        ];
    }
    
    /**
     * Returns SOA line items for Account + Unit filtered by PostingDate__c,
     * including fields required by SOA_PDFController.
     */
    public List<Invoice__c> getForSOAByPostingDate(Id accountId, Id unitId, Date startDate, Date endDate) {
        if (accountId == null || unitId == null || startDate == null || endDate == null) {
            return new List<Invoice__c>();
        }
        if (startDate > endDate) {
            //Date tmp = startDate; startDate = endDate; endDate = tmp;
        }
        return [
            SELECT Id,
                   PostingDate__c,
                   SAPInvoiceNumber__c,
                   InvoiceDescription__c,
                   SAPAssignment__c,
                   DebitCredit__c,
                   TotalAmount__c,
                   DocumentType__c,
                   Status__c
            FROM Invoice__c
            WHERE Account__c      = :accountId
              AND Unit__c         = :unitId
              AND PostingDate__c >= :startDate
              AND PostingDate__c <= :endDate
            ORDER BY PostingDate__c ASC, SAPInvoiceNumber__c ASC
        ];
    }

    // ======================================================
    // DML utilities
    // ======================================================

    /**
     * Bulk update invoices (null/empty-safe).
     */
    public List<Invoice__c> updateInvoices(List<Invoice__c> invoices) {
        if (invoices != null && !invoices.isEmpty()) {
            update invoices;
        }
        return invoices;
    }
    
    /**
     * Partial-success lookup updates (returns SaveResults for auditing).
     */
    public void updateLookupsPartial(List<Invoice__c> rows) {
        if (!rows.isEmpty()) update rows;
    }
}