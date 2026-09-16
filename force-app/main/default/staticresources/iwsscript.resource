/* eslint-disable @typescript-eslint/no-unused-vars */
let softphone_connector_initialized = false;
let softphone_listener_initialized = false;
let gcPresenceLanguage, gcUser, gcPresences, gcWrapupCodes;
function onConnectedSession(message) {
    log.info("onConnectedSession " + JSON.stringify(message));
    if (softphone_connector_initialized == true) {
        return;
    }
    coreUtils.updateOpenCtiStatus(false);
    coreUtils.updateConnectionLed("led-yellow", "Connection in standby ...");
}
function onDisconnectedSession(message) {
    log.info("onDisconnectedSession " + JSON.stringify(message));
    $("#led").removeClass();
    $("#led").addClass("led-red");
    $(".led-msg p").text("Session disconnected");
    coreUtils.updateOpenCtiStatus(false);
    softphone_connector_initialized = false;
}
function onActivateSession(message) {
    log.info("onActivateSession " + JSON.stringify(message));
    if (softphone_connector_initialized == true) {
        return;
    }
    coreUtils.updateConnectionLed("led-green", "Connection estabilished");
    coreUtils.updateOpenCtiStatus(true);
    softphone_connector_initialized = true;
    if (!softphone_listener_initialized) {
        sfutil.enableClickToDial();
        sfutil.addTabFocusListener(["contact_id", "lead_id", "context.livechat_id"]);
        softphone_listener_initialized = true;
    }
}
async function onActivatePureEmbeddableSessionFullPEF(message) {
    log.info("onActivatePureEmbeddableSessionFullPEF " + JSON.stringify(message));
    if (softphone_connector_initialized == true) {
        return;
    }
    if (softphoneSettings.GEN_INTEGRATION_TYPE == "PURECLOUD") {
        try {
            gcPresenceLanguage = iwscore.customParseURL("language", "en_US");
            gcUser = await pClient.usersApi.getUsersMe();
            window["gcUser"] = gcUser;
            window["gcPresenceLanguage"] = gcPresenceLanguage;
            gcPresences = (await pClient.presenceApi.getPresencedefinitions({ "localeCode": "ALL" })).entities;
            window["gcPresences"] = gcPresences;
            const availableStatus = gcPresences.filter(p => p.systemPresence === "Available" && p.primary === true);
            const onQueueStatus = gcPresences.filter(p => p.systemPresence === "On Queue" && p.primary === true);
            gcWrapupCodes = await pClient.getWrapupCodes();
            window["gcWrapupCodes"] = gcWrapupCodes;
            iwscore.getConnectorConfig().auth.notReadyPresenceId = availableStatus[0].id;
            iwscore.getConnectorConfig().auth.onQueuePresenceId = onQueueStatus[0].id;
            if (iwspure && iwspure.restore) {
                await iwspure.restore();
            }
        }
        catch (e) {
            log.error("[softphone] onPreActivatePureEmbeddableSessionFullPEF error on get GC data: " + e);
            iwscommand.PublishError("Error opening connection with Genesys API from domain : " + window.location.origin);
        }
    }
    coreUtils.updateOpenCtiStatus(true);
    sfutil.subscribeLMC();
    softphone_connector_initialized = true;
    if (!softphone_listener_initialized) {
        if (softphoneSettings.GEN_SMART_UI && softphoneSettings.GEN_CONTACT_DISAMBIGUATION) {
            sfutil.subscribeDisambiguationEvent();
        }
        sfutil.enableClickToDial();
        sfutil.addTabFocusListener(["contact_id", "lead_id", "context.livechat_id"]);
        if (softphoneSettings.GEN_EXTERNAL_ROUTING) {
            omniUtils.addPresenceListener();
        }
        softphone_listener_initialized = true;
    }
}
function onWdeSwitchInteraction(message) {
    log.info("onWdeSwitchInteraction " + JSON.stringify(message));
    sfutil.manageSwitchInteraction(message);
}
function onSwitchInteractionPEF(message) {
    log.info("onSwitchInteractionPEF " + JSON.stringify(message));
    sfutil.manageSwitchInteraction(message);
}
async function onPreActivatePureEmbeddableSessionFullPEF(message) {
    log.info("onPreActivatePureEmbeddableSessionFullPEF " + JSON.stringify(message));
    if (message.token) {
        iwscore.getConnectorConfig().auth.token = message.token;
        pClient = new PureClientSdk();
        pClient.client.setEnvironment(iwscore.getConnectorConfig().auth.environment);
        pClient.client.setAccessToken(message.token);
    }
}
function onPreRequestConfigurationPureEmbeddable(message) {
    log.info("onPreRequestConfigurationPureEmbeddable : " + JSON.stringify(message));
    const _params = iwscore.getLayoutParams();
    if (_params.integrationType === "pure-embeddable") {
        iwscore.sendPureEmbeddableConfiguration();
    }
}
//==================================================================
// Presence Sync
//==================================================================
async function onChannelStatus(message) {
    log.info("onChannelStatus " + JSON.stringify(message));
    if (softphoneSettings.GEN_INTEGRATION_TYPE == "PURECLOUD" && !gcPresences) {
        gcPresences = (await pClient.presenceApi.getPresencedefinitions({ "localeCode": "ALL" })).entities;
        window["gcPresences"] = gcPresences;
    }
    coreUtils.manageCTILabel(message);
    if (softphoneSettings.GEN_EXTERNAL_ROUTING) {
        switch (softphoneSettings.GEN_INTEGRATION_TYPE) {
            case 'PURECLOUD':
                omniUtils.manageChangeStatusGC(message);
                break;
            case 'WDE':
                omniUtils.manageGetWdeStatus(message);
                break;
        }
    }
}
//==================================================================
// VOICE INBOUND
//==================================================================
async function onEventRingingInbound(message) {
    log.info("onEventRingingInbound " + JSON.stringify(message));
    await sfutil.createTimelog(message);
    iwscore.addJSONObjectInMemory(message, undefined);
    coreUtils.manageWidgetVisibility();
}
async function onEventEstablishedInbound(message) {
    log.info("onEventEstablishedInbound " + JSON.stringify(message));
    try {
        const payload = {
            Subject: `${new Date().toISOString()} - ${message.MediaType}`,
            softphone_it__IWS_Interaction_ID__c: message.InteractionID,
            softphone_it__IWS_Media_Name__c: message.MediaType
        };
        await sfutil.createObject(message, "task", payload, sfutil.extractPhone(message.ANI));
        timeLogUtil.upsertTimeLog(message);
        sfutil.manageScreenPop(message);
    }
    catch (error) {
        log.error(`Error in onEventEstablishedInbound: ${error.message} ; ${JSON.stringify(error)}`);
    }
}
function onEventReleasedInbound(message) {
    log.info("onEventReleasedInbound " + JSON.stringify(message));
    timeLogUtil.upsertTimeLog(message);
    sfutil.removeSmartUiView(message.InteractionID);
}
function onEventMarkDoneInbound(message) {
    log.info("onEventMarkDoneInbound " + JSON.stringify(message));
    if (softphoneSettings.GEN_EXTERNAL_ROUTING) {
        omniUtils.manageVoiceBusy(true);
    }
    timeLogUtil.upsertTimeLog(message);
}

