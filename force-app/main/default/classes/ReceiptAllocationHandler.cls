/***
Class       : ReceiptAllocationHandler
Author      : Smaartt
Description : 
TestClass   : Test Class Name
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              27/04/23           Initial Version 
****************************************************************************************************************/
public class ReceiptAllocationHandler {
    private static final string MTD_TOR_CONDITION_TYPE_VALUE { get { return 'TransferOfRightsConditionType'; } }
    
    public class ReceiptModel {
        public String receiptId;
        public String accountName;
        public Id account;
        public String unitNumber;
        public String soNumber;
        public String paymentMode;
        public String chequeNo;
        public String currencyISOCode;
        public String mortageCheque;
        public Date maturityDate;
        public Decimal amount;
        public String bankName;
        public String bankAccountNo;
        public String paidBy;
        public String remarks;
        public List<InvoiceModel> rceiptAllocationList;
        public List<RelationshipModel> relatedAccounts;

        public ReceiptModel(ReceiptAcknowledgement__c receipt, List<InvoiceModel> rceiptAllocationList, List<RelationshipModel> relatedAccounts) {
            this.receiptId = receipt.Id;
            this.accountName = receipt.Account__r.Name;
            this.account = receipt.Account__c;
            this.unitNumber = receipt.SalesOrder__r.Unit__r.Name;
            this.soNumber = receipt.SalesOrder__r.Name;
            this.paymentMode = receipt.PaymentType__c;
            this.chequeNo = receipt.ReferenceNumber__c;
            this.currencyISOCode = receipt.CurrencyISOCode;
            this.mortageCheque = receipt.MortgageCheque__c ? 'Yes' : 'No';
            this.maturityDate = receipt.MaturityDate__c;
            this.amount = receipt.Amount__c;
            this.bankName = receipt.BankName__c;
            this.bankAccountNo = receipt.CustomerBankAccount__c;
            this.paidBy = receipt.PaidBy__c;
            this.remarks = receipt.Remarks__c;
            this.rceiptAllocationList = rceiptAllocationList;
            this.relatedAccounts = relatedAccounts;
        }
    }

    public class RelationshipModel {
        public String label;
        public String value;
        public String accountId;

        public RelationshipModel (String label, String value) {
            this.label = label;
            this.value = label;
            this.accountId = value;
        }
    }
    
    @AuraEnabled(cacheable=false)
    public static String fetchReceiptAlocationByReceiptId(Id receiptId){
     
        ReceiptModel returnReceiptModel;
        ReceiptAcknowledgementService objReceiptAcknowledgementService = ReceiptAcknowledgementService.getInstance();
        List<ReceiptAcknowledgement__c> receiptList = objReceiptAcknowledgementService.getReceiptAckNReceiptAllocationsByReceiptId(new Set<Id>{receiptId});
        List<ReceiptAllocation__c> allocationList;
        Boolean hasUserStartedAllocation = receiptList[0].Receipt_Allocations__r != null && receiptList[0].Receipt_Allocations__r.size() > 0;
        
        if (!receiptList.isEmpty()) {
            if (hasUserStartedAllocation && !receiptList[0].Receipt_Allocations__r.isEmpty()) {
                allocationList = receiptList[0].Receipt_Allocations__r;     
            } else if (hasUserStartedAllocation && receiptList[0].SalesOrder__c != null) {
                allocationList = buildVirtualAllocations(receiptList[0].Account__c,receiptList[0].SalesOrder__c);
            } else {
                allocationList = new List<ReceiptAllocation__c>();
            }
            
            List<InvoiceModel> invoiceModelList = prepareReceiptAllocation(allocationList);
            
            List<RelationshipModel> relatedAccounts = new List<RelationshipModel>();
            relatedAccounts.add(new RelationshipModel(receiptList[0].Account__r.Name, receiptList[0].Account__c));
            relatedAccounts.addAll(getRelatedAccountbyAccountId(receiptList[0].Account__c));
            returnReceiptModel = new ReceiptModel(receiptList[0], invoiceModelList, relatedAccounts);
        }

        return JSON.serialize(returnReceiptModel);
    }
    
