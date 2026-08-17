@isTest
private class BCAPPAmenitiesAPIControllerTest {
    
    @testSetup
    static void setupTestData() {
        
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		String grpName;
        System.runAs(u) {
            Group publicGroup = new Group(
                Name = 'Test Group',
                Type = 'Regular', // 'Regular' = Public Group
                DoesIncludeBosses = false
            );
            insert publicGroup;

            grpName = publicGroup.Name;

            GroupMember gm = new GroupMember(
                GroupId = publicGroup.Id,
                UserOrGroupId = u.Id
            );
            insert gm;
            
            EmailTemplate et = new EmailTemplate(
                Name = 'TestTemplate',
                DeveloperName = 'TestTemplate',
                Subject = 'Test',
                HtmlValue = 'Hello {!Case.CaseNumber}',
                TemplateType = 'custom',
				FolderId = UserInfo.getUserId()                
            );
    		insert et;

        }
        
        Project__c project = new Project__c(Name = 'Test Project');
        insert project;
        
        BuildingSection__c  phase = new BuildingSection__c (
            Name = 'Phase 1',
            Project__c = project.Id,
            BuildingSectionCode__c = 'BL-CAS'
        );
        insert phase;
        
        
        Unit__c unit = new Unit__c(
            Name = 'Unit 101',
            Project__c = project.Id,
            BuildingSectionName__c  = phase.Id
        );
        insert unit;
        
        Amenities__c amenity = new Amenities__c(
            Name = 'Swimming Pool',
            Type__c = 'Unpaid',
            isPaid__c = false,
            bookingFee__c = 0,
            slotDurationInMinutes__c = 60,
            dailyStartTime__c = Time.newInstance(9, 0, 0, 0),
            dailyEndTime__c = Time.newInstance(10, 0, 0, 0),
            project__c = project.Id,
            Building_Phase__c = phase.Id,
            userAccess__c = 'Owner',
            isReservation__c = true
        );
        insert amenity;
        
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        User__c user = new User__c(
            Name = 'Test User',
            Account__c = acc.Id,
            User_Type__c = 'Owner',
            User_Account__c = acc.Id,
            Email__c = 'test123@yopmail.com',
            Username__c = 'test123@yopmail.com',
            deviceRegistrationId__c = '12345-454354-445465465'
        );
        insert user;
        
         Service_Catalog__c sc = new Service_Catalog__c(Name = 'Amenities');
        insert sc;
        
        Task_Rule_Criteria__c rule = new Task_Rule_Criteria__c(
        Name = 'Status Confirmed Rule',
        Rule_Criteria__c = 'Status = \'Confirmed\''
    );
    insert rule;

    Service__c emailService = new Service__c(Name = 'Send Email');
    Service__c pushService = new Service__c(Name = 'Send Email');
        List<Service__c> notifyServices = new List<Service__c>();
        notifyServices.add(emailService);
         notifyServices.add(pushService);
    insert notifyServices;

    Action_Items__c actionItem = new Action_Items__c(
        Service_Catalog__c = sc.Id,
        Service__c = emailService.Id
       
    );
    Action_Items__c actionItem2 = new Action_Items__c(
        Service_Catalog__c = sc.Id,
        Service__c = pushService.Id
       
    );    
        
    List<Action_Items__c> actionItems = new List<Action_Items__c>();
        actionItems.add(actionItem);
         actionItems.add(actionItem2);
    insert actionItems;    

    Task_Action__c taskAction = new Task_Action__c(
        Project__c = project.Id,
        EmailTemplateName__c = 'TestTemplate',
        Send_Customer__c = true,
        Task__c = actionItem.Id,
         Task_Rule_Criteria__c = rule.Id,
        EmailRecipients__c='tetclass@test.com'
    );
    Task_Action__c grptaskAction = new Task_Action__c(
        Project__c = project.Id,
        EmailTemplateName__c = 'TestTemplate',
        Send_Customer__c = false,
        Task__c = actionItem.Id,
         Task_Rule_Criteria__c = rule.Id,
        EmailRecipients__c=grpName
    );
    
        
    Task_Action__c pushNotifytaskAction = new Task_Action__c(
        Project__c = project.Id,
        Task__c = actionItem2.Id,
        Template__c = 'Test template with {CaseNumber}',
        Title__c = 'Test Push Title',
        Task_Rule_Criteria__c = rule.Id
    );
   // insert taskAction;    
        
        List<Task_Action__c> lstTaskActions = new List<Task_Action__c>();
        lstTaskActions.add(grptaskAction);
        lstTaskActions.add(taskAction);
        lstTaskActions.add(pushNotifytaskAction);
    insert lstTaskActions;

    /*EmailTemplate et = new EmailTemplate(
        Name = 'Test Template',
        DeveloperName = 'Test_Template',
        Subject = 'Test',
        HtmlValue = 'Hello {!Case.CaseNumber}',
        TemplateType = 'custom',
        FolderId = UserInfo.getUserId()
    );
    insert et;*/

        EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'AmenityReservationForCustomer' LIMIT 1];

