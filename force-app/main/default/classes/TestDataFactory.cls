/*
* @Author : Jayprakash Bharti
* @CreatedDate : 20th AUG 2024
* @Description : 
*/
/*****************************************************************************************************
* Version       Author      Date             Comment       
* 1.0           Jayprakash  20AUG2024        Test  GIS Integration Implementation
*****************************************************************************************************/
@isTest
public class TestDataFactory {
    
    public static Account createPersonalAccount(String lastName, string Emirates_Id, String phone, String email){
        Id personAccountRecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Account account = new Account();
        account.RecordTypeId = personAccountRecordTypeId;
        account.lastName = lastName;
        account.LastName__pc = lastName;
        account.Emirates_Id__pc = Emirates_Id;
        account.PersonMobilePhone = phone;
        account.PersonEmail = email;
        return account;
    }
    
    public static ServiceAction__c createServiceAction(Id catalogId,String type,String subType,String subject,String department,Integer Order){
        ServiceAction__c action = new ServiceAction__c(
            ServiceCatalog__c = catalogId,
            TaskType__c = type,
            TaskSubType__c = subType,
            TaskSubject__c = subject,
            Department__c = department,
            Due_in_days__c = 2,
            Order__c = order
        );
        return action;
    }
    
    public static ServiceAction__c createServiceActionForHandover(Id catalogId,String handoverStatus,String subType,String subject,String department,Integer Order){
        ServiceAction__c action = new ServiceAction__c(
            ServiceCatalog__c = catalogId,
            HandoverStatus__c = handoverStatus,
            TaskSubType__c = subType,
            TaskSubject__c = subject,
            Department__c = department,
            Due_in_days__c = 2,
            Order__c = order
        );
        return action;
    }
    
    public static Account createBrokerAccount(String name, Boolean blackListed, String phone){
        Id brokerAgencyAccountRecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Broker_Agency').getRecordTypeId();
        Account account = new Account();
        account.RecordTypeId = brokerAgencyAccountRecordTypeId;
        account.Name = name;
        account.Phone = phone;
        return account;
    }
    
    public static Contact createContact(String lname,String accountId, Boolean isPrimary, String email){
        Contact con = new Contact();
        con.AccountId = accountId != null ? accountId : null;
        con.Email = email != null ? email : null;
        con.PrimaryContact__c = isPrimary != null ? isPrimary : false;
        con.LastName = lname;
        return con;
    }
    
    public static Project__c createProject(String projectName){
        Project__c project = new Project__c();
        project.name = projectName;
        return Project;
    }
    
    public static Project__c createProject(String projectName, Date regDate){
        Project__c project = new Project__c();
        project.Name = projectName;
        project.ProjectRegistrationDate__c = regDate;
        return Project;
    }
    
    public static Document__c createDoc(String documentId, String salesOrderId, String projectId){
        Document__c document = new Document__c();
        document.DocumentType__c = documentId;
        document.SalesOrder__c = salesOrderId;
        document.Project__c = projectId;
        return document;
    }
    
    public static Document__c createDoc(String documentId, String brokerCommissionId, String accId, String salesOrderId, String unitId, String projectId){
        Document__c document = new Document__c();
        document.DocumentType__c = documentId;
        document.BrokerCommission__c = brokerCommissionId;
        document.Account__c = accId;
        document.SalesOrder__c = salesOrderId;
        document.Unit__c = unitId;
        document.Project__c = projectId;
        return document;
    }
    
    public static Unit__c createUnit(Id projectId, String unitName, string Status){
        Unit__c unit = new Unit__c();
        unit.Name = unitName;
        unit.Project__c = projectId;
        unit.ADMPlotNumber__c = '1001';
        unit.Status__c = Status;
        unit.SaleableArea__c = 52;
        unit.SellingPrice__c = 100000.10;
        unit.DARIRegistration__c = date.newinstance(2024, 09, 15);
        return unit;
    }
    
