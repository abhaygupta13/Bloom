/***
Class       : InstallmentLineController
Author      : Dhanraj Poojary
Description : 
TestClass   : InstallmentLineControllerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.     version              Date                Details
1.          V1.0              24/11/25
Initial Version 
****************************************************************************************************************/

public class InstallmentLineController {
    public InstallmentLines__c installmentLine { get; set; }  
    public String customerName { get; set; }     
    public String customerAddress { get; set; } 
    public String unitNo { get; set; }
    public String taxInvoiceNo { get; set; }
    public String taxInvoiceDate { get; set; }
    public String dateOfSupply { get; set; }
    public String typeOfSupply { get; set; }
    public String projectName { get; set; }
    public String netTaxableAmount { get; set; }
    public Decimal totalVAT { get; set; }
    public String totalAmountDue { get; set; }
    public String totalAmountPayableInWords { get; set; }
    public String taxableAmount { get; set; }
    public String proformaTaxableAmount {get; set;}
    public Integer slNo { get; set; } 
    public String description { get; set; }
    public String qty { get; set; }
    public String unitPrice { get; set; }
    public String installmentNo { get; set; }
    public String installmentAmt { get; set; }
    public Decimal vatRate { get; set; }
    public String vatAmt { get; set; }
    public String grossAmt { get; set; }
    public String bankAccName { get; set; }
    public String bankName { get; set; }
    public String accNumber { get; set; }
    public String ibanNumber { get; set; }
    public String swiftCode { get; set; }
    public String beneficiaryName { get; set; }
    public String companyName { get; set; }
    public String companyAddress { get; set; }
    public String companyTRN { get; set; }
    
