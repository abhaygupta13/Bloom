/*******************************************************************************************************
Class       : LeasingOfficerCommissionService
Author      : 
Description : 
TestClass   : 
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1        1.0                04-12-2025             Initial draft
****************************************************************************************************************/
public inherited sharing class LeasingOfficerCommissionService {
    private static LeasingOfficerCommissionService instance;
    
    private static final string LEASING_OFFICER_COMMISSION_SAP_INTEGRATION { get { return 'LEASING_OFFICER_COMMISSION_SAP_INTEGRATION'; } }
    private static final string INTEGRATION_ACTION_INSERT { get { return 'Insert'; } }
    private static final string PAYMENT_PLAN_OBJECT_API_NAME { get { return 'LeasingOfficerCommission__c'; } }
    
    private LeasingOfficerCommissionService() {
        
    }
    
    public static LeasingOfficerCommissionService getInstance() { 
        if(instance == null) {
            instance = new LeasingOfficerCommissionService();
        }
        return instance;
    }
    
    public LeasingOfficerCommission__c insertLOC(LeasingOfficerCommission__c loc){
        if (loc != null) {
            insert loc;
        }
        return loc;
    }
    
    public List<LeasingOfficerCommission__c> updateLOCs(List<LeasingOfficerCommission__c> locs) {
        if (locs != null && !locs.isEmpty()) {
            update locs;
        }
        return locs;
    }
    
    public LeasingOfficerCommission__c updateLOC(LeasingOfficerCommission__c loc){
        if(loc != NULL ){
            loc = updateLOCs(new List<LeasingOfficerCommission__c>{loc})[0];
        }
        return loc;
    }
    
    public List<LeasingOfficerCommission__c > getLeasingOfficerCommissionByIds(Set<Id> LeasingOfficerCommissionIds) {
        
        return [ SELECT Id, LeasingOrder__r.Project__r.Leasing_Company__r.LeasingSAPCompanyCode__c ,LeasingOrder__r.LeasingStartDate__c,
                LeasingOrder__r.LeasingSAPContractId__c, LeasingOrder__r.Project__r.Leasing_Company__r.LeasingSAPContractTypeCode__c,
                isVATApplied__c, DueDate__c, Commission_Amount__c , Refdocno__c, Paymentdoc__c, LeasingOrder__r.Id,LeasingOrder__r.LeasingEndDate__c,
                LeasingOrder__r.Unit__r.PropertyUsage__c, LeasingOrder__r.Project__r.Leasing_Company__r.LeasingSAPCommercialContractTypeCode__c,
                LeasingOrder__r.Project__r.Leasing_Company__r.LeasingSAPResContractTypeCode__c, SAPConditionTypeCode__c,
                IsReversed__c, ReversalCategory__c, ReversedDate__c, ReversedReason__c, ReversedRemarks__c, RelatedPartyBloomHolding__c
                FROM LeasingOfficerCommission__c WHERE Id IN :LeasingOfficerCommissionIds];
    }
    
    public List<LeasingOfficerCommission__c> getLOCByLeasingOrderIds(Set<Id> leasingOrderIds){
        return [
            SELECT Id, LeasingOrder__c 
            FROM LeasingOfficerCommission__c 
            WHERE LeasingOrder__c IN :leasingOrderIds
        ];
    }
    
    public  IntegrationRecord__c getLeasingOfficerCommissionRecords(LeasingOfficerCommission__c  leasingOfficerCommission){
        IntegrationRecordService objIntegrationRecordService = IntegrationRecordService.getInstance();
        Map<String,String> paramMap = new Map<String,String>();
        paramMap.put('Param1',leasingOfficerCommission.LeasingOrder__r.Project__r.Leasing_Company__r.LeasingSAPCompanyCode__c);
        paramMap.put('Param2',  leasingOfficerCommission.LeasingOrder__r.LeasingSAPContractId__c);
        // Now put this in paramsMap
        paramMap.put('Param3', leasingOfficerCommission.SAPConditionTypeCode__c );
        paramMap.put('Param4',  String.valueOf(leasingOfficerCommission.LeasingOrder__r.LeasingStartDate__c));
        if (leasingOfficerCommission.isVATApplied__c) {
            paramMap.put('Param5', 'X');
        } else {
            paramMap.put('Param5', '');
        }
        if (!leasingOfficerCommission.IsReversed__c && leasingOfficerCommission.DueDate__c <= System.Today()) {
            paramMap.put('Param6', 'X');
        } else {
            paramMap.put('Param6', '');
            //paramMap.put('Param15',  '');
        }
        paramMap.put('Param7',  String.valueOf(leasingOfficerCommission.Commission_Amount__c));
        paramMap.put('Param8',  '0');
        
        if (leasingOfficerCommission.IsReversed__c ){
            paramMap.put('Param9', 'X');
            paramMap.put('Param13',  '');
            
        } else {
            paramMap.put('Param9', '');
            paramMap.put('Param13',  String.valueOf(leasingOfficerCommission.ReversalCategory__c ));
        }
        //paramMap.put('Param9',  String.valueOf(leasingOrderOtherCharge.IsReversed__c ));
        paramMap.put('Param10',  String.valueOf(leasingOfficerCommission.ReversedDate__c ));
        paramMap.put('Param11',  String.valueOf(leasingOfficerCommission.ReversedReason__c));
        paramMap.put('Param12',  String.valueOf(leasingOfficerCommission.ReversedRemarks__c));
        paramMap.put('Param13',  String.valueOf(leasingOfficerCommission.ReversalCategory__c ));
        paramMap.put('Param14',  String.valueOf(leasingOfficerCommission.Refdocno__c ));
        paramMap.put('Param15',  String.valueOf(leasingOfficerCommission.Paymentdoc__c ));
        paramMap.put('Param16',  String.valueOf(leasingOfficerCommission.LeasingOrder__r.LeasingEndDate__c));
        paramMap.put('Param17',  String.valueOf(leasingOfficerCommission.DueDate__c ));
        paramMap.put('Param18',UserInfo.getUserEmail());
        if (leasingOfficerCommission.RelatedPartyBloomHolding__c) {
            paramMap.put('Param19', 'Y');
        } else {
            paramMap.put('Param19', 'N');
        }
        
        return objIntegrationRecordService.getIntegrationRecord(LEASING_OFFICER_COMMISSION_SAP_INTEGRATION, INTEGRATION_ACTION_INSERT,'','', PAYMENT_PLAN_OBJECT_API_NAME, String.valueOf(leasingOfficerCommission.id),paramMap);
    }
}