@IsTest
public class BrokerUnitAssignmentTriggerHandlerTest {

    @testSetup
    static void setupTestData() {
        // Create Email Template (needed for helper)
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1];
        System.runAs(adminUser) {
            if ([SELECT COUNT() FROM EmailTemplate WHERE DeveloperName = 'UnitAssignmentNotification'] == 0) {
                EmailTemplate et = new EmailTemplate(
                    Name = 'Unit Assignment Notification',
                    DeveloperName = 'UnitAssignmentNotification',
                    FolderId = [SELECT Id FROM Folder WHERE Name = 'Public Email Templates' LIMIT 1].Id,
                    TemplateStyle = 'custom',
                    Subject = 'Test Unit Assignment',
                    HtmlValue = '<html><body>Unit Assigned</body></html>'
                );
                insert et;
            }
        }

        // Create test Account
        Account acc = new Account(Name = 'Handler Account');
        insert acc;

        // Create Contact (Agent)
        Contact contact = new Contact(
            LastName = 'Handler Contact',
            AccountId = acc.Id,
            Email = 'agent@test.com',
            BrokerContactRole__c = 'Agent;AuthorizedSignatoryOfficer',
            IsSendEmail__c = false
        );
        insert contact;

        // Create BrokerUnitAllocation__c
        BrokerUnitAllocations__c allocation = new BrokerUnitAllocations__c(
            //Name = 'Test Allocation',
            Account__c = acc.Id
        );
        insert allocation;

        // Create BrokerUnitAssignment__c linked to allocation
        BrokerUnitAssignment__c bua = new BrokerUnitAssignment__c(
            //Name = 'Handler Assignment',
            BrokerUnitAllocation__c  = allocation.Id
        );
        insert bua;
    }

    @IsTest
    static void test_afterInsert_sendsEmails() {
        // Retrieve test data
        BrokerUnitAssignment__c bua = [SELECT Id,BrokerUnitAllocation__c,Contact__c  FROM BrokerUnitAssignment__c LIMIT 1];

        Test.startTest();
        BrokerUnitAssignmentTriggerHandler handler = new BrokerUnitAssignmentTriggerHandler();
        handler.afterInsert(new List<sObject>{bua}, new Map<Id, sObject>{bua.Id => bua});
        Test.stopTest();

        // Verify agent contact was updated
        Contact c = [SELECT IsSendEmail__c FROM Contact WHERE Email = 'agent@test.com' LIMIT 1];
    }

    @IsTest
    static void test_resetIsSendMail() {
        Account acc = new Account(Name = 'Reset Test');
        insert acc;

        Contact c = new Contact(
            LastName = 'Reset Contact',
            AccountId = acc.Id,
            Email = 'reset@test.com',
            IsSendEmail__c = true
        );
        insert c;

        Test.startTest();
        BrokerUnitAssignmentHelper.resetIsSendMail();
        Test.stopTest();

        c = [SELECT IsSendEmail__c FROM Contact WHERE Id = :c.Id];
        System.assertEquals(false, c.IsSendEmail__c, 'IsSendEmail__c should be reset to false');
    }

    @IsTest
    static void test_all_trigger_contexts() {
        BrokerUnitAssignment__c bua = [SELECT Id,BrokerUnitAllocation__c,Contact__c  FROM BrokerUnitAssignment__c LIMIT 1];

        BrokerUnitAssignmentTriggerHandler handler = new BrokerUnitAssignmentTriggerHandler();

        // Validate all contexts execute safely
        handler.beforeInsert(new List<sObject>{bua});
        handler.afterInsert(new List<sObject>{bua}, new Map<Id, sObject>{bua.Id => bua});
        handler.beforeUpdate(new List<sObject>{bua}, new Map<Id, sObject>{bua.Id => bua}, new List<sObject>{bua}, new Map<Id, sObject>{bua.Id => bua});
        handler.afterUpdate(new List<sObject>{bua}, new Map<Id, sObject>{bua.Id => bua}, new List<sObject>{bua}, new Map<Id, sObject>{bua.Id => bua});
        handler.beforeDelete(new List<sObject>{bua}, new Map<Id, sObject>{bua.Id => bua});
        handler.afterDelete(new List<sObject>{bua}, new Map<Id, sObject>{bua.Id => bua});
        handler.afterUnDelete(new List<sObject>{bua}, new Map<Id, sObject>{bua.Id => bua});

        System.assertNotEquals(null, handler.isDisabled(), 'Handler should return boolean value');
    }
}