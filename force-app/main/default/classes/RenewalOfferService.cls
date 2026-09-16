/*****************************************************************************************
Class       : RenewalOfferService
Author      : Kalpana
Description : Service Class for Generate Renewal Offer PDF.
Created Date: 03/08/26
*****************************************************************************************/
public with sharing class RenewalOfferService {
    
    
    public static RenewalOfferWrapper getRenewalOffer(
        Id leasingOrderId
    ) {
        
        if (leasingOrderId == null) {
            
            throw new AuraHandledException(
                'Leasing Order Id is required.'
            );
            
        }
        
        
        /*
* Query Leasing Order
*/
        LeasingOrder__c order = [
            
            SELECT
            Id,
            Name,
            
            Account__r.Name,
            
            Project__r.Name,
            Project__r.Location_Name__c,
            
            Unit__r.UnitType__c,
            Unit__r.UnitNumber__c,
            Unit__r.Internal_Saleable_Area_Sq_F__c,
            Unit__r.External_Saleable_Area__c,
            
            LeasingStartDate__c,
            LeasingEndDate__c,
            
            TotalRentAfterDiscount__c,
            
            SecurityDeposit__c,
            
            TOR__c,
            
            RenewalFee__c
            
            FROM LeasingOrder__c
            
            WHERE Id = :leasingOrderId
            
            LIMIT 1
            
        ];
        
        
        /*
* Query Escalation Schedule
*/
        List<LeasingEscalationSchedule__c>
            escalationSchedules = [
                
                SELECT
                Id,
                
                LeasingStartDate__c,
                
                LeasingEndDate__c,
                
                TotalRent__c 
                
                FROM LeasingEscalationSchedule__c
                
                WHERE LeasingOrder__c = :leasingOrderId
                
                ORDER BY LeasingStartDate__c ASC
                
            ];
        
        
        /*
* Query Other Charges
*/
        List<LeasingOrdersOtherCharges__c>
            otherCharges = [
                
                SELECT
                Id,
                
                Type__c,
                
                TotalAmount__c,
                
                DueDate__c
                
                FROM LeasingOrdersOtherCharges__c
                
                WHERE LeasingOrder__c = :leasingOrderId
                
                AND DueDate__c != null
                
            ];
        
        
        RenewalOfferWrapper wrapper =
            new RenewalOfferWrapper();
        
        
        /*
* Populate Header
*/
        populateHeader(
            wrapper,
            order
        );
        
        
        /*
* Populate Base Rent Schedule
*/
        populateBaseRentSchedule(
            wrapper,
            escalationSchedules,
            order.Unit__r
        );
        
        
        /*
* Calculate First Year Charges
*/
        populateOtherCharges(
            wrapper,
            order,
            otherCharges
        );
        
        
        /*
* Other Fields
*/
        wrapper.securityDeposit =
            order.SecurityDeposit__c != null
            ? order.SecurityDeposit__c
            : 0;
        
        
        wrapper.torPercentage =
            order.TOR__c != null
            ? order.TOR__c
            : 0;
        
        
        wrapper.torStartDate =
            order.LeasingStartDate__c;
        
        
        wrapper.torEndDate =
            order.LeasingEndDate__c;
        
        
        wrapper.renewalFee =
            order.RenewalFee__c != null
            ? order.RenewalFee__c
            : 0;
        
        
        return wrapper;
        
    }
    
    
    private static void populateHeader(
        
        RenewalOfferWrapper wrapper,
        
        LeasingOrder__c order
        
    ) {
        
        
        wrapper.todayDate =
            System.today();
        
        
        wrapper.tenantName =
            order.Account__r != null
            ? order.Account__r.Name
            : '';
        
        
        wrapper.developmentName =
            order.Project__r != null
            ? order.Project__r.Name
            : '';
        
        
        wrapper.unitType =
            order.Unit__r != null
            ? order.Unit__r.UnitType__c
            : '';
        
        
        wrapper.unitNumber =
            order.Unit__r != null
            ? order.Unit__r.UnitNumber__c
            : '';
        
        
        wrapper.location =
            order.Project__r.Location_Name__c  != null
            ? order.Project__r.Location_Name__c
            : order.Project__r.Name;
        
        
        wrapper.internalArea =
            order.Unit__r != null
            ? order.Unit__r.Internal_Saleable_Area_Sq_F__c
            : null;
        
        
        wrapper.externalArea =
            order.Unit__r != null
            ? order.Unit__r.External_Saleable_Area__c
            : null;
        
        
        wrapper.renewalDate =
            order.LeasingStartDate__c;
        
        
        wrapper.renewalExpiry =
            order.LeasingEndDate__c;
        
        
        wrapper.currentRentAmount =
            order.TotalRentAfterDiscount__c != null
            ? order.TotalRentAfterDiscount__c
            : 0;
        
        
        wrapper.leaseTerms =
            calculateLeaseTerms(
                order.LeasingStartDate__c,
                order.LeasingEndDate__c
            );
        
    }
    
    
    private static String calculateLeaseTerms(Date startDate, Date endDate) {
    if (startDate == null || endDate == null) {
        return '';
    }

    // Make the end date inclusive
    Date inclusiveEndDate = endDate.addDays(1);

    Integer totalMonths = startDate.monthsBetween(inclusiveEndDate);

    // Adjust if addMonths overshoots
    Date calculatedEndDate = startDate.addMonths(totalMonths);
    if (calculatedEndDate > inclusiveEndDate) {
        totalMonths--;
    }

    Integer years = totalMonths / 12;
    Integer months = Math.mod(totalMonths, 12);

    String result = '';

    if (years > 0) {
        result += years + (years == 1 ? ' year' : ' years');
    }

    if (months > 0) {
        if (!String.isBlank(result)) {
            result += ' ';
        }
        result += months + (months == 1 ? ' month' : ' months');
    }

    // Optional: if duration is less than a month
    if (String.isBlank(result)) {
        result = '0 months';
    }

    return result;
}
    
    
    private static void populateBaseRentSchedule(
        
        RenewalOfferWrapper wrapper,
        
        List<LeasingEscalationSchedule__c>
        escalationSchedules,
        
        Unit__c unit
        
    ) {
        
        
        Decimal internalArea =
            unit != null
            ? unit.Internal_Saleable_Area_Sq_F__c
            : null;
        
        
        Integer periodNumber = 1;
        
        
        for (
            LeasingEscalationSchedule__c schedule
            : escalationSchedules
        ) {
            
            
            RenewalOfferWrapper.BaseRentRow row =
                new RenewalOfferWrapper.BaseRentRow();
            
            
            row.leasePeriod =
                'Lease Period '
                + periodNumber;
            
            
            row.startDate =
                schedule.LeasingStartDate__c;
            
            
            row.endDate =
                schedule.LeasingEndDate__c;
            
            
            row.totalBaseRent =
                schedule.TotalRent__c  != null
                ? schedule.TotalRent__c 
                : 0;
            
            
            if (
                internalArea != null &&
                internalArea != 0 &&
                schedule.TotalRent__c  != null
            ) {
                
                row.baseRentPerSqm =
                    schedule.TotalRent__c 
                    / internalArea;
                
            } else {
                
                row.baseRentPerSqm = 0;
                
            }
            
            
            wrapper.baseRentRows.add(row);
            
            
            periodNumber++;
            
        }
        
    }
    
    
    private static void populateOtherCharges(
        
        RenewalOfferWrapper wrapper,
        
        LeasingOrder__c order,
        
        List<LeasingOrdersOtherCharges__c>
        otherCharges
        
    ) {
        
        
        Date firstYearStart =
            order.LeasingStartDate__c;
        
        
        Date firstYearEnd =
            calculateFirstYearEnd(
                order.LeasingStartDate__c,
                order.LeasingEndDate__c
            );
        
        
        Decimal serviceCharge =
            0;
        
        
        Decimal marketingFund =
            0;
        
        
        Decimal chilledWaterAmount =
            0;
        
        
        Boolean hasChilledWater =
            false;
        
        
        for (
            LeasingOrdersOtherCharges__c charge
            : otherCharges
        ) {
            
            
            if (
                charge.DueDate__c < firstYearStart ||
                charge.DueDate__c > firstYearEnd
            ) {
                
                continue;
                
            }
            
            
            Decimal amount =
                charge.TotalAmount__c != null
                ? charge.TotalAmount__c
                : 0;
            
            
            if (
                charge.Type__c ==
                'Service Charge'
            ) {
                
                serviceCharge += amount;
                
            }
            
            
            else if (
                charge.Type__c ==
                'Marketing Fund'
            ) {
                
                marketingFund += amount;
                
            }
            
            
            else if (
                charge.Type__c ==
                'Chilled Water Charge'
            ) {
                
                chilledWaterAmount += amount;
                
                hasChilledWater = true;
                
            }
            
        }
        
        
        wrapper.serviceChargeAmount =
            serviceCharge;
        
        
        wrapper.marketingFundAmount =
            marketingFund;
        
        
        wrapper.chilledWater =
            hasChilledWater
            ? 'AED '
            + formatAmount(
                chilledWaterAmount
            )
            : 'Metered';
        
        
        if (
            wrapper.internalArea != null &&
            wrapper.internalArea != 0
        ) {
            
            wrapper.serviceChargePerSqm =
                serviceCharge /
                wrapper.internalArea;
            
        } else {
            
            wrapper.serviceChargePerSqm =
                0;
            
        }
        
        
        wrapper.grossRentAmountYear1 =
            wrapper.currentRentAmount
            + wrapper.serviceChargeAmount
            + wrapper.marketingFundAmount;
        
    }
    
    
    private static Date calculateFirstYearEnd(
        
        Date startDate,
        
        Date leaseEndDate
        
    ) {
        
        
        if (startDate == null) {
            
            return null;
            
        }
        
        
        Date firstYearEnd =
            startDate.addYears(1).addDays(-1);
        
        
        if (
            leaseEndDate != null &&
            firstYearEnd > leaseEndDate
        ) {
            
            firstYearEnd =
                leaseEndDate;
            
        }
        
        
        return firstYearEnd;
        
    }
    
    
    private static String formatAmount(
        Decimal amount
    ) {
        
        if (amount == null) {
            
            return '0.00';
            
        }
        
        
        return String.valueOf(
            amount.setScale(2)
        );
        
    }
    
}