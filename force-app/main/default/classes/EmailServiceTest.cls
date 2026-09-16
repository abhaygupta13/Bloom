@isTest
public class EmailServiceTest {
    
    private static final string ACCOUNT_RT_DEV_NAME_PERSON_ACCOUNT { get { return 'PersonAccount'; } }
    
    @TestSetup static void testDataSetup() {
         // Test data for Project__c and related Units
        Account account = TestDataFactory.createPersonalAccount('Lastname', '01010101', '1234567890', 'test@gmail.com');
        account.CustomerType__c = 'Resident';
        INSERT account;
        
        // Step 1: Create the required setup data
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        
        
        System.runAs(testUser){
            EmailTemplate emailTemplate  = TestDataFactory.createEmailTemplate('templateName');
            insert emailTemplate;
        }
        
        //Test data for Project__c and related Units
        Project__c project = TestDataFactory.createProject('ProjectTest', Date.today() - 1);
        insert project;
        
        Unit__c u = TestDataFactory.createUnit(project.Id, 'A1-G01', 'Unassigned');
        u.Project__c = project.Id;
        u.RegistrationDate__c = Date.today();
        insert u;
        
        SalesOrder__c salesOrder = TestDataFactory.createSalesOrder(account.Id, null, null, null, u.Id, 100.00);
        salesOrder.DocumentUploadedDate__c = Date.today() - 1; 
        salesOrder.UnitRegistrationDate__c = Date.today();
        insert salesOrder;
        
        Blob testBlob = Blob.valueOf('Sample file content');
        String fileName = 'TestFile.txt';
        String title = 'Test Title';

        // Test: createContentVersion (Single)
        ContentService utility = ContentService.getInstance();
        ContentVersion cv = utility.createContentVersion(testBlob, fileName, title);
        
        DocumentType__c dc1 = TestDataFactory.createDocumentType('Sales Order', 'Unit Registration');
        INSERT dc1;
        Document__c testDocument = TestDataFactory.createDoc(dc1.Id, salesOrder.Id, null);
        testDocument.Document_Name__c = 'Unit Registration';
        testDocument.ContentDocumentId__c = cv.ContentDocumentId;
        insert testDocument;
    }

    @isTest
    static void testSendMailWithHtmlBodyWithAllParams() {
        // Setup test data
        
        List<String> emailAddresses = new List<String>{'test@example.com'};
        String subject = 'Test Subject';
        String body = 'Test Body';
        Id whatId = UserInfo.getUserId(); // Use a valid Id
        Id whoId = UserInfo.getUserId(); //UserInfo.getUserId();  // Use a valid Id
        Id orgWideEmailAddressId = null; // Use a valid Id if needed
        
        // Mock the UserService instance
        Test.startTest();
        EmailTemplate eTemplate = [SELECT Id, Subject, HtmlValue, Body,DeveloperName FROM EmailTemplate limit 1];
        EmailService emailService = EmailService.getInstance();
        emailService.sendMailWithHtmlBody(emailAddresses, subject, body, whatId, whoId, orgWideEmailAddressId);
        emailService.sendMailWithHtmlBody(emailAddresses, subject, body, orgWideEmailAddressId);
        emailService.getSingleEmailMessage(emailAddresses, subject, body, orgWideEmailAddressId);
        emailService.getSingleEmailMessage(emailAddresses, whatId, whoId, subject, body, orgWideEmailAddressId);
        emailService.getSingleEmailMessage(emailAddresses, subject, body);
        emailService.getSingleEmailMessage(emailAddresses, whatId, whoId, subject, body, orgWideEmailAddressId, emailAddresses, emailAddresses);
        emailService.getEmailTemplateById(eTemplate.id);
        emailService.getEmailTemplateByDevName(eTemplate.DeveloperName);
        emailService.getSingleEmailMessageWithoutTargetObjectAsRecipient(emailAddresses,eTemplate.id,  whatId, whoId, orgWideEmailAddressId);
        emailService.getSingleEmailMessageWithTargetObjectAsRecipient(eTemplate.id, orgWideEmailAddressId, whatId, whoId, emailAddresses, emailAddresses, emailAddresses);
        emailService.getSingleEmailMessageWithoutTargetObjectId(eTemplate.id, orgWideEmailAddressId, whatId, emailAddresses, emailAddresses, emailAddresses);
        emailService.getEmailAttachment('filename', null, 'pdf');
        emailService.customUnitTableHeader();
       // emailService.sendMailWithEmailTemplate(emailAddresses,eTemplate.id,  whatId, whoId, orgWideEmailAddressId);
        Test.stopTest();
    }
    
