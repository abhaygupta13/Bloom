@IsTest
private class PushNotificationServiceTest {

    private static PushNotificationTemplate__c createTemplate(String name) {

        PushNotificationTemplate__c template =
            new PushNotificationTemplate__c(
                Name = name,
                Title__c = 'Test Title {0}',
                Body__c = 'Test Body {0}',
                NotificationType__c = 'Test',
                SenderBloomPartnersID__c = 'BP001'
            );

        insert template;
        return template;
    }


    private static Project__c createProject() {

        Project__c project = new Project__c(
            Name = 'Test Project'
        );

        insert project;
        return project;
    }


    private static Account createAccount() {

        Account account = new Account(
            Name = 'Test Account'
        );

        insert account;
        return account;
    }


    private static Contact createContact(
        Id accountId,
        Id projectId,
        String role
    ) {

        Contact contact = new Contact(
            LastName = 'Test Contact',
            Email = 'test.conatat@gmail.com',
            AccountId = accountId
        );

        if (role != null) {
            contact.BrokerContactRole__c = role;
        }

        insert contact;
        return contact;
    }


    @IsTest
    static void testReplaceTemplateParams() {

        String result =
            PushNotificationService.replaceTemplateParams(
                'Hello {0}',
                new List<String>{'Test'}
            );

        System.assertEquals('Hello Test', result);

        /*System.assertEquals(
            null,
            PushNotificationService.replaceTemplateParams(
                null,
                new List<String>{'Test'}
            )
        );

        System.assertEquals(
            'Test',
            PushNotificationService.replaceTemplateParams(
                'Test',
                null
            )
        );*/
    }


    @IsTest
    static void testLead() {

        Lead lead = new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company'
        );

        insert lead;

        PushNotificationTemplate__c template =
            createTemplate('Lead Template');

        Test.startTest();

        PushNotification__c notification =
            PushNotificationService.getInstance()
                .getPushNotificationRecord(
                    lead,
                    template,
                    new List<String>{'Test'}
                );

        Test.stopTest();

        System.assertEquals(
            'Lead',
            notification.ObjectAPIName__c
        );

        System.assertEquals(
            lead.Id,
            notification.RecordId__c
        );

        System.assertEquals(
            'Test Title Test',
            notification.Title__c
        );

        System.assertEquals(
            'Test Body Test',
            notification.Body__c
        );
    }


    @IsTest
    static void testContact() {

        Project__c project = createProject();

        Contact contact = createContact(
            null,
            project.Id,
            null
        );

        PushNotificationTemplate__c template =
            createTemplate('Contact Template');

        Test.startTest();

        PushNotification__c notification =
            PushNotificationService.getInstance()
                .getPushNotificationRecord(
                    contact,
                    template,
                    new List<String>{'Test'}
                );

        Test.stopTest();

        System.assertEquals(
            'Contact',
            notification.ObjectAPIName__c
        );

        System.assertEquals(
            contact.Id,
            notification.RecordId__c
        );

        System.assertEquals(
            contact.Id,
            notification.Contact__c
        );
    }


    @IsTest
    static void testAccount() {

        Project__c project = createProject();

        Account account = createAccount();

        Contact contact = createContact(
            account.Id,
            project.Id,
            'SuperAdmin'
        );

        // Required because service uses accountObj.Contacts
        account = [
            SELECT Id,
                   (SELECT Id, BrokerContactRole__c
                    FROM Contacts)
            FROM Account
            WHERE Id = :account.Id
        ];

        PushNotificationTemplate__c template =
            createTemplate('Account Template');

        Test.startTest();

        PushNotification__c notification =
            PushNotificationService.getInstance()
                .getPushNotificationRecord(
                    account,
                    template,
                    new List<String>{'Test'}
                );

        Test.stopTest();

        System.assertEquals(
            'Account',
            notification.ObjectAPIName__c
        );

        System.assertEquals(
            account.Id,
            notification.RecordId__c
        );

        System.assertEquals(
            contact.Id,
            notification.Contact__c
        );

        System.assertEquals(
            'Test Title Test',
            notification.Title__c
        );

        System.assertEquals(
            'Test Body Test',
            notification.Body__c
        );
    }

    @IsTest
    static void testBrokerCommission() {

        Project__c project = createProject();

        Account account = createAccount();

        Contact agent = createContact(
            account.Id,
            project.Id,
            null
        );

        BrokerCommission__c commission =
            new BrokerCommission__c(
                Project__c = project.Id,
                Agent__c = agent.Id
            );

        insert commission;

        PushNotificationTemplate__c template =
            createTemplate('Broker Commission Template');

        Test.startTest();

        PushNotification__c notification =
            PushNotificationService.getInstance()
                .getPushNotificationRecord(
                    commission,
                    template,
                    new List<String>{'Test'}
                );

        Test.stopTest();

        System.assertEquals(
            'BrokerCommission__c',
            notification.ObjectAPIName__c
        );

        System.assertEquals(
            commission.Id,
            notification.RecordId__c
        );

        System.assertEquals(
            'Test Body Test',
            notification.Body__c
        );
    }


    @IsTest
    static void testSalesOrder() {

        Project__c project = createProject();

        Account account = createAccount();
        
        
        Id accRecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Broker Agency').getRecordTypeId();
        Account acc = new Account(Name = 'Test Account', RecordTypeId= accRecordTypeId);
        insert acc;


        Contact brokerContact = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@example.com',
            MobileCountryCode__c = '+1',
            MobilePhone = '1234567890',
            AccountId = acc.Id
        );
        insert brokerContact;
        
        Opportunity opportunity = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = account.Id,
            StageName = 'Closed Won',
            WinReason__c = 'Bloom Brand',
            CloseDate = Date.today().addDays(30),
            BrokerAgencyAccount__c = acc.Id,
            BrokerAgentContact__c = brokerContact.Id
        );

        insert opportunity;

        SalesOrder__c salesOrder =
            new SalesOrder__c(
                Account__c = account.Id,
                Opportunity__c = opportunity.Id
            );

        insert salesOrder;

        PushNotificationTemplate__c template =
            createTemplate('Sales Order Template');

        Test.startTest();

        PushNotification__c notification =
            PushNotificationService.getInstance()
                .getPushNotificationRecord(
                    salesOrder,
                    template,
                    new List<String>{'Test'}
                );

        Test.stopTest();

        System.assertEquals(
            'SalesOrder__c',
            notification.ObjectAPIName__c
        );

        System.assertEquals(
            salesOrder.Id,
            notification.RecordId__c
        );

        System.assertEquals(
            'Test Body Test',
            notification.Body__c
        );
    }
    
    @IsTest
    static void testGetApprovalProcessPushNotificationRecord() {
        PushNotificationTemplate__c template = new PushNotificationTemplate__c(
            Name = 'Approval Notification',
            Title__c = 'Approval for {0}',
            Body__c = 'Your request for {0} has been {1}.',
            NotificationType__c = 'Approval',
            SenderBloomPartnersID__c = 'BLOOM'
        );
    
        List<String> values = new List<String>{ 'Test Request', 'Approved' };
        Id recordId = UserInfo.getUserId();
        String recipientEmail = 'test@example.com';
    
        Test.startTest();
        PushNotification__c pushNotification = PushNotificationService.getInstance().getApprovalProcessPushNotificationRecord(
            recordId,
            recipientEmail,
            template,
            values
        );
        Test.stopTest();
    
        System.assertEquals('Approval Notification', pushNotification.Type__c);
    }
}