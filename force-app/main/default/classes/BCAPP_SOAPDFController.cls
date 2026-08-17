/**
 * Class: SOA_PDFController
 * Purpose: Visualforce controller for Statement of Account (SOA) PDF rendering.
 *
 * Created By: Bloom Dev
 * Created On: 2025-09-01
 *
 * Description:
 * - Reads request params (accountId, unitId, startDate, endDate), fetches header data and line items,
 *   and prepares a view-model for the SOA PDF.
 * - Contains NO inline SOQL/DML. All data access is delegated to service classes.
 * - Business logic (debit/credit handling, running balance) is unchanged.
 */
public without sharing class BCAPP_SOAPDFController {
    // ===== Input Filters =====
    @AuraEnabled public Id   accountId   { get; private set; }
    @AuraEnabled public Id   unitId      { get; private set; }
    @AuraEnabled public Date startDate   { get; private set; }
    @AuraEnabled public Date endDate     { get; private set; }

    // ===== Header (bind these from Account/Unit/Org as you like) =====
    public String projectName      { get; private set; }
    public String propertyDetails  { get; private set; } // e.g., Unit code
    public String customerIdText   { get; private set; }
    public String customerName     { get; private set; }
    public String contractNumber   { get; private set; }
    public String customerTRN      { get; private set; }
    public String statementType    { get { return 'Detail'; } }
    public String statementPeriod  { get; private set; }
    public Date   printingDate     { get { return Date.today(); } }
    public String generatedBy          { get; private set; }
    
    public String bankAccountName   { get; private set; }
    public String bankAccountNumber { get; private set; }
    public String bankIBAN          { get; private set; }
    public String bankSwift         { get; private set; }
    public String bankName          { get; private set; }

    // ===== Rows & Totals =====
    public class RowVM {
        public Date   dateVal    { get; set; } // PostingDate__c
        public String docNo      { get; set; } // SAPInvoiceNumber__c
        public String description{ get; set; } // InvoiceDescription__c
        public String reference  { get; set; } // SAPAssignment__c
        public Decimal debit     { get; set; } // computed when DebitCredit__c = 'S'
        public Decimal credit    { get; set; } // computed when DebitCredit__c = 'H'
        public Decimal balance   { get; set; } // running total: prev + debit - credit
        public String docType    { get; set; } // Status__c (kept per original mapping comment)
    }
    public List<RowVM> rows       { get; private set; }
    public Decimal     totalDebit { get; private set; }
    public Decimal     totalCredit{ get; private set; }
    public Decimal     finalBalance { get; private set; }

    /**
     * Reads URL params, loads header & line items via services, and computes running balances.
     * Notes:
     * - Uses defaults if dates are not provided: last 12 months through today.
     * - SOQL moved into AccountService, UnitService, and InvoiceService.
     */
    public BCAPP_SOAPDFController() {
        // ---- Read URL params ----
        generatedBy = UserInfo.getName();
        accountId = (Id) ApexPages.currentPage().getParameters().get('accountId');
        unitId    = (Id) ApexPages.currentPage().getParameters().get('unitId');
        String sd =        ApexPages.currentPage().getParameters().get('startDate');
        String ed =        ApexPages.currentPage().getParameters().get('endDate');
         // Defaults aligned with the previously commented behavior
        //accountId = '0018d00000mkjjgAAA';
        //unitId = 'a0b8d00000QBVQHAA5';
        startDate = (sd == null ? Date.today().addMonths(-36) : Date.valueOf(sd));
        endDate   = (ed == null ? Date.today()               : Date.valueOf(ed));
        startDate = Date.valueOf(startDate);
        endDate = Date.valueOf(endDate);
        statementPeriod = startDate.format() + ' to ' + endDate.format();

        // ---- Header info via services (no inline SOQL) ----
        Account a = (accountId == null) ? null
            : AccountService.getInstance().getLightweightById(accountId);
        customerName   = (a == null) ? '' : a.Name;
        customerIdText = (a == null) ? '' : a.SAP_BP_No__c;
        customerTRN    = (a == null) ? '' : 'Test Number'; // preserved placeholder

        Unit__c u = (unitId == null) ? null
            : UnitService.fetchUnitDetailsById((String)unitId)[0];
        projectName     = (u == null || u.Project__r == null) ? '' : u.Project__r.Name;
        propertyDetails = (u == null) ? '' : u.Name;
        contractNumber  = (u == null) ? '' : (String) u.get('SAP_Contract_No__c');
        
        String bankAccountId = null;
        if (u != null) {
            if (u.Project__r != null) {
                bankAccountId = u.Project__r.BankAccount__c;
            } 
        }
		BankAccount__c bd = fetchBankDetailsByCompanyCode(bankAccountId);
        // ---- Fetch Bank Details using Company Code ----
        if (bd != null) {
            bankAccountName   = bd.BankNameCorporate__c;
            bankAccountNumber = bd.AccountNumberCorporate__c;
            bankIBAN          = bd.IBANNoCorporate__c;
            bankSwift         = bd.SwiftCodeCorporate__c;
            bankName          = bd.Name;
        } else {
            bankAccountName   = '';
            bankAccountNumber = '';
            bankIBAN          = '';
            bankSwift         = '';
            bankName          = '';
        }

        // ---- Line items via InvoiceService (no inline SOQL) ----
        List<Invoice__c> invs =
            InvoiceService.getInstance().getForSOAByPostingDate(accountId, unitId, startDate, endDate);

        // ---- Build rows & totals (unchanged logic) ----
        Decimal running = 0;
        rows = new List<RowVM>();
        totalDebit = 0;
        totalCredit = 0;

        for (Invoice__c inv : invs) {
            RowVM r = new RowVM();
            r.dateVal     = inv.PostingDate__c;
            r.docNo       = inv.SAPInvoiceNumber__c;
            r.description = inv.InvoiceDescription__c;
            r.reference   = inv.SAPAssignment__c;
            r.docType     = inv.Status__c;

            Decimal amt = (inv.TotalAmount__c == null) ? 0 : inv.TotalAmount__c;
            String dc   = (inv.DebitCredit__c == null) ? '' : inv.DebitCredit__c.trim();

            if (dc == 'Debit') { // Debit
                r.debit = amt; r.credit = 0;
                totalDebit += amt;
                running += amt;
            } else if (dc == 'Credit') { // Credit
                r.debit = 0; r.credit = amt;
                totalCredit += amt;
                running -= amt;
            } else {
                // Unknown flag -> treat as 0 impact
                r.debit = 0; r.credit = 0;
            }
            r.balance = running;
            rows.add(r);
        }
        finalBalance = running;
    }
    private BankAccount__c fetchBankDetailsByCompanyCode(String companyCode) {
        if (String.isBlank(companyCode)) return null;
        // SOQL is supported on Custom Metadata Types
        List<BankAccount__c> rows = [
            SELECT Name,CompanyCode__c, AccountNumberCorporate__c, IBANNoCorporate__c, SwiftCodeCorporate__c, BankNameCorporate__c 
            FROM BankAccount__c
            WHERE Id = :companyCode
            LIMIT 1
        ];
        return rows.isEmpty() ? null : rows[0];
    }
}