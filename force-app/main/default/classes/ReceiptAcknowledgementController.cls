/*****************************************************************************************
Class       : ReceiptAcknowledgementController
Author      : Vinay 
Description : 
testClass   : ReceiptAcknowledgementControllerTest
Created Date: 15 Oct 2024
------------------------------------------------------------------------------------------
-- History --
------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.      V1.0             15Oct2024           Initial Version 
2.		V2.0			 13Apr2026			Added method to check Receipt Allocation
*****************************************************************************************/
public class ReceiptAcknowledgementController {
    
    @AuraEnabled
    public static void verifyReceiptAcknowledgement(Id recordId){
        try{
            ReceiptAcknowledgementService objReceiptAcknowledgementService = ReceiptAcknowledgementService.getInstance();
            ReceiptAcknowledgement__c objReceiptAcknowledgement = new ReceiptAcknowledgement__c(Id = recordId, Finance_Verified__c = true, VerifyBy__c = UserInfo.getUserId(), VerifyDate__c = System.Today());
            objReceiptAcknowledgementService.updateReceiptAcknowledgement(objReceiptAcknowledgement);
        }catch(System.exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static Boolean hasReceiptAllocation(Id recordId){
        return [SELECT Id FROM ReceiptAllocation__c WHERE ReceiptAcknowledgement__c = :recordId LIMIT 1].size() > 0;
    }

    @AuraEnabled
    public static String generateAndAttachPdf(Id salesOrderId, String identifier) {
        SalesOrderService service = SalesOrderService.getInstance();
        List<Salesorder__c> salesOrders = service.getSalesOrderWithInstallmentLinesReceiptAllocation(salesOrderId);
        String soNumber = salesOrders[0].Name;
        PageReference pdfPage;
        
        if(identifier=='generateReceipt'){
            pdfPage = Page.ReceiptAcknowledgementPDF; // Replace with your VF page name
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
        cv.Title = 'Receipt Acknowledgment - ' + soNumber;
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
        
        // Constructor
        public SalesOrderWrapper(Salesorder__c so, List<ReceiptAllocation__c> installmentReceipts, List<ReceiptAllocation__c> salesOrderReceipts, Decimal otherChargeAdmFeeAmt, boolean admFeeIncluded, Decimal totalCollectedAmt, Decimal totalBalanceInstallment, Decimal admAmount, String admReceiptReference, Boolean isWaiver, Boolean isADM, Boolean isRegular) {
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
            }
            
            // Wrap the receipts for installment receipts
            for (ReceiptAllocation__c receipt : receiptAllocationMap.values()) {
                this.dueDateFormatted = (receipt.ReceiptAcknowledgement__r.New_Maturity_Date__c != null ? formatDate(receipt.ReceiptAcknowledgement__r.New_Maturity_Date__c) : formatDate(receipt.ReceiptAcknowledgement__r.MaturityDate__c));    
                this.installmentReceiptWrappers.add(new ReceiptWrapper(receipt, otherChargeAdmFeeAmtTEMP, admFeeIncluded, admReceiptReference));
            }
            if(lstDummyReceipts.size() > 0){
                for(ReceiptAllocation__c receipt : lstDummyReceipts){
                    this.installmentReceiptWrappers.add(new ReceiptWrapper(receipt, 0.0, admFeeIncluded, admReceiptReference)); 
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
                this.salesOrderReceiptWrappers.add(new ReceiptWrapper(receipt, otherChargeAdmFeeAmt, admFeeIncluded, admReceiptReference));
            }
            
            if (!admFeeIncluded) {
                for (ReceiptWrapper receiptWrapper : this.installmentReceiptWrappers) {
                    totalAmount += (receiptWrapper.receipt.AmountApplied__c != null) ? receiptWrapper.receipt.AmountApplied__c : 0;
                    totalPendingAmtInstallment +=  (receiptWrapper.receipt.InstallmentLine__r.PendingAmount__c != null) ? receiptWrapper.receipt.InstallmentLine__r.PendingAmount__c : 0;
                    totalAppliedAmtInstallment +=(receiptWrapper.receipt.AmountApplied__c != null) ? receiptWrapper.receipt.AmountApplied__c : 0; 
                    installmentCollectedAmount +=(receiptWrapper.receipt.ReceiptStatus__c == 'Cleared') ? receiptWrapper.receipt.AmountApplied__c : 0;
                }
            }
            
            if (admFeeIncluded) {
                for (ReceiptWrapper receiptWrapper : this.installmentReceiptWrappers) {
                    totalAmount += (receiptWrapper.receipt.AmountApplied__c != null) ? receiptWrapper.receipt.AmountApplied__c : 0;
                    totalPendingAmtInstallment +=  (receiptWrapper.receipt.InstallmentLine__r.PendingAmount__c != null) ? receiptWrapper.receipt.InstallmentLine__r.PendingAmount__c : 0;
                    totalAppliedAmtInstallment +=(receiptWrapper.receipt.AmountApplied__c != null) ? receiptWrapper.receipt.AmountApplied__c : 0;
                    installmentCollectedAmount +=(receiptWrapper.receipt.ReceiptStatus__c == 'Cleared') ? receiptWrapper.receipt.AmountApplied__c : 0;
                }
            }
            
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
        
        public ReceiptWrapper(ReceiptAllocation__c receipt, Decimal otherChargeAdmFeeAmt, Boolean admFeeIncluded, String admReceiptReference) {
            this.receipt = receipt;
            this.installmentdueDateFormatted = formatDate(receipt.InstallmentLine__r.InstallmentDate__c); 
            this.RvDateFormatted = (receipt.ReceiptAcknowledgement__r.New_Maturity_Date__c != null ? formatDate(receipt.ReceiptAcknowledgement__r.New_Maturity_Date__c) : formatDate(receipt.ReceiptAcknowledgement__r.MaturityDate__c));    
            this.otherChargedueDateFormatted = formatDate(receipt.SalesOrderOtherCharges__r.Due_Date__c); 
            
            // Adjust the amount only if 'Installment 1' and admFeeIncluded is true
            if (admFeeIncluded && receipt.Applied_To__c == 'Installment 1' && admReceiptReference != null && receipt.Receipt_Reference__c == admReceiptReference) {
                this.adjustedAmount = receipt.ReceiptAcknowledgement__r.Amount__c+ otherChargeAdmFeeAmt;
                receipt.AmountApplied__c =  receipt.AmountApplied__c + otherChargeAdmFeeAmt;
            } 
            else if(admFeeIncluded && receipt.Applied_To__c == 'Installment 1' && admReceiptReference == null){
                this.adjustedAmount = receipt.ReceiptAcknowledgement__r.Amount__c+ otherChargeAdmFeeAmt;
                receipt.AmountApplied__c =  receipt.AmountApplied__c + otherChargeAdmFeeAmt;
            }
            else {
                this.adjustedAmount = receipt.ReceiptAcknowledgement__r.Amount__c;  // No adjustment
            }
        }
    }
    
    public List<SalesOrderWrapper> salesOrderWrapperList { get; set; }

    public ReceiptAcknowledgementController() {
        salesOrderWrapperList = new List<SalesOrderWrapper>();
        String salesorderId = ApexPages.currentPage().getParameters().get('id');
        SalesOrderService service = SalesOrderService.getInstance();
        List<Salesorder__c> salesOrders = service.getSalesOrderWithInstallmentLinesReceiptAllocation(salesorderId);
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
        
        if (salesOrders == null || salesOrders.isEmpty()) {
            return;
        }
        
        isWaiver = salesOrders[0].ADMFeeWaivedAmount__c > 0 && !salesOrders[0].ADM_Fee_Included__c;
        isADM = !isWaiver && salesOrders[0].ADM_Fee_Included__c;
        isRegular = !isWaiver && !isADM;
        
        for (Salesorder__c so : salesOrders) {
            List<InstallmentLines__c> installmentLines = new List<InstallmentLines__c>();
            List<ReceiptAllocation__c> installmentReceipts = new List<ReceiptAllocation__c>();
            List<ReceiptAllocation__c> salesOrderReceipts = new List<ReceiptAllocation__c>(); 
            if (so.InstallmentLines__r != null) {
                for (InstallmentLines__c objInstallment : so.InstallmentLines__r) {
                    mapInstallment.put(objInstallment.id,objInstallment);
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
                    } else if (receipt.SalesOrderOtherCharges__c != null && so.ADM_Fee_Included__c && receipt.Applied_To__c == 'ADM Fee') {
                        otherChargeAdmFeeAmt = receipt.AmountApplied__c;
                        admReceiptReference = receipt.Receipt_Reference__c != null ? receipt.Receipt_Reference__c : null;
                    }
                    else if (receipt.SalesOrderOtherCharges__c != null && so.ADM_Fee_Included__c && receipt.Applied_To__c!='ADM Fee') {
                        salesOrderReceipts.add(receipt);
                        otherChargeAdmFeeAmt = receipt.AmountApplied__c;
                    }
                    if (receipt.SalesOrderOtherCharges__c != null && receipt.Applied_To__c == 'ADM Fee' && so.ADMFeeWaivedAmount__c == 0){
                        admFee += receipt.AmountApplied__c;
                    }
                }
            }
            for (Id installmentId : mapInstallment.keySet()) {
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
            }
            // Pass the list of receipts to the wrapper class constructor
            salesOrderWrapperList.add(new SalesOrderWrapper(so,installmentReceipts, salesOrderReceipts, otherChargeAdmFeeAmt, admFeeIncluded, collectedAmount, totalBalanceInstallment, admFee, admReceiptReference, isWaiver, isADM, isRegular));
        }
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
}