    public static EmailTemplate createEmailTemplate(String templateName){
        EmailTemplate validEmailTemplate = new EmailTemplate();
        validEmailTemplate.isActive = true;
        validEmailTemplate.Name = templateName;
        validEmailTemplate.DeveloperName = 'unique_name_addSomethingSpecialHere';
        validEmailTemplate.TemplateType = 'text';
        validEmailTemplate.FolderId = UserInfo.getUserId();
        return validEmailTemplate;
    }
    
    public static Lead createLead(String leadName, string phoneNumber,string emailID){
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        Lead testLead = new Lead(); 
        testLead.LastName = leadName;
        testLead.MobileCountryCode__c = '971';
        testLead.Status = 'New';
        testLead.MobilePhone = phoneNumber;
        testLead.Email = emailID;
        testLead.Lead_Channel__c = 'Call';
        testLead.LeadSource = 'Social Media'; // Using a LeadSource other than 'Broker Portal'
        testLead.leadsubsource__c='Instagram';
        testLead.OwnerId = adminUser.Id;
        return testLead;
    }    
    
    public static CommissionSchedule__c createCommissionSchedule(String project, Integer precentage, Decimal rangeStartAmount, Decimal rangeEndAmount){ 
        CommissionSchedule__c comSchedule = new CommissionSchedule__c();
        comSchedule.Project__c = project;
        comSchedule.Percentage__c = precentage;
        comSchedule.Amount_Range_Start__c = rangeStartAmount;
        comSchedule.Amount_Range_End__c = rangeEndAmount;
        return comSchedule;
    }
    
    public static Opportunity createOpportunity(String accountId, String winReason, String contact, String brokerAgencyId,String brokerAgentContact, String stageName, String closeDate, Decimal amount){
        String defaultStageName = 'Closed Won';
        Date defaultCloseDate = Date.today().addDays(30);
        Decimal defaultAmount = 10000;
        String defaultWinReason = 'Loyalty';
        // create Opportunity
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opportunity ' + System.currentTimeMillis();
        opp.AccountId = accountId != null ? accountId : null;
        opp.WinReason__c = winReason != null ? winReason : defaultWinReason;
        opp.Contact__c = contact != null ? contact : null;
        opp.BrokerAgencyAccount__c = brokerAgencyId != null ? brokerAgencyId : null;
        opp.BrokerAgentContact__c = brokerAgentContact != null ? brokerAgentContact : null;
        opp.StageName = stageName != null ? stageName : defaultStageName;
        opp.CloseDate = closeDate != null ? Date.valueOf(closeDate) : defaultCloseDate;
        opp.Amount = amount != null ? amount : defaultAmount;
        return opp;
    }
    
    public static SalesOrder__c createSalesOrder(String accountId, String oppId, String status, Date soldDate, String unit, Decimal netAmount){
        SalesOrder__c salesOrder = new SalesOrder__c();
        salesOrder.Account__c = accountId;
        salesOrder.Opportunity__c = oppId;
        salesOrder.Status__c = status;
        salesOrder.SoldDate__c = soldDate;
        salesOrder.Unit__c = unit;
        salesOrder.NetAmount__c = netAmount;
        return salesOrder;
    }
    
    public static InstallmentLines__c createInstallmentLines(String salesOrder, Decimal installmentAmount, Decimal clearedAmount, Integer installmentNumber, String paymentPlanId, String paymentInstallmentId){
        InstallmentLines__c installment = new InstallmentLines__c();
        installment.SalesOrder__c = salesOrder;
        installment.BrokerCommissionCreated__c = false;
        installment.InstallmentAmount__c = installmentAmount;
        installment.ClearedAmount__c = clearedAmount;
        installment.InstallmentNumber__c = installmentNumber;
        installment.Description__c = 'Test Description';
        installment.PaymentPlan__c = paymentPlanId;
        installment.PaymentInstallments__c = paymentInstallmentId;
        return installment;
    }
    
