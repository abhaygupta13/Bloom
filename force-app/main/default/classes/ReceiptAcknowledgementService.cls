/*****************************************************************************************
Class       : ReceiptAcknowledgementController
Author      : Vinay 
Description : 
testClass   : ReceiptAcknowledgementServiceTest
Created Date: 15 Oct 2024
------------------------------------------------------------------------------------------
-- History --
------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.      V1.0             15Oct2024           Initial Version 
2.		V1.1			 20Nov2025			 Added new method for StatementOFAccount
3.		V1.2			 19DEC2025			 Added new method for Receipt Integration changes
*****************************************************************************************/
public inherited sharing class ReceiptAcknowledgementService {
    
    private static final String INTEGRATION_TYPE_SALES_RECEIPT_INTEGRATION { get { return 'SALES_RECEIPT_INTEGRATION'; } }
    
    private static ReceiptAcknowledgementService instance;
    
    private ReceiptAcknowledgementService() {
        
    }
    
    public static ReceiptAcknowledgementService getInstance() { 
        if(instance == null) {
            instance = new ReceiptAcknowledgementService();
        }
        return instance;
    }
    
    public Map<Id,ReceiptAcknowledgement__c> getReceiptAcknowledgementMap(Set<Id> externalIds){
        Map<Id,ReceiptAcknowledgement__c> receiptMap = new Map<Id,ReceiptAcknowledgement__c>();
        List<ReceiptAcknowledgement__c> receiptAcknowledgementList  = [SELECT Id FROM ReceiptAcknowledgement__c where External_Id__c in:externalIds];
        
        
        if(!receiptAcknowledgementList.isEmpty()){
            for(ReceiptAcknowledgement__c receiptObj : receiptAcknowledgementList){
                receiptMap.put(receiptObj.External_Id__c,receiptObj);
            } 
        }
        
        return receiptMap; 
    }
    
    public ReceiptAcknowledgement__c getReceiptAcknowledgementById(Id recordId){
        return [SELECT Id FROM ReceiptAcknowledgement__c WHERE Id = :recordId];
    }
    
    public ReceiptAcknowledgement__c updateReceiptAcknowledgement(ReceiptAcknowledgement__c objReceiptAcknowledgement){
        if(objReceiptAcknowledgement != NULL ){
            objReceiptAcknowledgement = updateReceiptAcknowledgements(new List<ReceiptAcknowledgement__c>{objReceiptAcknowledgement})[0];
        }
        return objReceiptAcknowledgement;
    }
    
    public List<ReceiptAcknowledgement__c> updateReceiptAcknowledgements(List<ReceiptAcknowledgement__c> receiptAcknowledgementList){
        if(receiptAcknowledgementList != NULL && !receiptAcknowledgementList.isEmpty()){
            update receiptAcknowledgementList;
        }
        return receiptAcknowledgementList;
    }
    public List<ReceiptAcknowledgement__c> insertReceiptAcknowledgements(List<ReceiptAcknowledgement__c> receiptAcknowledgementList){
        if(receiptAcknowledgementList != NULL && !receiptAcknowledgementList.isEmpty()){
            insert receiptAcknowledgementList;
        }
        return receiptAcknowledgementList;
    }
    
    public List<ReceiptAcknowledgement__c> getReceiptAcknowledgementNReceiptAllocationsById(Set<Id> receiptAcknowledegementSet){
        return [SELECT Id,Name, Reason__c, Account__c,Account__r.Name,Account__r.isPersonAccount,Account__r.PersonContactId,Account__r.NameinArabic__c,Amount__c,Contact__c,SalesOrder__c,
                Status__c,StatusReason__c,Unit__c,Unit__r.Name,SalesOrder__r.Unit__r.Project__c,SalesOrder__r.Unit__r.Project__r.Name,MaturityDate__c,
                SalesOrder__r.Unit__r.Project__r.ProjectNameArabic__c,ActualReversalDate__c,
                ReferenceNumber__c,(SELECT Id,InstallmentLine__c,InstallmentLine__r.Type__c,InstallmentLine__r.InstallmentNumber__c,
                                    SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.BankNameCorporate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.Name,
                                    SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.AccountNumberCorporate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.IBANNoCorporate__c,
                                    SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.SwiftCodeCorporate__c,ReceiptStatus__c,
                                    SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_ADM_Charges__r.BankNameCorporate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_ADM_Charges__r.Name,
                                    SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_ADM_Charges__r.AccountNumberCorporate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_ADM_Charges__r.IBANNoCorporate__c,
                                    SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_ADM_Charges__r.SwiftCodeCorporate__c,
                                    SalesOrder__r.Virtual_Bank_Account_Number__c, SalesOrder__r.Virtual_Account_IBAN__c,
                                    SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.BankNameCorporate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.Name,
                                    SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.AccountNumberCorporate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.IBANNoCorporate__c,
                                    SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.SwiftCodeCorporate__c
                                    FROM Receipt_Allocations__r ORDER BY CreatedDate DESC LIMIT 1) FROM ReceiptAcknowledgement__c 
                WHERE Id IN: receiptAcknowledegementSet];
    }
    
    public List<ReceiptAcknowledgement__c> getReceiptAckNReceiptAllocationsByReceiptId(Set<Id> receiptAcknowledegementSet){
        return [SELECT Id,Name,Account__c,Account__r.Name,SalesOrder__r.Unit__r.Name,SalesOrder__r.Name,PaymentType__c,ReferenceNumber__c,CurrencyISOCode,
                MortgageCheque__c,MaturityDate__c,Amount__c,BankName__c,CustomerBankAccount__c,PaidBy__c,Remarks__c,
                (SELECT Id,Name,TypeOfInvoice__c,AmountApplied__c,SalesOrder__c,Account__r.Name,SalesOrder__r.Name,SalesOrder__r.Unit__r.Name,
                 InstallmentLine__c,InstallmentLine__r.Type__c,InstallmentLine__r.InstallmentNumber__c,InstallmentLine__r.InstallmentAmount__c,
                 SalesOrderOtherCharges__c,SalesOrderOtherCharges__r.TypeOfCharge__c,SalesOrderOtherCharges__r.Amount__c
                 FROM Receipt_Allocations__r)
                FROM ReceiptAcknowledgement__c WHERE Id IN: receiptAcknowledegementSet];
    }
    
    public List<ReceiptAcknowledgement__c> getReceiptAcknowledgementAndReceiptAllocationsBySOId(Id salesOrderId){
        
        return[SELECT Id,Name, Reason__c,Bank_Account__c,ChequeReceived__c,ChequeReceivedBy__c, Account__c,Amount__c,Contact__c,SalesOrder__c,
               Status__c,StatusReason__c,Unit__c,MaturityDate__c,
               Installment_Line_1__c,Opportunity__c,PaymentType__c,
               ReferenceNumber__c,(SELECT Id,InstallmentLine__c,TypeOfInvoice__c,InstallmentLine__r.Type__c,InstallmentLine__r.InstallmentNumber__c,
                                   ReceiptStatus__c,AmountApplied__c,DateOfApplication__c
                                   FROM Receipt_Allocations__r ORDER BY CreatedDate) FROM ReceiptAcknowledgement__c 
               WHERE SalesOrder__r.id =:salesOrderId and PaymentType__c = 'Transfer of rights - Resale']; 
    }
    public List<ReceiptAcknowledgement__c> getReceiptAcknowledgementByIds(Set<Id> receiptAcknowledgementIdSet){
        return [SELECT Id, Name, BankName__c, Reason__c, Remarks__c, ChequeBouncedDate__c, SAP_Special_GL_Indicator__c, ReceiptPostingDate__c, PaymentType__c,
                SAP_Wire_GL_Sub_Account__c, SAP_Cheque_GL_Sub_Account__c, SAP_Main_Buyer_BP_No__c, ReferenceNumber__c, Unit_Number__c, VerifyDate__c, Amount__c, 
                New_Maturity_Date__c, MaturityDate__c, SAP_Document_No__c, SAP_Company_Code__c, SAP_Contract_Number__c, 
                SAP_Condition_Type__c,SalesOrder__r.Unit__r.Project__r.BounceChequeFeeERPCondition__c,Unit__r.Project__r.Company__c, SalesOrder__r.Unit__r.BuildingSectionName__r.SAP_Building_No__c, 
                Unit__r.Project__r.BounceChequeFeeThresholdDays__c, Unit__r.Project__r.BounceChequeFeeAmount__c, 
                Unit__r.Project__r.BounceChequeFeeERPCondition__c, SalesOrder__r.Unit__r.Project__r.SAPProfitCenter__c,ReversalComments__c,ReversalApprovalStatus__c,
                ReversalApprovalDate__c,Unit__r.UnitNumber__c, SalesOrder__r.Unit__r.Project__r.BounceChequeFeeVATApplicable__c,
                ReceiptReversalCategory__c,Unit__r.SAP_Unit_Number__c,Bank_Account__r.Type__c,
                Account__c,Account__r.Name,Account__r.isPersonAccount,Account__r.PersonContactId,Account__r.NameinArabic__c,Contact__c,SalesOrder__c,
                Status__c,StatusReason__c,Unit__c,Unit__r.Name,SalesOrder__r.Unit__r.Project__c,SalesOrder__r.Unit__r.Project__r.Name,
                SalesOrder__r.Unit__r.Project__r.ProjectNameArabic__c,ActualReversalDate__c,
                SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.BankNameCorporate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.BeneficiaryNameCorporate__c,
                SalesOrder__r.Virtual_Bank_Account_Number__c, SalesOrder__r.Virtual_Account_IBAN__c, SalesOrder__r.SalesManager__r.Email,
                SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.SwiftCodeCorporate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.BankNameCorporate__c,
                SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.Name, SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.AccountNumberCorporate__c,
                SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.IBANNoCorporate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.SwiftCodeCorporate__c,
                Bank_Account__r.BankNameCorporate__c, Bank_Account__r.BeneficiaryNameCorporate__c, Bank_Account__r.AccountNumberCorporate__c, Bank_Account__r.IBANNoCorporate__c,
                SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.BeneficiaryNameCorporate__c,
                Bank_Account__r.SwiftCodeCorporate__c
                FROM ReceiptAcknowledgement__c WHERE Id IN : receiptAcknowledgementIdSet];
    }
    
    public List<ReceiptAcknowledgement__c> getReceiptAcknowledgementAndAllocationsByIds(Set<Id> receiptAcknowledgementIdSet){
        return [SELECT Id, Name, SalesOrder__r.Unit__r.Project__r.Name, SalesOrder__r.Unit__r.Project__r.ProjectNameArabic__c, Unit__r.Name, 
                Account__r.Name, Account__r.NameinArabic__c, Account__r.isPersonAccount, Account__r.PersonContactId, ReferenceNumber__c, ActualReversalDate__c, Amount__c, Reason__c, Bank_Account__r.Type__c, 
                Bank_Account__r.BankNameCorporate__c, SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.BankNameCorporate__c, 
                Bank_Account__r.BeneficiaryNameCorporate__c,
                SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.BeneficiaryNameCorporate__c, 
                Bank_Account__r.AccountNumberCorporate__c, SalesOrder__r.Virtual_Bank_Account_Number__c, Bank_Account__r.IBANNoCorporate__c, 
                SalesOrder__r.Virtual_Account_IBAN__c, Bank_Account__r.SwiftCodeCorporate__c, 
                SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.SwiftCodeCorporate__c,
                SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.BankNameCorporate__c, 
                SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.BeneficiaryNameCorporate__c,
                SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.AccountNumberCorporate__c,
                SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.IBANNoCorporate__c,
                SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__r.SwiftCodeCorporate__c, SalesOrder__r.SalesManager__r.Email,Contact__c,
                (SELECT Id,ReceiptAcknowledgement__c,TypeOfInvoice__c,AmountApplied__c
                 FROM Receipt_Allocations__r WHERE InstallmentLine__r.Type__c = 'Down Payment')
                FROM ReceiptAcknowledgement__c WHERE Id IN : receiptAcknowledgementIdSet];
    }
    
    public List<ReceiptAcknowledgement__c> getReceiptAcknowledgementBySalesOrders(Set<Id> salesOrderIdSet){
        Date pastDate = System.today().addDays(-45);
        return [SELECT Id, Name, BankName__c, Reason__c, Remarks__c, SalesOrder__c, New_Maturity_Date__c, MaturityDate__c,
                Status__c,StatusReason__c
                FROM ReceiptAcknowledgement__c 
                WHERE SalesOrder__c IN :salesOrderIdSet AND Status__c = 'Received' 
                AND (MaturityDate__c >= :pastDate OR New_Maturity_Date__c >= :pastDate)];
    }
    
    public List<ReceiptAcknowledgement__c> getAllReceiptAcknowledgementBySalesOrders(Set<Id> salesOrderIdSet){
        return [SELECT Id, MaturityDate__c,VerifyDate__c,SAP_Document_No__c,Due_Date__c,PaymentType__c,Status__c,SAP_Condition_Type__c
                FROM ReceiptAcknowledgement__c
                WHERE SalesOrder__c IN :salesOrderIdSet AND  
                MaturityDate__c <= :System.today()];
    }
    
    public List<ReceiptAcknowledgement__c> updateReceiptAcknowledgementWithoutTrigger(List<ReceiptAcknowledgement__c> raList){
        if(raList != NULL && !raList.isEmpty()){
            ReceiptAcknowledgementTriggerHandler.isTriggerDisabled = true;
            update raList;
            ReceiptAcknowledgementTriggerHandler.isTriggerDisabled = false;
        }
        return raList;
    }
    
    public List<ReceiptAcknowledgement__c> insertReceiptAcknowledgementWithoutTrigger(List<ReceiptAcknowledgement__c> raList){
        if(raList != NULL && !raList.isEmpty()){
            ReceiptAcknowledgementTriggerHandler.isTriggerDisabled = true;
            insert raList;
            ReceiptAcknowledgementTriggerHandler.isTriggerDisabled = false;
        }
        return raList;
    }
    
    public List<ReceiptAcknowledgement__c> getReceiptAcknowledgementByExternalId(Set<Id> extIds){
        return[SELECT Id,External_Id__c FROM ReceiptAcknowledgement__c 
               WHERE External_Id__c IN:extIds]; 
    }
    
    public List<ReceiptAcknowledgement__c> getSpecialGLReceipts(Id salesOrderId){
        return [SELECT Id, Name, SAP_Special_GL_Indicator__c, Amount__c, MaturityDate__c, New_Maturity_Date__c, BankName__c, AmountApplied__c,
                Installment_Line_1__c,Installment_Line_2__c,Installment_Line_3__c,Other_Charges_1__c,Other_Charges_2__c,Other_Charges_3__c,Status__c
                FROM ReceiptAcknowledgement__c 
                WHERE SalesOrder__c = : salesOrderId AND Status__c != 'Reversed'];     
    }

    public List<ReceiptAcknowledgement__c> deleteReceiptAcknowledgementWithoutTrigger(List<ReceiptAcknowledgement__c> raList){
        if(raList != NULL && !raList.isEmpty()){
            ReceiptAcknowledgementTriggerHandler.isTriggerDisabled = true;
            
            delete raList;
            ReceiptAcknowledgementTriggerHandler.isTriggerDisabled = false; 
        }
        return raList;
    }
    
    public ReceiptAcknowledgement__c createReceiptAcknowledgementObj(Decimal amount, Id salesOrder, Id unit, Id accId, Id oppId, String paymentType, String status, Boolean financeVerified, String bankName, String refNumber){
        ReceiptAcknowledgement__c receiptAcknowledgement = new ReceiptAcknowledgement__c();
        receiptAcknowledgement.Amount__c = amount;
        receiptAcknowledgement.Account__c = accId;
        receiptAcknowledgement.SalesOrder__c = salesOrder;
        receiptAcknowledgement.Unit__c = unit;
        receiptAcknowledgement.PaymentType__c = paymentType;
        receiptAcknowledgement.Opportunity__c = oppId;
        receiptAcknowledgement.Status__c = status;
        receiptAcknowledgement.Finance_Verified__c = financeVerified;
        receiptAcknowledgement.VerifyDate__c = Date.today();
        receiptAcknowledgement.ReceiptPostingDate__c = Date.today();
        receiptAcknowledgement.MaturityDate__c = Date.today();
        receiptAcknowledgement.BankName__c= bankName;
        receiptAcknowledgement.ReferenceNumber__c= refNumber;
        return receiptAcknowledgement;
    }
    
    public IntegrationRecord__c getReceiptAckIntegrationRecord(String action, ReceiptAcknowledgement__c receiptAck){
        IntegrationRecordService objIntegrationRecordService = IntegrationRecordService.getInstance();
        Map<String, String> paramMap = new Map<String, String>();
        paramMap.put('Param1', receiptAck.SAP_Company_Code__c);
        paramMap.put('Param2', receiptAck.SAP_Contract_Number__c);
        paramMap.put('Param3', String.valueOf(receiptAck.Name));
        paramMap.put('Param4', receiptAck.New_Maturity_Date__c != null ? String.valueOf(receiptAck.New_Maturity_Date__c) : String.valueOf(receiptAck.MaturityDate__c));
    
        paramMap.put('Param5', String.valueOf(receiptAck.VerifyDate__c));
        paramMap.put('Param6', receiptAck.Unit__r != null ? receiptAck.Unit__r.SAP_Unit_Number__c : '');
        paramMap.put('Param7', String.valueOf(receiptAck.Amount__c));
        paramMap.put('Param8', receiptAck.SalesOrder__r.Unit__r.Project__r.SAPProfitCenter__c != null ? receiptAck.SalesOrder__r.Unit__r.Project__r.SAPProfitCenter__c : '');
        paramMap.put('Param9', receiptAck.ReferenceNumber__c);
        paramMap.put('Param10', receiptAck.BankName__c);
        paramMap.put('Param11', receiptAck.SAP_Main_Buyer_BP_No__c);
        paramMap.put('Param12', receiptAck.SAP_Cheque_GL_Sub_Account__c);
        paramMap.put('Param13', receiptAck.SAP_Wire_GL_Sub_Account__c);
        paramMap.put('Param14', receiptAck.SAP_Special_GL_Indicator__c);
        paramMap.put('Param15', receiptAck.ReversalApprovalStatus__c == 'Approved' ? 'X' : '');
        paramMap.put('Param16', receiptAck.ActualReversalDate__c != null ? String.valueOf(receiptAck.ActualReversalDate__c) : '');
        paramMap.put('Param17', receiptAck.Reason__c);
        paramMap.put('Param18', receiptAck.ReversalComments__c);
        paramMap.put('Param19', receiptAck.ReceiptReversalCategory__c);
        paramMap.put('Param20', '');
        paramMap.put('Param21', '');
        paramMap.put('Param22', '');
        paramMap.put('Param23', '');
        paramMap.put('Param24', receiptAck.ReceiptPostingDate__c != null ? String.valueOf(receiptAck.ReceiptPostingDate__c) : '');
        paramMap.put('Param25', receiptAck.PaymentType__c != null && receiptAck.PaymentType__c == 'Online' ? 'Online' : '');
        paramMap.put('Param26', receiptAck.SAP_Document_No__c != null ? receiptAck.SAP_Document_No__c : '');
        return objIntegrationRecordService.getIntegrationRecord(INTEGRATION_TYPE_SALES_RECEIPT_INTEGRATION, action, 'ReceiptAcknowledgement__c', receiptAck.Id, paramMap);
    }
}