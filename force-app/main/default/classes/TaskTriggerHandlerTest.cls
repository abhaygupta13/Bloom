@istest
public class TaskTriggerHandlerTest {
    @istest
    static void Testmethod1(){
        Lead lead = new Lead(
            LastName = 'Test Lead',
            Status = 'New',
            MobileCountryCode__c = '971',
            MobilePhone = '37829292020',
            Email = 'testlead@example.com',
            Lead_Channel__c = 'Call'
        );
        insert lead;
        
        Task task = new Task(
            Status = 'Completed',
            Not_Contactable__c = true,
            Count__c = 1,
            Description = 'Not Contactable',
            WhoId = lead.Id,
            Subject = 'Task',
            ActivityDate = Date.today()
        );
        insert task;
        
        Map<Id, Task> newTask = new Map<Id, Task>();
        newTask.put(task.Id, task);
        
      
    }
    @istest
    static void Testmethod2(){
        Lead lead = new Lead(
            LastName = 'Test Lead',
            Status = 'New',
            MobileCountryCode__c = '971',
            MobilePhone = '37829292020',
            Email = 'testlead@example.com',
            Lead_Channel__c = 'Call'
        );
        insert lead;
        
        Task task = new Task(
            Status = 'Completed',
            Not_Contactable__c = true,
            Count__c = 2,
            Description = 'Not Contactable',
            WhoId = lead.Id,
            Subject = 'Task',
            ActivityDate = Date.today()
        );
        insert task;
    }
    @istest
    static void Testmethod3(){
        Lead lead = new Lead(
            LastName = 'Test Lead',
            Status = 'New',
            MobileCountryCode__c = '971',
            MobilePhone = '37829292020',
            Email = 'testlead@example.com',
            Lead_Channel__c = 'Call'
        );
        insert lead;
        
        Task task = new Task(
            Status = 'Completed',
            Not_Contactable__c = true,
            Count__c = 3,
            Description = 'Not Contactable',
            WhoId = lead.Id,
            Subject = 'Task',
            ActivityDate = Date.today()
        );
        insert task;
        
        
    }
    @istest
    static void Testmethod4(){
        Lead lead = new Lead(
            LastName = 'Test Lead',
            Status = 'New',
            MobileCountryCode__c = '971',
            MobilePhone = '37829292020',
            Email = 'testlead@example.com',
            Lead_Channel__c = 'Call'
        );
        insert lead;
        
        Task task = new Task(
            Status = 'Completed',
            Not_Contactable__c = true,
            Count__c = 4,
            Description = 'Not Contactable',
            WhoId = lead.Id,
            Subject = 'Task',
            ActivityDate = Date.today()
        );
        insert task;
        
      
        
    }
    @istest
    static void Testmethod5(){
        Lead lead = new Lead(
            LastName = 'Test Lead',
            Status = 'New',
            MobileCountryCode__c = '971',
            MobilePhone = '37829292020',
            Email = 'testlead@example.com',
            Lead_Channel__c = 'Call'
        );
        insert lead;
        
        Task task = new Task(
            Status = 'Completed',
            Not_Contactable__c = true,
            Count__c = 5,
            Description = 'Not Contactable',
            WhoId = lead.Id,
            Subject = 'Task',
            ActivityDate = Date.today()
        );
        insert task;
        
       
        
    }
    @istest
    static void Testmethod6(){
        List<Task> Tlist = new List<Task>();
        Lead lead = new Lead(
            LastName = 'Test Lead',
            Status = 'New',
            MobileCountryCode__c = '971',
            MobilePhone = '37829292020',
            Email = 'testlead@example.com',
            Lead_Channel__c = 'Call'
        );
        insert lead;
        
        Task task = new Task(
            Status = 'Completed',
            Not_Contactable__c = true,
            Count__c = 5,
            Description = 'Not Contactable',
            WhoId = lead.Id,
            Subject = 'Task',
            ActivityDate = Date.today()
        );
        insert task;
        
        task.Subject ='task update';
        update task;
        
        Tlist.add(task);
        
        Test.startTest();
        
        TaskTriggerHelper.updatLeadStatusOnTaskComplete(Tlist);
        delete task;
        
        Test.stopTest();
        
    }
    @istest
    static void Testmethod7(){
        Lead lead = new Lead(
            LastName = 'Test Lead',
            Status = 'Qualified',
            MobileCountryCode__c = '971',
            MobilePhone = '378292920202',
            Email = 'testlead1@example.com',
            Lead_Channel__c = 'Call',
            LeadSource = 'Event',
            //leadsubsource__c = 'Instagram',
            RecordTypeId = '012J7000000L3cmIAC',
            BuyRent__c = 'Buy',
            PropertyUsage__c = 'Residential Sale',
            CustomerBudget__c = '300k-650K',
            NumberOfBedrooms__c = '1BHK',
            UnitType__c = 'Apartment',
            Project__c = 'Bloom Living'
        );
        insert lead;
        
        Task task = new Task(
            Status = 'Completed',
            Not_Contactable__c = true,
            Count__c = 1,
            Description = 'Not Contactable',
            WhoId = lead.Id,
            Subject = 'Task',
            ActivityDate = Date.today()
        );
        insert task;
        
        
        
    }
    @istest
    static void Testmethod8(){
        Lead lead = new Lead(
            LastName = 'Test Lead',
            Status = 'Qualified',
            MobileCountryCode__c = '971',
            MobilePhone = '378292920206',
            Email = 'testlead8@example.com',
            Lead_Channel__c = 'Call',
            LeadSource = 'Event',
            //leadsubsource__c = 'Office',
            RecordTypeId = '012J7000000L3cmIAC',
            BuyRent__c = 'Buy',
            PropertyUsage__c = 'Residential Sale',
            CustomerBudget__c = '300k-650K',
            NumberOfBedrooms__c = '1BHK',
            UnitType__c = 'Apartment',
            Project__c = 'Bloom Living'
        );
        insert lead;
        
        Task task = new Task(
            Status = 'Completed',
            Not_Contactable__c = true,
            Count__c = 2,
            Description = 'Not Contactable',
            WhoId = lead.Id,
            Subject = 'Task',
            ActivityDate = Date.today()
        );
        insert task;
        
        Map<Id, Task> newTask = new Map<Id, Task>();
        newTask.put(task.Id, task);
        
        Test.startTest();
     //   TaskTriggerHelper.taskCreationOnLeadConversion(newTask);
        Test.stopTest();
        
    }
    @istest
    static void Testmethod11(){
        Lead lead = new Lead(
            LastName = 'Test Lead',
            Status = 'Qualified',
            MobileCountryCode__c = '971',
            MobilePhone = '3782929202012',
            Email = 'testlead12@example.com',
            Lead_Channel__c = 'Call',
            LeadSource = 'Event',
            //leadsubsource__c = 'Office',
            RecordTypeId = '012J7000000L3cmIAC',
            BuyRent__c = 'Buy',
            PropertyUsage__c = 'Residential Sale',
            CustomerBudget__c = '300k-650K',
            NumberOfBedrooms__c = '1BHK',
            UnitType__c = 'Apartment',
            Project__c = 'Bloom Living'
        );
        insert lead;
        
        Task task = new Task(
            Status = 'Completed',
            Not_Contactable__c = true,
            Count__c = 5,
            Description = 'Not Contactable',
            WhoId = lead.Id,
            Subject = 'Task',
            ActivityDate = Date.today()
        );
        insert task;
        
    }
    @isTest
    public static void Testmethod12(){
         Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Post_Sale_Payment_Deferral').getRecordTypeId();
        // Create Contact with Email
        Contact testContact = new Contact(
            LastName = 'Test Contact',
            Email = 'sonali.sengar@infobeans.com'
        );
        insert testContact;
        
        Case testCase2 = new Case(
            CurrencyIsoCode = 'AED',
            Origin = 'Email',
            RecordTypeId = caseRecordTypeId,
            CaseType__c = 'Service Request',
            ContactId = testContact.id,
            RequesterContactNumber__c='533353',
            RequesterEmail__c ='abc@gmail.com',
            Step__c = '2'
            
        );
        insert testCase2;
        Task crmTask = new Task(
            Status = 'Completed', 
            Type__c = 'Post Sale Payment Deferral',
            SubType__c = 'CRM Team Task',
            WhatId = testCase2.id
        );
        insert crmTask;
    } 
    
    
}