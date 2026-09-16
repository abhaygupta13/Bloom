/***
Class       : CTIHandler
Author      : Aman Bharti
Description : 
TestClass   : 
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0            13/05/26           Initial Version 
****************************************************************************************************************/
public inherited sharing class CTIHandler {
    private static CTIHandler instance;
    
    private CTIHandler() {
        
    }
    
    public static CTIHandler getInstance() { 
        if(instance == null) {
            instance = new CTIHandler();
        }
        return instance;
    }

    public void getIntegrationRecord(Id recordId, String phoneNumber, String skill){
            IntegrationRecordService integService = IntegrationRecordService.getInstance();
            IntegrationRecord__c integrationRecObj= new IntegrationRecord__c();
            Map<String, String> paramMap = new Map<String, String>();
                paramMap.put('Param1', Utility.getInstance().cleanPhoneNumber(phoneNumber));   
                paramMap.put('Param2', Utility.getInstance().maskPhoneNumber(phoneNumber));        
                paramMap.put('Param3', UserInfo.getUserEmail());
                paramMap.put('Param4', skill);
            integrationRecObj = integService.getIntegrationRecord('CLICK_TO_DIAL', 'Insert', recordId.getSObjectType().getDescribe().getName(), recordId, paramMap);
            integService.insertIntegrationRecords(new List<IntegrationRecord__c>{integrationRecObj});
    }

    
}