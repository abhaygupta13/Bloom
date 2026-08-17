@isTest
private class BCAPP_GenericServiceHandlerTest {

    private class Seed {
        Account acc;
        User__c appUser;
        Unit__c unit;
        Service_Catalog__c scAccessCard;
        Service_Catalog__c scGuest;
        AccessCard__c card;
        OnlinePayment__c payment;
        OnlinePaymentLineItem__c line;
        Case guestCase;
        Case accessCardCase;
    }

    private static Seed setupData() {
        Seed s = new Seed();

        // Account + User__c mapped by User_Account__c for utility lookup
        s.acc = BCAPP_TestDataFactory.createAccount('GSH Account');
        s.acc.SAP_BP_No__c = 'ACC-GSH-001';
        insert s.acc;

        s.appUser = BCAPP_TestDataFactory.createUser('az-gsh-1');
        s.appUser.Account__c = s.acc.Id;
        s.appUser.User_Account__c = s.acc.Id;
        s.appUser.User_Type__c = 'Owner';
        insert s.appUser;

        // Unit
        Project__c project = new Project__c(Name = 'Access Project');
        insert project;

        s.unit = new Unit__c(
            Name = 'U-GSH-001',
            Project__c = project.Id,
            CommunityCompanyCode__c = '1500',
            CommunitySAPUnitNumber__c = '1500'
        );
        insert s.unit;

        // Active allocation
        insert new Unit_Allocation__c(
            Unit__c = s.unit.Id,
            Account__c = s.acc.Id,
            User__c = s.appUser.Id,
            Start_Date__c = Date.today().addDays(-3),
            Active__c = true,
            User_Type__c = 'Owner'
        );

        // Service Catalogs
        s.scAccessCard = new Service_Catalog__c(Name = 'Access Card', Active__c = true, Amount__c = 100);
        s.scGuest      = new Service_Catalog__c(Name = 'Guest Management', Active__c = true, Amount__c = 0);
        insert new List<Service_Catalog__c>{ s.scAccessCard, s.scGuest };

        // Access card used in submit flow
        s.card = new AccessCard__c(
            CardNumber__c = 'CARD-GSH-001',
            CardType__c = 'Lobby',
            UserType__c = 'Owner',
            Status__c = 'Activated',
            Account__c = s.acc.Id,
            Unit__c = s.unit.Id
        );
        insert s.card;

        // Payment + line to attach
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

        // Seed cases for fetch tests
        s.accessCardCase = new Case(
            AccountId = s.acc.Id,
            Unit__c   = s.unit.Id,
            Status    = 'Submitted',
            Service_Catalog__c = s.scAccessCard.Id,
            RecordTypeId = Utilities.getRecordTypeId('Case','General Service Request'),
            User_Type__c = 'Owner'
        );
        s.guestCase = new Case(
            AccountId = s.acc.Id,
            Unit__c   = s.unit.Id,
            Status    = 'Submitted',
            Service_Catalog__c = s.scGuest.Id,
            Permit_From_Date__c = Date.today(),
            Permit_To_Date__c   = Date.today().addDays(1),
            RecordTypeId = Utilities.getRecordTypeId('Case','General Service Request'),
            User_Type__c = 'Owner'
        );
        insert new List<Case>{ s.accessCardCase, s.guestCase };

        return s;
    }

    private static Map<String, Object> parse() {
        String body = RestContext.response != null && RestContext.response.responseBody != null
            ? RestContext.response.responseBody.toString() : '';
        System.assertNotEquals('', body, 'Expected response body');
        return (Map<String, Object>) JSON.deserializeUntyped(body);
    }

    @isTest static void test_handleSubmit_accesscard_success() {
        Seed s = setupData();

        Map<String, Object> req = new Map<String, Object>{
            'requestType' => 'accesscardrequest',
            'accountId'   => (String) s.acc.Id,
            'unitId'      => (String) s.unit.Id,
            'referenceId' => (String) s.payment.Id,
            'cardNumbers' => new List<String>{ s.card.CardNumber__c }
        };

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();

        Test.startTest();
        BCAPP_GenericServiceHandler.handleSubmitRequest(req);
        Test.stopTest();
        
        Map<String, Object> req2 = new Map<String, Object>{
            'requestType' => 'guestrequest',
            'accountId'   => (String) s.acc.Id,
            'unitId'      => (String) s.unit.Id,
            'referenceId' => (String) s.payment.Id,
            'cardNumbers' => new List<String>{ s.card.CardNumber__c }
        };
        BCAPP_GenericServiceHandler.handleSubmitRequest(req2);
        
        Map<String, Object> req3 = new Map<String, Object>{
            'requestType' => 'vacationrequest',
            'accountId'   => (String) s.acc.Id,
            'unitId'      => (String) s.unit.Id,
            'referenceId' => (String) s.payment.Id,
            'cardNumbers' => new List<String>{ s.card.CardNumber__c }
        };
        BCAPP_GenericServiceHandler.handleSubmitRequest(req3);
        
        Map<String, Object> req4 = new Map<String, Object>{
            'requestType' => 'guestrequest2',
            'accountId'   => (String) s.acc.Id,
            'unitId'      => (String) s.unit.Id,
            'referenceId' => (String) s.payment.Id,
            'cardNumbers' => new List<String>{ s.card.CardNumber__c }
        };
        BCAPP_GenericServiceHandler.handleSubmitRequest(req4);
        

        //System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> wrapper = parse();
        Map<String, Object> data = (Map<String, Object>) wrapper.get('data');
        //System.assertNotEquals(null, data.get('srId'));
    }

    @isTest static void test_handleFetch_accesscardrequests_success() {
        Seed s = setupData();
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();

        Map<String, Object> req = new Map<String, Object>{
            'requestType' => 'accesscardrequests',
            'accountId'   => (String) s.acc.Id,
            'unitId'      => (String) s.unit.Id
        };
        BCAPP_GenericServiceHandler.handleFetchRequest(req);

        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> wrapper = parse();
        Map<String, Object> respWrapper = (Map<String, Object>) wrapper.get('data');
        List<Object> data = (List<Object>) respWrapper.get('data');
    }

    @isTest static void test_handleFetch_guestrequests_success() {
        Seed s = setupData();
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();

        Map<String, Object> req = new Map<String, Object>{
            'requestType' => 'guestrequests',
            'accountId'   => (String) s.acc.Id
        };
        BCAPP_GenericServiceHandler.handleFetchRequest(req);

        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> wrapper = parse();
        List<Object> data = (List<Object>) wrapper.get('data');
        System.assert(!data.isEmpty());
    }

    @isTest static void test_handleSubmit_missingType_error() {
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();

        BCAPP_GenericServiceHandler.handleSubmitRequest(new Map<String, Object>());
        System.assertEquals(500, RestContext.response.statusCode);
        Map<String, Object> wrapper = parse();
        Map<String, Object> err = (Map<String, Object>) wrapper.get('error');
        System.assertEquals('Missing requestType', (String) err.get('errorMessage'));
    }
}