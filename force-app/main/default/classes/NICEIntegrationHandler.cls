/***
Class       : NICEIntegrationHandler
Author      : Aman Bharti
Description : 
TestClass   : 
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0            13/05/26           Initial Version 
****************************************************************************************************************/
public inherited sharing class NICEIntegrationHandler {
    private static NICEIntegrationHandler instance;
    
    private NICEIntegrationHandler() {
        
    }
    
    public static NICEIntegrationHandler getInstance() { 
        if(instance == null) {
            instance = new NICEIntegrationHandler();
        }
        return instance;
    }

    public void getIntegrationRecordObj(String objName, String recordId, String phoneNumber, String maskedValue, String skill){
            IntegrationRecordService integService = IntegrationRecordService.getInstance();
            IntegrationRecord__c integrationRecObj= new IntegrationRecord__c();
            Map<String, String> paramMap = new Map<String, String>();
                paramMap.put('Param1', Utility.getInstance().cleanPhoneNumber(phoneNumber));   
                paramMap.put('Param2', maskedValue);        
                paramMap.put('Param3', UserInfo.getUserEmail());
                paramMap.put('Param4', skill);
            integrationRecObj = integService.getIntegrationRecord('CLICK_TO_DIAL', 'Insert', objName, recordId, paramMap);
            integService.insertIntegrationRecords(new List<IntegrationRecord__c>{integrationRecObj});
    }

    
}