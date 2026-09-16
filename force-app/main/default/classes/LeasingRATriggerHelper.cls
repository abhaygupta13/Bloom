/***
Class       : LeasingRATriggerHelper 
Author      : 
Description : Helper class for receipt acknowledgment trigger
TestClass   : 
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1        1.0                14-10-2025             Initial draft
****************************************************************************************************************/
public class LeasingRATriggerHelper {
    private static final string INTEGRATION_TYPE_LEASINGRECPT_SAP_INTEGRATION { get { return 'LEASINGRECEIPT_SAP_INTEGRATION'; } }
    private static final string LEASING_RECEIPT_ACKNOWLEDGEMENT { get { return 'LeasingReceiptAcknowledgment__c'; } } 
    private static final string PAYMENT_REVERSE_STATUS{ get { return 'Un Paid'; } } 

    public static void updateOwnFields(List<LeasingReceiptAcknowledgment__c> newList, Map<Id, LeasingReceiptAcknowledgment__c> newMap, Map<Id, LeasingReceiptAcknowledgment__c> oldMap){

        Set<Id> leasingOrderIds = new Set<Id>();
        for (LeasingReceiptAcknowledgment__c lca : newList) {
            if ((oldMap != null && lca.VerifyDate__c != null) || (oldMap == null && lca.VerifyDate__c != null))
                leasingOrderIds.add(lca.LeasingOrder__c);
        }

        List<LeasingOrder__c> leasingOrders = new List<LeasingOrder__c>();
        Map<Id, Date> loToPCDateMap = new Map<Id, Date>();
        if(leasingOrderIds.Size() > 0){
            leasingOrders = LeasingOrderService.getInstance().getLeasingOrdersByIds(leasingOrderIds);
            for (LeasingOrder__c lo : leasingOrders) {
                Date postingClosureDate;
                if (lo.Project__r != null && lo.Project__r.Leasing_Company__r != null) {
                    postingClosureDate = lo.Project__r.Leasing_Company__r.LeasingPostingClosureDate__c;
                }
                loToPCDateMap.put(lo.Id, postingClosureDate);
            }
            for (LeasingReceiptAcknowledgment__c lca : newList) {

                if ((oldMap != null && lca.VerifyDate__c != null) || (oldMap == null && lca.VerifyDate__c != null)) {
                    Date postingClosureDate = loToPCDateMap.get(lca.LeasingOrder__c);

                    if (postingClosureDate != null) {
                        Integer closurePeriod = (postingClosureDate.year() * 12) + postingClosureDate.month();
                        Integer postingPeriod = (lca.VerifyDate__c.year() * 12) + lca.VerifyDate__c.month();

                        if (postingPeriod <= closurePeriod) {
                            lca.VerifyDate__c.addError('Posting date is outside the posting range.');
                        }
                    }
                }
            }
        }

        if(oldMap == Null){
            Set<Id> leasingOrderSet = new Set<Id>();
             for(LeasingReceiptAcknowledgment__c lca : newList){
                //if(!lca.FullAmountAllocation__c && lca.HoldDate__c == Null)
                //  if(lca.ChequeDate__c != Null && lca.ChequeDate__c > Date.today())
                //  {
                //      lca.IsAdvancePayment__c = true;
                //  }
                 if(lca.IsAdvancePayment__c && lca.HoldDate__c == Null)
                 {
                     lca.SendtoSAP__c = true;
                 }
                 if(lca.OnHold__c || lca.Withdrawal__c || lca.Replacement__c){
                     lca.SendtoSAP__c = false;
                 }
                 leasingOrderSet.add(lca.LeasingOrder__c);
                 if(String.isBlank(lca.Note__c))
                	lca.Note__c = lca.BeingTowards__c;
                
            }
            Map<Id, LeasingOrder__c> leasingOrderMap = new Map<Id, LeasingOrder__c>(LeasingOrderService.getInstance().getLeasingOrdersByIds(leasingOrderSet));
            for(LeasingReceiptAcknowledgment__c lca  : newList ){
                LeasingOrder__c leasingorder = leasingOrderMap.get(lca.LeasingOrder__c) ;
                lca.UnitNumber__c = leasingorder?.Unit__r?.LeasingUnitNumber__c ;
                lca.Account__c = leasingorder?.Account__c;
                lca.AccountName__c = leasingorder?.Opportunity__r.Account.Name;
            }
        } else{
            For(LeasingReceiptAcknowledgment__c lca : newMap.values()){
                if(lca.HoldDate__c == Null && !lca.OnHold__c && !lca.Withdrawal__c && !lca.Replacement__c && String.isNotBlank(lca.SAPDocumentNumber__c) &&
                ((lca.MarkDeleteReverse__c != oldMap.get(lca.Id).MarkDeleteReverse__c && lca.MarkDeleteReverse__c)
                || (lca.ChequeBounced__c != oldMap.get(lca.Id).ChequeBounced__c && lca.ChequeBounced__c))){
                    lca.SendtoSAP__c = true;
                }
                if(lca.OnHold__c || lca.Withdrawal__c || lca.Replacement__c){
                     lca.SendtoSAP__c = false;
                 }
                if(lca.UnappliedAmount__c == 0.0 && oldMap.get(lca.Id).AppliedAmount__c != lca.AppliedAmount__c){
                  lca.IsAdvancePayment__c = false; 
                }
                if(String.isBlank(lca.Note__c))
                lca.Note__c = lca.BeingTowards__c;
            }
        }
    }

