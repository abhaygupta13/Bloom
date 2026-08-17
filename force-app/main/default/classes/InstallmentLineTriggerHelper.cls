/*
* @Author : Biswajeet Samal
* @CreatedDate : 26th AUG 2024
* @Description : InstallmentLine object trigger helper
*/
/*****************************************************************************************************
* Version       Author      	Date             Comment                                                                       
* 2.0           Jayprakash   	12AUG2024        created
*****************************************************************************************************/

public without sharing class InstallmentLineTriggerHelper {
    
    private static final string INSTALLMENT_LINE_INTEGRATION_STATUS_IN_PROGRESS { get { return 'In Progress'; } }
    
    public static void handleBeforeInsert(List<InstallmentLines__c> newList){
        Set<Id> paymentInstallmentIdSet = new Set<Id>();

        for (InstallmentLines__c inst : newList) {            
            if (inst.Inst_Amount_incl_tax__c != null){
                inst.Inst_inc_tax_in_words__c = Utilities.amountInWords(inst.Inst_Amount_incl_tax__c, 'Dirham', 'Fils');
            }
            if(inst.InstallmentAmount__c != null){                
                inst.InstallmentAmountintheWords__c = Utilities.amountInWords(inst.InstallmentAmount__c, 'Dirham', 'Fils');
            }
            if (inst.Send_to_SAP__c) {
                inst.IntegrationStatus__c = INSTALLMENT_LINE_INTEGRATION_STATUS_IN_PROGRESS;
            }
           
            if(inst.PaymentInstallments__c != NULL){
                paymentInstallmentIdSet.add(inst.PaymentInstallments__c);
            }
        }

        if(paymentInstallmentIdSet != NULL && paymentInstallmentIdSet.size() > 0){
            Map<Id, PaymentInstallments__c> paymentInstallmentsMap = new Map<Id, PaymentInstallments__c>([SELECT Id, DescriptionArabic__c FROM PaymentInstallments__c WHERE Id IN :paymentInstallmentIdSet AND DescriptionArabic__c != NULL]);
            for (InstallmentLines__c inst : newList) {
                if (inst.PaymentInstallments__c != NULL && paymentInstallmentsMap.containsKey(inst.PaymentInstallments__c)) {
                    inst.ArabicDescription__c = paymentInstallmentsMap.get(inst.PaymentInstallments__c).DescriptionArabic__c;
                }
            }
        }
    }
    
    public static void handleBeforeUpdate(List<InstallmentLines__c> newList, Map<Id, InstallmentLines__c> oldMap){
        Set<Id> paymentInstallmentIdSet = new Set<Id>();
        for (InstallmentLines__c inst : newList) {
            if (inst.Inst_Amount_incl_tax__c != null && inst.Inst_Amount_incl_tax__c != oldMap.get(inst.Id).Inst_Amount_incl_tax__c) {
                inst.Inst_inc_tax_in_words__c = Utilities.amountInWords(inst.Inst_Amount_incl_tax__c, 'Dirham', 'Fils');
            }
            if (inst.RevisedDate__c != null && inst.RevisedDate__c != oldMap.get(inst.Id).RevisedDate__c) {
                if(inst.SalesOrder__r.Resale__c && inst.SalesOrder__r.Status__c !='Sold'){
                    return;
                }
                else{
                    inst.Send_to_SAP__c = true;
                }
                   
            }
            if (inst.Send_to_SAP__c && !oldMap.get(inst.Id).Send_to_SAP__c) {
                inst.IntegrationStatus__c = INSTALLMENT_LINE_INTEGRATION_STATUS_IN_PROGRESS;
            }

            if(inst.PaymentInstallments__c != NULL && inst.PaymentInstallments__c != oldMap.get(inst.Id).PaymentInstallments__c){
                paymentInstallmentIdSet.add(inst.PaymentInstallments__c);
            }
        }

        if(paymentInstallmentIdSet != NULL && paymentInstallmentIdSet.size() > 0){
            Map<Id, PaymentInstallments__c> paymentInstallmentsMap = new Map<Id, PaymentInstallments__c>([SELECT Id, DescriptionArabic__c FROM PaymentInstallments__c WHERE Id IN :paymentInstallmentIdSet AND DescriptionArabic__c != NULL]);
            for (InstallmentLines__c inst : newList) {
                if (inst.PaymentInstallments__c != NULL && paymentInstallmentsMap.containsKey(inst.PaymentInstallments__c)) {
                    inst.ArabicDescription__c = paymentInstallmentsMap.get(inst.PaymentInstallments__c).DescriptionArabic__c;
                }
            }
        }
    }
    
    public static void handleAfterUpdate(List<InstallmentLines__c> newList, Map<Id, InstallmentLines__c> oldMap){
        Set<Id> installmentIds = new Set<Id>();
        Set<Id> installmentWithDocIds = new Set<Id>();
        Map<Id,InstallmentLines__c> salesOrderIdToHandoverInstallmentMap = new Map<Id,InstallmentLines__c>();
        InstallmentLineService objInstallmentLineService = InstallmentLineService.getInstance();
        List<InstallmentLines__c> linesToUpdate = new List<InstallmentLines__c>();

        for(InstallmentLines__c installmentLine : newList){
            if(!oldMap.get(installmentLine.Id).Send_to_SAP__c && installmentLine.Send_to_SAP__c){
                installmentIds.add(installmentLine.Id);
            }
            if(installmentLine.Type__c == 'Handover' && installmentLine.InstallmentDate__c != NULL && installmentLine.RevisedDate__c != NULL && installmentLine.RevisedDate__c != oldMap.get(installmentLine.Id).RevisedDate__c){
                salesOrderIdToHandoverInstallmentMap.put(installmentLine.SalesOrder__c, installmentLine);
            }
        }
        
        if(!installmentIds.isEmpty()){
            IntegrationRecordService objIntegrationRecordService = IntegrationRecordService.getInstance();
            List<IntegrationRecord__c> objIntegrationRecordList = objInstallmentLineService.getInstallmentIntegrationRecords(installmentIds);
            objIntegrationRecordService.insertIntegrationRecords(objIntegrationRecordList);
        }

        if(!salesOrderIdToHandoverInstallmentMap.isEmpty()){
            List<InstallmentLines__c> installmentLinesList = objInstallmentLineService.getPostHandoverInstallmentLinesBySalesOrderIds(salesOrderIdToHandoverInstallmentMap.keySet());
            for (InstallmentLines__c insRec : installmentLinesList) {
                if (insRec.InstallmentDate__c != null && insRec.SalesOrder__c != NULL) {
                    Integer monthsInBetween = salesOrderIdToHandoverInstallmentMap.get(insRec.SalesOrder__c).InstallmentDate__c.monthsBetween(insRec.InstallmentDate__c);
                    insRec.RevisedDate__c = salesOrderIdToHandoverInstallmentMap.get(insRec.SalesOrder__c).RevisedDate__c.addMonths(monthsInBetween);
                    insRec.Send_to_SAP__c = true;
                    linesToUpdate.add(insRec);
                }
            }
            objInstallmentLineService.updateInstallmentLines(linesToUpdate);
        }
    
        /*if(!installmentWithDocIds.isEmpty()){
            ReceiptAllocationService objReceiptAllocationService = ReceiptAllocationService.getInstance();
            ReceiptAcknowledgementService objReceiptAcknowledgementService = ReceiptAcknowledgementService.getInstance();
            List<ReceiptAllocation__c> objReceiptAllocationList = objReceiptAllocationService.getReceiptAllocationByInstallment(installmentWithDocIds);
            
            Map<Id,ReceiptAcknowledgement__c> objReceiptAcknowledgementMap = new Map<Id,ReceiptAcknowledgement__c>();
            for(ReceiptAllocation__c objReceiptAllocation :objReceiptAllocationList){
                objReceiptAcknowledgementMap.put(objReceiptAllocation.ReceiptAcknowledgement__c, new ReceiptAcknowledgement__c(Id = objReceiptAllocation.ReceiptAcknowledgement__c, SendtoSAP__c = true));
            }
            objReceiptAcknowledgementService.updateReceiptAcknowledgements(objReceiptAcknowledgementMap.values());
        }*/      
    }
    
     public static void updateReceiptRevisedDate(List<InstallmentLines__c> newList, Map<Id, InstallmentLines__c> oldMap){
        Map<Id, Date> installmentAndDateMap = new Map<Id, Date>();
        InstallmentLineService objInstallmentLineService = InstallmentLineService.getInstance();
        
        for(InstallmentLines__c installmentLine : newList){
            if(oldMap.get(installmentLine.Id).RevisedDate__c != installmentLine.RevisedDate__c && installmentLine.RevisedDate__c != NULL){
                installmentAndDateMap.put(installmentLine.Id, installmentLine.RevisedDate__c);
            }
        }
        
        if(!installmentAndDateMap.isEmpty()){
            ReceiptAllocationService objReceiptAllocationService = ReceiptAllocationService.getInstance();
            ReceiptAcknowledgementService objReceiptAcknowledgementService = ReceiptAcknowledgementService.getInstance();
            List<ReceiptAllocation__c> objReceiptAllocationList = objReceiptAllocationService.getReceiptAllocationByInstallment(installmentAndDateMap.keySet());
            
            Map<Id,ReceiptAcknowledgement__c> objReceiptAcknowledgementMap = new Map<Id,ReceiptAcknowledgement__c>();
            for(ReceiptAllocation__c objReceiptAllocation :objReceiptAllocationList){
                objReceiptAcknowledgementMap.put(objReceiptAllocation.ReceiptAcknowledgement__c, new ReceiptAcknowledgement__c(Id = objReceiptAllocation.ReceiptAcknowledgement__c, New_Maturity_Date__c = installmentAndDateMap.get(objReceiptAllocation.InstallmentLine__c)));
            }
            objReceiptAcknowledgementService.updateReceiptAcknowledgementWithoutTrigger(objReceiptAcknowledgementMap.values());
        }        
    }

    public static void handleAfterInsert(List<InstallmentLines__c> newList){
        Set<Id> installmentIds = new Set<Id>();
        InstallmentLineService objInstallmentLineService = InstallmentLineService.getInstance();
        
        for(InstallmentLines__c installmentLine : newList){
            if(installmentLine.Send_to_SAP__c){
                installmentIds.add(installmentLine.Id); 
            }
        }
        if(!installmentIds.isEmpty()){
            IntegrationRecordService objIntegrationRecordService = IntegrationRecordService.getInstance();
            List<IntegrationRecord__c> objIntegrationRecordList = objInstallmentLineService.getInstallmentIntegrationRecords(installmentIds);
            objIntegrationRecordService.insertIntegrationRecords(objIntegrationRecordList);
        }
    }
}