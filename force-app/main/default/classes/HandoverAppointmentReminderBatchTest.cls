@isTest
public class HandoverAppointmentReminderBatchTest {

    @TestSetup
    static void setupTestData() {
        // Create Test User
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
        
        // Create Email Templates inside System.runAs block
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

        // Create Contact for TargetObjectId scenario
        Contact cnt = new Contact(FirstName = 'John', LastName = 'Doe', Email = 'johndoe@example.com');
        insert cnt;
        
        // Create Account & Sales Orders
        Account acc = new Account(Name = 'Test Account',CompanyEmail__c='johndoe@example.com');
        insert acc;
        
        SalesOrder__c sc = new SalesOrder__c(Name = 'Test sales order', Account__c = acc.Id);
        SalesOrder__c sal = new SalesOrder__c(Name = 'Test sales order 1', Account__c = acc.Id);
        SalesOrder__c salOrd = new SalesOrder__c(Name = 'Test sales order 2', Account__c = acc.Id);
        insert new List<SalesOrder__c>{ sc, sal, salOrd };
        
        // Create Project & Building Section
        Project__c pr = new Project__c(Name = 'testProject');        
        insert pr;      
        
        BuildingSection__c bld = new BuildingSection__c(Name = 'testBuilding', BuildingSectionCode__c = '1234567890', Project__c = pr.Id);
        insert bld;      
        
        // Create Handover Phase
        HandoverPhase__c hphase = new HandoverPhase__c(
            Project__c = pr.Id,
            PaymentReminderStop__c = false,
            ApppintmentReminderStop__c = false,
            StopThirdHandoverAppointmentReminder__c = false,
            Name = 'Test'
        );
        insert hphase;
        
        // Create Units
        Unit__c unt = new Unit__c(Name = 'Unit Test A1435', Status__c = 'Unassigned', HO_Agent__c = testUser.Id, SAP_Unit_Number__c = '101', DoorNumber__c = 101, BuildingSectionName__c = bld.Id, RelatedSalesOrder__c = sal.Id, Active_Sales_Order__c = sal.Id);
        Unit__c un = new Unit__c(Name = 'Unit Test', Status__c = 'Available', SAP_Unit_Number__c = '102', BuildingSectionName__c = bld.Id, RelatedSalesOrder__c = sc.Id, Active_Sales_Order__c = sc.Id, DoorNumber__c = 101);
        Unit__c unc = new Unit__c(Name = 'Unit Test 2', Status__c = 'Available', SAP_Unit_Number__c = '103', BuildingSectionName__c = bld.Id, RelatedSalesOrder__c = salOrd.Id, Active_Sales_Order__c = salOrd.Id, DoorNumber__c = 101);
        insert new List<Unit__c>{ unt, un, unc };
        
        // Create Service Catalog
        ServiceCatalog__c servicecatalog = new ServiceCatalog__c(ProcessFlowType__c = 'Handover', ProcessType__c = 'Sales', Active__c = true, RecordTypeDevName__c = 'Handover');
        insert servicecatalog;
        
        // Create Handover Records (Fixed references to han & hn!)
        Handover__c hand = new Handover__c(
            Unit__c = unt.Id,
            account__c = acc.id,
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
        
        Handover__c han = new Handover__c(
            Unit__c = un.Id,
            Sub_Status__c = HandoverConstants.Handover_Sub_Status_Book_Appointment_with_Customer,
            Handover_Phase__c = hphase.Id,
            Is_BCC_Announcement_Sent__c = true,
            Customer_Email__c = 'test2@cloudsciencelabs.com',
            account__c = acc.id,
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
        
        Handover__c hn = new Handover__c(
            Unit__c = unc.Id,
            Sub_Status__c = HandoverConstants.Handover_Sub_Status_Book_Appointment_with_Customer,
            Handover_Phase__c = hphase.Id,
            Is_BCC_Announcement_Sent__c = true,
            Customer_Email__c = 'test3@cloudsciencelabs.com',
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
        
        insert new List<Handover__c>{ hand, han, hn };
    }

    @isTest
    public static void testBatchExecution() {
        Test.startTest();
        HandoverAppointmentReminderBatch batch = new HandoverAppointmentReminderBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();
         }

    @isTest
    public static void testSchedulableExecution() {
        Test.startTest();
        String cronExpression = '0 0 12 * * ?';
        String jobId = System.schedule('Test Handover CRM Reminder', cronExpression, new HandoverAppointmentReminderBatch());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered FROM CronTrigger WHERE Id = :jobId];
       // System.assertEquals(cronExpression, ct.CronExpression, 'The cron expression should match.');
        Test.stopTest();
    }
}