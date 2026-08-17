global  class HandoverBCCAndOrientationEmailBatch implements Database.Batchable<SObject> {
    global List<Id> recordIds;
    global String batchType;
    
    global HandoverBCCAndOrientationEmailBatch(List<Id> recordIds, String batchType) {
        this.recordIds = recordIds;
        this.batchType = batchType;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        if (batchType == HandoverConstants.BCC) {
            return Database.getQueryLocator([SELECT Id, Name,Is_BCC_Announcement_Sent__c,Is_Notice_of_Completion_Sent__c,Unit__c,Unit__r.SAP_Unit_Number__c, Sub_Status__c,Customer_Email__c,CustomerEmail__c,Customer_Name__c, Project__r.Name,
                                             Account_Manager_Name__c, Account_Manager_Email__c,Account_Manager_Phone__c,Project__c,Project__r.ProjectNameArabic__c,Customer_Name_Arabic__c,Promise_to_Pay_Date__c
                                             FROM Handover__c 
                                             WHERE Unit__c IN :recordIds AND Is_BCC_Announcement_Sent__c=false]);
        } else if (batchType == HandoverConstants.NOC) {
            return Database.getQueryLocator([SELECT Id, Name,Is_BCC_Announcement_Sent__c,Is_Notice_of_Completion_Sent__c, Unit__c,Unit__r.SAP_Unit_Number__c, Sub_Status__c,Customer_Email__c,CustomerEmail__c,Customer_Name__c, Project__r.Name,Is_Orientation_Letter_Sent__c,
                                             Account_Manager_Name__c, Account_Manager_Email__c,Account_Manager_Phone__c,Project__c,Project__r.ProjectNameArabic__c,Customer_Name_Arabic__c,Promise_to_Pay_Date__c,HO_Agent_Assigned_User__c
                                             FROM Handover__c 
                                             WHERE Id IN :recordIds AND Is_Notice_of_Completion_Sent__c = false]);
        } else if (batchType == HandoverConstants.Orientation) {
            return Database.getQueryLocator([SELECT Id, Name,Is_BCC_Announcement_Sent__c,Is_Notice_of_Completion_Sent__c, Unit__c,Unit__r.SAP_Unit_Number__c, Sub_Status__c,Customer_Email__c,CustomerEmail__c,Customer_Name__c, Project__r.Name,Is_Orientation_Letter_Sent__c,
                                             Account_Manager_Name__c, Account_Manager_Email__c,Account_Manager_Phone__c,Project__c,Project__r.ProjectNameArabic__c,Customer_Name_Arabic__c,Promise_to_Pay_Date__c,HO_Agent_Assigned_User__c
                                             FROM Handover__c 
                                             WHERE Id IN :recordIds AND Is_Orientation_Letter_Sent__c=false]);
        }
        return null;
    }
    
    global void execute(Database.BatchableContext BC, List<Handover__c> handoverList) {
        HandoverService HandoverService = HandoverService.getInstance();
        system.debug('handoverList: ' + handoverList);
        if (!handoverList.isEmpty()) {
            List<string> docList = new List<string>();
            if (batchType == HandoverConstants.BCC) {
                 List<Handover__c> handoversToUpdate = new List<Handover__c>();  
                Set<id>BccHoids = new set<id>();
                for (Handover__c ho : handoverList) {
                 BccHoids.add(ho.Unit__c);
            }

        List<Handover__c> toEmail = [SELECT Id, Name,Is_BCC_Announcement_Sent__c,Is_Notice_of_Completion_Sent__c,Unit__c,Unit__r.SAP_Unit_Number__c, Sub_Status__c,Customer_Email__c,CustomerEmail__c,Customer_Name__c, Project__r.Name,
                                             Account_Manager_Name__c, Account_Manager_Email__c,Account_Manager_Phone__c,Project__c,Project__r.ProjectNameArabic__c,Customer_Name_Arabic__c,Promise_to_Pay_Date__c
                                             FROM Handover__c WHERE Unit__c IN :BccHoids AND Is_BCC_Announcement_Sent__c=false FOR UPDATE  ];
                
              
                if (!toEmail.isEmpty()) {
                    docList.Add(HandoverConstants.HO_SOA);
                    Messaging.SendEmailResult[] results = HandoverEmailHelper.sendEmails(HandoverConstants.BCCAnnouncementEmailTemplate, toEmail,new List<String>(),new List<String>(),docList);
                    
                    for (Integer i = 0; i < results.size(); i++) {
                        if (results[i].isSuccess()) {
                            Handover__c hoObj = new Handover__c();
                            hoObj.Id = toEmail[i].Id;
                            hoObj.Is_BCC_Announcement_Sent__c = true;
                            handoversToUpdate.add(hoObj);
                        }
                    }
                }
                if (!handoversToUpdate.isEmpty()) {
                    //update handoversToUpdate;
                    HandoverService.updateHandovers(handoversToUpdate);
                }
                System.debug('batchType'+batchType);
            } else if (batchType == HandoverConstants.NOC) {
                List<Handover__c> handoversToUpdate = new List<Handover__c>();  
                System.debug('batchType'+batchType);
                docList.Add(HandoverConstants.HO_SOA);
                docList.Add(HandoverConstants.HO_CHO_DeSnagging_Report);
                System.debug('docList'+docList);
               Set<id>nocHoids = new set<id>();
                for (Handover__c ho : handoverList) {
                 nocHoids.add(ho.Id);
            }
                System.debug('nocHoids'+nocHoids);
           List<Handover__c >toEmail=[SELECT Id, Name,Is_BCC_Announcement_Sent__c,Is_Notice_of_Completion_Sent__c, Unit__c,Unit__r.SAP_Unit_Number__c, Sub_Status__c,Customer_Email__c,CustomerEmail__c,Customer_Name__c, Project__r.Name,Is_Orientation_Letter_Sent__c,
                                             Account_Manager_Name__c, Account_Manager_Email__c,Account_Manager_Phone__c,Project__c,Project__r.ProjectNameArabic__c,Customer_Name_Arabic__c,Promise_to_Pay_Date__c,HO_Agent_Assigned_User__c
                                             FROM Handover__c 
                                             WHERE Id IN :nocHoids AND Is_Notice_of_Completion_Sent__c = false FOR UPDATE];
                System.debug('toEmail'+toEmail);
               
                if (!toEmail.isEmpty()) {
                    Messaging.SendEmailResult[] results = HandoverEmailHelper.sendNOCEmails(HandoverConstants.Notice_of_Completion_Template, toEmail,new List<String>(),new List<String>(),docList);
                    System.debug('results'+results);
                    
                    
                    for (Integer i = 0; i < results.size(); i++) {
                        if (results[i] .isSuccess()) {
                            Handover__c hoObj = new Handover__c();
                            hoObj.Id = toEmail[i].Id;
                            HOObj.Is_Notice_of_Completion_Sent__c = true;
                            HOObj.Sub_Status__c = HandoverConstants.Handover_Sub_Status_Notice_of_Completion_Sent;
                            HOObj.Notice_of_Completion_Date__c = Date.Today();
                            HOObj.NOC_Date__c = Date.today().addDays(30);
                            handoversToUpdate.add(hoObj);
                        }
                    }
                }
                System.debug('handoversToUpdate'+handoversToUpdate);
                if (!handoversToUpdate.isEmpty()) {
                    
                    HandoverService.updateHandovers(handoversToUpdate);
                }
            } else if (batchType == 'Orientation') {
                List<Handover__c> toEmail = new List<Handover__c>();
                 Set<id>orientationHoids = new set<id>();
                List<Handover__c> handoversToUpdate = new List<Handover__c>();
                for (Handover__c ho : handoverList) {
                    if (ho.Is_Orientation_Letter_Sent__c == false) {
                      //  HandoverRoundRobin.handoverRRAssignmentToTeam(
                       //     new List<Handover__c>{ho}, HandoverConstants.TEAM_CRM
                      //  );
                        orientationHoids.add(ho.id);
                    }
                }
                toEmail = [SELECT Id, Name,Is_BCC_Announcement_Sent__c,Is_Notice_of_Completion_Sent__c, Unit__c,Unit__r.SAP_Unit_Number__c, Sub_Status__c,Customer_Email__c,CustomerEmail__c,Customer_Name__c, Project__r.Name,Is_Orientation_Letter_Sent__c,
                                             Account_Manager_Name__c, Account_Manager_Email__c,Account_Manager_Phone__c,Project__c,Project__r.ProjectNameArabic__c,Customer_Name_Arabic__c,Promise_to_Pay_Date__c,HO_Agent_Assigned_User__c
                                             FROM Handover__c 
                                             WHERE Id IN :orientationHoids AND Is_Orientation_Letter_Sent__c=false FOR UPDATE];
                
                if (!toEmail.isEmpty()) {
                    docList.Add(HandoverConstants.Guideline_1);
                    docList.Add(HandoverConstants.Guideline_1_Arabic);
                    //docList.Add(HandoverConstants.Home_Orientation_Journey);
                    for (Handover__c ho : toEmail) {
                        String result = HandoverEmailHelper.sendEmailProcess(Constants.Orientation_Template,ho.Id,new List<String>(),new List<String>{ho.HO_Agent_Assigned_User__c},docList);
                        system.debug('result----->'+result);
                        
                        if(result.equalsIgnoreCase('SUCCESS')){
                            
                            Handover__c HOObj = new Handover__c();
                            HOObj.Id = ho.Id;
                            HOObj.Unit_is_Ready__c = true;
                            HOObj.Is_Orientation_Letter_Sent__c = true;
                            HOObj.Home_Orientation_Invitation_Date__c = Date.Today();
                            HOObj.HomeOrientationInvitationDate__c = Date.today().addDays(14);
                            HOObj.Sub_Status__c = HandoverConstants.Handover_Sub_Status_Home_Orientation_Sent;
                            handoversToUpdate.add(HOObj);
                        }
                    }
                    if (!handoversToUpdate.isEmpty()) {
                        // update handoversToUpdate;
                        HandoverService.updateHandovers(handoversToUpdate);
                    }
                }
            }
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        // Any post-processing can be done here
    }
    
   
    

}