//==================================================================
// VOICE OUTBOUND
//==================================================================
async function onEventDialingOutbound(message) {
    log.info("onEventDialingOutbound  : " + JSON.stringify(message));
    coreUtils.manageWidgetVisibility();
    await sfutil.createTimelog(message);
    iwscore.addJSONObjectInMemory(message, undefined);
}
async function onEventRingingOutbound(message) {
    log.info("onEventRingingOutbound  : " + JSON.stringify(message));
    coreUtils.manageWidgetVisibility();
    await sfutil.createTimelog(message);
    iwscore.addJSONObjectInMemory(message, undefined);
}
async function onEventEstablishedOutbound(message) {
    log.info("onEventEstablishedOutbound  : " + JSON.stringify(message));
    if (softphoneSettings.GEN_EXTERNAL_ROUTING) {
        omniUtils.manageVoiceBusy(false);
    }
    try {
        const payload = {
            Subject: `${new Date().toISOString()} - ${message.MediaType}`,
            CallType: message.CallType,
            softphone_it__IWS_Interaction_ID__c: message.InteractionID,
            softphone_it__IWS_Media_Name__c: message.MediaType
        };
        await sfutil.createObject(message, "task", payload, sfutil.extractPhone(message.DNIS));
        timeLogUtil.upsertTimeLog(message);
        sfutil.manageScreenPop(message);
    }
    catch (error) {
        log.error(`Error in onEventEstablishedOutbound: ${error.message} ; ${JSON.stringify(error)}`);
    }
}
function onEventReleasedOutbound(message) {
    log.info("onEventReleasedOutbound : " + JSON.stringify(message));
    if (softphoneSettings.GEN_EXTERNAL_ROUTING) {
        omniUtils.manageVoiceBusy(true);
    }
    timeLogUtil.upsertTimeLog(message);
    sfutil.removeSmartUiView(message.InteractionID);
}
function onEventMarkDoneOutbound(message) {
    log.info("onEventMarkDoneOutbound " + JSON.stringify(message));
    if (softphoneSettings.GEN_EXTERNAL_ROUTING) {
        omniUtils.manageVoiceBusy(true);
    }
    timeLogUtil.upsertTimeLog(message);
}
//==================================================================
// CHAT
//==================================================================
async function onChatEventRingingInbound(message) {
    coreUtils.manageWidgetVisibility();
    if (softphoneSettings.GEN_EXTERNAL_ROUTING && message.attachdata["context.livechat_id"]) {
        return;
    }
    await sfutil.createTimelog(message);
    iwscore.addJSONObjectInMemory(message, undefined);
}
async function onChatEventEstablishedInbound(message) {
    log.info("onChatEventEstablishedInbound : " + JSON.stringify(message));
    try {
        if (softphoneSettings.GEN_EXTERNAL_ROUTING && message.attachdata["context.livechat_id"]) {
            //  sforce.console.presence.login(softphoneSettings.ER_OMNI_READY_ID, function (res) { console.log(res); });
            await omniUtils.openLiveChat(message);
        }
        else {
            const payload = {
                Subject: `${new Date().toISOString()} - ${message.MediaType}`,
                CallType: message.CallType,
                softphone_it__IWS_Interaction_ID__c: message.InteractionID,
                softphone_it__IWS_Media_Name__c: message.MediaType
            };
            await sfutil.createObject(message, "task", payload, message.attachdata["context.email"]);
            timeLogUtil.upsertTimeLog(message);
            sfutil.manageScreenPop(message);
        }
    }
    catch (error) {
        log.error(`Error in onChatEventEstablishedInbound: ${error.message} ; ${JSON.stringify(error)}`);
    }
}
function onChatEventReleasedInbound(message) {
    log.info("onChatEventReleasedInbound  " + JSON.stringify(message));
    sfutil.removeSmartUiView(message.InteractionID);
    if (softphoneSettings.GEN_EXTERNAL_ROUTING && message.attachdata["context.livechat_id"]) {
        return;
    }
    timeLogUtil.upsertTimeLog(message);
}
async function onChatEventMarkDoneInbound(message) {
    log.info("onChatEventMarkDoneInbound  " + JSON.stringify(message));
    if (softphoneSettings.GEN_EXTERNAL_ROUTING && message.attachdata["context.livechat_id"]) {
        await omniUtils.closeTab(message.attachdata["context.livechat_id"], undefined);
        return;
    }
    timeLogUtil.upsertTimeLog(message);
}
//==================================================================
// EMAIL
//==================================================================
async function onEmailEventRingingInbound(message) {
    log.info("onEmailEventRingingInbound " + JSON.stringify(message));
    coreUtils.manageWidgetVisibility();
    await sfutil.createTimelog(message);
    iwscore.addJSONObjectInMemory(message, undefined);
}
async function onEmailEventEstablishedInbound(message) {
    log.info("onEmailEventEstablishedInbound " + JSON.stringify(message));
    try {
        const payload = {
            Subject: `${new Date().toISOString()} - ${message.MediaType}`,
            CallType: message.CallType,
            softphone_it__IWS_Interaction_ID__c: message.InteractionID,
            softphone_it__IWS_Media_Name__c: message.MediaType
        };
        await sfutil.createObject(message, "task", payload, message.attachdata["context.email"]);
        timeLogUtil.upsertTimeLog(message);
        sfutil.manageScreenPop(message);
    }
    catch (error) {
        log.error(`Error in onEmailEventEstablishedInbound: ${error.message} ; ${JSON.stringify(error)}`);
    }
}
function onEmailEventReleasedInbound(message) {
    log.info("onEmailEventReleasedInbound " + JSON.stringify(message));
    sfutil.removeSmartUiView(message.InteractionID);
    timeLogUtil.upsertTimeLog(message);
}
function onEmailEventMarkDoneInbound(message) {
    log.info("onEmailEventMarkDoneInbound " + JSON.stringify(message));
    timeLogUtil.upsertTimeLog(message);
}
//==================================================================
// SMS
//==================================================================
async function onSmsEventRingingInbound(message) {
    log.info("onSmsEventRingingInbound " + JSON.stringify(message));
    coreUtils.manageWidgetVisibility();
    await sfutil.createTimelog(message);
    iwscore.addJSONObjectInMemory(message, undefined);
}
async function onSmsEventEstablishedInbound(message) {
    log.info("onSmsEventEstablishedInbound : " + JSON.stringify(message));
    try {
        const payload = {
            Subject: `${new Date().toISOString()} - ${message.MediaType}`,
            CallType: message.CallType,
            softphone_it__IWS_Interaction_ID__c: message.InteractionID,
            softphone_it__IWS_Media_Name__c: message.MediaType
        };
        await sfutil.createObject(message, "task", payload, sfutil.extractPhone(message.ANI));
        timeLogUtil.upsertTimeLog(message);
        sfutil.manageScreenPop(message);
    }
    catch (error) {
        log.error(`Error in onSmsEventEstablishedInbound: ${error.message} ; ${JSON.stringify(error)}`);
    }
}
function onSmsEventReleasedInbound(message) {
    log.info("onSmsEventReleasedInbound : " + JSON.stringify(message));
    sfutil.removeSmartUiView(message.InteractionID);
    timeLogUtil.upsertTimeLog(message);
}
function onSmsEventMarkDoneInbound(message) {
    log.info("onSmsEventMarkDoneInbound : " + JSON.stringify(message));
    timeLogUtil.upsertTimeLog(message);
}
//==================================================================
// WHATSAPP
//==================================================================
async function onWhatsappEventRingingInbound(message) {
    log.info("onWhatsappEventRingingInbound : " + JSON.stringify(message));
    coreUtils.manageWidgetVisibility();
    await sfutil.createTimelog(message);
    iwscore.addJSONObjectInMemory(message, undefined);
}
async function onWhatsappEventEstablishedInbound(message) {
    log.info("onWhatsappEventEstablishedInbound : " + JSON.stringify(message));
    try {
        const payload = {
            Subject: `${new Date().toISOString()} - ${message.MediaType}`,
            CallType: message.CallType,
            softphone_it__IWS_Interaction_ID__c: message.InteractionID,
            softphone_it__IWS_Media_Name__c: message.MediaType
        };
        await sfutil.createObject(message, "task", payload, sfutil.extractPhone(message.ANI));
        timeLogUtil.upsertTimeLog(message);
        sfutil.manageScreenPop(message);
    }
    catch (error) {
        log.error(`Error in onWhatsappEventEstablishedInbound: ${error.message} ; ${JSON.stringify(error)}`);
    }
}
function onWhatsappEventReleasedInbound(message) {
    log.info("onWhatsappEventReleasedInbound : " + JSON.stringify(message));
    sfutil.removeSmartUiView(message.InteractionID);
    timeLogUtil.upsertTimeLog(message);
}
function onWhatsappEventMarkDoneInbound(message) {
    log.info("onWhatsappEventMarkDoneInbound : " + JSON.stringify(message));
    timeLogUtil.upsertTimeLog(message);
}
//==================================================================
//WEBMESSAGING
//==================================================================
async function onWebmessagingEventRingingInbound(message) {
    log.info("onWebmessagingEventRinging : " + JSON.stringify(message));
    coreUtils.manageWidgetVisibility();
    await sfutil.createTimelog(message);
    iwscore.addJSONObjectInMemory(message, undefined);
}
async function onWebmessagingEventEstablishedInbound(message) {
    log.info("onWebmessagingEventEstablished : " + JSON.stringify(message));
    try {
        const payload = {
            Subject: `${new Date().toISOString()} - ${message.MediaType}`,
            CallType: message.CallType,
            softphone_it__IWS_Interaction_ID__c: message.InteractionID,
            softphone_it__IWS_Media_Name__c: message.MediaType
        };
        await sfutil.createObject(message, "task", payload, message.attachdata["context.email"]);
        timeLogUtil.upsertTimeLog(message);
        sfutil.manageScreenPop(message);
    }
    catch (error) {
        log.error(`Error in onWebmessagingEventEstablished: ${error.message} ; ${JSON.stringify(error)}`);
    }
}
function onWebmessagingEventReleasedInbound(message) {
    log.info("onWebmessagingEventReleased : " + JSON.stringify(message));
    sfutil.removeSmartUiView(message.InteractionID);
    timeLogUtil.upsertTimeLog(message);
}
function onWebmessagingEventMarkDoneInbound(message) {
    log.info("onWebmessagingEventMarkDoneInbound : " + JSON.stringify(message));
    timeLogUtil.upsertTimeLog(message);
}
//==================================================================
//CALLBACK
//==================================================================
function onCallbackEventRinging(message) {
    log.info("onCallbackEventRingingOutbound : " + JSON.stringify(message));
    iwscore.addJSONObjectInMemory(message, undefined);
    coreUtils.manageWidgetVisibility();
}
function onCallbackEventEstablished(message) {
    log.info("onCallbackEventRingingOutbound : " + JSON.stringify(message));
    sfutil.checkExistsAndScreenPop(message, ['leadorcontactid', 'contact_id', 'lead_id', 'id']);
}
//==============================================
// Open Event
//==============================================
async function onOpenEventRingingInbound(message) {
    coreUtils.manageWidgetVisibility();
    await sfutil.createTimelog(message);
    iwscore.addJSONObjectInMemory(message, undefined);
}
async function onOpenEventEstablishedInbound(message) {
    log.info("onOpenEventEstablishedInbound " + JSON.stringify(message));
    try {
        const payload = {
            Subject: `${new Date().toISOString()} - ${message.MediaType}`,
            CallType: message.CallType,
            softphone_it__IWS_Interaction_ID__c: message.InteractionID,
            softphone_it__IWS_Media_Name__c: message.MediaType
        };
        await sfutil.createObject(message, "task", payload, message.attachdata["context.email"]);
        timeLogUtil.upsertTimeLog(message);
        sfutil.manageScreenPop(message);
    }
    catch (error) {
        log.error(`Error in onOpenEventEstablishedInbound: ${error.message} ; ${JSON.stringify(error)}`);
    }
}
function onOpenEventReleasedInbound(message) {
    log.info("onOpenEventReleasedInbound " + JSON.stringify(message));
    timeLogUtil.upsertTimeLog(message);
}
function onOpenEventMarkDoneInbound(message) {
    log.info("onOpenEventMarkDoneInbound " + JSON.stringify(message));
    timeLogUtil.upsertTimeLog(message);
}
function onOpenEventAbandonedInbound(message) {
    log.info("onOpenEventAbandonedInbound " + JSON.stringify(message));
    timeLogUtil.upsertTimeLog(message);
}
//==================================================================
//WORKITEM
//==================================================================
function onWorkitemEventRingingInbound(message) {
    log.info("onWorkitemEventRingingInbound " + JSON.stringify(message));
    iwscore.addJSONObjectInMemory(message, undefined);
    coreUtils.manageWidgetVisibility();
}
function onWorkitemEventEstablishedInbound(message) {
    log.info("onWorkitemEventEstablishedInbound " + JSON.stringify(message));
    if (softphoneSettings.GEN_EXTERNAL_ROUTING) {
        omniUtils.createAgentWork(message);
    }
}
function onWorkitemEventReleasedInbound(message) {
    log.info("onWorkitemEventReleasedInbound " + JSON.stringify(message));
}
function onWorkitemEventMarkDoneInbound(message) {
    log.info("onWorkitemEventMarkDoneInbound: " + JSON.stringify(message));
}
//==================================================================
//WDE
//==================================================================
async function onDelegateCommand(message) {
    console.log("onDelegateCommand : " + JSON.stringify(message));
    omniUtils.manageDelegate(message);
}
function onRegisterCommand(message) {
    console.log("onRegisterCommand : " + JSON.stringify(message));
    if (!message || !message.ChainName) {
        console.log("invalid message, returning ...");
        return;
    }
}
function onInhibitCommand(message) {
    log.info("onInhibitCommand " + JSON.stringify(message));
}
function onMediaVoiceNotReady(message) {
    console.log("onMediaVoiceNotReady :" + JSON.stringify(message));
}
function onMediaVoiceReady(message) {
    console.log("onMediaVoiceReady :" + JSON.stringify(message));
}
function onMediaOpenMediaReady(message) {
    console.log("onMediaOpenMediaReady :" + JSON.stringify(message));
    if (softphoneSettings.GEN_EXTERNAL_ROUTING) {
        omniUtils.manageChannelStatusChange(message);
    }
}
function onMediaOpenMediaNotReady(message) {
    console.log("onMediaOpenMediaNotReady :" + JSON.stringify(message));
    if (softphoneSettings.GEN_EXTERNAL_ROUTING) {
        omniUtils.manageChannelStatusChange(message);
    }
}
function onMediaVoiceLogOff(message) {
    console.log("onMediaVoiceLogOff :" + JSON.stringify(message));
    if (softphoneSettings.GEN_EXTERNAL_ROUTING) {
        omniUtils.manageChannelStatusChange(message);
    }
}
function onMediaVoiceLogOn(message) {
    console.log("onMediaVoiceLogOn :" + JSON.stringify(message));
    if (softphoneSettings.GEN_EXTERNAL_ROUTING) {
        omniUtils.manageChannelStatusChange(message);
    }
}
function onMediaOpenMediaLogOff(message) {
    console.log("onMediaOpenMediaLogOff :" + JSON.stringify(message));
    if (softphoneSettings.GEN_EXTERNAL_ROUTING) {
        omniUtils.manageChannelStatusChange(message);
    }
}
function onMediaOpenMediaLogOn(message) {
    console.log("onMediaOpenMediaLogOn :" + JSON.stringify(message));
    if (softphoneSettings.GEN_EXTERNAL_ROUTING) {
        omniUtils.manageChannelStatusChange(message);
    }
}
function showNotification(callid) {
    const title = "Genesys";
    //icon = "image-url"
    const body = "Interaction from Genesys";
    const notification = new Notification(title, { body });
    notification.onclick = () => {
        notification.close();
        window.parent.focus();
        iwscommand.updateStatePEF(callid, "pickup");
    };
}
