public class EntitlementService {
    private EntitlementService() {}
    
     public static EntitlementService getInstance() {
        return new EntitlementService();
    }
    
     //insert Entitlements with trigger
    public List<Entitlement> insertEntitlementsWithTrigger(List<Entitlement> entitlementList){
        if(entitlementList != NULL && !entitlementList.isEmpty()){
            insert entitlementList;
        }
        return entitlementList;
    }
    
    //get Entitlements by accountId
    public List<Entitlement> getEntitlementsByAccountId(Set<Id> accIds){
        if(!accIds.isEmpty() && accIds.Size() > 0){
            return [SELECT Id, AccountId, SlaProcessId, SlaProcess.IsActive FROM Entitlement WHERE SlaProcess.IsActive = true AND AccountId IN :accIds];            
        } 
        return null;
    }
    
}