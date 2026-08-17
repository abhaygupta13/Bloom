public class BrokerUnitAllocationService {

    // --- Singleton instance ---
    private static BrokerUnitAllocationService instance;

    // Private constructor to prevent instantiation
    private BrokerUnitAllocationService() {}

    // --- Get singleton instance ---
    public static BrokerUnitAllocationService getInstance() {
        if (instance == null) {
            instance = new BrokerUnitAllocationService();
        }
        return instance;
    }

    // --- Get Project Ids for Account (High level roles) ---
     public static List<Project__c> getProjectsForAccount(String accountId) {
         if (String.isBlank(accountId)) return new List<Project__c>();
        Set<Id> projectIds = new Set<Id>();

        Datetime currentDateTime = System.now();
        
        // One query: directly pull project Ids from allocations
        for (BrokerUnitAllocations__c alloc : [
            SELECT Unit__r.Project__c
            FROM BrokerUnitAllocations__c
            WHERE Account__c = :accountId 
            AND Unit__r.Project__c != null AND Unit__r.Project__r.IsActive__c = true 
            	AND EndDate__c >= :currentDateTime
        ]) {
            projectIds.add(alloc.Unit__r.Project__c);
        }
		
        return projectIds.isEmpty()
            ? new List<Project__c>()
            : ProjectService.fetchProjectsByIds(projectIds);
    }

    // --- Get Unit counts for assigned projects ---
    public static Map<Id, Integer> getUnitCounts(Set<Id> projectIds, Id accountId) {
        Map<Id, Integer> mapCounts = new Map<Id, Integer>();
        if (projectIds == null || projectIds.isEmpty() || String.isBlank(accountId)) return mapCounts;

        Datetime currentDateTime = System.now();
        List<BrokerUnitAllocations__c> checkCountList = [
            SELECT Unit__r.Project__c, Id, Name 
            FROM BrokerUnitAllocations__c
            WHERE Unit__r.Project__c IN :projectIds
                AND Account__c = :accountId
                AND Unit__r.Project__r.IsActive__c = true
                AND Unit__r.IsActive__c = true
                AND Unit__r.IsExclusive__c = true
                AND Unit__r.Direct_Indirect__c != 'Direct'
                AND Unit__r.Status__c = 'Available'
            	AND EndDate__c >= :currentDateTime];
            
        System.debug('checkCount >> '+checkCountList);
        
        for (AggregateResult ar : [
            SELECT Unit__r.Project__c projectId, COUNT(Id) totalUnits
            FROM BrokerUnitAllocations__c
            WHERE Unit__r.Project__c IN :projectIds
                AND Account__c = :accountId
                AND Unit__r.Project__r.IsActive__c = true
                AND Unit__r.IsActive__c = true
                AND Unit__r.IsExclusive__c = true
                AND Unit__r.Direct_Indirect__c != 'Direct'
                AND Unit__r.Status__c = 'Available'
            	AND EndDate__c >= :currentDateTime
            GROUP BY Unit__r.Project__c
        ]) {
            mapCounts.put((Id)ar.get('projectId'), (Integer)ar.get('totalUnits'));
        }
        return mapCounts;
    }

    public static Map<Id, List<String>> getUnitTypes(Set<Id> projectIds, Id accountId) {
        Map<Id, List<String>> mapTypes = new Map<Id, List<String>>();
        if (projectIds == null || projectIds.isEmpty() || String.isBlank(accountId)) return mapTypes;

        Datetime currentDateTime = System.now();
        
        for (BrokerUnitAllocations__c b : [
            SELECT Unit__r.Project__c, Unit__r.UnitType__c
            FROM BrokerUnitAllocations__c
            WHERE Unit__r.Project__c IN :projectIds
                AND Account__c = :accountId
                AND Unit__r.Project__r.IsActive__c = true
                AND Unit__r.IsActive__c = true
                AND Unit__r.IsExclusive__c = true
                AND Unit__r.Direct_Indirect__c != 'Direct'
                AND Unit__r.Status__c = 'Available'
            	AND EndDate__c >= :currentDateTime
        ]) {
            addUnitType(mapTypes, b.Unit__r);
        }
        return mapTypes;
    }

    private static void addUnitType(Map<Id, List<String>> mapTypes, Unit__c u) {
        if (u == null || u.Project__c == null) return;
        if (!mapTypes.containsKey(u.Project__c)) mapTypes.put(u.Project__c, new List<String>());
        if (!String.isBlank(u.UnitType__c) && !mapTypes.get(u.Project__c).contains(u.UnitType__c)) {
            mapTypes.get(u.Project__c).add(u.UnitType__c);
        }
    }
    // Get Assigned Project IDs for which active units are allocated
    public Set<Id> getAssignedProjectIds(Id accountId) {
        if (String.isBlank(accountId)) return new Set<Id>();
        Set<Id> assignedProjectIds = new Set<Id>();

        Datetime currentDateTime = System.now();
        
        List<BrokerUnitAllocations__c> allocations = [
            SELECT Unit__r.Project__c
            FROM BrokerUnitAllocations__c
            WHERE Account__c = :accountId
              AND Unit__r.Project__c != null
              AND Unit__r.IsActive__c = true
              AND Unit__r.Status__c = 'Available'
              AND EndDate__c >= :currentDateTime            
        ];

        for (BrokerUnitAllocations__c alloc : allocations) {
            assignedProjectIds.add(alloc.Unit__r.Project__c);
        }

        return assignedProjectIds;
    }
    
    // BAPP Update Broker Unit Allocations
    public void updateBrokerUnitAllocations(List<BrokerUnitAllocations__c> allocations){
        if(allocations != null && !allocations.isEmpty()){
            update allocations;
        }
    }
    
    public Map<Id, BrokerUnitAllocations__c> getAllocationsWithAccount(Set<Id> allocationIds) {
        Map<Id, BrokerUnitAllocations__c> result = new Map<Id, BrokerUnitAllocations__c>();
        if (allocationIds == null || allocationIds.isEmpty()) return result;
    
        return new Map<Id, BrokerUnitAllocations__c>(
            [
                SELECT Id, Account__c
                FROM BrokerUnitAllocations__c
                WHERE Id IN :allocationIds
                  AND Account__c != NULL
            ]
        );
    }
    
    // BAPP Insert Broker Unit Allocations
    public List<BrokerUnitAllocations__c> insertBrokerUnitAllocations(List<BrokerUnitAllocations__c> allocations){
        if(allocations == null || allocations.isEmpty()){
            return new List<BrokerUnitAllocations__c>();
        }
        insert allocations;
        return allocations; 
    }
    
}