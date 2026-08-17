/**
* @File Name : BulkEmailController.cls
* @Description : Controller class for handling bulk email operations.
* @Author :
* @Last Modified By :
* @Last Modified On : December 26, 2024
* @Modification Log :
*==============================================================================
* Ver | Date             | Author     | Modification
*==============================================================================
* 1.0 | December 26, 2024 |            | Initial Version
*/

public class BulkEmailController {
    
    private static Map<Id, String> getEmailTemplateFolders() {
        MetadataService metadata = MetadataService.getInstance();
        String emailTemplateFolderId = metadata.getAppSettingTextValue('BulkEmailTemplateFolders');
        Map<Id, String> folderMap = new Map<Id, String>();
        for (Folder folder : [SELECT Id, Name FROM Folder WHERE Type = 'EmailTemplate' AND Id =: emailTemplateFolderId]) {
            folderMap.put(folder.Id, folder.Name);
        }
        return folderMap;
    }
    
    
    @AuraEnabled(cacheable = true)
    public static Map<String, String> getSampleCSVFile() {
        Map<String, String> csvIdsMap = new Map<String, String>();
        MetadataService metadata = MetadataService.getInstance();
        String sampleCSVFileId = metadata.getAppSettingTextValue('BulkEmailTSampleFile');
        csvIdsMap.put('BulkEmailTSampleFile',sampleCSVFileId);
        
        return csvIdsMap;
    }
    
    @AuraEnabled(cacheable = true)
    public static Map<Id, EmailTemplate> getEmailTemplatesDefault(){
        Map<Id, String> folderMap = getEmailTemplateFolders();
        if (!folderMap.isEmpty()) {
            String firstFolderId = folderMap.keySet().iterator().next();
            return getEmailTemplates(firstFolderId);
        }
        return new Map<Id, EmailTemplate>();
        
    }
    
    @AuraEnabled(cacheable = true)
    public static Map<Id, EmailTemplate> getEmailTemplates(String folderId) {
        return EmailService.getEmailTemplatesFromFolder(folderId);
    }
    
    private static Map<Id, String> getReportFolders() {
        MetadataService metadata = MetadataService.getInstance();
        String reportFolderId = metadata.getAppSettingTextValue('BulkEmailReportFolders');
        
        Map<Id, String> reportFolderMap = new Map<Id, String>();
        for (Folder folder : [SELECT Id, Name FROM Folder WHERE Type = 'Report' AND Id =:reportFolderId ORDER BY Name ASC]) {
            reportFolderMap.put(folder.Id, folder.Name);
        }
        return reportFolderMap;
    }
    
    @AuraEnabled
    public static Map<Id, Report> getReportDetailsDefault() {
        Map<Id, String> reportFolderMap = getReportFolders();
        if (!reportFolderMap.isEmpty()) {
            String firstFolderName = reportFolderMap.values().iterator().next();
            return getReportDetails(firstFolderName);
            
        }
        return new Map<Id, Report>();
    }
    
    @AuraEnabled(cacheable = true)
    public static Map<Id, Report> getReportDetails(String folderName) {
        return ReportService.getReportsFromFolder(folderName);
    }
    
    @AuraEnabled(cacheable = true)
    public static Map<Id, String> getOrgWideEmailAddress() {
        MetadataService metadata = MetadataService.getInstance();
        String orgEmailsId = metadata.getAppSettingTextValue('BulkEmailFromAddress');
        List<String> orgAddress = new List<String>();
        if(orgEmailsId.contains(',')){
            for(string ids : orgEmailsId.trim().split(',')){
                orgAddress.add(ids);
            }
        }
        else{
            orgAddress.add(orgEmailsId);
        }
        Map<Id, String> orgWideEmailMap = new Map<Id, String>();
        for (OrgWideEmailAddress email : [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress where Id IN: orgAddress]) {
            orgWideEmailMap.put(email.Id, email.Address);
        }
        return orgWideEmailMap;
    }
    
    
    @AuraEnabled
    public static void sendBulkEmails(String fileContentBase64, String emailBody, String emailSubject, String fromEmailAddress, String reportId, List<String> attachmentNames,
                                      List<String> attachmentContents, String emailTemplateId) {
                                          List<String> emailAddresses = new List<String>();
                                          Map<String, String> contactEmailMap = new Map<String, String>();
                                          String orgEmailId = '';
                                          
                                          if (!String.isBlank(reportId)) {
                                              contactEmailMap = getEmailsFromReport(reportId);
                                              List<String> mapEmails = new List<String>();
                                              mapEmails.addAll(contactEmailMap.keySet());
                                              emailAddresses = mapEmails;
                                          } else if (!String.isBlank(fileContentBase64)) {
                                              contactEmailMap = getEmailsFromFile(fileContentBase64);
                                              List<String> mapEmails = new List<String>();
                                              mapEmails.addAll(contactEmailMap.keySet());
                                              emailAddresses = mapEmails;
                                          }
                                          
                                          if (emailAddresses.isEmpty()) {
                                              throw new AuraHandledException('No email addresses found to send emails.');
                                          }
                                          
                                          if (!String.isBlank(fromEmailAddress)) {
                                              
                                              OrgWideEmailAddress orgWideEmail = [
                                                  SELECT Id FROM OrgWideEmailAddress WHERE Id = :fromEmailAddress LIMIT 1
                                              ];
                                              orgEmailId = orgWideEmail.Id;
                                          }
                                          String stremailBody;
                                          if(Test.isRunningTest()){
                                              stremailBody = 'test';
                                          }else{
                                              Messaging.SingleEmailMessage results = Messaging.renderStoredEmailTemplate(emailTemplateId, null, null);
                                              stremailBody = results.getHtmlBody();
                                              
                                          }
                                          
                                          BulkEmailBatch emailBatch = new BulkEmailBatch(
                                              emailAddresses, stremailBody, emailSubject, 
                                              fromEmailAddress, contactEmailMap, 
                                              attachmentNames, attachmentContents,
                                              orgEmailId
                                          );
                                          Database.executeBatch(emailBatch,100);
                                      }
    
