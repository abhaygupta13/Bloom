@IsTest
public class CloseWorkOrderBatchTest {
    
    @TestSetup
    static void setupData() {
        
        Profile salesManagerProfile = [SELECT Id FROM Profile WHERE Name = 'Sales Manager' LIMIT 1];
        Profile profileCC = [SELECT Id FROM Profile WHERE Name = 'Contractor' LIMIT 1];
        
        // Generate a unique username
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueOf(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(Math.rint(Math.random() * 1000000));
        String uniqueName = orgId + dateString + randomInt;
        
        
        // Create a new User record with custom fields
        User userRecord = new User();
        userRecord.Username = uniqueName + '@mail.com';
        userRecord.LastName = 'Zaki Al Bakri';
        userRecord.Email = 'Zakial@gmail.com';
        userRecord.Alias = 'Zaki';
        userRecord.TimeZoneSidKey = 'Asia/Dubai';
        userRecord.LocaleSidKey = 'en_US';
        userRecord.EmailEncodingKey = 'UTF-8';
        userRecord.ProfileId = profileCC.Id;  
        userRecord.LanguageLocaleKey = 'en_US';
        userRecord.IsActive = TRUE;
        userRecord.is_On_Vacation__c = FALSE;
        userRecord.isFreezed__c = FALSE;
        // userRecord.SM_Avalible_For_Leads__c = TRUE;
        
        
        insert userRecord;
        
        // Create another User with Sales Manager profile
        String salesManagerUniqueName = orgId + dateString + randomInt + 'sm';
        User salesManagerUser = new User();
        salesManagerUser.Username = salesManagerUniqueName + '@mail.com';
        salesManagerUser.LastName = 'John Doe';
        salesManagerUser.Email = 'johndoe@gmail.com';
        salesManagerUser.Alias = 'JohnD';
        salesManagerUser.TimeZoneSidKey = 'Asia/Dubai';
        salesManagerUser.LocaleSidKey = 'en_US';
        salesManagerUser.EmailEncodingKey = 'UTF-8';
        salesManagerUser.ProfileId = salesManagerProfile.Id;  
        salesManagerUser.LanguageLocaleKey = 'en_US';
        insert salesManagerUser;
        
        
        // Create related data (Project, Unit, etc.)
        Project__c prj = new Project__c();
        prj.Name = 'Test Project';    
        prj.Contractor__c = userRecord.Id; 
        insert prj;       
        
        // Create an Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Unit__c unt = new Unit__c();
        unt.Name = 'Test Unit';
        unt.Location__Latitude__s = 22.254653;
        unt.Location__Longitude__s = 98.232564;
        unt.Is_Property_keys_given__c = true;
        insert unt;
        
        Round_Robins__c roundrobin = new Round_Robins__c();
        roundrobin.Name = 'Service/Case Request';
        roundrobin.Assigned_To__c = '2';
        roundrobin.Project__c = prj.id;
        roundrobin.OwnerId = userRecord.Id;
        roundrobin.Sobject__c = 'Case';
        insert roundrobin;
        
        Round_Robin_User__c roundrobinuser = new Round_Robin_User__c();
        roundrobinuser.Name = 'CRM 2';
        roundrobinuser.Total_Open_Count__c = 3;
        // roundrobinuser.IsActive__c=true;
        
        
        roundrobinuser.Round_Robin__c = roundrobin.id;
        roundrobinuser.Round_Robin_ID__c = 1;
        roundrobinuser.RR_User_Name__c = 'Almeria Project - CRM 2';
        roundrobinuser.User__c = salesManagerUser.id; // Ensure User__c is set correctly
        insert roundrobinuser;
        system.debug('roundrobinuser==>'+ roundrobinuser);
        system.debug('roundrobinuser==1111>'+ roundrobinuser.IsActive__c);
        
        
        //another record 
        Round_Robins__c roundrobin1 = new Round_Robins__c();
        roundrobin1.Name = 'Service/Resale Case Request';
        roundrobin1.Assigned_To__c = '2';
        roundrobin1.Project__c = prj.id;
        roundrobin1.OwnerId = userRecord.Id;
        roundrobin1.Sobject__c = 'Case';
        insert roundrobin1;
        
        Round_Robin_User__c roundrobinuser1 = new Round_Robin_User__c();
        roundrobinuser1.Name = 'CRM 2';
        roundrobinuser1.Total_Open_Count__c = 3;
        // roundrobinuser.IsActive__c=true;
        
        
        roundrobinuser1.Round_Robin__c = roundrobin1.id;
        roundrobinuser1.Round_Robin_ID__c = 1;
        roundrobinuser1.RR_User_Name__c = 'Almeria Project - CRM 2';
        roundrobinuser1.User__c = salesManagerUser.id; // Ensure User__c is set correctly
        insert roundrobinuser1;
        system.debug('roundrobinuser==>'+ roundrobinuser1);
        system.debug('roundrobinuser==1111>'+ roundrobinuser1.IsActive__c);
        
        
        
        // Create a WorkOrder with 'Customer not available' and no ServiceAppointment in the last 48 hours
        WorkOrder wo1 = new WorkOrder(
            Subject = 'Test Work Order 1',
            Status = 'Open',
            Customer_Availability__c = 'Not Available',
            Unit__c = unt.Id,
            Requester_Email__c='alt.jm-eef16gn@yopmail.com',
            AccountId = acc.Id,
            Check_In_Time__c = DateTime.now().addDays(-3)
        );
        insert wo1;
        
        // Create a WorkOrder with 'Customer not available' and a recent ServiceAppointment (within 48 hours)
        WorkOrder wo2 = new WorkOrder(
            Subject = 'Test Work Order 2',
            Status = 'Open',
            Customer_Availability__c = 'Not Available',
            Unit__c = unt.Id,
            AccountId = acc.Id,
            Requester_Email__c = 'alt.jm-eef16gn@yopmail.com',
            Check_In_Time__c = DateTime.now().addDays(-3)
        );
        insert wo2;        
        
        WorkOrder wo3 = new WorkOrder(
            Subject = 'Test Work Order 3',
            Status = 'Open',
            Customer_Availability__c = 'Not Available',
            Unit__c = unt.Id,
            AccountId = acc.Id,
            Requester_Email__c = 'alt.jm-eef16gn@yopmail.com',
            Check_In_Time__c = DateTime.now().addDays(-3)
        );
        insert wo3;
        
        List<ServiceAppointment> sa = new List<ServiceAppointment>([Select Id from ServiceAppointment]);
        delete sa;
        
        ServiceAppointment saRecent = new ServiceAppointment(
            ParentRecordId = wo2.Id,
            Status = 'Completed',
            Closure_Reason__c = 'Customer not available'
        );
        insert saRecent;
        
        // Create a ServiceAppointment for wo3 more than 48 hours ago
        ServiceAppointment saOld = new ServiceAppointment(
            ParentRecordId = wo3.Id,
            Status = 'Completed',
            Closure_Reason__c = 'Customer not available'
        );
        insert saOld;
        //Test.setCreatedDate(saOld.Id,System.now().addDays(-2));
    }
    
    @IsTest
    static void testCloseWorkOrderBatch() {
        Test.startTest();
        Datetime startDate = System.today().addDays(-2); 
        Datetime endDate = System.today().addDays(-1);
        
        System.debug('testbatchSA'+ [SELECT ParentRecordId, CreatedDate, Closure_Reason__c, Status FROM ServiceAppointment]);
        //System.debug('testbatch'+[SELECT Id FROM WorkOrder WHERE Customer_Availability__c = 'Not Available' AND Id IN ( SELECT ParentRecordId FROM ServiceAppointment
                                                                                                                                   // WHERE CreatedDate >= :startDate AND CreatedDate < :endDate)]);
        System.debug('testQueryResult ::::: '+ [SELECT Id FROM WorkOrder WHERE Customer_Availability__c = 'Not Available' AND Check_In_Time__c <= LAST_N_DAYS:2 AND Status != 'Closed' AND Id NOT IN (SELECT ParentRecordId FROM ServiceAppointment WHERE Status != 'Completed' AND Closure_Reason__c != 'Customer not available')]);
        CloseWorkOrderBatch batch = new CloseWorkOrderBatch();
        Database.executeBatch(batch, 200);        
        Test.stopTest();
    }
    
    @IsTest
    static void testCloseWorkOrderScheduler() {
        Test.startTest();        
        // Execute the scheduler
        CloseWorkOrderScheduler scheduler = new CloseWorkOrderScheduler();
        scheduler.execute(null);
        Test.stopTest();
    }
}