/*****************************************************************************************
Class       : SalesOrderRebateTriggerHelper
Author      : Dhanraj Poojary
Description : SalesOrderRebateTriggerHelper
Test Class  : SalesOrderRebateTriggerHandlerTest
Created Date: 10 JUL 2026 
*****************************************************************************************/

public without sharing class SalesOrderRebateTriggerHelper {

    private static final String INSERT_STR = 'Insert';
    private static final String UPDATE_STR = 'Update';
    private static final Map<String, String> CHARGE_VS_CONDITION_TYPE = new Map<String, String>{
        'Salesorder Rebate' => 'RebateConditionType__c' };

    public static void handleBeforeInsert(List<SalesOrderRebate__c> newList){
        Set<Id> orderIds = new Set<Id>();
        for(SalesOrderRebate__c rebate : newList){
            if(rebate.SendtoSAP__c){
                rebate.IntegrationStatus__c = 'In Progress';
                rebate.IntegrationMessage__c = '';
            }
            if(rebate.SalesOrder__c != null){
                orderIds.add(rebate.SalesOrder__c);
            }
            populateConditionType(newList,orderIds); 
        }
    }

    public static void handleAfterInsert(List<SalesOrderRebate__c> newList){
        IntegrationRecordService integrationService = IntegrationRecordService.getInstance();
        SalesOrderRebateService rebateService = SalesOrderRebateService.getInstance();
        Set<Id> rebateIds = new Set<Id>();
        Set<Id> installmentIds = new Set<Id>();
        List<IntegrationRecord__c> integrationRecords = new List<IntegrationRecord__c>();

        for(SalesOrderRebate__c rebate : newList){
            rebateIds.add(rebate.Id);
            if(rebate.InstallmentLine__c != null){
                installmentIds.add(rebate.InstallmentLine__c);
            }
        }
        
        if(!installmentIds.isEmpty()){
            updateInstallmentRebateAmount(installmentIds);
        }
        
        if(!rebateIds.isEmpty()){
            List<SalesOrderRebate__c> rebateList = rebateService.getSalesOrderRebatesByIds(rebateIds);
            for(SalesOrderRebate__c rebate : rebateList){
                integrationRecords.add(rebateService.createRebateIntegrationRecord(rebate,INSERT_STR));
            }
            integrationService.insertIntegrationRecords(integrationRecords);
        }
    }

    public static void handleBeforeUpdate(List<SalesOrderRebate__c> newList,Map<Id, SalesOrderRebate__c> oldMap){
        for(SalesOrderRebate__c rebate : newList){
            if(rebate.SendtoSAP__c && !oldMap.get(rebate.Id).SendtoSAP__c){
                rebate.IntegrationStatus__c = 'In Progress';
                rebate.IntegrationMessage__c = '';
            }
        }
    }
    
    public static void handleAfterUpdate(List<SalesOrderRebate__c> newList,Map<Id, SalesOrderRebate__c> oldMap){
        Set<Id> rebateIds = new Set<Id>();
        Set<Id> installmentIds = new Set<Id>();
        SalesOrderRebateService rebateService = SalesOrderRebateService.getInstance();
        
        for(SalesOrderRebate__c rebate : newList){
            if(rebate.InstallmentLine__c != null){
                installmentIds.add(rebate.InstallmentLine__c);
            }
            SalesOrderRebate__c oldRebate = oldMap.get(rebate.Id);
            if(oldRebate.InstallmentLine__c != null){
                installmentIds.add(oldRebate.InstallmentLine__c);
            }
            if(!oldMap.get(rebate.Id).SendtoSAP__c && rebate.SendtoSAP__c){
                rebateIds.add(rebate.Id);
            }
        }
        
        if(!installmentIds.isEmpty()){
            updateInstallmentRebateAmount(installmentIds);
        }
        
        if(!rebateIds.isEmpty()){
            IntegrationRecordService integrationService = IntegrationRecordService.getInstance();
            List<IntegrationRecord__c> integrationRecords = new List<IntegrationRecord__c>();
            List<SalesOrderRebate__c> rebateList = rebateService.getSalesOrderRebatesByIds(rebateIds);
            for(SalesOrderRebate__c rebate : rebateList){
                String action = rebate.SAP_Document_No__c != null ? UPDATE_STR : INSERT_STR;
                integrationRecords.add(rebateService.createRebateIntegrationRecord(rebate,action));
            }
            integrationService.insertIntegrationRecords(integrationRecords);
        }
    }
    
    public static void populateConditionType(List<SalesOrderRebate__c> newList, Set<Id> orderIds) {
        Map<Id, SalesOrder__c> orderMap = new Map<Id, SalesOrder__c>(SalesOrderService.getInstance().getSalesOrdersByIds(orderIds));
        for (SalesOrderRebate__c rebate : newList) {
            String condTypeField = CHARGE_VS_CONDITION_TYPE.get('Salesorder Rebate');
            SalesOrder__c order = orderMap.get(rebate.SalesOrder__c);
            if (!String.isEmpty(condTypeField)) {
                if (order != null && order.Unit__c != null && order.Unit__r.Project__c != null) {
                    rebate.ConditionType__c = String.valueOf(order.Unit__r.Project__r.get(condTypeField));
                }
            }
        }
    }
    
    private static void updateInstallmentRebateAmount(Set<Id> installmentLineIds){
        InstallmentLineService installmentService = InstallmentLineService.getInstance();
        SalesOrderRebateService rebateService = SalesOrderRebateService.getInstance();
        if(installmentLineIds.isEmpty()){
            return;
        }
        
        Map<Id, Decimal> installmentVsRebate = new Map<Id, Decimal>();
        List<AggregateResult> lstAggRebate = rebateService.getTotalRebateByInstallments(installmentLineIds);
        for(AggregateResult ar : lstAggRebate){
            installmentVsRebate.put((Id)ar.get('installmentId'),(Decimal)ar.get('totalRebate'));
        }
        
        List<InstallmentLines__c> installmentList = new List<InstallmentLines__c>();
        for(Id installmentId : installmentLineIds){
            installmentList.add(new InstallmentLines__c(Id = installmentId,TotalRebateAmount__c = installmentVsRebate.containsKey(installmentId) ? installmentVsRebate.get(installmentId) : 0));
        }
        
        installmentService.updateInstallmentLines(installmentList);
    }
}