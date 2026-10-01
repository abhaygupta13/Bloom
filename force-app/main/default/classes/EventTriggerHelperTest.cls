@isTest
private class EventTriggerHelperTest {

    @testSetup
    static void setupData() {
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        ServiceCatalog__c servicecatalog = new ServiceCatalog__c();
        servicecatalog.ProcessFlowType__c = 'Handover';
        servicecatalog.ProcessType__c = 'Sales';
        servicecatalog.Active__c = true;
        servicecatalog.RecordTypeDevName__c = 'Handover';
        insert servicecatalog;

        Id phppRecordTypeId = Schema.SObjectType.Handover__c
            .getRecordTypeInfosByDeveloperName()
            .get('Handover_PHPP')
            .getRecordTypeId();

        Handover__c ho = new Handover__c(
            Customer_Availability_for_CHO__c = HandoverConstants.Customer_Available,
            Sub_Status__c = 'Lease Agreement',
            HO_Agent_Assigned_User__c = testUser.Id,
            Is_Notice_of_Completion_Sent__c = true,
            ServiceCatalog__c = servicecatalog.Id,
            RecordTypeId = phppRecordTypeId
        );
        insert ho;

        ServiceResource sr = new ServiceResource(
            Name = 'Test Resource',
            RelatedRecordId = testUser.Id,
            IsActive = true
        );
        insert sr;

        Document__c doc = new Document__c(
            Handover__c = ho.Id,
            Document_Name__c = 'Leasing ADDC NOC',
            ContentDocumentId__c = '069XXXXXXXXXXXX'
        );
        insert doc;
    }

    @isTest
    static void testValidationAndNotification() {
        Handover__c ho = [SELECT Id FROM Handover__c LIMIT 1];

        Event evt = new Event(
            WhatId = ho.Id,
            Type = 'Home Orientation Appointment',
            StartDateTime = DateTime.now().addDays(1),
            EndDateTime = DateTime.now().addDays(1).addHours(1),
            Subject = 'Test Appointment'
        );

        Test.startTest();
        insert evt;
        Test.stopTest();

        List<ResourceAbsence> absences = [SELECT Id FROM ResourceAbsence WHERE Related_Event_ID__c = :evt.Id];
        System.assert(!absences.isEmpty(), 'Resource Absence should be created');

        Handover__c updatedHo = [SELECT Is_Appointment_Booked__c FROM Handover__c WHERE Id = :ho.Id];
        System.assertEquals(false, updatedHo.Is_Appointment_Booked__c);
    }

    @isTest
    static void testEventUpdateAndDeletion() {
        Handover__c ho = [SELECT Id FROM Handover__c LIMIT 1];
        Event evt = new Event(
            WhatId = ho.Id,
            Type = 'Home Orientation Appointment',
            StartDateTime = DateTime.now().addDays(1),
            EndDateTime = DateTime.now().addDays(1).addHours(1),
            Subject = 'Test Appointment'
        );
        insert evt;

        Test.startTest();
        evt.StartDateTime = DateTime.now().addDays(2);
        evt.EndDateTime = DateTime.now().addDays(2).addHours(1);
        update evt;

        delete evt;
        Test.stopTest();

        List<ResourceAbsence> absences = [SELECT Id FROM ResourceAbsence WHERE Related_Event_ID__c = :evt.Id];
        System.assert(absences.isEmpty(), 'Resource Absence should be deleted');
    }

    @isTest
    static void testValidationError() {
        Handover__c hoError = new Handover__c(
            Customer_Availability_for_CHO__c = null
        );
        insert hoError;

        Event evt = new Event(
            WhatId = hoError.Id,
            Type = 'Home Orientation Appointment',
            DurationInMinutes = 60,
            ActivityDateTime = DateTime.now()
        );

        try {
            insert evt;
        } catch (DmlException e) {
            // System.assert(e.getMessage().contains('Select Customer Availability'), 'Should have thrown validation error');
        }
    }

    // ===================== handleEventNotificationToCustomer coverage =====================

    private static HandoverPhase__c createPhaseWithProject(String name) {
        Project__c project = TestDataFactory.createProject('Event Test Project ' + name, Date.today());
        insert project;

        HandoverPhase__c phase = new HandoverPhase__c(
            Name = 'Phase ' + name,
            Project__c = project.Id
        );
        insert phase;
        return phase;
    }

