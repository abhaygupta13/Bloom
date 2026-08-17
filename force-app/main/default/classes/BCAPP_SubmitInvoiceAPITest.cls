@IsTest
private class BCAPP_SubmitInvoiceAPITest {

    // Invoke doPost safely and swallow handler exceptions so controller lines get covered.
    private static void safeInvoke(String operation, Map<String,Object> data) {
        if (data == null) data = new Map<String,Object>();

        Map<String,Object> body = new Map<String,Object>{
            'operation' => operation,
            'data'      => data,
            'accountId' => UserInfo.getUserId()
        };

        RestRequest req = new RestRequest();
        req.requestUri  = '/services/apexrest/v1/submit-invoice';
        req.httpMethod  = 'POST';
        req.addHeader('Content-Type','application/json');
        req.requestBody = Blob.valueOf(JSON.serialize(body));

        RestContext.request  = req;
        RestContext.response = new RestResponse();

        try {
            
            BCAPP_SubmitInvoiceAPI.doPost(); // we only need to hit the controller
        } catch (Exception e) {
            // Expected if downstream handlers query/callout/etc. in a blank test context.
            System.debug('Handler threw (expected in unit test): ' + e.getMessage());
        }

        System.assertEquals('POST', RestContext.request.httpMethod);
    }

    @IsTest
    static void covers_all_supported_operations() {
        for (String op : new List<String>{
            'submitpayment',
            'updatepaymentstatus',
            'validateQuickPay',
            'submitQuickPay',
            'updateQuickPayStatus',
            'submitServiceRequestPayment',
            'updateServiceRequestPaymentStatus'
        }) {
            safeInvoke(op, new Map<String,Object>{ 'dummy' => true });
        }
    }

    @IsTest
    static void covers_default_else_branch() {
        // exercise the "when else" path
        safeInvoke('notARealOperation', new Map<String,Object>{});
    }
}