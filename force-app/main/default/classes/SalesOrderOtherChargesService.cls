/*****************************************************************************************
Class       : SalesOrderOtherChargesService
Author      : Vikas Baliyan
Description : SalesOrderOtherChargesService
Test Class  : 
Created Date: 07 MAY 2025 
*****************************************************************************************/
public inherited sharing class SalesOrderOtherChargesService {
    
    private static SalesOrderOtherChargesService instance;
    
    private SalesOrderOtherChargesService() {
        
    }
    
    public static SalesOrderOtherChargesService getInstance() { 
        if(instance == null) {
            instance = new SalesOrderOtherChargesService();
        }
        return instance;
    }
    
    public SalesOrderOtherCharges__c createSalesOrderOtherChargesObj(Id salesOrderId, Id accId, Id installmentId, Decimal amount, String typeOfCharge, Id raIdOld, Id raIdNew, String conditionType, Date dueDate){
        SalesOrderOtherCharges__c otherCharge = new SalesOrderOtherCharges__c();
        otherCharge.SalesOrder__c = salesOrderId;
        otherCharge.Account__c = accId;
        otherCharge.Installment_Line__c = installmentId;
        otherCharge.Amount__c = amount;
        otherCharge.TypeOfCharge__c = typeOfCharge;
        otherCharge.BouncedChequeReceiptAcknowledgement__c = raIdOld;
        otherCharge.SAP_Condition_Type__c = conditionType;
        otherCharge.Due_Date__c = dueDate;
        return otherCharge;
    }
    
    public List<SalesOrderOtherCharges__c> getSalesOrderOtherChargesByIds(Set<Id> otherChargesIds){
        return [SELECT Id, SAP_Document_No__c, Reason__c, IsVATApplicable__c, IsReversed__c, BouncedChequeReceiptAcknowledgement__r.SAP_Document_No__c, Installment_Line__c, Installment_Line__r.SAP_Document_No__c, StartDate__c, EndDate__c, TotalLatePaymentFee__c,
                ReversalCategory__c,ReversalApprovalDate__c, Remarks__c, SendtoSAP__c, SalesOrder__r.Company_Code__c, SalesOrder__r.SAP_Contract_No__c, TypeOfCharge__c, ReversalApprovalStatus__c, SAPReversalDocumentNo__c,
                SalesOrder__c, SalesOrder__r.Unit__c,SalesOrder__r.Opportunity__c,SalesOrder__r.Account__c,SalesOrder__r.Unit__r.Project__r.TechnologyFeeConditionType__c,
                SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__c,
                SAP_Condition_Type__c, Due_Date__c, Amount__c  FROM SalesOrderOtherCharges__c WHERE Id IN : otherChargesIds];
    }
    
    public  List<SalesOrderOtherCharges__c> getSalesOrderChargesByInstallment(Set<Id> setInstallmentIds, String chargeType){
        return [SELECT Id, Installment_Line__c, Name, Due_Date__c, StartDate__c, EndDate__c, TotalLatePaymentFee__c, TypeOfCharge__c, SendtoSAP__c
                FROM SalesOrderOtherCharges__c WHERE Installment_Line__c IN :setInstallmentIds AND TypeOfCharge__c =: chargeType AND Status__c != 'Reversed'];
    }
    
    public  List<SalesOrderOtherCharges__c> getSalesOrderChargesByProjectIds(Set<Id> projectIdList, List<String> salesOrderStatusValueList, String chargeType){
        return [SELECT Id,Name,SalesOrder__r.Name,SalesOrder__r.Unit__r.Project__r.Name,SalesOrder__r.Unit__r.Name,Account__r.Name,Account__r.isPersonAccount,
                Account__r.PersonContactId,Account__r.PersonContact.Name,Account__r.NameinArabic__c,SalesOrder__r.Contact__c,SalesOrder__r.Contact__r.Name,Amount__c,format(Amount__c) pendingamount,Due_Date__c 
                FROM SalesOrderOtherCharges__c WHERE SalesOrder__r.Unit__r.Project__c IN: projectIdList AND SalesOrder__r.Status__c NOT IN :salesOrderStatusValueList AND TypeOfCharge__c =: chargeType AND PendingAmount__c > 0 AND Due_Date__c != null];
    }
    
    public  SalesOrderOtherCharges__c getSalesOrderChargesByIdWithBank(Id salesOrderOtherChargeId){
        return [SELECT Id, SalesOrder__c,SalesOrder__r.Id,SalesOrder__r.Cheque_from_Bank__c,SalesOrder__r.Account__c,SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_ADM_Charges__c,SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_ADM_Charges__r.Name,SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__c,SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.Name,SalesOrder__r.Contact__c,SalesOrder__r.Opportunity__c,SalesOrder__r.OpportunityNumber__c,SalesOrder__r.Name,Name,TypeOfCharge__c,Amount__c,SalesOrder__r.UnitNumber__c,SalesOrder__r.AccountName__c,PendingAmount__c,
                SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__c,SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.Name,SalesOrder__r.Unit__r.BuildingSectionName__r.PHPPAccountInstallment__c,SalesOrder__r.Unit__r.BuildingSectionName__r.PHPPAccountInstallment__r.Name,
                SalesOrder__r.Unit__r.BuildingSectionName__r.HandoverAccountInstallment__c,SalesOrder__r.Unit__r.BuildingSectionName__r.HandoverAccountInstallment__r.Name FROM SalesOrderOtherCharges__c WHERE Id =: salesOrderOtherChargeId];
    }
    
    public List<SalesOrderOtherCharges__c> getSalesOrderChargesBySalesOrder(Id salesOrderId){
        return [SELECT Id, TypeOfCharge__c, Amount__c, PendingAmount__c, SalesOrder__c FROM SalesOrderOtherCharges__c WHERE SalesOrder__c =:salesOrderId];
    }
    
    public List<SalesOrderOtherCharges__c> getSalesOrderChargesBySalesOrder(Id salesOrderId, List<String> conditionTypeValueList){
        return [SELECT Id, TypeOfCharge__c, Amount__c, PendingAmount__c, SalesOrder__c FROM SalesOrderOtherCharges__c WHERE SalesOrder__c =:salesOrderId AND SAP_Condition_Type__c NOT IN: conditionTypeValueList];
    }
    
    public List<SalesOrderOtherCharges__c> insertSalesOrderOtherCharges(List<SalesOrderOtherCharges__c> SalesOrderOtherChargesList){
        if(SalesOrderOtherChargesList != NULL && !SalesOrderOtherChargesList.isEmpty()){
            insert SalesOrderOtherChargesList;
        }
        return SalesOrderOtherChargesList;
    }
    
    public List<SalesOrderOtherCharges__c> upsertSalesOrderOtherCharges(List<SalesOrderOtherCharges__c> salesOrderOtherChargesList){
        if(salesOrderOtherChargesList != NULL && !salesOrderOtherChargesList.isEmpty()){
            upsert salesOrderOtherChargesList;
        }
        return salesOrderOtherChargesList;
    }
    
    //Update Installment Lines
    public List<SalesOrderOtherCharges__c> updateOtherCharges(List<SalesOrderOtherCharges__c> otherChargesList){
        if(otherChargesList != NULL && !otherChargesList.isEmpty()){
            update otherChargesList;
        }
        return otherChargesList;
    }
    
    public SalesOrderOtherCharges__c updateOtherCharge(SalesOrderOtherCharges__c otherCharge){
        return updateOtherCharges(new List<SalesOrderOtherCharges__c>{otherCharge})[0];
    }
    
    public List<SalesOrderOtherCharges__c> updateOtherChargesWithoutTrigger(List<SalesOrderOtherCharges__c> otherChargesList){
        if(otherChargesList != NULL && !otherChargesList.isEmpty()){
            SalesOrderOtherChargesTriggerHandler.isTriggerDisabled = true;
            update otherChargesList;
            SalesOrderOtherChargesTriggerHandler.isTriggerDisabled = false;
        }
        return otherChargesList;
    }
    
    public IntegrationRecord__c createOtherChargeIntegrationRecord(SalesOrderOtherCharges__c otherCharge, String action){
        IntegrationRecordService objIntegrationRecordService = IntegrationRecordService.getInstance();
        Map<String, String> paramMap = new Map<String, String>();
        paramMap.put('Param1', otherCharge.SalesOrder__r != null ? otherCharge.SalesOrder__r.Company_Code__c : '');
        paramMap.put('Param2', otherCharge.SalesOrder__r != null ? otherCharge.SalesOrder__r.SAP_Contract_No__c : '');
        paramMap.put('Param3', otherCharge.SAP_Condition_Type__c);
        paramMap.put('Param4', String.valueOf(otherCharge.Due_Date__c));
        paramMap.put('Param5', String.valueOf(otherCharge.Amount__c));
        paramMap.put('Param6', '0');
        paramMap.put('Param7', '');
        paramMap.put('Param8', '');
        paramMap.put('Param13', otherCharge.IsVATApplicable__c ? 'X' : '');
        paramMap.put('Param15', action == 'Insert' ?  'X' : '');
        
        String invoiceNumber = otherCharge.SAP_Document_No__c != NULL ? otherCharge.SAP_Document_No__c : '';
        if(String.isNotEmpty(invoiceNumber)){
            List<String> documentNumberList = invoiceNumber.contains('/') ? invoiceNumber.split('/') : null;
            invoiceNumber = (documentNumberList.size() == 3) ? documentNumberList[1] : null;
        }
        
        if(otherCharge.IsReversed__c){
            paramMap.put('Param9', 'X');
            paramMap.put('Param10', String.valueOf(Date.today()));
            paramMap.put('Param11', otherCharge.Reason__c);
            paramMap.put('Param12', otherCharge.Remarks__c);
            paramMap.put('Param14', otherCharge.ReversalCategory__c);
            paramMap.put('Param16', otherCharge.TypeOfCharge__c == 'Cheque Bounce Fee' && otherCharge.ReversalCategory__c == 'Reversal of Bounce cheque fees paid' ? invoiceNumber : otherCharge.SAP_Document_No__c);
            paramMap.put('Param17', otherCharge.TypeOfCharge__c == 'Late Payment Charges' && otherCharge.ReversalCategory__c == 'Reversal of LPF paid' ? invoiceNumber : '');
        }
        return objIntegrationRecordService.getIntegrationRecord(action, 'SalesOrderOtherCharges__c', String.valueOf(otherCharge.Id), paramMap);
    }
    
    public List<SalesOrderOtherCharges__c> getActiveSalesOrderChargesBySalesOrderId(Id salesOrderId){
        return [SELECT Id,Name,SalesOrder__r.Name,SalesOrder__r.Unit__r.Project__r.Name,SalesOrder__r.Unit__r.Name,Account__r.Name,Account__r.isPersonAccount,Status__c,
                PendingAmount__c, AmountReceived__c, TypeOfCharge__c, Account__r.PersonContactId,Account__r.PersonContact.Name,Account__r.NameinArabic__c,SalesOrder__r.Contact__c,SalesOrder__r.Contact__r.Name,Amount__c,format(Amount__c) pendingamount,Due_Date__c,
                SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_ADM_Charges__r.SalesMID__c, SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.SalesMID__c
                FROM SalesOrderOtherCharges__c WHERE SalesOrder__c = :salesOrderId AND Status__c != 'Reversed' AND TypeOfCharge__c != 'Technology Fee'];
    }
}