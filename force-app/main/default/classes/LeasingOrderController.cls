/**
* @File Name : LeasingOrderController.cls
* @Description : Controller class to Create Leasing Order Records form Opportunity page
* @Author : Bloom Properties
* @Last Modified By :
* @Last Modified On : 
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | May 5, 2025 |   | Initial Version
**/
public with Sharing class LeasingOrderController {
    private static final string BLOOM_NO_REPLY_LEASING_OW_EMAIL_ID { get { return 'BloomNoReplyLeasingOWEmailId'; } }
    
    private static final string LEASING_OFFER_FOR_CUSROMER_SIGN { get { return 'LeasingOfferSignTemplateId'; } }
    
    
    private static final string OTHERCHARGE_ADMIN_FEE { get { return 'Admin Fee'; } } 
    private static final string OTHERCHARGE_EJARI_FEE { get { return 'Ejari/Tawtheeq Fee'; } }
    private static final string OTHERCHARGE_RENEWAL_FEE { get { return 'Renewal Fees'; } }
    private static final string OTHERCHARGE_SECURITY_DEPOSIT { get { return 'Security Deposit Amount'; } } 
    private static final string OTHERCHARGE_ADDITIONAL_SECURITY_DEPOSIT { get { return 'Additional Security Deposit Amount'; } } //Pranav
    private static final string OTHERCHARGE_EXTRA_CHEQUE_FEE { get { return 'Extra Cheque Fee'; } } 
    private static final string OTHERCHARGE_FITOUT_SECURITY_DEPOSIT_FEE { get { return 'Fit Out Security Deposit'; } } 
    private static final string OTHERCHARGE_SERVICE_CHARGE_FEE { get { return 'Service Charge Fee'; } } 
    private static final string COMMERCIAL_TYPE { get { return 'Commercial'; } } 
    private static final string RETAIL_TYPE { get { return 'Retail'; } } 
    private static final string RESIDENTIAL_TYPE { get { return 'Residential'; } } 
    private static final string YEAR { get { return 'Year'; } } 
    private static final string PAYMENT { get { return 'Payment'; } } 
    private static final string MOVE_OUT_REQUEST_FORM { get { return 'Move Out Request Form'; } }
    private static final string LEASING_ORDER_API_NAME { get { return 'LeasingOrder__c'; } } 
    private static final string PDC_DOC_NAME { get { return 'PDCs'; } }
    private static final string EJARI_DOC_NAME { get { return 'Tawtheeq /Ejari Document'; } } 
    
    //helper method to create escalation schedules once the Leasing Contract is created
    @AuraEnabled
    public static void insertEscalationSchedules(Id contractId,List<LeasingEscalationSchedule__c> splits) {
        LeasingOtherChargesService leasingOrderOtherChargesService = LeasingOtherChargesService.getInstance();
        LeasingEscalationScheduleService leasingescalationScheduleService = LeasingEscalationScheduleService.getInstance();
        for (LeasingEscalationSchedule__c s : splits) {
            s.LeasingOrder__c = contractId;
        }
        List<LeasingEscalationSchedule__c> escaLationSchedulesList = leasingescalationScheduleService.insertLeasingEscalationSchedule(splits) ;
        List<LeasingOrdersOtherCharges__c> delPreviousOtherCharges = leasingOrderOtherChargesService.getOtherChargesByLeasingOrderId(contractId);
        leasingOrderOtherChargesService.deleteOtherCharges(delPreviousOtherCharges);
        generatePaymentSchdulesCharges(contractId); //generate Payment schedules for Multiyear contracts based on Escaltion schedule
    }
    
    //helper method to get configured Offer lines for Discount calculations in Leasing Order creation
    @AuraEnabled(cacheable=true)
    public static Decimal getOfferLineDiscountSum(Id leasingOfferId) {
        if (leasingOfferId == null) {
            return 0;
        } 
        LeasingOfferService leasingOfferService = LeasingOfferService.getInstance();
        
        LeasingOffer__c chosenOffer = leasingOfferService.getLeasingDiscountOffers(leasingOfferId);
        
        LeasingOfferLineService leasingOfferLineService = LeasingOfferLineService.getInstance();
        
        
        Decimal totalLinePct = 0;
        Id promoId = chosenOffer.LeasingOfferPromotion__c;
        
        if (promoId != null) {
            for (LeasingOfferLines__c lineRec : leasingOfferLineService.getLeasingAdditionalDiscountOfferLines(promoId)) 
            {
                if (lineRec.OfferValue__c != null) {
                    totalLinePct += lineRec.OfferValue__c;
                }
            }
        }
        
        return totalLinePct; 
    }
    @AuraEnabled
    public static String createRenewalLeasingOrder(String contractId,String inputData){
        LeasingOrderWrapper data = (LeasingOrderWrapper)Json.deserialize(inputData,LeasingOrderWrapper.Class);
        LeasingOrder__c oldContract =
            LeasingOrderService.getInstance().getLeasingOrderById(contractId);
        LeasingOrder__c contract = prepareLeasingOrder(data) ;
        if (oldContract.LeasingSAPContractId__c != null) {
            contract.LegacyContratNumber__c = oldContract.LeasingSAPContractId__c;
            contract.LeasingSAPContractId__c = oldContract.LeasingSAPContractId__c;
        }
        contract.LeaseType__c = 'Renewal';
        contract.MasterLeasingOrder__c = contractId;
        contract.RenewalFee__c = contract.AdminFee__c;
        contract.AdminFee__c = 0;
        contract.CreditBalance__c = oldContract.MasterLeasingOrder__r.CreditBalance__c != Null || oldContract.MasterLeasingOrder__r.CreditBalance__c != 0 ? oldContract.MasterLeasingOrder__r.CreditBalance__c : 0;
        
        // Insert using service
        LeasingOrderService leasingOrderService = LeasingOrderService.getInstance();
        leasingOrderService.insertLeasingOrders(new List<LeasingOrder__c>{contract});
        
        // Clone attachments
        LeasingOfferHandler.cloneDocumentsWithFiles(contract.Opportunity__c, contract.Id);
        
        // Generate payment schedule if less than or equal to 12 months
        if (contract.LeasingContractMonths__c <= 12) {
            generatePaymentSchedule(contract);
        }
        return contract.Id;
    }
    //helper method to insert Leasing Order by collecting information from SearchProperties LWC
    @AuraEnabled
    //public static String createLeasingOrder(LeasingOrderWrapper data) {
    public static String createLeasingOrder(String inputData) {
        try {
            LeasingOrderWrapper data = (LeasingOrderWrapper)json.deserialize(inputData, LeasingOrderWrapper.Class);
            LeasingOrder__c contract = prepareLeasingOrder(data) ;
            // Insert using service
            LeasingOrderService leasingOrderService = LeasingOrderService.getInstance();
            leasingOrderService.insertLeasingOrders(new List<LeasingOrder__c>{contract});
            
            // Clone attachments
            LeasingOfferHandler.cloneDocumentsWithFiles(contract.Opportunity__c, contract.Id);
            
            // Generate payment schedule if less than or equal to 12 months
            if (contract.LeasingContractMonths__c <= 18 ) {
                generatePaymentSchedule(contract);
            }
            return contract.Id;
        }
        catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    //helper method to get configured Leasing Offers
    @AuraEnabled(cacheable=true)
    public static List<LeasingOffer__c> getLeasingoffers() {
        LeasingOfferService leasingOfferService = LeasingOfferService.getInstance();
        return leasingOfferService.getAllLeasingDiscountOffers();
    }
    
    @AuraEnabled(cacheable=true)
    public static LeasingOrder__c getLeasingDetails(Id recordId)
    { 
        LeasingOrderService leasingService = LeasingOrderService.getInstance();
        return leasingService.getLeasingOrderById(recordId);
    }
    @AuraEnabled
    public static Id generatePDF(Id contractId) {
        try {
            LeasingOrderService leasingOrderService =
                LeasingOrderService.getInstance();
            
            LeasingOrder__c leasingOrder =
                leasingOrderService.getLeasingOrderById(contractId);
            
            if (leasingOrder.PropertyUsage__c == 'Retail' &&
                leasingOrder.LeaseType__c == 'Renewal') {
                    RenewalOfferController.generateRenewalOffer(contractId);
                    return contractId;
                }
            
            
            if (leasingOrder.PropertyUsage__c == 'Retail' &&
                leasingOrder.LeaseType__c == 'New') {
                    
                    NewOfferPDFController.generatePDF(contractId);
                    
                    return contractId;
                }
            
            Set<Id> idSet = new Set<Id>{ contractId };
                LeasingOfferHandler.generateApprovedLeasingOffer(idSet);
            return contractId;
            
        } catch (Exception ex) {
            
            System.debug(
                'generatePDF Exception :- ' +
                ex.getMessage() +
                ' at line ' +
                ex.getLineNumber()
            );
            
            throw new AuraHandledException(
                'PDF Generation Failed: ' + ex.getMessage()
            );
        }
    }
    public static void generatePaymentSchdulesCharges(Id leasingContractId) { 
        LeasingOrderService leasingService = LeasingOrderService.getInstance();
        LeasingOrder__c leasingContract = leasingService.getLeasingOrderById(leasingContractId);
        List<LeasingEscalationSchedule__c> escalations = leasingContract.Leasing_Escalation_Splits__r ;
        //createPaymentSchedules(escalations,leasingContract);
        createPaymentSchedules(escalations,leasingContract);
        createOtherCharges(leasingContract.Id);
    }
    //Helper method to create other charge records 
    public static void createOtherCharges(Id leasingContractId) {
        LeasingOtherChargesService ocService = LeasingOtherChargesService.getInstance();
        Map<String, String> TYPE_TO_CONDITIONTYPE_MAP = ocService.getTypeToConditionTypeMap();
        Map<String, String> TYPE_TO_SUBCATEGORY_MAP = ocService.getTypeToSubCategoryMap();
        
        LeasingOrderService leasingService = LeasingOrderService.getInstance();
        
        LeasingOrder__c contract = leasingService.getLeasingOrderById(leasingContractId);
        
        List<LeasingOrdersOtherCharges__c> chargesToInsert = new List<LeasingOrdersOtherCharges__c>();
        
        Decimal vatPercentage = contract.Unit__r?.Project__r?.Leasing_Company__r?.LeasingVAT__c ?? null ;
        
        //Security Deposit
        if (contract.SecurityDeposit__c != null && contract.SecurityDeposit__c != 0 && contract.LeaseType__c != 'Renewal') {
            chargesToInsert.add(new LeasingOrdersOtherCharges__c(
                LeasingOrder__c = contract.Id,
                Type__c = OTHERCHARGE_SECURITY_DEPOSIT,
                ChargeAmount__c = contract.SecurityDeposit__c,
                ConditionType__c = TYPE_TO_CONDITIONTYPE_MAP.get(OTHERCHARGE_SECURITY_DEPOSIT),
                SubCategory__c = TYPE_TO_SUBCATEGORY_MAP.get(OTHERCHARGE_SECURITY_DEPOSIT),
                RelatedPartyBloomHolding__c = contract.RelatedPartyBloomHolding__c,
                VATAmount__c = 0.0 ));
        }
        
        //Additional Security Deposit
        if (contract.AdditionalSecurityDeposite__c != null && contract.AdditionalSecurityDeposite__c != 0) {
            chargesToInsert.add(new LeasingOrdersOtherCharges__c(
                LeasingOrder__c = contract.Id,
                Type__c = OTHERCHARGE_ADDITIONAL_SECURITY_DEPOSIT,
                ChargeAmount__c = contract.AdditionalSecurityDeposite__c,
                ConditionType__c = TYPE_TO_CONDITIONTYPE_MAP.get(OTHERCHARGE_ADDITIONAL_SECURITY_DEPOSIT),
                SubCategory__c = TYPE_TO_SUBCATEGORY_MAP.get(OTHERCHARGE_ADDITIONAL_SECURITY_DEPOSIT),
                RelatedPartyBloomHolding__c = contract.RelatedPartyBloomHolding__c,
                VATAmount__c = 0.0 ));
        }
        //Extra cheque fee - No changes for Residential and Commercial
        if (contract.ExtraChequeFee__c != null && contract.ExtraChequeFee__c != 0) {
            Decimal extraCheckFeeVatAmount = 0.0 ;
            extraCheckFeeVatAmount = vatPercentage != null ? ( (contract.ExtraChequeFee__c*vatPercentage)/100 ) : 0.0 ;
            
            chargesToInsert.add(new LeasingOrdersOtherCharges__c(
                LeasingOrder__c = contract.Id,
                Type__c = OTHERCHARGE_EXTRA_CHEQUE_FEE,
                ChargeAmount__c = contract.ExtraChequeFee__c,
                ConditionType__c = TYPE_TO_CONDITIONTYPE_MAP.get(OTHERCHARGE_EXTRA_CHEQUE_FEE),
                SubCategory__c = TYPE_TO_SUBCATEGORY_MAP.get(OTHERCHARGE_EXTRA_CHEQUE_FEE),
                RelatedPartyBloomHolding__c = contract.RelatedPartyBloomHolding__c,
                VATAmount__c = contract.RelatedPartyBloomHolding__c ? 0.0 : extraCheckFeeVatAmount,
                isVATApplied__c = contract.RelatedPartyBloomHolding__c ? false : true
            ));
        }
        //Admin Fee - No changes for Residential and Commercial
        if (contract.AdminFee__c != null && contract.AdminFee__c != 0) {
            Decimal adminFeeVatAmount ;
            adminFeeVatAmount = vatPercentage != null ? ( (contract.AdminFee__c*vatPercentage)/100 ) : 0.0 ;
            
            chargesToInsert.add(new LeasingOrdersOtherCharges__c(
                LeasingOrder__c = contract.Id,
                Type__c = OTHERCHARGE_ADMIN_FEE,
                ChargeAmount__c = contract.AdminFee__c,
                ConditionType__c = TYPE_TO_CONDITIONTYPE_MAP.get(OTHERCHARGE_ADMIN_FEE),
                SubCategory__c = TYPE_TO_SUBCATEGORY_MAP.get(OTHERCHARGE_ADMIN_FEE),
                RelatedPartyBloomHolding__c = contract.RelatedPartyBloomHolding__c,
                VATAmount__c = contract.RelatedPartyBloomHolding__c ? 0.0 : adminFeeVatAmount //propetyUsage == 'Commercial' && vatPercentage != null ? ( (contract.AdminFee__c*vatPercentage)/100 ) : null
            ));
        }
        //Fit Out Security Deposit Fee
        if (contract.FitOutSecurityDeposit__c != null && contract.FitOutSecurityDeposit__c != 0) {
            
            chargesToInsert.add(new LeasingOrdersOtherCharges__c(
                LeasingOrder__c = contract.Id,
                Type__c = OTHERCHARGE_FITOUT_SECURITY_DEPOSIT_FEE,
                ChargeAmount__c = contract.FitOutSecurityDeposit__c,
                ConditionType__c = TYPE_TO_CONDITIONTYPE_MAP.get(OTHERCHARGE_FITOUT_SECURITY_DEPOSIT_FEE),
                SubCategory__c = TYPE_TO_SUBCATEGORY_MAP.get(OTHERCHARGE_FITOUT_SECURITY_DEPOSIT_FEE),
                RelatedPartyBloomHolding__c = contract.RelatedPartyBloomHolding__c,
                VATAmount__c = 0.0 //vatPercentage != null ? ( (contract.FitOutSecurityDeposit__c*vatPercentage)/100 ) : null
            ));
        }
        //Ejari Fee
        if (contract.EjariTawtheeqFee__c != null && contract.EjariTawtheeqFee__c != 0) {
            chargesToInsert.add(new LeasingOrdersOtherCharges__c(
                LeasingOrder__c = contract.Id,
                Type__c = OTHERCHARGE_EJARI_FEE ,
                ChargeAmount__c = contract.EjariTawtheeqFee__c,
                ConditionType__c = TYPE_TO_CONDITIONTYPE_MAP.get(OTHERCHARGE_EJARI_FEE),
                SubCategory__c = TYPE_TO_SUBCATEGORY_MAP.get(OTHERCHARGE_EJARI_FEE),
                RelatedPartyBloomHolding__c = contract.RelatedPartyBloomHolding__c,
                VATAmount__c = 0.0
            ));
        }
        
        //Renewal Fee
        if (contract.RenewalFee__c != null && contract.RenewalFee__c != 0) {
            chargesToInsert.add(new LeasingOrdersOtherCharges__c(
                LeasingOrder__c = contract.Id,
                Type__c = OTHERCHARGE_RENEWAL_FEE ,
                ChargeAmount__c = contract.RenewalFee__c,
                ConditionType__c = TYPE_TO_CONDITIONTYPE_MAP.get(OTHERCHARGE_RENEWAL_FEE),
                RelatedPartyBloomHolding__c = contract.RelatedPartyBloomHolding__c
                //SubCategory__c = TYPE_TO_SUBCATEGORY_MAP.get(OTHERCHARGE_RENEWAL_FEE),
                //VATAmount__c = 0.0
            ));
        }
        
        //Service charge fee
        if(contract.Unit__r.PropertyUsage__c == COMMERCIAL_TYPE || contract.Unit__r.PropertyUsage__c == RETAIL_TYPE){
            chargesToInsert.add(new LeasingOrdersOtherCharges__c(
                LeasingOrder__c = contract.Id,
                Type__c = OTHERCHARGE_SERVICE_CHARGE_FEE,
                ChargeAmount__c = contract.ServiceChargeFee__c,
                ConditionType__c = TYPE_TO_CONDITIONTYPE_MAP.get(OTHERCHARGE_SERVICE_CHARGE_FEE),
                SubCategory__c = TYPE_TO_SUBCATEGORY_MAP.get(OTHERCHARGE_SERVICE_CHARGE_FEE),
                RelatedPartyBloomHolding__c = contract.RelatedPartyBloomHolding__c,
                VATAmount__c = 0.0
            ));
        }
        
        LeasingOtherChargesService leasingOrderOtherChargesService = LeasingOtherChargesService.getInstance();
        leasingOrderOtherChargesService.insertOtherCharges(chargesToInsert);
    }
    //Helper Method to Amend the Leasing order need to clean up existing Data then create new 
    @AuraEnabled
    // public static Id updateLeasingContractWithCleanup(Id contractId, LeasingOrderWrapper updatedData) {
    public static Id updateLeasingContractWithCleanup(Id contractId, String inputData){
        System.debug('inputData::'+inputData);
        //VALIDATION FIRST
        validatePaymentPlanEditable(contractId);
        
        LeasingOrderWrapper updatedData = (LeasingOrderWrapper)json.deserialize(inputData, LeasingOrderWrapper.Class);
        // 1) fetch & delete all child splits/schedules/charges
        LeasingEscalationScheduleService leasingEscService = LeasingEscalationScheduleService.getInstance();
        List<LeasingEscalationSchedule__c> escSchedulesToDelete = leasingEscService.getEscalationSchedulesByContractId(contractId);
        leasingEscService.deleteEscSchedules(escSchedulesToDelete);
        
        LeasingPaymentScheduleService leasingScheduleService = LeasingPaymentScheduleService.getInstance();
        List<PaymentPlanSchedule__c> paymentSchedulesToDelete = leasingScheduleService.getPaymentSchedulesByLeasingOrderId(contractId);
        leasingScheduleService.deletePaymentSchedules(paymentSchedulesToDelete);
        
        LeasingOtherChargesService leasingChargesService = LeasingOtherChargesService.getInstance(); 
        List<LeasingOrdersOtherCharges__c> leasingChargesToDelete =leasingChargesService.getOtherChargesByLeasingOrderId(contractId);
        leasingChargesService.deleteOtherCharges(leasingChargesToDelete);
        
        LeasingOrderService leasingService = LeasingOrderService.getInstance();
        leasingService.updateLeasingOrders(new List<LeasingOrder__c>{ getUpdatedLeasingOrder(updatedData,contractId)});
        
        // 4) re-generate schedules
        //generatePaymentSchdulesCharges(contractId);
        
        Integer months = updatedData.leasingContractMonths == null
            ? 0
            : Integer.valueOf(updatedData.leasingContractMonths);
        
        if (months > 0 && months <= 18) {
            LeasingOrder__c oneYearContract = getUpdatedLeasingOrder(updatedData, contractId);
            generatePaymentSchedule(oneYearContract);
        } else {
            generatePaymentSchdulesCharges(contractId);
        }
        
        return contractId;
    }
    
    
    
    
    public static void createPaymentSchedules(List<LeasingEscalationSchedule__c> escalations, LeasingOrder__c leasingContract) {
        List<PaymentPlanSchedule__c> schedulesToInsert = new List<PaymentPlanSchedule__c>();
        // Validate Cheque Payment Mode
        String mode = leasingContract.PaymentTerm__c;
        Integer paymentsPerYear = Integer.valueOf(mode.substringBefore(' '));
        // Grace period in months
        Integer graceDays = leasingContract.GracePeriod__c != null ? Integer.valueOf(leasingContract.GracePeriod__c) : 0;
        Integer graceMonths = Integer.valueOf((graceDays / 30.0).round(System.RoundingMode.HALF_UP));
        Integer contractMonths = leasingContract.LeasingContractMonths__c != null
            ? Integer.valueOf(leasingContract.LeasingContractMonths__c)
            : 0;
        
        Integer effectiveTenure = contractMonths - graceMonths;
        
        if (contractMonths <= 0) {
            throw new AuraHandledException('Contract duration must be greater than 0.');
        }
        
        // Leasing start date
        Date leasingStartDate = leasingContract.LeasingStartDate__c;
        Date leasingEndDate = leasingContract.LeasingEndDate__c;
        Date paymentStartDate;
        if (leasingStartDate == null) {
            throw new AuraHandledException('Missing Leasing Start Date');
        }
        
        Integer intervalMonths = (Integer)Math.round(12.0 / paymentsPerYear);
        Boolean breakLoop = false;
        Integer loopCounter = 0;
        if(String.isNotBlank(leasingContract.GracePeriodFormula__c) && leasingContract.GracePeriodFormula__c != '0 Month'){
            PaymentPlanSchedule__c schedule = new PaymentPlanSchedule__c();
            schedule.Name = 'Discounted Installment';
            schedule.LeasingOrder__c = leasingContract.Id;
            schedule.PaymentStartDate__c = leasingStartDate;
            schedule.Schedule_End_Date__c = leasingStartDate.addDays(Integer.valueOf(leasingContract.GracePeriod__c)-1);
            schedule.RelatedPartyBloomHolding__c = leasingContract.RelatedPartyBloomHolding__c;
            schedule.Amount__c = 0.0;
            schedulesToInsert.add(schedule); 
        }
        
        for (LeasingEscalationSchedule__c esc : escalations) {
            loopCounter++;
            Integer remainingMonths = 12;
            Date escYeatStartDate = paymentStartDate != null ? paymentStartDate.addMonths(intervalMonths) : null;
            if(escYeatStartDate != null && escYeatStartDate.monthsBetween(leasingEndDate) < 11){
                remainingMonths = escYeatStartDate.monthsBetween(leasingEndDate) + 1;
            }
            Decimal TotalAmount = esc.AfterDiscount__c;
            Decimal installmentAmount = loopCounter != escalations.size() ? TotalAmount/paymentsPerYear : (TotalAmount/remainingMonths) * intervalMonths;
            Decimal remainingAmount = TotalAmount;
            for(Integer i = 1; i <= paymentsPerYear; i++){
                paymentStartDate = esc.Year__c == 1 && i == 1 ? leasingStartDate.addMonths(graceMonths) 
                    : paymentStartDate.addMonths(intervalMonths);
                if(paymentStartDate > leasingEndDate){
                    break;
                }
                Date paymentEndDate =  paymentStartDate.addMonths(12/paymentsPerYear).addDays(-1);
                Decimal amount = 0;
                if(paymentEndDate <= leasingEndDate){
                    amount = installmentAmount;
                    remainingAmount = remainingAmount - installmentAmount;
                } else{
                    //amount =  Decimal.valueOf(paymentStartDate.daysBetween(leasingEndDate)/30).round(System.RoundingMode.HALF_UP) * installmentAmount / intervalMonths;
                    amount =  (Decimal.valueOf(paymentStartDate.daysBetween(leasingEndDate))/Decimal.valueOf(30)).round(System.RoundingMode.HALF_UP) * (installmentAmount / intervalMonths);
                    breakLoop = true;
                }
                
                PaymentPlanSchedule__c schedule = new PaymentPlanSchedule__c();
                schedule.Year__c = esc.Year__c;
                schedule.Name = 'Year ' + esc.Year__c + ' - Payment ' + i;
                schedule.LeasingOrder__c = leasingContract.Id;
                schedule.LeasingEscalationSplit__c = esc.Id;
                schedule.PaymentStartDate__c = paymentStartDate;
                schedule.RelatedPartyBloomHolding__c = leasingContract.RelatedPartyBloomHolding__c;
                schedule.Schedule_End_Date__c = paymentEndDate > leasingEndDate ? leasingEndDate : paymentEndDate;
                schedule.Amount__c = amount.setScale(2, RoundingMode.HALF_UP);
                schedulesToInsert.add(schedule);
                
                if(breakLoop)
                    break;
            }
            
        }
        
        LeasingPaymentScheduleService paymentScheduleService = LeasingPaymentScheduleService.getInstance();
        paymentScheduleService.insertPaymentSchedules(schedulesToInsert);
    }
    
    //to get the List of all projects for Leasing
    @AuraEnabled(cacheable=true)
    public static List<map<String,string>> getAllProjectsForLeasing(){
        List<map<String,string>> filtersToReturn = new List<map<String,string>>();
        ProjectService projService = ProjectService.getInstance();
        for(Project__c tempProject: projService.getLeasingProjects())
        {
            map<string,string> tempMap=new map<string,string>();
            tempMap.put('label',tempProject.Name);
            tempMap.put('value',tempProject.id);
            tempMap.put('ejariFee',      String.valueOf(tempProject.EjariTawtheeqFee__c  ));
            tempMap.put('adminFee',      String.valueOf(tempProject.AdminFee__c));
            tempMap.put('serviceCharge', String.valueOf(tempProject.LeasingServiceCharge__c));
            tempMap.put('securityDeposit', String.valueOf(tempProject.SecurityDeposit__c));
            tempMap.put('apartmentSecDeposit', String.valueOf(tempProject.LeasingApartmentSecurityDepositAmount__c));
            tempMap.put('villaSecDeposit', String.valueOf(tempProject.LeasingVillaSecurityDepositAmount__c));
            tempMap.put('city',tempProject.city__c );
            tempMap.put('projectName',tempProject.Name );
            
            filtersToReturn.add(tempMap);
        }
        return filtersToReturn;
    }
    //to get the List of buildings based on the selected project
    @AuraEnabled(cacheable=true)
    public static List<map<String,string>> getAllBuildings(string projectId){
        List<map<String,string>> filtersToReturn = new List<map<String,string>>();
        
        for(Building__c  tempBuilding: BuildingService.getInstance().getBuildingsForLeasing(projectId) ){
            map<string,string> tempMap=new map<string,string>();
            tempMap.put('label',tempBuilding.Name);
            tempMap.put('value',tempBuilding.id);
            filtersToReturn.add(tempMap);
        }
        return filtersToReturn;
    }
    // to show the details of units selected
    @AuraEnabled(cacheable=true)
    public static UnitWrapper getUnitDetails(ID buildingsId,String bedrooms,
                                             String propertyType,String unitNumber ,Id selectedUnitId)
    { 
        UnitWrapper unitsToReturn;
        unitsToReturn = new UnitWrapper(getAvailableLeasingUnits(buildingsId,bedrooms,
                                                                 propertyType,unitNumber, selectedUnitId));
        return unitsToReturn;
    }
    public static List<Unit__c> getAvailableLeasingUnits(
        Id buildingId,
        String bedrooms,
        String propertyType,
        String unitNumber, 
        Id selectedUnitId
    ) {
        List<Unit__c> unitList = new List<Unit__c>();
        
        // Escape single quotes to avoid SOQL injection
        String safeUnitNumber = String.isNotBlank(unitNumber) 
            ? String.escapeSingleQuotes(unitNumber) 
            : null;
        
        String baseQuery = 'SELECT Id, Name, NumberOfBedrooms__c, Internal_Saleable_Area__c, LeasingUnitSizesqm__c,' +
            ' UnitType__c, PropertyUsage__c, UnitCategory__c, LeasingAnnualRent__c,' +
            ' External_Saleable_Area__c, LeasingUnitNumber__c, Project__c, Project__r.Name, SAP_Unit_Number__c FROM Unit__c WHERE ';
        
        String whereClause = '';
        
        if (propertyType == COMMERCIAL_TYPE || propertyType == RETAIL_TYPE) {
            whereClause = '(Building__c = :buildingId AND IsActive__c = true ' +
                'AND LeasingUnitStatus__c = \'Available\' AND IsAvailableforLeasing__c = true ';
            
            if (safeUnitNumber != null) {
                whereClause += 'AND (PropertyUsage__c = :propertyType AND LeasingUnitNumber__c LIKE \'%' + safeUnitNumber + '%\')';
            } else {
                //whereClause += 'AND PropertyUsage__c = :propertyType';
                whereClause += 'AND PropertyUsage__c IN (\'Retail\',\'Commercial\')';
            }
            
            whereClause += ') OR (Id = :selectedUnitId)';
            
        } else {
            whereClause = '(Building__c = :buildingId AND IsActive__c = true ' +
                'AND LeasingUnitStatus__c = \'Available\' AND IsAvailableforLeasing__c = true ';
            
            if (safeUnitNumber != null) {
                whereClause += 'AND ((NumberOfBedrooms__c = :bedrooms AND PropertyUsage__c = :propertyType) ' +
                    'AND LeasingUnitNumber__c LIKE \'%' + safeUnitNumber + '%\')';
            } else {
                whereClause += 'AND (NumberOfBedrooms__c = :bedrooms AND PropertyUsage__c = :propertyType)';
            }
            
            whereClause += ') OR (Id = :selectedUnitId)';
        }
        
        unitList = Database.query(baseQuery + whereClause);
        return unitList;
    }
    @AuraEnabled(cacheable=true)
    public static LeasingOrder__c getActiveLeasingContract(Id opportunityId) {
        LeasingOrderService leasingOrderService = LeasingOrderService.getInstance();
        List<LeasingOrder__c> contract = leasingOrderService.getActiveLeasingContractByOppId(opportunityId);                                                                                                                                                                                                       
        return contract != null && !contract.isEmpty() ? contract[0] : null ; 
    }
    @AuraEnabled(cacheable=true)
    public static map<String,object> getsObjectType(Id recordID){
        System.debug('recordID:'+recordID);
        map<String,sObject> mapToReturn = new map<String,sObject>();
        Schema.SObjectType sobjectType = recordID.getSObjectType();
        string sobjectName = sobjectType.getDescribe().getName();
        OpportunityService oppService = OpportunityService.getInstance();
        if(sobjectName.equalsIgnoreCase('Opportunity')){
            mapToReturn.put(sobjectName,oppService.getOpportunityById(recordID));
        }
        if(sobjectName.equalsIgnoreCase('LeasingOrder__c')){
            LeasingOrderService leasingOrderService = LeasingOrderService.getInstance();
            mapToReturn.put(sobjectName,leasingOrderService.getLeasingOrderById(recordId));
        }
        return mapToReturn;
    }
    
    
    public static void generatePaymentSchedule(LeasingOrder__c contrct) {
        LeasingOrderService leasingOrderService = LeasingOrderService.getInstance();
        
        
        LeasingOrder__c contract = leasingOrderService.getLeasingOrderById(contrct.Id);
        Integer paymentsPerYear;
        Date leaseEndDate = contract.LeasingEndDate__c;
        Integer graceDays = contract.GracePeriod__c != null ? Integer.valueOf(contract.GracePeriod__c) : 0;
        Integer graceMonths = Integer.valueOf((graceDays / 30.0).round(System.RoundingMode.HALF_UP));
        Decimal tenureMonths = contract.LeasingContractMonths__c;
        Decimal effectiveTenure = tenureMonths - graceMonths;
        paymentsPerYear = Integer.valueOf(contract.PaymentTerm__c.substringBefore(' '));
        Decimal potentialAmount = contract.RentalAmountAfterDiscount__c == 0 ? contract.AppliedAnnualRent__c : contract.RentalAmountAfterDiscount__c ;
        Decimal TotalRent = (potentialAmount / 12)*effectiveTenure;
        
        Decimal installmentAmount = (potentialAmount/12)*(12/paymentsPerYear);
        Date startDate = contract.LeasingStartDate__c;
        
        Decimal monthlyRent = potentialAmount / 12;
        Date expectedEndDate = contract.LeasingStartDate__c.addMonths(Integer.valueOf(tenureMonths));
        Integer extraDays = expectedEndDate.daysBetween(contract.LeasingEndDate__c);
        if(extraDays > 0){
            Decimal dailyRent = monthlyRent / 30;
            totalRent += (dailyRent * extraDays);
        }
        
        if (contract.GracePeriod__c != null && contract.GracePeriod__c > 0) {
            startDate = startDate.addMonths(graceMonths);
        }
        List<PaymentPlanSchedule__c> schedules = new List<PaymentPlanSchedule__c>();
        Decimal remainingAmount = TotalRent;
        Boolean breakLoop = false;
        if(String.isNotBlank(contract.GracePeriodFormula__c) && contract.GracePeriodFormula__c != '0 Month' ){
            PaymentPlanSchedule__c schedule = new PaymentPlanSchedule__c();
            schedule.Name = 'Discounted Installment';
            schedule.LeasingOrder__c = contract.Id;
            schedule.PaymentStartDate__c = startDate;
            schedule.Schedule_End_Date__c = startDate.addDays(Integer.valueOf(contract.GracePeriod__c)-1);
            schedule.Amount__c = 0.0;
            schedule.RelatedPartyBloomHolding__c = contract.RelatedPartyBloomHolding__c;
            schedules.add(schedule);
        }
        
        for (Integer i = 0; i < paymentsPerYear; i++) {
            Date dueDate = startDate.addMonths((12 / paymentsPerYear)*i);
            Date endDate = dueDate.addMonths((12 / paymentsPerYear)).addDays(-1) > leaseEndDate ? leaseEndDate : dueDate.addMonths((12 / paymentsPerYear)).addDays(-1);
            Decimal currentAmount = installmentAmount;
            if(remainingAmount > currentAmount){
                remainingAmount -= currentAmount;
            }
            else{
                currentAmount = remainingAmount;
                breakLoop = true;
            }
            
            
            // if(endDate > leaseEndDate){
            //     currentAmount = (installmentAmount / (12 / paymentsPerYear)) * (Decimal.valueOf(dueDate.daysBetween(leaseEndDate)/30).round(System.RoundingMode.HALF_UP));
            // }
            schedules.add(new PaymentPlanSchedule__c(
                LeasingOrder__c = contract.Id,
                PaymentStartDate__c = dueDate,
                Schedule_End_Date__c = endDate,
                Amount__c = currentAmount.setScale(2, RoundingMode.HALF_UP),
                Year__c = 1 ,
                Name = YEAR+' '+1+' - '+PAYMENT+' '+(i+1),
                RelatedPartyBloomHolding__c = contract.RelatedPartyBloomHolding__c
            ));
            if(breakLoop)
                break;
            
        }
        
        LeasingPaymentScheduleService paymentScheduleService = LeasingPaymentScheduleService.getInstance();
        paymentScheduleService.insertPaymentSchedules(schedules);
        createOtherCharges(contract.Id);
        createLeasingCommission(contract);
    }
    
    @AuraEnabled(cacheable=true)
    public static Boolean hasEditPermission() {
        return FeatureManagement.checkPermission('LeasingFeeEditPermission');
    }
    
    
    public static LeasingOrder__c getUpdatedLeasingOrder(LeasingOrderWrapper updatedData, String contractId) 
    {
        LeasingOrder__c updLeasingOrder =  prepareLeasingOrder(updatedData); 
        if(String.isNotBlank(contractId)){
            List<LeasingOrder__c> oldContractList = LeasingOrderService.getInstance().getLeasingOrdersByIds(new Set<Id>{contractId});
            if(!oldContractList.isEmpty()){
                LeasingOrder__c oldContract = oldContractList[0];
                if(oldContract.LeaseType__c == 'Renewal'){
                    updLeasingOrder.LeaseType__c = 'Renewal';
                }
                if(oldContract.SAPConditionFrequency__c != 0 && !(updLeasingOrder.SAPConditionFrequency__c > 0) ){
                    updLeasingOrder.SAPConditionFrequency__c = oldContract.SAPConditionFrequency__c;
                }
                if(oldContract.SAPAnnualRenewal__c != 0 && !(updLeasingOrder.SAPAnnualRenewal__c > 0) ){
                    updLeasingOrder.SAPAnnualRenewal__c = oldContract.SAPAnnualRenewal__c;
                }
            }
        }
        updLeasingOrder.id = contractId ;
        return updLeasingOrder ;
    }
    public static LeasingOrder__c prepareLeasingOrder(LeasingOrderWrapper updatedData) 
    {
        
        String oppId     = updatedData.opportunityId;
        String name      = updatedData.name;
        String unitId    = updatedData.unitId;
        String buildingId =  updatedData.building;
        String projectId =  updatedData.project;
        String famStatus = updatedData.familyStatus;
        String remarks   = updatedData.remarks;
        String propertyId = updatedData.propertyId;
        Integer adultCount = updatedData.adultCount != Null ? updatedData.adultCount : 0;
        Integer childCount = updatedData.childCount != Null ? updatedData.childCount : 0;
        
        // handle discount
        Decimal discountAmt = 0;
        Decimal discountPct = 0;
        if (updatedData.discountType == 'Percentage') {
            discountPct = updatedData.discountPercentage == null ? 0 : updatedData.discountPercentage;
        } else if (updatedData.discountType == 'Amount') {
            discountAmt = updatedData.discountAmount == null ? 0 : updatedData.discountAmount;
        }
        
        Decimal annualRent          = updatedData.annualRent == null ? 0 : updatedData.annualRent;
        Decimal appliedRent         = updatedData.appliedAnnualRent == null ? annualRent : updatedData.appliedAnnualRent;
        Decimal rentalAfter         = updatedData.rentalAfterDiscount == null ? appliedRent : updatedData.rentalAfterDiscount;
        Date    leasingStartDate    = updatedData.leasingStartDate;
        
        Integer leasingContractMonths = updatedData.leasingContractMonths == null ? 0 : updatedData.leasingContractMonths;
        Decimal secDeposit          = updatedData.securityDeposit == null ? 0 : updatedData.securityDeposit;
        Decimal adminFee            = updatedData.adminFee == null ? 0 : updatedData.adminFee;
        Decimal ejariFee            = updatedData.ejariFee == null ? 0 : updatedData.ejariFee;
        Decimal serviceCharge       = updatedData.serviceCharge == null ? 0 : updatedData.serviceCharge;
        Decimal extraChequeFee      = updatedData.extraChequeFee == null ? 0 : updatedData.extraChequeFee;
        Decimal fitOutSecurity      = updatedData.fitOutSecurityDeposit == null ? 0 : updatedData.fitOutSecurityDeposit;
        Decimal gracePeriod         = updatedData.gracePeriod == null ? 0 : updatedData.gracePeriod;
        Date    leasingEndDate      = updatedData.leasingEndDate.addDays(Integer.valueOf(gracePeriod));
        Integer offerValidityDays   = updatedData.offerValidityDays == null ? 3 : updatedData.offerValidityDays;
        Boolean relatedPartyBloomHolding = updatedData.relatedPartyBloomHolding;
        
        Decimal bookingAmount            = updatedData.bookingAmount == null ? 0 : updatedData.bookingAmount;
        Integer SAPConditionFrequency            = updatedData.SAPConditionFrequency == null ? 0 :updatedData.SAPConditionFrequency ;
        Decimal SAPAnnualRenewal            = updatedData.SAPAnnualRenewal == null ? 0 :updatedData.SAPAnnualRenewal ;
        // get opportunity/account
        OpportunityService oppService = OpportunityService.getInstance();
        Opportunity  relatedOpp = oppService.getOpportunityById(oppId);
        // create LeasingOrder__c
        LeasingOrder__c contract = new LeasingOrder__c(
            OfferValidityDays__c             = (offerValidityDays <= 0 ? 3 : offerValidityDays),
            RelatedPartyBloomHolding__c = relatedPartyBloomHolding,
            Opportunity__c                   = oppId,
            Account__c                       = relatedOpp.AccountId,
            Name                             = name,
            Unit__c                          = unitId,
            Building__c                      = buildingId,
            Project__c                       = projectId,
            PropertyName__c                  = updatedData.projectName,
            FamilyStatus__c                  = famStatus,
            AnnualRent__c                    = annualRent,
            DiscountPercentage__c            = discountPct,
            RentalAmountAfterDiscount__c     = rentalAfter,
            PaymentTerm__c                   = updatedData.paymentPlanId,
            LeasingOffer__c                  = updatedData.leasingOfferId,
            LeasingStartDate__c              = leasingStartDate,
            AppliedAnnualRent__c             = appliedRent,
            DiscountType__c                  = updatedData.discountType,
            DiscountAmount__c                = discountAmt,
            LeasingContractMonths__c         = leasingContractMonths,
            LeasingEndDate__c                = leasingEndDate,
            AdminFee__c                      = adminFee,
            ServiceChargeFee__c              = serviceCharge,
            EjariTawtheeqFee__c              = ejariFee,
            ExtraChequeFee__c                = extraChequeFee,
            FitOutSecurityDeposit__c         = fitOutSecurity,
            Remarks__c                       = remarks,
            SecurityDeposit__c        = updatedData.securityDeposit,
            SecurityDepositType__c    = updatedData.securityDepositType,
            SecurityDepositPercent__c = updatedData.securityDepositType == 'Percentage' 
            ? updatedData.securityDepositPercent 
            : null,
            
            //SecurityDeposit__c               = secDeposit,
            AdditionalSecurityDeposite__c   = updatedData.additionalSecurityDeposit,//Pranav
            GracePeriod__c                   = gracePeriod,
            CurrentCondition__c              = updatedData.currentCondition,
            HandoverCondition__c             = updatedData.handOverCondition,
            BookingAmount__c                   = bookingAmount,
            propertyId__c                      =   propertyId,
            NoofAdults__c                   =   adultCount,
            NoofChildren__c                 =   childCount,
            LeaseType__c = 'New',
            SAPConditionFrequency__c            = SAPConditionFrequency,
            SAPAnnualRenewal__c           = SAPAnnualRenewal
        );                 
        if(updatedData.isBloomStaff != Null)
            contract.BloomEmployee__c = updatedData.isBloomStaff;
        
        if(updatedData.isBloomPartnerStaff != Null)
            contract.BloomSisterCompanyEmployee__c = updatedData.isBloomPartnerStaff;
        
        return contract ;
    }
    //Helper method - Using in Send Genrated offer to customer for signature and link the Offer to Email Message 
    @AuraEnabled
    public static void sendEmailWithDocument(Id recordId) {
        LeasingOrder__c contract = LeasingOrderService.getInstance().getLeasingOrderById(recordId);
        Document__c leasingOfferDocument = DocumentService.getInstance().getLeasingOfferDocumentsByContractIds(new Set<Id>{recordId})[0];
        MetadataService objMetadataService = MetadataService.getInstance();
        
        Id leaseOfferEmailTemplateId = objMetadataService.getAppSettingTextValue(LEASING_OFFER_FOR_CUSROMER_SIGN);
        
        ContentVersion version = ContentService.getInstance().getContentVersionByPublishLocation(leasingOfferDocument.Id);
        Id noReplyBloomLeasingOWDId = objMetadataService.getAppSettingTextValue(BLOOM_NO_REPLY_LEASING_OW_EMAIL_ID);
        
        List<String> toAddress = new List<String>();
        
        if(contract.Account__r.IsPersonAccount){
            toAddress.add(contract.Account__r.PersonEmail);
        }else{
            Contact primaryContact = ContactService.getInstance().getPrimaryContactByAccountId(contract.Account__c,TRUE)[0];
            toAddress.add(primaryContact.email);
        }
        
        EmailService objEmailService = EmailService.getInstance();
        Messaging.SingleEmailMessage objMail = objEmailService.getSingleEmailMessageWithoutTargetObjectId(leaseOfferEmailTemplateId,
                                                                                                          noReplyBloomLeasingOWDId ,
                                                                                                          contract.Id,
                                                                                                          toAddress,
                                                                                                          null, null);
        Messaging.EmailFileAttachment objFileAttachment = objEmailService.getEmailAttachment(version.Title + '.' + version.FileExtension,
                                                                                             version.VersionData,
                                                                                             'application/pdf');
        objMail.setFileAttachments(new Messaging.EmailFileAttachment[] { objFileAttachment}); 
        objEmailService.sendEmail(new List<Messaging.SingleEmailMessage>{objMail});
        
        
        EmailMessage emailMessage = EmailMessageService.getInstance().getLatestEmailMessageByRelatedToId(contract.Id);
        if(emailMessage != null){
            // Clone the ContentVersion
            ContentVersion clonedVersion = new ContentVersion();
            clonedVersion.Title = version.Title;
            clonedVersion.PathOnClient = version.Title + '.' + version.FileExtension;
            clonedVersion.VersionData = version.VersionData;
            // Set the new FirstPublishLocationId (e.g., target record to attach the file to)
            clonedVersion.FirstPublishLocationId = emailMessage.Id; // Replace with actual Id
            ContentService.getInstance().createContentVersion(new List<ContentVersion>{clonedVersion});
        }
    }
    @AuraEnabled(cacheable=true)
    public static LeasingOrder__c getLeasingOrder(Id recordId) {
        LeasingOrderService leasingService = LeasingOrderService.getInstance();
        return leasingService.getLeasingOrderById(recordId);
    }
    
    @AuraEnabled
    public static void terminateLease(LeasingOrder__c leasingOrder, List<LeasingOrdersOtherCharges__c> otherCharges) {
        // Update parent record
        leasingOrder.SendToSAP__c = true;
        leasingOrder.Lease_Terminated__c = true;
        leasingOrder.LeaseType__c = 'Termination';
        LeasingOrderService loServie = LeasingOrderService.getInstance();
        loServie.updateLeasingOrder(leasingOrder);
        
        // Add related charges
        if (!otherCharges.isEmpty()) {
            LeasingOtherChargesService ocService = LeasingOtherChargesService.getInstance();
            Map<String, String> TYPE_TO_CONDITIONTYPE_MAP = ocService.getTypeToConditionTypeMap();
            for (LeasingOrdersOtherCharges__c ch : otherCharges) {
                ch.LeasingOrder__c = leasingOrder.Id;
                ch.SendToSAP__c = true;
                
                if(TYPE_TO_CONDITIONTYPE_MAP.containsKey(ch.SubCategory__c)){
                    ch.ConditionType__c = TYPE_TO_CONDITIONTYPE_MAP.get(ch.SubCategory__c);
                }
                System.debug(ch);
                
            }
            ocService.insertOtherCharges(otherCharges);
        }
        
        //for move out form generation
        DocumentTypeService dtService = DocumentTypeService.getInstance();
        
        for(Documenttype__c dt : dtService.getActiveDocuGenDocumentTypeRecords(LEASING_ORDER_API_NAME)){
            if(dt.Type__c == MOVE_OUT_REQUEST_FORM){
                if(dt.DeliveryOption__c != Null && dt.DocGenPackage__c != Null && dt.Type__c != Null){
                    LeasingDocGenController.generateDocument(dt.DeliveryOption__c,dt.DocGenPackage__c,leasingOrder.Id,dt.Type__c);
                }
            }
        }
        
        //unit update logic in trigger
        //update payment plan logic here
        List<PaymentPlanSchedule__c> schedules = [SELECT Id,PaymentStartDate__c/*,Schedule_End_Date__c*/,Amount__c,DueAmount__c,CreditAmount__c,TotalInstallmentAmount__c, LeasingOrder__r.Unit__r.PropertyUsage__c
                                                  FROM PaymentPlanSchedule__c WHERE LeasingOrder__c = :leasingOrder.Id AND PaymentStartDate__c <= :leasingOrder.TerminationDate__c
                                                  /*AND DueAmount__c = 0*/ ORDER BY PaymentStartDate__c DESC LIMIT 1];
        
        PaymentPlanSchedule__c paidSchedule = schedules.isEmpty() ? null : schedules[0];
        //	System.debug('paidSchedule.TotalInstallmentAmount__c------ ' + paidSchedule.TotalInstallmentAmount__c);
        
        //Calculate CREDIT AMOUNT
        
        Decimal creditAmount = 0;
        
        if ( paidSchedule != null && paidSchedule.PaymentStartDate__c != null && paidSchedule.TotalInstallmentAmount__c != null &&
            leasingOrder.TerminationDate__c != null && String.isNotBlank(leasingOrder.PaymentTerm__c) &&
            paidSchedule.LeasingOrder__r.Unit__r.PropertyUsage__c != null &&
            (paidSchedule.LeasingOrder__r.Unit__r.PropertyUsage__c == 'Residential' ||
             paidSchedule.LeasingOrder__r.Unit__r.PropertyUsage__c == 'Commercial'
            )) {
                // Extract installment count from PaymentTerm
                Integer installmentCount = Integer.valueOf(leasingOrder.PaymentTerm__c.substringBefore(' '));
                Date startDate = paidSchedule.PaymentStartDate__c;
                Date endDate   = leasingOrder.TerminationDate__c;
                
                if (installmentCount > 0) {
                    
                    // Months paid for this installment
                    Integer monthsPaid = 12 / installmentCount;
                    
                    Date installmentEndDate = startDate.addMonths(monthsPaid);
                    
                    // Total days in paid installment
                    Integer totalDays =
                        startDate.daysBetween(installmentEndDate);
                    
                    Integer usedDays = 0;
                    
                    if(endDate != null && endDate >= startDate){
                        usedDays =startDate.daysBetween(endDate) + 1;
                    }
                    
                    if(usedDays > totalDays){
                        usedDays = totalDays;
                    }
                    Integer unusedDays = totalDays - usedDays;
                    
                    System.debug('totalDays------ ' + totalDays);
                    System.debug('usedDays------ ' + usedDays);
                    System.debug('unusedDays------ ' + unusedDays);
                    
                    if (unusedDays > 0 && totalDays > 0) {
                        System.debug('paidSchedule.TotalInstallmentAmount__c------ ' + paidSchedule.TotalInstallmentAmount__c);
                        Decimal perDayAmount =
                            paidSchedule.TotalInstallmentAmount__c / totalDays;
                        System.debug('perDayAmount------ ' + perDayAmount);
                        
                        creditAmount =
                            (perDayAmount * unusedDays)
                            .setScale(2, RoundingMode.HALF_UP);
                    }
                }
            }
        
        if (paidSchedule != null && creditAmount >= 0) {
            paidSchedule.CreditAmount__c = creditAmount;
            update paidSchedule;
        }
        
    }
    
    @AuraEnabled
    //public static void createLegalTask(String leasingOrdrId, LegalTaskWrapper data){
    public static void createLegalTask(String leasingOrdrId, String inputData){
        LeasingOrder__c lo = new LeasingOrder__c();
        LegalTaskWrapper data = (LegalTaskWrapper)JSON.deserialize(inputData, LegalTaskWrapper.class);
        lo.Id = leasingOrdrId;
        if(data.caseType == 'Legal Case'){
            lo.isLegalCase__c = true;
        } else{
            lo.isChequebouncecase__c = true;
        }
        //update lo;
        
        LeasingOrderService leasingOrderService = LeasingOrderService.getInstance();
        leasingOrderService.updateLeasingOrder(lo);
        LeasingOrder__c upadateLO = leasingOrderService.getLeasingOrderById(leasingOrdrId);
        
        Task legalTask = new Task();
        legalTask.Subject = upadateLO.LeasingOrderNumber__c + ' ' + data.caseType;
        legalTask.OwnerId = data.legalUserId;
        legalTask.WhatId = upadateLO.Id;
        ActivityService service = ActivityService.getInstance();
        service.insertTasks(new List<Task>{legalTask});
        
    }
    public static void createLeasingCommission(LeasingOrder__c leasingOrder){
        
        if (
            leasingOrder.LeaseType__c != 'Termination' &&
            (
                (leasingOrder.LeaseType__c == 'Renewal' &&
                 leasingOrder.RenewalFee__c != null &&
                 leasingOrder.RenewalFee__c > 0)
                ||
                (leasingOrder.LeaseType__c != 'Renewal' &&
                 leasingOrder.AdminFee__c != null &&
                 leasingOrder.AdminFee__c > 0)
            )
        ) {
            LeasingOfficerCommission__c loc = new LeasingOfficerCommission__c();
            loc.Name = leasingOrder.Owner.Name+' Leasing Commission' ;
            loc.LeasingOrder__c = leasingOrder.id ;
            loc.SAPConditionTypeCode__c = leasingOrder.LeaseType__c == 'Renewal' ? 'R057': 'R032' ;
            loc.Commission_Amount__c = loc.SAPConditionTypeCode__c == 'R057' ? 100.00 : ( leasingOrder.TotalAnnualRentwithVAT__c * 15/1000 );
                loc.LeasingOfficer__c = leasingOrder.OwnerId;
            LeasingOfficerCommissionService service = LeasingOfficerCommissionService.getInstance();
            service.insertLOC(loc);  
        }
    }
    
    @AuraEnabled
    public static String createFinanceTask(String inputData){
        try{
            LeasingOrderDataWrapper data = (LeasingOrderDataWrapper)JSON.deserialize(inputData, LeasingOrderDataWrapper.class);
            LeasingOrder__c  LO = new LeasingOrder__c();
            LO.Id = data.leasingOrderId;
            LO.EjariReceived__c = data.ejariReceived;
            LO.RERANumber__c = data.ejariNumber != null ? data.ejariNumber : '';
            LO.NoofPDCRecieved__c = data.pdcNumber;
            LO.PDCHandedOverTo__c = data.pdcUser;
            LO.PDCReceiveDate__c = Date.valueOf(data.pdcDate);
            //LO.LOSyncUser__c = data.loSyncUser;
            //LO.FinanceTask__c = true;
            
            LeasingOrderService leasingOrderService = LeasingOrderService.getInstance();
            leasingOrderService.updateLeasingOrders(new List<LeasingOrder__c>{LO});
            LeasingOrder__c upadateLO = leasingOrderService.getLeasingOrderById(data.leasingOrderId);
            List<Task> lotasks = new list<Task>();
            Task financeTask = new Task();
            if(data.isSyncTaskRequired != null && data.isSyncTaskRequired ){
                financeTask.Subject = label.LOFinananceTaskSubject + ' ' + upadateLO.Name;
            }else{
                financeTask.Subject = label.LOFinananceTaskSubjectTeamOnly + ' ' + upadateLO.Name;
            }
            financeTask.OwnerId = data.pdcUser;
            financeTask.WhatId = upadateLO.Id;
            lotasks.add(financeTask);
            if(data.isSyncTaskRequired != null && data.isSyncTaskRequired ){
                Task loSynctask = new Task();
                loSynctask.Subject = 'Sync leasing order :'+upadateLO.Name;
                loSynctask.OwnerId = data.loSyncUser;
                loSynctask.WhatId = upadateLO.Id;
                lotasks.add(loSynctask);
            }
            ActivityService service = ActivityService.getInstance();
            //service.insertTasks(new List<Task>{financeTask});
            service.insertTasks(lotasks);
            return 'Success';
        } catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
            
        }
        
        
    }
    
    @AuraEnabled(cacheable=true)
    public static Id getUserIdByName(String userName) {
        
        User u = [
            SELECT Id 
            FROM User 
            WHERE Name = :userName 
            LIMIT 1
        ];
        return u?.Id;
    }
    
    @AuraEnabled
    public static String handleFinanceFileUpload(String loId,String fileName, String base64Data){
        String docName = '';
        Id docId;
        if(fileName.split('\\.')[0] == 'PDC'){
            docName = PDC_DOC_NAME;
        }else{
            docName = EJARI_DOC_NAME;
        }
        //Document__c doc = [Select Id from Document__c where LeasingOrder__c =: loId and Document_Name__c =: docName];
        DocumentService docService = DocumentService.getInstance();
        for(Document__c doc : docService.getDocumentsByLeasingOrderId(loId)){
            if(doc.Document_Name__c == docName){
                docId = doc.Id;
                break;
            }
        }
        try {
            // Convert base64 to Blob
            Blob fileBody;
            try {
                fileBody = EncodingUtil.base64Decode(base64Data);
            } catch (Exception e) {
                throw new AuraHandledException('Invalid base64 data.');
            }
            
            // Create a new ContentVersion
            ContentService contentHelper = ContentService.getInstance();
            
            ContentVersion cv = new ContentVersion();
            cv.Title = fileName;
            cv.PathOnClient = fileName;
            cv.VersionData = fileBody;
            //insert cv;
            ContentVersion insertedCv =  contentHelper.insertContentVersion(cv);
            
            // Fetch the ContentDocument Id
            Id contentDocumentId = contentHelper.getContentDocumentId(insertedCv.Id);
            
            // Link the file to the record
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = contentDocumentId;
            cdl.LinkedEntityId = docId;
            cdl.ShareType = 'V'; // Viewer permission
            cdl.Visibility = 'AllUsers';
            //insert cdl;
            contentHelper.insertContentDocumentLink(new List<ContentDocumentLink>{cdl});
            
            return 'File uploaded successfully.';
        } catch (Exception e) {
            throw new AuraHandledException('Error uploading file: ' + e.getMessage());
        }
    }
    
    public class UnitWrapper{
        
        @AuraEnabled
        public List<UnitDetailsWrapper> unitDetailList=new List<UnitDetailsWrapper>();
        public UnitWrapper(List<Unit__c> unitData){
            for(Unit__c tempUnit : unitData){
                unitDetailList.add( new UnitDetailsWrapper(tempUnit) );
            }
        }
    }
    public class UnitDetailsWrapper{
        @AuraEnabled
        public boolean isSelected;
        @AuraEnabled
        public Unit__c unitDetails;
        public UnitDetailsWrapper(Unit__c tempUnit){
            isSelected = false;
            unitDetails = tempUnit;
        }
    }
    public class LeasingOrderWrapper {
        public String opportunityId{get; set;}
        public String name{get; set;}
        public String unitId{get; set;}
        public String familyStatus{get; set;}
        public String remarks{get; set;}
        public String currentCondition{get; set;}
        public String handOverCondition{get; set;}
        public String discountType{get; set;}
        public Decimal discountPercentage{get; set;}
        public Decimal discountAmount{get; set;}
        public Decimal annualRent{get; set;}
        public Decimal appliedAnnualRent{get; set;}
        public Date leasingStartDate{get; set;}
        public Date leasingEndDate{get; set;}
        public Integer leasingContractMonths{get; set;}
        public Decimal rentalAfterDiscount{get; set;}
        public String paymentPlanId{get; set;}
        public String leasingOfferId{get; set;}
        public Decimal securityDeposit{get; set;}
        public Decimal additionalSecurityDeposit{get; set;}//Pranav
        public Decimal adminFee{get; set;}
        public Decimal ejariFee{get; set;}
        public Decimal serviceCharge{get; set;}
        public Decimal extraChequeFee{get; set;}
        public Decimal fitOutSecurityDeposit{get; set;}
        public Integer gracePeriod{get; set;}
        public Integer offerValidityDays{get; set;}
        public String securityDepositType { get; set; }
        public String building { get; set; }
        public String project { get; set; }
        public String projectName { get; set; }
        public Decimal securityDepositPercent { get; set; }
        public Decimal bookingAmount{get; set;}
        public String propertyId {get; set;}
        public Integer adultCount {get; set;}
        public Integer childCount {get; set;}
        public Boolean isBloomStaff {get; set;}
        public Boolean isBloomPartnerStaff {get; set;}
        public Integer SAPConditionFrequency {get; set;}
        public Decimal SAPAnnualRenewal {get; set;}
        public Boolean relatedPartyBloomHolding {get; set;}
        
    }
    public class LegalTaskWrapper{
        public String caseType {get; set;}
        public String legalUserId {get; set;}
    }
    
    public class LeasingOrderDataWrapper {
        public String leasingOrderId{get; set;}
        public Boolean ejariReceived{get; set;}
        public String ejariNumber{get; set;}
        public Integer pdcNumber{get; set;}
        public String pdcUser{get; set;}
        public String pdcDate{get; set;}
        public String pdcFileName{get; set;}
        public String pdcFileData{get; set;}
        public String loSyncUser{get; set;}
        public Boolean isSyncTaskRequired{get; set;}
    }
    
    @AuraEnabled
    public static void validatePaymentPlanEditable(Id leasingOrderId) {
        
        LeasingPaymentScheduleService leasingScheduleService = LeasingPaymentScheduleService.getInstance();
        List<PaymentPlanSchedule__c> schedules = leasingScheduleService.getPaymentSchedulesByLeasingOrderId(leasingOrderId);
        
        /* for (PaymentPlanSchedule__c sch : schedules) {

Boolean hasError = String.isBlank(sch.RefDocno__c) || String.isBlank(sch.Paymentdoc__c) || sch.IsReversed__c != true;

if (hasError) {
throw new AuraHandledException(
'Payment Plan cannot be modified because related payment documents are not reversed or are blocked.'
);
}
}*/
    }
    
    @AuraEnabled
    public static void validateFinancialRecordsEditable(Id leasingOrderId) {
        
        // ---- Validate Payment Plan ----
        LeasingPaymentScheduleService leasingScheduleService = LeasingPaymentScheduleService.getInstance();
        List<PaymentPlanSchedule__c> schedules = leasingScheduleService.getPaymentSchedulesByLeasingOrderId(leasingOrderId);
        
        for (PaymentPlanSchedule__c sch : schedules) {
            
            Boolean hasError = 
                sch.RefDocno__c != null && !sch.IsReversed__c && String.isBlank(sch.Paymentdoc__c);
            
            if (hasError) {
                throw new AuraHandledException(
                    'Modification not allowed. Some Payment Plan records are linked to non-reversed.'
                );
            }
        }
        
        // ---- Validate Other Charges ----
        LeasingOtherChargesService leasingOtherchrgsService = LeasingOtherChargesService.getInstance();
        List<LeasingOrdersOtherCharges__c> charges = leasingOtherchrgsService.getOtherChargesByLeasingOrderId(leasingOrderId);
        
        for (LeasingOrdersOtherCharges__c ch : charges) {
            
            Boolean hasError =
                ch.RefDocno__c != null &&
                (
                    ch.IsReversed__c == false ||
                    String.isBlank(ch.Paymentdoc__c)
                );
            
            if (hasError) {
                throw new AuraHandledException(
                    'Modification not allowed. Some Other Charge records are linked to non-reversed.'
                );
            }
        }
    }
    
    @AuraEnabled
    public static List<LeasingOrdersOtherCharges__c> getOtherCharges(Date fromDate, Date toDate) {
        
        LeasingOtherChargesService leasingOrderOtherChargeService = LeasingOtherChargesService.getInstance();
        List<LeasingOrdersOtherCharges__c> otherCharges = leasingOrderOtherChargeService.getActiveOtherChargesByStartEndDate(fromDate, toDate);
        
        return otherCharges;
    }
    
    @AuraEnabled
    public static void updateOtherCharges(List<Id> recordIds, Date postingDate) {
        
        if(recordIds == null || recordIds.isEmpty()){
            throw new AuraHandledException('No records selected');
        }
        
        LeasingOtherChargesService leasingOrderOtherChargeService = LeasingOtherChargesService.getInstance();
        List<LeasingOrdersOtherCharges__c> charges = leasingOrderOtherChargeService.getLeasingOtherChargesByIds(new Set<Id>(recordIds));
        
        for(LeasingOrdersOtherCharges__c oc : charges){
            oc.PostingDate__c = postingDate;
            oc.SendToSAP__c = true;
        }
        
        List<LeasingOrdersOtherCharges__c> updatedCharges = leasingOrderOtherChargeService.updateLeasingOtherCharges(charges);
    }
    
    @AuraEnabled(cacheable=true)
    public static PaymentPlanSummaryWrapper getPaymentPlanSummary(Id leasingOrderId) {
        PaymentPlanSummaryWrapper summary = new PaymentPlanSummaryWrapper();
        
        if (leasingOrderId == null) {
            return summary;
        }
        
        LeasingPaymentScheduleService leasingScheduleService = LeasingPaymentScheduleService.getInstance();
        List<PaymentPlanSchedule__c> paymentSchedules = leasingScheduleService.getPaymentSchedulesByLeasingOrderId(leasingOrderId);
        
        for (PaymentPlanSchedule__c schedule : paymentSchedules) {
            summary.totalInstallmentAmount +=
                schedule.TotalInstallmentAmount__c != null
                ? schedule.TotalInstallmentAmount__c
                : 0;
            
            summary.totalDueAmount +=
                schedule.DueAmount__c != null
                ? Decimal.valueOf(String.valueOf(schedule.DueAmount__c))
                : 0;
            
            summary.totalClearedAmount +=
                schedule.ClearedAmount__c != null
                ? Decimal.valueOf(String.valueOf(schedule.ClearedAmount__c))
                : 0;
        }
        
        return summary;
    }
    
    public class PaymentPlanSummaryWrapper {
        @AuraEnabled public Decimal totalInstallmentAmount;
        @AuraEnabled public Decimal totalDueAmount;
        @AuraEnabled public Decimal totalClearedAmount;
        
        public PaymentPlanSummaryWrapper() {
            totalInstallmentAmount = 0;
            totalDueAmount = 0;
            totalClearedAmount = 0;
        }
    }
    
    @AuraEnabled
    public static Boolean ValidationLeasingOrderSyncWarning(Id recordId) {
        try {
            if (recordId == null) {
                throw new AuraHandledException('Leasing Order Id is required.');
            }
            
            LeasingOrderService leasingOrderService = LeasingOrderService.getInstance();
            LeasingOrder__c leasingOrder = leasingOrderService.getLeasingOrderforSyncById(recordId);
            
            Date postingClosureDate = leasingOrder.Project__r.Leasing_Company__r.LeasingPostingClosureDate__c;
            
            if (postingClosureDate == null) {
                return false;
            }
            
            Integer postingMonth = postingClosureDate.month();
            Integer postingYear = postingClosureDate.year();
            
            LeasingPaymentScheduleService paymentPlanService = LeasingPaymentScheduleService.getInstance();
            List<PaymentPlanSchedule__c> paymentPlans = paymentPlanService.getPaymentSchedulesByLeasingOrderId(recordId);
            
            for (PaymentPlanSchedule__c plan : paymentPlans) {
                if (plan.DueDate__c != null) {
                    Integer dueMonth = plan.DueDate__c.month();
                    Integer dueYear = plan.DueDate__c.year();
                    
                    if (dueYear < postingYear || (dueYear == postingYear && dueMonth <= postingMonth)) {
                        return true;
                    }
                }
            }
            
            LeasingOtherChargesService otherChargeService = LeasingOtherChargesService.getInstance();
            List<LeasingOrdersOtherCharges__c> otherCharges = otherChargeService.getOtherChargesByLeasingOrderId(recordId);
            
            for (LeasingOrdersOtherCharges__c charge : otherCharges) {
                if (charge.DueDate__c != null) {
                    Integer dueMonth = charge.DueDate__c.month();
                    Integer dueYear = charge.DueDate__c.year();
                    
                    if (dueYear < postingYear || (dueYear == postingYear && dueMonth <= postingMonth)) {
                        return true;
                    }
                }
            }
            
            LeasingReceiptAcknowledgementService receiptService = LeasingReceiptAcknowledgementService.getInstance();
            List<LeasingReceiptAcknowledgment__c> receipts = receiptService.getLRAByLeasingOrderId(recordId);
            
            for (LeasingReceiptAcknowledgment__c receipt : receipts) {
                if (receipt.VerifyDate__c != null) {
                    Integer verifyMonth = receipt.VerifyDate__c.month();
                    Integer verifyYear = receipt.VerifyDate__c.year();
                    
                    if (verifyYear < postingYear || (verifyYear == postingYear && verifyMonth <= postingMonth)) {
                        return true;
                    }
                }
            }
            
            return false;
            
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
}