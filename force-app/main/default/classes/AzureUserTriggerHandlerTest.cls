@isTest
private class AzureUserTriggerHandlerTest {

    @isTest
    static void testAllTriggerEvents() {
        // Arrange
        User__c testUser = new User__c(
            Name = 'Trigger Test User',
            Email__c = 'trigger@test.com',
            Azure_UserId__c = 'trigger-123',
            User_Type__c = 'Broker Agent',
            Username__c = 'trigger@test.com'
        );
        insert testUser;

        // Update to cover beforeUpdate and afterUpdate
        testUser.Name = 'Trigger Test User Updated';
        update testUser;

        // Delete to cover beforeDelete and afterDelete
        delete testUser;

        // Undelete to cover afterUndelete
        undelete testUser;
    }
}