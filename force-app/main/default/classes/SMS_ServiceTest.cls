@isTest
public class SMS_ServiceTest {
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"messages":[{"to":"447491163443","status":{"groupId":1,"groupName":"PENDING","id":7,"name":"PENDING_WAITING_DELIVERY","description":"Message sent to next instance"}}]}');
            return res;
        }
    }
    
    @isTest
    static void testSendEmail() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        SMS_Service.sendEmail('test@example.com', 'Test email body');
        Test.stopTest();
        
    }
    
    @isTest
    static void testSendSMS() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        SMS_Service.sendSMS('447491163443', 'This is a test SMS message.');
        Test.stopTest();
        
    }
    
    @isTest
    static void testSendEmail_InvalidInput() {
        try {
            SMS_Service.sendEmail(null, 'Test email body');
        } catch (Exception e) {
        }
    }
    
    @isTest
    static void testSendSMS_InvalidInput() {
        // Validate how the method behaves with invalid inputs
        try {
            SMS_Service.sendSMS(null, 'This is a test SMS message.');
        } catch (Exception e) {
        }
    }
}