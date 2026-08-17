@isTest
private class ConnectorEntityController_Test {
    
    static testMethod void myUnitTest() {
        ConnectorEntityController cec = new ConnectorEntityController();
        
        Contact con = new Contact();
        con.FirstName ='abc';
        con.LastName ='xyz';
        con.Email ='abc@it.it';
        Insert con;
        
        Task a = new Task();
        a.Subject='test';
        a.CallType = 'Inbound';
        ConnectorEntityController.createTask(a, 'Email', 'abc@it.it'); 
        
        Case c = new Case();
        c.Subject ='test';
        ConnectorEntityController.createCase(c, 'Email', 'abc@it.it');  
        
        Case c1 = new Case();
        c1.Subject ='test';
        ConnectorEntityController.createSObject(c1);  
        
        ConnectorEntityController.updateCase(c1.Id, '0033i00002Jj8tkAAB');
        ConnectorEntityController.updateCase('5003i00000Gp2A8AAK', '0033i00002Jj8tkAAB');
        ConnectorEntityController.updateTask(a.Id, '0033i00002Jj8tkAAB');
        
        String ou = ConnectorEntityController.ERCOmniUtilsPath;
        String su = ConnectorEntityController.ERCsyncUtilsPath;
        
        Contact testC = new Contact();
        testC.LastName = 'TestC';
        testC.Phone = '123';
        insert testC;
        Map<String,List<sObject>> mapObj = ConnectorEntityController.findRecords(testC.Id);
        List<Contact> fc = ConnectorEntityController.findContactId('Phone', '123');
        
        External_Routing_Bean__c erb = new External_Routing_Bean__c(Interaction_Id__c = '123',Agent_Id__c='456',PreChat_Id__c='1234567890abcdefgi');
        insert erb;
        ConnectorEntityController.updateExternalRoutingBean('123', '789');
        
    }
}