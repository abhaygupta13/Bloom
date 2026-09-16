/*****************************************************************************************
Class       : SalesOrderRebateService
Author      : Dhanraj
Description : SalesOrderRebateService
Test Class  : 
Created Date: 10 JUL 2026  
*****************************************************************************************/
public inherited sharing class SalesOrderRebateService {
    private static SalesOrderRebateService instance;
    
    private SalesOrderRebateService() {
    }
    
    public static SalesOrderRebateService getInstance() { 
        if(instance == null) {
            instance = new SalesOrderRebateService();
        }
        return instance;
    }
    
    public List<SalesOrderRebate__c> getSalesOrderRebatesByIds(Set<Id> rebateIds){
        return [SELECT Id,Name,SalesOrder__c,Amount__c,SendtoSAP__c,SAP_Document_No__c,IntegrationStatus__c,IntegrationMessage__c,
                ConditionType__c,Date__c,SalesOrder__r.Company_Code__c,SalesOrder__r.SAP_Contract_No__c
                FROM SalesOrderRebate__c WHERE Id IN :rebateIds];
    }
    
    public List<AggregateResult> getTotalRebateByInstallments(Set<Id> installmentLineIds){
        return [SELECT InstallmentLine__c installmentId,SUM(Amount__c) totalRebate FROM SalesOrderRebate__c
                WHERE InstallmentLine__c IN :installmentLineIds GROUP BY InstallmentLine__c];
    }
    
    public IntegrationRecord__c createRebateIntegrationRecord(SalesOrderRebate__c rebateCharge, String action){
        IntegrationRecordService objIntegrationRecordService = IntegrationRecordService.getInstance();
        Map<String, String> paramMap = new Map<String, String>();
        paramMap.put('Param1', rebateCharge.SalesOrder__r != null ? rebateCharge.SalesOrder__r.Company_Code__c : '');
        paramMap.put('Param2', rebateCharge.SalesOrder__r != null ? rebateCharge.SalesOrder__r.SAP_Contract_No__c : '');
        paramMap.put('Param3', rebateCharge.ConditionType__c);
        paramMap.put('Param4', String.valueOf(rebateCharge.Date__c));
        paramMap.put('Param5', String.valueOf(rebateCharge.Amount__c));
        paramMap.put('Param6', '0');
        paramMap.put('Param7', '');
        paramMap.put('Param8', '');
        paramMap.put('Param15', action == 'Insert' ?  'X' : '');
        
        String invoiceNumber = rebateCharge.SAP_Document_No__c != NULL ? rebateCharge.SAP_Document_No__c : '';
        if(String.isNotEmpty(invoiceNumber)){
            List<String> documentNumberList = invoiceNumber.contains('/') ? invoiceNumber.split('/') : null;
            invoiceNumber = (documentNumberList.size() == 3) ? documentNumberList[1] : null;
        }
        
        return objIntegrationRecordService.getIntegrationRecord(action, 'SalesOrderRebate__c', String.valueOf(rebateCharge.Id), paramMap);
    }
}