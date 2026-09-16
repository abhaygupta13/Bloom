/***
Class       : CaseDocumentCreation
Author      : Smaartt
Description : 
TestClass   : CaseSubstatusUpdateHandlerTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.          V1.0             12/12/23           Initial Version 
****************************************************************************************************************/

public class CaseDocumentCreation {
   Public Static void DocumentCreation(Map<Id,Case> Clist){
       
      List<Document__c> Dolist = new List<Document__c>();
      set<String> caseRecordTypeName = new set<String>();
      set<String> caseType = new set<String>();
      
      list<Case> caselist = [select id,recordType.Name,Type from Case where Id=:Clist.keyset()];
      
       for(case ca : caselist){
           caseRecordTypeName.add(ca.recordType.Name);
           caseType.add(ca.type);
       }
        List<Document_Set_Up_Config__mdt> DcList = [SELECT Id, Sobject__c, Case_RecordType__c, MasterLabel, Sub_Type__c 
                FROM Document_Set_Up_Config__mdt 
                WHERE Sobject__c = 'Case' AND Case_RecordType__c=:caseRecordTypeName AND Sub_Type__c=:caseType ORDER BY MasterLabel];
       
       
        for (Case c : caselist) {
            
            for(Document_Set_Up_Config__mdt doc : DcList){
                if(doc.Case_RecordType__c == c.recordType.Name && doc.Sub_Type__c==c.type){
                    
                    Document__c DC = new Document__c();
                    DC.Case__c = c.id;
                    Dc.Document_Name__c = doc.MasterLabel;
                    Dolist.add(DC);
                    
                }
                
            }
            
        }
       
        if(Dolist.size()>0){
             insert Dolist;   
           
        }
        
        
        
    } 

}