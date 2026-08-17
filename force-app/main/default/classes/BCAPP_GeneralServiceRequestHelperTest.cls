@isTest
private class BCAPP_GeneralServiceRequestHelperTest {

    private class Seed {
        Account acc;
        User__c appUser;
        Unit__c unit;
        Service_Catalog__c scGuest;
    }

    private static Seed setupData() {
        Seed s = new Seed();

        // Account + mapped community user
        s.acc = BCAPP_TestDataFactory.createAccount('GuestMgmt AC');
        insert s.acc;

        s.appUser = BCAPP_TestDataFactory.createUser('az-guest');
        s.appUser.Account__c = s.acc.Id;
        s.appUser.User_Account__c = s.acc.Id;
        s.appUser.User_Type__c = 'Holiday Homes';
        insert s.appUser;

        // Unit
        s.unit = new Unit__c(Name = 'U-GM-001');
        insert s.unit;

        // Service Catalog for Guest Management
        s.scGuest = new Service_Catalog__c(Name = 'Guest Management', Active__c = true);
        insert s.scGuest;

        // Service Catalog field mappings used by helper (by user type "Holiday Homes")
        insert new List<Service_Catalog_Fields__c>{
            new Service_Catalog_Fields__c(
                Name = 'unitId',
                Field_API_Name__c = 'Unit__c',
                User_Type__c = 'Holiday Homes',
                is_Date__c = false,
                is_Decimal__c = false,
                Service_Catalog__c = s.scGuest.Id
            ),
            new Service_Catalog_Fields__c(
                Name = 'fromDate',
                Field_API_Name__c = 'Permit_From_Date__c',
                User_Type__c = 'Holiday Homes',
                is_Date__c = true,
                is_Decimal__c = false,
                Service_Catalog__c = s.scGuest.Id
            ),
            new Service_Catalog_Fields__c(
                Name = 'toDate',
                Field_API_Name__c = 'Permit_To_Date__c',
                User_Type__c = 'Holiday Homes',
                is_Date__c = true,
                is_Decimal__c = false,
                Service_Catalog__c = s.scGuest.Id
            )
        };

        return s;
    }

    private static Map<String, Object> parse() {
        String body = RestContext.response != null && RestContext.response.responseBody != null
            ? RestContext.response.responseBody.toString() : '';
        System.assertNotEquals('', body, 'Expected response body');
        return (Map<String, Object>) JSON.deserializeUntyped(body);
    }

    @isTest static void test_manageGuestRequest_create_success() {
        Seed s = setupData();

        // Build guests (name + base64 content)
        List<Object> guests = new List<Object>{
            new Map<String, Object>{ 'name' => 'Passport.pdf', 'document' => EncodingUtil.base64Encode(Blob.valueOf('hello')).toString() }
        };

        Map<String, Object> req = new Map<String, Object>{
            'accountId' => (String) s.acc.Id,
            'unitId'    => (String) s.unit.Id,
            'fromDate'  => '01-Jan-2026',
            'toDate'    => '02-Jan-2026',
            'guests'    => guests
        };

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();

        BCAPP_GeneralServiceRequestHelper.manageGuestRequest(JSON.serialize(req));

        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> wrapper = parse();
        Map<String, Object> data = (Map<String, Object>) wrapper.get('data');
        System.assertNotEquals(null, data.get('srId'));
        System.assertEquals('Guest Request Submitted successfully', (String) data.get('message'));
    }

    @isTest static void test_manageGuestRequest_extension_success() {
        Seed s = setupData();

        // First create a Guest request via helper to ensure all prerequisites are met
        List<Object> guests = new List<Object>{
            new Map<String, Object>{ 'name' => 'Passport.pdf', 'document' => EncodingUtil.base64Encode(Blob.valueOf('hello')).toString() }
        };
        Map<String, Object> createReq = new Map<String, Object>{
            'accountId' => (String) s.acc.Id,
            'unitId'    => (String) s.unit.Id,
            'fromDate'  => '01-Jan-2026',
            'toDate'    => '02-Jan-2026',
            'guests'    => guests
        };
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        BCAPP_GeneralServiceRequestHelper.manageGuestRequest(JSON.serialize(createReq));
        Map<String, Object> createdWrap = parse();
        Map<String, Object> createdData = (Map<String, Object>) createdWrap.get('data');
        Id srId = (Id) createdData.get('srId');

        // Now request extension on the created SR
        Map<String, Object> extReq = new Map<String, Object>{
            'accountId' => (String) s.acc.Id,
            'srId'      => (String) srId,
            'type'      => 'extension',
            'toDate'    => '05-Jan-2026'
        };
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        BCAPP_GeneralServiceRequestHelper.manageGuestRequest(JSON.serialize(extReq));

        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> wrapper = parse();
        Map<String, Object> data = (Map<String, Object>) wrapper.get('data');
        System.assertEquals('Extension Updated successfully', (String) data.get('message'));
        System.assertEquals((String) srId, (String) data.get('srId'));
    }

    @isTest static void test_getAllGuestRequest_success() {
        Seed s = setupData();
        Case guestCase = new Case(
            AccountId = s.acc.Id,
            Unit__c = s.unit.Id,
            Status = 'Submitted',
            Service_Catalog__c = s.scGuest.Id,
            Permit_From_Date__c = Date.today(),
            Permit_To_Date__c = Date.today().addDays(1),
            RecordTypeId = Utilities.getRecordTypeId('Case','General Service Request'),
            User_Type__c = 'Holiday Homes'
        );
        insert guestCase;

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        BCAPP_GeneralServiceRequestHelper.getAllGuestRequest(JSON.serialize(new Map<String, Object>{ 'accountId' => (String) s.acc.Id }));

        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> wrapper = parse();
        List<Object> data = (List<Object>) wrapper.get('data');
        System.assert(!data.isEmpty());
    }
}