/***
Class       : LeasingOrderService
Author      : 
Description : 
TestClass   : 
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
****************************************************************************************************************/
public inherited sharing class LeasingOrderService {
    private static LeasingOrderService instance;
    private static final string INTEGRATION_ACTION_UPDATE { get { return 'U'; } }
    private static final string INTEGRATION_ACTION_INSERT { get { return 'C'; } }
    private static final string LEASINGORDER_OBJECT_API_NAME { get { return 'LeasingOrder__c '; } }
    private static final string INTEGRATION_TYPE_LEASINGORDER_SAP_INTEGRATION { get { return 'LEASINGORDER_SAP_INTEGRATION'; } }
    
    private LeasingOrderService() {
        
    }
    
    public static LeasingOrderService getInstance() { 
        if(instance == null) {
            instance = new LeasingOrderService();
        }
        return instance;
    }
    
    public LeasingOrder__c getLeasingOrderById(Id recordId){
        return [
            SELECT Id, AnnualRent__c, RentalAmountAfterDiscount__c, DiscountPercentage__c, ApprovalStatus__c,Opportunity__c,Owner.name,
            GracePeriodFormula__c,Unit__r.BuildingSectionName__r.Project__c,Unit__r.BuildingSectionName__c,Unit__c,PropertyUsage__c,Category__c,
            Building__r.BuildingNumber__c, LeasingOffer__c,AppliedAnnualRent__c,DiscountType__c,Name,LeasingOrderNumber__c,SubCategory__c,
            CreditBalance__c,MasterLeasingOrder__r.CreditBalance__c,MasterLeasingOrder__c,Dubaireraindexattached__c,Waiveof2monthspenaltyattached__c,Refundformattached__c,
            SecurityDeposit__c, EjariTawtheeqFee__c, AdminFee__c, ServiceChargeFee__c, AdditionalSecurityDeposite__c,FitOutdays__c,
            ExtraChequeFee__c, FitOutSecurityDeposit__c,Account__r.Name,Account__r.IsPersonAccount,Account__r.Nationality__pc,
            Account__r.PassportNumber__pc,Account__r.Emirates_Id__pc,Account__r.MaritalStatus__pc,Account__r.ResidentStatus__pc,
            Account__r.EmploymentStatus__pc,Account__r.NumberOfEmployees,Account__r.Position__pc,Account__r.CompanyAddress__pc,PermittedUse__c,
            Unit__r.Project__r.Leasing_Company__r.LeasingVAT__c,Unit__r.PropertyUsage__c,RERANumber__c,RenewalFee__c,UnitHandOverDate__c,
            GracePeriod__c,LeasingContractMonths__c,ContractPeriodEN__c,ContractPeriodAR__c,PaymentTerm__c,DiscountAmount__c,RelatedPartyBloomHolding__c,
            LeasingStartDate__c, Project__r.LeasingBankAccount__r.BeneficiaryNameCorporate__c, Project__r.LeasingBankAccount__r.BankNameCorporate__c, 
            Project__r.LeasingBankAccount__r.AccountNumberCorporate__c, Project__r.LeasingBankAccount__r.IBANNoCorporate__c, 
            Project__r.LeasingBankAccount__r.SwiftCodeCorporate__c, Project__r.Leasing_Company__r.LeasingPostingClosureDate__c,
            (Select AfterDiscount__c,Year__c, id from Leasing_Escalation_Splits__r),
            Account__r.PersonEmail,Account__r.CompanyName__c, Account__c, OwnerId,
            OfferValidityDays__c,Unit__r.Name,Unit__r.NumberOfCarParks__c,PropertyName__c,ContractTerm__c, TermofPayment__c ,
            LeasingEndDate__c,Remarks__c,Owner.Email,Owner.Phone,BloomTeamApprovalStatus__c ,CustomerApprovalStatus__c,
            Unit__r.Project__r.LeasingMunicipalityArea__c,HandoverCondition__c,CurrentCondition__c, Unit__r.Project__r.City__c,
            Unit__r.LeasingUnitSizesqm__c,AnnualRentVATAmount__c,TotalRentAfterDiscount__c,LeasingSAPContractId__c,
            TotalAnnualRentwithVAT__c,Unit__r.Project__r.SecurityDeposit__c,CurrencyIsoCode,Project__r.Name,
            Unit__r.Project__r.Leasing_Company__r.Name,Account__r.PersonMobilePhone,Project__c,Building__c,Unit__r.LeasingUnitNumber__c,
            Unit__r.UnitNumber__c,Unit__r.UnitModel__c,Unit__r.UnitType__c,Account__r.PersonMailingPostalCode,
            Account__r.PersonMailingCity,Account__r.PersonMailingCountry,Account__r.PersonMailingState,
            Account__r.PersonMailingStreet,Account__r.PersonMailingAddress,Unit__r.BuildingSectionName__r.Name,
            Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.BankNameCorporate__c,
            Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.BeneficiaryNameCorporate__c,
            Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.BranchCorporate__c,
            Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.AccountNumberCorporate__c,
            Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.SwiftCodeCorporate__c,
            Unit__r.BuildingSectionName__r.Primary_Account_Installment__r.IBANNoCorporate__c, Opportunity__r.Account.Name,Project__r.Leasing_Company__r.LeasingSAPCompanyCode__c, Unit__r.SAP_Business_Entity_No__c, 
            (SELECT Id,Name, DueDate__c, ClearedAmount__c, DueAmount__c, TotalInstallmentAmount__c,RefDocno__c
             FROM Payment_Plan_Schedules__r 
             ORDER BY ID ASC),
            (SELECT Id, Duedate__c, ClearedAmount__c, DueAmount__c, Type__c,Name, TotalAmount__c,RefDocno__c
             FROM Leasing_Orders_Other_Charges__r
             ORDER BY ID ASC),
            (SELECT Id, Name,UnappliedAmount__c, Amount__c, ChequeDate__c,SAPDocumentNumber__c  
             FROM LeasingReceiptAcknowledgment_s__r
             ORDER BY ID ASC),SAPBPNumber__c,CustomerName__c,
            LeaseType__c,Project__r.Leasing_Company__r.Name ,Project__r.Leasing_Company__r.LeasingBankAccountName__c,Project__r.Leasing_Company__r.LeasingBankAccountNumber__c,
            Project__r.Leasing_Company__r.LeasingBankName__c,Project__r.Leasing_Company__r.LeasingIBAN__c,Project__r.Leasing_Company__r.LeasingSWIFTCode__c FROM LeasingOrder__c WHERE Id = :recordId
        ];
    }
    
    public List<LeasingOrder__c> getActiveLeasingContractByOppId(Id opportunityId){
        return  [SELECT Id, Name FROM LeasingOrder__c
                 WHERE Opportunity__c = :opportunityId AND Status__c != 'Cancelled'
                 ORDER BY Createddate desc LIMIT 1]; 
    }
    
    
    public List<LeasingOrder__c> getLeasingOrdersByIds(Set<Id> leasingOrderIds) {
        return [ SELECT Id, Opportunity__r.Account.IsPersonAccount ,Account__c,
                Opportunity__r.Account.Name, Unit__r.PropertyUsage__c, Account__r.RecordType.DeveloperName,LeasingStartDate__c,GracePeriodFormula__c,
                LeasingEndDate__c, PropertyName__c, Project__r.Leasing_Company__r.LeasingSAPCompanyCode__c ,Project__r.SAPBusinessEntity__c,CreditBalance__c,
                MasterLeasingOrder__r.CreditBalance__c,MasterLeasingOrder__c,RERANumber__c,RenewalFee__c,Project__r.Leasing_Company__r.LeasingSAPRetailContractTypeCode__c,
                Project__r.Leasing_Company__r.LeasingSAPContractTypeCode__c, Unit__r.LeasingUnitNumber__c,Unit__r.SAP_Unit_Number__c, EjariTawtheeqFee__c, Name,TerminationNoticeDate__c,
                LeasingOrderNumber__c, Project__r.Leasing_Company__r.LeasingTenancyLaw__c, Account__r.SAP_BP_No__c,RejectionReason__c ,IntegrationStatus__c,
                SecurityDeposit__c, OwnerSAPBPNumber__c, TotalAnnualRentwithVAT__c, Project__r.Leasing_Company__r.LeasingVAT__c,CreatedDate,
                AppliedAnnualRent__c, LeasingContractMonths__c, LeasingSAPContractId__c,AdminFee__c, PaymentTerm__c , LeaseType__c ,
                AdditionalSecurityDeposite__c, Owner.Email, Project__r.Leasing_Company__r.LeasingSAPCommercialContractTypeCode__c,AnnualRent__c,
                Project__r.Leasing_Company__r.LeasingSAPResContractTypeCode__c, isVATApplied__c ,LeaseTerminationRefundType__c ,TerminationDate__c,
                TerminationType__c, IntegrationMessage__c, SAPAnnualRenewal__c, SAPConditionFrequency__c, Project__r.Leasing_Company__r.LeasingPostingClosureDate__c 
                FROM LeasingOrder__c WHERE Id IN :leasingOrderIds];
    }
    
    public List<LeasingOrder__c> insertLeasingOrdersWithoutTrigger(List<LeasingOrder__c> leasingOrders){
        if(leasingOrders != NULL && !leasingOrders.isEmpty()){
            LeasingOrderTriggerHandler.isTriggerDisabled = true;
            insert leasingOrders;
            LeasingOrderTriggerHandler.isTriggerDisabled = false;
        }
        return leasingOrders;
    }
    
    public List<LeasingOrder__c> insertLeasingOrders(List<LeasingOrder__c> leasingOrders){
        if(leasingOrders != NULL && !leasingOrders.isEmpty()){
            insert leasingOrders;
        }
        return leasingOrders;
    }
    
    public LeasingOrder__c updateLeasingOrder(LeasingOrder__c objLeasingOrder){
        if(objLeasingOrder != NULL ){
            objLeasingOrder = updateLeasingOrders(new List<LeasingOrder__c>{objLeasingOrder})[0];
        }
        return objLeasingOrder;
    }
    
    public List<LeasingOrder__c> updateLeasingOrders(List<LeasingOrder__c> leasingOrders){
        if(leasingOrders != NULL && !leasingOrders.isEmpty()){
            update leasingOrders;
        }
        return leasingOrders; 
    }
    public List<LeasingOrder__c> updateLeasingOrderswithOutTrigger(List<LeasingOrder__c> leasingOrders){
        if(leasingOrders != NULL && !leasingOrders.isEmpty()){
            LeasingOrderTriggerHandler.isTriggerDisabled = true ;
            update leasingOrders;
            LeasingOrderTriggerHandler.isTriggerDisabled = false ;
        }
        return leasingOrders; 
    }
    
    public IntegrationRecord__c getIntegrationRecord(LeasingOrder__c leasingOrder){
        Map<String,String> paramsMap = new Map<String,String>();
        IntegrationRecordService integService = IntegrationRecordService.getInstance();
        paramsMap.put('Param1',leasingOrder.Project__r.Leasing_Company__r.LeasingSAPCompanyCode__c);
        String contractTypeCode;
        
        if (leasingOrder.Unit__r.PropertyUsage__c == 'Commercial') {
            contractTypeCode = leasingOrder.Project__r.Leasing_Company__r.LeasingSAPCommercialContractTypeCode__c;
        } else if (leasingOrder.Unit__r.PropertyUsage__c == 'Residential') {
            contractTypeCode = leasingOrder.Project__r.Leasing_Company__r.LeasingSAPResContractTypeCode__c;
        } else if (leasingOrder.Unit__r.PropertyUsage__c == 'Retail') {
            contractTypeCode = leasingOrder.Project__r.Leasing_Company__r.LeasingSAPRetailContractTypeCode__c ;
        }
        
        // Now put this in paramsMap
        paramsMap.put('Param2', contractTypeCode);
        //paramsMap.put('Param2',leasingOrder.Project__r.Leasing_Company__r.SAPContractTypeCode__c);
        paramsMap.put('Param3',leasingOrder.Unit__r.SAP_Unit_Number__c);
        paramsMap.put('Param4',leasingOrder.Project__r.SAPBusinessEntity__c);
        //paramsMap.put('Param5',String.valueOf(leasingOrder.EjariTawtheeqFee__c));
        paramsMap.put('Param5',String.valueOf(leasingOrder.RERANumber__c));
        paramsMap.put('Param6',String.valueOf(Utility.formatDateToYYYYMMDD(leasingOrder.LeasingStartDate__c)));
        paramsMap.put('Param7',String.valueOf(Utility.formatDateToYYYYMMDD(leasingOrder.LeasingEndDate__c )));
        paramsMap.put('Param8',leasingOrder.Name);
        paramsMap.put('Param9',leasingOrder.LeasingSAPContractId__c); 
        paramsMap.put('Param10',leasingOrder.Project__r.Leasing_Company__r.LeasingTenancyLaw__c);
        paramsMap.put('Param11',leasingOrder.Account__r.SAP_BP_No__c);
        paramsMap.put('Param12',leasingOrder.OwnerSAPBPNumber__c);
        paramsMap.put('Param13',leasingOrder.Account__r.SAP_BP_No__c);
        //paramsMap.put('Param14',leasingOrder.AdditionalSecurityDeposite__c != Null &&  leasingOrder.AdditionalSecurityDeposite__c != 0 ? String.valueOf(leasingOrder.AdditionalSecurityDeposite__c) : String.valueOf(leasingOrder.SecurityDeposit__c));
        /* paramsMap.put(
'Param14',
leasingOrder.LeaseType__c == 'Renewal'
? String.valueOf(leasingOrder.AdditionalSecurityDeposite__c)
: String.valueOf(leasingOrder.SecurityDeposit__c)
); */
        paramsMap.put('Param14', '0'); 
        
        paramsMap.put('Param15',String.valueOf((leasingOrder.SAPAnnualRenewal__c == null || leasingOrder.SAPAnnualRenewal__c == 0) ? leasingOrder.AppliedAnnualRent__c : leasingOrder.SAPAnnualRenewal__c ));
        if (leasingOrder.isVATApplied__c) {
            paramsMap.put('Param16', 'X');
        } else {
            paramsMap.put('Param16', '');
        }
        paramsMap.put('Param17',String.valueOf(leasingOrder.AnnualRent__c)); 
        if (leasingOrder.LeasingContractMonths__c == 12) {
            paramsMap.put('Param18', String.valueOf(1)); 
            paramsMap.put('Param19', String.valueOf(0)); 
            paramsMap.put('Param20', String.valueOf(0));
            paramsMap.put('Param24', String.valueOf(1));
            
        } else if (leasingOrder.SAPAnnualRenewal__c > 0 && leasingOrder.SAPConditionFrequency__c > 0){
            paramsMap.put('Param18', String.valueOf(0));
            
            Integer contractMonths = leasingOrder.LeasingContractMonths__c != null 
                ? Integer.valueOf(leasingOrder.LeasingContractMonths__c) 
                : 0;
            
            Date fixedMonthEndDate = leasingOrder.LeasingStartDate__c.addMonths(Integer.valueOf(contractMonths));
            Integer days = fixedMonthEndDate.daysBetween(leasingOrder.LeasingEndDate__c);
            
            paramsMap.put('Param19', String.valueOf(contractMonths)); 
            paramsMap.put('Param20', String.valueOf(days));
        } 
        else {
            Integer contractMonths = leasingOrder.LeasingContractMonths__c != null 
                ? Integer.valueOf(leasingOrder.LeasingContractMonths__c) 
                : 0;
            
            Integer years  = Integer.valueOf(Math.floor(contractMonths / 12));
            Integer months = Math.mod(contractMonths, 12);
            Integer days   = months * 30; 
            
            paramsMap.put('Param18', String.valueOf(years)); 
            paramsMap.put('Param19', String.valueOf(months)); 
            paramsMap.put('Param20', String.valueOf(days));
        }
        
        paramsMap.put('Param25', '0');
        paramsMap.put('Param21','');
        paramsMap.put('Param22','');
        paramsMap.put('Param23','');
        /*String numberPart = leasingOrder.PaymentTerm__c != null ? leasingOrder.PaymentTerm__c.split(' ')[0] : null;
Integer termCount = numberPart != null ? Integer.valueOf(numberPart) : null;
paramsMap.put('Param25',String.valueOf(termCount));*/
        
        String numberPart = leasingOrder.PaymentTerm__c != null 
            ? leasingOrder.PaymentTerm__c.split(' ')[0] 
            : null;
        
        Integer termCount = 0;
        if (numberPart != null) {
            Integer termNumber = Integer.valueOf(numberPart);
            if (termNumber == 0) {
                termCount = 0;
            } else if (termNumber > 0) {
                termCount = Math.floor(12 / termNumber).intValue();
            }
        }
        paramsMap.put('Param24', String.valueOf((leasingOrder.SAPConditionFrequency__c == null || leasingOrder.SAPConditionFrequency__c == 0) ? termCount : leasingOrder.SAPConditionFrequency__c));
        /* if (leasingOrder.AdminFee__c != null && leasingOrder.AdminFee__c != 0) {
paramsMap.put('Param26', String.valueOf(leasingOrder.AdminFee__c));
} */
        
        paramsMap.put('Param26', '0'); 
        String actionType = String.isBlank(leasingOrder.LeasingSAPContractId__c ) ? INTEGRATION_ACTION_INSERT : INTEGRATION_ACTION_UPDATE;
        String leaseTypeValue = leasingOrder.LeaseType__c;
        
        String renewalSuccessMessage = System.Label.RenewedSuccessfullyMessage?.trim();
        
        if (
            leaseTypeValue == 'Renewal' &&
            leasingOrder.LeasingSAPContractId__c != null &&
            (
                leasingOrder.IntegrationMessage__c == null ||
                !leasingOrder.IntegrationMessage__c.toLowerCase()
                .contains(renewalSuccessMessage.toLowerCase())
            )
        ) {
            paramsMap.put('Param27', 'R');
        } else if (leaseTypeValue == 'Termination') {
            String terminationRefundType = leasingOrder.LeaseTerminationRefundType__c.split('-')[1];//this gives single char
            paramsMap.put('Param27', terminationRefundType);
            paramsMap.put('Param21',String.valueOf(Utility.formatDateToYYYYMMDD(leasingOrder.TerminationDate__c )));
            paramsMap.put('Param23',String.valueOf(Utility.formatDateToYYYYMMDD(leasingOrder.TerminationNoticeDate__c)));
            // Termination reason mapping
            Map<String, String> terminationReasonMap = new Map<String, String>{
                'No reason given' => '00',
                    'Low budget' => '01',
                    'Restricted use' => '02',
                    'Break-Lease' => '11',
                    'Break- Lease' => '11',
                    'Legal case' => '12',
                    'Relocation' => '13',
                    'Leaving Country' => '14',
                    'Unit upgrade' => '15',
                    'Downsizing' => '16',
                    'End of contract' => '17',
                    'Financial reason' => '18',
                    'Maintenance issue' => '21',
                    'Parking issue' => '22',
                    'Lack of Facilities' => '23',
                    'Job lost (termination)' => '24'
                    };
                        
                        String param22Value = terminationReasonMap.containsKey(leasingOrder.TerminationType__c)
                        ? terminationReasonMap.get(leasingOrder.TerminationType__c)
                        : ''; 
            paramsMap.put('Param22', param22Value);
        } else {
            paramsMap.put('Param27', actionType);
        }
        return integService.getIntegrationRecord(INTEGRATION_TYPE_LEASINGORDER_SAP_INTEGRATION, actionType,'','', LEASINGORDER_OBJECT_API_NAME, leasingOrder.Id,paramsMap);
    }
    
    public LeasingOrder__c getLeasingOrderforSyncById(Id recordId){
        return [
            SELECT Id, Account__c, Project__r.Leasing_Company__r.LeasingPostingClosureDate__c
            FROM LeasingOrder__c 
            WHERE Id = :recordId 
            LIMIT 1
        ];
    }
    
    public List<LeasingOrder__c> getLeasingOrdersByOwners(Set<Id> userIds){
        return [SELECT Id, LeasingOrderNumber__c, OwnerId, Owner.Email, Owner.Name,
                Name, Unit__r.UnitNumber__c FROM LeasingOrder__c where OwnerId IN :userIds];
    }
    public Map<Id, Unit__c> getUnitsWithPropertyUsage(Set<Id> unitIds) {
        
        if (unitIds == null || unitIds.isEmpty()) {
            
            return new Map<Id, Unit__c>();
        }
        
        return new Map<Id, Unit__c>(
            [
                SELECT Id, PropertyUsage__c
                FROM Unit__c
                WHERE Id IN :unitIds
            ]
        );
    }
    
    public Map<Id, LeasingOrder__c> getLeasingOrdersWithSAPContractId(Set<Id> leasingOrderIds) {
        if (leasingOrderIds == null || leasingOrderIds.isEmpty()) {
            return new Map<Id, LeasingOrder__c>();
        }
        
        return new Map<Id, LeasingOrder__c>([
            SELECT Id, LeasingSAPContractId__c
            FROM LeasingOrder__c
            WHERE Id IN :leasingOrderIds
        ]);
    }
}