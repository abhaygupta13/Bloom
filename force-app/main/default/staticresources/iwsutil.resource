/**
 * Utility class for managing LMC event channel subscriptions and various CTI operations.
 */
class Util {
    /**
     * A configuration object that maps Salesforce record types to their respective field mappings.
     *
     * @property {Record<string, SalesforceRecordConfig>} recordConfigs - The configuration object.
     * @property {SalesforceRecordConfig} recordConfigs.task - Configuration for the Salesforce Task record type.
     * @property {Object} recordConfigs.task.mappingField - Field mappings for the Task record type.
     * @property {string} recordConfigs.task.mappingField.contact - Maps to the "WhoId" field in Salesforce.
     * @property {string} recordConfigs.task.mappingField.lead - Maps to the "WhoId" field in Salesforce.
     * @property {string} recordConfigs.task.mappingField.account - Maps to the "WhatId" field in Salesforce.
     * @property {string} recordConfigs.task.mappingField.case - Maps to the "WhatId" field in Salesforce.
     * @property {SalesforceRecordConfig} recordConfigs.case - Configuration for the Salesforce Case record type.
     * @property {Object} recordConfigs.case.mappingField - Field mappings for the Case record type.
     * @property {string} recordConfigs.case.mappingField.contact - Maps to the "ContactId" field in Salesforce.
     * @property {string} recordConfigs.case.mappingField.account - Maps to the "AccountId" field in Salesforce.
     */
    recordConfigs = {
        task: {
            mappingField: {
                contact: "WhoId",
                lead: "WhoId",
                account: "WhatId",
                case: "WhatId"
            }
        },
        case: {
            mappingField: {
                contact: "ContactId",
                account: "AccountId"
            }
        },
        timelog: {
            mappingField: {
                contact: "softphone_it__Contact__c",
                account: "softphone_it__Account__c",
                case: "softphone_it__Case__c"
            }
        }
    };
    extractPhone(phone) {
        return phone.replace("tel:", "");
    }
    /**
     * Subscribes to the LMC event channel.
     *
     * @remarks
     * This method subscribes to the LMC event channel using the `sforce.opencti.subscribe` function.
     * It sets the `channelName` to `LMC_CONNECTOR` and provides a listener function to handle incoming messages.
     * If the subscription is successful, the resulting subscription object is stored in the `_evtSubscription` variable.
     * If the subscription fails, an error message is logged.
     */
    subscribeLMC() {
        sforce.opencti.subscribe({
            channelName: LMC_CONNECTOR,
            listener: (m) => this.listenerSubscribe(m),
            callback: function (result) {
                if (!result.success) {
                    log.info(`Failed to subscribe to event channel ${LMC_CONNECTOR}, errors : ${result.errors}`);
                }
                else {
                    _evtSubscription = result.subscription;
                }
            }
        });
    }
    /**
     * Unsubscribes from the LMC (Lightning Message Channel) if there is an active subscription.
     */
    unsubscribeLMC() {
        if (_evtSubscription) {
            sforce.opencti.unsubscribe({ subscription: _evtSubscription, callback: (res) => log.info("unsubscribe result :" + JSON.stringify(res)) });
            _evtSubscription = null;
        }
    }
    /**
     * Manages the incoming LMC event messages.
     * Handles the following commands:
     * - clikToDial: Initiates a click-to-dial operation.
     * - ringing: Updates the state of the call to 'pickup'.
     * @param msg - The event message.
     */
    listenerSubscribe(msg) {
        log.info("***listenerSubscribe, received event : " + JSON.stringify(msg));
        switch (msg.command) {
            case "clikToDial":
                {
                    log.info("***clikToDial received...");
                    const call = {
                        number: msg.number,
                        type: "call",
                        autoPlace: true,
                        attributes: {}
                    };
                    const key = (msg.objectType + "_id").toLowerCase();
                    call.attributes[key] = msg.recordId;
                    iwscommand.clickToDialPEF(call);
                    break;
                }
            case "ringing":
                log.info("***ringing received...");
                iwscommand.updateStatePEF(msg.callid, "pickup");
                break;
        }
    }
    /**
     * Displays a dialog with the specified title and body.
     * @param title - The title of the dialog.
     * @param body - The body content of the dialog.
     * @param refresh - Indicates whether the dialog should be refreshed.
     */
    showDialog(title, body, refresh) {
        sforce.opencti.publish({
            channelName: 'softphone_it__LMC_Connector__c',
            message: {
                "command": "openDialog",
                "refresh": refresh,
                "title": title,
                "body": body
            }, callback: (res) => console.log("*** callback result :", res)
        });
    }
    /**
     * Checks the notification permission and publishes a message to the 'softphone_it__LMC_Connector__c' channel.
     * @returns {void}
     */
    checkNotificationPermission() {
        sforce.opencti.publish({
            channelName: 'softphone_it__LMC_Connector__c',
            message: {
                "command": "checkNotificationPermission"
            }, callback: (res) => console.log("*** callback result :", res)
        });
    }
    /**
     * Displays a notification for a specific call. Tipically used to send a call notification as a broswer notification.
     *
     * @param callid - The ID of the call.
     * @param action - The action associated with the notification.
     */
    showNotification(callid, action) {
        sforce.opencti.publish({
            channelName: 'softphone_it__LMC_Connector__c',
            message: {
                "command": "showNotification",
                "callid": callid,
                "action": action
            }, callback: (res) => console.log("*** callback result :", res)
        });
    }
    /**
     * Adds a tab focus listener to the Salesforce CTI connector.
     * This listener is triggered when a primary tab is focused.
     * It checks if the focused tab matches any interaction's contact ID, Salesforce ID, live chat ID, or work item ID.
     * If a match is found, it switches the interaction also on Genesys.
     */
    addTabFocusListener(ids) {
        sforce.console.onFocusedPrimaryTab(listened => {
            sforce.console.getFocusedPrimaryTabId(focused => {
                if (focused && listened && focused.id == listened.id) {
                    for (const key in iwscore.mapInteractions) {
                        const ixn = iwscore.mapInteractions[key];
                        if (ixn) {
                            for (const id of ids) {
                                if (ixn.attachdata[id] && listened.objectId.startsWith(ixn.attachdata[id])) {
                                    iwscommand.SetInteractionOnWde(ixn.InteractionID || ixn.ConnectionID);
                                }
                            }
                        }
                    }
                }
            });
        });
    }
    /**
     * Enables click to dial functionality.
     *
     * @remarks
     * This function enables click to dial functionality based on the softphone settings.
     * If the GEN_SF_EXPERIENCE is set to 'Lightning', it uses the sforce.opencti API to handle click to dial.
     * Otherwise, it uses the sforce.interaction.cti API.
     *
     * @param callback - The callback function to be called after enabling click to dial.
     */
    enableClickToDial() {
        const callback = (res) => {
            log.info("click to dial response=" + JSON.stringify(res));
        };
        log.info("enabling click to dial");
        if (softphoneSettings.GEN_SF_EXPERIENCE == 'Lightning') {
            sforce.opencti.onClickToDial({
                listener: (payload) => {
                    log.info('Clicked phone number: ' + JSON.stringify(payload));
                    if (!payload || !payload.number) {
                        log.warn("The result from click to dial is not valid : " + JSON.stringify(payload));
                        return;
                    }
                    if (iwscore.getConnectorConfig().integrationType == "pure-embeddable") {
                        const call = {
                            number: payload.number,
                            type: "call",
                            autoPlace: true,
                            attributes: {}
                        };
                        const key = (payload.objectType + "_id").toLowerCase();
                        call.attributes[key] = payload.recordId;
                        iwscommand.clickToDialPEF(call);
                    }
                    else {
                        iwscommand.MakeCall(payload.number, undefined);
                    }
                }
            });
            sforce.opencti.enableClickToDial({ callback: callback });
        }
        else {
            log.info("setting onClickToDial");
            sforce.interaction.cti.onClickToDial(function (payload) {
                log.info('Clicked phone number: ' + JSON.stringify(payload));
                const result = JSON.parse(payload.result);
                if (!result || !result.number) {
                    log.warn("The result from click to dial is not valid : " + JSON.stringify(payload));
                    return;
                }
                log.info("Dialing phone number : " + result.number);
                iwscommand.MakeCall(result.number, undefined);
            });
            sforce.interaction.cti.enableClickToDial(undefined);
        }
    }
    /**
     * Checks if any of the specified IDs exist in the attachdata of a CtiMessage.
     * If found, performs a screen pop and returns true.
     * Otherwise, returns false.
     *
     * @param message - The CtiMessage object to check.
     * @param ids - An array of string IDs to search for in the attachdata.
     * @returns True if an item is found and a screen pop is performed, false otherwise.
     */
    checkExistsAndScreenPop(message, ids) {
        if (!message.attachdata) {
            log.debug(`[checkExistsAndScreenPop] No attachdata found.`);
            return false;
        }
        for (const id of ids) {
            if (message.attachdata[id]) {
                log.infoFormat(`[checkExistsAndScreenPop]: There is already an item associated to this interaction : {0}, opening it`, message.attachdata[id]);
                coreUtils.screenPop(message.attachdata[id]);
                return true;
            }
        }
        log.debug(`[checkExistsAndScreenPop] No existing IDs found in attachdata.`);
        return false;
    }
    /**
     * Manages the interaction switch on Genesys widget, focusing the related Salesforce tab
     *
     * @param message - The message containing the interaction details.
     */
    manageSwitchInteraction(message) {
        const interaction = iwscore.mapInteractions[message.InteractionID];
        if (interaction) {
            const id = interaction.attachdata.case_id || interaction.attachdata.contact_id || interaction.attachdata.task_id || interaction.attachdata.sfdc_id || interaction.attachdata["context.livechat_id"] || interaction.attachdata['context.work_item_id'];
            if (id) {
                coreUtils.focusTab(id);
            }
        }
    }
    /**
     * Removes a smart UI interaction view.
     *
     * @param id - The ID of the view to be removed.
     */
    removeSmartUiView(id) {
        if (softphoneSettings.GEN_SMART_UI && softphoneSettings.GEN_CONTACT_DISAMBIGUATION) {
            iwscore.sendCustomEvent("ConnectorInteractionRemoved", { interactionDeleted: id });
        }
    }
    /**
     * Subscribes to the disambiguation event.
     *
     * @remarks
     * This method adds event listeners for the "customViewEvent" and "customSelectEvent" events.
     * When the "customViewEvent" is triggered with a valid detail ID, it calls the `coreUtils.screenPop` method.
     * When the "customSelectEvent" is triggered with a valid detail ID and type, it calls the `performSmartUiAssociation` method.
     */
    subscribeDisambiguationEvent() {
        window.addEventListener("customViewEvent", (ev) => {
            console.log("Event : ", ev);
            if (ev && ev.detail && ev.detail.id) {
                coreUtils.screenPop(ev.detail.id);
            }
        });
        window.addEventListener("customSelectEvent", (ev) => {
            console.log("Event : ", ev);
            if (ev && ev.detail && ev.detail.id) {
                this.performSmartUiAssociation(ev.detail.id, ev.detail.type);
            }
        });
    }
    /**
     * Updates the related Salesforce object, with the selected object id, and adds the selected object id to the
     * Genesys participant data
     *
     * @param id - The ID to perform the association with.
     * @param type - The type of the association.
     * @returns A promise that resolves when the association is performed.
     */
    async performSmartUiAssociation(id, type) {
        log.info(`START performSmartUiAssociation, id=${id};type=${type}`);
        try {
            if (!id || !type) {
                throw new Error("Missing id or type");
            }

            coreUtils.screenPop(id);
            if (iwscore.getSelectedInteractionId()) {
                const int = iwscore.mapInteractions[iwscore.getSelectedInteractionId()];
               
                
                if (!int?.attachdata) {
                    log.info(`END performSmartUiAssociation interaction or attachdata are missing ${JSON.stringify(int)}`);
                    return;
                }
                let entityName;
                let entityId;
                if (int.attachdata.task_id) {
                    entityName = "task";
                    entityId = int.attachdata.task_id;
                } else if (int.attachdata.case_id) {
                   entityName = "case";
                   entityId = int.attachdata.case_id;
                }
                const config = this.recordConfigs[entityName];
                const field = config.mappingField[type];
                 if (!field) {
                    log.info(`END performSmartUiAssociation missing configuration for type ${type}; config=${JSON.stringify(config.mappingField)}`);
                    return;
                }
                log.info(`performSmartUiAssociation updating record ${entityName}; with id ${entityId} with this payload : ${ JSON.stringify({ [field]: id })}`);
                    
                await coreUtils.updateRecord(entityName, entityId, { [field]: id });
                const key = (type + "_id").toLowerCase();
                iwscommand.SetAttachdataById(int.InteractionID, { [key]: id });

                if (int.attachdata.timelog_id) {
                    const configTimelog = this.recordConfigs.timelog;
                    const field = configTimelog.mappingField[type];
                    await coreUtils.updateRecord("softphone_it__ConnectorEventTimeLog__c", int.attachdata.case_id, { [field]: id });
                    log.info(`END performSmartUiAssociation Timelog updated`);
                }

            }
        } catch (e) {
            log.error(`performSmartUiAssociation error : ${e.message}; ${JSON.stringify(e)}`);
        }

    }
    /**
     * Normalizes an array of records for the disambiguation view.
     *
     * @param records - The array of records to be normalized.
     * @returns The normalized array of records.
     */
    normalizeRecords(records) {
        const result = [];
        records.forEach(r => {
            if (r) {
                const record = { id: r.Id, name: r.Name, email: r.Email, type: r.type, phone: r.Phone };
                if (r.Account) {
                    record.accountName = r.Account.Name;
                    record.accountId = r.Account.Id;
                }
                result.push(record);
            }
        });
        return result;
    }
    /**
     * Adds the Smart UI disambiguation view.
     *
     * @param msg - The CtiMessage object.
     * @param records - An array of records.
     */
    addDisambiguationView(msg, records) {
        const obj = {
            id: "disambiguation",
            title: "disambiguation",
            jspath: smartuiDisambiguation,
            icon: "contact_phone",
            autoStart: true,
            type: "interaction",
            ctiMessage: msg,
            params: {
                groupby: "type",
                fields: "name,email,accountName,id,accountId",
                icon: "account_circle",
                viewEventName: "customViewEvent",
                selectEventName: "customSelectEvent",
                contact_icon: "person",
                lead_icon: "account_circle",
                hide_select_button: false,
                hide_view_button: false,
                contact_fields: "name,email,phone,accountName",
                lead_fields: "name,email,phone",
                records: records
            }
        };
        window.dispatchEvent(new CustomEvent(enumCustomEventType.ConnectorLocalViewAdded, {
            detail: obj
        }));
    }