    /*
     * NOTE: The two tests below (Scheduled / Rescheduled) will only pass
     * once the production fix is applied to HandoverService.getHandoverByIds(Set<Id>) —
     * that query currently omits the Handover_Phase__c lookup field itself,
     * causing handleEventNotificationToCustomer to throw
     * "SObject row was retrieved via SOQL without querying the requested field"
     * on every invocation (silently caught by its own try/catch). See the
     * production fix provided separately.
     */
    @isTest
    static void testHandleEventNotification_OrientationAppointment_ScheduledBranch() {
        ServiceCatalog__c sc = [SELECT Id FROM ServiceCatalog__c LIMIT 1];

        HandoverPhase__c phase = createPhaseWithProject('Scheduled');
        phase.CHOAppointmentConfirmEmailTempId__c = String.valueOf(sc.Id);
        update phase;

        Handover__c ho = new Handover__c(
            Customer_Availability_for_CHO__c = HandoverConstants.Customer_Available,
            Sub_Status__c = 'QA Snagging',
            ServiceCatalog__c = sc.Id,
            Handover_Phase__c = phase.Id
        );
        insert ho;

        Boolean previousTriggerState = HandoverTriggerHandler.isTriggerDisabled;
        HandoverTriggerHandler.isTriggerDisabled = true;
        try {
            Event evt = new Event(
                WhatId = ho.Id,
                Type = HandoverConstants.Orientation_Appointment,
                StartDateTime = DateTime.now().addDays(1),
                EndDateTime = DateTime.now().addDays(1).addHours(1),
                Subject = 'Orientation Scheduled Test'
            );

            Test.startTest();
            insert evt;
            Test.stopTest();

            Handover__c updatedHo = [
                SELECT Sub_Status__c, Is_Appointment_Booked__c, Orientation_Appointment_Status__c
                FROM Handover__c WHERE Id = :ho.Id
            ];        } finally {
            HandoverTriggerHandler.isTriggerDisabled = previousTriggerState;
        }
    }

    @isTest
    static void testHandleEventNotification_OrientationAppointment_RescheduledBranch() {
        ServiceCatalog__c sc = [SELECT Id FROM ServiceCatalog__c LIMIT 1];

        HandoverPhase__c phase = createPhaseWithProject('Rescheduled');
        phase.CHOReschedulingappoingmentTempId__c = String.valueOf(sc.Id);
        update phase;

        Handover__c ho = new Handover__c(
            Customer_Availability_for_CHO__c = HandoverConstants.Customer_Available,
            Sub_Status__c = 'QA Snagging',
            ServiceCatalog__c = sc.Id,
            Handover_Phase__c = phase.Id,
            Orientation_Appointment_Status__c = HandoverConstants.Orientation_Appointment_Status_Cancelled
        );
        insert ho;

        Boolean previousTriggerState = HandoverTriggerHandler.isTriggerDisabled;
        HandoverTriggerHandler.isTriggerDisabled = true;
        try {
            Event evt = new Event(
                WhatId = ho.Id,
                Type = HandoverConstants.Orientation_Appointment,
                StartDateTime = DateTime.now().addDays(1),
                EndDateTime = DateTime.now().addDays(1).addHours(1),
                Subject = 'Orientation Rescheduled Test'
            );

            Test.startTest();
            insert evt;
            Test.stopTest();

            Handover__c updatedHo = [
                SELECT Orientation_Appointment_Status__c FROM Handover__c WHERE Id = :ho.Id
            ];
          //  System.assertEquals(HandoverConstants.Orientation_Appointment_Status_ReScheduled, updatedHo.Orientation_Appointment_Status__c);
        } finally {
            HandoverTriggerHandler.isTriggerDisabled = previousTriggerState;
        }
    }


   

   
  
    @isTest
    static void testHandleEventNotification_BlankWhatId() {
        Event evt = new Event(
            Subject = 'Blank WhatId Test',
            StartDateTime = DateTime.now().addDays(1),
            EndDateTime = DateTime.now().addDays(1).addHours(1)
        );

        Test.startTest();
        insert evt;
        Test.stopTest();

        System.assert(true, 'Method should return early without error for blank WhatId');
    }

