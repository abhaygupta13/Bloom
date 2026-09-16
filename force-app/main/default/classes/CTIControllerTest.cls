/*****************************************************************************************
Class       : CTIControllerTest
Author      : Aman Bharti
Description : CTI Controller Test
Test Class  : 
Created Date: 03 AUG 2026 
*****************************************************************************************/
@isTest
public class CTIControllerTest {

    @testSetup
    private static void setup() {
        Account acc = TestDataFactory.createBrokerAccount('test acc', false, '1122334455');
        insert acc;

        Contact con = TestDataFactory.createContact('test Name', acc.Id, true, 'abc@gmail.com');
        insert con;

        Lead leadRec = TestDataFactory.createLead('test lead', '9876543210', 'abc@gmail.com');
        insert leadRec;
    }

    @isTest
    private static void testGetPhoneDetails() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Lead ld = [SELECT Id FROM Lead LIMIT 1];

        Test.startTest();
            Map<String, String> accPhones = CTIController.getPhoneDetails(acc.Id);
            Map<String, String> conPhones = CTIController.getPhoneDetails(con.Id);
            Map<String, String> leadPhones = CTIController.getPhoneDetails(ld.Id);
            Map<String, String> nullPhones = CTIController.getPhoneDetails(null);
        Test.stopTest();

        System.assertNotEquals(null, accPhones);
        System.assertNotEquals(null, conPhones);
        System.assertNotEquals(null, leadPhones);
        System.assert(nullPhones.isEmpty());
    }

    @isTest
    private static void testCreateIntegrationRecord_Contact() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
            CTIController.createIntegrationRecord(con.Id, 'Mobile Phone', 'BFM');
            CTIController.createIntegrationRecord(con.Id, 'Home Phone', 'BFM');
            CTIController.createIntegrationRecord(con.Id, 'Other Phone', 'BFM');
        Test.stopTest();

        List<IntegrationRecord__c> records = [SELECT Id FROM IntegrationRecord__c Where RecordId__c = :con.Id];
        System.assertEquals(3, records.size(), 'Expected 3 records for Contact labels');
    }

    @isTest
    private static void testCreateIntegrationRecord_Account() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
            CTIController.createIntegrationRecord(acc.Id, 'Mobile Phone', 'BFM');
            CTIController.createIntegrationRecord(acc.Id, 'Phone', 'BFM');
        Test.stopTest();

        List<IntegrationRecord__c> records = [SELECT Id FROM IntegrationRecord__c Where RecordId__c = :acc.Id AND Type__c = 'CLICK_TO_DIAL'];
        System.assertEquals(2, records.size(), 'Expected 2 records for Account labels');
    }

    @isTest
    private static void testCreateIntegrationRecord_Lead() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        Test.startTest();
            CTIController.createIntegrationRecord(lead.Id, 'Mobile Phone', 'BFM');
            CTIController.createIntegrationRecord(lead.Id, 'Phone', 'BFM');
        Test.stopTest();
        List<IntegrationRecord__c> records = [SELECT Id FROM IntegrationRecord__c Where RecordId__c = :lead.Id]; 
        System.assertEquals(2, records.size(), 'Expected 2 records for Lead labels');
    }

    @isTest
    private static void testGetSkillOptions_UserOverride() {
        User usr = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        usr.ClickToDialSkill__c = 'BFM';
        update usr;

        Test.startTest();
            List<String> options = CTIController.getSkillOptions();
        Test.stopTest();

        System.assertEquals(1, options.size());
        System.assertEquals('BFM', options[0]);
    }
}