    public static List<ReceiptAllocation__c> buildVirtualAllocations(Id accountId,Id salesOrderId) {
        List<ReceiptAllocation__c> virtualList = new List<ReceiptAllocation__c>();
        
        for (InstallmentLines__c inst : [SELECT Id, InstallmentNumber__c, InstallmentAmount__c, PendingAmount__c, SalesOrder__c, SalesOrder__r.Account__c
            FROM InstallmentLines__c WHERE SalesOrder__c = :salesOrderId AND PendingAmount__c > 0]) {
            ReceiptAllocation__c ra = new ReceiptAllocation__c();
            ra.InstallmentLine__c = inst.Id;
            ra.InstallmentLine__r = inst;
            ra.AmountApplied__c = 0;
            ra.SalesOrder__c = inst.SalesOrder__c;
            ra.Account__c = inst.SalesOrder__r.Account__c;
            virtualList.add(ra);
        }
        
        for (SalesOrderOtherCharges__c ch : [SELECT Id, TypeOfCharge__c, Amount__c, PendingAmount__c, SalesOrder__c, Account__c
            FROM SalesOrderOtherCharges__c WHERE SalesOrder__c = :salesOrderId AND PendingAmount__c > 0]) {
            ReceiptAllocation__c ra = new ReceiptAllocation__c();
            ra.SalesOrderOtherCharges__c = ch.Id;
            ra.SalesOrderOtherCharges__r = ch;
            ra.AmountApplied__c = 0;
            ra.SalesOrder__c = ch.SalesOrder__c;
            ra.Account__c = ch.Account__c;   
            virtualList.add(ra);
        } 
        return virtualList;
    }

    public static List<InvoiceModel> prepareReceiptAllocation(List<ReceiptAllocation__c> receiptAllocationList) {
        List<InvoiceModel> invoiceModelList = new List<InvoiceModel>();
        for (ReceiptAllocation__c receiptAllocation: receiptAllocationList) {
            Boolean isInstallment = receiptAllocation.InstallmentLine__c != null;
            String type;
            String no;
            Id installmentOtherChargeId;
            Decimal totalInvoiceAmount = 0;
            
            if (isInstallment) {
                no = String.valueOf(receiptAllocation.InstallmentLine__r.InstallmentNumber__c);
                installmentOtherChargeId = receiptAllocation.InstallmentLine__c;
                totalInvoiceAmount = receiptAllocation.InstallmentLine__r.InstallmentAmount__c;
            } else if (receiptAllocation.SalesOrderOtherCharges__c != null) {
                no = receiptAllocation.SalesOrderOtherCharges__r.TypeOfCharge__c;
                installmentOtherChargeId = receiptAllocation.SalesOrderOtherCharges__c;
                totalInvoiceAmount = receiptAllocation.SalesOrderOtherCharges__r.Amount__c;
            } else {
                continue;
            }
            
            if (isInstallment && receiptAllocation.TypeOfInvoice__c == 'Tax') {
                type = 'Tax';
            } else if (isInstallment) {
                type = 'Installment';
            } else {
                type = 'Other Charge';
            }
            
            Decimal amountApplied = receiptAllocation.AmountApplied__c != null ? receiptAllocation.AmountApplied__c : 0;     
            Decimal outstandingAmount = Math.max(totalInvoiceAmount - amountApplied, 0);       
            invoiceModelList.add(new InvoiceModel(no,type,totalInvoiceAmount,outstandingAmount,receiptAllocation.SalesOrder__c,installmentOtherChargeId,receiptAllocation.Account__r.Name,receiptAllocation.SalesOrder__r.Name,receiptAllocation.SalesOrder__r.Unit__r.Name,amountApplied,receiptAllocation.Id));
        }
        return invoiceModelList;
    }

    public static List<RelationshipModel> getRelatedAccountbyAccountId(Id accountId){
        List<RelationshipModel> relatedAccounts = new List<RelationshipModel>();
        List<AccountRelationship__c> allRelationships = AccountService.getRelatedAccountsForAccountId(accountId);
        for (AccountRelationship__c relationship: allRelationships) {
            relatedAccounts.add(new RelationshipModel(relationship.RelatedAccount__r.Name, relationship.RelatedAccount__c));
        }

        return relatedAccounts;
    }
    
    public class SalesOrderModel {
        @AuraEnabled public String unitName;
        @AuraEnabled public Id salesOrderId;
        @AuraEnabled public String salesOrderName;

