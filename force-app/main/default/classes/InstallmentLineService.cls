/*****************************************************************************************
Class       : InstallmentLineService
Author      : Vikas Baliyan
Description : InstallmentLine service class
Test Class  : 
Created Date: 07 NOV 2024
*****************************************************************************************/
public inherited sharing class InstallmentLineService {
    
    private static final string MTD_SALES_ORDER_STATUS_VALUE { get { return 'SalesOrderStatusForPaymentPlan'; } }
    
    private static InstallmentLineService instance;
    
    private InstallmentLineService() {  
    }
    
    public static InstallmentLineService getInstance() { 
        if(instance == null) {
            instance = new InstallmentLineService();
        }
        return instance;
    }
    
    /*
* Get Future & Current month's-pending Installment Lines records by sales order id set
*/
    public List<InstallmentLines__c> getInstallmentLinesBySalesOrder(Set<Id> salesOrderIdSet){
        Date today = Date.today();
        Date startOfMonth = Date.newInstance(today.year(), today.month(), 1);
        return [SELECT Id, InstallmentAmount__c, ClearedAmount__c, SalesOrder__c,PendingAmount__c, Name,InstallmentDate__c,Installment_Amount_Excluding_ADM__c FROM InstallmentLines__c /*WHERE SalesOrder__c IN: salesOrderIdSet AND InstallmentDate__c > Today*/  
                WHERE SalesOrder__c IN :salesOrderIdSet AND 
                ( 
                    Due_Date__c > :today
                    OR 
                    (Due_Date__c >= :startOfMonth AND Due_Date__c <= :today AND PendingAmount__c > 1)
                )];
    }
    
    /*
* Get Handover and Post Handover Installment Lines ONLY by sales order id set
*/
    public List<InstallmentLines__c> getHOAndPHPPInstallmentLinesBySalesOrderIds(Set<Id> salesOrderIdSet){
        return [SELECT Id, SalesOrder__c, Type__c, RevisedDate__c, Due_Date__c, InstallmentDate__c, Send_to_SAP__c FROM InstallmentLines__c WHERE SalesOrder__c IN :salesOrderIdSet AND Type__c IN ('Handover', 'Post Handover Installment')];
    }
    
    /*
* Get Handover Installment Lines ONLY by sales order id set
*/
    public List<InstallmentLines__c> getHandoverInstallmentLinesBySalesOrderIds(Set<Id> salesOrderIdSet){
        return [SELECT Id, SalesOrder__c, Type__c, RevisedDate__c, Due_Date__c, InstallmentDate__c, Send_to_SAP__c FROM InstallmentLines__c WHERE SalesOrder__c IN :salesOrderIdSet AND Type__c IN ('Handover')];
    }
    
    /*
* Get Post Handover Installment Lines ONLY by sales order id set
*/
    public List<InstallmentLines__c> getPostHandoverInstallmentLinesBySalesOrderIds(Set<Id> salesOrderIdSet){
        return [SELECT Id, SalesOrder__c, Type__c, RevisedDate__c, Due_Date__c, InstallmentDate__c, Send_to_SAP__c FROM InstallmentLines__c WHERE SalesOrder__c IN :salesOrderIdSet AND Type__c IN ('Post Handover Installment')];
    }
    
    public  List<InstallmentLines__c> getInstallmentLinesByProjectIds(Set<Id> projectIdList, List<String> salesOrderStatusValueList, Date currentDate, Date quaterlyDays){
        return [SELECT Id,Name,SalesOrder__r.Unit__r.Project__r.Name,SalesOrder__r.Unit__r.Project__r.EnableLPFCustomerNotification__c,SalesOrder__r.Unit__r.Name,SalesOrder__r.Account__c,SalesOrder__r.Account__r.Name,
                SalesOrder__r.Account__r.isPersonAccount,SalesOrder__r.Account__r.PersonContactId,SalesOrder__r.Account__r.PersonContact.Name,SalesOrder__r.Account__r.PersonEmail,
                SalesOrder__r.Account__r.NameinArabic__c,SalesOrder__r.Contact__c,SalesOrder__r.Contact__r.Name,SalesOrder__r.Contact__r.Email,SalesOrder__r.Status__c,PendingAmount__c,
                format(PendingAmount__c) pendingamount,InstallmentDate__c,Due_Date__c,ClearedAmount__c,InstallmentAmount__c,InstallmentNumber__c,Description__c,Type__c FROM InstallmentLines__c 
                WHERE SalesOrder__r.Unit__r.Project__c IN: projectIdList AND SalesOrder__r.Status__c NOT IN :salesOrderStatusValueList  AND ClearedAmount__c >= 0  AND Due_Date__c  >= :currentDate AND  Due_Date__c <= :quaterlyDays];
    }
    /*
* Get Installment Lines records by sales order id set
*/
    public List<InstallmentLines__c> getAllInstallmentLinesBySalesOrder(Set<Id> salesOrderIdSet){
        return [SELECT Id, 
                SalesOrder__c,
                PendingAmount__c, 
                Name,
                OriginalPPAmount__c,
                SalesOrder__r.ADM_Fee_Included__c,
                InstallmentDate__c,
                Installment_Amount_Excluding_ADM__c,
                AmountReceived__c,
                Type__c,
                Installment_Type__c,
                ClearedAmount__c,
                InstallmentAmount__c,
                InstallmentPercentage__c,
                BrokerPayoutPercentage__c,
                Due_Date__c,
                Description__c,
                PaymentInstallments__c,
                (Select id,
                 ReceiptStatus__c,
                 AmountApplied__c,
                 DateOfApplication__c,
                 ReceiptAcknowledgement__c,
                 ReceiptAcknowledgement__r.Opportunity__c, 
                 ReceiptAcknowledgement__r.Amount__c,
                 ReceiptAcknowledgement__r.MaturityDate__c,
                 ReceiptAcknowledgement__r.Status__c,
                 ReceiptAcknowledgement__r.PaymentType__c, 
                 ReceiptAcknowledgement__r.Name,
                 Name,ReceiptMaturityDate__c
                 from Receipt_Allocations__r)  
                FROM InstallmentLines__c WHERE SalesOrder__c IN: salesOrderIdSet];
    }
    public List<InstallmentLines__c> getOldInstallmentLinesBySalesOrderandDueDate(Set<Id> salesOrderIdSet){
        
        return [SELECT Id, 
                InstallmentDate__c, 
                Description__c
                FROM InstallmentLines__c WHERE SalesOrder__c IN: salesOrderIdSet and Due_Date__c <= TODAY] ;
        
    }
    
    
    public List<InstallmentLines__c> getAllInstallmentLinesBySalesOrderandDueDate(Set<Id> salesOrderIdSet){
        return [SELECT Id, 
                SalesOrder__c,
                PendingAmount__c, 
                Name,
                InstallmentDate__c,
                Installment_Amount_Excluding_ADM__c,
                AmountReceived__c,
                Installment_Type__c,
                ClearedAmount__c,
                InstallmentAmount__c,
                InstallmentPercentage__c,
                BrokerPayoutPercentage__c,
                Due_Date__c,
                (Select id,
                 ReceiptStatus__c,
                 AmountApplied__c,
                 DateOfApplication__c,
                 ReceiptAcknowledgement__c,
                 ReceiptAcknowledgement__r.Opportunity__c, 
                 ReceiptAcknowledgement__r.Amount__c,
                 ReceiptAcknowledgement__r.MaturityDate__c,
                 ReceiptAcknowledgement__r.Status__c,
                 ReceiptAcknowledgement__r.PaymentType__c, 
                 ReceiptAcknowledgement__r.Name,
                 Name
                 from Receipt_Allocations__r)  
                FROM InstallmentLines__c WHERE SalesOrder__c IN: salesOrderIdSet AND Due_Date__c > TODAY AND Type__c != 'Handover' ORDER BY Due_Date__c ASC];
    }
    public List<InstallmentLines__c> getPaidInstallmentLinesBySalesOrder(Set<Id> salesOrderIdSet){
        
        return [SELECT Id, 
                InstallmentDate__c, 
                Description__c
                FROM InstallmentLines__c WHERE SalesOrder__c IN: salesOrderIdSet AND Description__c = 'Resale' AND SAP_Condition_Type__c = 'P145'];
        
    }
    public  List<InstallmentLines__c> getInstallmentLinesByProject(Set<Id> projectIds, List<String> salesOrderStatusValueList){
        return [SELECT Id,Name,Due_Date__c,LastLPFCreatedDate__c,Type__c,LPFCalculationStopped__c,SalesOrder__c,SalesOrder__r.Account__c,SalesOrder__r.Account__r.isPersonAccount,SalesOrder__r.Account__r.PersonContactId,SalesOrder__r.Account__r.PersonEmail,SalesOrder__r.Contact__c,SalesOrder__r.Status__c,PendingAmount__c,InstallmentDate__c,SalesOrder__r.Unit__r.Project__c,
                SalesOrder__r.Unit__r.Project__r.LPFSAPConditionCode__c,SalesOrder__r.Unit__r.Project__r.InstallmentLPFGracePeriod__c,SalesOrder__r.Unit__r.Project__r.HandoverLPFGracePeriod__c,SalesOrder__r.Unit__r.Project__r.LPFAnnualPercentage__c,SalesOrder__r.Unit__r.Project__r.DailyLPFPercentage__c,SalesOrder__r.Unit__r.Project__r.LatePaymentFeeCalculationStartDate__c,
                SalesOrder__r.Unit__r.Project__r.LPFThresholdAmount__c,SalesOrder__r.Contact__r.Email,SalesOrder__r.Unit__r.Project__r.Name,SalesOrder__r.Unit__r.Project__r.EnableLPFCustomerNotification__c,OutstandingAmount__c,SalesOrder__r.Unit__r.Name
                FROM InstallmentLines__c WHERE SalesOrder__r.Unit__r.Project__c IN :projectIds AND SalesOrder__r.Status__c NOT IN :salesOrderStatusValueList AND SalesOrder__r.Unit__r.Project__r.EnableLatePaymentFee__c = TRUE AND SalesOrder__r.LPFCalculationStopped__c = FALSE AND LPFCalculationStopped__c = FALSE AND PendingAmount__c > 0 AND InstallmentDate__c != null AND InstallmentDate__c < TODAY];
    }
    
    /*
* Get Installment Lines records by Installment Number (1,2) and Broker Commission not created and have Broker Agency on Parent Sales Order
*/
    public List<InstallmentLines__c> getFirstNSecInstallmentByCommissionCreated(Boolean isBrokerCommissionCreated, Set<Integer> installmentNumberSet, String status){
        return [SELECT Id, InstallmentNumber__c , BrokerCommissionCreated__c, InstallmentAmount__c, ClearedAmount__c, SalesOrder__c,SalesOrder__r.Broker_Agency__c 
                ,SalesOrder__r.Opportunity__r.BrokerAgencyAccount__c,SalesOrder__r.Unit__r.Project__c
                FROM InstallmentLines__c WHERE ClearedAmount__c > 0 AND  BrokerCommissionCreated__c =: isBrokerCommissionCreated AND InstallmentNumber__c IN :installmentNumberSet 
                AND SalesOrder__r.Broker_Agency__c != null AND SalesOrder__r.Status__c =: status AND SalesOrder__r.SoldDate__c != null AND SalesOrder__r.Resale__c = FALSE];
    }
    
    public  List<InstallmentLines__c> getDPInstallmentLinesBySalesOrder(Set<Id> salesOrderIdSet){
        return [SELECT Id, InstallmentAmount__c, ClearedAmount__c, SalesOrder__c, Name,PendingAmount__c FROM InstallmentLines__c WHERE SalesOrder__c IN: salesOrderIdSet and InstallmentNumber__c=1];
    }
    
    public  List<InstallmentLines__c> getInstallmentLinesByIds(Set<Id> installmentIds){
        return [SELECT Id, SalesOrder__r.SAP_Contract_No__c,SalesOrder__r.Company_Code__c,SAP_Condition_Type__c,RevisedDate__c,SalesOrder__r.Unit__r.Project__r.TechnologyFeeConditionType__c,
                SalesOrder__r.Account__r.PersonContactId, SalesOrder__r.Contact__c, SalesOrder__r.Unit__r.Name,SalesOrder__r.Unit__c,SalesOrder__c,SalesOrder__r.Opportunity__c,SalesOrder__r.Account__c,
                SalesOrder__r.Unit__r.BuildingSectionName__r.HandoverAccountInstallment__c,SalesOrder__r.Unit__r.BuildingSectionName__r.PHPPAccountInstallment__c,Type__c,
                SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__c,SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__c,
                InstallmentAmount__c,InstallmentDate__c,(Select id,ReceiptAcknowledgement__c from Receipt_Allocations__r)
                FROM InstallmentLines__c WHERE Id IN :installmentIds];
    }
    
    public InstallmentLines__c getInstallmentLinesByIdWithBank(Id installmentId){
        return [SELECT Id,Name,InstallmentAmount__c,Tax_Amount__c,Inst_Amount_incl_tax__c,Inst_inc_tax_in_words__c,InstallmentNumber__c,SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__c,SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.Name,SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_ADM_Charges__c,SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_ADM_Charges__r.Name,
                SalesOrder__r.Unit__r.BuildingSectionName__r.HandoverAccountInstallment__c,SalesOrder__r.Unit__r.BuildingSectionName__r.HandoverAccountInstallment__r.Name,SalesOrder__r.Unit__r.BuildingSectionName__r.PHPPAccountInstallment__c,SalesOrder__r.Unit__r.BuildingSectionName__r.PHPPAccountInstallment__r.Name,
                SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__c,SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.Name,SalesOrder__r.Account__r.Name,SalesOrder__r.Account__r.PersonMailingAddress,SalesOrder__r.Unit__r.Name,SalesOrder__r.Name,SalesOrder__r.Tax_Percentage__c,SalesOrder__r.NetAmount__c,SalesOrder__r.AmountPayable__c,
                SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.AccountNumberCorporate__c,SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.IBANNoCorporate__c,
                SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.SwiftCodeCorporate__c,SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.BankNameCorporate__c,  
                SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.BeneficiaryNameCorporate__c,
                SalesOrder__r.Unit__r.BuildingSectionName__r.HandoverAccountInstallment__r.AccountNumberCorporate__c,SalesOrder__r.Unit__r.BuildingSectionName__r.HandoverAccountInstallment__r.IBANNoCorporate__c,
                SalesOrder__r.Unit__r.BuildingSectionName__r.HandoverAccountInstallment__r.SwiftCodeCorporate__c,SalesOrder__r.Unit__r.BuildingSectionName__r.HandoverAccountInstallment__r.BankNameCorporate__c,  
                SalesOrder__r.Unit__r.BuildingSectionName__r.HandoverAccountInstallment__r.BeneficiaryNameCorporate__c,  
                SalesOrder__r.Unit__r.BuildingSectionName__r.PHPPAccountInstallment__r.AccountNumberCorporate__c,SalesOrder__r.Unit__r.BuildingSectionName__r.PHPPAccountInstallment__r.IBANNoCorporate__c,
                SalesOrder__r.Unit__r.BuildingSectionName__r.PHPPAccountInstallment__r.SwiftCodeCorporate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.PHPPAccountInstallment__r.BankNameCorporate__c,  
                SalesOrder__r.Unit__r.BuildingSectionName__r.PHPPAccountInstallment__r.BeneficiaryNameCorporate__c,
                SalesOrder__r.Amount_Payable_in_English__c,SalesOrder__r.TaxableAmount__c,SalesOrder__r.ProjectName__c,SalesOrder__r.Unit__r.Project__r.Company__r.Name,SalesOrder__r.Unit__r.Project__r.Company__r.Address__c,SalesOrder__r.Unit__r.Project__r.Company__r.TRN__c,
                SalesOrder__r.SellingPrice__c,Type__c FROM InstallmentLines__c WHERE Id =: installmentId];
    }
    
    public List<InstallmentLines__c> getActiveInstallmentsByPaymentInstallmentIds(Set<Id> paymentInstallmentIds){
        MetadataService objMetadataService = MetadataService.getInstance();
        String salesOrderStatusValue = objMetadataService.getAppSettingTextValue(MTD_SALES_ORDER_STATUS_VALUE);
        List<String> salesOrderStatusValueList = salesOrderStatusValue.split(',');
        return [SELECT Id, SalesOrder__c, PaymentInstallments__c FROM InstallmentLines__c WHERE PaymentInstallments__c IN : paymentInstallmentIds AND SalesOrder__r.Status__c NOT IN :salesOrderStatusValueList];
    }
    
    public List<InstallmentLines__c> getInstallmentsByPaymentInstallmentIds(Set<Id> paymentInstallmentIds){
        return [SELECT Id, SalesOrder__c, PaymentInstallments__c FROM InstallmentLines__c WHERE PaymentInstallments__c IN : paymentInstallmentIds];
    }
    
    public  List<IntegrationRecord__c> getInstallmentIntegrationRecords(Set<Id> installmentIds){
        IntegrationRecordService objIntegrationRecordService = IntegrationRecordService.getInstance();
        List<IntegrationRecord__c> objIntegrationRecordList = new List<IntegrationRecord__c>();
        List<InstallmentLines__c> installmentLineList = getInstallmentLinesByIds(installmentIds);
        for(InstallmentLines__c objInstallmentLine :installmentLineList){
            Map<String,String> paramMap = new Map<String,String>();
            paramMap.put('Param1',objInstallmentLine.SalesOrder__r.Company_Code__c);
            paramMap.put('Param2',  objInstallmentLine.SalesOrder__r.SAP_Contract_No__c);
            paramMap.put('Param3',  objInstallmentLine.SAP_Condition_Type__c);
            paramMap.put('Param4',  String.valueOf(objInstallmentLine.RevisedDate__c != null ? objInstallmentLine.RevisedDate__c : objInstallmentLine.InstallmentDate__c));
            paramMap.put('Param5',  String.valueOf(objInstallmentLine.InstallmentAmount__c));
            paramMap.put('Param6',  '0');
            objIntegrationRecordList.add(objIntegrationRecordService.getIntegrationRecord('Insert','InstallmentLines__c',String.valueOf(objInstallmentLine.id),paramMap));
        }
        return objIntegrationRecordList;
    }
    
    public  List<IntegrationRecord__c> getInstallmentPostingIntegrationRecords(Set<Id> installmentIds){
        IntegrationRecordService objIntegrationRecordService = IntegrationRecordService.getInstance();
        List<IntegrationRecord__c> objIntegrationRecordList = new List<IntegrationRecord__c>();
        List<InstallmentLines__c> installmentLineList = getInstallmentLinesByIds(installmentIds);
        for(InstallmentLines__c objInstallmentLine :installmentLineList){
            Map<String,String> paramMap = new Map<String,String>();
            paramMap.put('Param1',objInstallmentLine.SalesOrder__r.Company_Code__c);
            paramMap.put('Param2',  objInstallmentLine.SalesOrder__r.SAP_Contract_No__c);
            paramMap.put('Param3',  objInstallmentLine.SAP_Condition_Type__c);
            paramMap.put('Param4',  String.valueOf(objInstallmentLine.RevisedDate__c != null ? objInstallmentLine.RevisedDate__c : objInstallmentLine.InstallmentDate__c));
            paramMap.put('Param5',  String.valueOf(objInstallmentLine.InstallmentAmount__c));
            paramMap.put('Param6',  '0');
            paramMap.put('Param15', 'X');
            objIntegrationRecordList.add(objIntegrationRecordService.getIntegrationRecord('Update','InstallmentLines__c',String.valueOf(objInstallmentLine.id),paramMap));
        }
        return objIntegrationRecordList;
    }
    
    public List<InstallmentLines__c> getInstallmentsNReceiptAllocations(Set<Id> installmentIdSet, Set<Id> newAllocationIdSet){
        return [SELECT Id, (SELECT Id, ReceiptAcknowledgement__c, ReceiptAcknowledgement__r.Reason__c, ReceiptAcknowledgement__r.IsBounceChequeFeeCreated__c, ReceiptAcknowledgement__r.ChequeBouncedDate__c, ReceiptStatus__c ,ReceiptAcknowledgement__r.ReceiptReversalCategory__c FROM Receipt_Allocations__r WHERE Id NOT IN : newAllocationIdSet ORDER BY CreatedDate DESC LIMIT 1) FROM InstallmentLines__c  WHERE Id IN : installmentIdSet];
    }
    
    /*
* update Installment Lines record
*/
    public List<InstallmentLines__c> updateInstallmentLinesLists(List<InstallmentLines__c> installmentLinesList){
        if(installmentLinesList != NULL && !installmentLinesList.isEmpty()){
            Database.update(installmentLinesList, true);
        }
        return installmentLinesList;
    }
    
    public List<InstallmentLines__c> getPastDueDatedInstallmentLinesBySalesOrderId(Set<Id> salesOrderIdSet){
        return [SELECT Id, InstallmentAmount__c,OutstandingAmount__c,Installment_Amount_Excluding_ADM__c,
                Installment_Type__c,BrokerPayoutPercentage__c,PendingAmount__c,AmountReceived__c,
                InstallmentPercentage__c,InstallmentDate__c, ClearedAmount__c, SalesOrder__c, Due_Date__c
                FROM InstallmentLines__c 
                WHERE SalesOrder__c IN: salesOrderIdSet
                AND Due_Date__c <= TODAY
                AND PendingAmount__c > 0 ORDER BY Due_Date__c ];
    }
    
    public List<InstallmentLines__c> getFirstInstallmentLineBySalesOrder(Id salesOrderId){
        return [SELECT Id, InstallmentAmount__c, ClearedAmount__c, SalesOrder__c, Name,PendingAmount__c FROM InstallmentLines__c WHERE SalesOrder__c =: salesOrderId and InstallmentNumber__c = 1 AND SAP_Condition_Type__c != NULL LIMIT 1];
    }
    
    /*
* update Installment Lines records
*/
    public List<InstallmentLines__c> updateInstallmentLines(List<InstallmentLines__c> installmentLines){
        if(installmentLines != NULL && !installmentLines.isEmpty()){
            update installmentLines;
        }
        return installmentLines;
    }
    
    public InstallmentLines__c updateinstallmentLine(InstallmentLines__c installment){
        return updateinstallmentLines(new List<InstallmentLines__c>{installment})[0];
    }
    
    public  List<InstallmentLines__c> getInstallmentLinesBySalesOrderId(Id salesOrderId){
        return [SELECT Id, Type__c, Due_Date__c, InstallmentAmount__c, ClearedAmount__c, SalesOrder__c, AmountReceived__c,InstallmentNumber__c,
                Name,PendingAmount__c , InstallmentPercentage__c, PaymentStatus__c, SalesOrder__r.Unit__c, SalesOrder__r.Unit__r.Name,
                SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.SalesMID__c,SalesOrder__r.Unit__r.VirtualAccountMID__c,
                SalesOrder__r.Unit__r.BuildingSectionName__r.HandoverAccountInstallment__r.SalesMID__c,SalesOrder__r.Unit__r.BuildingSectionName__r.PHPPAccountInstallment__r.SalesMID__c,
                SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.SalesMID__c,SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_ADM_Charges__r.SalesMID__c,
                SalesOrder__r.Unit__r.Project__r.Company__r.RevenuePercentage__c, SalesOrder__r.Unit__r.Project__r.Company__r.RevenueMID__c,Status__c
                FROM InstallmentLines__c WHERE SalesOrder__c =: salesOrderId];
    }
    
    public  List<InstallmentLines__c> getInstallmentLinesNAllocationBySalesOrderId(Id salesOrderId){
        return [SELECT Id, Name, (SELECT Id,Name,InstallmentLine__c FROM Receipt_Allocations__r) FROM InstallmentLines__c WHERE SalesOrder__c =: salesOrderId];
    }
    
    //Insert Installments without trigger
    public List<InstallmentLines__c> insertInstallmentWithoutTrigger(List<InstallmentLines__c> installmentList){
        if(installmentList != NULL && !installmentList.isEmpty()){
            InstallmentLineTriggerHandler.isTriggerDisabled = true;
            insert installmentList;
            InstallmentLineTriggerHandler.isTriggerDisabled = false;
        }
        return installmentList;
    } 
    
    public List<InstallmentLines__c> getInstallmentLinesByExternalIds(Set<Id> externalIdSet){
        return [Select id,External_Id__c from InstallmentLines__c where External_Id__c IN:externalIdSet];
    }
    
    public List<InstallmentLines__c> getAllInstallmentLinesBySalesOrderId(Id salesOrderId){
        return [SELECT Id, InstallmentAmount__c,OutstandingAmount__c,Due_Date__c,InstallmentNumber__c, Installment_Amount_Excluding_ADM__c,Installment_Type__c,BrokerPayoutPercentage__c,PendingAmount__c,AmountReceived__c,InstallmentPercentage__c,InstallmentDate__c, ClearedAmount__c, SalesOrder__c FROM InstallmentLines__c WHERE SalesOrder__c =: salesOrderId];
    }
    
    public List<InstallmentLines__c> getAllInstallmentLinesBySalesOrderId(Id salesOrderId, List<String> conditionTypeValueList){
        return [SELECT Id, InstallmentAmount__c,OutstandingAmount__c,Due_Date__c,InstallmentNumber__c, Installment_Amount_Excluding_ADM__c,Installment_Type__c,BrokerPayoutPercentage__c,PendingAmount__c,AmountReceived__c,InstallmentPercentage__c,InstallmentDate__c, ClearedAmount__c, SalesOrder__c FROM InstallmentLines__c WHERE SalesOrder__c =: salesOrderId AND SAP_Condition_Type__c NOT IN: conditionTypeValueList];
    }
    
    /*
* Get Installments Due till date
*/
    public List<InstallmentLines__c> getInstallmentLinesDueTillDateBySalesOrder(Id salesOrderId){
        Date today = Date.today();
        
        return [SELECT Id, InstallmentAmount__c, ClearedAmount__c, SalesOrder__c,PendingAmount__c, Name,InstallmentDate__c,Installment_Amount_Excluding_ADM__c,InstallmentPercentage__c FROM InstallmentLines__c /*WHERE SalesOrder__c IN: salesOrderIdSet AND InstallmentDate__c > Today*/  
                WHERE SalesOrder__c = :salesOrderId AND 
                ( 
                    InstallmentDate__c <= today
                )];
    }
    public List<InstallmentLines__c> deleteInstallmentLines(List<InstallmentLines__c> installments){
        InstallmentLineTriggerHandler.isTriggerDisabled = true;
        delete installments;
        InstallmentLineTriggerHandler.isTriggerDisabled = false;
        return installments;
    }
    
    public List<InstallmentLines__c> getInstallmentLinesWithSalesOrderDetails(String installmentId) {
        return [SELECT Id, Type__c, Due_Date__c, InstallmentAmount__c, ClearedAmount__c, SalesOrder__c, AmountReceived__c,
                Name,PendingAmount__c , InstallmentPercentage__c, PaymentStatus__c, SalesOrder__r.Unit__c, SalesOrder__r.Unit__r.Name,
                SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.SalesMID__c,
                SalesOrder__r.Unit__r.BuildingSectionName__r.HandoverAccountInstallment__r.SalesMID__c,SalesOrder__r.Unit__r.BuildingSectionName__r.PHPPAccountInstallment__r.SalesMID__c,
                SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.SalesMID__c,SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_ADM_Charges__r.SalesMID__c,
                SalesOrder__r.Unit__r.Project__r.Company__r.RevenuePercentage__c, SalesOrder__r.Unit__r.Project__r.Company__r.RevenueMID__c,Status__c
                FROM InstallmentLines__c WHERE Id =: installmentId];
    }
    
    public  List<InstallmentLines__c> getInstallmentLinesByProjectAndDueDate(Id projectIds, Date dueDate){
        MetadataService objMetadataService = MetadataService.getInstance();
        String salesOrderStatusValue = objMetadataService.getAppSettingTextValue(MTD_SALES_ORDER_STATUS_VALUE);
        List<String> salesOrderStatusValueList = salesOrderStatusValue.split(',');
        return [SELECT Id,Name,Due_Date__c,Type__c, InstallmentNumber__c, InstallmentPercentage__c , InstallmentAmount__c, SalesOrder__c,SalesOrder__r.Account__c,SalesOrder__r.Name,SalesOrder__r.Contact__c,SalesOrder__r.Status__c,PendingAmount__c,
                Milestone__c, InstallmentDate__c,SalesOrder__r.Unit__r.Project__c,SalesOrder__r.Unit__r.Project__r.Name,SalesOrder__r.Unit__r.Name
                FROM InstallmentLines__c WHERE SalesOrder__r.Unit__r.Project__c =:projectIds AND Due_Date__c != null AND Due_Date__c =: dueDate  AND SalesOrder__r.Status__c NOT IN :salesOrderStatusValueList
                Order by SalesOrder__r.Unit__c, SalesOrder__c, InstallmentNumber__c];
    }
}