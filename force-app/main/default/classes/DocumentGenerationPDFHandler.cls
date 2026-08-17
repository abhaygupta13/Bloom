public class DocumentGenerationPDFHandler {
    public String totalBalanceInstallment { get; set; }
    
    public class SalesOrderWrapper {
        public Salesorder__c salesOrder { get; set; }
        public String todayDate { get; set; }
        public List<ReceiptWrapper> installmentReceiptWrappers { get; set; } // Changed to wrapper list
        public List<ReceiptWrapper> salesOrderReceiptWrappers { get; set; }  // Changed to wrapper list
        public Decimal totalAmount { get; set; }
        public Decimal totalAmtOtherCharge { get; set; }
        public Decimal totalAppliedAmtOtherCharge { get; set; }
        public Decimal totalPendingAmtOtherCharge { get; set; }
        public Decimal totalPendingAmtInstallment { get; set; }
        public Decimal totalAppliedAmtInstallment { get; set; }
        public Decimal totalBalanceInstallment { get; set; }
        public Decimal installmentCollectedAmount { get; set; }
        public Decimal totalCollectedAmt { get; set; }
        public Decimal admAmount { get; set; }
        public Boolean isWaiver { get; set; }
        public Boolean isADM { get; set; }
        public Boolean isRegular { get; set; }
        public String totalAmountInWords { get; set; }
        public Date dueDate { get; set; }
        public String dueDateFormatted { get; set; }
        public Date OtherchargedueDate { get; set; }
        public String OtherchargedueDateFormatted { get; set; }
        public String bookingDateFormatted { get; set; }
        public boolean admFeeIncludedValue { get; set; }
        public String totalAmountFormatted { get; set; }
        public String admReceiptReference { get; set; }
        public Map<String,Decimal> admMap { get; set; }
        
        // Constructor
        public SalesOrderWrapper(Salesorder__c so, List<ReceiptAllocation__c> installmentReceipts, List<ReceiptAllocation__c> salesOrderReceipts, Decimal otherChargeAdmFeeAmt, boolean admFeeIncluded, Decimal totalCollectedAmt, Decimal totalBalanceInstallment, Decimal admAmount, String admReceiptReference, Boolean isWaiver, Boolean isADM, Boolean isRegular, Map<String,Decimal> admMap) {
            this.salesOrder = so;
            this.installmentReceiptWrappers = new List<ReceiptWrapper>();  // Initialize wrapper list
            this.salesOrderReceiptWrappers = new List<ReceiptWrapper>();
            this.totalAmount = 0;
            this.totalAmtOtherCharge=0;
            this.totalAppliedAmtOtherCharge=0;
            this.totalPendingAmtOtherCharge =0;
            this.totalPendingAmtInstallment=0;
            this.totalAppliedAmtInstallment=0;
            this.installmentCollectedAmount=0;
            this.totalCollectedAmt=totalCollectedAmt;
            this.totalBalanceInstallment=totalBalanceInstallment;
            this.admFeeIncludedValue = admFeeIncluded;
            this.admAmount = admAmount;
            this.admReceiptReference = admReceiptReference;
            this.isWaiver = isWaiver;
            this.isADM = isADM;
            this.isRegular = isRegular;
            DateTime d = DateTime.now();
            this.todayDate = d.format('dd-MMM-yy');
            this.bookingDateFormatted = formatDate(so.BookingDate__c);
            this.admMap = admMap;
            //Changes added by Jhilik
            Decimal otherChargeAdmFeeAmtTEMP = otherChargeAdmFeeAmt;
            Map<String,List<ReceiptAllocation__c>> installmentNumberToReceiptAllocationMap = new Map<String,List<ReceiptAllocation__c>>();
            Map<Id, ReceiptAllocation__c> receiptAllocationMap = new Map<Id, ReceiptAllocation__c>(); 
            List<ReceiptAllocation__c> lstDummyReceipts = new List<ReceiptAllocation__c>();
            
            for (ReceiptAllocation__c receipt : installmentReceipts) {
                if(receipt.Id != null){
                    receiptAllocationMap.put(receipt.Id, receipt);
                    if(!installmentNumberToReceiptAllocationMap.containsKey(receipt.InstallmentNumberOrChargeType__c)){
                        installmentNumberToReceiptAllocationMap.put(receipt.InstallmentNumberOrChargeType__c, new List<ReceiptAllocation__c>());
                    }
                    installmentNumberToReceiptAllocationMap.get(receipt.InstallmentNumberOrChargeType__c).add(receipt);
                }
                else{
                    lstDummyReceipts.add(receipt); 
                }
            }
            
            // Wrap the receipts for installment receipts
            for (ReceiptAllocation__c receipt : receiptAllocationMap.values()) {
                this.dueDateFormatted = (receipt.ReceiptAcknowledgement__r.New_Maturity_Date__c != null ? formatDate(receipt.ReceiptAcknowledgement__r.New_Maturity_Date__c) : formatDate(receipt.ReceiptAcknowledgement__r.MaturityDate__c));    
                this.installmentReceiptWrappers.add(new ReceiptWrapper(receipt, otherChargeAdmFeeAmtTEMP, admFeeIncluded, admReceiptReference, admMap));
            }
            if(lstDummyReceipts.size() > 0){
                for(ReceiptAllocation__c receipt : lstDummyReceipts){
                    this.installmentReceiptWrappers.add(new ReceiptWrapper(receipt, 0.0, admFeeIncluded, admReceiptReference, admMap)); 
                }
            }
            
            // Wrap the receipts for sales order receipts
            for (ReceiptAllocation__c receipt : salesOrderReceipts) {
                this.dueDate = (receipt.ReceiptAcknowledgement__r.New_Maturity_Date__c != null ? receipt.ReceiptAcknowledgement__r.New_Maturity_Date__c : receipt.ReceiptAcknowledgement__r.MaturityDate__c);  // Assign Date fiel 
                this.dueDateFormatted = this.dueDate.format();
                this.dueDateFormatted = DateTime.newInstance(this.dueDate.year(), this.dueDate.month(), this.dueDate.day()).format('dd-MMM-yy');
                this.OtherchargedueDate = receipt.SalesOrderOtherCharges__r.Due_Date__c;
                this.OtherchargedueDateFormatted= this.OtherchargedueDate.format();
                this.OtherchargedueDateFormatted = DateTime.newInstance(this.dueDate.year(), this.OtherchargedueDate.month(), this.OtherchargedueDate.day()).format('dd-MMM-yy');
                this.salesOrderReceiptWrappers.add(new ReceiptWrapper(receipt, otherChargeAdmFeeAmt, admFeeIncluded, admReceiptReference, admMap));
            }
            
            if (!admFeeIncluded) {
                for (ReceiptWrapper receiptWrapper : this.installmentReceiptWrappers) {
                    totalAmount += (receiptWrapper.adjustedAmount  != null) ? receiptWrapper.adjustedAmount  : 0;
                    totalPendingAmtInstallment +=  (receiptWrapper.receipt.InstallmentLine__r.PendingAmount__c != null) ? receiptWrapper.receipt.InstallmentLine__r.PendingAmount__c : 0;
                    totalAppliedAmtInstallment +=(receiptWrapper.adjustedAmount  != null) ? receiptWrapper.adjustedAmount  : 0; 
                    installmentCollectedAmount +=(receiptWrapper.receipt.ReceiptStatus__c == 'Cleared') ? receiptWrapper.adjustedAmount  : 0;
                }
            }
            
            if (admFeeIncluded) {
                for (ReceiptWrapper receiptWrapper : this.installmentReceiptWrappers) {
                    totalAmount += (receiptWrapper.adjustedAmount  != null) ? receiptWrapper.adjustedAmount  : 0;
                    totalPendingAmtInstallment +=  (receiptWrapper.receipt.InstallmentLine__r.PendingAmount__c != null) ? receiptWrapper.receipt.InstallmentLine__r.PendingAmount__c : 0;
                    totalAppliedAmtInstallment +=(receiptWrapper.adjustedAmount  != null) ? receiptWrapper.adjustedAmount  : 0;
                    installmentCollectedAmount +=(receiptWrapper.receipt.ReceiptStatus__c == 'Cleared') ? receiptWrapper.adjustedAmount  : 0;
                }
            }
            
            this.installmentReceiptWrappers.sort(new ReceiptWrapperComparator());
            
            for (ReceiptWrapper receiptWrapper : this.salesOrderReceiptWrappers) {
                totalAmount += (receiptWrapper.receipt.AmountApplied__c != null) ? receiptWrapper.receipt.AmountApplied__c : 0;
                totalAmtOtherCharge += (receiptWrapper.receipt.SalesOrderOtherCharges__r.Amount__c != null) ? receiptWrapper.receipt.SalesOrderOtherCharges__r.Amount__c : 0;
                totalAppliedAmtOtherCharge += (receiptWrapper.receipt.AmountApplied__c != null) ? receiptWrapper.receipt.AmountApplied__c : 0;
                totalPendingAmtOtherCharge +=(receiptWrapper.receipt.SalesOrderOtherCharges__r.PendingAmount__c != null) ? receiptWrapper.receipt.SalesOrderOtherCharges__r.PendingAmount__c : 0;
            }
            
            this.totalAmountFormatted = formatCurrency(totalAmount);
            this.totalAmountInWords = Utilities.amountInWords(totalAmount, 'Dirham', 'Fils');
        }
    }
    
    // Wrapper class for individual receipt formatting
    public class ReceiptWrapper {
        public ReceiptAllocation__c receipt { get; set; }
        public Decimal adjustedAmount { get; set; }
        public String installmentdueDateFormatted { get; set; }     
        public String RvDateFormatted { get; set; }
        public String otherChargedueDateFormatted { get; set; }
        public String admReceiptReference { get; set; }
        public Map<String,Decimal> admMap { get; set; }
        
        public ReceiptWrapper(ReceiptAllocation__c receipt, Decimal otherChargeAdmFeeAmt, Boolean admFeeIncluded, String admReceiptReference, Map<String,Decimal> admMap) {
            this.receipt = receipt;
            this.installmentdueDateFormatted = receipt.InstallmentLine__r.Due_Date__c != null ? formatDate(receipt.InstallmentLine__r.Due_Date__c) : formatDate(receipt.InstallmentLine__r.InstallmentDate__c); 
            this.RvDateFormatted = (receipt.ReceiptAcknowledgement__r.New_Maturity_Date__c != null ? formatDate(receipt.ReceiptAcknowledgement__r.New_Maturity_Date__c) : formatDate(receipt.ReceiptAcknowledgement__r.MaturityDate__c));    
            this.otherChargedueDateFormatted = formatDate(receipt.SalesOrderOtherCharges__r.Due_Date__c); 
            
            // Adjust the amount only if 'Installment 1' and admFeeIncluded is true
            if (admFeeIncluded && receipt.Applied_To__c == 'Installment 1' && admMap.containsKey(receipt.Receipt_Reference__c)) {
                this.adjustedAmount = receipt.ReceiptAcknowledgement__r.Amount__c + admMap.get(receipt.Receipt_Reference__c);
                receipt.AmountApplied__c =  receipt.AmountApplied__c + admMap.get(receipt.Receipt_Reference__c);
            } 
            else {
                this.adjustedAmount = (receipt.AmountApplied__c != null ? receipt.AmountApplied__c : 0);
            }
        }
    }
    
    public class ReceiptWrapperComparator implements Comparator<DocumentGenerationPDFHandler.ReceiptWrapper> {
        public Integer compare(DocumentGenerationPDFHandler.ReceiptWrapper a, DocumentGenerationPDFHandler.ReceiptWrapper b) {
            Integer aInstallment = (a.receipt.InstallmentLine__r != null && a.receipt.InstallmentLine__r.InstallmentNumber__c != null)
                ? Integer.valueOf(a.receipt.InstallmentLine__r.InstallmentNumber__c) : 0;
            
            Integer bInstallment = (b.receipt.InstallmentLine__r != null && b.receipt.InstallmentLine__r.InstallmentNumber__c != null)
                ? Integer.valueOf(b.receipt.InstallmentLine__r.InstallmentNumber__c) : 0;
            
            return aInstallment - bInstallment;
        }
    }
    
    public List<SalesOrderWrapper> salesOrderWrapperList { get; set; }
    
    public DocumentGenerationPDFHandler() {
        salesOrderWrapperList = new List<SalesOrderWrapper>();
        String salesorderId = ApexPages.currentPage().getParameters().get('id');
        List<Salesorder__c> salesOrders = getSalesorderDetailIfo(salesorderId);
        Map<Id,InstallmentLines__c> mapInstallment = new Map<Id,InstallmentLines__c>();
        Decimal otherChargeAdmFeeAmt = 0;
        Boolean admFeeIncluded = salesOrders[0].ADM_Fee_Included__c;
        Boolean isWaiver = false;
        Boolean isADM = false;
        Boolean isRegular = false;
        Decimal collectedAmount = 0;
        Decimal totalBalanceInstallment = 0;
        Set<Id> allocatedInstallmentIds = new Set<Id>();
        Decimal admFee = 0;
        String admReceiptReference = null;
        Set<String> installmentReceiptReferences = new Set<String>();
		List<ReceiptAllocation__c> admFeeReceipts = new List<ReceiptAllocation__c>();
        List<ReceiptAllocation__c> additionalAdmFeeList = new List<ReceiptAllocation__c>();
        Date installment1DueDate;
        Decimal installment1Percent = 0;
        Decimal installment1Amount = 0;
        Id installment1Id;
        Boolean isDeductADMFee = false;
        Map<String,Decimal> admMap = new map<String,Decimal>();
        Decimal combinedOtherChargesvalue = 0;
        
        if (salesOrders == null || salesOrders.isEmpty()) {
            return;
        }
        
        isWaiver = salesOrders[0].ADMFeeWaivedAmount__c > 0 && !salesOrders[0].ADM_Fee_Included__c;
        isADM = !isWaiver && salesOrders[0].ADM_Fee_Included__c;
        isRegular = !isWaiver && !isADM;
        
        for (Salesorder__c so : salesOrders) {
            if (so.ReceiptAllocations__r != null) {
                for (ReceiptAllocation__c receipt : so.ReceiptAllocations__r) {
                    if (receipt.InstallmentLine__c != null && receipt.Receipt_Reference__c != null) {
                        installmentReceiptReferences.add(receipt.Receipt_Reference__c);
                    }
                    if (receipt.Applied_To__c == 'ADM Fee' || receipt.Applied_To__c == 'ADM') {
                        admFeeReceipts.add(receipt);
                    }
                }
            }
        }
        
        if(admFeeReceipts.size() > 1){
            for (ReceiptAllocation__c admReceipt : admFeeReceipts) {
                if (!installmentReceiptReferences.contains(admReceipt.Receipt_Reference__c)) {
                    additionalAdmFeeList.add(admReceipt);
                }
            }
        }
        
        for (Salesorder__c so : salesOrders) {
            List<InstallmentLines__c> installmentLines = new List<InstallmentLines__c>();
            List<ReceiptAllocation__c> installmentReceipts = new List<ReceiptAllocation__c>();
            List<ReceiptAllocation__c> salesOrderReceipts = new List<ReceiptAllocation__c>(); 
            if (so.InstallmentLines__r != null) {
                for (InstallmentLines__c objInstallment : so.InstallmentLines__r) {
                    mapInstallment.put(objInstallment.id,objInstallment);
                    if(objInstallment.InstallmentNumber__c == 1){
                        installment1DueDate = objInstallment.Due_Date__c;
                        installment1Percent = objInstallment.InstallmentPercentage__c;
                        installment1Amount = objInstallment.InstallmentAmount__c;
                        installment1Id = objInstallment.Id;
                    }
                }
            }
            
            if (so.ReceiptAllocations__r != null) {
                for (ReceiptAllocation__c receipt : so.ReceiptAllocations__r) {
                    if (receipt.InstallmentLine__c != null) {
                        allocatedInstallmentIds.add(receipt.InstallmentLine__c);
                    }
                    if(receipt.ReceiptStatus__c == 'Cleared'){
                        collectedAmount += receipt.AmountApplied__c;
                    }
                    if(receipt.ReceiptStatus__c != 'Cleared'){
                        totalBalanceInstallment += receipt.AmountApplied__c;
                    }
                    
                    if (receipt.InstallmentLine__c != null) {
                        installmentReceipts.add(receipt);
                    } 
                    
                    if (receipt.SalesOrderOtherCharges__c != null && !so.ADM_Fee_Included__c) {
                        salesOrderReceipts.add(receipt);
                    } else if (receipt.SalesOrderOtherCharges__c != null && so.ADM_Fee_Included__c && (receipt.Applied_To__c == 'ADM Fee' || receipt.Applied_To__c == 'ADM')) {
                        otherChargeAdmFeeAmt = receipt.AmountApplied__c;
                        admReceiptReference = receipt.Receipt_Reference__c != null ? receipt.Receipt_Reference__c : null;
                        admMap.put(receipt.Receipt_Reference__c,receipt.AmountApplied__c);
                        combinedOtherChargesvalue += receipt.AmountApplied__c;
                    }
                    else if (receipt.SalesOrderOtherCharges__c != null && so.ADM_Fee_Included__c && (receipt.Applied_To__c != 'ADM Fee' || receipt.Applied_To__c != 'ADM')) {
                        salesOrderReceipts.add(receipt);
                        otherChargeAdmFeeAmt = receipt.AmountApplied__c;
                        combinedOtherChargesvalue += receipt.AmountApplied__c;
                    }
                    if (receipt.SalesOrderOtherCharges__c != null && (receipt.Applied_To__c == 'ADM Fee' || receipt.Applied_To__c == 'ADM')){
                        admFee += receipt.AmountApplied__c;
                    }
                }
            }
            if(additionalAdmFeeList.size() > 0){
                for (ReceiptAllocation__c objADMReceipt : additionalAdmFeeList) {
                    ReceiptAllocation__c clonedADMReceipt = objADMReceipt.clone(false, true, false, false);
                    clonedADMReceipt.InstallmentLine__c = installment1Id;
                    clonedADMReceipt.InstallmentLine__r = new InstallmentLines__c(
                        InstallmentDate__c = installment1DueDate,
                        InstallmentAmount__c = installment1Amount,
                        InstallmentPercentage__c = installment1Percent,
                        InstallmentNumber__c = 1
                    );
                    
                    installmentReceipts.add(clonedADMReceipt);
                }
            }
            for (Id installmentId : mapInstallment.keySet()) {
                InstallmentLines__c objInstallment = mapInstallment.get(installmentId);
                
                if (allocatedInstallmentIds != null && !allocatedInstallmentIds.contains(installmentId)) {
                    InstallmentLines__c objIL = mapInstallment.get(installmentId);
                    ReceiptAllocation__c dummyReceipt = new ReceiptAllocation__c();
                    
                    dummyReceipt.InstallmentLine__r = new InstallmentLines__c(
                        InstallmentNumber__c = objIL.InstallmentNumber__c,
                        InstallmentAmount__c = objIL.InstallmentAmount__c,
                        InstallmentPercentage__c = objIL.InstallmentPercentage__c,
                        InstallmentDate__c = objIL.InstallmentDate__c
                    );
                    
                    dummyReceipt.InstallmentLine__c = objIL.Id;
                    dummyReceipt.AmountApplied__c = objIL.InstallmentAmount__c;
                    installmentReceipts.add(dummyReceipt);
                    totalBalanceInstallment += objIL.InstallmentAmount__c;
                }
                else{
                    Decimal totalApplied = 0;
                    for (ReceiptAllocation__c rec : installmentReceipts) {
                        if (rec.InstallmentLine__c == installmentId) {
                            totalApplied += rec.AmountApplied__c;
                        }
                    }
                    
                    if (totalApplied < objInstallment.InstallmentAmount__c) {
                        Decimal unpaidAmount = objInstallment.InstallmentAmount__c - totalApplied;
                        totalBalanceInstallment += unpaidAmount;
                        isDeductADMFee = true;
                    }
                }
            }
            if(admFeeIncluded && combinedOtherChargesvalue > 0 && isDeductADMFee){
                Decimal admApplied = (so.ADM_Fee_Cleared_Amount__c > 0 ? so.ADM_Fee_Cleared_Amount__c : combinedOtherChargesvalue);
                totalBalanceInstallment = totalBalanceInstallment - combinedOtherChargesvalue;
            }
            // Pass the list of receipts to the wrapper class constructor
            salesOrderWrapperList.add(new SalesOrderWrapper(so,installmentReceipts, salesOrderReceipts, otherChargeAdmFeeAmt, admFeeIncluded, collectedAmount, totalBalanceInstallment, admFee, admReceiptReference, isWaiver, isADM, isRegular, admMap));
        }
    }
    
    public static List<Salesorder__c> getSalesorderDetailIfo(Id SalesorderId) {
        return [
            SELECT Id,BookingDate__c,Unit__r.UnitModel__c,Unit__r.ProjectName__c,Unit__r.UnitNumber__c,NetAmount__c,Unit__r.UnitType__c,Account__r.PersonEmail,Account__r.PersonMailingPostalCode,Account__r.Name,Account__r.PersonMobilePhone,Account__r.AccountNumber__c,Account__r.MobileCountryCode__c,Account__r.PersonMailingCity,Account__r.PersonMailingCountry,Name,Account__r.PersonMailingState,Account__r.PersonMailingStreet,SalesOrder__c.UnitNumber__c, ADM_Fee_Included__c,Unit__r.BuildingSectionName__r.Name,Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.BankNameCorporate__c,Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.BeneficiaryNameCorporate__c,
            Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.BranchCorporate__c,Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.AccountNumberCorporate__c,Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.SwiftCodeCorporate__c,Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.IBANNoCorporate__c, Sales_Order_Number__c, SellingPrice__c, ProjectName__c, AccountName__c, Virtual_Bank_Account_Number__c, Virtual_Account_IBAN__c, Sales_Order_Cleared_Amount__c, Net_Amount_excl_ADMWaiver__c, Sales_Price_Excluding_ADM__c,ADMFeeWaivedAmount__c,ADMFeeAmount__c,ADM_Fee_Cleared_Amount__c,
            (SELECT Id,InstallmentDate__c,InstallmentNumber__c,InstallmentAmount__c,Name,InstallmentPercentage__c,PendingAmount__c,LPCAmount__c,Due_Date__c FROM InstallmentLines__r ORDER BY InstallmentNumber__c),
            (SELECT Id, Name,ReceiptStatus__c,Receipt_Reference__c,InstallmentLine__r.InstallmentDate__c,InstallmentLine__r.Due_Date__c,InstallmentLine__r.InstallmentNumber__c,InstallmentLine__r.InstallmentAmount__c,InstallmentLine__r.Name,InstallmentLine__r.InstallmentPercentage__c,InstallmentLine__r.PendingAmount__c,InstallmentLine__r.LPCAmount__c,InstallmentAmountOtherChargeAmount__c,Receipt_Type__c, Applied_To__c, Receipt_Number__c, ReceiptAcknowledgementAmount__c,
             ReceiptAcknowledgement__r.BankName__c,ReceiptAcknowledgement__r.MaturityDate__c,ReceiptAcknowledgement__r.New_Maturity_Date__c,ReceiptAcknowledgement__r.Status__c,ReceiptAcknowledgement__r.Amount__c, 
             InstallmentNumberOrChargeType__c, AmountApplied__c, InstallmentLine__c, SalesOrderOtherCharges__c,SalesOrderOtherCharges__r.Name,SalesOrderOtherCharges__r.Due_Date__c,SalesOrderOtherCharges__r.TypeOfCharge__c,SalesOrderOtherCharges__r.Amount__c,SalesOrderOtherCharges__r.PendingAmount__c FROM ReceiptAllocations__r WHERE ReceiptStatus__c != 'Reversed' Order By InstallmentNumberOrChargeType__c ASC)
            FROM Salesorder__c  
            WHERE Id = :SalesorderId
        ];
    }
    
    
    public static String formatCurrency(Decimal amount) {
        if (amount == null) {
            return '0.00'; // Handle null cases
        }
        
        // Convert the amount to String with two decimal places
        String formattedAmount = String.valueOf(amount.setScale(2, RoundingMode.HALF_UP));
        
        // Format with commas for thousands
        return formattedAmount.replaceAll('(?<=\\d)(?=(\\d{3})+(?!\\d))', ',');
    }
    public static String formatDate(Date inputDate) {
        if (inputDate != null) {
            return DateTime.newInstance(inputDate.year(), inputDate.month(), inputDate.day()).format('dd-MMM-yy');
        }
        return '';
    }
    
    @AuraEnabled
    public static String generateAndAttachPdf(Id salesOrderId,String identifier) {
        List<Salesorder__c> salesOrders = getSalesorderDetailIfo(salesOrderId);
        String soNumber = salesOrders[0].Name;
        String statementFileName = 'Statement'+'-'+salesOrders[0].Name;
        PageReference pdfPage;
        System.debug('identifier'+identifier);
        if(identifier=='generateReceipt'){
            pdfPage = Page.ReceiptAcknowledgementPDF; // Replace with your VF page name
        }else if(identifier=='generateStatement'){
            pdfPage = Page.StatementOfAccountPDF; // Replace with your VF page name
        }
        
        pdfPage.getParameters().put('id', salesOrderId);
        Blob pdfBlob;
        
        if (Test.isRunningTest()) {
            // Return a mock Blob in test context
            pdfBlob = Blob.valueOf('Test PDF Content');
        } else {
            // Actual getContent() call outside test context
            pdfBlob = pdfPage.getContent();
        }
        
        ContentVersion cv = new ContentVersion();
        if(identifier=='generateReceipt'){
            cv.Title = 'Receipt Acknowledgment - ' + soNumber;
        }else if(identifier=='generateStatement'){
            cv.Title = statementFileName;
        }
        cv.PathOnClient = 'ReceiptAcknowledgment.pdf';
        cv.VersionData = pdfBlob;
        cv.IsMajorVersion = true;
        insert cv;
        
        ContentVersion insertedCV = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = insertedCV.ContentDocumentId;
        cdl.LinkedEntityId = salesOrderId;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        
        insert cdl;
        return cv.Id;
    }
    
    public static ContentVersion generateAndAttachDocument(Id parentId, Id documentId, string documentType, string documentName) {
        
        PageReference pdfPage;
        
        if(documentType == 'SALES_RECEIPT'){
            pdfPage = Page.SalesReceiptPDFPage;
        }else if(documentType == 'SALES_SOA'){
            pdfPage = Page.StatementOfAccountPage;
        }else if(documentType == 'SALES_INVOICE'){
            pdfPage = Page.SalesInvoicePDF;
        }else if(documentType == 'SALES_PORFORMA_INVOICE'){
            pdfPage = Page.SalesProformaInvoicePDF;
        }
        
        pdfPage.getParameters().put('id', parentId);
        Blob pdfBlob = Test.isRunningTest() ? Blob.valueOf('Test PDF Content') : pdfPage.getContent();
        
        ContentVersion cv = new ContentVersion();
        cv.Title = documentName;
        cv.PathOnClient = documentName;
        cv.VersionData = pdfBlob;
        cv.IsMajorVersion = true;
        insert cv;
        
        cv = [SELECT Id, Title, PathOnClient, VersionData, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = cv.ContentDocumentId;
        cdl.LinkedEntityId = String.isNotBlank(documentId) ? documentId : parentId;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;
        
        return cv;
    }
}