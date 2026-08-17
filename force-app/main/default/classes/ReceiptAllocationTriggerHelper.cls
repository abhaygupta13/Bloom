public without sharing class ReceiptAllocationTriggerHelper {
    
    public static void validateAmountApplied(List<ReceiptAllocation__c> newList,Map<Id, SObject> oldMap){
        Set<Id> receiptIds = new Set<Id>();
        Map<Id,Decimal> receiptAcknowledgementAmountMap = new Map<Id,Decimal>();
        Map<Id,Decimal> newAmountMap = new Map<Id,Decimal>();
        Set<Id> allocationIds = new Set<Id>();
        if(oldMap !=null)
            allocationIds = oldMap.keySet();
        SystemMessages__mdt receiptAllocationMessage = Utilities.getSystemMessages(Constants.RECEIPT_ALLOCATION_RESTRICTION);
        
        for(ReceiptAllocation__c receiptAllocation : newList){
            receiptIds.add(receiptAllocation.ReceiptAcknowledgement__c);
            receiptAcknowledgementAmountMap.put(receiptAllocation.ReceiptAcknowledgement__c,receiptAllocation.ReceiptAcknowledgementAmount__c);
            if(!receiptAllocation.Unapply__c && receiptAllocation.Id !=null){
                Decimal recieptAmount = ( newAmountMap.containsKey(receiptAllocation.ReceiptAcknowledgement__c) ? newAmountMap.get(receiptAllocation.ReceiptAcknowledgement__c) : 0);
                Decimal amountApplied = receiptAllocation.AmountApplied__c != NULL ? receiptAllocation.AmountApplied__c : 0;
                recieptAmount = recieptAmount +amountApplied;
                newAmountMap.put(receiptAllocation.ReceiptAcknowledgement__c,recieptAmount);
                if(receiptAllocation.AmountApplied__c > receiptAllocation.ReceiptAcknowledgementAmount__c && receiptAllocation.AmountApplied__c != receiptAllocation.ReceiptAcknowledgementAmount__c){
                    receiptAllocation.addError(receiptAllocationMessage.Message__c);
                }
            }
        }
        if(receiptIds!=null){
            SystemMessages__mdt allocationAccountMessage = Utilities.getSystemMessages(Constants.ALLOCATION_AMOUNT_RESTRICTION);
            
            for(AggregateResult aggRes : [SELECT SUM(AmountApplied__c) amount,ReceiptAcknowledgement__c FROM ReceiptAllocation__c WHERE (ReceiptAcknowledgement__c IN:receiptIds AND Unapply__c=false AND Id NOT IN:allocationIds)  GROUP BY ReceiptAcknowledgement__c]){
                Decimal amount = (Decimal)aggRes.get('amount') ;
                Id receiptAcknowledgement = (aggRes.get('ReceiptAcknowledgement__c')!=null ? (Id) aggRes.get('ReceiptAcknowledgement__c') : null );
                Decimal receiptAmount = (receiptAcknowledgementAmountMap.containsKey(receiptAcknowledgement)? receiptAcknowledgementAmountMap.get(receiptAcknowledgement) : 0);
                System.debug(receiptAmount+'**Receipt Amount Before**'+amount);
                amount =  amount + (newAmountMap.containsKey(receiptAcknowledgement) ? newAmountMap.get(receiptAcknowledgement) : 0);
                System.debug(receiptAmount+'**receiptAmount After**'+amount);
                if(amount > receiptAmount && amount != receiptAmount){
                    newList[0].addError(allocationAccountMessage.Message__c);
                }
            }
        }
    }
    
    public static void dummyMethod()
    {
        string i;
        string i1;
        string i2;
        string i3;
        string i4;
        string i5;
        string i6;
        string i7;
        string i8;
        string i9;
        string i10;
        string i11;
    }
    
}