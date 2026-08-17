@isTest
public class BulkEmailControllerTest {
    
    @isTest
    static void testGetEmailTemplateFolders() {
        List<Folder> emailTemplateFolders = [SELECT Id, Name FROM Folder WHERE Type = 'EmailTemplate' LIMIT 1];
        Test.startTest();
        BulkEmailController.getEmailTemplatesDefault();
        Test.stopTest();
    }
    
    @isTest
    static void testGetEmailTemplates() {
        List<Folder> emailTemplateFolders = [SELECT Id FROM Folder WHERE Type = 'EmailTemplate' LIMIT 1];
        if (emailTemplateFolders.isEmpty()) {
            System.assert(false, 'No EmailTemplate folders available for testing.');
        }
        List<EmailTemplate> templates = [SELECT Id FROM EmailTemplate WHERE FolderId = :emailTemplateFolders[0].Id LIMIT 1];
        if (templates.isEmpty()) {
            System.assert(false, 'No Email Templates available for testing.');
        }
        
        Test.startTest();
        Map<Id, EmailTemplate> templateMap = BulkEmailController.getEmailTemplates(emailTemplateFolders[0].Id);
        Test.stopTest();
        
        System.assertNotEquals(null, templateMap, 'Template map should not be null.');
        System.assert(templateMap.containsKey(templates[0].Id), 'Template map should include the existing template.');
    }
    
    @isTest
    static void testGetReportFolders() {
        // Query existing report folders
        List<Folder> reportFolders = [SELECT Id, Name FROM Folder WHERE Type = 'Report' LIMIT 1];
        if (reportFolders.isEmpty()) {
            System.assert(false, 'No Report folders available for testing.');
        }
        
        Test.startTest();
        BulkEmailController.getReportDetailsDefault();
        Test.stopTest();
    }
    
    @isTest
    static void testGetOrgWideEmailAddress() {
        Test.startTest();
        Map<Id, String> emailMap = BulkEmailController.getOrgWideEmailAddress();
        Test.stopTest();
    }
    
    @isTest
    static void testgetSampleCSVFile() {
        Test.startTest();
        Map<String, String> emailMap = BulkEmailController.getSampleCSVFile();
        Test.stopTest();
    }
    
    @isTest
    static void testSendBulkEmails() {
        EmailTemplate emailTemplate  = TestDataFactory.createEmailTemplate('templateName');
        insert emailTemplate;
        Map<Id, String> emailMap = BulkEmailController.getOrgWideEmailAddress();
        String csvContent = 'test1@example.com\ntest2@example.com\ninvalid-email\n';
        
        String base64EncodedCSV = EncodingUtil.base64Encode(Blob.valueOf(csvContent));
        List<Id> emailsList = new List<Id>();
        emailsList.addAll(emailMap.keySet());
        // Mock data
        String emailBody = '<p>This is a test email body.</p>';
        String emailSubject = 'Test Email Subject';
        String fromEmailAddress = emailsList[0];
        String reportId = null; 
        List<String> attachmentNames = new List<String>{ 'TestAttachment.txt' };
            List<String> attachmentContents = new List<String>{ EncodingUtil.base64Encode(Blob.valueOf('Test Attachment Content')) };
                List<Contact> contacts = [SELECT Id, Email FROM Contact WHERE Email != null LIMIT 1];
        
        List<String> emailAddresses = new List<String>{ 'test@test.com'};
            
            Test.startTest();
        try {
            BulkEmailController.sendBulkEmails(base64EncodedCSV, emailBody, emailSubject, fromEmailAddress, reportId, attachmentNames, attachmentContents, emailTemplate.Id);
        } catch (Exception e) {
            System.debug('Error while sending emails: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest(SeeAllData='true')
    static void testGetEmailsFromReport() {
        Map<Id, Report> reports = BulkEmailController.getReportDetailsDefault();
        List<Id> lstReports = new List<Id>();
        lstReports.addAll(reports.keySet());
        
        Test.startTest();
        Map<String, String> emails = BulkEmailController.getEmailsFromReport(lstReports[0]);
        Test.stopTest();
    }
}