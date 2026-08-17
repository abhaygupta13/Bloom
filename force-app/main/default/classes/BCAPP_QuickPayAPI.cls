/**
 * Class: BCAPP_QuickPayAPI
 * Purpose: REST API endpoint for Quick Pay operations (validate, submit, update status).
 *          Delegates all business logic to BCAPP_QuickPayHandler. No SOQL/DML here.
 *
 * Created By: Bloom Dev
 * Created On: 2025-09-01
 *
 * Description:
 * - Endpoint: POST /services/apexrest/v1/quick-pay
 * - Expects JSON payload with:
 *      • operation → one of: validateQuickPay | submitQuickPay | updateQuickPayStatus
 *      • data      → Map<String,Object> containing the parameters for the chosen operation
 * - Controller remains thin and only routes requests.
 */
@RestResource(urlMapping='/v1/quick-pay')
global with sharing class BCAPP_QuickPayAPI {

    /**
     * Handles POST requests for Quick Pay.
     * Behavior:
     * - Reads "operation" and "data" from the request body.
     * - Dispatches to the appropriate method in BCAPP_QuickPayHandler.
     * - On unsupported operation, returns an error via BCAPP_WebServiceHelper.
     */
    @HttpPost
    global static void handleQuickPay() {
        RestRequest req = RestContext.request;
        Map<String, Object> body =
            (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());

        String operation = (String) body.get('operation');
        Map<String, Object> data = (Map<String, Object>) body.get('data');

        switch on operation {
            when 'validateQuickPay' {
                BCAPP_QuickPayHandler.validateQuickPay(data);
            }
            when 'submitQuickPay' {
                BCAPP_QuickPayHandler.submitQuickPay(data);
            }
            when 'updateQuickPayStatus' {
                BCAPP_QuickPayHandler.updateQuickPayStatus(data);
            }
            when else {
                BCAPP_WebServiceHelper.makeServerErrorResponse(new Map<String, Object>{
                    'errorMessage' => 'Unsupported operation: ' + operation
                });
            }
        }
    }
}