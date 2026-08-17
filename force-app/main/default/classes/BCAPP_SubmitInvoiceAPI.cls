/**
 * Class: BCAPP_SubmitInvoiceAPI
 * Purpose: REST API controller for submitting or updating invoice-related payments,
 *          quick pay, and service request payments. Routes requests to appropriate handlers.
 *
 * Created By: Bloom Dev
 * Created On: 2025-09-01
 *
 * Description:
 * - Endpoint: POST /services/apexrest/v1/submit-invoice
 * - Expects JSON payload with:
 *      • operation → string key defining the action
 *      • data      → Map<String,Object> containing request parameters
 * - Supported operations:
 *      • submitpayment                  → BCAPP_InvoiceHandler.submitPayment
 *      • updatepaymentstatus            → BCAPP_InvoiceHandler.updatePaymentStatus
 *      • validateQuickPay               → BCAPP_QuickPayHandler.validateQuickPay
 *      • submitQuickPay                 → BCAPP_QuickPayHandler.submitQuickPay
 *      • updateQuickPayStatus           → BCAPP_QuickPayHandler.updateQuickPayStatus
 *      • submitServiceRequestPayment    → BCAPP_ServiceRequestPaymentHandler.submitPayment
 *      • updateServiceRequestPaymentStatus → BCAPP_ServiceRequestPaymentHandler.updatePaymentStatus
 * - Controller remains thin: no SOQL/DML. All data access is delegated to handler/service classes.
 */
@RestResource(urlMapping='/v1/submit-invoice')
global without sharing class BCAPP_SubmitInvoiceAPI {

    /**
     * Handles POST requests for invoice and quick pay operations.
     * @requestBody JSON -> Map<String,Object> with "operation" and "data".
     * @behavior    Dispatches to appropriate handler class based on operation.
     */
    @HttpPost
    global static void doPost() {
        RestRequest req = RestContext.request;
        Map<String, Object> body = 
            (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());

        String requestType = (String) body.get('operation');
        Map<String, Object> data = (Map<String, Object>) body.get('data');

        switch on requestType {
            when 'submitpayment' {
                BCAPP_InvoiceHandler.submitPayment(data);
            }
            when 'updatepaymentstatus' {
                BCAPP_InvoiceHandler.updatePaymentStatus(data);
            }
            when 'validateQuickPay' {
                BCAPP_QuickPayHandler.validateQuickPay(data);
            }
            when 'submitQuickPay' {
                BCAPP_QuickPayHandler.submitQuickPay(data);
            }
            when 'updateQuickPayStatus' {
                BCAPP_QuickPayHandler.updateQuickPayStatus(data);
            }
            when 'submitServiceRequestPayment' {
                BCAPP_ServiceRequestPaymentHandler.submitPayment(data);
            }
            when 'updateServiceRequestPaymentStatus' {
                BCAPP_ServiceRequestPaymentHandler.updatePaymentStatus(data);
            }
            when else {
                Map<String, Object> response = new Map<String, Object>{
                    'errorMessage' => 'Unsupported requestType: ' + requestType
                };
                BCAPP_WebServiceHelper.makeServerErrorResponse(response);
            }
        }
    }
}