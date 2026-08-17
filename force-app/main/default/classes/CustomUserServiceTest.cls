@isTest
private class CustomUserServiceTest {
    
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
        
        // Create Custom User
        User__c testUser = TestDataFactory.createCustomUser(true, true,'TestUser123@email.com', 'TestUser', testContact.Id, testAccount.Id, 'testUser@test.com', 'a4ed45a7-b964-4ed0-b2aa-111111111111');
        insert testUser;
        System.debug('testUser >> '+testUser);
    }
    
    /**
* Test getUserByEmail method of the class CustomUserService
*/
    @isTest
    static void testGetUserByEmail() {
        
        //Get Broker Account
        Account testAccount = [SELECT Id from Account where Name = 'Test'];
        
        //Get Contact
        Contact testContact = [SELECT Id from Contact Where LastName = 'TestContact'];
        
        Test.startTest();
        CustomUserService objCustomUserService = CustomUserService.getInstance();
        User__c result = objCustomUserService.getUserByEmail('testUser@test.com');
        Test.stopTest();
        
        System.assertEquals(testAccount.Id, result.Account__c, 'Should return one record for valid email id');
    }
    
    /**
* Test getUserByContactIdOrEmail method of the class CustomUserService passing emailId as parameter
*/
    @isTest
    static void testGetUserByContactIdOrEmailTestEmail() {
        
        //Get Broker Account
        Account testAccount = [SELECT Id from Account where Name = 'Test'];
        
        //Get Contact
        Contact testContact = [SELECT Id from Contact Where LastName = 'TestContact'];
        
        //Get User
        User__c testUser = [SELECT Id, Email__c from User__c where Name='TestUser'];
        
        Test.startTest();
        CustomUserService objCustomUserService = CustomUserService.getInstance();
        User__c result = objCustomUserService.getUserByContactIdOrEmail('','testUser@test.com');
        Test.stopTest();
        
        System.assertEquals(testUser.Email__c, result.Email__c, 'Should return one record for valid email id');
    }
    
    /**
* Test getUserByContactIdOrEmail method of the class CustomUserService passing contactId as parameter
*/
    @isTest
    static void testGetUserByContactIdOrEmailTestContactId() {
        
        //Get Broker Account
        Account testAccount = [SELECT Id from Account where Name = 'Test'];
        
        //Get Contact
        Contact testContact = [SELECT Id from Contact Where LastName = 'TestContact'];
        
        //Get User
        User__c testUser = [SELECT Id, Contact__c from User__c where Name='TestUser'];
        
        Test.startTest();
        CustomUserService objCustomUserService = CustomUserService.getInstance();
        User__c result = objCustomUserService.getUserByContactIdOrEmail(testContact.Id, '');
        Test.stopTest();
        
        System.assertEquals(testUser.Contact__c, result.Contact__c, 'Should return one record for valid contact id');
    }
    
    /**
* Test getUserByContactIdOrEmail method of the class CustomUserService passing contactId and emailId both
*/
    @isTest
    static void testGetUserByContactIdOrEmailTestBoth() {
        
        //Get Broker Account
        Account testAccount = [SELECT Id from Account where Name = 'Test'];
        
        //Get Contact
        Contact testContact = [SELECT Id from Contact Where LastName = 'TestContact'];
        
        //Get User
        User__c testUser = [SELECT Id, Contact__c, Email__c from User__c where Name='TestUser'];
        
        Test.startTest();
        CustomUserService objCustomUserService = CustomUserService.getInstance();
        User__c result = objCustomUserService.getUserByContactIdOrEmail(testContact.Id, 'testUser@test.com');
        Test.stopTest();
        
        System.assertEquals(testUser.Contact__c, result.Contact__c, 'Should return one record for valid contact id');
        System.assertEquals(testUser.Email__c, result.Email__c, 'Should return one record for valid email id');
    }
    
    /**
* Test getUserByAzureToken method of the class CustomUserService passing Azure token as parameter
*/
    @isTest
    static void testGetUserByAzureToken() {
        
        //Get Broker Account
        Account testAccount = [SELECT Id from Account where Name = 'Test'];
        
        //Get Contact
        Contact testContact = [SELECT Id from Contact Where LastName = 'TestContact'];
        
        //Get User
        User__c testUser = [SELECT Id, Email__c, Contact__c from User__c where Name='TestUser'];
        
        Test.startTest();
        User__c result = CustomUserService.getInstance().getUserByAzureToken('a4ed45a7-b964-4ed0-b2aa-111111111111');
        Test.stopTest();
        
        System.assertEquals(testUser.Contact__c, result.Contact__c, 'Should return one record for valid Azure token');
    }
    @isTest static void testGetUsersByContactIds() {
        Contact c = [SELECT Id FROM Contact WHERE LastName = 'TestContact' LIMIT 1];
        List<User__c> users = CustomUserService.getInstance().getUsersByContactIds(new Set<Id>{c.Id});
        System.assertNotEquals(0, users.size(), 'Should return users for given contact Ids');
        System.assertEquals(c.Id, users[0].Contact__c);
    }
    @isTest static void testUpdateUsers() {
        User__c user = [SELECT Id, Email__c FROM User__c WHERE Email__c = 'testUser@test.com' LIMIT 1];
        user.Email__c = 'updatedemail@test.com';
        
        List<User__c> updatedList = CustomUserService.getInstance().updateUsers(new List<User__c>{user});
        System.assertEquals(1, updatedList.size());
        System.assertEquals('updatedemail@test.com', updatedList[0].Email__c);
        
        // Query again to confirm update
        User__c updatedUser = [SELECT Email__c FROM User__c WHERE Id = :user.Id];
        System.assertEquals('updatedemail@test.com', updatedUser.Email__c);
    }
    @isTest static void testUpdateUsersWithoutTrigger() {
        User__c user = [SELECT Id, Email__c FROM User__c WHERE Email__c = 'testUser@test.com' LIMIT 1];
        user.Email__c = 'withouttrigger@test.com';
        
        List<User__c> updatedList = CustomUserService.getInstance().updateUsersWithoutTrigger(new List<User__c>{user});
        System.assertEquals(1, updatedList.size());
        System.assertEquals('withouttrigger@test.com', updatedList[0].Email__c);
        
        // Confirm the flag is reset
        System.assertEquals(false, AzureUserTriggerHandler.isTriggerDisabled);
    }
    
    @isTest
    static void testGetUsersByIds() {
        User__c testUser = [SELECT Id FROM User__c WHERE Name = 'TestUser' LIMIT 1];
        Set<Id> userIds = new Set<Id>{testUser.Id};
            Test.startTest();
        Map<Id, User__c> resultMap = CustomUserService.getInstance().getUsersByIds(userIds);
        Test.stopTest();
    }
    
    @isTest
    static void testGetUsersByIdsNull() {
        User__c testUser = [SELECT Id FROM User__c WHERE Name = 'TestUser' LIMIT 1];
        Set<Id> userIds = new Set<Id>{testUser.Id};
            Test.startTest();
        Map<Id, User__c> resultMap = CustomUserService.getInstance().getUsersByIds(null);
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateUser() {
        User__c testUser = [SELECT Id, Email__c FROM User__c WHERE Name = 'TestUser' LIMIT 1];
        testUser.Email__c = 'singleupdate@test.com';
        Test.startTest();
        CustomUserService.getInstance().updateUser(testUser);
        Test.stopTest();
    }
    
    @isTest
    static void testInsertContacts() {
        Account acc = new Account(Name = 'Test');
        insert acc;
        
        //Contact con = new Contact(LastName = 'TestContact', AccountId = acc.Id);
        // insert con;
        
        User__c newUser = new User__c(
            Username__c = 'inserted1@test.com',
            Name = 'InsertedUser',
            Email__c = 'inserted1@test.com',
            //Contact__c = con.Id,
            User_Account__c = acc.Id
        );
        
        Test.startTest();
        AzureUserTriggerHandler.isTriggerDisabled = true;
        CustomUserService.getInstance().insertContacts(new List<User__c>{newUser});
        AzureUserTriggerHandler.isTriggerDisabled = false;
        Test.stopTest();
    }
    @isTest
    static void testGetAppRegistrationUser() {
        
        // Get Account
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test' LIMIT 1];
        
        // Get Contact
        Contact testContact = [SELECT Id FROM Contact WHERE LastName = 'TestContact' LIMIT 1];
        
        // Create App Registration
        AppRegistration__c appReg = new AppRegistration__c(
            FirstName__c = 'John',
            LastName__c = 'Doe',
            Email__c = 'john.doe@test.com',
            Contact__c = testContact.Id,
            Account__c = testAccount.Id
        );
        
        Test.startTest();
        CustomUserService objCustomUserService = CustomUserService.getInstance();
        User__c result = objCustomUserService.getAppRegistrationUser(appReg);
        Test.stopTest();
        
        System.assertEquals('John Doe', result.Name);
        System.assertEquals('John Doe', result.Name__c);
        System.assertEquals('john.doe@test.com', result.Username__c);
    }
    
}