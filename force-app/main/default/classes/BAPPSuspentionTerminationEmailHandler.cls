public class BAPPSuspentionTerminationEmailHandler {
    @InvocableMethod(label='Send Warning Emails')
    public static void sendWarningEmails(List<Id> accountIds) {
        if (accountIds.isEmpty()) return;
        
        // Fetch related Account with warning count and necessary fields
        List<Account> accounts = [SELECT Id, Name, WarningCounter__c,
                                  WarningReason1__c, WarningReason2__c, WarningReason3__c,
                                  SuspensionReason__c, Blacklist_Reason__c,
                                  ApprovalStatus__c, Scenarios__c,
                                  ExecutiveSalesDirector__c,
                                  LineManager__c,
                                  isSuspended__c,
                                  Blacklisted__c,
                                  BBMId__c,
                                  Broker_Application__c,
                                  Broker_Application__r.ApplicationNumber__c
                                  FROM Account WHERE Id IN :accountIds];
        
        if (accounts.isEmpty()) {
            System.debug('No Account found for Ids: ' + accountIds);
            return;
        }
        
        // Fetch related Contacts with required roles
        List<Contact> contacts = [SELECT Id, Email, Name, AccountId, BrokerContactRole__c
                                  FROM Contact 
                                      WHERE AccountId IN :accountIds
                                  AND BrokerContactRole__c INCLUDES ('SuperAdmin', 'Partner','CEO', 'Owner','Admin')
                                  AND Email != null];
        system.debug('Contact ' + contacts);
        Map<Integer, String> templateMap = new Map<Integer, String>{
            1 => 'Broker_Warning1_Template',
                2 => 'Broker_Warning2_Template',
                3 => 'Broker_Warning3_Template'
                };
                    
                List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        
        for (Account acc : accounts) {
            // ---------- WARNING EMAIL LOGIC ----------
            if (acc.Blacklisted__c != true && acc.isSuspended__c != true) {
                Integer warnCount = acc.WarningCounter__c == null ? 0 : Integer.valueOf(acc.WarningCounter__c);
                if (warnCount < 3) {
                    String reason = warnCount == 0 ? acc.WarningReason1__c :
                    warnCount == 1 ? acc.WarningReason2__c :
                    acc.WarningReason3__c;
                    
                    EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :templateMap.get(warnCount + 1) LIMIT 1];
                    
                    // Fetch Org-Wide Email Address ID from Metadata Service
                    MetadataService objMetadataService = MetadataService.getInstance();
                    String orgWideEmail = objMetadataService.getAppSettingTextValue('BAPPOrgWideEmailAddress');
                    
                    for (Contact c : contacts) {
                        if (c.AccountId != acc.Id) continue;
                        
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        mail.setTargetObjectId(c.Id);
                        mail.setTemplateId(template.Id);
                        mail.setWhatId(acc.Id);
                        mail.setSaveAsActivity(false);
                        if (String.isNotBlank(orgWideEmail)) {
                            mail.setOrgWideEmailAddressId(orgWideEmail);
                        }
                        emailsToSend.add(mail);
                    }
                    
                    acc.WarningCounter__c = warnCount + 1;
                }
            }
            
            
            // ---------- TERMINATION EMAIL ----------
            if (acc.Blacklisted__c == true) {
                EmailTemplate suspTemplate = [SELECT Id, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Termination_Agency_Email' LIMIT 1];
                String suspensionSubject = 'Account Terminated '+ acc.Name;
                for (Contact c : contacts) {
                    if (c.AccountId != acc.Id) continue;
                    
                    String htmlBody = suspTemplate.HtmlValue;
                    htmlBody = htmlBody
                        .replace('{{Name}}', acc.Name != null ? acc.Name : '')
                        .replace('{{Reference_ID}}', acc.Broker_Application__r.ApplicationNumber__c != null ? acc.Broker_Application__r.ApplicationNumber__c : '')
                        .replace('{{Effective_Date}}', String.valueOf(Date.today()))
                        .replace('{{Reason}}', acc.Blacklist_Reason__c != null ? acc.Blacklist_Reason__c : '');
                    
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setTargetObjectId(c.Id);
                    mail.setSubject(suspensionSubject);
                    mail.setHtmlBody(htmlBody);
                    mail.setSaveAsActivity(false);
                    emailsToSend.add(mail);
                }
            }
            
           // ---------- SUSPENSION EMAIL ----------
            if (acc.isSuspended__c == true && acc.Blacklisted__c == false) {
                System.debug('In suspension Email');
                EmailTemplate termTemplate = [SELECT Id, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Suspension_Agency_Email' LIMIT 1];
                String terminationSubject = 'Account Suspended '+ acc.Name;
                System.debug('Out For Suspension Email');
                for (Contact c : contacts) {
                    System.debug('in For Suspension Email');
                    if (c.AccountId != acc.Id) continue;
                    System.debug('in If For Suspension Email');
                    String htmlBody = termTemplate.HtmlValue;
                    htmlBody = htmlBody
                        .replace('{{Name}}', acc.Name != null ? acc.Name : '')
                        .replace('{{Reference_ID}}', acc.Broker_Application__r.ApplicationNumber__c != null ? acc.Broker_Application__r.ApplicationNumber__c : '')
                        .replace('{{Effective_Date}}', String.valueOf(Date.today()))
                        .replace('{{Reason}}', acc.SuspensionReason__c != null ? acc.SuspensionReason__c : '');
                    
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setTargetObjectId(c.Id);
                    mail.setSubject(terminationSubject);
                    mail.setHtmlBody(htmlBody);
                    mail.setSaveAsActivity(false);
                    emailsToSend.add(mail);
                    System.debug('Email Sent');
                }
            }
            
            // ---------- LINE MANAGER APPROVED TERMINATION EMAIL ----------
            if (acc.ApprovalStatus__c == 'Approved By Line Manager' && acc.Scenarios__c == 'Terminate' && acc.ExecutiveSalesDirector__c != null) {
                EmailTemplate lmTermTemplate = [SELECT Id, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Line_Manager_Approved' LIMIT 1];
                
                String htmlBody = lmTermTemplate.HtmlValue;
                htmlBody = htmlBody
                    .replace('{{Name}}', acc.Name != null ? acc.Name : '')
                    .replace('{{ESD}}', acc.ExecutiveSalesDirector__c)
                    .replace('{{Line Manager}}', acc.LineManager__c != null ? acc.LineManager__c : '')
                    .replace('{{Reference_ID}}', acc.Broker_Application__r.ApplicationNumber__c != null ? acc.Broker_Application__r.ApplicationNumber__c : '')
                    .replace('{{Effective_Date}}', String.valueOf(Date.today()))
                    .replace('{{Reason}}', acc.SuspensionReason__c != null ? acc.SuspensionReason__c : '')
                    .replace('{{{{Application_Portal_Link}}}}', Label.BAPPAccountURL + acc.Id);
                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setTargetObjectId(acc.ExecutiveSalesDirector__c);
                mail.setSubject('Line Manager Approved - Termination'); // Optional subject override
                mail.setHtmlBody(htmlBody);
                mail.setSaveAsActivity(false);
                emailsToSend.add(mail);
            }
            
            // ---------- LINE MANAGER APPROVED SUSPEND EMAIL ----------
            if (acc.ApprovalStatus__c == 'Approved By Line Manager' && acc.Scenarios__c == 'Suspend' && acc.ExecutiveSalesDirector__c != null) {
                EmailTemplate lmSuspTemplate = [SELECT Id, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Line_Manager_Approved_Suspend' LIMIT 1];
                
                String htmlBody = lmSuspTemplate.HtmlValue;
                htmlBody = htmlBody
                    .replace('{{Name}}', acc.Name != null ? acc.Name : '')
                    .replace('{{ESD}}', acc.ExecutiveSalesDirector__c)
                    .replace('{{Line Manager}}', acc.LineManager__c != null ? acc.LineManager__c : '')
                    .replace('{{Reference_ID}}', acc.Broker_Application__r.ApplicationNumber__c != null ? acc.Broker_Application__r.ApplicationNumber__c : '')
                    .replace('{{Effective_Date}}', String.valueOf(Date.today()))
                    .replace('{{Reason}}', acc.SuspensionReason__c != null ? acc.SuspensionReason__c : '');
                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setTargetObjectId(acc.ExecutiveSalesDirector__c);
                mail.setSubject('Line Manager Approved - Suspension'); // Optional subject override
                mail.setHtmlBody(htmlBody);
                mail.setSaveAsActivity(false);
                emailsToSend.add(mail);
            }
            
            
            // ---------- LINE MANAGER REJECT TERMINATION EMAIL ----------
            if (acc.ApprovalStatus__c == 'Rejected By Line Manager' && acc.Scenarios__c == 'Terminate' && acc.BBMId__c != null) {
                EmailTemplate lmTermTemplate = [SELECT Id, HtmlValue, Body FROM EmailTemplate WHERE DeveloperName = 'Rejected_By_Line_Manager_Terminated' LIMIT 1];
                for (Contact c : contacts) {
                    if (c.AccountId != acc.Id) continue;
                    system.debug('Inside LINE MANAGER REJECT TERMINATION EMAIL');
                    system.debug('AccountId LM Terminate--->'+acc.Id);
                    system.debug('BBMId LM Terminate--->'+acc.BBMId__c);
                    
                    
                    
                    String htmlBody = lmTermTemplate.HtmlValue;
                    htmlBody = htmlBody
                        .replace('{{Name}}', acc.Name != null ? acc.Name : '')
                        .replace('{{ESD}}', acc.ExecutiveSalesDirector__c != null ? acc.ExecutiveSalesDirector__c : '')
                        .replace('{{Reference_ID}}', acc.Broker_Application__r.ApplicationNumber__c != null ? acc.Broker_Application__r.ApplicationNumber__c : '')
                        .replace('{{Rejection_Date}}', String.valueOf(Date.today()))
                        .replace('{{Rejection_Reason}}', acc.SuspensionReason__c != null ? acc.SuspensionReason__c : '');
                    
                    
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setTargetObjectId(acc.BBMId__c);
                    mail.setTemplateId(lmTermTemplate.Id);
                    //mail.setWhatId(acc.Id);
                    mail.setSaveAsActivity(false);
                    emailsToSend.add(mail);
                }
            }
            
            // ---------- LINE MANAGER REJECT SUSPEND EMAIL ----------
            if (acc.ApprovalStatus__c == 'Rejected By Line Manager' && acc.Scenarios__c == 'Suspend' && acc.BBMId__c != null) {
                EmailTemplate lmSuspTemplate = [SELECT Id, HtmlValue,Body FROM EmailTemplate WHERE DeveloperName = 'Rejected_By_Line_Manager_Suspeneded' LIMIT 1];
                for (Contact c : contacts) {
                    if (c.AccountId != acc.Id) continue;
                    system.debug('Inside LINE MANAGER REJECT SUSPEND EMAIL');
                    system.debug('AccountId Suspend--->'+acc.Id);
                    system.debug('BBMId Suspend--->'+acc.BBMId__c);
                    
                    String htmlBody = lmSuspTemplate.HtmlValue;
                    htmlBody = htmlBody
                        .replace('{{Name}}', acc.Name != null ? acc.Name : '')
                        .replace('{{ESD}}', acc.ExecutiveSalesDirector__c != null ? acc.ExecutiveSalesDirector__c : '')
                        .replace('{{Reference_ID}}', acc.Broker_Application__r.ApplicationNumber__c != null ? acc.Broker_Application__r.ApplicationNumber__c : '')
                        .replace('{{Rejection_Date}}', String.valueOf(Date.today()))
                        .replace('{{Rejection_Reason}}', acc.SuspensionReason__c != null ? acc.SuspensionReason__c : '');
                    
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setTargetObjectId(acc.BBMId__c);
                    mail.setTemplateId(lmSuspTemplate.Id);
                    //mail.setWhatId(acc.Id);
                    mail.setSaveAsActivity(false);
                    emailsToSend.add(mail);
                }
            }
            
             // ---------- ESD REJECT TERMINATION EMAIL ----------
            if (acc.ApprovalStatus__c == 'Rejected By Executive Sales Director' && acc.Scenarios__c == 'Terminate' && acc.BBMId__c != null) {
                EmailTemplate lmTermTemplate = [SELECT Id, HtmlValue, Body FROM EmailTemplate WHERE DeveloperName = 'Rejected_By_Line_Manager_Terminated' LIMIT 1];
                for (Contact c : contacts) {
                    if (c.AccountId != acc.Id) continue;
                    system.debug('Inside ESD REJECT TERMINATION EMAIL');
                    system.debug('AccountId ESD Terminate--->'+acc.Id);
                    system.debug('BBMId ESD Terminate--->'+acc.BBMId__c);
                    
                    
                    String htmlBody = lmTermTemplate.HtmlValue;
                    htmlBody = htmlBody
                        .replace('{{Name}}', acc.Name != null ? acc.Name : '')
                        .replace('{{ESD}}', acc.ExecutiveSalesDirector__c != null ? acc.ExecutiveSalesDirector__c : '')
                        .replace('{{Reference_ID}}', acc.Broker_Application__r.ApplicationNumber__c != null ? acc.Broker_Application__r.ApplicationNumber__c : '')
                        .replace('{{Rejection_Date}}', String.valueOf(Date.today()))
                        .replace('{{Rejection_Reason}}', acc.SuspensionReason__c != null ? acc.SuspensionReason__c : '');
                    
                    
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setTargetObjectId(acc.BBMId__c);
                    mail.setTemplateId(lmTermTemplate.Id);
                    //mail.setWhatId(acc.Id);
                    mail.setSaveAsActivity(false);
                    emailsToSend.add(mail);
                }
            }
            
            // ---------- ESD REJECT SUSPEND EMAIL ----------
            if (acc.ApprovalStatus__c == 'Rejected By Executive Sales Director' && acc.Scenarios__c == 'Suspend' && acc.BBMId__c != null) {
                EmailTemplate lmSuspTemplate = [SELECT Id,HtmlValue,Body FROM EmailTemplate WHERE DeveloperName = 'Rejected_By_Line_Manager_Suspeneded' LIMIT 1];
                for (Contact c : contacts) {
                    if (c.AccountId != acc.Id) continue;
                    
                    String htmlBody = lmSuspTemplate.HtmlValue;
                    htmlBody = htmlBody
                        .replace('{{Name}}', acc.Name != null ? acc.Name : '')
                        .replace('{{ESD}}', acc.ExecutiveSalesDirector__c != null ? acc.ExecutiveSalesDirector__c : '')
                        .replace('{{Reference_ID}}', acc.Broker_Application__r.ApplicationNumber__c != null ? acc.Broker_Application__r.ApplicationNumber__c : '')
                        .replace('{{Rejection_Date}}', String.valueOf(Date.today()))
                        .replace('{{Rejection_Reason}}', acc.SuspensionReason__c != null ? acc.SuspensionReason__c : '');
                    
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setTargetObjectId(acc.BBMId__c);
                    mail.setTemplateId(lmSuspTemplate.Id);
                    //mail.setWhatId(acc.Id);
                    mail.setSaveAsActivity(false);
                    emailsToSend.add(mail);
                }
            }
        }
        
        if (!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend);
            update accounts;
        }
    }
}