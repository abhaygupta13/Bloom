/***
Class       : reUsableSubStatusController
Author      : Smaartt
Description : 
TestClass   : reUsableSubStatusControllerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.     version              Date                Details
1.          V1.0                                Initial Version 
****************************************************************************************************************/

public class reUsableSubStatusController {
    
    @AuraEnabled(cacheable=false)
    public static List<Generic_Sub_Status_Config__mdt> getSubStatusValues(Id recordId) {
        
        List<Generic_Sub_Status_Config__mdt> subStatusValues = new List<Generic_Sub_Status_Config__mdt>();
        String sObjectName = recordId.getSObjectType().getDescribe().getName();
        
        List<Sub_Status_Object_Fields_Config__mdt> fields = [SELECT Id, MasterLabel, Remarks_API_Name__c, Sub_Status_API_Name__c FROM Sub_Status_Object_Fields_Config__mdt WHERE MasterLabel = :sObjectName];
        
        if (fields.size() > 0 && fields[0].Sub_Status_API_Name__c != null && fields[0].Remarks_API_Name__c != null) {
            String query = 'SELECT Id,' + fields[0].Sub_Status_API_Name__c + ',' + fields[0].Remarks_API_Name__c + ' FROM ' + sObjectName + ' WHERE Id = :recordId';
            sobject result = Database.query(query);
            String currentRecordStatus = String.valueOf(result.get(fields[0].Sub_Status_API_Name__c));
            
            try {
                subStatusValues = getSubStatusDetails(currentRecordStatus, sObjectName);
            } catch (Exception e) {
                throw new AuraHandledException('Error in getSubStatusValues: ' + e.getMessage());
            }
        }
        
        return subStatusValues;
    }
    
    public static List<Generic_Sub_Status_Config__mdt> getSubStatusDetails(String currentRecStatus, String sObjectName) {
        String profileId = UserInfo.getProfileId();
        List<Map<String, String>> subStatusDetails = new List<Map<String, String>>();
        String currentUserId = UserInfo.getUserId();
        User currentUser = [SELECT Profile.Name FROM User WHERE Id = :currentUserId];
        String profileName = currentUser.Profile.Name;
        
        List<Generic_Sub_Status_Config__mdt> nextStatusValues = [SELECT NextApplicableStatus__c, Reject_Reasons__c FROM Generic_Sub_Status_Config__mdt WHERE MasterLabel = :currentRecStatus AND Sobject__c = :sObjectName AND User_Identifier__c LIKE :('%' + profileName + '%')];
        return nextStatusValues;
    }
    
    
    
    @AuraEnabled(cacheable=true)
    public static list<Sub_Status_Object_Fields_Config__mdt> getSobjectFieldInfo(string recordId){
        
        String sObjectName = Id.valueOf(recordId).getSObjectType().getDescribe().getName();        
        list<Sub_Status_Object_Fields_Config__mdt> data = [SELECT Id, MasterLabel,SPA_signed_Date_Api_Name__c, Remarks_API_Name__c,Sub_Status_API_Name__c,Backup_Remarks_API_Name__c,Reject_Reason_Api_Name__c FROM Sub_Status_Object_Fields_Config__mdt WHERE MasterLabel =:sObjectName];
        return data;
    }
    
    
    
    @AuraEnabled
    public static void updateSobjectRec(sObject record,list<Sub_Status_Object_Fields_Config__mdt> sobjectConfigInfo){
        string backUpApiName = sobjectConfigInfo[0].Backup_Remarks_API_Name__c;
        string sobjectName = sobjectConfigInfo[0].MasterLabel;
        String subStatusApiName = sobjectConfigInfo[0].Sub_Status_API_Name__c;
        String subStatusValue = (String)record.get(subStatusApiName);
        
        string userName = [select Name from user where Id=:userinfo.getuserId()].Name;
        if(backUpApiName!=null){
        Sobject oldRec = database.query('Select '+backUpApiName+' From '+sobjectName+' Where Id IN (\'' + record.Id + '\')');
        if(record.get(backUpApiName)!=null){
            string newCmnt = userName+': '+record.get(backUpApiName);
            record.put(backUpApiName,oldRec.get(backUpApiName) == null?newCmnt:oldRec.get(backUpApiName)+'\n'+newCmnt);
        }}
        
        List<DynamicSobjectAction__mdt> dynamicActionList =[Select id,Sequence__c,ActionSobjectName__c,ActionType__c,UpdateApiName__c,Update_Value__c From DynamicSobjectAction__mdt Where CondtionApiName__c=:subStatusApiName AND ConditionValue__c=:subStatusValue AND CondtionSobject__c=:sobjectName Order By Sequence__c ASC ];
        
        
        if(dynamicActionList.size()>0){
            for(DynamicSobjectAction__mdt  act:dynamicActionList ){
                if(act.ActionType__c=='Update' && act.ActionSobjectName__c==sobjectName   ){
                    record.put(act.UpdateApiName__c,act.Update_Value__c);
                    
                }
            }
        } 
        try{
            update record;
        }catch(Exception e){
            list<string> sfs = e.getMessage().split(',');
            sfs.remove(0);
            String errorMessage = String.join(sfs, ', ');
            errorMessage = errorMessage.removeEnd(': []');
            throw new Auraexception(errorMessage);
        }
        
        
    }
    
    
    
    @AuraEnabled(cacheable=false)
    public static String getSalesOrderStatus(String salesOrderId) {
        System.debug(salesOrderId);
        try {
            SalesOrder__c salesOrder = [SELECT Id, Status__c FROM SalesOrder__c WHERE Id = :salesOrderId];
            
            if (salesOrder != null) {
                return salesOrder.Status__c;
            } else {
                return 'Record not found';
            }
        } catch (Exception ex) {
            return 'Error: ' + ex.getMessage();
        }
    }
      
}