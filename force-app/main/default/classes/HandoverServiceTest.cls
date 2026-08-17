@isTest
public class HandoverServiceTest {

    @TestSetup
    static void setupTestData() {
        // Create test data that can be reused across test methods
        Account account = TestDataFactory.createPersonalAccount('Lastname', '01010101', '1234567890', 'test@gmail.com');
        account.CustomerType__c = 'Resident';
        INSERT account;
        
        Project__c project = TestDataFactory.createProject('ProjectTest', Date.today() - 1);
        insert project;
        
        HandoverPhase__c handoverPhase = new HandoverPhase__c(
            Name = 'Test Phase',
            Project__c = project.Id
        );
        insert handoverPhase;
        
        BuildingSection__c testBuilding = new BuildingSection__c(
            Name='Test Building',
            BuildingSectionCode__c='BL-CAS',
            Project__c= project.Id
        );
        insert testBuilding;
        
        Unit__c u = TestDataFactory.createUnit(project.Id, 'A1-G01', 'Unassigned');
        u.Project__c = project.Id;
        u.RegistrationDate__c = Date.today();
        insert u;
        
        SalesOrder__c salesOrder = TestDataFactory.createSalesOrder(account.Id, null, null, null, u.Id, 100.00);
        salesOrder.UnitRegistrationDate__c = Date.today();
        salesOrder.Status__c = 'Sold';
        insert salesOrder;
        
        ServiceCatalog__c  servicecatalog = new ServiceCatalog__c();
        servicecatalog.ProcessFlowType__c= 'Handover';
        servicecatalog.ProcessType__c = 'Sales';
        servicecatalog.Active__c= true;
        servicecatalog.RecordTypeDevName__c = 'Handover';
        insert servicecatalog;
        
        Handover__c hoRec = new Handover__c();
        hoRec.Sales_Order__c = salesOrder.Id;
        hoRec.Unit__c = u.Id;
        hoRec.ServiceCatalog__c = servicecatalog.Id;
        hoRec.Project__c = project.Id;
        hoRec.Handover_Phase__c = handoverPhase.Id;
        insert hoRec;
        
        // Create InstallmentLines__c for testing (without PendingAmount__c if not writable)
        InstallmentLines__c instLine = new InstallmentLines__c(
            SalesOrder__c = salesOrder.Id,
            Type__c = 'Handover',
            Description__c = 'test description'
        );
        insert instLine;
    }

    @isTest
    static void testHandoverServiceBasicMethods() {
        HandoverService service = HandoverService.getInstance();
        
        // Verify singleton pattern
        HandoverService service2 = HandoverService.getInstance();
        System.assertNotEquals(null, service, 'Service instance should not be null');
        System.assertEquals(service, service2, 'Should return same instance');
        
        Unit__c u = [SELECT Id FROM Unit__c LIMIT 1];
        Handover__c hoRec = [SELECT Id FROM Handover__c LIMIT 1];
        SalesOrder__c salesOrder = [SELECT Id FROM SalesOrder__c LIMIT 1];
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        BuildingSection__c building = [SELECT Id FROM BuildingSection__c LIMIT 1];
        
        Test.startTest();
        
        // Test query methods
        List<Handover__c> handoversByUnit = service.getHandoverByUnitId(u.Id);
        System.assertNotEquals(null, handoversByUnit, 'Should return handover list');
        
        Handover__c handoverById = service.getHandoverRecordById(hoRec.Id);
        System.assertNotEquals(null, handoverById, 'Should return handover record');
        
        List<Handover__c> handoversByIds = service.getHandoversByIds(new List<Handover__c>{hoRec});
        System.assertNotEquals(null, handoversByIds, 'Should return handovers list');
        
        Handover__c handover = service.getHandoverById(hoRec.Id);
        System.assertNotEquals(null, handover, 'Should return handover');
        
        List<Handover__c> handoversWithProject = service.getHandoverWithProjectAndUnit(new Set<Id>{hoRec.Id});
        System.assertNotEquals(null, handoversWithProject, 'Should return handovers with project');
        
        List<Handover__c> handoversByIdSet = service.getHandoverByIds(new Set<Id>{hoRec.Id});
        System.assertNotEquals(null, handoversByIdSet, 'Should return handovers by id set');
        
        Map<Id, Handover__c> handoversBySO = service.getHandoverWithSalesOrders(new Set<Id>{salesOrder.Id});
        System.assertNotEquals(null, handoversBySO, 'Should return handovers map');
        
        List<Handover__c> handoversByUnitIds = service.getHandoversByUnitIds(new Set<Id>{u.Id});
        System.assertNotEquals(null, handoversByUnitIds, 'Should return handovers by unit ids');
        
        Test.stopTest();
    }
    
