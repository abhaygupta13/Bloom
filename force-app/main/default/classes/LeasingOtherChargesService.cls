/***
Class       : LeasingOtherChargesService
Author      : 
Description : 
TestClass   : 
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
****************************************************************************************************************/
public  inherited sharing  class LeasingOtherChargesService {
    
    private static LeasingOtherChargesService instance;
    
    private static final string INTEGRATION_TYPE_LEASING_OTHER_CHARGE_SAP_INTEGRATION { get { return 'LEASING_ORDER_OTHER_CHARGES_SAP_INTEGRATION'; } }
    private static final string INTEGRATION_ACTION_INSERT { get { return 'Insert'; } }
    private static final string LEASING_ORDER_OTHER_CHARGE_OBJECT_API_NAME { get { return 'LeasingOrdersOtherCharges__c  '; } }
    
    private LeasingOtherChargesService() {
        
    }
    
    public static LeasingOtherChargesService getInstance() { 
        if(instance == null) {
            instance = new LeasingOtherChargesService();
        }
        return instance;
    }
    
    public List<LeasingOrdersOtherCharges__c> getOtherChargesByLeasingOrderId(Id leasingOrderId){
        return [SELECT Id,Type__c,ChargeAmount__c,VATAmount__c,LeasingOrder__r.Unit__r.PropertyUsage__c,
                LeasingOrder__r.Unit__r.Project__r.LeasingMunicipalityArea__c,
                LeasingOrder__r.Unit__r.Project__r.Leasing_Company__r.LeasingVAT__c,
                LeasingOrder__r.Unit__r.Project__r.city__c,RefDocno__c, IsReversed__c, Paymentdoc__c,
                isVATApplied__c,TotalAmount__c, DueDate__C FROM LeasingOrdersOtherCharges__c
                WHERE LeasingOrder__c = :leasingOrderId];
    }
    
    public List<LeasingOrdersOtherCharges__c> getOtherChargesByLeasingOrderIds(Set<Id> leasingOrderIds){
        return [
            SELECT Id, LeasingOrder__c 
            FROM LeasingOrdersOtherCharges__c 
            WHERE LeasingOrder__c IN :leasingOrderIds order by dueDate__c ASC
        ];
    }
    
    public List<LeasingOrdersOtherCharges__c> getActiveOtherChargesByStartEndDate(Date fromDate, Date toDate){
        return [
            SELECT Id, Name, LeasingOrder__r.LeasingOrderNumber__c, LeasingOrder__r.Name, LeasingOrder__r.LeasingSAPContractId__c, LeasingOrder__r.IntegrationStatus__c, LeasingOrder__c, ConditionType__c, VATAmount__c, ChargeAmount__c, DueDate__c, PaymentStatus__c,
            LeasingOrder__r.LeasingStartDate__c, LeasingOrder__r.LeasingEndDate__c, PostingDate__c, SendtoSAP__c, Type__c
            FROM LeasingOrdersOtherCharges__c
            WHERE DueDate__c >= :fromDate
            AND DueDate__c <= :toDate
            AND PaymentStatus__c = 'Not Invoiced' AND LeasingOrder__r.LeasingSAPContractId__c != null AND LeasingOrder__r.IntegrationStatus__c = 'Success'
        ];
    }
    
    
    public List<LeasingOrdersOtherCharges__c> insertOtherCharges(List<LeasingOrdersOtherCharges__c> otherChargeList){
        if(otherChargeList != NULL && !otherChargeList.isEmpty()){
            insert otherChargeList;
        }
        return otherChargeList; 
    } 
    
    public void deleteOtherCharges(List<LeasingOrdersOtherCharges__c> otherChargeList){
        if(otherChargeList != NULL && !otherChargeList.isEmpty()){
            delete otherChargeList;
        }
    }
    
    public List<LeasingOrdersOtherCharges__c> getLeasingOtherChargesByIds(Set<Id> leasingOrderOtherChargeIds) {
        
        return [ SELECT Id, LeasingOrder__r.Project__r.Leasing_Company__r.LeasingSAPCompanyCode__c ,TotalAmount__c,ChargeAmount__c,CalculationFromDate__c ,
                LeasingOrder__r.LeasingSAPContractId__c, LeasingOrder__r.Project__r.Leasing_Company__r.LeasingSAPContractTypeCode__c,RelatedPartyBloomHolding__c,
                isVATApplied__c, DueDate__c, IsReversed__c, ReversedDate__c,LeasingOrder__r.Id,ConditionType__c ,PostingDate__c ,IsPosting__c,
                ReversedReason__c, ReversedRemarks__c, ReversalCategory__c, Refdocno__c, Paymentdoc__c,LeasingOrder__r.LeasingStartDate__c, CalculationToDate__c 
                FROM LeasingOrdersOtherCharges__c WHERE Id IN :leasingOrderOtherChargeIds AND ConditionType__c != null order by DueDate__c ASC];
    }
    
    public  IntegrationRecord__c getLeasingOtherChargeRecords(LeasingOrdersOtherCharges__c   leasingOrderOtherCharge){
        IntegrationRecordService objIntegrationRecordService = IntegrationRecordService.getInstance();
        Map<String,String> paramMap = new Map<String,String>();
        paramMap.put('Param1',leasingOrderOtherCharge.LeasingOrder__r.Project__r.Leasing_Company__r.LeasingSAPCompanyCode__c);
        paramMap.put('Param2',  leasingOrderOtherCharge.LeasingOrder__r.LeasingSAPContractId__c);
        paramMap.put('Param3',  leasingOrderOtherCharge.ConditionType__c);
        //paramMap.put('Param4',  String.valueOf(leasingOrderOtherCharge.LeasingOrder__r.LeasingStartDate__c));
        paramMap.put(
            'Param4',
            String.valueOf(
                leasingOrderOtherCharge.CalculationFromDate__c != null
                ? leasingOrderOtherCharge.CalculationFromDate__c
                : leasingOrderOtherCharge.LeasingOrder__r.LeasingStartDate__c
            )
        );
        //paramMap.put('Param5',  String.valueOf(leasingOrderOtherCharge.isVATApplied__c));
        if (leasingOrderOtherCharge.isVATApplied__c) {
            paramMap.put('Param5', 'X');
        } else {
            paramMap.put('Param5', '');
        }
        if ((!leasingOrderOtherCharge.IsReversed__c && leasingOrderOtherCharge.DueDate__c <= System.Today()) || (leasingOrderOtherCharge.IsPosting__c )) {
            paramMap.put('Param6', 'X');
        }  else {
            paramMap.put('Param6', '');
            //paramMap.put('Param15',  '');
        }
        paramMap.put('Param7',  String.valueOf(leasingOrderOtherCharge.ChargeAmount__c));
        paramMap.put('Param8',  '0');
        if (leasingOrderOtherCharge.IsReversed__c ){
            paramMap.put('Param9', 'X');
            paramMap.put('Param13',  '');
            
        } else {
            paramMap.put('Param9', '');
            paramMap.put('Param13',  String.valueOf(leasingOrderOtherCharge.ReversalCategory__c ));
        }
        //paramMap.put('Param9',  String.valueOf(leasingOrderOtherCharge.IsReversed__c ));
        paramMap.put('Param10',  String.valueOf(leasingOrderOtherCharge.ReversedDate__c ));
        paramMap.put('Param11', leasingOrderOtherCharge.ReversedReason__c != Null ? leasingOrderOtherCharge.ReversedReason__c : '');
        paramMap.put('Param12',  String.valueOf(leasingOrderOtherCharge.ReversedRemarks__c));
        paramMap.put('Param13',  String.valueOf(leasingOrderOtherCharge.ReversalCategory__c ));
        paramMap.put('Param14',  String.valueOf(leasingOrderOtherCharge.Refdocno__c ));
        paramMap.put('Param15',  String.valueOf(leasingOrderOtherCharge.Paymentdoc__c ));
        paramMap.put('Param16', String.valueOf(leasingOrderOtherCharge.CalculationToDate__c ));
        paramMap.put('Param17',  String.valueOf(leasingOrderOtherCharge.DueDate__c ));
        paramMap.put('Param18',UserInfo.getUserEmail());
        if (leasingOrderOtherCharge.RelatedPartyBloomHolding__c) {
            paramMap.put('Param19', 'Y');
        } else {
            paramMap.put('Param19', 'N');
        }
        
        //paramMap.put('Param16',  String.valueOf(leasingOrderOtherCharge.LeasingOrder__r.Id ));
        
        
        return objIntegrationRecordService.getIntegrationRecord(INTEGRATION_TYPE_LEASING_OTHER_CHARGE_SAP_INTEGRATION, INTEGRATION_ACTION_INSERT,'','', LEASING_ORDER_OTHER_CHARGE_OBJECT_API_NAME, String.valueOf(leasingOrderOtherCharge.id),paramMap);
    }
    
    public List<LeasingOrdersOtherCharges__c> updateLeasingOtherCharges(List<LeasingOrdersOtherCharges__c> otherChargesList) {
        if (otherChargesList != null && !otherChargesList.isEmpty()) {
            update otherChargesList;
        }
        return otherChargesList;
    }
    public List<LeasingOrdersOtherCharges__c> getunPaidOtherChargesByLeasingOrderIds(Set<Id> leasingOrderIds) {
        return [
            SELECT Id, LeasingOrder__c, DueDate__c, ChargeAmount__c,clearedAmount__c,DueAmount__c
            FROM LeasingOrdersOtherCharges__c
            WHERE LeasingOrder__c IN :leasingOrderIds AND RefDocno__c != null
            AND DueDate__c <= today  AND PaymentStatus__c  != 'Paid' ORDER BY DueDate__c ASC
        ];
    }
    
    public LeasingOrdersOtherCharges__c updateOtherCharge(LeasingOrdersOtherCharges__c objOtherCharge){
        if(objOtherCharge != NULL ){
            objOtherCharge = updateLeasingOtherCharges(new List<LeasingOrdersOtherCharges__c>{objOtherCharge})[0];
        }
        return objOtherCharge;
    }
    
    public LeasingOrdersOtherCharges__c getOtherChargesById(Id otherChargeId){
        return [SELECT Name, ChargeAmount__c, DueDate__c,Type__c, RefDocno__c,isVATApplied__c, VATAmount__c,
                LeasingOrder__r.Account__r.Name, LeasingOrder__r.SAPBPNumber__c,
                LeasingOrder__r.Project__r.Leasing_Company__r.Name,
                LeasingOrder__r.Project__r.Leasing_Company__r.LeasingCompanyVATRegistrationNumber__c,
                LeasingOrder__r.Project__r.Leasing_Company__r.LeasingVAT__c,
                LeasingOrder__r.Account__r.UAEVATRegisterNumber__c, LeasingOrder__r.Unit__r.Name, LeasingOrder__r.PropertyName__c,
                LeasingOrder__r.Account__r.TaxRegistrationNumber__c,LeasingOrder__r.Unit__r.LeasingUnitNumber__c,
                LeasingOrder__r.Project__r.LeasingBankAccount__r.BeneficiaryNameCorporate__c, LeasingOrder__r.Project__r.LeasingBankAccount__r.BankNameCorporate__c, LeasingOrder__r.Project__r.LeasingBankAccount__r.AccountNumberCorporate__c,
                LeasingOrder__r.Project__r.LeasingBankAccount__r.IBANNoCorporate__c, LeasingOrder__r.Project__r.LeasingBankAccount__r.SwiftCodeCorporate__c, Note__c
                //LeasingOrder__r.Property__c
                FROM LeasingOrdersOtherCharges__c
                WHERE Id = :otherChargeId];
    }
    
    // -------------------- STATIC MAPS --------------------
    // private static final Map<String, String> TYPE_TO_CONDITIONTYPE_MAP = new Map<String, String>{
    //     'EIPS-Admin Fee' => 'R003',
    //     'Admin Fee' => 'R003',
    //     'Security Deposit' => 'R006',
    //     'Security Deposit Amount' => 'R006',
    //     'Cheque Bounce Fees' => 'R008',
    //     'Short Term Renewal F' => 'R010',
    //     'Delay Payment Fee' => 'R013',
    //     'Fit Out Deposit' => 'R017',
    //     'Legal Fee' => 'R018',
    //     'Recovery of Utility' => 'R019',
    //     'Tenancy Registration' => 'R020',
    //     'Abu Dn Tawteeq renwl' => 'R022',
    //     'Brk Lease pmtl (2M C' => 'R037',
    //     'Utilities' => 'R043',
    //     'Overstay - Commercial' => 'R053',
    //     'Overstay - Residential' => 'R054',
    //     'Notice penalty - Commercial' => 'R055',
    //     'Notice penalty - Residential' => 'R056',
    //     'Notice penalty - Res' => 'R056',
    //     'Notice penalty - Re' => 'R056',
    //     'cheque replace fee' => 'R100',
    //     'Parking Card Access' => 'R014',
    //     'Extra Cheque Fee' => 'R100',
    //     'Chilled Water Charge' => 'R058',
    //     'CheckoutDamage Recovery Charge' => 'R016',
    //     'Ejari/Tawtheeq Fee' => 'R022',
    //     'Cooling fee' => 'R063',
    //     'Base Rent Residentia' => 'R001',
    //     'Parking Fee' => 'R002',
    //     'EIPS-NewRentCommisio' => 'R004',
    //     'EIPS-Rec Rent Commis' => 'R005',
    //     'Break Lease fees' => 'R009',
    //     'Chilled water Depst' => 'R011',
    //     'Brk Leas ptly (2M Rs' => 'R012',
    //     'Delay Payement Fee' => 'R013',
    //     'Installment Increase' => 'R015',
    //     'CheckoutDamage Recov' => 'R016',
    //     'Discount - Resi.' => 'R021',
    //     'Abu Dh Tawteeq renwl' => 'R022',
    //     'Changing occupant' => 'R023',
    //     'Base Rent Commercial' => 'R024',
    //     'Service Charge' => 'R025',
    //     'Base Rent' => 'R028',
    //     'Base Advertising Fee' => 'R029',
    //     'Staff Commission' => 'R032',
    //     'Broker Commission' => 'R033',
    //     'Leasing Director Com' => 'R034',
    //     'Discount - Comm.' => 'R035',
    //     'Parking Comm/ Retail' => 'R036',
    //     'Brk Lease pnlt (2M C' => 'R037',
    //     'Operatn Manager Comm' => 'R038',
    //     'Sr. Leasing Admin' => 'R039',
    //     'Collector' => 'R040',
    //     'Leasng Prop. Sup Com' => 'R051',
    //     'Leasing Manager Comm' => 'R052',
    //     'Overstay - Commercia' => 'R053',
    //     'Notice penalty - Com' => 'R055',
    //     'Staff Comm -Renewals' => 'R057',
    //     'Renewal Fees' => 'R007',
    //     'Design & Review Fee' => 'R064'
    // };
    
    // private static final Map<String, String> TYPE_TO_SUBCATEGORY_MAP = new Map<String, String>{
    //     'EIPS-Admin Fee' => 'Other charges',
    //     'Admin Fee' => 'Other charges',
    //     'Security Deposit' => 'Security Deposit',
    //     'Security Deposit Amount' => 'Security Deposit',
    //     'Cheque Bounce Fees' => 'Cheque Bounce charges',
    //     'Short Term Renewal F' => 'Other fee',
    //     'Delay Payment Fee' => 'Late fee',
    //     'Fit Out Deposit' => 'Other charges',
    //     'Legal Fee' => 'Legal case',
    //     'Recovery of Utility' => 'Utilities',
    //     'Tenancy Registration' => 'Ejari/Tawtheeq fee',
    //     'Tenancy Registration' => 'Ejari/Tawtheeq Fee',
    //     'Abu Dn Tawteeq renwl' => 'Tawtheeq',
    //     'Brk Lease pmtl (2M C' => 'Penalities',
    //     'Utilities' => 'Utilities',
    //     'Overstay - Commercial' => 'Penalities',
    //     'Overstay - Residential' => 'Penalities',
    //     'Notice penalty - Commercial' => 'Penalities',
    //     'Notice penalty - Residential' => 'Penalities',
    //     'cheque replace fee' => 'Other fee'
    // };
    
    public Map<String, String> getTypeToConditionTypeMap() {
        return TYPE_TO_CONDITIONTYPE_MAP;
    }
    
    public Map<String, String> getTypeToSubCategoryMap() {
        return TYPE_TO_SUBCATEGORY_MAP;
    }
    
    Static Map<String,String> TYPE_TO_CONDITIONTYPE_MAP = LeasingChargeMappingsUtil.getTypeToConditionTypeMap();
    
    Static Map<String,String> TYPE_TO_SUBCATEGORY_MAP = LeasingChargeMappingsUtil.getTypeToSubCategoryMap();
}