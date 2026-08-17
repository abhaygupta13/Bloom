/* eslint-disable @typescript-eslint/no-unused-vars */
//var firstInteractionIdSelected = null;
function onPreChannelStatus(message) {
    iwscore.setIwsInitData(message);
}
function onPreConnectedSession(message) {
    if (message.IwsApplicationName) {
        iwscore.setIwsApplicationName(message.IwsApplicationName);
    }
    iwscore.setIwsInitData(message);
    iwscore.showConnectedState();
}
function onPreDisconnectedSession(message) {
    iwscore.showDisconnectedState();
}
function onPreActivateSession(message) {
    const _params = iwscore.getConnectorConfig();
    if (_params.integrationType === "pure-embeddable" && message.token) {
        iwscore.initPureCloud(message.token);
        return;
    }
    iwscore.showActivedState();
    //load combo interactions
    if (message.interactions) {
        let i;
        log.debugFormat("[onPreActivateSession] received [{0}] interaction", message.interactions.length);
        //addEmptyOption() removeEmptyOption()
        //if((!isMultyInteractions()) && (isEnablePlaceHolder()))
        //	addEmptyOption();
        if (iwscore.isEnablePlaceHolder())
            iwscore.addEmptyOption();
        for (i = 0; i < message.interactions.length; i++) {
            if ((message.interactions[i].State == 8)
                ||
                    (message.interactions[i].State == 1)
                ||
                    (message.interactions[i].State == 2))
                continue;
            log.debug("[onPreActivateSession] Check if the interaction is a Campaign");
            if (iwscore.isCampaign(message.interactions[i])) {
                log.debug("[onPreActivateSession] The interaction is a Campaign");
                if (iwscore.isEnablePlaceHolder())
                    iwscore.addJSONObjectInMemoryCampaign(message.interactions[i], iwscore.isEnablePlaceHolderInteraction(message.interactions[i]));
                else
                    iwscore.addJSONObjectInMemoryCampaign(message.interactions[i], false);
            }
            else {
                log.debug("[onPreActivateSession] The interaction not is a Campaign");
                if (iwscore.isEnablePlaceHolder())
                    iwscore.addJSONObjectInMemory(message.interactions[i], iwscore.isEnablePlaceHolderInteraction(message.interactions[i]));
                else
                    iwscore.addJSONObjectInMemory(message.interactions[i], false);
            }
            //message.interactions[i].State == 5 means released
        }
        //if((!isMultyInteractions()) && (isEnablePlaceHolder()))
        if (iwscore.isEnablePlaceHolder())
            iwscore.removeEmptyOption();
        if (iwscore.countInteractions() > 0) {
            iwscore.removeDefaultOption();
        }
        return;
    }
    if (message.activeInteractions) {
        message.activeInteractions.forEach(i => iwscore.addJSONObjectInMemory(i));
    }
}
function onPreDeactivateSession(message) {
    iwscore.showConnectedState();
}
function onPreEventDeallocate(message) {
    iwscore.removeJSONObjectInMemory(message.ConnectionID);
}
function getIdFromDelegateCommand(message) {
    let id = "";
    try {
        const sapp = message.Parameters.CommandParameter;
        const n = sapp.indexOf("/");
        id = sapp.substring(n + 1).slice(0, -1);
    }
    catch (e) {
        log.warn("getIdFromDelegateCommand: " + e.message);
    }
    log.debugFormat("[getIdFromDelegateCommand] id[{0}]", id);
    return id;
}
function onPreDelegateCommand(message) {
    try {
        let id = iwscore.getMessageId(message);
        if (id) {
            log.debugFormat("[onPreDelegateCommand] with ConnectionID [{0}]", id);
        }
        else {
            id = getIdFromDelegateCommand(message);
            if (id) {
                log.debugFormat("[onPreDelegateCommand] with ConnectionID [{0}]", id);
                message.ConnectionID = id;
                message.InteractionID = id;
            }
        }
    }
    catch (e) {
        log.warn("[onPreDelegateCommand]: " + e.message);
    }
}
function onPreEventAgentReady(message) {
    log.info("onPreEventAgentReady " + JSON.stringify(message));
    if (softphoneSettings.GEN_EXTERNAL_ROUTING) {
        omniUtils.manageVoiceBusy(true);
    }
    const event = { Command: "MediaVoiceReady", Parameters: { Reasons: {} } };
    omniUtils.manageChannelStatusChange(event);
}
function onPreEventAgentNotReady(message) {
    log.info("onPreEventAgentNotReady " + JSON.stringify(message));
    if (softphoneSettings.GEN_EXTERNAL_ROUTING) {
        omniUtils.manageVoiceBusy(true);
    }
    const reason = message.attachdata && message.attachdata.ActionCode
        ? message.attachdata.ActionCode
        : "";
    const event = {
        Command: "MediaVoiceNotReady",
        Parameters: { Reasons: { [reason]: reason } }
    };
    omniUtils.manageChannelStatusChange(event);
}
function onPreEventReleasedInbound(message) {
    //removeJSONObjectInMemory(message.ConnectionID);
    //   window.dispatchEvent(new CustomEvent(enumCustomEventType.ConnectorInteractionReleased, { detail: message }));
}
function onPostEventReleasedConsult(message) {
    if (message.Service != 'PureCloud' || iwscore.getConnectorConfig().eventType == 'standard') {
        iwscore.removeJSONObjectInMemory(message.ConnectionID);
    }
}
function onPreEventReleasedInternal(message) {
    //    window.dispatchEvent(new CustomEvent(enumCustomEventType.ConnectorInteractionReleased, { detail: message }));
    //removeJSONObjectInMemory(message.ConnectionID);
}
function onPreEventPartyChangedInbound(message) {
    //release the consult...
    //PreviousConnID
    //add the new Inbound
    if (message.Service != 'PureCloud' || iwscore.getConnectorConfig().eventType == 'standard') {
        iwscore.removeJSONObjectInMemory(message.PreviousConnID);
        iwscore.addJSONObjectInMemory(message, undefined);
    }
}
function onPreEventPartyChangedInternal(message) {
    if (message.Service != 'PureCloud' || iwscore.getConnectorConfig().eventType == 'standard') {
        iwscore.removeJSONObjectInMemory(message.PreviousConnID);
        iwscore.addJSONObjectInMemory(message, undefined);
    }
}
function onPreEventPartyChangedOutbound(message) {
    if (message.Service != 'PureCloud') {
        iwscore.removeJSONObjectInMemory(message.PreviousConnID);
        iwscore.addJSONObjectInMemory(message, undefined);
    }
}
function onPreEventEstablishedOutbound(message) {
    if (iwscore.isCampaign(message)) {
        iwscore.addJSONObjectInMemoryCampaign(message, undefined);
        if (iwscore.isEnablePlaceHolder() && iwscore.isSelectedInteraction(message)) {
            iwscommand.SetInteractionOnWde(message.ConnectionID);
        }
    }
}
function onPreEventReleasedOutbound(message) {
    //  window.dispatchEvent(new CustomEvent(enumCustomEventType.ConnectorInteractionReleased, { detail: message }));
}
function onPreEventMarkDoneInbound(message) {
    /*
    //EventPartyChanged
    log.debugFormat("onPreEventMarkDoneInbound State [{0}] Name[{1}]", message.State, message.Name);
    if(message.Name != "EventReleased")
        return false;
        */
}
function onPostEventMarkDoneInbound(message) {
    if (message.Service != 'PureCloud' || iwscore.getConnectorConfig().eventType == 'standard') {
        iwscore.removeJSONObjectInMemory(message.ConnectionID);
    }
}
function onPostEventMarkDoneInternal(message) {
    if (message.Service != 'PureCloud' || iwscore.getConnectorConfig().eventType == 'standard') {
        iwscore.removeJSONObjectInMemory(message.ConnectionID);
    }
}
function onPostEventMarkDoneConsult(message) {
    if (message.Service != 'PureCloud' || iwscore.getConnectorConfig().eventType == 'standard') {
        iwscore.removeJSONObjectInMemory(message.ConnectionID);
    }
}
function onPostEventMarkDoneOutbound(message) {
    if (!iwscore.isCampaign(message) && (message.Service != 'PureCloud' || iwscore.getConnectorConfig().eventType == 'standard')) {
        iwscore.removeJSONObjectInMemory(message.ConnectionID);
    }
    else {
        const recordhandle = "" + iwscore.getRecordHandle(message);
        iwscore.removeJSONObjectInMemory(recordhandle);
    }
}
//==============================================
// Chat Section 
//==============================================
function onPreChatEventReleasedInbound(message) {
    // window.dispatchEvent(new CustomEvent(enumCustomEventType.ConnectorInteractionReleased, { detail: message }));
}
function onPostChatEventMarkDoneInbound(message) {
    if (message.Service != 'PureCloud' || iwscore.getConnectorConfig().eventType == 'standard') {
        iwscore.removeJSONObjectInMemory(message.ConnectionID);
    }
}
//==============================================
//Workitem Section 
//==============================================
function onPreWorkitemEventReleasedInbound(message) {
    if (message.Service != 'PureCloud' || iwscore.getConnectorConfig().eventType == 'standard') {
        iwscore.removeJSONObjectInMemory(message.ConnectionID);
    }
}
//Added in release 1.5.0.0
function onPostWorkitemEventRevokedInbound(message) {
    if (message.Service != 'PureCloud' || iwscore.getConnectorConfig().eventType == 'standard') {
        iwscore.removeJSONObjectInMemory(message.ConnectionID);
    }
}
//==============================================
//Email Section 
//==============================================
function onPreEmailEventReleasedInbound(message) {
    //  window.dispatchEvent(new CustomEvent(enumCustomEventType.ConnectorInteractionReleased, { detail: message }));
}
function onPostEmailEventReleasedInbound(message) {
    if (message.Service != 'PureCloud' || iwscore.getConnectorConfig().eventType == 'standard') {
        iwscore.removeJSONObjectInMemory(message.ConnectionID);
    }
}
function onPostEmailEventReleasedOutbound(message) {
    if (message.Service != 'PureCloud' || iwscore.getConnectorConfig().eventType == 'standard') {
        iwscore.removeJSONObjectInMemory(message.ConnectionID);
    }
}
function onPreEmailEventOpenedInbound(message) {
    iwscore.addJSONObjectInMemory(message, undefined);
}
function onPreEmailEventReplyEstablishedOutbound(message) {
    iwscore.addJSONObjectInMemory(message, undefined);
}
function onPreEmailEventReplyEstablished(message) {
    iwscore.addJSONObjectInMemory(message, undefined);
}
function onPreEmailEventReplyReleasedOutbound(message) {
    if (message.Service != 'PureCloud') {
        iwscore.removeJSONObjectInMemory(message.ConnectionID);
    }
}
function onPreEmailEventReplyReleased(message) {
    if (message.Service != 'PureCloud' || iwscore.getConnectorConfig().eventType == 'standard') {
        iwscore.removeJSONObjectInMemory(message.ConnectionID);
    }
    // window.dispatchEvent(new CustomEvent(enumCustomEventType.ConnectorInteractionReleased, { detail: message }));
}
function onPreEmailEventReplyCancelled(message) {
    if (message.Service != 'PureCloud' || iwscore.getConnectorConfig().eventType == 'standard') {
        iwscore.removeJSONObjectInMemory(message.ConnectionID);
    }
}
function onPreEmailEventReplyOpened(message) {
    iwscore.addJSONObjectInMemory(message, undefined);
}
function onPreEmailEventReplyOpenedOutbound(message) {
    iwscore.addJSONObjectInMemory(message, undefined);
}
//==============================================
// Workbin Section 
//==============================================
function onPreWorkbinPlacedIn(message) {
    if (message.Service != 'PureCloud' || iwscore.getConnectorConfig().eventType == 'standard') {
        iwscore.removeJSONObjectInMemory(message.ConnectionID);
    }
}
//==============================================
//SMS Section 
//==============================================
function onPreSMSEventReleasedInbound(message) {
    if (message.Service != 'PureCloud' || iwscore.getConnectorConfig().eventType == 'standard') {
        iwscore.removeJSONObjectInMemory(message.ConnectionID);
    }
}
function onPreSMSEventEstablishedOutbound(message) {
    iwscore.addJSONObjectInMemory(message, undefined);
}
function onPreSMSEventReleasedOutbound(message) {
    if (message.Service != 'PureCloud' || iwscore.getConnectorConfig().eventType == 'standard') {
        iwscore.removeJSONObjectInMemory(message.ConnectionID);
    }
}
//==============================================
//SMS Section 
//==============================================
function onPreSmsEventReleased(message) {
    if (message.Service != 'PureCloud' || iwscore.getConnectorConfig().eventType == 'standard') {
        iwscore.removeJSONObjectInMemory(message.ConnectionID);
    }
}
function onPreSmsEventReleasedInbound(message) {
    if (message.Service != 'PureCloud' || iwscore.getConnectorConfig().eventType == 'standard') {
        iwscore.removeJSONObjectInMemory(message.ConnectionID);
    }
}
function onPreSmsEventReleasedOutbound(message) {
    if (message.Service != 'PureCloud' || iwscore.getConnectorConfig().eventType == 'standard') {
        iwscore.removeJSONObjectInMemory(message.ConnectionID);
    }
}
//==============================================
//Webmessaging Section 
//==============================================
function onPostWebmessagingEventReleased(message) {
    if (message.Service != 'PureCloud' || iwscore.getConnectorConfig().eventType == 'standard') {
        iwscore.removeJSONObjectInMemory(message.ConnectionID);
    }
}
function onPostWebmessagingEventReleasedInbound(message) {
    if (message.Service != 'PureCloud' || iwscore.getConnectorConfig().eventType == 'standard') {
        iwscore.removeJSONObjectInMemory(message.ConnectionID);
    }
}
//==================================================================
//Events UserEvent
//==================================================================
function onPreEventUserEvent(message) {
    try {
        const eventname = message.attachdata.GSW_USER_EVENT;
        log.debugFormat("onPreEventUserEvent: the event is {0}", eventname);
        iwscore.callSafetyFunction("onPre" + eventname + "(message);", message);
        if (iwscore.checkFunction("on" + eventname)) {
            iwscore.callSafetyFunction("on" + eventname + "(message);", message);
            //return false;
        }
    }
    catch (e) {
        log.error("onPreEventUserEvent: " + e.message);
    }
    return true;
}
function onPostEventUserEvent(message) {
    try {
        const eventname = message.attachdata.GSW_USER_EVENT;
        log.debugFormat("onPostEventUserEvent: the event is {0}", eventname);
        iwscore.callSafetyFunction("onPost" + eventname + "(message);", message);
    }
    catch (e) {
        log.error("onPostEventUserEvent: " + e.message);
    }
    return true;
}
function onPrePreviewRecord(message) {
    log.debug("======= onPrePreviewRecord ==========");
    iwscore.addJSONObjectInMemoryCampaign(message, undefined); //false);
}
function onPreRecordProcessedAcknowledge(message) {
    log.debug("======= onPreRecordProcessedAcknowledge ==========");
    //var recordhandle = "" + getRecordHandle(message);
    //removeJSONObjectInMemory(recordhandle);	
}
function onPostRecordProcessedAcknowledge(message) {
    log.debug("======= onPostRecordProcessedAcknowledge ==========");
    const recordhandle = "" + iwscore.getRecordHandle(message);
    iwscore.removeJSONObjectInMemory(recordhandle);
}
function onPreRecordRejectAcknowledge(message) {
    log.debug("======= onPreRecordRejectAcknowledge ==========");
    const recordhandle = "" + iwscore.getRecordHandle(message);
    iwscore.removeJSONObjectInMemory(recordhandle);
}
function onPreRecordCancelAcknowledge(message) {
    log.debug("======= onPreRecordCancelAcknowledge ==========");
    const recordhandle = "" + iwscore.getRecordHandle(message);
    iwscore.removeJSONObjectInMemory(recordhandle);
}
function onPreScheduledCall(message) {
    log.debug("======= onPreScheduledCall ==========");
    iwscore.addJSONObjectInMemoryCampaign(message, undefined); //false);
}
function onPreChainedRecordsDataEnd(message) {
    log.debug("======= onPreChainedRecordsDataEnd ==========");
    iwscore.addJSONObjectInMemoryCampaign(message, undefined); //false);
}
//==================================================================
// PushPreview
//==================================================================
function onPreOutboundpreviewEventEstablished(message) {
    log.debug("======= onPreOutboundpreviewEventEstablished ==========");
    iwscore.addJSONObjectInMemoryCampaign(message, undefined); //false);
}
function onPreOutboundpreviewEventEstablishedInternal(message) {
    log.debug("======= onPreOutboundpreviewEventEstablishedInternal ==========");
    iwscore.addJSONObjectInMemoryCampaign(message, undefined); //false);
}
function onPostOutboundpreviewEventReleasedInternal(message) {
    onPostOutboundpreviewEventReleased(message);
}
function onPostOutboundpreviewEventReleased(message) {
    log.debug("======= onPostOutboundpreviewEventReleased ==========");
    const recordhandle = "" + iwscore.getRecordHandle(message);
    iwscore.removeJSONObjectInMemory(recordhandle);
}
//==================================================================
//Events Twitter
//==================================================================
function onPreTwitterEventReleasedInbound(message) {
    //   window.dispatchEvent(new CustomEvent(enumCustomEventType.ConnectorInteractionReleased, { detail: message }));
}
function onPostTwitterEventReleasedInbound(message) {
    if (message.Service != 'PureCloud' || iwscore.getConnectorConfig().eventType == 'standard') {
        iwscore.removeJSONObjectInMemory(message.ConnectionID);
    }
}
function onPreTwitterEventReplyOutbound(message) {
    /*
    onTwitterEventReplyOutbound
    onTwitterEventRetweetOutbound
    onTwitterEventRetweetWithCommentsOutbound
    onTwitterEventDirectMessageOutbound
    */
    try {
        const msgType = message.attachdata._twitterMsgType;
        log.debug("onPreTwitterEventReplyOutbound with " + msgType);
        if ((msgType === "Retweet") || (msgType === "DirectMessage")) {
            log.debug("onPreTwitterEventReplyOutbound with " + msgType);
            const myevent = "TwitterEvent{0}Outbound".format(msgType);
            log.debugFormat("onPreTwitterEventReply: the new event is on{0}", myevent);
            iwscore.callSafetyFunction("onPre" + myevent + "(message);", message);
            if (iwscore.checkFunction("on" + myevent)) {
                iwscore.callSafetyFunction("on" + myevent + "(message);", message);
            }
            return false;
        }
    }
    catch (e) {
        log.error("onPreTwitterEventReply: " + e.message);
    }
    return true;
}
//==================================================================
//Events Facebook
//==================================================================
function onPostFacebookEventReleasedInbound(message) {
    if (message.Service != 'PureCloud' || iwscore.getConnectorConfig().eventType == 'standard') {
        iwscore.removeJSONObjectInMemory(message.ConnectionID);
    }
}
function onPreFacebookEventReleasedInbound(message) {
    //    window.dispatchEvent(new CustomEvent(enumCustomEventType.ConnectorInteractionReleased, { detail: message }));
}
function onPostFacebookEventReleased(message) {
    if (message.Service != 'PureCloud' || iwscore.getConnectorConfig().eventType == 'standard') {
        iwscore.removeJSONObjectInMemory(message.ConnectionID);
    }
}
function onPreFacebookEventReleased(message) {
    //   window.dispatchEvent(new CustomEvent(enumCustomEventType.ConnectorInteractionReleased, { detail: message }));
}
//==================================================================
//Events Open
//==================================================================
function onPreOpenEventReleasedInbound(message) {
    //   window.dispatchEvent(new CustomEvent(enumCustomEventType.ConnectorInteractionReleased, { detail: message }));
}
function onPostOpenEventMarkDoneInbound(message) {
    if (message.Service != 'PureCloud' || iwscore.getConnectorConfig().eventType == 'standard') {
        iwscore.removeJSONObjectInMemory(message.ConnectionID);
    }
}
//==================================================================
//Generic Events
//==================================================================
function onPreWdeSwitchInteraction(message) {
    const mymessage = iwscore.getInteraction(message.InteractionID);
    if (mymessage) {
        const curr_message = iwscore.getSelectedInteraction();
        if (curr_message) {
            log.infoFormat("[onPreWdeSwitchInteraction] Selected Interaction [{0}] Switch Interaction[{1}] ======================", curr_message.InteractionID, mymessage.InteractionID);
            if (curr_message.InteractionID != mymessage.InteractionID) {
                iwscore.selectInteractionOptionByMessage(mymessage);
            }
        }
    }
}
function onPreSwitchInteractionPEF(message) {
    onPreWdeSwitchInteraction(message);
}
function onPreWebformEventEstablishedInbound(message) {
    iwscore.addJSONObjectInMemory(message, undefined);
}
function onPostWebformEventReleasedInbound(message) {
    iwscore.removeJSONObjectInMemory(message.ConnectionID);
}
/*function onPreSwitchInteractionPEF(message)
{
    if (window["InteractionBarUI"])
    {
        window["InteractionBarUI"].selectInteractionById(message.InteractionID);
    } else
    {
        firstInteractionIdSelected = message.InteractionID;
    }
}*/
//alert("iwsprescript well formed!");
