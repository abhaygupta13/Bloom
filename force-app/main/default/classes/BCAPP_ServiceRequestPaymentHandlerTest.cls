@isTest
private class BCAPP_ServiceRequestPaymentHandlerTest {

    // Capture call count at top-level (inner-class statics not allowed)
    private static Integer callCount = 0;

    private class DualCallMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            BCAPP_ServiceRequestPaymentHandlerTest.callCount++;
            HttpResponse res = new HttpResponse();
            // Token call (form-encoded)
            if (req.getBody() != null && req.getBody().contains('grant_type=password')) {
                res.setStatusCode(200);
                res.setBody('{"access_token":"tok123"}');
                return res;
            }
            // API call
            res.setStatusCode(200);
            res.setBody('{"ok":true}');
            return res;
        }
    }

    private static Account makeAccount(String name) {
        Account a = BCAPP_TestDataFactory.createAccount(name);
        a.SAP_BP_No__c = 'ACC-SRP-001';
        a.AccountNumber = 'ACC-SRP-001';
        insert a;
        return a;
    }

    private static Boolean bankSeeded = false;

    private static void ensureDefaultBank() {
        if (!bankSeeded) {
            if ([SELECT COUNT() FROM BankAccount__c WHERE CompanyCode__c = null] == 0) {
                insert new BankAccount__c(
                    Name = 'Default SRP Bank',
                    MMID__c = 'MMID-SRP-DEFAULT',
                    AccountNumberCorporate__c = '2222222222',
                    IBANNoCorporate__c = 'AE000000000000000020',
                    SwiftCodeCorporate__c = 'SRPDAEAD',
                    CompanyCode__c = '1173'
                );
            }
            bankSeeded = true;
        }
    }

    private static Unit__c makeUnit(String name) {
        Project__c project = new Project__c(Name = 'Service Request Payment Project');
        insert project;

        Unit__c u = new Unit__c(
            Name = name,
            Project__c = project.Id,
            CommunityCompanyCode__c = '1200',
            CommunitySAPUnitNumber__c = '1200',
            SAP_Company_Code__c = '1173'
        );
        insert u;

        if ([SELECT COUNT() FROM BankAccount__c WHERE CompanyCode__c = '1200'] == 0) {
            BankAccount__c ba =  new BankAccount__c(
                Name = 'SRP Bank',
                CompanyCode__c = '1200',
                AccountNumberCorporate__c = '6677889900',
                IBANNoCorporate__c = 'AE000000000000000004',
                SwiftCodeCorporate__c = 'SRPAEAD',
                BankNameCorporate__c = 'SRP Bank',
                MMID__c = 'MMID-SRP'
            );
            insert ba;
            project.BankAccount__c = ba.Id;
            update project;
        }
		
        return u;
    }

    private static Map<String, Object> parse() {
        String body = RestContext.response != null && RestContext.response.responseBody != null
            ? RestContext.response.responseBody.toString() : '';
        System.assertNotEquals('', body, 'Expected response body');
        return (Map<String, Object>) JSON.deserializeUntyped(body);
    }

    @isTest static void test_submit_and_update_success() {
        Account acc = makeAccount('SR Pay AC');
        Unit__c unit = makeUnit('U-SR-PAY');

        ensureDefaultBank();

        // Submit payment
        List<Object> requests = new List<Object>{ new Map<String, Object>{ 'amount' => 60.0 } };
        Map<String, Object> submit = new Map<String, Object>{
            'accountId'   => (String) acc.Id,
            'unitId'       => (String) unit.Id,
            'paymentMethod'=> 'CARD',
            'requestSource'=> 'Service Request',
            'serviceType'  => 'AccessCard',
            'amount'       => 60.0,
            'requests'     => requests
        };

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        BCAPP_ServiceRequestPaymentHandler.submitPayment(submit);
        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> submitWrap = parse();
        String paymentId = (String) ((Map<String, Object>) submitWrap.get('data')).get('paymentId');
        paymentId = BCAPP_Utility.decryptId(paymentId);
        System.assertNotEquals(null, paymentId, 'Payment should be created');

        // Update status to Success -> creates Receipt and posts to SAP (future callout)
        callCount = 0;
        Test.setMock(HttpCalloutMock.class, new DualCallMock());
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        Test.startTest();
        BCAPP_ServiceRequestPaymentHandler.updatePaymentStatus(new Map<String, Object>{
            'paymentId'    => (String) paymentId,
            'status'       => 'Success',
            'message'      => 'OK',
            'paymentMethod'=> 'CARD'
        });
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> updWrap = parse();
        Map<String, Object> updData = (Map<String, Object>) updWrap.get('data');
        System.assertEquals('Success', (String) updData.get('status'));
        Id receiptId = (Id) updData.get('receiptId');
        System.assertNotEquals(null, receiptId, 'Receipt should be returned');

        // Ensure receipt exists
        Receipt__c r = [SELECT Id, OnlinePayment__c FROM Receipt__c WHERE Id = :receiptId LIMIT 1];
        System.assertEquals(paymentId, r.OnlinePayment__c);

        // Future call executed (token + API)
        System.assert(callCount >= 2, 'Expected at least two callouts');
    }

    @isTest static void test_submit_invalid_request_error() {
        // Missing required fields
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        BCAPP_ServiceRequestPaymentHandler.submitPayment(new Map<String, Object>());
        System.assertEquals(500, RestContext.response.statusCode);
        Map<String, Object> wrap = parse();
        System.assertEquals(false, (Boolean) wrap.get('success'));
    }
}