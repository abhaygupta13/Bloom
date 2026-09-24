@isTest
public class WorkOrderTriggerHelperTest {
    @TestSetup
    static void setupTestData() {
        List<Service_Catalogue__c> serviceCatalogueList = new List<Service_Catalogue__c>();
        serviceCatalogueList.add(new Service_Catalogue__c(
            Name = 'Test Service Catalogue 1',
            Location__c = 'Laundry Room',
            Replace__c = 'Within 2 Day',
            Repair__c = 'Within 2 hours',
            Closure_Reason__c = 'Customer not available',
            Category__c = 'Civil',
            Sub_category__c = 'Walls/Ceiling',
            Incident_description__c = 'Full external paint',
            Resolution_Priority__c = 'PE',
            Resolution_Typology__c = 'Repair',
            Problem_Code__c = 'CM-PQA-Wall-Ceiling'
        ));
    
        serviceCatalogueList.add(new Service_Catalogue__c(
            Name = 'Test Service Catalogue 2',
            Location__c = 'Mater Bedroom',
            Replace__c = 'Within 2 Day',
            Repair__c = 'Within 2 hours',
            Closure_Reason__c = 'Customer not available',
            Category__c = 'Civil',
            Sub_category__c = 'Walls/Ceiling',
            Incident_description__c = 'Paint Peeling off',
            Resolution_Priority__c = 'P1',
            Resolution_Typology__c = 'Replace',
            Problem_Code__c = 'CM-PQA-Wall-Ceiling'
        ));
    
        serviceCatalogueList.add(new Service_Catalogue__c(
            Name = 'Test Service Catalogue 3',
            Location__c = 'Mater Bedroom',
            Replace__c = 'Within 2 Day',
            Repair__c = 'Within 2 hours',
            Closure_Reason__c = 'Customer not available',
            Category__c = 'Civil',
            Sub_category__c = 'Aluminium',
            Incident_description__c = 'rusted',
            Resolution_Priority__c = 'P2',
            Resolution_Typology__c = 'Repair',
            Problem_Code__c = 'al-kitchen sink'
        ));
    
        serviceCatalogueList.add(new Service_Catalogue__c(
            Name = 'Test Service Catalogue 4',
            Location__c = 'Mater Bedroom',
            Replace__c = 'Within 2 Day',
            Repair__c = 'Within 2 hours',
            Closure_Reason__c = 'Customer not available',
            Category__c = 'Civil',
            Sub_category__c = 'Aluminium',
            Incident_description__c = 'rusted',
            Resolution_Priority__c = 'P3',
            Resolution_Typology__c = 'Replace',
            Problem_Code__c = 'al-accessories'
        ));
    
        insert serviceCatalogueList;
    
        Account acc = new Account(Name = 'Test Acc');
        insert acc;
    
        Contract cnt = new Contract(Name = 'Test Contractor', AccountId = acc.Id);
        insert cnt;
    
        Profile salesManagerProfile = [SELECT Id FROM Profile WHERE Name = 'Sales Manager' LIMIT 1];
        Profile profileCC = [SELECT Id FROM Profile WHERE Name = 'Contractor' LIMIT 1];
    
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueOf(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(Math.rint(Math.random() * 1000000));
    
        String uniqueName = orgId + dateString + randomInt;
        String salesManagerUniqueName = orgId + dateString + randomInt + 'sm';
    
        List<User> userList = new List<User>();
    
        userList.add(new User(
            Username = uniqueName + '@mail.com',
            LastName = 'Zaki Al Bakri',
            Email = 'Zakial@gmail.com',
            Alias = 'Zaki',
            TimeZoneSidKey = 'Asia/Dubai',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profileCC.Id,
            LanguageLocaleKey = 'en_US',
            IsActive = true,
            is_On_Vacation__c = false,
            isFreezed__c = false
        ));
    
        userList.add(new User(
            Username = salesManagerUniqueName + '@mail.com',
            LastName = 'John Doe',
            Email = 'johndoe@gmail.com',
            Alias = 'JohnD',
            TimeZoneSidKey = 'Asia/Dubai',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = salesManagerProfile.Id,
            LanguageLocaleKey = 'en_US'
        ));
    
        insert userList;
    
        User userRecord = userList[0];
        User salesManagerUser = userList[1];
    
        Project__c prj = new Project__c(
            Name = 'Test Project',
            Contractor__c = userRecord.Id
        );
        insert prj;
    
        Unit__c unt = new Unit__c(
            Name = 'C-1233',
            Project__c = prj.Id,
            Is_Property_keys_given__c = true
        );
        insert unt;
    
        List<Round_Robins__c> roundRobinList = new List<Round_Robins__c>();
    
        roundRobinList.add(new Round_Robins__c(
            Name = 'Service/Case Request',
            Assigned_To__c = '2',
            Project__c = prj.Id,
            OwnerId = userRecord.Id,
            Sobject__c = 'Case'
        ));
    
        roundRobinList.add(new Round_Robins__c(
            Name = 'Service/Resale Case Request',
            Assigned_To__c = '2',
            Project__c = prj.Id,
            OwnerId = userRecord.Id,
            Sobject__c = 'Case'
        ));
    
        insert roundRobinList;
    
        List<Round_Robin_User__c> roundRobinUserList = new List<Round_Robin_User__c>();
    
        roundRobinUserList.add(new Round_Robin_User__c(
            Name = 'CRM 2',
            Total_Open_Count__c = 3,
            Round_Robin__c = roundRobinList[0].Id,
            Round_Robin_ID__c = 1,
            RR_User_Name__c = 'Almeria Project - CRM 2',
            User__c = salesManagerUser.Id
        ));
    
        roundRobinUserList.add(new Round_Robin_User__c(
            Name = 'CRM 2',
            Total_Open_Count__c = 3,
            Round_Robin__c = roundRobinList[1].Id,
            Round_Robin_ID__c = 1,
            RR_User_Name__c = 'Almeria Project - CRM 2',
            User__c = salesManagerUser.Id
        ));
    
        insert roundRobinUserList;
    
        System.debug('roundRobinUserList ==> ' + roundRobinUserList);
    
        List<WorkOrder> woList = new List<WorkOrder>();
    
        woList.add(new WorkOrder(
            Subject = 'New work order is created.--test',
            Description = 'This decriptions for test class.',
            Closure_Reason__c = 'Customer not available',
            Type_of_Incident__c = 'Out of Scope',
            Unit__c = unt.Id,
            Is_Emergency__c = true,
            Resolution_Priority__c = 'Emergency',
            Resolution_Typology__c = 'Repair',
            Category__c = 'Civil',
            Location__c = 'Laundry Room',
            Priority = 'Low',
            Status = Constants.CLOSED,
            AccountId = acc.Id,
            Check_In__c = false,
            Customer_Availability__c = 'Not Available',
            Incident_description__c = 'Full external paint',
            Problem_Code__c = 'CM-PQA-Wall-Ceiling',
            Sub_category__c = 'Walls/Ceiling',
            Repair__c = '2 Days',
            ServiceReportLanguage = ' ',
            Replace__c = 'Within 2 Day',
            Requester_Email__c = 'alt.jm-eef16gn@yopmail.com',
            OwnerId = userRecord.Id
        ));
    
        woList.add(new WorkOrder(
            Subject = 'New work order is created.--test TWO',
            Description = 'This decriptions for test class.',
            Closure_Reason__c = 'Customer not available',
            Type_of_Incident__c = 'Out of Scope',
            Unit__c = unt.Id,
            Is_Emergency__c = true,
            Resolution_Priority__c = 'Emergency',
            Resolution_Typology__c = 'Replace',
            Category__c = 'Civil',
            Location__c = 'Laundry Room',
            Priority = 'Low',
            Status = Constants.CLOSED,
            AccountId = acc.Id,
            Check_In__c = false,
            Customer_Availability__c = 'Not Available',
            Incident_description__c = 'Paint Peeling off',
            Problem_Code__c = 'CM-PQA-Wall-Ceiling',
            Sub_category__c = 'Walls/Ceiling',
            Repair__c = '2 Days',
            ServiceReportLanguage = ' ',
            Replace__c = 'Within 2 Day',
            Requester_Email__c = 'alt.jm-eef16gn@yopmail.com',
            OwnerId = userRecord.Id
        ));
    
        woList.add(new WorkOrder(
            Subject = 'New work order is created.--test THREE',
            Description = 'This decriptions for test class.',
            Closure_Reason__c = 'Customer not available',
            Type_of_Incident__c = 'Out of Scope',
            Unit__c = unt.Id,
            Is_Emergency__c = true,
            Resolution_Priority__c = 'Emergency',
            Resolution_Typology__c = 'Repair',
            Category__c = 'Civil',
            Location__c = 'Laundry Room',
            Priority = 'Low',
            Status = Constants.CLOSED,
            AccountId = acc.Id,
            Check_In__c = false,
            Customer_Availability__c = 'Not Available',
            Incident_description__c = 'rusted',
            Problem_Code__c = 'al-kitchen sink',
            Sub_category__c = 'Aluminium',
            Repair__c = '2 Days',
            ServiceReportLanguage = ' ',
            Replace__c = 'Within 2 Day',
            Requester_Email__c = 'alt.jm-eef16gn@yopmail.com',
            OwnerId = userRecord.Id
        ));
    
        woList.add(new WorkOrder(
            Subject = 'New work order is created.--test THREE',
            Description = 'This decriptions for test class.',
            Closure_Reason__c = 'Customer not available',
            Type_of_Incident__c = 'Out of Scope',
            Unit__c = unt.Id,
            Is_Emergency__c = true,
            Resolution_Priority__c = 'Emergency',
            Resolution_Typology__c = 'Replace',
            Category__c = 'Civil',
            Location__c = 'Laundry Room',
            Priority = 'Low',
            Status = Constants.CLOSED,
            AccountId = acc.Id,
            Check_In__c = false,
            Customer_Availability__c = 'Not Available',
            Incident_description__c = 'rusted',
            Problem_Code__c = 'al-accessories',
            Sub_category__c = 'Aluminium',
            Repair__c = '2 Days',
            ServiceReportLanguage = ' ',
            Replace__c = 'Within 2 Day',
            Requester_Email__c = 'alt.jm-eef16gn@yopmail.com',
            OwnerId = userRecord.Id
        ));
    
        insert woList;
    
        System.debug('workid --> ' + woList[0].OwnerId);
    
        WorkType newWrkType = new WorkType(
            Name = 'DLP',
            EstimatedDuration = 2,
            DurationType = 'Hours'
        );
        insert newWrkType;
    }

    @isTest
    static void updateWorkOrder1_Test() {
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

        WorkOrder w1 = [SELECT Id, Subject, Status, Description, Type_of_Incident__c, Unit__c, Resolution_Priority__c, Category__c, Location__c, Resolution_Typology__c, Priority, AccountId, Check_In__c, Is_Tenet_Request__c, Incident_description__c, Replace__c, Repair__c, Customer_Availability__c, Sub_category__c, Closure_Reason__c, Requester_Email__c FROM WorkOrder ORDER BY CreatedDate DESC LIMIT 1];
        ServiceAppointment saRec = [SELECT Id, Status FROM ServiceAppointment WHERE ParentRecordId = :w1.id LIMIT 1];
        System.debug('saRec ::::: '+ saRec);
        saRec.Status = 'Scheduled';
        update saRec;

        saRec.Status = 'In Progress';
        update saRec;

        w1.Check_In__c = true;
        w1.Status = 'Closed';
        w1.Closure_Reason__c = 'Out Of Scope';
        w1.Customer_Availability__c = 'Not Available';

        Test.startTest();
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