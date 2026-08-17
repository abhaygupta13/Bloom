global with sharing class ExternalRoutingChatAbandoned {
    public ExternalRoutingChatAbandoned() {}  

    @InvocableMethod (label='er_chat_abandoned')
    global static void externalRouting(List<String> ids){  
        List<String> app = new List<String>();
        softphone_it.ConnectorOutboundSoftphoneLogs.insertLogWsRequest('INFO', 'er_chat_abandoned', 'START', ids.toString(), '', '');
        for(String s : ids){
            app.add(s.substring(0, 15));
        }
        for(External_Routing_Bean__c erb : [SELECT id,Interaction_Id__c FROM External_Routing_Bean__c WHERE PreChat_Id__c IN :app order by CreatedDate desc]){
            try{
                CalloutOutbound(erb.Interaction_Id__c);
            }catch(Exception e){
                softphone_it.ConnectorOutboundSoftphoneLogs.insertLogWsRequest('ERROR', 'er_chat_abandoned', 'ERROR', 'exception in er_chat_abandoned, id=' + erb.id + ', ids=' + ids.toString(), e.getMessage(), ''); 
            }
        }
    }
    
   @future (callout=true)
    public Static void CalloutOutbound(String id){
        Map<String, Object> params = new Map<String, Object>();
        params.put('state', 'disconnected');
        String body = JSON.Serialize(params);
		
        if(!Test.isRunningTest()){
        	HttpResponse response = softphone_it.ConnectorCalloutGc.CalloutGC(body,  'conversations/chats/' + id, 'PATCH'); 
            softphone_it.ConnectorOutboundSoftphoneLogs.insertLogWsRequest('INFO', 'er_chat_abandoned', 'PATCH', 'conversations/chats/' + id, JSON.serialize(params), response.getBody());        
        }
    }  
}