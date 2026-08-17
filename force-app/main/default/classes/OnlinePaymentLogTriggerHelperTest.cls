@isTest
public class OnlinePaymentLogTriggerHelperTest {
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
        
        // Create Project (nested relationship in InstallmentLines__c)
        Project__c project = new Project__c(Name = 'Test Project', EnableLatePaymentFee__c = true);
        insert project;
        
        // Create Building
        Building__c building = TestDataFactory.createBuilding('Building 1', project.Id);
        insert building;
        
        // Create Unit
        Unit__c unit = new Unit__c(Name = 'Test Unit', Project__c = project.Id);
        insert unit;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = acc.Id,
            WinReason__c = 'New Project Launch'
        );
        insert opp;
        
        // Create Sales Order
        SalesOrder__c so = new SalesOrder__c(
            Name = 'SO-001',
            Status__c = 'Active',
            Account__c = acc.Id,
            Contact__c = con.Id,
            Unit__c = unit.Id,
            Opportunity__c = opp.Id,
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
        
        SalesOrderOtherCharges__c oc = new SalesOrderOtherCharges__c(
            SalesOrder__c = so.Id,
            TypeOfCharge__c = 'Service Charge',
            Amount__c = 200,
            Due_Date__c = Date.today().addDays(5)
            //Status__c = 'Pending'
        );
        insert oc;
        
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
            Category__c = 'General Enquiry',
            SubCategory__c = 'General Enquiry',
            RecordTypeDevName__c = 'GeneralEnquiry',
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
        
        List<OnlinePaymentLog__c> lstPaymentLog = new List<OnlinePaymentLog__c>();
        OnlinePaymentLogService service = OnlinePaymentLogService.getInstance();
        OnlinePaymentLog__c objPaymentLog = new OnlinePaymentLog__c(Contact__c = con.Id,JSONData__c = '{"transactionId":"TX123","amount":100}',IsProcessed__c = true,
                                                                    TransactionStatus__c = 'Success');
        insert objPaymentLog;
        
        OnlinePaymentLog__c objPaymentLog1 = new OnlinePaymentLog__c(Contact__c = con.Id,JSONData__c = '{"transactionId":"TX123","amount":100}',IsProcessed__c = true,
                                                                     TransactionStatus__c = 'Failed');       
        insert objPaymentLog1;
        lstPaymentLog.add(objPaymentLog1);
        service.updateOnlinePaymentLog(lstPaymentLog);
    }
    
    @isTest
    static void testOnlinePaymentLogService1() {
        Contact objContact = [SELECT Id FROM Contact LIMIT 1];
        OnlinePaymentLogService service = OnlinePaymentLogService.getInstance();
        //AppRegistration__c objApp = service.getAppRegistration(objContact.Id, 'Test', 'Test', 'Test', '678543', '765437', 'United Arab Emirates', '971', '9876543210', 'test@bloomholding.com', '123', 'Manual');
    }
    
    @isTest
    static void testOnlinePaymentLogService2() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        
        InstallmentLines__c inst = [SELECT Id FROM InstallmentLines__c LIMIT 1];
        
        SalesOrderOtherCharges__c soc = [SELECT Id FROM SalesOrderOtherCharges__c LIMIT 1];
        
        String paymentJson = '{"instalments":[{"id":"' + inst.Id + '","paid_amount":1000,"technology_fee":50}],"other_charges":[{"id":"' + soc.Id + '","paid_amount":500,"technology_fee":25}]}';
        
        OnlinePaymentLog__c log = new OnlinePaymentLog__c(
            Contact__c = con.Id,
            TransactionStatus__c = 'Success',
            JSONData__c = paymentJson
        );
        
        Test.startTest();
        insert log;
        Test.stopTest();
        delete log;
    }
    
}