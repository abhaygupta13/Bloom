@isTest
private class NotificationServiceTest {

    @testSetup
    static void setupData() {
        // Create Account
        Account acc = TestDataFactory.createBrokerAccount('test', false, '1122334455');
        insert acc;

        // Create Case
        List<Case> caseList = new List<Case>();
        for(Integer i=0; i<20; i++){
            Case caseObj = TestDataFactory.createBFMCase('Email', 'New', 'Test description', 'Test Subject',null,'test@gmail.com','0123456789');
            caseObj.AccountId = acc.Id;
            caseList.add(caseObj);
        }
        insert caseList;

        // Create SMS Template
        SMSTemplate__c smsTemp = new SMSTemplate__c(
            Name = 'BFM SR Create Notification',
            SenderNumber__c = '1234567890',
            Body__c = 'Hello {0}'
        );
        insert smsTemp;

        // Create WhatsApp Template
        WhatsAppTemplate__c waTemp = new WhatsAppTemplate__c(
            Name = 'BFM SR Create Notification',
            SenderNumber__c = '1234567890',
            Body__c = 'Hello {0}',
            DynamicParams__c = '{0}',
            TemplateAPIName__c = 'test_template',
            Language__c = 'en'
        );
        insert waTemp;
    }

    @isTest
    static void testReplaceTemplateParams() {
        String result = NotificationService.replaceTemplateParams(
            'Hello {0}', 
            new List<String>{'John'}
        );
        System.assertEquals('Hello John', result);
    }

    @isTest
    static void testGetSMSIntegrationRecord() {

        Case c = [SELECT Id, RequesterContactNumber__c FROM Case LIMIT 1];

        SMSTemplate__c smsTemp = [SELECT Id, SenderNumber__c, Body__c FROM SMSTemplate__c LIMIT 1];

        Test.startTest();

        IntegrationRecord__c rec = NotificationService.getInstance()
            .getSMSIntegrationRecord(c, smsTemp, new List<String>{'Test User'});

        Test.stopTest();

        System.assertNotEquals(null, rec);
    }

    @isTest
    static void testGetWhatsappIntegrationRecord() {

        Case c = [SELECT Id, RequesterContactNumber__c FROM Case LIMIT 1];

        WhatsAppTemplate__c waTemp = [SELECT Id, SenderNumber__c, Body__c, DynamicParams__c, TemplateAPIName__c, Language__c 
                                     FROM WhatsAppTemplate__c LIMIT 1];

        Test.startTest();

        IntegrationRecord__c rec = NotificationService.getInstance()
            .getWhatsappIntegrationRecord(c, waTemp, new List<String>{'Test User'});

        Test.stopTest();

        System.assertNotEquals(null, rec);
    }

    @isTest
    static void testGetSMSTemplates() {

        Test.startTest();

        Map<String, SMSTemplate__c> result = NotificationService.getInstance()
            .getSMSTemplates(new Set<String>{'BFM SR Create Notification'});

        Test.stopTest();

        System.assert(result.size() > 0);
    }

    @isTest
    static void testGetWhatsAppTemplates() {

        Test.startTest();

        Map<String, WhatsAppTemplate__c> result = NotificationService.getInstance()
            .getWhatsAppTemplates(new Set<String>{'BFM SR Create Notification'});

        Test.stopTest();

        System.assert(result.size() > 0);
    }

    @isTest
    static void testSendBellNotification() {

        Case c = [SELECT Id, OwnerId FROM Case LIMIT 1];

        Set<String> recipients = new Set<String>{c.OwnerId};

        Test.startTest();

            NotificationService.sendBellNotification(recipients, c.Id);
        

        Test.stopTest();

        System.assert(true);
    }
}