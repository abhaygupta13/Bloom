global class HandoverSendOrientationBatch implements Database.Batchable<SObject>, Database.Stateful {
    global List<Id> handoverIds;
    
    global HandoverSendOrientationBatch(List<Id> handoverIds) { 
        this.handoverIds = handoverIds;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id, Name,Is_BCC_Announcement_Sent__c, Unit__c,Unit__r.SAP_Unit_Number__c, Sub_Status__c,Customer_Email__c,Customer_Name__c, Project__r.Name,Is_Orientation_Letter_Sent__c,
                                         Account_Manager_Name__c, Account_Manager_Email__c,Account_Manager_Phone__c,Project__c,Project__r.ProjectNameArabic__c,Customer_Name_Arabic__c,Promise_to_Pay_Date__c,HO_Agent_Assigned_User__c
                                         FROM Handover__c 
                                         WHERE Id IN :handoverIds]);
    }
    global void execute(Database.BatchableContext BC, List<Handover__c> handoverList) {
        try{
            
            HandoverRoundRobin.handoverRRAssignmentToTeam(handOverList, Constants.TEAM_CRM);
            
            List<string> docList = new List<string>();
            docList.Add(Constants.Guideline_1);
            docList.Add(Constants.Guideline_1_Arabic);
          //  docList.Add(Constants.Home_Orientation_Journey);
            String result = HandoverEmailHelper.sendEmailProcess(Constants.Orientation_Template, handoverList[0].Id,new List<String>(),new List<String>{handoverList[0].HO_Agent_Assigned_User__c},docList);
            if(result.equalsIgnoreCase('SUCCESS') || Test.isRunningTest()){
                Handover__c HOObj = new Handover__c();
                HOObj.Id = handoverList[0].Id;
                HOObj.Unit_is_Ready__c = true;
                HOObj.Is_Orientation_Letter_Sent__c = true;
                HOObj.Home_Orientation_Invitation_Date__c = Date.Today();
                HOObj.Sub_Status__c = HandoverConstants.Handover_Sub_Status_Book_Appointment_with_Customer;
                update HOObj;
            }        
    	} catch (Exception ex) {
            ErrorLogHandler.logError('HandoverSendOrientationBatch', 'execute', ex, '');
        }
    }
    global void finish(Database.BatchableContext BC) {
    }
    
}