        public SalesOrderModel (String unitName, Id salesOrderId, String salesOrderName) {
            this.unitName = unitName;
            this.salesOrderId = salesOrderId;
            this.salesOrderName = salesOrderName;
        }
    }

    @AuraEnabled
    public static String fetchSalesOrderByAccountId(Id accountId){
        List<SalesOrderModel> relatedSalesOrder = new List<SalesOrderModel>();
        List<SalesOrder__c> allSalesOrders = OpportunityService.getSalesOrderByAccountId(new Set<Id>{accountId});
        for (SalesOrder__c salesOrder: allSalesOrders) {
            if (salesOrder.Status__c != Constants.SO_STATUS_CANCELLED && salesOrder.Status__c != Constants.SO_STATUS_CANCELLED_BY_USER &&  salesOrder.Status__c!=Constants.SO_BOOK_STATUS_CANCELLED) {
                relatedSalesOrder.add(new SalesOrderModel(salesOrder.Unit__r.Name, salesOrder.Id, salesOrder.Name));
            }
        }

        return JSON.serialize(relatedSalesOrder);
    }
    
    public class InvoiceModel{
        public String installmentNoOtherCharge;
        public String chargeType;
        public Decimal totalInvoiceAmount;
        public Decimal currentOutstandingAmount;
        public Decimal currentAmountApplied;
        public Decimal amountApplied;
        public Decimal finalOutstandingAmount;
        public Id salesOrderId;
        public Id installmentOtherChargeId;
        public String account;
        public String salesOrder;
        public String unitNumber;
        public Id Id;
        
        public InvoiceModel(String no, String chargeType, Decimal totalInvoiceAmount, Decimal currentOutstandingAmount, Id salesOrderId, Id installmentOtherChargeId, String accountName, String soNumber, String unitNumber, Decimal amountApplied, Id recordId){
            this.installmentNoOtherCharge = no;
            this.chargeType = chargeType;
            this.totalInvoiceAmount = totalInvoiceAmount.setscale(2);
            this.currentOutstandingAmount = currentOutstandingAmount.setscale(2);
            this.salesOrderId = salesOrderId;
            this.installmentOtherChargeId = installmentOtherChargeId;
            this.currentAmountApplied = amountApplied.setscale(2);
            this.amountApplied = amountApplied.setscale(2);
            this.finalOutstandingAmount = currentOutstandingAmount.setscale(2);
            this.account = accountName;
            this.salesOrder = soNumber;
            this.unitNumber = unitNumber;
            this.Id = recordId;
        }
    }
    
    @AuraEnabled(cacheable=false)
    public static String fetchInvoiceForSalesorder(Id SalesOrderId){
        List<InvoiceModel> invoiceModelList = new List<InvoiceModel>();
        InstallmentLineService objInstallmenLines = InstallmentLineService.getInstance();
        SalesOrderOtherChargesService objOtherCharges = SalesOrderOtherChargesService.getInstance();
        MetadataService objMetadataService=MetadataService.getInstance();
        String conditionTypeValue = objMetadataService.getAppSettingTextValue(MTD_TOR_CONDITION_TYPE_VALUE);
        List<String> conditionTypeValueList = conditionTypeValue.split(',');
        List<InstallmentLines__c> installmentLineList = objInstallmenLines.getAllInstallmentLinesBySalesOrderId(SalesOrderId,conditionTypeValueList);
        List<SalesOrderOtherCharges__c> salesOrderOtherChargesList = objOtherCharges.getSalesOrderChargesBySalesOrder(SalesOrderId,conditionTypeValueList);

        if(installmentLineList!=null && !installmentLineList.isEmpty()){
            for(InstallmentLines__c installmentLine: installmentLineList){
                if (installmentLine.PendingAmount__c != null && installmentLine.PendingAmount__c > 0) {
                    invoiceModelList.add(new InvoiceModel(String.valueOf(installmentLine.InstallmentNumber__c), installmentLine.Installment_Type__c=='Tax' ? 'Tax' : 'Installment', installmentLine.InstallmentAmount__c, installmentLine.PendingAmount__c, installmentLine.SalesOrder__c, installmentLine.Id, '', '', '', 0, null));
                }
            }
        }

        if(salesOrderOtherChargesList!=null && !salesOrderOtherChargesList.isEmpty()){
            for(SalesOrderOtherCharges__c otherCharge: salesOrderOtherChargesList){
                if (otherCharge.PendingAmount__c > 0) {
                    invoiceModelList.add(new InvoiceModel(otherCharge.TypeOfCharge__c, 'Other Charge', otherCharge.Amount__c, otherCharge.PendingAmount__c, otherCharge.SalesOrder__c, otherCharge.Id, '', '', '', 0, null));
                }
            }
        }
        
        return JSON.serialize(invoiceModelList);
    }

