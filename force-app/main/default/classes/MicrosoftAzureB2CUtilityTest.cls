@IsTest
public class MicrosoftAzureB2CUtilityTest {
    
    private class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"access_token":"mock_access_token"}');
            response.setStatusCode(200);
            return response;
        }
    }
    
    @TestSetup
    static void setupTestData() {
        
        Account accountRecord =BCAPP_TestDataFactory.createAccount('Test Account');
        accountRecord.Azure_UserPrincipal_Id__c='testttt';
        insert accountRecord;
        
        Contact cntRecord= BCAPP_TestDataFactory.createContact(accountRecord.id,'ewew@dasds.com');
        insert cntRecord;
        
        Case testCase =BCAPP_TestDataFactory.createCase();
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Move In Holiday Homes').getRecordTypeId();
        testCase.RecordTypeId=RecordTypeCaseId;
        testCase.AccountId= accountRecord.id;
        testCase.Move_Out_Date__c=system.today();
        testCase.Email_Address__c='testuser@fff.com';
        insert testCase;
        
        User__c userRecord= BCAPP_TestDataFactory.createUser('testttt');
        userRecord.Email__c=testCase.Email_Address__c;
        userRecord.Account__c=accountRecord.id;
        
        userRecord.User_Account__c=accountRecord.id;
        
        insert userRecord;
    }
    
    @IsTest
    static void testGetAccessToken() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        test.starttest();
        
        MicrosoftAzureB2CUtility.TokenResponse tokenResponse = MicrosoftAzureB2CUtility.getAccessToken();
        test.stoptest();
        
    }
    
    @IsTest
    static void testGetAccessToken2() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        test.starttest();
        MicrosoftAzureB2CUtility.TokenResponse tokenResponse = MicrosoftAzureB2CUtility.getAccessTokenv2();
        test.stoptest();
        
    }
    
    
    
    @IsTest
    static void testCreateUser() {
        Test.startTest();
        
        User__c testUser = [SELECT Id,User_Type__c, Email__c,Account__c,Temporary_Password__c  FROM User__c LIMIT 1];
        MicrosoftAzureB2CUtility.createUser(testUser);
        
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateUserName() {
        Test.startTest();
        
        User__c testUser = [SELECT Id,User_Type__c,Email__c,Temporary_Password__c FROM User__c LIMIT 1];
        MicrosoftAzureB2CUtility.updateUserName(testUser);
        
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateUserEmail() {
        Test.startTest();
        
        User__c testUser = [SELECT Id,User_Type__c,Email__c,Temporary_Password__c FROM User__c LIMIT 1];
        MicrosoftAzureB2CUtility.updateUser(testUser);
        
        Test.stopTest();
        
    }
    
    @IsTest
    static void testDeactivateUser() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        
        Test.startTest();
        
        HttpResponse response = MicrosoftAzureB2CUtility.deactivateUser(null, 'mock_principal_id');
        
        Test.stopTest();
    }
}