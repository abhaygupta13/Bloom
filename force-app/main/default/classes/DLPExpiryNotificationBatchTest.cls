@IsTest
public class DLPExpiryNotificationBatchTest {
     @IsTest
    static void sendDLPExpiryNotificationTestMethod() {
    Project__c project = new Project__c(
            Name = 'Test Project',
            Office_Location__c = 'Test Location'
        );
        insert project;
        
        // Create a Unit
        Unit__c unit = new Unit__c(
            Name = 'Unit Test A1435',
            SAP_Unit_Number__c = 'SAP12345',
            Status__c = 'Available'
           
        );
        insert unit;

        
        Schema.RecordTypeInfo recordTypeInfo = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('PersonAccount');
        
        Account acc = new Account();
        acc.LastName = 'Test Acc';
        acc.RecordTypeId = recordTypeInfo.getRecordTypeId();
        acc.PersonEmail = 'test@gmail.com';
        insert acc;
        
       
        SalesOrder__c sc = new SalesOrder__c();
        sc.Name ='Test sales order';
        sc.Unit__c = unit.Id;
        sc.Account__c = acc.Id;
        insert sc;
        
        
        unit.Active_Sales_Order__c = sc.Id;
        unit.RelatedSalesOrder__c = sc.Id;
        unit.NOCExpiryDate__c= Date.today().addMonths(1);
        update unit;
        
        Profile profileCRM = [SELECT Id FROM Profile WHERE Name = 'CRM Operations'];
        
        User userRecord = new User(
            Alias = 'zaki',
            Email = 'zakial@gmail.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Zaki Al Bakri',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profileCRM.Id,
           
            TimeZoneSidKey = 'Asia/Dubai',
            UserName = 'zaki.al.bakri@example.com'
        );
        insert userRecord;
        
        
        // Create a Handover record
        Handover__c handover1 = new Handover__c(
            Name = 'Test Handover',
            Customer_Email__c = 'test@example.com',
            HasDLPExpiryEmailSent__c=false,
            Is_Orientation_Letter_Sent__c = false,
            Is_BCC_Announcement_Sent__c = false,
            Unit__c = unit.Id,
           
            Project__c = project.Id,
            Customer_Availability_for_CHO__c = 'Customer Available',
           
            UnitCategory__c='Registered Unit',
            Is_Notice_of_Completion_Sent__c=false
        );
        insert handover1;
     Test.startTest();        
            // Execute the batch or schedulable class
           Database.executeBatch(new DLPExpiryNotificationBatch());
           DLPExpiryNotificationBatch scheduler = new DLPExpiryNotificationBatch();
        
        scheduler.execute(null);
        Test.stopTest();
    }
}