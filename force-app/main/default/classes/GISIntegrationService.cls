/*
* @Author : Biswajeet Samal
* @CreatedDate : 7th AUG 2024
* @Description : GIS Integration Service Class
*/
/*****************************************************************************************************
* Version       Author      Date             Comment                                                                       
* 1.0           Biswajeet   07AUG2024        Initial draft 
* 2.0           Jayprakash  20AUG2024        Implemented GIS Integration
*****************************************************************************************************/
public class GISIntegrationService { 
    
    private static GISIntegrationService instance;
    private LogService logInstance = LogService.getInstance();
    private static final string MDT_GIS_TOKEN_INTEGRATION_SETTING { 
        get
        { 
            return 'GISIntegrationSetting'; 
        } 
    }
    
    private String tokenValue;
    Private List<Unit__c> unitList;
    Map<String,ProjectPlot> projetplotMap;// used to hold project GIS API
    Map<String,Unit__c> unitCodeUnitObjMap;// = new Map<String,Unit__c>();
    List<Unit__c> withObjectIDUnitList; // used to hold List of Units already having ObjectId
    Map<String,String> othetUnitCodeObjectIdMap;// map used to update objectId of other units;
    Map<String,List<PushWrap>> projectAttributeListMap; // Map for final push data
    List<Integration_Logs__c> IntegrationLogList;
    
    private GISIntegrationService() {      
    }
    
    public static GISIntegrationService getInstance() {
        if(instance == null) {
            instance = new GISIntegrationService();
        }
        return instance;
    }
    
    private void getToken(){
        MetadataService objMetadataService = MetadataService.getInstance();
        Integration_Details__mdt objIntegrationdetails = objMetadataService.getIntegrationDetails(MDT_GIS_TOKEN_INTEGRATION_SETTING);
        if(objIntegrationdetails != null){
            HttpRequest request = new HttpRequest();
            request.setEndpoint(objIntegrationdetails.End_Point_URL__c);
            request.setMethod(objIntegrationdetails.MethodType__c);
            request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            String requestBody ='username='+objIntegrationdetails.User_Name__c+'&password='+objIntegrationdetails.Password__c+'&client=referer&referer=https://www.arcgis.com&expiration=60&f=json';
            request.setBody(requestBody);
            Http http = new Http();            
            try {
                HttpResponse response = http.send(request);
                Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                this.tokenValue = (String) jsonResponse.get('token');
                IntegrationLogList.add(logInstance.getIntegrationLog(request,response,'Outbound','GIS'));
            } catch (Exception e) {
                System.debug('Exception caught>> ' + e.getMessage());
            }
        }
    }
    
