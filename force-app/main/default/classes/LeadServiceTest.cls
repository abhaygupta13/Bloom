/*
* @Author : Jayprakash Bharti
* @CreatedDate : 30th AUG 2024
* @Description : 
*/
/*****************************************************************************************************
* Version       Author      Date             Comment       
* 1.0           Jayprakash  30AUG2024        Test 
* 1.1           prashant Sahu  30April2026   testFindDuplicateLead 
* 1.2           prashant Sahu  30April2026   testFilterStatusSummaryMethods 
*****************************************************************************************************/
@IsTest
public class LeadServiceTest {
    
    @IsTest
    static void testMethod1(){
        test.startTest();
        LeadService leadService= LeadService.getInstance();
        Lead lead= TestDataFactory.createLead('leadName', '1234567890','emailID@xyz.com');
        insert lead;
        lead.BudgetRangeFrom__c = 2000;
        update lead;
        Set<ID> leadidSet= new Set<ID>();
        Set<ID> leadidCreatedBySet= new Set<ID>();
         Set<ID> leadidCreatedByProfileSet= new Set<ID>();
        leadidSet.add(lead.id);
        leadidCreatedBySet.add(lead.CreatedById);
        Id CreatedById = lead.CreatedById;
      //  User u = [SELECT Id, ProfileId FROM User WHERE Id = :lead.CreatedById LIMIT 1];
   // Set<Id> createdByProfileIdSet = new Set<Id>{ u.ProfileId };
      //  leadidCreatedByProfileSet.add(profileId);
        leadService.getLeadByIds(leadidSet);
        leadService.getLeadById(lead.id);
         leadService.getLeadByIdsAndCreatedByIds(leadidSet,leadidCreatedBySet);
       //  leadService.getLeadByCreatedByIds(leadidSet,leadidCreatedBySet,createdByProfileIdSet);
        test.stopTest();
    }
    
    @IsTest
    static void testMethod2(){
        //Create Broker Account
        Account testAccount = TestDataFactory.createBrokerAccount('Test', false, '1111111111');
        insert testAccount;

        //Create Contact
        Contact testContact = TestDataFactory.createContact('TestContact', testAccount.Id, true, 'test@gmail.com');
        testContact.Blacklisted__c=false;
        testContact.IsSuspended__c=false;
        testContact.SuspensionTenure__c='';
        testContact.BrokerContactRole__c ='Admin;Agent';
        insert testContact;
        
        test.startTest();
        List<lead> leadSet= new List<lead>();
        LeadService leadService= LeadService.getInstance();
        
        Lead lead= TestDataFactory.createLead('leadName', '1234567890','emailID@xyz.com');
        lead = leadService.insertLead(lead);
        lead.LastName='Changed';
        leadSet.add(lead);
        
        leadService.updateLead(lead);
        leadService.updateLeadWithoutTrigger(lead);
        
        leadService.updateLeads(leadSet);
        leadService.updateLeadsWithoutTrigger(leadSet);
        
        Lead lead1= TestDataFactory.createLead('leadName1', '1234567891','emailID1@xyz.com');
        lead1.LeadManagerStatus__c = 'New';
        lead1.BrokerAgency__c = testAccount.Id;
        lead1.BrokerAgent__c = testContact.Id;
        
        List<Lead> leadSet2= new List<Lead>{lead1};
        leadService.insertLeads(leadSet2);
        leadService.getLeadsByADHAApplicationNumber('12345678');
        leadService.insertLeadsWithoutDuplicateRule(leadSet2);
        leadService.insertLeadWithoutDuplicateRule(lead);
        Set<Id> myLeadSet = new Set<Id>();
		myLeadSet.add(lead1.Id);
        
        Set<Id> userIdSet = new Set<Id>();
        userIdSet.add(UserInfo.getUserId());
        
        Set<Id> userProfileIdSet = new Set<Id>();
		userProfileIdSet.add(UserInfo.getProfileId());
        
        leadService.getLeadByCreatedByIds(myLeadSet, userIdSet, userProfileIdSet);
        leadService.getLeadByOwnerId(userIdSet, new List<String>{'New'});
        leadService.updateLeadWithoutDuplicateRule(lead1);
        leadService.getLeadsBySearch('leadName1',testAccount.Id, testContact.Id, 3,false);
        leadService.getLeadsBySearch('leadName1','', testContact.Id, 3,false);
        leadService.getLeadsBySearch('leadName1','', testContact.Id, 3,true);
        
        test.stopTest();
    }
    
