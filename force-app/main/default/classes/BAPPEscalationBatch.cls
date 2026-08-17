/*
* @Author      : Akshay Khairnar
* @Description : Batch class to send the Escalation Notifications
* Test Apex: BAPPEscalationBatchTest           
*****************************************************************************************************/

global class BAPPEscalationBatch implements Database.Batchable<SObject>, Schedulable, Database.Stateful {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime now = System.now();
        Datetime fifteenMinutesAgo = now.addMinutes(-15);
        
        
        String query = 'SELECT Id, Name, ApplicationNumber__c, RFIRaisedBy__c, RFIRaisedBy__r.Name, ' +
            			'RFIEscalationDate__c, RegistrationEscalationDate__c, AgencyEmail__c, Owner.Name ' +
            			'FROM BrokerApplication__c ' +
            			'WHERE (RFIEscalationDate__c >= :fifteenMinutesAgo ' +
            			'AND RFIEscalationDate__c <= :now ' +
            			'AND ApprovalStatus__c = \'RFI\' ' +
            			'AND IsRFIUpdated__c = true) ' + 
            			'OR (RegistrationEscalationDate__c >= :fifteenMinutesAgo ' +
            			'AND RegistrationEscalationDate__c <= :now ' +
            			'AND ApprovalStatus__c = \'Submitted\')';
        
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<BrokerApplication__c> scope) {
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        Datetime now = System.now();
        
        // Fetch the escalation email template
        EmailTemplate rfitemplate = EmailService.getInstance().getEmailTemplateByDevName('Broker_Application_RFI_Escalation');
        EmailTemplate regtemplate = EmailService.getInstance().getEmailTemplateByDevName('Broker_Application_Reg_Escalation');
        
        // Fetch Org-Wide Email Address
        String orgWideEmailId = MetadataService.getInstance().getAppSettingTextValue('BAPPOrgWideEmailAddress');
    	//Fetch MetaData for RFI
        String escalationRFIEmail = MetadataService.getInstance().getAppSettingTextValue('BAPPRFIRelatedEscalation');
        
        for (BrokerApplication__c app : scope) {
            String teamName = (app.RFIRaisedBy__r != null && app.RFIRaisedBy__r.Name != null) ? app.RFIRaisedBy__r.Name : '';
            // --- RFI Escalation ---
            if (app.RFIEscalationDate__c != null && isEscalationDue(app.RFIEscalationDate__c, now)) {
                String subjectrfi = 'Escalation Pending '+ teamName +' Review Post RFI Response';
                String rfiEmail = escalationRFIEmail;
                
                if (!String.isBlank(rfiEmail)) {
                    String htmlBody = rfitemplate.HtmlValue;
                    htmlBody = htmlBody
                        .replace('{!BrokerApplication__c.Name}', app.Name != null ? app.Name : '')
                        .replace('{!BrokerApplication__c.ApplicationNumber__c}', app.ApplicationNumber__c != null ? app.ApplicationNumber__c : '')
                        .replace('{Application Record Link}', Label.BAPP_URL + app.Id)
                        .replace('{TeamName}', teamName);
                    
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setToAddresses(new String[] { rfiEmail });
                    mail.setOrgWideEmailAddressId(orgWideEmailId);
                    mail.setSubject(subjectrfi);
                    mail.setHtmlBody(htmlBody);
                    emailsToSend.add(mail);
                }
            }
            
            // --- Registration Escalation ---
            if (app.RegistrationEscalationDate__c != null && isEscalationDue(app.RegistrationEscalationDate__c, now)) {
            	String escalationRegEmail = MetadataService.getInstance().getAppSettingTextValue('BAPPSubmitRegistrationEscalation');
                String subjectreg = 'Escalation: Application Request Pending Action from '+ teamName +' Team';
                String regEmail = escalationRegEmail;
                if (!String.isBlank(regEmail)) {
                    String htmlBody = regtemplate.HtmlValue;
                    htmlBody = htmlBody
                        .replace('{!BrokerApplication__c.Name}', app.Name != null ? app.Name : '')
                        .replace('{!BrokerApplication__c.ApplicationNumber__c}', app.ApplicationNumber__c != null ? app.ApplicationNumber__c : '')
                        .replace('{Application Record Link}', Label.BAPP_URL + app.Id)
                        .replace('{TeamName}', teamName);
                    
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setToAddresses(new String[] { regEmail });
                    mail.setOrgWideEmailAddressId(orgWideEmailId);
                    mail.setSubject(subjectreg);
                    mail.setHtmlBody(htmlBody);
                    emailsToSend.add(mail);
                }
            }
        }
        
        EmailService.getInstance().sendEmail(emailsToSend);
    }
    
    private static Boolean isEscalationDue(Datetime escalationDate, Datetime now) {
        Datetime fifteenMinsAgo = now.addMinutes(-15);
        return escalationDate >= fifteenMinsAgo && escalationDate <= now;
    }
    
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new BAPPEscalationBatch(), 200);
    }
    
    global void finish(Database.BatchableContext bc) {
        
    }
}