global with sharing class ConnectorEntityController {
    
    public ConnectorEntityController() { } 
    
    @RemoteAction
    global static Task createTask(Task task,String field, String value) {
        
        try{        
            List<Contact> contacts = Database.query('Select id,AccountId,Birthdate,Email,FirstName,LastName,Phone from Contact where ' + field + ' = \'' + value + '\'');
            System.debug('contacts found : ' + contacts);
            if ( contacts.size() == 1 ){
                task.WhoId = contacts.get(0).Id;
            } 
        } catch(Exception e){
            System.debug('Error in createTask ' + e);     
        }
        
        try{           
            Database.SaveResult sr =  Database.insert(task);
            System.debug('save result : ' + sr);   
            return task;
        } catch(Exception e){
            System.debug('Error in insert ' + e);
            
        }
        return null;
    }
    
    @RemoteAction
    global static List<Contact> findContactId(String field, String value) {
        
        try{        
            List<Contact> contacts = Database.query('Select id,name from Contact where ' + field + ' = \'' + value + '\'');
            System.debug('contacts found : ' + contacts);
            return contacts;
        } catch(Exception e){
            System.debug('Error in finding contact ' + e);     
        }
        return null;
    }
    
    @RemoteAction
    global static Map<String,List<sObject>> findRecords(String value) {
        Map<String,List<sObject>> result = new Map<String,List<sObject>>();
        try{        
            List<List<sObject>> records =[find : value IN ALL FIELDS RETURNING Lead (Id, Name,phone,email), Contact(id,name,phone,email,Account.Name)]; 
            System.debug('contacts found : ' + records);
            List<sObject> leads = records[0];
            List<sObject> contacts = records[1];
            result.put('contact',contacts);
            result.put('lead',leads);
            return result;
        } catch(Exception e){
            System.debug('Error in finding contact ' + e);     
        }
        return result;
    }
    
    @RemoteAction
    global static Case createCase(Case obj,String field, String value) {
        
        try{        
            List<Contact> contacts = Database.query('Select id,AccountId,Birthdate,Email,FirstName,LastName,Phone from Contact where ' + field + ' = \'' + value + '\'');
            System.debug('contacts found : ' + contacts);
            if ( contacts.size() == 1 ){
                obj.ContactId = contacts.get(0).Id;
            } 
        } catch(Exception e){
            System.debug('Error in finding contact ' + e);     
        }
        
        try{           
            Database.SaveResult sr =  Database.insert(obj);
            System.debug('save result : ' + sr);   
            return obj;
        } catch(Exception e){
            System.debug('Error in insert ' + e);
            
        }
        return null;
    }
    
    @RemoteAction
    global static SObject createSObject(SObject obj) {
        try{           
            Database.SaveResult sr =  Database.insert(obj);
            System.debug('save result : ' + sr);   
            return obj;
        } catch(Exception e){
            System.debug('Error in insert ' + e);
            
        }
        return null;
    }
    
    @RemoteAction
    global static String updateTask(String taskId,String contactId) {
        
        try{        
            List<Task> ts = [SELECT Id,softphone_it__IWS_Interaction_ID__c FROM Task WHERE Id = :taskId limit 1];
            System.debug('case found : ' + ts);
            if ( ts == null || ts.size() == 0 ){
                return null;
            }
            ts[0].WhoId = contactId;
            update ts[0];  
            return ts[0].softphone_it__IWS_Interaction_ID__c;
        } catch(Exception e){
            System.debug('Error in updateTask ' + e);     
        }
        
        return null;
    }
    
    @RemoteAction
    global static String updateCase(String caseId,String contactId) {
        
        try{        
            List<Case> cs = [SELECT Id,softphone_it__IWS_Interaction_ID__c FROM Case WHERE Id = :caseId limit 1];
            System.debug('case found : ' + cs);
            if ( cs == null || cs.size() == 0 ){
                return null;
            }
            cs[0].ContactId = contactId;
            update cs[0];  
            return cs[0].softphone_it__IWS_Interaction_ID__c;
        } catch(Exception e){
            System.debug('Error in updateCase ' + e);     
        }
        
        return null;
    }
    
    
    @RemoteAction
    global static void updateExternalRoutingBean(String id,String agentId){
        External_Routing_Bean__c lct = [SELECT id FROM External_Routing_Bean__c WHERE interaction_Id__c = :id];
        lct.Agent_Id__c  = agentId;
        update lct;     
    }
    
    @RemoteAction
    global static String ERCOmniUtilsPath {
        get {
            return GetResourceURL('softphoneerc','omniUtils');
        }
    }
    
    @RemoteAction
    global static String ERCsyncUtilsPath {
        get {
            return GetResourceURL(null,'syncUtils');
        }
    }
    
    
    public static String GetResourceURL(String namespace,String resourceName){
        
        List<StaticResource> resourceList= namespace != null ? 
            [SELECT Name, NamespacePrefix, SystemModStamp FROM StaticResource WHERE Name = :resourceName AND NamespacePrefix = :namespace] : 
        [SELECT Name, NamespacePrefix, SystemModStamp FROM StaticResource WHERE Name = :resourceName] ;
            if(resourceList.size() == 1){
                String nm = resourceList[0].NamespacePrefix;
                return '/resource/' + resourceList[0].SystemModStamp.getTime() + '/' + (nm != null && nm != '' ? nm + '__' : '') + resourceName; 
            }
        return ''; 
        
    }
    
}