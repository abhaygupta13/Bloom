//============================ BCAPP_Utility =============================
/*
* @Author : Eagles  
* @CreatedDate : 04 Sept 2024
* @Name : BCAPP_Utility
* @Description : This APEX class used to validate the Business rules in the Community APP
*/
/*****************************************************************************************************
* Version       Author                  Date             Comment                                                                       
* 1.0           Eagles               04 Sept 2024        Initial draft 
*****************************************************************************************************/

public  class BCAPP_Utility { 
    
    private static BCAPP_Utility instance;
    
    public static BCAPP_Utility getInstance() {
        if(instance == null) {
            instance = new BCAPP_Utility();
        }
        return instance;
    }
    public List<SObject> getRecords(String sObjectName, List<String> fields, String whereClause) {
        if (String.isEmpty(sObjectName) || fields == null || fields.isEmpty()) {
            throw new IllegalArgumentException('sObjectName and fields cannot be empty.');
        }
        
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(sObjectName);
        if (objType == null) {
            throw new IllegalArgumentException('Invalid object name: ' + sObjectName);
        }
        
        String query = 'SELECT ' + String.join(fields, ', ') + ' FROM ' + sObjectName;
        if (!String.isEmpty(whereClause)) {
            query += ' WHERE ' + whereClause;
        }
        system.debug(query);
        return Database.query(query);
    }
    
    // Method to validate the Service_Request__c object
    public String validateTenantMoveInRequest(Case request) {
        
        // Validate Email format
        if (!Pattern.matches('^[\\w.%+-]+@[\\w.-]+\\.[a-zA-Z]{2,}$', request.Email_Address__c )) {
            return 'Email address must be in a valid format.';
        }
        
        // Validate Lease Start Date
        Date currentDate = Date.today();
        if (request.EJARI_Tawteeq_start_date__c  > currentDate.addDays(-5)) {
            //  return 'Lease Start Date cannot be more than 5 days in the past.';
        }
        system.debug('Move_in_date__c--'+request.Move_in_date__c+'--'+request.EJARI_Tawteeq_end_date__c+'--'+request.EJARI_Tawteeq_start_date__c);        
        // Validate Lease End Date
        /*  if (request.EJARI_Tawteeq_end_date__c > request.EJARI_Tawteeq_start_date__c) {
return 'Lease End Date cannot be before Lease Start Date.';
}
system.debug('Move_in_date__c--'+request.Move_in_date__c+'--'+request.EJARI_Tawteeq_end_date__c+'--'+request.EJARI_Tawteeq_start_date__c);
// Validate Move In Date
if (request.Move_in_date__c  >= request.EJARI_Tawteeq_start_date__c || request.Move_in_date__c  <= request.EJARI_Tawteeq_end_date__c) {
return 'Move In Date must be on or after Lease Start Date and on or before Lease End Date.';
}*/
        
        // No validation errors
        return null;
    }
    
    /*  public static Id getRecordTypeIdByName(String objectName, String recordTypeName) {
// Query the RecordType object to find the record type ID by its DeveloperName and SObjectType
RecordType recordType = [SELECT Id
FROM RecordType
WHERE (DeveloperName = :recordTypeName OR Name=:recordTypeName)
AND SObjectType = :objectName
LIMIT 1];

// Return the Record Type ID
return recordType != null ? recordType.Id : null;
}*/
    
