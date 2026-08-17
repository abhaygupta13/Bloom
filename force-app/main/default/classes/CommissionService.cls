/***
Class       : CommissionService 
Author      : Smaartt
Description : 
TestClass   : Test Class Name
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              27/04/23           Initial Version 
****************************************************************************************************************/

public class CommissionService {

    public static List<InternalCommission__c> genericCommission ;
    
    /*
    * Get Active Internal Commissions
    */
    public static List<InternalCommission__c> getActiveInternalCommissions(){
        List<InternalCommission__c> internalCommissions = new List<InternalCommission__c>();
        internalCommissions = [SELECT Id,Name,DirectCommission__c,IndirectCommission__c,OfferPromotion__c,InventoryLaunchCategory__c,Project__c,SaleType__c,SaleValueTo__c,SalesValueFrom__c,StaffReferral__c,StaffReferralAmount__c,UserRole__c FROM InternalCommission__c WHERE IsActive__c = true ORDER By CreatedDate ASC];
        System.debug(internalCommissions.size()+'**internalCommissions**'+internalCommissions);
        return internalCommissions ; 
    }

    /*
    * Get Internal Commissions by Project
    */
    public static Map<String,List<InternalCommission__c>> getInternalCommissionsByProject(){

        Map<String,List<InternalCommission__c>> projectCommissionMap = new Map<String,List<InternalCommission__c>>();
        genericCommission = new List<InternalCommission__c>();

        for(InternalCommission__c commissionRecord :getActiveInternalCommissions()){
            if(commissionRecord.Project__c != null ){
                String projectId = String.valueOf(commissionRecord.Project__c);
                List<InternalCommission__c> projectCommission = (projectCommissionMap !=null && projectCommissionMap.containsKey(projectId) ? projectCommissionMap.get(projectId) : new List<InternalCommission__c>());
                projectCommission.add(commissionRecord);
                projectCommissionMap.put(projectId,projectCommission);
            }
            else{
                genericCommission.add(commissionRecord);
            }
        }

        return projectCommissionMap ;
    }

    /*
    * Get Internal Commissions for an Opportunity and Units
    */
    public static Map<Id,InternalCommission__c> getInternalCommissions(Opportunity opportunityRecord,List<Unit__c> unitRecords,Map<Id,OffersPromotions__c> unitToOfferMap){

        Set<Id> projectIds = new Set<Id>();
        Map<Id,InternalCommission__c> unitCommissionMap = new Map<Id,InternalCommission__c>();

        for(Unit__c unitRecord :unitRecords){
            projectIds.add(unitRecord.Project__c);
        }

        User userInfo = Utilities.getLoggedInUserDetail();

        Map<String,List<InternalCommission__c>> projectCommissionMap = getInternalCommissionsByProject();

        for(Unit__c unitRecord :unitRecords){
            OffersPromotions__c offer = unitToOfferMap.get(unitRecord.Id);
            List<InternalCommission__c> applicableCommissions = (projectCommissionMap !=null && projectCommissionMap.containsKey(String.valueOf(unitRecord.Project__c)) ? projectCommissionMap.get(String.valueOf(unitRecord.Project__c)) : genericCommission);
            System.debug(applicableCommissions.size()+'**applicableCommissions**'+applicableCommissions);
            if(applicableCommissions !=null && !applicableCommissions.isEmpty())
                unitCommissionMap.put(unitRecord.Id,getCommissionRecord(opportunityRecord,unitRecord,applicableCommissions,offer,userInfo.UserRole.Name));
        }

        return unitCommissionMap ; 
    }

    /*
    * Get Applicable Commission record
    */
    public static InternalCommission__c getCommissionRecord(Opportunity opportunityRecord,Unit__c unitRecord,List<InternalCommission__c> applicableCommissions,OffersPromotions__c offer, String userRole){

        InternalCommission__c commissionRecord = new InternalCommission__c();

        for(InternalCommission__c commissionRec : applicableCommissions){
            System.debug(commissionRec.InventoryLaunchCategory__c+'**commissionRec.InventoryLaunchCategory__c**'+opportunityRecord.SaleType__c);
            System.debug(commissionRec.SaleType__c+'**commissionRec.SaleType__c**'+commissionRec.SalesValueFrom__c);
            System.debug(commissionRec.UserRole__c+'**User Role-->**'+userRole);

            if(commissionRec.UserRole__c !=null && userRole !=null && !userRole.contains(commissionRec.UserRole__c)){
                continue ;
            }
            else if(commissionRec.SaleType__c !=null && opportunityRecord.SaleType__c !=null && commissionRec.SaleType__c != opportunityRecord.SaleType__c){
                continue ;
            }
            else if(commissionRec.OfferPromotion__c !=null && offer !=null && commissionRec.OfferPromotion__c != offer.Id){
                continue ;
            }
            else if(commissionRec.SalesValueFrom__c !=null && unitRecord.SellingPrice__c !=null && unitRecord.SellingPrice__c < commissionRec.SalesValueFrom__c){
                continue ;
            }
            else if(commissionRec.SaleValueTo__c !=null && unitRecord.SellingPrice__c !=null && unitRecord.SellingPrice__c > commissionRec.SaleValueTo__c){
                continue ;
            }
            commissionRecord = commissionRec ;
        }

        return commissionRecord ;
    }

