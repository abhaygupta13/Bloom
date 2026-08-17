/*****************************************************************************************
Class       : PaymentReminderWeeklyNotificationBatch
Author      : Dhanraj Poojary
Description : Batch to send details of upcoming Payment Installments Weekly
Test Class  : PaymentReminderWeeklyNotifyBatchTest
Created Date: 20 APRIL 2025 
*****************************************************************************************/

public class PaymentReminderWeeklyNotificationBatch implements Database.Batchable<sObject>, Schedulable{
    private static final string MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final string MTD_INSTALLMENT_WEEKLY_PAYMENT_REMINDER_NOTIFICATION_EMAIL_TEMPLATE_ID { get { return 'InstallmentWeeklyReminderETId'; } }
    private static final string MTD_SALES_ORDER_STATUS_VALUE { get { return 'SalesOrderStatusforPendingPayment'; } }
    private static final string MTD_INSTALLMENT_WEEKLY_REMINDER_EMAIL_ADDRESS_VALUE { get { return 'InstallmentWeeklyReminderEmailAddress'; } }
    private static final string MTD_INSTALLMENT_WEEKLY_REMINDER_DAYS { get { return 'InstallmentWeeklyReminderDays'; } }
    
    public Database.QueryLocator start(Database.BatchableContext bc) { 
        String query = 'SELECT Id,Name,SendWeeklyPaymentReminder__c FROM Project__c WHERE SendWeeklyPaymentReminder__c = TRUE';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Project__c> scope){
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        
        Id bloomNoReplySalesOWEId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
        Id installmentWeeklyReminderETId = objMetadataService.getAppSettingTextValue(MTD_INSTALLMENT_WEEKLY_PAYMENT_REMINDER_NOTIFICATION_EMAIL_TEMPLATE_ID);
        EmailTemplate weeklyReminderET = objEmailService.getEmailTemplateById(installmentWeeklyReminderETId);
        String emailBody = weeklyReminderET.HtmlValue;
        String emailSubject = weeklyReminderET.Subject;
        List<Id> projectIdList = new List<Id>();
        List<String> toAddress = new List<String>();
        Set<Date> targetDueDates = new Set<Date>();
        Map<Date,Date> mapTargetDates = new Map<Date,Date>();
        List<Integer> reminderDaysList = new List<Integer>();
        Map<Date, List<InstallmentLines__c>> mapInstallments = new Map<Date, List<InstallmentLines__c>>();
        Map<Integer, String> reminderLabelMap = new Map<Integer, String>();
        List<String> reminderValueList = new List<String>{'First', 'Second', 'Third', 'Fourth', 'Fifth'};
        String recepientEmailAddress = objMetadataService.getAppSettingTextValue(MTD_INSTALLMENT_WEEKLY_REMINDER_EMAIL_ADDRESS_VALUE);
        if(recepientEmailAddress != null) toAddress.addAll(recepientEmailAddress.split(','));
        
        String salesOrderStatusValue = objMetadataService.getAppSettingTextValue(MTD_SALES_ORDER_STATUS_VALUE);
        List<String> salesOrderStatusValueList = salesOrderStatusValue.split(',');
        String weeklyReminderDays = objMetadataService.getAppSettingTextValue(MTD_INSTALLMENT_WEEKLY_REMINDER_DAYS);
        List<String> weeklyReminderDaysList = weeklyReminderDays.split(',');
        
        for(String reminderDays : weeklyReminderDaysList){
            Date installmentDate = System.today().addDays(Integer.valueOf(reminderDays));
            targetDueDates.add(installmentDate);
            reminderDaysList.add(Integer.valueOf(reminderDays.trim()));
        }
        reminderDaysList.sort();
        
        for (Integer i = 0; i < reminderDaysList.size(); i++) {
            String label = (i < reminderValueList.size()) ? reminderValueList[i] + ' Reminder' : 'Reminder ';
            reminderLabelMap.put(reminderDaysList[i], label);
        }
         
        for(Project__c objProject : scope){  
            projectIdList.add(objProject.Id);
        }
        List<InstallmentLines__c> installmentList = [SELECT Id, Name, Description__c, SalesOrder__r.Unit__r.Project__r.Name, SalesOrder__r.Unit__r.Name, SalesOrder__r.Account__c, SalesOrder__r.Account__r.Name, SalesOrder__r.Account__r.isPersonAccount, SalesOrder__r.Account__r.PersonContactId, SalesOrder__r.Account__r.PersonContact.Name, SalesOrder__r.Account__r.NameinArabic__c, SalesOrder__r.Contact__c, SalesOrder__r.Contact__r.Name, SalesOrder__r.Status__c, PendingAmount__c, format(PendingAmount__c) pendingamount, InstallmentDate__c, Due_Date__c, SalesOrder__r.Unit__r.Project__c, SalesOrder__r.Unit__r.Project__r.ProjectNameArabic__c, InstallmentNumber__c, SalesOrder__r.Unit__r.Project__r.SendWeeklyPaymentReminder__c,Type__c FROM InstallmentLines__c WHERE SalesOrder__r.Unit__r.Project__c IN: projectIdList AND SalesOrder__r.Status__c NOT IN :salesOrderStatusValueList AND Due_Date__c != null AND Due_Date__c IN :targetDueDates];
        if(!installmentList.isEmpty()){
            for (InstallmentLines__c objIL : installmentList) {
                if (!mapInstallments.containsKey(objIL.Due_Date__c)) {
                    mapInstallments.put(objIL.Due_Date__c, new List<InstallmentLines__c>());
                }
                mapInstallments.get(objIL.Due_Date__c).add(objIL);
            }
            
            for (Date daysIL : mapInstallments.keySet()) {
                String installmentTable = objEmailService.customUnitILTableHeader(false);
                Integer daysUntilDue = Date.today().daysBetween(daysIL);
                emailSubject = reminderLabelMap.containsKey(daysUntilDue) ? reminderLabelMap.get(daysUntilDue)+' '+daysUntilDue+' Days before' : 'Reminder'+ daysUntilDue +'Days before';
                emailBody = weeklyReminderET.HtmlValue;
                List<InstallmentLines__c> filteredList = mapInstallments.get(daysIL);
                for(InstallmentLines__c pi : filteredList){  
                    installmentTable += objEmailService.makeTable(pi,false);
                }
                
                installmentTable += '</table>';
                String csv = objEmailService.generateCSV(filteredList,false);
                Blob csvBlob = Blob.valueOf(csv);
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName('PaymentDueInstallments'+daysUntilDue+'DaysBefore.csv');
                attachment.setBody(csvBlob);
                attachment.setContentType('text/csv');
                emailBody = emailBody.replace('{{INSTALLMENT_TABLE}}', installmentTable);
                Messaging.SingleEmailMessage email = objEmailService.getSingleEmailMessage(toAddress, emailSubject, emailBody, bloomNoReplySalesOWEId); 
                email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment});
                Messaging.SendEmailResult[] results = objEmailService.sendEmail(new List<Messaging.SingleEmailMessage>{email});        
                installmentTable = '';
            }
        }
    }
    
    public void finish(Database.BatchableContext bc){
    }
    
    // Scheduling the batch
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new PaymentReminderWeeklyNotificationBatch(), 100);
    }
}