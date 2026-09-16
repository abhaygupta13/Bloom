/*****************************************************************************************
Class       : LatePaymentFeeBatch
Author      : Dhanraj Poojary
Description : Batch to create Late Payment Fee Record if Installment Amount is pending after Due Date
Test Class  : LatePaymentFeeBatchTest
Created Date: 02 JAN 2025 
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.     Version              Date                Details
1.          V1.0              25/08/25           Initial Version 
2.			V1.1			  31/07/26		Updated logic to include records beyond the start date set at project level
****************************************************************************************************************/
public class LatePaymentFeeBatch implements Database.Batchable<sObject>, Schedulable{
    
    private static final string MTD_SALES_ORDER_STATUS_VALUE { get { return 'SalesOrderStatusforPendingPayment'; } }
    private static final string MTD_LPF_CALCULATION_DAYS { get { return 'LatePaymentFeeCalculationDays'; } }
    private static final string TYPE_OF_CHARGE { get { return 'Late Payment Charges'; } }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id,Name,EnableLatePaymentFee__c,DailyLPFPercentage__c FROM Project__c WHERE EnableLatePaymentFee__c = TRUE AND LatePaymentFeeCalculationStartDate__c != NULL';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Project__c> scope){
        System.debug('scope'+scope);
        MetadataService objMetadataService = MetadataService.getInstance();
        LatePaymentFeeService latePaymentService = LatePaymentFeeService.getInstance();
        SalesOrderOtherChargesService salesOrderOtherChargeService = SalesOrderOtherChargesService.getInstance();
        InstallmentLineService installmentLineService = InstallmentLineService.getInstance();
        String salesOrderStatusValue = objMetadataService.getAppSettingTextValue(MTD_SALES_ORDER_STATUS_VALUE);
        List<String> salesOrderStatusValueList = salesOrderStatusValue.split(',');
        Integer lpfCalculationDays = objMetadataService.getAppSettingNumberValue(MTD_LPF_CALCULATION_DAYS);
        List<LatePaymentFee__c> latePaymentFeeList = new List<LatePaymentFee__c>();
        Map<Id,SalesOrderOtherCharges__c> mapExistingSOCharges = new Map<Id,SalesOrderOtherCharges__c>();
        List<SalesOrderOtherCharges__c> lstSOCharges = new List<SalesOrderOtherCharges__c>();
        List<InstallmentLines__c> installmentList = new List<InstallmentLines__c>();
        List<InstallmentLines__c> installmentLinesToUpdate = new List<InstallmentLines__c>();
        Set<Id> setUpdatedInstallment = new Set<Id>();
        Map<Id,Date> startDateByInstallment = new Map<Id,Date>();
        Map<Id, Decimal> totalFeeByInstallment = new Map<Id, Decimal>();
        Map<Id, Id> installmentToSOChargeId = new Map<Id, Id>();
        Map<Id, Project__c> projectMap = new Map<Id, Project__c>(scope);
        Date currentDate = Date.today();
        
        List<InstallmentLines__c> lstInstallmentLines = installmentLineService.getInstallmentLinesByProject(projectMap.keySet(),salesOrderStatusValueList);

