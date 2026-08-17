@isTest
private class BCAPP_ServiceRequestSubmitAPITest {

    private class Seed {
        Account acc;
        Unit__c unit;
        User__c appUser;
        Unit_Allocation__c alloc;
        Service_Catalog__c sc;
        AccessCard__c card;
        OnlinePayment__c payment;
        OnlinePaymentLineItem__c line;
    }

    private static Seed setupData() {
        Seed s = new Seed();

        // Account + mapped community user
        s.acc = BCAPP_TestDataFactory.createAccount('SR Submit AC');
        s.acc.SAP_BP_No__c = 'ACC-SRS-001';
        insert s.acc;

        s.appUser = BCAPP_TestDataFactory.createUser('az-srs');
        s.appUser.Account__c = s.acc.Id;
        s.appUser.User_Account__c = s.acc.Id;
        s.appUser.User_Type__c = 'Owner';
        s.appUser.Email__c = 'user@test.com';
        insert s.appUser;

        // Unit
        Project__c project = new Project__c(Name = 'SR Project');
        insert project;

        s.unit = new Unit__c(
            Name = 'U-SRS-001',
            Project__c = project.Id,
            CommunityCompanyCode__c = '1400',
            CommunitySAPUnitNumber__c = '1400'
        );
        insert s.unit;

        insert new Unit_Allocation__c(
            Unit__c = s.unit.Id,
            Account__c = s.acc.Id,
            User__c = s.appUser.Id,
            Start_Date__c = Date.today().addDays(-5),
            Active__c = true,
            User_Type__c = 'Owner'
        );

        // Active allocation reference for other tests
        s.alloc = [SELECT Id FROM Unit_Allocation__c WHERE Unit__c = :s.unit.Id LIMIT 1];

        // Service Catalog for Access Card
        s.sc = new Service_Catalog__c(Name = 'Access Card', Active__c = true, Amount__c = 100);
        insert s.sc;

        // Active access card for validation
        s.card = new AccessCard__c(
            CardNumber__c = 'CARD-API-01',
            CardType__c = 'Lobby',
            UserType__c = 'Owner',
            Status__c = 'Activated',
            Account__c = s.acc.Id,
            Unit__c = s.unit.Id
        );
        insert s.card;

        // Payment + line item to attach SR Id
        s.payment = new OnlinePayment__c(
            Status__c = 'Success',
            RequestSource__c = 'API',
            RequestType__c = 'AccessCard',
            PaidAmount__c = 100,
            Account__c = s.acc.Id,
            Unit__c = s.unit.Id,
            PaymentMethod__c = 'CARD'
        );
        insert s.payment;
        s.line = new OnlinePaymentLineItem__c(
            OnlinePayment__c = s.payment.Id,
            PlannedAmount__c = 100
        );
        insert s.line;

        return s;
    }

    private static Map<String, Object> parse() {
        String body = RestContext.response != null && RestContext.response.responseBody != null
            ? RestContext.response.responseBody.toString() : '';
        System.assertNotEquals('', body, 'Expected response body');
        return (Map<String, Object>) JSON.deserializeUntyped(body);
    }

    private static void setReq(Map<String, Object> payload) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/v1/service-request-submit';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    @isTest static void test_submit_accesscard_request_success() {
        Seed s = setupData();

        Map<String, Object> payload = new Map<String, Object>{
            'requestType' => 'accesscardrequest',
            'accountId'   => (String) s.acc.Id,     // user lookup expects User_Account__c id
            'unitId'      => (String) s.unit.Id,
            'requestType' => 'accesscardrequest',
            'referenceId' => (String) s.payment.Id,
            'request'     => 'Replace',
            'cardNumbers' => new List<String>{ s.card.CardNumber__c }
        };
        // Align with helper expected key for request type name
        payload.put('requestType', 'accesscardrequest');
        payload.put('requestTypeName', 'Replace');

        setReq(payload);
        BCAPP_ServiceRequestSubmitAPI.submitRequest();

        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> wrap = parse();
        Map<String, Object> data = (Map<String, Object>) wrap.get('data');
        Id srId = (Id) data.get('srId');
        System.assertNotEquals(null, srId, 'SR should be created');

        // Line item should be linked to SR
        OnlinePaymentLineItem__c li = [SELECT Case__c FROM OnlinePaymentLineItem__c WHERE Id = :s.line.Id LIMIT 1];
        System.assertEquals(srId, li.Case__c);
    }

    @isTest static void test_submit_missing_type_error() {
        setReq(new Map<String, Object>());
        BCAPP_ServiceRequestSubmitAPI.submitRequest();
        System.assertEquals(500, RestContext.response.statusCode);
        Map<String, Object> wrap = parse();
        System.assertEquals(false, (Boolean) wrap.get('success'));
    }
}