    public Map<String,String> processDocuments(List<BCAPP_WrapperUtility.Document> wrapper,String parentId,String sCatalogDocId){
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        CaseService cService = CaseService.getInstance();
        Map<String,String> result = new Map<String,String>();
        for (BCAPP_WrapperUtility.Document doc : wrapper) {
            if (doc.fileName != null && doc.fileContent != null) {
                contentVersions.add(new ContentVersion(
                    Title = doc.fileName,
                    PathOnClient = doc.fileName, 
                    VersionData = doc.fileContent
                ));
            }
        }
        
        // Insert content versions
        CustomerDocumentService cdService = new CustomerDocumentService();
        if (!contentVersions.isEmpty()) {
            insert contentVersions;
            String customerDocId;
            List<Customer_Document__c> customerDocs = cdService.getCustomerDocumentsByCatalogId(parentId,sCatalogDocId);
            if(!customerDocs.isEmpty()){
                customerDocId = customerDocs[0].Id;
            }
            else{
                Case sr = cService.getCaseById(parentId);
                Service_Catolog_Documents__c scdoc = [select Name from Service_Catolog_Documents__c where Id=:sCatalogDocId ];
                Customer_Document__c cds = new Customer_Document__c();
                cds.Case__c = parentId;
                cds.Name = scdoc.Name;
                cds.Account__c = sr.AccountId;
                cds.Service_Catolog_Documents__c = sCatalogDocId;
                cdService.createCustomerDocument(new List<Customer_Document__c>{cds});
                customerDocId = cds.Id;
            }
            List<ContentDocumentLink> exisitngFiles = [select ContentDocumentId from ContentDocumentLink where  LinkedEntityId=:customerDocId];
            if(!exisitngFiles.isEmpty()){
                List<ContentDocument> existingcds = [select Id from ContentDocument where Id=:exisitngFiles[0].ContentDocumentId];
                delete existingcds;
            }
            // Create links to associate ContentDocuments with a parent record
            List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
            ContentDocumentService codService = new ContentDocumentService();
            List<ContentVersion> cVs = codService.fetchContentVersion(contentVersions);
            List<ContentDistribution> cd = new List<ContentDistribution>(); 
            UserService userservice = UserService.getInstance();
            Id integrationUser = UserInfo.getUserId();
            for (ContentVersion cv : cVs) {
                contentDocumentLinks.add(new ContentDocumentLink(
                    ContentDocumentId = cv.ContentDocumentId, 
                    LinkedEntityId = customerDocId
                ));
                contentDocumentLinks.add(new ContentDocumentLink(
                    ContentDocumentId = cv.ContentDocumentId, 
                    LinkedEntityId =  integrationUser
                ));
                cd.add(new ContentDistribution(
                    ContentVersionId  = cv.Id, 
                    PreferencesAllowPDFDownload = true,
                    Name = cv.Title
                    
                ));
            }
            // Insert ContentDocumentLinks
            Database.insert(contentDocumentLinks, false);
            insert cd;
            //check all documents 
            //CustomerDocumentService cdService = new CustomerDocumentService();
            Integer customerDocumentCount = cdService.getDocumentsCountOnCase(parentId);
            result.put('docId', contentDocumentLinks[0].ContentDocumentId);
            if(!cVs.isEmpty()){
                List<ContentDistribution> cds = [select DistributionPublicUrl from ContentDistribution where Id =:cd[0].Id];
                result.put('url', cds[0].DistributionPublicUrl);
            }
            
        }
        return result;
    }
    
    public List<String> parseMultiPicklist(String fieldValue) {
        List<String> picklistValues = new List<String>();
        
        if (fieldValue != null ) {
            // Split picklist values and add to set
            String[] valuesArray = fieldValue.split(';');
            for (String value : valuesArray) {
                picklistValues.add(value.trim()); // Trim spaces to avoid mismatches
            }
        }
        
        return picklistValues;
    }
    
    // Method to get the current user's local time
    public Datetime getCurrentUserLocalTime() {
        // Get current user information
        User currentUser = [SELECT TimeZoneSidKey FROM User WHERE Id = :UserInfo.getUserId()];
        
        // Get the current user's timezone
        TimeZone userTimeZone = TimeZone.getTimeZone(currentUser.TimeZoneSidKey);
        
        // Get current date-time in GMT
        Datetime currentDateTimeGMT = System.now(); // GMT/UTC
        
        // Convert the GMT time to the user's local time
        Datetime userLocalTime = currentDateTimeGMT.addSeconds(userTimeZone.getOffset(currentDateTimeGMT) / 1000);
        
        return userLocalTime;
    }
    
