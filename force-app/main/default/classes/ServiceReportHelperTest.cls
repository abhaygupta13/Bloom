@isTest
public class ServiceReportHelperTest {    
    @isTest
    static void updateDocumentOnWorkOrder_Test() {        		
        Test.startTest();        
        
        // Create and insert an Account record
        Account a = new Account(
            Name = 'testAccountSA',
            BillingPostalCode = '83059'
        );       
        insert a;  
        
        // Retrieve the Contractor Profile
         Profile salesManagerProfile = [SELECT Id FROM Profile WHERE Name = 'Sales Manager' LIMIT 1];
        Profile profileCC = [SELECT Id FROM Profile WHERE Name = 'Contractor' LIMIT 1];
        
        // Generate a unique username
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueOf(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
        Integer randomInt = Integer.valueOf(Math.rint(Math.random() * 1000000));
        String uniqueName = orgId + dateString + randomInt;
        
        // Create and insert a User record
        User userRecord = new User(
            Username = uniqueName + '@mail.com',
            LastName = 'Zaki Al Bakri',
            Email = 'Zakial@gmail.com',
            Alias = 'Zaki',
            TimeZoneSidKey = 'Asia/Dubai',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profileCC.Id,  
            LanguageLocaleKey = 'en_US',
            IsActive = TRUE,
            is_On_Vacation__c = FALSE,
            isFreezed__c = FALSE
        );
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
        
        
    
        
        
        
        
        // Create and insert a WorkOrder record
        WorkOrder wrk = new WorkOrder(
            Subject = 'New work order is created.--test',
            Description = 'This description is for the test class.',
            Closure_Reason__c = 'Customer not available',
            Type_of_Incident__c = 'Out of Scope',
            Project__c = prj.Id,
            Unit__c = unt.Id,
            Is_Emergency__c = true,
            Resolution_Priority__c = 'Emergency',
            Resolution_Typology__c = 'Repair',
            Category__c = 'Civil',
            Location__c = 'Laundry Room',
            Priority = 'Low',
            Status = 'New',
            AccountId = a.Id,
            Check_In__c = false,
            Customer_Availability__c = 'Not Available',
            Incident_description__c = 'Full external paint',
            Problem_Code__c = 'CM-PQA-Wall-Ceiling',
            Sub_category__c = 'Walls/Ceiling',
            Repair__c = '2 Days',
            ServiceReportLanguage = ' ',
            Replace__c = 'Within 2 Day',
            OwnerId = userRecord.Id
        );
        insert wrk;
        
        // Create and insert a ServiceAppointment record
        ServiceAppointment SA = new ServiceAppointment(            
            ParentRecordId = wrk.Id
        );        
        insert SA;
        
        // Create and insert a ContentVersion record
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Penguins',
            PathOnClient = 'Penguins.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );        
        insert contentVersion;    
        
        // Link the ContentDocument to the ServiceAppointment
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];        
        
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = SA.Id,
            ContentDocumentId = documents[0].Id,
            ShareType = 'V'
        );        
        insert cdl;
        
        // Create and insert a ServiceReport record
        ServiceReport sr = new ServiceReport(
            DocumentBody = Blob.valueOf('Test Content'),
            DocumentContentType = 'application/pdf',
            DocumentName = 'Test',
            ParentId = SA.Id
        );        
        insert sr;
        update sr;
        delete sr;
        
        Test.stopTest();
    }    
}