/*****************************************************************************************
Class       : NICEIntegrationControllerTest
Author      : Aman Bharti
Description : NICE Integration Controller Test
Test Class  : 
Created Date: 03 AUG 2026 
*****************************************************************************************/
@isTest
public class NICEIntegrationControllerTest {
    @testSetup
    private static void testData() {

        Account acc = TestDataFactory.createBrokerAccount('test', false, '1122334455');
        insert acc;
        
        Contact con = TestDataFactory.createContact('test Name', acc.Id, true,  'abc@gmail.com');
        insert con; 

        Lead leadRec = TestDataFactory.createLead('test lead', '9876543210', 'abc@gmail.com');
        insert leadRec;
    }

    @isTest
    private static void testgetPhoneDetails() {
        List<Account> accountList = [SELECT Id FROM Account];
        List<Contact> contactList = [SELECT Id FROM Contact];
        List<Lead> leadList = [SELECT Id FROM Lead];
        Test.startTest();
            List<NICEIntegrationController.PhoneDetail> accountPhones  = NICEIntegrationController.getPhoneDetails(accountList[0].Id);
            List<NICEIntegrationController.PhoneDetail> contactPhones = NICEIntegrationController.getPhoneDetails(contactList[0].Id);
            List<NICEIntegrationController.PhoneDetail> leadPhones = NICEIntegrationController.getPhoneDetails(leadList[0].Id);
        Test.stopTest();
        System.assertNotEquals(null, accountPhones);
        System.assertNotEquals(null, contactPhones);
        System.assertNotEquals(null, leadPhones);
    }

    @isTest
    private static void testCreateIntegrationRecord() {
        List<Account> accountList = [SELECT Id FROM Account];
        List<Map<String,String>> options = NICEIntegrationController.getSkillOptions();
        Test.startTest();
            NICEIntegrationController.createIntegrationRecord(accountList[0].Id, '9876543210','987XXXX210','BFM');
        Test.stopTest();
        List<IntegrationRecord__c> integrationList = [SELECT Id FROM IntegrationRecord__c];
        System.assertEquals(false, integrationList.isEmpty(), 'No Integration record found');
    }
}