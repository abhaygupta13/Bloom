@isTest
private class InstallmentLineServiceTest {

    @testSetup
    static void setupData() {
        // Create test Account
        Account acc = new Account(FirstName = 'Jane', LastName = 'Doe', PersonEmail = 'test@test.com');
        insert acc;

        // Create test Contact
        Contact con = new Contact(FirstName = 'John', LastName = 'Doe');
        insert con;

        // Create Project (nested relationship in InstallmentLines__c)
        Project__c project = new Project__c(Name = 'Test Project', EnableLatePaymentFee__c = true);
        insert project;

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
    }

    @isTest
    static void testGetInstance() {
        InstallmentLineService service = InstallmentLineService.getInstance();
        System.assertNotEquals(null, service);
    }

    @isTest
    static void testGetInstallmentLinesBySalesOrder() {
        List<SalesOrder__c> soList = [SELECT Id FROM SalesOrder__c LIMIT 1];
        Set<Id> salesOrderIds = new Set<Id>{soList[0].Id};
        List<InstallmentLines__c> result = InstallmentLineService.getInstance().getInstallmentLinesBySalesOrder(salesOrderIds);
        System.assertNotEquals(0, result.size());
    }

    @isTest
    static void testGetHOAndPHPPInstallmentLinesBySalesOrderIds() {
        List<SalesOrder__c> soList = [SELECT Id FROM SalesOrder__c LIMIT 1];
        Set<Id> salesOrderIds = new Set<Id>{soList[0].Id};
        List<InstallmentLines__c> result = InstallmentLineService.getInstance().getHOAndPHPPInstallmentLinesBySalesOrderIds(salesOrderIds);
        InstallmentLineService.getInstance().updateInstallmentLinesLists(result);
        InstallmentLineService.getInstance().getInstallmentLinesBySalesOrderId(soList[0].Id);
        System.assertEquals(2, result.size());
    }

    @isTest
    static void testGetInstallmentLinesByProjectIds() {
        List<String> excludedStatuses = new List<String>{'Cancelled'};
        Date today = Date.today();
        Date endDate = today.addDays(30);
        Set<Id> projectIds = new Set<Id>{[SELECT Id FROM Project__c LIMIT 1].Id};
        Id projectId = [SELECT Id FROM Project__c LIMIT 1].Id;
        List<InstallmentLines__c> result = InstallmentLineService.getInstance()
            .getInstallmentLinesByProjectIds(projectIds, excludedStatuses, today, endDate);
        InstallmentLineService.getInstance()
            .getInstallmentLinesByProjectAndDueDate(projectId, today);
        System.assert(result.size() > 0);
    }

    @isTest
    static void testGetAllInstallmentLinesBySalesOrder() {
        List<SalesOrder__c> soList = [SELECT Id FROM SalesOrder__c LIMIT 1];
        Set<Id> salesOrderIds = new Set<Id>{soList[0].Id};
        List<InstallmentLines__c> result = InstallmentLineService.getInstance().getAllInstallmentLinesBySalesOrder(salesOrderIds);
        System.assertNotEquals(0, result.size());
        List<InstallmentLines__c> result2 = InstallmentLineService.getInstance().getInstallmentLinesDueTillDateBySalesOrder(soList[0].Id);
    }

    @isTest
    static void testGetInstallmentLinesByProject() {
        Set<Id> projectIds = new Set<Id>{[SELECT Id FROM Project__c LIMIT 1].Id};
        List<InstallmentLines__c> result = InstallmentLineService.getInstance().getInstallmentLinesByProject(projectIds, new List<String>{'Cancelled'});
        System.assert(result.size() > 0);
    }

    @isTest
    static void testGetFirstNSecInstallmentByCommissionCreated() {
        List<InstallmentLines__c> result = InstallmentLineService.getInstance().getFirstNSecInstallmentByCommissionCreated(false, new Set<Integer>{1, 2}, 'Active');
        //System.assertNotEquals(0, result.size());
    }

