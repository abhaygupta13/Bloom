/***
    Class       : LeasingPaymentScheduleService
    Author      : 
    Description : 
    TestClass   : 
    ----------------------------------------------------------------------------------------------------------------
    -- History --
    ----------------------------------------------------------------------------------------------------------------
    Sr.No.  version              Date                Details
    ****************************************************************************************************************/
    public inherited sharing class LeasingPaymentScheduleService {
        private static LeasingPaymentScheduleService instance;
        
        private static final string INTEGRATION_TYPE_INSTALLEMENTLINE_SAP_INTEGRATION { get { return 'LEASING_INSTALLEMENT_LINE_SAP_INTEGRATION'; } }
        private static final string INTEGRATION_ACTION_INSERT { get { return 'Insert'; } }
        private static final string PAYMENT_PLAN_OBJECT_API_NAME { get { return 'PaymentPlanSchedule__c '; } }
        
        private LeasingPaymentScheduleService() { 
            
        }
        
        public static LeasingPaymentScheduleService getInstance() { 
            if(instance == null) {
                instance = new LeasingPaymentScheduleService();
            }
            return instance;
        }
        
        public List<PaymentPlanSchedule__c> getPaymentSchedulesByLeasingOrderId(Id leasingOrderId ){
            return [SELECT Id,Year__c,Amount__c,Name,RefDocno__c, IsReversed__c, Paymentdoc__c,  TotalInstallmentAmount__c, DueAmount__c,DueDate__c, clearedAmount__c FROM PaymentPlanSchedule__c
                    WHERE LeasingOrder__c = :leasingOrderId ORDER BY Year__c];
        }
        
        public List<PaymentPlanSchedule__c> insertPaymentSchedules(List<PaymentPlanSchedule__c> paymentScheduleList){
            if(paymentScheduleList != NULL && !paymentScheduleList.isEmpty()){
                insert paymentScheduleList;
            }
            return paymentScheduleList; 
        } 
        
        public void deletePaymentSchedules(List<PaymentPlanSchedule__c> paymentScheduleList){
            if(paymentScheduleList != NULL && !paymentScheduleList.isEmpty()){
                delete paymentScheduleList;
            }
        }
        
        public List<PaymentPlanSchedule__c> getPaymentSchedulesByLeasingOrders(Set<Id> leasingOrderIds ){
            return [
                SELECT Id, LeasingOrder__c , DueDate__c
                FROM PaymentPlanSchedule__c 
                WHERE LeasingOrder__c IN :leasingOrderIds ORDER by DueDate__c ASC
            ];
        }
        
        public List<PaymentPlanSchedule__c> updatePaymentPlanSchedules(List<PaymentPlanSchedule__c> ppsList){
            if(ppsList != NULL && !ppsList.isEmpty()){
                update ppsList;
            }
            return ppsList; 
        }
        public PaymentPlanSchedule__c updatePaymentPlanSchedule(PaymentPlanSchedule__c schedule){
            if(schedule != NULL){
                update schedule;
            }
            return schedule; 
        }
        
        public List<PaymentPlanSchedule__c> getpaymentPlanByIds(Set<Id> paymentPlanIds) {
            
            return [ SELECT Id,Name,Schedule_End_Date__c, LeasingOrder__r.Project__r.Leasing_Company__r.LeasingSAPCompanyCode__c ,LeasingOrder__r.Opportunity__r.Account.IsPersonAccount,
                    LeasingOrder__r.LeasingSAPContractId__c, LeasingOrder__r.Project__r.Leasing_Company__r.LeasingSAPContractTypeCode__c,IsPosting__c ,
                    PaymentStartDate__c, isVATApplied__c, DueDate__c, Amount__c , IsReversed__c, ReversedDate__c,PostingDate__c ,RelatedPartyBloomHolding__c,LeasingContractTypeCode__c,
                    ReversedReason__c, ReversedRemarks__c, ReversalCategory__c, Refdocno__c, Paymentdoc__c, LeasingOrder__r.Id,
                    LeasingOrder__r.Unit__r.PropertyUsage__c, LeasingOrder__r.Project__r.Leasing_Company__r.LeasingSAPCommercialContractTypeCode__c,
                    LeasingOrder__r.Project__r.Leasing_Company__r.LeasingSAPResContractTypeCode__c, LeasingOrder__r.Project__r.Leasing_Company__r.LeasingSAPRentfreeConditionType__c
                    FROM PaymentPlanSchedule__c WHERE Id IN :paymentPlanIds];
        }
        
        public Map<Id, LeasingOrder__c> getLeasingOrdersWithPropertyUsage(Set<Id> leasingOrderIds) {
            
            if (leasingOrderIds == null || leasingOrderIds.isEmpty()) {
                return new Map<Id, LeasingOrder__c>();
            }
            
            return new Map<Id, LeasingOrder__c>(
                [
                    SELECT Id,
                    Unit__r.PropertyUsage__c
                    FROM LeasingOrder__c
                    WHERE Id IN :leasingOrderIds
                ]
            );
        }
        
        public List<PaymentPlanSchedule__c> getunPaidPaymentPlansByLeasingOrderIds(Set<Id> leasingOrderIds) {
            return [
                SELECT Id, LeasingOrder__c, DueDate__c, Amount__c,clearedAmount__c,DueAmount__c
                FROM PaymentPlanSchedule__c
                WHERE LeasingOrder__c IN :leasingOrderIds AND RefDocno__c != null
                AND DueDate__c <= today AND PaymentStatus__c != 'Paid' ORDER BY DueDate__c ASC
            ]; 
        }
        
        
        
        public  IntegrationRecord__c getLeasingPaymentScheRecords(PaymentPlanSchedule__c  leasingPaymentPlan){
            IntegrationRecordService objIntegrationRecordService = IntegrationRecordService.getInstance();
            Map<String,String> paramMap = new Map<String,String>();
            paramMap.put('Param1',leasingPaymentPlan.LeasingOrder__r.Project__r.Leasing_Company__r.LeasingSAPCompanyCode__c);
            paramMap.put('Param2',  leasingPaymentPlan.LeasingOrder__r.LeasingSAPContractId__c);
            /* String contractTypeCode;
    
    if (leasingPaymentPlan.LeasingOrder__r.Unit__r.PropertyUsage__c == 'Commercial') {
    contractTypeCode = 'R024';
    //contractTypeCode = leasingPaymentPlan.LeasingOrder__r.Project__r.LeasingCompany__r.SAPCommercialContractTypeCode__c;
    } else if (leasingPaymentPlan.LeasingOrder__r.Unit__r.PropertyUsage__c == 'Residential') {
    contractTypeCode = leasingPaymentPlan.LeasingOrder__r.Project__r.Leasing_Company__r.LeasingSAPResContractTypeCode__c;
    }else if (leasingPaymentPlan.LeasingOrder__r.Unit__r.PropertyUsage__c == 'Retail') {
    contractTypeCode = 'R028';
    }
    if(leasingPaymentPlan.Name == 'Discounted Installment'){
    contractTypeCode = leasingPaymentPlan.LeasingOrder__r.Project__r.Leasing_Company__r.LeasingSAPRentfreeConditionType__c; 
    }
    // Now put this in paramsMap
    paramMap.put('Param3', contractTypeCode);*/
            
            paramMap.put('Param3', leasingPaymentPlan.LeasingContractTypeCode__c);
            //paramMap.put('Param3',  leasingPaymentPlan.LeasingOrder__r.Project__r.LeasingCompany__r.SAPContractTypeCode__c);
            paramMap.put('Param4',  String.valueOf(leasingPaymentPlan.PaymentStartDate__c));
            //paramMap.put('Param5',  String.valueOf(leasingPaymentPlan.isVATApplied__c));
            if (leasingPaymentPlan.isVATApplied__c) {
                paramMap.put('Param5', 'X');
            } else {
                paramMap.put('Param5', '');
            }
            if ((!leasingPaymentPlan.IsReversed__c && leasingPaymentPlan.DueDate__c <= System.Today() &&  leasingPaymentPlan.LeasingContractTypeCode__c != 'R999') || (leasingPaymentPlan.IsPosting__c )) {
                paramMap.put('Param6', 'X');
            } else {
                paramMap.put('Param6', '');
                //paramMap.put('Param15',  '');
            }
            paramMap.put('Param7',  String.valueOf(leasingPaymentPlan.Amount__c ));
            paramMap.put('Param8',  '0');
            if (leasingPaymentPlan.IsReversed__c ){
                paramMap.put('Param9', 'X');
                paramMap.put('Param13',  '');
                
            } else {
                paramMap.put('Param9', '');
                paramMap.put('Param13',  String.valueOf(leasingPaymentPlan.ReversalCategory__c ));
            }
            //paramMap.put('Param9',  String.valueOf(leasingPaymentPlan.IsReversed__c ));
            paramMap.put('Param10',  String.valueOf(leasingPaymentPlan.ReversedDate__c ));
            paramMap.put('Param11',  String.valueOf(leasingPaymentPlan.ReversedReason__c));
            paramMap.put('Param12',  String.valueOf(leasingPaymentPlan.ReversedRemarks__c));
            paramMap.put('Param14',  String.valueOf(leasingPaymentPlan.Refdocno__c ));
            paramMap.put('Param15',  String.valueOf(leasingPaymentPlan.Paymentdoc__c ));
            paramMap.put('Param16',  String.valueOf(leasingPaymentPlan.Schedule_End_Date__c));
            paramMap.put('Param17',  String.valueOf(leasingPaymentPlan.DueDate__c));
            paramMap.put('Param18',UserInfo.getUserEmail());
            if (leasingPaymentPlan.RelatedPartyBloomHolding__c) {
                paramMap.put('Param19', 'Y');
            } else {
                paramMap.put('Param19', 'N');
            }
            
            return objIntegrationRecordService.getIntegrationRecord(INTEGRATION_TYPE_INSTALLEMENTLINE_SAP_INTEGRATION, INTEGRATION_ACTION_INSERT,'','', PAYMENT_PLAN_OBJECT_API_NAME, String.valueOf(leasingPaymentPlan.id),paramMap);
        }
    
        public PaymentPlanSchedule__c getpaymentPlanById(Id paymentPlanId) {       
            return [SELECT Name, Amount__c, DueDate__c, RefDocno__c, PaymentStartDate__c, Schedule_End_Date__c, 
           CreditAmount__c, isVATApplied__c, Note__c,
           LeasingOrder__r.SAPBPNumber__c, LeasingOrder__r.PropertyName__c,
           LeasingOrder__r.Account__r.Name, LeasingOrder__r.Account__r.TaxRegistrationNumber__c, LeasingOrder__r.Account__r.UAEVATRegisterNumber__c,
           LeasingOrder__r.Unit__r.Name, LeasingOrder__r.Unit__r.LeasingUnitNumber__c,
           LeasingOrder__r.Project__r.Leasing_Company__r.Name, LeasingOrder__r.Project__r.Leasing_Company__r.LeasingCompanyVATRegistrationNumber__c, LeasingOrder__r.Project__r.Leasing_Company__r.LeasingVAT__c,
           LeasingOrder__r.Project__r.LeasingBankAccount__r.BeneficiaryNameCorporate__c, LeasingOrder__r.Project__r.LeasingBankAccount__r.BankNameCorporate__c, 
           LeasingOrder__r.Project__r.LeasingBankAccount__r.AccountNumberCorporate__c, LeasingOrder__r.Project__r.LeasingBankAccount__r.IBANNoCorporate__c, 
           LeasingOrder__r.Project__r.LeasingBankAccount__r.SwiftCodeCorporate__c
           FROM PaymentPlanSchedule__c WHERE Id = :paymentPlanId];
        }
    }