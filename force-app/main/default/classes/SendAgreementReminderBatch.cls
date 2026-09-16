/*
* @Author      : Akshay Khairnar
* @Description : Batch class to send the Agreement Reminder Notifications to Agency 7, 15 and 30 days after the Agreement initiation
                 by BBM
* Test Apex: SendAgreementReminderBatchTest           
************************************************************************************************************************************/

public class SendAgreementReminderBatch implements Database.Batchable<SObject>,Schedulable {
	
    private static final string MTD_BAPP_BROKER_NO_REPLY_EMAIL_ID { get { return 'BAPPOrgWideEmailAddress'; } }
    private static final string ET_BROKER_APPLICATION_AGREEMENT_REMINDER{ get { return 'Broker_Application_Agreement_Reminder'; } }
   
    
    private static final Integer EMAIL_DAY_7  = 7;
    private static final Integer EMAIL_DAY_15 = 15;
    private static final Integer EMAIL_DAY_30 = 30;
    MetadataService objMetadataService = MetadataService.getInstance();
    public Database.QueryLocator start(Database.BatchableContext bc) {
      
        return Database.getQueryLocator([
            SELECT Id, Name, AgencyEmail__c,
                   AgreementInitiationDate__c,
                   AgreementRemainingDays__c,
                   ApplicationNumber__c,
                   CompanyPhone_Number__c,
                   CountryCode__c
            FROM BrokerApplication__c
            WHERE
            AgencyEmail__c != null
            AND ApprovalStatus__c = 'Under Agreement' AND isSuspended__c = false
            AND BrokerSigned__c = false
        ]);
        
    }

