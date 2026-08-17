/**
 * InvoiceTriggerHelper
 * Layer: Trigger Helper
 * Purpose: Resolve Account__c / Unit__c lookups for new invoices using same-record keys.
 * Notes: No SOQL/DML here; delegates queries to selector services and DML to InvoiceService.
 */
public without sharing class InvoiceTriggerHelper {

    /**
     * Populates Invoice__c.Account__c and Invoice__c.Unit__c based on same-record keys.
     * - Account:  CustomerNumber__c  → Account.AccountNumber
     * - Unit:     SAPUnitNumber__c   → Unit__c.SAPUnitNumber__c
     */
    public static void upsertLookupsForNewInvoices(List<Invoice__c> newInvoices) {
        if (newInvoices == null || newInvoices.isEmpty()) return;

        // Gather keys (only where lookups are blank)
        Set<String> custNums = new Set<String>();
        Set<String> unitNums = new Set<String>();

        for (Invoice__c inv : newInvoices) {
            if (inv.Account__c == null && String.isNotBlank(inv.CustomerNumber__c)) {
                custNums.add(inv.CustomerNumber__c.trim());
            }
            if (inv.Unit__c == null && String.isNotBlank(inv.SAPUnitNumber__c)) {
                unitNums.add(inv.SAPUnitNumber__c.trim());
            }
        }
        if (custNums.isEmpty() && unitNums.isEmpty()) return;

        // Lookups via selectors
        Map<String, Id> acctByNumber = AccountService.byAccountNumber(custNums);
        Map<String, Id> unitBySapNum  = UnitService.bySapUnitNumber(unitNums);

        // Build minimal updates
        List<Invoice__c> updates = new List<Invoice__c>();
        for (Invoice__c inv : newInvoices) {
            Boolean changed = false;
            Invoice__c upd = new Invoice__c(Id = inv.Id);
            if (inv.SAPUniqueKey__c  == null || String.isNotBlank(inv.SAPUniqueKey__c )) {
                upd.SAPUniqueKey__c = inv.CompanyCode__c+'/'+inv.SAPInvoiceNumber__c+'/'+inv.InvoiceYear__c;
                upd.Name = inv.CompanyCode__c+'/'+inv.SAPInvoiceNumber__c+'/'+inv.InvoiceYear__c;
                changed = true;
            }
            if (inv.Account__c == null && String.isNotBlank(inv.CustomerNumber__c)) {
                Id aId = acctByNumber.get(inv.CustomerNumber__c.trim());
                if (aId != null) { upd.Account__c = aId; changed = true; }
            }
            if (inv.Unit__c == null && String.isNotBlank(inv.SAPUnitNumber__c)) {
                Id uId = unitBySapNum.get(inv.SAPUnitNumber__c.trim());
                if (uId != null) { upd.Unit__c = uId; changed = true; }
            }
            if (changed) updates.add(upd);
        }

         if (!updates.isEmpty()) {
            InvoiceService.getInstance().updateLookupsPartial(updates);
        }
    }
}