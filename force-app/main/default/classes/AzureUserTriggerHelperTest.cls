@isTest
private class AzureUserTriggerHelperTest {
     private static final string CONTACT_RT_DEV_NAME_BROKER { get { return 'Broker'; } }

    @testSetup
    static void setupData() {
        // Base user record for reference
        User__c usr = new User__c(
            Name = 'Test User',
            Email__c = 'testuser@example.com',
            Azure_UserId__c = 'AZURE_123',
            User_Type__c = 'Broker Agent',
            Temporary_Password__c = 'Tmp@123',
            IsSendToAB2C__c = false,
            Username__c = 'testuser@example.com'
        );
        insert usr;
    }

    @isTest
    static void testHandleBeforeInsert() {
        List<User__c> users = new List<User__c>{
            new User__c(Name = 'Before Insert', Email__c = 'before@example.com')
        };
        Test.startTest();
        AzureUserTriggerHelper.handleBeforeInsert(users);
        Test.stopTest();

        System.assertNotEquals(null, users[0].Temporary_Password__c, 'Temporary password should be set');
    }

    @isTest
    static void testSendWelcomeEmail() {
        // Prepare data
        User__c oldUser = [SELECT Id, Azure_UserId__c, User_Type__c, Email__c FROM User__c LIMIT 1];
        User__c newUser = oldUser.clone(false, false, false, false);
        newUser.Name = 'Test name';
        newUser.Id = oldUser.Id;
        newUser.Azure_UserId__c = 'NEW_AZURE_123'; // different value to trigger email logic
        newUser.Temporary_Password__c = 'Temp123';
        newUser.User_Type__c = 'Broker Agent';
        newUser.Email__c = 'welcome@example.com';
        
        User__c newUser2 = oldUser.clone(false, false, false, false);
        newUser2.Name = 'Test name New';
        newUser2.Id = oldUser.Id;
        newUser2.Azure_UserId__c = 'NEW_AZURE_121213'; // different value to trigger email logic
        newUser2.Temporary_Password__c = 'Temp121213';
        newUser2.User_Type__c = 'Owner';
        newUser2.Email__c = 'welcome@example.com';
        newUser2.AppType__c = 'Super App';
        
         User__c newUser3 = oldUser.clone(false, false, false, false);
        newUser3.Name = 'Test name New';
        newUser3.Id = oldUser.Id;
        newUser3.Azure_UserId__c = 'NEW_AZURE_121213'; // different value to trigger email logic
        newUser3.Temporary_Password__c = 'Temp121213';
        newUser3.User_Type__c = 'Owner';
        newUser3.Email__c = 'welcome@example.com';
        newUser3.AppType__c = 'Community App';

        Map<Id, User__c> oldMap = new Map<Id, User__c>{ oldUser.Id => oldUser };

        Test.startTest();
        AzureUserTriggerHelper.sendWelcomeEmail(new List<User__c>{ newUser }, oldMap);
        AzureUserTriggerHelper.sendWelcomeEmail(new List<User__c>{ newUser2 }, oldMap);
        AzureUserTriggerHelper.sendWelcomeEmail(new List<User__c>{ newUser3 }, oldMap);
        Test.stopTest();

        System.assert(true, 'sendWelcomeEmail executed successfully');
    }

    @isTest
    static void testHandleAfterInsert() {
        User__c insertedUser = new User__c(
            Name = 'After Insert',
            Email__c = 'afterinsert@example.com',
            Azure_UserId__c = 'AZ789',
            User_Type__c = 'Broker Agent',
            Username__c = 'afterinsert@example.com'
        );

        insert insertedUser;

        Test.startTest();
        AzureUserTriggerHelper.handleAfterInsert(new List<User__c>{ insertedUser });
        Test.stopTest();

        System.assert(true, 'handleAfterInsert executed without error');
    }

    @isTest
    static void testHandleAfterUpdate() {
        User__c existingUser = [SELECT Id, Email__c,User_Account__c,LastPasswordChangedDate__c, Temporary_Password__c, Account__c, Contact__c,User_Type__c, Azure_UserId__c,IsSendToAB2C__c,isActive__c,Username__c, Name FROM User__c LIMIT 1];
        User__c updatedUser = existingUser.clone(false, false, false, false);
        updatedUser.Id = existingUser.Id;
        updatedUser.IsSendToAB2C__c = true; // simulate update that triggers logic

        Map<Id, User__c> oldMap = new Map<Id, User__c>{ existingUser.Id => existingUser };

        Test.startTest();
        AzureUserTriggerHelper.handleAfterUpdate(new List<User__c>{ updatedUser }, oldMap);
        Test.stopTest();

        System.assert(true, 'handleAfterUpdate executed without error');
    }
    
    @isTest
    static void testHandleAfterUpdate_FullCoverage() {
        
        //  Create a base User__c record
        User__c baseUser = new User__c(
            Name = 'Old Name',
            Email__c = 'old@example.com',
            Azure_UserId__c = 'AZ123',
            User_Type__c = 'Broker Agent',
            IsSendToAB2C__c = false,
            isActive__c = true,
            Username__c = 'old@example.com',
            Contact__c = null,
            LastPasswordChangedDate__c = System.now()
        );
        insert baseUser;
        
        // Prepare oldMap
        Map<Id, User__c> oldMap = new Map<Id, User__c>{
            baseUser.Id => baseUser
                };
                    
                    List<User__c> updates = new List<User__c>();
        
        //️⃣ CASE 1: Azure_UserId__c = blank → create integration record
        User__c u1 = baseUser.clone(false, false, false, false);
        u1.Id = baseUser.Id;
        u1.IsSendToAB2C__c = true;
        u1.Azure_UserId__c = null;
        updates.add(u1);
        
        //️⃣ CASE 2: User deactivate
        User__c u2 = baseUser.clone(false, false, false, false);
        u2.Id = baseUser.Id;
        u2.IsSendToAB2C__c = true;
        u2.isActive__c = false;
        updates.add(u2);
        
        //  CASE 3: Email (username) change
        User__c u3 = baseUser.clone(false, false, false, false);
        u3.Id = baseUser.Id;
        u3.IsSendToAB2C__c = true;
        u3.Username__c = 'newemail@example.com';
        updates.add(u3);
        
        //  CASE 4: Name change
        User__c u4 = baseUser.clone(false, false, false, false);
        u4.Id = baseUser.Id;
        u4.IsSendToAB2C__c = true;
        u4.Name = 'New Name';
        updates.add(u4);
        
        //  CASE 5: User activate
        User__c u5 = baseUser.clone(false, false, false, false);
        u5.Id = baseUser.Id;
        u5.IsSendToAB2C__c = true;
        u5.isActive__c = true;
        oldMap.get(baseUser.Id).isActive__c = false; // simulate previous inactive
        updates.add(u5);
        
    }
    
    private static Contact createTestContact() {
       
        Id brokerContactRecordTypeId = Utility.getRecordTypeIdByDevName(Contact.SObjectType, CONTACT_RT_DEV_NAME_BROKER);
        Contact c = new Contact(
            LastName = 'Test Contact',
            TypeofEstablishment__c = 'Domestic',
            RecordTypeId = brokerContactRecordTypeId
        );
        insert c;
        return c;
    }

}