import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import checkScope from '@salesforce/apex/ServiceAppointmentController.checkScope';
import Scope from '@salesforce/schema/WorkOrder.Scope__c';
import Check_In from '@salesforce/schema/WorkOrder.Check_In__c';
import Customer_Availability from '@salesforce/schema/WorkOrder.Customer_Availability__c';
import { CloseActionScreenEvent } from 'lightning/actions';
import LightningAlert from 'lightning/alert';


const fields = [Scope, Check_In, Customer_Availability];

export default class DlpScope extends LightningElement {
    @api recordId; // The Work Order Id
    @api objectApiName;
    contentDocumentId;
    agentComment;
    error;
    result;
    isimagecapture = false;
    isVisible = false;
    isVisibleRsolutionTypology = false;
    isdlp = false;
    isUnderScopeCapture = false;
    imageType = 'Before';
    checkInValue;
    typologyValue;
    @track workOrder;


    scopeOptions = [
        { label: 'Under DLP Scope', value: 'Under Scope' },
        { label: 'Not in DLP Scope', value: 'Outside Scope' }
    ];

    resolutionTypologyOptions = [
        { label: 'Repair', value: 'Repair' },
        { label: 'Replace', value: 'Replace' }
    ];


    connectedCallback() {
        console.log('recordId', this.recordId);
    }


    handleChange(event) {
        this.checkInValue = event.detail.value;
        if (event.detail.value == 'Under Scope') {
            this.isVisibleRsolutionTypology = true;
            this.isimagecapture = true;
        } else if (event.detail.value == 'Outside Scope') {
            this.isimagecapture = true;
            this.isVisibleRsolutionTypology = false;
        }
    }

    handleCommentChange(event) {
        this.agentComment = event.currentTarget.value;
    }

    handleChangeResolutionTypology(evt) {
        this.typologyValue = evt.detail.value;
        console.log('typologyValue: ', this.typologyValue);
    }

    @wire(getRecord, { recordId: '$recordId', fields })
    wiredWorkOrder(result) {
        this.wiredWorkOrderResult = result;
        if (result.data != undefined) {
            console.log('in wire');
            this.workOrder = result.data.fields;
            if (this.workOrder.Check_In__c.value == true && (this.workOrder.Scope__c.value == undefined || this.workOrder.Scope__c.value == '')) {
                this.isVisible = true;
            }

        } else if (result.error != undefined) {
            console.error('Error retrieving:', error);
            this.handleAlert('error', 'An error has occured', 'Please contact Admin for support');
        }
    }

    handleData(e) {
        console.log('e', e.detail.dataValue);
        this.contentDocumentId = e.detail.dataValue;
    }

    handleSave() {
        this.result = 'in save'
        console.log('contentDocumentId:', this.contentDocumentId, 'scope:', this.checkInValue, 'workOrderId:', this.recordId, 'resolutionTypology:', this.typologyValue);
        if (this.checkValidity()) {
            checkScope({ contentDocumentId: this.contentDocumentId, agentComments: this.agentComment, scope: this.checkInValue, workOrderId: this.recordId, resolutionTypology: this.typologyValue })
                .then((result) => {
                    console.log(result);
                    this.result = result;
                    if (this.result == 'Success') {
                        refreshApex(this.wiredWorkOrderResult);
                        this.dispatchEvent(new CloseActionScreenEvent());
                        // this.handleAlert('success','Record Saved Successfully','');
                    } else {
                        this.handleAlert('error', 'An error has occured', 'Please contact Admin for support');
                    }
                })
                .catch(error => {
                    error = this.error;
                    console.error('Error updating record:', error);
                    this.handleAlert('error', 'An error has occured', 'Please contact Admin for support');
                });
        } else {
            this.handleAlert('error', 'Unable to Save Record', 'Please add all details to Save this Record');
        }
    }

    checkValidity() {
        let isValid = true;
        if (this.checkInValue == undefined || this.checkInValue == '') {
            isValid = false
        } else if ((this.checkInValue == 'Under Scope' || this.checkInValue == 'Outside Scope') && (this.contentDocumentId == '' || this.contentDocumentId == undefined)) {
            isValid = false;
        }
        return isValid;
    }

    async handleAlert(theme, label, message) {
        await LightningAlert.open({
            message: message,
            theme: theme,
            label: label,
        });
    }
}