@isTest
public class ActivityServiceTest {
    
    @testSetup
    static void setupTestData() {
        // Create test Account and Contact as WhatId-related objects for the Event
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
         // Create Contact with Email
        Contact testContact = new Contact(
            LastName = 'Test Contact',
            Email = 'sonali.sengar@test.com'
        );
        insert testContact;
        
         Project__c project = new Project__c(
            Name = 'Test Project',
            Office_Location__c = 'Test Location',
            isHandoverAvailable__c=true
        );
        insert project;
        
       //   EmailTemplate emailTemplate  = TestDataFactory.createEmailTemplate('templateName');
       //     insert emailTemplate;
        
       
        // Create a Unit
        Unit__c unit = new Unit__c(
            Name = 'Unit Test A1435',
            SAP_Unit_Number__c = 'SAP12345',
            Project__c= project.id,
            Status__c = 'Available'
           
        );
        insert unit;
         
       
        
        
        SalesOrder__c sc = new SalesOrder__c();
        sc.Name ='Test sales order';
        sc.Unit__c = unit.Id;
        sc.Account__c = testAccount.Id;
        insert sc;
        
        
        unit.Active_Sales_Order__c = sc.Id;
        unit.RelatedSalesOrder__c = sc.Id;
        update unit;
        
        Profile profileCRM = [SELECT Id FROM Profile WHERE Name = 'CRM Operations'];
        
        User userRecord = new User(
            Alias = 'zaki',
            Email = 'zakial@gmail.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Zaki Al Bakri',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profileCRM.Id,
            TimeZoneSidKey = 'Asia/Dubai',
            UserName = 'zaki.al.bakri@example.com'
        );
        insert userRecord;
        
         ServiceCatalog__c  servicecatalog = new ServiceCatalog__c();
        servicecatalog.ProcessFlowType__c= 'Handover';
        servicecatalog.ProcessType__c = 'Sales';
        servicecatalog.Active__c= true;
        servicecatalog.RecordTypeDevName__c = 'Non PHPP';
        insert servicecatalog;
        
        
        // Create a Handover record
        Handover__c handover1 = new Handover__c(
            Name = 'Test Handover',
            Customer_Email__c = 'test@example.com',
            ServiceCatalog__c = servicecatalog.Id,
            Is_Orientation_Letter_Sent__c = false,
            Is_BCC_Announcement_Sent__c =false,
            Unit__c = unit.Id,
           
            Project__c = project.Id,
            Customer_Availability_for_CHO__c = 'Customer Available',
            Unit_is_Ready__c=false,
            UnitCategory__c='Registered Unit',
            Is_Notice_of_Completion_Sent__c=false,
          
            Sub_Status__c= 'QA Snagging'
        );
        insert handover1;
       
        
        // Create test Events related to the test Account
        Event event1 = new Event(
            WhatId = testAccount.Id,
            Subject = 'Test Event 1',
            StartDateTime = DateTime.now(),
            EndDateTime = DateTime.now().addHours(2)
        );
        Event event2 = new Event(
            WhatId = testAccount.Id,
            Subject = 'Test Event 2',
            StartDateTime = DateTime.now().addDays(1),
            EndDateTime = DateTime.now().addDays(1).addHours(2)
        );
        insert new List<Event>{ event1, event2 };
            
            Lead testLead = TestDataFactory.createLead('Test', '9843216782', 'test@gmail.com');
        insert testLead;
        
        
        Task testTask = new Task(
            Subject = 'Day 1 Call 1 - Follow Up',
            Status = 'Open',
            OwnerId = UserInfo.getUserId(),
            WhoId = testLead.Id
        );
        insert testTask;
        
         Task HandovertestTask = new Task(
            Subject = 'Day 1 Call 1 - Follow Up',
            Status = 'Open',
            OwnerId = UserInfo.getUserId(),
            WhatId = handover1.Id
        );
        insert HandovertestTask;

        Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Post_Sale_Payment_Deferral').getRecordTypeId();
        SalesOrder__c testSalesOrder1 = new SalesOrder__c(
            Name = 'Test Sales Order1',
            Status__c = 'Sold',
            //Offer__c = testOfferPromotion.Id,
            Account__c = testAccount.Id,
            IsDefaulted__c = true
        );
        insert testSalesOrder1;
        // Create test ServiceCatalog record
        ServiceCatalog__c testServiceCatalog = new ServiceCatalog__c(
            Name = 'Test Service Catalog',
            Type__c = 'Service Request',
            Category__c = 'Financial - Payment Service',
            SubCategory__c = 'Postpone/Defer payment',
            RecordTypeDevName__c = 'Post_Sale_Payment_Deferral'
        );
        insert testServiceCatalog;        
        Case testCase = new Case(
            CurrencyIsoCode = 'AED',
            Origin = 'Walk-In',
            RecordTypeId = caseRecordTypeId,
            Sales_Order__c = testSalesOrder1.Id,
            CaseType__c = 'Service Request',
            ServiceCatalog__c = testServiceCatalog.Id,
            Case_Contact_Name__c = testContact.Id,
            ContactId = testContact.Id
        );
        insert testCase;
        // Create test ServiceAction record
        ServiceAction__c testServiceAction = new ServiceAction__c(
            ServiceCatalog__c = testServiceCatalog.Id,
            TaskType__c = 'Post Sale Payment Deferral',
            TaskSubType__c = 'CRM Team Task',
            TaskSubject__c = 'Test Task Subject',
            Department__c ='CRM',
            Due_in_days__c = 2,
            Order__c = 1
        );
        insert testServiceAction;
    }
    
