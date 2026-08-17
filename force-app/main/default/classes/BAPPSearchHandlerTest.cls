@IsTest
public class BAPPSearchHandlerTest {
    
    // ====== Test Setup ======
    @TestSetup
    static void setupData() {
        // Create Broker Account
        Account acc = TestDataFactory.createBrokerAccount('Test Broker Agency', false, '1234567890');
        insert acc;
        
        Contact conAgent = createContact(acc, 'Agent', true, 'Agent Contact');
        Contact conAdmin = createContact(acc, 'Admin', true, 'Admin Contact');
        Contact conPartner = createContact(acc, 'Partner', true, 'Partner Contact');
        Contact conNullRole = createContact(acc, null, true, 'Null Role Contact');
        
        // Create Leads for Admin and Agent
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 3; i++) {
            leads.add(new Lead(
                FirstName = 'Lead' + i,
                LastName = 'Tester',
                Company = 'Test Company',
                Email = 'lead' + i + '@test.com',
                Status = (i < 2 ? 'Closed' : 'New'), // mix Closed and New
                BrokerAgency__c = acc.Id,
                BrokerAgent__c = conAgent.Id, // assign to Agent
                //LeadCustomerName__c = 'Lead' + i + ' Tester',
                MobilePhoneNumber__c = '98765432' + i,
                MobileCountryCode__c = '971',
                Project__c = 'Bloom Towers',
                UnitType__c = 'Villa',
                NumberOfBedrooms__c = '6BHK',
                Passport_Number__c = '12345678',
                PassportExpiryDate__c = System.today().addYears(5),
                NationalID__c = '784-1234-1238867-8',
                NationalIDExpiryDate__c = System.today().addYears(5),
                PreferredCommunicationMethodology__c = 'WhatsApp',
                LanguagePreference__c = 'English'
            ));
        }
        insert leads;
    }
    
    // ====== TEST: Normal search by Admin ======
    @IsTest
    static void testNormalSearch_Admin() {
        Contact admin = [SELECT Id, AccountId FROM Contact WHERE BrokerContactRole__c INCLUDES ('Admin') LIMIT 1];
        
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        
        Test.startTest();
        BAPPSearchHandler.handleGetLeads('Lead', admin.AccountId, admin.Id, false);
        Test.stopTest();
        
        String body = RestContext.response.responseBody.toString();
        System.debug(body);
        
    }
    
    // ====== TEST: Normal search by Agent ======
    @IsTest
    static void testNormalSearch_Agent() {
        Contact agent = [SELECT Id, AccountId FROM Contact WHERE BrokerContactRole__c INCLUDES ('Agent') LIMIT 1];
        
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        
        Test.startTest();
        BAPPSearchHandler.handleGetLeads('Lead', agent.AccountId, agent.Id, false);
        Test.stopTest();
        
        String body = RestContext.response.responseBody.toString();
        System.debug(body);
    }
    
    // ====== TEST: Duplicate search ======
    @IsTest
    static void testDuplicateSearch() {
        Contact agent = [SELECT Id, AccountId FROM Contact WHERE BrokerContactRole__c INCLUDES ('Agent') LIMIT 1];
        
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        
        Test.startTest();
        BAPPSearchHandler.handleGetLeads('', agent.AccountId, agent.Id, true); // duplicateSearch = true
        Test.stopTest();
        
        String body = RestContext.response.responseBody.toString();
        System.debug(body);
    }
    
    // ====== TEST: Missing parameters ======
    @IsTest
    static void testMissingParams() {
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        
        Test.startTest();
        BAPPSearchHandler.handleGetLeads(null, null, null, null);
        Test.stopTest();
    }
    
    // ====== TEST: Invalid Account ======
    @IsTest
    static void testInvalidAccount() {
        Contact admin = [SELECT Id, AccountId FROM Contact WHERE BrokerContactRole__c INCLUDES ('Admin') LIMIT 1];
        
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        
        Test.startTest();
        BAPPSearchHandler.handleGetLeads('Lead', '001000000000001AAA', admin.Id, false);
        Test.stopTest();
    }
    
    // ====== TEST: Invalid Contact ======
    @IsTest
    static void testInvalidContact() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        
        Test.startTest();
        BAPPSearchHandler.handleGetLeads('Lead', acc.Id, '003000000000001AAA', false);
        Test.stopTest();
    }
    
    // ====== TEST: No Leads Found ======
    @IsTest
    static void testNoLeadsFound() {
        Contact admin = [SELECT Id, AccountId FROM Contact WHERE BrokerContactRole__c INCLUDES ('Admin') LIMIT 1];
        
        // Delete all leads
        delete [SELECT Id FROM Lead];
        
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        
        Test.startTest();
        BAPPSearchHandler.handleGetLeads('NonExistingSearch', admin.AccountId, admin.Id, false);
        Test.stopTest();
        
    }
    
    private static Contact createContact(Account acc, String role, Boolean isActive, String lastName) {
        Contact con = new Contact(
        LastName = lastName,
        AccountId = acc.Id,
        BrokerContactRole__c = role,
       	IsActive__c = isActive,
        Email ='johnny.depp+' + System.currentTimeMillis() + '@example.com',
        RecordTypeId = Utility.getRecordTypeIdByDevName(Contact.SObjectType, 'Broker'));
        insert con;
        return con;
    }
}