    public static PaymentPlan__c createPaymentPlan(String name){
        PaymentPlan__c paymentPlan = new PaymentPlan__c();
        paymentPlan.Name = name;
        paymentPlan.Description__c = 'Test description';
        return paymentPlan;
    }
    
    public static PaymentInstallments__c createPaymentInstallment(String paymentPlanId, Decimal installmentNumber, Integer installmentPercentage){
        PaymentInstallments__c paymentInstallments = new PaymentInstallments__c();
        paymentInstallments.PaymentPlan__c = paymentPlanId;
        paymentInstallments.Description__c = 'Test description';
        paymentInstallments.InstallmentNumber__c = installmentNumber;
        paymentInstallments.InstallmentPercentage__c = installmentPercentage;
        return paymentInstallments;
    }
    
    public static DocumentType__c createDocumentType(String objName, String placeholderName){
        DocumentType__c documentType = new DocumentType__c();
        documentType.ObjectType__c = objName;
        documentType.Type__c = placeholderName;
        return documentType;
    }
    
    public static Document__c createDocument(String invoiceId, String docTypeId, String docType){
        Document__c doc = new Document__c();
        doc.DocumentType__c = docTypeId;
        doc.Document_Name__c = docType;
        return doc;
    }
    
    public static ContentVersion createContentVersion(String base64, String fileName, String title) {
        ContentVersion cv = new ContentVersion();
        Blob fileBody = EncodingUtil.base64Decode(base64);
        cv.VersionData = fileBody;
        cv.Title = title;
        cv.PathOnClient = fileName;
        cv.IsMajorVersion = true;
        return cv;
    }
    
    public static ContentDocumentLink createContentDocumentLink(Id contentDocumentId, Id recordId, string shareType, string visibility) {
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = contentDocumentId;
        cdl.LinkedEntityId = recordId;
        cdl.Visibility = visibility != null ? visibility : 'AllUsers';
        cdl.ShareType = shareType!= null ? shareType : 'I';
        return cdl;
    }
    
    public static BrokerCommission__c createBrokerCommission(Decimal amount, Integer vatPercentage, String invoiceId, Date startDate, String commissionFor, String projectId, String salesOrderId, String agencyId, String agentId, String commissionScheduleId){
        BrokerCommission__c brokerCommission = new BrokerCommission__c();
        brokerCommission.CommissionAmount__c = amount != null ? amount : 15000;
        brokerCommission.Project__c = projectId != null ? projectId : null;
        brokerCommission.SalesOrder__c = salesOrderId != null ? salesOrderId : null;
        brokerCommission.Agency__c = agencyId != null ? agencyId : null;
        brokerCommission.Agent__c = agentId != null ? agentId :null;
        brokerCommission.CommissionFor__c = commissionFor != null ? commissionFor : '';
        brokerCommission.CommissionSchedule__c = commissionScheduleId != null ? commissionScheduleId : null;
        brokerCommission.VATPercentage__c = vatPercentage!= null ? vatPercentage : 5;
        brokerCommission.StartDate__c = startDate != null ? startDate : System.today();
        return brokerCommission;
    }
    
    public static User createUser(String profileId, String email, String username, String firstName, String lastName){
        User testUser = new User(
            Username = username, 
            Email = email,
            Alias = 'tuser', 
            ProfileId = profileId, 
            CommunityNickname = firstName+'_testuser',
            TimeZoneSidKey = 'America/Los_Angeles', 
            LocaleSidKey = 'en_US', 
            LanguageLocaleKey = 'en_US', 
            FirstName = firstName, 
            LastName = lastName,
            CompanyName = 'Test Company',
            EmailEncodingKey = 'UTF-8'
        );
        return testUser;
    }
    
