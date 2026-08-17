/**
Class       : SalesReceiptController
Author      : Dhanraj Poojary
Description :
TestClass   : SalesReceiptControllerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version    ¯          Date                Details
1.          V1.0              20/11/25           Initial Version 
****************************************************************************************************************/
public class SalesReceiptController {
    
    public class ReceiptWrapper {
        public ReceiptAllocation__c receipt { get; set; }
        public Decimal adjustedAmount { get; set; }
        public Decimal collectedAmount { get; set; }
        public String installmentDueDateFormatted { get; set; }
        public String rvDateFormatted { get; set; }
        public String otherChargeDueDateFormatted { get; set; }
        public String remitterName { get; set; }
        
        public ReceiptWrapper(ReceiptAllocation__c r,Boolean admFeeIncluded,Map<String, Decimal> admMap,String accountName) {
            receipt = r;
            Set<String> validStatuses = new Set<String>{ 'Cleared', 'Received' };
                
                installmentDueDateFormatted = Utility.formatDate(r.InstallmentLine__r != null ? r.InstallmentLine__r.Due_Date__c : null);
            
            Date rvDate = r.ReceiptAcknowledgement__r.MaturityDate__c;
            rvDateFormatted = Utility.formatDate(rvDate);
            
            otherChargeDueDateFormatted = Utility.formatDate(r.SalesOrderOtherCharges__r != null ? r.SalesOrderOtherCharges__r.Due_Date__c : null);
            
            Decimal baseAmount = Utility.getOrDefault(r.AmountApplied__c);
            Decimal admAmount = 0;
            
            if (admFeeIncluded && r.InstallmentLine__r != null && r.InstallmentLine__r.InstallmentNumber__c == 1 && r.Receipt_Reference__c != null && admMap != null && admMap.containsKey(r.Receipt_Reference__c)) {
                admAmount = admMap.get(r.Receipt_Reference__c);
            }
            adjustedAmount = baseAmount + admAmount;
            if (validStatuses.contains(r.ReceiptStatus__c)) {
                collectedAmount = baseAmount + admAmount;
            } else {
                collectedAmount = 0;
            }
            remitterName =(r.ReceiptAcknowledgement__r != null && !String.isBlank(r.ReceiptAcknowledgement__r.RemitterName__c)) ? r.ReceiptAcknowledgement__r.RemitterName__c : accountName;
        }
    }
    
    public class SalesOrderWrapper {
        public Salesorder__c salesOrder { get; set; }
        public String todayDate { get; set; }
        public List<ReceiptWrapper> installmentReceiptWrappers { get; set; }
        public List<ReceiptWrapper> salesOrderReceiptWrappers { get; set; }
        public Decimal totalCollectedAmt { get; set; }
        public Decimal totalPercentage { get; set; }
        public String totalAmountInWords { get; set; }
        public Decimal installmentCollectedTotal { get; set; }
        public Decimal otherChargesCollectedTotal { get; set; }
        public Decimal installmentAmountTotal { get; set; }
        public Decimal otherChargesAmountTotal { get; set; }
        
        private Set<Id> countedInstallmentIds;
        
