/*
* @Author : Akshay Khairnar
* @CreatedDate : 24/07/2025
* @Description : BAPPNotifyBLTeamHandler - Sends email to all BL_Team queue members for the given Broker Application
*
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           Akshay                    Initial draft 
*****************************************************************************************************/
public class BAPPNotifyBLTeamHandler {
    @InvocableMethod(label='Notify BL Team' description='Sends email to all BL_Team queue members for the given Broker Application')
    public static void notifyBLTeam(List<Id> brokerAppIds) {
        if (brokerAppIds.isEmpty()) return;

        // Fetch BrokerApplication record                
        
        BrokerApplicationService service = BrokerApplicationService.getInstance();
        Set<Id> brokerAppIdSet = new Set<Id>(brokerAppIds);
        
        List<BrokerApplication__c> appList = service.getApplicationByIds(brokerAppIdSet);
        Map<Id, BrokerApplication__c> appMap = new Map<Id, BrokerApplication__c>(appList);

        
        EmailTemplate template = EmailService.getInstance().getEmailTemplateByDevName('Notify_BL_Intial_Approval');
         
        // Query Org-Wide Email Address
        String orgWideEmailId = MetadataService.getInstance().getAppSettingTextValue('BAPPOrgWideEmailAddress');


        // Get the Queue Id for BL_Team        
        QueueService qs = new QueueService();
        Group blQueue = qs.getGroupByDeveloperNameAndType('Bloom_Legal_BL', 'Queue');
        List<GroupMember> members = qs.getGroupMembersByGroupId(blQueue.Id);


        Set<Id> userIds = new Set<Id>();
        for (GroupMember m : members) {
            userIds.add(m.UserOrGroupId);
        }

        // Get Emails of Queue Users
       
        UserService userService = UserService.getInstance();
        List<User> userList = userService.getUsersByIds(userIds);
        Map<Id, User> userMap = new Map<Id, User>(userList);
       

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Id appId : brokerAppIds) {
            BrokerApplication__c app = appMap.get(appId);
            if (app == null) continue;

            String htmlBody = template.HtmlValue;
            htmlBody = htmlBody
                .replace('{!BrokerApplication__c.Name}', app.Name != null ? app.Name : '')
                .replace('{Application_Record_Link}', Label.BAPP_URL + app.Id)
                .replace('{!BrokerApplication__c.ApplicationNumber__c}', app.ApplicationNumber__c != null ? app.ApplicationNumber__c : '');

            for (User u : userMap.values()) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setOrgWideEmailAddressId(orgWideEmailId);
                mail.setToAddresses(new String[] { u.Email });
                mail.setSubject(template.Subject != null ? template.Subject : 'Application Approved by Bloom Broker Management');
                mail.setHtmlBody(htmlBody);
                emails.add(mail);
            }
        }

        if (!emails.isEmpty()) {
            EmailService.getInstance().sendEmail(emails);
        }
    }
}