    public static SalesTarget__c createSalesTarget(String externalIdentifier, Decimal directTargetAmount, Decimal indirectTargetAmount, String year, String quarter){
        SalesTarget__c target = new SalesTarget__c(
            ExternalIdentifier__c = externalIdentifier, 
            DirectTargetAmount__c = directTargetAmount, 
            IndirectTargetAmount__c = indirectTargetAmount, 
            Year__c = year, 
            Quarter__c = quarter,
            DCLNotAchievedCommissionPercentage__c = 4,
            DCLAchievedCommissionPercentage__c = 5,
            DCLExceededCommissionPercentage__c = 1,
            DCLDoubledCommissionPercentage__c = 2,
            DSGNotAchievedCommissionPercentage__c = 6,
            DSGAchievedCommissionPercentage__c = 7,
            DSGExceededCommissionPercentage__c = 3,
            DSGDoubledCommissionPercentage__c = 2,
            IndirectPreLaunchCommissionPercentage__c = 5,
            IndirectLaunchCommissionPercentage__c = 3,
            IndirectPostLaunchCommiPercentage__c = 2,
            DeductionsPercentage__c = 1
        );
        return target;
    }
    
    public static Project__c createProject(String projectName, Date regDate, Date preLaunchStartDate, Date preLaunchEndDate, Date launchStartDate, Date launchEndDate, Date postLaunchStartDate){
        Project__c project = new Project__c();
        project.Name = projectName;
        project.ProjectRegistrationDate__c = regDate;
        project.PreLaunchStartDate__c = preLaunchStartDate;
        project.PreLaunchEndDate__c = preLaunchEndDate;
        project.LaunchStartDate__c = launchStartDate;
        project.LaunchEndDate__c = launchEndDate;
        project.PostLaunchStartDate__c = postLaunchStartDate;
        return Project;
    }
    
    public static ReceiptAcknowledgement__c createReceiptAcknowledgement(String oppId, String paymentType, Decimal amount, String accId, String status, Date maturityDate, String salesOrderId){
        ReceiptAcknowledgement__c testRecAck1= new ReceiptAcknowledgement__c(
            Opportunity__c = oppId,
            PaymentType__c = paymentType != null ? paymentType : 'Cheque',
            Amount__c = amount,
            Account__c = accId,
            Status__c = status != null ? status : 'Received',
            MaturityDate__c = maturityDate != null ? maturityDate : System.today().addDays(3),
            SalesOrder__c = salesOrderId,
            ReferenceNumber__c = '123456'
        );
        return testRecAck1;
    }
    
    public static ReceiptAllocation__c createReceiptAllocation(Id receiptAckId, Id accId, Id installmentId, Decimal amount, Id otherChargesId){
        ReceiptAllocation__c receiptAllocation = new ReceiptAllocation__c();
        receiptAllocation.ReceiptAcknowledgement__c = receiptAckId;
        receiptAllocation.Account__c = accId;
        receiptAllocation.InstallmentLine__c = installmentId;
        receiptAllocation.AmountApplied__c = amount;
        receiptAllocation.SalesOrderOtherCharges__c = otherChargesId;
        return receiptAllocation;
    }
    
    public static BankAccount__c createBankAccount(String name, String type, String projectId){
        return new BankAccount__c(
            Name = name,
            Type__c = type,
            Project__c = projectId
        );
    }
    
    public static Case createBFMCase(String origin, String status, String description, String subject, String bfmRequestStatus,String requesterEmail, String requesterConNumber){
        Id BFMServiceRecordTypeId =  Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('BFMServiceRequest').getRecordTypeId();
        return new Case(
            RecordTypeId = BFMServiceRecordTypeId,
            Origin = origin,
            Status = status,
            Description = description,
            BFMRequestStatus__c = bfmRequestStatus,
            Subject = subject,
            RequesterEmail__c = requesterEmail,
            RequesterContactNumber__c = requesterConNumber
        );
    }
    
