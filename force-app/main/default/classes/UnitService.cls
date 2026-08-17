/*
* @Author : Biswajeet Samal
* @CreatedDate : 7th AUG 2024
* @Description : Unit Service class
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           Biswajeet   07AUG2024        Initial draft 
* 2.0           Jayprakash  20AUG2024        Implemented GIS Integration
* 3.0 			Dhanraj		06APR2026		 Added method for Direct/Indirect filtering of units
*****************************************************************************************************/
public without sharing class UnitService {
    
    private static UnitService instance;
    
    public UnitService() {}
    
    public static UnitService getInstance() {
        if(instance == null) {
            instance = new UnitService();
        }
        return instance;
    }
    //fetch units by account id
    @AuraEnabled(cacheable=false) 
    public static List<Unit__c> getUnitsByAccount(String accId){
        List<Unit__c> unitList= [Select Id, Name, Active_Sales_Order__c, ActiveTenant__c, Active_Sales_Order__r.Name, Active_Sales_Order__r.Account__c FROM Unit__c WHERE Active_Sales_Order__r.Account__c =: accId OR ActiveTenant__c =: accId];
        return unitList;
    }  
    
    public static list<Unit__c> getAllAvailableUnitsUnderBuilding(set<ID> buildingsIds){
        list<Unit__c> lstUnittoreturn = [select id,Name,NumberOfBedrooms__c,UnitType__c,External_Saleable_Area__c,MeasuredArea__c,PropertyUsage__c,UnitModel__c,FloorNumber__c,UnitView__c,PropertyStatus__c,SaleableArea__c,TotalRooms__c,UnitCategory__c,MeasuredInternalArea__c,TerraceArea__c,TotalArea__c,UnitPlotArea__c,SellingPrice__c,AffectionPlan__c,MarketingPlan__c,AnticipatedServiceCharges__c,BuildingSectionName__c,BuildingSectionName__r.PropertyManagementFee__c from Unit__c where BuildingSectionName__c in :buildingsIds  and IsActive__c =true AND ( Status__c='Available' OR (Status__c= 'In Progress' AND LockedBy__c = :UserInfo.getUserId())) order by Name];
        return lstUnittoreturn ;
    } 
    
    public static List<Unit__c> fetchUnitDetailsById(String unitId){
        return [select Id,Legal_Status__c, Occupancy_Type__c,Project__c,Project__r.City__c,Project__r.BankAccount__c,BuildingSectionName__r.Project__c,Total_Outstanding__c,Status__c,Is_Chiller_Enabled__c,Project__r.Name,ProjectName__c,SAP_Contract_No__c,CommunityCompanyCode__c,CommunitySAPUnitNumber__c,SAP_Company_Code__c,
                Name from Unit__c where Id=:unitId];
    }
    
    public static list<Unit__c> getAllUnitsById(set<ID> unitIds){
        return [select BuildingSectionName__r.TaxPercentage__c,PlotArea__c,SAP_Company_Code__c,
                Location__Longitude__s, Location__Latitude__s,UnitModel__c,TotalRooms__c,id,Name,
                UnitPlotArea__c,status__c,InventoryCategory__c,GFAArea__c,Project__r.Name,
                AnticipatedServiceCharges__c,SaleableArea__c,MeasuredArea__c,UnitNumber__c,
                BuildingSectionName__r.PropertyManagementFee__c,PropertyStatus__c,Building__c,Building__r.Name,
                CompletionDate__c,Project__c,BuildingSectionName__c,CurrencyIsoCode,
                SellingPrice__c,MarketPrice__c,NumberOfBedrooms__c,UnitType__c,TotalArea__c,
                TerraceArea__c,MeasuredInternalArea__c,LockedBy__c,LockExpiryTime__c,
                NumberOfCarParks__c,Project__r.Amenities__c,Project__r.VirtualTour__c,
                UnitCategory__c,Project__r.VideoLink__c,Is_Chiller_Enabled__c,LeasingUnitStatus__c from Unit__c where id in :unitIds];
    }
    
    public static List<Unit__c> getUnitByBuilding(String buildingName){
        return [SELECT Id, Name,Occupancy_Type__c,Is_Chiller_Enabled__c, CommunityUnitNumber__c, ADMAddressingNumber__c
                FROM Unit__c where BuildingSectionName__c=:buildingName AND PropertyUsage__c='Residential'
                AND Legal_Status__c != 'With Legal' AND BlockedForCommunityApp__c = false];
    }
    
    @AuraEnabled(cacheable=false)
    public static list<Unit__c> getUnitsById(List<Id> unitIds){
        return [SELECT Id, Name, TotalArea__c, NumberOfCarParks__c, NumberOfBedrooms__c, SellingPrice__c, Project__c,Location__Longitude__s, Location__Latitude__s FROM Unit__c WHERE Id IN :unitIds];
    }
    
    @AuraEnabled(cacheable=false) 
    public static list<Unit__c> prepareUnitId(String unitName){
        list<Unit__c> lstUnitsId = new list<Unit__c>();
        lstUnitsId.add([Select Id from Unit__c where Name =: unitName]);
        return lstUnitsId;
    }
    
    /**
    * getAllProjects 
    *
    * return available projects
    * 
    * @usage searchUnit LWC
    *
    * @param none
    * @return   list<map<String,string>>  list of select options 
    * 
    */
    @AuraEnabled(cacheable=false)
    public static List<Unit__c> prepareDropdownData(String projectNameParam){
        list<Unit__c> lstDropdownData = new list<Unit__c>();
        if (String.isNotBlank(projectNameParam)) {
            for(Unit__c objUnit : [Select Id,TotalRooms__c,UnitCategory__c,Project__r.Name,HandoverZone__c,FloorNumber__c,UnitView__c,UnitModel__c,CommunityName__c,UnitType__c,BuildingSectionName__r.Name,Project__r.City__c from Unit__c where Project__r.Name =: projectNameParam AND PropertyStatus__c =:'Sale' AND (Status__c =: 'Available' OR Status__c =: 'Blocked')]){
                lstDropdownData.add(objUnit);
            }
        }else{
            for(Unit__c objUnit: [Select Id,TotalRooms__c,Project__r.Name,Project__c,UnitCategory__c,HandoverZone__c,UnitView__c,UnitModel__c,FloorNumber__c,CommunityName__c,UnitType__c,BuildingSectionName__r.Name,Project__r.City__c  from Unit__c where Project__r.IsActive__c = true AND PropertyStatus__c =:'Sale' AND (Status__c =: 'Available' OR Status__c =: 'Blocked')]){
                lstDropdownData.add(objUnit);
            }
        }       
        return lstDropdownData;
    }
    
    @AuraEnabled(cacheable=false)
    public static List<Unit__c> prepareOptionList(String projectId, String BuildingSectionId){
        list<Unit__c> lstDropdownData = new list<Unit__c>();
        if (String.isNotBlank(BuildingSectionId)) {
            lstDropdownData = [SELECT Id, Name, Project__c, Project__r.Name, BuildingSectionName__c, BuildingSectionName__r.Name, UnitType__c, UnitModel__c, FloorNumber__c, NumberOfBedrooms__c, Status__c, Location__Longitude__s, Location__Latitude__s FROM Unit__c WHERE Project__c =: projectId AND BuildingSectionName__c =: BuildingSectionId LIMIT 49999];
        }else{
            lstDropdownData = [SELECT Id, Name, Project__c, Project__r.Name, BuildingSectionName__c, BuildingSectionName__r.Name, UnitType__c, UnitModel__c, FloorNumber__c, NumberOfBedrooms__c, Status__c, Location__Longitude__s, Location__Latitude__s FROM Unit__c WHERE Project__c =: projectId  LIMIT 49999];
        }     
        return lstDropdownData;
    }
 
    @AuraEnabled(cacheable=false)
    public static List<Unit__c> getUnitQuery(String query) {
        List<Unit__c> records = Database.query(query);
        return records;
    }
    
    /*
    * Release units when the Reservation or Booking is cancelled
    */
    public static void makeUnitsAvailable(Set<Id> unitIds) {
        List<Unit__c> unitList = new List<Unit__c>();
        
        for(Id unitId : unitIds){
            Unit__c unitRecord = new Unit__c();
            unitRecord.Id = unitId ; 
            unitRecord.Status__c = Constants.UNIT_STATUS_AVAILABLE;
            unitRecord.LockedBy__c = null;
            unitRecord.LockTime__c = null;
            unitRecord.LockExpiryTime__c = null;
            unitRecord.RelatedOpportunity__c = null;
            unitRecord.RelatedSalesOrder__c = null;
            unitList.add(unitRecord);
        }
        
        if(unitList !=null && unitList.size()>0){
            update unitList; 
        }
        
    }
    
    public static Boolean cancelUnitReservation(Set<String> idList) {
        List<Unit__c> unitList = new List<Unit__c>();
        
        for(Unit__c objUnit : [Select id,Name from Unit__c where id IN:idList]){
            objUnit.Status__c = Constants.UNIT_STATUS_AVAILABLE;
            unitList.add(objUnit);
        }
        update unitList;
        return true;     
    }
    
    /*
    * Fetch list of units based on the condition
    */
    public static List<Unit__c> fetchPropertyInventories(string whereCondition){
        list<Unit__c> propertyInventoryList = new list<Unit__c>();
        Id userId = UserInfo.getUserId();
        
        try{
            string strQuery = 'Select id,Name,UnitPlotArea__c,PropertyStatus__c,GFAArea__c,Project__r.Name,CompletionDate__c,Project__c,BuildingSectionName__c,BuildingSectionName__r.Name,CurrencyIsoCode,SellingPrice__c,MarketPrice__c,NumberOfBedrooms__c,UnitType__c,TotalArea__c,TerraceArea__c,MeasuredInternalArea__c,UnitModel__c,UnitView__c,FloorNumber__c,PropertyUsage__c,UnitCategory__c,TotalRooms__c, Location__Longitude__s, Location__Latitude__s FROM Unit__c WHERE Id != null ';
            if(whereCondition != null && string.isNotEmpty(whereCondition)){
                strQuery += ' and ('+whereCondition+')';
            } 
            
            strQuery += ' AND ( Status__c =\'Available\' OR (Status__c =\'In-Progress\' AND LockedBy__c =: userId AND LockExpiryTime__c!=null))';
            
            strQuery += ' Order By Project__r.Name ASC limit '+Utilities.getRecordCount('AppFetchRecordCount',Utilities.getRecordCount('AppMaxRecordCount',0));
            system.debug('**Unit Query**'+strQuery);
            propertyInventoryList =  Database.query(strQuery);
            return propertyInventoryList;
        }
        catch(Exception e){
            system.debug('*** Exception e***'+e.getMessage());
            throw e;
        }
    }
    
    
    //Added by Maaz
    /* This query is used for the Offer generation */
    public static list<UnitDesign__c> getAllUnitDesign(set<ID> unitIds){
        return [select DesignType__c,GFAArea__c,PremiumAmount__c,SaleableArea__c,SellingPrice__c,TerraceArea__c,Unit__c,WebFloorPlan__c from UnitDesign__c where Unit__c in :unitIds];
    }
    
    //Get unit records by unit ids
    public List<Unit__c> getUnitsByIds(set<Id> unitIds){
        return [SELECT Id, Name,SAP_Unit_Number__c,Project__c,BuildingSectionName__r.Project__c,Active_Sales_Order__r.Account__c,Active_Sales_Order__c,GIS_Plot_No__c,UnitType__c,UnitModel__c,PlotArea__c,ADMPlotNumber__c,
                GIS_Object_Id__c,Status__c,SaleableArea__c,SellingPrice__c,Send_to_GIS__c,Net_Amount_Selling_Price__c,HandoverPhase__c,
                Project__r.Name,Project__r.GIS_Service_URL__c,Customer_Name__c, Location__Longitude__s, Location__Latitude__s FROM Unit__c WHERE Id IN :unitIds];
    }
    
    //Get unit records by unit names
    public List<Unit__c> getUnitsByNames(set<String> unitNames){
        return [SELECT Id, Name,GIS_Plot_No__c,UnitType__c,UnitModel__c,PlotArea__c,ADMPlotNumber__c,
                GIS_Object_Id__c,Status__c,SaleableArea__c,SellingPrice__c,Send_to_GIS__c,
                Project__r.Name,Project__r.GIS_Service_URL__c,Customer_Name__c, Location__Longitude__s, Location__Latitude__s FROM Unit__c WHERE name IN :unitNames];
    } 
    
    //Update Units without trigger
    public List<Unit__c> updateUnitsWithoutTrigger(List<Unit__c> unitList){
        if(unitList != NULL && !unitList.isEmpty()){
            UnitTriggerHandler.isTriggerDisabled = true;
            update unitList;
            UnitTriggerHandler.isTriggerDisabled = false;
        }
        return unitList;
    }
    //Get unit records by unit id
    public Unit__c getUnitById(Id unitId){
        return [SELECT Id, Name, UnitNumber__c, AffectionPlan__c, MarketingPlan__c, WebFloorPlan__c, IsFMSponsoredByBloom__c,IsManagedByBloom__c
                FROM Unit__c WHERE Id = :unitId];
    }
    
    //Update Unit without trigger
    public Unit__c updateUnitWithoutTrigger(Unit__c objUnit){
        if(objUnit != NULL){
            UnitTriggerHandler.isTriggerDisabled = true;
            objUnit = updateUnitsWithoutTrigger(new List<Unit__c>{objUnit})[0];
            UnitTriggerHandler.isTriggerDisabled = false;
        }
        return objUnit;
    }
    
    
    //Update Units
    public List<Unit__c> updateUnits(List<Unit__c> unitList){
        if(unitList != NULL && !unitList.isEmpty()){
            update unitList;
        }
        return unitList;
    }
    
    //Get unit models by project id
    public List<String> getUnitModelsByProjectId(Id projectId){
        List<String> unitModelList = new List<String>();
        for (AggregateResult ar : [SELECT UnitModel__c FROM Unit__c WHERE Project__c = :projectId GROUP BY UnitModel__c])  {
            unitModelList.add(string.valueof(ar.get('UnitModel__c')));
        }
        return unitModelList;
    }
    
    //Get units by project id
    public List<Unit__c> getUnitsByProjectId(Id projectId){
        return [SELECT Id, Name FROM Unit__c WHERE Project__c = :projectId];
    }
    
    //Get units by project & Unit Model
    public List<Unit__c> getUnitsByProjectAndUnitModel(Id projectId, String unitModel){
        return [SELECT Id, Name FROM Unit__c WHERE Project__c = :projectId AND UnitModel__c = :unitModel];
    }    
    //Get units by project id
    
    public List<Unit__c> getAvailableUnitsByProjectId(Id projectId){
        Id currentUserId = UserInfo.getUserId();
        return [SELECT Id, Name, UnitType__c, UnitCategory__c, NumberOfBedrooms__c, Internal_Saleable_Area__c, External_Saleable_Area__c, SellingPrice__c, Direct_Indirect__c FROM Unit__c WHERE Project__c = :projectId AND (Status__c = 'Available' OR (Status__c = 'Blocked' AND BlockedBy__c = :currentUserId))];
    }
    
    //Get units by project & Unit Model
    public List<Unit__c> getAvailableUnitsByProjectAndUnitModel(Id projectId, String unitModel){
        Id currentUserId = UserInfo.getUserId();
        return [SELECT Id, Name, UnitType__c, UnitCategory__c, NumberOfBedrooms__c, Internal_Saleable_Area__c, External_Saleable_Area__c, SellingPrice__c, Direct_Indirect__c FROM Unit__c WHERE Project__c = :projectId AND UnitModel__c = :unitModel AND (Status__c = 'Available' OR (Status__c = 'Blocked' AND BlockedBy__c = :currentUserId))];
    }    
    
    //Get units by project Unit Model & Direct/Indirect Type
    public List<Unit__c> getAvailableUnitsByProjectAndUnitModel(Id projectId, String unitModel, String directType){
        Id currentUserId = UserInfo.getUserId();
        return [SELECT Id, Name, UnitType__c, UnitCategory__c, NumberOfBedrooms__c, Internal_Saleable_Area__c, External_Saleable_Area__c, SellingPrice__c, Direct_Indirect__c FROM Unit__c WHERE Project__c = :projectId AND UnitModel__c = :unitModel AND (Status__c = 'Available' OR (Status__c = 'Blocked' AND BlockedBy__c = :currentUserId)) AND Direct_Indirect__c =: directType];
    }    
    
    //Get unit records by unit id
    public Unit__c getUnitsById(Id unitId){
        return [SELECT Id, Name, UnitNumber__c, AffectionPlan__c, MarketingPlan__c, WebFloorPlan__c FROM Unit__c WHERE Id = :unitId];
    }    
    //Get unit by unit name
    public Unit__c getUnitByName(String unitName){
        return [SELECT Id, Name, UnitNumber__c, AffectionPlan__c, MarketingPlan__c, WebFloorPlan__c FROM Unit__c WHERE Name = :unitName];
    }
    
    //Rajat Rastogi
    /* This query is used for the UnitMap */
    public Map<ID, Unit__c> getUnitMap(set<String> UnitIds){
        Map<ID, Unit__c> unitMap = new Map<ID, Unit__c>([SELECT Id,Name, Location__Longitude__s, Location__Latitude__s, RelatedOpportunity__r.Account.PersonEmail,
                                                         MeasuredArea__c, SaleableArea__c, AnticipatedServiceCharges__c,
                                                         Active_Sales_Order__c,Active_Sales_Order__r.Account__c,
                                                         Active_Sales_Order__r.Account__r.isPersonAccount,Active_Sales_Order__r.Account__r.PersonEmail,
                                                         BuildingSectionName__r.Project__r.Name, BuildingSectionName__c,BuildingSectionName__r.Project__c,
                                                         SAP_Unit_Number__c,BuildingSectionName__r.Project__r.ProjectNameArabic__c
                                                         FROM Unit__c WHERE ID IN :UnitIds]);
        return unitMap;
    }
    
    //Rajat Rastogi
    /* This query is used for the Unit */
    public List<Unit__c> getUnits(){
        return [SELECT Id, Name, Location__Longitude__s, Location__Latitude__s, BuildingSectionName__c,BuildingSectionName__r.Name, Status__c,Active_Sales_Order__c, Active_Sales_Order__r.Name,
                OwnerId,Owner.Name,CreatedDate,Project__c,Unit_Status__c,(Select Id,Name,Customer_Email__c,CustomerEmail__c from Handovers__r )
                FROM Unit__c
                WHERE Id IN (SELECT Unit__c FROM Handover__c WHERE Unit__c != null AND Is_BCC_Announcement_Sent__c = false) LIMIT 10000];
    }
    public  List<Unit__c> getUnitsWithBuilding(String buildingId){
        return [SELECT Id, Name, Location__Longitude__s, Location__Latitude__s, BuildingSectionName__c,BuildingSectionName__r.Name, Status__c,Active_Sales_Order__c, Active_Sales_Order__r.Name,
                OwnerId,Owner.Name,CreatedDate,Project__c,Unit_Status__c,(Select Id,Name,Customer_Email__c,CustomerEmail__c from Handovers__r )
                FROM Unit__c 
                WHERE BuildingSectionName__c = :buildingId 
                AND Id IN (SELECT Unit__c FROM Handover__c WHERE Unit__c != null AND Is_BCC_Announcement_Sent__c = false) LIMIT 10000];
    }
   public List<Unit__c> getBCCUnitsWithHandoverPhaseAndProjectId(String projectId, String handoverPhaseId) {
    return [SELECT Id, Name, HandoverPhase__c, BuildingSectionName__r.Name, Status__c, 
            Active_Sales_Order__r.Name, Owner.Name, CreatedDate, Project__c,
            (SELECT Id, Name, CustomerEmail__c, 
                    Unit__r.Name, Unit__r.Status__c, 
                    Sales_Order__r.Name, Building_Phase__r.Name,
                    Owner_Name__c, CreatedDate 
             FROM Handovers__r 
             WHERE Is_BCC_Announcement_Sent__c = false)
                FROM Unit__c 
            WHERE HandoverPhase__c = :handoverPhaseId 
            AND Project__c = :projectId
            AND Id IN (SELECT Unit__c FROM Handover__c WHERE Is_BCC_Announcement_Sent__c = false) 
            ];
    }
    
    public List<Unit__c> getUnitsWithProjectId(String projectId){
        return [SELECT Id, Name, Location__Longitude__s, Location__Latitude__s, BuildingSectionName__c,BuildingSectionName__r.Name, Status__c,Active_Sales_Order__c, Active_Sales_Order__r.Name,
                OwnerId,Owner.Name,CreatedDate,Project__c,Unit_Status__c,(Select Id,Name,Customer_Email__c,CustomerEmail__c from Handovers__r )
                FROM Unit__c 
                WHERE Project__c = :projectId 
                AND Id IN (SELECT Unit__c FROM Handover__c WHERE Unit__c != null AND Is_BCC_Announcement_Sent__c = false) LIMIT 10000];
    }
    
    public Map<Id, Unit__c> getUnitsByIds(Set<String> unitIds) {
        return new Map<Id, Unit__c>([SELECT Id, RelatedOpportunity__r.Account.PersonEmail,Active_Sales_Order__r.Account__c, Active_Sales_Order__c,BuildingSectionName__c, 
                                        BuildingSectionName__r.Project__c,Net_Amount_Selling_Price__c,HandoverPhase__c
                                     FROM Unit__c WHERE Id IN :unitIds]);
    }
    
    public list<Unit__c> getUnitsBySAPNo(String unitSAPNo) {
        return [SELECT Id,SAP_Unit_Number__c, HO_Agent__c FROM Unit__c WHERE SAP_Unit_Number__c = :unitSAPNo LIMIT 1];
    }
    
    //Get units registered units
    public List<Unit__c> getRegisteredUnitById(List<Unit__c> unitList){
        return [Select Id, Name, Project__c, Project__r.Name, RegistrationDate__c, Active_Sales_Order__r.Account__r.Name, Active_Sales_Order__r.Name
                FROM Unit__c 
                WHERE Id In :unitList AND RegistrationDate__c != null];
    }
    
    //Get units registered units
    public List<Unit__c> getSoldUnitsOfProject(String projectId, String status){
        return [SELECT Id, Name, RegistrationDate__c, Active_Sales_Order__c, ADM_Fee_Included__c, Active_Sales_Order__r.Name, Active_Sales_Order__r.SoldDate__c, 
                Status__c, Active_Sales_Order__r.UnitRegistrationDate__c, Active_Sales_Order__r.DocumentUploadedDate__c, ADMPlotNumber__c, Active_Sales_Order__r.Status__c,
                Active_Sales_Order__r.FundMovedToGRDate__c, Project__r.Name, Project__c
                FROM Unit__c
                WHERE Project__c =:projectId AND Active_Sales_Order__c != null AND Active_Sales_Order__r.Status__c = :status];
    }
    
    public List<Unit__c> getUnitDetails (string unitId){
        
        List<Unit__c> units = [select Id,Project__c, Building__c, BuildingSectionName__r.Project__c,Is_Chiller_Enabled__c,Name from Unit__c where Id=:unitId];
        return units;
    }
    
    public Map<Id,Unit__c> getUnitDetails (List<Id> unitIds){
        
        Map<ID, Unit__c> units = new Map<ID, Unit__c>([select Id,Project__c,BuildingSectionName__r.Project__c,Is_Chiller_Enabled__c from Unit__c where Id IN:unitIds]);
        return units;
    } 
    
    public IntegrationRecord__c getUnitGISIntegrationRecord(Unit__c unit){
        IntegrationRecordService objIntegrationRecordService = IntegrationRecordService.getInstance();
        Map<String,String> paramsMap = new Map<String,String>();
        paramsMap.put('Param1',unit.Project__c);
        paramsMap.put('Param2',unit.ADMPlotNumber__c);
        paramsMap.put('Param3',unit.GIS_Object_Id__c);
        paramsMap.put('Param4',unit.Status__c);
        paramsMap.put('Param5',String.valueof(unit.Net_Amount_Selling_Price__c));
        paramsMap.put('Param6',unit.UnitType__c);
        paramsMap.put('Param7',unit.UnitModel__c);
        paramsMap.put('Param8',String.valueof(unit.PlotArea__c));
        paramsMap.put('Param9',unit.Customer_Name__c);
        paramsMap.put('Param10',String.valueof(unit.SaleableArea__c));
        paramsMap.put('Param11',unit.GISServiceURL__c);
        paramsMap.put('Param12',unit.GIS_Plot_No__c);
        paramsMap.put('Param13',unit.Name);
        return objIntegrationRecordService.getIntegrationRecord('Insert', 'Unit__c', unit.Id, paramsMap);
    }
    
    public Unit__c getUnitNVehicleParkingsByUnitIds(Id unitId){
        return [
            SELECT Id, Name, Project__c, Project__r.Name, NumberOfCarParks__c, ActiveTenant__c,ActiveTenant__r.Name, BuildingSectionName__r.Name,Active_Sales_Order__r.Account__c,Active_Sales_Order__r.Account__r.Name
            FROM Unit__c WHERE Id = :unitId
        ];
    }
    
    

     public void updateUnitOccupancyStatus (string unitId,String status){



      //  Unit__c units = [select Id,Occupancy_Type__c from Unit__c where Id=:unitId];

        

        if(String.isNotBlank(status) && String.isNotBlank(unitId)){

            Unit__c unit = new Unit__c();

            unit.Occupancy_Type__c = status;

            unit.Id = unitId;

            update unit;

        }

        

    }

    

    /** Fetch a Unit by its Name (used in QuickPay validation). */

    public Unit__c getByName(String unitName) {

        return [

            SELECT Id, Name, ProjectName__c, Building_Phase_Name__c

            FROM Unit__c
            WHERE ADMAddressingNumber__c  = :unitName
            LIMIT 1

        ];

    }

    

    public static Map<String, Id> bySapUnitNumber(Set<String> sapUnitNumbers) {

        Map<String, Id> out = new Map<String, Id>();

        if (sapUnitNumbers == null || sapUnitNumbers.isEmpty()) return out;



        for (Unit__c u : [

            SELECT Id, SAP_Contract_No__c, CommunitySAPUnitNumber__c  

            FROM Unit__c

            WHERE CommunitySAPUnitNumber__c  IN :sapUnitNumbers

        ]) {

            if (String.isNotBlank(u.CommunitySAPUnitNumber__c ) && !out.containsKey(u.CommunitySAPUnitNumber__c )) {

                out.put(u.CommunitySAPUnitNumber__c , u.Id);

            }

        }

        return out;

    }
    // BAPP Update Unit
    public void updateExistingUnits(List<Unit__c> units){
        if(units != null && !units.isEmpty()){
            update units;
        }
        
    }
    @AuraEnabled(cacheable=false)
public static List<Unit__c> getUnitsFromAllSalesOrders(String accId){

    Set<Id> unitIds = new Set<Id>();

    for (SalesOrder__c so : [
        SELECT Unit__c
        FROM SalesOrder__c
        WHERE Account__c = :accId
        AND Unit__c != null
    ]) {
        unitIds.add(so.Unit__c);
    }

    if(unitIds.isEmpty()){
        return new List<Unit__c>();
    }

    return [
        SELECT Id, Name
        FROM Unit__c
        WHERE Id IN :unitIds
    ];
}
public Map<Id, Unit__c> getUnitsWithFloorPlan(Set<Id> unitIds) {
    return new Map<Id, Unit__c>([
        SELECT Id, WebFloorPlanCDId__c, WebFloorPlan__c,WebFloorPlanCVId__c
        FROM Unit__c
        WHERE Id IN :unitIds
    ]);
}

    public Map<Id, List<Document__c>> getUnitDocumentsByUnitIds(Set<Id> unitIds){

        Map<Id, List<Document__c>> unitVsDocumentsMap = new Map<Id, List<Document__c>>();

        if(unitIds == null || unitIds.isEmpty()){
            return unitVsDocumentsMap;
        }

        List<Document__c> unitDocuments = [
            SELECT Id, Name, Unit__c, ContentDocumentId__c, Content_Version_Id__c, DocumentType__c, DocumentType__r.Type__c
            FROM Document__c
            WHERE Unit__c IN :unitIds AND DocumentType__r.IsAvailableForApp__c = true AND ContentDocumentId__c != null
        ];

        for(Document__c doc : unitDocuments){
            if(!unitVsDocumentsMap.containsKey(doc.Unit__c)){
                unitVsDocumentsMap.put(doc.Unit__c, new List<Document__c>());
            }
            unitVsDocumentsMap.get(doc.Unit__c).add(doc);
        }
        return unitVsDocumentsMap;
    }

   
}