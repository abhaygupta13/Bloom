class TimeLogUtil {
    async upsertTimeLog(message) {
        if (!softphoneSettings.GEN_TIMELOG_ENABLED) {
            log.info(`timelog disabled.`);
            return;
        }
        log.info(`upsertTimeLog id=${message.InteractionID} START, msg: ${JSON.stringify(message)}`);
        if (softphoneSettings.GEN_INTEGRATION_TYPE == "PURECLOUD" && message.SourceMsg) {
            if (!message.SourceMsg.data) {
                message.SourceMsg.data = { ...message.SourceMsg };
            }
        }
        let objToUpsert = undefined;
        let result;
        try {
            objToUpsert = {
                Name: this.buildName(message),
                softphone_it__Interaction_Id__c: message.InteractionID,
                softphone_it__Agent_Id__c: gcUser?.name || message.AgentID,
                softphone_it__Direction__c: message.CallType,
                softphone_it__Media_Type__c: message.MediaType,
                softphone_it__Queue__c: message.SourceMsg?.data?.queueName,
                softphone_it__Disposition_Code__c: message.SourceMsg?.data?.disposition,
                softphone_it__Contact__c: message.attachdata?.contact_id,
                softphone_it__Account__c: message.attachdata?.account_id,
                softphone_it__Case__c: message.attachdata?.case_id,
                softphone_it__Parent_Id__c: message.attachdata?.task_id
            };
            const callTime = Date.now();
            if (message.EVENT.endsWith("Ringing") || message.EVENT.endsWith("Dialing")) {
                objToUpsert.softphone_it__Ringing_Time__c = callTime;
                result = await coreUtils.callApiSync(softphone_it.ConnectorController.insertConnectorEventTimeLog, objToUpsert);
                return result;
            }
            if (message.EVENT.endsWith("MarkDone")) {
                objToUpsert.softphone_it__MarkDone_Time__c = callTime;
            }
            if (message.SourceMsg?.data?.connectedTime && message.EVENT.endsWith("Established")) {
                objToUpsert.softphone_it__Established_Time__c = message.SourceMsg?.data?.isCallback ? callTime : new Date(message.SourceMsg?.data?.connectedTime).getTime();
            }
            if (message.SourceMsg?.category == 'callbackCallEnded') {
                message.SourceMsg.data = { endTime: new Date().toISOString(), id: message.InteractionID };
            }
            if (message.SourceMsg?.data?.endTime) {
                objToUpsert.softphone_it__Released_Time__c = new Date(message.SourceMsg?.data?.endTime).getTime();
                objToUpsert.softphone_it__State__c = message.SourceMsg?.data?.connectedTime || message.PickedUp ? 'answered' : 'not answered';
            }
            objToUpsert.softphone_it__Interaction_Duration__c = message.SourceMsg?.data?.interactionDurationSeconds;
            objToUpsert.softphone_it__Total_Acd_Duration__c = message.SourceMsg?.data?.totalAcdDurationSeconds;
            objToUpsert.softphone_it__Total_Ivr_Duration__c = message.SourceMsg?.data?.totalIvrDurationSeconds;
            objToUpsert.softphone_it__Disposition_Duration__c = message.SourceMsg?.data?.dispositionDurationSeconds;
            result = await coreUtils.callApiSync(softphone_it.ConnectorController.upsertConnectorEventTimeLog, objToUpsert);
            log.info(`createCustomTimelog id=${message.InteractionID} END, result: ${JSON.stringify(result)}`);
        }
        catch (e) {
            log.info(`upsertTimeLog id=${message.InteractionID} ERROR: ${JSON.stringify(e)}`);
        }
        return result;
    }
    buildName(message) {
        const media = message.MediaType == 'voice' ? 'Call' : this.getFirstLetterCapital(message.MediaType);
        const direction = message.CallType == 'Inbound' ? 'from' : 'to';
        let identifier;
        if (message.MediaType == "voice" || message.MediaType == "whatsapp" || message.MediaType == "sms") {
            identifier = message.CallType == 'Inbound' ? message.ANI : message.DNIS;
        }
        else {
            if (message.attachdata) {
                identifier = message.attachdata["context.email"];
            }
            else {
                identifier = message.EmailAddress;
            }
        }
        return `${media} ${direction} ${identifier}`;
    }
    getFirstLetterCapital(str) {
        // Check if the input is a string
        if (typeof str !== 'string') {
            throw new TypeError('Input must be a string.');
        }
        // Check if the string is empty
        if (str.length === 0) {
            return '';
        }
        // Get the first character and convert it to uppercase
        return str.charAt(0).toUpperCase() + str.slice(1);
    }
}
// eslint-disable-next-line @typescript-eslint/no-unused-vars
const timeLogUtil = new TimeLogUtil();
