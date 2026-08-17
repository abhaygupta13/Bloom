/***
Class       : ReceiptAllocationService
Author      : Dhanraj
Description : 
TestClass   : ReceiptAllocationServiceTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.       V1.0              13/06/25           Initial Version 
****************************************************************************************************************/

public inherited sharing class ReceiptAllocationService {
    
    private static ReceiptAllocationService instance;
    
    private ReceiptAllocationService() {
    }
    
    public static ReceiptAllocationService getInstance() { 
        if(instance == null) {
            instance = new ReceiptAllocationService();
        }
        return instance;
    }
    
    public List<ReceiptAllocation__c> insertReceiptAllocations(List<ReceiptAllocation__c> receiptAllocationList){
        if(receiptAllocationList != NULL && !receiptAllocationList.isEmpty()){
            insert receiptAllocationList;
        }
        return receiptAllocationList; 
    }
    
    public  List<ReceiptAllocation__c> getReceiptAllocationBySO(Id orderId){
        return [SELECT Id,ReceiptAcknowledgement__c,TypeOfInvoice__c,AmountApplied__c
                FROM   ReceiptAllocation__c WHERE SalesOrder__c = : orderId and  ReceiptAcknowledgement__r.PaymentType__c = 'Transfer of rights - Resale'];
    }
    
    public  List<ReceiptAllocation__c> getAllReceiptAllocationBySO(Id orderId){
        return [SELECT Id,DateOfApplication__c
                FROM   ReceiptAllocation__c WHERE SalesOrder__c = : orderId 
                and DateOfApplication__c  <= :System.today()];
    }
    
    public  List<ReceiptAllocation__c> getReceiptAllocationByInstallment(Set<Id> setInstallmentIds){
        return [SELECT Id,InstallmentLine__c,ReceiptAcknowledgement__c from ReceiptAllocation__c 
                where ReceiptAcknowledgement__c !=null
                And InstallmentLine__c IN : setInstallmentIds];
    }
    
    public List<ReceiptAllocation__c> getReceiptAllocationByOtherChargeIds(Set<Id> otherchargeIds){
        return [SELECT Id,SalesOrderOtherCharges__c,ReceiptAcknowledgement__c from ReceiptAllocation__c 
                where ReceiptAcknowledgement__c !=null
                And SalesOrderOtherCharges__c IN : otherchargeIds];
    }
    
    public List<ReceiptAllocation__c> getReceiptAllocationsByReceiptIds(Set<Id> receiptIds){
        return [SELECT Id, SalesOrderOtherCharges__c, ReceiptAcknowledgement__c, InstallmentLine__c,
                InstallmentLine__r.SAP_Document_No__c, SalesOrderOtherCharges__r.SAP_Document_No__c
                FROM ReceiptAllocation__c WHERE ReceiptAcknowledgement__c != NULL
                AND ReceiptAcknowledgement__c IN : receiptIds];
    }
    
    public List<ReceiptAllocation__c> insertReceiptAllocationsWithoutTrigger(List<ReceiptAllocation__c> receiptAllocationList){
        ReceiptAllocationTriggerHandler.isTriggerDisabled = true;
        if(receiptAllocationList != NULL && !receiptAllocationList.isEmpty()){
            insert receiptAllocationList;
        }
        ReceiptAllocationTriggerHandler.isTriggerDisabled = false;
        return receiptAllocationList; 
    }
    
    public List<ReceiptAllocation__c> updateReceiptAllocationsWithoutTrigger(List<ReceiptAllocation__c> receiptAllocationList){
        ReceiptAllocationTriggerHandler.isTriggerDisabled = true;
        if(receiptAllocationList != NULL && !receiptAllocationList.isEmpty()){
            update receiptAllocationList;
        }
        return receiptAllocationList; 
    }
    
    public List<ReceiptAllocation__c> deleteReceiptAllocationsWithoutTrigger(List<ReceiptAllocation__c> receiptAllocationList){
        ReceiptAllocationTriggerHandler.isTriggerDisabled = true;
        ReceiptAllocationTriggerForDeleteHandler.isTriggerDisabled = true;
        if(receiptAllocationList != NULL && !receiptAllocationList.isEmpty()){
            delete receiptAllocationList;
        }
        return receiptAllocationList; 
    }
    
    public ReceiptAllocation__c createReceiptAllocationObj(Decimal amount, Id installmentId, Id otherChargesId, Id salesOrderId, Id accId){
        ReceiptAllocation__c receiptAllocation = new ReceiptAllocation__c();
        receiptAllocation.AmountApplied__c = amount;
        receiptAllocation.InstallmentLine__c = installmentId;
        receiptAllocation.SalesOrderOtherCharges__c = otherChargesId;
        receiptAllocation.SalesOrder__c = salesOrderId;
        receiptAllocation.Account__c = accId;
        return receiptAllocation;
    }
}