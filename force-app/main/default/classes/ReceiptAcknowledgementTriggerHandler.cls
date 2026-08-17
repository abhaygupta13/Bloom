/***
Class       : ReceiptAcknowledgementTriggerHandler
Author      : Smaartt
Description : 
TestClass   : ReceiptAcknowledgementTriggerHandler
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              27/04/23           Initial Version 
2.          V1.1              26/08/24     Jayprakash   Updated to triger framework
****************************************************************************************************************/
public class ReceiptAcknowledgementTriggerHandler implements ITriggerHandler{
    
    //Use this variable to disable this trigger from transaction
    public static Boolean isTriggerDisabled = false;
    
    //check if the trigger is disabled from transaction
    public Boolean isDisabled(){
        return isTriggerDisabled;
    }
    
    public void beforeInsert(List<sObject> newList) {
        ReceiptAcknowledgementTriggerHelper.beforeInsertAction((List<ReceiptAcknowledgement__c>)newList);
    }
    
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        ReceiptAcknowledgementTriggerHelper.afterInsertAction((List<ReceiptAcknowledgement__c>)newList);
    }
    
    public void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap, List<sObject> oldList, Map<Id, sObject> oldMap) {
        ReceiptAcknowledgementTriggerHelper.beforeUpdateAction((List<ReceiptAcknowledgement__c>)newList, (Map<Id, ReceiptAcknowledgement__c>)oldMap);
    }
    
    public void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,  List<sObject> oldList, Map<Id, sObject> oldMap) {
        ReceiptAcknowledgementTriggerHelper.updateInstallmentOtherCharges(newMap.keySet());
        ReceiptAcknowledgementTriggerHelper.sendChequeBounceNotification(newMap,oldMap);
        ReceiptAcknowledgementTriggerHelper.handleAfterUpdate((List<ReceiptAcknowledgement__c>)newList, (Map<Id, ReceiptAcknowledgement__c>)oldMap);
    }
    
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        ReceiptAcknowledgementTriggerHelper.unApplyReceiptsBeforeDelete((Map<Id, ReceiptAcknowledgement__c>)oldMap);
    }
    
    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }
    
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
        
    }
}

