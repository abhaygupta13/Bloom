/*
*********************************************************
Apex Class Name    : ServiceReportTriggerHelper 
Created Date       : Sept 21, 2026
@description       : This is helper class for Service Report trigger.
Modification Log   :
Ver   Date         : Author                               Modification
1.0   21-09-2026   : Abhay Gupta                          Created Trigger Helper class for Service Report object
*********************************************************
*/
public without sharing class ServiceReportTriggerHelper {
    public static void updateDocumentOnWorkOrder(List<ServiceReport> ServiceReports) {
        Set<Id> serviceAppointmentIds = new Set<Id>();
        
        for(ServiceReport sr : ServiceReports) {
            if(sr.ParentId != null) {
                serviceAppointmentIds.add(sr.ParentId);
            }
        }
        List<ServiceAppointment> serviceAppointments = ServiceAppointmentService.getInstance().getServiceAppointmentsByIds(serviceAppointmentIds);
        
        Map<Id, Id> serviceAppointmentToWorkOrderMap = new Map<Id, Id>();
        for (ServiceAppointment sa : serviceAppointments) {
            serviceAppointmentToWorkOrderMap.put(sa.Id, sa.ParentRecordId);
        }
        
        // Query the files (ContentDocumentLinks) related to these ServiceAppointments
        ContentDocumentLinkService objContentDocumentLinkService = ContentDocumentLinkService.getInstance();
        List<ContentDocumentLink> contentLinks = objContentDocumentLinkService.getcontentDocumentLinksByIds(serviceAppointmentIds);
        
        // Create a list to hold the updated ContentDocumentLinks
        List<ContentDocumentLink> updatedContentLinks = new List<ContentDocumentLink>();
        
        for (ContentDocumentLink link : contentLinks) {
            Id workOrderId = serviceAppointmentToWorkOrderMap.get(link.LinkedEntityId);
            
            if (workOrderId != null) {
                // Create a new ContentDocumentLink to link the file to the WorkOrder
                ContentDocumentLink newLink = new ContentDocumentLink();
                newLink.ContentDocumentId = link.ContentDocumentId;
                newLink.LinkedEntityId = workOrderId;
                newLink.ShareType = link.ShareType; // Preserve the same ShareType
                updatedContentLinks.add(newLink);
            }
        }        
        
        objContentDocumentLinkService.insertContentDocumentLinkWithTrigger(updatedContentLinks);       
    }
}