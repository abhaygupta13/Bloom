/*****************************************************************************************
Class       : UnitAllocationTriggerHelper
Author      : Vikas Baliyan
Description : Unit Allocation Trigger Helper
Test Class  : 
Created Date: 18 APR 2025 
*****************************************************************************************/
public without sharing class UnitAllocationTriggerHelper {

    private static final String TENANT_STR = 'Tenant';
    
    public static void updateActiveTenant(List<Unit_Allocation__c> newList, Map<Id, Unit_Allocation__c> oldMap) {

        UnitService objUnitService = UnitService.getInstance();
        Map<Id, Unit_Allocation__c> unitAllocationMap = new Map<Id, Unit_Allocation__c>();
        
        for (Unit_Allocation__c newUA : newList) {
            // Insert logic (oldMap is null) 
            if (oldMap == null) {
                if(isEligibleForAssignment(newUA)){
                    unitAllocationMap.put(newUA.Unit__c, newUA);
                }
            }
            // Update logic (oldMap is not null)
            else {
                Unit_Allocation__c oldUA = oldMap.get(newUA.Id);
                if (oldUA != null && newUA.Active__c != oldUA.Active__c) {
                    if (isEligibleForAssignment(newUA)) {
                        // Active true
                        unitAllocationMap.put(newUA.Unit__c, newUA);
                    } else if (isEligibleForAssignment(oldUA)) {
                        // Active false
                        unitAllocationMap.put(oldUA.Unit__c, newUA);
                    }
                }
            }
        }
        
        if (!unitAllocationMap.isEmpty()) {
            List<Unit__c> unitsToUpdate = new List<Unit__c>();
            for (Id unitId : unitAllocationMap.keySet()) {
                Unit_Allocation__c ua = unitAllocationMap.get(unitId);
                Unit__c unitRecord = new Unit__c(Id = unitId, ActiveTenant__c = (ua != null && ua.Active__c && ua.User_Type__c == TENANT_STR) ? ua.Account__c : null);
                unitsToUpdate.add(unitRecord);
            }
            if (!unitsToUpdate.isEmpty()) {
                objUnitService.updateUnits(unitsToUpdate);
            }
        }
    }
    
    private static Boolean isEligibleForAssignment(Unit_Allocation__c ua) {
        return (ua != null && ua.Active__c == true && ua.User_Type__c == TENANT_STR && ua.Unit__c != null && ua.Account__c != null);
    }

}