/*
public override void afterUpdateMethod(List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap) { 

updateInstallmentOtherCharges(newMap.keySet());
system.debug(newMap.keySet());
}
public override void beforeDeleteMethod(List<SObject> oldList, Map<Id, SObject> oldMap) {

unApplyReceiptsBeforeDelete(oldMap);
system.debug(oldMap);
}
public static void updateInstallmentOtherCharges(Set<Id> receiptIds){

Map<Id,InstallmentLines__c> installmentLineMap = new  Map<Id,InstallmentLines__c>();
Map<Id,SalesOrderOtherCharges__c> otherChargesMap = new  Map<Id,SalesOrderOtherCharges__c>();
Set<Id> installmentLines = new Set<Id>();
Set<Id> otherCharges = new Set<Id>();
Set<Id> ReceiptAcknowledgement = new Set<Id>();
Map<Id,Decimal> recordInstallmentOtherChargeMap = new Map<Id,Decimal>();
Map<Id,Decimal> installmentOtherSupportCost = new Map<Id,Decimal>();
List<ReceiptAllocation__c> allocationRecordList1 = new List<ReceiptAllocation__c>();

for(ReceiptAllocation__c receiptAllocation : [SELECT Id,InstallmentLine__c,SalesOrderOtherCharges__c,ReceiptAcknowledgement__c FROM ReceiptAllocation__c WHERE ReceiptAcknowledgement__c IN:receiptIds]){
if(receiptAllocation.ReceiptAcknowledgement__c != null)
ReceiptAcknowledgement.add(receiptAllocation.ReceiptAcknowledgement__c);
if(receiptAllocation.InstallmentLine__c != null)
installmentLines.add(receiptAllocation.InstallmentLine__c);
system.debug(installmentLines);
if(receiptAllocation.SalesOrderOtherCharges__c != null)
otherCharges.add(receiptAllocation.SalesOrderOtherCharges__c);
system.debug(installmentLines);
}
For(ReceiptAllocation__c receiptAllocation1 : [SELECT Id,ReceiptAcknowledgement__r.Status__c FROM ReceiptAllocation__c
WHERE ReceiptAcknowledgement__c IN: ReceiptAcknowledgement AND AmountApplied__c > 0 AND ReceiptAcknowledgement__r.Status__c =: Constants.RECEIPT_STATUS_Reversed ]){
if(receiptAllocation1.ReceiptAcknowledgement__r.Status__c == Constants.RECEIPT_STATUS_Reversed){ 
receiptAllocation1.AmountApplied__c = 0;
allocationRecordList1.add(receiptAllocation1);
}
}                                                  

if(installmentLines!=null || otherCharges!=null){
System.debug(installmentLines+'***installmentLines and otherCharges***'+otherCharges);

for(ReceiptAllocation__c receiptAllocationRec : [SELECT AmountApplied__c,SalesOrderOtherCharges__c,InstallmentLine__c,ReceiptAcknowledgement__r.Status__c,Unapply__c FROM ReceiptAllocation__c WHERE (InstallmentLine__c IN:installmentLines OR SalesOrderOtherCharges__c IN:otherCharges) ORDER BY InstallmentLine__c,SalesOrderOtherCharges__c,ReceiptAcknowledgement__r.Status__c]){

Id installmentLineId = (receiptAllocationRec.InstallmentLine__c!=null ? receiptAllocationRec.InstallmentLine__c : null );
Id otherChargesId = (receiptAllocationRec.SalesOrderOtherCharges__c!=null ? receiptAllocationRec.SalesOrderOtherCharges__c : null ); 
Decimal amount = ((!receiptAllocationRec.Unapply__c && receiptAllocationRec.ReceiptAcknowledgement__r.Status__c==Constants.RECEIPT_STATUS_CLEARED)? receiptAllocationRec.AmountApplied__c :0);
//  Decimal amountRecieved = ((!receiptAllocationRec.Unapply__c && receiptAllocationRec.ReceiptAcknowledgement__r.Status__c==Constants.RECEIPT_STATUS_Received) ? receiptAllocationRec.AmountApplied__c :0);
Decimal amountReceive; 
If(!receiptAllocationRec.Unapply__c && receiptAllocationRec.ReceiptAcknowledgement__r.Status__c == Constants.RECEIPT_STATUS_Reversed ){
amountReceive = 0;
}else{
amountReceive = receiptAllocationRec.AmountApplied__c;
}
Decimal amountRecieved = amountReceive;

if(installmentLineId !=null && amount !=null){

InstallmentLines__c installmentLineRec = new InstallmentLines__c();
amount = amount + ((recordInstallmentOtherChargeMap!=null && recordInstallmentOtherChargeMap.containsKey(installmentLineId))? recordInstallmentOtherChargeMap.get(installmentLineId) : 0);
amountRecieved = amountRecieved + ((installmentLineMap!=null && installmentLineMap.containsKey(installmentLineId))? installmentLineMap.get(installmentLineId).AmountReceived__c : 0);
installmentLineRec.Id = installmentLineId ;
installmentLineRec.ClearedAmount__c = amount ;
installmentLineRec.AmountReceived__c = amountRecieved ;
installmentLineMap.put(installmentLineId,installmentLineRec);
recordInstallmentOtherChargeMap.put(installmentLineId,amount);
}

if(otherChargesId !=null && amount !=null){
amount = amount + ((recordInstallmentOtherChargeMap!=null && recordInstallmentOtherChargeMap.containsKey(otherChargesId))? recordInstallmentOtherChargeMap.get(otherChargesId) : 0);
SalesOrderOtherCharges__c otherChargeRec = new SalesOrderOtherCharges__c();
amountRecieved = amountRecieved + ((otherChargesMap!=null && otherChargesMap.containsKey(otherChargesId))? otherChargesMap.get(otherChargesId).AmountReceived__c : 0);
otherChargeRec.Id = otherChargesId ;
otherChargeRec.InvoicedAmount__c = amount ;
otherChargeRec.AmountReceived__c = amountRecieved ;
otherChargesMap.put(otherChargesId,otherChargeRec);
recordInstallmentOtherChargeMap.put(otherChargesId,amount);
}
}
System.debug(installmentLineMap+'***installmentLineList and otherChargesList***'+otherChargesMap);
//----- Update all the installment lines with the amount invoiced
if(allocationRecordList1!= null || allocationRecordList1.size()>0){
update allocationRecordList1;
}
//----- Update all the installment lines with the amount invoiced

if(installmentLineMap!=null || installmentLineMap.size()>0){
update installmentLineMap.values() ; 
}
//----- Update all the other charges with the amount invoiced

if(otherChargesMap!=null || otherChargesMap.size()>0){
update otherChargesMap.values() ; 
}

}
}
public static void unApplyReceiptsBeforeDelete(Map<Id,SObject> oldMap){
//ReceiptAcknowledgement__c
List<ReceiptAllocation__c> allocationRecordList = new List<ReceiptAllocation__c>();
for(ReceiptAllocation__c allocationRecord : [SELECT Id FROM ReceiptAllocation__c
WHERE ReceiptAcknowledgement__c IN: oldMap.keySet()
AND AmountApplied__c > 0]){
allocationRecord.AmountApplied__c = 0;
allocationRecordList.add(allocationRecord);
}
Update allocationRecordList;
}
}*/