    private void getUnitObjectId(ProjectPlot GISPlot){
        
        if(string.isNotEmpty(tokenValue) && GISPlot!=null){          //&& unit.GIS_Object_Id__c!=null
            String outFields='Project,ADM_Plot_Number,ObjectiD,Unit_Code,status';
            String endPointURL= GISPlot.Url+'/query?where=ADM_Plot_Number=\''+GISPlot.plot+'\'&outFields='+outFields+'&objectIds=&time=&resultType=none&returnHiddenFields=false&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnDistinctValues=false&cacheHint=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&sqlFormat=none&f=json&token='+tokenValue;
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endPointURL);
            request.setMethod('GET');
            
            Http http = new Http();            
            try {
                HttpResponse response = http.send(request);
                UpdateUnitObjectId(response);
                IntegrationLogList.add(logInstance.getIntegrationLog(request,response,'Outbound','GIS'));
            } catch (Exception exp) {
                IntegrationLogList.add(logInstance.getExceptionLog(exp, 'Outbound', 'GIS'));
            }
        }
    }
    
    private void updateUnitObjectId(HttpResponse response){
        GisObjectIdReaponse GisObjectId = (GisObjectIdReaponse) JSON.deserialize(response.getBody(), GisObjectIdReaponse.class);
        try{
            for(Feature feature:GisObjectId.features){
                if(feature.attributes!=null && feature.attributes.ObjectId!=null  ){
                    //if Unit code is of other units then only update there ObjectID
                    if(unitCodeUnitObjMap.containsKey(feature.attributes.Unit_Code)){
                        Unit__c unit = unitCodeUnitObjMap.get(feature.attributes.Unit_Code);
                        unit.GIS_Object_Id__c = String.valueOf(feature.attributes.ObjectId);
                        unitCodeUnitObjMap.put(unit.Name,unit);
                    }else{
                        //UPdate only objectId in SF. create Map
                        othetUnitCodeObjectIdMap.put(feature.attributes.Unit_Code,String.valueOf(feature.attributes.ObjectId));
                    }
                }
            }
        } catch (Exception exp) {
            IntegrationLogList.add(logInstance.getExceptionLog(exp, 'Outbound', 'GIS'));
        }
    }
    
    private void updatedDatatoGIS( List<Pushwrap> pushAttributeList,String gisEndpoint){
        String reqData='';
        for(Pushwrap pw:pushAttributeList){
            string tempReq = JSON.serialize(pw);
            reqData =reqData+tempReq+',';
        }
        reqData = reqData.removeEnd(',');
        reqData = '['+reqData+']';
        String endPointURL= gisEndpoint+'/applyEdits?token='+tokenValue+'&Updates='+reqdata+'&f=json';
        
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endPointURL);
        request.setHeader('Content-Type','application/x-www-form-urlencoded');
        request.setHeader('Content-Length', '0');
        request.setTimeout(120000);
        request.setMethod('POST');
        Http http = new Http();            
        try {
            HttpResponse response = http.send(request);
            IntegrationLogList.add(logInstance.getIntegrationLog(request,response,'Outbound','GIS'));
        } catch (Exception exp) {
            IntegrationLogList.add(logInstance.getExceptionLog(exp, 'Outbound', 'GIS'));
        }
    }
    
    private void splitdataProjectWise(){
        projectAttributeListMap = new Map<String,List<PushWrap>>();
        withObjectIDUnitList.addAll(unitCodeUnitObjMap.values());
        if(withObjectIDUnitList!=null && withObjectIDUnitList.size()>0){
            for(Unit__c unit:withObjectIDUnitList){
                if(unit.GIS_Object_Id__c!=null){
                    pushAttribute pal = new pushAttribute();
                    pal.OBJECTID= Integer.valueOf(unit.GIS_Object_Id__c);
                    pal.status= unit.Status__c;
                    pal.Selling_Price_AED= unit.Net_Amount_Selling_Price__c;//SellingPrice__c;
                    pal.Unit_Type = unit.UnitType__c;
                    pal.Unit_Model = unit.UnitModel__c;
                    pal.Plot_Area = unit.PlotArea__c;
                    pal.Customer_Name = unit.Customer_Name__c!= null ? EncodingUtil.urlEncode(unit.Customer_Name__c, 'UTF-8'): '';
                    pal.Saleable_Area = unit.SaleableArea__c;
                    
                    if(projectAttributeListMap.containsKey(unit.Project__c)){
                        list<PushWrap> tempLst = projectAttributeListMap.get(unit.Project__c);
                        PushWrap pw = new PushWrap(pal);
                        tempLst.add(pw);
                        projectAttributeListMap.put(unit.Project__c, tempLst);
                    }else{
                        PushWrap pw = new PushWrap(pal);
                        projectAttributeListMap.put(unit.Project__c, new List<PushWrap>{pw});
                    }
                }
            }
        }
    }
    
    private void updateUnitRecords(){
        Map<String,String> UnitCodeObjectIdMap = othetUnitCodeObjectIdMap;
        for(Unit__c unit: unitCodeUnitObjMap.values()){
            UnitCodeObjectIdMap.put(unit.Name,unit.GIS_Object_Id__c);
        }
        
        for(Unit__c unit: withObjectIDUnitList){
            UnitCodeObjectIdMap.put(unit.Name,unit.GIS_Object_Id__c);
        }
        try{
            if(UnitCodeObjectIdMap!=null && !UnitCodeObjectIdMap.isEmpty()){
                //get the Unit list in otherList and not having objectID
                UnitService objUnitService = UnitService.getInstance();
                List<Unit__c> unitList= objUnitService.getUnitsByNames(UnitCodeObjectIdMap.keySet());
                for(Unit__c unit:unitList){
                    unit.Send_to_GIS__c=false;
                    unit.GIS_Object_Id__c = UnitCodeObjectIdMap.get(unit.name);
                }
                objUnitService.updateUnitsWithoutTrigger(unitList);
            }
        } catch (Exception exp) {
            IntegrationLogList.add(logInstance.getExceptionLog(exp, 'Outbound', 'GIS'));
        }
    }
    
    public void executeIntegration(){
        IntegrationLogList= new List<Integration_Logs__c>();
        withObjectIDUnitList =new List<Unit__c>();
        othetUnitCodeObjectIdMap = new map<string,String>();
        Map<String,String> ProjectUrlMap = new Map<String,String>();
        projetplotMap = new Map<String,ProjectPlot>();
        if(this.unitList!=null && !this.unitList.isEmpty()){
            //1. do Token Allout and set Token Value
            this.getToken();
            
            //2. Perform data logic
            unitCodeUnitObjMap = new Map<String,Unit__c>();
            for(Unit__c unit:this.unitList){
                ProjectUrlMap.put(unit.Project__c,unit.Project__r.GIS_Service_URL__c);
                /*Start: 3.0 Commenting below code to update objectId of each units everytime
                if(unit.GIS_Object_Id__c!=null){
                    withObjectIDUnitList.add(unit);
                }else
                //End: 3.0
				*/{
                    unitCodeUnitObjMap.put(unit.name,unit); 
                    ProjectPlot pp = new ProjectPlot();
                    pp.name= unit.Project__c+'_'+unit.GIS_Plot_No__c;
                    pp.plot =unit.GIS_Plot_No__c;
                    pp.project=unit.Project__c;
                    pp.url=unit.Project__r.GIS_Service_URL__c;
                    projetplotMap.put(unit.Project__c+'_'+unit.GIS_Plot_No__c,pp);
                    
                }
            }
            
            //3. do GetObject CallOut for Each PlotNumber. This will also unitCodeUnitObjMap with objectId in Units.
            for(ProjectPlot pp : projetplotMap.values()){	getUnitObjectId(pp);       }
            
            //4. Split data project wise
            SplitdataProjectWise();
            
            //5. Push Updated Data to GIS
            for(String projectId:projectAttributeListMap.keySet() ){
                UpdatedDatatoGIS(projectAttributeListMap.get(projectId),ProjectUrlMap.get(projectId));
            }
            
            //6. Update the ObjectId of other units
            updateUnitRecords();
            
            //7. Insert the Exception log 
            logInstance.insertIntegrationLogs(IntegrationLogList);
            
        }
    }
    
    public void getUnitList(List<Unit__c> unitList){
        Set<Id> unitIds = (new Map<Id,SObject>(unitList)).keySet();
        UnitService objUnitService = UnitService.getInstance();
        this.unitList = objUnitService.getUnitsByIds(unitIds);
    }
    
    class GisObjectIdReaponse{
        Public String objectIdFieldName;
        Public String globalIdFieldName;
        Public UniqueIdField uniqueIdField;
        Public List<Field> fields;
        Public List<Feature> features;
    }
    class UniqueIdField{
        Public String name;
        Public boolean isSystemMaintained;
    }
    class Field{
        Public String name;
        Public String type;
        Public String alias;
        Public String sqlType;
        Public String domain;
        Public String defaultValue;
    }
    class Feature{
        Public Attributes attributes;
    }
    class Attributes{
        Public String UDM_PLOTNUMBER;
        Public String Unit_Code;
        Public Integer ObjectId;
        Public String Status;
    }
    class PushWrap{
        PushAttribute attributes;
        PushWrap(PushAttribute pa){
            attributes= pa;
        }
    }
    class PushAttribute{
        Public Integer ObjectId;
        //Public String Plot_Area;
        Public String Status;
        Public String Unit_Type;
        Public String Unit_Model;
        public decimal Plot_Area;
        public decimal Selling_Price_AED;
        public Decimal Saleable_Area;
        Public String Customer_Name;
    }
    class ProjectPlot{
        Public String name;
        Public String Project;
        Public String Plot;
        Public String url;
    }
}