    public InstallmentLineController() {
        Id installmentId = ApexPages.currentPage().getParameters().get('id');
        if (String.isBlank(installmentId)) return;
        companyName = null;
        companyAddress = null;
        companyTRN = null;
        // Fetch Sales Order with installments using your service
        InstallmentLineService service = InstallmentLineService.getInstance();
        installmentLine = service.getInstallmentLinesByIdWithBank(installmentId);
        if (installmentLine == null) return;
        
        // Customer info
        customerName = installmentLine.SalesOrder__r.Account__r.Name;
        Address addr = installmentLine.SalesOrder__r.Account__r.PersonMailingAddress;  
        companyName = installmentLine.SalesOrder__r.Unit__r.Project__r.Company__r.Name != null ? installmentLine.SalesOrder__r.Unit__r.Project__r.Company__r.Name : null;
        String companyaddr = installmentLine.SalesOrder__r.Unit__r.Project__r.Company__r.Address__c;

        if (!String.isBlank(companyaddr)) {
            List<String> parts = companyaddr.split(',');
            List<String> lines = new List<String>();
            
            for (Integer i = 0; i < parts.size(); i++) {
                String line = parts[i].trim();
                if (i + 1 < parts.size()) {
                    line += ', ' + parts[i + 1].trim();
                    i++;
                }
                lines.add(line);
            }            
            companyAddress = String.join(lines, '<br/>');
        } else {
            companyAddress = null;
        }

        companyTRN = installmentLine.SalesOrder__r.Unit__r.Project__r.Company__r.TRN__c != null ? installmentLine.SalesOrder__r.Unit__r.Project__r.Company__r.TRN__c : null;
        if (addr != null) {
            List<String> parts = new List<String>();
            if (String.isNotBlank(addr.street)) {
                parts.add(addr.street);
            }
            if (String.isNotBlank(addr.city)) {
                parts.add(addr.city);
            }
            if (String.isNotBlank(addr.state)) {
                parts.add(addr.state);
            }
            if (String.isNotBlank(addr.postalCode)) {
                parts.add(addr.postalCode);
            }
            if (String.isNotBlank(addr.country)) {
                parts.add(addr.country);
            }  
            customerAddress = String.join(parts, ', ');
        }
        totalAmountDue = '0';
        //proformaTaxableAmount = 0;
        // Populate Tax Invoice metadata
        unitNo = installmentLine.SalesOrder__r.Unit__r.Name;
        taxInvoiceNo = installmentLine.SalesOrder__r.Name;              
        taxInvoiceDate = formatDate(Date.today());               
        dateOfSupply = formatDate(Date.today()); 
        typeOfSupply = (installmentLine.SalesOrder__r.Tax_Percentage__c > 0 ? 'Commercial' : 'Residential');
        projectName = installmentLine.SalesOrder__r.ProjectName__c;
        netTaxableAmount = formatCurrency(installmentLine.InstallmentAmount__c);
        proformaTaxableAmount = formatCurrency(installmentLine.Tax_Amount__c);
        totalVAT = safe(installmentLine.SalesOrder__r.Tax_Percentage__c);
        totalAmountDue = formatCurrency(installmentLine.Inst_Amount_incl_tax__c);
        totalAmountPayableInWords = Utilities.amountInWords(installmentLine.Inst_Amount_incl_tax__c, 'Dirham', 'Fils');
        taxableAmount = formatCurrency(installmentLine.SalesOrder__r.TaxableAmount__c);
        slNo = 1;
        description = installmentLine.Type__c;
        unitNo = installmentLine.SalesOrder__r.Unit__r.Name;
        qty = '1';
        unitPrice = formatCurrency(installmentLine.SalesOrder__r.SellingPrice__c);
        installmentNo = String.valueOf(installmentLine.InstallmentNumber__c);
        installmentAmt = formatCurrency(installmentLine.InstallmentAmount__c);
        vatRate = installmentLine.SalesOrder__r.Tax_Percentage__c;
        vatAmt = formatCurrency(installmentLine.Tax_Amount__c);
        grossAmt = formatCurrency(installmentLine.Inst_Amount_incl_tax__c);
        bankAccName = (installmentLine.Type__c == 'Down Payment' || installmentLine.Type__c == 'Installment') ? installmentLine.SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.Name : installmentLine.Type__c == 'Handover' ? installmentLine.SalesOrder__r.Unit__r.BuildingSectionName__r.HandoverAccountInstallment__r.Name : installmentLine.Type__c == 'Post Handover Installment' ? installmentLine.SalesOrder__r.Unit__r.BuildingSectionName__r.PHPPAccountInstallment__r.Name : '';
        bankName = (installmentLine.Type__c == 'Down Payment' || installmentLine.Type__c == 'Installment') ? installmentLine.SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.BankNameCorporate__c : installmentLine.Type__c == 'Handover' ? installmentLine.SalesOrder__r.Unit__r.BuildingSectionName__r.HandoverAccountInstallment__r.BankNameCorporate__c : installmentLine.Type__c == 'Post Handover Installment' ? installmentLine.SalesOrder__r.Unit__r.BuildingSectionName__r.PHPPAccountInstallment__r.BankNameCorporate__c : '';
        accNumber = (installmentLine.Type__c == 'Down Payment' || installmentLine.Type__c == 'Installment') ? installmentLine.SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.AccountNumberCorporate__c : installmentLine.Type__c == 'Handover' ? installmentLine.SalesOrder__r.Unit__r.BuildingSectionName__r.HandoverAccountInstallment__r.AccountNumberCorporate__c : installmentLine.Type__c == 'Post Handover Installment' ? installmentLine.SalesOrder__r.Unit__r.BuildingSectionName__r.PHPPAccountInstallment__r.AccountNumberCorporate__c : '';
        ibanNumber = (installmentLine.Type__c == 'Down Payment' || installmentLine.Type__c == 'Installment') ? installmentLine.SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.IBANNoCorporate__c : installmentLine.Type__c == 'Handover' ? installmentLine.SalesOrder__r.Unit__r.BuildingSectionName__r.HandoverAccountInstallment__r.IBANNoCorporate__c : installmentLine.Type__c == 'Post Handover Installment' ? installmentLine.SalesOrder__r.Unit__r.BuildingSectionName__r.PHPPAccountInstallment__r.IBANNoCorporate__c : '';
        swiftCode = (installmentLine.Type__c == 'Down Payment' || installmentLine.Type__c == 'Installment') ? installmentLine.SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.SwiftCodeCorporate__c : installmentLine.Type__c == 'Handover' ? installmentLine.SalesOrder__r.Unit__r.BuildingSectionName__r.HandoverAccountInstallment__r.SwiftCodeCorporate__c : installmentLine.Type__c == 'Post Handover Installment' ? installmentLine.SalesOrder__r.Unit__r.BuildingSectionName__r.PHPPAccountInstallment__r.SwiftCodeCorporate__c : '';
        beneficiaryName = (installmentLine.Type__c == 'Down Payment' || installmentLine.Type__c == 'Installment') ? installmentLine.SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.BeneficiaryNameCorporate__c : installmentLine.Type__c == 'Handover' ? installmentLine.SalesOrder__r.Unit__r.BuildingSectionName__r.HandoverAccountInstallment__r.BeneficiaryNameCorporate__c : installmentLine.Type__c == 'Post Handover Installment' ? installmentLine.SalesOrder__r.Unit__r.BuildingSectionName__r.PHPPAccountInstallment__r.BeneficiaryNameCorporate__c : '';
    }
    
