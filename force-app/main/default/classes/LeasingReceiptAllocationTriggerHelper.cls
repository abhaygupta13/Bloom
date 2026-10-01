/***
Class       : LeasingReceiptAllocationTriggerHelper
Author      : 
Description : Helper class to handle trigger business logic 
TestClass   : LeasingRcptAllocationTriggerHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              11/10/25           Initial Version 
****************************************************************************************************************/
public without sharing class LeasingReceiptAllocationTriggerHelper {
    private static final string INTEGRATION_TYPE_LEASINGRECPT_SAP_INTEGRATION { get { return 'LEASINGRECEIPT_SAP_INTEGRATION'; } }
    private static final string OC_AMOUNT_EXCEED_ERROR {get {return 'Other charge cleared amount cannot be greater that Other charge total amount or less that \'0\'';}}
    private static final string PPS_AMOUNT_EXCEED_ERROR {get {return 'Payment plan applied amount cannot be greater than Payment plan total amount or lesser than \'0\'';}}
    private static final string ACkNOWLEDGEMENT_AMOUNT_EXCEED_ERROR {get {return 'Receipt Acknowledgement applied amount cannot be greater than Receipt Acknowledgement amount or lesser than \'0\'';}}
    private static final string LEASING_ORDER_ERROR {get{ return 'Kindly select correct leasing order : {LOName}';}}
    
    public static void beforeFieldUpdates(List<LeasingReceiptAllocation__c> newList){
        Map<Id,Decimal> parentAmountMap = new Map<id, Decimal>();
        Map<Id,Boolean> fullAllocationMap = new Map<id, Boolean>();
        
        Set<Id> acknowledgementIds = new Set<Id>();
        for(LeasingReceiptAllocation__c alloc : [SELECT Id ,PaymentPlanSchedule__r.LeasingOrder__c ,LeasingOrderOtherCharges__r.LeasingOrder__c, AmountApplied__c,
                                                LeasingReceiptAcknowledgment__r.SAPDocumentNumber__c, LeasingReceiptAcknowledgment__r.FullAmountAllocation__c,
                                                LeasingReceiptAcknowledgment__r.Amount__c, LeasingReceiptAcknowledgment__c
                                                FROM LeasingReceiptAllocation__c WHERE ID IN:newList]){
            if(alloc.PaymentPlanSchedule__c != null  ){
                alloc.LeasingOrder__c = alloc.PaymentPlanSchedule__r.LeasingOrder__c ;
            }else if(alloc.LeasingOrderOtherCharges__c != null){
                alloc.LeasingOrder__c = alloc.LeasingOrderOtherCharges__r.LeasingOrder__c ;
            }
           // alloc.SendtoSAP__c = true;
        }
        
        for(LeasingReceiptAllocation__c allocation : newList){
            if(allocation.LeasingReceiptAcknowledgment__c != Null){
                acknowledgementIds.add(allocation.LeasingReceiptAcknowledgment__c);
            }
        }
        if(!acknowledgementIds.isEmpty()){
            Map<Id, LeasingReceiptAcknowledgment__c>  receiptMap = new Map<Id, LeasingReceiptAcknowledgment__c>([Select Id, LeasingOrder__c, LeasingOrder__r.Name, VerifyDate__c 
                                                                                from LeasingReceiptAcknowledgment__c where Id IN : acknowledgementIds]);
            for(LeasingReceiptAllocation__c allocation : newList){
                if(allocation.LeasingOrder__c != Null && allocation.LeasingOrder__c != receiptMap.get(allocation.LeasingReceiptAcknowledgment__c).LeasingOrder__c){
                    String errorMsg = LEASING_ORDER_ERROR.replace('{LOName}',receiptMap.get(allocation.LeasingReceiptAcknowledgment__c).LeasingOrder__r.Name);
                    //allocation.addError(errorMsg);
                }
                if(receiptMap.get(allocation.LeasingReceiptAcknowledgment__c).VerifyDate__c <= Date.today())
                allocation.SendtoSAP__c = true;
            }
        }
               
    }

    //Helper method for SAP integration
    public static void afterInsertSAPIntegration(List<LeasingReceiptAllocation__c> newList){
        Set<Id> acknowledgementIds = new Set<Id>();
        LeasingReceiptAcknowledgementService service = LeasingReceiptAcknowledgementService.getInstance();
        for(LeasingReceiptAllocation__c alloc : newList){
            if(alloc.LeasingReceiptAcknowledgment__c != Null && !alloc.ReceiptHold__c){
                // Skip triggering 'U' if parent receipt has already initiated integration in this transaction (e.g. 'C' on insert)
                if(!LeasingReceiptAcknowledgementService.processedReceiptIdsInContext.contains(alloc.LeasingReceiptAcknowledgment__c)){
                    acknowledgementIds.add(alloc.LeasingReceiptAcknowledgment__c);
                }
            }
        }
        if(!acknowledgementIds.isEmpty() && acknowledgementIds.size()>0){
            service.createReceiptAckIntegrationRecord('U',acknowledgementIds, INTEGRATION_TYPE_LEASINGRECPT_SAP_INTEGRATION);
        }
    }
    
    //Helper method for roll up summary on parents (Insert/Update)
    public static void leasingRAAmountUpsert(Map<Id,LeasingReceiptAllocation__c> newAllocationMap,Map<Id,LeasingReceiptAllocation__c> oldAllocationMap){
        Map<Id, Decimal> ocAmountMap = new Map<Id,Decimal>();
        Map<Id, Decimal> rcptAcknowledgementAmountMap = new Map<Id,Decimal>();
        Map<Id, Decimal> pymntScheduleAmountMap = new Map<Id,Decimal>();
        List<LeasingOrdersOtherCharges__c> updateOcList = new List<LeasingOrdersOtherCharges__c>();
        List<LeasingReceiptAcknowledgment__c> updateRAList = new List<LeasingReceiptAcknowledgment__c>();
        List<PaymentPlanSchedule__c> updatePymntSchduleList = new List<PaymentPlanSchedule__c>();
        List<LeasingReceiptAllocation__c> integrateAllocations = new List<LeasingReceiptAllocation__c>();
        Map<Id, String> ppsPaymentDocMap = new Map<Id, String>();
        Map<Id, String> ocPaymentDocMap = new Map<Id, String>();
        
        for(LeasingReceiptAllocation__c ra : newAllocationMap.values()){
            if(oldAllocationMap == Null 
            || (newAllocationMap.get(ra.Id).LeasingOrderOtherCharges__c != oldAllocationMap.get(ra.Id).LeasingOrderOtherCharges__c)
            || (newAllocationMap.get(ra.Id).AmountApplied__c != oldAllocationMap.get(ra.Id).AmountApplied__c)){
                if(ra.LeasingOrderOtherCharges__c != Null){
                    ocAmountMap.put( ra.LeasingOrderOtherCharges__c, 
                        (ocAmountMap.get(ra.LeasingOrderOtherCharges__c) != null ? ocAmountMap.get(ra.LeasingOrderOtherCharges__c) : 0) + (ra.AmountApplied__c != null ? ra.AmountApplied__c : 0)
                    );

                    if(oldAllocationMap != Null  && (ra.AmountApplied__c != oldAllocationMap.get(ra.Id).AmountApplied__c)){
                        ocAmountMap.put(ra.LeasingOrderOtherCharges__c, ocAmountMap.get(ra.LeasingOrderOtherCharges__c) - oldAllocationMap.get(ra.Id).AmountApplied__c);     
                    }
                    if(oldAllocationMap != Null  && oldAllocationMap.get(ra.Id).LeasingOrderOtherCharges__c != Null && ra.LeasingOrderOtherCharges__c != oldAllocationMap.get(ra.Id).LeasingOrderOtherCharges__c){
                        ocAmountMap.put(oldAllocationMap.get(ra.Id).LeasingOrderOtherCharges__c,-oldAllocationMap.get(ra.Id).AmountApplied__c);
                    }
                }
                if(ra.LeasingOrderOtherCharges__c == Null && oldAllocationMap != Null && oldAllocationMap.get(ra.Id).LeasingOrderOtherCharges__c != Null){
                    ocAmountMap.put(oldAllocationMap.get(ra.Id).LeasingOrderOtherCharges__c , -oldAllocationMap.get(ra.Id).AmountApplied__c);
                }
                if(ra.SAPDocumentNoI__c != Null){
                    ocPaymentDocMap.put(ra.LeasingOrderOtherCharges__c, ra.SAPDocumentNoI__c);
                }
            }
        }
        
        if(!ocAmountMap.isEmpty()){
            System.debug('ocAmountMap>>'+ json.serialize(ocAmountMap));
            for ( LeasingOrdersOtherCharges__c oc : [Select Id, ClearedAmount__c, TotalAmount__c from LeasingOrdersOtherCharges__c where Id IN: ocAmountMap.keySet()]){
                oc.ClearedAmount__c = oc.ClearedAmount__c != Null ? oc.ClearedAmount__c + ocAmountMap.get(oc.Id) : ocAmountMap.get(oc.Id);
                if(oc.ClearedAmount__c > oc.TotalAmount__c || oc.ClearedAmount__c < 0){
                    //newAllocationMap.values()[0].addError(OC_AMOUNT_EXCEED_ERROR);
                }
                if(oc.ClearedAmount__c == oc.TotalAmount__c){
                    //oc.PaymentStatus__c = 'Paid';
                    //mark the Ref num from receipt to Other charge Paymentdoc num.. - TODO
                }
                oc.PaymentDocumentNumber__c = ocPaymentDocMap.containsKey(oc.Id) ? ocPaymentDocMap.get(oc.Id) : '';
                updateOcList.add(oc);
            }
        }

        if(!updateOcList.isEmpty()){
            LeasingOtherChargesService ocService = LeasingOtherChargesService.getInstance();
            //update updateOcList;
            ocService.updateLeasingOtherCharges(updateOcList);
        }

        for(LeasingReceiptAllocation__c ra : newAllocationMap.values()){
            if(oldAllocationMap == Null 
            || (newAllocationMap.get(ra.Id).PaymentPlanSchedule__c != oldAllocationMap.get(ra.Id).PaymentPlanSchedule__c)
            || (newAllocationMap.get(ra.Id).AmountApplied__c != oldAllocationMap.get(ra.Id).AmountApplied__c)){
                if(ra.PaymentPlanSchedule__c != Null){
                    System.debug('AJ::'+pymntScheduleAmountMap.get(ra.PaymentPlanSchedule__c));
                    System.debug('AJ::'+ ra.AmountApplied__c);
                   
                    pymntScheduleAmountMap.put( ra.PaymentPlanSchedule__c, 
                        (pymntScheduleAmountMap.get(ra.PaymentPlanSchedule__c) != null ? pymntScheduleAmountMap.get(ra.PaymentPlanSchedule__c) : 0) + (ra.AmountApplied__c != null ? ra.AmountApplied__c : 0)
                    );
                    if(oldAllocationMap != Null  && (ra.AmountApplied__c != oldAllocationMap.get(ra.Id).AmountApplied__c)){
                        pymntScheduleAmountMap.put(ra.PaymentPlanSchedule__c, pymntScheduleAmountMap.get(ra.PaymentPlanSchedule__c) - oldAllocationMap.get(ra.Id).AmountApplied__c);     
                    }
                    if(oldAllocationMap != Null  && oldAllocationMap.get(ra.Id).PaymentPlanSchedule__c != Null && ra.PaymentPlanSchedule__c != oldAllocationMap.get(ra.Id).PaymentPlanSchedule__c){
                        pymntScheduleAmountMap.put(oldAllocationMap.get(ra.Id).PaymentPlanSchedule__c,-oldAllocationMap.get(ra.Id).AmountApplied__c);
                    }
                }
                if(ra.PaymentPlanSchedule__c == Null && oldAllocationMap != Null && oldAllocationMap.get(ra.Id).PaymentPlanSchedule__c != Null){
                    pymntScheduleAmountMap.put(oldAllocationMap.get(ra.Id).PaymentPlanSchedule__c , -oldAllocationMap.get(ra.Id).AmountApplied__c);
                }
                if(ra.SAPDocumentNoI__c != null){
                    ppsPaymentDocMap.put(ra.PaymentPlanSchedule__c, ra.SAPDocumentNoI__c);
                }
            }
        }
        
        if(!pymntScheduleAmountMap.isEmpty()){
            System.debug('pymntScheduleAmountMap>>'+ json.serialize(pymntScheduleAmountMap));
            for ( PaymentPlanSchedule__c oc : [Select Id, ClearedAmount__c, TotalInstallmentAmount__c from PaymentPlanSchedule__c where Id IN: pymntScheduleAmountMap.keySet()]){
                if(pymntScheduleAmountMap.containsKey(oc.Id) && pymntScheduleAmountMap.get(oc.Id) != null){
                    oc.ClearedAmount__c = oc.ClearedAmount__c != Null ? oc.ClearedAmount__c + pymntScheduleAmountMap.get(oc.Id) : pymntScheduleAmountMap.get(oc.Id);
                    System.debug('AJ:::'+oc.ClearedAmount__c);
                     System.debug('AJ:::'+oc.TotalInstallmentAmount__c);
                    if(oc.ClearedAmount__c == oc.TotalInstallmentAmount__c ){
                       //oc.PaymentStatus__c = 'Paid';
                       //mark the Ref num from receipt to Installment Paymentdoc num.. - TODO
                    }
                    if(oc.ClearedAmount__c != null && oc.TotalInstallmentAmount__c != null && 
                       (oc.ClearedAmount__c > oc.TotalInstallmentAmount__c || oc.ClearedAmount__c < 0)){
                          //newAllocationMap.values()[0].addError(PPS_AMOUNT_EXCEED_ERROR);
                       }
                    oc.PaymentDocumentNumber__c = ppsPaymentDocMap.containsKey(oc.Id) ? ppsPaymentDocMap.get(oc.Id) : '';
                    updatePymntSchduleList.add(oc);
                }
            }
        }
        
        if(!updatePymntSchduleList.isEmpty()){
            LeasingPaymentScheduleService ppsServie = LeasingPaymentScheduleService.getInstance();
            ppsServie.updatePaymentPlanSchedules(updatePymntSchduleList);
        }
        //update updatePymntSchduleList;
    
        
        for(LeasingReceiptAllocation__c ra : newAllocationMap.values()){
             if(oldAllocationMap == Null 
            || (ra.LeasingReceiptAcknowledgment__c != oldAllocationMap.get(ra.Id).LeasingReceiptAcknowledgment__c)
            || (ra.AmountApplied__c != oldAllocationMap.get(ra.Id).AmountApplied__c)){
                if(ra.LeasingReceiptAcknowledgment__c != Null){
                    rcptAcknowledgementAmountMap.put( ra.LeasingReceiptAcknowledgment__c, 
                        (rcptAcknowledgementAmountMap.get(ra.LeasingReceiptAcknowledgment__c) != null ? rcptAcknowledgementAmountMap.get(ra.LeasingReceiptAcknowledgment__c) : 0) + (ra.AmountApplied__c != null ? ra.AmountApplied__c : 0)
                    );
                    if(oldAllocationMap != Null  && (ra.AmountApplied__c != oldAllocationMap.get(ra.Id).AmountApplied__c)){
                        rcptAcknowledgementAmountMap.put(ra.LeasingReceiptAcknowledgment__c, rcptAcknowledgementAmountMap.get(ra.LeasingReceiptAcknowledgment__c) - oldAllocationMap.get(ra.Id).AmountApplied__c);     
                    }
                    if(oldAllocationMap != Null  && oldAllocationMap.get(ra.Id).LeasingReceiptAcknowledgment__c != Null &&ra.LeasingReceiptAcknowledgment__c != oldAllocationMap.get(ra.Id).LeasingReceiptAcknowledgment__c){
                        rcptAcknowledgementAmountMap.put(oldAllocationMap.get(ra.Id).LeasingReceiptAcknowledgment__c,-oldAllocationMap.get(ra.Id).AmountApplied__c);
                    }
                    
                }

                if(ra.LeasingReceiptAcknowledgment__c == Null && oldAllocationMap != Null && oldAllocationMap.get(ra.Id).LeasingReceiptAcknowledgment__c != Null){
                    rcptAcknowledgementAmountMap.put(oldAllocationMap.get(ra.Id).LeasingReceiptAcknowledgment__c , -oldAllocationMap.get(ra.Id).AmountApplied__c);
                }
            }
        }
        
        if(!rcptAcknowledgementAmountMap.isEmpty()){
            System.debug('rcptAcknowledgementAmountMap>>'+ json.serialize(rcptAcknowledgementAmountMap));
            for ( LeasingReceiptAcknowledgment__c oc : [Select Id, AppliedAmount__c, Amount__c from LeasingReceiptAcknowledgment__c where Id IN: rcptAcknowledgementAmountMap.keySet()]){
                oc.AppliedAmount__c = oc.AppliedAmount__c != Null ? oc.AppliedAmount__c + rcptAcknowledgementAmountMap.get(oc.Id) : rcptAcknowledgementAmountMap.get(oc.Id);
                if(oc.AppliedAmount__c > oc.Amount__c || oc.AppliedAmount__c < 0){
                    //newAllocationMap.values()[0].addError(ACkNOWLEDGEMENT_AMOUNT_EXCEED_ERROR);
                }
                updateRAList.add(oc);
            }
        }

        if(!updateRAList.isEmpty()){
            LeasingReceiptAcknowledgementService service = LeasingReceiptAcknowledgementService.getInstance();
            service.updateLeasingReceiptAcknowledgement(updateRAList);
        }
        //Re-sync integration
        for(LeasingReceiptAllocation__c ra : newAllocationMap.values()){
            if(oldAllocationMap != Null && ra.SendtoSAP__c && ra.SendtoSAP__c != oldAllocationMap.get(ra.Id).SendtoSAP__c){
                integrateAllocations.add(ra);
            }
        }
        if(!integrateAllocations.isEmpty()){
            afterInsertSAPIntegration(integrateAllocations);
        }
    }

    // Helper method for reversal integration
    public static void reversalIntegration(List<LeasingReceiptAllocation__c> newList, Map<Id,LeasingReceiptAllocation__c> oldAllocationMap){
        List<LeasingReceiptAllocation__c> reversalList = new List<LeasingReceiptAllocation__c>();
        for(LeasingReceiptAllocation__c ra : newList){
            if(ra.ReversalDate__c != Null && oldAllocationMap.get(ra.Id).ReversalDate__c == Null){
                reversalList.add(ra);
            }
        }
        if(!reversalList.isEmpty()){
            //leasingRAAmountDlt(reversalList,null);
            afterInsertSAPIntegration(reversalList);
        }

    }

    //Helper method for reversal rollup summarry on parents
    public static void reversalAmountHandling(List<LeasingReceiptAllocation__c> newList, Map<Id,LeasingReceiptAllocation__c> oldAllocationMap){
        List<LeasingReceiptAllocation__c> reversalList = new List<LeasingReceiptAllocation__c>();
        for(LeasingReceiptAllocation__c ra : newList){
            if(ra.SAPReversalDocumentNumber__c != Null && ra.SAPReversalDocumentNumber__c != oldAllocationMap.get(ra.Id).SAPReversalDocumentNumber__c){
                reversalList.add(ra);
            }
        }
        if(!reversalList.isEmpty()){
            leasingRAAmountDlt(reversalList,null);
        }
    }

    //Helper method for rollup summary on parent (Delete)
    public static void leasingRAAmountDlt(List<LeasingReceiptAllocation__c> oldAllocationList,Map<Id,LeasingReceiptAllocation__c> oldAllocationMap){
        Map<Id, Decimal> ocAmountMap = new Map<Id,Decimal>();
        Map<Id, Decimal> rcptAcknowledgementAmountMap = new Map<Id,Decimal>();
        Map<Id, Decimal> pymntScheduleAmountMap = new Map<Id,Decimal>();
        List<LeasingOrdersOtherCharges__c> updateOcList = new List<LeasingOrdersOtherCharges__c>();
        List<LeasingReceiptAcknowledgment__c> updateRAList = new List<LeasingReceiptAcknowledgment__c>();
        List<PaymentPlanSchedule__c> updatePymntSchduleList = new List<PaymentPlanSchedule__c>();

        for(LeasingReceiptAllocation__c ra : oldAllocationList){
            if(ra.LeasingOrderOtherCharges__c != Null && ra.AmountApplied__c != Null){
                ocAmountMap.put( ra.LeasingOrderOtherCharges__c, 
                    (ocAmountMap.get(ra.LeasingOrderOtherCharges__c) != null ? ocAmountMap.get(ra.LeasingOrderOtherCharges__c) : 0) + (ra.AmountApplied__c != null ? ra.AmountApplied__c : 0)
                );
            }
            if(ra.PaymentPlanSchedule__c != Null && ra.AmountApplied__c != Null){
                pymntScheduleAmountMap.put( ra.PaymentPlanSchedule__c, 
                    (pymntScheduleAmountMap.get(ra.PaymentPlanSchedule__c) != null ? pymntScheduleAmountMap.get(ra.PaymentPlanSchedule__c) : 0) + (ra.AmountApplied__c != null ? ra.AmountApplied__c : 0)
                );
            }
            if(ra.LeasingReceiptAcknowledgment__c != Null && ra.AmountApplied__c != Null){
                rcptAcknowledgementAmountMap.put( ra.LeasingReceiptAcknowledgment__c, 
                    (rcptAcknowledgementAmountMap.get(ra.LeasingReceiptAcknowledgment__c) != null ? rcptAcknowledgementAmountMap.get(ra.LeasingReceiptAcknowledgment__c) : 0) + (ra.AmountApplied__c != null ? ra.AmountApplied__c : 0)
                );
            }
        }

        if(!ocAmountMap.isEmpty()){
            for ( LeasingOrdersOtherCharges__c oc : [Select Id, ClearedAmount__c, TotalAmount__c from LeasingOrdersOtherCharges__c where Id IN: ocAmountMap.keySet()]){
                oc.ClearedAmount__c =  oc.ClearedAmount__c - ocAmountMap.get(oc.Id) ;
                updateOcList.add(oc);
            }
        }

        if(!updateOcList.isEmpty()){
            LeasingOtherChargesService ocService = LeasingOtherChargesService.getInstance();
            ocService.updateLeasingOtherCharges(updateOcList);
        }
        

        if(!pymntScheduleAmountMap.isEmpty()){
            for ( PaymentPlanSchedule__c oc : [Select Id, ClearedAmount__c, TotalInstallmentAmount__c from PaymentPlanSchedule__c where Id IN: pymntScheduleAmountMap.keySet()]){
                oc.ClearedAmount__c =  oc.ClearedAmount__c - pymntScheduleAmountMap.get(oc.Id);
                updatePymntSchduleList.add(oc);
            }
        }
        
        if(!updatePymntSchduleList.isEmpty()){
            LeasingPaymentScheduleService ppsServie = LeasingPaymentScheduleService.getInstance();
            ppsServie.updatePaymentPlanSchedules(updatePymntSchduleList);
        }
        
        if(!rcptAcknowledgementAmountMap.isEmpty()){
            for ( LeasingReceiptAcknowledgment__c oc : [Select Id, AppliedAmount__c, Amount__c from LeasingReceiptAcknowledgment__c where Id IN: rcptAcknowledgementAmountMap.keySet()]){
                oc.AppliedAmount__c = oc.AppliedAmount__c - rcptAcknowledgementAmountMap.get(oc.Id);
                updateRAList.add(oc);
            }
        }

        if(!updateRAList.isEmpty()){
            LeasingReceiptAcknowledgementService service = LeasingReceiptAcknowledgementService.getInstance();
            service.updateLeasingReceiptAcknowledgement(updateRAList);
        }
    }
    
    public static void updateCreditBalanceOnLO(List<LeasingReceiptAllocation__c> newAllocationList,Map<Id,LeasingReceiptAllocation__c> oldAllocationMap){
        Set<Id> orderIds = new Set<Id>();
        Map<Id, Decimal> orderToSum = new Map<Id, Decimal>();
        if(oldAllocationMap == Null){
            for(LeasingReceiptAllocation__c allocation : newAllocationList){
                if(allocation.LeasingOrder__c != Null){
                    orderIds.add(allocation.LeasingOrder__c);   
                }
            }
        }
        if(oldAllocationMap != Null){
            for(LeasingReceiptAllocation__c allocation : newAllocationList){
                if(allocation.AmountApplied__c != oldAllocationMap.get(allocation.Id).AmountApplied__c)
                orderIds.add(allocation.LeasingOrder__c); 
            }
        }

        if(!orderIds.isEmpty()){
            for (AggregateResult ar : [
            SELECT LeasingOrder__c orderId,
                   SUM(UnappliedAmount__c) total
            FROM    LeasingReceiptAcknowledgment__c
            WHERE LeasingOrder__c IN :orderIds and SAPReversalDocumentNumber__c = Null
            GROUP BY LeasingOrder__c
        ]) {
                orderToSum.put(
                    (Id) ar.get('orderId'),
                    (Decimal) ar.get('total')
                );
            }
        }
        if(!orderToSum.isEmpty()){
            List<LeasingOrder__c> updateLOList = LeasingOrderService.getInstance().getLeasingOrdersByIds(orderToSum.keySet());
            For(LeasingOrder__c lo : updateLOList){
                lo.CreditBalance__c = lo.MasterLeasingOrder__c != null && (lo.MasterLeasingOrder__r.CreditBalance__c != Null || lo.MasterLeasingOrder__r.CreditBalance__c != 0) ? lo.MasterLeasingOrder__r.CreditBalance__c + orderToSum.get(lo.Id) : orderToSum.get(lo.Id);
            }
            if(!updateLOList.isEmpty()){
                LeasingOrderService.getInstance().updateLeasingOrders(updateLOList);
            }
        }
    }

}