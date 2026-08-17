/***
Class       : FollowUpTriggerHelper 
Author      : Jhilik
Description : 
TestClass   : FollowUpTriggerHelperTest
****************************************************************************************************************/
public without sharing class FollowUpTriggerHelper {
    
    private static final string MTD_OWE_NO_REPLY_SALES_IT_ID { get { return 'NoReplySalesIT'; } }
    private static final string FOLLOW_UP_ADDED_NOTIFICATION_TEMPLATE_ID { get { return 'FollowUpAddedNotificationTemplateId'; } }
    private static final string FOLLOW_UP_CUSTOM_NOTIFICATION_DEV_NAME { get { return 'Follow_Up_Notification'; } }

    public static void handleBeforeInsert(List<FollowUp__c> newList){
    }

    public static void handleAfterInsert(List<FollowUp__c> newList, Map<Id,FollowUp__c> newMap){
        notifyOwner(newList, newMap);
    }

    public static void notifyOwner(List<FollowUp__c> newList, Map<Id,FollowUp__c> newMap){
        MetadataService objMetadataService = MetadataService.getInstance();
        EmailService objEmailService = EmailService.getInstance();
        Id bloomNoReplySalesOWEId = objMetadataService.getAppSettingTextValue(MTD_OWE_NO_REPLY_SALES_IT_ID);
        Id followUpAddedNotificationETId = objMetadataService.getAppSettingTextValue(FOLLOW_UP_ADDED_NOTIFICATION_TEMPLATE_ID);
        List<Messaging.SingleEmailMessage> msgList = new List<Messaging.SingleEmailMessage>();

        Set<Id> queueIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        Set<Id> caseIds = new Set<Id>();
        Map<Id, User> userMap = new Map<Id, User>();
        Map<Id,Id> followUpIdToCaseOwnerIds = new Map<Id,Id>();
        Map<Id, Set<Id>> queueIdToGroupMemberMap = new Map<Id, Set<Id>>();
        Map<Id,Set<String>> followUpIdToRecipientEmailList = new Map<Id,Set<String>>();
        Map<Id,Set<String>> followUpIdToRecipientIdList = new Map<Id,Set<String>>();
        Map<Id, Set<Id>> caseIdToCRMUserIdList = new Map<Id, Set<Id>>();

        for (FollowUp__c fu : newList) {
            if (fu.CaseOwnerId__c != null) {
                Id caseOwnerId = (Id)fu.CaseOwnerId__c;
                followUpIdToCaseOwnerIds.put(fu.Id, caseOwnerId);
                if(caseOwnerId.getSObjectType() == Group.sObjectType) {
                    queueIds.add(caseOwnerId);
                } else if(caseOwnerId.getSObjectType() == User.sObjectType) {
                    userIds.add(caseOwnerId);
                }
                caseIds.add(fu.Case__c);
            }
        }

        if (queueIds.isEmpty() && userIds.isEmpty()) {
            return;
        }

        List<Task> taskList = ActivityService.getInstance().getCRMTasksByCaseIds(caseIds);
        for(Task tsk : taskList){
            if(tsk.OwnerId.getSObjectType() == User.sObjectType) {
                userIds.add(tsk.OwnerId);
                if(!caseIdToCRMUserIdList.containsKey(tsk.WhatId)){
                    caseIdToCRMUserIdList.put(tsk.WhatId, new Set<Id>());
                }
                caseIdToCRMUserIdList.get(tsk.WhatId).add(tsk.OwnerId);
            }
        }
        
        if (!queueIds.isEmpty()) {
            List<GroupMember> groupMemberList = GroupService.getGroupMembersByGroupIds(queueIds); //[SELECT GroupId, UserOrGroupId, UserOrGroup.Email FROM GroupMember WHERE GroupId IN :queueIds];
            for(GroupMember groupMemberRec : groupMemberList){
                if(groupMemberRec.UserOrGroupId.getSObjectType() == User.sObjectType){
                    if(!queueIdToGroupMemberMap.containsKey(groupMemberRec.GroupId)){
                        queueIdToGroupMemberMap.put(groupMemberRec.GroupId, new Set<Id>());
                    }
                    queueIdToGroupMemberMap.get(groupMemberRec.GroupId).add(groupMemberRec.UserOrGroupId);
                    userIds.add(groupMemberRec.UserOrGroupId);
                }
            }
        }

        if (!userIds.isEmpty()) {
            userMap = UserService.getInstance().getActiveUsersByIds(userIds);
        }

        for(Id fuId : followUpIdToCaseOwnerIds.keySet()){
            if(!followUpIdToRecipientEmailList.containsKey(fuId)){
                followUpIdToRecipientEmailList.put(fuId, new Set<String>());
                followUpIdToRecipientIdList.put(fuId, new Set<String>());
            }
            if(followUpIdToCaseOwnerIds.get(fuId).getSObjectType() == User.sObjectType && userMap.containsKey(followUpIdToCaseOwnerIds.get(fuId))) {
                followUpIdToRecipientEmailList.get(fuId).add(userMap.get(followUpIdToCaseOwnerIds.get(fuId)).Email);
                followUpIdToRecipientIdList.get(fuId).add(followUpIdToCaseOwnerIds.get(fuId));
            } else if(followUpIdToCaseOwnerIds.get(fuId).getSObjectType() == Group.sObjectType) {
                Set<Id> userIdList = queueIdToGroupMemberMap.get(followUpIdToCaseOwnerIds.get(fuId));
                for(Id usrId : userIdList){
                    if(userMap.containsKey(usrId)){
                        followUpIdToRecipientEmailList.get(fuId).add(userMap.get(usrId).Email);
                        followUpIdToRecipientIdList.get(fuId).add(usrId);
                    }
                }
            }
            if(caseIdToCRMUserIdList != NULL && caseIdToCRMUserIdList.containsKey(newMap.get(fuId).Case__c)){
                for(Id userRecId : caseIdToCRMUserIdList.get(newMap.get(fuId).Case__c)){
                    if(userMap.containsKey(userRecId)){
                        followUpIdToRecipientEmailList.get(fuId).add(userMap.get(userRecId).Email);
                        followUpIdToRecipientIdList.get(fuId).add(userRecId);
                    }
                }
            }
        }

        List<FeedItem> postList = new List<FeedItem>();
        CustomNotificationType notificationType = CustomNotificationService.getInstance().getCustomNotificationTypeByName(FOLLOW_UP_CUSTOM_NOTIFICATION_DEV_NAME);
        //CustomNotificationType notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName= :FOLLOW_UP_CUSTOM_NOTIFICATION_DEV_NAME];
        for(Id followUpId : followUpIdToRecipientEmailList.keySet()){
            Messaging.SingleEmailMessage objEmailMessage = new Messaging.SingleEmailMessage();
            objEmailMessage = objEmailService.getSingleEmailMessageWithoutTargetObjectId(followUpAddedNotificationETId, bloomNoReplySalesOWEId, followUpId, new List<String>(followUpIdToRecipientEmailList.get(followUpId)), null, null);
            msgList.add(objEmailMessage);
            System.debug('followUpIdToRecipientIdList ::::'+ followUpIdToRecipientIdList.get(followUpId));
            if(!followUpIdToRecipientIdList.get(followUpId).isEmpty()){
                CustomNotificationService.sendCustomNotification(new Set<String>(followUpIdToRecipientIdList.get(followUpId)), followUpId, notificationType, 'New Follow Up Added : ' + newMap.get(followUpId).CaseNumber__c, newMap.get(followUpId).Comments__c);
            }

            FeedItem post = new FeedItem();
            post.Body = 'New Follow Up Added : ' + newMap.get(followUpId).Name + '\r\n' + newMap.get(followUpId).Comments__c;
            post.Type = 'TextPost';
            post.ParentId = newMap.get(followUpId).Case__c;
            post.Title = 'New Follow Up Added : ' + newMap.get(followUpId).Name;
            postList.add(post);
        } 

        insert postList;
        objEmailService.sendEmail(msgList);
    }
}