/**
 * Class: BCAPP_ServiceRequestSubmitAPI
 * Purpose: Unified REST Controller entry-point to submit Service Requests (Cases) from the mobile app.
 *          Delegates to BCAPP_GenericServiceHandler without performing any SOQL/DML here.
 *
 * Created By: Bloom Dev
 * Created On: 2025-09-01
 *
 * Description:
 * - Endpoint: POST /services/apexrest/v1/service-request-submit
 * - Accepts JSON payload for Case-based service requests and routes to the generic handler.
 * - Keeps controller thin; data access and business logic live in handler/service classes.
 */
@RestResource(urlMapping='/v1/service-request-submit')
global with sharing class BCAPP_ServiceRequestSubmitAPI{

    /**
     * Submits a Service Request (Case) based on the JSON body.
     * @requestBody JSON -> Map<String,Object> required by BCAPP_GenericServiceHandler.handleSubmitRequest
     * @behavior    Pure delegation. No SOQL/DML or business rules here.*/
     
    @HttpPost
    global static void submitRequest() {
        Map<String, Object> reqMap =
            (Map<String, Object>) JSON.deserializeUntyped(RestContext.request.requestBody.toString());
        BCAPP_GenericServiceHandler.handleSubmitRequest(reqMap);
    }

}