        public SalesOrderWrapper(Salesorder__c so) {
            salesOrder = so;
            todayDate = Date.today().format();
            installmentReceiptWrappers = new List<ReceiptWrapper>();
            salesOrderReceiptWrappers = new List<ReceiptWrapper>();
            totalCollectedAmt = 0;
            totalPercentage = 0;
            countedInstallmentIds = new Set<Id>();
            installmentCollectedTotal = 0;
            otherChargesCollectedTotal = 0;
            installmentAmountTotal = 0;
otherChargesAmountTotal = 0;
            
            Boolean admIncluded = Utility.getOrDefault(so.ADM_Fee_Included__c);
            Map<String, Decimal> admMap = new Map<String, Decimal>();
            Set<String> installmentReceiptRefs = new Set<String>();
            List<ReceiptAllocation__c> installmentReceipts = new List<ReceiptAllocation__c>();
            List<ReceiptAllocation__c> otherChargeReceipts = new List<ReceiptAllocation__c>();
            
            if (so.ReceiptAllocations__r != null) {
                for (ReceiptAllocation__c r : so.ReceiptAllocations__r) {
                    if (Utility.getOrDefault(r.AmountApplied__c) == 0) continue;
                    
                    Boolean isADMCharge = r.InstallmentNumberOrChargeType__c == 'ADM Fee' || r.InstallmentNumberOrChargeType__c == 'ADM';
                    
                    if (r.InstallmentLine__c != null && !isADMCharge) {
                        installmentReceipts.add(r);
                        if (r.Receipt_Reference__c != null) {
                            installmentReceiptRefs.add(r.Receipt_Reference__c);
                        }
                    }
                    else if (r.SalesOrderOtherCharges__c != null) {
                        otherChargeReceipts.add(r);
                    }
                }
            }
            
            if (admIncluded) {
                for (ReceiptAllocation__c r : otherChargeReceipts) {
                    Boolean isADMCharge = r.InstallmentNumberOrChargeType__c == 'ADM Fee' || r.InstallmentNumberOrChargeType__c == 'ADM';
                    
                    if (isADMCharge && r.Receipt_Reference__c != null && installmentReceiptRefs.contains(r.Receipt_Reference__c)) {
                        admMap.put(r.Receipt_Reference__c, Utility.getOrDefault(r.AmountApplied__c));
                    }
                }
            }
            
            for (ReceiptAllocation__c r : installmentReceipts) {
                ReceiptWrapper rw = new ReceiptWrapper(r, admIncluded, admMap, so.AccountName__c);
                
                installmentReceiptWrappers.add(rw);
                installmentAmountTotal += r.InstallmentAmountOtherChargeAmount__c;
                installmentCollectedTotal += rw.collectedAmount;
                totalCollectedAmt += rw.collectedAmount;
                
                if (r.InstallmentLine__c != null && !countedInstallmentIds.contains(r.InstallmentLine__c)) {
                    countedInstallmentIds.add(r.InstallmentLine__c);
                    totalPercentage += Utility.getOrDefault(r.InstallmentLine__r.InstallmentPercentage__c);
                }
            }
            
            for (ReceiptAllocation__c r : otherChargeReceipts) {
                Boolean isADMCharge = r.InstallmentNumberOrChargeType__c == 'ADM Fee' || r.InstallmentNumberOrChargeType__c == 'ADM';
                Boolean mergedADM = admIncluded && isADMCharge && r.Receipt_Reference__c != null && admMap.containsKey(r.Receipt_Reference__c);
                if (mergedADM) continue;
                ReceiptWrapper rw = new ReceiptWrapper(r, false, null, so.AccountName__c);
                salesOrderReceiptWrappers.add(rw);
                otherChargesAmountTotal += r.InstallmentAmountOtherChargeAmount__c;
                otherChargesCollectedTotal += rw.collectedAmount;
                totalCollectedAmt += rw.collectedAmount;
            }
            
            totalAmountInWords = Utilities.amountInWords(totalCollectedAmt, 'Dirham', 'Fils');
        }
    }
    
    public List<SalesOrderWrapper> salesOrderWrapperList { get; set; }
    
    public SalesReceiptController() {
        salesOrderWrapperList = new List<SalesOrderWrapper>();
        
        Id salesOrderId = ApexPages.currentPage().getParameters().get('id');
        if (salesOrderId == null) return;
        
        SalesOrderService service = SalesOrderService.getInstance();
        List<Salesorder__c> orders = service.getSalesOrderWithInstallmentLinesReceiptAllocation(salesOrderId);
        
        if (!orders.isEmpty()) {
            salesOrderWrapperList.add(new SalesOrderWrapper(orders[0]));
        }
    }
}