/*
* @Author        : Rushikesh Jadhav
* @CreatedDate   : 26th SEP 2025
* @Description   : Helper class for Broker Unit Assignment trigger
*/
/*****************************************************************************************************
* Version       Author       Date             Comment                                                                       
* 1.1         Rushikesh      15OCT2025        Modified to send emails to Agent contacts of assigned contact’s account
*****************************************************************************************************/
public class BrokerUnitAssignmentHelper {

    // Send Unit Assignment Emails to Agent Contacts
    public static void sendUnitAssignmentEmails(List<BrokerUnitAssignment__c> assignments) {
        if (assignments.isEmpty()) return;
    
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        ContactService objContactService = ContactService.getInstance();
    
        //  Collect assigned Contact Ids
        Set<Id> assignedContactIds = new Set<Id>();
        for (BrokerUnitAssignment__c b : assignments) {
            if (b.Contact__c != null) assignedContactIds.add(b.Contact__c);
        }
        if (assignedContactIds.isEmpty()) return;
    
        // Get Contact → Account mapping from ContactService
        List<Contact> assignedContacts = objContactService.getContactByIds(new List<Id>(assignedContactIds));
        Map<Id, Id> contactToAccountMap = new Map<Id, Id>();
        for (Contact c : assignedContacts) {
            if (c.AccountId != null) contactToAccountMap.put(c.Id, c.AccountId);
        }
        if (contactToAccountMap.isEmpty()) return;
    
        //  Get all Agent Contacts for these Accounts via ContactService
        Set<Id> accountIds = new Set<Id>(contactToAccountMap.values());
        List<Contact> agentContacts = objContactService.getAgentContactsByAccountIds(accountIds); 
        
    
        if (agentContacts.isEmpty()) return;
    
        // Group Agent Contacts by AccountId
        Map<Id, List<Contact>> accountToAgentsMap = new Map<Id, List<Contact>>();
        for (Contact agent : agentContacts) {
            if (!accountToAgentsMap.containsKey(agent.AccountId)) {
                accountToAgentsMap.put(agent.AccountId, new List<Contact>());
            }
            accountToAgentsMap.get(agent.AccountId).add(agent);
        }
    
        //  Get Email Template via MetadataService
        /*Id templateId = objMetadataService.getAppSettingTextValue('UnitAssignmentNotification');*/
        Id templateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'UnitAssignmentNotification' LIMIT 1].Id;
        if (templateId == null) return;
    
        //  Build and send emails via EmailService
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        List<Contact> contactsToUpdate = new List<Contact>();
    
        for (BrokerUnitAssignment__c b : assignments) {
            Id assignedContactId = b.Contact__c;
            if (assignedContactId == null || !contactToAccountMap.containsKey(assignedContactId)) continue;
    
            Id accountId = contactToAccountMap.get(assignedContactId);
            List<Contact> agents = accountToAgentsMap.get(accountId);
            if (agents == null || agents.isEmpty()) continue;
    
            for (Contact agent : agents) {
                Messaging.SingleEmailMessage mail = objEmailService.getSingleEmailMessageWithTargetObjectAsRecipient(
                    templateId,
                    null,
                    b.Id,
                    agent.Id,
                    null,
                    null,
                    null
                );
                emails.add(mail);
    
                agent.IsSendEmail__c = true;
                contactsToUpdate.add(agent);
            }
        }
    
        if (!emails.isEmpty()) objEmailService.sendEmail(emails);
        if (!contactsToUpdate.isEmpty()) update contactsToUpdate;
    }

    // Reset IsSendEmail__c flag at end of the day (via batch or scheduler)
    public static void resetIsSendMail() {
        List<Contact> contactsToReset = [
            SELECT Id, IsSendEmail__c 
            FROM Contact 
            WHERE IsSendEmail__c = true
        ];
        for (Contact c : contactsToReset) {
            c.IsSendEmail__c = false;
        }
        if (!contactsToReset.isEmpty()) update contactsToReset;
    }
}