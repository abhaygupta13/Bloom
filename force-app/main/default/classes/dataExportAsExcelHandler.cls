/***
Class       : dataExportAsExcelHandler
Author      : Smaartt
Description : 
TestClass   : dataExportAsExcelHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              23/01/24           Initial Version 
****************************************************************************************************************/
public class dataExportAsExcelHandler {
    
    @Auraenabled(cacheable=true)
    public static List<SObject> exportData(String parentId, String identifier) {
        
        String sObjName = Id.valueOf(parentId).getSObjectType().getDescribe().getName();
        
        // Use dynamic SOQL to fetch Export_Data_Config__mdt record
        Export_Data_Config__mdt exportDataConfig = [SELECT Id, Parentookup_Api_Name__c, Fileds__c, Identifier_Filter__c, Parent_Sobject__c, Related_Sobject__c FROM Export_Data_Config__mdt WHERE Parent_Sobject__c = :sObjName AND Identifier_Filter__c = :identifier LIMIT 1];
        
        List<SObject> sObjectList = new List<SObject>();
        
        if (exportDataConfig != null) {
            // Use dynamic SOQL to query related SObject using Export_Data_Config__mdt fields
            String query = 'SELECT Id, ' + exportDataConfig.Fileds__c + ' FROM ' + exportDataConfig.Related_Sobject__c + ' WHERE ' + exportDataConfig.Parentookup_Api_Name__c + ' = :parentId';
            sObjectList = Database.query(query);
        } 
        return sObjectList;
    }
    
}