    public List<User__c> getUserbyAccountId(String userCode) {
        List<User__c> customer;
        if(!String.isBlank(userCode)){
            customer =  [select Request_for_Mobile_Amendment__c,Request_for_Email_Amendment__c,deviceRegistrationId__c,
                         User_Account__r.Owner__c,User_Account__r.Holiday_Homes__c,User_Account__r.Tenant__c,
                         Forget_Password_Request_OTP__c,Azure_UserId__c,Last_Login__c,Mobile_Number__c,User_Account__r.Emergency_contact_01__c,
                         Customer_Code__c, Account__c, Is_Azure_Active__c,Name, Username__c ,Email__c,User_Type__c ,User_Account__r.Emergency_contact_02__c,
                         User_Principal_Name__c,User_Account__r.FirstName,User_Account__r.LastName,User_Account__r.Mobile__c,User_Account__r.Emirates_ID_number__c,
                         User_Account__r.MobilePhone__pc,User_Account__r.Emirates_Id__pc,User_Account__r.Nationality__pc,User_Account__r.Nationality__c,User_Account__r.Emirates_ID_expiry_date__c,
                         User_Account__r.Email__c,User_Account__r.Name  from User__c where User_Account__c=:userCode];
        }
        return customer;
        
    }
    
    public static List<User__c> getUser(String userCode) {
        List<User__c> customer;
        if(!String.isBlank(userCode)){
            customer =  [select Forget_Password_Request_OTP__c,User_Account__c,Azure_UserId__c,Last_Login__c,Mobile_Number__c,Customer_Code__c, Account__c, Is_Azure_Active__c,Name, Username__c ,Email__c,User_Type__c ,User_Principal_Name__c,User_Account__r.FirstName,User_Account__r.LastName,User_Account__r.Mobile__c  from User__c where Azure_UserId__c=:userCode];
        }
        return customer;
        
    }
    public List<User__c> getUserbyEmail(String email) {
        List<User__c> customer;
        if(!String.isBlank(email)){
            customer =  [select Request_for_Email_Amendment__c,User_Account__r.Owner__c,User_Account__r.Holiday_Homes__c,User_Account__r.Tenant__c,Forget_Password_Request_OTP__c,Azure_UserId__c,Last_Login__c,Mobile_Number__c,Customer_Code__c, Account__c, Is_Azure_Active__c,Name, Username__c ,Email__c,User_Type__c ,User_Principal_Name__c,User_Account__r.FirstName,User_Account__r.LastName,User_Account__r.Mobile__c  from User__c where Email__c=:email];
        }
        return customer;
        
    }
    
    public List<BCAPP_WrapperUtility.RequiredDocuments> getRequiredDocuments(String projectId, String userType,String srId,Boolean isChillerEnabled){
        List<BCAPP_WrapperUtility.RequiredDocuments> docs = new List<BCAPP_WrapperUtility.RequiredDocuments>();
        if(!String.isBlank(projectId) && !String.isBlank(userType) && !String.isBlank(srId)){
            List<Service_Availability_Community__c> lstAC = ServiceAvaliabililtyCommunityService.getAvailableCommunity(projectId,srId);
            if(!lstAC.isEmpty()){
                Map<Id,Service_Availability_Community__c> docIds = new Map<Id,Service_Availability_Community__c>();
                for(Service_Availability_Community__c ac:lstAC){
                    List<String> requiredFor = ac.Required_For__c.split(';');
                    if(requiredFor.contains(userType)){
                        docIds.put(ac.Service_Catolog_Documents__c,ac);
                    }
                }
                for(Service_Catolog_Documents__c doc:ServiceCatalogDocumentService.getCatalogDocumentsByService(docIds.keySet(), srId)){
                    BCAPP_WrapperUtility.RequiredDocuments wrp = new BCAPP_WrapperUtility.RequiredDocuments();
                    wrp.displayName = doc.Document_Name__c;
                    wrp.documentType = doc.Document_Type__c.split(',');
                    wrp.isRequired = docIds.get(doc.Id).Is_Document_Required__c;
                    wrp.documentSize = Integer.valueOf(doc.Document_Size__c);
                    wrp.Name = doc.Name;
                    wrp.sCatalogDocId = doc.Id;
                    Boolean addDoc = true;
                    if(doc.is_Chiller_Enabled__c){
                        if(isChillerEnabled){
                            docs.add(wrp);
                        }
                    } 
                    else {
                        docs.add(wrp);
                    }
                    
                }
            }
        }
        System.debug('@#$$##$$'+docs);
        return docs;
    }
    
