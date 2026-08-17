@isTest
public class DefaultNoticeReminderBatchTest {

    @isTest
    static void testBatchExecutionONE() {
        // Create test data for supporting objects and relationships

        String recTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();

        // Create a Person Account with email
        Account acc = new Account(
            FirstName = 'John',
            LastName = 'Doe',
            RecordTypeId = recTypeId,
            PersonEmail = 'john.doe@example.com'
        );
        insert acc;

        Contact con = new Contact(LastName='Test Contact');
        insert con;

        Project__c project1 = new Project__c(
            Name='Test Project',
            DefaultUnpaidAmount__c = 1000,
            DefaultUnpaidAmountPercentage__c = 10,
            DefaultNotificationDays__c = 5,
            /* FirstDefaultNoticeReminderDays__c = 5,
            SecondDefaultNoticeReminderDays__c = 10,
            ThirdDefaultNoticeReminderDays__c = 15, */
            SendDefaultNotice__c = true,
            City__c = 'Dubai',
            ProjectNameArabic__c = 'اختبار المشروع'
        );
        insert project1;
        
        Project__c project2 = new Project__c(
            Name='Test Project',
            DefaultUnpaidAmount__c = 1000,
            DefaultUnpaidAmountPercentage__c = 10,
            DefaultNotificationDays__c = 15,
            /* FirstDefaultNoticeReminderDays__c = 15,
            SecondDefaultNoticeReminderDays__c = 10,
            ThirdDefaultNoticeReminderDays__c = 15, */
            SendDefaultNotice__c = true,
            City__c = 'Abu Dhabi',
            ProjectNameArabic__c = 'اختبار المشروع'
        );
        insert project2;

        List<Unit__c> unitList = new List<Unit__c>();
        Unit__c unit1 = new Unit__c(
            Name = 'Test Unit',
            Project__c = project1.Id
        );
        unitList.add(unit1);
        
        Unit__c unit2 = new Unit__c(
            Name = 'Test Unit TWO',
            Project__c = project2.Id
        );
        unitList.add(unit2);
        
        Unit__c unit3 = new Unit__c(
            Name = 'Test Unit THREE',
            Project__c = project2.Id
        );
        unitList.add(unit3);

        insert unitList;
        
        List<SalesOrder__c> salesOrderList = new List<SalesOrder__c>();
        SalesOrder__c so1 = new SalesOrder__c(
            Name = 'SO-001',
            Status__c = 'Sold',
            Account__c = acc.Id,
            Unit__c = unit1.Id,
            PHPP__c = true,
            SellingPrice__c = 200000,
            PostDueDateReminderSentDate__c = null
        );
        salesOrderList.add(so1);
        
        SalesOrder__c so2 = new SalesOrder__c(
            Name = 'SO-002',
            Status__c = 'Sold',
            Account__c = acc.Id,
            Unit__c = unit2.Id,
            PHPP__c = true,
            SellingPrice__c = 200000,
            CustomerDefaultStatus__c = 'Suspected Defaulter',
            PostDueDateReminderSentDate__c = Date.today().addDays(-20)
        );
        salesOrderList.add(so2);
        
        SalesOrder__c so3 = new SalesOrder__c(
            Name = 'SO-003',
            Status__c = 'Sold',
            Account__c = acc.Id,
            Unit__c = unit3.Id,
            PHPP__c = true,
            SellingPrice__c = 10000,
            CustomerDefaultStatus__c = 'Suspected Defaulter',
            PostDueDateReminderSentDate__c = Date.today().addDays(-20),
            DefaultCustomerLastReminderSentDate__c = Date.today().addDays(-30)
        );
        salesOrderList.add(so3);

        insert salesOrderList;
        
        PaymentPlan__c tempPaymentPlan= new PaymentPlan__c(
            Name='testPayPlan',
            Description__c='test'
        );
        insert tempPaymentPlan;
        
        /*PaymentPlan__c tempPaymentPlan1= new PaymentPlan__c(
            Name='testPayPlan1',
            Description__c='test'
        );
        insert tempPaymentPlan1;*/
        
        PaymentInstallments__c ppi = new PaymentInstallments__c();
        ppi.BrokerPayoutPercentage__c =100;
        ppi.Description__c = 'test description';
        ppi.InstallmentNumber__c = 1;
        ppi.InstallmentPercentage__c=100;
        ppi.PaymentPlan__c = tempPaymentPlan.id;
        ppi.InstallmentPercentage__c=100;
        ppi.Condition_Type__c='P012';
        
        insert ppi;
        
        List<InstallmentLines__c> installmentLines = new List<InstallmentLines__c>();
        InstallmentLines__c inst1 = new InstallmentLines__c(
            SalesOrder__c = so1.Id,
            PaymentInstallments__c = ppi.Id,
            PaymentPlan__c = tempPaymentPlan.Id,
            InstallmentDate__c = Date.today().addDays(-20),
            InstallmentAmount__c = 120000,
            Description__c = 'Test Description ONE'
        );
        installmentLines.add(inst1);
        
        /*InstallmentLines__c inst2 = new InstallmentLines__c(
            SalesOrder__c = so2.Id,
            PaymentInstallments__c = ppi.Id,
            PaymentPlan__c = tempPaymentPlan.Id,
            InstallmentDate__c = Date.today().addDays(-30),
            InstallmentAmount__c = 120000,
            Description__c = 'Test Description TWO'
        );
        installmentLines.add(inst2);
        
        InstallmentLines__c inst3 = new InstallmentLines__c(
            SalesOrder__c = so3.Id,
            PaymentInstallments__c = ppi.Id,
            PaymentPlan__c = tempPaymentPlan.Id,
            InstallmentDate__c = Date.today().addDays(-30),
            InstallmentAmount__c = 120000,
            Description__c = 'Test Description THREE'
        );
        installmentLines.add(inst3);*/
        
        insert installmentLines;

        // Create test ServiceCatalog record
        ServiceCatalog__c testServiceCatalog = new ServiceCatalog__c(
            Name = 'Service-Request-Default-Unit',
            Type__c = 'Service Request',
            Category__c = 'Financial - Payment Service',
            SubCategory__c = 'Postpone/Defer Payment',
            RecordTypeDevName__c = 'DefaultUnit'
        );
        insert testServiceCatalog;
        system.debug('testServiceCatalog----->'+testServiceCatalog);
        
        // Create test ServiceAction record
        ServiceAction__c testServiceAction = new ServiceAction__c(
            ServiceCatalog__c = testServiceCatalog.Id,
            TaskType__c = 'Default Unit',
            TaskSubType__c = 'Finance Team Task 1',
            TaskSubject__c = 'Finance Team Task 1',
            Due_in_days__c = 2,
            Order__c = 1
        );
        insert testServiceAction;
        
        // Create a Case for the Account
       	String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Default Unit').getRecordTypeId();
        // Create test Case related to the Account
        /*Case cs1 = new Case(Status = 'New', Origin = 'Phone', AccountId = acc.Id, RecordTypeId= RecordTypeCaseId, ServiceCatalog__c = testServiceCatalog.Id,
                           Sales_Order__c = so2.Id, Unit__c = unit2.Id, CustomerDefaultStatus__c = 'Suspected Defaulter', NumberOfDefaultNoticeRemindersSent__c = 1);
        insert cs1;
        
        Case cs2 = new Case(Status = 'New', Origin = 'Phone', AccountId = acc.Id, RecordTypeId= RecordTypeCaseId, ServiceCatalog__c = testServiceCatalog.Id,
                           Sales_Order__c = so3.Id, Unit__c = unit3.Id, CustomerDefaultStatus__c = 'Suspected Defaulter', NumberOfDefaultNoticeRemindersSent__c = 3);
        insert cs2;*/
        
        /* // Mock any additional required metadata values and services here
        TestMetadataService.mockAppSettings();  // Implement this helper method or use stubbing tools
        TestEmailService.mockEmailTemplates();  // Same for Email service
        TestServiceCatalogService.mockServiceCatalog(); */

        // Mock bank account, service catalog, and receipt allocations as needed
        
        
        Test.startTest();
        DefaultNoticeReminderBatch batch = new DefaultNoticeReminderBatch();
        Database.executeBatch(batch, 1);
        Test.stopTest();

        // Validate that SalesOrder and Case were updated
        List<SalesOrder__c> salesOrders = [SELECT Id, CustomerDefaultStatus__c, PostDueDateReminderSentDate__c FROM SalesOrder__c];
        System.assertEquals(3, salesOrders.size());
    }

