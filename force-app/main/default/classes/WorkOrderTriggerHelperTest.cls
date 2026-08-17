@isTest
public class WorkOrderTriggerHelperTest {
    @TestSetup
    static void setupTestData() {
        // Existing Setup Data
        Service_Catalogue__c srvCt = new Service_Catalogue__c();
        srvCt.Name = 'Test Service Catalogue 1';
        srvCt.Location__c = 'Laundry Room';
        srvCt.Replace__c = 'Within 2 Day';
        srvCt.Repair__c = 'Within 2 hours';
        srvCt.Closure_Reason__c = 'Customer not available';
        srvCt.Category__c = 'Civil';
        srvCt.Sub_category__c = 'Walls/Ceiling';
        srvCt.Incident_description__c = 'Full external paint';
        srvCt.Resolution_Priority__c = 'PE';
        srvCt.Resolution_Typology__c = 'Repair';
        srvCt.Problem_Code__c = 'CM-PQA-Wall-Ceiling';  
        insert srvCt; 
        
        Service_Catalogue__c srvCt1 = new Service_Catalogue__c();
        srvCt1.Name = 'Test Service Catalogue 2';
        srvCt1.Location__c = 'Mater Bedroom';
        srvCt1.Replace__c = 'Within 2 Day';
        srvCt1.Repair__c = 'Within 2 hours';
        srvCt1.Closure_Reason__c = 'Customer not available';
        srvCt1.Category__c = 'Civil';
        srvCt1.Sub_category__c = 'Walls/Ceiling';
        srvCt1.Incident_description__c = 'Paint Peeling off';
        srvCt1.Resolution_Priority__c = 'P1';
        srvCt1.Resolution_Typology__c = 'Replace';
        srvCt1.Problem_Code__c = 'CM-PQA-Wall-Ceiling';        
        insert srvCt1;

        Service_Catalogue__c srvCt2 = new Service_Catalogue__c();
        srvCt2.Name = 'Test Service Catalogue 3';
        srvCt2.Location__c = 'Mater Bedroom';
        srvCt2.Replace__c = 'Within 2 Day';
        srvCt2.Repair__c = 'Within 2 hours';
        srvCt2.Closure_Reason__c = 'Customer not available';
        srvCt2.Category__c = 'Civil';
        srvCt2.Sub_category__c = 'Aluminium';
        srvCt2.Incident_description__c = 'rusted';
        srvCt2.Resolution_Priority__c = 'P2';
        srvCt2.Resolution_Typology__c = 'Repair';
        srvCt2.Problem_Code__c = 'al-kitchen sink';        
        insert srvCt2;

        Service_Catalogue__c srvCt3 = new Service_Catalogue__c();
        srvCt3.Name = 'Test Service Catalogue 4';
        srvCt3.Location__c = 'Mater Bedroom';
        srvCt3.Replace__c = 'Within 2 Day';
        srvCt3.Repair__c = 'Within 2 hours';
        srvCt3.Closure_Reason__c = 'Customer not available';
        srvCt3.Category__c = 'Civil';
        srvCt3.Sub_category__c = 'Aluminium';
        srvCt3.Incident_description__c = 'rusted';
        srvCt3.Resolution_Priority__c = 'P3';
        srvCt3.Resolution_Typology__c = 'Replace';
        srvCt3.Problem_Code__c = 'al-accessories';        
        insert srvCt3;
        
        Account acc = new Account();
        acc.Name = 'Test Acc';
        insert acc;
        
        Contract cnt = new Contract();
        cnt.Name = 'Test Contractor';
        cnt.AccountId = acc.Id;
        insert cnt;
        
        // Create and insert Case
        Case cse = new Case();
        cse.Status = 'New';
        cse.Subject = 'Test Case'; 
        cse.OwnerId = UserInfo.getUserId();  // Ensure the Case has an OwnerId
       // insert cse;      
        
        // Fetch the Profile Id for 'Contact Centre'
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
        
        Unit__c unt = new Unit__c();
        unt.Name = 'C-1233';
        unt.Project__c = prj.Id;
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
        
        
      
        
        
        
        // WorkOrder setup
        List<WorkOrder> woList = new List<WorkOrder>();
        WorkOrder wrk = new WorkOrder();
        wrk.Subject = 'New work order is created.--test';
        wrk.Description = 'This decriptions for test class.';
        wrk.Closure_Reason__c = 'Customer not available'; //'Out Of Scope';
        wrk.Type_of_Incident__c = 'Out of Scope';
        wrk.Unit__c = unt.Id; 
        wrk.Is_Emergency__c = true;
        wrk.Resolution_Priority__c = 'Emergency'; // 'Priority 1';        
        wrk.Resolution_Typology__c = 'Repair';
        wrk.Category__c = 'Civil';
        wrk.Location__c = 'Laundry Room';
        wrk.Priority = 'Low';
        wrk.Status = Constants.CLOSED;
        wrk.AccountId = acc.Id;
        wrk.Check_In__c = false;
        wrk.Customer_Availability__c = 'Not Available';
        wrk.Incident_description__c = 'Full external paint';
        wrk.Problem_Code__c = 'CM-PQA-Wall-Ceiling';
        wrk.Sub_category__c = 'Walls/Ceiling';
        wrk.Repair__c = '2 Days';        
        wrk.ServiceReportLanguage = ' ';
        wrk.Replace__c = 'Within 2 Day';
        wrk.Requester_Email__c='alt.jm-eef16gn@yopmail.com';        
        
        wrk.OwnerId=userRecord.id;
        woList.add(wrk); 


        WorkOrder wrk1 = new WorkOrder();
        wrk1.Subject = 'New work order is created.--test TWO';
        wrk1.Description = 'This decriptions for test class.';
        wrk1.Closure_Reason__c = 'Customer not available'; //'Out Of Scope';
        wrk1.Type_of_Incident__c = 'Out of Scope';
        wrk1.Unit__c = unt.Id; 
        wrk1.Is_Emergency__c = true;
        wrk1.Resolution_Priority__c = 'Emergency'; // 'Priority 1';        
        wrk1.Resolution_Typology__c = 'Replace';
        wrk1.Category__c = 'Civil';
        wrk1.Location__c = 'Laundry Room';
        wrk1.Priority = 'Low';
        wrk1.Status = Constants.CLOSED;
        wrk1.AccountId = acc.Id;
        wrk1.Check_In__c = false;
        wrk1.Customer_Availability__c = 'Not Available';
        wrk1.Incident_description__c = 'Paint Peeling off';
        wrk1.Problem_Code__c = 'CM-PQA-Wall-Ceiling';
        wrk1.Sub_category__c = 'Walls/Ceiling';
        wrk1.Repair__c = '2 Days';        
        wrk1.ServiceReportLanguage = ' ';
        wrk1.Replace__c = 'Within 2 Day';
        wrk1.Requester_Email__c='alt.jm-eef16gn@yopmail.com';        

        wrk1.OwnerId=userRecord.id;
        woList.add(wrk1); 

        WorkOrder wrk2 = new WorkOrder();
        wrk2.Subject = 'New work order is created.--test THREE';
        wrk2.Description = 'This decriptions for test class.';
        wrk2.Closure_Reason__c = 'Customer not available'; //'Out Of Scope';
        wrk2.Type_of_Incident__c = 'Out of Scope';
        wrk2.Unit__c = unt.Id; 
        wrk2.Is_Emergency__c = true;
        wrk2.Resolution_Priority__c = 'Emergency'; // 'Priority 1';        
        wrk2.Resolution_Typology__c = 'Repair';
        wrk2.Category__c = 'Civil';
        wrk2.Location__c = 'Laundry Room';
        wrk2.Priority = 'Low';
        wrk2.Status = Constants.CLOSED;
        wrk2.AccountId = acc.Id;
        wrk2.Check_In__c = false;
        wrk2.Customer_Availability__c = 'Not Available';
        wrk2.Incident_description__c = 'rusted';
        wrk2.Problem_Code__c = 'al-kitchen sink';
        wrk2.Sub_category__c = 'Aluminium';
        wrk2.Repair__c = '2 Days';        
        wrk2.ServiceReportLanguage = ' ';
        wrk2.Replace__c = 'Within 2 Day';
        wrk2.Requester_Email__c='alt.jm-eef16gn@yopmail.com';        

        wrk2.OwnerId=userRecord.id;
        woList.add(wrk2); 

        WorkOrder wrk3 = new WorkOrder();
        wrk3.Subject = 'New work order is created.--test THREE';
        wrk3.Description = 'This decriptions for test class.';
        wrk3.Closure_Reason__c = 'Customer not available'; //'Out Of Scope';
        wrk3.Type_of_Incident__c = 'Out of Scope';
        wrk3.Unit__c = unt.Id; 
        wrk3.Is_Emergency__c = true;
        wrk3.Resolution_Priority__c = 'Emergency'; // 'Priority 1';        
        wrk3.Resolution_Typology__c = 'Replace';
        wrk3.Category__c = 'Civil';
        wrk3.Location__c = 'Laundry Room';
        wrk3.Priority = 'Low';
        wrk3.Status = Constants.CLOSED;
        wrk3.AccountId = acc.Id;
        wrk3.Check_In__c = false;
        wrk3.Customer_Availability__c = 'Not Available';
        wrk3.Incident_description__c = 'rusted';
        wrk3.Problem_Code__c = 'al-accessories';
        wrk3.Sub_category__c = 'Aluminium';
        wrk3.Repair__c = '2 Days';        
        wrk3.ServiceReportLanguage = ' ';
        wrk3.Replace__c = 'Within 2 Day';
        wrk3.Requester_Email__c='alt.jm-eef16gn@yopmail.com';        

        wrk3.OwnerId=userRecord.id;
        woList.add(wrk3); 

        insert  woList;
          System.debug('workid-->'+ wrk.OwnerId);
        
        WorkType newWrkType = new WorkType();
        newWrkType.Name = 'DLP';
        newWrkType.EstimatedDuration = 2;
        newWrkType.DurationType = 'Hours';
        insert newWrkType;
    }   
  
    
    

