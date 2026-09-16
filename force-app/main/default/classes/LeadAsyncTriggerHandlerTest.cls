@isTest
public class LeadAsyncTriggerHandlerTest {

    @isTest
    static void TestMethod1(){
        Test.enableChangeDataCapture();
        List<Lead> Llist = new List<Lead>();
        Lead l = new Lead();
        l.LastName = 'Testclass';
        l.MobileCountryCode__c = '971';
        l.Status = 'New';
        l.MobilePhone = '37829292020';
        l.Email = 'Testclass@gmail.com';
        Llist.add(l);
        insert Llist;
        
        update l;
        Test.getEventBus().deliver();
        
        // Delete the record
        Test.enableChangeDataCapture();
        delete l;
        Test.getEventBus().deliver();
        
        // UnDelete the record
        Test.enableChangeDataCapture();
        undelete l;
        Test.getEventBus().deliver();
        
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        AssignmentRule__c assr = new AssignmentRule__c();
        assr.RecordType__c = 'Lead';
        assr.ProcessName__c = 'Digital Lead Assignment';
        assr.IsActive__c = true;
        insert assr;
        
        Time startime = Time.newInstance(9, 30, 0, 0);
        Time Endtime = Time.newInstance(20, 30, 0, 0);
        AssignmentUser__c assru = new AssignmentUser__c();
        assru.IsActive__c = true;
        assru.AssignmentDays__c = 'Monday;Tuesday;Wednesday';
        assru.MondayStartTime__c = startime;
        assru.MondayEndTime__c = Endtime;
        assru.TuesdayStartTime__c  = startime;
        assru.TuesdayEndTime__c = Endtime;
        assru.AssignmentRule__c = assr.Id;
        assru.User__c = adminUser.Id;
        assru.MaximumCapacity__c = 100;
        insert assru;
        
        LeadChangeEvent event = new LeadChangeEvent();
        EventBus.ChangeEventHeader header = new EventBus.ChangeEventHeader();
        header.changeType = 'CREATE';
        event.ChangeEventHeader = header;
        
        EventBus.ChangeEventHeader header2 = new EventBus.ChangeEventHeader();
        header2.changeType = 'UPDATE';
        event.ChangeEventHeader = header2;
        
        EventBus.ChangeEventHeader header3 = new EventBus.ChangeEventHeader();
        header3.changeType = 'DELETE';
        event.ChangeEventHeader = header3;
        
        EventBus.ChangeEventHeader header4 = new EventBus.ChangeEventHeader();
        header4.changeType = 'UNDELETE';
        event.ChangeEventHeader = header4;
        
        Test.startTest();
        LeadAsyncTriggerHandler ias = new LeadAsyncTriggerHandler(); 
        ias.isDisabled();
        AsyncTriggerDispatcher.disableAllAsyncTriggers();
        AsyncTriggerDispatcher.enableAllAsyncTriggers();
        Test.stopTest();
    }
    
