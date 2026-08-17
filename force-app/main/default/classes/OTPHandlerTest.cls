@isTest
private class OTPHandlerTest {
    @testSetup static void setup() {
        //Create Broker Account
        Account testAccount = TestDataFactory.createBrokerAccount('Test', false, '1111111111');
        insert testAccount;

        //Create Contact - Active
        Contact testActiveContact = TestDataFactory.createBrokerContact('TestContactActive', testAccount.Id, false, false, true, 'test@gmail.com');
        insert testActiveContact;

        //Create Contact - InActive
        Contact testInActiveContact = TestDataFactory.createBrokerContact('TestContactInactive', testAccount.Id, false, false, false, 'test1@gmail.com');
        insert testInActiveContact;

        //Create Contact - Terminated
        Contact testTerminatedContact = TestDataFactory.createBrokerContact('TestContactTerminated', testAccount.Id, false, true, false, 'test2@gmail.com');
        insert testTerminatedContact;

        //Create Contact - Suspended
        Contact testSuspendedContact = TestDataFactory.createBrokerContact('TestContactSuspended', testAccount.Id, true, false, false, 'test3@gmail.com');
        insert testSuspendedContact;

        // Create Custom User - Active
        User__c testActiveUser = TestDataFactory.createCustomUser(true, true,'TestUserActive1', 'TestUserActive', testActiveContact.Id, testAccount.Id, 'testUserActive1@test.com', 'a4ed45a7-b964-4ed0-b2aa-111111111111');
        insert testActiveUser;
        System.debug('testUser ACTIVE >> '+testActiveUser);

        // Create Custom User - Inactive
        User__c testInActiveUser = TestDataFactory.createCustomUser(false, false, 'TestUserActive2','TestUserInactive', testInActiveContact.Id, testAccount.Id, 'testUserInactive2@test.com', 'a4ed45a7-b964-4ed0-b2aa-111111111112');
        insert testInActiveUser;
        System.debug('testUser INACTIVE >> '+testInActiveUser);

        // Create Custom User - Terminated
        User__c testTerminatedUser = TestDataFactory.createCustomUser(false, false, 'TestUserActive3','TestTerminatedUser', testTerminatedContact.Id, testAccount.Id, 'testUserTerminated3@test.com', 'a4ed45a7-b964-4ed0-b2aa-111111111113');
        insert testTerminatedUser;
        System.debug('testUser testTerminatedUser >> '+testTerminatedUser);

        //Create Broker Application
        BrokerApplication__c testApplication = TestDataFactory.createBrokerApplication('Test', 'Domestic');
    }

