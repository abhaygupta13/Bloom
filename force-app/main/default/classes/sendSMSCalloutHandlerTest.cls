@isTest
public class sendSMSCalloutHandlerTest {
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a mock HTTP response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"token": "mockedTokenValue"}');
            return res;
        }
    }
    
     @isTest static void CalloutSendSMSTestMethod(){
         
          Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
          Set<id>smsid = new Set<id>();
         SMSTransaction__c smt = new SMSTransaction__c();
         smt.Phone_Number__c = '535335353';
         smt.Message__c ='test message';
         smt.Send_SMS__c = true;
         insert smt;
         smsid.add(smt.id);
         sendSMSCalloutHandler.sendSMS(smsid);
         
       
         
     }
         
}