    @isTest
    static void testGetEventByWhatId() {
        // Get the test Account ID
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Lead objlead = [SELECT Id FROM Lead LIMIT 1];
        Handover__c handover = [Select id from Handover__c limit 1];
         ServiceAction__c ServiceAction = [Select id,TaskSubType__c from ServiceAction__c limit 1];
        Set<Id> setLeadId = new Set<Id>{objLead.Id};
            Task objTask = [SELECT ID,WhoId FROM Task WHERE WhoId =: objlead.Id];
        Set<Id> setTaskId = new Set<Id>{objTask.Id};
            
            Task testTask = new Task(
                Subject = 'Day 1 Call 1 - Follow Up',
                Status = 'Open',
                OwnerId = UserInfo.getUserId(),
                WhoId = objlead.Id
            );
        List<Task> lstTask = new List<Task>{testTask};
            // Call the method to get events by WhatId
            Test.startTest();
        ActivityService service = ActivityService.getInstance();
        List<Event> events = service.getEventByWhatId(new Set<Id>{ testAccount.Id });
        Event event1 = new Event(
            WhatId = testAccount.Id,
            Subject = 'Test Event 1',
            StartDateTime = DateTime.now(),
            EndDateTime = DateTime.now().addHours(2)
        );
        List<Event> lstEvent = new List<Event>{event1};
        service.getTasksByWhoIds(setleadId);
        service.getTasksById(objTask.Id);
        service.getTasksByIds(setTaskId);
        service.updateTask(objTask);
        service.insertTasks(lstTask);
        //service.insertTasksWithoutTrigger(lstTask);
        service.upsertTasks(lstTask);
        service.getTasksBySubjectAndWhoId(setleadId,'Test');
        service.insertEvents(lstEvent);
         service.fetchCompletedTaskFromServiceAction(ServiceAction,ServiceAction.Id);
         service.updateTasks(lstTask);
         service.upsertTasksWithoutTrigger(lstTask);
        Test.stopTest();
    }
    
    @isTest
    static void testDeleteEvents() {
        // Query test Events
        List<Event> events = [SELECT Id FROM Event LIMIT 2];
        
        // Call the method to delete the events
        Test.startTest();
        ActivityService service = ActivityService.getInstance();
        service.deleteEvents(events);
        Test.stopTest();
        
        // Verify that the events were deleted
        Integer eventCount = [SELECT COUNT() FROM Event WHERE Id IN :events];
        System.assertEquals(0, eventCount, 'All events should have been deleted.');
    }
    