    @isTest
    static void unitTest1(){
        Unit__c unit = [SELECT Id, Name, Active_Sales_Order__c, Active_Sales_Order__r.Name, RegistrationDate__c, Active_Sales_Order__r.Account__r.Name FROM Unit__c];
        SalesOrder__c so = [SELECT Id, Name, Unit__r.Name, Unit__c, UnitRegistrationDate__c, Account__r.Name FROM SalesOrder__c];
        Test.startTest();                         
        EmailService emailService = EmailService.getInstance();
        String table = emailService.makeTable(unit);
        System.assertNotEquals(null, table, 'Table should created');
        table = emailService.makeTable(so);
        System.assertNotEquals(null, table, 'Table should created');
        Test.stopTest();
    }
    
    @isTest
    static void unitTest2(){
        SalesOrder__c so = [SELECT Id, Name, Unit__r.Name, Unit__c, UnitRegistrationDate__c, Account__r.Name FROM SalesOrder__c];
        ContentVersion cv = [SELECT Id, ContentDocumentId  FROM ContentVersion LIMIT 1];
        Document__c doc = [SELECT Id, Name, Document_Name__c, ContentDocumentId__c FROM Document__c WHERE Document_Name__c = 'Unit Registration' LIMIT 1];
        doc.ContentDocumentId__c = cv.ContentDocumentId;
        UPDATE doc;
        Test.startTest();                         
        EmailService emailService = EmailService.getInstance();
        emailService.getAttachments(new List<SalesOrder__c>{so}, 'Unit Registration');
        Test.stopTest();
    }
    @isTest
    static void unitTest3(){
        EmailService emailService = EmailService.getInstance();
        emailService.customUnitILTableHeader(true);
    }
     @isTest
    static void unitTest4(){
        EmailService emailService = EmailService.getInstance();
        emailService.customLeadTableHeader('test',true);
        emailService.customLeadTableHeader('test',false);
        emailService.customsalesOrderOtherChargesTableHeader();
        emailService.customPaymentPlanTableHeader();
        
    }