    public Map<String, ContentDistribution> getFileUrls(List<Id> recordIds) {
        Map<String, ContentDistribution> recordFileUrlsMap = new Map<String, ContentDistribution>();
        Map<String, String> cdVsLId = new Map<String, String>();
        List<Id> cdIds = new List<Id>();
        ContentDocumentService codService = new ContentDocumentService();
        List<ContentDocumentLink> documentLinks = codService.fetchContentDocLinksByLinkEntityIds(recordIds);
        for (ContentDocumentLink link : documentLinks) {
            cdIds.add(link.ContentDocumentId);
            cdVsLId.put(link.ContentDocumentId,link.LinkedEntityId);
        }
        List<ContentDistribution> cds = [select ContentDocumentID,ContentVersion.FileExtension,ContentVersionId,DistributionPublicUrl,ContentDownloadUrl from ContentDistribution where ContentDocumentID =:cdVsLId.keySet()];
        for (ContentDistribution link : cds) {
            // String fileUrl = '/sfc/servlet.shepherd/document/download/' + link.ContentDocumentId;
            if (cdVsLId.containsKey(link.ContentDocumentID)) {
                recordFileUrlsMap.put(cdVsLId.get(link.ContentDocumentID), link);
            }
            
        }
        return recordFileUrlsMap;
        
    }
    
    public void sendEmail(string developerName,List<string> recipientEmail,id recordId) {
        
        // Create an email template
        EmailTemplate emailTemplate = EmailTemplateService.getEmailTemplateByDeveloperName(developerName);
        
        // Set up the SingleEmailMessage object
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        OrgWideEmailAddress[] orgWideEmails = [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = :Label.BCAPP_OrgWideEmailAddress LIMIT 1];
        
        if(!orgWideEmails.isEmpty())
            email.setOrgWideEmailAddressId(orgWideEmails[0].Id);
        
        system.debug('recipientEmail'+recipientEmail);
        // Set the "To" email address
        email.setToAddresses(recipientEmail);
        email.setTargetObjectId([select id from contact where email!=null limit 1].Id);
        email.setWhatId(recordId);
        email.setTreatTargetObjectAsRecipient(false);
        
        
        // Set the email template to use
        email.setTemplateId(emailTemplate.Id);
        
        // Set the email to be sent
        email.setSaveAsActivity(true);
        
        
        // Send the email
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }
    
    public void sendCustomEmail(List<String> recipientEmails, Id recordId, String htmlBody,string plainBody,string subject) {
        // Create a list to hold emails
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        // Create a new email message instance
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        // Set the recipients
        mail.setToAddresses(recipientEmails);
        
        OrgWideEmailAddress[] orgWideEmails = [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address =  :Label.BCAPP_OrgWideEmailAddress LIMIT 1];
        
        if(!orgWideEmails.isEmpty())
            mail.setOrgWideEmailAddressId(orgWideEmails[0].Id);
        
        // Set the subject
        mail.setSubject(subject);
        
        // Set the HTML body
        mail.setHtmlBody(htmlBody);
        
        // Optionally, set the plain text body if needed (in case the recipient does not support HTML)
        mail.setPlainTextBody(plainBody);
        
        // Set the WhatId to associate the email with a record (e.g., Case, Opportunity, etc.)
        mail.setWhatId(recordId);
        
        // Add email to the list
        emails.add(mail);
        
        // Send the emails
        Messaging.sendEmail(emails);
    }
    
    
    
    public String checkDuplicateRequest(String email, Id unitId,String srType,List<string> lstStatus){
        String moveInrecordTypeId = Utilities.getRecordTypeId('Case',srType);
        CaseService cService = CaseService.getInstance();
        List<Case> lstCase = cService.getExistingServiceCase(email ,moveInrecordTypeId,unitId,lstStatus);
        String caseNumber ;
        if(!lstCase.isEmpty()){ 
            caseNumber = lstCase[0].Request_Number__c; 
        }
        return caseNumber;
    }
    
