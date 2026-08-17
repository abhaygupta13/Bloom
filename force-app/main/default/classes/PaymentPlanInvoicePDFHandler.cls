public with sharing class PaymentPlanInvoicePDFHandler {
    
    public String invoiceNo { get; set; }
    public String invoiceDate { get; set; }
    public String supplyDate { get; set; }
    public String dueDate { get; set; }
    public String EndDate { get; set; }
    
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
    
    private static final Decimal VAT_PERCENT = 5;
    //private static final Decimal VAT_PERCENT = 5;
    public Decimal vatRate { get; set; }
    public Boolean showVat { get; set; }
    private static final String DOC_NAME = 'Tax Invoice';
    
    public PaymentPlanInvoicePDFHandler() {
        
        Id ppsId = ApexPages.currentPage().getParameters().get('id');
        if (ppsId == null) return;
        
        PaymentPlanSchedule__c pps = LeasingPaymentScheduleService.getInstance().getpaymentPlanById(ppsId);
        
        invoiceNo   = pps.RefDocno__c;
        invoiceDate = formatDate(pps.PaymentStartDate__c);
        supplyDate  = formatDate(pps.PaymentStartDate__c)+' - '+formatDate(pps.Schedule_End_Date__c);
        EndDate = formatDate(pps.Schedule_End_Date__c);
        dueDate     = formatDate(pps.PaymentStartDate__c);
        leasingCompanyName = pps.LeasingOrder__r.Project__r.Leasing_Company__r.Name;
        customerVat = pps.LeasingOrder__r.Account__r.TaxRegistrationNumber__c;
        VATRegNo = pps.LeasingOrder__r.Project__r.Leasing_Company__r.LeasingCompanyVATRegistrationNumber__c;
        customerName = pps.LeasingOrder__r.Account__r.Name;
        customerAccNumber = pps.LeasingOrder__r.SAPBPNumber__c;
        propertyName = pps.LeasingOrder__r.PropertyName__c;
        
        amount      = pps.Amount__c;
        vatRate = (pps.isVATApplied__c && pps.LeasingOrder__r.Project__r.Leasing_Company__r.LeasingVAT__c != null)
                   ? pps.LeasingOrder__r.Project__r.Leasing_Company__r.LeasingVAT__c: 0;
        showVat = pps.isVATApplied__c && vatRate > 0;
        vatAmount = showVat ? (amount * vatRate) / 100 : 0;
        System.Debug('amount----' + amount + 'vatAmount' + vatAmount);
        totalAmount = amount + vatAmount;
        
        description = String.isNotBlank(pps.Note__c) ? pps.Note__c : 'Base Rent - ' + supplyDate;
        amountInWords = AmountToWordsUtil.convert(totalAmount);
        bankAccName = pps.LeasingOrder__r.Project__r.LeasingBankAccount__r.BeneficiaryNameCorporate__c;
        bankName = pps.LeasingOrder__r.Project__r.LeasingBankAccount__r.BankNameCorporate__c;
        accNumber = pps.LeasingOrder__r.Project__r.LeasingBankAccount__r.AccountNumberCorporate__c;
        IBAN = pps.LeasingOrder__r.Project__r.LeasingBankAccount__r.IBANNoCorporate__c;
        swiftCode = pps.LeasingOrder__r.Project__r.LeasingBankAccount__r.SwiftCodeCorporate__c;
        unit = pps.LeasingOrder__r.Unit__r.LeasingUnitNumber__c;
    }

    
    @AuraEnabled
    public static String generateAndAttachPdf(Id paymentPlanScheduleId) {
        
        PageReference pdfPage = Page.PaymentPlanTaxInvoicePDF;
        pdfPage.getParameters().put('id', paymentPlanScheduleId);
        
        Blob pdfBlob;
        if (Test.isRunningTest()) {
            pdfBlob = Blob.valueOf('Test PDF');
        } else {
            pdfBlob = pdfPage.getContent();
        }
        
        Document__c doc = DocumentService.getInstance().getPaymentPlanDocumentByName(paymentPlanScheduleId,DOC_NAME);
        
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
    
    private static String formatDate(Date d) {
        return d != null ? d.format() : '';
    }
}