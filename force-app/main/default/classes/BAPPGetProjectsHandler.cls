/*
* @Author        : Rushikesh Jadhav
* @CreatedDate  : 22th SEP 2025
* @Description  : Handler class that retrieves active projects mapped to 
*                 a broker account and indicates whether the
*                 broker has assigned units for each project.
*/
/*****************************************************************************************************
* Version       Author           Date             Comment                                                                       
* 1.0           Rushikesh        22-SEP-2025      Initial implementation of BAPP project handler
*****************************************************************************************************/

public with sharing class BAPPGetProjectsHandler {

    public static void handleGetProjects(String accountId) {
        try {
            // === Validate accountId ===
            if (String.isBlank(accountId)) {
                returnError(Label.BAPP_AccountIdRequired, 400);
                return;
            }

            // === Validate accountId existence ===
            if (!Utility.recordExists(accountId)) {
                returnError(Label.BAPP_InvalidAccountId, 404);
                return;
            }
            ProjectAgencyAllocationService service = ProjectAgencyAllocationService.getInstance();
            BrokerUnitAllocationService BuaService = BrokerUnitAllocationService.getInstance();

            // Get allocations
            List<ProjectAgencyAllocation__c> allocations = service.getAllocationsByAccount(accountId);
            

            // Map allocations to unique projects 
            Map<Id, Project__c> projectMap = new Map<Id, Project__c>();
            for (ProjectAgencyAllocation__c paa : allocations) {
                if (paa.Project__r != null) {
                    projectMap.put(paa.Project__r.Id, new Project__c(
                        Id = paa.Project__r.Id,
                        Name = paa.Project__r.Name
                    ));
                }
            }
            List<Project__c> activeProjects = projectMap.values();

            // Get assigned project IDs (with active units)
            Set<Id> assignedProjectIds = BuaService.getAssignedProjectIds(accountId);
            System.debug('assignedProjectIds >>'+assignedProjectIds);
            if (assignedProjectIds == null) {
                assignedProjectIds = new Set<Id>();
            }

            // Build response
            List<Map<String, Object>> results = new List<Map<String, Object>>();
            for (Project__c proj : activeProjects) {
                Map<String, Object> row = new Map<String, Object>{
                    'ProjectId'     => proj.Id,
                    'ProjectName'   => proj.Name,
                    'UnitsAssigned' => assignedProjectIds.contains(proj.Id) ? 'Yes' : 'No'
                };
                results.add(row);
            }
            
            Map<String, Object> response = new Map<String, Object>{
                'status'    => 'success',
                'accountId' => accountId,
                'projects'  => results
            };
                
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf(JSON.serializePretty(response));

        } catch (Exception ex) {
            RestContext.response.statusCode = 500;
            RestContext.response.responseBody =
                Blob.valueOf('{"status":"error","message":"' + ex.getMessage() + '"}');
        }
    }

    // === Reusable Error Response Method ===
    private static void returnError(String msg, Integer code) {
        RestContext.response.statusCode = code;
        RestContext.response.addHeader('Content-Type', 'application/json;charset=UTF-8');
        RestContext.response.responseBody = Blob.valueOf(
            JSON.serializePretty(new Map<String, Object>{
                'status' => 'error',
                'message' => msg
            })
        );
    }
}