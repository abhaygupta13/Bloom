global class BCCAnnouncementEmailBatch implements Database.Batchable<SObject>, Database.Stateful {
    global List<Id> unitIds;
    global Boolean isSuccessfullySent = false;
    
    global BCCAnnouncementEmailBatch(List<Id> unitIds) {
        this.unitIds = unitIds;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id, Name,Is_BCC_Announcement_Sent__c, Unit__c,Unit__r.SAP_Unit_Number__c, Sub_Status__c,Customer_Email__c,CustomerEmail__c,Customer_Name__c, Project__r.Name,
                                         Account_Manager_Name__c, Account_Manager_Email__c,Account_Manager_Phone__c,Project__c,Project__r.ProjectNameArabic__c,Customer_Name_Arabic__c,Promise_to_Pay_Date__c
                                         FROM Handover__c 
                                         WHERE Unit__c IN :unitIds]);
    }
    
    global void execute(Database.BatchableContext BC, List<Handover__c> handoverList) {
        system.debug('handoverList'+handoverList);
        try {
            if (!handoverList.isEmpty()) {
                List<string> docList = new List<string>();
                docList.Add(Constants.HO_SOA);
                docList.Add(Constants.BCC_DOCUMENT);
                String result = HandoverEmailHelper.sendEmailProcess(Constants.BCCAnnouncementEmailTemplate, handoverList[0].Id,new List<String>(),new List<String>(),docList);
                if(result.equalsIgnoreCase('SUCCESS')){
                    Handover__c HOObj = new Handover__c();
                    HOObj.Id = handoverList[0].Id;
                    HOObj.Is_BCC_Announcement_Sent__c = true;
                    //HOObj.Sub_Status__c = Constants.Handover_Sub_Status_Bcc_Sent_To_Customer;
                    update HOObj;
                }else{
                    
                }   
            }
            
        } catch (Exception ex) {
            System.debug('Error: ' + ex.getMessage() + ex.getMessage());
            System.debug('Stack Trace: ' + ex.getStackTraceString());
            ErrorLogHandler.logError('BCCAnnouncementEmailBatch', 'execute', ex, '');
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        // Any post-processing can be done here
    }
    
    public static void method(){
        integer x = 1;
        integer y=2;
        integer z=3;
    }
}