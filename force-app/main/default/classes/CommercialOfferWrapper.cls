public class CommercialOfferWrapper {
    
    public Date todayDate { get; set; }
    public String tenantFullName { get; set; }
    public String tenantFirstName { get; set; }

    public String developmentName { get; set; }
    public String unitType { get; set; }
    public String unitNumber { get; set; }
    public String location { get; set; }
    public Decimal internalArea { get; set; }
    public Decimal externalArea { get; set; }
    public String leaseTerms { get; set; }
    public Date renewalDate { get; set; }
    public Date renewalExpiry { get; set; }
    public Decimal currentRentAmount { get; set; }
    public List<BaseRentRow> baseRentRows { get; set; }
    public Decimal serviceChargeAmount { get; set; }
    public Decimal serviceChargePerSqm { get; set; }
    public Decimal marketingFundAmount { get; set; }
    public Decimal grossRentAmountYear1 { get; set; }
    public String chilledWater { get; set; }
    public Decimal securityDeposit { get; set; }
    public Decimal torPercentage { get; set; }
    public Date torStartDate { get; set; }
    public Date torEndDate { get; set; }
    public Decimal renewalFee { get; set; }

    // ===== Renewal Offer Fees & Details =====
    public Decimal adminFee { get; set; }
    public Decimal designReviewFee { get; set; }
    public Decimal fitOutSecurity{get;set;}
    public Integer fitOutPeriod { get; set; }
    public String contractPeriod { get; set; }
    public Date handoverDate { get; set; }
    public Date rentCommencementDate { get; set; }
    public Date leaseExpiry { get; set; }
    public String permittedUse { get; set; }
    public String termOfPayment { get; set; }
    
    
    public CommercialOfferWrapper() {
        baseRentRows = new List<BaseRentRow>();
        
        todayDate = System.today();
        location = 'Al Bateen – Abu Dhabi';
        
        serviceChargeAmount = 0;
        serviceChargePerSqm = 0;
        marketingFundAmount = 0;
        grossRentAmountYear1 = 0;
        securityDeposit = 0;
        torPercentage = 0;
        renewalFee = 0;
        
        adminFee = 0;
        designReviewFee = 0;
        fitOutPeriod = 0;
        fitOutSecurity = 0;
        
        chilledWater = 'Metered';
    }
    
    
    public class BaseRentRow {
        
        public String leasePeriod { get; set; }
        public Date startDate { get; set; }
        public Date endDate { get; set; }
        public Decimal baseRentPerSqm { get; set; }
        public Decimal totalBaseRent { get; set; }
    }
}