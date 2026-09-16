@isTest
public class ServiceAppointmentServiceTest {
    @TestSetup
    static void setup() {
        Map<String, Id> profileMap = new Map<String, Id>();
        for (Profile p : [SELECT Id, Name FROM Profile WHERE Name IN ('Sales Manager', 'System Administrator', 'Contractor')]) {
            profileMap.put(p.Name, p.Id);
        }
        String uStr = UserInfo.getOrganizationId() + DateTime.now().getTime();
        List<User> users = new List<User>{
            new User(Alias='standt', Email='sa1@test.com', EmailEncodingKey='UTF-8', LastName='TestingSA', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId=profileMap.get('Contractor'), TimeZoneSidKey='America/Los_Angeles', UserName='sa1' + uStr + '@test.com'),
            new User(Alias='standt2', Email='sa2@test.com', EmailEncodingKey='UTF-8', LastName='TestingSA2', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId=profileMap.get('System Administrator'), TimeZoneSidKey='America/Los_Angeles', UserName='sa2' + uStr + '@test.com'),
            new User(Alias='JohnD', Email='johndoe@gmail.com', EmailEncodingKey='UTF-8', LastName='John Doe', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId=profileMap.get('Sales Manager'), TimeZoneSidKey='Asia/Dubai', UserName='sm' + uStr + '@mail.com')
        };
        insert users;
        Project__c prj = new Project__c(Name='Test Project', Contractor__c=users[0].Id);
        insert prj;
        Unit__c unt = new Unit__c(Name='C-1233', Project__c=prj.Id, Is_Property_keys_given__c = true);
        insert unt;
        Account acc = new Account(Name='Test Account');
        insert acc;
        OperatingHours oh = new OperatingHours(Name='test Holiday');
        insert oh;
        ServiceTerritory st = new ServiceTerritory(Name='Test Territory', OperatingHoursId=oh.Id, IsActive=true);
        insert st;
        List<ServiceResource> srs = new List<ServiceResource>{
            new ServiceResource(Name='Test Resource', RelatedRecordId=users[2].Id, Is_Contractor__c=false, IsActive=true),
            new ServiceResource(Name='Test Resource 2', RelatedRecordId=users[1].Id, Is_Contractor__c=true, IsActive=true)
        };
        insert srs;
        List<ServiceTerritoryMember> stms = new List<ServiceTerritoryMember>{
            new ServiceTerritoryMember(ServiceResourceId=srs[0].Id, ServiceTerritoryId=st.Id, EffectiveStartDate=Date.today().addDays(-1), EffectiveEndDate=Date.today().addYears(1)),
            new ServiceTerritoryMember(ServiceResourceId=srs[1].Id, ServiceTerritoryId=st.Id, EffectiveStartDate=Date.today().addDays(-1), EffectiveEndDate=Date.today().addYears(1))
        };
        insert stms;
        List<Round_Robins__c> rrs = new List<Round_Robins__c>{
            new Round_Robins__c(Name='Service/Case Request', Assigned_To__c='2', Project__c=prj.Id, OwnerId=users[0].Id, Sobject__c='Case'),
            new Round_Robins__c(Name='Service/Resale Case Request', Assigned_To__c='2', Project__c=prj.Id, OwnerId=users[0].Id, Sobject__c='Case')
        };
        insert rrs;
        List<Round_Robin_User__c> rrUsers = new List<Round_Robin_User__c>{
            new Round_Robin_User__c(Name='CRM 2', Total_Open_Count__c=3, Round_Robin__c=rrs[0].Id, Round_Robin_ID__c=1, RR_User_Name__c='Almeria Project - CRM 2', User__c=users[2].Id),
            new Round_Robin_User__c(Name='CRM 2', Total_Open_Count__c=3, Round_Robin__c=rrs[1].Id, Round_Robin_ID__c=1, RR_User_Name__c='Almeria Project - CRM 2', User__c=users[2].Id)
        };
        insert rrUsers;
        WorkOrder wo = new WorkOrder(Subject='Test Work Order', AccountId=acc.Id, Unit__c=unt.Id, Status='In Progress', Scope__c='Under Scope');
        insert wo;
        DateTime startDt = DateTime.now().addDays(1);
        DateTime endDt = startDt.addHours(2);
        ServiceAppointment sa = new ServiceAppointment(Status='None', ParentRecordId=wo.Id, EarliestStartTime=startDt, SchedStartTime=startDt, SchedEndTime=endDt, DueDate=endDt);
        insert sa;
        insert new WorkType(Name='DLP', EstimatedDuration=2, DurationType='Hours');
        List<AssignedResource> ars = new List<AssignedResource>{
            new AssignedResource(ServiceResourceId=srs[0].Id, ServiceAppointmentId=sa.Id),
            new AssignedResource(ServiceResourceId=srs[1].Id, ServiceAppointmentId=sa.Id)
        };
        insert ars;
    }
    @IsTest
    static void testCreateServiceAppointmentSelf() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        ServiceAppointment sa = new ServiceAppointment(Status=Constants.IN_PROGRESS, ParentRecordId=wo.Id, EarliestStartTime=DateTime.now().addHours(-2), SchedStartTime=DateTime.now().addHours(-3), Is_First_Appointment__c=false, SchedEndTime=DateTime.now().addHours(1), DueDate=DateTime.now().addHours(-1));
        ServiceAppointmentService ss = ServiceAppointmentService.getInstance();
        Test.startTest();
        ss.insertServiceAppointmentsWithoutTrigger(new List<ServiceAppointment>{sa});
        sa.Status = 'Completed';
        ss.getServiceAppointmentsByParentRecordSetIds(new Set<Id>{wo.Id});
        Test.stopTest();
    }
    @IsTest
    static void testServiceAppointmentServiceMethods() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        ServiceAppointmentService service = ServiceAppointmentService.getInstance();
        DateTime startTime = DateTime.now().addDays(2);
        DateTime endTime = startTime.addHours(2);
        ServiceAppointment sa1 = new ServiceAppointment(Status='None', ParentRecordId=wo.Id, EarliestStartTime=startTime, SchedStartTime=startTime, SchedEndTime=endTime, DueDate=endTime);
        Test.startTest();
        List<ServiceAppointment> insertedSAs = service.insertServiceAppointments(new List<ServiceAppointment>{sa1});
        System.assertEquals(1, insertedSAs.size());
        System.assertNotEquals(null, insertedSAs[0].Id);
        sa1.Job_Status__c = 'Check-In';
        List<ServiceAppointment> updatedSAs = service.updateServiceAppointments(new List<ServiceAppointment>{sa1});
        System.assertEquals(1, updatedSAs.size());
        sa1.Job_Status__c = 'Check-Out';
        List<ServiceAppointment> updatedWithoutTrigger = service.updateServiceAppointmentsWithoutTrigger(new List<ServiceAppointment>{sa1});
        System.assertEquals(1, updatedWithoutTrigger.size());
        List<ServiceAppointment> byIds = service.getServiceAppointmentsByIds(new Set<Id>{sa1.Id});
        List<ServiceAppointment> byParent = service.getServiceAppointmentsByParentRecordSetIds(new Set<Id>{wo.Id});
        List<ServiceAppointment> byParentDesc = service.getSAByParentRecordIdsOrderByCreatedDateDesc(new Set<Id>{wo.Id});
        List<AggregateResult> countByParent = service.getSACountByParentRecordIds(new Set<Id>{wo.Id});
        Test.stopTest();
        System.assertEquals(1, byIds.size());
        System.assert(byParent.size() > 0);
        System.assert(byParentDesc.size() > 0);
        System.assertEquals(1, countByParent.size());
    }
}