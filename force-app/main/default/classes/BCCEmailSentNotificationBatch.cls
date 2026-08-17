/*****************************************************************************************
Class       : BCCEmailSentNotificationBatch
Author      :  Jhilik
Description : 
test Class  : BCCEmailSentNotificationBatchTest
Created Date: 11-Feb-2026
*****************************************************************************************/
public without sharing class BCCEmailSentNotificationBatch implements Database.Batchable<sObject>, Schedulable,Database.Stateful {
    private static final string BCC_EMAIL_SENT_NOTIFICATION_TEMPLATE_ID { get { return 'BCCEmailSentTemplateId'; } }
    private static final string BLOOM_NO_REPLY_INTERNAL_EMAIL_ID { get { return 'NoReplySalesIT'; } }

    public Database.QueryLocator start(Database.BatchableContext bc) { 
        DateTime dt = DateTime.now().addDays(-1);
        String queryStr = 'SELECT Id, BCCAnnouncementSentTime__c, Unit__c, Unit__r.Name, Unit__r.Project__c, Unit__r.Project__r.Name FROM Handover__c WHERE BCCAnnouncementSentTime__c >= :dt';
        return Database.getQueryLocator(queryStr);
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new BCCEmailSentNotificationBatch(), 100);
    }

    public void execute(Database.BatchableContext bc, List<Handover__c> scope) {
        Map<Id, List<Handover__c>> projectIdToHandoverListMap = new Map<Id, List<Handover__c>>();
        Map<String, List<String>> projectNameToUnitNameList = new Map<String, List<String>>();
        for(Handover__c hoRec : scope){
            if(!projectIdToHandoverListMap.containsKey(hoRec.Unit__r.Project__c)){
                projectIdToHandoverListMap.put(hoRec.Unit__r.Project__c, new List<Handover__c>());
            }
            projectIdToHandoverListMap.get(hoRec.Unit__r.Project__c).add(hoRec);
            if(!projectNameToUnitNameList.containsKey(hoRec.Unit__r.Project__r.Name)){
                projectNameToUnitNameList.put(hoRec.Unit__r.Project__c, new List<String>());
            }
            projectNameToUnitNameList.get(hoRec.Unit__r.Project__c).add(hoRec.Unit__r.Name);
        }

        sendEmail(projectIdToHandoverListMap);
    }

    public void sendEmail(Map<Id, List<Handover__c>> projectIdToHandoverListMap ){
        EmailService objEmailService = EmailService.getInstance();
        MetadataService objMetadataService = MetadataService.getInstance();
        Id bccEmailNotificationSentTemplateId = objMetadataService.getAppSettingTextValue(BCC_EMAIL_SENT_NOTIFICATION_TEMPLATE_ID);
        Id noReplyBloomInternalEmailId = objMetadataService.getAppSettingTextValue(BLOOM_NO_REPLY_INTERNAL_EMAIL_ID);

        List<User> treasuryTeamUsers = [SELECT Id, Email FROM User 
                                        WHERE Id IN (SELECT UserOrGroupId FROM GroupMember 
                                        WHERE Group.Type = 'Queue' AND Group.Name = 'Handover Treasury Queue')];
                                    
        List<String> emailsToNotify = new List<String>();
        for(User u : treasuryTeamUsers){
            if(String.isNotBlank(u.Email)){
                emailsToNotify.add(u.Email);
            }           
        }
        emailsToNotify.add('jhilikgandhi@yopmail.com');
                       
        EmailTemplate emailTemplate = objEmailService.getEmailTemplateById(bccEmailNotificationSentTemplateId);
        String emailBody = emailTemplate.HtmlValue;
        String htmlBody = ('<table style="border-collapse: collapse" Border="1" ><thead><tr><th>S. No</th><th>Project Name</th> <th>Unit Number</th> </tr></thead><tbody>');          
        
        Integer i = 1;
        String baseUrl = System.URL.getOrgDomainUrl().toExternalForm();
        for(Id projectRecId : projectIdToHandoverListMap.keySet()){
            for(Handover__c handoverRec : projectIdToHandoverListMap.get(projectRecId)){
                htmlBody += '<tr><td>' + i++ + '</td>';
                String projectUrl = baseUrl + '/lightning/r/Project__c/' + handoverRec.Unit__r.Project__c + '/view';
                htmlBody += '<td><a href="' + projectUrl + '" target="_blank">' + handoverRec.Unit__r.Project__r.Name + '</a></td>';
                String unitUrl = baseUrl + '/lightning/r/Unit__c/' + handoverRec.Unit__c + '/view';
                htmlBody += '<td><a href="' + unitUrl + '" target="_blank">' + handoverRec.Unit__r.Name + '</a></td></tr>';
                //htmlBody += '<td>' + handoverRec.Unit__r.Project__r.Name + '</td>';
                //htmlBody += '<td>' + handoverRec.Unit__r.Name + '</td></tr>';
            }
        }
        htmlBody += ('</tbody></table>');
        emailBody = emailBody.replace('{{PROJECTANDUNITTABLE}}', htmlBody);
        // Send email
        Messaging.SingleEmailMessage email = objEmailService.getSingleEmailMessage(emailsToNotify, null, null, emailTemplate.Subject, emailBody, noReplyBloomInternalEmailId, new List<String>{'rattia@bloomholding.com'}, null);
        // Sending emails
        Messaging.SendEmailResult[] results = objEmailService.sendEmail(new List<Messaging.SingleEmailMessage>{email});
    }

    public void finish(Database.BatchableContext bc) {
    }
}