    @isTest
    static void updateWorkOrder1_Test() {
        // Create a system admin user
        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User adminUser = new User(
            ProfileId = sysAdminProfile.Id,
            Username = 'tsadgadgsassd@example.com',
            Email = 'testadmin@example.com',
            Alias = 'testad',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Admin',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            IsActive = true
        );
        insert adminUser;

        // Fetch latest WorkOrder
        WorkOrder w1 = [SELECT Id, Subject, Status, Description, Type_of_Incident__c, Unit__c, Resolution_Priority__c, Category__c, Location__c, Resolution_Typology__c, Priority, 
                        AccountId, Check_In__c, Is_Tenet_Request__c, Incident_description__c, Replace__c, Repair__c, Customer_Availability__c, Sub_category__c, Closure_Reason__c ,Requester_Email__c
                        FROM WorkOrder ORDER BY CreatedDate DESC 
                        LIMIT 1];  
        ServiceAppointment saRec = [SELECT Id, Status FROM ServiceAppointment WHERE ParentRecordId = :w1.id LIMIT 1];
        System.debug('saRec ::::: '+ saRec);
        saRec.Status = 'Scheduled';
        update saRec;
        
        saRec.Status = 'In Progress';
        update saRec;
        
        // Modify WorkOrder
        w1.Check_In__c = true;
        w1.Status = 'Closed';
        w1.Closure_Reason__c = 'Out Of Scope'; //Constants.OUTSIDE_SCOPE
        w1.Customer_Availability__c = 'Not Available';
        
        Test.startTest();
        // Set the running user to the system admin user
        System.runAs(adminUser) {
        w1.Is_Tenet_Request__c = 'Tenant';
        w1.Requester_Name__c = 'Test';
        w1.Requester_Email__c = 'test@gmail.com';
        w1.Requester_Phone__c = '1234567890';
        update w1;
        
        w1.Is_Tenet_Request__c = 'Owner';
        w1.Requester_Name__c = '';
        w1.Requester_Email__c = 'test@gmail.com';
        w1.Requester_Phone__c = '';
        update w1;
        
        // Update and test changes
        w1.Customer_Availability__c = 'Available';
        w1.Closure_Reason__c = 'Warranty post DLP';
        
        
        w1.Status = 'Closed';
        w1.Type_of_Incident__c = 'Warranty Post DLP';
        update w1;
        
        w1.Status = 'Closed';
        w1.Type_of_Incident__c = '';
        w1.Scope__c = 'Out of DLP Scope';
        update w1;
        
        w1.Status = 'Completed';
        update w1;       
        }
        Test.stopTest();
    }
}