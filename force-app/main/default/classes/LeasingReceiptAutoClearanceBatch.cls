/***
Class       : LeasingReceiptAutoClearanceBatch
Author      : Bloom Holding 
Description : It creates Receipt Allocation if Receipt Applied amount available and any installment payment date is today
TestClass   : LeasingReceiptAutoClearanceBatchTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
****************************************************************************************************************/
public class LeasingReceiptAutoClearanceBatch implements Database.Batchable<SObject>, Schedulable{
    // === Start method ===
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 
            'Select id,LeasingOrder__c,UnappliedAmount__c,BeingTowards__c ,Amount__c from LeasingReceiptAcknowledgment__c '
            + 'where UnappliedAmount__c != 0.0 AND BeingTowards__c != null AND SAPReversalDocumentNumber__c = null' ;
        // Return as query locator
        List<LeasingReceiptAcknowledgment__c> receipts = Database.query(query);
        System.debug(receipts);
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext bc, List<LeasingReceiptAcknowledgment__c> receipts) {
        
        Set<Id> leasingOrderIds = new Set<Id>();
        
        Map<Id, List<LeasingReceiptAcknowledgment__c>> leasingOrderWithReceiptsMap = new Map<Id, List<LeasingReceiptAcknowledgment__c>>();
        
        for(LeasingReceiptAcknowledgment__c rec : receipts){
            leasingOrderIds.add(rec.LeasingOrder__c);
            
            if(!leasingOrderWithReceiptsMap.containsKey(rec.LeasingOrder__c)) {
                leasingOrderWithReceiptsMap.put(rec.LeasingOrder__c, new List<LeasingReceiptAcknowledgment__c>());
            }
            leasingOrderWithReceiptsMap.get(rec.LeasingOrder__c).add(rec);
        }
        System.debug(json.serialize(leasingOrderWithReceiptsMap));
        //  Fetch Data
        List<PaymentPlanSchedule__c> schedules = LeasingPaymentScheduleService.getInstance()
            .getunPaidPaymentPlansByLeasingOrderIds(leasingOrderIds);
        
        List<LeasingOrdersOtherCharges__c> otherCharges = LeasingOtherChargesService.getInstance()
            .getunPaidOtherChargesByLeasingOrderIds(leasingOrderIds);
        
        //  GROUP BY LeasingOrderId
        Map<Id, List<PaymentPlanSchedule__c>> orderToSchedulesMap = new Map<Id, List<PaymentPlanSchedule__c>>();
        Map<Id, List<LeasingOrdersOtherCharges__c>> orderToChargesMap = new Map<Id, List<LeasingOrdersOtherCharges__c>>();
        
        //  Remaining trackers
        Map<Id, Decimal> scheduleRemainingMap = new Map<Id, Decimal>();
        Map<Id, Decimal> chargeRemainingMap = new Map<Id, Decimal>();
        
        for(PaymentPlanSchedule__c sch : schedules){
            if(!orderToSchedulesMap.containsKey(sch.LeasingOrder__c)){
                orderToSchedulesMap.put(sch.LeasingOrder__c, new List<PaymentPlanSchedule__c>());
            }
            orderToSchedulesMap.get(sch.LeasingOrder__c).add(sch);
            
            scheduleRemainingMap.put(sch.Id, sch.DueAmount__c);
        }
        
        for(LeasingOrdersOtherCharges__c charge : otherCharges){
            if(!orderToChargesMap.containsKey(charge.LeasingOrder__c)){
                orderToChargesMap.put(charge.LeasingOrder__c, new List<LeasingOrdersOtherCharges__c>());
            }
            orderToChargesMap.get(charge.LeasingOrder__c).add(charge);
            
            chargeRemainingMap.put(charge.Id, charge.DueAmount__c);
        }
        
        List<LeasingReceiptAllocation__c> allocations = new List<LeasingReceiptAllocation__c>();
        
        
        for(Id orderId : leasingOrderWithReceiptsMap.keySet()){
            
            List<LeasingReceiptAcknowledgment__c> orderReceipts = leasingOrderWithReceiptsMap.get(orderId);
            List<PaymentPlanSchedule__c> orderSchedules = orderToSchedulesMap.get(orderId);
            List<LeasingOrdersOtherCharges__c> orderCharges = orderToChargesMap.get(orderId);
            
            for(LeasingReceiptAcknowledgment__c receipt : orderReceipts){
                 System.debug('receipt::'+receipt);
                Decimal remaining = receipt.UnappliedAmount__c;
                
                Boolean applyInstallment = receipt.BeingTowards__c != null && receipt.BeingTowards__c.contains('Rent Installment');
                Boolean applyOtherCharge = receipt.BeingTowards__c != null && !receipt.BeingTowards__c.contains('Rent Installment');
                
                /* APPLY TO INSTALLMENTS */
                if(applyInstallment && orderSchedules != null){
                    
                    
                    for(PaymentPlanSchedule__c sch : orderSchedules){
                        
                        if(remaining <= 0) break;
                        
                        Decimal schRemaining = scheduleRemainingMap.get(sch.Id);
                        
                        if(schRemaining == 0) continue;
                        System.debug('sch::'+sch);
                        
                        Decimal allocationAmount = schRemaining <= remaining ? schRemaining : remaining;
                        
                        
                        allocations.add(new LeasingReceiptAllocation__c(
                            LeasingOrder__c = orderId,
                            LeasingReceiptAcknowledgment__c = receipt.Id,
                            PaymentPlanSchedule__c = sch.Id,
                            //AmountApplied__c = allocationAmount - sch.clearedAmount__c
                            AmountApplied__c = allocationAmount
                        ));
                        //allocationAmount = allocationAmount - sch.clearedAmount__c ; 
                        remaining -= allocationAmount;
                        scheduleRemainingMap.put(sch.Id, schRemaining - allocationAmount);
                    }
                }
                
                /* APPLY TO OTHER CHARGES */
                if(applyOtherCharge && orderCharges != null){
                    
                    for(LeasingOrdersOtherCharges__c charge : orderCharges){
                        System.debug('charge:::'+charge);
                        
                        if(remaining <= 0) break;
                        
                        Decimal chargeRemaining = chargeRemainingMap.get(charge.Id);
                        
                        if(chargeRemaining == 0) continue;
                        
                        Decimal allocationAmount = chargeRemaining <= remaining ? chargeRemaining : remaining;
                        
                        allocations.add(new LeasingReceiptAllocation__c(
                            LeasingOrder__c = orderId,
                            LeasingReceiptAcknowledgment__c = receipt.Id,
                            LeasingOrderOtherCharges__c = charge.Id,
                            // AmountApplied__c = allocationAmount - charge.clearedAmount__c 
                            AmountApplied__c = allocationAmount  
                        ));
                       
                        remaining -= allocationAmount;
                        chargeRemainingMap.put(charge.Id, chargeRemaining - allocationAmount);
                         System.debug('chargeRemainingMap:::'+chargeRemainingMap);
                    }
                }
                
                //receipt.AppliedAmount__c = receipt.Amount__c - remaining;
            }
        }
         System.debug('allocations:::'+allocations);
        LeasingPaymentScheduleTriggerHelper.bypassIntegration = true;
        LeasingOtherChargesTriggerHelper.bypassIntegration = true;
        LeasingReceiptAcknowledgementService.bypassIntegration = true;
        LeasingReceiptAllocationService.getInstance().insertReceiptAllocations(allocations);
        //LeasingReceiptAcknowledgementService.getInstance().updateReceiptACknowledgementsWithoutTrigger(receipts);
    }
    // === Finish ===
    public void finish(Database.BatchableContext bc) {
        
    }
    // === Schedulable execute method ===
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new LeasingReceiptAutoClearanceBatch(), 20);
    }
}