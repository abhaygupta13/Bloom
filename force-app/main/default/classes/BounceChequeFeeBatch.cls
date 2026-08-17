/*****************************************************************************************
Class       : BounceChequeFeeBatch
Author      : Aman Bharti
Description : BounceChequeFeebatch
Test Class  : BounceChequeFeebatchTest
Created Date: 17 JUNE 2025 
*****************************************************************************************/

public class BounceChequeFeeBatch implements Database.Batchable<SObject>,Schedulable{
    
    private static final String CHEQUE_BOUNCE_FEE_STR { get { return 'Cheque Bounce Fee'; } }
    private static final String REVERSED_STR { get { return 'Reversed'; } }
    private static final String BOUNCE_CHEQUE_FEE_EXCLUDED_REASONS { get { return 'BounceChequeFeeExcludedReasons'; } }
    private static final String DOWN_PAYMENT_STR { get { return 'Down Payment'; } }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        MetadataService objMetadataService = MetadataService.getInstance();
        Set<String> excludeReasonsSet = new Set<String>(objMetadataService.getAppSettingTextValue(BOUNCE_CHEQUE_FEE_EXCLUDED_REASONS).split(','));
        String query = 'SELECT Id,Account__c,SalesOrder__c,IsBounceChequeFeeCreated__c,ChequeBouncedDate__c,SalesOrder__r.Unit__r.Project__r.BounceChequeFeeAmount__c,SalesOrder__r.Unit__r.Project__r.BounceChequeFeeERPCondition__c, SalesOrder__r.Unit__r.Project__r.BounceChequeFeeThresholdDays__c,Reason__c FROM ReceiptAcknowledgement__c WHERE IsBounceChequeFeeCreated__c = false AND SalesOrder__c != null AND SalesOrder__r.Status__c = \'Sold\' AND ChequeBouncedDate__c != null AND Reason__c NOT IN: excludeReasonsSet AND ReceiptReversalCategory__c = \'Bounced Cheque\'';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<ReceiptAcknowledgement__c> scope) {
        List<SalesOrderOtherCharges__c> otherChanrgesToBeCreated = new List<SalesOrderOtherCharges__c>();
        
        SalesOrderOtherChargesService objSalesOrderOtherChargesService = SalesOrderOtherChargesService.getInstance();
        ReceiptAcknowledgementService objReceiptAcknowledgementService = ReceiptAcknowledgementService.getInstance();
        InstallmentLineService objInstallmentLineService = InstallmentLineService.getInstance();
        Map<Id, ReceiptAcknowledgement__c> receiptMap = new Map<Id, ReceiptAcknowledgement__c>(scope);
        Map<Id, ReceiptAcknowledgement__c> receiptAckMap = new Map<Id, ReceiptAcknowledgement__c>(objReceiptAcknowledgementService.getReceiptAcknowledgementNReceiptAllocationsById(receiptMap.keySet()));
        List<ReceiptAcknowledgement__c> receiptAckToUpdateList = new List<ReceiptAcknowledgement__c>();
        
        //fetch installmentsIds
        Set<Id> installmentIdSet = new Set<Id>();
        for(ReceiptAcknowledgement__c receiptAck : receiptAckMap.values()){
            if(receiptAck.Receipt_Allocations__r != null && receiptAck.Receipt_Allocations__r.size() > 0 && receiptAck.Receipt_Allocations__r[0].ReceiptStatus__c == REVERSED_STR){
                installmentIdSet.add(receiptAck.Receipt_Allocations__r[0].InstallmentLine__c);
            }
        }
        Map<Id, InstallmentLines__c> installmentNAllocationMap = new Map<Id, InstallmentLines__c> (objInstallmentLineService.getInstallmentsNReceiptAllocations(installmentIdSet, new Set<Id>()));
        
        for(ReceiptAcknowledgement__c receipt : scope){
            Integer bufferDays = receipt.SalesOrder__r != null && receipt.SalesOrder__r.Unit__r != null && receipt.SalesOrder__r.Unit__r.Project__r != null && receipt.SalesOrder__r.Unit__r.Project__r.BounceChequeFeeThresholdDays__c != null ? (Integer)receipt.SalesOrder__r.Unit__r.Project__r.BounceChequeFeeThresholdDays__c : 0;
            Date finalBounceDate = receipt.ChequeBouncedDate__c.addDays(bufferDays);
            Id installmentId =  receiptAckMap.get(receipt.Id).Receipt_Allocations__r != null &&
                                receiptAckMap.get(receipt.Id).Receipt_Allocations__r.size() > 0 &&
                                receiptAckMap.get(receipt.Id).Receipt_Allocations__r[0].ReceiptStatus__c == REVERSED_STR && 
                                receiptAckMap.get(receipt.Id).Receipt_Allocations__r[0].InstallmentLine__r != null && 
                                receiptAckMap.get(receipt.Id).Receipt_Allocations__r[0].InstallmentLine__r.Type__c != DOWN_PAYMENT_STR
                                ? receiptAckMap.get(receipt.Id).Receipt_Allocations__r[0].InstallmentLine__c : null;
            if(installmentId != null && !receipt.IsBounceChequeFeeCreated__c && finalBounceDate < Date.today() && installmentNAllocationMap != null && installmentNAllocationMap.containsKey(installmentId) && installmentNAllocationMap.get(installmentId).Receipt_Allocations__r != null && installmentNAllocationMap.get(installmentId).Receipt_Allocations__r[0].ReceiptStatus__c == REVERSED_STR){
                // creating sales order other charges
                otherChanrgesToBeCreated.add(
                    objSalesOrderOtherChargesService.createSalesOrderOtherChargesObj(
                        receipt.SalesOrder__c, 
                        receipt.Account__c,
                        installmentId,
                        receipt.SalesOrder__r.Unit__r.Project__r.BounceChequeFeeAmount__c != null ? receipt.SalesOrder__r.Unit__r.Project__r.BounceChequeFeeAmount__c :0,
                        CHEQUE_BOUNCE_FEE_STR,
                        receipt.Id,
                        null,
                        receipt.SalesOrder__r.Unit__r.Project__r.BounceChequeFeeERPCondition__c,
                        Date.today())
                );
                receiptAckToUpdateList.add(new ReceiptAcknowledgement__c(Id = receipt.id, IsBounceChequeFeeCreated__c = true));
            }  
        }
        // inserting sales order other charges
        objSalesOrderOtherChargesService.insertSalesOrderOtherCharges(otherChanrgesToBeCreated);
        //updating Receipt Acknowlwdgement's Bounce cheque fee created flag to true
        objReceiptAcknowledgementService.updateReceiptAcknowledgementWithoutTrigger(receiptAckToUpdateList);
    }
    
    public void finish(Database.BatchableContext bc) {
        //finish logic here
    }

    public void execute(SchedulableContext context){
        // Scheduling the batch
        Database.executeBatch(new BounceChequeFeeBatch(), 50); 
    }
}