    public static Case createCase(String recordTypeDevName, String origin, String status, String description, String Subject, String accId, String unitId, String conId){
        Case caseObj = new Case();
        if(recordTypeDevName != null){caseObj.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(recordTypeDevName).getRecordTypeId();}
        caseObj.Origin = origin;
        caseObj.Status = status;
        caseObj.Description = description;
        caseObj.Subject = subject;
        caseObj.AccountId = accId;
        caseObj.Unit__c = unitId;
        caseObj.ContactId = conId;
        return caseObj;
    }
    
    public static ServiceCatalog__c createServiceCatalog(String name, String processType, String type, String category, String subCategory, String objNames, String recordTypeDevName){
        ServiceCatalog__c scObj = new ServiceCatalog__c();
        scObj.Name = name;
        scObj.ProcessType__c = processType; 
        scObj.Type__c = type;
        scObj.Category__c = category;
        scObj.SubCategory__c = subCategory;
        scObj.Object__c = objNames;
        scObj.RecordTypeDevName__c = recordTypeDevName;
        return scObj;
    }
    
    public static Building__c createBuilding(String buildingName, Id projectId){
        Building__c building = new Building__c();
        building.Name = buildingName;
        building.Project__c = projectId;
        return building;
    }
    
    public static Unit_Allocation__c createUnitAllocation(Boolean isActive, Id accId, Id unitId){
        Unit_Allocation__c scObj = new Unit_Allocation__c();
        scObj.Active__c = isActive;
        scObj.Account__c = accId;
        scObj.Unit__c = unitId;
        return scObj;
    }
    
    public static SalesOrderOtherCharges__c createOtherCharge(Id salesOrderId, Id accId, String typeOfCharges, Boolean sendToSAP, String category, String reason, String remarks, String conditionType, Date duedate, Decimal amount) {
        SalesOrderOtherCharges__c otherCharge = new SalesOrderOtherCharges__c(
            SalesOrder__c = salesOrderId,
            Account__c = accId,
            TypeOfCharge__c = typeOfCharges,
            SendtoSAP__c = sendToSAP,
            SAP_Condition_Type__c = conditionType,
            Due_Date__c = dueDate,
            Amount__c = amount,
            ReversalCategory__c = category,
            Reason__c = reason,
            Remarks__c = remarks
        );
        return otherCharge;
    }
    
    public static BuildingSection__c createbuildingSection(String name, String sectionCode, Id projectId){
        BuildingSection__c bs = new BuildingSection__c();
        bs.Name = Name;
        bs.BuildingSectionCode__c = sectionCode;
        bs.Project__c = projectId;
        return bs;
    }
    
    //Shruti - Added a method to create custom User records
    public static User__c createCustomUser(Boolean azureActive, Boolean isActive, String username, String name, String contactId, String accountId, String emailId, String azureUserId){
        User__c testUser = new User__c(
            Username__c = username,
            Name = name,
            Is_Azure_Active__c = azureActive,
            isActive__c = isActive,
            Contact__c = contactId,
            Azure_UserId__c = azureUserId,
            Mobile_Number__c = '2222222222',
            Email__c = emailId,
            Account__c = accountId,
            User_Type__c = 'Broker Agent'
        );
        return testUser;
    }
    
    //Shruti - Added a method to create OTP records
    public static OTP__c createOTP(Integer otpExpirationMinutes, String commType, String processType, String accountId, String contactId, String randomOtp, Boolean isVerified, String transactionId ){
        OTP__c otpData = new OTP__c(
            Email__c = 'test@test.com',
            PhoneNumber__c = '1111111111',
            TransactionId__c = transactionId,
            OTPCode__c = randomOtp,
            OTPCodeExpiration__c = DateTime.now().addMinutes(otpExpirationMinutes),
            CommunicationType__c = commType,
            ProcessType__c	= processType,
            Account__c = accountId,
            Contact__c = contactId,
            Verified__c = isVerified
        );
        return otpData;
    }
    