    @isTest
    static void testInsertEvents() {
        // Get the test Account ID for WhatId
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        // Create new Event records
        List<Event> newEvents = new List<Event>{
            new Event(
                WhatId = testAccount.Id,
                Subject = 'Inserted Event 1',
                StartDateTime = DateTime.now().addDays(2),
                EndDateTime = DateTime.now().addDays(2).addHours(2)
            ),
                new Event(
                    WhatId = testAccount.Id,
                    Subject = 'Inserted Event 2',
                    StartDateTime = DateTime.now().addDays(3),
                    EndDateTime = DateTime.now().addDays(3).addHours(2)
                )
                };
                    
                    // Call the method to insert events
                    Test.startTest();
        ActivityService service = ActivityService.getInstance();
        List<Event> insertedEvents = service.insertEvents(newEvents);
        Test.stopTest();
        
        // Verify that the events were inserted and have valid IDs
        System.assertEquals(2, insertedEvents.size(), 'There should be 2 inserted events.');
        for (Event evt : insertedEvents) {
            System.assertNotEquals(null, evt.Id, 'The inserted event should have an ID.');
        }
    }
    
    
    @isTest
    static void testgetOpenTasksBywhatIds() {
     Case caseObj = [SELECT Id, Status FROM Case LIMIT 1];
     Id caseId = caseObj.id;
        
        
           Task crmTask = new Task(
            Status = 'Completed', 
            Type__c = 'Post Sale Payment Deferral',
            SubType__c = 'CRM Team Task',
            WhatId = caseId
        );
        insert crmTask;
         Task financeTask = new Task(
            Status = 'Open', 
            Type__c = 'Post Sale Payment Deferral',
            SubType__c = 'Finance Team Task',
            WhatId = caseId
        );
       
      
        
     ServiceAction__c sa = [Select id,TaskSubject__c,Order__c,FinalTask__c,TaskType__c,TaskSubType__c from ServiceAction__c];
        
        Id defaultBHId = MetadataService.getInstance().getAppSettingTextValue('DefaultBusinessHoursId');
        Date nextBusinessDate = BusinessHoursService.getInstance().getNextBusinessDate(defaultBHId,System.now());
        Date nextDate = Date.today().addDays(1);
        String subject = 'CC';
        Date dueDate; 
     // Call method under test
        Test.startTest();
        ActivityService.getInstance().getOpenTasksBywhatIds(new Set<Id>{caseId});
        ActivityService.getInstance().createTaskFromServiceAction(sa);
        ActivityService.getInstance().fetchTaskFromServiceAction(sa,String.valueOf(caseId));
        ActivityService.getInstance().fetchOpenTaskFromServiceAction(sa,String.valueOf(caseId));
        ActivityService.getInstance().fetchOpenTaskByCaseList(new List<Case>{caseObj});
        ActivityService.getInstance().closeTasks(new List<Task>{crmTask} );
        ActivityService.getInstance().insertTasksWithoutTrigger(new List<Task>{financeTask} );
        ActivityService.getInstance().getActivity(subject,System.today(),nextBusinessDate,'test','Open', 'type', 'low', 1,null, caseObj.id);
         ActivityService.getInstance().getActivityWithSLA(subject,System.today(),nextBusinessDate,'test','Open', 'type', 'low', 1,null, caseObj.id,null,null,null);
        
        
        Test.stopTest();
        
    }
    @isTest
static void testFetchLatestAndOpenTaskForCase() {

    Account acc = [SELECT Id FROM Account LIMIT 1];
    Contact con = [SELECT Id FROM Contact LIMIT 1];
    User usr = [SELECT Id FROM User LIMIT 1];
    SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
    ServiceCatalog__c sc = [SELECT Id FROM ServiceCatalog__c LIMIT 1];

    Id rtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                    .get('Post_Sale_Payment_Deferral')
                    .getRecordTypeId();

    Case caseObj = new Case(
        RecordTypeId = rtId,
        Origin = 'Walk-In',
        Status = 'New',
        CaseType__c = 'Service Request',
        ContactId = con.Id,
        Case_Contact_Name__c = con.Id,
        AccountId = acc.Id,
        Sales_Order__c = so.Id,
        ServiceCatalog__c = sc.Id,
        OwnerId = usr.Id
    );

    // Insert Case without trigger
    CaseService.getInstance().insertCaseWithoutTrigger(
        new List<Case>{ caseObj }
    );

    Task openTask1 = new Task(
        Subject = 'Open Task 1',
        Status = 'Open',
        WhatId = caseObj.Id,
        OwnerId = usr.Id,
        Department__c = 'CRM',
        Type__c = 'Poor Knowledge',
        SubType__c = 'CRM Team Task 1',
        FinalTask__c = false
    );

    Task openTask2 = new Task(
        Subject = 'Open Task 2',
        Status = 'Open',
        WhatId = caseObj.Id,
        OwnerId = usr.Id,
        Department__c = 'Finance',
        Type__c = 'Poor Knowledge',
        SubType__c = 'CRM Team Task',
        FinalTask__c = true
    );

    insert new List<Task>{openTask1, openTask2};

    Test.startTest();

    List<Task> latestTask =
        ActivityService.getInstance().fetchLatestOpenTaskOnCase(caseObj.Id);

    List<Task> openTasks =
        ActivityService.getInstance().fetchOpenTaskForCase(caseObj);

    Test.stopTest();

    System.assertEquals(1, latestTask.size());
    System.assertEquals(caseObj.Id, latestTask[0].WhatId);

    System.assertEquals(2, openTasks.size());
    System.assertEquals(caseObj.Id, openTasks[0].WhatId);
}
@IsTest
    static void testCreateEventObj() {
        // Create Lead
        Lead testLead = TestDataFactory.createLead('Test Customer', '0501234567', 'test@example.com');
        insert testLead;

        // Create Appointment Slot
        List<AppointmentSlot__c> slots = TestDataFactory.createAppointmentSlots(
            1,
            'Available',
            UserInfo.getUserId(),
            Date.today().addDays(1)
        );
        AppointmentSlot__c testSlot = slots[0];

        DateTime startDateTime = DateTime.newInstance(2026, 1, 15, 10, 0, 0);

        DateTime endDateTime = DateTime.newInstance(2026, 1, 15, 11, 0, 0);
        // Call the method we are testing
        Test.startTest();
        Event resultEvent = ActivityService.getInstance()
            .createEventObj(
                testLead.Id,
                testSlot.Id,
                'Scheduled',
                startDateTime,
                endDateTime,
                'Test Appointment',
                'Appointment'
            );
        Test.stopTest();

        System.assertNotEquals(null, resultEvent, 'Event should not be null');
        System.assertEquals(testLead.Id, resultEvent.WhoId, 'WhoId should match the Lead');
        System.assertEquals(testSlot.Id, resultEvent.AppointmentSlot__c, 'Appointment Slot should match');
        System.assertEquals('Scheduled', resultEvent.AppointmentStatus__c, 'Appointment status should match');
        System.assertEquals(startDateTime, resultEvent.StartDateTime, 'Start date/time should match');
        System.assertEquals(endDateTime, resultEvent.EndDateTime, 'End date/time should match');
        System.assertEquals('Test Appointment', resultEvent.Subject, 'Subject should match');
        System.assertEquals('Appointment', resultEvent.Type, 'Type should match');
    }

