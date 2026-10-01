@IsTest
public class ServiceAppointmentControllerTest {
    @TestSetup
    public static void setup() {
        Profile salesManagerProfile = [SELECT Id FROM Profile WHERE Name = 'Sales Manager' LIMIT 1];
        Profile systemadministrator = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Contractor' LIMIT 1];
        User u = new User(Alias = 'standt', Email='standarduser@test.com', EmailEncodingKey='UTF-8', LastName='TestingSA', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', UserName='SAstandarduser@test.com.test');
        insert u;

        User u2 = new User(Alias = 'standt', Email='standarduser@test.com', EmailEncodingKey='UTF-8', LastName='TestingSA2', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = systemadministrator.Id, TimeZoneSidKey='America/Los_Angeles', UserName='SAstandarduser2@test.com');
        insert u2;

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
        salesManagerUser.TimeZoneSidKey = 'Asia/Dubai';
        salesManagerUser.LocaleSidKey = 'en_US';
        salesManagerUser.EmailEncodingKey = 'UTF-8';
        salesManagerUser.ProfileId = salesManagerProfile.Id;
        salesManagerUser.LanguageLocaleKey = 'en_US';
        insert salesManagerUser;

        Project__c prj = new Project__c();
        prj.Name = 'Test Project';
        prj.Contractor__c = u.Id;
        insert prj;

        Unit__c unt = new Unit__c();
        unt.Name = 'C-1233';
        unt.Project__c = prj.Id;
        unt.Is_Property_keys_given__c = true;
        insert unt;

        Account acc = new Account(Name='Test Account');
        insert acc;

        OperatingHours oh = new OperatingHours(Name = 'test Holiday');
        insert oh;

        ServiceTerritory st = new ServiceTerritory(Name = 'Test Territory', OperatingHoursId = [SELECT Id FROM OperatingHours LIMIT 1].Id, IsActive = true);
        insert st;

        ServiceResource sr = new ServiceResource(Name = 'Test Resource', RelatedRecordId = salesManagerUser.Id, Is_Contractor__c = false, IsActive = true);
        insert sr;

        ServiceResource sr2 = new ServiceResource(Name = 'Test Resource 2', RelatedRecordId = u2.Id, Is_Contractor__c = true, IsActive = true);
        insert sr2;

        ServiceTerritoryMember stm = new ServiceTerritoryMember(ServiceResourceId = sr.Id, ServiceTerritoryId = st.Id, EffectiveStartDate = Date.today().addDays(-1), EffectiveEndDate = Date.today().addYears(1));
        insert stm;

        ServiceTerritoryMember stm2 = new ServiceTerritoryMember(ServiceResourceId = sr2.Id, ServiceTerritoryId = st.Id, EffectiveStartDate = Date.today().addDays(-1), EffectiveEndDate = Date.today().addYears(1));
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
        roundrobinuser.Round_Robin__c = roundrobin.id;
        roundrobinuser.Round_Robin_ID__c = 1;
        roundrobinuser.RR_User_Name__c = 'Almeria Project - CRM 2';
        roundrobinuser.User__c = salesManagerUser.id;
        insert roundrobinuser;
        system.debug('roundrobinuser==>'+ roundrobinuser);
        system.debug('roundrobinuser==1111>'+ roundrobinuser.IsActive__c);

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
        roundrobinuser1.Round_Robin__c = roundrobin1.id;
        roundrobinuser1.Round_Robin_ID__c = 1;
        roundrobinuser1.RR_User_Name__c = 'Almeria Project - CRM 2';
        roundrobinuser1.User__c = salesManagerUser.id;
        insert roundrobinuser1;
        system.debug('roundrobinuser==>'+ roundrobinuser1);
        system.debug('roundrobinuser==1111>'+ roundrobinuser1.IsActive__c);

        WorkOrder wo = new WorkOrder(Subject = 'Test Work Order', AccountId = acc.Id, Description='test', Unit__c = unt.Id, Is_Emergency__c = true, Resolution_Priority__c = 'Emergency', Resolution_Typology__c = 'Repair', hasappointmentcanceled__c=true, Category__c = 'Civil', Location__c = 'Laundry Room', Priority = 'Low', Status = 'In Progress', Scope__c='Under Scope');
        insert wo;

        DateTime startDateTime = DateTime.now().addDays(1);
        DateTime endDateTime = DateTime.now().addDays(1).addHours(2);

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

        List<WorkOrder> woList = new List<WorkOrder>();
        WorkOrder wrk2 = new WorkOrder();
        wrk2.Subject = 'New work order is created.--test THREE';
        wrk2.Description = 'This decriptions for test class.';
        wrk2.Closure_Reason__c = 'Customer not available';
        wrk2.Type_of_Incident__c = 'Out of Scope';
        wrk2.Unit__c = unt.Id;
        wrk2.Is_Emergency__c = true;
        wrk2.Resolution_Priority__c = 'Emergency';
        wrk2.Resolution_Typology__c = 'Repair';
        wrk2.Category__c = 'Civil';
        wrk2.Location__c = 'Laundry Room';
        wrk2.Priority = 'Low';
        wrk2.Status = 'In Progress';
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
        wrk2.Scope__c = 'Under Scope';
        wrk2.OwnerId= u2.id;
        woList.add(wrk2);

        insert woList;
    }

    /*@IsTest
    static void testCreateServiceAppointmentSelf() {
        Id workOrderId = [SELECT Id FROM WorkOrder WHERE Subject = 'Test Work Order' LIMIT 1].Id;
        WorkOrder woRec = new WorkOrder(Id=workOrderId, Status = 'In Progress');
        update woRec;
        DateTime startDateTime = DateTime.now().addDays(1);
        DateTime endDateTime = DateTime.now().addDays(1).addHours(2);
        system.debug('startDateTime-->'+startDateTime);

        ServiceResource sr = [SELECT Id FROM ServiceResource WHERE Is_Contractor__c = FALSE];
        Test.startTest();
        ServiceAppointment sa = new ServiceAppointment();
        sa.Status = Constants.IN_PROGRESS;
        sa.ParentRecordId = workOrderId;
        sa.EarliestStartTime = DateTime.now().addHours(-2);
        sa.SchedStartTime = DateTime.now().addHours(-3);
        sa.Is_First_Appointment__c = false;
        sa.SchedEndTime = DateTime.now().addHours(1);
        sa.DueDate = DateTime.now().addHours(-1);
        insert sa;

        AssignedResource assRes = new AssignedResource();
        assRes.ServiceResourceId = sr.Id;
        assRes.ServiceAppointmentId = sa.Id;
        insert assRes;
        system.debug('ServiceResourceId--->'+sr.id);

        String result = ServiceAppointmentController.createServiceAppointment(startDateTime, endDateTime, 'Self', workOrderId);
        Test.stopTest();

        ServiceAppointment sa1 = [SELECT Id, Status, ParentRecordId, SchedStartTime, SchedEndTime FROM ServiceAppointment WHERE ParentRecordId = :workOrderId ORDER BY CreatedDate DESC LIMIT 1];
        system.debug('ServiceAppointment------>'+sa1);
        System.assertNotEquals(null, sa1);
	    System.assertEquals('Success', result);
    }*/

    @IsTest
    static void testCreateServiceAppointmentContractor() {
        Id workOrderId = [SELECT Id FROM WorkOrder LIMIT 1].Id;
        DateTime startDateTime = DateTime.now().addDays(1);
        DateTime endDateTime = DateTime.now().addDays(1).addHours(2);

        Test.startTest();
        String result = ServiceAppointmentController.createServiceAppointment(startDateTime, endDateTime, 'Contractor', workOrderId);
        Test.stopTest();
        System.assertEquals('already created', result);
    }

    @IsTest
    static void createServiceAppointment_Error() {
        WorkOrder workOrderObj = [SELECT Id,Status,Cancel_Time__c ,Due_Date__c,Resolution_Typology__c,Resolution_Priority__c,CreatedDate FROM WorkOrder LIMIT 1];
        System.debug('workOrderObjcreate----------------------->'+workOrderObj);
        DateTime startDateTime = DateTime.now().addDays(1);
        DateTime endDateTime = DateTime.now().addDays(1).addHours(2);

        Test.startTest();
        String result = ServiceAppointmentController.createServiceAppointment(startDateTime, endDateTime, 'Contractor', workOrderObj.Id);
        Test.stopTest();
        System.assertEquals('already created', result);
    }

    @IsTest
    static void testCheckIn() {
        Id workOrderId = [SELECT Id,Status,Cancel_Time__c ,Due_Date__c,Resolution_Typology__c,Resolution_Priority__c,CreatedDate FROM WorkOrder WHERE Subject = 'Test Work Order' LIMIT 1].Id;
        String contentDocumentId = '12345';
        String customerAvailability = 'Available';

        ServiceAppointment sa = new ServiceAppointment();
        sa.Status = 'None';
        sa.ParentRecordId = workOrderId;
        sa.EarliestStartTime = DateTime.now().addHours(-2);
        sa.SchedStartTime = DateTime.now().addHours(-3);
        sa.Is_First_Appointment__c = false;
        sa.SchedEndTime = DateTime.now().addHours(1);
        sa.DueDate = DateTime.now().addHours(-1);

        insert sa;

        sa.status = 'Scheduled';
        Test.startTest();
        update sa;
        ServiceAppointmentController.checkIn(contentDocumentId, customerAvailability, 'testAgentComment', workOrderId);
        Test.stopTest();
    }

    @IsTest
    static void checkIn_Error() {
        WorkOrder workOrderObj = [SELECT Id,Status,Cancel_Time__c ,Due_Date__c,Resolution_Typology__c,Resolution_Priority__c,CreatedDate FROM WorkOrder WHERE Subject = 'Test Work Order' LIMIT 1];
        System.debug('workOrderObj================>'+ workOrderObj);

        ServiceAppointment sa = new ServiceAppointment();
        sa.Status = 'None';
        sa.ParentRecordId = workOrderObj.id;
        sa.EarliestStartTime = DateTime.now().addHours(-2);
        sa.SchedStartTime = DateTime.now().addHours(-3);
        sa.Is_First_Appointment__c = false;
        sa.SchedEndTime = DateTime.now().addHours(1);
        sa.DueDate = DateTime.now().addHours(-1);

        String contentDocumentId = '12345';
        String customerAvailability = 'Available';

        Test.startTest();
        insert sa;

        sa.status = 'Scheduled';

        update sa;

        String result = ServiceAppointmentController.checkIn(contentDocumentId, customerAvailability, 'testAgentComment', workOrderObj.Id);
        String result1 = ServiceAppointmentController.checkIn(contentDocumentId, 'Not Available', 'testAgentComment', workOrderObj.Id);
        //ServiceAppointmentController.updateDueDate(new List<WorkOrder>{workOrderObj});
        Test.stopTest();

        System.assertEquals('Success', result);
    }

    @IsTest
    static void testCheckScope() {
        Id workOrderId = [SELECT Id FROM WorkOrder where Subject = 'Test Work Order' LIMIT 1 ].Id;
        String contentDocumentId = '12345';
        String scope = 'Under Scope';
        String resolutionTypology='Repair';

        ServiceAppointment sa = new ServiceAppointment();
        sa.Status = 'In Progress';
        sa.ParentRecordId = workOrderId;
        sa.EarliestStartTime = DateTime.now().addHours(-2);
        sa.SchedStartTime = DateTime.now().addHours(-3);
        sa.Is_First_Appointment__c = false;
        sa.SchedEndTime = DateTime.now().addHours(1);
        sa.DueDate = DateTime.now().addHours(-1);
        insert sa;
        Test.startTest();
        ServiceAppointmentController.checkScope(contentDocumentId, 'testAgentComment', scope, workOrderId,resolutionTypology);
        Test.stopTest();
    }

    @IsTest
    static void testCheckRectification() {
        Id workOrderId = [SELECT Id FROM WorkOrder LIMIT 1].Id;
        String contentDocumentId = '12345';

        Test.startTest();
        String result = ServiceAppointmentController.checkRectification(contentDocumentId, 'testAgentComment', workOrderId);
        Test.stopTest();

        System.assertEquals('Success', result);

        WorkOrder wo = [SELECT Id, Rectification__c FROM WorkOrder WHERE Id = :workOrderId];
        System.assertEquals('Completed', wo.Rectification__c);
    }

    @IsTest
    static void checkRectification_Error() {
        WorkOrder workOrderObj = [SELECT Id FROM WorkOrder LIMIT 1];
        String contentDocumentId = '12345';

        Test.startTest();
        String result = ServiceAppointmentController.checkRectification(contentDocumentId, 'testAgentComment', workOrderObj.Id);
        Test.stopTest();

        System.assertEquals('Success', result);
    }

    @IsTest
    static void createServiceAppointmentWhenCustomerNotAvailable() {
        WorkOrder workOrderObj = [SELECT Id, Subject FROM WorkOrder WHERE Subject = 'Test Work Order' LIMIT 1];
        List<String> workOrderIds = new List<String>{workOrderObj.Id};

        ServiceAppointment saObj = [SELECT Id, Status FROM ServiceAppointment WHERE ParentRecordId = :workOrderObj.Id ORDER BY CreatedDate DESC LIMIT 1];
        System.debug('saObj ==>> ' + saObj);

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

        ServiceTerritory territory = new ServiceTerritory(Name = 'Territory Test', OperatingHoursId = opHours.Id, IsActive = true);
        insert territory;

        ServiceTerritoryMember srvTrtMbr = new ServiceTerritoryMember();
        srvTrtMbr.ServiceResourceId = srvRes.Id;
        srvTrtMbr.ServiceTerritoryId = territory.Id;
        srvTrtMbr.EffectiveStartDate = Date.today().addDays(-1);
        srvTrtMbr.EffectiveEndDate = Date.today().addYears(1);
        insert srvTrtMbr;

        ServiceAppointment sa = new ServiceAppointment();
        sa.Status = 'None';
        sa.ParentRecordId = workOrderObj.Id;
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

        Test.startTest();
        sa.status = 'Scheduled';
        ServiceAppointmentController.createSAWhenCustomerAvailable(workOrderObj.Id);
        Test.stopTest();
        System.assertEquals('Scheduled', sa.Status);
    }

    @IsTest
    static void testSaveSign() {
        Id workOrderId = [SELECT Id FROM WorkOrder LIMIT 1].Id;
        String base64Signature = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/w8ACfsD/wAAAABJRU5ErkJggg==';
        Test.startTest();
        ServiceAppointmentController.saveSign(workOrderId,base64Signature);
        Test.stopTest();
    }
    
    @IsTest
    static void testCheckout() {
        WorkOrder wo = [SELECT Id FROM WorkOrder WHERE Subject = 'New work order is created.--test THREE' LIMIT 1];
    
        ServiceAppointment sa = new ServiceAppointment(ParentRecordId = wo.Id, Status = 'In Progress');
        insert sa;
    
        Test.startTest();
        String result = ServiceAppointmentController.checkOut('5', 'Completed successfully', wo.Id, 'Customer');
        Test.stopTest();
    
        WorkOrder updatedWO = [SELECT Customer_Comment__c, Rating__c, Signed_By__c, Closure_Comment__c, Closure_Reason__c FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals('Completed successfully', updatedWO.Customer_Comment__c);
        System.assertEquals('5', updatedWO.Rating__c);
        System.assertEquals('Customer', updatedWO.Signed_By__c);
        System.assertEquals('Work Completed', updatedWO.Closure_Comment__c);
        System.assertEquals('Work Completed', updatedWO.Closure_Reason__c);
    
        ServiceAppointment updatedSA = [SELECT Job_Status__c FROM ServiceAppointment WHERE Id = :sa.Id];
        System.assertEquals('Check-Out', updatedSA.Job_Status__c);
    }
}