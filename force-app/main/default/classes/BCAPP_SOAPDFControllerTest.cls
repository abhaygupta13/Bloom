@isTest
private class BCAPP_SOAPDFControllerTest {

    private static Account makeAccount(String name, String acctNumber) {
        Account a = BCAPP_TestDataFactory.createAccount(name);
        a.SAP_BP_No__c = acctNumber;
        a.AccountNumber = acctNumber;
        insert a;
        return a;
    }

    private static Unit__c makeUnit(String name) {
        Project__c project = new Project__c(Name = 'SOA Project');
        insert project;

        Unit__c u = new Unit__c(
            Name = name,
            Project__c = project.Id,
            CommunityCompanyCode__c = '1000'
        );
        insert u;

        if ([SELECT COUNT() FROM BankAccount__c WHERE CompanyCode__c = '1000'] == 0) {
            BankAccount__c ba = new BankAccount__c(
                Name = 'SOA Bank',
                CompanyCode__c = '1000',
                AccountNumberCorporate__c = '4455667788',
                IBANNoCorporate__c = 'AE000000000000000006',
                SwiftCodeCorporate__c = 'SOAAEAD',
                BankNameCorporate__c = 'SOA Bank'
            );
            insert ba;
            project.BankAccount__c = ba.Id;
            update project;
        }
		
        return u;
    }

    private static Invoice__c inv(Account acc, Unit__c unit, Date posting, String dc, Decimal amt, String descr, String sapNo, String assign) {
        Invoice__c i = new Invoice__c(
            Account__c = acc.Id,
            Unit__c    = unit.Id,
            PostingDate__c = posting,
            InvoiceDate__c = posting,
            DebitCredit__c = dc,
            TotalAmount__c = amt,
            InvoiceDescription__c = descr,
            SAPInvoiceNumber__c = sapNo,
            SAPAssignment__c = assign,
            // Use a valid invoice status; other tests use 'Unpaid'/'Partially Paid'
            Status__c = 'Unpaid',
            DocumentType__c = 'DR',
            CompanyCode__c  = '1000'
        );
        insert i;
        return i;
    }

    @isTest static void test_rows_and_totals_computation() {
        Account acc = makeAccount('SOA AC', 'ACC-777');
        Unit__c unit = makeUnit('U-SOA-001');

        Date sd = Date.today().addDays(-10);
        Date ed = Date.today();

        // Prepare a synthetic VF request and attach expected parameters
        PageReference pr = new PageReference('/apex/SOA_PDF');
        pr.getParameters().put('accountId', (String) acc.Id);
        pr.getParameters().put('unitId',    (String) unit.Id);
        pr.getParameters().put('startDate', String.valueOf(sd));
        pr.getParameters().put('endDate',   String.valueOf(ed));
        Test.setCurrentPage(pr);

        // Sanity: ensure params are set as expected
        System.assertEquals((String) acc.Id, ApexPages.currentPage().getParameters().get('accountId'));
        System.assertEquals((String) unit.Id, ApexPages.currentPage().getParameters().get('unitId'));

        // Debit 100 (S), Credit 40 (H)
        inv(acc, unit, Date.today().addDays(-5), 'Debit', 100, 'Debit Line', 'SAP-1', 'REF-1');
        inv(acc, unit, Date.today().addDays(-3), 'Credit', 40,  'Credit Line','SAP-2', 'REF-2');

        BCAPP_SOAPDFController ctrl = new BCAPP_SOAPDFController();

        System.assertEquals('Detail', ctrl.statementType);
        System.assert(!ctrl.rows.isEmpty(), 'Rows should be populated');
        // Running balance should be debit - credit = 60
        System.assertEquals(60, ctrl.finalBalance);
        // Totals
        System.assertEquals(100, ctrl.totalDebit);
        System.assertEquals(40,  ctrl.totalCredit);
        // Header
        System.assertEquals(acc.SAP_BP_No__c, ctrl.customerIdText);
        System.assertEquals(unit.Name, ctrl.propertyDetails);
    }

    @isTest static void test_defaults_and_empty_results() {
        // No params passed: controller should not crash and should default safely
        Test.setCurrentPage(new PageReference('/apex/SOA_PDF'));

        BCAPP_SOAPDFController ctrl = new BCAPP_SOAPDFController();

        // With no IDs, header text should be blank and no rows returned
        System.assertEquals('Detail', ctrl.statementType);
        System.assertEquals('', ctrl.customerIdText);
        System.assertEquals('', ctrl.propertyDetails);
        System.assertEquals(0, ctrl.totalDebit);
        System.assertEquals(0, ctrl.totalCredit);
        System.assertEquals(0, ctrl.finalBalance);
        System.assertEquals(true, ctrl.rows == null || ctrl.rows.isEmpty());
        // Statement period should be non-empty string with formatted dates
        System.assertNotEquals(null, ctrl.statementPeriod);
        System.assert(!String.isBlank(ctrl.statementPeriod));
    }

    @isTest static void test_mixed_flags_and_companycode_path() {
        Account acc = makeAccount('SOA AC 2', 'ACC-888');
        // Include a company code to exercise fetchBankDetailsByCompanyCode with a value
        Unit__c unit = new Unit__c(Name = 'U-SOA-002', SAP_Company_Code__c = '1000');
        insert unit;

        Date sd = Date.today().addDays(-15);
        Date ed = Date.today();

        PageReference pr = new PageReference('/apex/SOA_PDF');
        pr.getParameters().put('accountId', (String) acc.Id);
        pr.getParameters().put('unitId',    (String) unit.Id);
        pr.getParameters().put('startDate', String.valueOf(sd));
        pr.getParameters().put('endDate',   String.valueOf(ed));
        Test.setCurrentPage(pr);

        // Create S=100, H=30, X=50 (unknown flag should not change totals)
        inv(acc, unit, Date.today().addDays(-10), 'Debit', 100, 'Debit',  'SAP-10', 'R1');
        inv(acc, unit, Date.today().addDays(-8),  'Credit', 30,  'Credit', 'SAP-20', 'R2');
        inv(acc, unit, Date.today().addDays(-6),  'X', 50,  'Other',  'SAP-30', 'R3');

        BCAPP_SOAPDFController ctrl = new BCAPP_SOAPDFController();

        // Totals ignore unknown flag
        System.assertEquals(100, ctrl.totalDebit);
        System.assertEquals(30,  ctrl.totalCredit);
        System.assertEquals(70,  ctrl.finalBalance);
        System.assert(!ctrl.rows.isEmpty());

        // Find the 'X' row and ensure it contributes 0/0 and does not impact running balance
        BCAPP_SOAPDFController.RowVM xRow;
        for (BCAPP_SOAPDFController.RowVM r : ctrl.rows) {
            if (r.docNo == 'SAP-30') { xRow = r; break; }
        }
        System.assertNotEquals(null, xRow, 'Expected to find SAP-30 row');
        System.assertEquals(0, xRow.debit);
        System.assertEquals(0, xRow.credit);

        // Bank details should be blank since no custom metadata is present even with a company code
        System.assertEquals('', ctrl.bankAccountName);
        System.assertEquals('', ctrl.bankAccountNumber);
        System.assertEquals('', ctrl.bankIBAN);
        System.assertEquals('', ctrl.bankSwift);
        System.assertEquals('', ctrl.bankName);
        // Header mapping
        System.assertEquals(acc.SAP_BP_No__c, ctrl.customerIdText);
        System.assertEquals(unit.Name, ctrl.propertyDetails);
    }
}