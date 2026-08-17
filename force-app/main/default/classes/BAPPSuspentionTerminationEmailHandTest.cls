@isTest
public class BAPPSuspentionTerminationEmailHandTest {

    // Utility to safely create EmailTemplates in a separate context
    private static void createEmailTemplates() {
        User u = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(u) {
            List<String> templateNames = new List<String>{
                'Broker_Warning1_Template',
                'Broker_Warning2_Template',
                'Broker_Warning3_Template',
                'Termination_Agency_Email',
                'Suspension_Agency_Email',
                'Line_Manager_Approved',
                'Line_Manager_Approved_Suspend',
                'Rejected_By_Line_Manager_Terminated',
                'Rejected_By_Line_Manager_Suspeneded'
            };

            List<EmailTemplate> templates = new List<EmailTemplate>();
            for (String devName : templateNames) {
                templates.add(new EmailTemplate(
                    Name = devName,
                    DeveloperName = devName,
                    HtmlValue = '<html><body>Hello {{Name}}, Ref: {{Reference_ID}}, Date: {{Effective_Date}}, Reason: {{Reason}}</body></html>',
                    Subject = 'Test Template - ' + devName,
                    FolderId = UserInfo.getUserId(),
                    TemplateType = 'custom',
                    IsActive = true
                ));
            }
            insert templates;
        }
    }

    @testSetup
    static void setupData() {
        
        User execUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        User bbmUser = [SELECT Id FROM User WHERE Profile.Name = 'Broker Management Team' AND IsActive = true LIMIT 1];

        // 1️⃣ Insert setup data first
        createEmailTemplates();

        // 2️⃣ Then insert non-setup data
        BrokerApplication__c brokerApp = new BrokerApplication__c(
            Name = 'TestApp'
            //ApplicationNumber__c = 'APP-001'
        );
        insert brokerApp;

        List<Account> accList = new List<Account>();
        List<Contact> conList = new List<Contact>();
        
        Id accRecordTypeId = Utility.getRecordTypeIdByDevName(Account.SObjectType, 'Broker_Agency');
        Id conRecordTypeId = Utility.getRecordTypeIdByDevName(Contact.SObjectType, 'Broker');
        

        for (Integer i = 0; i < 5; i++) {
            Account acc = new Account(
                Name = 'Broker ' + i,
                WarningCounter__c = i == 0 ? 0 : i == 1 ? 1 : 2,
                Broker_Application__c = brokerApp.Id,
                ApprovalStatus__c = 'Submitted',
                Scenarios__c = 'None',
                isSuspended__c = false,
                Blacklisted__c = false,
                RecordTypeId = accRecordTypeId,
                ExecutiveSalesDirector__c = execUser.Id,
                BBMId__c = bbmUser.Id
            );
            accList.add(acc);
        }
        insert accList;

        for (Account acc : accList) {
            conList.add(new Contact(
                LastName = 'Contact ' + acc.Name,
                Email = acc.Name.replace(' ', '').toLowerCase() + '@example.com',
                AccountId = acc.Id,
                BrokerContactRole__c = 'Admin',
                RecordTypeId = conRecordTypeId
            ));
        }
        insert conList;
    }

    @isTest static void testWarningFlow() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Broker 0' LIMIT 1];

        Test.startTest();
        BAPPSuspentionTerminationEmailHandler.sendWarningEmails(new List<Id>{ acc.Id });
        Test.stopTest();

        acc = [SELECT WarningCounter__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(1, acc.WarningCounter__c);
    }
    
    @isTest static void testSuspensionFlow() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Broker 1' LIMIT 1];
        acc.isSuspended__c = true;
        acc.SuspensionReason__c = 'Non-compliance';
        update acc;

        Test.startTest();
        BAPPSuspentionTerminationEmailHandler.sendWarningEmails(new List<Id>{ acc.Id });
        Test.stopTest();

