global with sharing class ExternalRoutingChatTransfer {
   
    @InvocableMethod (label='er_chat_transfer')
    global static void externalRouting(List<String> ids){
        List<String> app = new List<String>();
        softphone_it.ConnectorOutboundSoftphoneLogs.insertLogWsRequest('INFO', 'er_chat_transfer', 'START', ids.toString(), '', '');
        for(String s : ids){
            app.add(s.substring(0, 15));
        }
        for(External_Routing_Bean__c t : [select id,Interaction_Id__c,Agent_Id__c from External_Routing_Bean__c WHERE PreChat_Id__c IN :app order by CreatedDate desc]){
            try{
                //LiveChatTranscript lct = [select Id,CreatedDate,softphoneerc__IWS_PreChat_Id__c,softphoneerc__IWS_Customer_Name__c,status from LiveChatTranscript WHERE id = :id order by CreatedDate desc limit 1];
                //External_Routing_Bean__c t = [select id,Interaction_Id__c,Agent_Id__c from External_Routing_Bean__c WHERE PreChat_Id__c = :lct.softphoneerc__IWS_PreChat_Id__c order by CreatedDate desc limit 1];
                //External_Routing_Bean__c t = [select id,Interaction_Id__c,Agent_Id__c from External_Routing_Bean__c WHERE PreChat_Id__c = :id order by CreatedDate desc limit 1];
                
                if ( t.Interaction_Id__c == null || t.Agent_Id__c == null ){
                    String log = 'cannot transfer missing parameters, agentId : ' + t.Agent_Id__c + ', interactionId : ' +  t.Interaction_Id__c;
                    softphone_it.ConnectorOutboundSoftphoneLogs.insertLogWsRequest('ERROR', 'er_chat_transfer', 'ERROR', ids.toString(), log, ''); 
                    return;
                }
                CalloutOutbound(t.Interaction_Id__c,t.Agent_Id__c);
            }catch(Exception e){
                softphone_it.ConnectorOutboundSoftphoneLogs.insertLogWsRequest('ERROR', 'er_chat_transfer', 'ERROR', 'id=' + t.id + ', ids='+ids.toString(), e.getMessage(), ''); 
            }
        }
    }

    @future (callout=true)
    public Static void CalloutOutbound(String id, String agentId){
        softphone_it__Connector_Settings__c COS = softphone_it__Connector_Settings__c.getOrgDefaults();
        String queueId = COS.softphone_it__GC_QUEUE_ID__c;
        Map<String, Object> params = new Map<String, Object>();
        params.put('queueId', queueId);
        String body = JSON.Serialize(params);
     	 if(!Test.isRunningTest()){
             try{
                 String path = 'conversations/chats/'+ id + '/participants/' + agentId + '/replace';
                 HttpResponse response = softphone_it.ConnectorCalloutGc.CalloutGC(body, path , 'POST');
                 softphone_it.ConnectorOutboundSoftphoneLogs.insertLogWsRequest('INFO', 'er_chat_transfer', 'POST', path, JSON.serialize(params), response.getBody());  
             }catch( Exception e){
                 softphone_it.ConnectorOutboundSoftphoneLogs.insertLogWsRequest('ERROR', 'er_chat_transfer', 'ERROR', 'id=' + id + ',agentId=' + agentId, e.getMessage(), '');            
             }	
        }
    }
}