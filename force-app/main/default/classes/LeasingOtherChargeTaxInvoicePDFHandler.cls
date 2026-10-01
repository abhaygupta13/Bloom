public with sharing class LeasingOtherChargeTaxInvoicePDFHandler {
    
    public String invoiceNo { get; set; }
    public String invoiceDate { get; set; }
    public String supplyDate { get; set; }
    public String dueDate { get; set; }
    
    public String customerName { get; set; }
    public String customerVat { get; set; }
    public String propertyName { get; set; }
    
    public Decimal amount { get; set; }
    public Decimal vatAmount { get; set; }
    public Decimal totalAmount { get; set; }
    public String description { get; set; }
    public String amountInWords { get; set; }
    public String customerAccNumber { get; set; }
    public String leasingCompanyName {get; set;}
    public String VATRegNo {get; set;}
    public String bankAccName {get; set;}
    public String bankName {get; set;}
    public String accNumber {get; set;}
    public String IBAN {get; set;}
    public String swiftCode {get; set;}
    public String unit {get; set;}
    
    public Boolean hasError { get; set; }
    public String errorMessage { get; set; }
    
    private static final Decimal VAT_PERCENT = 5;
    public Decimal vatRate { get; set; }
    public Boolean showVat { get; set; }
    private static final String DOC_NAME = 'Tax Invoice';

    public LeasingOtherChargeTaxInvoicePDFHandler() {
        hasError = false;
        errorMessage = '';
        Id ocId = ApexPages.currentPage().getParameters().get('id');
        if (ocId == null) return;
        
        LeasingOrdersOtherCharges__c oc = LeasingOtherChargesService.getInstance().getOtherChargesById(ocId) ;
        
        if (oc == null || String.isBlank(oc.RefDocno__c)) {
            hasError = true;
            errorMessage = Label.BL_TaxInvoiceOtherChargeNotSynced;
            return;
        }
        
        invoiceNo   = oc.RefDocno__c;
        //invoiceDate = formatDate(Date.today());
        invoiceDate = formatDate(oc.DueDate__c);
        supplyDate  = formatDate(oc.DueDate__c);
        dueDate     = formatDate(oc.DueDate__c);
        leasingCompanyName = oc.LeasingOrder__r.Project__r.Leasing_Company__r.Name;
        VATRegNo = oc.LeasingOrder__r.Project__r.Leasing_Company__r.LeasingCompanyVATRegistrationNumber__c;
        
        customerName = oc.LeasingOrder__r.Account__r.Name;
        customerAccNumber = oc.LeasingOrder__r.SAPBPNumber__c;
        //
        customerVat  = oc.LeasingOrder__r.Account__r.TaxRegistrationNumber__c;
        //propertyName = pps.LeasingOrder__r.Property__c;
        propertyName = oc.LeasingOrder__r.PropertyName__c;
        
        amount      = oc.ChargeAmount__c;
        vatRate = (oc.isVATApplied__c && oc.LeasingOrder__r.Project__r.Leasing_Company__r.LeasingVAT__c != null)
                   ? oc.LeasingOrder__r.Project__r.Leasing_Company__r.LeasingVAT__c : 0;
        showVat = oc.isVATApplied__c && vatRate > 0;
        vatAmount = showVat ? (amount * vatRate) / 100 : 0;
        totalAmount = amount + vatAmount;
        
        description   = String.isNotBlank(oc.Note__c) ? oc.Note__c : oc.Type__c +' - ' + supplyDate;
        //amountInWords = totalAmount + ' Only';
        amountInWords = AmountToWordsUtil.convert(totalAmount);
        bankAccName = oc.LeasingOrder__r.Project__r.LeasingBankAccount__r.BeneficiaryNameCorporate__c;
        bankName = oc.LeasingOrder__r.Project__r.LeasingBankAccount__r.BankNameCorporate__c;
        accNumber = oc.LeasingOrder__r.Project__r.LeasingBankAccount__r.AccountNumberCorporate__c;
        IBAN = oc.LeasingOrder__r.Project__r.LeasingBankAccount__r.IBANNoCorporate__c;
        swiftCode = oc.LeasingOrder__r.Project__r.LeasingBankAccount__r.SwiftCodeCorporate__c;
        unit = oc.LeasingOrder__r.Unit__r.LeasingUnitNumber__c;
    }
    private static String formatDate(Date d) {
        return d != null ? d.format() : '';
    }

    @AuraEnabled
    public static String generateAndAttachPdf(Id ocId) {
        LeasingOrdersOtherCharges__c oc = LeasingOtherChargesService.getInstance().getOtherChargesById(ocId);
        if (oc == null || String.isBlank(oc.RefDocno__c)) {
            throw new AuraHandledException(Label.BL_TaxInvoiceOtherChargeNotSynced);
        }
        
        PageReference pdfPage = Page.LeasingOtherChargeTaxInvoice;
        pdfPage.getParameters().put('id', ocId);
        
        Blob pdfBlob;
        if (Test.isRunningTest()) {
            pdfBlob = Blob.valueOf('Test PDF');
        } else {
            pdfBlob = pdfPage.getContent();
        }
        
        Document__c doc = DocumentService.getInstance().getOtherChargeDocumentByName(ocId,DOC_NAME);
        
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Tax Invoice';
        cv.PathOnClient = 'Tax_Invoice.pdf';
        cv.VersionData = pdfBlob;
        
        if (!Test.isRunningTest()) {
            cv.FirstPublishLocationId = doc.Id;
        }
        
        insert cv;
        return cv.Id;
    }
}