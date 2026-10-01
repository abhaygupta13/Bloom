@istest
public class LeadAsyncTriggerHandlerTest {

    @TestSetup
    static void setupData() {
        List<PushNotificationTemplate__c> templates =new List<PushNotificationTemplate__c>();
        templates.add(new PushNotificationTemplate__c(Name = 'Lead Created', Title__c = 'Lead Created', Body__c = 'New lead created: {0}', NotificationType__c = '1', SenderBloomPartnersID__c = 'Test'));
        templates.add(new PushNotificationTemplate__c(Name = 'Lead Closure', Title__c = 'Lead Closure', Body__c = 'Lead {0} has been closed successfully.', NotificationType__c = '1', SenderBloomPartnersID__c = 'Test'));
        templates.add(new PushNotificationTemplate__c(Name = 'Booking Form Sent', Title__c = 'Booking Form Sent', Body__c = 'Booking form sent: {0}', NotificationType__c = '1', SenderBloomPartnersID__c = 'Test'));        
        insert templates;
        
        DocumentType__c dt = new DocumentType__c(Type__c = 'Booking Form', Active__c = true);
        insert dt;
    }

    @istest
    static void TestMethod1(){
        Test.enableChangeDataCapture();
        List<Lead> Llist = new List<Lead>();
        Lead l = new lead();
        l.LastName = 'Testclass';
        l.MobileCountryCode__c = '971';
        l.Status = 'New';
        l.MobilePhone = '37829292020';
        l.Email = 'Testclass@gmail.com';
        // l.Lead_Channel__c = 'Online'; 
        Llist.add(l);
        insert Llist;
        //  l.LastName = 'testlead1';
        //  Llist.add(l);
        Update l;
        Test.getEventBus().deliver();
        
        //Delete the record
        Test.enableChangeDataCapture();
        DELETE l;
        Test.getEventBus().deliver();
        //UnDelete the record
        Test.enableChangeDataCapture();
        UNDELETE l;
        Test.getEventBus().deliver();
        
        
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        AssignmentRule__c assr = new AssignmentRule__c();
        assr.RecordType__c = 'Lead';
        assr.ProcessName__c = 'Digital Lead Assignment';
        assr.IsActive__c = true;
        insert assr;
        
        time startime = Time.newInstance(9, 30, 0, 0);
        Time Endtime = Time.newInstance(20, 30, 0, 0);
        AssignmentUser__c assru = new AssignmentUser__c();
        assru.IsActive__c = true;
        assru.AssignmentDays__c = 'Monday;Tuesday;Wednesday';
        assru.MondayStartTime__c = startime;
        assru.MondayEndTime__c = Endtime;
        assru.TuesdayStartTime__c  = startime;
        assru.TuesdayEndTime__c = Endtime;
        assru.AssignmentRule__c = assr.id;
        assru.User__c = adminUser.id;
        assru.MaximumCapacity__c = 100;
        insert assru;
        
        
        
        
        LeadChangeEvent event = new LeadChangeEvent();
        
        // Set the ChangeEventHeader
        EventBus.ChangeEventHeader header = new EventBus.ChangeEventHeader();
        header.changeType = 'CREATE'; // Change to 'UPDATE', 'DELETE', or 'UNDELETE' to test other scenarios
        event.ChangeEventHeader = header;
        //  EventBus.Publish(event);
        
        
        // Set the ChangeEventHeader
        EventBus.ChangeEventHeader header2 = new EventBus.ChangeEventHeader();
        header2.changeType = 'UPDATE'; // Change to 'UPDATE', 'DELETE', or 'UNDELETE' to test other scenarios
        event.ChangeEventHeader = header2;
        EventBus.ChangeEventHeader header3 = new EventBus.ChangeEventHeader();
        header3.changeType = 'DELETE'; // Change to 'UPDATE', 'DELETE', or 'UNDELETE' to test other scenarios
        event.ChangeEventHeader = header3;
        EventBus.ChangeEventHeader header4 = new EventBus.ChangeEventHeader();
        header4.changeType = 'UNDELETE'; // Change to 'UPDATE', 'DELETE', or 'UNDELETE' to test other scenarios
        event.ChangeEventHeader = header4;
        test.starttest();
        
        
        LeadAsyncTriggerHandler ias = new LeadAsyncTriggerHandler(); 
        //ias.changeTypeCreate(new List<Id>{Llist[0].Id});
        //ias.changeTypeDelete(new List<Id>{Llist[0].Id});
       // ias.changeTypeUndelete(new List<Id>{Llist[0].Id});
       // ias.changeTypeUpdate(new List<Id>{Llist[0].Id});
        
        ias.isDisabled();
        AsyncTriggerDispatcher.disableAllAsyncTriggers();
        AsyncTriggerDispatcher.enableAllAsyncTriggers();
        //AsyncTriggerDispatcher.run(null);
        
        test.stoptest();
    }