    /**
      * Creates a Salesforce object with the specified entity name and payload.
      *
      * @param message - The CtiMessage object.
      * @param entityName - The name of the entity (e.g., "Task", "Case").
      * @param payload - The payload for the object.
      * @param contactIdentifier - The identifier for the contact (e.g., phone number).
      * @returns A Promise that resolves to the created object.
      */
    async createObject(message, entityName, payload, contactIdentifier) {
        if (sfutil.checkExistsAndScreenPop(message, [entityName + "_id"])) {
            return;
        }
        try {
            log.info(`[createObject] Starting to create ${entityName} with contact identifier: ${contactIdentifier}`);
            // Step 1: Recognize contact
            const contact = await this.recognizeContact(message, contactIdentifier);
            // Step 2: Populate payload with the appropriate association field
            this.populatePayload(payload, entityName, contact);
            // Step 3: Create the Salesforce record
            const result = await coreUtils.createRecord(entityName, payload);
            log.info(`[createObject] Successfully created ${entityName} : ${JSON.stringify(result)}`);
            // Step 4: Attach data to the message
            this.addAttachData(message, contact, result, entityName);
            return result;
        }
        catch (error) {
            log.error(`[createObject] Failed to create ${entityName}: ${error.message} ; ${JSON.stringify(error)}`);
            throw error;
        }
    }
    /**
     * Sets the participant data for the given interaction on Genesys.
     * Updates the ctiMessage in memory with the correct attach data.
     *
     * @param message - The CtiMessage to add attach data to.
     * @param attachData - The attach data to be added.
     */
    addAttachData(message, record, object, entityName) {
        const attachData = {};
        if (record?.type && record?.id) {
            attachData[record.type + "_id"] = record.id;
        }
        attachData[entityName + "_id"] = object.Id;
        iwscommand.SetAttachdataById(message.InteractionID, attachData);
        message.attachdata = { ...message.attachdata, ...attachData };
        iwscore.addJSONObjectInMemory(message);
    }
    /**
     * Manages the screen pop based on the given CtiMessage.
     * If GEN_LIVE_VOICE_TRANSCRIPT is enabled and the message has a timelog_id,
     * it performs a screen pop using the timelog_id.
     * Otherwise, it performs a screen pop using the contact_id, lead_id, or entityNameId from the attachdata.
     *
     * @param message The CtiMessage containing the necessary data for the screen pop.
     */
    manageScreenPop(message) {
        if (softphoneSettings.GEN_LIVE_VOICE_TRANSCRIPT && message.MediaType == 'voice' && message.attachdata.timelog_id) {
            coreUtils.screenPop(message.attachdata.timelog_id);
        }
        else {
            coreUtils.screenPop(message.attachdata.contact_id || message.attachdata.lead_id || message.attachdata.case_id || message.attachdata.task_id);
        }
    }
    /**
     * Populates the given payload with the appropriate field and value based on the provided entity name and Salesforce record.
     *
     * @param payload - The payload object to be populated.
     * @param entityName - The name of the entity to be used for retrieving the configuration.
     * @param record - The Salesforce object wrapper containing the record details.
     *
     * The method checks if the record has an id and type. If both are present, it retrieves the configuration for the given entity name.
     * If a mapping field is defined for the record type, it assigns the record id to the corresponding field in the payload.
     * Logs a debug message with the assigned field and value. If no mapping field is defined, logs a warning message.
     */
    populatePayload(payload, entityName, record) {
        if (record?.id && record?.type) {
            const config = this.recordConfigs[entityName];
            if (config && config.mappingField && config.mappingField[record.type]) {
                const field = config.mappingField[record.type];
                payload[field] = record.id;
                log.debug(`Assigned ${field}: ${record.id}`);
            }
            else {
                log.warn(`No association field defined for entity: ${entityName}`);
            }
        }
    }
    /**
     * Recognizes a contact based on the provided message and contact identifier.
     * If the message contains the contact_id participant data, returns it immediately.
     * @param message - The CtiMessage object containing the contact information.
     * @param contactIdentifier - The identifier of the contact.
     * @returns A Promise that resolves to a RecognitionResult object representing the recognized contact.
     */
    async recognizeContact(message, contactIdentifier) {
        if (message.attachdata?.contact_id) {
            log.debug(`Contact ID already exists: ${message.attachdata.contact_id}`);
            return { id: message.attachdata.contact_id, type: "contact" };
        }
        if (message.attachdata?.lead_id) {
            log.debug(`Lead ID already exists: ${message.attachdata.lead_id}`);
            return { id: message.attachdata.lead_id, type: "lead" };
        }
        if (message.attachdata?.account_id) {
            log.debug(`Lead ID already exists: ${message.attachdata.lead_id}`);
            return { id: message.attachdata.account_id, type: "account" };
        }
        log.info(`Searching for contact with identifier: ${contactIdentifier}`);
        const records = await coreUtils.find('sosl', `'${contactIdentifier}' IN ALL FIELDS RETURNING Lead (Id, Name,phone,email), Contact(id,name,phone,email,Account.Name)`, []);
        if (records.length === 1) {
            log.info(`Found single contact: ${records[0].Id}`);
            return { id: records[0].Id, type: records[0].type };
        }
        else if (records.length > 1) {
            const showDisambiguation = softphoneSettings.GEN_SMART_UI && softphoneSettings.GEN_CONTACT_DISAMBIGUATION;
            if (showDisambiguation) {
                log.info(`Multiple contacts found (${records.length}). Initiating disambiguation.`);
                this.addDisambiguationView(message, this.normalizeRecords(records));
            }
        }
        return undefined;
    }
    /**
     * Executes a SQL query on a specified object and retrieves the results.
     *
     * @param objectName - The name of the object to query.
     * @param fieldName - The name of the field to filter by.
     * @param fieldValue - The value of the field to filter by.
     * @param columns - An array of column names to retrieve.
     * @returns A promise that resolves to an array of records, where each record is an object with key-value pairs representing the columns and their values.
     */
    async executeSqlQuery(objectName, fieldName, fieldValue, columns) {
        return await coreUtils.find(`${objectName}`, `${fieldName}='${fieldValue}'`, columns);
    }
    /**
     * Creates a time log entry based on the provided CTI message.
     *
     * This function attempts to upsert a time log using the `timeLogUtil.upsertTimeLog` method.
     * If the time log is successfully created and has an ID, it sets the attach data for the
     * interaction with the time log ID and updates the message's attach data with the time log ID.
     *
     * @param {CtiMessage} message - The CTI message containing interaction details.
     * @returns {Promise<Record<string, unknown>>} - A promise that resolves to the created or updated time log record.
     */
    async createTimelog(message) {
        const timelog = await timeLogUtil.upsertTimeLog(message);
        if (timelog && timelog.Id) {
            iwscommand.SetAttachdataById(message.InteractionID, { timelog_id: timelog.Id });
            message.attachdata.timelog_id = timelog.Id;
        }
        return timelog;
    }
}
const sfutil = new Util();
