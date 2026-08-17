@isTest
public class AppRegistrationTriggerHelperTest {
    private static final string POST_SALE_PAYMENT_DEFERRAL { get { return 'Postpone/Defer payment'; } }
    private static final string BFM_SERVICE_REQUEST { get { return 'BFM Service Request'; } }
    private static final string FINANCIAL_PAYMENT_SERVICE_CATEGORY{ get { return 'Financial - Payment Service'; } }
    private static final string SERVICE_COMPLAINT { get { return 'Complaint'; } }
    private static final string  CRM_CATEGORY{ get { return 'CRM'; } }
    private static final string  BFM_SERVICE_CATEGORY{ get { return 'BFM Service'; } }
    private static final string SERVICE_REQUEST { get { return 'Service Request'; } }
    
    @testSetup
    static void setupData() {
        // Create test Account
        Account acc = new Account(FirstName = 'Jane', LastName = 'Doe', PersonEmail = 'test@test.com');
        insert acc;
        
        // Create test Contact
        Contact con = new Contact(FirstName = 'John', LastName = 'Doe', Email = 'test@gmail.com');
        insert con;
        
        Contact con2 = new Contact(FirstName = 'John', LastName = 'Doe', Email = 'test2@bloomholding.com', MobilePhone = '+971 (987)6543210');
        insert con2;
        
        // Create Project (nested relationship in InstallmentLines__c)
        Project__c project = new Project__c(Name = 'Test Project', EnableLatePaymentFee__c = true);
        insert project;
        
        // Create Building
        Building__c building = TestDataFactory.createBuilding('Building 1', project.Id);
        insert building;
        
        // Create Unit
        Unit__c unit = new Unit__c(Name = 'Test Unit', Project__c = project.Id);
        insert unit;
        
        // Create Sales Order
        SalesOrder__c so = new SalesOrder__c(
            Name = 'SO-001',
            Status__c = 'Active',
            Account__c = acc.Id,
            Contact__c = con.Id,
            Unit__c = unit.Id,
            //Broker_Agency__c = 'Test Broker',
            SoldDate__c = Date.today()
        );
        insert so;
        
        // Create InstallmentLines__c records
        List<InstallmentLines__c> installments = new List<InstallmentLines__c>{
            new InstallmentLines__c(
                SalesOrder__c = so.Id,
                InstallmentNumber__c = 1,
                //PendingAmount__c = 5000,
                InstallmentAmount__c = 10000,
                ClearedAmount__c = 5000,
                //Due_Date__c = Date.today().addDays(5),
                InstallmentDate__c = Date.today().addDays(3),
                InstallmentPercentage__c = 40,
                BrokerCommissionCreated__c = false,
                Type__c = 'Handover',
                Description__c = 'test description'
            ),
                new InstallmentLines__c(
                    SalesOrder__c = so.Id,
                    InstallmentNumber__c = 2,
                    InstallmentPercentage__c = 20,
                    //PendingAmount__c = 8000,
                    InstallmentAmount__c = 10000,
                    ClearedAmount__c = 2000,
                    //Due_Date__c = Date.today().addDays(-2),
                    InstallmentDate__c = Date.today().addDays(-3),
                    BrokerCommissionCreated__c = false,
                    Type__c = 'Post Handover Installment',
                    Description__c = 'test description'
                )
                };
                    insert installments;
        
        List<Case> caseList = new List<Case>();
        for(Integer i = 0; i<10; i++){
            Case caseBFMObj = TestDataFactory.createBFMCase('Email', 'New', 'Test description', 'Test Subject',null,'test@gmail.com','0123456789');
            caseBFMObj.AccountId = acc.Id;
            caseBFMObj.SuppliedEmail = 'test123@gmail.com';
            caseList.add(caseBFMObj);
        }
        insert caseList;
        
        List<ServiceCatalog__c> scList = new List<ServiceCatalog__c>();
        ServiceCatalog__c scBFM = TestDataFactory.createServiceCatalog('BFM', 'Sales', 'Service Request', 'BFM Service', 'BFM Service Request', 'Account;Sales Order;Unit', 'BFMServiceRequest');
        scBFM.AvailableForOwner__c = true;scBFM.AvailableForTenant__c = true;
        ServiceCatalog__c scPost = TestDataFactory.createServiceCatalog('BFM', 'Sales', 'Service Request', 'Financial - Payment Service', POST_SALE_PAYMENT_DEFERRAL, 'Account;Sales Order;Unit', 'Post_Sale_Payment_Deferral');
        scPost.AvailableForOwner__c = true;
        scList.add(scBFM); scList.add(scPost);
        
        ServiceCatalog__c testServiceCatalog = new ServiceCatalog__c(
            Name = 'Test Service Catalog',
            Type__c = 'Service Request',
            Category__c = 'Financial - Payment Service',
            SubCategory__c = 'Third Party Form',
            RecordTypeDevName__c = 'ThirdPartyForm',
            AvailableForOwner__c = true
        );
        scList.add(testServiceCatalog);
        
        ServiceCatalog__c testServiceCatalog1 = new ServiceCatalog__c(
            Name = 'Test Service Catalog',
            Type__c = 'Service Request',
            Category__c = 'Financial - Payment Service',
            SubCategory__c = 'Payment',
            RecordTypeDevName__c = 'Payment_Sr',
            AvailableForOwner__c = true
        );
        scList.add(testServiceCatalog1);
        ServiceCatalog__c testServiceCatalog2 = new ServiceCatalog__c(
            Name = 'Test Service Catalog',
            Type__c = 'Service Request',
            Category__c = 'Customer Service Request',
            SubCategory__c = 'KYC Update Request',
            RecordTypeDevName__c = 'KYCUpdateRequest',
            AvailableForOwner__c = true,
            IsAvailableForSuperApp__c = true
        );
        scList.add(testServiceCatalog2);
        ServiceCatalog__c testServiceCatalog3 = new ServiceCatalog__c(
            Name = 'Test Service Catalog',
            Type__c = 'Service Request',
            Category__c = 'Financial - Payment Service',
            SubCategory__c = 'Payment Due Date Update',
            RecordTypeDevName__c = 'Payment_Due_Date_Update',
            AvailableForOwner__c = true
        );
        scList.add(testServiceCatalog3);
        
        insert scList;
        
        List<AppRegistration__c> lstApp = new List<AppRegistration__c>();
        AppRegistrationService service = AppRegistrationService.getInstance();
        AppRegistration__c objApp = new AppRegistration__c(Contact__c = con.Id,DeviceId__c = '123',EmiratesID__c = '678543',
                                                           PassportNumber__c = '765437',Email__c = 'test@bloomholding.com',FirstName__c = 'Test',
                                                           MiddleName__c = 'Test',LastName__c = 'Test',MobileCountryCode__c = '971',MobilePhone__c = '9876543210',
                                                           Nationality__c = 'United Arab Emirates',RegistrationType__c = 'Manual');
        service.insertAppRegistration(objApp);
        service.updateAppRegistration(objApp);
        AppRegistration__c objApp1 = new AppRegistration__c(Contact__c = con2.Id,DeviceId__c = '123',EmiratesID__c = '6785435',
                                                            PassportNumber__c = '765437',Email__c = 'test2@bloomholding.com',FirstName__c = 'Test1',
                                                            MiddleName__c = 'Test1',LastName__c = 'Test1',MobileCountryCode__c = '971',MobilePhone__c = '9876543210',
                                                            Nationality__c = 'United Arab Emirates',RegistrationType__c = 'Manual');
        lstApp.add(objApp1);
        service.insertAppRegistrations(lstApp);
        service.updateAppRegistrations(lstApp);
    }
    
    @isTest
    static void testAppRegistrationService1() {
        Contact objContact = [SELECT Id FROM Contact LIMIT 1];
        AppRegistrationService service = AppRegistrationService.getInstance();
        AppRegistration__c objApp = service.getAppRegistration(objContact.Id, 'Test', 'Test', 'Test', '678543', '765437', 'United Arab Emirates', '971', '9876543210', 'test@bloomholding.com', '123', 'Manual');
    }
    
    @isTest
    static void testAppRegistrationService2() {
        Contact objContact = [SELECT Id FROM Contact LIMIT 1];
        AppRegistrationService service = AppRegistrationService.getInstance();
        List<AppRegistration__c> lstApp = service.getExistingAppRegistration('678543', '765437', 'United Arab Emirates');
    }
    
    @isTest
    static void testAppRegistrationService3() {
        Contact objContact = [SELECT Id FROM Contact LIMIT 1];
        AppRegistration__c objApp = [SELECT Id FROM AppRegistration__c LIMIT 1];
        AppRegistrationService service = AppRegistrationService.getInstance();
        List<AppRegistration__c> lstApp = service.getAppRegistrationById(objApp.Id);
        List<AppRegistration__c> lstApp1 = service.getAppRegistrationByContactId(objContact.Id);
    }
}