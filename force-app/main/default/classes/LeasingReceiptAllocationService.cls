/*******************************************************************************************************
Class       : LeasingReceiptAllocationService
Author      : 
Description : 
TestClass   : 
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1        1.0                03-12-2025             Initial draft
****************************************************************************************************************/
public inherited sharing class LeasingReceiptAllocationService {
    private static LeasingReceiptAllocationService instance;
    
    private LeasingReceiptAllocationService() {
        
    }
    
    public static LeasingReceiptAllocationService getInstance() { 
        if(instance == null) {
            instance = new LeasingReceiptAllocationService();
        }
        return instance;
    }

    public List<LeasingReceiptAllocation__c> updateLeasingReceiptAllocations(List<LeasingReceiptAllocation__c> receiptList) {
        if (receiptList != null && !receiptList.isEmpty()) {
            update receiptList;
        }
        return receiptList;
    }
     //insert Allocations without trigger
    public List<LeasingReceiptAllocation__c> insertReceiptAllocationsWithoutTrigger(List<LeasingReceiptAllocation__c> receiptList){
        if(receiptList != NULL && !receiptList.isEmpty()){
            LeasingReceiptAllocationTriggerHandler.isTriggerDisabled = true;
            insert receiptList;
            LeasingReceiptAllocationTriggerHandler.isTriggerDisabled = false;
        }
        return receiptList;
    }
  //insert Allocations without trigger
    public List<LeasingReceiptAllocation__c> insertReceiptAllocations(List<LeasingReceiptAllocation__c> receiptList){
        if(receiptList != NULL && !receiptList.isEmpty()){
            insert receiptList;
        }
        return receiptList;
    }

    public LeasingReceiptAllocation__c updateLeasingReceiptAllocation(LeasingReceiptAllocation__c receipt){
        if(receipt != NULL ){
            receipt = updateLeasingReceiptAllocations(new List<LeasingReceiptAllocation__c>{receipt})[0];
        }
        return receipt;
    }

    public List<LeasingReceiptAllocation__c> getChildAllocations(Set<Id> acknowledgemenIds){
        return [Select Id,SAPReversalDocumentNumber__c, LeasingReceiptAcknowledgment__r.SAPReversalDocumentNumber__c, PaymentPlanSchedule__c,LeasingOrderOtherCharges__c,
                PaymentPlanSchedule__r.Paymentdocumentnumber__c,PaymentPlanSchedule__r.PaymentStatus__c, PaymentPlanSchedule__r.DueAmount__c,LeasingOrderOtherCharges__r.Paymentdocumentnumber__c,
                LeasingOrderOtherCharges__r.PaymentStatus__c, LeasingOrderOtherCharges__r.DueAmount__c, LeasingReceiptAcknowledgment__c
                FROM LeasingReceiptAllocation__c 
                WHERE LeasingReceiptAcknowledgment__c IN : acknowledgemenIds order by CreatedDate ASC
                //AND SAPReversalDocumentNumber__c != Null
                ];
    }
}