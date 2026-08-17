@isTest
private class BCAPP_AccessCardServiceHandlerTest {

    private class SetupCtx {
        Account acc;
        Unit__c unit;
        User__c appUser;
        Service_Catalog__c sc;
        AccessCard__c card;
        OnlinePayment__c payment;
        OnlinePaymentLineItem__c line;
    }

    private static SetupCtx seed(Boolean withActiveCard) {
        SetupCtx s = new SetupCtx();

        s.acc = BCAPP_TestDataFactory.createAccount('SvcHandler – Account');
        s.acc.SAP_BP_No__c = 'ACC-SVC-001';
        insert s.acc;

        Project__c project = new Project__c(Name = 'Svc Project');
        insert project;

        s.unit = new Unit__c(
            Name = 'U-SVC-001',
            Project__c = project.Id,
            CommunityCompanyCode__c = '1600',
            CommunitySAPUnitNumber__c = '1600'
        );
        insert s.unit;

        s.appUser = BCAPP_TestDataFactory.createUser('az-svc-1');
        s.appUser.Account__c = s.acc.Id;
        s.appUser.User_Account__c = s.acc.Id;
        s.appUser.User_Type__c = 'Owner';
        s.appUser.Email__c = 'test123@yopmail.com';
        insert s.appUser;

        insert new Unit_Allocation__c(
            Unit__c = s.unit.Id,
            Account__c = s.acc.Id,
            User__c = s.appUser.Id,
            Start_Date__c = Date.today().addDays(-7),
            Active__c = true,
            User_Type__c = 'Owner'
        );

        s.sc = new Service_Catalog__c(Name = 'Access Card', Active__c = true, Amount__c = 150);
        insert s.sc;

        if (withActiveCard) {
            s.card = new AccessCard__c(
                CardNumber__c = 'CARD-SVC-001',
                CardType__c = 'Lobby',
                UserType__c = 'Owner',
                Status__c = 'Activated',
                Account__c = s.acc.Id,
                Unit__c = s.unit.Id
            );
            insert s.card;
        }

        s.payment = new OnlinePayment__c(
            Status__c = 'Success',
            RequestSource__c = 'API',
            RequestType__c = 'AccessCard',
            PaidAmount__c = 150,
            Account__c = s.acc.Id,
            Unit__c = s.unit.Id,
            PaymentMethod__c = 'CARD'
        );
        insert s.payment;
        s.line = new OnlinePaymentLineItem__c(
            OnlinePayment__c = s.payment.Id,
            PlannedAmount__c = 150
        );
        insert s.line;

        return s;
    }

    private static Map<String, Object> parseWrapper() {
        String body = RestContext.response != null && RestContext.response.responseBody != null
            ? RestContext.response.responseBody.toString() : '';
        System.assertNotEquals('', body, 'Expected response body');
        return (Map<String, Object>) JSON.deserializeUntyped(body);
    }

    private static void initRest() {
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
    }

    @isTest static void test_getActiveCards_delegates_success() {
        SetupCtx s = seed(true);
        Map<String, Object> req = new Map<String, Object>{
            'accountId' => (String) s.acc.Id,
            'unitId'    => (String) s.unit.Id
        };

        initRest();
        BCAPP_AccessCardServiceHandler.getActiveCards(req);

        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> wrapper = parseWrapper();
        List<Object> rows = (List<Object>) ((Map<String, Object>) wrapper.get('data')).get('data');
        System.assertEquals(1, rows.size());
        System.assertEquals('CARD-SVC-001', (String) ((Map<String, Object>) rows[0]).get('cardNumber'));
    }

    @isTest static void test_checkEligibility_delegates_success() {
        SetupCtx s = seed(true);
        Map<String, Object> req = new Map<String, Object>{
            'accountId' => (String) s.acc.Id,
            'unitId'    => (String) s.unit.Id
        };

        initRest();
        BCAPP_AccessCardServiceHandler.checkEligibility(req);

        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> wrapper = parseWrapper();
        Map<String, Object> data = (Map<String, Object>) wrapper.get('data');
        System.assertEquals(true, (Boolean) data.get('isEligible'));
        System.assertEquals('Owner', (String) data.get('userType'));
    }

    @isTest static void test_handleSubmit_delegates_success_and_attachesPayment() {
        SetupCtx s = seed(true);

        Map<String, Object> req = new Map<String, Object>{
            'accountId'   => (String) s.acc.Id,
            'unitId'      => (String) s.unit.Id,
            'requestType' => 'Replace',
            'referenceId' => (String) BCAPP_Utility.encryptId(s.payment.Id),
            'cardNumbers' => new List<String>{ s.card.CardNumber__c }
        };

        initRest();
        Test.startTest();
        BCAPP_AccessCardServiceHandler.handleSubmit(req);
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> wrapper = parseWrapper();
        Map<String, Object> data = (Map<String, Object>) wrapper.get('data');
        Id srId = (Id) data.get('srId');
        System.assertNotEquals(null, srId);

        OnlinePaymentLineItem__c li = [SELECT Case__c FROM OnlinePaymentLineItem__c WHERE Id = :s.line.Id];
        System.assertEquals(srId, li.Case__c);
    }

