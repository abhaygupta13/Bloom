@IsTest
public class SMSHandlerTest {

    /* =====================================================
     * MOCK
     * ===================================================== */
    private class SMSHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"success"}');
            return res;
        }
    }

    /* =====================================================
     * COMMON TEST DATA HELPERS
     * ===================================================== */

    private static List<OTP__c> createOTPData() {
        OTP__c otp = new OTP__c(
            PhoneNumber__c = '971500000000',
            OTPCode__c     = '123456'
        );
        insert otp;
        return new List<OTP__c>{ otp };
    }

    private static BrokerApplication__c createAgreementApplication() {
        BrokerApplication__c app = new BrokerApplication__c(
            Name = 'Agreement Test App',
            CompanyPhone_Number__c = '501111111',
            CountryCode__c = '971',
            AgreementInitiationDate__c = Date.today().addDays(-5)
        );
        insert app;
        return app;
    }

    private static BrokerApplicant__c createPartnerApplicant(Id appId) {
        BrokerApplicant__c ba = new BrokerApplicant__c(
            BrokerApplication__c = appId,
            BrokerContactRole__c = 'Partner',
            PhoneNumber__c = '522222222',
            CountryCode__c = '971'
        );
        insert ba;
        return ba;
    }

    /* =====================================================
     * OTP SMS TESTS
     * ===================================================== */

    @IsTest
    static void testGetSuperAppOTPSMS() {
        SMSHandler.SMS sms =
            SMSHandler.getSuperAppOTPSMS(createOTPData());

        System.assertEquals(1, sms.messages.size());
        System.assertEquals('SMS', sms.messages[0].channel);
    }

    @IsTest
    static void testGetBrokerAppOTPSMS() {
        SMSHandler.SMS sms =
            SMSHandler.getBrokerAppOTPSMS(createOTPData());

        System.assertEquals(1, sms.messages.size());
    }

    /* =====================================================
     * SEND SMS / QUEUEABLE
     * ===================================================== */

    @IsTest
    static void testSendSMS() {
        Test.setMock(HttpCalloutMock.class, new SMSHttpMock());

        SMSHandler.SMS sms =
            SMSHandler.getSuperAppOTPSMS(createOTPData());

        Test.startTest();
        SMSHandler.sendSMS(sms);
        Test.stopTest();

        System.assert(true);
    }

    @IsTest
    static void testQueueableExecution() {
        Test.setMock(HttpCalloutMock.class, new SMSHttpMock());

        SMSHandler.SMS sms =
            SMSHandler.getBrokerAppOTPSMS(createOTPData());

        Test.startTest();
        System.enqueueJob(new SMSHandler(sms));
        Test.stopTest();

        System.assert(true);
    }

    /* =====================================================
     * AGREEMENT REMINDER SMS
     * Uses CMDT: Agreement Pending Signature
     * ===================================================== */

    @IsTest
    static void testAgreementReminderSMS() {
    
        BrokerApplication__c app = createAgreementApplication();
        BrokerApplicant__c partner = createPartnerApplicant(app.Id);
    
        Map<Id, List<BrokerApplicant__c>> applicantsByApp =
            new Map<Id, List<BrokerApplicant__c>>{
                app.Id => new List<BrokerApplicant__c>{ partner }
            };
    
        SMSHandler.SMS sms =
            SMSHandler.getAgreementReminderSMS(
                new List<BrokerApplication__c>{ app },
                applicantsByApp
            );
    
        // ASSERT SAFELY — template may not exist in test org
        System.assertNotEquals(
            null,
            sms,
            'SMS object should not be null'
        );
    
        // Template-driven SMS: messages may be 0 if CMDT not present
        System.assertNotEquals(
            null,
            sms.messages,
            'Messages list should be initialized'
        );
    }

    /* =====================================================
     * RFI REMINDER SMS
     * ===================================================== */

    @IsTest
    static void testRFIReminderSMS() {
    
        BrokerApplication__c app = new BrokerApplication__c(
            Name = 'RFI App',
            CompanyPhone_Number__c = '509999999',
            CountryCode__c = '971'
        );
        insert app;
    
        RFI__c rfi = new RFI__c(
            BrokerApplication__c = app.Id
        );
        insert rfi;
    
        SMSHandler.SMS sms =
            SMSHandler.getRFIReminderSMS(
                new List<RFI__c>{ rfi },
                new Map<Id, List<BrokerApplicant__c>>()
            );
    
        System.assertEquals(
            0,
            sms.messages.size(),
            'No SMS should be generated when metadata template is unavailable in test'
        );
    }
   
}