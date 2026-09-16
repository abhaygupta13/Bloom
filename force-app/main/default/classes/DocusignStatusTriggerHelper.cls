/*
* Author         : Swapnil Patil
* Created Date   : 21st April 2026
* Description    : Move logic from BAPP DocuSign Status flow to trigger for handling status update and email notification
*/
/*****************************************************************************************************
* Version       Author                  Date                        Comment
* 1.0           Swapnil Patil           21st April 2026             Updates Broker Application status to 'Approved'
*****************************************************************************************************/
public without sharing class DocusignStatusTriggerHelper {
    
    private static final String BAPP_BBM_FIRST_SIGNED_TEMPLATE { get { return 'Notify BBM On Under Agreement - First Signed'; } } //BAPP
    
    public static void processAfterUpdate(List<dfsle__EnvelopeStatus__c> newList, Map<Id, dfsle__EnvelopeStatus__c> oldMap) {
        
        Set<Id> brokerAppIdsToUpdate = new Set<Id>();
        Set<Id> brokerAppIdsForEmail = new Set<Id>();
        
        for (dfsle__EnvelopeStatus__c rec : newList) {
            
            dfsle__EnvelopeStatus__c oldRec = oldMap.get(rec.Id);
            Id sourceId = (Id) rec.dfsle__SourceId__c;
            
            if (sourceId.getSObjectType() != BrokerApplication__c.SObjectType) {
                System.debug('Not a BrokerApplication record, skipping');
                continue;
            }
            
            // Status Completed check
            if (rec.dfsle__Status__c == 'Completed' && oldRec.dfsle__Status__c != rec.dfsle__Status__c) {
                brokerAppIdsToUpdate.add(sourceId);
            }
            
            // Broker Signed check
            if (rec.BrokerSigned__c == true && oldRec.BrokerSigned__c != rec.BrokerSigned__c) {
                brokerAppIdsForEmail.add(sourceId);
            }
        }
        
        // BROKER APPLICATION LOGIC
        if (!brokerAppIdsToUpdate.isEmpty()) {
            List<BrokerApplication__c> brokerApps = BrokerApplicationService.getInstance().getApplicationByIds(brokerAppIdsToUpdate);
            for (BrokerApplication__c app : brokerApps) {
                app.ApprovalStatus__c = 'Approved';
            }
            BrokerApplicationService.getInstance().updateBrokerApplications(brokerApps);
        }
        
        // EMAIL LOGIC
        if (!brokerAppIdsForEmail.isEmpty()) {
            EmailTemplate template = EmailService.getInstance().getEmailTemplateByName(BAPP_BBM_FIRST_SIGNED_TEMPLATE);
            List<String> toEmails = new List<String>{ System.Label.BAPP_Bloom_Signatory };
                List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            
            for (Id appId : brokerAppIdsForEmail) {
                Messaging.SingleEmailMessage mail = EmailService.getInstance().getSingleEmailMessageWithoutTargetObjectId(template.Id,null,appId,toEmails,null,null);
                emails.add(mail);
            }
            EmailService.getInstance().sendEmail(emails);
        }
    }
}