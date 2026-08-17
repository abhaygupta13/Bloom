/***
Class       : ReceiptAllocationTriggerHandler
Author      : Smaartt
Description : 
TestClass   : ReceiptAllocationTriggerHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              27/04/23           Initial Version 
****************************************************************************************************************/

public without sharing class ReceiptAllocationTriggerHandler  implements ITriggerHandler{
    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return isTriggerDisabled;
    }
    
    public void beforeInsert(List<sObject> newList) {
        ReceiptAllocationTriggerHelper.validateAmountApplied((List<ReceiptAllocation__c>)newList,null);
    }
    
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        Set<Id> raIds = new Set<Id>();        
        for(ReceiptAllocation__c receiptAllocation : (List<ReceiptAllocation__c>)newList){
            raIds.add(receiptAllocation.ReceiptAcknowledgement__c);
        }
        ReceiptAcknowledgementTriggerHelper.updateInstallmentOtherCharges(raIds);
    }
    
    
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
        ReceiptAllocationTriggerHelper.validateAmountApplied((List<ReceiptAllocation__c>)newList,(Map<id,ReceiptAllocation__c>)oldMap);
    }
    
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,  List<sObject> oldList, Map<Id, sObject> oldMap) {
        
    }
    
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
    }
    
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
        
    }
    
}

/*


public override void afterInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) 
{
Set<Id> raIds = new Set<Id>();

for(ReceiptAllocation__c receiptAllocation : (List<ReceiptAllocation__c>)newList){
raIds.add(receiptAllocation.ReceiptAcknowledgement__c);
}
ReceiptAcknowledgementTriggerHandler.updateInstallmentOtherCharges(raIds);
}

public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 

User usr = Utilities.getLoggedInUserDetail();
List<ReceiptAcknowledgement__c> updateReceiptAcknowledgement = new List<ReceiptAcknowledgement__c>();
Set<Id> receiptAcknowledgementIds = new Set<Id>();

for(ReceiptAllocation__c receiptAllocation : (List<ReceiptAllocation__c>)newList){
receiptAcknowledgementIds.add(receiptAllocation.ReceiptAcknowledgement__c);
}

for (Id recordId: receiptAcknowledgementIds) {
ReceiptAcknowledgement__c receiptAcknowledgement = new ReceiptAcknowledgement__c();
receiptAcknowledgement.Id = recordId;

updateReceiptAcknowledgement.add(receiptAcknowledgement);
}
if (!updateReceiptAcknowledgement.isEmpty()) {
update updateReceiptAcknowledgement;
}
}

public override void beforeInsertMethod(List<SObject> newList, Map<Id, SObject> newMap) {
ReceiptAllocationTriggerHelper.validateAmountApplied((List<ReceiptAllocation__c>)newList,null);
}

public override void beforeUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 
ReceiptAllocationTriggerHelper.validateAmountApplied((List<ReceiptAllocation__c>)newList,(Map<id,ReceiptAllocation__c>)oldMap);
}
/*
public void validateAmountApplied(List<ReceiptAllocation__c> newList,Map<Id, SObject> oldMap){
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
recieptAmount = recieptAmount +receiptAllocation.AmountApplied__c ;
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
}*/