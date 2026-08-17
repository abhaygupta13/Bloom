public with sharing class WorkOrderImageController {
    public WorkOrder workOrder { get; set; }
    public List<List<String>> beforeImagePairs { get; set; }
    public List<List<String>> AfterImagePairs { get; set; }
    public String signUrls { get; set; }
    public String todayDate { get; set; }
    
    public WorkOrderImageController() {
        Id workOrderId = ApexPages.currentPage().getParameters().get('id');
        DateTime now = System.now();
        todayDate = now.format('d MMMM, h:mm a');
        List<String> beforeImageUrls = new List<String>();
        List<String> afterImageUrls = new List<String>();
        
        if (workOrderId != null) {
            // Get WorkOrder details
            workOrder = [SELECT Id,Owner.Name,WorkOrderNumber,Signed_By__c, Requester_Name__c, Type_of_Incident__c,Requester_Email__c, Location__c, Requester_Phone__c,
                         Incident_description__c, Project__r.Name, Unit__r.UnitNumber__c,Description,Customer_Comment__c,Rating__c,Closure_Comment__c,Problem_Code_New__c,
                         AgentsComments__c, Sub_category__c,Category__c FROM WorkOrder WHERE Id = :workOrderId LIMIT 1];
            
            // Get related images from ContentDocumentLink
            List<ContentDocumentLink> links = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :workOrderId];
            
            if (!links.isEmpty()) {
                Set<Id> contentDocIds = new Set<Id>();
                for (ContentDocumentLink link : links) {
                    contentDocIds.add(link.ContentDocumentId);
                }
                
                // Get the ContentDocument of files
                List<ContentVersion> versions = [SELECT Id, Title, FileExtension FROM ContentVersion WHERE ContentDocumentId IN :contentDocIds ORDER BY CreatedDate];
                system.debug('versions-->'+versions);
                
                for (ContentVersion version : versions) {
                    String fileExtension = version.FileExtension.toLowerCase();
                    if (fileExtension == 'png' || fileExtension == 'jpg' || fileExtension == 'jpeg') {
                        if(version.Title == 'Signature'){
                            system.debug('Signature___versions-->'+versions);
                            signUrls = '/sfc/servlet.shepherd/version/download/' + version.Id;
                        }
                        if(version.Title != null && version.Title.contains('Before')){
                            String BeforeUrl = '/sfc/servlet.shepherd/version/download/' + version.Id;
                            beforeImageUrls.add(BeforeUrl);
                        }
                        if(version.Title != null && version.Title.contains('After')){
                            String AfterUrl = '/sfc/servlet.shepherd/version/download/' + version.Id;
                            afterImageUrls.add(AfterUrl);
                        }
                    }
                }
                beforeImagePairs = new List<List<String>>();
                for (Integer i = 0; i < beforeImageUrls.size(); i += 2) {
                    List<String> pair = new List<String>();
                    pair.add(beforeImageUrls[i]);
                    if (i + 1 < beforeImageUrls.size()) {
                        pair.add(beforeImageUrls[i + 1]);
                    } else {
                        pair.add(null); 
                    }
                    beforeImagePairs.add(pair);
                }
                
                AfterImagePairs = new List<List<String>>();
                for (Integer i = 0; i < afterImageUrls.size(); i += 2) {
                    List<String> pair = new List<String>();
                    pair.add(afterImageUrls[i]);
                    if (i + 1 < afterImageUrls.size()) {
                        pair.add(afterImageUrls[i + 1]);
                    } else {
                        pair.add(null); 
                    }
                    AfterImagePairs.add(pair);
                }
            }
        }
    }
    public static void generateAndAttachPdf(Id recordId) {
        if (!String.isBlank(recordId)) {
            system.debug('insertPdfAttachment-->'+recordId);
            completeMilestone(recordId);
            insertPdfAttachment(recordId);
        }
    }
    
    @Future(callout=true)
    public static void insertPdfAttachment(Id recordId) {
        try {
            WorkOrder workOrder = [SELECT Id, WorkOrderNumber FROM WorkOrder WHERE Id = :recordId LIMIT 1];
            system.debug('workOrder'+workOrder);
            
            PageReference pdfPage = Page.WorkOrderPdf;
            pdfPage.getParameters().put('id', recordId);
            Blob pdfBlob;
            if (Test.isRunningTest()) {
                pdfBlob = Blob.valueOf('Dummy PDF content for testing.');
            } else {
                pdfBlob = pdfPage.getContentAsPDF();
            }
            
            ContentVersion cv = new ContentVersion();
            cv.Title = workOrder.WorkOrderNumber + '_Work Order Service Report';
            cv.PathOnClient = 'WorkOrder.pdf';
            cv.VersionData = pdfBlob;
            cv.IsMajorVersion = true;
            insert cv;
            
            Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1].ContentDocumentId;
            
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = contentDocId;
            cdl.LinkedEntityId = recordId;
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers';
            insert cdl;
            
            //completeMilestone(recordId);

            system.debug('insertPdfAttachment_cdl-->'+cdl);
            WorkOrder wo = new WorkOrder();
            wo.Id = recordId;
            wo.Check_Out_Time__c = System.now();
            wo.Status = Constants.CLOSED; //Constants.COMPLETED_LABEL;
            wo.Check_Out__c = true;
            wo.ScheduledAppointmentTimeStarted__c = false;
            WorkOrderService objWorkOrderService = WorkOrderService.getInstance();
            List<WorkOrder> updatedWo = objWorkOrderService.updateWorkOrdersWithTrigger(new List<WorkOrder>{wo}); 
            
            if(!updatedWo.isEmpty() && updatedWo[0].status == Constants.CLOSED && updatedWo[0].Closure_Reason__c == Constants.WORK_COMPLETED){
                List<EmailMessage> msgRec = [SELECT Id FROM EmailMessage WHERE RelatedToId =:recordId ORDER BY CreatedDate DESC LIMIT 1];
                if (!msgRec.isEmpty()) {
                    Id recId = msgRec[0].Id;
                    if(cv!=null){
                        Attachment attachment = new Attachment();
                        attachment.ParentId = recId;
                        attachment.Name = cv.Title;
                        attachment.Body = cv.VersionData;
                        Database.insert(attachment,false);
                    }
                }
            }
        } 
        catch (Exception e) {
            System.debug('Error in insertPdfAttachment: ' + e.getMessage());
        }
    }

    public static void completeMilestone(Id workorderId){
        List<EntityMilestone> milestoneList = [SELECT Id, StartDate, IsViolated , TimeRemainingInMins, ParentEntityId, CompletionDate FROM EntityMilestone WHERE ParentEntityId = :workorderId AND CompletionDate = NULL];
        for(EntityMilestone milestoneRec : milestoneList){
            milestoneRec.CompletionDate = System.now();
        }
        update milestoneList;
    }
    
}