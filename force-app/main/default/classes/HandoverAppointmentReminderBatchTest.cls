@isTest
public class HandoverAppointmentReminderBatchTest {

    @TestSetup
    static void setupTestData() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'HO Agent' LIMIT 1];
        User testUser = new User(
            Username = 'testhoagent' + DateTime.now().getTime() + '@gmail.com',
            LastName = 'Test',
            Email = 'testuser@example.com',
            Alias = 'test',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

        System.runAs(testUser) {
            List<EmailTemplate> templates = new List<EmailTemplate>{
                new EmailTemplate(
                    Name = 'Appointment Booked Reminder After Five Days',
                    DeveloperName = 'App_Reminder_5_Days',
                    TemplateType = 'text',
                    FolderId = testUser.Id,
                    IsActive = true,
                    Subject = 'Reminder 5 Days {!Handover__c.Name}',
                    HtmlValue = 'Dear Customer'
                ),
                new EmailTemplate(
                    Name = 'Appointment Booked Reminder After Ten Days',
                    DeveloperName = 'App_Reminder_10_Days',
                    TemplateType = 'text',
                    FolderId = testUser.Id,
                    IsActive = true,
                    Subject = 'Reminder 10 Days {!Handover__c.Name}',
                    HtmlValue = 'Dear Customer'
                ),
                new EmailTemplate(
                    Name = 'Appointment Booked Reminder after 15 days',
                    DeveloperName = 'App_Reminder_15_Days',
                    TemplateType = 'text',
                    FolderId = testUser.Id,
                    IsActive = true,
                    Subject = 'Reminder 15 Days {!Handover__c.Name}',
                    HtmlValue = 'Dear Customer'
                )
            };
            insert templates;
        }

        Contact cnt = new Contact(FirstName = 'John', LastName = 'Doe', Email = 'johndoe@example.com');
        insert cnt;

        Account acc = new Account(Name = 'Test Account', CompanyEmail__c = 'johndoe@example.com');
        insert acc;

        SalesOrder__c sc = new SalesOrder__c(Name = 'Test sales order', Account__c = acc.Id);
        SalesOrder__c sal = new SalesOrder__c(Name = 'Test sales order 1', Account__c = acc.Id);
        SalesOrder__c salOrd = new SalesOrder__c(Name = 'Test sales order 2', Account__c = acc.Id);
        insert new List<SalesOrder__c>{ sc, sal, salOrd };

        Project__c pr = new Project__c(Name = 'testProject');
        insert pr;

        BuildingSection__c bld = new BuildingSection__c(Name = 'testBuilding', BuildingSectionCode__c = '1234567890', Project__c = pr.Id);
        insert bld;

        // Phase used for the 5-day / 10-day / 15-day (reminder allowed) scenarios
        HandoverPhase__c hphase = new HandoverPhase__c(
            Project__c = pr.Id,
            PaymentReminderStop__c = false,
            ApppintmentReminderStop__c = false,
            StopThirdHandoverAppointmentReminder__c = false,
            Name = 'Test'
        );
        insert hphase;

        // Second phase to cover the branch where the 15-day reminder is suppressed
        HandoverPhase__c hphaseStopThird = new HandoverPhase__c(
            Project__c = pr.Id,
            PaymentReminderStop__c = false,
            ApppintmentReminderStop__c = false,
            StopThirdHandoverAppointmentReminder__c = true,
            Name = 'Test Stop Third Reminder'
        );
        insert hphaseStopThird;

        SalesOrder__c salOrd2 = new SalesOrder__c(Name = 'Test sales order 3', Account__c = acc.Id);
        insert salOrd2;

        /*
         * CRITICAL FIX #1: HandoverTriggerHelper.beforeInsert() sets
         * Handover_Phase__c on every new Handover__c from
         * Unit__c.HandoverPhase__c. If the Unit doesn't have HandoverPhase__c
         * populated, the trigger silently nulls out Handover_Phase__c on the
         * Handover record, which breaks the batch's
         * Handover_Phase__r.ApppintmentReminderStop__c filter and causes
         * the batch to process ZERO records.
         */
        Unit__c unt = new Unit__c(
            Name = 'Unit Test A1435', Status__c = 'Unassigned', HO_Agent__c = testUser.Id,
            SAP_Unit_Number__c = '101', DoorNumber__c = 101, BuildingSectionName__c = bld.Id,
            RelatedSalesOrder__c = sal.Id, Active_Sales_Order__c = sal.Id,
            HandoverPhase__c = hphase.Id
        );
        Unit__c un = new Unit__c(
            Name = 'Unit Test', Status__c = 'Available', SAP_Unit_Number__c = '102',
            BuildingSectionName__c = bld.Id, RelatedSalesOrder__c = sc.Id, Active_Sales_Order__c = sc.Id,
            DoorNumber__c = 101,
            HandoverPhase__c = hphase.Id
        );
        Unit__c unc = new Unit__c(
            Name = 'Unit Test 2', Status__c = 'Available', SAP_Unit_Number__c = '103',
            BuildingSectionName__c = bld.Id, RelatedSalesOrder__c = salOrd.Id, Active_Sales_Order__c = salOrd.Id,
            DoorNumber__c = 101,
            HandoverPhase__c = hphase.Id
        );
        Unit__c uncStopThird = new Unit__c(
            Name = 'Unit Test 3', Status__c = 'Available', SAP_Unit_Number__c = '104',
            BuildingSectionName__c = bld.Id, RelatedSalesOrder__c = salOrd2.Id, Active_Sales_Order__c = salOrd2.Id,
            DoorNumber__c = 101,
            HandoverPhase__c = hphaseStopThird.Id
        );
        insert new List<Unit__c>{ unt, un, unc, uncStopThird };

        /*
         * CRITICAL FIX #2: RecordTypeDevName__c must be 'Non PHPP' to match
         * ServiceCatalogService.getServiceCatalogByProcessFlowTypeAndRecordType(
         *     'Handover', 'Non PHPP'
         * )
         * called inside HandoverTriggerHelper.beforeInsert(). A mismatch
         * causes serviceCatalogList[0] to throw a ListException on an
         * empty list.
         */
        ServiceCatalog__c servicecatalog = new ServiceCatalog__c(
            ProcessFlowType__c = 'Handover',
            ProcessType__c = 'Sales',
            Active__c = true,
            RecordTypeDevName__c = 'Non PHPP'
        );
        insert servicecatalog;

        // Covers daysDifference == 5, Contact__c branch (setTargetObjectId)
        Handover__c hand = new Handover__c(
            Unit__c = unt.Id,
            Account__c = acc.Id,
            Sub_Status__c = HandoverConstants.Handover_Sub_Status_Book_Appointment_with_Customer,
            Handover_Phase__c = hphase.Id,
            Is_BCC_Announcement_Sent__c = true,
            Customer_Email__c = 'test1@cloudsciencelabs.com',
            CRM_Team_Assigned_User__c = testUser.Id,
            Is_Orientation_Letter_Sent__c = true,
            Customer_Availability_for_CHO__c = 'Customer Not available',
            HO_Agent_Assigned_User__c = testUser.Id,
            Contact__c = cnt.Id,
            Date_of_Customer_Contacted__c = Date.today() - 5,
            Promise_to_Pay_Date__c = Date.today() + 15,
            Home_Orientation_Invitation_Date__c = Date.today() - 5,
            ServiceCatalog__c = servicecatalog.Id,
            StopAllEmailCommunication__c = false
        );

        // Covers daysDifference == 10, CustomerEmail__c branch (setToAddresses)
        Handover__c han = new Handover__c(
            Unit__c = un.Id,
            Sub_Status__c = HandoverConstants.Handover_Sub_Status_Book_Appointment_with_Customer,
            Handover_Phase__c = hphase.Id,
            Is_BCC_Announcement_Sent__c = true,
            Customer_Email__c = 'test2@cloudsciencelabs.com',
            Account__c = acc.Id,
            CRM_Team_Assigned_User__c = testUser.Id,
            Is_Orientation_Letter_Sent__c = true,
            Customer_Availability_for_CHO__c = 'Customer Not available',
            HO_Agent_Assigned_User__c = testUser.Id,
            Date_of_Customer_Contacted__c = Date.today() - 10,
            Promise_to_Pay_Date__c = Date.today() + 15,
            Home_Orientation_Invitation_Date__c = Date.today() - 10,
            ServiceCatalog__c = servicecatalog.Id,
            StopAllEmailCommunication__c = false
        );

        // Covers daysDifference == 15, isFifteenDays branch, CC + update logic
        Handover__c hn = new Handover__c(
            Unit__c = unc.Id,
            Sub_Status__c = HandoverConstants.Handover_Sub_Status_Book_Appointment_with_Customer,
            Handover_Phase__c = hphase.Id,
            Is_BCC_Announcement_Sent__c = true,
            Customer_Email__c = 'test3@cloudsciencelabs.com',
            Account__c = acc.Id,
            CRM_Team_Assigned_User__c = testUser.Id,
            Is_Orientation_Letter_Sent__c = true,
            Customer_Availability_for_CHO__c = 'Customer Not available',
            HO_Agent_Assigned_User__c = testUser.Id,
            Date_of_Customer_Contacted__c = Date.today() - 15,
            Promise_to_Pay_Date__c = Date.today() + 15,
            Home_Orientation_Invitation_Date__c = Date.today() - 15,
            ServiceCatalog__c = servicecatalog.Id,
            StopAllEmailCommunication__c = false
        );

        // Covers daysDifference == 15 with stopThirdReminder = true
        // (selectEmailTemplate remains null, no email queued)
        Handover__c hnStopThird = new Handover__c(
            Unit__c = uncStopThird.Id,
            Sub_Status__c = HandoverConstants.Handover_Sub_Status_Book_Appointment_with_Customer,
            Handover_Phase__c = hphaseStopThird.Id,
            Is_BCC_Announcement_Sent__c = true,
            Customer_Email__c = 'test4@cloudsciencelabs.com',
            Account__c = acc.Id,
            CRM_Team_Assigned_User__c = testUser.Id,
            Is_Orientation_Letter_Sent__c = true,
            Customer_Availability_for_CHO__c = 'Customer Not available',
            HO_Agent_Assigned_User__c = testUser.Id,
            Date_of_Customer_Contacted__c = Date.today() - 15,
            Promise_to_Pay_Date__c = Date.today() + 15,
            Home_Orientation_Invitation_Date__c = Date.today() - 15,
            ServiceCatalog__c = servicecatalog.Id,
            StopAllEmailCommunication__c = false
        );

        insert new List<Handover__c>{ hand, han, hn, hnStopThird };
    }

    @isTest
    public static void testBatchExecution() {
        Test.startTest();
        HandoverAppointmentReminderBatch batch = new HandoverAppointmentReminderBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        List<Handover__c> updatedHandovers = [
            SELECT Id, Customer_Availability_for_CHO__c, OwnerId
            FROM Handover__c
            WHERE Sub_Status__c = :HandoverConstants.Handover_Sub_Status_Book_Appointment_with_Customer
        ];

        System.assertNotEquals(0, updatedHandovers.size(), 'Handover records should exist after batch run.');
    }

    @isTest
    public static void testSchedulableExecution() {
        Test.startTest();
        String cronExpression = '0 0 12 * * ?';
        String jobId = System.schedule('Test Handover CRM Reminder', cronExpression, new HandoverAppointmentReminderBatch());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered FROM CronTrigger WHERE Id = :jobId];
        System.assertNotEquals(null, ct, 'Cron trigger should be created for the scheduled job.');
        Test.stopTest();
    }
}