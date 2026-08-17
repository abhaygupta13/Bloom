/**
 * Class: BCAPP_AccessCardAPI
 * Purpose: REST API controller for Access Card–related operations such as fetching active cards
 *          and checking eligibility. Delegates all logic to BCAPP_AccessCardServiceHandler.
 *
 * Created By: Bloom Dev
 * Created On: 2025-09-01
 *
 * Description:
 * - Endpoint: POST /services/apexrest/v1/get-access-card
 * - Expects JSON payload with an "operation" key and other request parameters.
 * - Supported operations:
 *      • getaccesscards          → fetch active access cards
 *      • geteligibleaccesscards  → check eligibility for access card request
 * - Controller is thin: no inline SOQL/DML. All business logic and data access live in service classes.
 */
@RestResource(urlMapping='/v1/get-access-card')
global with sharing class BCAPP_AccessCardAPI {

    /**
     * Handles POST request for Access Card operations.
     * @requestBody JSON -> Map<String,Object> with "operation" and other parameters.
     * @behavior    Dispatches to BCAPP_AccessCardServiceHandler methods based on operation.
     */
    @HttpPost
    global static void handleAccessCardApi() {
        Map<String, Object> reqMap =
            (Map<String, Object>) JSON.deserializeUntyped(RestContext.request.requestBody.toString());

        String operation = (String) reqMap.get('operation');
        Map<String, Object> response = new Map<String, Object>();

        if (String.isBlank(operation)) {
            response.put('errorMessage', 'Missing operation key');
            BCAPP_WebServiceHelper.makeServerErrorResponse(response);
            return;
        }

        if (operation == 'getaccesscards') {
            BCAPP_AccessCardServiceHandler.getActiveCards(reqMap);
        } else if (operation == 'geteligibleaccesscards') {
            BCAPP_AccessCardServiceHandler.checkEligibility(reqMap);
        } else {
            response.put('errorMessage', 'Unsupported operation: ' + operation);
            BCAPP_WebServiceHelper.makeServerErrorResponse(response);
        }
    } 
}