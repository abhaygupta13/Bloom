/***
Class       : SalesOrderService
Author      : Biswajeet
Description : 
TestClass   : SalesOrderServiceTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0            25/08/23            Initial Version 
1.1         V1.1            14/02/25            Added additional fields in getSalesOrdersByIds() 
1.2         V1.2            17/02/25            Added additional fields in getSalesOrdersByIds()
1.3         V1.3            02/03/25            Added new method for Joint Owners
1.4			V1.4			20/11/25			Added new method for StatementOfAccount
1.5			V1.5			10/07/26			Added rebate fields in getSalesOrderWithInstallmentAndReceiptAllocation()
****************************************************************************************************************/

public inherited sharing class SalesOrderService {
    
    private static final string RESIDENT_CUST_TYPE { get { return 'Resident'; } }
    private static final string INTERNATIONAL_CUST_TYPE { get { return 'International'; } }
    private static final string GCC_CUST_TYPE { get { return 'GCC'; } }
    private static final string UAE_NATIONAL_CUST_TYPE { get { return 'UAE National'; } }
    private static final string SPA_SIGNED_DOC_TYPE { get { return 'SPA - Signed'; } }
    private static final string PASSPORT_DOC_TYPE { get { return 'Passport'; } }
    private static final string EID_DOC_TYPE { get { return 'Emirates ID'; } }
    private static final Set<String> SALES_ORDER_ADHA_STATUSES = new Set<String>{'Booked','Reserved','Sold'};
        private static final string CUSTOMER_SIGNED_SUB_STATUS { get { return 'SPA Counter Signed'; } }
    private static final string UPDATE_STR { get { return 'Update'; } }
    private static final string SALES_ORDER_OBJECT_API_NAME { get { return 'SalesOrder__c'; } }
    private static final string SALES_ORDER_STATUS_BOOKED { get { return 'Booked'; } }
    private static final string SALES_ORDER_STATUS_RESERVED { get { return 'Reserved'; } }
    private static final string SALES_ORDER_STATUS_SOLD { get { return 'Sold'; } }
    private static final string SALES_ORDER_MULE_STATUS_DEV_NEW { get { return 'DEV_NEW'; } }
    private static final string SALES_ORDER_MULE_STATUS_DEV_SALES_OFFER_GENERATED { get { return 'DEV_SALES_OFFER_GENERATED'; } }
    private static final string SALES_ORDER_MULE_STATUS_DEV_RESERVATION_AGREEMENT_SIGNED { get { return 'DEV_RESERVATION_AGREEMENT_SIGNED'; } }
    private static final string SALES_ORDER_MULE_STATUS_DEV_SPA_SIGNED { get { return 'DEV_SPA_SIGNED'; } }
    private static final string DOC_NAME_SPA_SIGNED { get { return  'SPA Signed'; } }
    private static final string DOC_NAME_SIGNED_BOOKING_FORM { get { return  'Signed_Booking_Form'; } }
    private static final string DOC_TYPE_PDF { get { return  'pdf'; } }
    private static final string SALES_ORDER_ADHA_STATUS_DEV_INITIAL_CANCEL { get { return 'DEV_INITIAL_CANCEL'; } }
    private static final string CUSTOMER_SUB_TYPE_STAFF { get { return 'STAFF'; } }
    
    
    private static SalesOrderService instance;
    
    private SalesOrderService() {
        
    }
    
    public static SalesOrderService getInstance() { 
        if(instance == null) {
            instance = new SalesOrderService();
        }
        return instance;
    }
    public List<SalesOrder__c> getSalesOrdersByOppIds(Set<Id> oppIds){
        return [SELECT Id,Opportunity__r.id,PriorADHAStatus__c FROM SalesOrder__c WHERE
                Opportunity__r.id IN:oppIds];  
    }
    public List<SalesOrder__c> getSalesOrdersByIds(Set<Id> salesOrderIds){
        return [SELECT Id, Direct_Indirect__c,Name,Sales_Price_Excluding_ADM__c,Sales_Order_Received_Amount__c,SalesOrderReceivedAmountinwords__c, 
                SalesManager__c,Account__r.RecordType.DeveloperName,Account__r.PersonEmail,Unit__r.Project__c,Account__c,Account__r.name, 
                Company_Code__c, SoldDate__c,BookingDate__c, Status__c, Project__c, ADMFeeAmount__c, ADM_Fee_Included__c, 
                Opportunity__r.BrokerAgencyAccount__c, Opportunity__r.BrokerAgentContact__c, Opportunity__r.Lead__r.LeadSource,
                Opportunity__r.Lead__r.leadsubsource__c, NetAmount__c, Drawloop_Next_1__c,
                Unit__r.Project__r.HOCEmailTemplateFullyPaid__c, Unit__r.Project__r.HOCEmailTemplatePartiallyPaid__c, 
                Sales_Order_Installment_Total__c, Sales_Order_Cleared_Amount__c,Unit__r.Name, Sales_Order_Pending_Amount__c,
                ProjectName__c, UnitNumber__c,Resale__c,Unit__r.Project__r.RecoveryFeeCondType__c,Unit__r.Project__r.PendingFeeCondType__c,
                Unit__r.Project__r.ChequeBounceFeeCondType__c,Unit__r.Project__r.LatePaymentChargesCondType__c,
                Unit__r.Project__r.ChequeWithWithdrawalFeeCondType__c,Unit__r.Project__r.ADMAdminFeeCondType__c, 
                Unit__r.Project__r.EvaluationFeesCondType__c,Unit__r.Project__r.MortgageFeesCondType__c,Unit__r.Project__r.HassantukFeeCondType__c,
                Unit__c,Unit__r.Project__r.ChequePostponementFeeCondType__c,Unit__r.Project__r.chequePostponeFeeShortTerm__c,Unit__r.Project__r.chequePostponeFeeLongTerm__c,
                Unit__r.Project__r.ChequeReplacementFeeCondType__c,Unit__r.Project__r.ChequeWithdrawalFeeCondType__c, NewSalesOrder__c, PreviousSalesOrder__c,
                Unit__r.Project__r.PropertyEnrollmentUnderTawtheeqCondType__c,Unit__r.Project__r.ResaleAdminFeeCondType__c,
                Unit__r.Project__r.ADDCConditionType__c,Unit__r.Project__r.MergedPaidInstallmentConditionType__c,Unit__r.Project__r.RebateConditionType__c,
                Unit__r.Project__r.DariTitleDeedFeeCondType__c,Unit__r.Project__r.BounceChequeFeeVATApplicable__c,Unit__r.Project__r.ADMFeeCondType__c,
                IsDraftOrder__c, Unit__r.Project__r.AdditionalADMFeeConditionType__c, Unit__r.Project__r.UAEPassFeeConditionType__c,
                Unit__r.Project__r.AdminChargesCondType__c, Unit__r.Project__r.UnitCancellationFeesCondType__c,Unit__r.Project__r.ModificationAdvanceFeeCondType__c,
                Unit__r.Project__r.TammFeeConditionType__c,Unit__r.Project__r.ResaleRenewalFeesCondType__c
                FROM SalesOrder__c
                WHERE Id IN :salesOrderIds];
    }
    
    public List<SalesOrder__c> getSalesOrdersNOtherChargesByIds(Set<Id> brokerIdSet, Set<Id> projectIdSet, Integer thresholdAmount){
        return [SELECT Id, Direct_Indirect__c,Name,Sales_Price_Excluding_ADM__c,Sales_Order_Received_Amount__c,SalesOrderReceivedAmountinwords__c, 
                SalesManager__c,Account__r.RecordType.DeveloperName,Account__r.PersonEmail,Unit__r.Project__c,Account__c,Account__r.name, 
                Company_Code__c, SoldDate__c,BookingDate__c, Status__c, Project__c, ADMFeeAmount__c, ADM_Fee_Included__c, 
                Opportunity__r.BrokerAgencyAccount__c, Opportunity__r.BrokerAgentContact__c, Opportunity__r.Lead__r.LeadSource,
                Opportunity__r.Lead__r.leadsubsource__c, NetAmount__c, Drawloop_Next_1__c, Opportunity__r.BrokerAgencyAccount__r.Is_VAT_Registered__c,
                Unit__r.Project__r.HOCEmailTemplateFullyPaid__c, Unit__r.Project__r.HOCEmailTemplatePartiallyPaid__c,
                Unit__r.Project__r.ApplyADRECBrokerCommissionPolicy__c,Unit__r.Project__r.VATPercentage__c,
                Unit__r.UnitType__c, Unit__r.UnitModel__c,TaxableAmount__c,
                Sales_Order_Installment_Total__c, Sales_Order_Cleared_Amount__c,Unit__r.Name, Sales_Order_Pending_Amount__c,
                Unit__r.Project__r.ProjectRegistrationDate__c, PreviousSalesOrder__c,ADM_DLD_Pre_Registered_Date__c,
                ProjectName__c, UnitNumber__c, Resale__c,(SELECT Id,InvoicedAmount__c,Amount__c,OutstandingAmount__c FROM SalesOrdersOtherCharges__r WHERE OutstandingAmount__c >= 0 AND OutstandingAmount__c <= :thresholdAmount AND TypeOfCharge__c = 'ADM Fee' LIMIT 1) FROM SalesOrder__c
                WHERE Opportunity__r.BrokerAgencyAccount__c IN :brokerIdSet AND Unit__r.Project__c IN :projectIdSet];
    }
    
    public List<SalesOrder__c> getNewSalesOrdersByIds(Set<Id> salesOrderIds){
        return [SELECT Id, Direct_Indirect__c,Name,Sales_Price_Excluding_ADM__c,Sales_Order_Received_Amount__c,SalesOrderReceivedAmountinwords__c, 
                SalesManager__c,Account__r.RecordType.DeveloperName,Account__r.FirstName,Account__r.LastName,Account__r.PersonEmail,Account__r.Name,
                Account__r.PersonMobilePhone, Account__r.Legal_Status__c, Account__r.IsPersonAccount, SAP_Contract_No__c, Discount__c, 
                PreviousSalesOrder__c, IsDefaulted__c, SalesPriceExcludingADMWithDiscount__c, ADM_Fee_Combined__c, 
                First_Installment_Amount__c, First_Installment_Received_Amount__c, Offer__r.Name, PaymentPlan__c, PaymentPlan__r.Name,
                Unit__r.Name, Unit__r.Building__c, Unit__r.Project__r.City__c, Unit__r.Project__r.ResaleEligibleAmoutPercentage__c, 
                Unit__r.Project__c,Account__c, Broker_Agencyy__c, Broker_Agent__c, Opportunity__c,
                Company_Code__c, SoldDate__c,BookingDate__c, Status__c, ADMFeeAmount__c, ADM_Fee_Included__c, 
                Opportunity__r.BrokerAgencyAccount__c, Opportunity__r.BrokerAgentContact__c, Opportunity__r.BrokerAgentContact__r.Email,
                Opportunity__r.BrokerAgencyAccount__r.Name, Unit__r.Legal_Status__c, Unit__r.RegistrationDate__c,
                NetAmount__c, Drawloop_Next_1__c, Unit__c, Unit__r.UnitNumber__c,
                Unit__r.Project__r.HOCEmailTemplateFullyPaid__c, Unit__r.Project__r.HOCEmailTemplatePartiallyPaid__c, 
                Sales_Order_Installment_Total__c, Sales_Order_Cleared_Amount__c, Sales_Order_Pending_Amount__c,
                ProjectName__c, UnitNumber__c, Resale__c, Sale_Type__c, ResaleBrokerAgency__c, ResaleBrokerAgent__c,
                ResaleBrokerAgent__r.Email, ResaleBrokerAgency__r.Name
                FROM SalesOrder__c
                WHERE Id IN :salesOrderIds];
    }
    
    public List<SalesOrder__c> getSalesOrdersWithInstallment(Set<Id> salesOrderIds){
        return[SELECT Id, (SELECT Id, CreatedDate, InstallmentDate__c FROM InstallmentLines__r ORDER BY InstallmentDate__c desc LIMIT 1) 
               FROM SalesOrder__c WHERE Id IN : salesOrderIds]; 
    }
    public SalesOrder__c getSalesOrdersById(Id salesOrderId){   
        return [SELECT Id, Name, Account__c, Account__r.Id, Account__r.Name, Account__r.FirstName, Account__r.LastName, Account__r.PersonEmail, Account__r.PersonMobilePhone, 
                Account__r.Legal_Status__c, Account__r.IsPersonAccount, Account__r.RecordType.DeveloperName, Direct_Indirect__c, Company_Code__c, SAP_Contract_No__c, Status__c, Project__c, 
                ProjectName__c, UnitNumber__c, Resale__c, Broker_Agencyy__c, Broker_Agent__c, SalesManager__c, SoldDate__c, BookingDate__c, Drawloop_Next_1__c, Discount__c, PreviousSalesOrder__c, 
                IsDefaulted__c, Sales_Price_Excluding_ADM__c, SalesPriceExcludingADMWithDiscount__c, ADMFeeAmount__c, ADM_Fee_Combined__c, ADM_Fee_Included__c, NetAmount__c, Sales_Order_Received_Amount__c, 
                SalesOrderReceivedAmountinwords__c, Sales_Order_Installment_Total__c, Sales_Order_Cleared_Amount__c, Sales_Order_Pending_Amount__c, First_Installment_Amount__c, First_Installment_Received_Amount__c, 
                Opportunity__c, Opportunity__r.BrokerAgencyAccount__c, Opportunity__r.BrokerAgentContact__c, Opportunity__r.BrokerAgentContact__r.Email, Offer__r.Name, PaymentPlan__c, PaymentPlan__r.Name, Unit__c, 
                Unit__r.Name, Unit__r.UnitNumber__c, Unit__r.Building__c, Unit__r.Project__c, Unit__r.Project__r.City__c, Unit__r.Project__r.ResaleEligibleAmoutPercentage__c, Unit__r.Project__r.HOCEmailTemplateFullyPaid__c, 
                Unit__r.Project__r.HOCEmailTemplatePartiallyPaid__c, Unit__r.Legal_Status__c, Unit__r.RegistrationDate__c
                FROM SalesOrder__c
                WHERE Id =:salesOrderId];
    }
    
    public Map<Id, SalesOrder__c> getSalesOrdersMap(Set<Id> salesOrderIdSet){
        Map<Id, SalesOrder__c> soMap = new Map<Id, SalesOrder__c>(
            [SELECT Id, Unit__c, Account__c, Drawloop_Next_1__c, Name, 
             Unit__r.Project__r.DefaultUnpaidAmount__c, Unit__r.Project__r.ResaleUnitAdminFeeVilla__c,
             Unit__r.Project__r.ResaleUnitEvaluationFeeVilla__c, Unit__r.Project__r.ResaleUnitAdminFeeApt__c,
             Unit__r.Project__r.ResaleUnitEvaluationFeeApt__c,Unit__r.Project__r.ResaleWithMortgageAdminFeeVilla__c,
             Unit__r.Project__r.ResaleWithMortgageMortgageFeeVilla__c,
             Unit__r.Project__r.ResaleWithMortgageEvaluationFeeVilla__c,
             Unit__r.Project__r.ResaleWithMortgageAdminFeeApt__c,
             Unit__r.Project__r.ResaleWithMortgageMortgageFeeApt__c,Unit__r.Project__r.ResaleWithMortgageEvaluationFeeApt__c,
             Unit__r.Project__r.DefaultUnpaidAmountPercentage__c, PostDueDateReminderSentDate__c, 
             Sales_Order_Pending_Amount__c, DefaultCustomerLastReminderSentDate__c, 
             Unit__r.Project__r.Name, PHPP__c, Unit__r.Project__r.City__c, Unit__r.Project__r.SendDefaultNotice__c, 
             Unit__r.Name, Account__r.Name, Account__r.isPersonAccount, Account__r.PersonContactId, 
             Account__r.PersonContact.Name, Account__r.NameinArabic__c, Account__r.PersonMobilePhone, Contact__c, 
             Contact__r.Name, Status__c, Unit__r.Project__c, Unit__r.Project__r.ProjectNameArabic__c, 
             Unit__r.BuildingSectionName__r.Primary_Account_Installment__c, 
             Unit__r.BuildingSectionName__r.HandoverAccountInstallment__c, 
             Unit__r.BuildingSectionName__r.PHPPAccountInstallment__c, 
             CustomerDefaultStatus__c, Unit__r.Project__r.DefaultNotificationDays__c, Unit__r.Project__r.AdminFee__c,
             SellingPrice__c,Resale__c 
             FROM SalesOrder__c WHERE Id IN :salesOrderIdSet]
        );
        /* Map<Id, SalesOrder__c> soMap = new Map<Id, SalesOrder__c>([SELECT Id, Unit__c,Account__c, Drawloop_Next_1__c
FROM SalesOrder__c WHERE ID IN :salesOrderId]);  */
        return soMap;
    }
    
    public List<SalesOrder__c> updateSalesOrders(List<SalesOrder__c> salesOrders){
        if(salesOrders != NULL && !salesOrders.isEmpty()){
            Database.update(salesOrders, false);
        }
        return salesOrders;
    }
    
    public List<SalesOrder__c> getUnitRegisteredSalesOrders(Set<Id> salesOrderIds){
        return [Select Id, Name, ProjectArabicName__c, Unit__c, Unit__r.Name, Unit__r.Project__r.Name, Unit__r.Project__c, Unit__r.Project__r.ProjectNameArabic__c, 
                UnitRegistrationDate__c, Account__c, Account__r.Name, Account__r.PersonEmail, Contact__c, Account__r.PersonContactId
                FROM SalesOrder__c 
                WHERE Id In :salesOrderIds AND UnitRegistrationDate__c != null];
    }
    
    public List<SalesOrder__c> getSalesOrdersWithDocuments(List<String> salesOrderIds){
        return [
            SELECT Id, Name, Account__r.CustomerType__c, DocumentUploadedDate__c,
            (SELECT Id, Name, DocumentType__r.Type__c, ContentDocumentId__c FROM Documents__r WHERE ContentDocumentId__c != null)
            FROM SalesOrder__c WHERE Id in  :salesOrderIds];
    }
    public SalesOrder__c getSalesOrderByUnit(Id unitId){
        return [Select Id,Unit__c,IsDefaulted__c,Status__c FROM SalesOrder__c WHERE Unit__c =:unitId and Status__c = 'Sold'];
    }
    public List<SalesOrder__c>  getSalesOrderByUnitIds(Set<Id> unitIds){
        return [Select Id,Unit__c,IsDefaulted__c,Status__c FROM SalesOrder__c WHERE Unit__c IN:unitIds and Status__c = 'Sold'];
    }
    
    public List<SalesOrder__c> getSalesOrders(List<String> salesOrderIds, Date documentUploadedDate){
        return [
            SELECT Id, Name, Account__r.CustomerType__c, DocumentUploadedDate__c,
            (SELECT Id, Name, DocumentType__r.Type__c, ContentDocumentId__c FROM Documents__r WHERE ContentDocumentId__c != null)
            FROM SalesOrder__c WHERE Id in  :salesOrderIds AND DocumentUploadedDate__c = :documentUploadedDate];
    }
    
    public List<SalesOrder__c> getSalesOrdersBySalesManager(String status, Set<Id> salesManagerIdSet, Integer selectedYear, Integer selectedQuarter){
        return [SELECT Id,IsTaxable__c, Tax_Percentage__c, TaxableAmount__c, Opportunity__r.LeadSubSource__c, Sales_Price_Excluding_ADM__c,BookingDate__c, NetAmount__c, ADM_Fee_Included__c, ADMFeeAmount__c,Unit__r.Project__r.PreLaunchStartDate__c, Unit__r.Project__r.PreLaunchEndDate__c, Unit__r.Project__r.LaunchStartDate__c, Unit__r.Project__r.LaunchEndDate__c, Opportunity__r.LeadSource, Unit__r.Project__r.PostLaunchStartDate__c, Unit__r.Project__r.PostLaunchEndDate__c, Opportunity__r.BrokerAgencyAccount__c,Opportunity__r.BrokerAgentContact__c,Project__c,
                SoldDate__c, SalesManager__c,Status__c,Secondary_Sales_Manager__c, Sale_Type__c, UpgradedFrom__c, UpgradedFrom__r.IsTaxable__c, UpgradedFrom__r.Tax_Percentage__c, UpgradedFrom__r.TaxableAmount__c, 
                UpgradedFrom__r.SoldDate__c, UpgradedFrom__r.ADM_Fee_Included__c, UpgradedFrom__r.Sales_Price_Excluding_ADM__c, UpgradedFrom__r.NetAmount__c
                FROM SalesOrder__c WHERE Account__r.CustomerSubType__c != :CUSTOMER_SUB_TYPE_STAFF AND Status__c =: status AND  (SalesManager__c IN :salesManagerIdSet OR Secondary_Sales_Manager__c IN :salesManagerIdSet) AND Resold__c = false AND Resale__c = false AND CALENDAR_YEAR(SoldDate__c) =: selectedYear AND CALENDAR_QUARTER(SoldDate__c) =: selectedQuarter];
    }
       public SalesOrder__c getSalesOrderByCaseId(Id salesOrderId){   
        return [SELECT Id, Name,Account__c, Company_Code__c, SAP_Contract_No__c,Sales_Order_Pending_Amount_in_Words_Arab__c,Sales_Order_Pending_Amount__c,IsDefaulted__c, Unit__r.Project__c,Unit__r.Project__r.City__c,Unit__r.Building__c,
                Status__c, Unit__c,NetAmount__c,Account__r.Legal_Status__c, Unit__r.Name,First_Installment_Received_Amount__c,First_Installment_Amount__c,
                Account__r.Id,Offer__r.Name,Unit__r.Project__r.ResaleEligibleAmoutPercentage__c, Account__r.Name, Account__r.IsPersonAccount, 
                Account__r.PersonMobilePhone, Contact__c, Account__r.PersonContactId FROM SalesOrder__c WHERE Id =:salesOrderId];
    }
    public List<SalesOrder__c> getSalesOrdersWithJointOwner(Set<Id> salesOrderIds){
        return [SELECT Id, Name,AccountName__c,Sales_Price_Excluding_ADM__c,Sales_Order_Received_Amount__c, SalesManager__c,Account__r.RecordType.DeveloperName,Account__r.PersonEmail,Account__r.Salutation,
                Account__r.FirstName, Account__r.MiddleName, Account__r.LastName, Account__r.Name, Account__r.Title_Arabic__c, Account__r.NameinArabic__c,
                Unit__r.Project__c,Account__c, Company_Code__c, SoldDate__c,
                BookingDate__c, Status__c, Project__c, ADMFeeAmount__c, ADM_Fee_Included__c, Opportunity__r.BrokerAgencyAccount__c, Opportunity__r.BrokerAgentContact__c, NetAmount__c, Unit__c, 
                Unit__r.Project__r.HOCEmailTemplateFullyPaid__c, Unit__r.Project__r.HOCEmailTemplatePartiallyPaid__c, Sales_Order_Installment_Total__c, Sales_Order_Cleared_Amount__c, Sales_Order_Pending_Amount__c,
                (SELECT Id,Account__c,Account__r.RecordType.DeveloperName,Account__r.Salutation,Account__r.FirstName, 
                 Account__r.MiddleName, Account__r.LastName, Account__r.Name, Name_In_Arabic__c,SalesOrder__c,
                 Account__r.Title_Arabic__c, Account__r.NameinArabic__c, IsActive__c FROM Joint_OwnersSalesOrder__r
                 ORDER BY CreatedDate) FROM SalesOrder__c WHERE Id IN :salesOrderIds];
    }
    
    public List<SalesOrder__c> getSalesOrderWithInstallmentLinesReceiptAllocation(String salesOrderId) {
        return [SELECT Id,BookingDate__c,Unit__r.UnitModel__c,Unit__r.ProjectName__c,Unit__r.UnitNumber__c,NetAmount__c,Unit__r.UnitType__c,Account__r.PersonEmail,Account__r.PersonMailingPostalCode,Account__r.Name,Account__r.PersonMobilePhone,Account__r.AccountNumber__c,Account__r.MobileCountryCode__c,Account__r.PersonMailingCity,Account__r.PersonMailingCountry,Name,Account__r.PersonMailingState,Account__r.PersonMailingStreet,SalesOrder__c.UnitNumber__c, ADM_Fee_Included__c,Unit__r.BuildingSectionName__r.Name,Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.BankNameCorporate__c,Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.BeneficiaryNameCorporate__c,
                Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.BranchCorporate__c,Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.AccountNumberCorporate__c,Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.SwiftCodeCorporate__c,Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.IBANNoCorporate__c, Sales_Order_Number__c, SellingPrice__c, ProjectName__c, AccountName__c, Virtual_Bank_Account_Number__c, Virtual_Account_IBAN__c, Sales_Order_Cleared_Amount__c, Net_Amount_excl_ADMWaiver__c, Sales_Price_Excluding_ADM__c,ADMFeeWaivedAmount__c,ADMFeeAmount__c,
                (SELECT Id,InstallmentDate__c,InstallmentNumber__c,InstallmentAmount__c,Name,InstallmentPercentage__c,PendingAmount__c,LPCAmount__c,Due_Date__c FROM InstallmentLines__r ORDER BY InstallmentNumber__c),
                (SELECT Id, Name,ReceiptStatus__c,Receipt_Reference__c,InstallmentLine__r.InstallmentDate__c,InstallmentLine__r.InstallmentNumber__c,InstallmentLine__r.InstallmentAmount__c,InstallmentLine__r.Name,InstallmentLine__r.InstallmentPercentage__c,InstallmentLine__r.PendingAmount__c,InstallmentLine__r.LPCAmount__c,InstallmentLine__r.Due_Date__c,InstallmentAmountOtherChargeAmount__c,Receipt_Type__c, Applied_To__c, Receipt_Number__c, ReceiptAcknowledgementAmount__c,
                 ReceiptAcknowledgement__r.BankName__c,ReceiptAcknowledgement__r.RemitterName__c,ReceiptAcknowledgement__r.MaturityDate__c,ReceiptAcknowledgement__r.New_Maturity_Date__c,ReceiptAcknowledgement__r.Status__c,ReceiptAcknowledgement__r.Amount__c, 
                 InstallmentNumberOrChargeType__c, AmountApplied__c, InstallmentLine__c, SalesOrderOtherCharges__c,SalesOrderOtherCharges__r.Name,SalesOrderOtherCharges__r.Due_Date__c,SalesOrderOtherCharges__r.TypeOfCharge__c,SalesOrderOtherCharges__r.Amount__c,SalesOrderOtherCharges__r.PendingAmount__c,DateOfApplication__c FROM ReceiptAllocations__r WHERE ReceiptStatus__c != 'Reversed' Order By InstallmentNumberOrChargeType__c ASC)
                FROM Salesorder__c  
                WHERE Id = :salesorderId];
    }
    
    public SalesOrder__c getSalesOrderWithInstallmentAndReceiptAllocation(String salesOrderId) {
        return [SELECT Id,BookingDate__c,Unit__r.UnitModel__c,Unit__r.ProjectName__c,Unit__r.UnitNumber__c,NetAmount__c,Unit__r.UnitType__c,Account__r.IsPersonAccount,Account__r.Phone,Account__r.PersonEmail,Account__r.PersonMailingPostalCode,Account__r.Name,Account__r.PersonMobilePhone,Account__r.AccountNumber__c,Account__r.MobileCountryCode__c,Account__r.PersonMailingCity,Account__r.PersonMailingCountry,Name,Account__r.PersonMailingState,Account__r.PersonMailingStreet,SalesOrder__c.UnitNumber__c, 
                ADM_Fee_Included__c,Unit__r.BuildingSectionName__r.Name,Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.BankNameCorporate__c,Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.BeneficiaryNameCorporate__c,
                Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.BranchCorporate__c,Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.AccountNumberCorporate__c,Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.SwiftCodeCorporate__c,Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.IBANNoCorporate__c, Sales_Order_Number__c, SellingPrice__c, ProjectName__c, AccountName__c, Virtual_Bank_Account_Number__c, Virtual_Account_IBAN__c, Sales_Order_Cleared_Amount__c, Net_Amount_excl_ADMWaiver__c, Sales_Price_Excluding_ADM__c,ADMFeeWaivedAmount__c,ADMFeeAmount__c,ADM_Fee_Cleared_Amount__c,SoldDate__c,Tax_Percentage__c,
                Amount_Payable_Excluding_ADM__c,TaxableAmount__c,ADM_Waiver__c,Unit__r.BuildingSectionName__r.BounceChequeAccount__r.BankNameCorporate__c,Unit__r.BuildingSectionName__r.BounceChequeAccount__r.BeneficiaryNameCorporate__c,Unit__r.BuildingSectionName__r.BounceChequeAccount__r.BranchCorporate__c,Unit__r.BuildingSectionName__r.BounceChequeAccount__r.AccountNumberCorporate__c,Unit__r.BuildingSectionName__r.BounceChequeAccount__r.SwiftCodeCorporate__c,Unit__r.BuildingSectionName__r.BounceChequeAccount__r.IBANNoCorporate__c,
                (SELECT Id,InstallmentDate__c,InstallmentNumber__c,InstallmentAmount__c,Name,InstallmentPercentage__c,PendingAmount__c,LPCAmount__c,Due_Date__c FROM InstallmentLines__r ORDER BY InstallmentNumber__c),
                (SELECT Id,Name,TypeOfCharge__c,Due_Date__c,Amount__c,PendingAmount__c FROM SalesOrdersOtherCharges__r WHERE Status__c != 'Reversed' ORDER BY Due_Date__c ASC),
                (SELECT Id,Name,Date__c,Percentage__c,Amount__c,Status__c,ConditionType__c,InstallmentLine__c,InstallmentLine__r.Name FROM SalesOrderRebates__r WHERE Status__c != 'Reversed' ORDER BY Date__c ASC),
                (SELECT Id,Name,SalesOrder__c,Receipt__c,Receipt__r.Name,Amount__c,CreatedDate,Remarks__c,ERPReferenceNo__c,Status__c,IntegrationStatus__c,IntegrationMessage__c FROM SalesOrderRefunds__r ORDER BY CreatedDate ASC),
                (SELECT Id, Name,ReceiptStatus__c,Receipt_Reference__c,InstallmentLine__r.InstallmentDate__c,InstallmentLine__r.Due_Date__c,InstallmentLine__r.InstallmentNumber__c,InstallmentLine__r.InstallmentAmount__c,InstallmentLine__r.Name,InstallmentLine__r.InstallmentPercentage__c,InstallmentLine__r.PendingAmount__c,InstallmentLine__r.LPCAmount__c,InstallmentAmountOtherChargeAmount__c,Receipt_Type__c, Applied_To__c, Receipt_Number__c, ReceiptAcknowledgementAmount__c,
                 ReceiptAcknowledgement__r.BankName__c,ReceiptAcknowledgement__r.MaturityDate__c,ReceiptAcknowledgement__r.New_Maturity_Date__c,ReceiptAcknowledgement__r.Status__c,ReceiptAcknowledgement__r.Amount__c,DateOfApplication__c,
                 InstallmentNumberOrChargeType__c, AmountApplied__c, InstallmentLine__c, SalesOrderOtherCharges__c,SalesOrderOtherCharges__r.Name,SalesOrderOtherCharges__r.Due_Date__c,SalesOrderOtherCharges__r.TypeOfCharge__c,SalesOrderOtherCharges__r.Amount__c,SalesOrderOtherCharges__r.PendingAmount__c FROM ReceiptAllocations__r WHERE ReceiptStatus__c != 'Reversed' Order By InstallmentNumberOrChargeType__c ASC)
                FROM Salesorder__c  
                WHERE Id = :salesOrderId LIMIT 1];
    }
    
    public void updateDocumentUploadDate(Set<String> salesOrderIds){
        List<SalesOrder__c> updateSalesOrderRecords = new List<SalesOrder__c>();
        List<SalesOrder__c> salesOrders = getSalesOrders(new List<String>(salesOrderIds), null);
        
        //System.debug('salesOrders -------->' +salesOrders);
        // Iterate through Sales Orders
        for (SalesOrder__c salesOrder : salesOrders) {
            Boolean hasSPA = false;
            Boolean hasEID = false;
            Boolean hasPassport = false;
            
            // Check document types
            for (Document__c doc : salesOrder.Documents__r) {
                if (doc.DocumentType__r.Type__c == SPA_SIGNED_DOC_TYPE) hasSPA = true;
                if (doc.DocumentType__r.Type__c == EID_DOC_TYPE) hasEID = true;
                if (doc.DocumentType__r.Type__c == PASSPORT_DOC_TYPE) hasPassport = true;
            }
            
            // Apply logic based on Customer Type
            if (hasSPA) {
                String salesOrderId = null;
                if ((salesOrder.Account__r.CustomerType__c == RESIDENT_CUST_TYPE || salesOrder.Account__r.CustomerType__c == UAE_NATIONAL_CUST_TYPE) && hasEID) {
                    salesOrderId = salesOrder.Id;
                } else if ((salesOrder.Account__r.CustomerType__c == GCC_CUST_TYPE || salesOrder.Account__r.CustomerType__c == INTERNATIONAL_CUST_TYPE) && hasPassport) {
                    salesOrderId = salesOrder.Id;
                }
                if(salesOrderId != null){
                    updateSalesOrderRecords.add(new SalesOrder__c(Id = salesOrderId, DocumentUploadedDate__c = Date.today())); 
                }
            }
            if(updateSalesOrderRecords.size() > 0){
                updateSalesOrders(updateSalesOrderRecords);
            }
        }
    }
    public List<SalesOrder__c> getADHASalesOrders(Set<Id> salesOrderIds){
        return [Select Id ,ADHAApplicationNumber__c,Status__c ,Opportunity__r.Lead__c,SubStatus__c,Opportunity__r.ADHAStatus__c,
                (SELECT Id, Name, Content_Version_Id__c,DocumentType__r.Type__c FROM Documents__r WHERE
                 Content_Version_Id__c != null AND DocumentType__r.Type__c IN ('SPA - Signed','Booking Form - Signed')),
                Unit__r.ADMPlotNumber__c,Unit__r.PlotAddress__c,Unit__r.Project__r.Name,Unit__r.Project__r.ProjectNameArabic__c,
                Unit__r.Project__r.DistrictNameAr__c,Unit__r.Project__r.DistrictNameEN__c,
                Unit__r.Project__r.MunicipalityNameAR__c , Unit__r.Project__r.MunicipalityNameEN__c,
                Unit__r.BuildingSectionName__r.ConstructionStatus__c , Unit__r.Location__Latitude__s ,Unit__r.Location__Longitude__s,
                Unit__r.SellingPrice__c,Unit__r.Project__r.MunicipalityCode__c ,Unit__r.Project__r.CommunityCode__c,
                Unit__r.Project__r.DistrictCode__c,Unit__r.Project__r.ProjectId__c,Unit__r.MRNNumber__c,
                Unit__r.PlotArea__c , Unit__r.SaleableArea__c,Unit__r.Project__r.RoadId__c,Unit__r.BuildingSectionName__r.EndDate__c,
                Account__r.Emirates_Id__pc,ADHACancellationReason__c FROM SalesOrder__c 
                WHERE Id In :salesOrderIds AND ADHAApplicationNumber__c != null AND Opportunity__r.ADHAStatus__c != 'PC_Rejected' ];
    }
    
    public IntegrationRecord__c prepareIntegrationRecord(SalesOrder__c salesOrder){
        Map<String,String> paramsMap = new Map<String,String>();
        Map<String,String> statusValueMappings = new Map<String, String>{
SALES_ORDER_STATUS_BOOKED => SALES_ORDER_MULE_STATUS_DEV_NEW,
                SALES_ORDER_STATUS_RESERVED => SALES_ORDER_MULE_STATUS_DEV_SALES_OFFER_GENERATED,
SALES_ORDER_STATUS_SOLD => SALES_ORDER_MULE_STATUS_DEV_RESERVATION_AGREEMENT_SIGNED,
CUSTOMER_SIGNED_SUB_STATUS => SALES_ORDER_MULE_STATUS_DEV_SPA_SIGNED
                };
        IntegrationRecordService integService = IntegrationRecordService.getInstance();
        String muleStatus = statusValueMappings.get(salesOrder.SubStatus__c) ?? statusValueMappings.get(salesOrder.Status__c) ?? '' ;
        if( (muleStatus == SALES_ORDER_MULE_STATUS_DEV_NEW ||
             muleStatus == SALES_ORDER_MULE_STATUS_DEV_SALES_OFFER_GENERATED) &&
           String.isNotBlank(salesOrder.ADHACancellationReason__c) ){
               muleStatus = SALES_ORDER_ADHA_STATUS_DEV_INITIAL_CANCEL ;
           }
        paramsMap.put('Param1',salesOrder.ADHAApplicationNumber__c);
        paramsMap.put('Param2',muleStatus);
        paramsMap.put('Param3',salesOrder.Opportunity__r?.Lead__c );
        String contentVersionId = '';
        String docName = '';
        for(Document__c doc : salesOrder.Documents__r ){
            if(salesOrder.SubStatus__c == CUSTOMER_SIGNED_SUB_STATUS && salesOrder.Status__c == SALES_ORDER_STATUS_SOLD &&
               doc.DocumentType__r.Type__c == 'SPA - Signed'){
                contentVersionId = doc.Content_Version_Id__c; 
                docName = DOC_NAME_SPA_SIGNED;
                break ;
               }else if(salesOrder.Status__c == SALES_ORDER_STATUS_SOLD && doc.DocumentType__r.Type__c == 'Booking Form - Signed'){
                contentVersionId = doc.Content_Version_Id__c    ;   
                docName = DOC_NAME_SIGNED_BOOKING_FORM;
                break ;
            }
        }
        paramsMap.put('Param4',contentVersionId);
        paramsMap.put('Param5',salesOrder.Unit__r?.ADMPlotNumber__c);
        paramsMap.put('Param6',salesOrder.Unit__r?.PlotAddress__c);
        paramsMap.put('Param7',salesOrder.Unit__r?.ADMPlotNumber__c);
        paramsMap.put('Param8',salesOrder.Unit__r?.Project__r?.ProjectNameArabic__c);
        paramsMap.put('Param9',salesOrder.Unit__r?.Project__r?.Name);
        paramsMap.put('Param10',salesOrder.Unit__r?.Project__r?.DistrictNameAr__c);
        paramsMap.put('Param11',salesOrder.Unit__r?.Project__r?.DistrictNameEN__c);
        paramsMap.put('Param12',salesOrder.Unit__r?.Project__r?.MunicipalityNameAR__c);
        paramsMap.put('Param13',salesOrder.Unit__r?.Project__r?.MunicipalityNameEN__c);
        paramsMap.put('Param14',salesOrder.Unit__r?.Project__r?.Name);
        paramsMap.put('Param15',salesOrder.Unit__r?.Project__r?.ProjectNameArabic__c);
        paramsMap.put('Param16',salesOrder.Unit__r?.BuildingSectionName__r?.ConstructionStatus__c);
        paramsMap.put('Param17',String.valueOf(salesOrder.Unit__r?.Location__Latitude__s) ?? '');
        paramsMap.put('Param18',String.valueOf(salesOrder.Unit__r?.Location__Longitude__s) ?? '');
        paramsMap.put('Param19',String.valueOf(salesOrder.Unit__r?.SellingPrice__c) ?? '');
        paramsMap.put('Param20',salesOrder.Unit__r?.Project__r?.MunicipalityCode__c);
        paramsMap.put('Param21',salesOrder.Unit__r?.Project__r?.CommunityCode__c);
        paramsMap.put('Param22',salesOrder.Unit__r?.Project__r?.DistrictCode__c);
        paramsMap.put('Param23',salesOrder.Unit__r?.Project__r?.ProjectId__c);
        paramsMap.put('Param24',String.valueOf(salesOrder.Unit__r?.PlotArea__c) ?? '');
        paramsMap.put('Param25',String.valueOf(salesOrder.Unit__r?.SaleableArea__c) ?? '');
        paramsMap.put('Param26',salesOrder.Unit__r?.Project__r?.RoadId__c);
        paramsMap.put('Param27',String.valueOf(salesOrder.Unit__r?.BuildingSectionName__r?.EndDate__c) ?? '' );
        paramsMap.put('Param28',salesOrder.Unit__r?.MRNNumber__c);
        paramsMap.put('Param29', salesOrder.Account__r?.Emirates_Id__pc?.replaceAll('-', ''));//removing hyphens in emiratesID
        paramsMap.put('Param30', DOC_TYPE_PDF);
        paramsMap.put('Param31', docName);
        paramsMap.put('Param32', salesOrder.ADHACancellationReason__c);
        return integService.getIntegrationRecord('SALESORDER_ADHA_INTEGRATION',UPDATE_STR,'','',
                                                 SALES_ORDER_OBJECT_API_NAME,salesOrder.Id,paramsMap);
    } 
    
    //Update Sales Orders without trigger
    public List<SalesOrder__c> updateSalesOrdersWithoutTrigger(List<SalesOrder__c> salesOrders){
        if(salesOrders != NULL && !salesOrders.isEmpty()){
            SalesOrderTriggerHandler.isTriggerDisabled = true;
            update salesOrders;
            SalesOrderTriggerHandler.isTriggerDisabled = false;
        }
        return salesOrders;
    }  
    
    public void createSalesOrder(SalesOrder__c order){
        if(order != NULL ){
            insert order;
        }
    }
    
    // BAPP Get Sales Order Counts
    public static Map<Id, Integer> getSalesOrderCounts(Id accountId, Set<Id> contactIds, Date updatedOnFrom, Date updatedOnTo) {
        Map<Id, Integer> result = new Map<Id, Integer>();
        String dateFilter = '';
        
        if (updatedOnFrom != null && updatedOnTo != null) {
            DateTime fromDT = DateTime.newInstance(updatedOnFrom, Time.newInstance(0, 0, 0, 0));
            DateTime toDT   = DateTime.newInstance(updatedOnTo, Time.newInstance(23, 59, 59, 999));
            dateFilter = ' AND LastModifiedDate >= :fromDT AND LastModifiedDate <= :toDT';
        }
        
        String soql = 
            'SELECT Opportunity__r.BrokerAgentContact__c agentId, COUNT(Id) total ' +
            'FROM SalesOrder__c ' +
            'WHERE Opportunity__r.BrokerAgencyAccount__c = :accountId ' +
            'AND Opportunity__r.BrokerAgentContact__c IN :contactIds' +
            dateFilter +
            ' GROUP BY Opportunity__r.BrokerAgentContact__c';
        
        for (AggregateResult ar : Database.query(soql)) {
            result.put((Id)ar.get('agentId'), (Integer)ar.get('total'));
        }
        return result;
    }
    public static List<SalesOrder__c> runFilteredSalesOrderQuery(String soql) {
        return Database.query(soql);
    }
    /**
* Get SalesOrders with related Opportunity and Broker Agency
*/
    public List<SalesOrder__c> getSalesOrdersWithOpportunityAndAgency(Set<Id> salesOrderIds) {
        if (salesOrderIds == null || salesOrderIds.isEmpty()) {
            return new List<SalesOrder__c>();
        }
        
        return [
            SELECT Id, Opportunity__c, Opportunity__r.BrokerAgencyAccount__c
            FROM SalesOrder__c
            WHERE Id IN :salesOrderIds
        ];
    }
    
    public List<SalesOrder__c> getActiveSalesOrdersByAccountId(Id accountId){
        Set<String> statuses = new Set<String>{SALES_ORDER_STATUS_BOOKED, SALES_ORDER_STATUS_RESERVED, SALES_ORDER_STATUS_SOLD};
            return [SELECT Id, Unit__c, Unit__r.ADMAddressingNumber__c, Unit__r.Name, Status__c,
                    Unit__r.Project__r.Name, Handover_Date__c, Account__r.Name, Unit__r.BuildingSectionName__r.Name,
                    Unit__r.Project__r.Amenities__c, Unit__r.Location__Latitude__s, Unit__r.Location__Longitude__s,
                    Unit__r.SaleableArea__c, NetAmount__c, Sales_Order_Cleared_Amount__c, Unit__r.NumberOfBedrooms__c,
                    Unit__r.NumberOfBathrooms__c,SPA_Collection_Status__c,
                    (SELECT Id,Account__r.Name,RelationshipType__c,SharePercentage__c FROM Joint_OwnersSalesOrder__r),
                    (SELECT Id,Name, ContentDocumentId__c,Content_Version_Id__c, DocumentType__c FROM Documents__r
                     WHERE DocumentType__r.IsAvailableForApp__c = true)
                    FROM SalesOrder__c WHERE Account__c = :accountId AND Status__c IN :statuses];
    }
    
    public List<SalesOrder__c> getMobileAppActiveSalesOrdersByAccountId(Id accountId){
        Set<String> statuses = new Set<String>{SALES_ORDER_STATUS_BOOKED, SALES_ORDER_STATUS_RESERVED, SALES_ORDER_STATUS_SOLD};
            return [SELECT Id, Unit__c, Unit__r.ADMAddressingNumber__c, Unit__r.Name, Status__c,
                    Unit__r.Project__r.Name, Handover_Date__c, Account__r.Name, Unit__r.BuildingSectionName__r.Name,
                    Unit__r.Project__r.Amenities__c, Unit__r.Location__Latitude__s, Unit__r.Location__Longitude__s,
                    Unit__r.SaleableArea__c, NetAmount__c, Sales_Order_Cleared_Amount__c, Unit__r.NumberOfBedrooms__c,
                    Unit__r.NumberOfBathrooms__c,SPA_Collection_Status__c,
                    (SELECT Id,Account__r.Name,RelationshipType__c,SharePercentage__c FROM Joint_OwnersSalesOrder__r),
                    (SELECT Id,Name, ContentDocumentId__c,Content_Version_Id__c, DocumentType__c,DocumentType__r.Type__c FROM Documents__r
                     WHERE DocumentType__r.IsAvailableForApp__c = true AND ContentDocumentId__c != null)
                    FROM SalesOrder__c WHERE Account__c = :accountId AND ((Status__c IN :statuses AND Resale__c = false) OR (Resale__c = true AND Status__c = :SALES_ORDER_STATUS_SOLD))];
    }
    
    public SalesOrder__c getSalesOrderById(Id recordId){   
        return [SELECT Id, Name,Account__c, Company_Code__c, SAP_Contract_No__c,IsDefaulted__c, Unit__r.Project__c,Unit__r.Project__r.City__c,Unit__r.Building__c,
                Status__c, Unit__c,NetAmount__c,Account__r.Legal_Status__c, Unit__r.Name,First_Installment_Received_Amount__c,First_Installment_Amount__c,
                Account__r.Id,Offer__r.Name,Unit__r.Project__r.ResaleEligibleAmoutPercentage__c, Account__r.Name, Account__r.IsPersonAccount, 
                Account__r.PersonMobilePhone, Contact__c, Account__r.PersonContactId FROM SalesOrder__c WHERE Id =:recordId];
    } 
    
    public List<SalesOrder__c> getSalesOrdersByAccountIds(Id accountIds){
        return [SELECT Id,Unit__c,Unit__r.Name,Account__r.Id FROM SalesOrder__c WHERE
                Account__r.Id =:accountIds];  
    }
    
    public List<SalesOrder__c> getSalesOrdersByAccountIdsForSegment(Set<Id> accountIds,Set<String> invalidStatus){
        return [SELECT Account__c,Status__c,NetAmount__c,Account__r.Segment__c FROM SalesOrder__c WHERE Account__c IN :accountIds AND Status__c NOT IN :invalidStatus];  
    }
    
    public Integer getActiveSalesOrdersByPaymentPlanIds(Id paymentPlanId,List<String> invalidStatus){
        return [SELECT COUNT() FROM SalesOrder__c WHERE PaymentPlan__c = :paymentPlanId AND Status__c NOT IN :invalidStatus];  
    }
    
    public List<String> getJointOwnerEmails(Id salesOrderId){
        
        List<String> emailList = new List<String>();
        
        List<JointOwner__c> jointOwnerList = [SELECT Id, Email__c FROM JointOwner__c WHERE SalesOrder__c = :salesOrderId AND Email__c != null];
        
        for(JointOwner__c jo : jointOwnerList){
            emailList.add(jo.Email__c);
        }
        
        return emailList;
    }
}