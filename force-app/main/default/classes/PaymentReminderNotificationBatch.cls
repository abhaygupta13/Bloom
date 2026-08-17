/*****************************************************************************************
Class       : PaymentReminderNotificationBatch
Author      : Dhanraj Poojary
Description : Batch to send payment reminder notification of Payment Installments
Test Class  : PaymentReminderNotificationBatchTest
Created Date: 30 DEC 2024 
*****************************************************************************************/

public class PaymentReminderNotificationBatch implements Database.Batchable<sObject>, Schedulable{
    private static final string MTD_OWE_NO_REPLY_BLOOM_SALES_ID { get { return 'BloomNoReplySalesOWEmailId'; } }
    private static final string MTD_INSTALLMENT_FIRST_PAYMENT_REMINDER_NOTIFICATION_EMAIL_TEMPLATE_ID { get { return 'InstallmentFirstPaymentReminderETId'; } }
    private static final string MTD_INSTALLMENT_SECOND_PAYMENT_REMINDER_NOTIFICATION_EMAIL_TEMPLATE_ID { get { return 'InstallmentSecondPaymentReminderETId'; } }
    private static final string MTD_INSTALLMENT_THIRD_PAYMENT_REMINDER_NOTIFICATION_EMAIL_TEMPLATE_ID { get { return 'InstallmentThirdPaymentReminderETId'; } }
    private static final string MTD_PHPP_PAYMENT_REMINDER_NOTIFICATION_EMAIL_TEMPLATE_ID { get { return 'PHPPPaymentReminderETId'; } }
    private static final string MTD_SALES_ORDER_STATUS_VALUE { get { return 'ActiveSalesOrderStatus'; } }
    private static final string INSTALLMENT_VALUE { get { return 'Installment'; } }
    private static final string HANDOVER_VALUE { get { return 'Handover'; } }
    private static final string POST_HANDOVER_VALUE { get { return 'Post Handover Installment'; } }
    private static final string LEGAL_STATUS_VALUE { get { return 'LegalStatusValues'; } }
    private Id recordId;
    
    public PaymentReminderNotificationBatch() {        
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) { 
        MetadataService objMetadataService = MetadataService.getInstance();
        String salesOrderStatusValue = objMetadataService.getAppSettingTextValue(MTD_SALES_ORDER_STATUS_VALUE);
        List<String> salesOrderStatusValueList = salesOrderStatusValue.split(',');
        String legalStatusValue = objMetadataService.getAppSettingTextValue(LEGAL_STATUS_VALUE);
        List<String> legalStatusValueList = legalStatusValue.split(',');
        
        String query = 'SELECT Id, Name, Description__c, SalesOrder__r.Unit__r.Project__r.Name, SalesOrder__r.Unit__r.Name, SalesOrder__r.Account__c, SalesOrder__r.Account__r.Name, SalesOrder__r.Account__r.isPersonAccount, SalesOrder__r.Account__r.PersonContactId, SalesOrder__r.Account__r.PersonContact.Name, SalesOrder__r.Account__r.NameinArabic__c, SalesOrder__r.Contact__c, SalesOrder__r.Contact__r.Name, SalesOrder__r.Status__c, PendingAmount__c, InstallmentDate__c, Due_Date__c, SalesOrder__r.Unit__r.Project__c, SalesOrder__r.Unit__r.Project__r.FirstPaymentReminder__c, SalesOrder__r.Unit__r.Project__r.SecondPaymentReminder__c, ' +
            'SalesOrder__r.Unit__r.Project__r.ThirdPaymentReminder__c, SalesOrder__r.Unit__r.Project__r.ProjectNameArabic__c, InstallmentNumber__c, SalesOrder__r.Unit__r.Project__r.SendPaymentReminder__c, SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__c, SalesOrder__r.Unit__r.BuildingSectionName__r.HandoverAccountInstallment__c, SalesOrder__r.Unit__r.BuildingSectionName__r.PHPPAccountInstallment__c,Type__c,SalesOrder__r.Account__r.PersonContact.Email,SalesOrder__r.Contact__r.Email,SalesOrder__r.Virtual_Bank_Account_Number__c,SalesOrder__r.Virtual_Account_IBAN__c,OutstandingAmount__c ' +
            'FROM InstallmentLines__c WHERE SalesOrder__r.Status__c IN :salesOrderStatusValueList AND SalesOrder__r.Unit__r.Project__r.SendPaymentReminder__c = TRUE ' +
            'AND Due_Date__c != null AND Due_Date__c >= TODAY AND Due_Date__c <= NEXT_N_DAYS:40 AND OutstandingAmount__c > 0 AND InstallmentNumber__c != 1 AND Type__c != \'Down Payment\''+
            'AND SalesOrder__r.Account__r.Legal_Status__c NOT IN : legalStatusValueList AND SalesOrder__r.LegalStatus__c NOT IN : legalStatusValueList AND SalesOrder__r.Unit__r.DoNotSendPaymentReminder__c = FALSE';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<InstallmentLines__c> scope) {
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        BankAccountService objBankAccountService = BankAccountService.getInstance();
        
        // Retrieve email template IDs and settings
        Id bloomNoReplySalesOWEId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_BLOOM_SALES_ID);
        Id installmentFirstPaymentReminderETId = objMetadataService.getAppSettingTextValue(MTD_INSTALLMENT_FIRST_PAYMENT_REMINDER_NOTIFICATION_EMAIL_TEMPLATE_ID);
        Id installmentSecondPaymentReminderETId = objMetadataService.getAppSettingTextValue(MTD_INSTALLMENT_SECOND_PAYMENT_REMINDER_NOTIFICATION_EMAIL_TEMPLATE_ID);
        Id installmentThirdPaymentReminderETId = objMetadataService.getAppSettingTextValue(MTD_INSTALLMENT_THIRD_PAYMENT_REMINDER_NOTIFICATION_EMAIL_TEMPLATE_ID);
        Id phppPaymentReminderETId = objMetadataService.getAppSettingTextValue(MTD_PHPP_PAYMENT_REMINDER_NOTIFICATION_EMAIL_TEMPLATE_ID);
        
