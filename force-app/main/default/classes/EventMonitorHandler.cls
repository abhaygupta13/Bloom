/*****************************************************************************************
Class       : EventMonitorHandler
Author      : Soubhagya Ranjan Nayak
Description : Implements TxnSecurity.EventCondition to alert the admin on report exports
              containing PII or GDPR-tagged fields on Contact and Account objects.
Test class  : EventMonitorHandlerTest
Created Date: 14 MAY 2026
------------------------------------------------------------------------------------------
-- History --
------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.      V1.0                14MAY2026           Initial Version
*****************************************************************************************/
public without sharing class EventMonitorHandler implements TxnSecurity.EventCondition {

    public Boolean evaluate(SObject event) {
        Boolean result = false;
        try {
            ReportEvent reportEvent = (ReportEvent) event;
            if (reportEvent.Operation == 'ReportExported') {
                result = evaluateExportCompliance(reportEvent);
            }
        } catch (Exception e) {
            // Fail safe — do not block on unexpected errors
        }
        return result;
    }

    private boolean evaluateExportCompliance(ReportEvent reportEvent) {
    String reportId = reportEvent.ReportId;
    if (reportId == null) return false;

    // Step 1: Get PII/GDPR-tagged fields — fetch Label too
    List<FieldDefinition> complianceFields = [
        SELECT QualifiedApiName, Label, ComplianceGroup,
               EntityDefinition.QualifiedApiName,
               EntityDefinition.Label
        FROM FieldDefinition
        WHERE EntityDefinition.QualifiedApiName IN (
            'Contact', 'Account', 'SalesOrder__c', 'Lead',
            'HandOver__c', 'Unit__c',
            'BrokerApplication__c', 'BrokerApplicant__c'
        )
        AND ComplianceGroup != NULL
    ];

    // Step 2: Build sets for BOTH api names and labels
    Set<String> taggedApiNames = new Set<String>();
    Set<String> taggedLabels   = new Set<String>();

    for (FieldDefinition fd : complianceFields) {
        taggedApiNames.add(fd.QualifiedApiName.toLowerCase());
        taggedLabels.add(fd.Label.toLowerCase());
        
        // Also add "ObjectLabel FieldLabel" format
        // e.g. "Sales Order Account Email"
        taggedLabels.add(
            (fd.EntityDefinition.Label + ' ' + fd.Label).toLowerCase()
        );
    }

    // Step 3: Get report columns
    Reports.ReportDescribeResult describe = Reports.ReportManager.describeReport(reportId);
    Reports.ReportExtendedMetadata meta   = describe.getReportExtendedMetadata();
    Map<String, Reports.DetailColumn> columns = meta.getDetailColumnInfo();

    // Step 4: Check column KEY and LABEL both
    for (String colKey : columns.keySet()) {
        Reports.DetailColumn col = columns.get(colKey);
        
        String colKeyLower   = colKey.toLowerCase();
        String colLabelLower = col.getLabel().toLowerCase();

        if (taggedApiNames.contains(colKeyLower)
         || taggedLabels.contains(colKeyLower)
         || taggedLabels.contains(colLabelLower)) {
            return true;
        }
    }
    return false;
}
}