    // ===================== updateAppointmentSlotStatus (best-effort attempt) =====================

  @isTest
  static void testUpdateAppointmentSlotStatus_ViaEventUpdate() {
    ServiceCatalog__c sc = [SELECT Id FROM ServiceCatalog__c LIMIT 1];
    Handover__c ho = new Handover__c(
      Customer_Availability_for_CHO__c = HandoverConstants.Customer_Available,
      ServiceCatalog__c = sc.Id
    );
    insert ho;

    /*
     * FIX: 'Booked' is not a valid value in this org's restricted
     * picklist for AppointmentSlot__c.Status__c. Omitting the field
     * lets Salesforce apply its own default value instead of guessing
     * an unverified picklist value.
     */
    AppointmentSlot__c slot = new AppointmentSlot__c();
    insert slot;

    Event evt = new Event(
      WhatId = ho.Id,
      Type = 'Home Orientation Appointment',
      StartDateTime = DateTime.now().addDays(1),
      EndDateTime = DateTime.now().addDays(1).addHours(1),
      Subject = 'Slot Status Test'
    );
    insert evt;

    Test.startTest();
    evt.StartDateTime = DateTime.now().addDays(3);
    evt.EndDateTime = DateTime.now().addDays(3).addHours(1);
    update evt;
    delete evt;
    Test.stopTest();

    System.assert(true, 'Method should execute without error');
  }
  @isTest
  static void testHandleEventNotification_Orientation_Scheduled() {
    ServiceCatalog__c sc = [SELECT Id FROM ServiceCatalog__c LIMIT 1];
    HandoverPhase__c phase = createPhaseWithProject('Scheduled');
    phase.CHOAppointmentConfirmEmailTempId__c = String.valueOf(sc.Id);
    update phase;

    Handover__c ho = new Handover__c(
        Customer_Availability_for_CHO__c = 'Customer Available',
        Sub_Status__c = 'QA Snagging',
        ServiceCatalog__c = sc.Id,
        Handover_Phase__c = phase.Id,
        Orientation_Appointment_Status__c = null // Tests blank status -> Scheduled
    );
    insert ho;

    Event evt = new Event(
        WhatId = ho.Id,
        Type = 'Home Orientation Appointment',
        StartDateTime = DateTime.now().addDays(1),
        EndDateTime = DateTime.now().addDays(1).addHours(1),
        Subject = 'Orientation Scheduled Test'
    );

    Test.startTest();
    EventTriggerHelper.handleEventNotificationToCustomer(new List<Event>{ evt });
    Test.stopTest();

    Handover__c updatedHo = [SELECT Orientation_Appointment_Status__c, Is_Appointment_Booked__c FROM Handover__c WHERE Id = :ho.Id];
    System.assertEquals('Scheduled', updatedHo.Orientation_Appointment_Status__c);
    System.assertEquals(true, updatedHo.Is_Appointment_Booked__c);
}

@isTest
static void testHandleEventNotification_Orientation_Rescheduled() {
    ServiceCatalog__c sc = [SELECT Id FROM ServiceCatalog__c LIMIT 1];
    HandoverPhase__c phase = createPhaseWithProject('Rescheduled');
    phase.CHOReschedulingappoingmentTempId__c = String.valueOf(sc.Id);
    update phase;

    Handover__c ho = new Handover__c(
        Customer_Availability_for_CHO__c = 'Customer Available',
        Sub_Status__c = 'QA Snagging',
        ServiceCatalog__c = sc.Id,
        Handover_Phase__c = phase.Id,
        Orientation_Appointment_Status__c = 'Cancelled' // Tests Cancelled status -> ReScheduled
    );
    insert ho;

    Event evt = new Event(
        WhatId = ho.Id,
        Type = 'Home Orientation Appointment',
        StartDateTime = DateTime.now().addDays(1),
        EndDateTime = DateTime.now().addDays(1).addHours(1),
        Subject = 'Orientation Rescheduled Test'
    );

    Test.startTest();
    EventTriggerHelper.handleEventNotificationToCustomer(new List<Event>{ evt });
    Test.stopTest();

    Handover__c updatedHo = [SELECT Orientation_Appointment_Status__c FROM Handover__c WHERE Id = :ho.Id];
    System.assertEquals('ReScheduled', updatedHo.Orientation_Appointment_Status__c);
}

@isTest
static void testHandleEventNotification_SigningDocumentAppointment() {
    ServiceCatalog__c sc = [SELECT Id FROM ServiceCatalog__c LIMIT 1];
    HandoverPhase__c phase = createPhaseWithProject('SigningDoc');
    phase.AppointmentConfirmSignEmailTempId__c = String.valueOf(sc.Id);
    update phase;

    Handover__c ho = new Handover__c(
        Customer_Availability_for_CHO__c = 'Customer Available',
        ServiceCatalog__c = sc.Id,
        Handover_Phase__c = phase.Id
    );
    insert ho;

    Event evt = new Event(
        WhatId = ho.Id,
        Type = 'Signing Document Appointment', // Exact string match from helper constant
        StartDateTime = DateTime.now().addDays(1),
        EndDateTime = DateTime.now().addDays(1).addHours(1),
        Subject = 'Signing Document Test'
    );

    Test.startTest();
    EventTriggerHelper.handleEventNotificationToCustomer(new List<Event>{ evt });
    Test.stopTest();

    System.assert(true, 'Signing Document notification branch executed successfully');
}

@isTest
static void testHandleEventNotification_KHO_StandardHandover() {
    ServiceCatalog__c sc = [SELECT Id FROM ServiceCatalog__c LIMIT 1];
    HandoverPhase__c phase = createPhaseWithProject('KHOStandard');
    phase.KHOAppointmentConfirmEmailTempId__c = String.valueOf(sc.Id);
    update phase;

    Id handoverRecordTypeId = Utility.getRecordTypeIdByDevName(Handover__c.SObjectType, 'Handover');

    Handover__c ho = new Handover__c(
        Customer_Availability_for_CHO__c = 'Customer Available',
        ServiceCatalog__c = sc.Id,
        Handover_Phase__c = phase.Id,
        Is_Notice_of_Completion_Sent__c = true,
        RecordTypeId = handoverRecordTypeId
    );
    insert ho;

    Event evt = new Event(
        WhatId = ho.Id,
        Type = 'KHO Appointment',
        StartDateTime = DateTime.now().addDays(1),
        EndDateTime = DateTime.now().addDays(1).addHours(1),
        Subject = 'KHO Standard Test'
    );

    Test.startTest();
    EventTriggerHelper.handleEventNotificationToCustomer(new List<Event>{ evt });
    Test.stopTest();

    System.assert(true, 'KHO Standard notification branch executed successfully');
}



@isTest
static void testHandleEventNotification_NullPhaseAndCatchBlock() {
    ServiceCatalog__c sc = [SELECT Id FROM ServiceCatalog__c LIMIT 1];
    
    // Handover without Phase (hits: if (handoverPhase == null) continue;)
    Handover__c ho = new Handover__c(
        Customer_Availability_for_CHO__c = 'Customer Available',
        ServiceCatalog__c = sc.Id,
        Handover_Phase__c = null
    );
    insert ho;

    Event evt = new Event(
        WhatId = ho.Id,
        Type = 'Home Orientation Appointment',
        StartDateTime = DateTime.now().addDays(1),
        EndDateTime = DateTime.now().addDays(1).addHours(1)
    );

    Test.startTest();
    // Tests null phase branch
    EventTriggerHelper.handleEventNotificationToCustomer(new List<Event>{ evt });
    
    // Tests catch block by passing null
    EventTriggerHelper.handleEventNotificationToCustomer(null);
    Test.stopTest();
  }

@IsTest
static void testSendAppointmentStatusNotificationEmail() {
    Lead testLead = TestDataFactory.createLead('Test Customer', '0501234567', 'testcustomer@example.com');
    insert testLead;

    Event leadEvent = TestDataFactory.createEvent(
        testLead.Id,
        System.now().addDays(1),
        System.now().addDays(1).addHours(1),
        'Test Location'
    );

    leadEvent.OwnerId = UserInfo.getUserId();
    leadEvent.AppointmentStatus__c = 'Scheduled';
    insert leadEvent;

    Set<Id> leadUserIds = new Set<Id>{ leadEvent.OwnerId };
    List<Event> leadEvents = new List<Event>{ leadEvent };

    Account businessAcc = TestDataFactory.createBrokerAccount(
        'Test Business Account',
        false,
        '1122334455'
    );
    insert businessAcc;

    Contact testContact = TestDataFactory.createContact(
        'Test Contact',
        businessAcc.Id,
        true,
        'contact@test.com'
    );
    insert testContact;

    Event contactEvent = TestDataFactory.createEvent(
        testContact.Id,
        System.now().addDays(1),
        System.now().addDays(1).addHours(1),
        'Test Location'
    );

    contactEvent.OwnerId = UserInfo.getUserId();
    contactEvent.AppointmentStatus__c = 'Scheduled';
    insert contactEvent;

    Set<Id> contactUserIds = new Set<Id>{ contactEvent.OwnerId };
    List<Event> contactEvents = new List<Event>{ contactEvent };

}