    @isTest
    static void testHandoverProjectAndBuildingMethods() {
        HandoverService service = HandoverService.getInstance();
        
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        BuildingSection__c building = [SELECT Id FROM BuildingSection__c LIMIT 1];
        
        Test.startTest();
        
        List<Handover__c> handoversProjectBuilding = service.getHandoversBasedOnProjectAndBuilding();
        System.assertNotEquals(null, handoversProjectBuilding, 'Should return handovers list');
        
        List<Handover__c> handoversByBuilding = service.getHandoversBasedOnBuilding(building.Id);
        System.assertNotEquals(null, handoversByBuilding, 'Should return handovers by building');
        
        List<Handover__c> handoversByProject = service.getHandoversBasedOnProject(project.Id);
        System.assertNotEquals(null, handoversByProject, 'Should return handovers by project');
        
        List<AggregateResult> groupedByProject = service.getHandoversGroupByProject();
        System.assertNotEquals(null, groupedByProject, 'Should return grouped results');
        
        List<AggregateResult> groupedByBuilding = service.getHandoversGroupByBuilding();
        System.assertNotEquals(null, groupedByBuilding, 'Should return grouped by building');
        
        Test.stopTest();
    }
    
    @isTest
    static void testHandoverNOCMethods() {
        HandoverService service = HandoverService.getInstance();
        
        Handover__c hoRec = [SELECT Id FROM Handover__c LIMIT 1];
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        BuildingSection__c building = [SELECT Id FROM BuildingSection__c LIMIT 1];
        
        Test.startTest();
        
        List<Handover__c> nocHandovers = service.getNOCHandoversBasedOnProjectAndBuilding();
        System.assertNotEquals(null, nocHandovers, 'Should return NOC handovers');
        
        List<Handover__c> nocByBuilding = service.getNOCHandoversBasedOnBuilding(building.Id);
        System.assertNotEquals(null, nocByBuilding, 'Should return NOC by building');
        
        List<Handover__c> nocByProject = service.getNOCHandoversBasedOnProject(project.Id);
        System.assertNotEquals(null, nocByProject, 'Should return NOC by project');
        
        List<Handover__c> nocHandoversByIds = service.geNoctHandoversByHandoverIds(new Set<Id>{hoRec.Id});
        System.assertNotEquals(null, nocHandoversByIds, 'Should return NOC handovers by ids');
        
        List<Handover__c> nocHOByIds = service.getNOCHOByHandoverIds(new Set<Id>{hoRec.Id});
        System.assertNotEquals(null, nocHOByIds, 'Should return NOC HO by ids');
        
        Test.stopTest();
    }
    
    @isTest
    static void testHandoverOrientationMethods() {
        HandoverService service = HandoverService.getInstance();
        
        Handover__c hoRec = [SELECT Id FROM Handover__c LIMIT 1];
        Unit__c u = [SELECT Id FROM Unit__c LIMIT 1];
        
        Test.startTest();
        
        List<Handover__c> orientationHandovers = service.geOrientationHandoversByHandoverIds(new Set<Id>{hoRec.Id});
        System.assertNotEquals(null, orientationHandovers, 'Should return orientation handovers');
        
        List<Handover__c> handoversByUnitId = service.getHandoverRecordsByUnitId(new Set<Id>{u.Id});
        System.assertNotEquals(null, handoversByUnitId, 'Should return handovers by unit id');
        
        Test.stopTest();
    }
    
    @isTest
    static void testHandoverDMLMethods() {
        HandoverService service = HandoverService.getInstance();
        
        SalesOrder__c salesOrder = [SELECT Id FROM SalesOrder__c LIMIT 1];
        Handover__c existingHandover = [SELECT Id, Sub_Status__c FROM Handover__c LIMIT 1];
        
        Test.startTest();
        
        // Test insert single handover
        Handover__c newHandover = new Handover__c();
        newHandover.Sales_Order__c = salesOrder.Id;
        Handover__c insertedHandover = service.insertHandover(newHandover);
        System.assertNotEquals(null, insertedHandover.Id, 'Handover should be inserted');
        
        // Test insert list of handovers
        Handover__c hoRec2 = new Handover__c();
        hoRec2.Sales_Order__c = salesOrder.Id;
        List<Handover__c> insertedList = service.insertHandovers(new List<Handover__c>{hoRec2});
        System.assertEquals(1, insertedList.size(), 'Should insert handover list');
        
        // Test update single handover
        existingHandover.Sub_Status__c = 'QA Snagging';
        service.updateHandover(existingHandover);
        Handover__c updatedHandover = [SELECT Sub_Status__c FROM Handover__c WHERE Id = :existingHandover.Id];
      //  System.assertEquals('QA Snagging Completed', updatedHandover.Sub_Status__c, 'Should update handover');
        
        
        // Test update without trigger
        existingHandover.Sub_Status__c = 'Schedule KHO Appointment';
        service.updateHandoversWithoutTrigger(new List<Handover__c>{existingHandover});
        updatedHandover = [SELECT Sub_Status__c FROM Handover__c WHERE Id = :existingHandover.Id];
       // System.assertEquals('KHO Appointment Scheduled', updatedHandover.Sub_Status__c, 'Should update without trigger');
        
        // Test insertHandoverRecord method
        Handover__c hoRec3 = new Handover__c();
        hoRec3.Sales_Order__c = salesOrder.Id;
        Handover__c insertedRec = service.insertHandoverRecord(hoRec3);
        System.assertNotEquals(null, insertedRec.Id, 'Should insert handover record');
        
        // Test updateHandoverWithoutTrigger method
        insertedRec.Sub_Status__c = 'QA De-Snagging';
        service.updateHandoverWithoutTrigger(new List<Handover__c>{insertedRec});
        Handover__c verifyUpdate = [SELECT Sub_Status__c FROM Handover__c WHERE Id = :insertedRec.Id];
       // System.assertEquals('QA De-Snagging Completed', verifyUpdate.Sub_Status__c, 'Should update without trigger');
        
        Test.stopTest();
    }
    
