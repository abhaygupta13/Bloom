@isTest
public class LeadTriggerHandlerTest {
    
    @TestSetup 
    static void testDataSetup(){
        Profile profileDetail = [SELECT Id FROM Profile WHERE Name='Sales Manager'];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        
        User userRecord = new User(Alias = 'Zaki', Email='Zakial@gmail.com', 
                                   EmailEncodingKey='UTF-8', LastName='Zaki Al Bakri', LanguageLocaleKey='en_US', 
                                   LocaleSidKey='en_US', ProfileId = profileDetail.id, 
                                   TimeZoneSidKey='Asia/Dubai', UserName= uniqueName+'@mail.com',SAP_BP_No__c='0');
        insert userRecord;
        
        User testUser = new User(
            Alias = 'testuser',
            Email = 'testuser@bloomholding1.com',
            Username = 'testuser@bloomholding1.com',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LastName='Zaki Al Bakri',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        
    }
    
    @isTest
    static void testCreateLeadTask_NewLead() {
        List<user> ulist = [select id from user where Profile.Name ='System Administrator' AND IsActive = true limit 1];
        Id BrokeragencyId =Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Broker_Agency').getRecordTypeId();
        //  Id BrokeragentId =Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('BrokerAgent').getRecordTypeId();
        Account a = new Account();
        a.Name = 'TestVinay';
        a.RecordTypeId = BrokeragencyId;
        insert a;
        Contact c = new Contact(); 
        c.LastName = 'test conatat';
        c.AccountId = a.id;
        c.Email = 'test.conatat@gmail.com';
        // c.RecordTypeId = BrokeragentId;
        insert c;
       
        Lead testLead = TestDataFactory.createLead('Test', '9843216782', 'test@gmail.com');
        insert testLead;
        
        Task task = new Task(
            Status = 'Open',
            Count__c = 1,
            WhoId = testLead.Id,
            Subject = 'CC - Day 1 Call 1 - Follow Up',
            ActivityDate = Date.today()
        );
        insert task;
        
        
        Test.startTest();
        Lead objLead = [SELECT Id,ContactCentreLeadStatus__c FROM Lead LIMIT 1];
        objLead.ContactCentreLeadStatus__c = 'Qualified';
        update objLead;
        Test.stopTest();
    }
    
    @isTest
    static void testCreateLeadTask_InvalidStatus() {
        user ulist1 = [select id from user where Profile.Name ='Contact Centre Team'AND IsActive = true limit 1];
        // Test data setup
        Lead testLead = new Lead(); 
        testLead.LastName = 'Test Lead';
        testLead.MobileCountryCode__c = '971';
        testLead.Status = 'New';
        testLead.MobilePhone = '9876543211';
        testLead.Email = 'test@gmail.com';
        testLead.Lead_Channel__c = 'Call';
        testLead.LeadSource = 'Social Media'; // Using a LeadSource other than 'Broker Portal'
        testLead.leadsubsource__c='Instagram';
        testLead.OwnerId = ulist1.Id;
        // Insert the test lead
        
        insert testLead;
        
        testLead.LeadSource = 'Social Media';
        update testLead;
        Test.startTest();
        
        // Call the method to be tested
        List<Lead> leadList = new List<Lead>{ testLead };
            Test.stopTest();
    }
    
    @isTest
    static void testCreateLeadTask_WrongLeadSource() {
        List<user> ulist3 = [select id from user where Profile.Name ='System Administrator' AND IsActive = true limit 1];
        // Test data setup
        Lead testLead = new Lead();
        testLead.LastName = 'Test Lead';
        testLead.MobileCountryCode__c = '971';
        testLead.Status = 'New';
        testLead.MobilePhone = '37829292020';
        testLead.Email = 'testlead@example.com';
        // testLead.Lead_Channel__c = 'Offline';
        testLead.LeadSource = 'Offline';// Using a LeadSource other than 'Broker'
        testLead.leadsubsource__c='Banner';
        testLead.OwnerId = ulist3[0].id;
        insert testLead;
        
        Test.startTest();
        List<Lead> leadList = new List<Lead>{ testLead };
            Test.stopTest();
    }
    
    @isTest
    static void testCreateLeadTaskOnStatusUpdate_QualifiedLead() {
        // Test data setup
        Round_Robins__c rr=new Round_Robins__c(
            Name='Sales Manager',
            Assigned_To__c = String.valueof(1),
            Sobject__c='Lead'
        );
        insert rr;
        
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        Lead testLead = new Lead(); 
        testLead.LastName = 'Testclass';
        testLead.MobileCountryCode__c = '971';
        testLead.Status = 'In Progress';
        testLead.MobilePhone = '37829292020';
        testLead.Email = 'testlead@example.com';
        // testLead.Lead_Channel__c = 'Offline';
        testLead.LeadSource = 'Offline'; // Using a LeadSource other than 'Broker Portal'
        testLead.leadsubsource__c='Banner';
        testLead.OwnerId = adminUser.Id;
        insert testLead;
        
        Task objTask = new Task();
        objTask.WhoId = testlead.id;
        objTask.Status = 'New';
        objTask.Subject = 'Call';
        insert objTask;
        // Update the lead's status to 'Qualified' and change the owner
        testLead.ContactCentreLeadStatus__c = 'Qualified';
        testLead.BuyRent__c = 'Buy';
        testLead.PropertyUsage__c = 'Residential Sale';
        testLead.CustomerBudget__c = '300k-650K';
        testLead.NumberOfBedrooms__c = '1BHK';
        testLead.UnitType__c = 'Apartment';
        testLead.Project__c = 'Bloom Living';
        User newOwner = [SELECT Id FROM User WHERE Email = 'testuser@bloomholding1.com' AND IsActive = true LIMIT 1];
        testLead.OwnerId = newOwner.Id;
        
        Test.startTest();
        update testLead;
        Test.stopTest();
    }
    
    @isTest
    static void testCreateLeadTaskOnStatusUpdate_NewLead() {
        // Test data setup
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        Lead testLead = new Lead();
        testLead.LastName = 'Test Lead';
        testLead.MobileCountryCode__c = '971';
        testLead.MobilePhone = '37829292020';
        testLead.Email = 'testlead@example.com';
        testLead.LeadSource = 'Offline'; 
        testLead.leadsubsource__c='Banner';
        testLead.Status = 'Qualified';
        testLead.OwnerId = adminUser.Id;
        testLead.BuyRent__c = 'Buy';
        testLead.PropertyUsage__c = 'Residential Sale';
        // testLead.AreaSqmt__c = '100-150 SQM';
        testLead.CustomerBudget__c = '300k-650K';
        testLead.NumberOfBedrooms__c = '1BHK';
        testLead.UnitType__c = 'Apartment';
        // testLead.PropertyReadiness__c = '0-12 months';
        testLead.Project__c = 'Bloom Living';
        insert testLead;
        
        Test.startTest();
        
        // Update the lead's status to 'New' and change the owner
        testLead.Status = 'New';
        User newOwner = [SELECT Id FROM User WHERE Profile.Name = 'Sales Manager' AND IsActive = true LIMIT 1];
        testLead.OwnerId = newOwner.Id;
        testLead.LastName = 'test12';
        testLead.MiddleName = 'tes12';
        testLead.FirstName = 'tes12';
        testLead.MobilePhoneNumber__c = '043535353';
        testLead.MobilePhone = '043535353';
         testLead.PhoneNumber__c='043535353';
        
        update testLead;
        
        delete  testLead;
        Test.stopTest();
    }
    
    @isTest
    static void testUseCase1(){
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Contact Centre Team' LIMIT 1];
        User u = new User(
            Username = 'testusercontactcen@bloomholding.com',
            Alias = 'tuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Asia/Dubai',
            ProfileId = p.Id
        );
        insert u;
        
        System.runAs(u) {
            Lead testLead = new Lead(); 
            testLead.LastName = 'Test Lead';
            testLead.MobileCountryCode__c = '971';
            testLead.Status = 'New';
            testLead.MobilePhone = '9876543211';
            testLead.Email = 'test@gmail.com';
            testLead.Lead_Channel__c = 'Call';
            testLead.LeadSource = 'Social Media'; // Using a LeadSource other than 'Broker Portal'
            testLead.leadsubsource__c='Instagram';
            insert testLead;
        }
    }
    
    @isTest
    static void testUseCase2(){
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Sales Manager' LIMIT 1];
        User u = new User(
            Username = 'testusersales@bloomholding.com',
            Alias = 'tuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Asia/Dubai',
            ProfileId = p.Id
        );
        insert u;
        
        System.runAs(u) {
            Lead testLead = new Lead(); 
            testLead.LastName = 'Test Lead';
            testLead.MobileCountryCode__c = '971';
            testLead.Status = 'New';
            testLead.MobilePhone = '9876543211';
          //  testLead.Email = 'test@gmail.com'; //og
            testLead.Lead_Channel__c = 'Call';
            testLead.LeadSource = 'Social Media'; // Using a LeadSource other than 'Broker Portal'
            testLead.leadsubsource__c='Instagram';
            insert testLead;
        }
    }
    
     @isTest
    static void testUseCase3(){
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Contact Centre Team' LIMIT 1];
        User u = new User(
            Username = 'testusercontactcen@bloomholding.com',
            Alias = 'tuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Asia/Dubai',
            ProfileId = p.Id
        );
        insert u;
        
        System.runAs(u) {
            Lead testLead = new Lead(); 
            testLead.LastName = 'Test Lead';
            testLead.MobileCountryCode__c = '971';
            testLead.Status = 'New';
            testLead.MobilePhone = '9876543211';
            testLead.Email = 'test@gmail.com';
            testLead.Lead_Channel__c = 'Call';
            testLead.LeadSource = 'Social Media'; // Using a LeadSource other than 'Broker Portal'
            testLead.leadsubsource__c='Instagram';
            insert testLead;
            
            
            
            Lead objLead = [SELECT Id FROM Lead];
            Task t = new Task(
                        Subject = 'LO - Day 1 Call 1 - Follow Up', 
                        ActivityDate = Date.today().addDays(-1),
                		WhoId = objLead.Id
                    );
            insert t;
            objLead.LeadManagerStatus__c = 'Follow Up';
            objLead.FollowUpDate__c = Date.Today().addDays(10);
            objLead.FollowUpBy__c = u.Id;
            objLead.FollowUpRemarks__c = 'Test';
            update objLead;
            
            Lead objLead1 = [SELECT Id FROM Lead];
            objLead1.LeadManagerStatus__c = 'Waiting List';
            objLead1.WaitingListDate__c = Date.Today().addDays(10);
            objLead1.WaitingListBy__c = u.Id;
            objLead1.WaitingListRemarks__c = 'Test';
            update objLead1;
        }
    }
    
    @isTest
    static void testUseCase4(){
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Contact Centre Team' LIMIT 1];
        User u = new User(
            Username = 'testusercontactcen@bloomholding.com',
            Alias = 'tuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Asia/Dubai',
            ProfileId = p.Id
        );
        insert u;
        
        System.runAs(u) {
            Lead testLead = new Lead(); 
            testLead.LastName = 'Test Lead';
            testLead.MobileCountryCode__c = '971';
            testLead.Status = 'New';
            testLead.MobilePhone = '9876543211';
            testLead.Email = 'test@gmail.com';
            testLead.Lead_Channel__c = 'Call';
            testLead.LeadSource = 'Social Media'; // Using a LeadSource other than 'Broker Portal'
            testLead.leadsubsource__c='Instagram';
            insert testLead;
            
            
            
            Lead objLead = [SELECT Id FROM Lead];
            Task t = new Task(
                        Subject = 'LO - Day 1 Call 1 - Follow Up', 
                        ActivityDate = Date.today().addDays(-1),
                		WhoId = objLead.Id
                    );
            insert t;
            Task objTask = [SELECT ID FROM Task WHERE Subject = 'LO - Day 1 Call 1 - Follow Up' AND WhoId =: objLead.Id LIMIT 1];
            objTask.Status = 'Completed';
            update objTask;
            objLead.LeadManagerStatus__c = 'Follow Up';
            objLead.FollowUpDate__c = Date.Today().addDays(10);
            objLead.FollowUpBy__c = u.Id;
            objLead.FollowUpRemarks__c = 'Test';
            update objLead;
        }
    }
    
    @isTest
    static void testUseCase5(){
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Contact Centre Team' LIMIT 1];
        User u = new User(
            Username = 'testusercontactcen@bloomholding.com',
            Alias = 'tuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Asia/Dubai',
            ProfileId = p.Id
        );
        insert u;
        
        System.runAs(u) {
            Lead testLead = new Lead(); 
            testLead.LastName = 'Test Lead';
            testLead.MobileCountryCode__c = '971';
            testLead.Status = 'New';
            testLead.MobilePhone = '9876543211';
            testLead.Email = 'test@gmail.com'; 
            testLead.Lead_Channel__c = 'Call';
            testLead.LeadSource = 'Social Media'; // Using a LeadSource other than 'Broker Portal'
            testLead.leadsubsource__c='Instagram';
            insert testLead;
            
            Lead objLead = [SELECT Id FROM Lead];
            objLead.LeadManagerStatus__c = 'Follow Up';
            objLead.FollowUpDate__c = Date.Today().addDays(10);
            objLead.FollowUpBy__c = u.Id;
            objLead.FollowUpRemarks__c = 'Test';
            objLead.LeadManagerStatus__c = 'Waiting List';
            objLead.LeadTeam__c = 'Leasing';
            update objLead;
        }
    }
}