    @IsTest
    static void testCreateAppointmentNotificationEmail() {
        Lead objLead = new Lead(
            FirstName = 'Test',
            LastName = 'Customer',
            Company = 'Test Company',
            Email = 'test@example.com'
        );
        insert objLead;

        Event evt = TestDataFactory.createEvent(
            objLead.Id,
            DateTime.newInstance(2026, 1, 15, 10, 0, 0),
            DateTime.newInstance(2026, 1, 15, 11, 0, 0),
            'Test Location'
        );

        // Create EmailTemplate object only - DO NOT INSERT
        EmailTemplate template = TestDataFactory.createEmailTemplate('Appointment Notification');
        template.Subject = 'Your appointment is confirmed';
        template.HtmlValue =
            '<p>Dear [Customer_Name] / [Customer_Name_Arabic],</p>' +
            '<p>Your appointment is on [Date] at [Slot_Time].</p>' +
            '<p>Location: [Location]</p>' +
            '<p>Contact: [Manager_Name] - [Manager_Number]</p>';

        // Template values
        Map<String, String> templateFieldValues = TestDataFactory.createAppointmentTemplateFieldValues();

        Test.startTest();
        Messaging.SingleEmailMessage resultEmail = ActivityService.getInstance()
            .createAppointmentNotificationEmail(template, evt, templateFieldValues);
        Test.stopTest();

        System.assertNotEquals(null, resultEmail, 'Email message should not be null');
        System.assertEquals(
            'Your appointment is confirmed',
            resultEmail.getSubject(),
            'Email subject should match the template subject'
        );
        System.assertEquals(objLead.Id, resultEmail.getTargetObjectId(), 'Email recipient should be the Lead');

        String emailBody = resultEmail.getHtmlBody();

        System.assert(emailBody.contains('Test Customer'), 'Customer name should be present in the email');
        System.assert(
            emailBody.contains('Test Customer Arabic'),
            'Customer Arabic name should be present in the email'
        );
        System.assert(emailBody.contains('Test Location'), 'Location should be present in the email');
        System.assert(emailBody.contains('Test Manager'), 'Manager name should be present in the email');
        System.assert(emailBody.contains('0501234567'), 'Manager phone should be present in the email');
    }

    @IsTest
    static void testUpdateEvents() {
        Lead testLead = TestDataFactory.createLead('Test Customer', '0501234567', 'test@example.com');
        insert testLead;

        Event testEvent = TestDataFactory.createAppointmentEvent(
            testLead.Id,
            DateTime.newInstance(2026, 1, 15, 10, 0, 0),
            DateTime.newInstance(2026, 1, 15, 11, 0, 0),
            'Test Location'
        );

        testEvent.Subject = 'Updated Appointment';

        Test.startTest();
        List<Event> resultEvents = ActivityService.getInstance().updateEvents(new List<Event>{ testEvent });
        Test.stopTest();

        System.assertNotEquals(null, resultEvents, 'Event list should not be null');
        System.assertEquals(1, resultEvents.size(), 'Event list should contain one Event');

        Event updatedEvent = [SELECT Id, Subject FROM Event WHERE Id = :testEvent.Id];
        System.assertEquals('Updated Appointment', updatedEvent.Subject, 'Event Subject should be updated');
    }
}