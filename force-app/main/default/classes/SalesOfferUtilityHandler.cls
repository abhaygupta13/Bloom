/***
Class       : SalesOfferUtilityHandler
Author      : Smaartt
Description : 
TestClass   : SalesOfferUtilityHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              20/07/23           Initial Version 
****************************************************************************************************************/


public with sharing class SalesOfferUtilityHandler { 
    public static Map<Id,Set<Id>> buildingToPaymentPlanMap ;
    public static list<OfferLines__c> getApplicableOfferLines(list<OfferLines__c> allOfferLines,Unit__c unitRecord,Opportunity opportunityRecord, Lead leadRecord, decimal totalUnitOffered , decimal totalofAllUnitPrice){
        list<OfferLines__c> applicableOfferLinesCalculated  = new list<OfferLines__c>();
        for(OfferLines__c tempOfferLine: allOfferLines ){
            if(tempOfferLine.LowerBound__c != null && tempOfferLine.UpperBound__c !=null){
                decimal decimalValToCompare=0;
                if(totalUnitOffered!=null && tempOfferLine.DiscountType__c!=null && tempOfferLine.DiscountType__c.equalsIgnoreCase('Bulk Discount')){decimalValToCompare = totalUnitOffered; } //Constant Constants.DISCOUNT_TYPE_BULK_DISCOUNT replaced 
                else if(totalofAllUnitPrice!=null && tempOfferLine.Bulk__c ){decimalValToCompare = totalofAllUnitPrice; }
                else if(!tempOfferLine.Bulk__c){decimalValToCompare = unitRecord.SellingPrice__c; }
            }
            applicableOfferLinesCalculated.add(tempOfferLine);
        }
        return applicableOfferLinesCalculated;
    }
    
    
    public with sharing class SalesOfferDetails{
        @AuraEnabled
        public Id leadId {get; set;}
        @AuraEnabled
        public Id opportunityId {get; set;}
        @AuraEnabled
        public List<UnitDesign__c>unitDesignInfo {get; set;}
        
        
        @AuraEnabled
        public Id unitId {get; set;}
        @AuraEnabled
        public Id offerId {get; set;}
        @AuraEnabled
        public integer totalUnitOffered {get; set;}
        @AuraEnabled
        public Decimal totalOfAllUnitSellingPrice {get; set;}
        @AuraEnabled
        public Decimal totalOfAllUnitNetSellingPrice {get; set;}
        @AuraEnabled
        public Lead leadRecord {get; set;}
        @AuraEnabled
        public Opportunity opportunityRecord {get; set;}
        
        @AuraEnabled 
        public Decimal admFeeTobeChargedAmount {get; set;}
        @AuraEnabled 
        public Decimal admFeeTobeChargedPercentage {get; set;}
        
        @AuraEnabled 
        public Map<id,Set<Map<String,Decimal>>>paymentIdvsUnitMixMap {get; set;}
        
        
        @AuraEnabled
        public Id unitDesignRecordId {get; set;}
        @AuraEnabled
        public boolean hasUnitDesign {get; set;}
        @AuraEnabled
        public list<map<String,string>> availableUnitDesigns {get; set;}
        
        @AuraEnabled
        public contact contactRecord {get; set;}
        @AuraEnabled
        public Unit__c unitRecord {get; set;}
        @AuraEnabled
        public OffersPromotions__c offerRecord {get; set;}
        @AuraEnabled
        public list<OfferLines__c> applicableOfferLinesCalculated {get; set;}
        @AuraEnabled
        public list<PaymentPlanWrapper> applicablePaymentPlansCalculated {get; set;}
        @AuraEnabled
        public boolean offersAvailable {get; set;}
        @AuraEnabled
        public boolean offerLinesApplied {get; set;}
        @AuraEnabled
        public set<map<String,string>> availablePaymentPlans {get; set;}
        @AuraEnabled
        public list<map<String,string>> availablePaymentPlansWithMemo {get; set;}
        @AuraEnabled
        public list<map<String,string>> availableOffers {get; set;}
        @AuraEnabled
        public list<map<String,string>> availableWithMemoOffers {get; set;}
        @AuraEnabled
        public boolean multiPurposeAmountApplicable {get; set;}
        public SalesOfferDetails(){totalOfAllUnitNetSellingPrice=0;}
        
    }
    
    public with sharing class SaleOfferInputParam{
        @AuraEnabled
        public Id unitId {get; set;}
        @AuraEnabled
        public Id offerId {get; set;}
        @AuraEnabled
        public list<Id> selectedPayments {get; set;}
        @AuraEnabled
        public boolean multiPurposeAmountApplicable {get; set;}
        
        @AuraEnabled
        public String finishingtypeValue {get; set;}
        @AuraEnabled
        public boolean admincludedfee {get; set;}
        
        @AuraEnabled
        public Id designId {get; set;}
        @AuraEnabled
        public String paymentMethod {get; set;}
        @AuraEnabled
        public String unitFinishes {get; set;}
        @AuraEnabled
        public String unitFurnishing {get; set;}
        
        @AuraEnabled
        public boolean mortgageApplicable {get; set;}
        @AuraEnabled
        public String mortgageBank {get; set;}
        @AuraEnabled
        public decimal amount {get; set;}
        @AuraEnabled
        public String amountType {get; set;}
    }
    
    public with sharing class PaymentPlanWrapper{
        @AuraEnabled
        public string description {get; set;}
        @AuraEnabled
        public boolean isSelected {get; set;}
        
        
        
        @AuraEnabled
        public Decimal discountedUnitSalesPrice {get; set;}
        @AuraEnabled
        public Decimal bulkDiscountAmount {get; set;}
        @AuraEnabled
        public Decimal corporateDiscountAmount {get; set;}
        @AuraEnabled
        public Decimal wealthDiscountAmount {get; set;}
        @AuraEnabled
        public Decimal paymentPlanDiscountAmount {get; set;}
        @AuraEnabled
        public Decimal pmWavedFee {get; set;}
        @AuraEnabled
        public Decimal netSalesPrice {get; set;}
        @AuraEnabled
        public Decimal netSalesPriceExcluwaiver {get; set;}
        @AuraEnabled
        public Decimal rebateAmount {get; set;}
        @AuraEnabled
        public Decimal partnerDiscountAmount {get; set;}
        @AuraEnabled
        public Decimal premiumAmmount {get; set;}
        @AuraEnabled
        public Decimal admFeeWaiverAmount {get; set;} 
        @AuraEnabled
        public Decimal serviceChargeAmount {get; set;} 
        @AuraEnabled
        public Integer serviceChargeWaivedYears {get; set;} 
        @AuraEnabled
        public Decimal pmWavedFeeYears {get; set;}
        
        @AuraEnabled
        public Decimal homeMaintenanceWavierYears {get; set;}
        
        @AuraEnabled
        public Decimal externalComissionAmount {get; set;}
        @AuraEnabled
        public string externalComissionAmountBasis {get; set;}
        @AuraEnabled
        public Decimal mortgageSubsidy {get; set;}
        @AuraEnabled
        public Decimal otherSalesSupportAmount {get; set;}
         @AuraEnabled
        public Map<id,boolean>unitIdToAdmFeeIncludeValue {get; set;}

         @AuraEnabled
        public Map<id,boolean>unitIdToOfferAdmFeeIncludeVal {get; set;}
        
        
        
        @AuraEnabled
        public Decimal internalComissionAmount {get; set;}
        @AuraEnabled
        public Decimal internalStaffComissionAmount {get; set;}
        @AuraEnabled
        public Decimal internalReferralComissionAmount {get; set;}
        @AuraEnabled
        public Decimal discountAmount {get; set;}
        @AuraEnabled
        public PaymentPlan__c paymentPlanDetails {get; set;}
        @AuraEnabled
        public list<PaymentInstallmentWrapper> installmentDetails {get; set;}
        public PaymentPlanWrapper(){}
        public PaymentPlanWrapper(PaymentPlan__c tempRec , Decimal sellingPrice){
            isSelected=(tempRec.StandardFlag__c!=null && tempRec.StandardFlag__c.equalsIgnoreCase('YES'));   //Constant Constants.YES replaced 
            paymentPlanDetails=tempRec;
            installmentDetails=new list<PaymentInstallmentWrapper>();
            for(PaymentInstallments__c tempInstallmentRec: tempRec.PaymentInstallments__r){
                installmentDetails.add(new PaymentInstallmentWrapper( tempInstallmentRec ,sellingPrice));
            }
        }
    } 
    
    public with sharing class PaymentInstallmentWrapper{
        @AuraEnabled
        public decimal totalValue {get; set;}
        @AuraEnabled
        public PaymentInstallments__c installmentRecord {get; set;}
        public PaymentInstallmentWrapper(PaymentInstallments__c tempRec , Decimal sellingPrice){
            tempRec.InstallmentDate__c = ((tempRec.InstallmentDate__c!=null && tempRec.InstallmentDate__c < system.today() ) || tempRec.InstallmentNumber__c == 1) ? system.today(): tempRec.InstallmentDate__c;
            installmentRecord=tempRec;
            
            totalValue = (tempRec.InstallmentPercentage__c!=null && sellingPrice!=null ) ? ((tempRec.InstallmentPercentage__c/100) * sellingPrice) : sellingPrice;
            
            totalValue = totalValue.setScale(2);
            
        }
        
    }
    
    public static map<id,SalesOfferDetails> generateSalesOfferMap(map<Id,Id> unitIdToOffer,map<Id,boolean> unitToMultiPurposeAmountApplicableMap,map<Id,set<Id>> unitToSelectedPaymentPlanMap, map<Id,ID> selectedDesignMap ,Id opportunityOrLedId,Integer SelectedUnitCount,Map<id,String>unitIdToFinishtypeOption,Map<Id,Boolean>unitIdToAdmFeeIncluded ){
        System.debug('unitIdToFinishtypeOption'+unitIdToFinishtypeOption);
        User loggedInUser = [SELECT Id,Name,ProfileName__c,UserRole.Name,Profile.Name, UserRole.Id,AccountId, ContactId, Contact.AccountId,Contact.AgentID__c,Team__c,Email,UserRoleId,ProfileId,FullPhotoUrl,Title,Manager.Name,MobilePhone  FROM USER WHERE Id=:UserInfo.getUserId()];
        String userProfileName = loggedInUser.ProfileName__c;
        map<id,SalesOfferDetails> salesOffersMapToreturn = new map<id,SalesOfferDetails>();
        map<id,Unit__c> unitsToProcess = new map<id,Unit__c>();
        map<id,Lead> leadMap = new map<id,Lead>();
        map<id,Opportunity> opportunityMap = new map<id,Opportunity>();
        map<id,set<Id>> buildingToPaymentPlanIdsMap = new map<id,set<Id>>();
        map<id,list<OffersPromotions__c>> buildingOrProjectToOfferMap = new map<id,list<OffersPromotions__c>>();
        map<id,OffersPromotions__c> unitToOfferMap = new map<id,OffersPromotions__c>();
        Map<Id, Set<Map<String, Decimal>>> paymentIdvsUnitMixMapforError = new Map<Id, Set<Map<String, Decimal>>>();
        
        list<DiscountOrderSetting__mdt> discountSequenceList = [select id, Order__c, MasterLabel from DiscountOrderSetting__mdt order by Order__c];
        Decimal totalOfAllUnitSalesPrice=0;
        List<Unit__c> allUnitsData = getAllUnitsById( unitIdToOffer.keySet() );
        for(Unit__c tempUnitRec :  allUnitsData){
            unitsToProcess.put(tempUnitRec.Id, tempUnitRec);
            totalOfAllUnitSalesPrice=(totalOfAllUnitSalesPrice+tempUnitRec.SellingPrice__c).setScale(2);
            if(tempUnitRec.BuildingSectionName__c!=null){
                buildingToPaymentPlanIdsMap.put(tempUnitRec.BuildingSectionName__c,new set<Id>());
                System.debug('buildingToPaymentPlanIdsMap'+buildingToPaymentPlanIdsMap);
                buildingOrProjectToOfferMap.put(tempUnitRec.BuildingSectionName__c,new list<OffersPromotions__c>());
            }
            if(tempUnitRec.Project__c!=null){
                buildingOrProjectToOfferMap.put(tempUnitRec.Project__c,new list<OffersPromotions__c>());
            }
        }
        map<id,List<map<string,string>>> relatedDesignOptions = new map<id,List<map<string,string>>>();
        if(opportunityOrLedId.getsobjecttype() == Opportunity.sobjecttype){
            opportunityMap = OpportunityService.getOpportunityDetailsMapbyId(opportunityOrLedId);
        }else if(opportunityOrLedId.getsobjecttype() == Lead.sobjecttype){
            leadMap = OpportunityService.getLeadDetailsMapbyId(opportunityOrLedId);
        }
        String AccountCustomerSubtype = opportunityMap.containsKey(opportunityOrLedId) ? opportunityMap.get(opportunityOrLedId).Account.CustomerSubType__c : null;
        String opportunityAgetntType = opportunityMap.containsKey(opportunityOrLedId) ? opportunityMap.get(opportunityOrLedId).AgentType__c: null;
        
        
        map<id,PaymentPlan__c> allRelatedPaymentPlans= new map<id,PaymentPlan__c>();
        allRelatedPaymentPlans = new map<id,PaymentPlan__c>(PaymentPlanOffPromotionService.getPaymentPlanByBuidlingIds(buildingToPaymentPlanIdsMap.keySet()));
        System.debug('allRelatedPaymentPlans'+allRelatedPaymentPlans.size());
        
        buildingToPaymentPlanIdsMap = new map<id,set<Id>>(PaymentPlanOffPromotionService.getPaymentPlanIdsByBuidlingIds(buildingToPaymentPlanIdsMap,buildingToPaymentPlanIdsMap.keySet()));
        
        map<id,OffersPromotions__c> offersMap = new map<id,OffersPromotions__c>(PaymentPlanOffPromotionService.getActiveOffersAndPromotions(buildingOrProjectToOfferMap.keySet(),buildingOrProjectToOfferMap.keySet()));
        System.debug('offersMap'+offersMap);
        for(OffersPromotions__c tempOfferRec : offersMap.values()){
            if(buildingOrProjectToOfferMap.containsKey(tempOfferRec.BuildingSectionName__c)){
                buildingOrProjectToOfferMap.get(tempOfferRec.BuildingSectionName__c).add(tempOfferRec);
            }
            if(buildingOrProjectToOfferMap.containsKey(tempOfferRec.Project__c)){
                buildingOrProjectToOfferMap.get(tempOfferRec.Project__c).add(tempOfferRec);
            }
        }
        decimal totalNetSellingPrice=0;
        Map<Id,BrokerCommission__c> unitExternalCommissionMap = new Map<Id,BrokerCommission__c>();
        map<Id,InternalCommission__c> unitInternalCommissionMap = new map<Id,InternalCommission__c>();
        map<id,boolean>unittoIdOfferadm = new Map<id,boolean>();
        for(Id unitID : unitIdToOffer.keySet()){
            unitToOfferMap.put(unitID,offersMap.containsKey(unitIdToOffer.get(unitID))?offersMap.get(unitIdToOffer.get(unitID)):null);
           
        }
        System.debug('unitToOfferMap'+unitToOfferMap);
       for (Id unitID : unitToOfferMap.keySet()) {
    OffersPromotions__c offer = unitToOfferMap.get(unitID);
    Boolean admFeeIncluded = offer != null ? offer.ADM_Fee_Included__c : null;
    
    // Put the value in the new map
    unitToIdOfferAdm.put(unitID, admFeeIncluded);
    System.debug('unitToIdOfferAdm'+unitToIdOfferAdm);
       }
       
        if(opportunityMap.containskey(opportunityOrLedId)){
            unitExternalCommissionMap = CommissionService.getBrokerCommissions(opportunityMap.get(opportunityOrLedId),allUnitsData, unitToOfferMap );
            unitInternalCommissionMap =  CommissionService.getInternalCommissions(opportunityMap.get(opportunityOrLedId),allUnitsData, unitToOfferMap );
        }
        Set<Id> PaymentPlanids = new Set<Id>();
        for(Id unitID : unitIdToOffer.keySet()){
            System.debug('unitToSelectedPaymentPlanMap'+unitToSelectedPaymentPlanMap.get(unitID));
            Set<Id> unitPaymentPlanIds = unitToSelectedPaymentPlanMap.get(unitID);
            if (unitPaymentPlanIds != null) {
                PaymentPlanids.addAll(unitPaymentPlanIds);
            }
            System.debug('PaymentPlanids'+PaymentPlanids);
        }
        
        System.debug('PaymentPlanids'+PaymentPlanids);
        List<Payment_Plan_Offer__c> paymentPlanOfferList = new List<Payment_Plan_Offer__c>();
        if(!PaymentPlanids.isEmpty()){
            paymentPlanOfferList = [Select id,Offer_Promotion__c,Offer_Promotion__r.Name,Payment_Plan__c,Payment_Plan__r.Offers_Based_On_Payment_Plan__c 
                                    From Payment_Plan_Offer__c 
                                    where Payment_Plan__c IN :PaymentPlanids AND Payment_Plan__r.Offers_Based_On_Payment_Plan__c=true];
        }
        System.debug('paymentPlanOfferList'+paymentPlanOfferList);
        
        Map<String,String>paymentPlanOfferMap = new Map<String,String>();
        if(paymentPlanOfferList.size()>0){
            for(Payment_Plan_Offer__c ppo: paymentPlanOfferList){
                paymentPlanOfferMap.put(ppo.Offer_Promotion__r.Name,ppo.Offer_Promotion__c);
            }
        }
        
        for(Id unitID : unitIdToOffer.keySet()){
            SalesOfferDetails salesOfferObj= new SalesOfferDetails();
            salesOfferObj.leadId = opportunityOrLedId.getsobjecttype() == Lead.sobjecttype?opportunityOrLedId:null;
            salesOfferObj.opportunityId = opportunityOrLedId.getsobjecttype() == Opportunity.sobjecttype?opportunityOrLedId:null;
            salesOfferObj.unitId=unitID;
            salesOfferObj.offerId=unitIdToOffer.get(unitID);
            salesOfferObj.totalOfAllUnitSellingPrice=totalOfAllUnitSalesPrice.setScale(2);
            salesOfferObj.totalUnitOffered = unitIdToOffer.size();
            salesOfferObj.opportunityRecord = salesOfferObj.opportunityId!=null ? opportunityMap.get(opportunityOrLedId) :null ;
            salesOfferObj.leadRecord = salesOfferObj.leadId!=null ? LeadMap.get(opportunityOrLedId) :null ;
            salesOfferObj.unitRecord = unitsToProcess.get(unitId);
            
            salesOfferObj.offerRecord = offersMap.containsKey(salesOfferObj.offerId)?offersMap.get(salesOfferObj.offerId):null;
            boolean memoOffer = (salesOfferObj.offerRecord!=null && salesOfferObj.offerRecord.BookingMemo__c!=null)?true:false;
            salesOfferObj.availableOffers = new list<map<String,string>>();
            salesOfferObj.availableWithMemoOffers = new list<map<String,string>>();
            salesOfferObj.unitDesignRecordId = (selectedDesignMap!=null && selectedDesignMap.containsKey(unitID) && selectedDesignMap.get(unitID)!=null)?selectedDesignMap.get(unitID):null;
            //salesOfferObj.unitDesignRecord = (salesOfferObj.unitDesignRecordId!=null &&  unitDesignMap.containsKey(salesOfferObj.unitDesignRecordId) )? unitDesignMap.get(salesOfferObj.unitDesignRecordId) :null;
            salesOfferObj.availableUnitDesigns = relatedDesignOptions.containsKey(unitID)  ? relatedDesignOptions.get(unitID)  : new list<map<String,string>>();
            salesOfferObj.hasUnitDesign =  !salesOfferObj.availableUnitDesigns.isEmpty();
            // salesOfferObj.multiPurposeAmountApplicable= (!unitToMultiPurposeAmountApplicableMap.isEmpty() && unitToMultiPurposeAmountApplicableMap.containsKey(unitID) )? unitToMultiPurposeAmountApplicableMap.get(unitID) :  ( (salesOfferObj.unitRecord.BuildingSectionName__r.EligibileforMultiPurposeRoom__c || salesOfferObj.hasUnitDesign )?true:false);
            salesOfferObj.availableOffers.add(new map<string,string>{'label' =>'None' , 'value' => ''});
            salesOfferObj.availableWithMemoOffers.add(new map<string,string>{'label' =>'None' , 'value' => ''});
            
            
            if(salesOfferObj.unitRecord.Project__c!=null && buildingOrProjectToOfferMap.containsKey(salesOfferObj.unitRecord.Project__c) ){
                for(OffersPromotions__c tempOfferRec : buildingOrProjectToOfferMap.get(salesOfferObj.unitRecord.Project__c) ){
                    System.debug('tempoffer'+tempOfferRec);
                    if(tempOfferRec.BuildingSectionName__c==null && salesOfferObj.unitRecord.Project__c == tempOfferRec.Project__c ){
                        if (userProfileName.contains('Broker Agency')) 
                        {
                            if (tempOfferRec.BrokerPortalFlag__c == true ) 
                            {
                                salesOfferObj.availableOffers.add(new map<string,string>{'label' =>tempOfferRec.Name , 'value' => tempOfferRec.Id});
                            }
                        } else if (tempOfferRec.BookingMemo__c==null  && paymentPlanOfferList.size()==0 ) 
                        { 
                            System.debug('tempoffer'+tempOfferRec);
                            if (((AccountCustomerSubtype!=null && opportunityAgetntType!=null)||(AccountCustomerSubtype==null && opportunityAgetntType!=null)) &&
                                ((tempOfferRec.Customer_Sub_Type__c == AccountCustomerSubtype && tempOfferRec.Direct_Indirect__c == opportunityAgetntType) ||
                                 (tempOfferRec.Direct_Indirect__c == null && tempOfferRec.Customer_Sub_Type__c == AccountCustomerSubtype)||(tempOfferRec.Direct_Indirect__c ==AccountCustomerSubtype && tempOfferRec.Customer_Sub_Type__c == null))) {
                                     salesOfferObj.availableOffers.add(new Map<String, String>{'label' => tempOfferRec.Name, 'value' => tempOfferRec.Id});
                                 }  
                            
                        }
                        else if(tempOfferRec.BookingMemo__c==null && paymentPlanOfferList.size()>0){
                            System.debug('tempoffer'+tempOfferRec);
                            if(paymentPlanOfferMap.containsKey(tempOfferRec.Name)){
                                salesOfferObj.availableOffers.add(new Map<String, String>{'label' => tempOfferRec.Name, 'value' => tempOfferRec.Id});
                                
                            }
                            System.debug('availableOffers'+salesOfferObj.availableOffers);
                        }  
                        if (tempOfferRec.BookingMemo__c !=null ) 
                        {
                            if (tempOfferRec.BookingMemo__r.OwnerId == loggedInUser.Id && tempOfferRec.Unit__c == salesOfferObj.unitId) 
                            {
                                salesOfferObj.availableWithMemoOffers.add(new map<string,string>{'label' =>tempOfferRec.Name , 'value' => tempOfferRec.Id});
                            }
                        }
                        else
                        {
                            salesOfferObj.availableWithMemoOffers.add(new map<string,string>{'label' =>tempOfferRec.Name , 'value' => tempOfferRec.Id});
                        }
                    }
                    
                }
            }
            if(salesOfferObj.unitRecord.BuildingSectionName__c!=null && buildingOrProjectToOfferMap.containsKey(salesOfferObj.unitRecord.BuildingSectionName__c) ){
                for(OffersPromotions__c tempOfferRec : buildingOrProjectToOfferMap.get(salesOfferObj.unitRecord.BuildingSectionName__c) ){
                    if(salesOfferObj.unitRecord.BuildingSectionName__c ==tempOfferRec.BuildingSectionName__c ){
                        if (userProfileName.contains('Broker Agency')) 
                        {
                            if (tempOfferRec.BrokerPortalFlag__c == true ) 
                            { 
                                salesOfferObj.availableOffers.add(new map<string,string>{'label' =>tempOfferRec.Name , 'value' => tempOfferRec.Id});
                            }
                        }
                        else if (tempOfferRec.BookingMemo__c==null  && paymentPlanOfferList.size()==0 ) 
                        {
                            
                            if (((AccountCustomerSubtype!=null && opportunityAgetntType!=null)||(AccountCustomerSubtype==null && opportunityAgetntType!=null)) &&
                                ((tempOfferRec.Customer_Sub_Type__c == AccountCustomerSubtype && tempOfferRec.Direct_Indirect__c == opportunityAgetntType) ||
                                 (tempOfferRec.Direct_Indirect__c == null && tempOfferRec.Customer_Sub_Type__c == AccountCustomerSubtype)||(tempOfferRec.Direct_Indirect__c ==AccountCustomerSubtype && tempOfferRec.Customer_Sub_Type__c == null))) {
                                     salesOfferObj.availableOffers.add(new Map<String, String>{'label' => tempOfferRec.Name, 'value' => tempOfferRec.Id});
                                     System.debug('availableOffers'+salesOfferObj.availableOffers);
                                 }
                        }
                        else if(tempOfferRec.BookingMemo__c==null && paymentPlanOfferList.size()>0){
                            System.debug('tempoffer'+tempOfferRec);
                            if(paymentPlanOfferMap.containsKey(tempOfferRec.Name)){
                                salesOfferObj.availableOffers.add(new Map<String, String>{'label' => tempOfferRec.Name, 'value' => tempOfferRec.Id});
                                
                            }
                            System.debug('availableOffers'+salesOfferObj.availableOffers);
                        }  
                        
                        if (tempOfferRec.BookingMemo__c != null) 
                        {
                            if (tempOfferRec.BookingMemo__r.OwnerId == loggedInUser.Id && tempOfferRec.Unit__c == salesOfferObj.unitId) 
                            {
                                salesOfferObj.availableWithMemoOffers.add(new map<string,string>{'label' =>tempOfferRec.Name , 'value' => tempOfferRec.Id});
                            }
                        }
                        else
                        {
                            salesOfferObj.availableWithMemoOffers.add(new map<string,string>{'label' =>tempOfferRec.Name , 'value' => tempOfferRec.Id});
                        }
                    }
                    
                }
            }
            salesOfferObj.offersAvailable = (salesOfferObj.availableOffers.size()!=1);
            salesOfferObj.applicableOfferLinesCalculated = new list<OfferLines__c>();
            if(salesOfferObj.offerRecord != null){
                salesOfferObj.applicableOfferLinesCalculated = getApplicableOfferLines(salesOfferObj.offerRecord.Offers_Lines__r,salesOfferObj.unitRecord,salesOfferObj.opportunityRecord,salesOfferObj.leadRecord ,salesOfferObj.totalUnitOffered, salesOfferObj.totalOfAllUnitSellingPrice );
            }
            salesOfferObj.offerLinesApplied = !(salesOfferObj.applicableOfferLinesCalculated.isEmpty());
            map<string,decimal> discountNameToPercentage = new map<string,decimal>();
            decimal admWavierPercentage = 0;
            decimal homeMaintenanceWavierYears = 0;
            decimal serviceChargesWavierYears = 0;
            decimal pmWavedFeeYears=0;
            decimal otherSalesSupport = 0;
            decimal subsidy = 0;
            
            decimal pmWavedFee = 0;
            decimal offerLevelRebate = 0;
            decimal offerlevelPremium =  0;
            decimal internalCommissionMemo = 0;
            decimal externalCommissionMemo = 0;
            Set<id> descriptionPaymentPlaid = new set<id>();
            for(Id tempPaymentId : buildingToPaymentPlanIdsMap.get(salesOfferObj.unitRecord.BuildingSectionName__c)){
                descriptionPaymentPlaid.add(tempPaymentId);
                // String description=[select id,Description__c from PaymentPlan__c where id=:tempPaymentId].Description__c;
            }
            List<PaymentPlan__c> Descriptionlist = [SELECT Id, Description__c FROM PaymentPlan__c WHERE Id IN :descriptionPaymentPlaid];
            System.debug('Descriptionlist'+Descriptionlist);
            System.debug('salesOfferObj.applicableOfferLinesCalculated'+salesOfferObj.applicableOfferLinesCalculated);
            for(OfferLines__c tempOfferLine : salesOfferObj.applicableOfferLinesCalculated){
                tempOfferLine.OfferValue__c = tempOfferLine.OfferValue__c.setScale(2);
                if(!memoOffer && tempOfferLine.OfferType__c.equalsIgnoreCase('Additional Discount') && tempOfferLine.DiscountType__c!=null  )
                { 
                    if(!discountNameToPercentage.containsKey(tempOfferLine.DiscountType__c.toLowerCase())) 
                    {
                        discountNameToPercentage.put(tempOfferLine.DiscountType__c.toLowerCase(),0);
                    }
                    discountNameToPercentage.put(tempOfferLine.DiscountType__c.toLowerCase(), discountNameToPercentage.get(tempOfferLine.DiscountType__c.toLowerCase())+ (tempOfferLine.OfferValue__c/100));
                }
                else if(memoOffer && tempOfferLine.OfferType__c.equalsIgnoreCase('Additional Discount') && tempOfferLine.BudgetTaskName__c == 'Discount' )
                {
                    discountNameToPercentage.put('PaymentPlanDiscount__c'.toLowerCase(),tempOfferLine.OfferValue__c/100);
                }
                else if(tempOfferLine.OfferType__c.equalsIgnoreCase('Rebate') && tempOfferLine.OfferValue__c!=null )
                {
                    offerLevelRebate= offerLevelRebate + tempOfferLine.OfferValue__c;
                }
                else if(tempOfferLine.OfferType__c.equalsIgnoreCase('Premium Discount') && tempOfferLine.OfferValue__c!=null )
                {
                    offerlevelPremium = offerlevelPremium + tempOfferLine.OfferValue__c;
                }
                if(tempOfferLine.BudgetTaskName__c!=null){
                    if( tempOfferLine.BudgetTaskName__c.equalsIgnoreCase('ADM Fee')  ){
                        admWavierPercentage= admWavierPercentage + (tempOfferLine.OfferValue__c);
                        System.debug(admWavierPercentage);
                    }else if(tempOfferLine.BudgetTaskName__c.equalsIgnoreCase('Home Maintenance') ){
                        homeMaintenanceWavierYears= homeMaintenanceWavierYears + tempOfferLine.OfferValue__c;
                        System.debug(homeMaintenanceWavierYears);
                    }else if(tempOfferLine.BudgetTaskName__c.equalsIgnoreCase('Home Maintenance') ){
                        homeMaintenanceWavierYears= homeMaintenanceWavierYears + tempOfferLine.OfferValue__c;
                        
                    }else if(tempOfferLine.BudgetTaskName__c.equalsIgnoreCase('PM Fee') ){
                        pmWavedFeeYears = pmWavedFeeYears + tempOfferLine.OfferValue__c;
                        System.debug('pmWavedFeeYears'+pmWavedFeeYears);
                    }else if(tempOfferLine.BudgetTaskName__c.equalsIgnoreCase('Service Charges') ){ 
                        
                        serviceChargesWavierYears=  serviceChargesWavierYears + tempOfferLine.OfferValue__c;
                        System.debug('serviceChargesWavierYears'+serviceChargesWavierYears);
                    }else if(tempOfferLine.BudgetTaskName__c.equalsIgnoreCase('Subsidy') ){ 
                        subsidy =  subsidy + tempOfferLine.OfferValue__c;
                    }
                    
                    else if(tempOfferLine.BudgetTaskName__c.equalsIgnoreCase('Internal Commission') ){ 
                        internalCommissionMemo =  internalCommissionMemo + tempOfferLine.OfferValue__c;
                    }else if(tempOfferLine.BudgetTaskName__c.equalsIgnoreCase('External Commission') ){ 
                        externalCommissionMemo =  externalCommissionMemo + tempOfferLine.OfferValue__c;
                    }else if(tempOfferLine.BudgetTaskName__c.equalsIgnoreCase('Others') && tempOfferLine.OfferOn__c.equalsIgnoreCase('PM Fee') ){ 
                        if(salesOfferObj.unitRecord.BuildingSectionName__r.PropertyManagementFee__c !=null && salesOfferObj.unitRecord.MarketLeaseRent__c !=null ){
                            otherSalesSupport=  otherSalesSupport + ((salesOfferObj.unitRecord.BuildingSectionName__r.PropertyManagementFee__c/100) * salesOfferObj.unitRecord.MarketLeaseRent__c * tempOfferLine.OfferValue__c);
                            pmWavedFee = pmWavedFee + ((salesOfferObj.unitRecord.BuildingSectionName__r.PropertyManagementFee__c/100) * salesOfferObj.unitRecord.MarketLeaseRent__c * tempOfferLine.OfferValue__c);
                        }
                        
                    }else if(tempOfferLine.BudgetTaskName__c.equalsIgnoreCase('Others') ){ //Constant Constants.BUDGET_LINE_OTHER replaced 
                        otherSalesSupport=  otherSalesSupport + tempOfferLine.OfferValue__c;
                    }
                }
            }
            salesOfferObj.applicablePaymentPlansCalculated = new list<PaymentPlanWrapper>();
            salesOfferObj.availablePaymentPlans = new set<map<string,string>>();
            salesOfferObj.availablePaymentPlansWithMemo = new list<map<string,string>>();
            set<ID> selectedPlans= new set<ID>();
            set<ID> standardPlans= new set<ID>();
            Set<id> paymentPlanIdforDescription = new Set<id>();
            
            if(buildingToPaymentPlanIdsMap.containsKey(salesOfferObj.unitRecord.BuildingSectionName__c)){
                for(Id tempPaymentId : buildingToPaymentPlanIdsMap.get(salesOfferObj.unitRecord.BuildingSectionName__c)){
                    // String description=[select id,Description__c from PaymentPlan__c where id=:tempPaymentId].Description__c;
                    //System.debug('description'+description.size());
                    if(salesOfferObj.opportunityRecord!=null && allRelatedPaymentPlans.get(tempPaymentId).CustomerSubType__c!=null && salesOfferObj.opportunityRecord.Account.CustomerSubType__c != allRelatedPaymentPlans.get(tempPaymentId).CustomerSubType__c){
                        continue;
                    }
                    boolean isAvailablePlan=false;
                    if (userProfileName.contains('Broker Agency')) 
                    {  
                        if (allRelatedPaymentPlans.get(tempPaymentId).BrokerPortalFlag__c == true ) 
                        {
                            salesOfferObj.availablePaymentPlans.add(new map<string,string>{'label' =>allRelatedPaymentPlans.get(tempPaymentId).Name , 'value' => allRelatedPaymentPlans.get(tempPaymentId).Id});
                            isAvailablePlan=true;
                        }
                        if(allRelatedPaymentPlans.get(tempPaymentId).BrokerPortalFlag__c == true  && allRelatedPaymentPlans.get(tempPaymentId).StandardFlag__c!=null && allRelatedPaymentPlans.get(tempPaymentId).StandardFlag__c == 'Yes')
                        {  
                            standardPlans.add(tempPaymentId);
                        }
                    }
                    
                    else if (allRelatedPaymentPlans.get(tempPaymentId).BookingMemo__c == null ) 
                    {
                        Decimal maxUnitPaymentPlan = allRelatedPaymentPlans.get(tempPaymentId).Maximum_No_Of_Units__c;
                        Decimal minUnitPaymentPlan = allRelatedPaymentPlans.get(tempPaymentId).Minimum_No_Of_Units__c;
                        System.debug('maxUnitPaymentPlan'+maxUnitPaymentPlan);
                        if(maxUnitPaymentPlan!=null && minUnitPaymentPlan!=null && maxUnitPaymentPlan>=SelectedUnitCount && minUnitPaymentPlan<=SelectedUnitCount ){
                            salesOfferObj.availablePaymentPlans.add(new map<string,string>{'label' =>allRelatedPaymentPlans.get(tempPaymentId).Name , 'value' => allRelatedPaymentPlans.get(tempPaymentId).Id});
                        }
                        isAvailablePlan=true;
                        if(allRelatedPaymentPlans.get(tempPaymentId).StandardFlag__c!=null && allRelatedPaymentPlans.get(tempPaymentId).StandardFlag__c == 'Yes'){ //Constant Constants.YES replaced 
                            standardPlans.add(tempPaymentId);
                        }
                    }
                    
                    if (allRelatedPaymentPlans.get(tempPaymentId).BookingMemo__c != null) 
                    {
                        if (allRelatedPaymentPlans.get(tempPaymentId).Unit__c  == salesOfferObj.unitId && allRelatedPaymentPlans.get(tempPaymentId).BookingMemo__r.OwnerId == loggedInUser.Id ) {
                            salesOfferObj.availablePaymentPlansWithMemo.add(new map<string,string>{'label' =>allRelatedPaymentPlans.get(tempPaymentId).Name , 'value' => allRelatedPaymentPlans.get(tempPaymentId).Id});
                            isAvailablePlan=true;
                            if(allRelatedPaymentPlans.get(tempPaymentId).StandardFlag__c!=null && allRelatedPaymentPlans.get(tempPaymentId).StandardFlag__c == 'Yes'){ //Constant Constants.YES replaced 
                                standardPlans.add(tempPaymentId);
                            }
                        }
                    }
                    else
                    {
                        salesOfferObj.availablePaymentPlansWithMemo.add(new map<string,string>{'label' =>allRelatedPaymentPlans.get(tempPaymentId).Name , 'value' => allRelatedPaymentPlans.get(tempPaymentId).Id});
                        isAvailablePlan=true;
                        if(allRelatedPaymentPlans.get(tempPaymentId).StandardFlag__c!=null && allRelatedPaymentPlans.get(tempPaymentId).StandardFlag__c == 'Yes'){ //Constant Constants.YES replaced 
                            standardPlans.add(tempPaymentId);
                        }
                    }
                    if(!isAvailablePlan)
                    { 
                        continue;
                    }
                    if(!memoOffer && allRelatedPaymentPlans.containsKey(tempPaymentId) ){
                        allRelatedPaymentPlans.get(tempPaymentId).PaymentPlanDiscount__c = allRelatedPaymentPlans.get(tempPaymentId).PaymentPlanDiscount__c !=null?allRelatedPaymentPlans.get(tempPaymentId).PaymentPlanDiscount__c:0;
                        discountNameToPercentage.put('PaymentPlanDiscount__c'.toLowerCase(), (allRelatedPaymentPlans.get(tempPaymentId).PaymentPlanDiscount__c/100));
                    }
                    Decimal calculatedWealthDiscountAmount = 0;
                    Decimal calculatedCorporateDiscountAmount = 0;
                    Decimal calculatedBulkDiscountAmount = 0;
                    Decimal calculatedPaymentPlanDiscountAmount = 0;
                    Decimal totalDiscountedPrice=0;
                    
                    System.debug('unitid: ' + unitIdToFinishtypeOption);
                    
                    List<UnitDesign__c> unitDesignDetail = [SELECT Id, Unit__c, DesignType__c, SellingPrice__c 
                                                            FROM UnitDesign__c 
                                                            WHERE Unit__c IN :unitIdToFinishtypeOption.keySet()];
                    
                    salesOfferObj.unitDesignInfo = unitDesignDetail;
                    System.debug('unitIdToFinishtypeOption'+unitIdToFinishtypeOption);
                    System.debug('unitDesignDetail: ' + unitDesignDetail);
                    System.debug('unitId: ' + salesOfferObj.unitRecord.Id + ' finishvalue: ' + unitIdToFinishtypeOption.get(salesOfferObj.unitRecord.Id));
                    if(!salesOfferObj.unitDesignInfo.isEmpty()){
                        for (UnitDesign__c designInfo : salesOfferObj.unitDesignInfo) {
                            
                            if (salesOfferObj.unitRecord.Id == designInfo.Unit__c &&
                                designInfo.DesignType__c == unitIdToFinishtypeOption.get(salesOfferObj.unitRecord.Id)) {
                                    
                                    totalDiscountedPrice = designInfo.SellingPrice__c;
                                    System.debug('totalDiscountedPrice: ' + totalDiscountedPrice);
                                    
                                    break;
                                }
                        }}
                    System.debug('totalDiscountedPrice'+totalDiscountedPrice);
                    if (totalDiscountedPrice ==0) {
                        totalDiscountedPrice = salesOfferObj.unitRecord.SellingPrice__c;
                        System.debug('totalDiscountedPrice: ' + totalDiscountedPrice);
                    } 
                    
                    Decimal unitArea = 0;
                    Decimal internalCommission = 0;
                    Decimal ReferralCommissionAmount = 0;
                    for(DiscountOrderSetting__mdt discountSeq :  discountSequenceList){
                        if(discountNameToPercentage.containsKey(discountSeq.MasterLabel.toLowerCase())){
                            if(discountSeq.MasterLabel.equalsIgnoreCase('Bulk Discount')){ //Constant Constants.DISCOUNT_TYPE_BULK_DISCOUNT replaced 
                                calculatedBulkDiscountAmount = (totalDiscountedPrice * discountNameToPercentage.get(discountSeq.MasterLabel.toLowerCase())).setScale(2);
                            }else if(discountSeq.MasterLabel.equalsIgnoreCase('Corporate Discount')){ //Constant Constants.DISCOUNT_TYPE_CORPORATE_DISCOUNT replaced 
                                calculatedCorporateDiscountAmount = (totalDiscountedPrice * discountNameToPercentage.get(discountSeq.MasterLabel.toLowerCase())).setScale(2);
                            }else if(discountSeq.MasterLabel.equalsIgnoreCase('Wealth Discount')){ //Constant Constants.DISCOUNT_TYPE_WEALTH_DISCOUNT replaced 
                                calculatedWealthDiscountAmount = (totalDiscountedPrice * discountNameToPercentage.get(discountSeq.MasterLabel.toLowerCase())).setScale(2);
                            }else{
                                calculatedPaymentPlanDiscountAmount = (totalDiscountedPrice * discountNameToPercentage.get(discountSeq.MasterLabel.toLowerCase())).setScale(2);
                            }
                            totalDiscountedPrice = (totalDiscountedPrice - (totalDiscountedPrice * discountNameToPercentage.get(discountSeq.MasterLabel.toLowerCase()))).setScale(2);
                        }
                    }
                    if(salesOfferObj.unitRecord.MeasuredArea__c !=null)
                    {
                        unitArea = (salesOfferObj.unitRecord.MeasuredArea__c).setScale(2);
                    }
                    else if(salesOfferObj.unitRecord.SaleableArea__c !=null)
                    { 
                        unitArea = (salesOfferObj.unitRecord.SaleableArea__c).setScale(2);
                    } 
                    PaymentPlanWrapper tempPaymentPlanRec;
                   
                   
                   
                    decimal premiumAmmount = (offerlevelPremium).setScale(2);
                    if(allRelatedPaymentPlans.containsKey(tempPaymentId)){
                        tempPaymentPlanRec = new PaymentPlanWrapper( allRelatedPaymentPlans.get(tempPaymentId) ,totalDiscountedPrice.setScale(2));
                    }
                    if(tempPaymentPlanRec != null && unitToSelectedPaymentPlanMap!=null && unitToSelectedPaymentPlanMap.containsKey(unitID) && unitToSelectedPaymentPlanMap.get(unitID)!=null ){
                        tempPaymentPlanRec.isSelected= unitToSelectedPaymentPlanMap.get(unitID).contains(tempPaymentId);
                    }
                    if(tempPaymentPlanRec.isSelected){
                        selectedPlans.add(tempPaymentId);
                        System.debug('selectedPlans'+selectedPlans);
                    }
                    if(allRelatedPaymentPlans.containsKey(tempPaymentId)){
                        tempPaymentPlanRec.premiumAmmount = (premiumAmmount + ( (allRelatedPaymentPlans.get(tempPaymentId).Premium__c!=null && allRelatedPaymentPlans.get(tempPaymentId).Premium__c!= 0)?allRelatedPaymentPlans.get(tempPaymentId).Premium__c:0 )).setScale(2) ;
                    }
                    decimal multiPurposeAmount=0;
                    for (PaymentPlan__c plan : Descriptionlist) {
                        tempPaymentPlanRec.description = plan.Description__c;
                        
                    }
                     tempPaymentPlanRec.unitIdToAdmFeeIncludeValue = new Map<id,boolean>();
                     tempPaymentPlanRec.unitIdToAdmFeeIncludeValue=unitIdToAdmFeeIncluded;
                    tempPaymentPlanRec.unitIdToOfferAdmFeeIncludeVal =  new Map<id,boolean>();
                     tempPaymentPlanRec.unitIdToOfferAdmFeeIncludeVal = unitToIdOfferAdm;
                    system.debug('unitIdToOfferAdmFeeIncludeVal'+tempPaymentPlanRec.unitIdToOfferAdmFeeIncludeVal);
                    tempPaymentPlanRec.discountedUnitSalesPrice =totalDiscountedPrice;
                    tempPaymentPlanRec.netSalesPrice = ( totalDiscountedPrice + tempPaymentPlanRec.premiumAmmount  + multiPurposeAmount  ).setScale(2);
                    
                    tempPaymentPlanRec.netSalesPriceExcluwaiver = tempPaymentPlanRec.netSalesPrice- (1.96077 * tempPaymentPlanRec.netSalesPrice/100);
                    tempPaymentPlanRec.rebateAmount=0;
                   
                    tempPaymentPlanRec.partnerDiscountAmount=(calculatedCorporateDiscountAmount+calculatedWealthDiscountAmount).setScale(2) ;
                   
                        tempPaymentPlanRec.admFeeWaiverAmount = ((tempPaymentPlanRec.netSalesPriceExcluwaiver) * (admWavierPercentage/100 )).setScale(2);
                  
                    
                      tempPaymentPlanRec.otherSalesSupportAmount = otherSalesSupport.setScale(2);
                    System.debug('unitId'+salesOfferObj.unitRecord.id +'unitDesignDetail'+salesOfferObj.unitDesignInfo);
                    if(!salesOfferObj.unitDesignInfo.isEmpty() && (salesOfferObj.unitRecord.id==salesOfferObj.unitDesignInfo[0].Unit__c)&& (salesOfferObj.unitDesignInfo[0].DesignType__c==unitIdToFinishtypeOption.get(salesOfferObj.unitRecord.Id))){
                        System.debug('unitDesignDetail'+unitDesignDetail);
                        tempPaymentPlanRec.discountAmount = (salesOfferObj.unitDesignInfo[0].SellingPrice__c -totalDiscountedPrice).setScale(2);
                    } else {
                        System.debug('unitDesignDetail'+unitDesignDetail);
                        System.debug('unitrecord'+salesOfferObj.unitRecord.id);
                        tempPaymentPlanRec.discountAmount = (salesOfferObj.unitRecord.SellingPrice__c - totalDiscountedPrice).setScale(2);
                    }
                    tempPaymentPlanRec.pmWavedFee=pmWavedFee.setScale(2);
                    tempPaymentPlanRec.pmWavedFeeYears=pmWavedFeeYears.setScale(2);
                    tempPaymentPlanRec.homeMaintenanceWavierYears= homeMaintenanceWavierYears.setScale(2);
                    
                    if(serviceChargesWavierYears!=null && serviceChargesWavierYears!=0 && salesOfferObj.unitRecord.AnticipatedServiceCharges__c != null && unitArea!= null   ){
                        decimal incrementalSC = salesOfferObj.unitRecord.AnticipatedServiceCharges__c;
                        tempPaymentPlanRec.serviceChargeWaivedYears = Integer.ValueOf(serviceChargesWavierYears);
                        
                        for(integer tempi = 1; tempi<= serviceChargesWavierYears ; tempi++ ){
                            
                            incrementalSC =0;// (incrementalSC + ( incrementalSC * (salesOfferObj.unitRecord.EscalationServiceCharge__c/100) )).setScale(2);
                            
                            tempPaymentPlanRec.serviceChargeAmount = ((tempPaymentPlanRec.serviceChargeAmount!=null? tempPaymentPlanRec.serviceChargeAmount : 0) + (incrementalSC * unitArea)).setScale(2);
                        }
                        
                    }
                    
                    /*  if(salesOfferObj.unitRecord.BuildingSectionName__r.HomeMaintenanceFee__c != null){
tempPaymentPlanRec.homeMaintenanceWaiverFee = (homeMaintenanceWavierYears * salesOfferObj.unitRecord.BuildingSectionName__r.HomeMaintenanceFee__c).setScale(2) ;
} */
                    if(memoOffer && externalCommissionMemo!=0 && externalCommissionMemo!=null){
                        tempPaymentPlanRec.externalComissionAmount = ((tempPaymentPlanRec.netSalesPrice) *  (externalCommissionMemo/100)).setScale(2);
                        tempPaymentPlanRec.externalComissionAmountBasis='Percent';  //Constant Constants.COMISSIONBASIS_PERCENT replaced 
                    }else if(opportunityOrLedId!=null && opportunityMap.containsKey(opportunityOrLedId) && opportunityMap.get(opportunityOrLedId).AgentType__c !=null && opportunityMap.get(opportunityOrLedId).AgentType__c.equalsIgnoreCase('Indirect') && unitExternalCommissionMap.get(unitID) != null && (unitExternalCommissionMap.get(unitID).CommissionAmount__c!=null || unitExternalCommissionMap.get(unitID).CommissionPercentage__c!=null )){
                        tempPaymentPlanRec.externalComissionAmount = (unitExternalCommissionMap.get(unitID).CommissionAmount__c!=null? unitExternalCommissionMap.get(unitID).CommissionAmount__c : ( (tempPaymentPlanRec.netSalesPrice) * (unitExternalCommissionMap.get(unitID).CommissionPercentage__c /100 ) )).setScale(2) ;
                        tempPaymentPlanRec.externalComissionAmountBasis=unitExternalCommissionMap.get(unitID).CommissionAmount__c!=null? 'Amount': 'Percent'; //Constant Constants.COMISSIONBASIS_AMOUNT & COMISSIONBASIS_PERCENT replaced 
                    }
                    if(memoOffer && internalCommissionMemo!=0 && internalCommissionMemo!=null )
                    {
                        tempPaymentPlanRec.internalComissionAmount = ((tempPaymentPlanRec.netSalesPrice) * (internalCommissionMemo/100)).setScale(2);
                    }
                    else if(unitInternalCommissionMap.get(unitID) != null && opportunityOrLedId!=null && opportunityMap.containsKey(opportunityOrLedId) )
                    {
                        if (opportunityMap.get(opportunityOrLedId).AgentType__c == 'Direct') 
                        { 
                            internalCommission = unitInternalCommissionMap.get(unitID).DirectCommission__c;
                        } 
                        else 
                        {
                            internalCommission = unitInternalCommissionMap.get(unitID).IndirectCommission__c;
                        }
                        
                        if (opportunityMap.get(opportunityOrLedId).ReferralType__c == 'Referral') { //Constant Constants.OPPORTUINTY_REFERRAL_STAFF replaced 
                            
                            if (unitInternalCommissionMap.get(unitID).StaffReferral__c != null && unitInternalCommissionMap.get(unitID).StaffReferral__c > 0) {
                                ReferralCommissionAmount = ((tempPaymentPlanRec.netSalesPrice) * (unitInternalCommissionMap.get(unitID).StaffReferral__c/100)).setScale(2);
                            } else if (unitInternalCommissionMap.get(unitID).StaffReferralAmount__c != null){
                                ReferralCommissionAmount = unitInternalCommissionMap.get(unitID).StaffReferralAmount__c.setScale(2);
                            }
                        }
                        tempPaymentPlanRec.internalStaffComissionAmount = ((tempPaymentPlanRec.netSalesPrice) * ((internalCommission != null ? internalCommission : 0) /100)).setScale(2) ;
                        tempPaymentPlanRec.internalReferralComissionAmount = ReferralCommissionAmount.setScale(2);
                        tempPaymentPlanRec.internalComissionAmount = ((tempPaymentPlanRec.netSalesPrice) * ((internalCommission != null ? internalCommission : 0) /100) + (ReferralCommissionAmount!= null ? ReferralCommissionAmount : 0)).setScale(2);
                    }
                    
                    tempPaymentPlanRec.bulkDiscountAmount=calculatedBulkDiscountAmount.setScale(2);
                    tempPaymentPlanRec.corporateDiscountAmount=calculatedCorporateDiscountAmount.setScale(2);
                    tempPaymentPlanRec.wealthDiscountAmount=calculatedWealthDiscountAmount.setScale(2);
                    tempPaymentPlanRec.paymentPlanDiscountAmount=calculatedPaymentPlanDiscountAmount.setScale(2);
                    decimal paymentPlanRebate = (!memoOffer && allRelatedPaymentPlans.get(tempPaymentId).RebatePercentage__c != null? allRelatedPaymentPlans.get(tempPaymentId).RebatePercentage__c:0);
                    
                    
                    //  List<PaymentInstallments__c> paymentInstallments = [SELECT Id,Name,InstallmentPercentage__c,Date_Type__c FROM PaymentInstallments__c WHERE PaymentPlan__c = :tempPaymentPlanRec.paymentPlanDetails.Id ];
                    //  System.debug('paymentInstallments'+paymentInstallments);
                    System.debug('paymentInstallments733'+tempPaymentPlanRec.paymentPlanDetails.PaymentInstallments__r);
                    
                     Decimal totalPostHandOverValue = 0;
                    for (PaymentInstallments__c installment : tempPaymentPlanRec.paymentPlanDetails.PaymentInstallments__r) {
                       
                        if (installment.Description__c != null && installment.Description__c.contains('Post HO')) { 
                            System.debug('installment' + installment);
                            totalPostHandOverValue += tempPaymentPlanRec.netSalesPrice * installment.InstallmentPercentage__c;
                            System.debug('totalPostHandOverValue' + totalPostHandOverValue);
                        }
                       
                    }
                     if(totalPostHandOverValue!=0 && totalPostHandOverValue!=null){
                        tempPaymentPlanRec.rebateAmount = ((totalPostHandOverValue / 100) * (offerLevelRebate + paymentPlanRebate) / 100);
                        System.debug('rebateAmount' + tempPaymentPlanRec.rebateAmount);
                        }
                    
                    //   System.debug('rebateamount'+tempPaymentPlanRec.netSalesPrice*.4);
                    //  System.debug('rebateamount'+offerLevelRebate);
                    //   System.debug('rebateamount'+paymentPlanRebate);
                    //  tempPaymentPlanRec.rebateAmount =( (tempPaymentPlanRec.netSalesPrice*.4))/100;
                    //     System.debug('rebateamount'+ tempPaymentPlanRec.rebateAmount);
                    // tempPaymentPlanRec.rebateAmount =  ((tempPaymentPlanRec.netSalesPrice) * ((offerLevelRebate + paymentPlanRebate)/100 )).setScale(2);
                    salesOfferObj.applicablePaymentPlansCalculated.add(tempPaymentPlanRec);
                    if(tempPaymentPlanRec.isSelected){
                        totalNetSellingPrice= (totalNetSellingPrice + tempPaymentPlanRec.netSalesPrice).setScale(2);
                    }
                }
                
            }
            if(selectedPlans.isEmpty() && !standardPlans.isEmpty() && standardPlans.size()==1){
                for(PaymentPlanWrapper tempPaymentPlanRec : salesOfferObj.applicablePaymentPlansCalculated ){
                    if(standardPlans.contains(tempPaymentPlanRec.paymentPlanDetails.Id)){
                        tempPaymentPlanRec.isSelected=true;
                        totalNetSellingPrice=(totalNetSellingPrice + tempPaymentPlanRec.netSalesPrice).setScale(2);
                    }
                }
            }
            salesOffersMapToreturn.put(unitID,salesOfferObj); 
        }
        Set<Id> unitIds = new Set<Id>();
        for (Id unitId : salesOffersMapToreturn.keySet()) {
            unitIds.add(unitId);
        }
        System.debug('unitIds'+unitIds);
        Map<Id,Unit__c> unitMap = new Map<Id, Unit__c>([SELECT Id,Project__r.ADM_Fee_Amount_Charged__c,Project__r.ADM_Fee_Charged_Percentage__c, Project__c FROM Unit__c WHERE Id IN :unitIds]);
        System.debug('unitMap'+unitMap.values());
        for (Id unitID : salesOffersMapToreturn.keySet()) {
            SalesOfferDetails  salesOfferObj = salesOffersMapToreturn.get(unitID);
            Unit__c unitRecord = unitMap.get(unitID);
            System.debug('unitRecord'+unitRecord);
            if (unitRecord != null) {
                
                salesOfferObj.admFeeTobeChargedAmount = unitRecord.Project__r.ADM_Fee_Amount_Charged__c;
                salesOfferObj.admFeeTobeChargedPercentage  = unitRecord.Project__r.ADM_Fee_Charged_Percentage__c;
                salesOfferObj.paymentIdvsUnitMixMap = paymentIdvsUnitMixMapforError;
                System.debug('salesOfferObj.paymentIdvsUnitMixMap' + salesOfferObj.paymentIdvsUnitMixMap);
                
                
            }
            salesOffersMapToreturn.put(unitID, salesOfferObj);
        }
        
        
        for(ID unitID : salesOffersMapToreturn.keySet()){
            salesOffersMapToreturn.get(unitID).totalOfAllUnitNetSellingPrice=totalNetSellingPrice.setScale(2);
        }
        return salesOffersMapToreturn;
    }
    
    
    /*Methods from other classes added*/
    
    public static list<Unit__c> getAllUnitsById(set<ID> unitIds){
        return [select BuildingSectionName__r.TaxPercentage__c,PlotArea__c,BlockedBy__c,Internal_Saleable_Area__c,External_Saleable_Area__c,UnitModel__c,TotalRooms__c,id,Name,UnitPlotArea__c,status__c,InventoryCategory__c,GFAArea__C,Project__r.Name,AnticipatedServiceCharges__c,SaleableArea__c,MeasuredArea__c,BuildingSectionName__r.PropertyManagementFee__c,PropertyStatus__c,CompletionDate__c,Project__c,BuildingSectionName__c,CurrencyIsoCode,SellingPrice__c,MarketPrice__c,NumberOfBedrooms__c,UnitType__c,TotalArea__c,OnlineReservationFee__c,TerraceArea__c,MeasuredInternalArea__c,LockedBy__c,LockExpiryTime__c,NumberOfCarParks__c,Project__r.Amenities__c,Project__r.VirtualTour__c,UnitCategory__c,Project__r.VideoLink__c,Project__r.ADM_Fee_Amount_Charged__c,Project__r.ADM_Fee_Charged_Percentage__c from Unit__c where id in :unitIds];
    }
    public static Map<Id,PaymentPlan__c> getPaymentPlanByBuidlingIds(Set<Id> buidlingIds){
        Map<Id,PaymentPlan__c> paymentPlanMap ;
        Set<Id> paymentPlanIds = new Set<ID>();
        buildingToPaymentPlanMap = new Map<Id,Set<Id>>();
        for(BuildingSectionMapping__c buildingPaymentMappingRec: [select id,BuildingSectionName__c,PaymentPlan__c from BuildingSectionMapping__c where BuildingSectionName__c in :buidlingIds ]){
            paymentPlanIds.add(buildingPaymentMappingRec.PaymentPlan__c);
            if(!buildingToPaymentPlanMap.containsKey(buildingPaymentMappingRec.BuildingSectionName__c)){
                buildingToPaymentPlanMap.put(buildingPaymentMappingRec.BuildingSectionName__c,new Set<Id>());
            }
            buildingToPaymentPlanMap.get(buildingPaymentMappingRec.BuildingSectionName__c).add(buildingPaymentMappingRec.PaymentPlan__c);
        }
        if (paymentPlanIds != null) {
            paymentPlanMap = getPaymentPlanByIds(paymentPlanIds);
        }
        return paymentPlanMap ;
    }
    
    public static Map<Id,Set<Id>> getPaymentPlanIdsByBuidlingIds(Map<Id,Set<Id>> buildingToPaymentPlanIds,Set<Id> buidlingIds){
        
        Map<Id,Set<Id>> buildingToPaymentPlanIdsMap = new Map<Id,Set<Id>>();
        
        for(BuildingSectionMapping__c tempPaymentMappingRec: [select id,BuildingSectionName__c,PaymentPlan__c from BuildingSectionMapping__c where BuildingSectionName__c in :buidlingIds AND PaymentPlan__r.IsActive__c = 'Yes']){
            buildingToPaymentPlanIds.get(tempPaymentMappingRec.BuildingSectionName__c).add(tempPaymentMappingRec.PaymentPlan__c);
        }
        
        return buildingToPaymentPlanIds ;
    }
    
    public static List<OffersPromotions__c>  getActiveOffersAndPromotions(Set<Id> buildingIds, Set<Id> projectIds){
        
        List<OffersPromotions__c> allOfferPromotions = new List<OffersPromotions__c>();
        List<OffersPromotions__c> applicableOfferPromotions = new List<OffersPromotions__c>();
        
        User loggedIdUser = [SELECT Id,Name,ProfileName__c,UserRole.Name,Profile.Name, UserRole.Id,AccountId, ContactId, Contact.AccountId,Contact.AgentID__c,Team__c,Email,UserRoleId,ProfileId,FullPhotoUrl,Title,Manager.Name,MobilePhone  FROM USER WHERE Id=:UserInfo.getUserId()];
        String userProfileName = loggedIdUser.ProfileName__c;
        String userProfileId = loggedIdUser.Id;
        allOfferPromotions =  [select id,Name,BookingMemo__c, BuildingSectionName__c,Project__c,Unit__c,BrokerPortalFlag__c, (select id,Name,OfferType__c,OfferOn__c,OfferValue__c,CustomerType__c,Nationality__c,ResidentStatus__c,Unit__c,UnitType__c,UnitModel__c,NumberOfBedrooms__c,LeadSource__c,LowerBound__c,UpperBound__c,RangeOnField__c,Bulk__c,DiscountType__c,BudgetTaskName__c,OfferValueType__c from Offers_Lines__r) from OffersPromotions__c where  IsActive__c = true
                               and(Project__c in :projectIds or BuildingSectionName__c in :buildingIds)];
        for(OffersPromotions__c offerProm : allOfferPromotions){
            applicableOfferPromotions.add(offerProm);
        }
        
        return applicableOfferPromotions ;
    }
    
    public static Map<Id,PaymentPlan__c> getPaymentPlanByIds(Set<Id> paymentPlanIds){
        Map<Id,PaymentPlan__c> paymentPlanMap ;
        paymentPlanMap = new map<id,PaymentPlan__c>([select id,name,CustomerSubType__c,PaymentPlanType__c ,Premium__c,RebatePercentage__c,PaymentPlanDiscount__c,Unit__c,BookingMemo__r.OwnerId,BookingMemo__r.RelatedOpportunity__c,StandardFlag__c,BrokerPortalFlag__c,(select id,Name,BrokerPayoutPercentage__c,Date_Type__c,PaymentPlan__c,InstallmentNumber__c,Description__c,InstallmentPercentage__c,InstallmentDate__c from PaymentInstallments__r ORDER BY InstallmentNumber__c asc) from PaymentPlan__c where id in :paymentPlanIds and  IsActive__c = 'Yes']);
        return paymentPlanMap ;
    } 
    
    
}