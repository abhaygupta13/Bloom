public with sharing class PaymentPlanOffPromotionService {

    public static Map<Id,Set<Id>> buildingToPaymentPlanMap ;
    /*
    * Get All Payment Plans and payment lines for a building
    */
    public static Map<Id,PaymentPlan__c> getPaymentPlanByProjectIds(Set<Id> projectIds){
        //--- Get all the building of the project
        Map<Id,PaymentPlan__c> paymentPlanMap ;
        Set<Id> buildingsIds = new Set<ID>();
        for(BuildingSection__c tempPaymentMappingRec: [select id,Name from BuildingSection__c where Project__c in :projectIds ]){
            buildingsIds.add(tempPaymentMappingRec.id);
        }
        if (buildingsIds != null) {
            paymentPlanMap = getPaymentPlanByBuidlingIds(buildingsIds);
        }
        System.debug('paymentPlanMap'+paymentPlanMap);
        return paymentPlanMap ;
    }
    
    /*
    * Get All Payment Plans and payment lines for a building
    */
    public static Map<Id,PaymentPlan__c> getPaymentPlanByBuidlingIds(Set<Id> buidlingIds){
        System.debug('buidlingIds'+buidlingIds);
        // Building Section Mapping , identify the payment plans ids
        Map<Id,PaymentPlan__c> paymentPlanMap ;
        Set<Id> paymentPlanIds = new Set<ID>();
        buildingToPaymentPlanMap = new Map<Id,Set<Id>>();
        // for(BuildingSectionMapping__c tempPaymentMappingRec: [select id,BuildingSectionName__c,PaymentPlan__c from BuildingSectionMapping__c where BuildingSectionName__c in :buidlingIds ]){
        //     paymentPlanIds.add(tempPaymentMappingRec.PaymentPlan__c);
        // }
        for(BuildingSectionMapping__c buildingPaymentMappingRec: [select id,BuildingSectionName__c,PaymentPlan__c from BuildingSectionMapping__c where BuildingSectionName__c in :buidlingIds ]){
          System.debug('buildingPaymentMappingRec'+buildingPaymentMappingRec);
            paymentPlanIds.add(buildingPaymentMappingRec.PaymentPlan__c);
            System.debug('paymentPlanIds'+paymentPlanIds);
            if(!buildingToPaymentPlanMap.containsKey(buildingPaymentMappingRec.BuildingSectionName__c)){
                buildingToPaymentPlanMap.put(buildingPaymentMappingRec.BuildingSectionName__c,new Set<Id>());
            }
            buildingToPaymentPlanMap.get(buildingPaymentMappingRec.BuildingSectionName__c).add(buildingPaymentMappingRec.PaymentPlan__c);
        }
        if (paymentPlanIds != null) {
            paymentPlanMap = getPaymentPlanByIds(paymentPlanIds);
            System.debug('paymentPlanMap'+paymentPlanMap);
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

    /*
    * Get All Payment Plans by Id
    */
    public static Map<Id,PaymentPlan__c> getPaymentPlanByIds(Set<Id> paymentPlanIds){
        System.debug('paymentPlanIds'+paymentPlanIds);
        //Maaz Changed on 30 MAy. Put hardcoded 'Yes' for  :CONSTANT_ACTIVE_Y something something
        Map<Id,PaymentPlan__c> paymentPlanMap ;
        paymentPlanMap = new map<id,PaymentPlan__c>([select id,name,Offers_Based_On_Payment_Plan__c,Maximum_No_Of_Units__c,Minimum_No_Of_Units__c,CustomerSubType__c,PaymentPlanType__c ,Premium__c,RebatePercentage__c,PaymentPlanDiscount__c,Unit__c,BookingMemo__r.OwnerId,BookingMemo__r.RelatedOpportunity__c,StandardFlag__c,BrokerPortalFlag__c,(select id,Name,BrokerPayoutPercentage__c,PaymentPlan__c,InstallmentNumber__c,Description__c,InstallmentPercentage__c,InstallmentDate__c,InstallmentType__c,Condition_Type__c,Date_Type__c from PaymentInstallments__r ORDER BY InstallmentNumber__c asc) from PaymentPlan__c where id in :paymentPlanIds and  IsActive__c = 'Yes']);
        System.debug('paymentPlanMap'+paymentPlanMap);
        return paymentPlanMap ;
    }

    @AuraEnabled(cacheable=false)
    public static void insertPaymentPlan(List<PaymentPlan__c> paymentPlanList){
      insert paymentPlanList;
    }





    
    /*
    * Get Active Offers and Promotions by Project or Id
    */
    public static List<OffersPromotions__c>  getActiveOffersAndPromotions(Set<Id> buildingIds, Set<Id> projectIds){

        List<OffersPromotions__c> allOfferPromotions = new List<OffersPromotions__c>();
        List<OffersPromotions__c> applicableOfferPromotions = new List<OffersPromotions__c>();

        User loggedIdUser = Utilities.getLoggedInUserDetail();
        String userProfileName = loggedIdUser.ProfileName__c;
        String userProfileId = loggedIdUser.Id;
        //if (userProfileName.contains('PT1') || userProfileName.contains(Constants.SALES_MANAGER)) { //PT1 for development only 
          allOfferPromotions =  [select id,Name,ADM_Fee_Included__c,BookingMemo__c,BuildingSectionName__c,Project__c,Unit__c,BrokerPortalFlag__c,
Direct_Indirect__c,Customer_Sub_Type__c, (select id,Name,OfferType__c,OfferOn__c,OfferValue__c,CustomerType__c,Nationality__c,ResidentStatus__c,Unit__c,UnitType__c,UnitModel__c,NumberOfBedrooms__c,LeadSource__c,LowerBound__c,UpperBound__c,RangeOnField__c,Bulk__c,DiscountType__c,BudgetTaskName__c,OfferValueType__c from Offers_Lines__r) from OffersPromotions__c where  IsActive__c = true
          and(Project__c in :projectIds or BuildingSectionName__c in :buildingIds)];
        //}//booking memo owner

        for(OffersPromotions__c offerProm : allOfferPromotions){
                applicableOfferPromotions.add(offerProm);
        }

        System.debug('**Applicable Offers**'+applicableOfferPromotions);
        return applicableOfferPromotions ;
    }

    public static OffersPromotions__c  getSelectedOffersAndPromotions(Id offersPromotionsId){

        OffersPromotions__c allOfferPromotions = new OffersPromotions__c();

        allOfferPromotions =  [SELECT id,Name,ADM_Fee_Included__c,BuildingSectionName__c,Project__c,Unit__c,BrokerPortalFlag__c, (SELECT id,Name,OfferType__c,OfferOn__c,OfferValue__c,CustomerType__c,Nationality__c,ResidentStatus__c,Unit__c,UnitType__c,UnitModel__c,NumberOfBedrooms__c,LeadSource__c,LowerBound__c,UpperBound__c,RangeOnField__c,Bulk__c,DiscountType__c,BudgetTaskName__c,OfferValueType__c FROM Offers_Lines__r) FROM OffersPromotions__c where  Id  =: offersPromotionsId];

        return allOfferPromotions ;
    }

    @AuraEnabled(cacheable=false)
    public static void insertOffersPromotions(List<OffersPromotions__c> offersPromotionsList){
      insert offersPromotionsList;
    }

    @AuraEnabled(cacheable=false)
    public static String lastCreatedIdOffersPromotions(String bookingMemoId, String unitId)  {   
    String lastCreatedId;
    List<OffersPromotions__c> records = [select Id from OffersPromotions__c where BookingMemo__c =: bookingMemoId and Unit__c =: unitId limit 1];
        if(records.size() > 0)
        {
             lastCreatedId = records[0].Id;
        }
        return lastCreatedId;     
    }

    public static Map<String,OffersPromotions__c> getOffersPromotionsByName(Set<String> offersPromotionsNames) {   
        
        Map<String,OffersPromotions__c> offersPromotionsMap = new Map<String,OffersPromotions__c>();    

        for(OffersPromotions__c offerPromotionRecord : [SELECT Id, Name, OfferName__c FROM OffersPromotions__c WHERE OfferName__c In : offersPromotionsNames]){
            offersPromotionsMap.put(offerPromotionRecord.OfferName__c,offerPromotionRecord);
        }       
        return offersPromotionsMap;
    }

    public static Map<Id,List<OffersPromotions__c>> getActiveOffersPromotions(Opportunity opportunityRec,List<Unit__c> unitList,User loggedInUser){

        Map<Id,List<OffersPromotions__c>> unitOfferMap = new Map<Id,List<OffersPromotions__c>>();
        Map<Id,List<OffersPromotions__c>> buildingProjectOfferMap = new Map<Id,List<OffersPromotions__c>>();


        for(Unit__c unitRec : unitList){
            buildingProjectOfferMap.put(unitRec.BuildingSectionName__c,new List<OffersPromotions__c>());
            buildingProjectOfferMap.put(unitRec.Project__c,new List<OffersPromotions__c>());
            unitOfferMap.put(unitRec.Id,new List<OffersPromotions__c>());
        }

        if(buildingProjectOfferMap != null){
            Map<Id,OffersPromotions__c> offersMap = new Map<Id,OffersPromotions__c>(PaymentPlanOffPromotionService.getActiveOffersAndPromotions(buildingProjectOfferMap.keySet(),buildingProjectOfferMap.keySet()));

            for(OffersPromotions__c offerRec : offersMap.values()){
                if(buildingProjectOfferMap.containsKey(offerRec.BuildingSectionName__c)){
                    buildingProjectOfferMap.get(offerRec.BuildingSectionName__c).add(offerRec);
                }
                if(buildingProjectOfferMap.containsKey(offerRec.Project__c)){
                    buildingProjectOfferMap.get(offerRec.Project__c).add(offerRec);
                }
            }

            for(Unit__c unitRec : unitList){
                if(buildingProjectOfferMap.containsKey(unitRec.BuildingSectionName__c)){
                    for(OffersPromotions__c offerRec : buildingProjectOfferMap.get(unitRec.BuildingSectionName__c)){
                        System.debug(offerRec+'**Offer Record**');
                        //------ Standard Offers
                        if(offerRec.BookingMemo__c == null){
                            unitOfferMap.get(unitRec.Id).add(offerRec);
                        }
                            //------ Check if Memo offer is applicable
                        else if(opportunityRec!=null && offerRec.BookingMemo__c != null && offerRec.Unit__c  == unitRec.Id && offerRec.BookingMemo__r.OwnerId == loggedInUser.Id && offerRec.BookingMemo__r.RelatedOpportunity__c == opportunityRec.Id){
                            unitOfferMap.get(unitRec.Id).add(offerRec);
                        }
                    }
                } 
                if(buildingProjectOfferMap.containsKey(unitRec.Project__c)){
                    for(OffersPromotions__c offerRec : buildingProjectOfferMap.get(unitRec.Project__c)){
                        System.debug(offerRec+'**Offer Record**');
                        //------ Standard Offers
                        if(offerRec.BookingMemo__c == null && offerRec.BuildingSectionName__c==null){
                            unitOfferMap.get(unitRec.Id).add(offerRec);
                        }
                            //------ Check if Memo offer is applicable
                        else if(opportunityRec!=null  && offerRec.BuildingSectionName__c==null && offerRec.BookingMemo__c != null && offerRec.Unit__c  == unitRec.Id && offerRec.BookingMemo__r.OwnerId == loggedInUser.Id && offerRec.BookingMemo__r.RelatedOpportunity__c == opportunityRec.Id){
                            unitOfferMap.get(unitRec.Id).add(offerRec);
                        }
                    }
                }
            }
            System.debug('**Unit Offers**'+unitOfferMap);
        }
        return unitOfferMap ;

    }
   

     
}