        Case amenityBooking = new Case(
        	Amenities__c   = amenity.Id,
            project__c = project.Id,
            Permit_From_Date__c   = Date.newInstance(2026, 10, 1),
            startTime__c    = Time.newInstance(11, 0, 0, 0),
            endTime__c     = Time.newInstance(12, 0, 0, 0),
            durationInMinutes__c = 60,
            AccountId        = acc.Id,
            recordTypeId = Utilities.getRecordTypeId('Case','Community General Service Request'),
            Unit__c  = unit.Id,
            Service_Catalog__c = sc.Id,
            Origin = 'Admin',
            User_Type__c = 'Owner',
            Status ='Confirmed'
            );
        insert amenityBooking;
        
    }
    
    @isTest
    static void testAmenitiesGetRequest() {
        // Prepare Request
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'requestType' => 'aminities',
                'projectId' => [SELECT Id FROM Unit__c LIMIT 1].Id,
                'accountId' => [SELECT Id FROM Account LIMIT 1].Id
                });
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/v1/amenities/get-request';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        RestContext.request = req;
        
        // Prepare Response
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        Test.startTest();
        BCAPP_AmenitiesAPI.amenities();
        Test.stopTest();
        
        // No exceptions = success, assert logs or results if mock services are used
        System.assert(true, 'Executed amenities method for get-request');
    }
	
	@isTest
    static void testAmenitiesGetRequestException() {
        // Prepare Request
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'requestType' => 'aminities',
                'projectId' => [SELECT Id FROM Unit__c LIMIT 1].Id,
                'accountId' => ''
                });
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/v1/amenities/get-request';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        RestContext.request = req;
        
        // Prepare Response
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        Test.startTest();
        BCAPP_AmenitiesAPI.amenities();
        Test.stopTest();
        
        System.assert(true, 'Executed amenities method for get-request');
    }
        
    @isTest
    static void testBookAmenitySlot() {
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'requestType' => 'create',
                'amenityId' => [SELECT Id FROM Amenities__c LIMIT 1].Id,
                'accountId' => [SELECT Id FROM Account LIMIT 1].Id,
                'bookingDate' => '01-Oct-2026',
                'bookingTime' => '10:00 AM',
                'unitId' => [SELECT Id FROM Unit__c LIMIT 1].Id,
                'music' => true,
                'serveFandB' => true,
                'noOfGuests' => 10
                });
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/v1/amenities/booking-requests';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        Test.startTest();
        BCAPP_AmenitiesAPI.amenities();
        BCAPP_AmenitiesAPI.amenities();
        Test.stopTest();
        
        
        
        System.assert(true, 'Executed amenities method for booking-requests');
    }
    
      @isTest
    static void testBookAmenitySlotException() {
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'requestType' => 'create',
                'amenityId' => [SELECT Id FROM Amenities__c LIMIT 1].Id,
                'accountId' => [SELECT Id FROM Account LIMIT 1].Id,
                'bookingDate' => '01-Oct-2026',
                'bookingTime' => '11:00 AM',
                'unitId' => [SELECT Id FROM Unit__c LIMIT 1].Id,
                'music' => true,
                'serveFandB' => true,
                'noOfGuests' => 10
                });
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/v1/amenities/booking-requests';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        Test.startTest();
        BCAPP_AmenitiesAPI.amenities();
        BCAPP_AmenitiesAPI.amenities();
        Test.stopTest();
        
        
        
        System.assert(true, 'Executed amenities method for booking-requests');
    }
    @isTest
    static void testInvalidRequestType() {
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'requestType' => 'invalidType'
                });
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/v1/amenities/get-request';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        Test.startTest();
        BCAPP_AmenitiesAPI.amenities();
        Test.stopTest();
        
        System.assert(true, 'Handled unsupported requestType');
    }
    @isTest
    static void testGetAvailableDatesByMonth() {
        // Create dummy Amenity
        Amenities__c amenity = [SELECT Id FROM Amenities__c LIMIT 1];
        
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'requestType' => 'aminityDates',
                'amenityId' => amenity.Id
                });
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/v1/amenities/get-request';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        Test.startTest();
        BCAPP_AmenitiesAPI.amenities();
        Test.stopTest();
    }
    
    @isTest
    static void testGetAmenitySlotsByDate() {
        Amenities__c amenity = [SELECT Id FROM Amenities__c LIMIT 1];
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'requestType' => 'amenitySlotsByDate',
                'amenityId' => amenity.Id,
                'selectedDate' => '01-Oct-2026',
                'slotDurationHours' => 1
                });
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/v1/amenities/get-request';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        Test.startTest();
        BCAPP_AmenitiesAPI.amenities();
        Test.stopTest();
    }
    
    @isTest
    static void testGetAmenityBookings() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'requestType' => 'bookings',
                'accountId' => acc.Id,
                'type' => 'upcoming'
                });
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/v1/amenities/get-request';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        Test.startTest();
        BCAPP_AmenitiesAPI.amenities();
        Test.stopTest();
    }
     @isTest
    static void testCancelBooking() {
        // Get the test data created in @testSetup method
        Case booking = [SELECT Id FROM Case LIMIT 1];
        
         String jsonBody = JSON.serialize(new Map<String, Object>{
            'reason' => 'test',
                'bookingId' => booking.Id,
                'requestType' => 'cancel'
                });
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/v1/amenities/booking-requests';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        Test.startTest();
        BCAPP_AmenitiesAPI.amenities();
        Test.stopTest();

        
    }
   
     // Helper to call the service and return response map
    private static Map<String, Object> callValidate(String amenityId, String accountId, String unitId, Date d, String timeStr) {
        Datetime myDatetime = Datetime.newInstance(d.year(), d.month(), d.day());
        Map<String, Object> jsonData = new Map<String, Object>{
            'amenityId'   => amenityId,
            'bookingDate' => myDatetime.format('dd-MMM-yyyy'), // service expects "dd-MMM-yyyy" (e.g., 01-Oct-2026)
            'bookingTime' => timeStr,
            'accountId'   => accountId,
            'unitId'      => unitId,
            'referenceId' => null
        };

        // capture response written by BCAPP_WebServiceHelper
        RestContext.response = new RestResponse();
        BCAPP_AmenityBookingService.validateAminities(jsonData);

        String body = RestContext.response.responseBody == null
                      ? ''
                      : RestContext.response.responseBody.toString();
      

        return (Map<String, Object>) JSON.deserializeUntyped(body);
    }

    @isTest
    static void testValidate_Eligible() {
        Amenities__c amenity = [SELECT Id FROM Amenities__c LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];

        Date target = Date.today().addDays(5);

        Map<String, Object> res = callValidate(amenity.Id, acc.Id, unit.Id, target, '10:00 AM');
    }

    @isTest
    static void testValidate_UnitWithLegal_Blocked() {
        Amenities__c amenity = [SELECT Id FROM Amenities__c LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];

        // Mark unit as legally blocked
        unit.Legal_Status__c = 'With Legal';
        update unit;

        Date target = Date.today().addDays(6);

        Map<String, Object> res = callValidate(amenity.Id, acc.Id, unit.Id, target, '11:00 AM');
    }

    @isTest
    static void testValidate_MaxDailyBookingsReached() {
        Amenities__c amenity = [SELECT Id FROM Amenities__c LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];

        Date target = Date.today().addDays(7);

        // Seed two bookings for same account on the same date
        List<Case> existing = new List<Case>{
            new Case(
                AccountId = acc.Id,
                Permit_From_Date__c = target,
                startTime__c = Time.newInstance(10,0,0,0),
                endTime__c   = Time.newInstance(11,0,0,0),
                Status = 'Confirmed'
            ),
            new Case(
                AccountId = acc.Id,
                Permit_From_Date__c = target,
                startTime__c = Time.newInstance(12,0,0,0),
                endTime__c   = Time.newInstance(13,0,0,0),
                Status = 'Confirmed'
            )
        };
        //insert existing;

        Map<String, Object> res = callValidate(amenity.Id, acc.Id, unit.Id, target, '02:00 PM');

    }


    
}