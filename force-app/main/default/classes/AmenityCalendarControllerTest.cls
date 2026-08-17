@isTest
private class AmenityCalendarControllerTest {

    private class Seed {
        Project__c project;
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

        // Project
        s.project = new Project__c(Name = 'Test Community',isEnabledMIP__c = true);
        insert s.project;

        // Building/Phase required for Amenity
        BuildingSection__c bld = new BuildingSection__c(
            Name = 'BLD-1',
            BuildingSectionCode__c = 'BL-CAS',
            Project__c = s.project.Id
        );
        insert bld;

        // Amenity (reservable, with schedule and 60-min slots)
        s.amenity = new Amenities__c(
            Name = 'Pool',
            Project__c = s.project.Id,
            Building_Phase__c = bld.Id,
            isReservation__c = true,
            isPaid__c = false,
            dailyStartTime__c = Time.newInstance(8, 0, 0, 0),
            dailyEndTime__c = Time.newInstance(10, 0, 0, 0),
            slotDurationInMinutes__c = 60
        );
        insert s.amenity;

        // Account + mobile user mapping
        s.acc = BCAPP_TestDataFactory.createAccount('Amenity AC');
        insert s.acc;
        s.appUser = BCAPP_TestDataFactory.createUser('az-amenity');
        s.appUser.Account__c = s.acc.Id;
        s.appUser.User_Account__c = s.acc.Id;
        s.appUser.User_Type__c = 'Owner';
        insert s.appUser;

        // Unit under the same project
        s.unit = new Unit__c(Name = 'U-AM-001', Project__c = s.project.Id);
        insert s.unit;

        // Service Catalog for Amenities
        s.scAmenities = new Service_Catalog__c(Name = 'Amenities', Active__c = true, Amount__c = 50);
        insert s.scAmenities;

        // Optional payment + line for bookUnpaidAmenitySlot path
        s.payment = new OnlinePayment__c(Status__c = 'Pending', RequestSource__c = 'API', RequestType__c = 'Amenity', PaidAmount__c = 50);
        insert s.payment;
        s.line = new OnlinePaymentLineItem__c(OnlinePayment__c = s.payment.Id);
        insert s.line;

        return s;
    }

    @isTest static void test_getAmenitiesByProject_and_wrapper() {
        Seed s = setupData();

        // getAmenitiesByProject
        List<Amenities__c> ams = AmenityCalendarController.getAmenitiesByProject(s.project.Id);
        System.assertEquals(1, ams.size());
        System.assertEquals(s.amenity.Id, ams[0].Id);

        // getCommunitiesAndAmenities
        AmenityCalendarController.AmenityCommunityWrapper wrp = AmenityCalendarController.getCommunitiesAndAmenities();
        System.assert(wrp != null);
        System.assert(!wrp.communities.isEmpty());
        System.assert(!wrp.amenities.isEmpty());
    }

    @isTest static void test_getSlotsForDateUnpaidSF_basic() {
        Seed s = setupData();

        Map<String, Object> req = new Map<String, Object>{
            'amenityId' => (String) s.amenity.Id,
            'selectedDate' => '01-Jan-2026'
        };
        String reqJson = JSON.serialize(req);
        String res = AmenityCalendarController.getSlotsForDateUnapidSF(reqJson);
        List<Object> slots = (List<Object>) JSON.deserializeUntyped(res);
        System.assert(!slots.isEmpty(), 'Expected some time slots');

        // Expect 2 slots: 8:00–9:00 and 9:00–10:00 based on 8–10 and 60-min duration
        System.assertEquals(2, slots.size());
        Map<String, Object> first = (Map<String, Object>) slots[0];
        System.assertEquals('8:00 AM', (String) first.get('start'));
        System.assertEquals('9:00 AM', (String) first.get('end'));
    }

    @isTest static void test_bookUnpaidAmenitySlot_creates_case_and_links_payment() {
        Seed s = setupData();

        Map<String, Object> req = new Map<String, Object>{
            'amenityId'   => (String) s.amenity.Id,
            'bookingDate' => '01-Jan-2026',
            'bookingTime' => '8:00 AM',
            'accountId'   => (String) s.acc.Id,
            'unitId'      => (String) s.unit.Id,
            'referenceId' => (String) s.payment.Id
        };
        String result = AmenityCalendarController.bookUnpaidAmenitySlot(JSON.serialize(req));
        Map<String, Object> resp = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(true, (Boolean) resp.get('success'));
        Id bookingId = (Id) resp.get('bookingId');
        System.assertNotEquals(null, bookingId);

        Case c = [SELECT Status, Amenities__c, Unit__c, Project__c, Service_Catalog__r.Name FROM Case WHERE Id = :bookingId LIMIT 1];
        System.assertEquals('Confirmed', c.Status);
        System.assertEquals(s.amenity.Id, c.Amenities__c);
        System.assertEquals('Amenities', c.Service_Catalog__r.Name);

        OnlinePaymentLineItem__c li = [SELECT Case__c FROM OnlinePaymentLineItem__c WHERE Id = :s.line.Id LIMIT 1];
        System.assertEquals(bookingId, li.Case__c);
    }

    @isTest static void test_getBookingSlots_marks_booked_hour() {
        Seed s = setupData();

        // Create an existing booking at 9:00 AM
        Case existing = new Case(
            RecordTypeId = Utilities.getRecordTypeId('Case', 'Community General Service Request'),
            Status = 'Confirmed',
            Project__c = s.project.Id,
            Amenities__c = s.amenity.Id,
            Permit_From_Date__c = Date.newInstance(2026, 1, 1),
            startTime__c = Time.newInstance(9, 0, 0, 0),
            endTime__c = Time.newInstance(10, 0, 0, 0),
            Origin = 'Community App',
            Subject = 'Amenity Booking'
        );
        insert existing;
        String expectedCaseNumber = [SELECT CaseNumber FROM Case WHERE Id = :existing.Id].CaseNumber;

        List<Case> fetched = CaseService.getInstance().fetchBookedAmenityByDateRange(
            Date.newInstance(2026, 1, 1),
            Date.newInstance(2026, 1, 1),
            (String) s.project.Id,
            (String) s.amenity.Id
        );
        System.assertEquals(1, fetched.size(), 'Expected helper service to return the seeded booking');

        String slotsJson = AmenityCalendarController.getBookingSlots('2026-01-01', '2026-01-01', (String) s.project.Id, (String) s.amenity.Id);
        List<Object> slots = (List<Object>) JSON.deserializeUntyped(slotsJson);

        // Find 9:00 AM slot on that date
        Boolean foundBooked = false;
        for (Object o : slots) {
            Map<String, Object> m = (Map<String, Object>) o;
            if ((String) m.get('date') == '2026-01-01' && (String) m.get('startTime') == '09:00:00') {
                foundBooked = ((String) m.get('status')) == 'Confirmed';
                Object bookingNumber = m.get('bookingNumber');
                System.assertNotEquals(null, bookingNumber, 'Expected booking number to be present');
                break;
            }
        }
        System.assert(foundBooked, 'Expected 9:00 AM to be marked Confirmed');
    }
}