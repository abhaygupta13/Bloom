@isTest
public class SendEmailInvocableTest {
    @TestSetup
    static void setupTestData() {
        
        Profile profile = [Select Id,Name FROM Profile Where Name ='HO Agent' LIMIT 1];
        User testUser = new User(
            Username = 'testhoagent@gmail.com', // Make sure this is unique in your org
            LastName = 'Test',
            Email = 'testuser@example.com',
            Alias = 'test',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;      
        
        Profile profileCrm = [Select Id,Name FROM Profile Where Name ='CRM Team' LIMIT 1];
        User testCRMUser = new User(
            Username = 'testcrmuser23@gmail.com', // Make sure this is unique in your org
            LastName = 'Test Crm User',
            Email = 'testuser23@example.com',
            Alias = 'testur',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profileCrm.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testCRMUser;  
        
        Profile profileOper = [Select Id,Name FROM Profile Where Name ='Operations Team' LIMIT 1];
        User testOprUser = new User(
            Username = 'testopruser@gmail.com', // Make sure this is unique in your org
            LastName = 'Test Oper User',
            Email = 'testuser263@example.com',
            Alias = 'testurop',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profileOper.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testOprUser;  
        
        Project__c pr = new Project__c();
        pr.Name = 'testProject';        
        insert pr;     
        
        BuildingSection__c bld = new BuildingSection__c();
        bld.Name = 'testBuilding';
        bld.BuildingSectionCode__c = '1234567890';
        bld.Project__c = pr.Id; 
        insert bld;        
        
        Unit__c unt = new Unit__c();
        unt.Name = 'Unit Test A1435';
        unt.Status__c = 'Unassigned';
        unt.HO_Agent__c = testUser.Id;
        unt.BuildingSectionName__c = bld.Id;
        insert unt;
        
         Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('PersonAccount');
        
        Account acc = new Account();
        acc.LastName = 'Test Acc';
        acc.RecordTypeId = recordTypeInfo.getRecordTypeId();
        acc.PersonEmail = 'test@example.com';
        insert acc;
        
        Handover__c hand = new Handover__c();
        hand.Status__c = 'In Progress';
        hand.Unit__c = unt.Id; 
        hand.account__c = acc.id;
        hand.Sub_Status__c ='Home Orientation Sent';
        hand.Is_BCC_Announcement_Sent__c = true;
        hand.Customer_Email__c ='test34@gmail.com';
        hand.HO_Agent_Assigned_User__c = testUser.Id;
        hand.CRM_Team_Assigned_User__c = testCRMUser.Id;
        hand.Operation_Team_Assigned_User__c = testOprUser.Id;
        hand.Customer_Availability_for_CHO__c = 'Customer Available';
        hand.OwnerId = testUser.Id;
        insert hand;
        system.debug('con version');
          
        
    }
    
    @isTest
    public static void sendEmailTest(){  
        List<Id> unitId = new List<Id>();
        Unit__c unt = [Select Id,Name,Status__c from Unit__c where Name ='Unit Test A1435' Limit 1];
        System.debug('unt ' + unt);
        unitId.add(unt.Id);
        Handover__c handover = [SELECT Id,Name,Unit__c, Customer_Email__c,Sub_Status__c,ownerId,Customer_Availability_for_CHO__c FROM Handover__c WHERE Unit__c=:unt.Id LIMIT 1];
        
        
        Event evn = new Event();
        evn.WhatId = handover.Id;
        evn.Subject = 'Other';
        evn.StartDateTime = DateTime.newInstance(2024, 6, 20, 8, 43, 38); 
        evn.EndDateTime = DateTime.newInstance(2024, 6, 22, 8, 43, 38); 
        evn.CurrencyIsoCode ='AED';
        insert evn;
        
        Test.startTest();
        BCCAnnouncementEmailBatch batchJob = new BCCAnnouncementEmailBatch(unitId);
        Database.executeBatch(batchJob);
        BCCAnnouncementEmailBatch.method();
        Test.stopTest();
        
        SendEmailInvocable.EmailRequest sendEmail = new SendEmailInvocable.EmailRequest();
        sendEmail.recordId = handover.Id ;
        sendEmail.templateName = Constants.PAYMENT_Confirmation_Template;
        SendEmailInvocable.sendEmail(new List<SendEmailInvocable.EmailRequest>{sendEmail});
        
       

    }
    @isTest
    public static void sendEmailTest2(){  
        Unit__c unt = [Select Id,Name,Status__c from Unit__c where Name ='Unit Test A1435' Limit 1];
        
        Handover__c handover = [SELECT Id,Name,Unit__c, Customer_Email__c,CustomerEmail__c,Sub_Status__c,ownerId,Customer_Availability_for_CHO__c FROM Handover__c WHERE Unit__c=:unt.Id LIMIT 1];
        SendEmailInvocable.EmailRequest sendEmail = new SendEmailInvocable.EmailRequest();
        sendEmail.recordId = handover.Id ;
        sendEmail.templateName = Constants.Handover_Completion_Customer_Attended;
        SendEmailInvocable.sendEmail(new List<SendEmailInvocable.EmailRequest>{sendEmail});
    }
     @isTest
    public static void sendEmailTest3(){  
        Unit__c unt = [Select Id,Name,Status__c from Unit__c where Name ='Unit Test A1435' Limit 1];
        
        Handover__c handover = [SELECT Id,Name,Unit__c, Customer_Email__c,CustomerEmail__c,Sub_Status__c,ownerId,Customer_Availability_for_CHO__c FROM Handover__c WHERE Unit__c=:unt.Id LIMIT 1];
        SendEmailInvocable.EmailRequest sendEmail = new SendEmailInvocable.EmailRequest();
        sendEmail.recordId = handover.Id ;
        sendEmail.templateName = Constants.Handover_Congratulation_Email_Template;
        SendEmailInvocable.sendEmail(new List<SendEmailInvocable.EmailRequest>{sendEmail});
        
    }
     @isTest
    public static void sendEmailTest4(){  
        Unit__c unt = [Select Id,Name,Status__c from Unit__c where Name ='Unit Test A1435' Limit 1];
        
        Handover__c handover = [SELECT Id,Name,Unit__c, Customer_Email__c,CustomerEmail__c,Sub_Status__c,ownerId,Customer_Availability_for_CHO__c FROM Handover__c WHERE Unit__c=:unt.Id LIMIT 1];
        SendEmailInvocable.EmailRequest sendEmail = new SendEmailInvocable.EmailRequest();
        sendEmail.recordId = handover.Id ;
        sendEmail.templateName = Constants.KHO_Appointment_Scheduled_Template;
        SendEmailInvocable.sendEmail(new List<SendEmailInvocable.EmailRequest>{sendEmail});
        
    }
     @isTest
    public static void sendEmailTest5(){  
        Unit__c unt = [Select Id,Name,Status__c from Unit__c where Name ='Unit Test A1435' Limit 1];
        
        Handover__c handover = [SELECT Id,Name,Unit__c, Customer_Email__c,CustomerEmail__c,Sub_Status__c,ownerId,Customer_Availability_for_CHO__c FROM Handover__c WHERE Unit__c=:unt.Id LIMIT 1];
        SendEmailInvocable.EmailRequest sendEmail = new SendEmailInvocable.EmailRequest();
        sendEmail.recordId = handover.Id ;
        sendEmail.templateName = Constants.Title_Deed_Registration;
        SendEmailInvocable.sendEmail(new List<SendEmailInvocable.EmailRequest>{sendEmail});
    }
    
}