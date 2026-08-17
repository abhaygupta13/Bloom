@isTest
public class EventTriggerTest {
    
    @testSetup
    static void setup() {
        Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('PersonAccount');
        Account acc = new Account();
        acc.LastName = 'Test Acc';
        acc.RecordTypeId = recordTypeInfo.getRecordTypeId();
        acc.PersonEmail = 'test@gmail.com';
        insert acc;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = acc.Id;
        opp.LeadChannel__c = 'Call';
        opp.LeadSource = 'Event';
        opp.LeadSubSource__c = 'Sales Launch';
        opp.StageName = 'New';
        opp.WinReason__c = 'Price';
        opp.CloseDate = Date.today();
        insert opp;
        
        SalesOrder__c sc = new SalesOrder__c();
        sc.Name ='Test sales order';
        sc.Account__c = acc.Id;
        insert sc;
        
        SalesOrder__c sc1 = new SalesOrder__c();
        sc1.Name ='Test sales order 2';
        sc1.Account__c = acc.Id;
        insert sc1;
        
        Project__c pr = new Project__c();
        pr.Name = 'testProject';        
        insert pr;
        
        BuildingSection__c bld = new BuildingSection__c();
        bld.Name = 'testBuilding';
        bld.BuildingSectionCode__c = '1234567890';
        bld.Project__c = pr.Id; 
        insert bld; 
        
        Unit__c unit = new Unit__c();
        unit.Name = 'Unit001';
        unit.SAP_Unit_Number__c = '123';
        unit.RelatedOpportunity__c = opp.Id;
        unit.Active_Sales_Order__c = sc.Id;
        unit.RelatedSalesOrder__c = sc.Id;
        unit.BuildingSectionName__c = bld.Id;
        insert unit;
        
         Unit__c unit2 = new Unit__c();
        unit2.Name = 'Unit002';
        unit2.SAP_Unit_Number__c = '124';
        unit2.RelatedOpportunity__c = opp.Id;
        unit2.Active_Sales_Order__c = sc1.Id;
        unit2.RelatedSalesOrder__c = sc1.Id;
        unit2.BuildingSectionName__c = bld.Id;
        insert unit2;
        
          User u = new User();
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
            Profile p = [SELECT Id FROM Profile WHERE Name='HO Agent'];
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Handover_HO_Agent'];
            
            u = new User(FirstName = 'Ho Agent', LastName='User', Alias = 'op', Email='hoagent@bloom.com', EmailEncodingKey='UTF-8',ProfileId = p.Id, 
                         LocaleSidKey = 'en_US', LanguageLocaleKey='en_US', TimeZoneSidKey='America/Los_Angeles', UserName='hoagent@bloom.com.u1');
            insert u;
            
            insert new PermissionSetAssignment(AssigneeId = u.Id,PermissionSetId = ps.Id);
        }
        
        Handover__c ho = new Handover__c();
        ho.Sub_Status__c = 'Created';
        ho.Is_Manual__c = 'Yes';
        ho.unit__c = unit.Id;
        ho.Sales_Order__c = sc.Id;
        ho.Customer_Availability_for_CHO__c = '';
        ho.Is_Notice_of_Completion_Sent__c = false;
        insert ho;
        
