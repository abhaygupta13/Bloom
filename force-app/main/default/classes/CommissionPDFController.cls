/*****************************************************************************************
Class       : CommissionPDFController 
Author      : Vikas Baliyan
Description : Commission PDF Controller 
Test Class  : 
Created Date: 18 NOV 2024 
*****************************************************************************************/

public class CommissionPDFController {
    public List<InvoiceLineItem> invoiceLineItems { get; set; }//using in vf page
    public String totalAmount { get; set; }
    public String totalvatAmount { get; set; }
    public String totalAmountWithVAT { get; set; }
    public String amountInWords {get; set;}
    public String totalSellingPrice {get; set;}
    public Decimal vatPercentage {get; set;}
    private List<ContentVersion> contentVersionList;
    private static final string BROKER_COMMISSION_ID_STRING { get { return 'brokerCommissionId'; } }
    private static final string FIRST_COMMISSION_STRING { get { return 'First Commission'; } }
    private static final string SECOND_COMMISSION_STRING { get { return 'Second Commission'; } }
    private static final string FULL_PAYMENT_STRING { get { return 'Full Payment'; } }
    
    // NEW: Bank Account properties
    public String bankName { get; set; }
    public String accountName { get; set; }
    public String accountNumber { get; set; }
    public String ibanNumber { get; set; }
    public String swiftCode { get; set; }

    // NEW: Authorized Signatory properties
    public String authorizedSignatoryName { get; set; }
    public String authorizedSignatoryDesignation { get; set; }

    // NEW: Company Logo properties
    public String companyLogoContentVersionId { get; set; }
    public Boolean hasCompanyLogo { get; set; }

    public CommissionPDFController (){
        BrokerCommissionService objBrokerCommService = BrokerCommissionService.getInstance();
        String commissionInvoiceParamId = ApexPages.currentPage().getParameters().get(BROKER_COMMISSION_ID_STRING);
        
        List<BrokerCommission__c> brokerCommissionList = objBrokerCommService.getBrokerCommissionForPDF(commissionInvoiceParamId);

        invoiceLineItems = new List<InvoiceLineItem>();
        Integer invoiceLine = 1;
        
        // NEW: Initialize bank details (will be populated from first record)
        initializeBankDetails(brokerCommissionList);
        initializeAuthorizedSignatoryDetails(brokerCommissionList);
        initializeCompanyLogo(brokerCommissionList);

        for(BrokerCommission__c bc : brokerCommissionList){
            String projectName = bc.Project__c != null ? bc.Project__r.Name : '';
            String unitNumber = bc.InstallmentLine__c != null && bc.InstallmentLine__r.SalesOrder__c != null && bc.InstallmentLine__r.SalesOrder__r.UnitNumber__c != null ? bc.InstallmentLine__r.SalesOrder__r.UnitNumber__c : '';
            Decimal installmentNumber = bc.InstallmentLine__c != null && bc.InstallmentLine__r.InstallmentNumber__c != null ? bc.InstallmentLine__r.InstallmentNumber__c : 0;
            Decimal netAmountWithoutADMFee = (bc.SalesOrder__r != null) ? (bc.SalesOrder__r.ADM_Fee_Included__c ? bc.SalesOrder__r.Sales_Price_Excluding_ADM__c : bc.SalesOrder__r.NetAmount__c) : 0.00;
            Decimal lineTotal = bc.CommissionAmount__c != null ? bc.CommissionAmount__c : 0.00;
            Decimal vatAmount = lineTotal != null && bc.VATPercentage__c != null && bc.VATPercentage__c != 0 ? (lineTotal * bc.VATPercentage__c/100) : 0.00;
            Decimal totalWithVat = (lineTotal + vatAmount);
            Decimal sellingPrice;

            if((bc.SalesOrder__r.Unit__r.UnitType__c == 'Retail' || bc.SalesOrder__r.Unit__r.UnitType__c == 'Show Room')){
                sellingPrice = bc.SalesOrder__r.SellingPrice__c;
            }
            else{
                Decimal taxableAmount = bc.SalesOrder__r.TaxableAmount__c != null && bc.SalesOrder__r.TaxableAmount__c > 0 ? bc.SalesOrder__r.TaxableAmount__c : 0; 
                sellingPrice = bc.SalesOrder__r.ADM_Fee_Included__c ? bc.SalesOrder__r.Sales_Price_Excluding_ADM__c : (bc.SalesOrder__r.NetAmount__c != null ? (bc.SalesOrder__r.NetAmount__c - taxableAmount) : 0);
            }
            totalSellingPrice = formatAmount(sellingPrice);
            vatPercentage = bc.VATPercentage__c != null ? bc.VATPercentage__c.setScale(2, RoundingMode.HALF_UP) : 0.00;
            amountInWords = Utilities.amountInWords(totalWithVat, 'Dirham','Fils');
            // Determine type of payment based on installment number
            String typeOfPayment = bc.IsFullPayment__c ? FULL_PAYMENT_STRING : (installmentNumber == 1) ? FIRST_COMMISSION_STRING : SECOND_COMMISSION_STRING;
            invoiceLineItems.add(new InvoiceLineItem(invoiceLine, 
                                                    bc.Agency__r != null ? bc.Agency__r.Name : '', 
                                                    (bc.Project__r != null && bc.Project__r.Company__r != null) ? bc.Project__r.Company__r.Name : '', 
                                                    (bc.Project__r != null && bc.Project__r.Company__r != null) ? bc.Project__r.Company__r.Address__c : '',
                                                    (bc.Project__r != null && bc.Project__r.Company__r != null) ? bc.Project__r.Company__r.TRN__c : '',
                                                    bc.Name, 
                                                    bc.Agency__r != null && bc.Agency__r.Is_VAT_Registered__c == 'Yes' ? bc.Agency__r.UAEVATRegisterNumber__c : '',
                                                    projectName, 
                                                    unitNumber, 
                                                    'Commission Invoice', 
                                                    formatAmount(sellingPrice), 
                                                    bc.CommissionPercentage__c, 
                                                    typeOfPayment, 
                                                    formatAmount(lineTotal), 
                                                    formatAmount(vatAmount), 
                                                    formatAmount(totalWithVat)
                                                ));
            
            totalAmount = formatAmount(lineTotal);
            totalvatAmount = formatAmount(vatAmount);
            totalAmountWithVAT = formatAmount(totalWithVat);
            invoiceLine++;        
        }
    }

