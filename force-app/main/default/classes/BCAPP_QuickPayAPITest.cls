@isTest
private class BCAPP_QuickPayAPITest {

    private class Seed {
        Account acc;
        Unit__c unit;
        User__c appUser;
        Unit_Allocation__c alloc;
    }

    private static Boolean bankSeeded = false;

    private static void ensureDefaultBank() {
        if (!bankSeeded) {
            if ([SELECT COUNT() FROM BankAccount__c WHERE CompanyCode__c = null] == 0) {
                insert new BankAccount__c(
                    Name = 'Default QuickPay API Bank',
                    MMID__c = 'MMID-DEFAULT-API',
                    AccountNumberCorporate__c = '1111111111',
                    IBANNoCorporate__c = 'AE000000000000000010',
                    SwiftCodeCorporate__c = 'DEF2AEAD',
                    CompanyCode__c = '1173'
                );
            }
            bankSeeded = true;
        }
    }

    private static Seed setupData() {
        Seed s = new Seed();

        ensureDefaultBank();

        // Account with AccountNumber for QuickPay validation
        s.acc = BCAPP_TestDataFactory.createAccount('QP Account');
        s.acc.SAP_BP_No__c = 'ACC-QP-001';
        s.acc.AccountNumber = 'ACC-QP-001';
        insert s.acc;

        Project__c project = new Project__c(Name = 'QuickPay API Project');
        insert project;

        // Unit with Name used for validation
        s.unit = new Unit__c(
            Name = 'U-QP-100',
            Project__c = project.Id,
            CommunityCompanyCode__c = '1100',
            CommunitySAPUnitNumber__c = '1100',
            SAP_Company_Code__c = '1173'
        );
        insert s.unit;

        if ([SELECT COUNT() FROM BankAccount__c WHERE CompanyCode__c = '1100'] == 0) {
            insert new BankAccount__c(
                Name = 'QP API Bank',
                CompanyCode__c = '1100',
                AccountNumberCorporate__c = '1122334455',
                IBANNoCorporate__c = 'AE000000000000000002',
                SwiftCodeCorporate__c = 'QPAEAEAD',
                BankNameCorporate__c = 'QP API Bank',
                MMID__c = 'MMID-QPA'
            );
        }

        // Create mapped community user needed by Unit_Allocation__c
        s.appUser = BCAPP_TestDataFactory.createUser('az-qpay');
        s.appUser.Account__c = s.acc.Id;
        s.appUser.User_Account__c = s.acc.Id;
        s.appUser.User_Type__c = 'Owner';
        s.appUser.Email__c = 'test123@yopmail.com';
        insert s.appUser;

        // Active allocation for Account + Unit
        s.alloc = new Unit_Allocation__c(
            Unit__c = s.unit.Id,
            Account__c = s.acc.Id,
            User__c = s.appUser.Id,
            Start_Date__c = Date.today().addDays(-10),
            Active__c = true,
            User_Type__c = 'Owner'
        );
        insert s.alloc;

        return s;
    }

    private static void setReq(Map<String, Object> payload) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/v1/quick-pay';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    private static Map<String, Object> parse() {
        String body = RestContext.response != null && RestContext.response.responseBody != null
            ? RestContext.response.responseBody.toString() : '';
        System.assertNotEquals('', body, 'Expected response body');
        return (Map<String, Object>) JSON.deserializeUntyped(body);
    }

    @isTest static void test_validateQuickPay_success() {
        Seed s = setupData();

        Map<String, Object> data = new Map<String, Object>{
            'customerId' => s.acc.SAP_BP_No__c, // AccountNumber
            'unitId'     => s.unit.Name          // Unit Name
        };
        setReq(new Map<String, Object>{ 'operation' => 'validateQuickPay', 'data' => data });
        BCAPP_QuickPayAPI.handleQuickPay();

        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> wrap = parse();
        Map<String, Object> res  = (Map<String, Object>) wrap.get('data');
        System.assertEquals((String) s.unit.Id, (String) res.get('unitId'));
        System.assertEquals((String) s.acc.Id, (String) res.get('accountId'));
        System.assertNotEquals(null, res.get('totalOutstanding'));
    }

    @isTest static void test_validateQuickPay_mismatch_error() {
        Seed s = setupData();

        // wrong unit name
        Map<String, Object> data = new Map<String, Object>{
            'customerId' => 'ACC-XYZ',
            'unitId'     => 'NO-UNIT'
        };
        setReq(new Map<String, Object>{ 'operation' => 'validateQuickPay', 'data' => data });
        BCAPP_QuickPayAPI.handleQuickPay();

        System.assertEquals(500, RestContext.response.statusCode);
        Map<String, Object> wrap = parse();
        Map<String, Object> err = (Map<String, Object>) wrap.get('error');
        System.assert(((String) err.get('errorMessage')).startsWith('Given Customer ID'));
    }

    @isTest static void test_submit_and_update_success() {
        Seed s = setupData();

        // submitQuickPay
        Map<String, Object> submitData = new Map<String, Object>{
            'customerId'   => (String) s.acc.Id, // Account Id
            'unitId'       => (String) s.unit.Id,
            'paymentMethod'=> 'CARD',
            'amount'       => 125
        };
        setReq(new Map<String, Object>{ 'operation' => 'submitQuickPay', 'data' => submitData });
        BCAPP_QuickPayAPI.handleQuickPay();

        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> submitWrap = parse();
        String paymentId = (String) ((Map<String, Object>) submitWrap.get('data')).get('paymentId');
        paymentId = BCAPP_Utility.decryptId(paymentId);
        System.assertNotEquals(null, paymentId);

        // updateQuickPayStatus → Success (creates Receipt)
        Map<String, Object> updData = new Map<String, Object>{
            'paymentId' => (String)paymentId,
            'status'    => 'Success',
            'message'   => 'OK'
        };
        setReq(new Map<String, Object>{ 'operation' => 'updateQuickPayStatus', 'data' => updData });
        BCAPP_QuickPayAPI.handleQuickPay();

        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> updWrap = parse();
        Map<String, Object> upd = (Map<String, Object>) updWrap.get('data');
        System.assertEquals('Success', (String) upd.get('status'));

        // Verify a receipt exists linked to the payment
        List<Receipt__c> recs = [SELECT Id, OnlinePayment__c FROM Receipt__c WHERE OnlinePayment__c = :paymentId LIMIT 1];
        System.assert(!recs.isEmpty(), 'Expected a receipt for successful quick pay');
    }
}