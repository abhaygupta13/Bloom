public with sharing class RefundCalculationService {
    
    private static final Set<String> BREAK_LEASE_TYPES = new Set<String>{
        'Break Lease fees',
            'Brk Lease pnlt (2M C',
            'Brk Leas ptly (2M Rs'
            };
                
                private static final String MAINTENANCE_CHARGE_TYPE = 'CheckoutDamage Recovery Charge';
    
    /**
* Calculate additional days between Termination Date and Lease End Date.
*/
    public static Integer calculateAdditionalDays(Date leaseEndDate, Date terminationDate) {
        
        if (leaseEndDate == null || terminationDate == null) {
            return 0;
        }
        
        // Only applicable when tenant vacates before lease end
        if (terminationDate >= leaseEndDate) {
            return 0;
        }
        
        return terminationDate.daysBetween(leaseEndDate);
    }
    
    /**
* Calculate actual lease duration (inclusive).
* Example:
* 01-Jan-2024 to 31-Dec-2024 = 366
* 01-Jul-2024 to 30-Jun-2025 = 365
*/
    public static Integer getLeaseDuration(Date leaseStartDate, Date leaseEndDate) {
        
        if (leaseStartDate == null || leaseEndDate == null) {
            return 365;
        }
        
        Integer duration = leaseStartDate.daysBetween(leaseEndDate) + 1;
        
        return duration > 0 ? duration : 365;
    }
    
    /**
* Calculate Daily Rent
*/
    public static Decimal calculateDailyRent(
        Decimal annualRent,
        Date leaseStartDate,
        Date leaseEndDate
    ) {
        
        if (annualRent == null || annualRent == 0) {
            return 0;
        }
        
        Integer leaseDuration = getLeaseDuration(leaseStartDate, leaseEndDate);
        
        return annualRent.divide(leaseDuration, 6);
    }
    
    /**
* Value of Days = Daily Rent × Additional Days
*/
    public static Decimal calculateValueOfDays(
        Decimal annualRent,
        Date leaseStartDate,
        Date leaseEndDate,
        Integer additionalDays
    ) {
        
        if (additionalDays == null || additionalDays <= 0) {
            return 0;
        }
        
        Decimal dailyRent = calculateDailyRent(
            annualRent,
            leaseStartDate,
            leaseEndDate
        );
        
        return (dailyRent * additionalDays).setScale(2);
    }
    
    /**
* Break Lease Charges
*/
    public static Decimal calculateBreakLeaseCharges(
        List<LeasingOrdersOtherCharges__c> charges
    ) {
        
        Decimal total = 0;
        
        if (charges == null) {
            return total;
        }
        
        for (LeasingOrdersOtherCharges__c charge : charges) {
            
            if (charge.TotalAmount__c == null) {
                continue;
            }
            
            if (BREAK_LEASE_TYPES.contains(charge.Type__c)) {
                total += charge.TotalAmount__c;
            }
        }
        
        return total.setScale(2);
    }
    
    /**
* Maintenance Charges
*/
    public static Decimal calculateMaintenanceCharges(
        List<LeasingOrdersOtherCharges__c> charges
    ) {
        
        Decimal total = 0;
        
        if (charges == null) {
            return total;
        }
        
        for (LeasingOrdersOtherCharges__c charge : charges) {
            
            if (charge.TotalAmount__c == null) {
                continue;
            }
            
            if (charge.Type__c == MAINTENANCE_CHARGE_TYPE) {
                total += charge.TotalAmount__c;
            }
        }
        
        return total.setScale(2);
    }
    
    public static Decimal calculateDueAmount(
        Decimal valueOfDays,
        Decimal breakLeasePenalty,
        Decimal balancePayment,
        Decimal adminFees,
        Decimal maintenanceCharges,
        Decimal securityDeposit
    ) {
        
        Decimal total =
            nvl(valueOfDays)
            + nvl(breakLeasePenalty)
            + nvl(balancePayment)
            + nvl(adminFees)
            + nvl(maintenanceCharges)
            + nvl(securityDeposit);
        
        return total.setScale(2);
    }
    
    private static Decimal nvl(Decimal value) {
        return value == null ? 0 : value;
    }
    
    public static Decimal calculatePDCTotal(
        List<LeasingReceiptAcknowledgment__c> receipts,
        Date terminationDate
    ){
        
        Decimal total=0;
        
        if(receipts==null){
            return total;
        }
        
        for(LeasingReceiptAcknowledgment__c receipt:receipts){
            
            if(receipt.ChequeDate__c!=null
               && receipt.ChequeDate__c>terminationDate
               && receipt.Amount__c!=null){
                   
                   total+=receipt.Amount__c;
                   
               }
            
        }
        
        return total.setScale(2);
        
    }
    
    public static Decimal calculateDueAmountAfterPOCAdj(
        Decimal dueAmount,
        Decimal totalPDCReturn
    ){
        return (nvl(dueAmount) - nvl(totalPDCReturn)).setScale(2);
    }
}