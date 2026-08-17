@istest
public class CaseServiceTest {
    @istest
    static void testmethod1(){
 Round_Robins__c rr=new Round_Robins__c(
            Name='Service/Case Request',
            Assigned_To__c = String.valueof(1),
            Sobject__c='Case'
        );
        insert rr;
        
        Round_Robins__c Reseller=new Round_Robins__c(
            Name='Service/Resale Case Request',
            Assigned_To__c = String.valueof(1),
            Sobject__c='Case'
            
        );
        insert Reseller;
        
        Profile profileDetail = [SELECT Id FROM Profile WHERE Name='CRM Operations'];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        
        User userRecord = new User(Alias = 'Zaki', Email='Zakial@gmail.com', 
                                   EmailEncodingKey='UTF-8', LastName='Zaki Al Bakri', LanguageLocaleKey='en_US', 
                                   LocaleSidKey='en_US', ProfileId = profileDetail.id, 
                                   TimeZoneSidKey='Asia/Dubai', UserName= uniqueName+'@mail.com');
        insert userRecord;
        User userRecord2 = new User(Alias = 'Zaki2', Email='Zakial2@gmail.com', 
                                    EmailEncodingKey='UTF-8', LastName='Zaki A2l Bakri', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = profileDetail.id, 
                                    TimeZoneSidKey='Asia/Dubai', UserName= uniqueName+'3232'+'@mail.com');
        insert userRecord2;
        Round_Robin_User__c rrUser=new Round_Robin_User__c(
            Name='Hani Zaki Al Bakri -  SM',
            Round_Robin__c=rr.Id,
            Total_Open_Count__c=0,
            User__c=userRecord.id
            
        );
        insert rrUser;
        
        Round_Robin_User__c rrUser1=new Round_Robin_User__c(
            Name='Zaki Al Bakri -  SM',
            Round_Robin__c=rr.Id,
            Total_Open_Count__c=10,
            User__c=userRecord2.id
        );
        insert rrUser1;
        
        Id personRecId =Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        
        Account Acc = new Account();
        Acc.LastName__pc = 'Test class Account';
        Acc.LastName = 'Test class Account';
        Acc.PersonEmail='aaa@abc.com';
        Acc.PersonMobilePhone='123456789';
        //Address or Mobile Numbe
        Acc.RecordTypeId = personRecId;
        insert Acc;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Test class name';
        opp.AccountId = Acc.id;
        opp.CloseDate = system.today();
        opp.StageName = 'New';
        opp.ForecastCategoryName = 'Omitted';
        opp.LeadChannel__c = 'Call';
        opp.WinReason__c = 'Won - Special Discount';
        insert opp;
        Project__c testProject=new Project__c(
            Name='Test Project'
        );
        insert testProject;
        
        
        BuildingSection__c testBuilding=new BuildingSection__c(
            Name='Test Building',
            BuildingSectionCode__c='BL-CAS',
            Project__c=testProject.Id
            
        );
        insert testBuilding;
        Unit__c testUnit=new Unit__c(
            Name='test Unit',
            Status__c='Available',
            UnitType__c='Townhouse',
            BuildingSectionName__c=testBuilding.id,
            Project__c=testProject.Id,
            PropertyUsage__c='Residential',
            UnitView__c  ='Beach Side',
            FloorNumber__c='01',
            NumberOfBedrooms__c='3',
            UnitModel__c='1BHK',
            SellingPrice__c= 700000
        );
        insert testUnit;
        
        SalesOrder__c testOrder = new SalesOrder__c(
            Name = 'Test Order',
            Status__c = 'Booked',
            // Contact__c=tempContact.id,
            Unit__c =testUnit.id,
            Account__c = Acc.Id,
            Opportunity__c=Opp.Id            
        );
        insert testOrder;
        
        Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('DefaultUnit').getRecordTypeId();
        SalesOrder__c testSalesOrder1 = new SalesOrder__c(
            Name = 'Test Sales Order1',
            Status__c = 'Sold',
            //Offer__c = testOfferPromotion.Id,
            Account__c = Acc.Id,
            IsDefaulted__c = true
        );
        insert testSalesOrder1;
        Set<Id> soIds = new Set<Id>();
        soIds.add(testOrder.Id);
        soIds.add(testSalesOrder1.Id);
        
        //    Id caseRecor= Schema.SObjectType.case.getRecordTypeInfosByName().get('General_Service_Request').getRecordTypeId();
        String RecordTypeCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Social Media').getRecordTypeId();
        Case tempCase=new Case(
            CurrencyIsoCode='AED',
            Status='Draft',
            Origin='Email',
            AccountId = Acc.id,
            Main_Buyer_Share_Percentage__c=40,
            // Case_Sub_Status__c= 'Created',
            RecordTypeId=RecordTypeCaseId,
            Sales_Order__c= testOrder.id
        );
         
        insert tempCase;
    
        Account tempAcc=new Account(
            Name='test'
        );
        insert tempAcc;
        JointOwner__c tempJointOwner=new JointOwner__c(
            Account__c=tempAcc.id,
            SharePercentage__c=40,
            Case__c=tempCase.id
        );
        insert tempJointOwner;
        Case tempCase1 =new Case(
            CurrencyIsoCode='AED',
            Status='Draft',
            Origin='Email',
            Main_Buyer_Share_Percentage__c=40,
            // Case_Sub_Status__c= 'Created',
            RecordTypeId=RecordTypeCaseId,
            Sales_Order__c= testOrder.id
        );
        Case tempCase2 =new Case(
            CurrencyIsoCode='AED',
            Status='Draft',
            Origin='Email',
            Main_Buyer_Share_Percentage__c=40,
            // Case_Sub_Status__c= 'Created',
            RecordTypeId=RecordTypeCaseId,
            Sales_Order__c= testOrder.id
        );
        list<Case> insertNewList2 = new list<Case>();
        insertNewList2.add(tempCase2);
        
        list<Case> insertNewList=new list<Case>();
        insertNewList.add(tempCase1);        
        list<Case> trgNewList=new list<Case>();
        trgNewList.add(tempCase);        
        Set<id> caseid = new set<id>();
        caseid.add(id.valueof(tempCase.id));
        List<id> profileIds = new List<Id>();
        profileIds.add(profileDetail.id);
        CaseService casesev = CaseService.getInstance();
        casesev.updateUnits(trgNewList);
        casesev.insertCaseWithoutTrigger(insertNewList);
        casesev.updateCaseWithoutTrigger(trgNewList);
        casesev.getCasesByIds(caseid);
        casesev.getCasesByCaseIds(trgNewList);
        casesev.getCaseByIds(caseid);
        casesev.getCaseById(tempCase.id);
        casesev.insertCase(null);
        casesev.insertCases(null);
        casesev.updateCasesWithoutTrigger(trgNewList);
        casesev.getCasesByCreatedByIds(caseid,profileIds);
        casesev.getCasesByRecordTypeAndSalesOrder(new Set<Id>{testOrder.Id},RecordTypeCaseId);
        casesev.getCasesNVehicleParkingDetailsByIds(caseid);
        casesev.insertCaseWithoutTrigger(tempCase1);
        casesev.insertCaseWithTrigger(new List<Case>{tempCase2});
        casesev.getCaseRecordWithDocuments(tempCase.Id);
        casesev.updateCase(tempCase);
        casesev.updateAndReturnCase(tempCase);
        casesev.getCaseByIdsAndCreatedByIds(new Set<Id>{tempCase1.Id}, new Set<Id>{UserInfo.getUserId()});
        casesev.getCaseRecordWithDocuments(tempCase1.Id);
        casesev.getrelatedCaseToAccount(Acc.Id);
        casesev.updateCase(tempCase);
        casesev.updateCases(trgNewList);
        casesev.lstgetCaseRelatedtoSR(tempCase.Id);
        casesev.getRelatedCaseToAccount(tempAcc.Id, '');
        casesev.getrelatedCaseToAccount(tempAcc.Id);
        casesev.getCasesByRecordTypeAndSalesOrder(soIds, caseRecordTypeId);

        Amenities__c amenity = new Amenities__c(Name = 'Community Hall',Building_Phase__c =testBuilding.Id);
        insert amenity;

        Service_Catalog__c amenityCatalog = new Service_Catalog__c(
            Name = 'Amenities',
            Active__c = true,
            Access_To__c = 'Owner;Tenant',
            Service_Available_on_Mobile__c = true
        );
        insert amenityCatalog;

        Id communityRecordType = Utilities.getRecordTypeId('Case', 'Community General Service Request');

        Case confirmedBooking = new Case(
            Subject = 'Confirmed Amenity Booking',
            AccountId = Acc.Id,
            Project__c = testProject.Id,
            Amenities__c = amenity.Id,
            Permit_From_Date__c = Date.today(),
            startTime__c = Time.newInstance(9, 0, 0, 0),
            endTime__c = Time.newInstance(10, 0, 0, 0),
            Status = 'Confirmed',
            Service_Catalog__c = amenityCatalog.Id,
            RecordTypeId = communityRecordType
        );
        insert confirmedBooking;

        Case submittedBooking = confirmedBooking.clone(false, true, true, true);
        submittedBooking.Status = 'Submitted';
        submittedBooking.Permit_From_Date__c = Date.today().addDays(1);
        insert submittedBooking;

        Case cancelledBooking = confirmedBooking.clone(false, true, true, true);
        cancelledBooking.Status = 'Cancelled';
        cancelledBooking.Permit_From_Date__c = Date.today().addDays(2);
        insert cancelledBooking;

        casesev.getAmenityBookingsByDate(Date.today(), amenity.Id);
        casesev.fetchAmenitySlotExist(amenity.Id, Date.today(), Time.newInstance(9, 0, 0, 0));
        casesev.checkServicesByAccount(Acc.Id, Date.today());
        casesev.fetchAmenityByAccount(Acc.Id, true);
        casesev.fetchAmenityByAccount(Acc.Id, false);
        casesev.fetchBookedAmenityByDateRange(Date.today(), Date.today().addDays(3), testProject.Id, amenity.Id);
        casesev.getOpenCasesByRecordTypeAndSalesOrder(soIds, RecordTypeCaseId);
        casesev.getCasesByRecordTypeSalesOrderANDStatus(testOrder.Id, new List<Id>{RecordTypeCaseId}, 'Open');
        casesev.getCaseInstallmentByRecordId(tempCase.Id);
        casesev.getCaseMapByIds(new Set<Id>{tempCase.Id});
        casesev.getCaseByAccountId(acc.id);
    }
        @IsTest
    static void testAdditionalCaseServiceMethods() {
        
        // Account
        Account acc = new Account(
            Name = 'Broker Account'
        );
        insert acc;
        
        // Contact
        Contact con = new Contact(
            LastName = 'Broker Contact',
            AccountId = acc.Id,
            Email = 'broker@test.com'
        );
        insert con;
        
        // Record Type
        Id rtId = Schema.SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('BrokerGeneralServiceRequest')
            .getRecordTypeId();
        
        // Cases
        Case c1 = new Case(
            Subject = 'Broker Case 1',
            Status = 'New',
            ContactId = con.Id,
            AccountId = acc.Id,
            RecordTypeId = rtId,
            Type = 'Broker',
            ApprovalStatus__c = 'Pending'
        );
        
        Case c2 = new Case(
            Subject = 'Broker Case 2',
            Status = 'Closed',
            ContactId = con.Id,
            AccountId = acc.Id,
            RecordTypeId = rtId,
            Type = 'Broker'
        );
        
        insert new List<Case>{ c1, c2 };
            
            Test.startTest();
        
        CaseService cs = CaseService.getInstance();
        
        // =====================================================
        // getCasesByContactId
        // =====================================================
        
        List<Case> contactCases =
            cs.getCasesByContactId(con.Id);
        
        System.assertNotEquals(
            null,
            contactCases
        );
        
        // =====================================================
        // getBloomAppCasesByCustomerId
        // =====================================================
        
        List<Case> bloomCases =
            cs.getBloomAppCasesByCustomerId(
                new Set<Id>{ con.Id },
                'Phone'
            );
        
        // =====================================================
        // getCaseDetailsWithBrokerAppNumber
        // =====================================================
        
        List<Case> brokerCases =
            cs.getCaseDetailsWithBrokerAppNumber(
                new List<Id>{ c1.Id }
            );
        
        System.assertEquals(
            1,
            brokerCases.size()
        );
        
        // =====================================================
        // getCaseMapByIds
        // =====================================================
        
        Map<Id, Case> caseMap =
            cs.getCaseMapByIds(
                new Set<Id>{ c1.Id }
            );
        
        System.assert(
            caseMap.containsKey(c1.Id)
        );
        
        // =====================================================
        // getCaseByAccountId
        // =====================================================
        
        List<Case> accCases =
            cs.getCaseByAccountId(acc.Id);
        
        System.assertNotEquals(
            null,
            accCases
        );
        
        // =====================================================
        // getValidBrokerCaseIds
        // =====================================================
        
        Set<Id> validIds =CaseService.getValidBrokerCaseIds(new Set<Id>{ c1.Id, c2.Id },'BrokerGeneralServiceRequest');
        
        
        System.assert(
            validIds.contains(c1.Id)
        );
        
        // =====================================================
        // getCaseBySalesOrderUnitAccountId
        // =====================================================
        
        List<Case> salesCases =
            cs.getCaseBySalesOrderUnitAccountId(
                null,
                null,
                acc.Id
            );
        
        System.assertNotEquals(
            null,
            salesCases
        );
        
        Test.stopTest();
    }
    @IsTest
    static void testGetCaseByAccountIds() {
        
        // Account
        Account acc = new Account(
            Name = 'Broker Account'
        );
        insert acc;
        // Contact
        Contact con = new Contact(
            LastName = 'Broker Contact',
            AccountId = acc.Id,
            Email = 'broker@test.com'
        );
        insert con;
        
        // Record Type
        Id rtId = Schema.SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('BrokerGeneralServiceRequest')
            .getRecordTypeId();
        
        // Case
        Case c = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Origin = 'Phone',
            AccountId = acc.Id,
            ContactId = con.Id,
            RecordTypeId = rtId,
            Type = 'Broker',
            ApprovalStatus__c = 'Pending'
        );
        
        insert c;
        
        Test.startTest();
        
        List<Case> caseList =
            CaseService.getInstance()
            .getCaseByAccountIds(
                new Set<Id>{ acc.Id }
            );
        List<Case> caseList1 =
            CaseService.getInstance()
            .getNonLegalCases(
                new List<Case>{ c }
            );
        
        Test.stopTest();
        
        System.assertEquals(
            1,
            caseList.size()
        );
        
        System.assertEquals(
            acc.Id,
            caseList[0].AccountId
        );
    }
}