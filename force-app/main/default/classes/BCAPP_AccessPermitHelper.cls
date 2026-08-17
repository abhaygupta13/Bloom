public class BCAPP_AccessPermitHelper {
    
    public void createAccessPermitRequest(String data){
         
        Map<String,Object>  returnValue = new Map<String,Object>();
        Case sr;
        BCAPP_Utility utility_ref = BCAPP_Utility.getInstance();
        Map<String, Object> reqData = (Map<String, Object>) JSON.deserializeUntyped(data);
        BCAPP_Utility utility = new BCAPP_Utility();
        String accountId = (String)reqData.get('accountId');
        List<User__c> customer;
        if(!String.isBlank(accountId)){
            customer = utility_ref.getUserbyAccountId(accountId);
        }
        if(customer.isEmpty()){
            returnValue.put('errorMessage','Invalid User');
            BCAPP_WebServiceHelper.makeServerErrorResponse(returnValue);
            return;
        }
        if(!String.isBlank(customer[0].Account__c)){
            Case accessPermit = new Case();
            try{
                accessPermit.Access_Permit_Preferred_Date__c  =  utility.parseDate((String)reqData.get('preferredDate'));
                accessPermit.Access_Permit_Category__c = (String)reqData.get('category');
                accessPermit.Service_Types__c = (String)reqData.get('serviceType');
                accessPermit.Permit_Validaity__c = (String)reqData.get('permitValidity');
                accessPermit.Access_Permit_Description__c = (String)reqData.get('description');
                accessPermit.Access_Permit_Company__c = (String)reqData.get('company');
                accessPermit.Unit__c = (String)reqData.get('unitId');
                accessPermit.AccountId = accountId;
                accessPermit.User_Type__c = customer[0].User_Type__c;
                accessPermit.Email_Address__c = customer[0].Email__c;
                accessPermit.Status = 'Submitted';
                accessPermit.Type='Gate Pass';
                accessPermit.Case_Sub_Status__c='Pending Check-In';
                accessPermit.Origin='Mobile app';
                accessPermit.subject='Access Permit Request';

                if(reqData.get('frequency')!=null){
                    accessPermit.Frequency__c = (String)reqData.get('frequency');
                }
                if((accessPermit.Access_Permit_Category__c=='Delivery' ) ||
                   (accessPermit.Access_Permit_Category__c== 'Maintenance' && accessPermit.Permit_Validaity__c=='1')){
                        accessPermit.Frequency__c='One time';
                }
                if(accessPermit.Access_Permit_Category__c== 'Maintenance' && accessPermit.Permit_Validaity__c !='1'){
                     accessPermit.Frequency__c='Recurring';
                }
                if((String)reqData.get('dateFrom')!=null){
                    accessPermit.Permit_From_Date__c  =  utility.parseDate((String)reqData.get('dateFrom'));
                    if(accessPermit.Access_Permit_Preferred_Date__c ==NULL){
                        accessPermit.Access_Permit_Preferred_Date__c=accessPermit.Permit_From_Date__c;
                    }
                }
                if((String)reqData.get('dateTo')!=null){
                    accessPermit.Permit_To_Date__c  =  utility.parseDate((String)reqData.get('dateTo'));
                }
                accessPermit.Request_Type__c = BCAPP_Constants.ACCESS_PERMIT;
                List<Service_Catalog__c> sc = ServiceCatalogService.fetchServiceCatalogByName('Access Permit');
                if(!sc.isEmpty()){
                    accessPermit.Service_Catalog__c = sc[0].Id;
                } 
                accessPermit.recordTypeId = Utilities.getRecordTypeId('Case', BCAPP_Constants.ACCESS_PERMIT);
                if(accessPermit.Unit__c!=null){
                    List<Unit__c> units = UnitService.fetchUnitDetailsById(accessPermit.Unit__c);
                    if(!units.isEmpty()){
                        accessPermit.Project__c =  units[0].Project__c;
                        accessPermit.Project_Name__c =  units[0].Project__r.Name;
                    }
                }
                CaseService cService = CaseService.getInstance();
                cService.insertCase(accessPermit); 
                sr = cService.getCaseById(accessPermit.Id);
                returnValue.put('requestNumber',sr.CaseNumber);
                returnValue.put('srId',sr.Id );
                BCAPP_WebServiceHelper.makeSuccessResponse(returnValue);
            }
            catch(Exception e){
                returnValue.put('errorMessage','Failed to Access Permit Request: ' + e.getMessage());
                BCAPP_WebServiceHelper.makeServerErrorResponse(returnValue);
            }
        }
        else{
            returnValue.put('errorMessage','User Not found');
            BCAPP_WebServiceHelper.makeServerErrorResponse(returnValue);
        }
    }
    
    public List<Map<String, String>> getCategoryOptions(String objectApiName, String fieldApiName) {
        List<Map<String, String>> picklistOptions = new List<Map<String, String>>();
        
        // Get the schema describe for the sObject
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectApiName);
        if (objectType == null) {
            throw new IllegalArgumentException('Invalid object API name: ' + objectApiName);
        }
        
        Schema.DescribeSObjectResult describeResult = objectType.getDescribe();
        
        Schema.DescribeFieldResult fieldDescribe = describeResult.fields.getMap().get(fieldApiName).getDescribe();
        
        List<Schema.PicklistEntry> picklistEntries = fieldDescribe.getPicklistValues();
        
        // Populate the list with label-value pairs for the picklist options
        for (Schema.PicklistEntry entry : picklistEntries) {
            if (entry.isActive()) {
                Map<String, String> picklistValue = new Map<String, String>();
                picklistValue.put('label', entry.getLabel());
                picklistValue.put('value', entry.getValue());
                
                picklistOptions.add(picklistValue);
            }
        }
        
        return picklistOptions;
    }
    
    // Method to get dependent picklist values based on controlling field value
    public  List<Map<String, String>> getDependentPicklistValues(String dependentFieldName,String ObjectName,String controllingFieldValue) {
        
        List<Map<String,String>> dependentPicklistValues = new List<Map<String,String>>();
        Schema.sObjectField dependentField = getFieldFromApiName(ObjectName,dependentFieldName);
        Schema.DescribeFieldResult dependentFieldResult = dependentField.getDescribe();
        Schema.sObjectField controllerField = dependentFieldResult.getController();
        if (controllerField == null) {
            return null;
        }
        Schema.DescribeFieldResult controllerFieldResult = controllerField.getDescribe();
        
        List<Schema.PicklistEntry> controllerValues = (controllerFieldResult.getType() == Schema.DisplayType.Boolean ? null : controllerFieldResult.getPicklistValues());
        String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        for (Schema.PicklistEntry dependentEntry : dependentFieldResult.getPicklistValues()) {
            if (dependentEntry.isActive()) {
                List<String> base64chars = String.valueOf(((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(dependentEntry))).get('validFor')).split('');
                for (Integer i = 0; i < controllerValues.size(); i++) {
                    String controllerValue = controllerValues[i].isActive() ? controllerValues[i].getLabel() : null;
                    if (controllerValue == null) continue;
                    Integer bitIndex = i / 6;
                    Integer bitShift = 5 - Math.mod(i, 6);
                    if ((base64map.indexOf(base64chars[bitIndex]) & (1 << bitShift)) != 0  && controllingFieldValue==controllerValue) {
                        Map<String, String> dependentPicklistMap = new Map<String, String>();
                        dependentPicklistMap.put('label', dependentEntry.getValue());
                        dependentPicklistMap.put('value', dependentEntry.getLabel());
                        dependentPicklistValues.add(dependentPicklistMap);
                    }
                    
                }
            }
        }
        return dependentPicklistValues; 
        
    }
    
    public Schema.sObjectField getFieldFromApiName(String objectApiName, String fieldApiName) {
        // Get the Schema for the sObject
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectApiName);
        
        if (objectType == null) {
            throw new IllegalArgumentException('Invalid object API name: ' + objectApiName);
        }
        
        Schema.DescribeSObjectResult describeResult = objectType.getDescribe();
        
        Map<String, Schema.SObjectField> fields = describeResult.fields.getMap();
        
        if (fields.containsKey(fieldApiName)) {
            return fields.get(fieldApiName);
        } else {
            throw new IllegalArgumentException('Field API name not found: ' + fieldApiName);
        }
    }
}