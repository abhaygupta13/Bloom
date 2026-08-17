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
        Set<Id> caseIdsToUpdateAfterSign = new Set<Id>();
        Set<Id> caseIdsToUpdateBeforeSign = new Set<Id>();
        
        for (dfsle__EnvelopeStatus__c rec : newList) {
            system.debug('rec-->'+rec);
            
            dfsle__EnvelopeStatus__c oldRec = oldMap.get(rec.Id);
            Id sourceId = (Id) rec.dfsle__SourceId__c;
            system.debug('sourceId-->'+sourceId);
            system.debug('sourceId.getSObjectType()-->'+sourceId.getSObjectType());
            system.debug('Case.SObjectType-->'+ Case.SObjectType);
            if (sourceId.getSObjectType() == BrokerApplication__c.SObjectType) {
                // Broker Signed check
                if (rec.BrokerSigned__c == true && oldRec.BrokerSigned__c != rec.BrokerSigned__c) {
                    brokerAppIdsForEmail.add(sourceId);
                }
                // Status Completed check
                if (rec.dfsle__Status__c == 'Completed' && oldRec.dfsle__Status__c != rec.dfsle__Status__c) {
                    brokerAppIdsToUpdate.add(sourceId);
                }
            }
            if(sourceId.getSObjectType() == Case.SObjectType){
            system.debug('rec.dfsle__Status__c-->'+ rec.dfsle__Status__c);
            system.debug('oldRec.dfsle__Status__c-->'+ oldRec.dfsle__Status__c);
            system.debug('rec.dfsle__Status__c-->'+ rec.dfsle__Status__c);
                if (rec.dfsle__Status__c == 'Completed' && oldRec.dfsle__Status__c != rec.dfsle__Status__c) {
                    caseIdsToUpdateAfterSign.add(sourceId);
                }
                if (rec.dfsle__Status__c == 'Sent') {
                    caseIdsToUpdateBeforeSign.add(sourceId);
                }
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
        if (!caseIdsToUpdateAfterSign.isEmpty()) {
            List<Case> cases = CaseService.getInstance().getCaseByIds(caseIdsToUpdateAfterSign);
            for (Case cas : cases) {
                cas.AgreementRenewalStatus__c = 'Agreement Signed';
            }
            CaseService.getInstance().updateCaseWithoutTrigger(cases);
        }
        if (!caseIdsToUpdateBeforeSign.isEmpty()) {
            Set<Id> accountIdsToUpdate = new Set<Id>();
            List<Case> cases = CaseService.getInstance().getCaseByIds(caseIdsToUpdateBeforeSign);
            for (Case cas : cases) {
                accountIdsToUpdate.add(cas.AccountId);
                cas.AgreementRenewalStatus__c = 'In Progress';
            }
            CaseService.getInstance().updateCaseWithoutTrigger(cases);
            
            if(!accountIdsToUpdate.isEmpty()){
                List<Account> accounts = AccountService.getInstance().getAccountsByIds(accountIdsToUpdate);
                for (Account acc : accounts) {
                    acc.AgreementRenewalStatus__c = 'In Progress';
                }
                AccountService.getInstance().updateAccountsWithoutTrigger(accounts);
            }
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