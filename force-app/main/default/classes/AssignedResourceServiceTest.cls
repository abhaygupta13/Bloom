@isTest
public class AssignedResourceServiceTest {
    @TestSetup
    static void setupTestData() {
        Map<String, Id> profileMap = new Map<String, Id>();
        for (Profile p : [SELECT Id, Name FROM Profile WHERE Name IN ('Sales Manager', 'Contractor')]) {
            profileMap.put(p.Name, p.Id);
        }
        String uStr = UserInfo.getOrganizationId() + DateTime.now().getTime();
        List<User> users = new List<User>{
            new User(Alias='standt', Email='standarduser1@test.com', EmailEncodingKey='UTF-8', LastName='User1', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId=profileMap.get('Contractor'), TimeZoneSidKey='America/Los_Angeles', UserName='usr1' + uStr + '@test.com'),
            new User(Alias='standt2', Email='standarduser2@test.com', EmailEncodingKey='UTF-8', LastName='User2', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId=profileMap.get('Sales Manager'), TimeZoneSidKey='America/Los_Angeles', UserName='usr2' + uStr + '@test.com'),
            new User(Alias='JohnD', Email='johndoe@gmail.com', EmailEncodingKey='UTF-8', LastName='John Doe', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId=profileMap.get('Sales Manager'), TimeZoneSidKey='America/Los_Angeles', UserName='sm' + uStr + '@mail.com')
        };
        insert users;
        Account acc = new Account(Name='Test Account');
        insert acc;
        OperatingHours opHours = new OperatingHours(Name='Standard Hours');
        insert opHours;
        ServiceTerritory territory = new ServiceTerritory(Name='Main Territory', OperatingHoursId=opHours.Id, IsActive=true);
        insert territory;
        List<ServiceResource> srvResList = new List<ServiceResource>{
            new ServiceResource(Name='Test Resource', RelatedRecordId=users[2].Id, Is_Contractor__c=false, IsActive=true),
            new ServiceResource(Name='Test Resource 2', RelatedRecordId=users[1].Id, Is_Contractor__c=true, IsActive=true)
        };
        insert srvResList;
        List<ServiceTerritoryMember> stmList = new List<ServiceTerritoryMember>{
            new ServiceTerritoryMember(ServiceResourceId=srvResList[0].Id, ServiceTerritoryId=territory.Id, EffectiveStartDate=Date.today().addDays(-1), EffectiveEndDate=Date.today().addYears(1)),
            new ServiceTerritoryMember(ServiceResourceId=srvResList[1].Id, ServiceTerritoryId=territory.Id, EffectiveStartDate=Date.today().addDays(-1), EffectiveEndDate=Date.today().addYears(1))
        };
        insert stmList;
        Project__c prj = new Project__c(Name='Test Project', Contractor__c=users[0].Id);
        insert prj;
        Unit__c unt = new Unit__c(Name='C-1233', Project__c=prj.Id, Is_Property_keys_given__c  = true);
        insert unt;
        List<Round_Robins__c> rrs = new List<Round_Robins__c>{
            new Round_Robins__c(Name='Service/Case Request', Assigned_To__c='2', Project__c=prj.Id, OwnerId=users[0].Id, Sobject__c='Case'),
            new Round_Robins__c(Name='Service/Resale Case Request', Assigned_To__c='2', Project__c=prj.Id, OwnerId=users[0].Id, Sobject__c='Case')
        };
        insert rrs;
        List<Round_Robin_User__c> rrUsers = new List<Round_Robin_User__c>{
            new Round_Robin_User__c(Name='CRM 2', Total_Open_Count__c=3, Round_Robin__c=rrs[0].Id, Round_Robin_ID__c=1, RR_User_Name__c='Almeria Project - CRM 2', User__c=users[1].Id),
            new Round_Robin_User__c(Name='CRM 2', Total_Open_Count__c=3, Round_Robin__c=rrs[1].Id, Round_Robin_ID__c=1, RR_User_Name__c='Almeria Project - CRM 2', User__c=users[2].Id)
        };
        insert rrUsers;
        WorkOrder wrk = new WorkOrder(Subject='Test Work Order', AccountId=acc.Id, Status='New', Unit__c=unt.Id, Contractor__c=users[0].Id);
        insert wrk;
        DateTime startDt = DateTime.now().addDays(1);
        DateTime endDt = startDt.addHours(2);
        ServiceAppointment sa = new ServiceAppointment(Status=Constants.SCHEDULED, ParentRecordId=wrk.Id, EarliestStartTime=startDt, SchedStartTime=startDt, Is_First_Appointment__c=false, SchedEndTime=endDt, DueDate=endDt);
        insert sa;
        insert new WorkType(Name='DLP', EstimatedDuration=2, DurationType='Hours');
        AssignedResource ase = new AssignedResource(ServiceResourceId=srvResList[0].Id, ServiceAppointmentId=sa.Id);
        AssignedResourceService.getInstance().insertAssignedResources(new List<AssignedResource>{ase});
    }
    
    @isTest
    static void sendMailWhenServiceAppointmentScheduled_Test() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        ServiceAppointment sa = new ServiceAppointment(Status=Constants.IN_PROGRESS, ParentRecordId=wo.Id, EarliestStartTime=DateTime.now().addHours(-2), SchedStartTime=DateTime.now().addHours(-3), Is_First_Appointment__c=false, SchedEndTime=DateTime.now().addHours(1), DueDate=DateTime.now().addHours(-1));
        insert sa;
        ServiceResource sr = [SELECT Id FROM ServiceResource LIMIT 1];
        AssignedResource assRes3 = new AssignedResource(ServiceResourceId=sr.Id, ServiceAppointmentId=sa.Id);
        AssignedResourceService aa = AssignedResourceService.getInstance();
        Test.startTest();
        aa.insertAssignedResourcesWithoutTrigger(new List<AssignedResource>{assRes3});
        assRes3.Transaction = 'test';
        aa.updateServiceAppointmentsWithoutTrigger(new List<AssignedResource>{assRes3});
        assRes3.Transaction = 'test 2';
        aa.updateUnits(new List<AssignedResource>{assRes3});
        Test.stopTest();
    }
}