      @IsTest
  static void testSendMobileAppPushNotification_LeadCreated() {

    Lead testLead = TestDataFactory.createADHATestLead();
    testLead.Status = 'New';

    insert testLead;

    Test.startTest();
      LeadAsyncTriggerHelper.sendMobilAppPushNotification(new Set<Id>{ testLead.Id }, 'Lead Created', new Set<String>{'Lead Created'});
    Test.stopTest();

    List<PushNotification__c> notifications = [
      SELECT Id, Type__c, NotificationType__c, ObjectAPIName__c FROM PushNotification__c
      WHERE RecordId__c = :testLead.Id AND NotificationType__c = '1'
    ];

    System.assertEquals(1, notifications.size(), 'Lead Created push notification should be created.');
    System.assertEquals('Lead', notifications[0].ObjectAPIName__c);
  }

  @IsTest
  static void testSendMobileAppPushNotification_LeadCancelled() {
    Lead testLead = TestDataFactory.createADHATestLead();
    testLead.Status = 'Closed';

    insert testLead;

    Test.startTest();
    LeadAsyncTriggerHelper.sendMobilAppPushNotification(new Set<Id>{ testLead.Id }, 'Lead Closure', new Set<String>{'Lead Closure'});
    Test.stopTest();

    List<PushNotification__c> notifications = [
      SELECT Id, Type__c, NotificationType__c, ObjectAPIName__c FROM PushNotification__c
      WHERE RecordId__c = :testLead.Id AND NotificationType__c = '1'
    ];

  }

    @IsTest
    static void testLeadOwnerChanged() {
    
      Test.enableChangeDataCapture();
    
      Lead testLead = TestDataFactory.createLead('Test Customer','0501234567','testcustomer@example.com');
      insert testLead;
    
      String profileId = UserInfo.getProfileId();
    
      User anotherUser = TestDataFactory.createUser(profileId,'anotheruser@test.com','anotheruser' + System.currentTimeMillis() + '@test.com','Another','User');
      insert anotherUser;
      Test.getEventBus().deliver();
      Test.startTest();
      testLead.OwnerId = anotherUser.Id;
      update testLead;
      Test.getEventBus().deliver();
      Test.stopTest();
    } 

    @IsTest
    static void testADHALeadClosed() {

        Test.enableChangeDataCapture();

        Lead testLead = TestDataFactory.createADHATestLead();
        insert testLead;
        Test.getEventBus().deliver();
        Test.startTest();
        testLead.Status = 'Closed';
        update testLead;
        Test.getEventBus().deliver();
        Test.stopTest();
    }

    @IsTest
    static void testADHABookingFormSent() {

        Test.enableChangeDataCapture();

        Lead testLead = TestDataFactory.createADHATestLead();
        insert testLead;
        Test.getEventBus().deliver();
        Test.startTest();
        testLead.BookingStatus__c = 'Booking Form Sent';
        update testLead;
        Test.getEventBus().deliver();
        Test.stopTest();
    }


    @IsTest
    static void testADHABookingFormSigned() {

        Test.enableChangeDataCapture();

        Lead testLead = TestDataFactory.createADHATestLead();
        insert testLead;
        Test.getEventBus().deliver();
        Test.startTest();
        testLead.BookingStatus__c = 'Booking Form Signed';
        update testLead;
        Test.getEventBus().deliver();
        Test.stopTest();
    }


    @IsTest
    static void testADHABookingCancelled() {

        Test.enableChangeDataCapture();

        Lead testLead = TestDataFactory.createADHATestLead();
        insert testLead;
        Test.getEventBus().deliver();
        Test.startTest();
        testLead.BookingStatus__c = 'Booking Cancelled';
        update testLead;
        Test.getEventBus().deliver();
        Test.stopTest();
    }


