@isTest
private class BCAPP_AccessCardAPITest {

    // Utility: build basic Account, Unit, User__c, Service Catalog and Access Cards
    private class TestSetupData {
        Account acc;
        Unit__c unit;
        User__c appUser;
        Service_Catalog__c scAccessCard;
        List<AccessCard__c> cards;
    }

    private static TestSetupData createBaseData(Boolean withActiveResident) {
        TestSetupData data = new TestSetupData();

        // Account
        data.acc = BCAPP_TestDataFactory.createAccount('Test Account');
        insert data.acc;

        // Unit
        data.unit = new Unit__c(Name = 'U-1001', Legal_Status__c = null);
        insert data.unit;

        // User__c referenced by helper via User_Account__c
        data.appUser = BCAPP_TestDataFactory.createUser('az-123');
        data.appUser.Account__c = data.acc.Id;
        data.appUser.User_Account__c = data.acc.Id;
        data.appUser.User_Type__c = 'Owner';
        insert data.appUser;

        // Active allocation for account+unit today
        Unit_Allocation__c alloc = new Unit_Allocation__c(
            Unit__c = data.unit.Id,
            Account__c = data.acc.Id,
            User__c = data.appUser.Id,
            Start_Date__c = Date.today().addDays(-10),
            End_Date__c = null,
            Active__c = true,
            User_Type__c = 'Owner'
        );
        insert alloc;

        // Optional: add an active resident allocation (Tenant/Holiday Homes) to block owner
        if (withActiveResident) {
            Unit_Allocation__c resident = new Unit_Allocation__c(
                Unit__c = data.unit.Id,
                Account__c = data.acc.Id,
                User__c = data.appUser.Id,
                Start_Date__c = Date.today().addDays(-5),
                End_Date__c = null,
                Active__c = true,
                User_Type__c = 'Tenant'
            );
            insert resident;
        }

        // Service Catalog for Access Card with Amount
        data.scAccessCard = new Service_Catalog__c(
            Name = 'Access Card',
            Active__c = true,
            Amount__c = 100
        );
        insert data.scAccessCard;

        // Active Access Card(s)
        data.cards = new List<AccessCard__c>{
            new AccessCard__c(
                CardNumber__c = 'CARD-001',
                CardType__c = 'Lobby',
                UserType__c = 'Owner',
                ResidentName__c = 'John Doe',
                Status__c = 'Activated',
                Account__c = data.acc.Id,
                Unit__c = data.unit.Id
            )
        };
        insert data.cards;

        return data;
    }

    // Helper to set Rest request and execute
    private static Map<String, Object> invokeApi(Map<String, Object> payload) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/v1/get-access-card';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        RestContext.request = req;
        RestContext.response = new RestResponse();

        BCAPP_AccessCardAPI.handleAccessCardApi();

        String body = RestContext.response.responseBody == null ? '' : RestContext.response.responseBody.toString();
        System.assertNotEquals('', body, 'Response body should not be empty');
        return (Map<String, Object>) JSON.deserializeUntyped(body);
    }

    @isTest static void test_getAccessCards_success() {
        TestSetupData data = createBaseData(false);

        Map<String, Object> payload = new Map<String, Object>{
            'operation' => 'getaccesscards',
            'accountId' => (String) data.acc.Id,
            'unitId'    => (String) data.unit.Id
        };

        Map<String, Object> res = invokeApi(payload);
        System.assertEquals(200, RestContext.response.statusCode, 'HTTP 200 expected');
        System.assertEquals(true, (Boolean) res.get('success'));

        // Response shape: { success:true, data:{ data:[{...}] } }
        Map<String, Object> outerData = (Map<String, Object>) res.get('data');
        System.assertNotEquals(null, outerData, 'Outer data should exist');
        List<Object> listData = (List<Object>) outerData.get('data');
        System.assert(listData != null && !listData.isEmpty(), 'Active cards list should not be empty');

        Map<String, Object> first = (Map<String, Object>) listData[0];
        System.assertEquals('CARD-001', (String) first.get('cardNumber'));
        System.assertEquals('Activated', (String) first.get('status'));
        System.assertEquals(Decimal.valueOf(100), (Decimal) first.get('Amount'));
    }

    @isTest static void test_checkEligibility_true_forOwner_noResidents() {
        TestSetupData data = createBaseData(false);

        Map<String, Object> payload = new Map<String, Object>{
            'operation' => 'geteligibleaccesscards',
            'accountId' => (String) data.acc.Id,
            'unitId'    => (String) data.unit.Id
        };

        Map<String, Object> res = invokeApi(payload);
        System.assertEquals(200, RestContext.response.statusCode, 'HTTP 200 expected');
        System.assertEquals(true, (Boolean) res.get('success'));

        Map<String, Object> dataMap = (Map<String, Object>) res.get('data');
        System.assertEquals(true, (Boolean) dataMap.get('isEligible'));
        System.assertEquals('Owner', (String) dataMap.get('userType'));
    }

    @isTest static void test_checkEligibility_ownerBlocked_dueToActiveResidents() {
        TestSetupData data = createBaseData(true);

        Map<String, Object> payload = new Map<String, Object>{
            'operation' => 'geteligibleaccesscards',
            'accountId' => (String) data.acc.Id,
            'unitId'    => (String) data.unit.Id
        };

        Map<String, Object> res = invokeApi(payload);
        System.assertEquals(200, RestContext.response.statusCode, 'HTTP 200 expected');
        System.assertEquals(true, (Boolean) res.get('success'));

        Map<String, Object> dataMap = (Map<String, Object>) res.get('data');
        System.assertEquals(false, (Boolean) dataMap.get('isEligible'));
        System.assert(((String) dataMap.get('message')).contains('Owner cannot request'));
    }

    @isTest static void test_missingOperation_error() {
        Map<String, Object> payload = new Map<String, Object>{
            // no operation key
        };
        Map<String, Object> res = invokeApi(payload);
        System.assertEquals(500, RestContext.response.statusCode, 'HTTP 500 expected');
        System.assertEquals(false, (Boolean) res.get('success'));
        Map<String, Object> err = (Map<String, Object>) res.get('error');
        System.assertEquals('Missing operation key', (String) err.get('errorMessage'));
    }

    @isTest static void test_unsupportedOperation_error() {
        Map<String, Object> payload = new Map<String, Object>{
            'operation' => 'unknown-op'
        };
        Map<String, Object> res = invokeApi(payload);
        System.assertEquals(500, RestContext.response.statusCode, 'HTTP 500 expected');
        System.assertEquals(false, (Boolean) res.get('success'));
        Map<String, Object> err = (Map<String, Object>) res.get('error');
        System.assert(((String) err.get('errorMessage')).startsWith('Unsupported operation'));
    }
}