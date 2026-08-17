/*
* @Author        : Rushikesh Jadhav
* @CreatedDate  : 20th SEP 2025
* @Description  : Apex handler for retrieving broker project listings.
*                 - Validates account and contact inputs.
*                 - Fetches assigned and public projects for brokers.
*/
/*****************************************************************************************************
* Version     Author             Date           Comment
* 1.0         Rushikesh Jadhav   26SEP2025      Initial draft – broker project listing implementation
*****************************************************************************************************/

public with sharing class BAPPGetProjectListingHandler {

    public static void handleGetProjects(Id accountId, Id contactId) {
        // --- Validate input ---
        if (String.isBlank(accountId) || String.isBlank(contactId)) {
            sendErrorResponse(Label.BAPP_AccountAndContactRequired, 400);
            return;
        }

        // --- Validate record existence ---
        if (!Utility.recordExists(accountId)) {
            sendErrorResponse(Label.BAPP_InvalidAccountId, 404);
            return;
        }
        if (!Utility.recordExists(contactId)) {
            sendErrorResponse(Label.BAPP_InvalidContactId, 404);
            return;
        }

        // --- Validate contact belongs to account ---
        Contact con = ContactService.getInstance().getContactById(contactId);
        if (con == null || con.AccountId != accountId) {
            sendErrorResponse(Label.BAPP_InvalidAccountContactRelation, 400);
            return;
        }

        // --- Determine high-level role ---
        Set<String> highLevelRoles = new Set<String>{'Admin','SuperAdmin','CEO','Owner','Partner','AuthorizedSignatoryOfficer'};
        Boolean isHighLevel = false;
        if (!String.isBlank(con.BrokerContactRole__c)) {
            Set<String> roles = new Set<String>(con.BrokerContactRole__c.split(';'));
            roles.retainAll(highLevelRoles);
            isHighLevel = !roles.isEmpty();
        }

        // --- Fetch assigned projects ---
        List<Project__c> assignedProjects = isHighLevel ? 
            BrokerUnitAllocationService.getProjectsForAccount(accountId) : 
            BrokerUnitAssignmentService.getProjectsForContact(contactId, accountId);

        // --- Fetch public projects ---
        List<Project__c> publicProjects = fetchBrokerPublicProjects();

        // --- Merge all projects (avoid duplicates) ---
        Map<Id, Project__c> allProjects = new Map<Id, Project__c>();
        for (Project__c p : publicProjects) allProjects.put(p.Id, p);
        for (Project__c p : assignedProjects) allProjects.put(p.Id, p);

        if (allProjects.isEmpty()) {
            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf('{"projectDetails":[]}');
            return;
        }

        // --- Prepare Id sets ---
        Set<Id> assignedProjectIds = new Map<Id, Project__c>(assignedProjects).keySet();
        Set<Id> publicProjectIds = new Map<Id, Project__c>(publicProjects).keySet();

        // --- Get unit counts and types using service classes ---
        Map<Id, Integer> unitCounts = new Map<Id, Integer>();
        Map<Id, List<String>> unitTypes = new Map<Id, List<String>>();

        if (isHighLevel) {
            unitCounts.putAll(BrokerUnitAllocationService.getUnitCounts(assignedProjectIds, accountId));
            unitTypes.putAll(BrokerUnitAllocationService.getUnitTypes(assignedProjectIds, accountId));
        } else {
            unitCounts.putAll(BrokerUnitAssignmentService.getUnitCounts(assignedProjectIds, accountId, contactId));
            unitTypes.putAll(BrokerUnitAssignmentService.getUnitTypes(assignedProjectIds, accountId, contactId));
        }

        // --- Public projects units ---
        Map<Id, Integer> publicUnitCounts = fetchPublicUnitCounts(publicProjectIds);
        Map<Id, List<String>> publicUnitTypes = fetchPublicUnitTypes(publicProjectIds); 
        
        // Merge counts
        for (Id projId : publicUnitCounts.keySet()) {
            Integer count = publicUnitCounts.get(projId);
            if (unitCounts.containsKey(projId)) {
                unitCounts.put(projId, unitCounts.get(projId) + count);
            } else {
                unitCounts.put(projId, count);
            }
        }
        
        // Merge unit types
        for (Id projId : publicUnitTypes.keySet()) {
            if (!unitTypes.containsKey(projId)) unitTypes.put(projId, new List<String>());
            for (String type : publicUnitTypes.get(projId)) {
                if (!unitTypes.get(projId).contains(type)) {
                    unitTypes.get(projId).add(type);
                }
            }
        }

        // --- Build response ---
        List<Map<String, Object>> projectList = new List<Map<String, Object>>();
        for (Project__c proj : allProjects.values()) {
            Integer totalUnits = unitCounts.containsKey(proj.Id) 
                ? unitCounts.get(proj.Id) 
                : 0;
        
            // Skip projects with zero units
            if (totalUnits == 0) {
                continue;
            }
            Map<String, Object> projMap = new Map<String, Object>();
            projMap.put('isPublic', proj.IsPublic__c);
            projMap.put('projectName', proj.Name);
            projMap.put('projectId', proj.Id);
            projMap.put('Location', proj.Office_Location__c);
            projMap.put('Amenities', proj.Amenities__c);
            projMap.put('totalUnitCount', unitCounts.containsKey(proj.Id) ? unitCounts.get(proj.Id) : 0);
            projMap.put('unitType', unitTypes.containsKey(proj.Id) ? unitTypes.get(proj.Id) : new List<String>());
            projectList.add(projMap);
        }

        // --- Send response ---
        RestContext.response.statusCode = 200;
        Map<String, Object> respWrapper = new Map<String, Object>{'projectDetails' => projectList};
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(respWrapper));
    }
    // fetch broker public projects
    private static List<Project__c> fetchBrokerPublicProjects() {
        return [
            SELECT Id, Name, Office_Location__c, Amenities__c,
                   IsPublic__c, IsAvailableForBroker__c
            FROM Project__c
            WHERE IsPublic__c = true
              AND IsAvailableForBroker__c = true
              AND IsActive__c = true
        ];
    }
    //  Broker-specific unit counts
    private static Map<Id, Integer> fetchPublicUnitCounts(Set<Id> projectIds) {
        Map<Id, Integer> mapCounts = new Map<Id, Integer>();
        if (projectIds.isEmpty()) return mapCounts;
    
        for (AggregateResult ar : [
            SELECT Project__c, COUNT(Id) totalUnits
            FROM Unit__c
            WHERE Project__c IN :projectIds
              AND IsPublic__c = true
              AND IsActive__c = true
              AND Status__c = 'Available'
              AND Direct_Indirect__c != 'Direct'
            GROUP BY Project__c
        ]) {
            mapCounts.put(
                (Id) ar.get('Project__c'),
                (Integer) ar.get('totalUnits')
            );
        }
        return mapCounts;
    }
    // Broker-specific unit types
    private static Map<Id, List<String>> fetchPublicUnitTypes(Set<Id> projectIds) {
        Map<Id, List<String>> mapTypes = new Map<Id, List<String>>();
        if (projectIds.isEmpty()) return mapTypes;
    
        for (Unit__c u : [
            SELECT Project__c, UnitType__c
            FROM Unit__c
            WHERE Project__c IN :projectIds
              AND IsPublic__c = true
              AND IsActive__c = true
              AND Status__c = 'Available'
              AND Direct_Indirect__c != 'Direct'
        ]) {
            if (!mapTypes.containsKey(u.Project__c)) {
                mapTypes.put(u.Project__c, new List<String>());
            }
            if (!String.isBlank(u.UnitType__c)
                && !mapTypes.get(u.Project__c).contains(u.UnitType__c)) {
                mapTypes.get(u.Project__c).add(u.UnitType__c);
            }
        }
        return mapTypes;
    }

    private static void sendErrorResponse(String message, Integer statusCode) {
        RestContext.response.statusCode = statusCode;
        Map<String, Object> errorMap = new Map<String, Object>{'status' => 'error', 'message' => message};
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(errorMap));
    }
}