    //Shruti - Added a method to create OTP records
    public static Contact createBrokerContact(String lname,String accountId, Boolean isSuspended, Boolean isTerminated, Boolean isActive, String email){
        Contact con = new Contact();
        con.LastName = lname;
        con.AccountId = accountId != null ? accountId : null;
        con.Email = email != null ? email : null;
        con.IsSuspended__c = isSuspended != null ? isSuspended : false;
        con.Blacklisted__c = isTerminated != null ? isTerminated : false;
        con.SuspensionTenure__c = '2';
        return con;
    }
    
    // Rushikesh - Added method to create broker application
    public static BrokerApplication__c createBrokerApplication(String name, String typeOfEstablishment) {
        BrokerApplication__c app = new BrokerApplication__c(
            Name = name,
            TypeofEstablishment__c = typeOfEstablishment,
            ApprovalStatus__c = 'Draft',
            IsRFIUpdated__c = false,
            isRequestForReAgreement__c = false,
            TradeLicenseNumber__c = 'DLD-1234567',
            TradeLicenseExpiryDate__c = Date.today().addYears(2),
            AgencyType__c = 'LTD',
            RegisteredCountry__c = 'United Arab Emirates',
            RegisteredEmirate__c = 'Dubai',
            AgencyEmail__c = 'user@test.com',
            LicenseType__c = 'Commercial',
            IsVATRegistered__c = 'No',
            VATUndertakingIssueDate__c = Date.today().addYears(1),
            TaxRegistrationNumber__c = 'TRN-567890',
            ORNADM__c = '12345',
            AddressLine01__c = 'Initial Address Line 1',
            AddressLine02__c = 'Initial Address Line 2',
            Country__c = 'United Arab Emirates',
            Emirate__c = 'Dubai',
            City__c = 'Dubai',
            CurrentScreen__c = 'screen 3',
            CountryCode__c = '971',
            ZipCodePOBoxNumber__c = '54321',
            CompanyPhone_Number__c = '9876543210',
            Account_Number__c = '111222333',
            BankCountry__c = 'United Arab Emirates',
            BankNameValue__c= 'Emirates NBD',
            BankBranchAddress__c = 'Initial Branch',
            SwiftCode__c = 'INITSWFT',
            IBAN__c = 'AE070331234567890InitialIBAN'
        );
        insert app;
        return app;
    }
    
    // Rushikesh - Added method to create broker applicant
    public static BrokerApplicant__c createBrokerApplicant(Id applicationId) {
        BrokerApplicant__c applicant = new BrokerApplicant__c(
            BrokerContactRole__c = 'Admin',
            Title__c = 'Mr.',
            FirstName__c = 'John',
            LastName__c = 'Doe',
            Email__c = 'john@example.com',
            PhoneNumber__c = '+971501234567',
            NationalId__c = '784-1234-5678901-1',
            NationalIDExpiryDate__c = Date.today().addYears(2),
            DateOfBirth__c = Date.newInstance(1985, 5, 15),
            Country__c = 'United Arab Emirates',
            PassportNumber__c = 'P12345678',
            PassportExpiryDate__c = Date.today().addYears(1),
            Designation__c = 'CEO',
            ShareHoldingPercentage__c = 100,
            BrokerApplication__c = applicationId
        );
        insert applicant;
        return applicant;
    } 
    
    // Shruti - Added method to create broker Unit Allocation
    public static BrokerUnitAllocations__c createBrokerUnitAllocation(Id accountId, Id unitId, Boolean isActive) {
        BrokerUnitAllocations__c objBrokerUnitAllocation = new BrokerUnitAllocations__c();
        objBrokerUnitAllocation.Account__c = accountId;
        objBrokerUnitAllocation.Unit__c = unitId;
        objBrokerUnitAllocation.IsActive__c = isActive;
        return objBrokerUnitAllocation;
    }
    
