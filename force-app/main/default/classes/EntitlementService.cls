/*
*********************************************************
Apex Class Name    : EntitlementService
Created Date       : Dec 26, 2024
@description       : This class handles record retrieval and DML operations.
Modification Log   :
Ver   Date         : Author                               Modification
4.8   10-09-2026   : Abhay Gupta                          Optimised the class and removed uncommented code
*********************************************************
*/
public inherited sharing class EntitlementService {
    private EntitlementService() {}
    
    public static EntitlementService getInstance() {
        return new EntitlementService();
    }
    
    public List<Entitlement> insertEntitlements(List<Entitlement> entitlementList) {
        if(entitlementList != null && !entitlementList.isEmpty()) {
            insert entitlementList;
        }
        return entitlementList;
    }
    
    public List<Entitlement> getEntitlementsByAccountIdSet(Set<Id> accIds) {
        return [
                    SELECT 
                        Id, 
                        AccountId, 
                        SlaProcessId, 
                        SlaProcess.IsActive 
                    FROM Entitlement 
                    WHERE SlaProcess.IsActive = true 
                    AND AccountId IN :accIds
                ];
    }
    
}