    public List<Action_Items__c> getServiceCatalogActionItems(String scId){
        return [SELECT Service_Catalog__c, On_Submit__c ,OwnerId
                FROM Action_Items__c 
                WHERE Service_Catalog__c =:scId AND On_Submit__c = true];
    }
    
    public String changeCaseAssigment(String scId){
        String caseOwnerId;
        if (!String.isBlank(scId)) {
            List<Action_Items__c> taskManagers = getServiceCatalogActionItems(scId);
            if(!taskManagers.isEmpty()){
                caseOwnerId = taskManagers[0].OwnerId;
            }   
        }
        return caseOwnerId;
    }
    
    public Map<String,Service_Catalog_Fields__c> getServiceCatalogFieldMapping(String sCatalogId,String userType){
        Map<String,Service_Catalog_Fields__c> fieldMap = new Map<String,Service_Catalog_Fields__c>();
        for(Service_Catalog_Fields__c config:ServiceCatalogService.getServiceCatalogFields(sCatalogId)){
            if(config.User_Type__c!=null && userType!=null){
                List<String> userTypes =  parseMultiPicklist(config.User_Type__c);
                if(userTypes.contains(userType)){
                    fieldMap.put(config.Field_API_Name__c,config);
                }
            }
        }
        return fieldMap;
    }
    
    public Map<String, Date> getQuarterDateRange(String quarterInput) {
        Date startDate;
        Date endDate;
        String[] parts = quarterInput.split(' ');
        if (parts.size() != 2) {
            throw new IllegalArgumentException('Invalid input format. Expected format: "QuarterX YYYY"');
        }
        
        String quarter = parts[0];
        Integer year = Integer.valueOf(parts[1]);
        switch on quarter {
            when 'Quarter1' {
                startDate = Date.newInstance(year, 1, 1);
                endDate = Date.newInstance(year, 3, 31);
            }
            when 'Quarter2' {
                startDate = Date.newInstance(year, 4, 1);
                endDate = Date.newInstance(year, 6, 30);
            }
            when 'Quarter3' {
                startDate = Date.newInstance(year, 7, 1);
                endDate = Date.newInstance(year, 9, 30);
            }
            when 'Quarter4' {
                startDate = Date.newInstance(year, 10, 1);
                endDate = Date.newInstance(year, 12, 31);
            }
            when else {
                throw new IllegalArgumentException('Invalid quarter input');
            }
        }
        
        Map<String, Date> dateRange = new Map<String, Date>();
        dateRange.put('start', startDate);
        dateRange.put('end', endDate);
        return dateRange;
    }
    
    public static void sendEmail(String emailTemplateDeveloperName,  Id contactId, String toAddress, 
                                 List<String> ccAddresses, Id recordId, Id orgWideEmailAddressId) {
                                     // Query the email template by its developer name
                                     EmailTemplate emailTemplate = EmailTemplateService.getEmailTemplateByDeveloperName(emailTemplateDeveloperName);
                                     
                                     // Query the contact to use for the email
                                     Contact contact = [SELECT Id FROM Contact WHERE Id = :contactId LIMIT 1];
                                     
                                     if (emailTemplate != null && contact != null) {
                                         // Prepare the email message
                                         Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
                                         emailMessage.setTemplateId(emailTemplate.Id); // Set the template
                                         emailMessage.setTargetObjectId(contact.Id); // Set the recipient contact
                                         emailMessage.setWhatId(recordId); // Set the related record for merge fields
                                         
                                         // Set To, CC, and Org-Wide Address
                                         emailMessage.setToAddresses(new String[] { toAddress }); // Specify recipient email address
                                         emailMessage.setCcAddresses(ccAddresses); // Specify CC addresses
                                         emailMessage.setOrgWideEmailAddressId(orgWideEmailAddressId); // Specify Org-Wide Email Address
                                         
                                         emailMessage.setSaveAsActivity(true); // Log the email activity
                                         
                                         // Send the email
                                         Messaging.sendEmail(new Messaging.SingleEmailMessage[] { emailMessage });
                                     }
                                 }
    
    
    // Wrapper class to hold input parameters for Flow
    public class EmailRequest {
        @InvocableVariable(required=true)
        public String emailTemplateDeveloperName;
        