    private String formatAmount(Decimal amount) {
        if (amount == null) {
            return '0.00';
        }

        String amountStr = amount.setScale(2, RoundingMode.HALF_UP).format();
        if (!amountStr.contains('.')) amountStr += '.00';
        else if (amountStr.split('\\.')[1].length() == 1) amountStr += '0';
        return amountStr;
        //return amount.setScale(2, RoundingMode.HALF_UP).format();
    }


    public class InvoiceLineItem {
        public Integer invoiceLine { get;  set; }
        public String agency { get;  set; }
        public String sellerName { get;  set; }
        public String address { get;  set; }
        public String TRN { get;  set; }
        public String invoiceName { get;  set; }
        public String brokerTRN { get;  set; }
        public String projectName { get;  set; }
        public String unitNumber { get;  set; }
        public String description { get;  set; }
        public String sellingPrice { get;  set; }
        public Decimal commissionPercentage { get;  set; }
        public String typeOfPayment { get;  set; }
        public String totalAmount { get;  set; }
        public String vatAmount { get;  set; }
        public String totalWithVAT { get;  set; }

        public InvoiceLineItem(Integer invoiceLine, String agency, String sellerName, String address, String TRN, String invoiceName, String brokerTRN,  String projectName, String unitNumber, String description, String sellingPrice, Decimal commissionPercentage, String typeOfPayment, String totalAmount, String vatAmount, String totalWithVAT) {
            this.invoiceLine = invoiceLine;
            this.agency = agency;
            this.sellerName = sellerName;
            this.address = address;
            this.TRN = TRN;
            this.invoiceName = invoiceName;
            this.brokerTRN = brokerTRN;
            this.projectName = projectName; 
            this.unitNumber = unitNumber;
            this.description = description;
            this.sellingPrice = sellingPrice;
            this.commissionPercentage = commissionPercentage;
            this.typeOfPayment = typeOfPayment;
            this.totalAmount = totalAmount;
            this.vatAmount = vatAmount;
            this.totalWithVAT = totalWithVAT;
        }
    }

