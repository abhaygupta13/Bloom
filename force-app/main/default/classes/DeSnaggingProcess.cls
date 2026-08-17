/***
Class       : DeSnaggingProcess
Author      : Rajat Rastogi
Description : 
TestClass   : DeSnaggingProcessTest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.      V1.0             	 11/06/2024           Initial Version  
****************************************************************************************************************/ 

@RestResource(urlMapping='/DeSnagging/*')
global without sharing class DeSnaggingProcess {
    @HttpPost
    global static String deSnaggingReport(String base64Pdf, String fileName, String fileType, String inspector, String snagCount, String status, String report_type, String unitNumber) {
        try {
            DocumentService DocumentService = DocumentService.getInstance();
            HandoverService HandoverService = HandoverService.getInstance();
            UnitService UnitService = UnitService.getInstance();
            Id HOAgentId;
            List<Handover__c> handOverList;
            Handover__c handOver;
            // Remove debug statements before going to production - Moneeb
            
            if (String.isBlank(base64Pdf) || String.isBlank(fileName) || String.isBlank(fileType)) {
                return HandoverConstants.FILE_DATA_NOT_FOUND; //'File Data not found';
            }
            if (String.isBlank(status)) {
                return HandoverConstants.Please_Select_Status;
            }
            
            /********** START - Assignment of Inspector to HandOver *********/
            List<User> inspectorUser = new List<User>(); // HO Agent or HO Manager
            if (String.isBlank(inspector)) {
                inspector = System.Label.HO_Manager_Email;
            }
            
            inspectorUser = [SELECT Id FROM User WHERE Email = :inspector AND isActive = true LIMIT 1];
            System.debug('inspectorUser - ' + inspectorUser);
            if (inspectorUser.isEmpty()) {
                return HandoverConstants.INSPECTOR_NOT_FOUND; //'Inspector not found';
            }
            else{
                HOAgentId = inspectorUser[0].Id;
            }
            System.debug('HOAgentId - ' + HOAgentId);
            /********** END - Assignment of Inspector to HandOver *********/
            
            /********** START - Getting and updating unit for HandOver *********/
            if(String.isBlank(unitNumber)){
                return HandoverConstants.UNIT_CANNOT_BE_BLANK;
            }
            List<Unit__c> unitList = UnitService.getUnitsBySAPNo(unitNumber);
            if (unitList.isEmpty()) {
                return HandoverConstants.UNABLE_TO_FIND_UNIT; //'Unable to find Unit';
            }
            
            Unit__c unit = unitList[0];
            if (HOAgentId != null && unit.HO_Agent__c != HOAgentId) {
                unit.HO_Agent__c = HOAgentId;
                update unit;
            }
            /********** END - Getting and updating unit for HandOver *********/
            
            handOverList = HandoverService.getHandoverByUnitId(unit.Id);
            if(!handOverList.isEmpty()){
                //List<Document__c> existingQASnagDocList = [SELECT Id, Document_Name__c,ContentDocumentId__c FROM Document__c WHERE Document_Name__c =: HandoverConstants.HO_QA_Snagging_Report AND Handover__c =: handOverList[0].Id LIMIT 1];
                List<Document__c> existingQASnagDocList = DocumentService.getDocumentByHandoverIdAndName(handOverList[0].Id, HandoverConstants.HO_QA_Snagging_Report);
                if(!handOverList.isEmpty() && !existingQASnagDocList.isEmpty() && String.isBlank(existingQASnagDocList[0].ContentDocumentId__c) && 
                   status == HandoverConstants.Status_QA && report_type == HandoverConstants.SNAGGING){
                
                    CustomDocManageController.addFilesonRecordCreate(base64Pdf, fileName+fileType, existingQASnagDocList[0]);  // to upload QA snag report on that Handover
                    handOverList[0].Sub_Status__c = HandoverConstants.HANDOVER_STATUS_QA_Snagging_Completed;
                    /* if(Integer.valueOf(handOverList[0].Step__c) == 1 && handOverList[0].Sales_Order__c != null){
                        handOverList[0].Step__c = '2';
                    } */
                    update handOverList;
                    HandoverController.validateForNextReview(handOverList[0].Id);
                    return HandoverConstants.REPORT_UPLOADED_SUCCESSFULLY_ON_HANDOVER +'"'+ handOverList[0].Name+ '"}';
                }else if (!handOverList.isEmpty() && status == HandoverConstants.Status_QA && report_type == HandoverConstants.SNAGGING ) {
                    return HandoverConstants.HANDOVER_ALREADY_CREATED;
                }
            }
            
            Blob fileBody = EncodingUtil.base64Decode(base64Pdf);
            
            /********** START - Creation of Handover and uploading Snagging Report *********/
            if (handOverList.isEmpty()) {
                if (report_type == HandoverConstants.SNAGGING && String.isNotBlank(status) && status == HandoverConstants.Status_QA) {
                    handOver = new Handover__c(
                        Name = 'HO-' + unit.SAP_Unit_Number__c,
                        Sub_Status__c = HandoverConstants.HANDOVER_STATUS_QA_Snagging_Completed,
                        Is_Manual__c = HandoverConstants.NO,
                        OwnerId = HOAgentId,
                        HO_Agent_Assigned_User__c = HOAgentId,
                        Unit__c = unit.Id,
                        Step__c = '0'
                    );
                    HandoverService.insertHandovers(new List<Handover__c>{handOver});
                    System.debug('handOver - ' + handOver);
                    createDocumentPlaceHolderForHO(handOver);  // call method to create all placeholder at the time of Handover creation from custom metadata 
                    //List<Document__c> QASnagDocList = [SELECT Id, Document_Name__c FROM Document__c WHERE Document_Name__c =: HandoverConstants.HO_QA_Snagging_Report AND Handover__c =: handOver.Id LIMIT 1];
                    List<Document__c> QASnagDocList = DocumentService.getDocumentByHandoverIdAndName( handOver.Id, HandoverConstants.HO_QA_Snagging_Report);
                    if(!QASnagDocList.isEmpty()){
                        CustomDocManageController.addFilesonRecordCreate(base64Pdf, fileName+fileType, QASnagDocList[0]);  // to upload QA snag report on that Handover
                    }else{
                        // log an eeror log
                    }
                    //HandoverReviewNextStepController.validateForNextReview(handOver.Id);
                    return HandoverConstants.HANDOVER_CREATED_SUCCESSFULLY_FOR_THIS_UNIT  +'"'+ handOver.Name+ '"}'; //'Handover created successfully for this unit.';
                }
                return HandoverConstants.Please_Select_Snagging_Report; //'No Snag report.';
            } 
            
            /********** END - Creation of Handover and uploading Snagging Report *********/
            
            handOver = (handOverList != null && !handOverList.isEmpty()) ? handOverList[0] : null;
            // set the status QA Desnagging Completed
            if (report_type == HandoverConstants.DESNAGGING && String.isNotBlank(status) && status == HandoverConstants.Status_QA) {
              
                    //List<Document__c> QASnagDocList = [SELECT Id, Document_Name__c FROM Document__c WHERE Document_Name__c =:HandoverConstants.HO_QA_DeSnagging_Report AND Handover__c =: handOver.Id LIMIT 1];
                    List<Document__c> QASnagDocList = DocumentService.getDocumentByHandoverIdAndName(handOver.Id, HandoverConstants.HO_QA_DeSnagging_Report);
                   System.debug('QASnagDocList'+QASnagDocList);
                if(!QASnagDocList.isEmpty()){
                        CustomDocManageController.addFilesonRecordCreate(base64Pdf, fileName+fileType, QASnagDocList[0]);  //  upload QA desnag report on that Handover
                        handOver.Sub_Status__c = HandoverConstants.HANDOVER_STATUS_QA_DESnagging_Completed; 
                        //update handOver;
                        /* if(Integer.valueOf(handOver.Step__c) == 2 && handOver.Sales_Order__c != null){
                            handOver.Step__c = '3';
                        } */
                        HandoverService.updateHandovers(new List<Handover__c>{handOver});
                        HandoverController.validateForNextReview(handOver.Id);
                        return HandoverConstants.REPORT_UPLOADED_SUCCESSFULLY_ON_HANDOVER  +'"'+ handOver.Name+ '"}';
                    }else{
                        //log an error
                    }
                
            }
            // set the status CHO Snagging Completed
            else if (report_type == HandoverConstants.SNAGGING && String.isNotBlank(status) && status == HandoverConstants.Status_CHO) {
               
                    //List<Document__c> QASnagDocList = [SELECT Id, Document_Name__c,ContentDocumentId__c FROM Document__c WHERE Document_Name__c =:HandoverConstants.HO_CHO_Snagging_Report AND Handover__c =: handOver.Id LIMIT 1];
                    List<Document__c> QASnagDocList = DocumentService.getDocumentByHandoverIdAndName(handOver.Id, HandoverConstants.HO_CHO_Snagging_Report);
                    if(!QASnagDocList.isEmpty()){
                        CustomDocManageController.addFilesonRecordCreate(base64Pdf, fileName+fileType, QASnagDocList[0]);  //  upload CHO snag report on that Handover
                         handOver.Sub_Status__c = HandoverConstants.Handover_Sub_Status_CHO_SNAGGING_COMPLETED;
                    	//update handOver;
                        HandoverService.updateHandovers(new List<Handover__c>{handOver});
                        return HandoverConstants.REPORT_UPLOADED_SUCCESSFULLY_ON_HANDOVER  +'"'+handOver.Name+ '"}';
                    }else{
                        //log an error
                    }
                
            } 
            // set the status CHO DeSnagging Completed
            else if (report_type == HandoverConstants.DESNAGGING && String.isNotBlank(status) && status == HandoverConstants.Status_CHO) {
               
                   // List<Document__c> QASnagDocList = [SELECT Id, Document_Name__c FROM Document__c WHERE Document_Name__c =:HandoverConstants.HO_CHO_DeSnagging_Report AND Handover__c =: handOver.Id LIMIT 1];
                   List<Document__c> QASnagDocList = DocumentService.getDocumentByHandoverIdAndName(handOver.Id, HandoverConstants.HO_CHO_DeSnagging_Report);
                    if(!QASnagDocList.isEmpty()){
                        CustomDocManageController.addFilesonRecordCreate(base64Pdf, fileName+fileType, QASnagDocList[0]);  //  upload CHO De snag report on that Handover
                        handOver.Sub_Status__c = HandoverConstants.Handover_Sub_Status_CHO_DE_SNAGGING_COMPLETED; 
                    	//update handOver;
                        HandoverService.updateHandovers(new List<Handover__c>{handOver});
                        return HandoverConstants.REPORT_UPLOADED_SUCCESSFULLY_ON_HANDOVER  +'"'+ handOver.Name+ '"}';
                    }else{
                        //log an error
                    }
                
            }
            
            return HandoverConstants.DOCUMENT_PLACEHOLDER_NOT_FOUND;
            
        } catch (Exception ex) {
            ErrorLogHandler.logError('DeSnaggingProcess', 'deSnaggingReport', ex, '');
            return ex.getMessage();
        }
    }
    
    public static void createDocumentPlaceHolderForHO(Handover__c handOverObj){
        // create Document placeholder for all doc & report
        try{
            DocumentService DocumentService = DocumentService.getInstance();
            MetadataService handoverMetadataService = MetadataService.getInstance();
            List<Document_Set_Up_Config__mdt> documentList = handoverMetadataService.getDocumentSetupConfigs(HandoverConstants.HANDOVER_SOBJECT);
            List<Document__c> docListForHandover = new List<Document__c>();
            for(Document_Set_Up_Config__mdt doc : documentList){
                Document__c bccDoc = new Document__c();
                bccDoc.Handover__c = handOverObj.Id;
                bccDoc.Document_Name__c = doc.MasterLabel;
                docListForHandover.add(bccDoc);
            }
            if(!docListForHandover.isEmpty())
                //insert docListForHandover;
                DocumentService.insertDocuments(docListForHandover);
            
        }catch(Exception ex){
            ErrorLogHandler.logError('DeSnaggingProcess','createDocumentPlaceHolderForHO',ex,'');
        }
    }
   
}