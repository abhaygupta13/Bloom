public class LeasingOtherChargesTriggerHelper {
    public static Boolean bypassIntegration = false;
    private static final string LEASING_OTHERCHARGE { get { return 'LeasingOrdersOtherCharges__c'; } }
    private static final string ORGANIZATION_TYPE { get { return 'Organization'; } }
    
    public static void beforeInsertActions(List<LeasingOrdersOtherCharges__c> newList) {
        Set<Id> leasingOrderIds = new Set<Id>();        
        for (LeasingOrdersOtherCharges__c charge : newList) {
            if (charge.LeasingOrder__c != null && charge.type__c == 'CheckoutDamage Recovery Charge') {
                leasingOrderIds.add(charge.LeasingOrder__c);
            }
        }
        
        if (leasingOrderIds.isEmpty()) return;
        
        DocumentService objDocumentService = DocumentService.getInstance();
        List<Document__c> docList = objDocumentService.getLeasingSignDocuments(leasingOrderIds, new List<String>{'Checkout Form'});
        
        Set<Id> ordersWithoutCheckoutDoc = new Set<Id>(leasingOrderIds);
        
        if (docList != null) {
            for (Document__c doc : docList) {
                if (doc == null) continue; 
                
                if (String.isNotBlank(doc.Content_Version_Id__c) && 
                    String.isNotBlank(doc.ContentDocumentId__c) && 
                    String.isNotBlank(doc.LeasingOrder__c)) {
                        
                        ordersWithoutCheckoutDoc.remove(doc.LeasingOrder__c);
                    }
            }
        }
        
        for (LeasingOrdersOtherCharges__c charge : newList) {
            if (charge.LeasingOrder__c != null && charge.type__c == 'CheckoutDamage Recovery Charge' && ordersWithoutCheckoutDoc.contains(charge.LeasingOrder__c)) {
                
                charge.addError('Checkout form document must be uploaded before creating other charges.');
            }
        }
    }
    
    public static void afterInsertActions(List<LeasingOrdersOtherCharges__c> newList, Map<Id,LeasingOrdersOtherCharges__c> newMap){
        //for SAP integration
        Set<Id> leasingOrderOtherChargeIds = new Set<Id>();
        for(LeasingOrdersOtherCharges__c leasingOrderOtherCharge : newList){
            if(leasingOrderOtherCharge.SendToSAP__c != Null && leasingOrderOtherCharge.SendToSAP__c){
                leasingOrderOtherChargeIds.add(leasingOrderOtherCharge.Id);
            }
        }
        if (!leasingOrderOtherChargeIds.isEmpty()) {
            integrateRecords(leasingOrderOtherChargeIds);
        }
    }
    
    public static void beforeFieldUpdates(List<LeasingOrdersOtherCharges__c> newList , Map<id,LeasingOrdersOtherCharges__c> oldMap){
        List<Schema.FieldSetMember> sapFieldSetFields = Schema.SObjectType.LeasingOrdersOtherCharges__c.fieldSets.getMap().get('SAP_Integration_Fields').getFields();
        
        Set<Id> leasingOrderIds = new Set<Id>();
        Set<Id> leasingOrderIdsAPI = new Set<Id>();
        
        for (LeasingOrdersOtherCharges__c leasingOtherCharge : newList) {
            leasingOrderIdsAPI.add(leasingOtherCharge.LeasingOrder__c);
            if (oldMap != null && leasingOtherCharge.PostingDate__c != null)// && leasingOtherCharge.PostingDate__c != oldMap.get(leasingOtherCharge.Id).PostingDate__c)
                leasingOrderIds.add(leasingOtherCharge.LeasingOrder__c);
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
        
        for(LeasingOrdersOtherCharges__c leasingOtherCharge  : newList ){
            if(oldMap != null){
                if (leasingOtherCharge.PostingDate__c != null){// && leasingOtherCharge.PostingDate__c != oldMap.get(leasingOtherCharge.Id).PostingDate__c) {
                        
                        Date postingClosureDate = loToPCDateMap.get(leasingOtherCharge.LeasingOrder__c);
                        if (postingClosureDate != null) {
                            
                            Integer closurePeriod = (postingClosureDate.year() * 12) + postingClosureDate.month();
                            Integer postingPeriod = (leasingOtherCharge.PostingDate__c.year() * 12) + leasingOtherCharge.PostingDate__c.month();
                            
                            if (postingPeriod <= closurePeriod) {
                                leasingOtherCharge.PostingDate__c.addError('Posting date is outside the posting range.');
                            }
                        }
                    }
                
                if(leasingOtherCharge.ClearedAmount__c == leasingOtherCharge.TotalAmount__c && leasingOtherCharge.PaymentDocumentNumber__c != null){
                    leasingOtherCharge.PaymentStatus__c = 'Paid';
                }
                if(leasingOtherCharge.RefDocno__c != oldMap.get(leasingOtherCharge.Id).RefDocno__c && leasingOtherCharge.PaymentDocumentNumber__c == null){
                    leasingOtherCharge.paymentStatus__c = 'Un Paid';
                }
                if (leasingOtherCharge.PaymentStatus__c == 'Un Paid' && leasingOtherCharge.Paymentdoc__c != null && leasingOtherCharge.Paymentdoc__c != oldMap.get(leasingOtherCharge.Id).Paymentdoc__c ) { 
                    leasingOtherCharge.PaymentStatus__c = 'Reversed';
                }
                if(bypassIntegration && leasingOtherCharge.PaymentDocumentNumber__c != null)
                    continue;
                LeasingOrder__c leasingOrder = leasingOrderMap.get(leasingOtherCharge.LeasingOrder__c);
                
                // Set the SendToSAP__c field only if the Leasing Order has a SAP Contract Id
                if (leasingOrder != null &&
                    !String.isBlank(leasingOrder.LeasingSAPContractId__c) &&
                    String.isBlank(leasingOtherCharge.RefDocno__c)) {
                        
                        for (FieldSetMember member : sapFieldSetFields) {
                            String field = member.getFieldPath();
                            if (leasingOtherCharge.get(field) != oldMap.get(leasingOtherCharge.Id).get(field)) {
                                leasingOtherCharge.SendToSAP__c = true;
                                break;
                            }
                        }
                    }
                if(!oldMap.get(leasingOtherCharge.Id).SendToSAP__c && leasingOtherCharge.SendToSAP__c){
                    leasingOtherCharge.IntegrationStatus__c = 'In Progress';
                }
            }
        }
    }
    
    public static void afterFieldUpdates(List<LeasingOrdersOtherCharges__c> newList , Map<id,LeasingOrdersOtherCharges__c> oldMap){        
        Set<Id> leasingOrderOtherChargeIds = new Set<Id>();
        Set<Id> integratedOCIds = new Set<Id>();
        
        for(LeasingOrdersOtherCharges__c leasingOrderOtherCharge : newList){
            
            if(oldMap != null && leasingOrderOtherCharge.PaymentStatus__c  != 'Paid'){
                
                if (!oldMap.get(leasingOrderOtherCharge.Id).SendToSAP__c && leasingOrderOtherCharge.SendToSAP__c) {
                    leasingOrderOtherChargeIds.add(leasingOrderOtherCharge.Id);
                }
            }
            
            if(oldMap != null && oldMap.get(leasingOrderOtherCharge.Id).IntegrationStatus__c != leasingOrderOtherCharge.IntegrationStatus__c && leasingOrderOtherCharge.IntegrationStatus__c == 'Success' && !leasingOrderOtherCharge.SendToSAP__c && String.isBlank(oldMap.get(leasingOrderOtherCharge.Id).RefDocno__c ) && String.isNotBlank(leasingOrderOtherCharge.RefDocno__c)){
                integratedOCIds.add(leasingOrderOtherCharge.Id);
            }
        }
        
        if (!leasingOrderOtherChargeIds.isEmpty()) {
            // LeasingOtherChargesService leasingOrderOtherChargeService = LeasingOtherChargesService.getInstance();
            // List<IntegrationRecord__c> integrationRecordsToInsert = new List<IntegrationRecord__c>();
            // List<LeasingOrdersOtherCharges__c> leasingOrderOtherChargesList = leasingOrderOtherChargeService.getLeasingOtherChargesByIds(leasingOrderOtherChargeIds);
            // for(LeasingOrdersOtherCharges__c leasingOrderOtherCharge : leasingOrderOtherChargesList ){
            //     integrationRecordsToInsert.add(leasingOrderOtherChargeService.getLeasingOtherChargeRecords(leasingOrderOtherCharge));
            // }
            // IntegrationRecordService integService = IntegrationRecordService.getInstance();
            // integService.insertIntegrationRecords(integrationRecordsToInsert);
            integrateRecords(leasingOrderOtherChargeIds);
        }
        
        if(!integratedOCIds.isEmpty()){
            List<LeasingReceiptAcknowledgment__c> leasingReceipts = LeasingReceiptAcknowledgementService.getChildLeasingReceiptForIntegration(integratedOCIds);
            
            for (LeasingReceiptAcknowledgment__c lra : leasingReceipts) {
                lra.SendToSAP__c = true;
            }
            
            List<LeasingReceiptAcknowledgment__c> updatedLRA = LeasingReceiptAcknowledgementService.getInstance().updateLeasingReceiptAcknowledgement(leasingReceipts);
        }
        
    }
    
    public static void integrateRecords(Set<Id> leasingOrderOtherChargeIds){
        LeasingOtherChargesService leasingOrderOtherChargeService = LeasingOtherChargesService.getInstance();
        List<IntegrationRecord__c> integrationRecordsToInsert = new List<IntegrationRecord__c>();
        List<LeasingOrdersOtherCharges__c> leasingOrderOtherChargesList = leasingOrderOtherChargeService.getLeasingOtherChargesByIds(leasingOrderOtherChargeIds);
        for(LeasingOrdersOtherCharges__c leasingOrderOtherCharge : leasingOrderOtherChargesList ){
            integrationRecordsToInsert.add(leasingOrderOtherChargeService.getLeasingOtherChargeRecords(leasingOrderOtherCharge));
        }
        IntegrationRecordService integService = IntegrationRecordService.getInstance();
        integService.insertIntegrationRecords(integrationRecordsToInsert);
    }
    
    public static void applyVatOnCreate(List<LeasingOrdersOtherCharges__c> newList) {
        LeasingOtherChargesService ocService = LeasingOtherChargesService.getInstance();
        Map<String, String> TYPE_TO_CONDITIONTYPE_MAP = ocService.getTypeToConditionTypeMap();
        Map<String, String> TYPE_TO_SUBCATEGORY_MAP = ocService.getTypeToSubCategoryMap();
        
        // Set<String> vatConditionTypes = new Set<String>{
        //     'R002','R003','R004','R005','R007','R008','R009','R010','R063','R064',
        //         'R013','R014','R015','R016','R019','R023','R024','R056','R058',
        //         'R025','R028','R029','R035','R036','R037','R053','R055','R100'
        //         };
        StaticResource sr = [SELECT Body FROM StaticResource WHERE Name = 'leasingOCVatConditionTypes' LIMIT 1];
        
        List<String> vatConditionTypeList = (List<String>)JSON.deserialize(sr.Body.toString(),List<String>.class);
        
        Set<String> vatConditionTypes = new Set<String>(vatConditionTypeList);
        
        for (LeasingOrdersOtherCharges__c charge : newList) {
            charge.ConditionType__c = TYPE_TO_CONDITIONTYPE_MAP.get(charge.Type__c);
            charge.SubCategory__c = TYPE_TO_SUBCATEGORY_MAP.get(charge.Type__c);
            
            if (charge.ConditionType__c != null &&
                vatConditionTypes.contains(charge.ConditionType__c) && !charge.RelatedPartyBloomHolding__c) {
                    charge.isVATApplied__c = true;
                    charge.VATAmount__c = charge.ChargeAmount__c*5/100;
                }
        }
    }
    public static void createDocuments(List<LeasingOrdersOtherCharges__c> newList , Map<Id,LeasingOrdersOtherCharges__c> newMap){
        
        DocumentService objDocumentService = DocumentService.getInstance();
        List<DocumentType__c> leasingContractDocTypeList = objDocumentService.getDocTypes(LEASING_OTHERCHARGE);
        List<Document__c> documentList = new List<Document__c>();
        List<LeasingOrdersOtherCharges__c> leasingOtherCharges = LeasingOtherChargesService.getInstance().getLeasingOtherChargesByIds(newMap.keySet());
        for(LeasingOrdersOtherCharges__c leasingOtherCharge :leasingOtherCharges)
        {
            for(DocumentType__c objDocumentType :leasingContractDocTypeList)
            {
                // if (objDocumentType.Customer_Type__c == ORGANIZATION_TYPE && !leasingOtherCharge.LeasingOrder__r.Opportunity__r.Account.IsPersonAccount){
                documentList.add(new Document__c(LeasingOrdersOtherCharges__c = leasingOtherCharge.Id, DocumentType__c = objDocumentType.Id, Document_Name__c = objDocumentType.Type__c));
                // }
            }
        }
        objDocumentService.insertDocuments(documentList);   
    }
    
}