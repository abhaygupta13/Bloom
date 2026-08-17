/***
Class       : CaseSubstatusUpdateHandler
Author      : Smaartt
Description : 
TestClass   : CaseSubstatusUpdateHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0              12/12/23           Initial Version  

****************************************************************************************************************/

public class CaseSubstatusUpdateHandler {
    
    @AuraEnabled
    public static List<Case_Status_Configuration__mdt> getSubStatusValues(string recordId) {
        
        String currentUserId = UserInfo.getUserId();
        User currentUser = [SELECT Profile.Name FROM User WHERE Id = :currentUserId];
        String profileName = currentUser.Profile.Name;
        case ca = [select id , Case_Sub_Status__c, recordtype.name from case where id = :recordId];
        system.debug(ca);
        List<Case_Status_Configuration__mdt> nextStatusValues = [SELECT Next_Applicable_Status__c FROM Case_Status_Configuration__mdt WHERE MasterLabel = :ca.Case_Sub_Status__c AND isActive__c=true AND Case_Type__c =:ca.recordtype.name AND User_Identifier__c LIKE :('%' + profileName + '%')];
        system.debug(nextStatusValues);
        return nextStatusValues;
        
    }
    
     @AuraEnabled
    public static List<Case_Status_Display_Config__mdt> getNextApplicableStatus(string caseSubStatus,String caseId) {
        
       List<Case>caseDetail = [SELECT Id, CaseNumber, RecordTypeId, RecordType.Name FROM Case where id=:caseId ];
         System.debug(caseDetail);
        String recordTypeName = caseDetail[0].RecordType.Name;
        System.debug(recordTypeName);
        List<Case_Status_Display_Config__mdt>getNextApplicableStatus = [SELECT Case_Record_Type__c,Case_Status__c,MasterLabel FROM Case_Status_Display_Config__mdt WHERE MasterLabel = :caseSubStatus AND Case_Record_Type__c =:recordTypeName];
        system.debug(getNextApplicableStatus);
        
        return getNextApplicableStatus;
        
    }
    @AuraEnabled
    Public static void updateCase(Case caseInfo){
        try{
            Update caseInfo;
         
        }catch(Exception e){
           list<string> sfs = e.getMessage().split(',');
            sfs.remove(0);
            String errorMessage = String.join(sfs, ', ');
            errorMessage = errorMessage.removeEnd(': []');
            throw new Auraexception(errorMessage);
        }
    }
    
   

    @AuraEnabled
    public static List<Sales_Validation__c> checkRequiredFlag(String recordId, String selectedSubStatus) {
        Map<String, Sales_Validation_Types_Config__mdt> salesValidationMetadataMap = new Map<String, Sales_Validation_Types_Config__mdt>();
       List<Sales_Validation__c>salesValidatondetail = new List<Sales_Validation__c>();
        for (Sales_Validation_Types_Config__mdt config : [SELECT MasterLabel, Is_Active__c, required__c, ValidationType__c FROM Sales_Validation_Types_Config__mdt WHERE Is_Active__c = true AND required__c = true]) {
            salesValidationMetadataMap.put(config.MasterLabel, config);
        }
          List<Case>caseDetail = [SELECT Id, CaseNumber,Type, RecordTypeId, RecordType.Name FROM Case where id=:recordId ];
         System.debug(caseDetail);
        String caseType = caseDetail[0].Type;

        List<Sales_Validation__c> caseRelatedSalesValidation = [SELECT Id, Case__c, Approver_Validated_Flag__c, Validation_Sub_Type__c FROM Sales_Validation__c WHERE Case__c = :recordId AND Approver_Validated_Flag__c != 'Yes'];
        System.debug('caseRelatedSalesValidation'+caseRelatedSalesValidation);
        if (selectedSubStatus == 'Transfer Completed' && (caseType=='Transfer of Right'||caseType=='Gifting'||caseType=='NOC/Transfer of Right')) {
            for (Sales_Validation__c svd : caseRelatedSalesValidation) {
                String validationSubType = svd.Validation_Sub_Type__c;
                if (salesValidationMetadataMap.containsKey(validationSubType)) {
                    salesValidatondetail.add(svd);
                    return salesValidatondetail;
                }
                return null;
            }
        }
        return null;

       
    }
    
    @AuraEnabled(cacheable=false)
    public static String getCaseStatus(String caseId) {
        System.debug(caseId);
        try {
            Case ca = [SELECT Id, Status FROM Case WHERE Id = :caseId];
            
            if (ca != null) {
                return ca.Status;
            } else {
                return 'Record not found';
            }
        } catch (Exception ex) {
            return 'Error: ' + ex.getMessage();
        }
    }
     
    
    
}