    public static void handleReceiptIntegration(Map<Id, LeasingReceiptAcknowledgment__c> newMap, Map<Id, LeasingReceiptAcknowledgment__c> oldMap){
        Set<Id> reversalIdSet = new set<Id>();
        Set<Id> idSet = new set<Id>();
        Set<Id> bounceChequeIdSet = new set<Id>();
        LeasingReceiptAcknowledgementService service = LeasingReceiptAcknowledgementService.getInstance();
        
        for(LeasingReceiptAcknowledgment__c leasingReceipt : newMap.Values()){
            if(oldMap == null && leasingReceipt.SendtoSAP__c){
                idSet.add(leasingReceipt.Id); 
            }
            if(oldMap != null && leasingReceipt.SendtoSAP__c && oldMap.get(leasingReceipt.id).SendtoSAP__c != leasingReceipt.SendtoSAP__c && !leasingReceipt.OnHold__c && !leasingReceipt.Withdrawal__c && !leasingReceipt.Replacement__c){
                idSet.add(leasingReceipt.Id); 
            }
        }
        if(!idSet.isEmpty() && oldMap == Null){
            service.createReceiptAckIntegrationRecord('C',idSet,INTEGRATION_TYPE_LEASINGRECPT_SAP_INTEGRATION);
        }

        if(!idSet.isEmpty() && oldMap != Null){
            service.createReceiptAckIntegrationRecord('U',idSet,INTEGRATION_TYPE_LEASINGRECPT_SAP_INTEGRATION);
        }
    }