    @isTest static void test_handleSubmit_delegates_error_forMissingCards() {
        SetupCtx s = seed(true);
        Map<String, Object> req = new Map<String, Object>{
            'accountId'   => (String) s.acc.Id,
            'unitId'      => (String) s.unit.Id,
            'requestType' => 'Replace',
            'referenceId' => (String) BCAPP_Utility.encryptId(s.payment.Id),
            'cardNumbers' => new List<String>() // empty list → error
        };

        initRest();
        BCAPP_AccessCardServiceHandler.handleSubmit(req);

        System.assertEquals(500, RestContext.response.statusCode);
        Map<String, Object> wrapper = parseWrapper();
        System.assertEquals(false, (Boolean) wrapper.get('success'));
        Map<String, Object> err = (Map<String, Object>) wrapper.get('error');
        System.assertEquals('At least one card number must be provided for replacement.', (String) err.get('errorMessage'));
    }

    @isTest static void test_handleSubmit_missing_payment_reference() {
        SetupCtx s = seed(true);
        Map<String, Object> req = new Map<String, Object>{
            'accountId'   => (String) s.acc.Id,
            'unitId'      => (String) s.unit.Id,
            'requestType' => 'Replace',
            'cardNumbers' => new List<String>{ s.card.CardNumber__c }
        };

        initRest();
        BCAPP_AccessCardServiceHandler.handleSubmit(req);
        System.assertEquals(500, RestContext.response.statusCode);
        Map<String, Object> errWrapper = parseWrapper();
        Map<String, Object> error = (Map<String, Object>) errWrapper.get('error');
        System.assertEquals('Missing payment reference.', (String) error.get('errorMessage'));
    }

    @isTest static void test_handleSubmit_rejects_reused_payment() {
        SetupCtx s = seed(true);
        Map<String, Schema.RecordTypeInfo> caseRt = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName();
        Id rtId = caseRt.isEmpty() ? Schema.SObjectType.Case.getRecordTypeInfos()[0].getRecordTypeId() : caseRt.values()[0].getRecordTypeId();
        Case existingCase = new Case(
            AccountId = s.acc.Id,
            Unit__c = s.unit.Id,
            Service_Catalog__c = s.sc.Id,
            Status = 'Submitted',
            RecordTypeId = rtId
        );
        insert existingCase;

        s.line.Case__c = existingCase.Id;
        update s.line;

        Map<String, Object> req = new Map<String, Object>{
            'accountId'   => (String) s.acc.Id,
            'unitId'      => (String) s.unit.Id,
            'requestType' => 'Replace',
            'referenceId' => (String) BCAPP_Utility.encryptId(s.payment.Id),
            'cardNumbers' => new List<String>{ s.card.CardNumber__c }
        };

        initRest();
        BCAPP_AccessCardServiceHandler.handleSubmit(req);
        System.assertEquals(500, RestContext.response.statusCode);
        Map<String, Object> errWrapper = parseWrapper();
        Map<String, Object> error = (Map<String, Object>) errWrapper.get('error');
        System.assertEquals('Missing payment reference.', (String) error.get('errorMessage'));
    }

    @isTest static void test_handleSubmit_rejects_failed_payment() {
        SetupCtx s = seed(true);
        s.payment.Status__c = 'Failed';
        update s.payment;

        Map<String, Object> req = new Map<String, Object>{
            'accountId'   => (String) s.acc.Id,
            'unitId'      => (String) s.unit.Id,
            'requestType' => 'Replace',
            'referenceId' => (String) BCAPP_Utility.encryptId(s.payment.Id),
            'cardNumbers' => new List<String>{ s.card.CardNumber__c }
        };

        initRest();
        BCAPP_AccessCardServiceHandler.handleSubmit(req);
        System.assertEquals(500, RestContext.response.statusCode);
        Map<String, Object> errWrapper = parseWrapper();
        Map<String, Object> error = (Map<String, Object>) errWrapper.get('error');
        System.assertEquals('Missing payment reference.', (String) error.get('errorMessage'));
    }

    @isTest static void test_handleSubmit_amount_mismatch_error() {
        SetupCtx s = seed(true);
        s.payment.PaidAmount__c = 10;
        update s.payment;

        Map<String, Object> req = new Map<String, Object>{
            'accountId'   => (String) s.acc.Id,
            'unitId'      => (String) s.unit.Id,
            'requestType' => 'Replace',
            'referenceId' => (String) BCAPP_Utility.encryptId(s.payment.Id),
            'cardNumbers' => new List<String>{ s.card.CardNumber__c }
        };

        initRest();
        BCAPP_AccessCardServiceHandler.handleSubmit(req);
        System.assertEquals(500, RestContext.response.statusCode);
        Map<String, Object> errWrapper = parseWrapper();
       Map<String, Object> error = (Map<String, Object>) errWrapper.get('error');
        System.assert(String.valueOf(error.get('errorMessage')).contains('Payment amount mismatch'));
    }

    @isTest static void test_handleCheckEligibility_legal_unit() {
        SetupCtx s = seed(true);
        Unit__c unit = [SELECT Id, Legal_Status__c FROM Unit__c WHERE Id = :s.unit.Id];
        unit.Legal_Status__c = 'With Legal';
        update unit;

        Map<String, Object> req = new Map<String, Object>{
            'accountId' => (String) s.acc.Id,
            'unitId'    => (String) s.unit.Id
        };

        initRest();
        BCAPP_AccessCardServiceHandler.checkEligibility(req);
        Map<String, Object> wrapper = parseWrapper();
        Map<String, Object> data = (Map<String, Object>) wrapper.get('data');
        System.assertEquals(false, (Boolean) data.get('isEligible'));
        System.assertEquals('Unit is legally blocked. Cannot process request.', (String) data.get('message'));
    }
}