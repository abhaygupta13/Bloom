/**
* @File Name : LeasingOfferLetterGenerateController.cls
* @Description : Controller class to Create Leasing Order Records form Opportunity page
* @Author : Bloom Properties
* @Last Modified By :
* @Last Modified On : May 5, 2025
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | May 5, 2025 |   | Initial Version
**/
public with sharing class LeasingOfferLetterGenerateController {
    
    private static final string SYMBOL_MODULUS { get { return '%' ;} } 
    private static final string WORKING_DAYS { get { return 'Working Days'; } } 
    private static final string NO_GRACEPERIOD { get { return 'No Grace Period'; } } 
    private static final string NO_REMARKS{ get { return 'No Remarks'; } }
    private static final string NOT_AVAILABLE{ get { return  'Not Available'; } } 
    private static final string DUBAI{ get { return  'Dubai'; } } 
    private static final string EJARI{ get { return  'Ejari'; } } 
    private static final string TAWTHEEQ{ get { return  'Tawtheeq'; } } 
    private static final string APPROVED{ get { return  'Approved'; } } 
    private static final string OFFER_LETTER{ get { return  'Offer Letter'; } } 
    private static final string DRAFT_OFFER_LETTER{ get { return  'Draft Offer Letter'; } } 
    private static final string COMMERCIAL{ get { return  'Commercial'; } }
    private static final string RESIDENTIAL{ get { return  'Residential'; } }    
    private static final string EXTRA_CHEQUE_FEE { get { return  'Extra Cheque Fee'; } }
    private static final string FEE { get { return  'Fee'; } } 
    
    private static final string VAT_LABEL { get { return  'VAT'; } } 
    private static final string NA { get { return  'NA'; } }
    private static final string EJARI_TAWTHEEQ_FEE { get { return  'Ejari/Tawtheeq Fee'; } }
    private static final string ADMIN_FEE { get { return  'Admin Fee'; } }
    
    public LeasingOrder__c leaseContract { get; set; }
    public Opportunity opp { get; set; }
    public String OfferDate { get; set; }
    public String AnnualRent { get; set; }
    public String SecurityDeposit { get; set; }
    public String AdminFee { get; set; }
    public String termofPayment { get; set; }
    public String contractTerm { get; set; }
    public String unitNumber { get; set; }
    public String customerType { get; set; }
    public String unitType { get; set; }
    public String gracePeriod { get; set; }
    public String leasingStartDate { get; set; }
    public String leasingEndDate { get; set; }
    public Boolean isMultiyearContract { get; set; }
    public String remarks { get; set; }
    public String ownerEmailAddress { get; set; }
    public String ownerPhoneNumber { get; set; }
    public String offerValidity { get; set; }
    public String noOfCarParking { get; set; }
    public String projectMuncipality { get; set; }
    public String offerLetterTitle { get; set; }
    public String annualRentpersqm { get; set; }
    public String annualRentWithOutVAT { get; set; }
    public String annualRentVAT { get; set; }
    public String totalRentWithVAT { get; set; }
    public String noOfPayments { get; set; }
    public String corporateCompanyName { get; set; }
    public String corporateContactName { get; set; }
    public String accountType {get; set;}
    public String leasingCompanyName {get; set;}
    public String vatPercentageStr {get; set;}
    public String totalRentWithVATVar {get; set;} 
    public String securityDepositPercentageVar {get; set;}
    public String rentSystem {get; set;}
    public Integer totalAnnualRentPayments {get; set;}
    public String pageBottomNumberMessage {get; set;}
    
    
    public Map<String, List<LeasingPaymentScheduleWrapper>> paymentsByYear { get; set; }
    
    public LeasingOfferLetterGenerateController(ApexPages.StandardController controller) {
        System.debug('77 LeasingOfferLetterGenerateController init StandardController :- ' + controller.getId());
        this.leaseContract = (LeasingOrder__c) controller.getRecord();
        if (leaseContract != null) {
            LeasingOrderService leasingOrderService = LeasingOrderService.getInstance();
            this.leaseContract =leasingOrderService.getLeasingOrderById(this.leaseContract.Id);
            System.debug('83 LeasingOfferLetterGenerateController leaseContract :- ' + this.leaseContract.Id + ' ' + this.leaseContract.Name + ' months ' + leaseContract.LeasingContractMonths__c);
            OfferDate = System.today().format(); // Format the current date 
            isMultiyearContract = leaseContract.LeasingContractMonths__c > 12 ? true : false ;
            Decimal vatPercentage = leaseContract.Unit__r?.Project__r?.Leasing_Company__r?.LeasingVAT__c ?? 0.0 ;
            if (vatPercentage != null && vatPercentage.scale() > 0 && vatPercentage.stripTrailingZeros().scale() > 0) {
                // Has decimal places
                vatPercentageStr = vatPercentage + SYMBOL_MODULUS;
            } else {
                // No decimal part (whole number)
                vatPercentageStr = String.valueOf(vatPercentage?.intValue()) + SYMBOL_MODULUS;
            }
            
            Decimal securityDepositPercentage = leaseContract.Unit__r.Project__r.SecurityDeposit__c ;
            if (securityDepositPercentage.scale() > 0 && securityDepositPercentage.stripTrailingZeros().scale() > 0) {
                // Has decimal places
                securityDepositPercentageVar = securityDepositPercentage + SYMBOL_MODULUS;
            } else {
                // No decimal part (whole number)
                securityDepositPercentageVar = String.valueOf(securityDepositPercentage.intValue()) + SYMBOL_MODULUS;
            }
            
            leasingCompanyName = leaseContract.Unit__r?.Project__r?.Leasing_Company__r?.Name ;
            // Fetch related Opportunity
            if (leaseContract.Opportunity__c != null) {
                offerValidity = leaseContract.OfferValidityDays__c +' '+WORKING_DAYS;
                
                OpportunityService oppService = OpportunityService.getInstance();
                opp = oppService.getOpportunityById(leaseContract.Opportunity__c);
                
                ContactService conService = ContactService.getInstance();
                Contact con = conService.getContactByAccountId(opp.AccountId)[0];
                corporateCompanyName = opp.Account.Name ;
                corporateContactName = con.Name;
                accountType = opp.Account.Recordtype.DeveloperName ;
                System.debug('105 LeasingOfferLetterGenerateController opp :- ' + leaseContract.Opportunity__c + ' AccountType: ' + accountType);
                Decimal appliedAnnualRenPersqm = leaseContract.RentalAmountAfterDiscount__c/leaseContract.Unit__r?.LeasingUnitSizesqm__c ;
                annualRentpersqm = leaseContract.CurrencyIsoCode +' '+ formatDecimalWithCommas(appliedAnnualRenPersqm) ;
                SecurityDeposit = leaseContract.CurrencyIsoCode +' '+ formatDecimalWithCommas(leaseContract.SecurityDeposit__c) ; 

              //  SecurityDeposit = leaseContract.CurrencyIsoCode +' '+ formatDecimalWithCommas(leaseContract.SecurityDeposit__c != null ? leaseContract.SecurityDeposit__c : 0 ) ; 
                Decimal adminFeewithVat = leaseContract.AdminFee__c + (leaseContract.AdminFee__c*vatPercentage)/100 ;
                System.debug('122 LeasingOfferLetterGenerateController adminFeewithVat :- ' + adminFeewithVat);
                AdminFee = leaseContract.CurrencyIsoCode +' '+formatDecimalWithCommas(leaseContract.AdminFee__c)+' + '+
                     leaseContract.CurrencyIsoCode +' '+formatDecimalWithCommas( (leaseContract.AdminFee__c*vatPercentage)/100)+ ' = '+leaseContract.CurrencyIsoCode +' '+formatDecimalWithCommas(adminFeewithVat) ;
                
                annualRentWithOutVAT =leaseContract.CurrencyIsoCode +' '+ formatDecimalWithCommas(leaseContract.RentalAmountAfterDiscount__c) ; 
                annualRentVAT =leaseContract.CurrencyIsoCode +' '+ formatDecimalWithCommas(leaseContract.AnnualRentVATAmount__c) ; 
                
                if(isMultiyearContract){
                    totalRentWithVAT =leaseContract.CurrencyIsoCode +' '+formatDecimalWithCommas(leaseContract.TotalRentAfterDiscount__c) ;
                }else{
                    totalRentWithVAT =leaseContract.CurrencyIsoCode +' '+ formatDecimalWithCommas(leaseContract.TotalAnnualRentwithVAT__c) ; //String.valueOf(leaseContract.AnnualRent__c.setScale(2).format());
                }
                
                totalRentWithVATVar = annualRentWithOutVAT +' + '+annualRentVAT +' = ' + totalRentWithVAT ;
                contractTerm = String.ValueOf(leaseContract.LeasingContractMonths__c);
                termofPayment = leaseContract.PaymentTerm__c;
                Integer paymentsPerYear = Integer.valueOf(leaseContract.PaymentTerm__c.substringBefore(' '));
                noOfPayments = String.valueOf(paymentsPerYear);
                unitNumber = leaseContract.Unit__r.Name;
                customerType = leaseContract.Unit__r.PropertyUsage__c ;
                unitType = customerType.toLowerCase();
                gracePeriod = (leaseContract.GracePeriod__c == 0 || String.isEmpty(String.ValueOf(leaseContract.GracePeriod__c)))
                    ?  NO_GRACEPERIOD : String.ValueOf(leaseContract.GracePeriod__c) ;
                
                Date lsStart = leaseContract.LeasingStartDate__c;
                leasingStartDate = DateTime.newInstance(lsStart, Time.newInstance(0, 0, 0, 0))
                    .format('dd-MM-yyyy');
                
                Date lsEnd = leaseContract.LeasingEndDate__c;
                leasingEndDate = DateTime.newInstance(lsEnd, Time.newInstance(0, 0, 0, 0))
                    .format('dd-MM-yyyy');
                
                
                
                remarks = leaseContract.Remarks__c ?? NO_REMARKS ;
                ownerEmailAddress = leaseContract.Owner.Email ;
                ownerPhoneNumber = leaseContract.Owner.Phone ;
                noOfCarParking = String.ValueOF(leaseContract.Unit__r.NumberOfCarParks__c) ?? NOT_AVAILABLE;
                projectMuncipality = leaseContract.Unit__r?.Project__r?.city__c ;
                
                rentSystem =  projectMuncipality == DUBAI ? EJARI : TAWTHEEQ ; 
                
                offerLetterTitle =  (leaseContract.BloomTeamApprovalStatus__c == APPROVED && 
                                     leaseContract.CustomerApprovalStatus__c == APPROVED ) ? OFFER_LETTER : OFFER_LETTER;//? OFFER_LETTER : DRAFT_OFFER_LETTER;                  
                List<PaymentPlanSchedule__c> listpaymentScheules = [SELECT Year__c, Amount__c ,Name,Escalation__c,TotalInstallmentAmount__c,
                                                                    PaymentStartDate__c,VATAmount__c FROM PaymentPlanSchedule__c
                                                                    WHERE LeasingOrder__c = :leaseContract.Id ORDER BY Year__c];
                totalAnnualRentPayments = listpaymentScheules?.size() ?? 0;
                String customerTypeChar = leaseContract.Unit__r.PropertyUsage__c == 'residential' ? 'R' : 'C';
                pageBottomNumberMessage = generateSRNumber(leaseContract);//'SR: '+String.valueOf(Date.today().year()) +'/'+customerTypeChar+'/'+unitNumber+'/000';
                
                List<LeasingPaymentScheduleWrapper> allPayments = new List<LeasingPaymentScheduleWrapper>();
                paymentsByYear = new Map<String, List<LeasingPaymentScheduleWrapper>>();
                for(PaymentPlanSchedule__c ps : listpaymentScheules){
                    DateTime psStartDateDateTime = DateTime.newInstance(ps.PaymentStartDate__c, Time.newInstance(0, 0, 0, 0));
                    // String formattedDate = psStartDateDateTime.format('dd-MM-yyyy', 'GMT');
                    String formattedDate = psStartDateDateTime.format('dd-MM-yyyy');
                    // formattedDate = ps.Name == 'Year 1 - Payment 1' ? 'Current Dated' : formattedDate ;
                    formattedDate = ps.Name == 'Year 1 - Payment 1' && ps.PaymentStartDate__c ==  this.leaseContract.LeasingStartDate__c ? 'Current Dated' : formattedDate ;
                    if(customerType == COMMERCIAL){
                        allPayments.add(new LeasingPaymentScheduleWrapper(String.valueOf(ps.Year__c), leaseContract.CurrencyIsoCode +' '+formatDecimalWithCommas(ps.Amount__c) ,
                                                                          ps.Name,String.valueOf(ps.Escalation__c),
                                                                          formattedDate,leaseContract.CurrencyIsoCode +' '+formatDecimalWithCommas(ps.VATAmount__c),leaseContract.CurrencyIsoCode +' '+formatDecimalWithCommas(ps.TotalInstallmentAmount__c))
                                       );
                    }else{
                        allPayments.add(new LeasingPaymentScheduleWrapper(String.valueOf(ps.Year__c), leaseContract.CurrencyIsoCode +' '+formatDecimalWithCommas(ps.Amount__c) ,
                                                                          ps.Name,String.valueOf(ps.Escalation__c),
                                                                          formattedDate,NA,leaseContract.CurrencyIsoCode +' '+formatDecimalWithCommas(ps.TotalInstallmentAmount__c))
                                       );  
                    }
                    
                }
                // Group payments by year
                for (LeasingPaymentScheduleWrapper p : allPayments) {
                    if (!paymentsByYear.containsKey(String.valueOf(p.year))) {
                        paymentsByYear.put(String.valueOf(p.year), new List<LeasingPaymentScheduleWrapper>());
                    }
                    paymentsByYear.get(String.valueOf(p.year)).add(p);
                }
            }
        }
    }
    
    public List<LeasingEscalationSchedule__c> getSplits() {
        LeasingEscalationScheduleService escService = LeasingEscalationScheduleService.getInstance();
        return escService.getEscalationSchedulesByContractId(leaseContract.Id);
    }
    
    public List<PaymentPlanSchedule__c> getPaymentSchedules(){
        LeasingPaymentScheduleService paymentservice = LeasingPaymentScheduleService.getInstance();
        return paymentservice.getPaymentSchedulesByLeasingOrderId(leaseContract.Id);
    }    
    
    public List<LeasingOtherChargesWrapper> getServiceCharges() {
        LeasingOtherChargesService otherChrgeService = LeasingOtherChargesService.getInstance();
        List<LeasingOtherChargesWrapper> scList = new List<LeasingOtherChargesWrapper>();
        for(LeasingOrdersOtherCharges__c pp : otherChrgeService.getOtherChargesByLeasingOrderId(leaseContract.Id))
        {
            String  vatAmount  = ( (pp.Type__c == ADMIN_FEE) || (pp.Type__c == EXTRA_CHEQUE_FEE) )  ?  leaseContract.CurrencyIsoCode +' '+formatDecimalWithCommas(pp.VATAmount__c) : NA ;
            
            String totalAmount =  leaseContract.CurrencyIsoCode +' '+formatDecimalWithCommas(pp.TotalAmount__c)  ;
            String chargeTypeVar =  '';
            String amountExpressionVar =  '';
            if(pp.LeasingOrder__r.Unit__r.PropertyUsage__c == RESIDENTIAL && pp.Type__c == ADMIN_FEE){
                Decimal vat = pp.LeasingOrder__r?.Unit__r?.Project__r?.Leasing_Company__r?.LeasingVAT__c;
                if (vat != null) {
                    chargeTypeVar = ADMIN_FEE + ' + ' + VAT_LABEL  +'\n(' + vat.setScale(0) + SYMBOL_MODULUS+')';
                } else {
                    chargeTypeVar = ADMIN_FEE+' + '+VAT_LABEL  +SYMBOL_MODULUS;
                }       
                amountExpressionVar = leaseContract.CurrencyIsoCode +' '+formatDecimalWithCommas(pp.ChargeAmount__c)+' + '+leaseContract.CurrencyIsoCode +' '+formatDecimalWithCommas(pp.VATAmount__c)+' = '+leaseContract.CurrencyIsoCode +' '+formatDecimalWithCommas(pp.TotalAmount__c);
                LeasingOtherChargesWrapper sce = new LeasingOtherChargesWrapper( chargeTypeVar ,
                                                                                leaseContract.CurrencyIsoCode +' '+formatDecimalWithCommas(pp.ChargeAmount__c),
                                                                                vatAmount ,amountExpressionVar);
                scList.add(sce); 
            }else if(pp.LeasingOrder__r.Unit__r.PropertyUsage__c == RESIDENTIAL && pp.Type__c == EXTRA_CHEQUE_FEE){
                chargeTypeVar = EXTRA_CHEQUE_FEE+' ' + VAT_LABEL  ;
                amountExpressionVar = leaseContract.CurrencyIsoCode +' '+formatDecimalWithCommas(pp.ChargeAmount__c)+'+ '+leaseContract.CurrencyIsoCode +' '+formatDecimalWithCommas(pp.VATAmount__c)+'= '+leaseContract.CurrencyIsoCode +' '+formatDecimalWithCommas(pp.TotalAmount__c);
                
                LeasingOtherChargesWrapper sce = new LeasingOtherChargesWrapper( chargeTypeVar ,
                                                                                leaseContract.CurrencyIsoCode +' '+formatDecimalWithCommas(pp.ChargeAmount__c),
                                                                                vatAmount ,amountExpressionVar);
                scList.add(sce); 
            }else if(pp.Type__c == EJARI_TAWTHEEQ_FEE){
                String typeName = pp.LeasingOrder__r.Unit__r.Project__r.city__c == DUBAI ? EJARI+' '+FEE : TAWTHEEQ+' '+FEE;
                LeasingOtherChargesWrapper sce = new LeasingOtherChargesWrapper( typeName ,
                                                                                leaseContract.CurrencyIsoCode +' '+formatDecimalWithCommas(pp.ChargeAmount__c),
                                                                                vatAmount ,totalAmount);
                scList.add(sce); 
            }
            else {
                LeasingOtherChargesWrapper sce = new LeasingOtherChargesWrapper( pp.Type__c ,
                                                                                leaseContract.CurrencyIsoCode +' '+formatDecimalWithCommas(pp.ChargeAmount__c),
                                                                                vatAmount ,totalAmount);
                scList.add(sce); 
            }
            
            
        }
        return scList ;
    } 
    public class LeasingOtherChargesWrapper{
        public String chargeType { get; set; }
        public String amount { get; set; }
        public String VATamount { get; set; }
        public String totalAmount { get; set; }
        public LeasingOtherChargesWrapper(String chargeType , String amount,String VATamount , String totalAmount ){
            this.chargeType = chargeType;
            this.amount = amount ;
            this.VATamount = VATamount ;
            this.totalAmount = totalAmount ;
        } 
    }
    public static String formatDecimalWithCommas(Decimal decimalInput) {
        // Round to 2 decimal places
        Decimal rounded = decimalInput.setScale(2, RoundingMode.HALF_UP);
        
        // Split integer and decimal parts
        String[] parts = String.valueOf(rounded).split('\\.');
        String intPart = parts[0];
        String decPart = parts.size() > 1 ? parts[1] : '00';
        
        // Add commas to the integer part
        String result = '';
        Integer len = intPart.length();
        Integer count = 0;
        
        for (Integer i = len - 1; i >= 0; i--) {
            result = intPart.substring(i, i+1) + result;
            count++;
            if (Math.mod(count, 3) == 0 && i > 0) {
                result = ',' + result;
            }
        }
        
        // Ensure exactly two decimal digits
        if (decPart.length() == 1) {
            decPart += '0';
        }
        
        return result + '.' + decPart;
    }
     public static String generateSRNumber(LeasingOrder__c leasingOrder) {
        if (leasingOrder == null) return null;
       
         // --- 1️⃣ Extract needed fields ---
        String leaseTypeChar = leasingOrder.LeaseType__c == 'Renewal' ? 'R' : 'N';
        String sapCompanyCode = leasingOrder.Project__r?.Leasing_Company__r?.LeasingSAPCompanyCode__c != null ? String.valueOf(leasingOrder.Project__r.Leasing_Company__r.LeasingSAPCompanyCode__c) : '';
       // --- 2️⃣ Get last 5 digits of LeasingOrderNumber__c ---
        String orderNumStr = String.isNotBlank(leasingOrder.LeasingOrderNumber__c) ? leasingOrder.LeasingOrderNumber__c : (leasingOrder.Name != null ? leasingOrder.Name : '');
        String digitsOnly = orderNumStr.replaceAll('\\D', '');
        String last5Digits = '';
        if (String.isNotBlank(digitsOnly)) {
            last5Digits = digitsOnly.length() >= 5 ? digitsOnly.substring(digitsOnly.length() - 5) : digitsOnly.leftPad(5, '0');
        } else {
            last5Digits = orderNumStr.length() >= 5 ? orderNumStr.right(5) : orderNumStr.leftPad(5, '0');
        }
        // --- 3️⃣ Assemble final SR Number using Lease Start Date year ---
        Integer srYear = leasingOrder.LeasingStartDate__c != null 
            ? leasingOrder.LeasingStartDate__c.year() 
            : (leasingOrder.CreatedDate != null ? leasingOrder.CreatedDate.year() : Date.today().year());
        String srNumber = 'SR: ' + 
            String.valueOf(srYear) + '/' + 
            leaseTypeChar + '/' + 
            sapCompanyCode + '/' + 
            last5Digits;
        return srNumber;
    }
    public class LeasingPaymentScheduleWrapper {
        public String year { get; set; }
        public String amount { get; set; }
        public String name { get; set; }
        public String escPercent { get; set; }
        public String VATamount { get; set; }
        public String totalAmount { get; set; }
        public String paymentStartDate { get; set; }
        public LeasingPaymentScheduleWrapper(String year , String amount , String name,
                                             String escPercent,String paymentStartDate,
                                             String VATamount , String totalAmount )
        {
            this.year = year ;
            this.amount = amount ;
            this.name = name ;
            this.escPercent = escPercent ;
            this.paymentStartDate = paymentStartDate ;
            this.VATamount = VATamount ;
            this.totalAmount = totalAmount ;
        } 
    }    
}