    public void execute(Database.BatchableContext bc, List<BrokerApplication__c> scope) {
		System.debug('SendAgreementReminderBatch.execute 37 >>' + bc);
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        List<BrokerApplication__c> updates = new List<BrokerApplication__c>();

        // ===== SMS ADD =====
        List<BrokerApplication__c> appsForSMS = new List<BrokerApplication__c>();
        Set<Id> applicationIdsForSMS = new Set<Id>();
        // ===================

        BrokerApplicationService brokerApplicationService = BrokerApplicationService.getInstance();
        
        // Load the Classic Email Template
        EmailTemplate template = EmailService.getInstance().getEmailTemplateByDevName(ET_BROKER_APPLICATION_AGREEMENT_REMINDER);
        // Query Org-Wide Email Address
        Id orgWideEmailId = objMetadataService.getAppSettingTextValue(MTD_BAPP_BROKER_NO_REPLY_EMAIL_ID);
        
        Date today = Date.today();

        for (BrokerApplication__c app : scope) {
            Boolean hasUpdate = false;

            BrokerApplication__c updatedApp = new BrokerApplication__c(Id = app.Id);

            // ===== SMS ADD =====
            applicationIdsForSMS.add(app.Id);
            System.debug('applicationIdsForSMS 61>> '+applicationIdsForSMS);
            // ===================

            // Agreement logic
            if (app.AgreementInitiationDate__c != null) {
                Integer agreementDaysPassed = app.AgreementInitiationDate__c.daysBetween(today);
                System.debug('agreementDaysPassed 67 >> '+agreementDaysPassed);
                Integer remainingDays = 30 - agreementDaysPassed;
                System.debug('remainingDays 69 >> '+agreementDaysPassed);
                updatedApp.AgreementRemainingDays__c = String.valueOf(remainingDays);
                hasUpdate = true;             

                if (agreementDaysPassed >= 30) {
                    updatedApp.IsAgreementExpired__c = true;
                    System.debug('Inside if agreementDaysPassed 75 >> ');
                } else {
                    updatedApp.IsAgreementExpired__c = false;
                     System.debug('Inside else agreementDaysPassed 78 >> ');
                }
                if (agreementDaysPassed == EMAIL_DAY_7 ||
                    agreementDaysPassed == EMAIL_DAY_15 ||
                    agreementDaysPassed == EMAIL_DAY_30) {

                    String subject = Label.BAPPAgencyAgreementPendingReminderSubject + app.ApplicationNumber__c;
                    
                    String remainingPhrase = '';
                    if (remainingDays == 0) {
                        remainingPhrase = 'within today';
                    } else if (remainingDays == 1) {
                        remainingPhrase = 'within 1 day';
                    } else {
                        remainingPhrase = 'within next ' + remainingDays + ' days';
                    }
                    
                    String htmlBody = template.HtmlValue;

                    htmlBody = htmlBody
                        .replace('{!BrokerApplication__c.Name}', app.Name != null ? app.Name : '')
                        .replace('{AgreementRemainingDays__c}', remainingPhrase)
                        .replace('{!BrokerApplication__c.AgreementInitiationdate__c}', app.AgreementInitiationDate__c != null ? String.valueOf(app.AgreementInitiationDate__c) : '')
                        .replace('{!BrokerApplication__c.ApplicationNumber__c}', app.ApplicationNumber__c != null ? app.ApplicationNumber__c : '');

                    Messaging.SingleEmailMessage agreementEmail =
                        EmailService.getInstance()
                            .getSingleEmailMessage(
                                new String[] { app.AgencyEmail__c },
                                null,
                                subject,
                                htmlBody,
                                orgWideEmailId
                            );

					emails.add(agreementEmail);
                }
				 System.debug('emails 115 >> '+ emails);
                // ===== SMS ADD (Daily till 30 days Agency) =====
                if (agreementDaysPassed >= 0 &&
                    agreementDaysPassed < 30 &&
                    String.isNotBlank(app.CompanyPhone_Number__c) &&
                    String.isNotBlank(app.CountryCode__c)) {

                    appsForSMS.add(app);
                    System.debug('appsForSMS 123 >> '+ appsForSMS);
                }
                // =======================================
            }

            if (hasUpdate) {
                
                updates.add(updatedApp);
                System.debug('updates 131 >> '+ updates);
            }
        }

        //Send Email
        EmailService.getInstance().sendEmail(emails);
        System.debug('Sent');

        //Update Broker Application
        brokerApplicationService.updateBrokerApplicationsWithoutTrigger(updates);

        // ===== SMS ADD =====
        if (!appsForSMS.isEmpty()) {
			
            Map<Id, List<BrokerApplicant__c>> applicantsByApp =
                new Map<Id, List<BrokerApplicant__c>>();

            List<BrokerApplicant__c> applicants =
                BrokerApplicantService.getInstance()
                    .getPartnerAndOwnerApplicantsForSMS(
                        applicationIdsForSMS
                    );
			System.debug('applicants 151 >> '+ applicants);
            for (BrokerApplicant__c ba : applicants) {
                if (!applicantsByApp.containsKey(ba.BrokerApplication__c)) {
                    applicantsByApp.put(
                        ba.BrokerApplication__c,
                        new List<BrokerApplicant__c>()
                    );
                }
                System.debug('applicantsByApp 159 >> '+ applicantsByApp);
                applicantsByApp.get(ba.BrokerApplication__c).add(ba);
                System.debug('applicantsByApp 161 >> '+ applicantsByApp);
            }

            SMSHandler.SMS smsPayload =
                SMSHandler.getAgreementReminderSMS(
                    appsForSMS,
                    applicantsByApp
                );
			System.debug('smsPayload 169 >> '+ smsPayload);
            if (smsPayload != null &&
                smsPayload.messages != null &&
                !smsPayload.messages.isEmpty()) {
				System.debug('enqueueJob 173 >> ');
                System.enqueueJob(new SMSHandler(smsPayload));
            }
        }
        // ===================
    }
    
    public void execute(SchedulableContext sc) {
        // Schedulable entry point, calls the batch
        Database.executeBatch(new SendAgreementReminderBatch(), 200);
    }

    public void finish(Database.BatchableContext bc) {
    }
}