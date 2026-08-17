@isTest
public class User_ServiceTest {

    @TestSetup
    static void setupData() {
        Account account = BCAPP_TestDataFactory.createAccount('Primary Account');
        insert account;

        Contact contact = BCAPP_TestDataFactory.createContact(account.Id, 'primary@example.com');
        insert contact;

        User__c activeUser = BCAPP_TestDataFactory.createUser('Azure-Primary-1');
        activeUser.Account__c = account.Id;
        activeUser.User_Account__c = account.Id;
        activeUser.Email__c = 'primary-user@example.com';
        activeUser.Contact__c = contact.Id;
        insert activeUser;

        User__c secondaryUser = BCAPP_TestDataFactory.createUser('Azure-Primary-2');
        secondaryUser.Account__c = account.Id;
        secondaryUser.User_Account__c = account.Id;
        secondaryUser.Email__c = 'secondary-user@example.com';
        secondaryUser.Contact__c = contact.Id;
        insert secondaryUser;
    }

    @isTest
    static void testQueryHelpers() {
        Account account = [SELECT Id FROM Account WHERE Name = 'Primary Account' LIMIT 1];
        Contact contact = [SELECT Id FROM Contact WHERE AccountId = :account.Id LIMIT 1];
        User_Service service = User_Service.getInstance();

        Test.startTest();
        List<User__c> azureUsers = service.getUsersByAzure(account.Id);
        List<User__c> emailUsers = service.getUsersByEmail('primary-user@example.com');
        List<User__c> accountUsers = service.getUsersByAccountId(new Set<Id>{account.Id});
        List<User__c> contactUsers = service.getUsersByContactIds(new Set<Id>{contact.Id});
        Test.stopTest();

        System.assertEquals(2, azureUsers.size(), 'Expected both users to be returned for the account.');
        System.assertEquals(1, emailUsers.size(), 'Email filter should return a single user.');
        System.assertEquals(2, accountUsers.size(), 'Account filter should return both users.');
        System.assertEquals(2, contactUsers.size(), 'Contact filter should return both users attached to the contact.');
    }

    @isTest
    static void testCreateAndUpdateUser() {
        Account account = [SELECT Id FROM Account WHERE Name = 'Primary Account' LIMIT 1];
        Contact contact = [SELECT Id FROM Contact WHERE AccountId = :account.Id LIMIT 1];
        User_Service service = User_Service.getInstance();

        User__c transientUser = BCAPP_TestDataFactory.createUser('Azure-New-User');
        transientUser.Account__c = account.Id;
        transientUser.User_Account__c = account.Id;
        transientUser.Email__c = 'new-user@example.com';
        transientUser.Contact__c = contact.Id;

        Test.startTest();
        service.createUser(transientUser);
        transientUser.Mobile_Number__c = '971500000000';
        service.updateUser(transientUser);
        Test.stopTest();

        User__c persisted = [SELECT Mobile_Number__c FROM User__c WHERE Id = :transientUser.Id];
        System.assertEquals('971500000000', persisted.Mobile_Number__c, 'Mobile number should be updated through the service.');
    }
}