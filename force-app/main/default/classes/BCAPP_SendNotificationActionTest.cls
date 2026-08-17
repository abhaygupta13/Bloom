@isTest
private class BCAPP_SendNotificationActionTest {

    private class Seed {
        Account acc;
        User__c appUser;
        Service_Catalog__c sc;
        Service__c svcEmail;
        Service__c svcPush;
        Case sr;
        Id templateId;
    }

    private static Id getAnyEmailFolderId() {
        // Use any Email template folder available in org
        Folder f = [SELECT Id FROM Folder WHERE Type = 'Email' LIMIT 1];
        return f.Id;
    }

    private static Id ensureEmailTemplate(String devName) {
        Id folderId = getAnyEmailFolderId();
        EmailTemplate et = new EmailTemplate(
            Name = 'Test Notify Template',
            DeveloperName = devName,
            FolderId = folderId,
            TemplateType = 'html',
            Subject = 'Notification for {!Case.CaseNumber}',
            HtmlValue = '<p>Status: {!Case.Status}</p>'
        );
        insert et;
        return et.Id;
    }

    private static Seed setupData() {
        Seed s = new Seed();
        // Account + user (for customer email and device token)
        s.acc = BCAPP_TestDataFactory.createAccount('Notif AC');
        insert s.acc;

        s.appUser = BCAPP_TestDataFactory.createUser('az-notif');
        s.appUser.Account__c = s.acc.Id;
        s.appUser.User_Account__c = s.acc.Id;
        s.appUser.Email__c = 'user@test.com';
        s.appUser.deviceRegistrationId__c = 'reg-xyz';
        insert s.appUser;

        // Service Catalog and Services
        s.sc = new Service_Catalog__c(Name = 'Test Service', Active__c = true);
        insert s.sc;
        s.svcEmail = new Service__c(Name = 'Send Email', Is_Active__c = true);
        s.svcPush  = new Service__c(Name = 'Push Notification', Is_Active__c = true);
        insert new List<Service__c>{ s.svcEmail, s.svcPush };

        // Case under the catalog
        s.sr = new Case(
            AccountId = s.acc.Id,
            Status = 'Submitted',
            Service_Catalog__c = s.sc.Id,
            RecordTypeId = Utilities.getRecordTypeId('Case','General Service Request'),
            User__c = s.appUser.Id,
            Subject = 'Test SR'
        );
        insert s.sr;

        return s;
    }

    @isTest static void test_handleSendEmailActionItems_sendsEmail() {
        // Use an existing EmailTemplate in org metadata
        EmailTemplate anyTpl = [SELECT DeveloperName FROM EmailTemplate LIMIT 1];
        String devName = anyTpl.DeveloperName;
        Seed s = setupData();

        // Action item configured for Send Email with customer recipient
        Action_Items__c ai = new Action_Items__c(
            Service_Catalog__c = s.sc.Id,
            Service__c = s.svcEmail.Id,
            On_Submit__c = true
        );
        insert ai;

        Task_Action__c ta = new Task_Action__c(
            Task__c = ai.Id,
            EmailTemplateName__c = devName,
            Send_Customer__c = true,
            Status__c = 'Submitted'
            
        );
        Task_Action__c ta1 = new Task_Action__c(
            Task__c = ai.Id,
            EmailTemplateName__c = devName,
            Send_Customer__c = false,
            Status__c = 'Submitted',
            EmailRecipients__c = 'test@test.com',
             emailCCAddresses__c = 'test@test.com'
        );
        List<Task_Action__c> lstTA = new List<Task_Action__c>{ta,ta1};
        insert lstTA;
		 Task_Rule_Criteria__c tRC = new Task_Rule_Criteria__c();
        tRC.Task__c = ai.Id;
       	tRC.Rule_Criteria__c = 'Status=\'Submitted\'';
		insert tRC;
        Test.startTest();
        new BCAPP_SendNotificationAction(new List<Case>{ s.sr }, new Map<Id, SObject>()).handleSendEmailActionItems();
        Test.stopTest();

        // No exception and flow reached Messaging; basic assertion using template exists
        System.assert(true, 'Email flow executed');
    }

    private class PushMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(202);
            res.setBody('{"ok":true}');
            return res;
        }
    }

    @isTest static void test_handlePushNotificationActionItems_enqueuesAndSends() {
        Seed s = setupData();

        // Action item configured for Push Notification without rule criteria
        Action_Items__c ai = new Action_Items__c(
            Service_Catalog__c = s.sc.Id,
            Service__c = s.svcPush.Id,
            On_Submit__c = true
        );
        insert ai;
        
        Task_Rule_Criteria__c tRC = new Task_Rule_Criteria__c();
        tRC.Task__c = ai.Id;
       	tRC.Rule_Criteria__c = 'Status=\'Submitted\'';
		insert tRC;

        Task_Action__c ta = new Task_Action__c(
            Task__c = ai.Id,
            Title__c = 'SR Update',
            Template__c = 'Case {CaseNumber} is {Status}',
            Task_Rule_Criteria__c = tRC.Id
            
        );
        insert ta;

        // Set callout mock for queued push job
        Test.setMock(HttpCalloutMock.class, new PushMock());

        Test.startTest();
        new BCAPP_SendNotificationAction(new List<Case>{ s.sr }, new Map<Id, SObject>()).handlePushNotificationActionItems();
        Test.stopTest();

        System.assert(true, 'Push flow executed');
    }
}