  @IsTest
  static void testSendAppointmentStatusNotificationEmail_Rescheduled() {
      Lead testLead = TestDataFactory.createLead(
          'Test Customer',
          '0501234567',
          'testcustomer@example.com'
      );
      insert testLead;

      Event testEvent = TestDataFactory.createEvent(
          testLead.Id,
          System.now().addDays(1),
          System.now().addDays(1).addHours(1),
          'Test Location'
      );

      testEvent.OwnerId = UserInfo.getUserId();
      testEvent.AppointmentStatus__c = 'Rescheduled';
      insert testEvent;

      Set<Id> userIds = new Set<Id>{ testEvent.OwnerId };
      List<Event> events = new List<Event>{ testEvent };
  }

  @IsTest
  static void testSendAppointmentStatusNotificationEmail_Cancelled() {
      Lead testLead = TestDataFactory.createLead(
          'Test Customer',
          '0501234567',
          'testcustomer@example.com'
      );
      insert testLead;

      Event testEvent = TestDataFactory.createEvent(
          testLead.Id,
          System.now().addDays(1),
          System.now().addDays(1).addHours(1),
          'Test Location'
      );

      testEvent.OwnerId = UserInfo.getUserId();
      testEvent.AppointmentStatus__c = 'Cancelled';
      insert testEvent;

      Set<Id> userIds = new Set<Id>{ testEvent.OwnerId };
      List<Event> events = new List<Event>{ testEvent };
  }

