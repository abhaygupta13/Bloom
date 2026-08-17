/*
* @Author      : Akshay Khairnar  
* @CreatedDate : 10th SEP 2025
* @Description : Handles inventory assignment and allocation logic invoked from Flow. 
- Including unit allocation to agencies and unit assignment to high-level contacts (e.g., Admin, Super Admin, CEO)
*/
/*****************************************************************************************************
* Version       Author      	   Date             Comment                                                                       
* 1.1           Akshay Khairnar    18th SEP 2025    Initial Draft
*****************************************************************************************************/
public with sharing class InventoryAssignmentHandler {
    
    // Wrapper for inputs from Flow
    public class AllocationRequest {
        @InvocableVariable(label='Agency Id')
        public Id agencyId;   // Flow will pass {!Agency.firstSelectedRow.Id}
        
        @InvocableVariable(label='Unit Ids')
        public List<Id> unitIds; // Flow will pass {!AllUnits}
        
        @InvocableVariable(label='Start Date')
        public DateTime startDate;   // Flow will pass screen Start Date
        
        @InvocableVariable(label='End Date')
        public DateTime endDate;     // Flow will pass screen End Date
        
        // New variables for Project Agency Allocation
        @InvocableVariable(label='Project Id')
        public Id projectId;     // Flow will pass {!$Record.Id}
        
        @InvocableVariable(label='Agency Ids')
        public List<Id> agencyIds; // Flow will pass multiple agencies from screen
    }
    
    @InvocableMethod(
        label='Create Broker Unit Allocations' 
        description='Creates BrokerUnitAllocations and BrokerUnitAssignments for selected Units and Agency'
    )
    public static void createBrokerUnitAllocations(List<AllocationRequest> requests) {
        
        Set<Id> agencyIds = new Set<Id>();
        Set<Id> unitIds = new Set<Id>();
        Set<Id> projectIds = new Set<Id>();
        Set<Id> projectAgencyIds = new Set<Id>();
        
        for (AllocationRequest r : requests) {
            if (r.agencyId != null) agencyIds.add(r.agencyId);
            if (r.unitIds != null) unitIds.addAll(r.unitIds);
            if (r.projectId != null) projectIds.add(r.projectId);
            if (r.agencyIds != null) projectAgencyIds.addAll(r.agencyIds);
        }
        
        Map<Id, List<Contact>> contactsByAgency = getBrokerContactsByAccounts(agencyIds);
        
        Map<String, ProjectAgencyAllocation__c> existingAllocMap = getProjectAgencyAllocationsBulk(projectIds, projectAgencyIds);
        
        List<BrokerUnitAllocations__c> allocations = new List<BrokerUnitAllocations__c>();
        List<Unit__c> unitsToUpdate = new List<Unit__c>();
        List<BrokerUnitAssignment__c> assignments = new List<BrokerUnitAssignment__c>();
        List<ProjectAgencyAllocation__c> projectAgencyUpserts = new List<ProjectAgencyAllocation__c>();
        
        for (AllocationRequest r : requests) {
            
            if (r.agencyId != null && r.unitIds != null) {
                for (Id unitId : r.unitIds) {
                    allocations.add(new BrokerUnitAllocations__c(
                        Account__c = r.agencyId,
                        Unit__c = unitId,
                        StartDate__c = r.startDate,
                        EndDate__c = r.endDate,
                        IsActive__c = true
                    ));
                    unitsToUpdate.add(new Unit__c(
                        Id = unitId,
                        IsPublic__c = false,
                        IsExclusive__c = true
                    ));
                }
            }
            
            if (r.projectId != null && r.agencyIds != null) {
                for (Id agencyId : r.agencyIds) {
                    String key = r.projectId + '-' + agencyId;
                    if (existingAllocMap.containsKey(key)) {
                        ProjectAgencyAllocation__c pa = existingAllocMap.get(key);
                        if (!pa.IsActive__c) {
                            pa.IsActive__c = true;
                            projectAgencyUpserts.add(pa);
                        }
                    } else {
                        projectAgencyUpserts.add(new ProjectAgencyAllocation__c(
                            Project__c = r.projectId,
                            Account__c = agencyId,
                            IsActive__c = true
                        ));
                    }
                }
            }
        }
        
        /* ---------- DML ---------- */
        if (!allocations.isEmpty()) {
            List<BrokerUnitAllocations__c> inserted = BrokerUnitAllocationService.getInstance().insertBrokerUnitAllocations(allocations);
            
            for (BrokerUnitAllocations__c a : inserted) {
                
                List<Contact> agencyContacts = contactsByAgency.get(a.Account__c);
                if (agencyContacts == null || agencyContacts.isEmpty()) {
                    continue;
                }
                
                for (Contact c : agencyContacts) {
                    assignments.add(new BrokerUnitAssignment__c(
                        BrokerUnitAllocation__c = a.Id,
                        Contact__c = c.Id,
                        Active__c = true
                    ));
                }
            }
        }
        
        if (!unitsToUpdate.isEmpty())
            UnitService.getInstance().updateExistingUnits(unitsToUpdate);
        
        if (!assignments.isEmpty())
            BrokerUnitAssignmentService.getInstance().insertBrokerUnitAssignments(assignments);
        
        if (!projectAgencyUpserts.isEmpty())
            upsert projectAgencyUpserts;
    }
    
    private static Map<Id, List<Contact>> getBrokerContactsByAccounts(Set<Id> accountIds) {
        Map<Id, List<Contact>> result = new Map<Id, List<Contact>>();
        if (accountIds == null || accountIds.isEmpty()) return result;
        
        for (Contact c : [
            SELECT Id, AccountId, IsActive__c
            FROM Contact
            WHERE AccountId IN :accountIds AND IsActive__c = true
            AND BrokerContactRole__c INCLUDES ('Admin', 'SuperAdmin', 'CEO')
        ]) {
            if (!result.containsKey(c.AccountId)) {
                result.put(c.AccountId, new List<Contact>());
            }
            result.get(c.AccountId).add(c);
        }
        return result;
    }
    
    
    private static Map<String, ProjectAgencyAllocation__c> getProjectAgencyAllocationsBulk(Set<Id> projectIds, Set<Id> agencyIds) {
        Map<String, ProjectAgencyAllocation__c> result = new Map<String, ProjectAgencyAllocation__c>();
        
        if (projectIds.isEmpty() || agencyIds.isEmpty()) return result;
        
        for (ProjectAgencyAllocation__c pa : [
            SELECT Id, Project__c, Account__c, IsActive__c
            FROM ProjectAgencyAllocation__c
            WHERE Project__c IN :projectIds
            AND Account__c IN :agencyIds
        ]) {
            result.put(pa.Project__c + '-' + pa.Account__c, pa);
        }
        return result;
    }
    
}