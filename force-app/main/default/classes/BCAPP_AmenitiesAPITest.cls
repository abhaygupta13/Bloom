@isTest
private class BCAPP_AmenitiesAPITest {

    private class Seed {
        Project__c project;
        BuildingSection__c building;
        Amenities__c amenity;
        Account acc;
        User__c appUser;
        Unit__c unit;
        Service_Catalog__c scAmenities;
        OnlinePayment__c payment;
        OnlinePaymentLineItem__c line;
    }

    private static Seed setupData() {
        Seed s = new Seed();

        s.project = new Project__c(Name = 'Amenity Project');
        insert s.project;

        s.building = new BuildingSection__c(
            Name = 'BLD-API-1',
            BuildingSectionCode__c = 'BL-API',
            Project__c = s.project.Id
        );
        insert s.building;

        s.amenity = new Amenities__c(
            Name = 'Gym',
            Project__c = s.project.Id,
            Building_Phase__c = s.building.Id,
            isReservation__c = true,
            isPaid__c = false,
            userAccess__c = 'Owner',
            dailyStartTime__c = Time.newInstance(8, 0, 0, 0),
            dailyEndTime__c = Time.newInstance(10, 0, 0, 0),
            slotDurationInMinutes__c = 60
        );
        insert s.amenity;

        s.acc = BCAPP_TestDataFactory.createAccount('Amenity API AC');
        insert s.acc;

        s.appUser = BCAPP_TestDataFactory.createUser('az-amenity-api');
        s.appUser.Account__c = s.acc.Id;
        s.appUser.User_Account__c = s.acc.Id;
        s.appUser.User_Type__c = 'Owner';
        insert s.appUser;

        s.unit = new Unit__c(Name = 'U-AM-API-001', Project__c = s.project.Id);
        insert s.unit;

        // Active allocation for account+unit to satisfy validations
        insert new Unit_Allocation__c(
            Unit__c = s.unit.Id,
            Account__c = s.acc.Id,
            User__c = s.appUser.Id,
            Start_Date__c = Date.today().addDays(-1),
            Active__c = true,
            User_Type__c = 'Owner'
        );

        s.scAmenities = new Service_Catalog__c(Name = 'Amenities', Active__c = true, Amount__c = 25);
        insert s.scAmenities;

        s.payment = new OnlinePayment__c(Status__c = 'Pending', RequestSource__c = 'API', RequestType__c = 'Amenity', PaidAmount__c = 25);
        insert s.payment;
        s.line = new OnlinePaymentLineItem__c(OnlinePayment__c = s.payment.Id);
        insert s.line;

        return s;
    }

    private static Map<String, Object> respWrapper() {
        String body = RestContext.response != null && RestContext.response.responseBody != null
            ? RestContext.response.responseBody.toString() : '';
        System.assertNotEquals('', body, 'Expected response body');
        return (Map<String, Object>) JSON.deserializeUntyped(body);
    }

    private static void setReq(String uriSuffix, Map<String, Object> payload) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/v1/amenities/' + uriSuffix;
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    @isTest static void test_get_request_amenities_success() {
        Seed s = setupData();
        // Note: API expects key 'projectId' but service uses it as unitId.
        Map<String, Object> payload = new Map<String, Object>{
            'requestType' => 'aminities',
            'projectId'   => (String) s.unit.Id,
            'accountId'   => (String) s.acc.Id
        };
        setReq('get-request', payload);
        BCAPP_AmenitiesAPI.amenities();
        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> wrap = respWrapper();
        System.assertEquals(true, (Boolean) wrap.get('success'));
        List<Object> data = (List<Object>) wrap.get('data');
        System.assert(!data.isEmpty());
    }

    @isTest static void test_get_request_amenity_slots_success() {
        Seed s = setupData();
        Map<String, Object> payload = new Map<String, Object>{
            'requestType' => 'amenitySlotsByDate',
            'amenityId'   => (String) s.amenity.Id,
            'selectedDate'=> '01-Jan-2026'
        };
        setReq('get-request', payload);
        BCAPP_AmenitiesAPI.amenities();
        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> wrap = respWrapper();
        System.assertEquals(true, (Boolean) wrap.get('success'));
        List<Object> data = (List<Object>) wrap.get('data');
        System.assert(!data.isEmpty());
    }

    @isTest static void test_get_request_missing_type_error() {
        setReq('get-request', new Map<String, Object>());
        BCAPP_AmenitiesAPI.amenities();
        System.assertEquals(500, RestContext.response.statusCode);
        Map<String, Object> wrap = respWrapper();
        System.assertEquals(false, (Boolean) wrap.get('success'));
        System.assertEquals('Missing requestType', (String) ((Map<String, Object>) wrap.get('error')).get('errorMessage'));
    }

    @isTest static void test_booking_create_and_cancel() {
        Seed s = setupData();
        Map<String, Object> createReq = new Map<String, Object>{
            'requestType' => 'create',
            'amenityId'   => (String) s.amenity.Id,
            'bookingDate' => '01-Jan-2026',
            'bookingTime' => '8:00 AM',
            'accountId'   => (String) s.acc.Id,
            'unitId'      => (String) s.unit.Id,
            'referenceId' => (String) s.payment.Id
        };
        setReq('booking-requests', createReq);
        BCAPP_AmenitiesAPI.amenities();
        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> wrap = respWrapper();
        System.assertEquals(true, (Boolean) wrap.get('success'));
        Id bookingId = (Id) ((Map<String, Object>) wrap.get('data')).get('bookingId');
        System.assertNotEquals(null, bookingId);

        // cancel
        Map<String, Object> cancelReq = new Map<String, Object>{
            'requestType' => 'cancel',
            'bookingId'   => (String) bookingId,
            'reason'      => 'Testing cancel'
        };
        setReq('booking-requests', cancelReq);
        BCAPP_AmenitiesAPI.amenities();
        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> wrap2 = respWrapper();
        System.assertEquals(true, (Boolean) wrap2.get('success'));
    }

    @isTest static void test_unsupported_types() {
        // Unsupported get-request type
        setReq('get-request', new Map<String, Object>{ 'requestType' => 'unknown' });
        BCAPP_AmenitiesAPI.amenities();
        System.assertEquals(500, RestContext.response.statusCode);

        // Unsupported booking type
        setReq('booking-requests', new Map<String, Object>{ 'requestType' => 'unknown' });
        BCAPP_AmenitiesAPI.amenities();
        System.assertEquals(500, RestContext.response.statusCode);
    }
}