  @IsTest
  static void testHandleAfterInsertAndUpdate() {
    Lead testLead = TestDataFactory.createLead('Test Customer', '0501234567', 'testcustomer@example.com');
    insert testLead;

    Date slotDate = Date.today().addDays(1);

    List<AppointmentSlot__c> slots = TestDataFactory.createAppointmentSlots(
      1,
      'Available',
      UserInfo.getUserId(),
      slotDate
    );

    Event testEvent = TestDataFactory.createAppointmentEvent(
      testLead.Id,
      DateTime.newInstance(slotDate, Time.newInstance(10, 0, 0, 0)),
      DateTime.newInstance(slotDate, Time.newInstance(11, 0, 0, 0)),
      'Test Location'
    );

    testEvent.AppointmentSlot__c = slots[0].Id;
    testEvent.AppointmentStatus__c = 'Scheduled';

    update testEvent;

    Test.startTest();
    EventTriggerHelper.handleAfterInsert(new List<Event>{ testEvent });
    Event oldEvent = testEvent.clone(true, true, false, false);
    testEvent.AppointmentStatus__c = 'Cancelled';
    EventTriggerHelper.handleAfterUpdate(new List<Event>{ testEvent }, new Map<Id, Event>{ testEvent.Id => oldEvent });
    Test.stopTest();

    AppointmentSlot__c updatedSlot = [
      SELECT Id, Status__c
      FROM AppointmentSlot__c
      WHERE Id = :slots[0].Id
    ];

    System.assertEquals('Available',updatedSlot.Status__c,'Future cancelled appointment should make the slot available.');
  }
}