        List<Messaging.SingleEmailMessage> msgList = new List<Messaging.SingleEmailMessage>();
        List<Id> projectIdList = new List<Id>();
        Map<Id, BankAccount__c> bankMap = new Map<Id, BankAccount__c>();
        Set<Id> setBankAccountIds = new Set<Id>();
        Date currentDate = Date.today();
        
        EmailTemplate firstReminderTemplate = objEmailService.getEmailTemplateById(installmentFirstPaymentReminderETId);
        EmailTemplate secondReminderTemplate = objEmailService.getEmailTemplateById(installmentSecondPaymentReminderETId);
        EmailTemplate thirdReminderTemplate = objEmailService.getEmailTemplateById(installmentThirdPaymentReminderETId);
        EmailTemplate phppReminderTemplate = objEmailService.getEmailTemplateById(phppPaymentReminderETId);
        
        for (InstallmentLines__c pi : scope) {
            if (pi.SalesOrder__r.Unit__r.Project__c != null) {
                projectIdList.add(pi.SalesOrder__r.Unit__r.Project__c);
            }
            if(pi.SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__c != null){
                setBankAccountIds.add(pi.SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__c);
            }
            if(pi.SalesOrder__r.Unit__r.BuildingSectionName__r.HandoverAccountInstallment__c != null){
                setBankAccountIds.add(pi.SalesOrder__r.Unit__r.BuildingSectionName__r.HandoverAccountInstallment__c);
            }
            if(pi.SalesOrder__r.Unit__r.BuildingSectionName__r.PHPPAccountInstallment__c != null){
                setBankAccountIds.add(pi.SalesOrder__r.Unit__r.BuildingSectionName__r.PHPPAccountInstallment__c);
            }
        }
        
        if(!setBankAccountIds.isEmpty()){
            bankMap = new Map<Id, BankAccount__c>(objBankAccountService.getBankAccountByIds(setBankAccountIds));
        }
        
