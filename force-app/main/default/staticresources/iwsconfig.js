log.setLogLevel(enumloglevel.error);
if (softphoneSettings.GEN_LOG_LEVEL == 'Debug') {
    log.setLogLevel(enumloglevel.debug);
}
switch (softphoneSettings.GEN_INTEGRATION_TYPE) {
    case "PURECLOUD":
        loadPureRequestConfig();
        break;
    case "WDE":
        loadWDE();
        break;
}
function loadWDE() {
    iwscore.getConnectorConfig().integrationType = "wde";
    iwscore.createConnection(softphoneSettings.WDE_HOST, softphoneSettings.WDE_PORT, { 'protocol': softphoneSettings.WDE_PROTOCOL });
}
function loadPureRequestConfig() {
    const customAttributes = softphoneSettings.PEF_CUSTOM_ATTRIBUTES?.split(",") || [];
    const searchTargets = softphoneSettings.PEF_SEARCH_TARGETS?.split(",") || [];
    const interactionDetails = {
        call: softphoneSettings.PEF_DISPLAY_DETAILS_CALL?.split(",") || [],
        callback: softphoneSettings.PEF_DISPLAY_DETAILS_CALLBACK?.split(",") || [],
        chat: softphoneSettings.PEF_DISPLAY_DETAILS_CHAT?.split(",") || [],
        email: softphoneSettings.PEF_DISPLAY_DETAILS_EMAIL?.split(",") || [],
        message: softphoneSettings.PEF_DISPLAY_DETAILS_MESSAGE?.split(",") || []
    };
    const params = {
        customInteractionAttributes: ["timelog_id", "context.email", "sfdc_id", "case_id", "task_id", "contact_id", "lead_id", "account_id", "context.livechat_id", "service_channel_id", "work_item_id", ...customAttributes],
        settings: {
            searchTargets: [...searchTargets],
            embedWebRTCByDefault: softphoneSettings.PEF_EMBED_WEB_RTC_BY_DEFAULT,
            hideWebRTCPopUpOption: softphoneSettings.PEF_HIDE_WEB_RTC_POP_UP_OPTION,
            enableCallLogs: softphoneSettings.PEF_ENABLE_CALL_LOGS,
            hideCallLogSubject: softphoneSettings.PEF_HIDE_CALL_LOG_SUBJECT,
            hideCallLogContact: softphoneSettings.PEF_HIDE_CALL_LOG_CONTACT,
            hideCallLogRelation: softphoneSettings.PEF_HIDE_CALL_LOG_RELATION,
            enableTransferContext: softphoneSettings.PEF_ENABLE_TRANSFER_CONTEXT,
            dedicatedLoginWindow: softphoneSettings.PEF_DEDICATED_LOGIN_WINDOW,
            embeddedInteractionWindow: softphoneSettings.PEF_EMBEDDED_INTERACTION_WINDOW,
            enableConfigurableCallerId: softphoneSettings.PEF_ENABLE_CONFIGURABLE_CALLER_ID,
            enableServerSideLogging: softphoneSettings.PEF_ENABLE_SERVER_SIDE_LOGGING,
            enableCallHistory: softphoneSettings.PEF_ENABLE_CALL_HISTORY,
            theme: {
                primary: softphoneSettings.PEF_THEME_PRIMARY,
                text: softphoneSettings.PEF_THEME_TEXT
            },
            sso: {
                provider: softphoneSettings.GC_SSO_PROVIDER,
                orgName: softphoneSettings.GC_SSO_ORG_NAME
            },
            display: {
                interactionDetails: interactionDetails
            }
        },
        clientIds: {
            "mypurecloud.com": "9d789d97-b8ef-4e54-8638-96dea523aa28",
            "mypurecloud.de": "2850f585-583d-4c3d-8dfc-2ff77aa41c11",
            "mypurecloud.ie": "58905000-8cd7-4909-b939-97c4e6a03581",
            "mypurecloud.jp": "02e69958-dea2-448a-81ab-bcbebe07fd72",
            "mypurecloud.com.au": "238d8aa6-cddf-4945-aa30-9a7acb2cc603",
            "usw2.pure.cloud": "eaabe512-ef46-4ab8-ad74-f6c111dcd871",
            "cac1.pure.cloud": "cd402ed2-7953-4716-8542-bfa2adbab2f0",
            "euw2.pure.cloud": "cd402ed2-7953-4716-8542-bfa2adbab2f0",
            "aps1.pure.cloud": "cd402ed2-7953-4716-8542-bfa2adbab2f0",
            "apne2.pure.cloud": "cd402ed2-7953-4716-8542-bfa2adbab2f0"
        },
        helpLinks: {}
    };
    const permission = "softphoneGenericCRM";
    let url = "https://apps." + softphoneSettings.PEF_GC_ENVIRONMENT + "/crm/" + permission + "/index.html?request_configuration=true&full_PEF=true&crm_domain=" + window.location.origin;
    if (softphoneSettings.GEN_LIVE_VOICE_TRANSCRIPT) {
        url += '&notification_categories=interactionSelection,chatUpdate,interactionWindow,conversationTranscription,messageUpdate';
    }
    const config = {
        context: window,
        layoutType: softphoneSettings.GEN_SMART_UI ? 'smart-ui' : 'frame',
        integrationType: "pure-embeddable",
        url: url,
        auth: {
            environment: softphoneSettings.PEF_GC_ENVIRONMENT
        },
        pefParams: params,
        eventType: softphoneSettings.CON_EVENT_TYPE || 'standard',
        smartUi: {
            mainJSpath: smartUiPath,
            showConnectionLed: softphoneSettings.GEN_SHOW_CONNECTION_LED,
            interactionUrl: softphoneSettings.GEN_LIVE_INTERACTION ? "https://apps." + softphoneSettings.PEF_GC_ENVIRONMENT + "/crm/" + permission + "/interaction.html" : "",
            globalViews: []
        }
    };
    const appConfig = { ...config };
    delete appConfig.context;
    log.info("starting connector, configuration : " + JSON.stringify(appConfig));
    iwscore.initCTI(config);
    iwscore.enableCTI();
}