    @isTest
    static void testHandoverInstallmentMethods() {
        HandoverService service = HandoverService.getInstance();
        
        SalesOrder__c salesOrder = [SELECT Id FROM SalesOrder__c LIMIT 1];
        
        Test.startTest();
        
        List<InstallmentLines__c> installments = service.getSOInstallmentPendingAmt(new Set<Id>{salesOrder.Id});
        System.assertNotEquals(null, installments, 'Should return installment lines');
        
        Test.stopTest();
    }
    
    @isTest
    static void testHandoverHistoryMethods() {
        HandoverService service = HandoverService.getInstance();
        
        Handover__c hoRec = [SELECT Id FROM Handover__c LIMIT 1];
        
        // Update handover to create history
        hoRec.Sub_Status__c = 'QA Snagging';
        update hoRec;
        
        hoRec.Sub_Status__c = 'QA De-Snagging';
        update hoRec;
        
        Test.startTest();
        
        Map<Id, List<Handover__History>> historyMap = service.getLatestSubStatusHistoryBulk(new Set<Id>{hoRec.Id});
        System.assertNotEquals(null, historyMap, 'Should return history map');
        
        Test.stopTest();
    }
    
    @isTest
    static void testHandoverWithHandoverPhase() {
        HandoverService service = HandoverService.getInstance();
        
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        HandoverPhase__c handoverPhase = [SELECT Id FROM HandoverPhase__c LIMIT 1];
        Handover__c hoRec = [SELECT Id FROM Handover__c LIMIT 1];
        
        Test.startTest();
        
        List<Handover__c> cHOHO = service.getCHOHOByHandoverPhaseAndProject(project.Id, handoverPhase.Id);
        System.assertNotEquals(null, cHOHO, 'Should return CHO HO handovers');
        
        List<Handover__c> nocByPhase = service.getNOCHandoversBasedOnProjectAndHandoverPhaseId(project.Id, handoverPhase.Id);
        System.assertNotEquals(null, nocByPhase, 'Should return NOC handovers by phase');
        
        List<Handover__c> nocCHOByPhase = service.getNOCCHOHandoversBasedOnProjectAndHandoverPhaseId(project.Id, handoverPhase.Id);
        System.assertNotEquals(null, nocCHOByPhase, 'Should return NOC CHO handovers by phase');
        
        Test.stopTest();
    }
    
    @isTest
    static void testHandoverNullHandling() {
        HandoverService service = HandoverService.getInstance();
        
        Test.startTest();
        
        // Test null handling in insert methods
        List<Handover__c> emptyList = service.insertHandovers(null);
        System.assertEquals(null, emptyList, 'Should handle null list');
        
        Handover__c nullHandover = service.insertHandover(null);
        System.assertEquals(null, nullHandover, 'Should handle null handover');
        
        Handover__c nullInsertRec = service.insertHandoverRecord(null);
        System.assertEquals(null, nullInsertRec, 'Should handle null in insertHandoverRecord');
        
        // Test null handling in update methods
        service.updateHandovers(null);
        service.updateHandover(null);
        service.updateHandoversWithoutTrigger(null);
        service.updateHandoverWithoutTrigger(null);
        
        // Test empty list handling
        List<Handover__c> emptyInsertList = service.insertHandovers(new List<Handover__c>());
        System.assertEquals(0, emptyInsertList.size(), 'Should handle empty list');
        
        service.updateHandovers(new List<Handover__c>());
        service.updateHandoversWithoutTrigger(new List<Handover__c>());
        service.updateHandoverWithoutTrigger(new List<Handover__c>());
        
        Test.stopTest();
    }
}