        Handover__c ho1 = new Handover__c();
        ho1.Sub_Status__c = HandoverConstants.Handover_Sub_Status_Home_Orientation_Sent;
        ho1.Is_Manual__c = 'Yes';
        ho1.unit__c = unit2.Id;
        ho1.HO_Agent_Assigned_User__c = u.id;
        ho1.Sales_Order__c = sc1.Id;
        ho1.Customer_Availability_for_CHO__c = HandoverConstants.Customer_Available;
        ho1.Is_Notice_of_Completion_Sent__c = false;
        insert ho1;
        
        
    }
    
    @isTest
    static void testValidationWhenCustomerAvailabilityIsBlank() {
        Handover__c handover = [SELECT Id FROM Handover__c WHERE Sub_Status__c = 'Created' LIMIT 1];
        
        Event newEvent = new Event(
            WhatId = handover.Id,
            Subject = 'Test Event',
            StartDateTime = DateTime.now().addDays(1),
            EndDateTime = DateTime.now().addDays(1).addHours(1)
        );
        
        Test.startTest();
        try {
            insert newEvent;
            System.assert(false, 'Expected an exception due to blank Customer Availability.');
        } catch (DmlException e) {
            System.assert(e.getDmlMessage(0).contains(Constants.Select_Customer_Availability), 'Unexpected error message: ' + e.getDmlMessage(0));
        }
        Test.stopTest();
    }
    
    @isTest
    static void testValidationWhenExistingAppointmentAndOrientationScheduled() {
        Handover__c handover = [SELECT Id, Orientation_Appointment_Status__c FROM Handover__c WHERE Sub_Status__c = 'Created' LIMIT 1];
        handover.Customer_Availability_for_CHO__c = Constants.Customer_Available;
        handover.Orientation_Appointment_Status__c = Constants.Orientation_Appointment_Status_Scheduled;
        update handover;
        
        Event existingEvent = new Event(
            WhatId = handover.Id,
            Subject = 'Existing Event',
            StartDateTime = DateTime.now().addDays(-1),
            EndDateTime = DateTime.now().addDays(-1).addHours(1)
        );
        insert existingEvent;
        
        Event newEvent = new Event(
            WhatId = handover.Id,
            Subject = 'New Test Event',
            type = 'Home Orientation Appointment',
            StartDateTime = DateTime.now().addDays(1),
            EndDateTime = DateTime.now().addDays(1).addHours(1)
        );
        
        Test.startTest();
        try {
            insert newEvent;
            System.assert(false, 'Expected an exception due to existing appointment and scheduled orientation.');
        } catch (DmlException e) {
            System.assert(e.getDmlMessage(0).contains(Constants.Delete_Existing_Appointment), 'Unexpected error message: ' + e.getDmlMessage(0));
        }
        Test.stopTest();
    }
    
    @isTest
    static void testNoValidationErrors() {
        Handover__c handover = [SELECT Id, Customer_Availability_for_CHO__c FROM Handover__c WHERE Sub_Status__c = 'Created' LIMIT 1];
        
        handover.Customer_Availability_for_CHO__c = Constants.Customer_Available;
        update handover;
        
        Event newEvent = new Event(
            WhatId = handover.Id,
            Subject = 'Test Event Without Errors',
            StartDateTime = DateTime.now().addDays(1),
            EndDateTime = DateTime.now().addDays(1).addHours(1)
        );
        
        Test.startTest();
        insert newEvent; 
        Test.stopTest();
        
        Event insertedEvent = [SELECT Id FROM Event WHERE WhatId = :handover.Id AND Subject = 'Test Event Without Errors' LIMIT 1];
        System.assertNotEquals(null, insertedEvent);
    }
    @isTest
    static void eventResourceabesence() {
        string orientationstatus = HandoverConstants.Handover_Sub_Status_Home_Orientation_Sent;
        
        Handover__c handover = [SELECT Id, HO_Agent_Assigned_User__c,Customer_Availability_for_CHO__c FROM Handover__c WHERE Sub_Status__c =: orientationstatus LIMIT 1];
       
        ServiceResource res = new ServiceResource();
        res.Name ='Mohamed Al Sallami';
        res.IsActive = true;
        res.RelatedRecordId = handover.HO_Agent_Assigned_User__c;
        insert  res;
        
        handover.Customer_Availability_for_CHO__c = Constants.Customer_Available;
        update handover;
        Event newEvent = new Event(
            WhatId = handover.Id,
            type = 'Home Orientation Appointment',
            Subject = 'Test1',
            StartDateTime = DateTime.now().addDays(1),
            EndDateTime = DateTime.now().addDays(1).addHours(1)
        );
        insert newEvent;
        newEvent.StartDateTime =  DateTime.now().addDays(2);
        newEvent.EndDateTime = DateTime.now().addDays(2).addHours(1);
        update newEvent;
       
        delete [select id, Subject from Event  where Subject='Delete Event'];
    }
     @isTest
    static void testforpendingMehods() {
        Handover__c handover = [SELECT Id, Customer_Availability_for_CHO__c FROM Handover__c WHERE Sub_Status__c = 'Created' LIMIT 1];
        handover.Customer_Availability_for_CHO__c = Constants.Customer_Available;
        update handover;
        Event newEvent = new Event(
            WhatId = handover.Id,
            Subject = 'Test1',
            StartDateTime = DateTime.now().addDays(1),
            EndDateTime = DateTime.now().addDays(1).addHours(1)
        );
        insert newEvent;
        newEvent.Subject = 'Delete Event';
        update newEvent;
        delete [select id, Subject from Event  where Subject='Delete Event'];
    }
}