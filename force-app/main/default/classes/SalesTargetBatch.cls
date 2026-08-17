/*****************************************************************************************
Class       : SalesTargetBatch
Author      : Vikas Baliyan
Description : Sales Target Batch
Test Class  : 
Created Date: 09 NOV 2024 
*****************************************************************************************/

public class SalesTargetBatch implements Database.Batchable<sObject>,Schedulable {
    private static final string SALES_TARGET_QUARTER_YEAR { get { return 'SalesTargetQuarterYear'; } }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        
        String currentYear = getQuarterOrYear('Year');
        String currentQuarter = getQuarterOrYear('Quarter');
        
        // SOQL to fetch Sales Target records
        String query = 'SELECT Id, DirectAchievedAmount__c, IndirectAchievedAmount__c,DirectTargetAmount__c,IndirectPreLaunchAchievedAmount__c,IndirectLaunchAchievedAmount__c,DSGAchievedAmount__c,IndirectPostLaunchAchievedAmount__c,DCLAchievedAmount__c,DCLRefAchievedAmount__c,SalesManager__c,Quarter__c,Year__c, SpecialProjectsAchievedAmount__c, SpecialDirectAchievedCommissionAmt__c, SpecialDirectNotAchievedCommiAmt__c, SpecialDirectDoubledCommissionAmount__c, SpecialDirectExceededCommissionAmt__c, (SELECT Id,Name,Project__c,IsSpecialProject__c,AchievedPercentage__c,NotAchievedPercentage__c,DoubledPercentage__c,ExceededPercentage__c FROM ProjectSalesTargets__r) FROM SalesTarget__c WHERE Year__c =: currentYear AND Quarter__c =: currentQuarter';
        return Database.getQueryLocator(query);
    }
    // Main logic of processing each batch
    public void execute(Database.BatchableContext bc, List<SalesTarget__c> scope){
        SalesOrderService objSalesOrder = SalesOrderService.getInstance();
        SalesTargetService objSalesTarget = SalesTargetService.getInstance();
        ProjectSalesTargetService objProjectSalesTarget = ProjectSalesTargetService.getInstance();

        String selectedYear = getQuarterOrYear('Year');
        String selectedQuarter = getQuarterOrYear('Quarter');
        // Set of sales manager id's to fetch the related sales order
        Set<Id> salesManagerIdSet = new Set<Id>();
        Map<String, ProjectSalesTarget__c> salesManagerToSpecialProjectMap = new Map<String, ProjectSalesTarget__c>();
        for(SalesTarget__c salesTarget : scope){
            if(salesTarget.SalesManager__c != null){
                salesManagerIdSet.add(salesTarget.SalesManager__c);
            }

            if(salesTarget.ProjectSalesTargets__r != null && !salesTarget.ProjectSalesTargets__r.isEmpty()){
                for(ProjectSalesTarget__c projectSalesTarget : salesTarget.ProjectSalesTargets__r){
                    if(projectSalesTarget.IsSpecialProject__c){
                        salesManagerToSpecialProjectMap.put((salesTarget.SalesManager__c + '_' + projectSalesTarget.Project__c), projectSalesTarget);
                    }
                }
            }
        }
        
        // sales order list based on sold date, salesManger and status
        List<SalesOrder__c> salesOrderList = objSalesOrder.getSalesOrdersBySalesManager(Constants.SALES_ORDER_STATUS_SOLD, salesManagerIdSet, Integer.valueOf(selectedYear), Integer.valueOf(selectedQuarter.substring(1)));
        //Map to store sales manager's direct and indirect amount
        Map<String, Decimal> salesManagerDirIndirAmountMap = new Map<String, Decimal>();
        Map<Id, SalesTarget__c> salesManagerIdToSalesTargetMap = new Map<Id, SalesTarget__c>();
        Map<String, Integer> salesManagerToAchievedUnitCountMap = new Map<String, Integer>();
        for(SalesOrder__c salesOrder : salesOrderList){
            Boolean isSpecialProject = salesManagerToSpecialProjectMap.containsKey(salesOrder.SalesManager__c+'_'+salesOrder.Unit__r.Project__c);
            Decimal taxAmount = salesOrder.IsTaxable__c && salesOrder.Tax_Percentage__c != null && salesOrder.TaxableAmount__c != null ? salesOrder.TaxableAmount__c : 0;
            Decimal netAmount = salesOrder.NetAmount__c != null ? salesOrder.NetAmount__c : 0;
            Decimal netAmountWithoutADMFee = (selectedYear == '2024' && selectedQuarter == 'Q3') ? netAmount : (salesOrder.ADM_Fee_Included__c ? salesOrder.Sales_Price_Excluding_ADM__c : (netAmount - taxAmount));
            netAmountWithoutADMFee = getEligibleAmountForSalesTarget(salesOrder, netAmountWithoutADMFee);
            //if Secondary Sales Manager is not null then divide the amount by 2
            netAmountWithoutADMFee = salesOrder.Secondary_Sales_Manager__c != null ? netAmountWithoutADMFee / 2 : netAmountWithoutADMFee;
            Boolean isIndirect = isIndirect(salesOrder.Opportunity__r.LeadSource, salesOrder.Opportunity__r.LeadSubSource__c);
            Decimal indirectPreLaunchAchievedAmount = (salesOrder.Unit__r.Project__r.PreLaunchStartDate__c <= salesOrder.BookingDate__c &&  salesOrder.BookingDate__c <= salesOrder.Unit__r.Project__r.PreLaunchEndDate__c) && isIndirect ? netAmountWithoutADMFee : 0;
            Decimal indirectLaunchAchievedAmount = (salesOrder.Unit__r.Project__r.LaunchStartDate__c <= salesOrder.BookingDate__c &&  salesOrder.BookingDate__c <= salesOrder.Unit__r.Project__r.LaunchEndDate__c) && isIndirect ? netAmountWithoutADMFee : 0;
            Decimal indirectPostLaunchAchievedAmount = (salesOrder.Unit__r.Project__r.PostLaunchStartDate__c <= salesOrder.BookingDate__c &&  (salesOrder.Unit__r.Project__r.PostLaunchEndDate__c == null || salesOrder.BookingDate__c <= salesOrder.Unit__r.Project__r.PostLaunchEndDate__c)) && isIndirect ? netAmountWithoutADMFee : 0;
            Decimal directSelfGeneratedAchievedAmount = !isSpecialProject && isDirectSelfGenerated(salesOrder.Opportunity__r.LeadSource, salesOrder.Opportunity__r.LeadSubSource__c) ? netAmountWithoutADMFee : 0;
            Decimal directCompanyLeadAchievedAmount = !isSpecialProject && isDirectCoLeadGenerated(salesOrder.Opportunity__r.LeadSource, salesOrder.Opportunity__r.LeadSubSource__c)  ? netAmountWithoutADMFee : 0;
            Decimal directCompanyLeadRefAchievedAmount = !isSpecialProject && (salesOrder.Opportunity__r.LeadSource == 'Referral' && salesOrder.Opportunity__r.LeadSubSource__c != 'CustomerReferral') ? netAmountWithoutADMFee : 0;


            Decimal specialProjectsAchievedAmount = isSpecialProject && !isIndirect ? netAmountWithoutADMFee : 0;
            Decimal specialProjectDirectAchievedCommissionAmount = isSpecialProject && !isIndirect ? salesManagerToSpecialProjectMap.get(salesOrder.SalesManager__c+'_'+salesOrder.Unit__r.Project__c).AchievedPercentage__c/100 * specialProjectsAchievedAmount : 0;
            Decimal specialProjectDirectNotAchievedCommiAmount = isSpecialProject && !isIndirect ? salesManagerToSpecialProjectMap.get(salesOrder.SalesManager__c+'_'+salesOrder.Unit__r.Project__c).NotAchievedPercentage__c/100 * specialProjectsAchievedAmount : 0;
            Decimal specialProjectDirectExceededCommissionAmount = isSpecialProject && !isIndirect ? salesManagerToSpecialProjectMap.get(salesOrder.SalesManager__c+'_'+salesOrder.Unit__r.Project__c).ExceededPercentage__c/100 * specialProjectsAchievedAmount : 0;
            Decimal specialProjectDirectDoubledCommissionAmount = isSpecialProject && !isIndirect ? salesManagerToSpecialProjectMap.get(salesOrder.SalesManager__c+'_'+salesOrder.Unit__r.Project__c).DoubledPercentage__c/100 * specialProjectsAchievedAmount : 0;

            salesManagerIdToSalesTargetMap = createSalesManagerToSalesTargetMap(salesManagerIdToSalesTargetMap, salesOrder.SalesManager__c, indirectPreLaunchAchievedAmount, indirectLaunchAchievedAmount, indirectPostLaunchAchievedAmount, directSelfGeneratedAchievedAmount, directCompanyLeadAchievedAmount, directCompanyLeadRefAchievedAmount, specialProjectsAchievedAmount, specialProjectDirectAchievedCommissionAmount, specialProjectDirectNotAchievedCommiAmount, specialProjectDirectDoubledCommissionAmount, specialProjectDirectExceededCommissionAmount);
            salesManagerDirIndirAmountMap = createSalesManagerDirIndirAmountMap(salesManagerDirIndirAmountMap, salesOrder.SalesManager__c, netAmountWithoutADMFee, salesOrder.Opportunity__r.LeadSource, salesOrder.Opportunity__r.LeadSubSource__c);
            salesManagerToAchievedUnitCountMap = createSalesManagerToAchievedUnitCountMap(salesManagerToAchievedUnitCountMap, salesOrder.SalesManager__c, salesOrder.Unit__r.Project__c);

            

            //  if secondary sales manager is not null then calculate the amount for secondary sales manager
            if(salesOrder.Secondary_Sales_Manager__c != null){
                salesManagerIdToSalesTargetMap = createSalesManagerToSalesTargetMap(salesManagerIdToSalesTargetMap, salesOrder.Secondary_Sales_Manager__c, indirectPreLaunchAchievedAmount, indirectLaunchAchievedAmount, indirectPostLaunchAchievedAmount, directSelfGeneratedAchievedAmount, directCompanyLeadAchievedAmount, directCompanyLeadRefAchievedAmount, specialProjectsAchievedAmount, specialProjectDirectAchievedCommissionAmount, specialProjectDirectNotAchievedCommiAmount, specialProjectDirectDoubledCommissionAmount, specialProjectDirectExceededCommissionAmount);
                salesManagerDirIndirAmountMap = createSalesManagerDirIndirAmountMap(salesManagerDirIndirAmountMap, salesOrder.Secondary_Sales_Manager__c, netAmountWithoutADMFee, salesOrder.Opportunity__r.LeadSource, salesOrder.Opportunity__r.LeadSubSource__c);
                salesManagerToAchievedUnitCountMap = createSalesManagerToAchievedUnitCountMap(salesManagerToAchievedUnitCountMap, salesOrder.Secondary_Sales_Manager__c, salesOrder.Unit__r.Project__c);
            }
        }
        // list of Sales Target to update  
        List<SalesTarget__c> updatedSalesTargetList = new List<SalesTarget__c>();
        List<ProjectSalesTarget__c> updatedProjectSalesTargetsList = new List<ProjectSalesTarget__c>();

        for(SalesTarget__c salesTarget : scope){
            Decimal directAmount = salesManagerDirIndirAmountMap.containsKey(salesTarget.SalesManager__c+'_Direct') ? salesManagerDirIndirAmountMap.get(salesTarget.SalesManager__c+'_Direct') : 0;
            Decimal indirectAmount = salesManagerDirIndirAmountMap.containsKey(salesTarget.SalesManager__c+'_Indirect') ? salesManagerDirIndirAmountMap.get(salesTarget.SalesManager__c+'_Indirect') : 0;
            salesTarget.DirectAchievedAmount__c =  directAmount;
            salesTarget.IndirectAchievedAmount__c =  indirectAmount;

            salesTarget.IndirectPreLaunchAchievedAmount__c = salesManagerIdToSalesTargetMap.containsKey(salesTarget.SalesManager__c) ? (salesManagerIdToSalesTargetMap.get(salesTarget.SalesManager__c).IndirectPreLaunchAchievedAmount__c != null ? salesManagerIdToSalesTargetMap.get(salesTarget.SalesManager__c).IndirectPreLaunchAchievedAmount__c: 0) : 0;
            salesTarget.IndirectLaunchAchievedAmount__c =  salesManagerIdToSalesTargetMap.containsKey(salesTarget.SalesManager__c) ? (salesManagerIdToSalesTargetMap.get(salesTarget.SalesManager__c).IndirectLaunchAchievedAmount__c != null ? salesManagerIdToSalesTargetMap.get(salesTarget.SalesManager__c).IndirectLaunchAchievedAmount__c : 0 ) : 0;
            salesTarget.IndirectPostLaunchAchievedAmount__c = salesManagerIdToSalesTargetMap.containsKey(salesTarget.SalesManager__c) ? (salesManagerIdToSalesTargetMap.get(salesTarget.SalesManager__c).IndirectPostLaunchAchievedAmount__c != null ? salesManagerIdToSalesTargetMap.get(salesTarget.SalesManager__c).IndirectPostLaunchAchievedAmount__c : 0) : 0;
            salesTarget.DSGAchievedAmount__c = salesManagerIdToSalesTargetMap.containsKey(salesTarget.SalesManager__c) ? (salesManagerIdToSalesTargetMap.get(salesTarget.SalesManager__c).DSGAchievedAmount__c != null ? salesManagerIdToSalesTargetMap.get(salesTarget.SalesManager__c).DSGAchievedAmount__c : 0) : 0;
            salesTarget.DCLAchievedAmount__c = salesManagerIdToSalesTargetMap.containsKey(salesTarget.SalesManager__c) ? (salesManagerIdToSalesTargetMap.get(salesTarget.SalesManager__c).DCLAchievedAmount__c != null ? salesManagerIdToSalesTargetMap.get(salesTarget.SalesManager__c).DCLAchievedAmount__c : 0) : 0;
            salesTarget.DCLRefAchievedAmount__c = salesManagerIdToSalesTargetMap.containsKey(salesTarget.SalesManager__c) ? (salesManagerIdToSalesTargetMap.get(salesTarget.SalesManager__c).DCLRefAchievedAmount__c != null ? salesManagerIdToSalesTargetMap.get(salesTarget.SalesManager__c).DCLRefAchievedAmount__c : 0) : 0;
            
            salesTarget.SpecialProjectsAchievedAmount__c = salesManagerIdToSalesTargetMap.containsKey(salesTarget.SalesManager__c) && salesManagerIdToSalesTargetMap.get(salesTarget.SalesManager__c).SpecialProjectsAchievedAmount__c != null ? salesManagerIdToSalesTargetMap.get(salesTarget.SalesManager__c).SpecialProjectsAchievedAmount__c : 0;
            salesTarget.SpecialDirectAchievedCommissionAmt__c = salesManagerIdToSalesTargetMap.containsKey(salesTarget.SalesManager__c) && salesManagerIdToSalesTargetMap.get(salesTarget.SalesManager__c).SpecialDirectAchievedCommissionAmt__c != null ? salesManagerIdToSalesTargetMap.get(salesTarget.SalesManager__c).SpecialDirectAchievedCommissionAmt__c : 0;
            salesTarget.SpecialDirectNotAchievedCommiAmt__c = salesManagerIdToSalesTargetMap.containsKey(salesTarget.SalesManager__c) && salesManagerIdToSalesTargetMap.get(salesTarget.SalesManager__c).SpecialDirectNotAchievedCommiAmt__c != null ? salesManagerIdToSalesTargetMap.get(salesTarget.SalesManager__c).SpecialDirectNotAchievedCommiAmt__c : 0;
            salesTarget.SpecialDirectDoubledCommissionAmount__c = salesManagerIdToSalesTargetMap.containsKey(salesTarget.SalesManager__c) && salesManagerIdToSalesTargetMap.get(salesTarget.SalesManager__c).SpecialDirectDoubledCommissionAmount__c != null && salesTarget.SpecialProjectsAchievedAmount__c >= salesTarget.DirectTargetAmount__c * 2 ? salesManagerIdToSalesTargetMap.get(salesTarget.SalesManager__c).SpecialDirectDoubledCommissionAmount__c : 0;
            salesTarget.SpecialDirectExceededCommissionAmt__c = salesManagerIdToSalesTargetMap.containsKey(salesTarget.SalesManager__c) && salesManagerIdToSalesTargetMap.get(salesTarget.SalesManager__c).SpecialDirectExceededCommissionAmt__c != null && salesTarget.SpecialProjectsAchievedAmount__c > salesTarget.DirectTargetAmount__c ? salesManagerIdToSalesTargetMap.get(salesTarget.SalesManager__c).SpecialDirectExceededCommissionAmt__c : 0;
            updatedSalesTargetList.add(salesTarget);
            
            if(salesTarget.ProjectSalesTargets__r != null && !salesTarget.ProjectSalesTargets__r.isEmpty()){
                for(ProjectSalesTarget__c projectSalesTarget : salesTarget.ProjectSalesTargets__r){
                    String key = salesTarget.SalesManager__c + '_' + projectSalesTarget.Project__c;
                    if(salesManagerToAchievedUnitCountMap.containsKey(key)){
                        projectSalesTarget.AchievedUnit__c = salesManagerToAchievedUnitCountMap.get(key);
                        updatedProjectSalesTargetsList.add(projectSalesTarget);
                    }
                }
            }
        }
        //update Sales Targets
        objSalesTarget.updateSalesTarget(updatedSalesTargetList);
        //update Project Sales Targets
        objProjectSalesTarget.updateProjectSalesTargets(updatedProjectSalesTargetsList);
    }

    public void finish(Database.BatchableContext bc){

    }
    // Scheduling the batch
    public void execute(SchedulableContext sc) {
        SalesTargetBatch batch = new SalesTargetBatch();
        Database.executeBatch(batch, 200);
    }

    private String getQuarterOrYear(String quarterOrYear){
        if (Test.isRunningTest()){
            return quarterOrYear == 'Year' ? '2025' : 'Q1';
        }
        MetadataService objMetadataService = MetadataService.getInstance();
        Boolean isMetadataActive = objMetadataService.getAppSettingBooleanValue(SALES_TARGET_QUARTER_YEAR);
        String salesTargetQuarterYear = objMetadataService.getAppSettingTextValue(SALES_TARGET_QUARTER_YEAR);
        
        String currentYear = String.valueOf(Date.today().year());
        Integer currentMonth = Date.today().month();
        
        // Determine the current quarter based on the current month
        String currentQuarter = Utility.getCurrentQuarter(currentMonth);
        
        // if metadata is active then use the values from metadata
        currentQuarter = isMetadataActive ? salesTargetQuarterYear.split('-')[0] : currentQuarter;
        currentYear = isMetadataActive ? salesTargetQuarterYear.split('-')[1] : currentYear;
        return quarterOrYear == 'Year' ? currentYear : currentQuarter;
    }

    private Map<Id, SalesTarget__c> createSalesManagerToSalesTargetMap(Map<Id, SalesTarget__c> salesManagerIdToSalesTargetMap, Id SalesManager, Decimal indirectPreLaunchAchievedAmount, Decimal indirectLaunchAchievedAmount, Decimal indirectPostLaunchAchievedAmount, Decimal directSelfGeneratedAchievedAmount, Decimal directCompanyLeadAchievedAmount, Decimal directCompanyLeadRefAchievedAmount, Decimal specialAchievedAmount, Decimal specialDirectAchievedCommissionAmount, Decimal specialDirectNotAchievedCommiAmount, Decimal specialDirectDoubledCommissionAmount, Decimal specialDirectExceededCommissionAmount){
        if(!salesManagerIdToSalesTargetMap.containsKey(SalesManager)){
            salesManagerIdToSalesTargetMap.put(SalesManager, new SalesTarget__c(IndirectPreLaunchAchievedAmount__c = indirectPreLaunchAchievedAmount, IndirectLaunchAchievedAmount__c = indirectLaunchAchievedAmount, IndirectPostLaunchAchievedAmount__c = indirectPostLaunchAchievedAmount, DSGAchievedAmount__c = directSelfGeneratedAchievedAmount, DCLAchievedAmount__c = directCompanyLeadAchievedAmount, DCLRefAchievedAmount__c = directCompanyLeadRefAchievedAmount, SpecialProjectsAchievedAmount__c = specialAchievedAmount, SpecialDirectAchievedCommissionAmt__c = specialDirectAchievedCommissionAmount, SpecialDirectNotAchievedCommiAmt__c = specialDirectNotAchievedCommiAmount, SpecialDirectDoubledCommissionAmount__c = specialDirectDoubledCommissionAmount, SpecialDirectExceededCommissionAmt__c = specialDirectExceededCommissionAmount));
        }
        else{
            SalesTarget__c target = salesManagerIdToSalesTargetMap.get(SalesManager);
            target.IndirectPreLaunchAchievedAmount__c += indirectPreLaunchAchievedAmount;
            target.IndirectLaunchAchievedAmount__c += indirectLaunchAchievedAmount;
            target.IndirectPostLaunchAchievedAmount__c += indirectPostLaunchAchievedAmount;
            target.DSGAchievedAmount__c += directSelfGeneratedAchievedAmount;
            target.DCLAchievedAmount__c += directCompanyLeadAchievedAmount;
            target.DCLRefAchievedAmount__c += directCompanyLeadRefAchievedAmount;
            target.SpecialProjectsAchievedAmount__c += specialAchievedAmount;
            target.SpecialDirectAchievedCommissionAmt__c += specialDirectAchievedCommissionAmount;
            target.SpecialDirectNotAchievedCommiAmt__c += specialDirectNotAchievedCommiAmount;
            target.SpecialDirectDoubledCommissionAmount__c += specialDirectDoubledCommissionAmount;
            target.SpecialDirectExceededCommissionAmt__c += specialDirectExceededCommissionAmount;
            salesManagerIdToSalesTargetMap.put(SalesManager, target);
        }
        return salesManagerIdToSalesTargetMap;
    }

    private Map<String, Decimal> createSalesManagerDirIndirAmountMap(Map<String, Decimal> salesManagerDirIndirAmountMap, Id salesManager, Decimal netAmountWithoutADMFee, String leadSource, String leadSubSource){
        if(isIndirect(leadSource, leadSubSource)){
            if(!salesManagerDirIndirAmountMap.containsKey(salesManager+'_Indirect')){
                salesManagerDirIndirAmountMap.put(salesManager+'_Indirect', 0);
            }
            salesManagerDirIndirAmountMap.put(salesManager+'_Indirect', salesManagerDirIndirAmountMap.get(salesManager+'_Indirect') + netAmountWithoutADMFee);
        }
        else{
            if(!salesManagerDirIndirAmountMap.containsKey(salesManager+'_Direct')){
                salesManagerDirIndirAmountMap.put(salesManager+'_Direct', 0);
            }
            salesManagerDirIndirAmountMap.put(salesManager+'_Direct', salesManagerDirIndirAmountMap.get(salesManager+'_Direct') + netAmountWithoutADMFee);
        }
        return salesManagerDirIndirAmountMap;
    }

    private Map<String, Integer> createSalesManagerToAchievedUnitCountMap(Map<String, Integer> salesManagerToAchievedUnitCountMap, Id salesManagerId, Id projectId){
        String key = salesManagerId+'_'+projectId;
        if(!salesManagerToAchievedUnitCountMap.containsKey(key)){
            salesManagerToAchievedUnitCountMap.put(key, 0);
        }
        salesManagerToAchievedUnitCountMap.put(key, salesManagerToAchievedUnitCountMap.get(key) + 1);
        return salesManagerToAchievedUnitCountMap;
    }

    private Boolean isIndirect(String leadSource, String leadSubSource){
        return (leadSource == 'Broker'  || leadSource == 'Broker Portal' || (leadSource == 'Referral' && leadSubSource != 'CustomerReferral'));
    }

    private Boolean isDirectSelfGenerated(String leadSource, String leadSubSource){
        return (leadSource == 'Word of Mouth' || leadSource == 'Personal Contact' || leadSource == 'Sales Self Generate' || (leadSource == 'Sales Manager' && leadSubSource == 'Direct Contact'));
    }

    private Boolean isDirectCoLeadGenerated(String leadSource, String leadSubSource){
        return !isDirectSelfGenerated(leadSource, leadSubSource) && leadSource != 'Broker' && leadSource != 'Broker Portal'
        && ((leadSource == 'Referral' && leadSubSource == 'CustomerReferral') || leadSource != 'Referral');
    }

    private Decimal getEligibleAmountForSalesTarget(SalesOrder__c salesOrder, Decimal netAmountWithoutADMFee){
        if(salesOrder.Sale_Type__c != 'Upgrade Sale' || salesOrder.UpgradedFrom__c == null){
            return netAmountWithoutADMFee;
        }

        SalesOrder__c oldSO = salesOrder.UpgradedFrom__r;

        if(oldSO == null || oldSO.SoldDate__c == null){
            return netAmountWithoutADMFee;
        }

        Decimal taxAmount = oldSO.IsTaxable__c && oldSO.Tax_Percentage__c != null && oldSO.TaxableAmount__c != null ? oldSO.TaxableAmount__c : 0;

        Integer oldQuarter = ((oldSO.SoldDate__c.month() - 1) / 3) + 1;
        Integer newQuarter = ((salesOrder.SoldDate__c.month() - 1) / 3) + 1;

        if(oldSO.SoldDate__c.year() == salesOrder.SoldDate__c.year() && oldQuarter == newQuarter){
            return netAmountWithoutADMFee;
        }
        Decimal oldAmount = (oldSO.ADM_Fee_Included__c  && oldSO.Sales_Price_Excluding_ADM__c != null) ? oldSO.Sales_Price_Excluding_ADM__c : oldSO.NetAmount__c - taxAmount;

        return Math.max(netAmountWithoutADMFee - oldAmount, 0);
    }

}