        for (InstallmentLines__c pi : lstInstallmentLines) {
            Date lastLPFDate = pi.LastLPFCreatedDate__c;
            Date calculationStartDate;
            Date dueDate = pi.Due_Date__c;
            Integer gracePeriodDays = 0;
            Boolean shouldCalculateLPF = false;
            Date projectLPFStartDate = pi.SalesOrder__r.Unit__r.Project__r.LatePaymentFeeCalculationStartDate__c;
            Decimal lpfThresholdAmount = pi.SalesOrder__r.Unit__r.Project__r.LPFThresholdAmount__c;
            
            if (lpfThresholdAmount != null && (pi.PendingAmount__c == null || pi.PendingAmount__c < lpfThresholdAmount)) {
                continue;
            }
            
            if (pi.Type__c == 'Handover') {
                gracePeriodDays = pi.SalesOrder__r.Unit__r.Project__r.HandoverLPFGracePeriod__c != null ? 
                    Integer.valueOf(pi.SalesOrder__r.Unit__r.Project__r.HandoverLPFGracePeriod__c) : 0;
            } else if(pi.Type__c == 'Installment'){
                gracePeriodDays = pi.SalesOrder__r.Unit__r.Project__r.InstallmentLPFGracePeriod__c != null ? 
                    Integer.valueOf(pi.SalesOrder__r.Unit__r.Project__r.InstallmentLPFGracePeriod__c) : 0;
            }
            
            if (lastLPFDate == null) {
                // Existing overdue installments before LPF activation
                if (dueDate < projectLPFStartDate) {
                    calculationStartDate = projectLPFStartDate;
                    if (currentDate >= calculationStartDate) {
                        shouldCalculateLPF = true;
                    }
                }
                else {
                    // Existing flow for installments due after LPF activation
                    Date graceEndDate = dueDate.addDays(gracePeriodDays + 1);
                    if (currentDate >= graceEndDate) {
                        calculationStartDate = dueDate.addDays(1);
                        shouldCalculateLPF = true;
                    }
                }
                
            }
            else {
                calculationStartDate = lastLPFDate.addDays(1);
                shouldCalculateLPF = currentDate >= calculationStartDate ? true : false;
            }
            
            if (shouldCalculateLPF) {
                Integer daysToCharge = calculationStartDate.daysBetween(currentDate) + 1; // Include current date
                Decimal dailyLPFPercent = pi.SalesOrder__r.Unit__r.Project__r.DailyLPFPercentage__c;
                
                // Skip calculation if Daily LPF Percentage is not configured
                if (dailyLPFPercent == null || dailyLPFPercent <= 0) {
                    continue;
                }
                Decimal fee = pi.PendingAmount__c * (dailyLPFPercent / 100) * daysToCharge;
                fee = fee.setScale(3, RoundingMode.HALF_UP);
                LatePaymentFee__c objLatePaymentFee = new LatePaymentFee__c(
                    DueAmount__c = pi.PendingAmount__c, DueDate__c = pi.Due_Date__c,
                    InstallmentLine__c = pi.Id, LatePaymentFeePercentage__c = dailyLPFPercent,
                    StartDate__c = calculationStartDate, EndDate__c = currentDate, Fee__c = fee);
                
                totalFeeByInstallment.put(pi.Id, (totalFeeByInstallment.get(pi.Id) ?? 0) + fee);
                latePaymentFeeList.add(objLatePaymentFee);
                setUpdatedInstallment.add(pi.Id);
                startDateByInstallment.put(pi.Id,calculationStartDate);
                installmentList.add(pi);
                installmentLinesToUpdate.add(new InstallmentLines__c(Id = pi.Id, LastLPFCreatedDate__c = currentDate));
            }   
        }
        
        for (SalesOrderOtherCharges__c objSOC : salesOrderOtherChargeService.getSalesOrderChargesByInstallment(setUpdatedInstallment, TYPE_OF_CHARGE)) {
            mapExistingSOCharges.put(objSOC.Installment_Line__c, objSOC);
        } 
        
        for (InstallmentLines__c pi : installmentList) { 
            Decimal totalFee = totalFeeByInstallment.get(pi.Id);
            SalesOrderOtherCharges__c soc = mapExistingSOCharges.get(pi.Id);
            
            if (soc == null) {
                soc = new SalesOrderOtherCharges__c(
                    Installment_Line__c = pi.Id,
                    StartDate__c = startDateByInstallment.get(pi.Id),
                    TypeOfCharge__c = 'Late Payment Charges',
                    Account__c = pi.SalesOrder__r.Account__c,
                    SalesOrder__c = pi.SalesOrder__c,
                    SAP_Condition_Type__c = pi.SalesOrder__r.Unit__r.Project__r.LPFSAPConditionCode__c ?? ''
                );
            }
            Decimal existingFee = soc.TotalLatePaymentFee__c != null ? soc.TotalLatePaymentFee__c : 0;
            Decimal updatedFee = existingFee > 0 ? existingFee + totalFee : totalFee;
            updatedFee = updatedFee.setScale(2, RoundingMode.HALF_UP);
            soc.Due_Date__c = currentDate;
            soc.EndDate__c = currentDate;
            soc.Amount__c = updatedFee;
            soc.TotalLatePaymentFee__c = updatedFee;
            lstSOCharges.add(soc);
        }
        
        if(!lstSOCharges.isEmpty()){
            List<SalesOrderOtherCharges__c> insertedCharges = salesOrderOtherChargeService.upsertSalesOrderOtherCharges(lstSOCharges);
            for (SalesOrderOtherCharges__c soc : insertedCharges) {
                installmentToSOChargeId.put(soc.Installment_Line__c, soc.Id);
            }
        }
        
        for (LatePaymentFee__c lpf : latePaymentFeeList) {
            lpf.SalesOrderOtherCharges__c = installmentToSOChargeId.get(lpf.InstallmentLine__c);
        }
        latePaymentService.insertLatePaymentFeeLists(latePaymentFeeList);
        
        installmentLineService.updateInstallmentLines(installmentLinesToUpdate);
    }
    
    public void finish(Database.BatchableContext BC) {
    }
    
    public void execute(SchedulableContext sc){
        Database.executeBatch(new LatePaymentFeeBatch(),1);
    }
}