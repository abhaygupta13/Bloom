global class BAPPCaseEscalationBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable {

    // -------------------------
    // START
    // -------------------------
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime now = System.now();
        Datetime twentyFourHoursAgo = now.addHours(-24);

        String query = 'SELECT Id, CaseNumber, Account__r.Name, Subject, Owner.Name, Escalation_Date__c, ' +
                       'CreatedDate, Status ' +
                       'FROM Case ' +
                       'WHERE Escalation_Date__c <= :twentyFourHoursAgo';
        
        // 🧩 Add debug log to see what query and records are being fetched
    List<Case> casesForProcessing = Database.query(query);
    System.debug('🔍 [BAPPCaseEscalationBatch] Found ' + casesForProcessing.size() + ' cases for processing.');
    for (Case c : casesForProcessing) {
        System.debug('➡️ CaseId: ' + c.Id +
                     ', CaseNumber: ' + c.CaseNumber +
                     ', Account: ' + (c.Account__r != null ? c.Account__r.Name : 'N/A') +
                     ', Escalation_Date__c: ' + c.Escalation_Date__c);
    }

        return Database.getQueryLocator(query);
    }

    // -------------------------
    // EXECUTE
    // -------------------------
    global void execute(Database.BatchableContext bc, List<Case> scope) {
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        Datetime now = System.now();

        // Fetch Email Template (replace with your actual one)
        EmailTemplate template = EmailService.getInstance().getEmailTemplateByDevName('Broker_Service_Request_Reg_Escalation');

        String orgWideEmailId = MetadataService.getInstance().getAppSettingTextValue('BAPPOrgWideEmailAddress');
        
        String escalationEmail = MetadataService.getInstance().getAppSettingTextValue('BAPPSubmitsServiceRequestEscalation');

        // Loop through Cases
        for (Case c : scope) {
            if (c.Escalation_Date__c != null && isOlderThan24Hours(c.Escalation_Date__c, now)) {
                String subject = 'Case Escalation Alert - ' + c.CaseNumber;
                String htmlBody = template != null ? template.HtmlValue : '';

                htmlBody = htmlBody
                    .replace('{!Case.CaseNumber}', c.CaseNumber != null ? c.CaseNumber : '')
                    .replace('{AgencyName}', c.Account__r != null ? c.Account__r.Name : '')
                    .replace('{Case Record Link}', Label.BAPP_URL + c.Id);

                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[] { escalationEmail });
                mail.setOrgWideEmailAddressId(orgWideEmailId);
                mail.setSubject(subject);
                mail.setHtmlBody(htmlBody);
                emailsToSend.add(mail);
            }
        }

        if (!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend);
            System.debug('Case escalation emails sent: ' + emailsToSend.size());
        } else {
            System.debug('No Case escalation emails sent this run.');
        }
    }

    // -------------------------
    // HELPER METHOD
    // -------------------------
    @TestVisible
    private static Boolean isOlderThan24Hours(Datetime escalationDate, Datetime now) {
        return escalationDate <= now.addHours(-24);
    }

    // -------------------------
    // FINISH
    // -------------------------
    global void finish(Database.BatchableContext bc) {
        System.debug('CaseEscalationBatch completed.');
    }

    // -------------------------
    // SCHEDULABLE ENTRY POINT
    // -------------------------
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BAPPCaseEscalationBatch(), 200);
    }
}