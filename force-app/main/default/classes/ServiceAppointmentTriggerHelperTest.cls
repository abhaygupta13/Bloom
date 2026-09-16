@isTest
public class ServiceAppointmentTriggerHelperTest {
    
    @TestSetup
    static void setupTestData() {
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Sales Manager' LIMIT 1];
        
        Profile contractorProfile = [SELECT Id FROM Profile WHERE Name = 'Contractor' LIMIT 1];
        User usr1 = new User(Alias = 'standt', Email = 'standarduser1@test.com', EmailEncodingKey = 'UTF-8',
                             LastName = 'User1', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US',
                             ProfileId = contractorProfile.Id, TimeZoneSidKey = 'America/Los_Angeles',
                             UserName = 'standuser130546@test.com');
        insert usr1;
        
        User usr2 = new User(Alias = 'standt', Email = 'standarduser2@test.com', EmailEncodingKey = 'UTF-8',
                             LastName = 'User2', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US',
                             ProfileId = standardProfile.Id, TimeZoneSidKey = 'America/Los_Angeles',
                             UserName = 'conus43434er@test.com');
        insert usr2;
        
         String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueOf(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(Math.rint(Math.random() * 1000000));
        String uniqueName = orgId + dateString + randomInt;
        
        
         String salesManagerUniqueName = orgId + dateString + randomInt + 'sm';
        User salesManagerUser = new User();
        salesManagerUser.Username = salesManagerUniqueName + '@mail.com';
        salesManagerUser.LastName = 'John Doe';
        salesManagerUser.Email = 'johndoe@gmail.com';
        salesManagerUser.Alias = 'JohnD';
        salesManagerUser.TimeZoneSidKey = 'America/Los_Angeles';
        salesManagerUser.LocaleSidKey = 'en_US';
        salesManagerUser.EmailEncodingKey = 'UTF-8';
        salesManagerUser.ProfileId = standardProfile.Id;  
        salesManagerUser.LanguageLocaleKey = 'en_US';
        insert salesManagerUser;
        
        
       
        
        
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        OperatingHours opHours = new OperatingHours(Name = 'Standard Hours');
        insert opHours;
        
        ServiceTerritory territory = new ServiceTerritory(Name = 'Main Territory', OperatingHoursId = opHours.Id, IsActive = true);
        insert territory;
        
        ServiceResource srvRes = new ServiceResource();
        srvRes.Name = 'Test Resource';
        srvRes.RelatedRecordId = salesManagerUser.Id;
        srvRes.Is_Contractor__c = false;
        srvRes.IsActive = true;
        insert srvRes;
        
        ServiceResource srvRes2 = new ServiceResource();
        srvRes2.Name = 'Test Resource 2';
        srvRes2.RelatedRecordId = usr2.Id;
        srvRes2.Is_Contractor__c = true;
        srvRes2.IsActive = true;
        insert srvRes2;
        
        ServiceTerritoryMember srvTrtMbr = new ServiceTerritoryMember();
        srvTrtMbr.ServiceResourceId = srvRes.Id;
        srvTrtMbr.ServiceTerritoryId = territory.Id;
        srvTrtMbr.EffectiveStartDate = Date.today().addDays(-1);
        srvTrtMbr.EffectiveEndDate = Date.today().addYears(1);        
        insert srvTrtMbr;
        
        ServiceTerritoryMember srvTrtMbr2 = new ServiceTerritoryMember();
        srvTrtMbr2.ServiceResourceId = srvRes2.Id;
        srvTrtMbr2.ServiceTerritoryId = territory.Id;
        srvTrtMbr2.EffectiveStartDate = Date.today().addDays(-1);
        srvTrtMbr2.EffectiveEndDate = Date.today().addYears(1);
        insert srvTrtMbr2;
        
        Project__c prj = new Project__c();
        prj.Name = 'Test Project';    
        prj.Contractor__c = usr1.Id; 
        insert prj;       
        
        Unit__c unt = new Unit__c();
        unt.Name = 'C-1233';
        unt.Project__c = prj.Id;
        unt.Is_Property_keys_given__c = true;
        insert unt;
        
        Round_Robins__c roundrobin = new Round_Robins__c();
        roundrobin.Name = 'Service/Case Request';
        roundrobin.Assigned_To__c = '2';
        roundrobin.Project__c = prj.id;
        roundrobin.OwnerId = usr1.Id;
        roundrobin.Sobject__c = 'Case';
        insert roundrobin;
    
        Round_Robin_User__c roundrobinuser = new Round_Robin_User__c();
        roundrobinuser.Name = 'CRM 2';
        roundrobinuser.Total_Open_Count__c = 3;
       
       
       
        roundrobinuser.Round_Robin__c = roundrobin.id;
        roundrobinuser.Round_Robin_ID__c = 1;
        roundrobinuser.RR_User_Name__c = 'Almeria Project - CRM 2';
        roundrobinuser.User__c = usr2.id; // Ensure User__c is set correctly
        insert roundrobinuser;
        system.debug('roundrobinuser==>'+ roundrobinuser);
        system.debug('roundrobinuser==1111>'+ roundrobinuser.IsActive__c);
        
        
        //another record 
         Round_Robins__c roundrobin1 = new Round_Robins__c();
        roundrobin1.Name = 'Service/Resale Case Request';
        roundrobin1.Assigned_To__c = '2';
        roundrobin1.Project__c = prj.id;
        roundrobin1.OwnerId = usr1.Id;
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
        
        
        WorkOrder wrk = new WorkOrder();
        wrk.Subject = 'Test Work Order';
        wrk.AccountId = acc.Id;
        wrk.Status = 'New';
        wrk.Unit__c = unt.Id; 
        wrk.Contractor__c = usr1.Id;
        
        insert wrk;
        
        DateTime startDateTime = DateTime.now().addDays(1);
        DateTime endDateTime = DateTime.now().addDays(1).addHours(2);
        
        ServiceAppointment sa = new ServiceAppointment();
        sa.Status = Constants.SCHEDULED;
        sa.ParentRecordId = wrk.Id;
        sa.EarliestStartTime = startDateTime;
        sa.SchedStartTime = startDateTime;
        sa.Is_First_Appointment__c = false;
        sa.SchedEndTime = endDateTime;
        sa.DueDate = endDateTime;
        insert sa;
        system.debug('service===>'+sa);
        
        WorkType newWrkType = new WorkType();
        newWrkType.Name = 'DLP';
        newWrkType.EstimatedDuration = 2;
        newWrkType.DurationType = 'Hours';
        insert newWrkType;
        
        AssignedResource assRes = new AssignedResource();
        assRes.ServiceResourceId = srvRes.Id;
        assRes.ServiceAppointmentId = sa.Id;
        insert assRes;
        
        AssignedResource assRes1 = new AssignedResource();
        assRes1.ServiceResourceId = srvRes2.Id;
        assRes1.ServiceAppointmentId = sa.Id;       
        insert assRes1;
    }
    
    @isTest
    static void sendMailWhenServiceAppointmentScheduled_Test() {
        //ServiceAppointment sa = [SELECT Id, Status, ParentRecordId, SchedStartTime, SchedEndTime FROM ServiceAppointment LIMIT 1];
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Sales Manager' LIMIT 1];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueOf(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(Math.rint(Math.random() * 1000000));
        String uniqueName = orgId + dateString + randomInt;
        String salesManagerUniqueName = orgId + dateString + randomInt + 'sm';
        
        User salesManagerUser = new User();
        salesManagerUser.Username = salesManagerUniqueName + '@mail.com';
        salesManagerUser.LastName = 'John Doe';
        salesManagerUser.Email = 'johndoe@gmail.com';
        salesManagerUser.Alias = 'JohnD';
        salesManagerUser.TimeZoneSidKey = 'America/Los_Angeles';
        salesManagerUser.LocaleSidKey = 'en_US';
        salesManagerUser.EmailEncodingKey = 'UTF-8';
        salesManagerUser.ProfileId = standardProfile.Id;  
        salesManagerUser.LanguageLocaleKey = 'en_US';
        
        insert salesManagerUser;
        ServiceResource srvRes = new ServiceResource();
        srvRes.Name = 'Test Resource';
        srvRes.RelatedRecordId = salesManagerUser.Id;
        srvRes.Is_Contractor__c = false;
        srvRes.IsActive = true;
        insert srvRes;
        
        OperatingHours opHours = new OperatingHours(Name = 'Standard Hours');
        insert opHours;

        
        ServiceTerritory territory = new ServiceTerritory(Name = 'Territory 1', OperatingHoursId = opHours.Id, IsActive = true);
        insert territory;
 
        
        ServiceTerritoryMember srvTrtMbr = new ServiceTerritoryMember();
        srvTrtMbr.ServiceResourceId = srvRes.Id;
        srvTrtMbr.ServiceTerritoryId = territory.Id;
        srvTrtMbr.EffectiveStartDate = Date.today().addDays(-1);
        srvTrtMbr.EffectiveEndDate = Date.today().addYears(1);        
        insert srvTrtMbr;

        
        ServiceAppointment sa = new ServiceAppointment();
        sa.Status = 'None';
        sa.ParentRecordId = [select id from workorder limit 1].id;
        sa.EarliestStartTime = DateTime.now().addHours(-2);
        sa.SchedStartTime = DateTime.now().addHours(-3);
        sa.Is_First_Appointment__c = false;
        sa.SchedEndTime = DateTime.now().addHours(1);
        sa.DueDate = DateTime.now().addHours(-1);
        insert sa;  
        
        AssignedResource assRes = new AssignedResource();
        assRes.ServiceResourceId = srvRes.Id;
        assRes.ServiceAppointmentId = sa.Id;
        insert assRes;

        
        /* ServiceAppointment oldSA = sa.clone();
oldSA.Status = 'New'; 
oldSA.SchedStartTime = DateTime.now().addHours(-1);
oldSA.SchedEndTime = DateTime.now().addHours(1);

Map<Id, ServiceAppointment> saOldMap = new Map<Id, ServiceAppointment>{oldSA.Id => oldSA};
*/
        Test.startTest();
        sa.status = Constants.SCHEDULED;
        //update sa;
        // Call the method to test
        //ServiceAppointmentTriggerHelper.sendMailWhenServiceAppointmentScheduled(new List<ServiceAppointment>{sa}, saOldMap);
        Test.stopTest();
    }
    
  /*  @isTest
    static void addContractor_Test() {

        ServiceAppointment sa = [SELECT Id, Status, ParentRecordId,Is_First_Appointment__c FROM ServiceAppointment LIMIT 1];
        system.debug('ServiceAppointment===11111111111111>'+sa);
        Test.startTest();
        ServiceAppointmentTriggerHelper.addContractor(new List<ServiceAppointment>{sa}, new Map<Id, ServiceAppointment>{});
        Test.stopTest();
    } */
    
    @isTest
static void addContractor_Test() {
    // Create a ServiceAppointment record for testing
    ServiceAppointment testSA = new ServiceAppointment(
        Status = 'Scheduled',
        ParentRecordId =[select id from workorder limit 1].id, // Replace with a valid Id if necessary
        Is_First_Appointment__c = true
    );
    insert testSA;

    // Query the inserted ServiceAppointment
    ServiceAppointment sa = [SELECT Id, Status, ParentRecordId, Is_First_Appointment__c FROM ServiceAppointment WHERE Id = :testSA.Id];
    System.debug('ServiceAppointment===>' + sa);

    // Create a mock old value map
    Map<Id, ServiceAppointment> oldServiceAppointment = new Map<Id, ServiceAppointment>{
        sa.Id => new ServiceAppointment(Status = 'Not Scheduled')
    };

    Test.startTest();
    // Call the method to test
    ServiceAppointmentTriggerHelper.addContractor(new List<ServiceAppointment>{sa}, oldServiceAppointment);
    Test.stopTest();
}

    
    @isTest
    static void newAppontmentSchedule_Test() {
        List<ServiceAppointment> appointments = [SELECT Id, Status, ParentRecordId FROM ServiceAppointment LIMIT 1];
        system.debug('appointments===111=>'+appointments);
         Map<Id, ServiceAppointment> oldMap = new Map<Id, ServiceAppointment>();
        for (ServiceAppointment sa : appointments) {
            oldMap.put(sa.Id, sa.clone(false, true, false, false));
        }
        
        Test.startTest();
        ServiceAppointmentTriggerHelper.newAppontmentSchedule(appointments,oldMap);
        Test.stopTest();
    }
    
    @isTest
    static void updateFirstAppointment_Test() {
        
        Test.startTest();
        ServiceAppointmentTriggerHelper.updateFirstAppointment(new List<ServiceAppointment>());
        Test.stopTest();
        
    }
    
    @isTest
    static void statusUpdate_Test() {
        Test.startTest();
        ServiceAppointmentTriggerHelper.statusUpdate(new List<ServiceAppointment>(), new Map<Id, ServiceAppointment>());
        Test.stopTest();
        
    }

    @isTest
    static void testCanceledFlag() {
        List<ServiceAppointment> appointments = [SELECT Id, Status, Closure_Reason__c, ParentRecordId FROM ServiceAppointment LIMIT 1];
        appointments[0].Status = 'Canceled';
        Test.startTest();
        update appointments[0];
        Test.stopTest();
    }
}