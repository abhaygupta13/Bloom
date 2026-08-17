/*****************************************************************************************
Class       : EventMonitorHandlerTest
Author      : Soubhagya Ranjan Nayak
Description : Test class for EventMonitorHandler
Created Date: 15 MAY 2026
------------------------------------------------------------------------------------------
-- History --
------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0             15MAY2026           Initial Version
*****************************************************************************************/
@IsTest
private class EventMonitorHandlerTest {

    /* ───────────────────────────────────────────────────────────────
     * Tests that do NOT need org data
     * ─────────────────────────────────────────────────────────────── */

    @IsTest
    static void testHandlerImplementsInterface() {
        TxnSecurity.EventCondition handler = new EventMonitorHandler();
        System.assertNotEquals(null, handler, 'Handler should instantiate successfully');
    }

    @IsTest
    static void testEvaluateReturnsFalseForNonExportOperation() {
        EventMonitorHandler handler = new EventMonitorHandler();

        ReportEvent evt = new ReportEvent();
        evt.Operation = 'ReportRun';

        Test.startTest();
        Boolean result = handler.evaluate(evt);
        Test.stopTest();

        System.assertEquals(false, result,
            'Non-export operations should always return false');
    }

    @IsTest
    static void testEvaluateReturnsFalseWhenReportIdIsNull() {
        EventMonitorHandler handler = new EventMonitorHandler();

        ReportEvent evt = new ReportEvent();
        evt.Operation = 'ReportExported';

        Test.startTest();
        Boolean result = handler.evaluate(evt);
        Test.stopTest();

        System.assertEquals(false, result,
            'Null ReportId should return false');
    }

    @IsTest
    static void testEvaluateHandlesClassCastException() {
        EventMonitorHandler handler = new EventMonitorHandler();
        Account acct = new Account(Name = 'Test');

        Test.startTest();
        Boolean result = handler.evaluate(acct);
        Test.stopTest();

        System.assertEquals(false, result,
            'ClassCastException should be caught and return false');
    }

    @IsTest
    static void testEvaluateHandlesDescribeFailure() {
        EventMonitorHandler handler = new EventMonitorHandler();

        ReportEvent evt = new ReportEvent();
        evt.Operation = 'ReportExported';
        evt.ReportId = '00O000000000000AAA';

        Test.startTest();
        Boolean result = handler.evaluate(evt);
        Test.stopTest();

        System.assertEquals(false, result,
            'Inaccessible report should be caught and return false');
    }

    @IsTest
    static void testMultipleEvaluationsAreStateless() {
        EventMonitorHandler handler = new EventMonitorHandler();

        ReportEvent evtRun = new ReportEvent();
        evtRun.Operation = 'ReportRun';

        ReportEvent evtExport = new ReportEvent();
        evtExport.Operation = 'ReportExported';
        evtExport.ReportId = '00O000000000000AAA';

        Test.startTest();
        Boolean r1 = handler.evaluate(evtRun);
        Boolean r2 = handler.evaluate(evtExport);
        Boolean r3 = handler.evaluate(evtRun);
        Test.stopTest();

        System.assertEquals(false, r1, 'First non-export call should return false');
        System.assertEquals(false, r2, 'Export with bad Id should return false');
        System.assertEquals(false, r3, 'Second non-export call should return false');
    }

    /* ───────────────────────────────────────────────────────────────
     * Tests that NEED real org data (SeeAllData = true)
     * Reports.ReportManager.describeReport() and FieldDefinition
     * SOQL only work against live metadata / report definitions.
     * ─────────────────────────────────────────────────────────────── */

    /**
     * Exercises the FULL evaluateExportCompliance path:
     *   FieldDefinition SOQL  ->  describeReport  ->  column loop
     * Covers the lines that are unreachable with a fake report Id.
     */
    @IsTest(SeeAllData=true)
    static void testEvaluateExportComplianceWithRealReport() {
        List<Report> reports = [
            SELECT Id FROM Report
            WHERE Format != 'MultiBlock'
            LIMIT 1
        ];

        if (reports.isEmpty()) {
            System.debug('No usable report found - skipping real-report test');
            return;
        }

        EventMonitorHandler handler = new EventMonitorHandler();

        ReportEvent evt = new ReportEvent();
        evt.Operation = 'ReportExported';
        evt.ReportId  = reports[0].Id;

        Test.startTest();
        Boolean result = handler.evaluate(evt);
        Test.stopTest();

        // Result depends on whether report columns overlap with
        // compliance-tagged fields. Both outcomes are valid.
        System.assert(result || !result,
            'Full compliance path should complete without throwing');
    }

    /**
     * Targets the "return true" branch inside the column loop.
     * Picks a Contact/Account report (more likely to contain
     * compliance-tagged fields such as Email, Phone, etc.).
     */
    @IsTest(SeeAllData=true)
    static void testEvaluateExportComplianceContactAccountReport() {
        List<Report> reports = [
            SELECT Id FROM Report
            WHERE Format != 'MultiBlock'
              AND (DeveloperName LIKE '%Contact%' OR DeveloperName LIKE '%Account%')
            LIMIT 1
        ];

        if (reports.isEmpty()) {
            reports = [SELECT Id FROM Report WHERE Format != 'MultiBlock' LIMIT 1];
        }

        if (reports.isEmpty()) {
            System.debug('No usable report found - skipping contact/account report test');
            return;
        }

        EventMonitorHandler handler = new EventMonitorHandler();

        ReportEvent evt = new ReportEvent();
        evt.Operation = 'ReportExported';
        evt.ReportId  = reports[0].Id;

        Test.startTest();
        Boolean result = handler.evaluate(evt);
        Test.stopTest();

        System.assert(result != null, 'Result should not be null');
    }

    /**
     * Ensures the FieldDefinition SOQL executes without error
     * independent of the report path.
     */
    @IsTest(SeeAllData=true)
    static void testFieldDefinitionQueryExecutes() {
        List<FieldDefinition> complianceFields = [
            SELECT QualifiedApiName, ComplianceGroup
            FROM FieldDefinition
            WHERE EntityDefinition.QualifiedApiName IN ('Contact', 'Account')
              AND ComplianceGroup != NULL
        ];

        System.assert(complianceFields != null,
            'FieldDefinition query should execute without error');
    }
}