    public static void reversalAllocationHandling(List<LeasingReceiptAcknowledgment__c> newList, Map<Id,LeasingReceiptAcknowledgment__c> oldAckMap){
        List<LeasingReceiptAllocation__c> childAllocations = new List<LeasingReceiptAllocation__c>();
        Set<Id> reversalAckIds = new Set<Id>();
        for(LeasingReceiptAcknowledgment__c lca : newList){
            if(lca.SAPReversalDocumentNumber__c != Null && lca.SAPReversalDocumentNumber__c != oldAckMap.get(lca.Id).SAPReversalDocumentNumber__c){
                reversalAckIds.add(lca.Id);
            }
        }
        if(!reversalAckIds.isEmpty()){
            List <PaymentPlanSchedule__c> PaymentPlanSchedules = new List<PaymentPlanSchedule__c>();
            List <LeasingOrdersOtherCharges__c> LeasingOrderOtherCharges = new List<LeasingOrdersOtherCharges__c>();
            LeasingReceiptAllocationService service = LeasingReceiptAllocationService.getInstance();
            for(LeasingReceiptAllocation__c ra : service.getChildAllocations(reversalAckIds)){
                                            ra.SAPReversalDocumentNumber__c = ra.LeasingReceiptAcknowledgment__r.SAPReversalDocumentNumber__c;
                                            childAllocations.add(ra);
                                            if(ra.PaymentPlanSchedule__c != null){
                                                PaymentPlanSchedules.add(new PaymentPlanSchedule__c(Id = ra.PaymentPlanSchedule__c, PaymentStatus__c = PAYMENT_REVERSE_STATUS));
                                            }else if(ra.LeasingOrderOtherCharges__c != null){
                                                LeasingOrderOtherCharges.add(new LeasingOrdersOtherCharges__c(Id = ra.LeasingOrderOtherCharges__c, PaymentStatus__c = PAYMENT_REVERSE_STATUS));
                                            }
            }
            if(!childAllocations.isEmpty()){
                service.updateLeasingReceiptAllocations(childAllocations);
            }
            if(!PaymentPlanSchedules.isEmpty()){
                LeasingPaymentScheduleService.getInstance().updatePaymentPlanSchedules(PaymentPlanSchedules);
            }
            if(!LeasingOrderOtherCharges.isEmpty()){
                LeasingOtherChargesService.getInstance().updateLeasingOtherCharges(LeasingOrderOtherCharges);
            }

        }
    }
    
    public static void createDocuments(List<LeasingReceiptAcknowledgment__c> newList , Map<Id,LeasingReceiptAcknowledgment__c> newMap){
        
        DocumentService objDocumentService = DocumentService.getInstance();
        List<DocumentType__c> leasingAckDocTypeList = objDocumentService.getDocTypes(LEASING_RECEIPT_ACKNOWLEDGEMENT);
        List<Document__c> documentList = new List<Document__c>();
        List<LeasingReceiptAcknowledgment__c> leasingAcks = LeasingReceiptAcknowledgementService.getLeasingReceiptAcknowledgementByIds(newMap.keySet());
        for(LeasingReceiptAcknowledgment__c leasingAck :leasingAcks)
        {
            for(DocumentType__c objDocumentType :leasingAckDocTypeList)
            {
             documentList.add(new Document__c(LeasingReceiptAcknowledgment__c = leasingAck.Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c));  
            }
        }
        objDocumentService.insertDocuments(documentList);   
    }   
    