    private static Decimal safe(Decimal d) { return d == null ? 0 : d; }
    private static Boolean safe(Boolean val) { return val == null ? false : val; }
    
    public static String formatCurrency(Decimal amount) {
        if (amount == null) return '0.00';
        String amt = String.valueOf(amount.setScale(2, RoundingMode.HALF_UP));
        return amt.replaceAll('(?<=\\d)(?=(\\d{3})+(?!\\d))', ',');
    }
    
    public static String formatDate(Date inputDate) {
        if (inputDate != null)
            return DateTime.newInstance(inputDate.year(), inputDate.month(), inputDate.day()).format('dd-MMM-yy');
        return '';
    }
    
    @AuraEnabled
    public static String generateAndAttachPdf(Id installmentId, String identifier) {
        System.debug('installmentId'+installmentId);
        if (installmentId == null) {
            throw new AuraHandledException('Installment Id is required.');
        }
        
        InstallmentLineService service = InstallmentLineService.getInstance();
        List<InstallmentLines__c> lstInstallmentLine =
            service.getInstallmentLinesWithSalesOrderDetails(installmentId);
        
        if (lstInstallmentLine.isEmpty()) {
            throw new AuraHandledException('No Installment Line found for the provided Id.');
        }
        
        String installmentNumber = lstInstallmentLine[0].Name;
        PageReference pdfPage;
        String fileName;
        String title;
        
        if (identifier == 'salesProformaPDF') {
            pdfPage = Page.SalesProformaInvoicePDF;
            fileName = 'SalesProformaInvoice.pdf';
            title = 'Sales Proforma Invoice - ' + installmentNumber;
        } else if (identifier == 'salesInvoicePDF' || String.isBlank(identifier)) {
            pdfPage = Page.SalesInvoicePDF;
            fileName = 'SalesInvoice.pdf';
            title = 'Sales Invoice - ' + installmentNumber;
        } else {
            throw new AuraHandledException('Invalid PDF identifier.');
        }
        
        pdfPage.getParameters().put('id', installmentId);
        Blob pdfBlob = Test.isRunningTest()
            ? Blob.valueOf('Test PDF Content')
            : pdfPage.getContent();
        
        ContentService objContentService = ContentService.getInstance();
        ContentVersion cv = objContentService.createContentVersion(pdfBlob, fileName, title);
        
        ContentVersion insertedCV = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
            LIMIT 1
        ];
        
        objContentService.createContentDocumentLink(
            insertedCV.ContentDocumentId,
            installmentId,
            'V',
            'AllUsers'
        );
        
        return cv.Id;
    }
}