    @isTest
    static void testOwnerEmailsAndTemplateUtilities() {
        EmailService emailService = EmailService.getInstance();

        // Cover user owner branch
        List<String> userOwnerEmails = emailService.getOwnerEmails(UserInfo.getUserId());
        System.assert(!userOwnerEmails.isEmpty(), 'User owner email should be returned');

        // Cover queue/Group owner branch with setup DML first
        Group emailQueue = new Group(
            Name = 'EmailServiceQueue' + System.currentTimeMillis(),
            DeveloperName = 'EmailServiceQueue' + System.currentTimeMillis(),
            Type = 'Queue'
        );
        insert emailQueue;
        GroupMember gm = new GroupMember(GroupId = emailQueue.Id, UserOrGroupId = UserInfo.getUserId());
        insert gm;

        User actingUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        Contact templateContact;
        EmailTemplate templateRecord;
        Id emailFolderId;
        Id orgWideId;
        String orgWideDisplayName;
        List<Messaging.EmailFileAttachment> allAttachments;
        List<Messaging.EmailFileAttachment> namedAttachments;

        System.runAs(actingUser) {
            Account contactAccount = new Account(Name = 'Template Parent ' + System.currentTimeMillis());
            insert contactAccount;
            templateContact = new Contact(
                LastName = 'TemplateContact',
                AccountId = contactAccount.Id,
                Email = 'template-contact@example.com'
            );
            insert templateContact;

            emailFolderId = [SELECT Id FROM Folder WHERE Type = 'Email' LIMIT 1].Id;
            templateRecord = TestDataFactory.createEmailTemplate('Coverage Template');
            templateRecord.FolderId = emailFolderId;
            templateRecord.DeveloperName = 'Coverage_Template_' + String.valueOf(System.currentTimeMillis());
            templateRecord.Subject = 'Coverage Subject';
            templateRecord.HtmlValue = '<p>Hello {!Contact.LastName}</p>';
            templateRecord.Body = 'Fallback body';
            insert templateRecord;

            List<OrgWideEmailAddress> orgWideRecords = [SELECT Id, DisplayName FROM OrgWideEmailAddress LIMIT 1];
            orgWideId = orgWideRecords.isEmpty() ? null : orgWideRecords[0].Id;
            orgWideDisplayName = orgWideRecords.isEmpty() ? null : orgWideRecords[0].DisplayName;

            Test.startTest();
            emailService.sendEmailUsingTemplate(templateContact.Id, templateRecord.Id, orgWideId, new List<String>{'extra@example.com'});
            Test.stopTest();

            Map<String, Schema.RecordTypeInfo> caseRecordTypes = Schema.SObjectType.Case.getRecordTypeInfosByName();
            Id socialMediaRtId = caseRecordTypes.containsKey('Social Media') ? caseRecordTypes.get('Social Media').getRecordTypeId() : null;
            List<Schema.PicklistEntry> subStatusEntries = Case.Case_Sub_Status__c.getDescribe().getPicklistValues();
            String subStatusValue = !subStatusEntries.isEmpty() ? subStatusEntries[0].getValue() : null;
            Case caseRecord = new Case(Subject = 'Attachment Case', Status = 'New', Origin = 'Phone', Type='Question');
            if (socialMediaRtId != null) {
                caseRecord.RecordTypeId = socialMediaRtId;
            }
            if (subStatusValue != null) {
                caseRecord.put('Case_Sub_Status__c', subStatusValue);
            }
            insert caseRecord;

            ContentVersion cv = new ContentVersion(
                Title = 'CaseDoc',
                PathOnClient = 'CaseDoc.pdf',
                VersionData = Blob.valueOf('Case attachment content')
            );
            insert cv;
            ContentVersion persistedCv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

            Id docTypeId = [SELECT Id FROM DocumentType__c LIMIT 1].Id;
            Document__c caseDoc = new Document__c(
                DocumentType__c = docTypeId,
                Case__c = caseRecord.Id,
                Document_Name__c = 'CaseDoc',
                ContentDocumentId__c = persistedCv.ContentDocumentId
            );
            insert caseDoc;

            allAttachments = emailService.getCaseAttachments(caseRecord.Id);
            namedAttachments = emailService.getCaseAttachmentsByDocName(caseRecord.Id, new List<String>{'CaseDoc'});
        }

        List<String> queueOwnerEmails = emailService.getOwnerEmails(emailQueue.Id);
        System.assertEquals(1, queueOwnerEmails.size(), 'Queue member email should be captured');

        if (orgWideId != null) {
            OrgWideEmailAddress fetchedOrgWide = emailService.getOrgWideEmailAddressByDisplayName(orgWideDisplayName);
            System.assertEquals(orgWideId, fetchedOrgWide.Id, 'Display name lookup should return org-wide address');
        }

        System.assertEquals(1, allAttachments.size(), 'All case attachments should include uploaded document');
        System.assertEquals(1, namedAttachments.size(), 'Filtered attachments should include matching doc name');

        // Cover custom unit header without quarterly reminder
        emailService.customUnitILTableHeader(false);
    }