    @IsTest
    static void testADHAOpportunityCreated() {

        Test.enableChangeDataCapture();

        Lead testLead = TestDataFactory.createADHATestLead();
        insert testLead;
        Test.getEventBus().deliver();
        Test.startTest();
        testLead.BookingStatus__c = 'Opportunity Created';
        update testLead;
        Test.getEventBus().deliver();
        Test.stopTest();
    }
    
    @IsTest
    static void testLeadInternalEmailNotification() {
        Test.enableChangeDataCapture();
        Lead testLead = TestDataFactory.createADHATestLead();
        insert testLead;
        
        Test.getEventBus().deliver();
        Test.startTest();
        testLead.LeadManagerStatus__c = 'Waiting List';
        testLead.Lead_Channel__c = 'API Integration';
        testLead.LeadSource = 'Government Entity';
        testLead.leadsubsource__c = 'ADHA';
        testLead.Status = 'Closed';
        update testLead;
        Test.getEventBus().deliver();
        Test.stopTest();
    }
    
    @IsTest
    static void testLeadInternalEmailNotification2() {
        Test.enableChangeDataCapture();
        Lead testLead = TestDataFactory.createADHATestLead();
        insert testLead;
        
        Test.getEventBus().deliver();
        Test.startTest();
        testLead.LeadManagerStatus__c = 'Waiting List';
        testLead.LeadTeam__c = 'Leasing';
        update testLead;
        Test.getEventBus().deliver();
        Test.stopTest();
    }
    
    @IsTest
    static void testCreateSMTask() {
        Test.enableChangeDataCapture();
        Lead testLead = TestDataFactory.createADHATestLead();
        insert testLead;
        
        // insert new Document__c(Lead__c = testLead.Id, Document_Name__c = 'Booking Form');
        Test.getEventBus().deliver();
        Test.startTest();
        testLead.LeadManagerStatus__c = 'In Progress';
        testLead.FollowUpDate__c = Date.valueOf('2026-09-21');
        testLead.LeadTeam__c = 'Sales';
        update testLead;
        
        //LeadAsyncTriggerHelper.createADHAFirstFollowUpTask(new List<Id>{ testLead.Id });
        // LeadAsyncTriggerHelper.generateBookingForm(new Set<Id>{ testLead.Id });
        LeadAsyncTriggerHelper.sendLeadOwnerCustomNotification(new List<Lead>{ testLead });
        Test.getEventBus().deliver();
        Test.stopTest();
        
        // LeadAsyncTriggerHelper.createSMTask(new List<Id>{ testLead.Id });
    }
    
    @IsTest
    static void testLeadCustomerEmailBankLoan() {
        AssignmentRule__c ar = new AssignmentRule__c(IsActive__c = true, ProcessName__c = 'ADHA Lead Assignment', RecordType__c = 'Lead', ProcessType__c = 'Sales');
        insert ar;
        
        Test.enableChangeDataCapture();
        Lead testLead = TestDataFactory.createADHATestLead();
        insert testLead;
        
        Test.getEventBus().deliver();
        Test.startTest();
        testLead.TopUpType__c = 'Bank Loan Top-up';
        testLead.leadsubsource__c = 'ADHA';
        update testLead;
        Test.getEventBus().deliver();
        Test.stopTest();
    }
    
    @IsTest
    static void testUnitReservationOnADHALead() {
        Project__c objProject = TestDataFactory.createProject('Test Project');
        objProject.GIS_Service_URL__c='URL';
        insert objProject;
        
        List<unit__c> unitLst = new List<unit__c>();
        for(integer i =0;i<3;i++){          
            unitLst.add(TestDataFactory.createUnit(objProject.Id, 'J1A1-G01'+i,'Available'));  
        }
        insert unitLst;
        
        AssignmentRule__c ar = new AssignmentRule__c(IsActive__c = true, ProcessName__c = 'ADHA Lead Assignment', RecordType__c = 'Lead', ProcessType__c = 'Sales');
        insert ar;
        
        Test.enableChangeDataCapture();
        Lead testLead = TestDataFactory.createADHATestLead();
        testLead.ProjectLookup__c = objProject.Id;
        insert testLead;
        
        unitLst[0].BlockedForLead__c = testLead.Id;
        update unitLst[0];
        
        Test.getEventBus().deliver();
        Test.startTest();
        testLead.Unit__c = unitLst[0].Id;
        update testLead;
        Test.getEventBus().deliver();
        Test.stopTest();
    }
    
}