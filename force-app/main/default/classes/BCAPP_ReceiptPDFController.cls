/**
 * Class: ReceiptPDFController
 * Purpose: Visualforce controller for rendering the Receipt PDF.
 *
 * Created By: Bloom Dev
 * Created On: 2025-09-01
 *
 * Description:
 * - Loads receipt header, related account/unit display fields, and invoice allocations.
 * - Computes formatted amounts and “amount in words” for display.
 * - Contains NO inline SOQL/DML: all data access is delegated to service classes.
 */
public with sharing class BCAPP_ReceiptPDFController {
    // ===== Data exposed to the VF page =====
    public Receipt__c receipt { get; private set; }
    public List<InvoiceAllocation__c> allocations { get; private set; }
    public String cur { get; private set; }
    public String receiptNo { get; private set; }
    public String projectName { get; private set; }
    public String contractNumber { get; private set; }
    public String customerId { get; private set; }
    public String paymentType { get; private set; }
    public String referenceNumber { get; private set; }
    public String amountInWords { get; private set; }

    /** Returns AmountReceived__c formatted to 2dp for display. */
    public String amountReceived2dp {
        get {
            return (receipt != null && receipt.AmountReceived__c != null)
                ? String.valueOf(receipt.AmountReceived__c.setScale(2))
                : '';
        }
    }
    
    public String totalReceived2dp {
        get {
            return (receipt != null && receipt.AmountReceived__c != null)
                ? String.valueOf((receipt.AmountReceived__c + receipt.TechnologyFee__c).setScale(2))
                : '';
        }
    }
	
    public String technologyFee2dp {
        get {
            return (receipt != null && receipt.TechnologyFee__c != null)
                ? String.valueOf(receipt.TechnologyFee__c.setScale(2))
                : '';
        }
    }
    /**
     * Loads receipt, allocations, and header display fields via services.
     * - Expects a 'receiptId' URL parameter.
     * - Derives receiptNo from first allocation (CompanyCode/SAPInvoiceNumber/InvoiceYear) or falls back to Receipt Name.
     */
    public BCAPP_ReceiptPDFController() {
        Id receiptId = (Id) ApexPages.currentPage().getParameters().get('receiptId');

        // ---- Header: Receipt (via service; no inline SOQL) ----
        receipt = ReceiptService.getInstance().getById(receiptId);
		System.debug('receipt.Unit__c '+receipt.Unit__c);
        // ---- Allocations (via service; includes invoice fields used below) ----
        allocations = InvoiceAllocationService.getInstance().getByReceipt(receiptId);

        // Derive display receipt number (fallback to receipt.Name)
        if (!allocations.isEmpty() && allocations[0].Invoice__r != null) {
            String companyCode = (String) allocations[0].Invoice__r.get('CompanyCode__c');
            String sapNo       = (String) allocations[0].Notes__c;
            String invYear     = (String) allocations[0].Invoice__r.get('InvoiceYear__c');
            if (!String.isBlank(companyCode) && !String.isBlank(sapNo) && !String.isBlank(invYear)) {
                receiptNo = sapNo;
            } else {
                receiptNo = receipt != null ? receipt.Name : '';
            }
        } else {
            receiptNo = receipt != null ? receipt.Name : '';
        }

        // Currency (static as per existing behavior)
        cur = 'AED';

        // ---- Related display fields via services ----
        // Account info
        Account acc = (receipt != null && receipt.Account__c != null)
            ? AccountService.getInstance().getLightweightById(receipt.Account__c)
            : null;

        // Unit info
        Unit__c unit = (receipt != null && receipt.Unit__c != null)
            ? UnitService.fetchUnitDetailsById((String) receipt.Unit__c)[0]
            : null;
		System.debug('unit' + unit);
        projectName    = (unit == null) ? '' : (String) unit.get('ProjectName__c');
        contractNumber = (unit == null) ? '' : (String) unit.get('SAP_Contract_No__c');
        customerId     = (acc  == null) ? '' : acc.SAP_BP_No__c;
        paymentType    = (receipt == null) ? '' : receipt.PaymentMode__c;
        referenceNumber= (receipt == null) ? '' : receipt.GatewayReference__c;

        // Amount in words
        amountInWords = getAmountToWords(receipt != null ? receipt.AmountReceived__c + receipt.TechnologyFee__c : null);
    }

    /**
     * Converts a decimal amount to words in AED (“Dirhams” / “Fils”).
     * @param amount Amount to convert
     * @return e.g., "One Hundred Twenty Three Dirhams and Forty Five Fils"
     */
    private String getAmountToWords(Decimal amount) {
       // UAE currency terms
    	return Utilities.amountToWords(amount, 'Dirhams', 'Fils');
    }
}