        @InvocableVariable
        public String queueDeveloperName;
        
        @InvocableVariable
        public List<String> toAddresses;
        
        @InvocableVariable
        public List<String> ccAddresses;
        
        @InvocableVariable
        public String recordId;
        
        @InvocableVariable
        public String orgWideEmailAddressId;
        
        
        public EmailRequest() {
            // Initialize lists to avoid null pointer exceptions
            this.toAddresses = new List<String>();
            this.ccAddresses = new List<String>();
        }
        
        // Constructor for initializing the request
        public EmailRequest(String emailTemplateDeveloperName, String queueDeveloperName, List<String> toAddresses, List<String> ccAddresses, String recordId, String orgWideEmailAddressId) {
            this.emailTemplateDeveloperName = emailTemplateDeveloperName;
            this.queueDeveloperName = queueDeveloperName;
            this.toAddresses = toAddresses;
            this.ccAddresses = ccAddresses;
            this.recordId = recordId;
            this.orgWideEmailAddressId = orgWideEmailAddressId;
        }
    }
    
    @InvocableMethod(label='Send Email to Queue or Recipient')
    public static void sendEmail(List<EmailRequest> requests) {
        try{
            List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
            
            for (EmailRequest request : requests) {
                // Query the email template by its developer name
                EmailTemplate emailTemplate = EmailTemplateService.getEmailTemplateByDeveloperName(request.emailTemplateDeveloperName);
                // Query the queue by its developer name
                List<Group> queue = [
                    SELECT Id,Email
                    FROM Group 
                    WHERE DeveloperName = :request.queueDeveloperName 
                    AND Type = 'Queue' 
                    LIMIT 1
                ];
                List<string> toAddresses=new List<string>();
                
                // Use provided toAddress if available, otherwise use queue member emails
                if (request.toAddresses != null && !request.toAddresses.isEmpty()) {
                    toAddresses=request.toAddresses;
                }
                else if(queue.size()>0 && queue[0].Email!=null){
                    toAddresses.add(queue[0].Email);
                }
                else if( queue.size()>0){
                    // Query the queue members' email addresses
                    List<User> queueMembers = [
                        SELECT Email 
                        FROM User 
                        WHERE Id IN (
                            SELECT UserOrGroupId 
                            FROM GroupMember 
                            WHERE GroupId = :queue[0].Id
                        ) AND Email != null
                    ];
                    for (User member : queueMembers) {
                        toAddresses.add(member.Email);
                    }
                }
                
                // Only proceed if there are recipients
                if (!toAddresses.isEmpty()) {
                    Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
                    emailMessage.setTemplateId(emailTemplate.Id); // Set the template
                    emailMessage.setToAddresses(toAddresses); // Set recipients
                    emailMessage.setWhatId(request.recordId); // Set the related record for merge fields
                    emailMessage.setTargetObjectId([select id from contact where email!=null limit 1].Id);
                    emailMessage.setTreatTargetObjectAsRecipient(false);
                    
                    // Set CC and Org-Wide Address
                    if (request.ccAddresses != null) {
                        emailMessage.setCcAddresses(request.ccAddresses);
                    }
                    emailMessage.setOrgWideEmailAddressId([select id, DisplayName from OrgWideEmailAddress  where Address =  :Label.BCAPP_OrgWideEmailAddress limit 1].Id); // Specify Org-Wide Email Address
                    
                    emailMessage.setSaveAsActivity(true); // Log the email activity
                    
                    // Add to list of email messages to be sent
                    emailMessages.add(emailMessage);
                }
                
            }
            
            // Send all emails
            if (!emailMessages.isEmpty()) {
                Messaging.sendEmail(emailMessages);
            }
        }
        catch(Exception e){
            
        }
    }
    
    
    public Map<String, Date> getDateRange(String objectName, String dateField,String recordTypeId) {
        // Construct the dynamic SOQL query to get the minimum and maximum dates
        String minQuery = 'SELECT MIN(' + dateField + ') minDate FROM ' + objectName;
        String maxQuery = 'SELECT MAX(' + dateField + ') maxDate FROM ' + objectName;
        
        if(!String.isBlank(recordTypeId)){
            String whereCLause = ' WHERE recordTypeId=:recordTypeId';
            minQuery += whereCLause;
            maxQuery += whereCLause;
        }
        AggregateResult minResult = Database.query(minQuery);
        AggregateResult maxResult = Database.query(maxQuery);
        
        DateTime minDateTime = (DateTime)minResult.get('minDate');
        DateTime maxDateTime = (DateTime)maxResult.get('maxDate');
        
        Date minDate = minDateTime.date();
        Date maxDate = maxDateTime.date();
        
        Map<String, Date> yearRange = new Map<String, Date>{'minDate' => minDate,'maxDate' => maxDate};
            return yearRange;
    }
    
    
    public static List<QuarterOption> getQuarterlyOptions(Date startDate, Date endDate) {
        List<QuarterOption> quarters = new List<QuarterOption>();
        
        // Calculate the start and end years
        Integer startYear = startDate.year();
        Integer endYear = endDate.year();
        
        for (Integer year = endYear; year >= startYear; year--) {
            for (Integer quarter = 1; quarter <= 4; quarter++) {
                Date quarterStartDate = getQuarterStartDate(year, quarter);
                Date quarterEndDate = getQuarterEndDate(year, quarter);
                
                if (quarterEndDate >= startDate && quarterStartDate <= endDate) {
                    String label = 'Quarter ' + quarter + ' of ' + year;
                    String value = 'Quarter' + quarter + ' ' + year;
                    quarters.add(new QuarterOption(label, value));
                }
            }
        }
        
        return quarters;
    }
    
    
    // Method to parse date string in 'DD-MMM-YYYY' format to Date object
    public Date parseDate(String dateString) {
        if (String.isEmpty(dateString)) {
            return null;
        }
        
        try {
            // Split the date string into day, month, and year
            String[] dateParts = dateString.split('-');
            if (dateParts.size() != 3) {
                throw new IllegalArgumentException('Invalid date format. Expected DD-MMM-YYYY.');
            }
            
            // Extract day, month abbreviation, and year
            Integer day = Integer.valueOf(dateParts[0]);
            String monthStr = dateParts[1];
            Integer year = Integer.valueOf(dateParts[2]);
            // Map month abbreviation to month number
            Map<String, Integer> monthMap = new Map<String, Integer>{
                'Jan' => 1, 'Feb' => 2, 'Mar' => 3, 'Apr' => 4,
                    'May' => 5, 'Jun' => 6, 'Jul' => 7, 'Aug' => 8,
                    'Sep' => 9, 'Oct' => 10, 'Nov' => 11, 'Dec' => 12
                    };
                        
                        Integer month = monthMap.get(monthStr);
            if (month == null) {
                throw new IllegalArgumentException('Invalid month abbreviation.');
            }
            
            // Create and return the Date object
            return Date.newInstance(year, month, day);
            
        } catch (Exception e) {
            throw new IllegalArgumentException('Invalid date format. Dates should be in the format DD-MMM-YYYY.');
        }
    }
    
