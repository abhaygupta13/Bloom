public class BrokerUnitAssignmentService {

    // --- Singleton instance ---
    private static BrokerUnitAssignmentService instance;

    // Private constructor to prevent instantiation
    private BrokerUnitAssignmentService() {}

    // --- Get singleton instance ---
    public static BrokerUnitAssignmentService getInstance() {
        if (instance == null) {
            instance = new BrokerUnitAssignmentService();
        }
        return instance;
    }

    // --- Projects assigned to specific Contact (Normal users) ---
    public static List<Project__c> getProjectsForContact(String contactId, String accountId) {
        Set<Id> projectIds = new Set<Id>();
        Datetime currentDateTime = System.now();

        // One query: directly pull project Ids from assignments
        for (BrokerUnitAssignment__c bua : [
            SELECT BrokerUnitAllocation__r.Unit__r.Project__c
            FROM BrokerUnitAssignment__c
            WHERE Contact__c = :contactId And BrokerUnitAllocation__r.Account__c = :accountId AND Active__c=true
            AND BrokerUnitAllocation__r.Unit__r.Project__c != null
            AND BrokerUnitAllocation__r.Unit__r.Project__r.IsActive__c = true
            AND BrokerUnitAllocation__r.EndDate__c >= :currentDateTime
        ]) {
            projectIds.add(bua.BrokerUnitAllocation__r.Unit__r.Project__c);
        }

        return ProjectService.fetchProjectsByIds(projectIds);
    }

    // --- Get Unit counts for assigned projects for Contact ---
    public static Map<Id, Integer> getUnitCounts(Set<Id> projectIds, Id accountId, Id contactId) {
        Map<Id, Integer> mapCounts = new Map<Id, Integer>();
        if (projectIds.isEmpty()) return mapCounts;

        Datetime currentDateTime = System.now();
        
        for (AggregateResult ar : [
            SELECT BrokerUnitAllocation__r.Unit__r.Project__c projectId, COUNT(Id) totalUnits
            FROM BrokerUnitAssignment__c
            WHERE BrokerUnitAllocation__r.Unit__r.Project__c IN :projectIds
                AND Contact__c = :contactId
                AND BrokerUnitAllocation__r.Account__c = :accountId
                AND Active__c = true
                AND BrokerUnitAllocation__r.Unit__r.Project__r.IsActive__c = true
                AND BrokerUnitAllocation__r.Unit__r.IsActive__c = true
                AND BrokerUnitAllocation__r.Unit__r.IsExclusive__c = true
                AND BrokerUnitAllocation__r.Unit__r.Direct_Indirect__c != 'Direct'
                AND BrokerUnitAllocation__r.Unit__r.Status__c = 'Available'            
            	AND BrokerUnitAllocation__r.EndDate__c >= :currentDateTime
            GROUP BY BrokerUnitAllocation__r.Unit__r.Project__c
        ]) {
            mapCounts.put((Id)ar.get('projectId'), (Integer)ar.get('totalUnits'));
        }
        return mapCounts;
    }

    public static Map<Id, List<String>> getUnitTypes(Set<Id> projectIds, Id accountId, Id contactId) {
        Map<Id, List<String>> mapTypes = new Map<Id, List<String>>();
        if (projectIds.isEmpty()) return mapTypes;

        Datetime currentDateTime = System.now();
        
        for (BrokerUnitAssignment__c b : [
            SELECT BrokerUnitAllocation__r.Unit__r.Project__c, BrokerUnitAllocation__r.Unit__r.UnitType__c
            FROM BrokerUnitAssignment__c
            WHERE BrokerUnitAllocation__r.Unit__r.Project__c IN :projectIds
                AND Contact__c = :contactId
                AND BrokerUnitAllocation__r.Account__c = :accountId
                AND Active__c = true
                AND BrokerUnitAllocation__r.Unit__r.Project__r.IsActive__c = true
                AND BrokerUnitAllocation__r.Unit__r.IsActive__c = true
                AND BrokerUnitAllocation__r.Unit__r.IsExclusive__c = true
                AND BrokerUnitAllocation__r.Unit__r.Direct_Indirect__c != 'Direct'
                AND BrokerUnitAllocation__r.Unit__r.Status__c = 'Available'
            	AND BrokerUnitAllocation__r.EndDate__c >= :currentDateTime
        ]) {
            addUnitType(mapTypes, b.BrokerUnitAllocation__r.Unit__r);
        }
        return mapTypes;
    }

    private static void addUnitType(Map<Id, List<String>> mapTypes, Unit__c u) {
        if (!mapTypes.containsKey(u.Project__c)) mapTypes.put(u.Project__c, new List<String>());
        if (!String.isBlank(u.UnitType__c) && !mapTypes.get(u.Project__c).contains(u.UnitType__c)) {
            mapTypes.get(u.Project__c).add(u.UnitType__c);
        }
    }
    
    //BAPP Get Broker Unit Assign By Allocation Ids
    public List<BrokerUnitAssignment__c> getBrokerUnitAssignByAllocationIds(set<Id> allocationIds){
        return [SELECT Id, Active__c, BrokerUnitAllocation__c
            FROM BrokerUnitAssignment__c
            WHERE BrokerUnitAllocation__c IN :allocationIds
            AND Active__c = true];
    }
    
    // BAPP Update Broker Unit Assignments
    public void updateBrokerUnitAssignments(List<BrokerUnitAssignment__c> assignments){
        if(assignments != null && !assignments.isEmpty()){
            update assignments;
        }
    }
    
    // BAPP Insert Broker Unit Assignments
    public void insertBrokerUnitAssignments(List<BrokerUnitAssignment__c> assignments){
        if(assignments != null && !assignments.isEmpty()){
            insert assignments;
        }
    }
    
    // Fetch assignments by Allocation Ids + Contact Ids
    public List<BrokerUnitAssignment__c> getAssignmentsByAllocationAndContacts( Set<Id> allocationIds, Set<Id> contactIds){
        if(allocationIds == null || allocationIds.isEmpty() ||
           contactIds == null || contactIds.isEmpty()){
               return new List<BrokerUnitAssignment__c>();
           }
        
        return [SELECT Id, BrokerUnitAllocation__c, Contact__c, Active__c FROM BrokerUnitAssignment__c WHERE BrokerUnitAllocation__c IN :allocationIds AND Contact__c IN :contactIds];
    }

}