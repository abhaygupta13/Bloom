@isTest
public class UtilitiesTest {
    @isTest static void UtilitiesTestMethod(){
        
        Set<id>userIds = new Set<id>();
        Set<String> messageNames = new Set<String>();
        messageNames.add('test');
        Set<String>profileNames = new Set<String>();
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = testAccount.Id);
        insert testContact;
        
        Project__c testProject=new Project__c(
            Name='Test Project'
        );
        insert testProject;
       
Opportunity tempOpp=new Opportunity(
            Name='tempOpp',
            StageName='New',
            CloseDate=system.today(),
            LeadChannel__c='Walk in',
            AccountId=testAccount.Id,
           WinReason__c='Loyalty'
        );
        insert tempOpp;
                
        
        List<String> toRecipients = new List<String>{'recipient1@example.com'};
            List<String> bccRecipients = new List<String>{'bcc1@example.com'};
                List<String> ccRecipients = new List<String>{'cc1@example.com'};
                    
                    Profile profile = [SELECT Id,Name FROM Profile WHERE Name = 'Standard User'];
        profileNames.add(profile.Name);
        User testUser = new User(
            Alias = 'standt',
            Email = 'standarduser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'standarduser@testorg9847588474.com'
        );
        insert testUser;
        userIds.add(testUser.id);
        
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName('TestAttachment.txt');
        attachment.setBody(Blob.valueOf('Test attachment body'));
        
        // Call the method being tested
        Utilities.getEmailInstance(
            testContact.Id, null, testAccount.Id, toRecipients, bccRecipients, ccRecipients,
            'Test Subject', 'Test Body', '<html><body>Test HTML Body</body></html>',
            new List<Messaging.EmailFileAttachment>{attachment}, null
        );
        
        Messaging.SingleEmailMessage testEmail = new Messaging.SingleEmailMessage();
        testEmail.setToAddresses(new List<String>{'test@example.com'});
        testEmail.setSubject('Test Subject');
        testEmail.setPlainTextBody('This is a test email.');
        
        // Add the test email to a list
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        emailList.add(testEmail);
        
        // Call the method under test
        Utilities.sendEmail(emailList);
        
        
        
        ContentVersion cvObj = new ContentVersion();
        cvObj.Title = 'Test File';
        cvObj.VersionData = Blob.valueOf('Test data');
        cvObj.PathOnClient='H';
        insert cvObj;
       
        Decimal testAmount1 = 12345.67;
        String testCurrencyUnit = 'Dollars';
        String testCurrencySubUnit = 'Cents';
        
        
         Utilities.amountInWords(testAmount1, testCurrencyUnit, testCurrencySubUnit);
        Utilities.setEmailFileAtt(cvObj);
        Utilities.NumberToTextconvert(4);
        Utilities.prepareBuildingsNames(testProject.id);
        Utilities.getSystemMessages( messageNames);
        Utilities.getSystemMessages('test message');
        Utilities.getTimer('test');
        Utilities.getOrgWideEmailAddressId();
        Utilities.getSystemInformation('Account');
        
        Utilities.getCurrentUserProfileName();
        Utilities.getRecordTypeId('Account','Person Account');
        Utilities.getRecordTypeId('Account','Person Account');
        Utilities.getConstantValue('Test');
        Utilities.getConstant('Test');
        Utilities.getPicklistValues('Lead','Status');
        Utilities.getRecordCount('Test',5);
        Utilities.getRecordCount('Test',0);
        Utilities.getRecordCount('Test',null);
        Utilities.getLoggedInUserDetail();
         Utilities.getVFDomainURL();
        
        Utilities.createLogAudit(testAccount.id,'test');
        Utilities.getValidationFields();
       
        Utilities.getOfferLineService();
         Utilities.genericValidationMsgGenerator(testAccount.id);
        Utilities.OppBlackListEirateValidation(tempOpp.id);
       
        
    }
    
}