    public class ReceiptAllocationModel {
        public String Id;
        public String account;
        public String accountId;
        public String salesOrder;
        public String salesOrderId;
        public String unitNumber;
        public String installmentNoOtherCharge;
        public String installmentOtherChargeId;
        public Boolean isInstallment;
        public String chargeType;
        public Decimal totalInvoiceAmount;
        public Decimal currentOutstandingAmount;
        public Decimal currentAmountApplied;
        public Decimal amountApplied;
        public Decimal finalOutstandingAmount;
    }

    @AuraEnabled
    public static string UpdateReceiptAllocation(String receiptAllocations, String receiptId){
        try {
            
            List<ReceiptAllocationModel> receiptAllocationList = (List<ReceiptAllocationModel>)System.JSON.deserialize(receiptAllocations, List<ReceiptAllocationModel>.class);
            List<ReceiptAllocation__c> upsertReceiptAllocationList = new List<ReceiptAllocation__c>();
            for (ReceiptAllocationModel receiptAllocation: receiptAllocationList) {
                ReceiptAllocation__c newReceiptAllocation = new ReceiptAllocation__c();
                if (receiptAllocation.Id != '') {
                    newReceiptAllocation.Id = receiptAllocation.Id;
                    newReceiptAllocation.AmountApplied__c = receiptAllocation.amountApplied;
                } else {
                    if (receiptAllocation.isInstallment) {
                        newReceiptAllocation.InstallmentLine__c = receiptAllocation.installmentOtherChargeId;
                    } else if(receiptAllocation.chargeType=='Tax'){
                        newReceiptAllocation.InstallmentLine__c = receiptAllocation.installmentOtherChargeId;
                    }else{
                       newReceiptAllocation.SalesOrderOtherCharges__c = receiptAllocation.installmentOtherChargeId;

                    }
                    if(receiptAllocation.isInstallment){                       
                        newReceiptAllocation.TypeOfInvoice__c = Constants.INVOICE_TYPE_INSTALLMENT;
                    } else if(receiptAllocation.chargeType=='Tax'){
                        newReceiptAllocation.TypeOfInvoice__c = 'Tax';
                    }else{                        
                     newReceiptAllocation.TypeOfInvoice__c = receiptAllocation.installmentNoOtherCharge;
                    }
                    
                    if(receiptAllocation.installmentNoOtherCharge == Constants.INVOICE_TYPE_ADM){
                        newReceiptAllocation.TypeOfInvoice__c = Constants.INVOICE_TYPE_ADM;
                    }
                    if(receiptAllocation.installmentNoOtherCharge == Constants.BUDGET_LINE_ADMADMINFEE){
                        newReceiptAllocation.TypeOfInvoice__c = Constants.BUDGET_LINE_ADMADMINFEE;
                    }
                    newReceiptAllocation.ReceiptAcknowledgement__c = receiptId;
                    newReceiptAllocation.AmountApplied__c = receiptAllocation.amountApplied;
                    // newReceiptAllocation.CurrencyIsoCode = receiptAllocation.CurrencyIsoCode;
                    newReceiptAllocation.DateOfApplication__c = Date.today();
                    newReceiptAllocation.Account__c = receiptAllocation.accountId;
                    newReceiptAllocation.SalesOrder__c = receiptAllocation.salesOrderId;
                }
                
                upsertReceiptAllocationList.add(newReceiptAllocation);
            }

            if (!upsertReceiptAllocationList.isEmpty()) {
                upsert upsertReceiptAllocationList;
            }
        } catch (Exception ex) {
           
             throw new AuraHandledException(ex.getMessage());
        }
        return 'success';
    }
}