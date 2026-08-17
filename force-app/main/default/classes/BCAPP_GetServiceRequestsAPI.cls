/**
 * Class: BCAPP_GetServiceRequestsAPI
 * Purpose: REST Controller for fetching Service Requests (Cases) from the mobile app.
 *          Delegates request handling to BCAPP_GenericServiceHandler. No SOQL/DML here.
 *
 * Created By: Bloom Dev
 * Created On: 2025-09-01
 *
 * Description:
 * - Endpoint: POST /services/apexrest/v1/service-request-get
 * - Accepts JSON payload with filter parameters for fetching Service Requests.
 * - Controller stays thin, routing logic only. Data access happens in handler/service classes.
 */
@RestResource(urlMapping='/v1/service-request-get')
global with sharing class BCAPP_GetServiceRequestsAPI {

    /**
     * Handles POST request to fetch Service Requests (Cases).
     * @requestBody JSON -> Map<String,Object> with filters and request context.
     * @behavior    Delegates to BCAPP_GenericServiceHandler.handleFetchRequest(reqMap).
    */
    @HttpPost
    global static void listRequests() {
        Map<String, Object> reqMap =
            (Map<String, Object>) JSON.deserializeUntyped(RestContext.request.requestBody.toString());
        BCAPP_GenericServiceHandler.handleFetchRequest(reqMap);
    } 
}