/*****************************************************************************************
Class       : RenewalOfferWrapper
Author      : Kalpana
Description : Wrapper for Generate Renewal Offer PDF.
Created Date: 03/08/26
*****************************************************************************************/
public class RenewalOfferWrapper {

    /*
     * Header Details
     */
    public Date todayDate { get; set; }

    public String tenantName { get; set; }

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


    /*
     * Base Rent Schedule
     */
    public List<BaseRentRow> baseRentRows { get; set; }


    /*
     * Charges
     */
    public Decimal serviceChargeAmount { get; set; }

    public Decimal serviceChargePerSqm { get; set; }

    public Decimal marketingFundAmount { get; set; }

    public Decimal grossRentAmountYear1 { get; set; }

    public String chilledWater { get; set; }


    /*
     * Other Details
     */
    public Decimal securityDeposit { get; set; }

    public Decimal torPercentage { get; set; }

    public Date torStartDate { get; set; }

    public Date torEndDate { get; set; }

    public Decimal renewalFee { get; set; }


    public RenewalOfferWrapper() {

        baseRentRows =
            new List<BaseRentRow>();

        todayDate =
            System.today();

        location =
            'Al Bateen – Abu Dhabi';

        serviceChargeAmount =
            0;

        serviceChargePerSqm =
            0;

        marketingFundAmount =
            0;

        grossRentAmountYear1 =
            0;

        securityDeposit =
            0;

        torPercentage =
            0;

        renewalFee =
            0;

        chilledWater =
            'Metered';

    }


    public class BaseRentRow {

        public String leasePeriod { get; set; }

        public Date startDate { get; set; }

        public Date endDate { get; set; }

        public Decimal baseRentPerSqm { get; set; }

        public Decimal totalBaseRent { get; set; }

    }

}