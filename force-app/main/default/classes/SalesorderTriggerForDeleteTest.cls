@isTest
public class SalesorderTriggerForDeleteTest {

    @isTest
    static void testSystemAdminDelete() {
        // Create a system admin user
        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User adminUser = new User(
            ProfileId = sysAdminProfile.Id,
            Username = 'tsadgadgsassd@example.com',
            Email = 'testadmin@example.com',
            Alias = 'testad',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Admin',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            IsActive = true
        );
        insert adminUser;

        // Set the running user to the system admin user
        System.runAs(adminUser) {
            // Create test account
            Account testAccount = new Account(Name = 'Test Account');
            insert testAccount;
            // Create test SalesOrder
            SalesOrder__c  testSalesOrder = new SalesOrder__c(Name = 'Test Salesorder', Account__c=testAccount.Id);
            insert testSalesOrder;

            // Attempt to delete the salesorder
            Test.startTest();
            delete testSalesOrder;
            Test.stopTest();

            // Verify that the salesorder is deleted
            System.assertEquals(0, [SELECT COUNT() FROM SalesOrder__c WHERE Id = :testSalesOrder.Id]);
        }
    }


}