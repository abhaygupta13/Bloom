@IsTest
private class PushNotificationTriggerHelperTest {

    @IsTest
    static void testCreateIntegrationRecords() {
        
        Account a = new Account();
        a.Name = 'Test Account';
        insert a;
        
        Contact c = new Contact(); 
        c.LastName = 'test conatat';
        c.AccountId = a.id;
        c.Email = 'test.conatat@gmail.com';
        insert c;
        
        Lead testLead = new Lead(); 
        testLead.LastName = 'Test Lead';
        testLead.MobileCountryCode__c = '971';
        testLead.Status = 'New';
        testLead.MobilePhone = '9876543211';
        testLead.Email = 'test@gmail.com'; 
        insert testLead;


        PushNotification__c pushNotification = new PushNotification__c(
            ObjectAPIName__c = 'Lead',
            RecordId__c = testLead.Id,
            SenderBloomPartnersID__c = 'BP001',
            Title__c = 'Test Title',
            Body__c = 'Test Body',
            NotificationType__c = '1',
            Contact__c = c.Id
        );
        
        insert pushNotification;
        
        pushNotification.Body__c = 'Test Body Notification';
        update pushNotification;
        
        PushNotification__c pushNotification1 = new PushNotification__c(
            ObjectAPIName__c = 'Lead',
            RecordId__c = testLead.Id,
            SenderBloomPartnersID__c = 'BP001',
            Title__c = 'Test Title',
            Body__c = 'Test Body',
            NotificationType__c = '1',
            Contact__c = c.Id
        );
        
        insert pushNotification1;
        
        delete pushNotification1;


        Test.startTest();
        PushNotificationTriggerHelper.createIntegrationRecords(new List<PushNotification__c>{pushNotification});
        Test.stopTest();

        IntegrationRecord__c record = [
            SELECT Type__c,
                   Action__c,
                   ObjectAPIName__c,
                   RecordId__c,
                   Param1__c,
                   Param2__c,
                   Param3__c,
                   Param4__c,
                   LongTextParam1__c
            FROM IntegrationRecord__c
            WHERE Type__c = 'PUSH_NOTIFICATION_INTEGRATION'
            LIMIT 1
        ];

        System.assertEquals('PUSH_NOTIFICATION_INTEGRATION', record.Type__c);
        System.assertEquals('Insert', record.Action__c);
        System.assertEquals('Lead', record.ObjectAPIName__c);
        System.assertEquals('BP001', record.Param1__c);
        System.assertEquals('Test Title', record.Param2__c);
        System.assertEquals('1', record.Param4__c);
    }
}