/**
 * Class: BCAPP_GetInvoicesAPI
 * Purpose: REST API controller for fetching invoice-related data such as invoices, summaries,
 *          receipts, payment history, and statements of account. 
 *          Delegates all logic to BCAPP_InvoiceHandler.
 *
 * Created By: Bloom Dev
 * Created On: 2025-09-01
 *
 * Description:
 * - Endpoint: POST /services/apexrest/v1/get-invoices
 * - Expects JSON payload with:
 *      • operation → string key defining the action
 *      • data      → Map<String,Object> containing request parameters
 * - Supported operations:
 *      • getinvoices
 *      • getinvoicebyid
 *      • getsummary
 *      • getpaymenthistory
 *      • getreceipt
 *      • getpaymentstatus
 *      • getstatementofaccount
 * - Controller contains no SOQL/DML. Data access is done via BCAPP_InvoiceHandler and service classes.
 */
@RestResource(urlMapping='/v1/get-invoices')
global with sharing class BCAPP_GetInvoicesAPI {

    /**
     * Handles POST requests for invoice operations.
     * @requestBody JSON -> Map<String,Object> with "operation" and "data".
     * @behavior    Dispatches to BCAPP_InvoiceHandler methods based on operation.
     */
    @HttpPost
    global static void doPost() {
        RestRequest req = RestContext.request;
        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());

        String requestType = (String) body.get('operation');
        Map<String, Object> data = (Map<String, Object>) body.get('data');

        switch on requestType {
            when 'getinvoices'           { BCAPP_InvoiceHandler.getInvoices(data); }
            when 'getinvoicebyid'        { BCAPP_InvoiceHandler.getInvoiceById(data); }
            when 'getsummary'            { BCAPP_InvoiceHandler.getSummary(data); }
            when 'getpaymenthistory'     { BCAPP_InvoiceHandler.getPaymentHistory(data); }
            when 'getreceipt'            { BCAPP_InvoiceHandler.getReceipt(data); }
            when 'getpaymentstatus'      { BCAPP_InvoiceHandler.getPaymentStatus(data); }
            when 'getstatementofaccount' { BCAPP_InvoiceHandler.getStatementOfAccount(data); }
            when else {
                Map<String, Object> response = new Map<String, Object>{'errorMessage' => 'Unsupported requestType: ' + requestType};
                BCAPP_WebServiceHelper.makeServerErrorResponse(response);
            }
        }
    }
}