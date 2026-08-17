/***
Class       : salesValidationsDisplayCtrl
Author      : Smaartt
Description : 
TestClass   : salesValidationsDisplayCtrlTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.     version              Date                Details
1.          V1.0                                Initial Version 
****************************************************************************************************************/


public class salesValidationsDisplayCtrl {
    
    @AuraEnabled
    public static salesValidationWrapper getSalesValidation(String recordId){
        string flagApiName= null;
        
        string profileName  = [select id,name from profile where Id=:userInfo.getProfileId()].Name;       
        String sObjectName = Id.valueOf(recordId).getSObjectType().getDescribe().getName();
        salesValidationWrapper wrap = new salesValidationWrapper();
        wrap.metaConfigData=null;
        String relationshipAPIName;
        list<Sales_Validation_c__mdt> metaData = [select MasterLabel,Identifier__c,Relationship_API_Name__c from Sales_Validation_c__mdt where Identifier__c LIKE :('%' + profileName + '%') and sObject__c LIKE :('%' + sObjectName + '%')];        
        for(Sales_Validation_c__mdt meta:metaData){
            if(meta.Relationship_API_Name__c!=null){
            	relationshipAPIName=meta.Relationship_API_Name__c;
                break;
            }
            
        }
        if(metaData.size()>0){
        String query='select id,name,Validation_Type__c,Validation_Sub_Type__c,Approver_Comments__c,Initiator_Comments__c,Initiator_Validated_Flag__c,Approver_Validated_Flag__c from Sales_Validation__c where '+ relationshipAPIName +'=:recordId';
        System.debug(query);
        wrap.validationRecords =database.query(query);
        wrap.metaConfigData=metaData;
        }
        return wrap;
    }
    
     @AuraEnabled
    public static void updateSalesValidationInfo(List<Sobject> records){
        
        try{
          update records;            
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());   
            
        }
    }
    

   /* @AuraEnabled
    public static String updateSalesValidation(Sales_Validation__c tempVal){
        tempVal.Last_Modified_Date__c= system.now();
        tempVal.Last_Modified_By__c= UserInfo.getUserId(); 
        try{
            update tempVal;
            return 'Success';
        }
        catch(Exception ex){
            throw ex ;
        }
        
    }*/
    
    
    
    public class salesValidationWrapper {
        
        @AuraEnabled
        public list<Sales_Validation_c__mdt> metaConfigData {get;set;}
        @AuraEnabled
        public list<Sales_Validation__c> validationRecords {get;set;}
        
    }
}