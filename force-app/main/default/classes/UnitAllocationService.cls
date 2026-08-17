/**
 * UnitAllocationService
 * SOQL/selectors for Unit_Allocation__c, singleton pattern.
 */
public without sharing class UnitAllocationService {
    public static UnitAllocationService inst;
    public static UnitAllocationService getInstance() {
        if (inst == null) inst = new UnitAllocationService();
        return inst;
    }
    public UnitAllocationService() {}

    public List<Unit_Allocation__c> fetchUnitAllocationDetails(String recId,String accountId){
        return [select User_Type__c from Unit_Allocation__c where Id=:recId AND Account__c=:accountId AND Active__c=true];
    }
    
    public List<Unit_Allocation__c> fetchUnitAllocationDetailsbyUnit(id unitId,id accountId){
        return [select id,Active__c,Start_Date__c,End_Date__c from Unit_Allocation__c  where Account__c=:accountId and Unit__c=:unitId and Active__c=true];
    }
    
     public List<Unit_Allocation__c> fetchUnitAllocationByUnitId(String unitId){
        return [select Active__c,Start_Date__c,End_Date__c,Account__c from Unit_Allocation__c  where  Unit__c=:unitId and Active__c=true];
    }
    
    public List<Unit_Allocation__c> fetchAllUnitsRelatedToAccount(String accountId){
        return [SELECT Unit__r.Project__c,Unit__c,Unit__r.UnitNumber__c,Unit__r.UnitModel__c,Unit__r.Project__r.Community_Image_Url__c,Unit__r.Legal_Status__c,
                Unit__r.Building_Phase_Name__c,Unit__r.FloorNumber__c,Unit__r.Is_Chiller_Enabled__c,
                Unit__r.Is_Lease_Hold__c,Unit__r.Project__r.Name, Unit__r.CommunityUnitNumber__c,Unit__r.ADMAddressingNumber__c
                FROM Unit_Allocation__c  
                where Account__c  =: accountId AND Active__c = true];
    }
    
    public void createUnitAllocation(Unit_Allocation__c request){
        insert request;
    }
    
    public void updateUnitAllocation(Unit_Allocation__c request){  
        system.debug('##$$%%$'+request);  
        update request;
    }

    public List<Unit_Allocation__c> fetchUnitAllocationByUnitIds(Set<Id> unitIds){
        return [SELECT Id, Active__c, Unit__c, Account__c FROM Unit_Allocation__c WHERE Unit__c IN: unitIds];
    }

    public List<Unit_Allocation__c> fetchUnitAllocationByAccIds(Set<String> userTypeSet, Set<Id> customerIds, Boolean active, Boolean isParkingEnabled){
        return [SELECT Id, Name, Account__r.Name, Active__c, User_Type__c,  Unit__c, Unit__r.Name, Unit__r.CarParkAllocation__c, Unit__r.Active_Sales_Order__r.Account__r.Name, Unit__r.ActiveTenant__r.Name 
            FROM Unit_Allocation__c 
            WHERE Active__c =:active AND User_Type__c IN :userTypeSet AND Account__c IN :customerIds AND Unit__r.Project__r.EnableVehicleParking__c =:isParkingEnabled];
    }

    /** Get active allocation for account+unit on a given date; returns null if none. */
    public Unit_Allocation__c getActiveAllocation(Id unitId, Id accountId, Date onDate) {
        List<Unit_Allocation__c> rows = [
            SELECT Id, User_Type__c
            FROM Unit_Allocation__c
            WHERE Unit__c = :unitId
              AND Account__c = :accountId
              AND Start_Date__c <= :onDate
              AND (End_Date__c >= :onDate OR End_Date__c = null)
            LIMIT 1
        ];
        return rows.isEmpty() ? null : rows[0];
    }

    /** Check if any active Tenant/Holiday Homes exists for a unit at a date. */
    public Boolean hasActiveResidents(Id unitId, Date onDate) {
        List<Unit_Allocation__c> residents = [
            SELECT Id
            FROM Unit_Allocation__c
            WHERE Unit__c = :unitId
              AND User_Type__c IN ('Tenant','Holiday Homes')
              AND Start_Date__c <= :onDate
              AND (End_Date__c >= :onDate OR End_Date__c = null)
            LIMIT 1
        ];
        return !residents.isEmpty();
    }

    /** QuickPay: does an active allocation (Active__c = true) exist for Account+Unit? */
    public Boolean hasActiveAllocationFlag(Id accountId, Id unitId) {
        List<Unit_Allocation__c> rows = [
            SELECT Id
            FROM Unit_Allocation__c
            WHERE Account__c = :accountId
              AND Unit__c    = :unitId
              AND Active__c  = true
            LIMIT 1
        ];
        return !rows.isEmpty();
    }
}