@isTest
private class BCAPP_QuickPayHandlerTest {

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
                    Name = 'Default QuickPay Bank',
                    MMID__c = 'MMID-DEFAULT',
                    AccountNumberCorporate__c = '0000000000',
                    IBANNoCorporate__c = 'AE000000000000000000',
                    SwiftCodeCorporate__c = 'DEFBAEAD'
                );
            }
            bankSeeded = true;
        }
    }

    private static Seed setupData() {
        Seed s = new Seed();

        ensureDefaultBank();

        s.acc = BCAPP_TestDataFactory.createAccount('QP Handler AC');
        s.acc.SAP_BP_No__c = 'ACC-H-001';
        s.acc.AccountNumber = 'ACC-H-001';
        insert s.acc;

        Project__c project = new Project__c(Name = 'QuickPay Project');
        insert project;

        s.unit = new Unit__c(
            Name = 'U-QPH-100',
            Project__c = project.Id,
            CommunityCompanyCode__c = '1000',
            CommunitySAPUnitNumber__c = '1000',
            SAP_Company_Code__c = '1000'
        );
        insert s.unit;

        s.appUser = BCAPP_TestDataFactory.createUser('az-qph');
        s.appUser.Account__c = s.acc.Id;
        s.appUser.User_Account__c = s.acc.Id;
        s.appUser.User_Type__c = 'Owner';
        s.appUser.Email__c = 'test123@test.com';
        insert s.appUser;

        s.alloc = new Unit_Allocation__c(
            Unit__c = s.unit.Id,
            Account__c = s.acc.Id,
            User__c = s.appUser.Id,
            Start_Date__c = Date.today().addDays(-15),
            Active__c = true,
            User_Type__c = 'Owner'
        );
        insert s.alloc;

        // Optional: add one invoice to ensure totalOutstanding calculation encounters data
        if ([SELECT COUNT() FROM BankAccount__c WHERE CompanyCode__c = '1000'] == 0) {
            BankAccount__c ba = new BankAccount__c(
                Name = 'QP Bank',
                CompanyCode__c = '1000',
                AccountNumberCorporate__c = '1234567890',
                IBANNoCorporate__c = 'AE000000000000000001',
                SwiftCodeCorporate__c = 'ABCDAEAD',
                BankNameCorporate__c = 'QP Bank',
                MMID__c = 'MMID-QP'
            );
            insert ba;
            project.BankAccount__c = ba.Id;
            update project;
        }

        Invoice__c inv = new Invoice__c(
            Account__c = s.acc.Id,
            Unit__c    = s.unit.Id,
            Status__c  = 'Unpaid',
            DocumentType__c = 'DR',
            CompanyCode__c  = '1000',
            PostingDate__c  = Date.today().addDays(-7),
            TotalAmount__c = 150,
            DueAmount__c   = 150,
            InvoiceDate__c = Date.today().addDays(-7),
            SAPInvoiceNumber__c = 'SAP-QPH-1',
            InvoiceDescription__c = 'QuickPay Test'
        );
        insert inv;

        return s;
    }

    private static Map<String, Object> parse() {
        String body = RestContext.response != null && RestContext.response.responseBody != null
            ? RestContext.response.responseBody.toString() : '';
        System.assertNotEquals('', body, 'Expected response body');
        return (Map<String, Object>) JSON.deserializeUntyped(body);
    }

    private class QuickPayStatusMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"success":true}');
            return res;
        }
    }

    @isTest static void test_validateQuickPay_success_and_error() {
        Seed s = setupData();

        // Success
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        BCAPP_QuickPayHandler.validateQuickPay(new Map<String, Object>{
            'customerId' => s.acc.SAP_BP_No__c,
            'unitId'     => s.unit.Name
        });
        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> ok = parse();
        Map<String, Object> okData = (Map<String, Object>) ok.get('data');
        System.assertEquals((String) s.acc.Id, (String) okData.get('accountId'));
        System.assertEquals((String) s.unit.Id, (String) okData.get('unitId'));

        // Error (mismatch)
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        BCAPP_QuickPayHandler.validateQuickPay(new Map<String, Object>{
            'customerId' => 'ACC-XXX',
            'unitId'     => 'UNKNOWN'
        });
        System.assertEquals(500, RestContext.response.statusCode);
        Map<String, Object> err = parse();
        System.assert(((String) ((Map<String, Object>) err.get('error')).get('errorMessage')).startsWith('Given Customer ID'));
    }

    @isTest static void test_submit_and_update_status_success() {
        Seed s = setupData();

        // submitQuickPay
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        BCAPP_QuickPayHandler.submitQuickPay(new Map<String, Object>{
            'customerId'   => (String) s.acc.Id,
            'unitId'       => (String) s.unit.Id,
            'paymentMethod'=> 'CARD',
            'amount'       => 75
        });
        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> wrap = parse();
        String paymentId = (String) ((Map<String, Object>) wrap.get('data')).get('paymentId');
        paymentId = BCAPP_Utility.decryptId(paymentId);
        System.assertNotEquals(null, paymentId);

        // updateQuickPayStatus
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        Test.setMock(HttpCalloutMock.class, new QuickPayStatusMock());
        BCAPP_QuickPayHandler.updateQuickPayStatus(new Map<String, Object>{
            'paymentId' => (String) paymentId,
            'status'    => 'Success',
            'message'   => 'OK'
        });
        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> upd = parse();
        System.assertEquals('Success', (String) ((Map<String, Object>) upd.get('data')).get('status'));

        // Ensure receipt created
        List<Receipt__c> recs = [SELECT Id FROM Receipt__c WHERE OnlinePayment__c = :paymentId LIMIT 1];
        System.assert(!recs.isEmpty(), 'Expected receipt created for quick pay');
    }
}