        for (InstallmentLines__c pi : scope) {
            if (pi.Due_Date__c == null || pi.SalesOrder__r.Unit__r.Project__r == null) {
                continue;
            }
            
            Date dueDate = pi.Due_Date__c;
            Date firstReminderDate;
            Date secondReminderDate;
            Date thirdReminderDate;
            
            Integer firstDays = pi.SalesOrder__r.Unit__r.Project__r.FirstPaymentReminder__c != null ? Integer.valueOf(pi.SalesOrder__r.Unit__r.Project__r.FirstPaymentReminder__c) : null;      
            Integer secondDays = pi.SalesOrder__r.Unit__r.Project__r.SecondPaymentReminder__c != null ? Integer.valueOf(pi.SalesOrder__r.Unit__r.Project__r.SecondPaymentReminder__c) : null;
            Integer thirdDays = pi.SalesOrder__r.Unit__r.Project__r.ThirdPaymentReminder__c != null ? Integer.valueOf(pi.SalesOrder__r.Unit__r.Project__r.ThirdPaymentReminder__c) : null;
            
            if (firstDays != null) firstReminderDate = dueDate.addDays(-firstDays);
            if (secondDays != null) secondReminderDate = dueDate.addDays(-secondDays);
            if (thirdDays != null) thirdReminderDate = dueDate.addDays(-thirdDays);
            
            EmailTemplate selectedTemplate;
            String reminderLabel;
            
            if (firstReminderDate != null && currentDate == firstReminderDate) {
                selectedTemplate = (pi.Type__c == POST_HANDOVER_VALUE) ? phppReminderTemplate : firstReminderTemplate; 
                reminderLabel = 'First';
            } else if (secondReminderDate != null && currentDate == secondReminderDate) {
                selectedTemplate = (pi.Type__c == POST_HANDOVER_VALUE) ? phppReminderTemplate : secondReminderTemplate;
                reminderLabel = 'Second';
            } else if (thirdReminderDate != null && currentDate == thirdReminderDate) {
                selectedTemplate = (pi.Type__c == POST_HANDOVER_VALUE) ? phppReminderTemplate : thirdReminderTemplate;
                reminderLabel = 'Third';
            }
            
            if (selectedTemplate != null) {
                Messaging.SingleEmailMessage emailMsg = getEmailContent(pi,objEmailService,selectedTemplate,bankMap,bloomNoReplySalesOWEId,reminderLabel);
                
                if (emailMsg != null) {
                    msgList.add(emailMsg);
                }
            }
        }
        