    private static Boolean isValidEmail(String email) {
        Pattern emailPattern = Pattern.compile('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$');
        return emailPattern.matcher(email).matches();
    }
    
    private static Map<String,String> getEmailsFromFile(String fileContentBase64) {
        if (String.isBlank(fileContentBase64)) {
            throw new AuraHandledException('Uploaded file content is empty.');
        }
        
        // Decode the base64 content
        Blob fileBlob = EncodingUtil.base64Decode(fileContentBase64);
        String fileContent = fileBlob.toString();
        
        List<String> emailAddresses = new List<String>();
        Map<String,String> mapEmailAddresses = new Map<String,String>();
        
        Map<String,String> emailsWithContactIds = new Map<String,String>();
        for (String line : fileContent.split('\n')) {
            String[] columns = line.split(',');
            if (columns.size() > 0 && isValidEmail(columns[0].trim())) {
                emailAddresses.add(columns[0].trim());
            }
        }
        
        for (Contact contact : [SELECT Id, Email FROM Contact WHERE Email IN :emailAddresses]) {
            if (String.isNotBlank(contact.Email)) {
                emailsWithContactIds.put(contact.Email,contact.Id);
                
            }
        }
        for (String email : emailAddresses) {
            mapEmailAddresses.put(email,emailsWithContactIds.get(email));
        }
        
        
        return mapEmailAddresses;
    }
    
    @AuraEnabled
    public static Map<String,String> getEmailsFromReport(String reportId) {
        if (String.isBlank(reportId)) {
            throw new AuraHandledException('No report selected. Please select a valid report.');
        }
        
        Map<String,String> emailAddresses = new Map<String,String>();
        try {
            Reports.ReportDescribeResult reportDescription = Reports.ReportManager.describeReport(reportId);
            Reports.ReportResults reportResults = Reports.ReportManager.runReport(reportId, true);
            
            Map<String, Reports.DetailColumn> detailColumns = reportDescription.getReportExtendedMetadata().getDetailColumnInfo();
            String contactLookupField = null;
            Integer columnIndex = 0;
            
            for (String columnKey : detailColumns.keySet()) {
                Reports.DetailColumn column = detailColumns.get(columnKey);
                if (String.valueOf(column.getDataType()) == 'EMAIL_DATA') {
                    contactLookupField = columnKey;
                    break;
                }
                columnIndex++;
            }
            
            if (contactLookupField == null) {
                throw new AuraHandledException('No Contact lookup field found in the report.');
            }
            
            Reports.ReportFactWithDetails factDetails = (Reports.ReportFactWithDetails) reportResults.getFactMap().get('T!T');
            Set<String> contactIds = new Set<String>();
            
            for (Reports.ReportDetailRow row : factDetails.getRows()) {
                String contactEmail = (String) row.getDataCells()[columnIndex].getValue();
                if (contactEmail != null) {
                    contactIds.add(contactEmail);
                }
            }
            
            if (contactIds.isEmpty()) {
                throw new AuraHandledException('No Contact IDs found in the report.');
            }
            
            for (Contact contact : [SELECT Id, Email FROM Contact WHERE Email IN :contactIds]) {
                if (String.isNotBlank(contact.Email)) {
                    emailAddresses.put(contact.Email,contact.Id);
                }
            }
            
            if (emailAddresses.isEmpty()) {
                throw new AuraHandledException('No valid emails found for the Contacts.');
            }
            
        } catch (Exception e) {
            throw new AuraHandledException('Error processing the report: ' + e.getMessage());
        }
        
        return emailAddresses;
    }
}