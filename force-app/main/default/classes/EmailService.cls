/*
* @Author : Biswajeet Samal
* @CreatedDate : 7th AUG 2024
* @Description : EmailService
Test Apex: EmailServiceTest
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           Biswajeet   07AUG2024        Initial draft 
* 1.1           Dhanraj     28JAN2025        New methods for Quaterly Payment Notification
* 1.2           Dhanraj     13FEB2025        New method for Handover Notice Notification to include CC and BCC Address
*****************************************************************************************************/
public inherited sharing class EmailService {
    
    private static final String BASE_URL = URL.getOrgDomainUrl().toExternalForm(); 
    
    private static EmailService instance;
    
    private EmailService() {
        
    }
    
    public static EmailService getInstance() {
        if(instance == null) {
            instance = new EmailService();
        }
        return instance;
    }
       public Messaging.SingleEmailMessage getSingleEmailMessage(List<String> emailAddresses,Id whatId, Id targetObjectId, String subject, String body) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        if(emailAddresses != NULL && !emailAddresses.isEmpty() ){ mail.setToAddresses(emailAddresses); }
        if(String.isNotBlank(whatId)){  mail.setWhatID(whatId); }
        if(String.isNotBlank(targetObjectId)){ mail.setTargetObjectId(targetObjectId); }
        mail.setSubject(subject);
        mail.setHtmlBody(body);
        return mail;
    }

    public void sendMailWithActivityHtmlBody(List<String> emailAddresses, String subject, String body, Id whatId, Id whoId, Id orgWideEmailAddressId) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(emailAddresses);
        mail.setSubject(subject);
        mail.setHtmlBody(body);
        mail.setWhatId(whatId);
        mail.setSaveAsActivity(true);
        mail.setOrgWideEmailAddressId(orgWideEmailAddressId);
        sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
    public void sendMailWithHtmlBody(List<String> emailAddresses, String subject, String body, Id whatId, Id whoId, Id orgWideEmailAddressId) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(emailAddresses);
        mail.setSubject(subject);
        mail.setHtmlBody(body);
        mail.setOrgWideEmailAddressId(orgWideEmailAddressId);
        sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    public List<String> getOwnerEmails(Id ownerId) {
        List<String> ownerEmails = new List<String>();
        
        // Check if the OwnerId is a User
        if (ownerId.getSObjectType() == User.sObjectType) {
            // Query for the User's email
            User ownerUser = [SELECT Email FROM User WHERE Id = :ownerId LIMIT 1];
            ownerEmails.add(ownerUser.Email);
        }
        // Check if the OwnerId is a Group (Queue)
        else if (ownerId.getSObjectType() == Group.sObjectType) {
            // Query the Group's members and get the email of each member
            List<GroupMember> groupMembers = [SELECT UserOrGroupId,UserOrGroup.Email FROM GroupMember where GroupId = :ownerId];
            
            // Add the email of each user member of the Queue
            for (GroupMember member : groupMembers) {
                if (member.UserOrGroupId != null && member.UserOrGroupId.getSObjectType() == User.sObjectType) {
                    ownerEmails.add(member.UserOrGroup.Email);
                }
            }
        }
        
        system.debug('ownerEmails'+ownerEmails);
        return ownerEmails;
    }
    
    public void sendMailWithHtmlBody(List<String> emailAddresses, String subject, String body, Id orgWideEmailAddressId) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(emailAddresses);
        mail.setSubject(subject);
        mail.setHtmlBody(body);
        mail.setOrgWideEmailAddressId(orgWideEmailAddressId);
        sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
    public Messaging.SingleEmailMessage getSingleEmailMessage(List<String> emailAddresses, String subject, String body, Id orgWideEmailAddressId) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        if(emailAddresses != NULL && !emailAddresses.isEmpty() ){ mail.setToAddresses(emailAddresses); }
        if(String.isNotBlank(orgWideEmailAddressId)){  mail.setOrgWideEmailAddressId(orgWideEmailAddressId); }
        if(String.isNotBlank(orgWideEmailAddressId)){  mail.setOrgWideEmailAddressId(orgWideEmailAddressId); }
        if(String.isNotBlank(subject)){  mail.setSubject(subject); }
        if(String.isNotBlank(body)){  mail.setHtmlBody(body); }
        return mail;
    }
    
    public Messaging.SingleEmailMessage getSingleEmailMessage(List<String> emailAddresses, Id whatId, String subject, String body, Id orgWideEmailAddressId) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(emailAddresses);
        mail.setSubject(subject);
        mail.setHtmlBody(body);
        if(String.isNotBlank(whatId)){  mail.setWhatID(whatId); }
        mail.setOrgWideEmailAddressId(orgWideEmailAddressId);
        return mail;
    }

    public Messaging.SingleEmailMessage getSingleEmailMessage(List<String> emailAddresses, String subject, String body) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(emailAddresses);
        mail.setSubject(subject);
        mail.setHtmlBody(body);
        return mail;
    }
    
    public Messaging.SingleEmailMessage getSingleEmailMessage(List<String> emailAddresses,Id whatId, Id targetObjectId, String subject, String body, Id orgWideEmailAddressId) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        if(emailAddresses != NULL && !emailAddresses.isEmpty() ){ mail.setToAddresses(emailAddresses); }
        if(String.isNotBlank(whatId)){  mail.setWhatID(whatId); }
        if(String.isNotBlank(targetObjectId)){ mail.setTargetObjectId(targetObjectId); }
        if(String.isNotBlank(orgWideEmailAddressId)){  mail.setOrgWideEmailAddressId(orgWideEmailAddressId); }
        mail.setSubject(subject);
        mail.setHtmlBody(body);
        return mail;
    }
    public String buildInstallmentPostponementEmailBody(Case caseRec, List<CaseInstallment__c> installments,List<BankAccount__c> bankAccounts) {
        String emailBody = '<html><body>';
        emailBody += '<p style="padding-left: 12px;">Dear <strong>' + 'valued customer' + '</strong>,</p>';
        emailBody += '<p style="padding-left: 12px;">Greetings from <strong>Bloom Properties</strong>!</p>';
        emailBody += '<p style="padding-left: 12px;">Please be informed that your request to postpone the following installments has been approved:</p>';
        
        Integer counter = 1;
        for (CaseInstallment__c installment : installments) {
            emailBody +='<p style="padding-left: 12px;">'+ counter + '] ' + installment.Name + ', amount AED ' +installment.InstallmentAmount__c+ ' to be on ' + installment.NewInstallmentDate__c.format() + '</p><br/>';
            counter++;
        }
        emailBody += '<p style="padding-left: 12px;">In order to continue the request, please be advised that you will need to pay the deferral fee of <strong>AED 500</strong> through transferring it using the below bank details.</p>';
        emailBody += '<p style="padding-left: 12px;">Once we receive the fee, you will receive an appointment link to visit our office and replace the requested cheques.</p>';
        if(!bankAccounts.isEmpty()){
            emailBody += '<p style="padding-left: 12px;"><strong>Bank Details:</strong></p>';
            emailBody += '<p style="padding-left: 12px;"><strong>Bank Account Name:</strong> ' + bankAccounts[0].Name + '</p>';
            emailBody += '<p style="padding-left: 12px;"><strong>Account Number:</strong> ' + bankAccounts[0].AccountNumberCorporate__c + '</p>';
            emailBody += '<p style="padding-left: 12px;"><strong>Beneficiary Name:</strong> ' + bankAccounts[0].BeneficiaryNameCorporate__c + '</p>';
            emailBody += '<p style="padding-left: 12px;"><strong>Bank Name:</strong> ' + bankAccounts[0].BankNameCorporate__c + '</p>';
        }
        emailBody += '<p style="padding-left: 12px;">For any inquiries, please do not hesitate to email us through customerservice@bloomholding.com or call us through 800-Bloom (25666).</p>';
        emailBody += '<p style="padding-left: 12px;">Thanks,</p>';
        emailBody += '<p style="padding-left: 12px;"><strong>Bloom Customer Service</strong></p>';
        emailBody += '</body></html>';
        
        return emailBody;
    }
    
    
    public Messaging.SingleEmailMessage getSingleEmailMessage(List<String> emailAddresses,Id whatId, Id targetObjectId, String subject, String body, Id orgWideEmailAddressId, List<String> ccEmailAddresses, List<String> bccEmailAddresses) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        if(emailAddresses != NULL && !emailAddresses.isEmpty() ){ mail.setToAddresses(emailAddresses); }
        if(String.isNotBlank(whatId)){  mail.setWhatID(whatId); }
        if(String.isNotBlank(targetObjectId)){ mail.setTargetObjectId(targetObjectId); }
        if(String.isNotBlank(orgWideEmailAddressId)){  mail.setOrgWideEmailAddressId(orgWideEmailAddressId); }
        if(ccEmailAddresses != NULL && !ccEmailAddresses.isEmpty() ){ mail.setCCAddresses(ccEmailAddresses); }
        if(bccEmailAddresses != NULL && !bccEmailAddresses.isEmpty() ){ mail.setBCCAddresses(bccEmailAddresses); }
        mail.setSubject(subject);
        mail.setHtmlBody(body);
        return mail;
    }
    
    public Messaging.SingleEmailMessage getSingleEmailMessageWithoutTargetObjectAsRecipient(List<String> emailAddresses, Id emailTemplateId, Id whatId, Id targetObjectId, Id orgWideEmailAddressId) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        if(String.isNotBlank(emailTemplateId)){   mail.setTemplateId(emailTemplateId); }
        if(String.isNotBlank(targetObjectId)){  mail.setTargetObjectId(targetObjectId); }
        if(String.isNotBlank(orgWideEmailAddressId)){  mail.setOrgWideEmailAddressId(orgWideEmailAddressId); }
        if(String.isNotBlank(whatId)){  mail.setWhatID(whatId); }
        if(emailAddresses != NULL && !emailAddresses.isEmpty() ){ mail.setToAddresses(emailAddresses);  }
        mail.setSaveAsActivity(false);
        mail.setTreatTargetObjectAsRecipient(false);
        return mail;
    }
    public Messaging.SingleEmailMessage getSingleEmailMessageWithTargetObjectAsRecipient(Id emailTemplateId, Id orgWideEmailAddressId, Id whatId, Id targetObjectId, List<String> toEmailAddresses, List<String> ccEmailAddresses, List<String> bccEmailAddresses) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        if(String.isNotBlank(emailTemplateId)){ mail.setTemplateId(emailTemplateId); }
        if(String.isNotBlank(orgWideEmailAddressId)){  mail.setOrgWideEmailAddressId(orgWideEmailAddressId); }
        if(String.isNotBlank(whatId)){  mail.setWhatID(whatId); }
        if(String.isNotBlank(targetObjectId)){ mail.setTargetObjectId(targetObjectId); }
        if(toEmailAddresses != NULL && !toEmailAddresses.isEmpty() ){ mail.setToAddresses(toEmailAddresses); }
        if(ccEmailAddresses != NULL && !ccEmailAddresses.isEmpty() ){ mail.setCCAddresses(ccEmailAddresses); }
        if(bccEmailAddresses != NULL && !bccEmailAddresses.isEmpty() ){ mail.setBCCAddresses(bccEmailAddresses); }
        mail.setSaveAsActivity(true);
        mail.setTreatTargetObjectAsRecipient(true);
        return mail;
    }
    
    public Messaging.SingleEmailMessage getSingleEmailMessageWithoutTargetObjectId(Id emailTemplateId, Id orgWideEmailAddressId, Id whatId, List<String> toEmailAddresses, List<String> ccEmailAddresses, List<String> bccEmailAddresses) {
        Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(emailTemplateId, null, whatId);
        if(String.isNotBlank(orgWideEmailAddressId)){  mail.setOrgWideEmailAddressId(orgWideEmailAddressId); }
        if(toEmailAddresses != NULL && !toEmailAddresses.isEmpty() ){ mail.setToAddresses(toEmailAddresses); }
        if(ccEmailAddresses != NULL && !ccEmailAddresses.isEmpty() ){ mail.setCCAddresses(ccEmailAddresses); }
        if(bccEmailAddresses != NULL && !bccEmailAddresses.isEmpty() ){ mail.setBCCAddresses(bccEmailAddresses); }
        mail.setSaveAsActivity(true);
        mail.setTreatTargetObjectAsRecipient(false);
        return mail;
    }
    
    public Messaging.EmailFileAttachment getEmailAttachment(string fileName, Blob fileBody, string contentType){
        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
        attach.setContentType(contentType);
        attach.setFileName(fileName);
        attach.setInline(false);
        attach.Body = fileBody;
        return attach;
    }
    
    /*
* Commenting below method as it is not been used and have exception
* System.EmailException: SendEmail failed. First exception on row 0; first error: REQUIRED_FIELD_MISSING, Missing targetObjectId with template: []
* 
*/ 
    /*
public void sendMailWithEmailTemplate(List<String> emailAddresses, Id emailTemplateId, Id whatId, Id whoId, Id orgWideEmailAddressId) {
Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
mail.setToAddresses(emailAddresses);
mail.setTemplateId(emailTemplateId);
mail.setOrgWideEmailAddressId(orgWideEmailAddressId);
sendEmail(new Messaging.SingleEmailMessage[] { mail });
}*/
    /**
* Sends an email using an Email Template with extra 'To' addresses.
*
* @param targetRecordId   - Contact, Lead, or User Id for merge fields in the template
* @param whatId           - Related record Id (Case, Opportunity, etc.) for merge fields
* @param templateId       - Id of the Email Template
* @param orgWideEmailId   - Id of the Org-Wide Email Address to send from
* @param extraEmailList   - List of additional email addresses to send to
*/
    public void sendEmailUsingTemplate(
        Id targetRecordId,
        //Id whatId,
        Id templateId,
        Id orgWideEmailId,
        List<String> extraEmailList
    ) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        // Required fields for template-based email
        mail.setTargetObjectId(targetRecordId);
        //mail.setWhatId(whatId);
        mail.setTemplateId(templateId);
        mail.setOrgWideEmailAddressId(orgWideEmailId);
        mail.setSaveAsActivity(false);
        
        // Add extra plain email addresses (optional)
        if (extraEmailList != null && !extraEmailList.isEmpty()) {
            mail.setToAddresses(extraEmailList);
        }
        
        sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
    public List<Messaging.SendEmailResult> sendEmail(List<Messaging.SingleEmailMessage> emailList) {
        UserService objUserService = UserService.getInstance();
        List<Messaging.SendEmailResult> emailResultList;
        try {
        if(!objUserService.hasBypassEmail() && emailList != NULL && !emailList.isEmpty()){
            emailResultList = Messaging.sendEmail(emailList);
        }
        } catch (Exception e) {
        System.debug('A generic error occurred: ' + e.getMessage());
    }
        return emailResultList;
    }
    
    //get email template by developer name
    public EmailTemplate getEmailTemplateByDevName(string emailTemplateDevName){
        return [SELECT Id, Subject,HtmlValue, Body FROM EmailTemplate WHERE DeveloperName = :emailTemplateDevName];
    }
    
    //get email template by name
    public EmailTemplate getEmailTemplateByName(string templateName){
        return [SELECT Id, Name, Subject, Body, HTMLValue, TemplateType FROM EmailTemplate WHERE Name = :templateName AND IsActive = true LIMIT 1];
    }
    
    //get email template by record Id
    public EmailTemplate getEmailTemplateById(Id emailTemplateId){
        return [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE Id = :emailTemplateId];
    }
     public Map<Id, EmailTemplate> getEmailTemplatesByIds(Set<Id> emailTemplateIds) {
    return new Map<Id, EmailTemplate>([
        SELECT Id, Subject, HtmlValue, Body 
        FROM EmailTemplate 
        WHERE Id IN :emailTemplateIds
    ]);
}
    
    //get OrgWideEmailAddress by display name
    public OrgWideEmailAddress getOrgWideEmailAddressByDisplayName(String displayName){
        return [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = :displayName];
    }
    
    public Map<String, List<Messaging.EmailFileAttachment>> getAttachments(List<SalesOrder__c> salesOrders, String attachmentName) {
        Map<String, List<Messaging.EmailFileAttachment>> mapOfRecordIdIdAndAttachment = new Map<String, List<Messaging.EmailFileAttachment>>();
        List<Document__c> docList = [SELECT Id, SalesOrder__c, ContentDocumentId__c 
                                     FROM Document__c 
                                     WHERE SalesOrder__c IN :salesOrders 
                                     AND ContentDocumentId__c != null 
                                     AND Document_Name__c = :attachmentName];
        if(docList != null && !docList.isEmpty()){
            Map<String, String> soDocMap = new Map<String, String>(); 
            
            // Populate the map with documents grouped by SalesOrder__c
            for (Document__c doc : docList) {
                soDocMap.put(doc.SalesOrder__c, doc.ContentDocumentId__c);
            }
            // Query ContentVersion using the extracted ContentDocumentId__c values
            List<ContentVersion> conVer = [SELECT Id, Title, PathOnClient, ContentDocumentId, VersionData 
                                           FROM ContentVersion 
                                           WHERE ContentDocumentId IN :soDocMap.Values() AND isLatest = true]; 
            //system.debug('conVersion List:' +conVer);
            
            // Create a map of <ContentDocumentId, List<ContentVersion>>
            Map<Id, ContentVersion> contentDocumentVersionMap = new Map<Id, ContentVersion>();
            
            // Populate the map with ContentVersions grouped by ContentDocumentId
            for (ContentVersion cv : conVer) {
                contentDocumentVersionMap.put(cv.ContentDocumentId, cv);
            }
            //System.debug('contentDocumentVersionMap ---->' +contentDocumentVersionMap);
            
            for(SalesOrder__c so : salesOrders){
                if(soDocMap.containsKey(so.Id)){
                    if(contentDocumentVersionMap.containsKey(soDocMap.get(so.Id))){
                        ContentVersion cv = contentDocumentVersionMap.get(soDocMap.get(so.Id));
                        Blob fileData = cv.VersionData;
                        Messaging.EmailFileAttachment emlAtt = new Messaging.EmailFileAttachment();
                        emlAtt.setFilename(cv.PathOnClient);
                        emlAtt.setBody(fileData);
                        mapOfRecordIdIdAndAttachment.put(so.Id, new List<Messaging.EmailFileAttachment>{emlAtt});
                    }
                }
            }
        }
        return mapOfRecordIdIdAndAttachment;
    }
    
    public String customUnitTableHeader(){
        String emailBody = '<table style="border-collapse: collapse; width: 100%;">';
        // Add table headers
        emailBody += '<tr>';
        emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Sales Order Number</th>';
        emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Unit Number</th>';
        emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Customer Name</th>';
        emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Registration Date</th>';
        emailBody += '</tr>';
        return emailBody;
    }
    
    public String makeTable(Unit__c unit){
        if (unit == null) {
            return '';
        }
        String unitLink = '';
        if (unit.Id != null && unit.Name != null) {
            unitLink = '<a href="' + BASE_URL + '/' + unit.Id + '">' + unit.Name + '</a>';
        }
        String soLink = '';
        String customerName = '';
        if (unit.Active_Sales_Order__c != null && unit.Active_Sales_Order__r != null) {
            soLink = '<a href="' + BASE_URL + '/' + unit.Active_Sales_Order__c + '">' + unit.Active_Sales_Order__r.Name + '</a>';
            if (unit.Active_Sales_Order__r.Account__r != null && unit.Active_Sales_Order__r.Account__r.Name != null) {
                customerName = unit.Active_Sales_Order__r.Account__r.Name;
            }
        }
        
        String admRegDate = '';
        if (unit.RegistrationDate__c != null) {
            admRegDate = unit.RegistrationDate__c.format();
        }
        String htmlBody = '<tr>';
        htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + soLink + '</td>');
        htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + unitLink + '</td>');
        htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + customerName + '</td>');
        htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + admRegDate + '</td>');
        htmlBody += ('</tr>');
        return htmlBody;
    }
    
    public String makeTable(SalesOrder__c so){
        String unitLink = '<a href="'+BASE_URL+ '/' + so.Unit__c + '">' + so.Unit__r.Name + '</a>';
        String soLink = '<a href="'+BASE_URL+ '/' + so.Id + '">' + so.Name + '</a>';
        String regDate = so.UnitRegistrationDate__c.format();
        String htmlBody = '<tr>'; 
        htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + soLink + '</td>');
        htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + unitLink+ '</td>');
        htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + so.Account__r.Name+ '</td>');
        htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + regDate+ '</td>');
        htmlBody += ('</tr>');
        return htmlBody;
    }
    
    public String customUnitILTableHeader(Boolean isQuarterlyReminder){
        String emailBody = '<table style="border-collapse: collapse; width: 100%;">';
        // Add table headers
        emailBody += '<tr>';
        emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Project Name</th>';
        emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Unit Number</th>';
        emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Customer Name</th>';
        if(isQuarterlyReminder){
            emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Installment Number</th>';
            emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Description</th>';
            emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Type</th>';
        }
        emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Amount</th>';
        emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Due Date</th>';
        emailBody += '</tr>';
        return emailBody;
    }
    
    public String customLeadTableHeader(String strHeader, Boolean dailyNotification){
        String emailBody = '<table style="border-collapse: collapse; width: 100%;">';
        // Add table headers
        if(dailyNotification){
            emailBody += '<tr>';
            emailBody += '<th colspan="5" style="border: 1px solid black; text-align: center; padding: 8px;">'+strHeader+'</th>';
            emailBody += '</tr>';
            emailBody += '<tr>';
            emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Lead Number</th>';
            emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Lead Full Name</th>';
            emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Lead Status</th>';
            emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Created Date</th>';
            emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Project</th>';
            emailBody += '</tr>';
        }
        else{
            emailBody += '<tr>';
            emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Lead Number</th>';
            emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Customer Name</th>';
            emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Lead Status</th>';
            emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Sales Manager</th>';
            emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Assigned Date</th>';
            emailBody += '</tr>';
        }
        return emailBody;
    }
    
    public String customsalesOrderOtherChargesTableHeader(){
        String emailBody = '<table style="border-collapse: collapse; width: 100%;">';
        // Add table headers
        emailBody += '<tr>';
        emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Sales Order</th>';
        emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Sales Order Charge</th>';
        emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Customer Name</th>';
        emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Amount</th>';
        emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Due Date</th>';
        emailBody += '</tr>';
        return emailBody;
    }
    
    public String customPaymentPlanTableHeader(){
        String emailBody = '<table style="border-collapse: collapse; width: 100%;">';
        // Add table headers
        emailBody += '<tr>';
        emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Payment Installment</th>';
        emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Payment Plan</th>';
        emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Project</th>';
        emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Installment Number</th>';
        emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Installment (%)</th>';
        emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Installment Date</th>';
        emailBody += '<th style="border: 1px solid black; text-align: center; padding: 8px;">Revised Date</th>';
        emailBody += '</tr>';
        return emailBody;
    }
    
    public String customSalesOrderTableHeader() {
        String tableStyle = 'width:100%;'+'border-collapse:collapse;'+'font-family:Arial,Helvetica,sans-serif;'+'font-size:10px;'+'line-height:140%;';
        String headerStyle = 'border:1px solid #777;'+'background-color:#eeeeee;'+'padding:6px 5px;'+'text-align:center;'+'vertical-align:middle;'+'font-weight:bold;'+'word-break:normal;'+'overflow-wrap:normal;';
        String htmlBody = '<table cellpadding="0" cellspacing="0" border="0" '+'style="' + tableStyle + '">';
        htmlBody += '<tr>';
        htmlBody += '<th width="6%" style="' + headerStyle + '">Serial Number</th>';
        htmlBody += '<th width="10%" style="' + headerStyle + '">Unit Number</th>';
        htmlBody += '<th width="8%" style="' + headerStyle + '">Plot Number</th>';
        htmlBody += '<th width="18%" style="' + headerStyle + '">Buyer Name</th>';
        htmlBody += '<th width="12%" style="' + headerStyle + '">Ownership Percentage (%)</th>';
        htmlBody += '<th width="18%" style="' + headerStyle + '">Joint Buyer(s)</th>';
        htmlBody += '<th width="10%" style="' + headerStyle + '">Total Fees (2%)</th>';
        htmlBody += '<th width="10%" style="' + headerStyle + '">Selling Price</th>';
        htmlBody += '<th width="8%" style="' + headerStyle + '">DARI Application Number</th>';
        htmlBody += '</tr>';
        return htmlBody;
    }
    
    public String makeTable(InstallmentLines__c il, Boolean isQuarterlyReminder){
        String projectName = (il.SalesOrder__r.Unit__r.Project__r.Name != null ? il.SalesOrder__r.Unit__r.Project__r.Name : '');
        String unitNumber = (il.SalesOrder__r.Unit__r.Name != null ? il.SalesOrder__r.Unit__r.Name : '');
        String customerName = (il.SalesOrder__r.Account__r.Name != null ? il.SalesOrder__r.Account__r.Name : '');
        String installmentNumber = (il.InstallmentNumber__c != null ? String.valueOf(il.InstallmentNumber__c) : '');
        String installmentDescription = (il.Description__c != null ? il.Description__c : '');
        String installmentType = (il.Type__c != null ? il.Type__c : '');
        String amount = (il.PendingAmount__c > 0 ? String.valueOf(il.get('pendingamount')) : 'AED 0');
        String dueDate = DateTime.newInstance(il.Due_Date__c.year(),il.Due_Date__c.month(),il.Due_Date__c.day()).format('d-MM-YYYY');
        String htmlBody = '<tr>'; 
        htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + projectName + '</td>');
        htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + unitNumber+ '</td>');
        htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + customerName+ '</td>');
        if(isQuarterlyReminder){
            htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + installmentNumber+ '</td>');
            htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + installmentDescription+ '</td>');
            htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + installmentType+ '</td>');
        }
        htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + amount+ '</td>');
        htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + dueDate+ '</td>');
        htmlBody += ('</tr>');
        return htmlBody;
    }
    
    public String makeTable(Lead objLead,Boolean dailyNotification){
        String leadNumber = (objLead.LeadNumber__c != null ? objLead.LeadNumber__c : '');
        String leadName = (objLead.Name != null ? objLead.Name : '');
        String status = (objLead.Status != null ? objLead.Status : '');
        String createdDate = DateTime.newInstance(objLead.CreatedDate.year(),objLead.CreatedDate.month(),objLead.CreatedDate.day()).format('d-MM-YYYY');
        String project = (objLead.Project__c != null ? objLead.Project__c : '');
        String leadManagerStatus = (objLead.LeadManagerStatus__c != null ? objLead.LeadManagerStatus__c : '');
        String leadManager = (objLead.Owner.Name != null ? objLead.Owner.Name : '');
        DateTime leadManagerAssignedDate = (objLead.LeadManagerAssignedDate__c != null ? objLead.LeadManagerAssignedDate__c.addHours(4) : null);
        String htmlBody = '<tr>'; 
        if(dailyNotification){
            htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + leadNumber + '</td>');
            htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + leadName + '</td>');
            htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + status + '</td>');
            htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + createdDate + '</td>');
            htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + project + '</td>');
            htmlBody += ('</tr>');
        }
        else{
            htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + leadNumber + '</td>');
            htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + leadName + '</td>');
            htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + leadManagerStatus + '</td>');
            htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + leadManager + '</td>');
            htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + leadManagerAssignedDate + '</td>');
            htmlBody += ('</tr>');
        }
        return htmlBody;
    }      
    
    public String makeTable(SalesOrderOtherCharges__c so){
        String dueDate = DateTime.newInstance(so.Due_Date__c.year(),so.Due_Date__c.month(),so.Due_Date__c.day()).format('d-MM-YYYY');
        String salesOrderLink = '<a href="'+BASE_URL+ '/' + so.SalesOrder__c + '">' + so.SalesOrder__r.Name + '</a>';
        String soChargeLink = '<a href="'+BASE_URL+ '/' + so.Id + '">' + so.Name + '</a>';
        String htmlBody = '<tr>'; 
        htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + salesOrderLink + '</td>');
        htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + soChargeLink + '</td>');
        htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + so.Account__r.Name + '</td>');
        htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + so.Amount__c + '</td>');
        htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + dueDate + '</td>');
        htmlBody += ('</tr>');
        return htmlBody;
    }
    
    public String makeTable(PaymentInstallments__c objPI){
        String installmentDate = (objPI.InstallmentDate__c != null ? DateTime.newInstance(objPI.InstallmentDate__c.year(),objPI.InstallmentDate__c.month(),objPI.InstallmentDate__c.day()).format('d-MM-YYYY') : '');
        String revisedDate = (objPI.RevisedDate__c != null ? DateTime.newInstance(objPI.RevisedDate__c.year(),objPI.RevisedDate__c.month(),objPI.RevisedDate__c.day()).format('d-MM-YYYY') : '');
        String paymentPlanLink = '<a href="'+BASE_URL+ '/' + objPI.Id + '">' + objPI.Name + '</a>';
        String htmlBody = '<tr>'; 
        htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + paymentPlanLink + '</td>');
        htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + objPI.Payment_Plan_Name__c + '</td>');
        htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + objPI.Project__c + '</td>');
        htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + objPI.InstallmentNumber__c + '</td>');
        htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + objPI.InstallmentPercentage__c + '</td>');
        htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + installmentDate + '</td>');
        htmlBody += ('<td style="border: 1px solid black; text-align: center; padding: 8px;">' + revisedDate + '</td>');
        htmlBody += ('</tr>');
        return htmlBody;
    }
    
        public String makeTable(Integer serialNo,SalesOrder__c so,String jointOwners) {
        String unitNumber = so.Unit__r != null ? so.Unit__r.Name : '';
        String plotNumber = so.Unit__r != null ? String.valueOf(so.Unit__r.ADMPlotNumber__c) : '';
        String buyerName = so.Account__r != null ? so.Account__r.Name : '';
        String ownershipPercentage = so.OwnerSharePercentage__c != null ? String.valueOf(so.OwnerSharePercentage__c) : '';
        String totalFees = so.SellingPrice__c != null ? formatCurrency(so.SellingPrice__c) : '';
        String sellingPrice = so.SellingPrice__c != null ? formatCurrency(so.SellingPrice__c) : '';
        String dariApplicationNumber = '';//so.DARIApplicationNumber__c != null ? so.DARIApplicationNumber__c : '';
        String cellStyle = 'border:1px solid #777;'+'padding:5px 4px;'+'vertical-align:top;'+'font-family:Arial,Helvetica,sans-serif;'+'font-size:10px;'+'line-height:140%;';
        String textCellStyle = cellStyle + 'text-align:left;'+'word-break:normal;'+'overflow-wrap:break-word;';
        String centerCellStyle = cellStyle + 'text-align:center;'+'white-space:nowrap;';
        String numberCellStyle = cellStyle + 'text-align:right;'+'white-space:nowrap;';
        String htmlBody = '<tr>';
        htmlBody += '<td style="' + centerCellStyle + '">' + serialNo + '</td>';
        htmlBody += '<td style="' + centerCellStyle + '">' + unitNumber + '</td>';
        htmlBody += '<td style="' + centerCellStyle + '">' + plotNumber + '</td>';
        htmlBody += '<td style="' + textCellStyle + '">' + buyerName + '</td>';
        htmlBody += '<td style="' + centerCellStyle + '">' + ownershipPercentage + '</td>';
        htmlBody += '<td style="' + textCellStyle + '">' + jointOwners + '</td>';
        htmlBody += '<td style="' + numberCellStyle + '">' + totalFees + '</td>';
        htmlBody += '<td style="' + numberCellStyle + '">' + sellingPrice + '</td>';
        htmlBody += '<td style="' + centerCellStyle + '">' + dariApplicationNumber + '</td>';
        htmlBody += '</tr>';
        return htmlBody;
    }
    
    public String generateCSV(List<InstallmentLines__c> ilList, Boolean isQuarterlyReminder) {
        // Initialize the CSV content with column headers
        String csvContent = (isQuarterlyReminder ? 'Project Name,Unit Number,Customer Name,Installment Number,Description,Type,Amount,Due Date\n' 
                             : 'Project Name,Unit Number,Customer Name,Amount,Due Date\n');
        
        if (ilList != null && ilList.size() > 0) {
            for (InstallmentLines__c il : ilList) {
                // Format date so Excel doesn’t auto-convert
                DateTime dt = DateTime.newInstance(il.Due_Date__c.year(), il.Due_Date__c.month(), il.Due_Date__c.day());
                String formattedDate = '="' + dt.format('dd-MM-yyyy') + '"';
                
                csvContent += '"' + (il.SalesOrder__r.Unit__r.Project__r.Name != null ? il.SalesOrder__r.Unit__r.Project__r.Name : '') + '",';
                csvContent += '"' + (il.SalesOrder__r.Unit__r.Name != null ? il.SalesOrder__r.Unit__r.Name : '') + '",';
                csvContent += '"' + (il.SalesOrder__r.Account__r.Name != null ? il.SalesOrder__r.Account__r.Name : '') + '",';
                
                if (isQuarterlyReminder) {
                    csvContent += '"' + (il.InstallmentNumber__c != null ? String.valueOf(il.InstallmentNumber__c) : '') + '",';
                    csvContent += '"' + (il.Description__c != null ? il.Description__c : '') + '",';
                    csvContent += '"' + (il.Type__c != null ? il.Type__c : '') + '",';
                }
                
                csvContent += '"' + (il.PendingAmount__c > 0 ? String.valueOf(il.get('pendingamount')) : 'AED 0') + '",';
                csvContent += formattedDate + '\n';
            }
        }
        return csvContent;
    }
    
    public String generateCSV(List<SalesOrderOtherCharges__c> socList){
        // Initialize the CSV content with column headers
        String csvContent = 'Sales Order, Sales Order Charge, Customer Name, Amount, Due Date \n';
        // Loop through the Account records and create the CSV rows
        if(socList.size() > 0){
            for (SalesOrderOtherCharges__c objSOC : socList) {
                csvContent += '"' + (objSOC.SalesOrder__r.Name != null ? objSOC.SalesOrder__r.Name : '') + '",';
                csvContent += '"' + (objSOC.Name != null ? objSOC.Name : '') + '",';
                csvContent += '"' + (objSOC.Account__r.Name != null ? objSOC.Account__r.Name : '') + '",';
                csvContent += '"' + (objSOC.Amount__c > 0 ? String.valueOf(objSOC.get('pendingamount')) : '') + '",';
                csvContent += '"' + DateTime.newInstance(objSOC.Due_Date__c.year(),objSOC.Due_Date__c.month(),objSOC.Due_Date__c.day()).format('d-MM-YYYY') + '"\n';
            }
        }
        return csvContent;
    }
    
    public String generateCSV(List<Lead> leadList){
        // Initialize the CSV content with column headers
        String csvContent = 'Lead Number, Customer Name, Lead Status, Sales Manager, Assigned Date \n';
        // Loop through the Account records and create the CSV rows
        if(leadList.size() > 0){
            for (Lead objLead : leadList) {
                DateTime leadManagerAssignedDate = (objLead.LeadManagerAssignedDate__c != null ? objLead.LeadManagerAssignedDate__c : null); 
                DateTime modifiedManagerAssignedDate = leadManagerAssignedDate.addHours(4);
                csvContent += '"' + (objLead.LeadNumber__c != null ? objLead.LeadNumber__c : '') + '",';
                csvContent += '"' + (objLead.Name != null ? objLead.Name : '') + '",';
                csvContent += '"' + (objLead.LeadManagerStatus__c != null ? objLead.LeadManagerStatus__c : '') + '",';
                csvContent += '"' + (objLead.Owner.Name != null ? objLead.Owner.Name : '') + '",';
                csvContent += '"' + modifiedManagerAssignedDate + '"\n';
            }
        }
        return csvContent;
    }
    
    public String generateCSV(List<SalesOrder__c> salesOrders,Map<Id,String> accountJointOwnersMap) {
        String csvContent = 'Serial Number,Unit Number,Plot Number,Buyer Name,Ownership Percentage (%),Joint Buyer(s),Total Fees (2%),Selling Price,DARI Application Number\n';
        Integer serialNo = 1;
        for (SalesOrder__c so : salesOrders) {
            csvContent += '"' + serialNo + '",';
            csvContent += '"' + (so.Unit__r != null ? so.Unit__r.Name : '') + '",';
            csvContent += '"' + (so.Unit__r.ADMPlotNumber__c != null ? so.Unit__r.ADMPlotNumber__c : '') + '",';
            csvContent += '"' + (so.Account__r != null ? so.Account__r.Name : '') + '",';
            csvContent += '"' + (so.OwnerSharePercentage__c != null ? String.valueOf(so.OwnerSharePercentage__c) : '') + '",';
            csvContent += '"' + (accountJointOwnersMap.containsKey(so.Account__c) ? accountJointOwnersMap.get(so.Account__c): '') + '",';
            csvContent += '"' + (so.SellingPrice__c != null ? String.valueOf(so.SellingPrice__c) : '') + '",';
            csvContent += '"' + (so.SellingPrice__c != null ? String.valueOf(so.SellingPrice__c) : '') + '",';
            //csvContent += '"' + (so.DARIApplicationNumber__c != null ? so.DARIApplicationNumber__c : '') + '"\n';
            serialNo++;
        }
        return csvContent;
    }
    
    public static Map<Id, EmailTemplate> getEmailTemplatesFromFolder(String folderId) {
        Map<Id, EmailTemplate> templateMap = new Map<Id, EmailTemplate>();
        for (EmailTemplate template : [
            SELECT Id, Name, IsActive, FolderId, FolderName, Subject, Description, HtmlValue, DeveloperName, Body
            FROM EmailTemplate
            WHERE IsActive = true AND FolderId = :folderId
            ORDER BY FolderName, Name
        ]) {
            templateMap.put(template.Id, template);
        }
        return templateMap;
    }
    
    public List<Messaging.EmailFileAttachment> getCaseAttachmentsByDocName(String caseId, List<String> documentNameList){
        Set<Id> contentDocIds = new Set<Id>();
        List<Messaging.EmailFileAttachment> fileAttachments = new List<Messaging.EmailFileAttachment>();
        Map<Id,String> docIdNameMap = new Map<Id,String>();
        
        for(Document__c doc : [SELECT id, ContentDocumentId__c, document_name__c 
                               FROM Document__c 
                               WHERE Case__c =: caseId 
                               AND ContentDocumentId__c != null 
                               AND Document_Name__c IN :documentNameList]){
                                   contentDocIds.add(doc.ContentDocumentId__c);
                                   docIdNameMap.put(doc.ContentDocumentId__c, doc.document_name__c);
                               }
        
        for (ContentVersion cv : [SELECT Id, Title, VersionData, FileExtension, ContentDocumentId
                                  FROM ContentVersion
                                  WHERE ContentDocumentId IN :contentDocIds
                                  AND IsLatest = true]) {
                                      Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                                      efa.setFileName(docIdNameMap.get(cv.ContentDocumentId) + '.' + cv.FileExtension);
                                      efa.setBody(cv.VersionData);
                                      //efa.setContentType('application/octet-stream');
                                      fileAttachments.add(efa);
                                  }
        return fileAttachments;
    }
    
    //Pranav
    public List<Messaging.EmailFileAttachment> getCaseAttachments(String caseId){
        Set<Id> contentDocIds = new Set<Id>();
        List<Messaging.EmailFileAttachment> fileAttachments = new List<Messaging.EmailFileAttachment>();
        Map<Id,String> docIdNameMap = new Map<Id,String>();

        for(Document__c doc : [Select id, ContentDocumentId__c, document_name__c from Document__c where Case__c =: caseId AND ContentDocumentId__c != Null]){
                                   contentDocIds.add(doc.ContentDocumentId__c);
                                   docIdNameMap.put(doc.ContentDocumentId__c, doc.document_name__c);
                               }
        
        for (ContentVersion cv : [SELECT Id, Title, VersionData, FileExtension, ContentDocumentId
                                  FROM ContentVersion
                                  WHERE ContentDocumentId IN :contentDocIds
                                  AND IsLatest = true]) {
                                      Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                                      efa.setFileName(docIdNameMap.get(cv.ContentDocumentId) + '.' + cv.FileExtension);
                                      efa.setBody(cv.VersionData);
                                      //efa.setContentType('application/octet-stream');
                                      fileAttachments.add(efa);
                                  }
        return fileAttachments;
    }
    
    private String formatCurrency(Decimal value) {
        if (value == null) {
            return '';
        }
        String result = String.valueOf(value.setScale(2));
        List<String> parts = result.split('\\.');
        String integerPart = parts[0];
        String decimalPart = parts.size() > 1 ? parts[1] : '00';
        Boolean negative = integerPart.startsWith('-');
        if (negative) {
            integerPart = integerPart.substring(1);
        }
        String formatted = '';
        while (integerPart.length() > 3) {
            formatted = ',' + integerPart.substring(integerPart.length() - 3) + formatted;
            integerPart = integerPart.substring(0, integerPart.length() - 3);
        }
        formatted = integerPart + formatted;
        if (negative) {
            formatted = '-' + formatted;
        }
        return formatted + '.' + decimalPart;
    }
    
    public Map<String, EmailTemplate> getEmailTemplatesByName(Set<String> templateNames) {
        Map<String, EmailTemplate> templateNameVsEmailTemplateMap = new Map<String, EmailTemplate>();
        for (EmailTemplate mailTemplate : [SELECT Id, Name, DeveloperName, OwnerId, IsActive, Subject, FolderId, FolderName,
                                                    Description, Body, HTMLValue, TemplateType
                                            FROM EmailTemplate
                                            WHERE Name IN :templateNames
        ]) {
            templateNameVsEmailTemplateMap.put(mailTemplate.Name, mailTemplate);
        }

        return templateNameVsEmailTemplateMap;
    }

}