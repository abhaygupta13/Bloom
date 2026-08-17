@isTest
public class ServiceAppointmentServiceTest {
    @TestSetup
    public static void setup() {        
        // Create a User
        Profile salesManagerProfile = [SELECT Id FROM Profile WHERE Name = 'Sales Manager' LIMIT 1];
        Profile systemadministrator = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Contractor' LIMIT 1];
        User u = new User(Alias = 'standt', Email='standarduser@test.com', 
                          EmailEncodingKey='UTF-8', LastName='TestingSA', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='SAstandarduser@test.com');
        insert u;
        
        User u2 = new User(Alias = 'standt', Email='standarduser@test.com', 
                           EmailEncodingKey='UTF-8', LastName='TestingSA2', LanguageLocaleKey='en_US', 
                           LocaleSidKey='en_US', ProfileId = systemadministrator.Id, 
                           TimeZoneSidKey='America/Los_Angeles', UserName='SAstandarduser2@test.com');
        insert u2;
        
        // Generate a unique username
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueOf(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(Math.rint(Math.random() * 1000000));
        String uniqueName = orgId + dateString + randomInt;
        
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
        prj.Contractor__c = u.Id; //cnt.Id;
        insert prj;       
        
        Unit__c unt = new Unit__c();
        unt.Name = 'C-1233';
        unt.Project__c = prj.Id;
        insert unt;
        
        
        // Create an Account
        Account acc = new Account(Name='Test Account');
        insert acc;
        
        OperatingHours oh  = new OperatingHours(
            Name = 'test Holiday'
        );
        insert oh;
        // Create a Service Territory
        ServiceTerritory st = new ServiceTerritory(
            Name = 'Test Territory',
            OperatingHoursId = [SELECT Id FROM OperatingHours LIMIT 1].Id,
            IsActive = true
        );
        insert st;
        
        
        // Create a Service Resource linked to the User
        ServiceResource sr = new ServiceResource(
            Name = 'Test Resource',
            RelatedRecordId = salesManagerUser.Id,
            Is_Contractor__c = false,
            IsActive = true
        );
        insert sr;
        
        ServiceResource sr2 = new ServiceResource(
            Name = 'Test Resource 2',
            RelatedRecordId = u2.Id,
            Is_Contractor__c = true,
            IsActive = true
        );
        insert sr2;
        
        // Create a Service Territory Member linking the Service Resource to the Service Territory
        ServiceTerritoryMember stm = new ServiceTerritoryMember(
            ServiceResourceId = sr.Id,
            ServiceTerritoryId = st.Id,
            EffectiveStartDate = Date.today().addDays(-1),
            EffectiveEndDate = Date.today().addYears(1)
        );
        insert stm;
        
        ServiceTerritoryMember stm2 = new ServiceTerritoryMember(
            ServiceResourceId = sr2.Id,
            ServiceTerritoryId = st.Id,
            EffectiveStartDate = Date.today().addDays(-1),
            EffectiveEndDate = Date.today().addYears(1)
        );
        insert stm2;
        
        
        Round_Robins__c roundrobin = new Round_Robins__c();
        roundrobin.Name = 'Service/Case Request';
        roundrobin.Assigned_To__c = '2';
        roundrobin.Project__c = prj.id;
        roundrobin.OwnerId = u.Id;
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
        roundrobin1.OwnerId = u.Id;
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
        
        
        
        // Create a Work Order linked to the Account
        WorkOrder wo = new WorkOrder(
            Subject = 'Test Work Order',
            AccountId = acc.Id,
            Unit__c = unt.Id,
            Status = 'In Progress',
            Scope__c='Under Scope'
        );
        insert wo;
        
        DateTime startDateTime = DateTime.now().addDays(1);
        DateTime endDateTime = DateTime.now().addDays(1).addHours(2);
        
        // Create a Service Appointment linked to the Work Order
        ServiceAppointment sa = new ServiceAppointment();
        sa.Status = 'None';
        sa.ParentRecordId = wo.Id;
        sa.EarliestStartTime = startDateTime;
        sa.SchedStartTime = startDateTime;
        sa.SchedEndTime = endDateTime;
        sa.DueDate = endDateTime;
        insert sa;
        system.debug('ServiceAppointmentnew->'+sa);
        
        
        
        WorkType newWrkType = new WorkType();
        newWrkType.Name = 'DLP';
        newWrkType.EstimatedDuration = 2;
        newWrkType.DurationType = 'Hours';
        insert newWrkType;
        
        
        // Assign the Service Resource to the Service Appointment
        AssignedResource assRes = new AssignedResource();
        assRes.ServiceResourceId = sr.Id;
        assRes.ServiceAppointmentId = sa.Id;
        insert assRes;
        system.debug('ServiceResourceId--->'+sr.id);
        
        AssignedResource assRes2 = new AssignedResource();
        assRes2.ServiceResourceId = sr2.Id;
        assRes2.ServiceAppointmentId = sa.Id;
        insert assRes2;
        system.debug('ServiceResourceId2--->'+sr2.id);
    } 
    
    @IsTest
    static void testCreateServiceAppointmentSelf() {
        // Get Work Order Id
        Id workOrderId = [SELECT Id FROM WorkOrder ORDER BY CreatedDate DESC LIMIT 1].Id;
        WorkOrder workOrderObj = [SELECT Id FROM WorkOrder ORDER BY CreatedDate DESC LIMIT 1];
        //ServiceAppointment sa = [SELECT Id, Status, ParentRecordId, SchedStartTime, SchedEndTime FROM ServiceAppointment];
        
        ServiceAppointment sa = new ServiceAppointment();
        sa.Status = Constants.IN_PROGRESS;
        sa.ParentRecordId = [select id from workorder limit 1].id;
        sa.EarliestStartTime = DateTime.now().addHours(-2);
        sa.SchedStartTime = DateTime.now().addHours(-3);
        sa.Is_First_Appointment__c = false;
        sa.SchedEndTime = DateTime.now().addHours(1);
        sa.DueDate = DateTime.now().addHours(-1);
        ServiceAppointmentService ss = ServiceAppointmentService.getInstance();
        Test.startTest();        
        List<ServiceAppointment> insertedSAs = ss.insertServiceAppointmentsWithoutTrigger(new List<ServiceAppointment>{sa});
        sa.Status = 'Completed';
        List<ServiceAppointment> updatedSAs = ss.updateUnits(new List<ServiceAppointment>{sa});        
        List<ServiceAppointment> getedSAs = ss.getServiceAppointmentsByParentRecordSetIds(new Set<Id>{workOrderId});
        List<ServiceAppointment> getedWrk = ss.getServiceAppointmentsByParentRecordIds(new List<WorkOrder>{workOrderObj});
        Test.stopTest();
    }  
}