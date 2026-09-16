/*
* @Author      : Rushikesh Jadhav
* @CreatedDate : 26th MAY 2025
* @Description : Apex REST Web Service controller for handling Broker Application and Applicant operations
*                such as application submission, applicant submission, profile retrieval, and tracking application status.
*/
/*****************************************************************************************************
* Version   Author           Date           Comment
* 1.0       Rushikesh      26th MAY 2025    Initial draft - Supports POST operations for application/applicant
*                                           submissions and GET operation for tracking application via URL endpoints.
*****************************************************************************************************/

@RestResource(urlMapping='/brokerAppWebService/V1/*')
global class BAPPWebService {
	
    @HttpPost //Handles HTTP POST requests and delegates to the appropriate helper method.
    global static void doPost() {
        RestRequest req = RestContext.request;
        String requestBodyString;

        if(RestContext.request.requestBody != null){
            requestBodyString = RestContext.request.requestBody.toString();
        }

        switch on req.requestURI.substringAfterLast('/') {
            when 'submitBrokerApplication' {
                System.debug('submitBrokerApplication >>>> Called');
                BAPPSubmitBrokerApplicationHandler.handleBrokerApplication(requestBodyString);
            }
            when 'submitBrokerApplicant' {
                System.debug('BBAPPWebService.BrokerApplicant>>>>>>');
                BAPPSubmitBrokerApplicantHandler.handleBrokerApplicant(requestBodyString);
            }
            when 'submitBrokerCaseApplicant' {
                System.debug('BBAPPWebService.BrokerCaseApplicant>>>>>>');
                BAPPSubmitCaseApplicantHandler.handleCaseBrokerApplicant(requestBodyString);
            }
            when 'getApplicantProfile'{
                BAPPLoginHandler.handleGetProfile(requestBodyString);
            }
            when 'submitLead' {
                BAPPLeadGenerationHandler.handleLeadGeneration(requestBodyString);
            }
            when 'filterLeads' {
                BAPPGetLeadsHandler.handleLeadFilters();
            }
            when 'submitCaseServiceRequest' {
                BAPPCaseServiceRequestHandler.handleCaseServiceRequest();
            }
            when 'unitAssignment'{
                BAPPAssignUnassignUnitHandler.handleAssignUnassign(requestBodyString);
            }
            when 'getUnitListing' {
                BAPPGetUnitListHandler.handleGetUnitList(requestBodyString);
            }
            when 'submitContactCase' {
                BAPPUpdateAgentInfoHandler.handleUpdateAgentInfo(requestBodyString);
            }
            when 'submitAgencyCase' {
                BAPPAgencyInfoUpdateHandler.handleAgencyInfoUpdate(requestBodyString);
            }
        }
    }
    ////Handles HTTP GET requests
   @HttpGet
    global static void doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        // Extract endpoint name from the URL
        String endpoint = req.requestURI.substringAfterLast('/');

        //  Extract query parameters (if needed)
        Map<String, String> params = req.params;

        // Switch based on endpoint
        switch on endpoint {
            when 'trackMyApplication' {
                String rawApplicationNumber = params.get('applicationNumber');

                // Validate BEFORE adding 'BA-'
                if (String.isBlank(rawApplicationNumber?.trim())) {
                    BAPPSubmitBrokerApplicationHandler.makeErrorResponse(Label.BAAP_MissingApplicationNumber, 400);
                    return;
                }
                String applicationNumber = 'BA-' + params.get('applicationNumber');
                BAPPSubmitBrokerApplicationHandler.handleTrackApplication(applicationNumber);
            }
            when 'getTeamMember' {
                
                String accountId = params.get('accountId');
                    if (String.isBlank(accountId)) {
                        RestContext.response.statusCode = 400;
                        RestContext.response.responseBody = Blob.valueOf('{"message":"Missing accountId"}');
                        return;
                    }
                    BAPPGetTeamMembersHandler.handleGetTeamMember(accountId);
            }
            /*when 'getLLeads' {
                String accountId = params.get('accountId');
                String contactId = params.get('contactId');
    
                if (String.isBlank(accountId) && String.isBlank(contactId)) {
                    RestContext.response.statusCode = 400;
                    RestContext.response.responseBody = Blob.valueOf('{"status":"error", "message":"Missing accountId or contactId"}');
                    return;
                }
    
                BAPPLeadGenerationHandler.handleGetLeads(accountId, contactId);
            }*/
            when 'searchLead' {
                String searchKey = params.get('searchKey');
                String accountId = params.get('accountId');
                String contactId = params.get('contactId');
                //String objectName = params.get('objectName');
                Boolean duplicateSearch = (params.containsKey('duplicateSearch') &&
                                   params.get('duplicateSearch') == 'true');
               
                BAPPSearchHandler.handleGetLeads(searchKey,accountId,contactId,duplicateSearch);
            }
            when 'getLeads' {
                BAPPGetLeadsHandler.handleLeadFilters();
            }
            when 'getSalesOrder' {
                BAPPGetSalesOrdersHandler.handleSalesOrderFilters();
            }
            when 'leadStatusCount' {
                BAPPGetLeadsHandler.getLeadStatusCounts();
            }
            when 'getProjectAgencyAllocation' {
                String accountId = params.get('accountId');
                if (String.isBlank(accountId)) {
                    RestContext.response.statusCode = 400;
                    RestContext.response.responseBody = Blob.valueOf('{"status":"error","message":"Missing accountId"}');
                    return;
                }
                BAPPGetProjectsHandler.handleGetProjects(accountId);
            }
            when 'getProjects' {
                String accountId = params.get('accountId');
                String contactId = params.get('contactId');
            
                if (String.isBlank(accountId) || String.isBlank(contactId)) {
                    RestContext.response.statusCode = 400;
                    RestContext.response.responseBody = Blob.valueOf(
                        '{"status":"error","message":"Missing accountId or contactId"}'
                    );
                    return;
                }
            
                BAPPGetProjectListingHandler.handleGetProjects(accountId, contactId);
            }
            when 'brokerSummaryCount' {
                BAPPGetLeadsHandler.getBrokerSummaryCounts();
            }
            when 'getServiceRequests' {
                BAPPCaseServiceRequestHandler.getServiceRequests();
            }
        }
    }
}