    @isTest
    static void testLeadEmailNotification(){
        Map<String, Id> profileMap = new Map<String, Id>();
        for(Profile p : [SELECT Id, Name FROM Profile WHERE Name IN ('Reception Team', 'Sales Manager', 'Contact Centre Team')]){
            profileMap.put(p.Name, p.Id);
        }
        
        String uniqueKey = String.valueOf(System.currentTimeMillis());
        
        // Create Broker Agency Account & Broker Contact
        Id agencyRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Broker_Agency') != null 
            ? Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Broker_Agency').getRecordTypeId() 
            : null;
        Account brokerAgency = new Account(Name = 'Test Agency ' + uniqueKey);
        if(agencyRtId != null){
            brokerAgency.RecordTypeId = agencyRtId;
        }
        TriggerDispatcher.disableAllTriggers();
        insert brokerAgency;
        
        Id brokerContactRtId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Broker') != null 
            ? Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Broker').getRecordTypeId() 
            : null;
        Contact brokerAgent = new Contact(LastName = 'Agent ' + uniqueKey, AccountId = brokerAgency.Id);
        if(brokerContactRtId != null){
            brokerAgent.RecordTypeId = brokerContactRtId;
        }
        insert brokerAgent;
        TriggerDispatcher.enableAllTriggers();

        List<Lead> leadsToInsert = new List<Lead>();
        
        // 1. Normal Lead (falls to default template)
        Lead normalLead = new Lead(
            LastName = 'Normal Lead',
            Status = 'New',
            MobileCountryCode__c = '971',
            MobilePhone = '971501111111',
            Email = 'normal@test.com',
            Lead_Channel__c = 'Walk in'
        );
        leadsToInsert.add(normalLead);
        
        // 2. Broker Portal Lead (skips default template)
        Lead brokerPortalLead = new Lead(
            LastName = 'Broker Portal Lead',
            Status = 'New',
            MobileCountryCode__c = '971',
            MobilePhone = '971502222222',
            Email = 'broker@test.com',
            Lead_Channel__c = 'Broker Portal'
        );
        leadsToInsert.add(brokerPortalLead);
        
        insert leadsToInsert;
        
        List<Id> leadIds = new List<Id>{ normalLead.Id, brokerPortalLead.Id };
        
        // 3. Reception Team User Leads (with broker and without broker)
        if(profileMap.containsKey('Reception Team')){
            User recUser = new User(
                FirstName = 'Rec', LastName = 'User', Email = 'rec@test.com',
                Username = 'rec' + uniqueKey + '@test.com', Alias = 'recu',
                TimeZoneSidKey = 'Asia/Dubai', LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US', ProfileId = profileMap.get('Reception Team')
            );
            System.runAs(recUser){
                Lead recLeadWithBroker = new Lead(
                    LastName = 'Rec Lead Broker', Status = 'New', 
                    MobileCountryCode__c = '971', MobilePhone = '971503333331', 
                    Email = 'rec1@test.com',
                    BrokerAgency__c = brokerAgency.Id, BrokerAgent__c = brokerAgent.Id
                );
                Lead recLeadWithoutBroker = new Lead(
                    LastName = 'Rec Lead No Broker', Status = 'New', 
                    MobileCountryCode__c = '971', MobilePhone = '971503333332', 
                    Email = 'rec2@test.com'
                );
                insert new List<Lead>{ recLeadWithBroker, recLeadWithoutBroker };
                leadIds.add(recLeadWithBroker.Id);
                leadIds.add(recLeadWithoutBroker.Id);
            }
        }
        
        // 4. Sales Manager User Leads (with broker and without broker)
        if(profileMap.containsKey('Sales Manager')){
            User smUser = new User(
                FirstName = 'SM', LastName = 'User', Email = 'sm@test.com',
                Username = 'sm' + uniqueKey + '@test.com', Alias = 'smu',
                TimeZoneSidKey = 'Asia/Dubai', LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US', ProfileId = profileMap.get('Sales Manager')
            );
            System.runAs(smUser){
                Lead smLeadWithBroker = new Lead(
                    LastName = 'SM Lead Broker', Status = 'New', 
                    MobileCountryCode__c = '971', MobilePhone = '971504444441', 
                    Email = 'sm1@test.com',
                    BrokerAgency__c = brokerAgency.Id, BrokerAgent__c = brokerAgent.Id
                );
                Lead smLeadWithoutBroker = new Lead(
                    LastName = 'SM Lead No Broker', Status = 'New', 
                    MobileCountryCode__c = '971', MobilePhone = '971504444442', 
                    Email = 'sm2@test.com'
                );
                //insert new List<Lead>{ smLeadWithBroker, smLeadWithoutBroker };
                leadIds.add(smLeadWithBroker.Id);
                leadIds.add(smLeadWithoutBroker.Id);
            }
        }
        
        // 5. Contact Centre Team User Leads (Sales and Leasing)
        if(profileMap.containsKey('Contact Centre Team')){
            User ccUser = new User(
                FirstName = 'CC', LastName = 'User', Email = 'cc@test.com',
                Username = 'cc' + uniqueKey + '@test.com', Alias = 'ccu',
                TimeZoneSidKey = 'Asia/Dubai', LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US', ProfileId = profileMap.get('Contact Centre Team')
            );
            System.runAs(ccUser){
                Lead ccSales = new Lead(
                    LastName = 'CC Sales', Status = 'New', 
                    MobileCountryCode__c = '971', MobilePhone = '971505555551', 
                    Email = 'cc1@test.com', LeadTeam__c = 'Sales'
                );
                Lead ccLeasing = new Lead(
                    LastName = 'CC Leasing', Status = 'New', 
                    MobileCountryCode__c = '971', MobilePhone = '971505555552', 
                    Email = 'cc2@test.com', LeadTeam__c = 'Leasing'
                );
                insert new List<Lead>{ ccSales, ccLeasing };
                leadIds.add(ccSales.Id);
                leadIds.add(ccLeasing.Id);
            }
        }
        
        Test.startTest();
        try {
            LeadAsyncTriggerHelper.leadEmailNotificationToCustomer(leadIds);
        } catch(Exception ex) {
            System.debug('Exception in testLeadEmailNotification: ' + ex.getMessage());
        }
        Test.stopTest();
    }
}