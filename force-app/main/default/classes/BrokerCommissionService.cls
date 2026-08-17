/*****************************************************************************************
Class       : BrokerCommissionService
Author      : Vikas Baliyan
Description : BrokerCommissionService Service
Test Class  : 
Created Date: 09 APR 2025 
*****************************************************************************************/
public inherited sharing class BrokerCommissionService {
    private static BrokerCommissionService instance;
    private BrokerCommissionService() { }
    
    public static BrokerCommissionService getInstance() {
        if(instance == null) {
            instance = new BrokerCommissionService();
        }
        return instance;
    }

    public List<BrokerCommission__c> getBrokerCommission(List<BrokerCommission__c> commissionList){
        return [SELECT Id,Name, Agency__c,Agency__r.Name,CommissionAmount__c, CommissionPercentage__c,VATPercentage__c,TotalCommissionAmountWithVAT__c, SalesOrder__r.Sales_Price_Excluding_ADM__c,SalesOrder__r.NetAmount__c,SalesOrder__r.ADMFeeAmount__c,SalesOrder__r.ADM_Fee_Included__c, Project__r.Name, SalesOrder__r.Unit__r.Name, SalesOrder__r.Name, SalesOrder__r.Broker_Agent__c FROM BrokerCommission__c WHERE Id IN : commissionList];
    }

    public  List<BrokerCommission__c> getBrokerCommissionForPDF(String recordId){
        return [SELECT Id, Name, IsFullPayment__c, VATPercentage__c, CommissionPercentage__c, Project__r.Company__r.Name, Project__r.Company__r.TRN__c, Project__r.Company__r.Address__c, SalesOrder__r.Sales_Price_Excluding_ADM__c, SalesOrder__r.ADMFeeAmount__c, SalesOrder__r.NetAmount__c, SalesOrder__r.ADM_Fee_Included__c,Agency__r.Is_VAT_Registered__c,Agency__r.Bank_Account_IBAN_Number__c, Agency__r.AccountNumber, Agency__r.Bank_Account_Bank_Name__c, Agency__r.Bank_Account_Name__c,Agency__r.UAEVATRegisterNumber__c, Agency__r.Trade_License_No__c,Agency__r.Name, Agency__r.BillingStreet, Agency__r.BillingCity, Agency__r.BillingState, Agency__r.BillingPostalCode, Agency__r.BillingCountry, Project__r.Name, InstallmentLine__r.SalesOrder__r.UnitNumber__c,InstallmentLine__r.InstallmentNumber__c, SalesOrder__r.SellingPrice__c, CommissionAmount__c,
        SalesOrder__r.Opportunity__r.BrokerAgencyAccount__r.BankAccount__r.Name, SalesOrder__r.Opportunity__r.BrokerAgencyAccount__r.BankAccount__r.BeneficiaryNameCorporate__c, SalesOrder__r.Opportunity__r.BrokerAgencyAccount__r.BankAccount__r.AccountNumberCorporate__c,SalesOrder__r.Opportunity__r.BrokerAgencyAccount__r.BankAccount__r.IBANNoCorporate__c,SalesOrder__r.Opportunity__r.BrokerAgencyAccount__r.BankAccount__r.SwiftCodeCorporate__c,
        SalesOrder__r.Unit__r.UnitType__c,SalesOrder__r.IsTaxable__c,SalesOrder__r.TaxableAmount__c
        FROM BrokerCommission__c WHERE ID =: recordId];
    }

    public  BrokerCommission__c getOnlyBrokerCommissionFields(String recordId){
        return [SELECT Id,  Status__c FROM BrokerCommission__c WHERE Id = :recordId LIMIT 1];
    }
    
     /*
    * fetch Broker Commission record by id
    */
    public BrokerCommission__c getBrokerCommissionById(String recordId){
        return [SELECT Id, Agency__c, InvoiceDate__c,Agency__r.Name, CommissionSchedule__r.Percentage__c,SalesOrder__r.Unit__r.UnitModel__c, 
                FinalApprovalStatus__c, BrokerInvoiceNumber__c, ERPConditionCreatedDate__c, ERPPostedDate__c, Agency__r.Broker_Registration_Expiry_Date__c, 
                Agency__r.RERACertificateExpiryDate__c, Agency__r.Trade_License_Expiry_Date__c, SalesOrder__r.Unit__r.Name, SalesOrder__r.Unit__r.RegistrationDate__c, 
                FirstApprovalStatus__c, SecondApprovalStatus__c, IntegrationStatus__c, SalesOrder__r.Sales_Price_Excluding_ADM__c, Status__c, VerifiedBy__r.Name, 
                VerifiedBy__r.Title,VerifiedDate__c,SalesOrder__r.ADM_Fee_Included__c,SalesOrder__r.NetAmount__c,SalesOrder__r.ADMFeeAmount__c,
                SalesOrder__r.Account__r.Name, SalesOrder__r.TaxableAmount__c,TotalCommissionAmountWithVAT__c, InstallmentLine__r.PaymentPlan__r.Name, 
                Project__r.Name, SalesOrder__r.Unit__r.UnitType__c, SalesOrder__r.Unit__r.SAP_Usage_Type__c,SalesOrder__r.Unit__r.Sales_Order_SPA_Signed_Date__c, 
                UnitType__c,CommissionPercentage__c,CommissionAmount__c,SalesOrder__r.SoldDate__c, PaymentPlan__r.Name, SalesOrder__r.ADMFeeWaivedAmount__c,
                SalesOrder__r.Unit__r.SellingPrice__c, Agent__r.Name, InstallmentLine__r.Due_Date__c,SalesOrder__r.Opportunity__r.BrokerAgencyAccount__c,
                Agency__r.Is_VAT_Registered__c,
                InstallmentLine__r.InstallmentNumber__c,IsFullPayment__c
                FROM BrokerCommission__c 
                WHERE Id = :recordId];  
    }
    
    /*
    * fetch Broker Commission record by list
    */
    public List<BrokerCommission__c> getBrokerCommissionById(List<BrokerCommission__c> brokerList){
        return [SELECT Id, Name,InvoiceDate__c,SalesOrder__r.Opportunity__r.BrokerAgencyAccount__c FROM BrokerCommission__c WHERE Id IN: brokerList];
    }

    /*
    * update Broker Commission record
    */
    public List<BrokerCommission__c> updateBrokerCommissions(List<BrokerCommission__c> brokerCommissionList){
        if(brokerCommissionList != NULL && !brokerCommissionList.isEmpty()){
            update brokerCommissionList;
        }
        return brokerCommissionList;
    }

     /*
    * insert Broker Commission record
    */
    public List<BrokerCommission__c> insertBrokerCommissions(List<BrokerCommission__c> brokerCommissionList){
        if(brokerCommissionList != NULL && !brokerCommissionList.isEmpty()){
            insert brokerCommissionList;
        }
        return brokerCommissionList;
    }

    public List<BrokerCommission__c> getBrokerRecordsByidSet(Set<Id> brokerIdSet){
        return [SELECT Id,CreatedDate,InvoiceDate__c,FirstApprovalStatus__c,SecondApprovalStatus__c,FinalApprovalStatus__c, FirstIntegrationDate__c, IntegrationStatus__c,CommissionPercentage__c,
                BrokerInvoiceNumber__c,InstallmentLine__r.InstallmentNumber__c,Agency__r.Is_VAT_Registered__c,SalesOrder__r.Unit__r.SAP_Broker_bp__c, 
                SalesOrder__r.Unit__r.SAP_Building_No__c, SalesOrder__r.Unit__r.SAP_Business_Entity_No__c,SalesOrder__r.Unit__r.SAP_Unit_Number__c, SalesOrder__r.Company_Code__c,
                CommissionAmount__c,Agency__r.SAP_Company_Code__c,SalesOrder__r.SAP_Contract_No__c 
                FROM BrokerCommission__c WHERE Id IN :brokerIdSet];
    }
    // update broker commission without trigger
    public List<BrokerCommission__c> updateBrokerCommissionWithoutTrigger(List<BrokerCommission__c> bcList){
        if(bcList != NULL && !bcList.isEmpty()){
            BrokerCommissionTriggerHandler.isTriggerDisabled = true;
            update bcList;
            BrokerCommissionTriggerHandler.isTriggerDisabled = false;
        }
        return bcList;
    }
    
    // BAPP Get Total Commissions
    public static Map<Id, Decimal> getTotalCommissions(Id accountId, Set<Id> contactIds, Date updatedOnFrom, Date updatedOnTo) {
        Map<Id, Decimal> result = new Map<Id, Decimal>();
        String dateFilter = '';
        
        if (updatedOnFrom != null && updatedOnTo != null) {
            DateTime fromDT = DateTime.newInstance(updatedOnFrom, Time.newInstance(0, 0, 0, 0));
            DateTime toDT   = DateTime.newInstance(updatedOnTo, Time.newInstance(23, 59, 59, 999));
            dateFilter = ' AND LastModifiedDate >= :fromDT AND LastModifiedDate <= :toDT';
        }
        
        String soql = 
            'SELECT SalesOrder__r.Opportunity__r.BrokerAgentContact__c agentId, SUM(CommissionAmount__c) total ' +
            'FROM BrokerCommission__c ' +
            'WHERE Status__c = \'Paid\' ' +
            'AND SalesOrder__r.Opportunity__r.BrokerAgencyAccount__c = :accountId ' +
            'AND SalesOrder__r.Opportunity__r.BrokerAgentContact__c IN :contactIds' +
            dateFilter +
            ' GROUP BY SalesOrder__r.Opportunity__r.BrokerAgentContact__c';
        
        for (AggregateResult ar : Database.query(soql)) {
            result.put((Id)ar.get('agentId'), (Decimal)ar.get('total'));
        }
        return result;
    }
    
    // BAPP Get BrokerCommission by invoice number
    public BrokerCommission__c getByInvoiceNumber(String invoiceNumber) {
        if (String.isBlank(invoiceNumber)) return null;
        
        List<BrokerCommission__c> results = [
            SELECT Id, Name, BrokerInvoiceNumber__c 
            FROM BrokerCommission__c 
            WHERE BrokerInvoiceNumber__c = :invoiceNumber 
            LIMIT 1
        ];
        return results.isEmpty() ? null : results[0];
    }
    // BAPP Get Pending BrokerCommission by Account Id and Contact Id
    public Map<Id,List<BrokerCommission__c>> getPendingBrokerCommissionByAccountAndContact(Set<Id> accountIds, Set<Id> contactIds) {
        Map<Id,List<BrokerCommission__c>> pendingCommissionMap = new Map<Id,List<BrokerCommission__c>>();
        
        if (accountIds == null || accountIds.isEmpty() || contactIds == null || contactIds.isEmpty()) {
            return pendingCommissionMap;
        }
        
        for(BrokerCommission__c bc : [
            SELECT Id,Status__c,SalesOrder__r.Opportunity__r.BrokerAgencyAccount__c,SalesOrder__r.Opportunity__r.BrokerAgentContact__c
            FROM BrokerCommission__c
            WHERE SalesOrder__r.Opportunity__r.BrokerAgencyAccount__c IN :accountIds
            AND SalesOrder__r.Opportunity__r.BrokerAgentContact__c IN :contactIds
            AND Status__c NOT IN ('Paid','Cancelled')
        ]){
            Id contactId = bc.SalesOrder__r.Opportunity__r.BrokerAgentContact__c;
            
            if(!pendingCommissionMap.containsKey(contactId)){
                pendingCommissionMap.put(contactId,new List<BrokerCommission__c>());
            }
            
            pendingCommissionMap.get(contactId).add(bc);
        }
        
        return pendingCommissionMap;
    }
}