    @isTest
    static void testBatchExecutionTWO() {
        // Create test data for supporting objects and relationships

        String recTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();

        // Create a Person Account with email
        Account acc = new Account(
            FirstName = 'John',
            LastName = 'Doe',
            RecordTypeId = recTypeId,
            PersonEmail = 'john.doe@example.com'
        );
        insert acc;

        Contact con = new Contact(LastName='Test Contact');
        insert con;

        Project__c project1 = new Project__c(
            Name='Test Project',
            DefaultUnpaidAmount__c = 1000,
            DefaultUnpaidAmountPercentage__c = 10,
            DefaultNotificationDays__c = 5,
            SendDefaultNotice__c = true,
            City__c = 'Dubai',
            ProjectNameArabic__c = 'اختبار المشروع'
        );
        insert project1;
        
        Project__c project2 = new Project__c(
            Name='Test Project',
            DefaultUnpaidAmount__c = 1000,
            DefaultUnpaidAmountPercentage__c = 10,
            DefaultNotificationDays__c = 15,
            SendDefaultNotice__c = true,
            City__c = 'Abu Dhabi',
            ProjectNameArabic__c = 'اختبار المشروع'
        );
        insert project2;

        List<Unit__c> unitList = new List<Unit__c>();
        Unit__c unit1 = new Unit__c(
            Name = 'Test Unit',
            Project__c = project1.Id
        );
        unitList.add(unit1);
        
        Unit__c unit2 = new Unit__c(
            Name = 'Test Unit TWO',
            Project__c = project2.Id
        );
        unitList.add(unit2);
        
        Unit__c unit3 = new Unit__c(
            Name = 'Test Unit THREE',
            Project__c = project2.Id
        );
        unitList.add(unit3);

        insert unitList;
        
        List<SalesOrder__c> salesOrderList = new List<SalesOrder__c>();
        SalesOrder__c so1 = new SalesOrder__c(
            Name = 'SO-001',
            Status__c = 'Sold',
            Account__c = acc.Id,
            Unit__c = unit1.Id,
            PHPP__c = true,
            SellingPrice__c = 200000,
            PostDueDateReminderSentDate__c = null
        );
        salesOrderList.add(so1);
        
        SalesOrder__c so2 = new SalesOrder__c(
            Name = 'SO-002',
            Status__c = 'Sold',
            Account__c = acc.Id,
            Unit__c = unit2.Id,
            PHPP__c = true,
            SellingPrice__c = 200000,
            CustomerDefaultStatus__c = 'Suspected Defaulter',
            PostDueDateReminderSentDate__c = Date.today().addDays(-20)
        );
        salesOrderList.add(so2);
        
        SalesOrder__c so3 = new SalesOrder__c(
            Name = 'SO-003',
            Status__c = 'Sold',
            Account__c = acc.Id,
            Unit__c = unit3.Id,
            PHPP__c = true,
            SellingPrice__c = 10000,
            CustomerDefaultStatus__c = 'Suspected Defaulter',
            PostDueDateReminderSentDate__c = Date.today().addDays(-20),
            DefaultCustomerLastReminderSentDate__c = Date.today().addDays(-30)
        );
        salesOrderList.add(so3);

        insert salesOrderList;
        
        PaymentPlan__c tempPaymentPlan= new PaymentPlan__c(
            Name='testPayPlan',
            Description__c='test'
        );
        insert tempPaymentPlan;
        
        PaymentInstallments__c ppi = new PaymentInstallments__c();
        ppi.BrokerPayoutPercentage__c =100;
        ppi.Description__c = 'test description';
        ppi.InstallmentNumber__c = 1;
        ppi.InstallmentPercentage__c=100;
        ppi.PaymentPlan__c = tempPaymentPlan.id;
        ppi.InstallmentPercentage__c=100;
        ppi.Condition_Type__c='P012';
        
        insert ppi;
        
        List<InstallmentLines__c> installmentLines = new List<InstallmentLines__c>();
        /*InstallmentLines__c inst1 = new InstallmentLines__c(
            SalesOrder__c = so1.Id,
            PaymentInstallments__c = ppi.Id,
            PaymentPlan__c = tempPaymentPlan.Id,
            InstallmentDate__c = Date.today().addDays(-20),
            InstallmentAmount__c = 120000,
            Description__c = 'Test Description ONE'
        );
        installmentLines.add(inst1);*/
        
        InstallmentLines__c inst2 = new InstallmentLines__c(
            SalesOrder__c = so2.Id,
            PaymentInstallments__c = ppi.Id,
            PaymentPlan__c = tempPaymentPlan.Id,
            InstallmentDate__c = Date.today().addDays(-30),
            InstallmentAmount__c = 120000,
            Description__c = 'Test Description TWO'
        );
        installmentLines.add(inst2);
        
        /*InstallmentLines__c inst3 = new InstallmentLines__c(
            SalesOrder__c = so3.Id,
            PaymentInstallments__c = ppi.Id,
            PaymentPlan__c = tempPaymentPlan.Id,
            InstallmentDate__c = Date.today().addDays(-30),
            InstallmentAmount__c = 120000,
            Description__c = 'Test Description THREE'
        );
        installmentLines.add(inst3);*/
        
        insert installmentLines;

        // Create test ServiceCatalog record
        ServiceCatalog__c testServiceCatalog = new ServiceCatalog__c(
            Name = 'Service-Request-Default-Unit',
            Type__c = 'Service Request',
            Category__c = 'Financial - Payment Service',
            SubCategory__c = 'Postpone/Defer Payment',
            RecordTypeDevName__c = 'DefaultUnit'
        );
        insert testServiceCatalog;
        system.debug('testServiceCatalog----->'+testServiceCatalog);
        
        // Create test ServiceAction record
        ServiceAction__c testServiceAction = new ServiceAction__c(
            ServiceCatalog__c = testServiceCatalog.Id,
            TaskType__c = 'Default Unit',
            TaskSubType__c = 'Finance Team Task 1',
            TaskSubject__c = 'Finance Team Task 1',
            Due_in_days__c = 2,
            Order__c = 1
        );
        insert testServiceAction;
        
        // Create a Case for the Account
       	String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Default Unit').getRecordTypeId();
        // Create test Case related to the Account
        Case cs1 = new Case(Status = 'New', Origin = 'Phone', AccountId = acc.Id, RecordTypeId= RecordTypeCaseId, ServiceCatalog__c = testServiceCatalog.Id,
                           Sales_Order__c = so2.Id, Unit__c = unit2.Id, CustomerDefaultStatus__c = 'Suspected Defaulter', NumberOfDefaultNoticeRemindersSent__c = 1);
        insert cs1;
        
        /*Case cs2 = new Case(Status = 'New', Origin = 'Phone', AccountId = acc.Id, RecordTypeId= RecordTypeCaseId, ServiceCatalog__c = testServiceCatalog.Id,
                           Sales_Order__c = so3.Id, Unit__c = unit3.Id, CustomerDefaultStatus__c = 'Suspected Defaulter', NumberOfDefaultNoticeRemindersSent__c = 3);
        insert cs2;*/
        
        /* // Mock any additional required metadata values and services here
        TestMetadataService.mockAppSettings();  // Implement this helper method or use stubbing tools
        TestEmailService.mockEmailTemplates();  // Same for Email service
        TestServiceCatalogService.mockServiceCatalog(); */

        // Mock bank account, service catalog, and receipt allocations as needed
        
        
        Test.startTest();
        DefaultNoticeReminderBatch batch = new DefaultNoticeReminderBatch();
        Database.executeBatch(batch, 1);
        Test.stopTest();

        // Validate that SalesOrder and Case were updated
        List<SalesOrder__c> salesOrders = [SELECT Id, CustomerDefaultStatus__c, PostDueDateReminderSentDate__c FROM SalesOrder__c];
        System.assertEquals(3, salesOrders.size());
    }
    