    public static void updateCreditBalanceOnLO(List<LeasingReceiptAcknowledgment__c> newList,Map<Id,LeasingReceiptAcknowledgment__c> oldAckMap){
        Set<Id> orderIds = new Set<Id>();
        Map<Id, Decimal> orderToSum = new Map<Id, Decimal>();
        if(oldAckMap == Null){
            for(LeasingReceiptAcknowledgment__c allocation : newList){
                if(allocation.LeasingOrder__c != Null){
                    orderIds.add(allocation.LeasingOrder__c);   
                }
            }
        }
        if(oldAckMap != Null){
            for(LeasingReceiptAcknowledgment__c allocation : newList){
                if(allocation.Amount__c != oldAckMap.get(allocation.Id).Amount__c)
                orderIds.add(allocation.LeasingOrder__c); 
            }
        }

        if(!orderIds.isEmpty()){
            for (AggregateResult ar : [
            SELECT LeasingOrder__c orderId,
                   SUM(UnappliedAmount__c) total
            FROM 	LeasingReceiptAcknowledgment__c
            WHERE LeasingOrder__c IN :orderIds and SAPReversalDocumentNumber__c = Null
            GROUP BY LeasingOrder__c
        ]) {
                orderToSum.put(
                    (Id) ar.get('orderId'),
                    (Decimal) ar.get('total')
                );
            }
            System.debug('Map>>'+orderToSum);
        }
        if(!orderToSum.isEmpty()){
            List<LeasingOrder__c> updateLOList = LeasingOrderService.getInstance().getLeasingOrdersByIds(orderToSum.keySet());
            System.debug('List>>'+json.serialize(updateLOList));
            For(LeasingOrder__c lo : updateLOList){
                lo.CreditBalance__c = lo.MasterLeasingOrder__c != null && (lo.MasterLeasingOrder__r.CreditBalance__c != Null && lo.MasterLeasingOrder__r.CreditBalance__c != 0) 
                    ? lo.MasterLeasingOrder__r.CreditBalance__c + orderToSum.get(lo.Id) :
                orderToSum.get(lo.Id);
                // lo.CreditBalance__c = lo.MasterLeasingOrder__r != null && (lo.MasterLeasingOrder__r.CreditBalance__c != Null || lo.MasterLeasingOrder__r.CreditBalance__c != 0) 
                // ? lo.MasterLeasingOrder__r.CreditBalance__c + orderToSum.get(lo.Id) :
                // orderToSum.get(lo.Id);
            }
            if(!updateLOList.isEmpty()){
                LeasingOrderService.getInstance().updateLeasingOrders(updateLOList);
            }
        }
    }

    public static void updatePaymentDocNumber(List<LeasingReceiptAcknowledgment__c> newList, Map<Id,LeasingReceiptAcknowledgment__c>  oldAckMap){
        Map<Id,LeasingReceiptAcknowledgment__c> requiredAck = new Map<Id, LeasingReceiptAcknowledgment__c>();
        Map<Id,PaymentPlanSchedule__c> pps = new Map<Id,PaymentPlanSchedule__c>();
        Map<Id,LeasingOrdersOtherCharges__c> oc = new Map<Id,LeasingOrdersOtherCharges__c>();
        for(LeasingReceiptAcknowledgment__c rcpt : newList){
            if(rcpt.SAPDocumentNumber__c != Null && rcpt.SAPDocumentNumber__c != oldAckMap.get(rcpt.Id).SAPDocumentNumber__c){
                requiredAck.put(rcpt.Id, rcpt);
            }
        }
        if(!requiredAck.isEmpty() && requiredAck.size()>0){
            for(LeasingReceiptAllocation__c allocation : LeasingReceiptAllocationService.getInstance().getChildAllocations(requiredAck.keySet())){
                if(allocation.PaymentPlanSchedule__c != null){
                    pps.put( allocation.PaymentPlanSchedule__c, new PaymentPlanSchedule__c(
                        Id = allocation.PaymentPlanSchedule__c, 
                        Paymentdocumentnumber__c = requiredAck.get(allocation.LeasingReceiptAcknowledgment__c).SAPDocumentNumber__c,
                        PaymentStatus__c = allocation.PaymentPlanSchedule__r.DueAmount__c != 0 ? 'Un Paid' : 'Paid'));
                }
                if(allocation.LeasingOrderOtherCharges__c != Null){
                    
                    oc.put(allocation.LeasingOrderOtherCharges__c, new LeasingOrdersOtherCharges__c(
                        Id = allocation.LeasingOrderOtherCharges__c, 
                        Paymentdocumentnumber__c = requiredAck.get(allocation.LeasingReceiptAcknowledgment__c).SAPDocumentNumber__c,
                        PaymentStatus__c = allocation.LeasingOrderOtherCharges__r.DueAmount__c != 0 ? 'Un Paid' : 'Paid' ));
                }
            }

            if(!pps.isEmpty()){
                LeasingPaymentScheduleService.getInstance().updatePaymentPlanSchedules(pps.values());
            }
            if(!oc.isEmpty()){
                LeasingOtherChargesService.getInstance().updateLeasingOtherCharges(oc.values());
            }
        }
    }
}