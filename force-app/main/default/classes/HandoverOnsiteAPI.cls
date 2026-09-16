/***
Class       : HandoverOnsiteAPI
Author      : Antriksh 
Description : 
TestClass   : HandoverOnsiteAPITest
----------------------------------------------------------------------------------------------------------------
-- History --
----------------------------------------------------------------------------------------------------------------
Sr.No.  version              Date                Details
1.      V1.0             	 30/03/2026           Initial Version  
****************************************************************************************************************/ 

@RestResource(urlMapping='/DeSnaggingProcess/*')
global without sharing class HandoverOnsiteAPI {
    
    private static final String HANDOVER_CREATED_SUCCESSFULLY_FOR_THIS_UNIT = '{"message": "Handover created successfully for this unit.", "statusCode": 200, "statusType": "Success", "HandoverName": ';
    private static final String REPORT_UPLOADED_SUCCESSFULLY_ON_HANDOVER = '{"message": "Report uploaded successfully on Handover OR Document Already Uploaded", "statusCode": 200, "statusType": "Success", "HandoverName": ';
    private static final String PLEASE_SELECT_SNAGGING_REPORT = 'Please select report type snagging and Status is QA';
    private static final String FILE_DATA_NOT_FOUND = '{"message": "File Data not found", "statusCode": "401", "statusType": "Error"}';
    private static final String HANDOVER_ALREADY_CREATED = '{"message": "Handover already created/updated for this unit. ", "statusCode": "401", "statusType": "Error"}';
    private static final String INSPECTOR_NOT_FOUND = '{"message": "Inspector not found in the system", "statusCode": "401", "statusType": "Error"}';
    private static final String UNABLE_TO_FIND_UNIT = '{"message": "Unable to find Unit in the system", "statusCode": "401", "statusType": "Error"}';
    private static final String UNIT_CANNOT_BE_BLANK = '{"message": "Unit cannot be blank", "statusCode": "401", "statusType": "Error"}';
    private static final String DOCUMENT_PLACEHOLDER_NOT_FOUND = '{"message": "No Document placeholder found on Handover OR Document Already Uploaded", "statusCode": "401", "statusType": "Error"}';
    private static String Please_Select_Status =  '{"message": "Please Select Status", "statusCode": "401", "statusType": "Error"}';
    
    private static final String HO_QA_SNAGGING_REPORT = 'QA Snagging Report';
    private static final String HO_QA_DESNAGGING_REPORT = 'QA Desnagging Report';
    private static final String HO_CHO_SNAGGING_REPORT = 'CHO Snagging Report';
    private static final String HO_CHO_DESNAGGING_REPORT = 'CHO Desnagging Report';
    private static final String HANDOVER_STATUS_QA_SNAGGING = 'QA Snagging';
    private static final String HANDOVER_STATUS_QA_DESNAGGING = 'QA De-Snagging';
    private static final String HANDOVER_SUB_STATUS_CHO_SNAGGING = 'CHO Snagging';
    private static final String HANDOVER_SUB_STATUS_CHO_DE_SNAGGING = 'CHO De-Snagging';
    private static final String Handover_Sub_Status_Upload_SOA = 'Upload SOA';
    private static final String Handover_Sub_Status_Settlement_Follow_up = 'Settlement Follow up';
    private static final String DE_SNAGGING_REPORT = 'deSnaggingReport';
    private static final String STATUS_CHO = 'CHO';
    private static final String STATUS_QA = 'QA';
    private static final String HANDOVER = 'Handover';
    private static final String SNAGGING = 'snagging';
    private static final String DESNAGGING = 'desnagging';
    private static final String HANDOVER_SOBJECT = 'Handover__c';
    private static final String NO = 'No';
    
    private static final string MDT_HO_Manager_Email { get { return 'HO_Manager_Email'; } }
    
    
    @HttpPost
    global static String deSnaggingReport(String base64Pdf, String fileName, String fileType, String inspector, String snagCount, String status, String report_type, String unitNumber) {
        try {
            DocumentService objDocumentService = DocumentService.getInstance();
            HandoverService objHandoverService = HandoverService.getInstance();
            MetadataService handoverMetadataService = MetadataService.getInstance();
            UnitService objUnitService = UnitService.getInstance();
            UserService objUserService = UserService.getInstance();
            
            
            Blob fileBody = EncodingUtil.base64Decode(base64Pdf);
            Id HOAgentId;
            List<Handover__c> handOverList;
            Handover__c handOver;
            Boolean handoverRecordCreated = false;
            
            if (String.isBlank(base64Pdf) || String.isBlank(fileName) || String.isBlank(fileType)) return FILE_DATA_NOT_FOUND;
            if (String.isBlank(status)) return 'Please Select Status';
            
            if (String.isBlank(unitNumber)) return UNIT_CANNOT_BE_BLANK;
            
            
            /********** START - Assignment of Inspector to HandOver *********/
            List<User> inspectorUser = new List<User>(); // HO Agent or HO Manager
            String hoMangerEmail = String.isBlank(inspector) ? (String)handoverMetadataService.getAppSettingTextValue('HO_Manager_Email') : inspector;
            
            inspectorUser = objUserService.getUsersByEmail(hoMangerEmail);
            
            if (inspectorUser.isEmpty()) {
                return INSPECTOR_NOT_FOUND; //'Inspector not found';
            }
            else{
                HOAgentId = inspectorUser[0].Id;
            }
            
            /********** END - Assignment of Inspector to HandOver *********/
            
            /********** START - Getting and updating unit for HandOver *********/
            if(String.isBlank(unitNumber)){
                return UNIT_CANNOT_BE_BLANK;
            }
            List<Unit__c> unitList = objUnitService.getUnitsBySAPNo(unitNumber);
            if (unitList.isEmpty()) {
                return UNABLE_TO_FIND_UNIT; //'Unable to find Unit';
            }
            
            Unit__c unit = unitList[0];
            if (HOAgentId != null && unit.HO_Agent__c != HOAgentId) {
                unit.HO_Agent__c = HOAgentId;
                objUnitService.updateUnitWithoutTrigger(unit);
            }
            
            handOverList = objHandoverService.getHandoverByUnitId(unit.Id);
            
            
            /********** START - Creation of Handover and uploading Snagging Report *********/
            if(handOverList.isEmpty()) {
                if (report_type == SNAGGING && String.isNotBlank(status) && status == Status_QA) {
                    handOver = new Handover__c(
                        Name = 'HO-' + unit.SAP_Unit_Number__c,
                        Sub_Status__c = HANDOVER_STATUS_QA_DESNAGGING,
                        Is_Manual__c = NO,
                        OwnerId = HOAgentId,
                        HO_Agent_Assigned_User__c = HOAgentId,
                        Unit__c = unit.Id,
                        Status__c = 'In Progress'
                    );
                    handOver = objHandoverService.insertHandover(handOver);
                    handoverRecordCreated = true;
                    
                    List<Document__c> QASnagDocList = objDocumentService.getDocumentBasedonType(handOver.Id, HO_QA_Snagging_Report);
                    if(!QASnagDocList.isEmpty()){
                        objDocumentService.addFile(base64Pdf, fileName+fileType, QASnagDocList[0].Id);  // to upload QA snag report on that Handover
                        
                        
                    }
                    return HANDOVER_CREATED_SUCCESSFULLY_FOR_THIS_UNIT  +'"'+ handOver.Name+ '"}'; //'Handover created successfully for this unit.';
                }
                return Please_Select_Snagging_Report; //'No Snag report.';
            } 
            else {
                handOver = handOverList[0];
                if(handOver.HO_Agent_Assigned_User__c == NULL){
                    handOver.HO_Agent_Assigned_User__c = HOAgentId;
                }
                
                String docTargetName = '';
                String targetSubStatus = '';
                
                if (status == STATUS_QA) {
                    docTargetName = (report_type == SNAGGING) ? HO_QA_SNAGGING_REPORT : HO_QA_DESNAGGING_REPORT;
                    targetSubStatus = (report_type == SNAGGING) ? HANDOVER_STATUS_QA_DESNAGGING : Handover_Sub_Status_Upload_SOA;
                }
                else if (status == STATUS_CHO) {
                    docTargetName = (report_type == SNAGGING) ? HO_CHO_SNAGGING_REPORT : HO_CHO_DESNAGGING_REPORT;
                }
                
                List<Document__c> targetDocs = objDocumentService.getDocumentByHandoverIdAndName(handOver.Id, docTargetName);
                
                if (!targetDocs.isEmpty()){
                    
                    objDocumentService.addFile(base64Pdf, fileName + fileType,targetDocs[0].Id);
                    if(!handoverRecordCreated && status == STATUS_QA) {
                        handOver.Sub_Status__c = targetSubStatus;
                        if(report_type == DESNAGGING) {
                            handOver.Unit_is_Ready__c = true;
                        }
                        objHandoverService.updateHandover(handOver);
                    }
                    else if(!handoverRecordCreated && status == STATUS_CHO && !handOver.Handover_Phase__r.SkipHandoverCHOTasks__c){
                        HandoverHandler objHandoverHandler = HandoverHandler.getInstance();
                        ActivityService objActivityService = ActivityService.getInstance();
                        List<Task> openTaskList = objActivityService.getOpenTaskForHandoverTeam(handOver);
                        if(openTaskList != NULL && openTaskList.size() > 0){
                            objHandoverHandler.createNextHOTask(handOver, openTaskList[0]);
                        }
                        
                    }
                }
                return REPORT_UPLOADED_SUCCESSFULLY_ON_HANDOVER  +'"'+ handOver.Name+ '"}';
            }
        } catch (Exception ex) {
            ErrorLogHandler.logError('HandoverOnsiteAPI', 'deSnaggingReport', ex, '');
            return ex.getMessage();
        }
    }
}