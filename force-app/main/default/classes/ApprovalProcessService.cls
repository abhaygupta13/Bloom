/*****************************************************************************************
Class       : ApprovalProcessService
Author      : Vikas Baliyan
Description : ApprovalProcessService Service
Test Class  : 
Created Date: 09 APR 2025 
*****************************************************************************************/
public with sharing class ApprovalProcessService {
    private static ApprovalProcessService instance;
    private ApprovalProcessService() { }
    
    public static ApprovalProcessService getInstance() {
        if(instance == null) {
            instance = new ApprovalProcessService();
        }
        return instance;
    }

    /*
    * fetch Process Instance Steps by record Id
    */
    public List<ProcessInstanceNode> getProcessInstanceNodsByRecordId (String recordId, String status){
        return [SELECT Id, ProcessNodeName,LastActor.Name, LastActor.Title, ProcessNode.Name, ProcessInstanceId, NodeStatus, ProcessInstance.ProcessDefinition.Name, LastModifiedDate, CreatedDate FROM ProcessInstanceNode WHERE ProcessInstance.TargetObjectId =: recordId AND NodeStatus =: status AND ProcessInstance.Status =: status ORDER BY CreatedDate ASC];
    }
}