@isTest
private class BCAPP_InvoiceHandlerTest {

    private class Seed {
        Account acc;
        Unit__c unit;
        Invoice__c inv1;
        Invoice__c inv2;
        OnlinePayment__c paymentPending;
    }

    private static Boolean bankSeeded = false;

    private static void ensureDefaultBank() {
        if (!bankSeeded) {
            if ([SELECT COUNT() FROM BankAccount__c WHERE CompanyCode__c = null] == 0) {
                insert new BankAccount__c(
                    Name = 'Default Invoice Bank',
                    MMID__c = 'MMID-INV-DEFAULT',
                    AccountNumberCorporate__c = '3333333333',
                    IBANNoCorporate__c = 'AE000000000000000030',
                    SwiftCodeCorporate__c = 'INVDAEAD'
                );
            }
            bankSeeded = true;
        }
    }

    private static Seed setupData() {
        Seed s = new Seed();

        ensureDefaultBank();
        s.acc = BCAPP_TestDataFactory.createAccount('Invoice Handler AC');
        s.acc.SAP_BP_No__c = 'ACC-INV-001';
        s.acc.AccountNumber = 'ACC-INV-001';
        insert s.acc;

        Project__c project = new Project__c(Name = 'Invoice Handler Project');
        insert project;

        // IMPORTANT: set SAP_Company_Code__c because handler reads this field
        s.unit = new Unit__c(
            Name = 'U-INV-H-001',
            Project__c = project.Id,
            CommunityCompanyCode__c = '1300',
            CommunitySAPUnitNumber__c = '1300',
            SAP_Company_Code__c = '1300'
        );
        insert s.unit;

        // Bank account for company code = 1300 so fetchBankDetailsByCompanyCode() returns a record
        if ([SELECT COUNT() FROM BankAccount__c WHERE CompanyCode__c = '1300'] == 0) {
            BankAccount__c ba = new BankAccount__c(
                Name = 'Invoice Bank',
                CompanyCode__c = '1300',
                AccountNumberCorporate__c = '9988776655',
                IBANNoCorporate__c = 'AE000000000000000005',
                SwiftCodeCorporate__c = 'INVAEDA',
                BankNameCorporate__c = 'Invoice Bank',
                MMID__c = 'MMID-INV'
            );
            insert ba;
            project.BankAccount__c = ba.Id;
            update project;
        }

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
            SAPInvoiceNumber__c = 'SAP-H-1001',
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
            SAPInvoiceNumber__c = 'SAP-H-1002',
            InvoiceDescription__c = 'Utilities'
        );
        insert new List<Invoice__c>{ s.inv1, s.inv2 };

        // Pending payment used by submit/update tests
        s.paymentPending = new OnlinePayment__c(
            Account__c = s.acc.Id,
            Unit__c = s.unit.Id,
            Status__c = 'Pending',
            PaidAmount__c = 10,
            PaymentMethod__c = 'CARD',
            RequestSource__c = 'API',
            GatewayReference__c = 'GW-FAIL-1'
        );
        insert s.paymentPending;