    /**
     * Test Required parameter Transaction Id
     */
    @isTest
    static void testTransactionIdMissing() {
        // Prepare JSON request body
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'processType' => 'Registration',
            'commType' => 'Email',
            'transactionId' => '',
            'email' => 'test@test.com',
            'phoneNumber' => '',
            'accountId' => '',
            'contactId' => '',
            'customerKey' => ''
        });

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri = '/services/apexrest/webServiceUtility/V1/SendOtpToVerify';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(jsonBody);

        try {
            Test.startTest();
            WebServiceUtility.doPost();
            Test.stopTest();
        } catch (OTPHandler.CustomException ce) {
            system.debug('Catch >> CustomException >>');
        }
    }

    /**
     * Test Required parameter Process type
     */
    @isTest
    static void testProcessTypeMissing() {
        // Prepare JSON request body
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'processType' => '',
            'commType' => 'Email',
            'transactionId' => '12345678',
            'email' => 'test@test.com',
            'phoneNumber' => '',
            'accountId' => '',
            'contactId' => '',
            'customerKey' => ''
        });

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri = '/services/apexrest/webServiceUtility/V1/SendOtpToVerify';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(jsonBody);

        try {
            Test.startTest();
            WebServiceUtility.doPost();
            Test.stopTest();
        } catch (OTPHandler.CustomException ce) {
            system.debug('Catch >> CustomException >>');
        }
    }

    /**
     * Test Process Type = Registration with all required parameters
     */
    @isTest
    static void testRegistrationWithAllParameters() {
        // Prepare JSON request body
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'processType' => 'Registration',
            'commType' => 'Email',
            'transactionId' => '12345678',
            'email' => 'test@test.com',
            'phoneNumber' => '',
            'accountId' => '',
            'contactId' => '',
            'customerKey' => ''
        });

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri = '/services/apexrest/webServiceUtility/V1/SendOtpToVerify';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(jsonBody);

        Test.startTest();
        WebServiceUtility.doPost();
        Test.stopTest();

        List<OTP__c> otpData = [SELECT Id, Email__c, ProcessType__c from OTP__c];
        System.debug('otplist >>'+otpData );
        for (OTP__c varOtp : otpData) {
            System.assertEquals('test@test.com', varOtp.Email__c);
        }
        System.assertEquals(200, RestContext.response.statusCode);
    }

    /**
     * Test Process Type = Registration: email parameter missing
     */
    @isTest
    static void testRegistrationEmailMissing() {
        // Prepare JSON request body
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'processType' => 'Registration',
            'commType' => 'Email',
            'transactionId' => '12345678',
            'email' => '',
            'phoneNumber' => '',
            'accountId' => '',
            'contactId' => '',
            'customerKey' => ''
        });

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri = '/services/apexrest/webServiceUtility/V1/SendOtpToVerify';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(jsonBody);

        try {
            Test.startTest();
            WebServiceUtility.doPost();
            Test.stopTest();
        } catch (OTPHandler.CustomException ce) {
            system.debug('Catch >> CustomException >>');
        }
    }
    /**
     * Test Process Type = Registration: comm type parameter missing
     */
    @isTest
    static void testRegistrationCommTypeMissing() {
        // Prepare JSON request body
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'processType' => 'Registration',
            'commType' => '',
            'transactionId' => '12345678',
            'email' => 'test@test.com',
            'phoneNumber' => '',
            'accountId' => '',
            'contactId' => '',
            'customerKey' => ''
        });

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri = '/services/apexrest/webServiceUtility/V1/SendOtpToVerify';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(jsonBody);

        try {
            Test.startTest();
            WebServiceUtility.doPost();
            Test.stopTest();
        } catch (OTPHandler.CustomException ce) {
            system.debug('Catch >> CustomException >>');
        }
    }
    /**
     * Test Process Type = Track My Application with all required parameters
     */
    @isTest
    static void testTrackMyApplicationWithAllParameters() {

        BrokerApplication__c brokerApplicationObj = [SELECT Id, Name, ApplicationNumber__c, AgencyEmail__c from BrokerApplication__c LIMIT 1];

        // Prepare JSON request body
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'processType' => 'Track My Application',
            'commType' => 'Email;SMS',
            'transactionId' => '12345678',
            'email' => '',
            'phoneNumber' => '',
            'accountId' => '',
            'contactId' => '',
            'customerKey' => brokerApplicationObj.ApplicationNumber__c
        });

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri = '/services/apexrest/webServiceUtility/V1/SendOtpToVerify';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(jsonBody);

        Test.startTest();
        WebServiceUtility.doPost();
        Test.stopTest();

        List<OTP__c> otpData = [SELECT Id, Email__c, ProcessType__c from OTP__c];
        System.debug('otplist >>'+otpData );
        for (OTP__c varOtp : otpData) {
            System.assertEquals(brokerApplicationObj.AgencyEmail__c, varOtp.Email__c);
        }
        System.assertEquals(200, RestContext.response.statusCode);
    }

    /**
     * Test Process Type = Track My Application: Comm type missing
     */
    @isTest
    static void testTrackMyApplicationCommTypeMissing() {

        BrokerApplication__c brokerApplicationObj = [SELECT Id, Name, ApplicationNumber__c, AgencyEmail__c from BrokerApplication__c LIMIT 1];

        // Prepare JSON request body
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'processType' => 'Track My Application',
            'commType' => '',
            'transactionId' => '12345678',
            'email' => '',
            'phoneNumber' => '',
            'accountId' => '',
            'contactId' => '',
            'customerKey' => brokerApplicationObj.ApplicationNumber__c
        });

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri = '/services/apexrest/webServiceUtility/V1/SendOtpToVerify';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(jsonBody);

        try {
            Test.startTest();
            WebServiceUtility.doPost();
            Test.stopTest();
        } catch (OTPHandler.CustomException ce) {
            system.debug('Catch >> CustomException >>');
        }
    }
    /**
     * Test Process Type = Track My Application: Invalid Application Number
     */
    @isTest
    static void testTrackMyApplicationInvalidApplicationNumber() {

        BrokerApplication__c brokerApplicationObj = [SELECT Id, Name, ApplicationNumber__c, AgencyEmail__c from BrokerApplication__c LIMIT 1];

        // Prepare JSON request body
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'processType' => 'Track My Application',
            'commType' => 'Email;SMS',
            'transactionId' => '12345678',
            'email' => '',
            'phoneNumber' => '',
            'accountId' => '',
            'contactId' => '',
            'customerKey' => 'BA-222222'
        });

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri = '/services/apexrest/webServiceUtility/V1/SendOtpToVerify';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(jsonBody);

        try {
            Test.startTest();
            WebServiceUtility.doPost();
            Test.stopTest();
        } catch (OTPHandler.CustomException ce) {
            system.debug('Catch >> CustomException >>');
        }
    }

    /**
     * Test Process Type = Track My Application: Customer Key missing
     */
    @isTest
    static void testTrackMyApplicationCustomerKeyMissing() {

        BrokerApplication__c brokerApplicationObj = [SELECT Id, Name, ApplicationNumber__c, AgencyEmail__c from BrokerApplication__c LIMIT 1];

        // Prepare JSON request body
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'processType' => 'Track My Application',
            'commType' => 'Email;SMS',
            'transactionId' => '12345678',
            'email' => '',
            'phoneNumber' => '',
            'accountId' => '',
            'contactId' => '',
            'customerKey' => ''
        });

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri = '/services/apexrest/webServiceUtility/V1/SendOtpToVerify';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(jsonBody);

        try {
            Test.startTest();
            WebServiceUtility.doPost();
            Test.stopTest();
        } catch (OTPHandler.CustomException ce) {
            system.debug('Catch >> CustomException >>');
        }
    }

    /**
     * Test Process Type = Forgot Password with all required parameters
     */
    @isTest
    static void testForgotPasswordWithAllParameters() {

        Contact contactObj = [SELECT Id, Name, email, IsSuspended__c, Blacklisted__c, isActive__c from Contact where lastName='TestContactActive'];

        User__c userObj = [SELECT Id, Name, Email__c from User__c where Email__c ='testUserActive1@test.com'];

        BrokerApplication__c brokerApplicationObj = [SELECT Id, Name, ApplicationNumber__c, AgencyEmail__c from BrokerApplication__c LIMIT 1];

        // Prepare JSON request body
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'processType' => 'Forgot Password',
            'commType' => 'Email;SMS;WhatsApp',
            'transactionId' => '12345678',
            'email' => 'testUserActive1@test.com',
            'phoneNumber' => '',
            'accountId' => '',
            'contactId' => '',
            'customerKey' => ''
        });

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri = '/services/apexrest/webServiceUtility/V1/SendOtpToVerify';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(jsonBody);

        Test.startTest();
        WebServiceUtility.doPost();
        Test.stopTest();

        List<OTP__c> otpData = [SELECT Id, Email__c, ProcessType__c from OTP__c];
        System.debug('otplist >>'+otpData );
        for (OTP__c varOtp : otpData) {
            System.assertEquals(userObj.Email__c, varOtp.Email__c);
        }
        System.assertEquals(200, RestContext.response.statusCode);
    }

    /**
     * Test Process Type = Forgot Password : User not found for email id in request
     */
    @isTest
    static void testForgotPasswordUserNotFound() {

        Contact contactObj = [SELECT Id, Name, email, IsSuspended__c, Blacklisted__c, isActive__c from Contact where lastName='TestContactActive'];

        User__c userObj = [SELECT Id, Name, Email__c from User__c where Email__c ='testUserInactive2@test.com'];

        BrokerApplication__c brokerApplicationObj = [SELECT Id, Name, ApplicationNumber__c, AgencyEmail__c from BrokerApplication__c LIMIT 1];

        // Prepare JSON request body
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'processType' => 'Forgot Password',
            'commType' => 'Email;SMS;WhatsApp',
            'transactionId' => '12345678',
            'email' => 'testUserInactive2@test.com',
            'phoneNumber' => '',
            'accountId' => '',
            'contactId' => '',
            'customerKey' => ''
        });

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri = '/services/apexrest/webServiceUtility/V1/SendOtpToVerify';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(jsonBody);

        try {
            Test.startTest();
            WebServiceUtility.doPost();
            Test.stopTest();
        } catch (OTPHandler.CustomException ce) {
            system.debug('Catch >> CustomException >>');
        }
    }
    /**
     * Test Process Type = Forgot Password : User is Inactive
     */
    @isTest
    static void testForgotPasswordUserInactive() {

        Contact contactObj = [SELECT Id, Name, email, IsSuspended__c, Blacklisted__c, isActive__c from Contact where lastName='TestContactInactive'];

        User__c userObj = [SELECT Id, Name, Email__c from User__c where Email__c ='testUserInactive2@test.com'];

        BrokerApplication__c brokerApplicationObj = [SELECT Id, Name, ApplicationNumber__c, AgencyEmail__c from BrokerApplication__c LIMIT 1];

        // Prepare JSON request body
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'processType' => 'Forgot Password',
            'commType' => 'Email;SMS;WhatsApp',
            'transactionId' => '12345678',
            'email' => 'testUserInactive2@test.com',
            'phoneNumber' => '',
            'accountId' => '',
            'contactId' => '',
            'customerKey' => ''
        });

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri = '/services/apexrest/webServiceUtility/V1/SendOtpToVerify';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(jsonBody);

        Test.startTest();
        WebServiceUtility.doPost();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }
    /**
     * Test Process Type = Forgot Password : User is Terminated
     */
    @isTest
    static void testForgotPasswordUserTerminated() {

        Contact contactObj = [SELECT Id, Name, email, IsSuspended__c, Blacklisted__c, isActive__c from Contact where lastName='TestContactTerminated'];

        User__c userObj = [SELECT Id, Name, Email__c from User__c where Email__c ='testUserTerminated3@test.com'];

        BrokerApplication__c brokerApplicationObj = [SELECT Id, Name, ApplicationNumber__c, AgencyEmail__c from BrokerApplication__c LIMIT 1];

        // Prepare JSON request body
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'processType' => 'Forgot Password',
            'commType' => 'Email;SMS;WhatsApp',
            'transactionId' => '12345678',
            'email' => 'testUserTerminated3@test.com',
            'phoneNumber' => '',
            'accountId' => '',
            'contactId' => '',
            'customerKey' => ''
        });

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri = '/services/apexrest/webServiceUtility/V1/SendOtpToVerify';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(jsonBody);

        Test.startTest();
        WebServiceUtility.doPost();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }
    /**
     * Test Process Type = Forgot Password : Comm Type Missing
     */
    @isTest
    static void testForgotPasswordCommTypeMissing() {

        BrokerApplication__c brokerApplicationObj = [SELECT Id, Name, ApplicationNumber__c, AgencyEmail__c from BrokerApplication__c LIMIT 1];

        // Prepare JSON request body
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'processType' => 'Forgot Password',
            'commType' => '',
            'transactionId' => '12345678',
            'email' => 'testUserActive@test.com',
            'phoneNumber' => '',
            'accountId' => '',
            'contactId' => '',
            'customerKey' => ''
        });

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri = '/services/apexrest/webServiceUtility/V1/SendOtpToVerify';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(jsonBody);

        try {
            Test.startTest();
            WebServiceUtility.doPost();
            Test.stopTest();
        } catch (OTPHandler.CustomException ce) {
            system.debug('Catch >> CustomException >>');
        }
    }
    /**
     * Test Process Type = Forgot Password : ContactId and EmailId missing
     */
    @isTest
    static void testForgotPasswordContactIdAndEmailIdMissing() {

        BrokerApplication__c brokerApplicationObj = [SELECT Id, Name, ApplicationNumber__c, AgencyEmail__c from BrokerApplication__c LIMIT 1];

        // Prepare JSON request body
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'processType' => 'Forgot Password',
            'commType' => 'Email;SMS;WhatsApp',
            'transactionId' => '12345678',
            'email' => '',
            'phoneNumber' => '',
            'accountId' => '',
            'contactId' => '',
            'customerKey' => ''
        });

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri = '/services/apexrest/webServiceUtility/V1/SendOtpToVerify';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(jsonBody);

        try {
            Test.startTest();
            WebServiceUtility.doPost();
            Test.stopTest();
        } catch (OTPHandler.CustomException ce) {
            system.debug('Catch >> CustomException >>');
        }
    }

    /**
     * Verify OTP - OTP Verified Successfully
     */
    @isTest
    static void testVerifyOTPSuccessfull() {

        //Create OTP - valid
        OTP__c testOTP = TestDataFactory.createOTP(2, 'Email', 'Registration', null, null, '2222', false, '12345678');
        testOTP.CommunicationType__c = 'SMS';
        insert testOTP;

        OTP__c insertedOTP = [SELECT Id, OTPCode__c, TransactionId__c from OTP__c where id=: testOTP.Id];

        // Prepare JSON request body
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'otpValue' => insertedOTP.OTPCode__c,
            'transactionId' => insertedOTP.TransactionId__c
        });

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri = '/services/apexrest/webServiceUtility/V1/VerifyOTP';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(jsonBody);

        Test.startTest();
        WebServiceUtility.doPost();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
    }

    /**
     * Verify OTP - Invalid OTP
     */
    @isTest
    static void testVerifyOTPInvalidOTP() {

        //Create OTP - valid
        OTP__c testOTP = TestDataFactory.createOTP(2, 'Email', 'Registration', null, null, '2222', false, '12345678');
        testOTP.CommunicationType__c = 'Email';
        insert testOTP;

        OTP__c insertedOTP = [SELECT Id, OTPCode__c, TransactionId__c from OTP__c where id=: testOTP.Id];

        // Prepare JSON request body
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'otpValue' => '3213',
            'transactionId' => insertedOTP.TransactionId__c
        });

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri = '/services/apexrest/webServiceUtility/V1/VerifyOTP';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(jsonBody);

        Test.startTest();
        WebServiceUtility.doPost();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }
    /**
     * Verify OTP - Expired OTP
     */
    @isTest
    static void testVerifyOTPExpiredOTP() {

        //Create OTP - valid
        OTP__c testOTP = TestDataFactory.createOTP(2, 'Email', 'Registration', null, null, '2222', false, '12345678');
        testOTP.OTPCodeExpiration__c = DateTime.now().addMinutes(-2);
        insert testOTP;

        OTP__c insertedOTP = [SELECT Id, OTPCode__c, TransactionId__c from OTP__c where id=: testOTP.Id];

        // Prepare JSON request body
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'otpValue' => '3213',
            'transactionId' => insertedOTP.TransactionId__c
        });

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri = '/services/apexrest/webServiceUtility/V1/VerifyOTP';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(jsonBody);

        Test.startTest();
        WebServiceUtility.doPost();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }

    /**
     * Verify OTP - Already verified OTP
     */
    @isTest
    static void testVerifyOTPAlreadyVerifiedOTP() {

        //Create OTP - valid
        OTP__c testOTP = TestDataFactory.createOTP(2, 'Email', 'Registration', null, null, '2222', true, '12345678');
        insert testOTP;

        OTP__c insertedOTP = [SELECT Id, OTPCode__c, TransactionId__c from OTP__c where id=: testOTP.Id];

        // Prepare JSON request body
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'otpValue' => testOTP.OTPCode__c,
            'transactionId' => insertedOTP.TransactionId__c
        });

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri = '/services/apexrest/webServiceUtility/V1/VerifyOTP';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(jsonBody);

        Test.startTest();
        WebServiceUtility.doPost();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }

    /**
     * Verify OTP - OTP Not Found
     */
    @isTest
    static void testVerifyOTPNotFound() {

        //Create OTP - valid
        OTP__c testOTP = TestDataFactory.createOTP(2, 'Email', 'Registration', null, null, '2222', true, '12345678');
        insert testOTP;

        OTP__c insertedOTP = [SELECT Id, OTPCode__c, TransactionId__c from OTP__c where id=: testOTP.Id];

        // Prepare JSON request body
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'otpValue' => testOTP.OTPCode__c,
            'transactionId' => '11111111'
        });

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri = '/services/apexrest/webServiceUtility/V1/VerifyOTP';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(jsonBody);

        Test.startTest();
        WebServiceUtility.doPost();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }
    /**
     * Verify OTP - Missing OTPvalue parameter in Request
     */
    @isTest
    static void testVerifyOTPMissingParameterOTPValue() {

        //Create OTP - valid
        OTP__c testOTP = TestDataFactory.createOTP(2, 'Email', 'Registration', null, null, '2222', true, '12345678');
        insert testOTP;

        OTP__c insertedOTP = [SELECT Id, OTPCode__c, TransactionId__c from OTP__c where id=: testOTP.Id];

        // Prepare JSON request body
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'otpValue' => '',
            'transactionId' => testOTP.TransactionId__c
        });

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri = '/services/apexrest/webServiceUtility/V1/VerifyOTP';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(jsonBody);

        try {
            Test.startTest();
            WebServiceUtility.doPost();
            Test.stopTest();
        } catch (OTPHandler.CustomException ce) {
            system.debug('Catch >> CustomException Verify OTP method >>');
        }
    }
    /**
     * Verify OTP - Missing Transaction Id parameter in Request
     */
    @isTest
    static void testVerifyOTPMissingParameterTransactionId() {

        //Create OTP - valid
        OTP__c testOTP = TestDataFactory.createOTP(2, 'Email', 'Registration', null, null, '2222', true, '12345678');
        insert testOTP;

        OTP__c insertedOTP = [SELECT Id, OTPCode__c, TransactionId__c from OTP__c where id=: testOTP.Id];

        // Prepare JSON request body
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'otpValue' => testOTP.OTPCode__c,
            'transactionId' => ''
        });

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri = '/services/apexrest/webServiceUtility/V1/VerifyOTP';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(jsonBody);

        try {
            Test.startTest();
            WebServiceUtility.doPost();
            Test.stopTest();
        } catch (OTPHandler.CustomException ce) {
            system.debug('Catch >> CustomException Verify OTP method >>');
        }
    }
    /**
     * Verify OTP - No/Null Request body
     */
    @isTest
    static void testVerifyOTPNullRequestBody() {

        //Create OTP - valid
        OTP__c testOTP = TestDataFactory.createOTP(2, 'Email', 'Registration', null, null, '2222', true, '12345678');
        insert testOTP;

        OTP__c insertedOTP = [SELECT Id, OTPCode__c, TransactionId__c from OTP__c where id=: testOTP.Id];

        // Prepare JSON request body
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'otpValue' => testOTP.OTPCode__c,
            'transactionId' => ''
        });

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestUri = '/services/apexrest/webServiceUtility/V1/VerifyOTP';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = null;

        
        Test.startTest();
        WebServiceUtility.doPost();
        Test.stopTest();

        System.assertEquals(500, RestContext.response.statusCode);
    }
    
    @isTest
    static void testdeleteOTP() {
        OTP__c testOTP = TestDataFactory.createOTP(2, 'Email', 'Registration', null, null, '2222', false, '12345678');
        testOTP.CommunicationType__c = 'Email';
        testOTP.ProcessType__c = 'Bloom App Registration';
        insert testOTP;
        List<OTP__c> insertedOTP = [SELECT Id, OTPCode__c, TransactionId__c from OTP__c];
        delete insertedOTP;
    }
    
    @isTest
    static void testdeleteOTP1() {
        OTP__c testOTP = TestDataFactory.createOTP(2, 'Email', 'Registration', null, null, '2222', false, '12345678');
        testOTP.CommunicationType__c = 'Email';
        testOTP.ProcessType__c = 'Bloom App Forgot Password';
        insert testOTP;
        List<OTP__c> insertedOTP = [SELECT Id, OTPCode__c, TransactionId__c from OTP__c];
        delete insertedOTP;
    }
    
    @isTest
    static void testOTPInstance() {
        OTP__c testOTP = TestDataFactory.createOTP(2, 'Email', 'Registration', null, null, '2222', false, '12345678');
        testOTP.CommunicationType__c = 'Email';
        testOTP.ProcessType__c = 'Bloom App Forgot Password';
        insert testOTP;
        OTPHandler objOTP = OTPHandler.getInstance();
        objOTP.generateSuperAppOTP('Bloom App Registration','test@gmail.com','9999999999','Email',testOTP.Id);
    }
}