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
private class UnitServiceTest {
    
     @TestSetup static void testDataSetup() {
        DocumentType__c dc1 = TestDataFactory.createDocumentType('Unit', 'Project-Unit Registration Document');
        INSERT dc1;
        Test.startTest();
        Project__c objProject = TestDataFactory.createProject('Test Project');
        objProject.GIS_Service_URL__c='URL';
        insert objProject;
        
        List<unit__c> unitLst = new List<unit__c>();
        for(integer i =0;i<13;i++){          
            unitLst.add(TestDataFactory.createUnit(objProject.Id, 'J1A1-G01A'+i,'Booked'));  
        }
        insert unitLst;
        Test.stopTest();
    }
    
    
    @isTest static void UnitServiceTestMethod(){
        
        Set<Id> buidlingIds = new Set<id>();
        Set<Id>unitIds = new Set<id>();
        Set<String>StringunitIds = new Set<String>();
        Set<Id>projectIds = new Set<id>();
        List<Id> unitidList = new List<Id>();
        Map<String, String> mapFieldApiFieldValues = new Map<String, String>();
        
        
        Account tempAcc=new Account(
            Name= 'test',
            MobileNumber__c = '12345678'  
        );
        
        insert tempAcc;
        
        Contact tempContact =new Contact(
            LastName='test',
            AccountId=tempAcc.id,
            Email='test@gmail.com'
        );
        insert tempContact;
        Opportunity tempOpp=new Opportunity(
            Name='tempOpp',
            StageName='New',
            CloseDate=Date.today(),
            LeadChannel__c='Walk in',
            AccountId=tempAcc.Id,
            ContactId=tempContact.id,
            Contact__c=tempContact.id,
            WinReason__c='Loyalty'
        );
        insert tempOpp;
        
        
        
        
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
        buidlingIds.add(testBuilding.id);
        
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
            SellingPrice__c= 700000,
            CommunitySAPUnitNumber__c = 'SAP-001',
            ADMAddressingNumber__c = 'SAP-001'
            
        );
        insert testUnit;
        unitIds.add(testUnit.id);
        unitidList.add(testUnit.id);
        StringunitIds.add(testUnit.id);
        mapFieldApiFieldValues.put('Status__c', 'Available');
        String query = 'SELECT Id, Name FROM Unit__c WHERE Name IN (\'test Unit\')';
        
        UnitService.getAllAvailableUnitsUnderBuilding(buidlingIds);
        UnitService.getUnitsByAccount(tempAcc.Id);
        UnitService.getAllUnitsById(unitIds);
        UnitService.getUnitsById(unitidList);
        UnitService.prepareUnitId('test Unit');
        UnitService.prepareDropdownData('test');
        UnitService.prepareOptionList(testProject.id,testBuilding.id);
        UnitService.getUnitQuery(query );
        UnitService.makeUnitsAvailable(unitIds);
        UnitService.cancelUnitReservation(StringunitIds);
        UnitService.fetchPropertyInventories(null);
        UnitService.getAllUnitDesign(unitIds);
        UnitService usc = UnitService.getInstance();
        usc.updateUnitWithoutTrigger(testUnit);
        usc.getUnitModelsByProjectId(testProject.id);
        usc.getUnitsByProjectId(testProject.id);
        usc.getUnitsByProjectAndUnitModel(testProject.id,'1BHK');
        usc.getAvailableUnitsByProjectId(testProject.id,'Direct');
        usc.getAvailableUnitsByProjectAndUnitModel(testProject.id,'1BHK');
        usc.getSoldUnitsOfProject(testProject.id,'Sold');
        usc.getUnits();
        usc.getUnitsByIds(new Set<String>{testUnit.id});
        usc.getUnitsById(testUnit.id);
        usc.getUnitsBySAPNo('Available');
        UnitService.fetchUnitDetailsById(testUnit.id);
        usc.getUnitMap(new Set<String>{testUnit.Id});
        usc.getUnitsById(testUnit.id);
        usc.getUnitsWithProjectId(testProject.id);
        usc.getUnitById(testUnit.Id);
        UnitService.getUnitByBuilding(testBuilding.Name);
        usc.getUnitsWithBuilding(testBuilding.Id);
        usc.getUnitDetails(testUnit.id);
        usc.getUnitDetails(new List<Id>{testUnit.id});
        usc.getUnitGISIntegrationRecord(testUnit);
        usc.getUnitNVehicleParkingsByUnitIds(testUnit.id);
        usc.getByName(testUnit.ADMAddressingNumber__c);
        UnitService.bySapUnitNumber(new Set<String>{'SAP-001'});
        UnitService.bySapUnitNumber(new Set<String>());
        usc.updateUnitOccupancyStatus(testUnit.Id, 'Available');

    }
    
    @isTest static void UnitServiceTestMethod2(){
        
        Map<id,Unit__c> unitMap = new Map<id,Unit__c>([SELECT Id, Name,GIS_Plot_No__c,UnitType__c,UnitModel__c,PlotArea__c,ADMPlotNumber__c,GIS_Object_Id__c,Status__c,SaleableArea__c,SellingPrice__c,Send_to_GIS__c,Project__r.Name,Project__r.GIS_Service_URL__c FROM Unit__c limit 2]);
        UnitService objUnitService = UnitService.getInstance();
        List<Unit__c> unitList= objUnitService.getUnitsByIds(unitMap.keySet());
        
        List<Unit__c> unitList2 = [Select Id FROM Unit__c];
        Set<String> unitNames = new Set<String>();
        String unitName;
        for(Unit__c unit:unitMap.values()){
            unitNames.add(unit.name);
            unitName = String.ValueOf(unit.name);
            unit.Send_to_GIS__c=true;
        }
        objUnitService.getUnitsByNames(unitNames);
        objUnitService.getUnitByName(unitName);
		objUnitService.getRegisteredUnitById(unitList2);
        objUnitService.updateUnitsWithoutTrigger(unitMap.values());
        objUnitService.updateUnits(unitMap.values());
        
        
    }
    
}