        return s;
    }

    private static Map<String, Object> parse() {
        String body = RestContext.response != null && RestContext.response.responseBody != null
            ? RestContext.response.responseBody.toString() : '';
        System.assertNotEquals('', body, 'Expected response body');
        return (Map<String, Object>) JSON.deserializeUntyped(body);
    }

    @isTest static void test_get_invoices_and_summary_and_byId() {
        Seed s = setupData();

        // getInvoices
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        BCAPP_InvoiceHandler.getInvoices(new Map<String, Object>{
            'accountId' => (String) s.acc.Id,
            'unitId'    => (String) s.unit.Id
        });
        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> wrap1 = parse();
        Map<String, Object> data1 = (Map<String, Object>) wrap1.get('data');
        System.assert(((List<Object>) data1.get('records')).size() >= 2);

        // getSummary
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        BCAPP_InvoiceHandler.getSummary(new Map<String, Object>{
            'accountId' => (String) s.acc.Id,
            'unitId'    => (String) s.unit.Id
        });
        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> wrap2 = parse();
        System.assertNotEquals(null, ((Map<String, Object>) wrap2.get('data')).get('totalDue'));

        // getInvoiceById
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        BCAPP_InvoiceHandler.getInvoiceById(new Map<String, Object>{ 'invoiceId' => (String) s.inv1.Id });
        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> wrap3 = parse();
        Map<String, Object> data3 = (Map<String, Object>) wrap3.get('data');
        System.assertEquals('SAP-H-1001', (String) ((Map<String, Object>) data3.get('invoice')).get('sapInvoiceNumber'));
    }

    @isTest static void test_submit_update_status_failed_and_history() {
        Seed s = setupData();

        // submitPayment (works now because Unit has SAP_Company_Code__c and bank exists)
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        List<Object> invs = new List<Object>{
            new Map<String, Object>{ 'invoiceId' => (String) s.inv1.Id, 'amount' => 100 },
            new Map<String, Object>{ 'invoiceId' => (String) s.inv2.Id, 'amount' => 50 }
        };
        Map<String, Object> submit = new Map<String, Object>{
            'invoices'      => invs,
            'source'        => 'API',
            'customerId'    => (String) s.acc.Id,
            'unitId'        => (String) s.unit.Id,
            'paymentMethod' => 'CARD'
        };
        BCAPP_InvoiceHandler.submitPayment(submit);
        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> submitWrap = parse();
        String paymentId = (String) ((Map<String, Object>) submitWrap.get('data')).get('paymentId');
        paymentId = BCAPP_Utility.decryptId(paymentId);
        System.assertNotEquals(null, paymentId);

        // updatePaymentStatus → use Failed to avoid external poster
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        BCAPP_InvoiceHandler.updatePaymentStatus(new Map<String, Object>{
            'paymentId'    => (String) paymentId,
            'status'       => 'Success',
            'message'      => 'Success',
            'paymentMethod'=> 'CARD'
        });
        BCAPP_InvoiceHandler.updatePaymentStatus(new Map<String, Object>{
            'paymentId'    => (String) paymentId,
            'status'       => 'Failed',
            'message'      => 'Declined',
            'paymentMethod'=> 'CARD'
        });
        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> updWrap = parse();
        Map<String, Object> updData = (Map<String, Object>) updWrap.get('data');
        System.assertEquals('Failed', (String) updData.get('status'));
        System.assertEquals(null, (Object) updData.get('receiptId'));

        // Seed a SUCCESS payment/receipt/allocation directly so history has data
        OnlinePayment__c pOk = new OnlinePayment__c(
            Account__c = s.acc.Id, Unit__c = s.unit.Id, Status__c = 'Success',
            PaidAmount__c = 75, PaymentMethod__c = 'CARD', RequestSource__c = 'API'
        );
        insert pOk;
        Receipt__c rOk = new Receipt__c(
            Account__c = s.acc.Id, Unit__c = s.unit.Id, AmountReceived__c = 75,
            PaymentDate__c = Date.today(), PaymentMode__c = 'Online', Status__c = 'Posted',
            OnlinePayment__c = pOk.Id
        );
        insert rOk;
        insert new InvoiceAllocation__c(
            Invoice__c = s.inv1.Id, Receipt__c = rOk.Id, AllocatedAmount__c = 75, AllocationDate__c = Date.today()
        );

        // getPaymentStatus (for the failed payment)
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        BCAPP_InvoiceHandler.getPaymentStatus(new Map<String, Object>{ 'paymentId' => (String) paymentId });
        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> statWrap = parse();
        Map<String, Object> statData = (Map<String, Object>) statWrap.get('data');
        System.assertEquals('Failed', (String) statData.get('status'));

        // getPaymentHistory (should include the seeded success payment)
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        BCAPP_InvoiceHandler.getPaymentHistory(new Map<String, Object>{ 'accountId' => (String) s.acc.Id });
        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> histWrap = parse();
        List<Object> hist = (List<Object>) ((Map<String, Object>) histWrap.get('data')).get('paymentHistory');
        System.assert(!hist.isEmpty(), 'Expected at least one successful payment in history');
    }

    @isTest static void test_receipt_and_statement_view_paths() {
        Seed s = setupData();

        // Insert a receipt + allocation directly (avoid poster/Success branch)
        Receipt__c rec = new Receipt__c(
            Account__c = s.acc.Id, Unit__c = s.unit.Id, AmountReceived__c = 120,
            PaymentDate__c = Date.today().addDays(-2), PaymentMode__c = 'Online', Status__c = 'Posted'
        );
        insert rec;
        insert new InvoiceAllocation__c(
            Invoice__c = s.inv1.Id, Receipt__c = rec.Id, AllocatedAmount__c = 120, AllocationDate__c = rec.PaymentDate__c
        );

        // getReceipt (uses Test.isRunningTest() → dummy PDF, should be 200)
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        BCAPP_InvoiceHandler.getReceipt(new Map<String, Object>{ 'receiptId' => (String) rec.Id });
        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> receiptWrap = parse();
        System.assertEquals(true, (Boolean) receiptWrap.get('success'));
        Map<String, Object> receiptData = (Map<String, Object>) receiptWrap.get('data');
        System.assertNotEquals(null, ((Map<String, Object>) receiptData.get('receipt')).get('receiptPdf'));

        // Statement of Account (mode=view) also uses test-safe PDF generation
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        BCAPP_InvoiceHandler.getStatementOfAccount(new Map<String, Object>{
            'accountId' => (String) s.acc.Id,
            'unitId'    => (String) s.unit.Id,
            'mode'      => 'view',
            'startDate' => String.valueOf(Date.today().addDays(-30)),
            'endDate'   => String.valueOf(Date.today())
        });
        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> soaWrap = parse();
        System.assertEquals(true, (Boolean) soaWrap.get('success'));

        // Invalid mode → expect 500 from error response
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        BCAPP_InvoiceHandler.getStatementOfAccount(new Map<String, Object>{
            'accountId' => (String) s.acc.Id,
            'unitId'    => (String) s.unit.Id,
            'mode'      => 'unsupported',
            'startDate' => String.valueOf(Date.today().addDays(-30)),
            'endDate'   => String.valueOf(Date.today())
        });
        System.assertEquals(500, RestContext.response.statusCode);
        
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        BCAPP_InvoiceHandler.getStatementOfAccount(new Map<String, Object>{
            'accountId' => (String) s.acc.Id,
            'unitId'    => (String) s.unit.Id,
            'mode'      => 'email',
            'startDate' => String.valueOf(Date.today().addDays(-30)),
            'endDate'   => String.valueOf(Date.today())
        });
        System.assertEquals(500, RestContext.response.statusCode);
    }
}