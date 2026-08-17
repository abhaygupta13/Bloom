@isTest
private class BCAPP_PushNotificationAPITest {

    // Capture the last request at top-level to avoid static-in-inner-class error
    private static HttpRequest lastReq;
    private class PushMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            BCAPP_PushNotificationAPITest.lastReq = req;
            HttpResponse res = new HttpResponse();
            res.setStatusCode(202);
            res.setBody('{"messages":[{"messageId":"abc123"}]}');
            return res;
        }
    }

    private static BCAPP_PushNotificationAPI.PushNotificationParams makeParams() {
        BCAPP_PushNotificationAPI.PushNotificationParams p =
            new BCAPP_PushNotificationAPI.PushNotificationParams(
                'reg-123',
                'Test Title',
                'Hello from unit test',
                'SR-0001',
                'Submitted'
            );
        p.moduleName = 'Access Card';
        p.deepLinkUrl = 'app://sr/SR-0001';
        p.scheduledTime = Datetime.newInstance(2026, 1, 1, 8, 0, 0);
        p.options = new Map<String, Object>{ 'badge' => 3, 'isSilent' => true };
        return p;
    }

    @isTest static void test_enqueue_and_send_success() {
        Test.setMock(HttpCalloutMock.class, new PushMock());

        List<BCAPP_PushNotificationAPI.PushNotificationParams> listParams = new List<BCAPP_PushNotificationAPI.PushNotificationParams>{
            makeParams(),
            new BCAPP_PushNotificationAPI.PushNotificationParams('', 'T', 'M', null, null) // skipped (no registration id)
        };

        BCAPP_PushNotificationAPI job = new BCAPP_PushNotificationAPI(listParams);

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        System.assertNotEquals(null, lastReq, 'Expected an HTTP request to be made');
        // Basic assertions on request configuration
        System.assertEquals('application/json', lastReq.getHeader('Content-Type'));
        System.assert(!String.isBlank(lastReq.getHeader('Authorization')));

        String body = lastReq.getBody();
        System.assert(body.contains('reg-123'));
        System.assert(body.contains('Test Title'));
        System.assert(body.contains('customPayload'));
        System.assert(body.contains('Access Card'));
    }
}