    @isTest
    static void testUpdateInstallmentLines() {
        InstallmentLines__c installment = [SELECT Id, PendingAmount__c FROM InstallmentLines__c LIMIT 1];
        //installment.PendingAmount__c = 0;
        List<InstallmentLines__c> updated = InstallmentLineService.getInstance().updateInstallmentLines(new List<InstallmentLines__c>{installment});
        InstallmentLineService.getInstance().getInstallmentLinesWithSalesOrderDetails(installment.Id);
        //System.assertEquals(0, updated[0].PendingAmount__c);
    }

    @isTest
    static void testUpdateInstallmentLine() {
        InstallmentLines__c installment = [SELECT Id, InstallmentAmount__c FROM InstallmentLines__c LIMIT 1];
        installment.InstallmentAmount__c += 500;
        InstallmentLines__c updated = InstallmentLineService.getInstance().updateinstallmentLine(installment);
        System.assertNotEquals(null, updated);
    }

    @isTest
    static void testInsertInstallmentWithoutTrigger() {
        InstallmentLines__c newLine = new InstallmentLines__c(
            SalesOrder__c = [SELECT Id FROM SalesOrder__c LIMIT 1].Id,
            InstallmentNumber__c = 3,
            //PendingAmount__c = 1000,
            InstallmentAmount__c = 1000,
            ClearedAmount__c = 0,
            //Due_Date__c = Date.today().addDays(1),
            InstallmentDate__c = Date.today(),
            Description__c = 'test description'
        );
        List<InstallmentLines__c> result = InstallmentLineService.getInstance().insertInstallmentWithoutTrigger(new List<InstallmentLines__c>{newLine});
        InstallmentLineService.getInstance().getInstallmentIntegrationRecords(new Set<Id>{result[0].Id});
        InstallmentLineService.getInstance().getActiveInstallmentsByPaymentInstallmentIds(new Set<Id>{result[0].Id});
        System.assertEquals(1, result.size());
    }

    @isTest
    static void testGetDPInstallmentLinesBySalesOrder() {
        SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
        Set<Id> salesOrderIds = new Set<Id>{[SELECT Id FROM SalesOrder__c LIMIT 1].Id};
        List<InstallmentLines__c> result = InstallmentLineService.getInstance().getDPInstallmentLinesBySalesOrder(salesOrderIds);
          System.assert(result.size() > 0);
        List<InstallmentLines__c> result2 = InstallmentLineService.getInstance().getAllInstallmentLinesBySalesOrderandDueDate(salesOrderIds);
        List<InstallmentLines__c> result3 = InstallmentLineService.getInstance().getHandoverInstallmentLinesBySalesOrderIds(salesOrderIds);
        List<InstallmentLines__c> result4 = InstallmentLineService.getInstance().getOldInstallmentLinesBySalesOrderandDueDate(salesOrderIds);
        List<InstallmentLines__c> result5 = InstallmentLineService.getInstance().getPaidInstallmentLinesBySalesOrder(salesOrderIds);
        InstallmentLines__c inst = InstallmentLineService.getInstance().getInstallmentLinesByIdWithBank(result[0].Id);
        List<InstallmentLines__c> result6 = InstallmentLineService.getInstance().getFirstInstallmentLineBySalesOrder(so.Id);
        List<InstallmentLines__c> result7 = InstallmentLineService.getInstance().getInstallmentLinesNAllocationBySalesOrderId(so.Id);
        List<InstallmentLines__c> result8 = InstallmentLineService.getInstance().getAllInstallmentLinesBySalesOrderId(so.Id);
       
    }

    @isTest
    static void testGetPastDueInstallmentLinesBySalesOrderId() {
        Set<Id> salesOrderIds = new Set<Id>{[SELECT Id FROM SalesOrder__c LIMIT 1].Id};
        List<InstallmentLines__c> result = InstallmentLineService.getInstance().getPastDueDatedInstallmentLinesBySalesOrderId(salesOrderIds);
        System.assert(result.size() > 0);
        
    }
}