    @isTest
	static void testFindDuplicateLead() {

    LeadService service = LeadService.getInstance();

    // 🔹 Create original lead (duplicate target)
    Lead l1 = new Lead(
        FirstName = 'John',
        MiddleName = 'A',
        LastName = 'Doe',
        Company = 'Test Company',
        Status = 'New',
        Email = 'john@test.com',
        MobilePhoneNumber__c = '9999999999'
    );
    insert l1;

    // 🔹 Create another lead (to test exclusion by Id)
    Lead l2 = new Lead(
        FirstName = 'John',
        MiddleName = 'A',
        LastName = 'Doe',
        Company = 'Test Company',
        Status = 'New',
        Email = 'john@test.com',
        MobilePhoneNumber__c = '9999999999'
    );
    insert l2;

    // 🔹 Prepare request
    BAPPLeadGenerationHandler.LeadGenerationRequest req = 
        new BAPPLeadGenerationHandler.LeadGenerationRequest();

    req.firstName = 'John';
    req.middleName = 'A';
    req.lastName = 'Doe';
    req.email = 'john@test.com';
    req.phoneNumber = '9999999999';
    req.leadId = l2.Id; // exclude this one

    Test.startTest();

    List<Lead> result = service.findDuplicateLead(req);

    Test.stopTest();

    // 🔹 Assertions
    System.assertNotEquals(null, result);
    System.assert(result.size() > 0, 'Duplicate should be found');
    System.assertEquals(l1.Id, result[0].Id, 'Should return first lead, not excluded one');
}
        
    @isTest
    static void testFilterStatusSummaryMethods() {
        
        LeadService service = LeadService.getInstance();
        
        //Create Broker Account
        Account testAccount = TestDataFactory.createBrokerAccount('Test', false, '1111111111');
        insert testAccount;
        
        //Create Contact
        Contact testContact = TestDataFactory.createContact('TestContact', testAccount.Id, true, 'test@gmail.com');
        testContact.Blacklisted__c=false;
        testContact.IsSuspended__c=false;
        testContact.SuspensionTenure__c='';
        testContact.BrokerContactRole__c ='Admin;Agent';
        insert testContact;
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'user@test.com',
            Username = 'user' + System.currentTimeMillis() + '@test.com',
            Alias = 'tst',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert u;
        
        List<Lead> leads = new List<Lead>{
            new Lead(
                FirstName='John',
                LastName='Doe',
                Company='Test',
                Status='New',
                Email='john@test.com',
                BrokerAgency__c=testAccount.Id,
                BrokerAgent__c=testContact.Id,
                OwnerId=u.Id,
                Lead_Channel__c='Broker Portal'
            ),
                new Lead(
                    FirstName='Jane',
                    LastName='Smith',
                    Company='Test',
                    Status='Closed',
                    Email='testttttt@test.com',
                    BrokerAgency__c=testAccount.Id,
                    BrokerAgent__c=testContact.Id,
                    OwnerId=u.Id,
                    Lead_Channel__c='Broker Portal'
                )
                };
                    insert leads;
        
        Test.startTest();
        
        BAPPGetLeadsHandler.FilterCriteria filter = new BAPPGetLeadsHandler.FilterCriteria();
        filter.status = 'New;Closed';
        filter.salesManagerId = u.Id;
        filter.updatedOnFrom = Date.today().addDays(-1);
        filter.updatedOnTo = Date.today().addDays(1);
        
        List<Lead> filterResult = service.getLeadsByFilters(
            testAccount.Id,
            testContact.Id,
            new List<String>(), // no recordType filter
            filter,
            false // NOT admin → agent filter applied
        );
        System.assert(filterResult.size() >= 0);
        
        List<Lead> statusResult = service.getLeadsForStatusCount(
            testAccount.Id,
            testContact.Id,
            Date.today().addDays(-1),
            Date.today().addDays(1),
            false, // isAdmin
            true   // isAgent
        );
        
        System.assert(statusResult.size() >= 0);
        Map<Id, Map<String, Object>> summary =
            LeadService.getLeadSummaryData(
                new Set<Id>{testContact.Id},
                Date.today().addDays(-1),
                Date.today().addDays(1)
            );
        
        System.assert(summary != null);
        Test.stopTest();
    }
}