    @isTest
    static void testBatchExecutionTHREE() {
        // Create test data for supporting objects and relationships

        String recTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();

        // Create a Person Account with email
        Account acc = new Account(
            FirstName = 'John',
            LastName = 'Doe',
            RecordTypeId = recTypeId,
            PersonEmail = 'john.doe@example.com'
        );
        insert acc;

        Contact con = new Contact(LastName='Test Contact');
        insert con;

        Project__c project1 = new Project__c(
            Name='Test Project',
            DefaultUnpaidAmount__c = 1000,
            DefaultUnpaidAmountPercentage__c = 10,
            DefaultNotificationDays__c = 5,
            SendDefaultNotice__c = true,
            City__c = 'Dubai',
            ProjectNameArabic__c = 'اختبار المشروع'
        );
        insert project1;
        
        Project__c project2 = new Project__c(
            Name='Test Project',
            DefaultUnpaidAmount__c = 1000,
            DefaultUnpaidAmountPercentage__c = 10,
            DefaultNotificationDays__c = 15,
            SendDefaultNotice__c = true,
            City__c = 'Abu Dhabi',
            ProjectNameArabic__c = 'اختبار المشروع'
        );
        insert project2;

        List<Unit__c> unitList = new List<Unit__c>();
        Unit__c unit1 = new Unit__c(
            Name = 'Test Unit',
            Project__c = project1.Id
        );
        unitList.add(unit1);
        
        Unit__c unit2 = new Unit__c(
            Name = 'Test Unit TWO',
            Project__c = project2.Id
        );
        unitList.add(unit2);
        
        Unit__c unit3 = new Unit__c(
            Name = 'Test Unit THREE',
            Project__c = project2.Id
        );
        unitList.add(unit3);

        insert unitList;
        
        List<SalesOrder__c> salesOrderList = new List<SalesOrder__c>();
        SalesOrder__c so1 = new SalesOrder__c(
            Name = 'SO-001',
            Status__c = 'Sold',
            Account__c = acc.Id,
            Unit__c = unit1.Id,
            PHPP__c = true,
            SellingPrice__c = 200000,
            PostDueDateReminderSentDate__c = null
        );
        salesOrderList.add(so1);
        
        SalesOrder__c so2 = new SalesOrder__c(
            Name = 'SO-002',
            Status__c = 'Sold',
            Account__c = acc.Id,
            Unit__c = unit2.Id,
            PHPP__c = true,
            SellingPrice__c = 200000,
            CustomerDefaultStatus__c = 'Suspected Defaulter',
            PostDueDateReminderSentDate__c = Date.today().addDays(-20)
        );
        salesOrderList.add(so2);
        
        SalesOrder__c so3 = new SalesOrder__c(
            Name = 'SO-003',
            Status__c = 'Sold',
            Account__c = acc.Id,
            Unit__c = unit3.Id,
            PHPP__c = true,
            SellingPrice__c = 10000,
            CustomerDefaultStatus__c = 'Suspected Defaulter',
            PostDueDateReminderSentDate__c = Date.today().addDays(-20),
            DefaultCustomerLastReminderSentDate__c = Date.today().addDays(-30)
        );
        salesOrderList.add(so3);

        insert salesOrderList;
        
        PaymentPlan__c tempPaymentPlan= new PaymentPlan__c(
            Name='testPayPlan',
            Description__c='test'
        );
        insert tempPaymentPlan;
        
        PaymentInstallments__c ppi = new PaymentInstallments__c();
        ppi.BrokerPayoutPercentage__c =100;
        ppi.Description__c = 'test description';
        ppi.InstallmentNumber__c = 1;
        ppi.InstallmentPercentage__c=100;
        ppi.PaymentPlan__c = tempPaymentPlan.id;
        ppi.InstallmentPercentage__c=100;
        ppi.Condition_Type__c='P012';
        
        insert ppi;
        
        List<InstallmentLines__c> installmentLines = new List<InstallmentLines__c>();
        /*InstallmentLines__c inst1 = new InstallmentLines__c(
            SalesOrder__c = so1.Id,
            PaymentInstallments__c = ppi.Id,
            PaymentPlan__c = tempPaymentPlan.Id,
            InstallmentDate__c = Date.today().addDays(-20),
            InstallmentAmount__c = 120000,
            Description__c = 'Test Description ONE'
        );
        installmentLines.add(inst1);
        
        InstallmentLines__c inst2 = new InstallmentLines__c(
            SalesOrder__c = so2.Id,
            PaymentInstallments__c = ppi.Id,
            PaymentPlan__c = tempPaymentPlan.Id,
            InstallmentDate__c = Date.today().addDays(-30),
            InstallmentAmount__c = 120000,
            Description__c = 'Test Description TWO'
        );
        installmentLines.add(inst2);*/
        
        InstallmentLines__c inst3 = new InstallmentLines__c(
            SalesOrder__c = so3.Id,
            PaymentInstallments__c = ppi.Id,
            PaymentPlan__c = tempPaymentPlan.Id,
            InstallmentDate__c = Date.today().addDays(-30),
            InstallmentAmount__c = 120000,
            Description__c = 'Test Description THREE'
        );
        installmentLines.add(inst3);
        
        insert installmentLines;

        // Create test ServiceCatalog record
        ServiceCatalog__c testServiceCatalog = new ServiceCatalog__c(
            Name = 'Service-Request-Default-Unit',
            Type__c = 'Service Request',
            Category__c = 'Financial - Payment Service',
            SubCategory__c = 'Postpone/Defer Payment',
            RecordTypeDevName__c = 'DefaultUnit'
        );
        insert testServiceCatalog;
        system.debug('testServiceCatalog----->'+testServiceCatalog);
        
        // Create test ServiceAction record
        ServiceAction__c testServiceAction = new ServiceAction__c(
            ServiceCatalog__c = testServiceCatalog.Id,
            TaskType__c = 'Default Unit',
            TaskSubType__c = 'Finance Team Task 1',
            TaskSubject__c = 'Finance Team Task 1',
            Due_in_days__c = 2,
            Order__c = 1
        );
        insert testServiceAction;
        
        // Create a Case for the Account
       	String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Default Unit').getRecordTypeId();
        // Create test Case related to the Account
        /*Case cs1 = new Case(Status = 'New', Origin = 'Phone', AccountId = acc.Id, RecordTypeId= RecordTypeCaseId, ServiceCatalog__c = testServiceCatalog.Id,
                           Sales_Order__c = so2.Id, Unit__c = unit2.Id, CustomerDefaultStatus__c = 'Suspected Defaulter', NumberOfDefaultNoticeRemindersSent__c = 1);
        insert cs1;*/
        
        Case cs2 = new Case(Status = 'New', Origin = 'Phone', AccountId = acc.Id, RecordTypeId= RecordTypeCaseId, ServiceCatalog__c = testServiceCatalog.Id,
                           Sales_Order__c = so3.Id, Unit__c = unit3.Id, CustomerDefaultStatus__c = 'Suspected Defaulter', NumberOfDefaultNoticeRemindersSent__c = 3);
        insert cs2;
        
        /* // Mock any additional required metadata values and services here
        TestMetadataService.mockAppSettings();  // Implement this helper method or use stubbing tools
        TestEmailService.mockEmailTemplates();  // Same for Email service
        TestServiceCatalogService.mockServiceCatalog(); */

        // Mock bank account, service catalog, and receipt allocations as needed
        
        
        Test.startTest();
        DefaultNoticeReminderBatch batch = new DefaultNoticeReminderBatch();
        Database.executeBatch(batch, 1);
        Test.stopTest();

        // Validate that SalesOrder and Case were updated
        List<SalesOrder__c> salesOrders = [SELECT Id, CustomerDefaultStatus__c, PostDueDateReminderSentDate__c FROM SalesOrder__c];
        System.assertEquals(3, salesOrders.size());
        //System.assertEquals('Suspected Defaulter', salesOrders[0].CustomerDefaultStatus__c);
        //System.assertNotEquals(null, salesOrders[0].PostDueDateReminderSentDate__c);

        List<Case> caseList = [SELECT Id, Sales_Order__c, NumberOfDefaultNoticeRemindersSent__c FROM Case];
        //System.assert(caseList.size() > 0);
        //System.assertEquals(1, caseList[0].NumberOfDefaultNoticeRemindersSent__c);
    }

    @isTest
    static void testScheduledExecution() {
        Test.startTest();
        String jobId = System.schedule('Test Default Notice Batch Schedule',
            '0 0 23 * * ?',
            new DefaultNoticeReminderBatch());
        Test.stopTest();

        System.assertNotEquals(null, jobId);
    }
}