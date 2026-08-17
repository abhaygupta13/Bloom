@isTest
private class ConnectorTimeLogController_Test {

     static testMethod void myUnitTest() {
        Object o;
        ConnectorTimeLogController ctlc = new ConnectorTimeLogController(o);
                    
        Map<String, Object> objCreate = new Map<String, Object>{
        
            'interactionId' => '1234567890'};
        
        ConnectorTimeLogController.createConnectorEventTimeLog(objCreate);         
        
        Map<String, Object> obj = new Map<String, Object>{
            'callTime'=> 1234567890, 
            'field' => 'softphone_it__Established_Time__c', 
            'interactionId' => '1234567890'};
    
        ConnectorTimeLogController.updateConnectorEventTimeLog(obj);
        
        Map<String, Object> obj2 = new Map<String, Object>{
            'callTime'=> 1234567890, 
            'field' => 'Released_Time__c', 
            'state' => 'answered', 
            'disposition' => 'disposition', 
            'interactionDuration' => 2,
            'totalAcdDuration' => 2,
            'totalIvrDuration' => 2,
            'dispositionDuration' => 2,
            'disposition' => 'disposition', 
            'interactionId' => '1234567890'};
        
        ConnectorTimeLogController.updateConnectorEventTimeLog(obj2);
    }

}