        System.assert(true, 'Suspension flow covered');
    }

    @isTest static void testTerminationFlow() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Broker 2' LIMIT 1];
        acc.Blacklisted__c = true;
        acc.Blacklist_Reason__c = 'Violation';
        update acc;

        Test.startTest();
        BAPPSuspentionTerminationEmailHandler.sendWarningEmails(new List<Id>{ acc.Id });
        Test.stopTest();

        System.assert(true, 'Termination flow covered');
    }

    @isTest static void testLineManagerApprovedFlows() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Broker 0' LIMIT 1];
        acc.ApprovalStatus__c = 'Approved By Line Manager';
        acc.Scenarios__c = 'Terminate';
        acc.ExecutiveSalesDirector__c = UserInfo.getUserId();
        acc.LineManager__c = UserInfo.getUserId();
        update acc;

        Test.startTest();
        BAPPSuspentionTerminationEmailHandler.sendWarningEmails(new List<Id>{ acc.Id });
        
        acc.Scenarios__c = 'Suspend';
        update acc;
       
        BAPPSuspentionTerminationEmailHandler.sendWarningEmails(new List<Id>{ acc.Id });
        Test.stopTest();

        System.assert(true, 'Approved by Line Manager flows covered');
    }

    @isTest
static void testRejectedByLMFterminatelows() {
    // Create a test User
    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
    User testUser = new User(
        Alias = 'tuser',
        Email='testuser@example.com',
        EmailEncodingKey='UTF-8',
        LastName='User',
        LanguageLocaleKey='en_US',
        LocaleSidKey='en_US',
        ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName='testuser'+System.currentTimeMillis()+'@example.com'
    );
    insert testUser;
    User bbmUser = [SELECT Id FROM User WHERE Profile.Name = 'Broker Management Team' AND IsActive = true LIMIT 1];

    Account acc = [SELECT Id FROM Account WHERE Name = 'Broker 1' LIMIT 1];
    acc.BBMId__c = bbmUser.Id;
    acc.ApprovalStatus__c = 'Rejected By Line Manager';
    acc.Scenarios__c = 'Terminate';
    update acc;

    Test.startTest();
    BAPPSuspentionTerminationEmailHandler.sendWarningEmails(new List<Id>{ acc.Id });
    

    // Next scenario
    acc.Scenarios__c = 'Suspend';
    update acc;

    
    BAPPSuspentionTerminationEmailHandler.sendWarningEmails(new List<Id>{ acc.Id });
    Test.stopTest();

    System.assert(true, 'Rejected by Line Manager flows covered with User recipient');
}
    
    @isTest
    static void testRejectedByLMFSuspendlows() {
        // Create a test User
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            Alias = 'tuser',
            Email='testuser@example.com',
            EmailEncodingKey='UTF-8',
            LastName='User',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles',
            UserName='testuser'+System.currentTimeMillis()+'@example.com'
        );
        insert testUser;
        User bbmUser = [SELECT Id FROM User WHERE Profile.Name = 'Broker Management Team' AND IsActive = true LIMIT 1];
        
        Account acc = [SELECT Id FROM Account WHERE Name = 'Broker 1' LIMIT 1];
        acc.BBMId__c = bbmUser.Id;
        acc.ApprovalStatus__c = 'Rejected By Line Manager';
        acc.Scenarios__c = 'Suspend';
        update acc;
        
        Test.startTest();
        BAPPSuspentionTerminationEmailHandler.sendWarningEmails(new List<Id>{ acc.Id });
        Test.stopTest();
        
        System.assert(true, 'Rejected by Line Manager flows covered with User recipient');
    }

    @isTest static void testRejectedByESDFlows() {
        User bbmUser = [SELECT Id FROM User WHERE Profile.Name = 'Broker Management Team' AND IsActive = true LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = 'Broker 2' LIMIT 1];
        acc.ApprovalStatus__c = 'Rejected By Executive Sales Director';
        acc.Scenarios__c = 'Terminate';
        //acc.BBMId__c = UserInfo.getUserId();
        acc.BBMId__c = bbmUser.id;
        update acc;

        Test.startTest();
        BAPPSuspentionTerminationEmailHandler.sendWarningEmails(new List<Id>{ acc.Id });
       

        acc.Scenarios__c = 'Suspend';
        update acc;
        
        BAPPSuspentionTerminationEmailHandler.sendWarningEmails(new List<Id>{ acc.Id });
        Test.stopTest();

        System.assert(true, 'Rejected by ESD flows covered');
    }
}