import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import checkIn from '@salesforce/apex/ServiceAppointmentController.checkIn';
import Check_In from '@salesforce/schema/WorkOrder.Check_In__c';
import Customer_Availability from '@salesforce/schema/WorkOrder.Customer_Availability__c';
import { CloseActionScreenEvent } from 'lightning/actions';
import LightningAlert from 'lightning/alert';

const fields = [Check_In,Customer_Availability];

export default class CheckIN extends LightningElement {
    @api recordId; // The Work Order Id
    @api objectApiName;
    contentDocumentId;
    agentComment;
    isVisible = true;
    error;
    response;
    isdlp = false;
    isimagecapture = false;
    isUnderScopeCapture = false;
    checkInValue;
    options = [
        { label: 'Customer Available', value: 'Available' },
        { label: 'Customer Not Available', value: 'Not Available' }
    ];
    @track workOrder;
    wiredWorkOrderResult;

    connectedCallback() {
        console.log('recordId', this.recordId);
    }

    handleChange(event) {
        this.checkInValue = event.detail.value;
        if (event.detail.value == 'Available') {
            this.isimagecapture = false;
        } else if (event.detail.value == 'Not Available') {
            this.isimagecapture = true;
        }
    }

    handleCommentChange(event) {
        this.agentComment = event.currentTarget.value;
    }

    @wire(getRecord, { recordId: '$recordId', fields })
    wiredWorkOrder(result) {
        this.wiredWorkOrderResult = result;
        if (result.data != undefined) {
            console.log('in wire');
            this.workOrder = result.data.fields;
            if (this.workOrder.Check_In__c.value === true && this.workOrder.Customer_Availability__c.value === 'Available') {
                this.isVisible = false;
            }
        } else if (result.error != undefined) {
            console.error('Error retrieving:', error);
            this.handleAlert('error','An error has occured','Please contact Admin for support');
        }
    }

    handleData(e) {
        console.log('e', e.detail.dataValue);
        this.contentDocumentId = e.detail.dataValue;
    }

    handleSave() {
            if(this.checkValidity()){
                checkIn({ contentDocumentId: this.contentDocumentId,
                 customerAvailablity: this.checkInValue, agentComments: this.agentComment, workOrderId: this.recordId })
                .then((result) => {
                    console.log(result);
                    this.response = result;
                    if(this.response == 'Success'){
                        refreshApex(this.wiredWorkOrderResult);
                        this.dispatchEvent(new CloseActionScreenEvent());
                      //  this.handleAlert('success','Record Saved Successfully','');
                    }else{
                        this.handleAlert('error','An error has occured','Please contact Admin for support');
                    }
                })
                .catch(error => {
                    error = this.error;
                    console.error('Error updating record:', error);
                    this.handleAlert('error','An error has occured','Please contact Admin for support');
                });
            }else{
                this.handleAlert('error','Unable to Save Record','Please add all details to Save this Record');
            }
    }

    checkValidity(){
        let isValid = true;
        if(this.checkInValue == undefined || this.checkInValue == ''){
            isValid = false
        }else if(this.checkInValue == 'Not Available' && (this.contentDocumentId == '' || this.contentDocumentId == undefined)){
            isValid = false;
        }
        return isValid;
    }

    async handleAlert(theme,label,message) {
        await LightningAlert.open({
            message: message,
            theme: theme,
            label: label,
        });
    }
}