@isTest
private class BCAPP_GetInvoicesAPITest {

    private class Seed {
        Account acc;
        Unit__c unit;
        Invoice__c inv1;
        Invoice__c inv2;
    }

    private static Seed setupData() {
        Seed s = new Seed();

        s.acc = BCAPP_TestDataFactory.createAccount('Invoice AC');
        insert s.acc;

        s.unit = new Unit__c(Name = 'U-INV-001');
        insert s.unit;

        // Two unpaid invoices
        s.inv1 = new Invoice__c(
            Account__c = s.acc.Id,
            Unit__c    = s.unit.Id,
            Status__c  = 'Unpaid',
            DocumentType__c = 'DR',
            CompanyCode__c  = '1000',
            PostingDate__c  = Date.today().addDays(-10),
            TotalAmount__c = 300,
            DueAmount__c   = 300,
            InvoiceDate__c = Date.today().addDays(-10),
            SAPInvoiceNumber__c = 'SAP-1001',
            InvoiceDescription__c = 'Maintenance'
        );
        s.inv2 = new Invoice__c(
            Account__c = s.acc.Id,
            Unit__c    = s.unit.Id,
            Status__c  = 'Partially Paid',
            DocumentType__c = 'DR',
            CompanyCode__c  = '1000',
            PostingDate__c  = Date.today().addDays(-5),
            TotalAmount__c = 200,
            DueAmount__c   = 50,
            InvoiceDate__c = Date.today().addDays(-5),
            SAPInvoiceNumber__c = 'SAP-1002',
            InvoiceDescription__c = 'Utilities'
        );
        insert new List<Invoice__c>{ s.inv1, s.inv2 };

        return s;
    }

    private static void setReq(Map<String, Object> payload) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/v1/get-invoices';
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

    @isTest static void test_getinvoices_success() {
        Seed s = setupData();
        setReq(new Map<String, Object>{
            'operation' => 'getinvoices',
            'data' => new Map<String, Object>{
                'accountId' => (String) s.acc.Id,
                'unitId'    => (String) s.unit.Id
            }
        });
        BCAPP_GetInvoicesAPI.doPost();

        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> wrapper = parse();
        System.assertEquals(true, (Boolean) wrapper.get('success'));
        Map<String, Object> data = (Map<String, Object>) wrapper.get('data');
        List<Object> records = (List<Object>) data.get('records');
        //System.assert(records.size() >= 2, 'Should return 2 invoices');
    }

    @isTest static void test_getinvoicebyid_success() {
        Seed s = setupData();
        setReq(new Map<String, Object>{
            'operation' => 'getinvoicebyid',
            'data' => new Map<String, Object>{ 'invoiceId' => (String) s.inv1.Id }
        });
        BCAPP_GetInvoicesAPI.doPost();

        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> wrapper = parse();
        System.assertEquals(true, (Boolean) wrapper.get('success'));
        Map<String, Object> data = (Map<String, Object>) wrapper.get('data');
        Map<String, Object> invoice = (Map<String, Object>) data.get('invoice');
        System.assertEquals('SAP-1001', (String) invoice.get('sapInvoiceNumber'));
    }

    @isTest static void test_getsummary_success() {
        Seed s = setupData();
        setReq(new Map<String, Object>{
            'operation' => 'getsummary',
            'data' => new Map<String, Object>{
                'accountId' => (String) s.acc.Id,
                'unitId'    => (String) s.unit.Id
            }
        });
        BCAPP_GetInvoicesAPI.doPost();

        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> wrapper = parse();
        System.assertEquals(true, (Boolean) wrapper.get('success'));
        Map<String, Object> data = (Map<String, Object>) wrapper.get('data');
        //System.assertNotEquals(null, data.get('totalDue'));
    }

    @isTest static void test_unsupported_operation_error() {
        setReq(new Map<String, Object>{ 'operation' => 'unknown', 'data' => new Map<String, Object>() });
        BCAPP_GetInvoicesAPI.doPost();
        System.assertEquals(500, RestContext.response.statusCode);
        Map<String, Object> wrapper = parse();
        System.assertEquals(false, (Boolean) wrapper.get('success'));
    }
}