     public Time parseFormattedTime(String inputTime) {

         if (String.isBlank(inputTime)) return null;        

        // Remove leading/trailing spaces and make uppercase
        inputTime = inputTime.trim().toUpperCase();
        // Regex for "h:mm AM/PM"
        Pattern timePattern = Pattern.compile('^(\\d{1,2}):(\\d{2})\\s?(AM|PM)$');
        Matcher matcher = timePattern.matcher(inputTime);

        if (matcher.matches()) {
            Integer hour = Integer.valueOf(matcher.group(1));
            Integer minute = Integer.valueOf(matcher.group(2));
            String meridian = matcher.group(3);
            if (meridian == 'PM' && hour < 12) {
                hour += 12;
            } else if (meridian == 'AM' && hour == 12) {
                hour = 0;
            }
           

            return Time.newInstance(hour, minute, 0, 0);

        } else {

            throw new IllegalArgumentException('Time format should be h:mm AM/PM (e.g., 4:00 PM)');

        }

    }
    
    private static Date getQuarterStartDate(Integer year, Integer quarter) {
        if (quarter == 1) {
            return Date.newInstance(year, 1, 1);
        } else if (quarter == 2) {
            return Date.newInstance(year, 4, 1);
        } else if (quarter == 3) {
            return Date.newInstance(year, 7, 1);
        } else if (quarter == 4) {
            return Date.newInstance(year, 10, 1);
        } else {
            return null;
        }
    }
    
