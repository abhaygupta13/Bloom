@isTest
public class ExternalRouting_Test {
    
    static testMethod void syncutilTest() {
        Object o;
        SyncUtil su = new SyncUtil(o);
        SyncUtil.isSyncEnable();
    } 
    
	static testMethod void testObject() {
        Object o;
        ExternalRoutingObject cptgc = new ExternalRoutingObject(o);
        
        List<String> objId = new List<String>();
        objId.add('123123');
        Test.startTest();
        ExternalRoutingObject.externalRouting(objId); 
        
        Test.stopTest();  

    }

    static testMethod void testChat() {
        ExternalRoutingChat erc = new ExternalRoutingChat();


        Task ts = new Task(Subject='test');
        insert ts;
        List<String> l = new List<String>();
        ExternalRoutingChat.externalRouting(l); 
        l.add(ts.Id);
        HTTPResponse res = new HTTPResponse();
                res.setBody('{}');
                res.setStatusCode(200); 
         
        Test.startTest();
        ExternalRoutingChat.externalRouting(l); 
        
        ExternalRoutingChat.createExternalRoutingBeanFromResponse(res, '123123', new Map<String,Object>());
        Test.stopTest(); 
    }
    
   static testMethod void testAbandoned() {
       ExternalRoutingChatAbandoned erc = new ExternalRoutingChatAbandoned();
       Task t= new task(Subject='test',  softphone_it__IWS_Interaction_ID__c = null);
       insert t;
       List<String> ids = new List<String>{'1234567890abcdefgi'};
           Test.startTest();
       ExternalRoutingChatAbandoned.CalloutOutbound('1234567890abcde');
       Test.stopTest();  
       
       External_Routing_Bean__c erb = new External_Routing_Bean__c();
       erb.Interaction_Id__c = 'abc123';
       erb.PreChat_Id__c = '1234567890abcdefgi';
       insert erb;
       ExternalRoutingChatAbandoned.externalRouting(ids);
    }
    
   
    
     static testMethod void testTransfer() {
        ExternalRoutingChatTransfer erc = new ExternalRoutingChatTransfer();
        External_Routing_Bean__c erb = new External_Routing_Bean__c(Interaction_Id__c = '123',Agent_Id__c='456',PreChat_Id__c='1234567890abcdefgi');
        insert erb;
        Task t= new task(Subject='test',  softphone_it__IWS_Interaction_ID__c = null);
        insert t;
        List<String> ids = new List<String>{'1234567890abcdefgi'};
            
        Test.startTest();    
        ExternalRoutingChatTransfer.CalloutOutbound('1234567890abcde', 'customerName');
        Test.stopTest(); 
        HTTPResponse res = new HTTPResponse();
                res.setBody('{}');
                res.setStatusCode(200);
        ExternalRoutingChatTransfer.externalRouting (ids);
         
       	External_Routing_Bean__c erbb = new External_Routing_Bean__c(Interaction_Id__c = null,Agent_Id__c=null ,PreChat_Id__c='1234567890abcdefgi');
        insert erbb;
        ExternalRoutingChatTransfer.externalRouting (ids);
    }
}