    /*
    * Get Active Broker Commissions
    */
    public static Map<Id,List<BrokerCommission__c>> getActiveBrokerCommissions(Set<Id> projectIds,Set<Id> buildingIds){
        Map<Id,List<BrokerCommission__c>> brokerCommissionMap = new Map<Id,List<BrokerCommission__c>>();

        System.debug(projectIds+'**Project Building**'+buildingIds);
        for(BrokerCommission__c brokerCommissionRec : [SELECT Id,Name,BrokerType__c,BuildingSection__c,CommissionPercentage__c,CommissionAmount__c,OfferPromotion__c,Project__c,SaleType__c,UnitType__c,UnitCategory__c,UnitView__c FROM BrokerCommission__c WHERE IsActive__c = true AND (Project__c IN:projectIds OR BuildingSection__c IN:buildingIds)]){
            if(brokerCommissionRec.BuildingSection__c !=null){
                Id buildingId = brokerCommissionRec.BuildingSection__c ;
                List<BrokerCommission__c> buildingCommission = (brokerCommissionMap !=null && brokerCommissionMap.containsKey(buildingId) ? brokerCommissionMap.get(buildingId) : new List<BrokerCommission__c>());
                buildingCommission.add(brokerCommissionRec);
                brokerCommissionMap.put(buildingId,buildingCommission);
            }
            Id projectId = brokerCommissionRec.Project__c;
            List<BrokerCommission__c> projectCommission = (brokerCommissionMap !=null && brokerCommissionMap.containsKey(projectId) ? brokerCommissionMap.get(projectId) : new List<BrokerCommission__c>());
            System.debug(brokerCommissionRec+'**Project**'+projectId);
            projectCommission.add(brokerCommissionRec);
            brokerCommissionMap.put(projectId,projectCommission);
        } 
        System.debug(brokerCommissionMap.size()+'**brokerCommissions**'+brokerCommissionMap);
        return brokerCommissionMap ; 
    }

    /*
    * Get External Commissions for an Opportunity and Units
    */
    public static Map<Id,Decimal> getExternalCommissions(Opportunity opportunityRecord,List<Unit__c> unitRecords,Map<Id,OffersPromotions__c> unitToOfferMap){

        Map<Id,Decimal> unitExternalCommissionMap = new Map<Id,Decimal>();
        return unitExternalCommissionMap ; 
    }

    /*
    * Get External Commissions for an Opportunity and Units
    */
    public static Map<Id,BrokerCommission__c> getBrokerCommissions(Opportunity opportunityRecord,List<Unit__c> unitRecords,Map<Id,OffersPromotions__c> unitToOfferMap){

        Set<Id> projectIds = new Set<Id>();
        Set<Id> buildingIds = new Set<Id>();
        Map<Id,BrokerCommission__c> unitExternalCommissionMap = new Map<Id,BrokerCommission__c>();

        for(Unit__c unitRecord :unitRecords){
            projectIds.add(unitRecord.Project__c);
            buildingIds.add(unitRecord.BuildingSectionName__c);
        }

        Map<Id,List<BrokerCommission__c>> projectBuildingCommissionMap = getActiveBrokerCommissions(projectIds,buildingIds);

        for(Unit__c unitRecord :unitRecords){
            OffersPromotions__c offer = unitToOfferMap.get(unitRecord.Id);
            List<BrokerCommission__c> applicableCommissions = (projectBuildingCommissionMap !=null && projectBuildingCommissionMap.containsKey(String.valueOf(unitRecord.BuildingSectionName__c)) ? projectBuildingCommissionMap.get(String.valueOf(unitRecord.BuildingSectionName__c)) : (projectBuildingCommissionMap !=null && projectBuildingCommissionMap.containsKey(String.valueOf(unitRecord.Project__c)) ? projectBuildingCommissionMap.get(String.valueOf(unitRecord.Project__c)) : null));

            if(applicableCommissions !=null && !applicableCommissions.isEmpty()){
                unitExternalCommissionMap.put(unitRecord.Id,getExternalCommissionRecord(opportunityRecord,unitRecord,applicableCommissions,offer));
            }
        }

        return unitExternalCommissionMap ; 
    }

    /*
    * Get Applicable Commission record
    */
    public static BrokerCommission__c getExternalCommissionRecord(Opportunity opportunityRecord,Unit__c unitRecord,List<BrokerCommission__c> applicableCommissions,OffersPromotions__c offer){

        BrokerCommission__c commissionRecord = new BrokerCommission__c();
        Decimal brokerCommissionPercentage = 0;

        for(BrokerCommission__c commissionRec : applicableCommissions){
            if(commissionRec.SaleType__c !=null && opportunityRecord.SaleType__c !=null && commissionRec.SaleType__c != opportunityRecord.SaleType__c){
                continue ;
            }
            else if(commissionRec.UnitType__c !=null && unitRecord.UnitType__c !=null && commissionRec.UnitType__c != unitRecord.UnitType__c){
                continue ;
            }
            else if(commissionRec.UnitCategory__c !=null && unitRecord.UnitCategory__c !=null && commissionRec.UnitCategory__c != unitRecord.UnitCategory__c){
                continue ;
            }
            else if(commissionRec.UnitView__c !=null && unitRecord.UnitView__c !=null && commissionRec.UnitView__c != unitRecord.UnitView__c){
                continue ;
            }
            else if(commissionRec.OfferPromotion__c !=null && offer !=null && commissionRec.OfferPromotion__c != offer.Id){
                continue ;
            }
            commissionRecord = commissionRec ;
        }

        return commissionRecord ;
    }
    
}