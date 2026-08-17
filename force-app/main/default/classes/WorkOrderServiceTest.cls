@isTest
public class WorkOrderServiceTest {
    @TestSetup
    static void setupTestData() {
        // Existing Setup Data
        Service_Catalogue__c srvCt = new Service_Catalogue__c();
        srvCt.Name = 'Test Service Catalogue';
        srvCt.Location__c = 'Laundry Room';
        srvCt.Replace__c = 'Within 2 Day';
        srvCt.Repair__c = 'Within 2 hours';
        srvCt.Closure_Reason__c = 'Customer not available';
        srvCt.Category__c = 'Civil';
        srvCt.Sub_category__c = 'Walls/Ceiling';
        srvCt.Incident_description__c = 'Full external paint';
        srvCt.Resolution_Priority__c = 'Emergency';
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
        srvCt1.Resolution_Typology__c = 'Repair';
        srvCt1.Problem_Code__c = 'CM-PQA-Wall-Ceiling';        
        insert srvCt1;
        
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
        insert  wrk;
          System.debug('workid-->'+ wrk.OwnerId);
    }   
  
    
    

    @isTest
    static void updateWorkOrder1_Test() {
        // Fetch latest WorkOrder
        WorkOrder w1 = [SELECT Id, Subject, Status, Description, Type_of_Incident__c, Unit__c, Resolution_Priority__c, Category__c, Location__c, Resolution_Typology__c, Priority, 
                        AccountId, Check_In__c, Incident_description__c, Replace__c, Repair__c, Customer_Availability__c, Sub_category__c, Closure_Reason__c ,Requester_Email__c
                        FROM WorkOrder ORDER BY CreatedDate DESC 
                        LIMIT 1]; 
        
        WorkOrder wrk = new WorkOrder();
        wrk.Subject = 'New work order is created.--test';
        wrk.Description = 'This decriptions for test class.';
        wrk.Closure_Reason__c = 'Customer not available'; //'Out Of Scope';
        wrk.Type_of_Incident__c = 'Out of Scope';
        wrk.Unit__c = [select id from Unit__c limit 1].Id; 
        wrk.Is_Emergency__c = true;
        wrk.Resolution_Priority__c = 'Emergency'; // 'Priority 1';        
        wrk.Resolution_Typology__c = 'Repair';
        wrk.Category__c = 'Civil';
        wrk.Location__c = 'Laundry Room';
        wrk.Priority = 'Low';
        wrk.Status = Constants.CLOSED;
        wrk.AccountId = [select id from account limit 1].Id;
        wrk.Check_In__c = false;
        wrk.Customer_Availability__c = 'Not Available';
        wrk.Incident_description__c = 'Full external paint';
        wrk.Problem_Code__c = 'CM-PQA-Wall-Ceiling';
        wrk.Sub_category__c = 'Walls/Ceiling';
        wrk.Repair__c = '2 Days';        
        wrk.ServiceReportLanguage = ' ';
        wrk.Replace__c = 'Within 2 Day';
        wrk.Requester_Email__c='alt.jm-eef16gn@yopmail.com';
        //wrk.OwnerId=userRecord.id;
        
        
        
        
        
        
        WorkOrderService wko = WorkOrderService.getInstance();
        Test.startTest();
        List<WorkOrder> res1 = wko.insertWorkOrdersWithoutTrigger(new List<WorkOrder> {wrk});
        
        //w1.Status = 'Closed';
        w1.Type_of_Incident__c = '';
        w1.Scope__c = 'Out of DLP Scope';
        List<WorkOrder> res2 = wko.updateWorkOrdersWithTrigger(new List<WorkOrder> {w1});
        List<WorkOrder> res3 = wko.getWorkOrdersByIds(new List<WorkOrder> {wrk});        
        RecordType res4 = wko.getRecordTypeOfCase('Resale');
        Test.stopTest();
    }
}