    private static Date getQuarterEndDate(Integer year, Integer quarter) {
        if (quarter == 1) {
            return Date.newInstance(year, 3, 31);
        } else if (quarter == 2) {
            return Date.newInstance(year, 6, 30);
        } else if (quarter == 3) {
            return Date.newInstance(year, 9, 30);
        } else if (quarter == 4) {
            return Date.newInstance(year, 12, 31);
        } else {
            return null;
        }
    }
    
    public Boolean uploadFilesToCase(Id parentId, List<BCAPP_WrapperUtility.Document> filesDataList) {
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
         String fileContent = '';
        try {
            for (BCAPP_WrapperUtility.Document filesData : filesDataList) {
                
                // for (String fileName : filesData.keySet()) {
                // String fileContent = filesData.fileName;
                ContentVersion contentVersion = new ContentVersion();
                contentVersion.VersionData = filesData.fileContent;
                contentVersion.Title = filesData.fileName; 
                 if(filesData.contentType!=null){
                    fileContent = filesData.contentType;
                }
                contentVersion.PathOnClient = filesData.fileName+fileContent; 
                contentVersions.add(contentVersion);
                // }
            }
            
            insert contentVersions;
            ContentDocumentService codService = new ContentDocumentService();
            List<ContentVersion> cVs = codService.fetchContentVersion(contentVersions);
            for (ContentVersion version : cVs) {
                ContentDocumentLink link = new ContentDocumentLink();
                link.ContentDocumentId = version.ContentDocumentId;
                link.LinkedEntityId = parentId; // Link to Case record
                //  link.ShareType = 'V'; 
                link.Visibility = 'AllUsers'; 
                contentDocumentLinks.add(link);
                
            }
            insert contentDocumentLinks;
            return true;
            
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            return false;
        }
    }
    
    public String generateRandomPassword() {
        
        String charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        String randomPassword = '';
        String charToInsert = '@';
        for (Integer i = 0; i < 8; i++) {  
            Integer randomIndex = Integer.valueOf(Math.floor(Math.random() * charset.length()));
            randomPassword += charset.substring(randomIndex, randomIndex + 1);
        }
        String modifiedString = randomPassword.substring(0, 4) + charToInsert + randomPassword.substring(4);
        
        return modifiedString;
    }
    
   

    public static String encryptId(String sfId) {
        
        final String SECRET_KEY_B64 = 'oZq1x2F4vY0dTt1pQ9yWkN2mB5s4Ue8fY3r0cL7aH9I=';
    	final String IV_B64 = '9pH3wF2uLk0zV8qR5tBnXQ=';
        Blob key = EncodingUtil.base64Decode(SECRET_KEY_B64);
        Blob iv  = EncodingUtil.base64Decode(IV_B64);
        Blob data = Blob.valueOf(sfId);

        Blob encrypted = Crypto.encrypt('AES256', key, iv, data);
        return EncodingUtil.base64Encode(encrypted);
    }
    
     public static String decryptId(String encryptedSfId) {
    
        final String SECRET_KEY_B64 = 'oZq1x2F4vY0dTt1pQ9yWkN2mB5s4Ue8fY3r0cL7aH9I=';
        final String IV_B64 = '9pH3wF2uLk0zV8qR5tBnXQ=';
    
        Blob key = EncodingUtil.base64Decode(SECRET_KEY_B64);
        Blob iv  = EncodingUtil.base64Decode(IV_B64);
    
        Blob encryptedBlob = EncodingUtil.base64Decode(encryptedSfId);
    
        Blob decryptedBlob = Crypto.decrypt('AES256', key, iv, encryptedBlob);
    
        return decryptedBlob.toString();
	}

    
    
    
    public class QuarterOption {
        public String label { get; set; }
        public String value { get; set; }
        
        public QuarterOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
    
}