    // NEW: Method to initialize bank details from the first broker commission record
    private void initializeBankDetails(List<BrokerCommission__c> brokerCommissionList) {
        if (brokerCommissionList != null && !brokerCommissionList.isEmpty()) {
            BrokerCommission__c firstRecord = brokerCommissionList[0];
            
            // Check if SalesOrder, Opportunity, Account and BankAccount relationships exist
            if (firstRecord.SalesOrder__r != null &&
                firstRecord.SalesOrder__r.Opportunity__r != null &&
                firstRecord.SalesOrder__r.Opportunity__r.BrokerAgencyAccount__r != null &&
                firstRecord.SalesOrder__r.Opportunity__r.BrokerAgencyAccount__r.BankAccount__r != null) {
                    
                    bankName     = firstRecord.SalesOrder__r.Opportunity__r.BrokerAgencyAccount__r.BankAccount__r.Name;
                    accountName  = firstRecord.SalesOrder__r.Opportunity__r.BrokerAgencyAccount__r.BankAccount__r.BeneficiaryNameCorporate__c;
                    accountNumber= firstRecord.SalesOrder__r.Opportunity__r.BrokerAgencyAccount__r.BankAccount__r.AccountNumberCorporate__c;
                    ibanNumber   = firstRecord.SalesOrder__r.Opportunity__r.BrokerAgencyAccount__r.BankAccount__r.IBANNoCorporate__c;
                    swiftCode    = firstRecord.SalesOrder__r.Opportunity__r.BrokerAgencyAccount__r.BankAccount__r.SwiftCodeCorporate__c;
                } else {
                    // Set default empty values if no bank account found
                    bankName = '';
                    accountName = '';
                    accountNumber = '';
                    ibanNumber = '';
                    swiftCode = '';
                }
        }
    }

    // NEW: Method to initialize authorized signatory details
    private void initializeAuthorizedSignatoryDetails(List<BrokerCommission__c> brokerCommissionList) {
        if (brokerCommissionList != null && !brokerCommissionList.isEmpty()) {
            BrokerCommission__c firstRecord = brokerCommissionList[0];
            
            if (firstRecord.SalesOrder__r != null &&
                firstRecord.SalesOrder__r.Opportunity__r != null &&
                firstRecord.SalesOrder__r.Opportunity__r.BrokerAgencyAccount__r != null) {
                    
                    String agencyId = firstRecord.SalesOrder__r.Opportunity__r.BrokerAgencyAccount__r.Id;
                    List<Contact> authorizedSignatories = ContactService.getInstance().getBrokerAuthSignContactsByAccount(agencyId);
                    
                    
                    if (!authorizedSignatories.isEmpty()) {
                        Contact signatory = authorizedSignatories[0];
                        authorizedSignatoryName = signatory.Name;
                        authorizedSignatoryDesignation = signatory.Designation__c;
                    } else {
                        // Set default empty values if no authorized signatory found
                        authorizedSignatoryName = '';
                        authorizedSignatoryDesignation = '';
                    }
                }
        }
    }

    // NEW: Method to initialize company logo
    private void initializeCompanyLogo(List<BrokerCommission__c> brokerCommissionList) {
        if (brokerCommissionList != null && !brokerCommissionList.isEmpty()) {
            BrokerCommission__c firstRecord = brokerCommissionList[0];
            
            if (firstRecord.SalesOrder__r != null &&
                firstRecord.SalesOrder__r.Opportunity__r != null &&
                firstRecord.SalesOrder__r.Opportunity__r.BrokerAgencyAccount__r != null) {
                    
                    Id agencyId = firstRecord.SalesOrder__r.Opportunity__r.BrokerAgencyAccount__r.Id;
                    
                    DocumentService docService = DocumentService.getInstance();
                    List<Document__c> docList = docService.getDocumentByAccountIdAndName(agencyId, 'Company Logo');
                    
                    if (!docList.isEmpty()) {
                        companyLogoContentVersionId = docList[0].Content_Version_Id__c;
                        hasCompanyLogo = true;
                    } else {
                        companyLogoContentVersionId = null;
                        hasCompanyLogo = false;
                    }
                } else {
                    // No valid account found
                    companyLogoContentVersionId = null;
                    hasCompanyLogo = false;
                }
        }
    }

}