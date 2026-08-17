global with sharing class ExternalRoutingChat {
    public ExternalRoutingChat() {}  

    @InvocableMethod (label='er_chat')
    global static void externalRouting(List<String> id){ 
        softphone_it.ConnectorOutboundSoftphoneLogs.insertLogWsRequest('INFO', 'er_chat', 'START', id.toString(), '', '');
        for(String chatId : id){      
            try{ 
                CalloutOutbound(chatId, '');
            }catch(Exception e){
                System.debug('ERRORE: ' + e.getMessage());
                softphone_it.ConnectorOutboundSoftphoneLogs.insertLogWsRequest('ERROR', 'er_chat', 'ERROR', id.toString(), e.getMessage(), '');
            }
        }
    }
    
   @future (callout=true)
    public Static void CalloutOutbound(String liveChatId, String customerName){
        softphone_it__Connector_Settings__c COS = softphone_it__Connector_Settings__c.getOrgDefaults();
        String queueId = COS.softphone_it__GC_QUEUE_ID__c;
        Map<String, Object> params = new Map<String, Object>();
        params.put('queueId', queueId);
        params.put('provider', 'Salesforce');
        params.put('customerName', customerName);
        Map<String, String> attributes = new Map<String, String>{'livechat_id'=> liveChatId};
        params.put('attributes', attributes);
        String body = JSON.Serialize(params);
        
        if(!Test.isRunningTest()){
            HttpResponse response = softphone_it.ConnectorCalloutGc.CalloutGC(body,  'conversations/chats', 'POST'); 
            createExternalRoutingBeanFromResponse(response, liveChatId, params);
        }
    }
    
    public static void createExternalRoutingBeanFromResponse(HTTPResponse response, String liveChatId, Map<String, Object> params){
        
        if (response.getStatusCode() == 200) {
            Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());              
           
            External_Routing_Bean__c app = new External_Routing_Bean__c();
            app.Name = 'ExternalFlowRouting';
            app.Interaction_Id__c = (String)results.get('id');
            app.PreChat_Id__c = liveChatId;
            insert app;       
        } 
       // softphone_it.ConnectorOutboundSoftphoneLogs.insertLog('er_chat','',response.getBody(),'INFO',String.valueOf(params));
        
       softphone_it.ConnectorOutboundSoftphoneLogs.insertLogWsRequest('INFO', 'er_chat', 'POST', 'conversations/chats', JSON.serialize(params), response.getBody());

    }
}