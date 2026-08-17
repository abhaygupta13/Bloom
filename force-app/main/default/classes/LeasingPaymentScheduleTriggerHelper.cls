public class LeasingPaymentScheduleTriggerHelper {
    public static Boolean bypassIntegration = false;
    private static final string LEASING_PAYMENTPLAN { get { return 'PaymentPlanSchedule__c'; } }
    private static final string ORGANIZATION_TYPE { get { return 'Organization'; } } 
    
    public static void applyVatOnCreate(List<PaymentPlanSchedule__c> newList, Map<id,LeasingOrder__c> oldMap) {
        
        Set<Id> leasingOrderIds = new Set<Id>();
        for (PaymentPlanSchedule__c pps : newList) {
            if (pps.LeasingOrder__c != null) {
                leasingOrderIds.add(pps.LeasingOrder__c);
            }
        }
        
        if (leasingOrderIds.isEmpty()) return;
        
        LeasingPaymentScheduleService service =
            LeasingPaymentScheduleService.getInstance();
        
        Map<Id, LeasingOrder__c> leasingOrderMap =
            service.getLeasingOrdersWithPropertyUsage(leasingOrderIds);
        
        for (PaymentPlanSchedule__c pps : newList) {
            LeasingOrder__c lo = leasingOrderMap.get(pps.LeasingOrder__c);
            if (lo != null && lo.Unit__r.PropertyUsage__c == 'Commercial' && !pps.RelatedPartyBloomHolding__c) {
                pps.isVATApplied__c = true;
            }
        }
    }
    
    public static void beforeFieldUpdates(List<PaymentPlanSchedule__c> newList , Map<id,PaymentPlanSchedule__c> oldMap){
        System.debug('##called beforeFieldUpdates'); 
        List<Schema.FieldSetMember> sapFieldSetFields = Schema.SObjectType.PaymentPlanSchedule__c.fieldSets.getMap().get('SAP_Integration_Fields').getFields();
        Set<Id> leasingOrderIds = new Set<Id>();
        Set<Id> leasingOrderIdsAPI = new Set<Id>();
        
        for(PaymentPlanSchedule__c paymentPlan: newList){
            leasingOrderIdsAPI.add(paymentPlan.LeasingOrder__c);
            if (oldMap != null && paymentPlan.PostingDate__c != null)// && paymentPlan.PostingDate__c  != oldMap.get(paymentPlan.Id).PostingDate__c)
                leasingOrderIds.add(paymentPlan.LeasingOrder__c);
        }
        
        LeasingOrderService loService = LeasingOrderService.getInstance();
        List<LeasingOrder__c> leasingOrders = new List<LeasingOrder__c>();
        Map<Id, Date> loToPCDateMap = new Map<Id, Date>();
        Map<Id, LeasingOrder__c> leasingOrderMap =
            loService.getLeasingOrdersWithSAPContractId(leasingOrderIdsAPI);
        if(leasingOrderIds.Size() > 0){
            leasingOrders = loService.getLeasingOrdersByIds(leasingOrderIds);
            for (LeasingOrder__c lo : leasingOrders) {
                Date postingClosureDate;
                if (lo.Project__r != null && lo.Project__r.Leasing_Company__r != null) {
                    postingClosureDate = lo.Project__r.Leasing_Company__r.LeasingPostingClosureDate__c;
                }
                loToPCDateMap.put(lo.Id, postingClosureDate);
            }
        }
        for(PaymentPlanSchedule__c paymentPlan  : newList ){
            
            if (oldMap != null && paymentPlan.PostingDate__c != null){// && paymentPlan.PostingDate__c  != oldMap.get(paymentPlan.Id).PostingDate__c) {
                Date postingClosureDate = loToPCDateMap.get(paymentPlan.LeasingOrder__c);
                System.debug('##called postingClosureDate '+postingClosureDate);
                if (postingClosureDate != null) {
                    
                    Integer closurePeriod = (postingClosureDate.year() * 12) + postingClosureDate.month();
                    Integer postingPeriod = (paymentPlan.PostingDate__c.year() * 12) + paymentPlan.PostingDate__c.month();
                    
                    if (postingPeriod <= closurePeriod) {
                        paymentPlan.addError('Posting date is outside the posting range.');
                        System.debug('##called postingPeriod'+postingPeriod);
                    }
                }
            }
            
            if(paymentPlan.ClearedAmount__c == paymentPlan.TotalInstallmentAmount__c && paymentPlan.PaymentDocumentNumber__c != null){
                paymentPlan.PaymentStatus__c = 'Paid'; 
            }//could be duplicate..
            if(oldMap != null && paymentPlan.RefDocno__c != oldMap.get(paymentPlan.Id).RefDocno__c && paymentPlan.PaymentDocumentNumber__c == null){
                paymentPlan.PaymentStatus__c = 'Un Paid';
            }
            if (oldMap != null && paymentPlan.PaymentStatus__c == 'Un Paid' && paymentPlan.Paymentdoc__c != null && paymentPlan.Paymentdoc__c != oldMap.get(paymentPlan.Id).Paymentdoc__c ) { 
                paymentPlan.PaymentStatus__c = 'Reversed';
            }
            
            if((oldMap != null && paymentPlan.PaymentStatus__c != 'Paid')){
                if(bypassIntegration && paymentPlan.PaymentDocumentNumber__c != null)
                    continue;
                
                LeasingOrder__c leasingOrder = leasingOrderMap.get(paymentPlan.LeasingOrder__c);
                
                // Set the SendToSAP__c field only if the Leasing Order has a SAP Contract Id
                if (leasingOrder != null &&
                    !String.isBlank(leasingOrder.LeasingSAPContractId__c) &&
                    String.isBlank(paymentPlan.RefDocno__c)) {
                        
                        for (FieldSetMember member : sapFieldSetFields) {
                            String field = member.getFieldPath();
                            if (paymentPlan.get(field) != oldMap.get(paymentPlan.Id).get(field)) {
                                paymentPlan.SendToSAP__c = true;
                                break;
                            }
                        }
                    }
                if(!oldMap.get(paymentPlan.Id).SendToSAP__c && paymentPlan.SendToSAP__c){
                    paymentPlan.IntegrationStatus__c = 'In Progress';
                }
                /*if( (oldMap.get(paymentPlan.Id).ClearedAmount__c != paymentPlan.ClearedAmount__c) && 
paymentPlan.ClearedAmount__c == paymentPlan.TotalInstallmentAmount__c ){
paymentPlan.PaymentStatus__c = 'Paid';
}*/
            }
        }
    }
    
    public static void afterFieldUpdates(List<PaymentPlanSchedule__c> newList , Map<id,PaymentPlanSchedule__c> oldMap){        
        Set<Id> paymentPlanIds = new Set<Id>();
        Set<Id> integratedPaymentPlanIds = new Set<Id>();
        
        for(PaymentPlanSchedule__c paymentPlan : newList){
            
            if(oldMap != null){
                
                if (!oldMap.get(paymentPlan.Id).SendToSAP__c && paymentPlan.SendToSAP__c && paymentPlan.ShowSyncButton__c) {
                    paymentPlanIds.add(paymentPlan.Id);
                }
                
                if(oldMap.get(paymentPlan.Id).IntegrationStatus__c != paymentPlan.IntegrationStatus__c && paymentPlan.IntegrationStatus__c == 'Success' && !paymentPlan.SendToSAP__c  && String.isBlank(oldMap.get(paymentPlan.Id).RefDocno__c ) && String.isNotBlank(paymentPlan.RefDocno__c)){
                    integratedPaymentPlanIds.add(paymentPlan.Id);
                }
                
            }
        }
        
        if (!paymentPlanIds.isEmpty()) {
            LeasingPaymentScheduleService paymentPlanService = LeasingPaymentScheduleService.getInstance();
            List<IntegrationRecord__c> integrationRecordsToInsert = new List<IntegrationRecord__c>();
            List<PaymentPlanSchedule__c> paymentPlanList = paymentPlanService.getpaymentPlanByIds(paymentPlanIds);
            for(PaymentPlanSchedule__c paymentPlan : paymentPlanList ){
                integrationRecordsToInsert.add(paymentPlanService.getLeasingPaymentScheRecords(paymentPlan));
            }
            IntegrationRecordService integService = IntegrationRecordService.getInstance();
            integService.insertIntegrationRecords(integrationRecordsToInsert);
        }  
        
        if(!integratedPaymentPlanIds.isEmpty()){
            List<LeasingReceiptAcknowledgment__c> leasingReceipts = LeasingReceiptAcknowledgementService.getChildLeasingReceiptForIntegration(integratedPaymentPlanIds);
            
            for (LeasingReceiptAcknowledgment__c lra : leasingReceipts) {
                lra.SendToSAP__c = true;
            }
            
            List<LeasingReceiptAcknowledgment__c> updatedLRA = LeasingReceiptAcknowledgementService.getInstance().updateLeasingReceiptAcknowledgement(leasingReceipts);
        }
    }
    
    public static void createDocuments(List<PaymentPlanSchedule__c> newList , Map<Id,PaymentPlanSchedule__c> newMap){
        DocumentService objDocumentService = DocumentService.getInstance();
        List<DocumentType__c> leasingContractDocTypeList = objDocumentService.getDocTypes(LEASING_PAYMENTPLAN);
        List<Document__c> documentList = new List<Document__c>();
        List<PaymentPlanSchedule__c> leasingPaymentsplans = LeasingPaymentScheduleService.getInstance().getpaymentPlanByIds(newMap.keySet());
        for(PaymentPlanSchedule__c leasingPaymentsplan :leasingPaymentsplans)
        {
            for(DocumentType__c objDocumentType :leasingContractDocTypeList)
            {
                // if (objDocumentType.Customer_Type__c == ORGANIZATION_TYPE && !leasingPaymentsplan.LeasingOrder__r.Opportunity__r.Account.IsPersonAccount){
                
                documentList.add(new Document__c(PaymentPlanSchedule__c = leasingPaymentsplan.Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c));
                //}
            }
        }
        objDocumentService.insertDocuments(documentList);   
    }
    
}