    // Shruti - Added method to create broker Unit Assignment
    public static BrokerUnitAssignment__c createBrokerUnitAssignment(Id brokerUnitAllocationId, Id contactId, Boolean isActive) {
        BrokerUnitAssignment__c objBrokerUnitAssignment = new BrokerUnitAssignment__c();
        objBrokerUnitAssignment.BrokerUnitAllocation__c = brokerUnitAllocationId;
        objBrokerUnitAssignment.Contact__c = contactId;
        objBrokerUnitAssignment.Active__c = isActive;
        return objBrokerUnitAssignment;
    }
    
    public static VehicleParking__c createVehicleParking(String modelName, String plateNumber, String status, Id unitId, Id accId, Date startDate, Date endDate){
        VehicleParking__c vp = new VehicleParking__c();
        vp.VehicleMakeModel__c = modelName;
        vp.VehiclePlateNumber__c = plateNumber;
        vp.Status__c = status;
        vp.Unit__c = unitId;
        vp.CustomerName__c = accId;
        vp.StartDate__c = startDate;
        vp.EndDate__c = endDate;
        return vp;
    }
    
    public static VehicleParkingDetails__c createVehicleParkingDetails(String modelName, String plateNumber, Id unitId, Id caseId){
        VehicleParkingDetails__c vpd = new VehicleParkingDetails__c();
        vpd.VehicleMakeModel__c = modelName;
        vpd.VehiclePlateNumber__c = plateNumber;
        vpd.Unit__c = unitId;
        vpd.Case__c = caseId;
        return vpd;
    }
    
    public static Group createGroup(String name, String type) {
        Group groupObj = new Group();
        groupObj.Name = name;
        groupObj.Type = type;
        return groupObj;
    }
    
    public static User createUserWithPermissionSet(String profileName, String permSetName, String userName, String userEmail) {
        User u;

        System.runAs(new User(Id = UserInfo.getUserId())) {
            Profile p = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
            
            u = new User(
                FirstName = userName.split(' ')[0],
                LastName = 'TestUser',
                Alias = 'testU',
                Email = userEmail,
                EmailEncodingKey = 'UTF-8',
                ProfileId = p.Id,
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                TimeZoneSidKey = 'America/Los_Angeles',
                UserName = userEmail + '.test'
            );
            insert u;

            if (String.isNotBlank(permSetName)) {
                PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = :permSetName LIMIT 1];
                insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);
            }
        }
        return u;
    }

    public static CommonArea__c createCommonArea(String commonAreaCode, String commonAreaName, Id buildingId, Id projectId, Id communityId){
        CommonArea__c commonArea = new CommonArea__c();
        commonArea.Name = commonAreaCode;
        commonArea.CommonAreaName__c = commonAreaName;
        commonArea.Building__c = buildingId;
        commonArea.Project__c = projectId;
        commonArea.Community__c = communityId;
        return commonArea;
    }

    public static QMSToken__c createQMSTokenAssignment(String counterId, String counterName, String email, String eid, String name, String serviceId, String trnId){
        QMSToken__c token = new QMSToken__c();
        token.CounterId__c = counterId;
        token.CounterName__c = counterName;
        token.Email__c = email;
        token.EmiratesId__c = eid;
        token.Name__c = name;
        token.ServiceId__c = serviceId;
        token.TokenTRNId__c = trnId;
        return token;
    }


    public static QMSTokenAssignment__c createQMSTokenAssignment(String name, String email, String assignmentId, Id tokenId){
        QMSTokenAssignment__c tokenAssignment = new QMSTokenAssignment__c();
        tokenAssignment.AssignedDate__c = Date.today();
        tokenAssignment.AssignedPersonName__c = name;
        tokenAssignment.AssignedPersonEmail__c = email;
        tokenAssignment.AssignmentId__c = assignmentId;
        tokenAssignment.QMSToken__c = tokenId;
        return tokenAssignment;
    }
}