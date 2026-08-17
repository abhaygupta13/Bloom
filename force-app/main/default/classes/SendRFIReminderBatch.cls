/*
* @Author      : Akshay Khairnar
* @Description : Batch class to send the RFI Reminder Notifications to Agency - 2 weeks and 30 days after the BBM team has raised RFI
* Test Apex: SendRFIReminderBatchTest           
***********************************************************************************************************************************/

public class SendRFIReminderBatch implements Database.Batchable<SObject>,Schedulable, Database.Stateful {

    private static final string MTD_BAPP_BROKER_NO_REPLY_EMAIL_ID { get { return 'BAPPOrgWideEmailAddress'; } }
    
    private static final Integer EMAIL_DAY_0  = 0;
    private static final Integer EMAIL_DAY_15 = 15;
    private static final Integer EMAIL_DAY_30 = 30;
    MetadataService objMetadataService = MetadataService.getInstance();
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        
        //  Select all active RFIs for daily SMS
        String query = 'SELECT Id, CreatedDate, BrokerApplication__r.Name, RFIComments__c, RFI_Remaining_Days__c, ' +
                       'BrokerApplication__r.ApplicationNumber__c, BrokerApplication__r.AgencyEmail__c, ' +
                       'BrokerApplication__r.CompanyPhone_Number__c, BrokerApplication__r.CountryCode__c ' +
                       'FROM RFI__c ' +
                       'WHERE BrokerApplication__r.ApprovalStatus__c = \'RFI\' ' + 
                       'AND BrokerApplication__r.IsRFIUpdated__c = false ' + 
                       'AND BrokerApplication__r.AgencyEmail__c != null';
		System.debug('query 26 >> ' +query);
        System.debug('Database.getQueryLocator 27 >> ' +Database.getQueryLocator(query));
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<RFI__c> scope) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        List<RFI__c> updateRFIs = new List<RFI__c>();
        Date today = Date.today();
        BrokerApplicationService baService = BrokerApplicationService.getInstance();
		
        // Query Org-Wide Email Address
        Id orgWideEmailId = MetadataService.getInstance().getAppSettingTextValue(MTD_BAPP_BROKER_NO_REPLY_EMAIL_ID);
        // Track latest RFI date by BrokerApplication
		Map<Id, Date> latestRfiByApp = new Map<Id, Date>();
        // Get the HTML email template body
        EmailTemplate template = EmailService.getInstance().getEmailTemplateByDevName('Broker_Application_RFI_Reminder');
		// Track latest RFI per application for SMS
        Map<Id, RFI__c> latestRfiForSMS = new Map<Id, RFI__c>();
        Set<Id> applicationIdsForSMS = new Set<Id>();

        // Track latest RFI for cancelling applications
        for (RFI__c rfi : scope) {
            Date createdDate = rfi.CreatedDate.date();
            Integer daysPassed = createdDate.daysBetween(today);
            Boolean send = false;

            // Store latest RFI date per application
            if (rfi.BrokerApplication__c != null) {
                System.debug('Inside If Rfi 55 >> ');
                if (!latestRfiByApp.containsKey(rfi.BrokerApplication__c) || latestRfiByApp.get(rfi.BrokerApplication__c) == createdDate) {
                    System.debug('Inside If latestRfiByApp 57 >> ');
                    latestRfiByApp.put(rfi.BrokerApplication__c, createdDate);
                    System.debug('latestRfiByApp 59 >> '+latestRfiByApp);
                }
            }

            // Calculate remaining days
            Integer remaining = 30 - daysPassed;
            updateRFIs.add(new RFI__c(Id = rfi.Id, RFI_Remaining_Days__c = String.valueOf(remaining)));

            if (daysPassed == EMAIL_DAY_0  || daysPassed == EMAIL_DAY_15  || daysPassed == EMAIL_DAY_30) {
                send = true;
            }
            // Track latest RFI per application for SMS
            if (rfi.BrokerApplication__r != null &&
                String.isNotBlank(rfi.BrokerApplication__r.CompanyPhone_Number__c) &&
                String.isNotBlank(rfi.BrokerApplication__r.CountryCode__c)) {
				System.debug('inside track rfi 73 >> '+ rfi);
                if (!latestRfiForSMS.containsKey(rfi.BrokerApplication__c) ||
                    latestRfiForSMS.get(rfi.BrokerApplication__c).CreatedDate < rfi.CreatedDate) {
                    System.debug('Inside if latestRfiForSMS 76 >> ');

                    latestRfiForSMS.put(rfi.BrokerApplication__c, rfi);
                    System.debug('latestRfiForSMS 79 >> ' + latestRfiForSMS);
                    applicationIdsForSMS.add(rfi.BrokerApplication__c);
                    System.debug('applicationIdsForSMS 81 >> ' + applicationIdsForSMS);
                }
            }

            if (send) {
                BrokerApplication__c app = rfi.BrokerApplication__r;
                
                String subjectrfi = Label.BAPPBrokerAgencyRFIReminderSubject + app.ApplicationNumber__c;
                // Prepare dynamic HTML by replacing merge fields
                String htmlBody = template.HtmlValue;

                htmlBody = htmlBody
                    .replace('{!BrokerApplication__c.Name}', app.Name != null ? app.Name : '')
                    .replace('{!BrokerApplication__c.ApplicationNumber__c}', app.ApplicationNumber__c != null ? app.ApplicationNumber__c : '')
                    .replace('{!RFI__c.RFI_Remaining_Days__c}', remaining != null ? String.valueOf(remaining) : '')
                    .replace('{!RFI__c.RFIComments__c}', rfi.RFIComments__c != null ? rfi.RFIComments__c : '')
                    .replace('{Application Record Link}', Label.BAPP_BloomConnectLoginPageLink)
                    .replace('{{RFI_Date}}', String.valueOf(createdDate)); // Replace manually since it's not a standard merge

                Messaging.SingleEmailMessage email = EmailService.getInstance().getSingleEmailMessage(new String[] { app.AgencyEmail__c }, null, subjectrfi, htmlBody, orgWideEmailId);
				emails.add(email);
            }
        }
        //This functionality has been commented out as per the confirmation received from the business team on 26 Jan 2026. 
        //The auto-cancellation logic related to RFI needs to be stopped, meaning the broker application should not be automatically cancelled.
        //Set ApprovalStatus = 'Cancelled' if last RFI is older than 30 days and IsRFIUpdated = false
        /*if (!latestRfiByApp.isEmpty()) {
            
            BrokerApplicationService appService = BrokerApplicationService.getInstance();
            List<BrokerApplication__c> appsToUpdate = appService.getApplicationByIds(latestRfiByApp.keySet());
            

            List<BrokerApplication__c> brokerApplicationsToCancel = new List<BrokerApplication__c>();

            for (BrokerApplication__c app : appsToUpdate) {
                Date lastRfiDate = latestRfiByApp.get(app.Id);
                if (lastRfiDate != null && !app.IsRFIUpdated__c && lastRfiDate.daysBetween(Date.today()) >= 30) {
                    app.ApprovalStatus__c = 'Cancelled';
                    app.IsRFIUpdated__c = false;
                    brokerApplicationsToCancel.add(app);
                }
            }

            //Update Broker Applications
            baService.updateBrokerApplicationsWithoutTrigger(brokerApplicationsToCancel);
        }*/
		//Send Email
        EmailService.getInstance().sendEmail(emails);
        
        //Update RFI records
        RFIService.getInstance().updateRFIRecords(updateRFIs);
    
    	//  SMS: Partner / Owner via Service
        Map<Id, List<BrokerApplicant__c>> applicantsByApp = new Map<Id, List<BrokerApplicant__c>>();
        if (!applicationIdsForSMS.isEmpty()) {
            List<BrokerApplicant__c> applicants =
                BrokerApplicantService.getInstance().getPartnerAndOwnerApplicantsForSMS(applicationIdsForSMS);
            System.debug('applicants 138 >> ' + applicants);
            for (BrokerApplicant__c ba : applicants) {
                if (!applicantsByApp.containsKey(ba.BrokerApplication__c)) {
                    applicantsByApp.put(ba.BrokerApplication__c, new List<BrokerApplicant__c>());
                    System.debug('applicantsByApp 142 >> ' + applicantsByApp);
                }
                applicantsByApp.get(ba.BrokerApplication__c).add(ba);
                System.debug('applicantsByApp 145 >> ' + applicantsByApp);
            }
        }

        // Send SMS
        if (!latestRfiForSMS.isEmpty()) {
            SMSHandler.SMS smsPayload = SMSHandler.getRFIReminderSMS(latestRfiForSMS.values(), applicantsByApp);
            System.debug('smsPayload 152 >> ' + smsPayload);
            if (smsPayload != null && smsPayload.messages != null && !smsPayload.messages.isEmpty()) {
                System.debug('Inside if smsPayload 154 >> ' + smsPayload);
                System.enqueueJob(new SMSHandler(smsPayload));
            }
        }
    }
    
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new SendRFIReminderBatch(), 200);
    }

    public void finish(Database.BatchableContext bc) {
    }
}