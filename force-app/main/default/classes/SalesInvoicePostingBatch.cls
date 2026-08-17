/*****************************************************************************************
Class       : SalesInvoicePostingBatch
Author      : Biswajeet
Description : Batch to post the invoice to SAP
Test Class  : SalesInvoicePostingBatchTest
Created Date: 24 JUL 2025 
*****************************************************************************************/
public class SalesInvoicePostingBatch implements Database.Batchable<SObject>, Schedulable {
    
    private static final string MTD_SALES_INVOICE_POSTING_DATE { get { return 'SalesInvoicePostingDate'; } }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        MetadataService objMetadataService = MetadataService.getInstance();
        Date salesInvoicePostingDate = objMetadataService.getAppSettingDateValue(MTD_SALES_INVOICE_POSTING_DATE);
        salesInvoicePostingDate = (salesInvoicePostingDate == NULL ? System.today() : salesInvoicePostingDate);
        
        return Database.getQueryLocator([SELECT Id, SalesOrder__r.SAP_Contract_No__c,
                                         SalesOrder__r.Company_Code__c,
                                         SAP_Condition_Type__c, SAP_Document_No__c,
                                         RevisedDate__c,InstallmentAmount__c,
                                         InstallmentDate__c FROM InstallmentLines__c
                                         WHERE SalesOrder__r.Unit__r.Project__r.EnableSalesInvoicePosting__c = true
                                         AND Due_Date__c = :salesInvoicePostingDate 
                                         AND SAP_Document_No__c = NULL
                                         AND SalesOrder__r.Status__c = 'Sold']);
    }
    
    public void execute(Database.BatchableContext bc, List<InstallmentLines__c> installmentLineList) {
        IntegrationRecordService objIntegrationRecordService = IntegrationRecordService.getInstance();
        List<IntegrationRecord__c> objIntegrationRecordList = new List<IntegrationRecord__c>();
        for(InstallmentLines__c objInstallmentLine :installmentLineList){
            Map<String,String> paramMap = new Map<String,String>();
            paramMap.put('Param1',objInstallmentLine.SalesOrder__r.Company_Code__c);
            paramMap.put('Param2', objInstallmentLine.SalesOrder__r.SAP_Contract_No__c);
            paramMap.put('Param3', objInstallmentLine.SAP_Condition_Type__c);
            paramMap.put('Param4', String.valueOf(objInstallmentLine.RevisedDate__c != null ? objInstallmentLine.RevisedDate__c : objInstallmentLine.InstallmentDate__c));
            paramMap.put('Param5', String.valueOf(objInstallmentLine.InstallmentAmount__c));
            paramMap.put('Param6', '0');
            paramMap.put('Param15', 'X');
            objIntegrationRecordList.add(objIntegrationRecordService.getIntegrationRecord('Update','InstallmentLines__c',String.valueOf(objInstallmentLine.id),paramMap));
        }
        objIntegrationRecordService.insertIntegrationRecords(objIntegrationRecordList);
    }
    
    public void finish(Database.BatchableContext bc) {
        
    }
    
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new SalesInvoicePostingBatch(), 50);
    }
}