        if (!msgList.isEmpty()) {
            objEmailService.sendEmail(msgList);
        }
    }
    
    public Messaging.SingleEmailMessage getEmailContent(InstallmentLines__c pi,EmailService objEmailService,EmailTemplate emailTemplate,Map<Id, BankAccount__c> bankMap,Id bloomNoReplySalesOWEId,String reminderLabel) {
        if (pi == null || pi.Due_Date__c == null) return null;
        
        Contact emailRecipient = pi.SalesOrder__r.Account__r.isPersonAccount? pi.SalesOrder__r.Account__r.PersonContact: pi.SalesOrder__r.Contact__r;
        if (emailRecipient == null || String.isBlank(emailRecipient.Email)) {
            return null;
        }
        Id contactId = pi.SalesOrder__r.Account__r.isPersonAccount? pi.SalesOrder__r.Account__r.PersonContactId: pi.SalesOrder__r.Contact__c;
        Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(emailTemplate.Id,contactId,pi.Id);
        String body = mail.getHtmlBody();
        String subject = mail.getSubject();
        Datetime dt = Datetime.newInstance(pi.Due_Date__c.year(),pi.Due_Date__c.month(),pi.Due_Date__c.day());
        String formattedDate = dt.format('dd-MM-yyyy');
        
        body = body.replace('[Customer_Name]', pi.SalesOrder__r.Account__r.Name != null ? pi.SalesOrder__r.Account__r.Name : '')
            .replace('[Customer_NameArabic]', pi.SalesOrder__r.Account__r.NameinArabic__c != null ? pi.SalesOrder__r.Account__r.NameinArabic__c : '')
            .replace('[Project_Name]', pi.SalesOrder__r.Unit__r.Project__r.Name != null ? pi.SalesOrder__r.Unit__r.Project__r.Name : '')
            .replace('[Project_Name_Arabic]', pi.SalesOrder__r.Unit__r.Project__r.ProjectNameArabic__c != null ? pi.SalesOrder__r.Unit__r.Project__r.ProjectNameArabic__c : '')
            .replace('[Unit_Name]', pi.SalesOrder__r.Unit__r.Name != null ? pi.SalesOrder__r.Unit__r.Name : '')
            .replace('[Pending_Amount]', pi.OutstandingAmount__c != null ? String.valueOf(pi.OutstandingAmount__c) : '')
            .replace('[Installment_Date]', formattedDate != null ? formattedDate : '');
        
        Id bankId;
        if (pi.Type__c == HANDOVER_VALUE) {
            bankId = pi.SalesOrder__r.Unit__r.BuildingSectionName__r.HandoverAccountInstallment__c;
        } else if (pi.Type__c == POST_HANDOVER_VALUE) {
            bankId = pi.SalesOrder__r.Unit__r.BuildingSectionName__r.PHPPAccountInstallment__c;
        } else {
            bankId = pi.SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__c;
        }
        
        BankAccount__c selectedBank = (bankId != null ? bankMap.get(bankId) : null);
        if (selectedBank != null) {
            body = body.replace('[BankName]', selectedBank.BankNameCorporate__c)
                .replace('[BankAccountName]', selectedBank.BeneficiaryNameCorporate__c)
                .replace('[BankSwiftCode]', selectedBank.SwiftCodeCorporate__c);
            if(pi.Type__c == 'Installment'){
                body = body.replace('[BankAccountNumber]', pi.SalesOrder__r.Virtual_Bank_Account_Number__c != null ? pi.SalesOrder__r.Virtual_Bank_Account_Number__c : selectedBank.AccountNumberCorporate__c)
                .replace('[BankAccountIBAN]', pi.SalesOrder__r.Virtual_Account_IBAN__c != null ? pi.SalesOrder__r.Virtual_Account_IBAN__c : selectedBank.IBANNoCorporate__c);
            }
            else if(pi.Type__c != 'Installment'){
                body = body.replace('[BankAccountNumber]', selectedBank.AccountNumberCorporate__c)
                .replace('[BankAccountIBAN]', selectedBank.IBANNoCorporate__c);
            }
        }
        mail.setHtmlBody(body);
        if (pi.Type__c == POST_HANDOVER_VALUE) {
            subject = getDynamicSubject(pi, reminderLabel);
        } else {
            subject = subject
                .replace('[Project_Name]', pi.SalesOrder__r.Unit__r.Project__r.Name != null ? pi.SalesOrder__r.Unit__r.Project__r.Name : '')
                .replace('[Unit_Name]', pi.SalesOrder__r.Unit__r.Name != null ? pi.SalesOrder__r.Unit__r.Name : '')
                .replace('[Project_Name_Arabic]', pi.SalesOrder__r.Unit__r.Project__r.ProjectNameArabic__c != null ? pi.SalesOrder__r.Unit__r.Project__r.ProjectNameArabic__c : '');
        }
        mail.setSubject(subject);
        mail.setOrgWideEmailAddressId(bloomNoReplySalesOWEId);
        
        return mail;
    }
    
    public void finish(Database.BatchableContext bc){
    }
    
    // Scheduling the batch
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new PaymentReminderNotificationBatch(), 100);
    }
    
    public String getDynamicSubject(InstallmentLines__c pi, String reminderLabel) {
        if (pi.Due_Date__c == null) return '';
        
        Datetime dt = Datetime.newInstance(pi.Due_Date__c.year(), pi.Due_Date__c.month(), pi.Due_Date__c.day());
        String monthName = dt.format('MMMM');
        String year = dt.format('yyyy');
        String projectName = pi.SalesOrder__r.Unit__r.Project__r.Name != null ? pi.SalesOrder__r.Unit__r.Project__r.Name : '';
        
        return projectName + ' | ' + reminderLabel + ' Payment Reminder | ' + monthName + ' ' + year + ' Installment';
    }
}