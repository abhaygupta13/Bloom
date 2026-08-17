@isTest
private class OTPServiceTest {
    @testSetup static void setup() {
        //Create Broker Account
        Account testAccount = TestDataFactory.createBrokerAccount('Test', false, '1111111111');
        insert testAccount;

        //Create Contact
        Contact testContact = TestDataFactory.createContact('TestContact', testAccount.Id, true, 'test@gmail.com');
        testContact.Blacklisted__c=false;
        testContact.IsSuspended__c=false;
        testContact.SuspensionTenure__c='';
        insert testContact;

    }

    /**
     * Test generateOTP method of the class OTPService
     */
    @isTest
    static void testGenerateOTP() {
        
        Test.startTest();
        OTPService objOTPService = OTPService.getInstance();
        String result = objOTPService.generateOTP(4);
        Test.stopTest();

        System.assertEquals(result.length(), 4, 'Should return 4 digit OTP');
    }

    /**
     * Test generateOTP method of the class OTPService when length is passed as null
     */
    @isTest
    static void testGenerateOTPDefaultLength() {
        
        Test.startTest();
        OTPService objOTPService = OTPService.getInstance();
        String result = objOTPService.generateOTP(null);
        Test.stopTest();

        System.assertEquals(result.length(), 6, 'Should return 6 digit OTP');
    }

    /**
     * Test createOTPRecord method of the class OTPService, no exception
     */
    @isTest
    static void testCreateOTPNoException() {

        //Get Broker Account
        Account testAccount = [SELECT Id from Account where Name = 'Test'];
        
        //Get Contact
        Contact testContact = [SELECT Id from Contact Where LastName = 'TestContact'];

        //Create OTP
        OTP__c testOTP = TestDataFactory.createOTP(2, 'Email', 'Registration', testAccount.Id, testContact.Id, '2222', false, '12345678');
        

        Test.startTest();
        OTPService objOTPService = OTPService.getInstance();
        OTP__c insertedOTP = objOTPService.createOTPRecord(testOTP);
        Id otpId = insertedOTP.Id;
        Test.stopTest();

        System.assertNotEquals(null, otpId, 'Should return OTP Id');
    }

    /**
     * Test createOTPRecord method of the class OTPService with Exception scenario
     */
    @isTest
    static void testCreateOTPWithException() {

        Boolean exceptionScenario = false;

        try {
            Test.startTest();
            OTPService objOTPService = OTPService.getInstance();
            OTP__c insertedOTP = objOTPService.createOTPRecord(null); 
            String otpId = insertedOTP.Id;
            Test.stopTest();
        } catch (Exception e) {
            exceptionScenario = true;
        }
        System.assertEquals(true, exceptionScenario , 'Boolean Exception Scenario should be set to true');
    }

    /**
     * Test updateOTP method of the class OTPService, no exception
     */
    @isTest
    static void testUpdateOTPNoException() {

        //Get Broker Account
        Account testAccount = [SELECT Id from Account where Name = 'Test'];
        
        //Get Contact
        Contact testContact = [SELECT Id from Contact Where LastName = 'TestContact'];

        //Create OTP
        OTP__c testOTP = TestDataFactory.createOTP(2, 'Email', 'Registration', testAccount.Id, testContact.Id, '2222', false, '12345678');
        insert testOTP;
        testOTP.Verified__c = true;

        Test.startTest();
        OTPService objOTPService = OTPService.getInstance();
        OTP__c updatedOTP = objOTPService.updateOTP(testOTP); 
        Id otpId = updatedOTP.Id;
        Test.stopTest();

        OTP__c checkOTP = [SELECT Id, Verified__c FROM OTP__c WHERE Id =: otpId];

        System.assertEquals(true, checkOTP.Verified__c, 'Field Verified__c should be update to true');
    }

    /**
     * Test updateOTP method of the class OTPService with Exception scenario
     */
    @isTest
    static void testUpdateOTPWithException() {

        Boolean exceptionScenario = false;

        try {
            Test.startTest();
            OTPService objOTPService = OTPService.getInstance();
            OTP__c updatedOTP = objOTPService.updateOTP(null); 
            Id otpId = updatedOTP.Id;
            Test.stopTest();
        } catch(Exception e) {
            exceptionScenario = true;
        }

        System.assertEquals(true, exceptionScenario, 'Boolean exceptionScenario should be set to true');
    }

    /**
     * Test getOTPRecords method of the class OTPService with not exception
     */
    @isTest
    static void testGetOTPRecordsNoException() {

        Boolean exceptionScenario = false;

        //Get Broker Account
        Account testAccount = [SELECT Id from Account where Name = 'Test'];
        
        //Get Contact
        Contact testContact = [SELECT Id from Contact Where LastName = 'TestContact'];

        //Create OTP
        OTP__c testOTP = TestDataFactory.createOTP(2, 'Email', 'Registration', testAccount.Id, testContact.Id, '2222', false, '12345678');
        insert testOTP;

        List<OTP__c> listOTPRecords;
        try {
            Test.startTest();
            OTPService objOTPService = OTPService.getInstance();
            listOTPRecords = objOTPService.getOTPRecords(testOTP.TransactionId__c);
            Test.stopTest();
        } catch (Exception e) {
            exceptionScenario = true;
        }
        

        for(OTP__c objOtp : listOTPRecords){
            System.assertEquals(objOtp.OTPCode__c, '2222', 'OTP code should be same');
        }
        
    }

    /**
     * Test getOTPRecords method of the class OTPService with exception
     */
    @isTest
    static void testGetOTPRecordsWithException() {

        Boolean exceptionScenario = false;

        //Get Broker Account
        Account testAccount = [SELECT Id from Account where Name = 'Test'];
        
        //Get Contact
        Contact testContact = [SELECT Id from Contact Where LastName = 'TestContact'];

        //Create OTP
        OTP__c testOTP = TestDataFactory.createOTP(2, 'Email', 'Registration', testAccount.Id, testContact.Id, '2222', false, '12345678');
        insert testOTP;

        List<OTP__c> listOTPRecords;
        try {
            Test.startTest();
            OTPService objOTPService = OTPService.getInstance();
            listOTPRecords = objOTPService.getOTPRecords('');
            Test.stopTest();
        } catch (Exception e) {
            exceptionScenario = true;
        }

        System.assertEquals(true, exceptionScenario, 'Exception boolean should be set to true');
        
    }
}