    @isTest
    static void testTableAndCsvGenerators() {
        EmailService emailService = EmailService.getInstance();

        SalesOrder__c baseSalesOrder = [
            SELECT Id, Name, Account__c, SellingPrice__c, Account__r.Name, Unit__c, Unit__r.Name, Unit__r.Project__c, Unit__r.Project__r.Name, Unit__r.ADMPlotNumber__c, OwnerSharePercentage__c
            FROM SalesOrder__c
            LIMIT 1
        ];

        String projectName = baseSalesOrder.Unit__r != null && baseSalesOrder.Unit__r.Project__r != null
            ? baseSalesOrder.Unit__r.Project__r.Name
            : 'Project';
        String unitName = baseSalesOrder.Unit__r != null ? baseSalesOrder.Unit__r.Name : 'Unit';
        String accountName = baseSalesOrder.Account__r != null ? baseSalesOrder.Account__r.Name : 'Account';
        String salesOrderName = String.isNotBlank(baseSalesOrder.Name) ? baseSalesOrder.Name : 'Sales Order';

        String installmentJson = JSON.serialize(new Map<String, Object>{
            'Due_Date__c' => Date.today(),
            'InstallmentNumber__c' => 1,
            'Description__c' => 'Coverage Installment',
            'Type__c' => 'Quarterly',
            'PendingAmount__c' => 0,
            'pendingamount' => 0,
            'SalesOrder__c' => baseSalesOrder.Id,
            'SalesOrder__r' => new Map<String, Object>{
                'attributes' => new Map<String, Object>{'type' => 'SalesOrder__c'},
                'Unit__r' => new Map<String, Object>{
                    'attributes' => new Map<String, Object>{'type' => 'Unit__c'},
                    'Project__r' => new Map<String, Object>{'Name' => projectName},
                    'Name' => unitName
                },
                'Account__r' => new Map<String, Object>{'Name' => accountName},
                'Name' => salesOrderName
            }
        });
        InstallmentLines__c ilWithRel = (InstallmentLines__c) JSON.deserialize(installmentJson, InstallmentLines__c.class);

        String socJson = JSON.serialize(new Map<String, Object>{
            'Id' => baseSalesOrder.Id,
            'Name' => 'Charge Coverage',
            'SalesOrder__c' => baseSalesOrder.Id,
            'SalesOrder__r' => new Map<String, Object>{'attributes' => new Map<String, Object>{'type' => 'SalesOrder__c'}, 'Name' => salesOrderName},
            'Account__r' => new Map<String, Object>{'Name' => accountName},
            'Amount__c' => 0,
            'PendingAmount__c' => 0,
            'pendingamount' => 0,
            'Due_Date__c' => Date.today()
        });
        SalesOrderOtherCharges__c socWithRel = (SalesOrderOtherCharges__c) JSON.deserialize(socJson, SalesOrderOtherCharges__c.class);

        String piJson = JSON.serialize(new Map<String, Object>{
            'Id' => baseSalesOrder.Id,
            'Name' => 'PI Coverage',
            'Payment_Plan_Name__c' => 'Coverage Plan',
            'InstallmentNumber__c' => 1,
            'InstallmentPercentage__c' => 10,
            'InstallmentDate__c' => Date.today(),
            'RevisedDate__c' => Date.today().addDays(5)
        });
        PaymentInstallments__c piWithRel = (PaymentInstallments__c) JSON.deserialize(piJson, PaymentInstallments__c.class);

        User ownerUser = [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId()];
        String leadJson = JSON.serialize(new Map<String, Object>{
            'LeadNumber__c' => 'LN-001',
            'Name' => 'Coverage Lead',
            'Status' => 'New',
            'LeadManagerStatus__c' => 'New',
            'Owner' => new Map<String, Object>{
                'attributes' => new Map<String, Object>{'type' => 'User'},
                'Name' => ownerUser.Name
            },
            'OwnerId' => ownerUser.Id,
                'CreatedDate' => Date.Today(),
            'LeadManagerAssignedDate__c' => System.now()
        });
        Lead leadWithRel = (Lead) JSON.deserialize(leadJson, Lead.class);

        emailService.makeTable(ilWithRel, true);
        emailService.makeTable(ilWithRel, false);
        emailService.makeTable(socWithRel);
        emailService.makeTable(piWithRel);
        emailService.makeTable(leadWithRel, true);
        emailService.makeTable(leadWithRel, false);

        emailService.generateCSV(new List<InstallmentLines__c>{ ilWithRel }, true);
        emailService.generateCSV(new List<InstallmentLines__c>{ ilWithRel }, false);
        emailService.generateCSV(new List<SalesOrderOtherCharges__c>{ socWithRel });
        emailService.generateCSV(new List<Lead>{ leadWithRel });
        emailService.generateCSV(new List<Lead>());
        emailService.getEmailTemplatesByName(new Set<String>{'Customer Not Available'});
        emailService.makeTable(1, baseSalesOrder, 'Test');
    }
}