/**
 * BCAPP_SapInvoiceIngestService
 * Layer: Service (Integration ingest)
 * Purpose: Ingest SAP invoice clearing items (Misc flow) and upsert Invoice__c records.
 *
 * Key Behavior:
 *  - Idempotent upsert on Invoice__c via external id SAPInvoiceNumber__c.
 *  - When exactly one invoice is produced, links OnlinePayment__c and all of its line items to that invoice.
 *
 * Sharing Model: without sharing (ingest/service layer; callers own access control).
 * Dependencies: OnlinePayment__c, OnlinePaymentLineItem__c, Invoice__c, BCAPP_SapInvoiceClearingItem (DTO).
 * SOQL/DML Location: No SOQL in this class; DML (upsert/update) lives here by design.
 * Bulkification: Operates on lists/sets; single upsert call; single updates for parent and lines.
 * Error Handling: Quiet on upsert failures (partial success); updates proceed best-effort.
 * Last Reviewed: 2025-09-02
 */
public without sharing class BCAPP_SapInvoiceIngestService {

    private static final BCAPP_SapInvoiceIngestService INST = new BCAPP_SapInvoiceIngestService();
    public static BCAPP_SapInvoiceIngestService getInstance() { return INST; }
    private BCAPP_SapInvoiceIngestService() {}

    /** Safely parse a date string; returns null on blank/invalid. */
    private static Date toDate(String s) {
        try { return String.isBlank(s) ? null : Date.valueOf(s); } catch (Exception e) { return null; }
    }
    /** Safely parse a decimal string; returns null on blank/invalid. */
    private static Decimal toDec(String s) {
        try { return String.isBlank(s) ? null : Decimal.valueOf(s); } catch (Exception e) { return null; }
    }

    /**
     * Upsert Invoice__c from SAP response (Misc flow), then attach:
     *  - OnlinePayment__c.Invoice__c (if exactly one invoice returned)
     *  - All OnlinePaymentLineItem__c.Invoice__c (if exactly one invoice returned)
     *
     * Idempotent on Invoice__c via External ID: SAPInvoiceNumber__c
     *
     * @param payment      Parent OnlinePayment__c for context/currency/account link
     * @param paymentLines All line items under the given payment (optional)
     * @param sapItems     SAP clearing items to map into Invoice__c
     */
    public void createMiscInvoicesFromSapResponse(
        OnlinePayment__c payment,
        List<OnlinePaymentLineItem__c> paymentLines,
        List<BCAPP_SapInvoiceClearingItem> sapItems
    ) {
        if (payment == null || sapItems == null || sapItems.isEmpty()) return;

        // 1) Build invoices for upsert
        List<Invoice__c> upsertInvoices = new List<Invoice__c>();
        Set<String> invoiceNumbers = new Set<String>();

        for (BCAPP_SapInvoiceClearingItem s : sapItems) {
            if (s == null || String.isBlank(s.Invoice)) continue;

            Invoice__c inv = new Invoice__c();

            // ---- Idempotency key ----
            inv.SAPInvoiceNumber__c = s.Invoice; // External ID
            invoiceNumbers.add(s.Invoice);

            // ---- Mappings (as provided) ----
            inv.Name                   = s.Invoice;              // Invoice Name
            inv.CompanyCode__c         = s.Bukrs;                // Company Code
            inv.CustomerNumber__c      = s.Buyer;                // Customer Number
            inv.SAPContractNumber__c   = s.Contract;             // SAP Contract Number
            inv.Status__c              = s.Status;               // Status ("Paid")
            inv.InvoiceYear__c         = s.FiscalYear;           // Invoice Year (Text)
            inv.TotalAmount__c         = toDec(s.Amount);        // Total Amount
            inv.DueAmount__c           = (s.Status == 'Paid' ? 0 : toDec(s.Amount)); // heuristic
            inv.PostingDate__c         = toDate(s.VerifiedDate); // Posting Date
            inv.ClearedDate__c         = toDate(s.DueDate);      // Clearing Date
            inv.InvoiceDate__c         = toDate(s.VerifiedDate); // Invoice Date
            inv.InvoiceDescription__c  = s.MsgTxt;               // Description
            inv.SAPAssignment__c       = s.RefDoc;               // SAP Assignment (from RefDoc)

            // Currency + Account from payment
            inv.CurrencyIsoCode        = payment.CurrencyIsoCode;
            inv.Account__c             = payment.Account__c;
			inv.DocumentType__c = 'DR';
            upsertInvoices.add(inv);
        }

        if (upsertInvoices.isEmpty()) return;

        // 2) Upsert and collect created/updated Ids by SAPInvoiceNumber__c
        Map<String, Id> invNumToId = new Map<String, Id>();
        Database.UpsertResult[] results = Database.upsert(
            upsertInvoices, Invoice__c.Fields.SAPInvoiceNumber__c, /* allOrNone */ false
        );
        for (Integer i = 0; i < results.size(); i++) {
            Database.UpsertResult r = results[i];
            // Continue on individual failures (quiet policy)
            if (r.isSuccess()) {
                String invNum = upsertInvoices[i].SAPInvoiceNumber__c;
                invNumToId.put(invNum, r.getId());
            }
        }
        if (invNumToId.isEmpty()) return;

        // 3) If exactly one invoice returned, attach payment + all line items to that invoice
        if (invNumToId.size() == 1) {
            Id theInvoiceId = invNumToId.values()[0];

            // Update OnlinePayment__c.Invoice__c
            OnlinePayment__c payUpdate = new OnlinePayment__c(
                Id = payment.Id,
                Invoice__c = theInvoiceId
            );

            // Update all line items
            List<OnlinePaymentLineItem__c> lineUpdates = new List<OnlinePaymentLineItem__c>();
            if (paymentLines != null && !paymentLines.isEmpty()) {
                for (OnlinePaymentLineItem__c li : paymentLines) {
                    if (li == null) continue;
                    lineUpdates.add(new OnlinePaymentLineItem__c(
                        Id = li.Id,
                        Invoice__c = theInvoiceId
                    ));
                }
            }

            // DML (best-effort, logic unchanged)
            update payUpdate;
            if (!lineUpdates.isEmpty()) update lineUpdates;
        }
        // Multiple invoices: ambiguous → intentionally skip linking (unchanged).
    }
}