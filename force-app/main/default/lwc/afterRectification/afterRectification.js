import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import checkRectification from '@salesforce/apex/ServiceAppointmentController.checkRectification';
import Rectification from '@salesforce/schema/WorkOrder.Rectification__c';
import Scope from '@salesforce/schema/WorkOrder.Scope__c';
import Check_In from '@salesforce/schema/WorkOrder.Check_In__c';
import Customer_Availability from '@salesforce/schema/WorkOrder.Customer_Availability__c';
import { CloseActionScreenEvent } from 'lightning/actions';
import LightningAlert from 'lightning/alert';


const fields = [Rectification,Check_In,Customer_Availability,Scope];

export default class AfterRectification extends LightningElement {
    @api recordId; // The Work Order Id
    @api objectApiName;
    contentDocumentId;
    wiredWorkOrderResult;
    customerComment;
    error;
    result;
    isimagecapture= true;
    isVisible = false;
    isdlp = false;
    imageType = 'After';
    isUnderScopeCapture = false;
    checkInValue;
    @track workOrder;

    connectedCallback() {
        console.log('recordId', this.recordId);
    }

    handleCommentChange(event) {
        this.customerComment = event.currentTarget.value;
    }

    handleChange(event) {
        this.checkInValue = event.detail.value;
        if(event.detail.value == 'Under Scope'){
            this.isimagecapture = true;
        }else if(event.detail.value == 'Outside Scope'){
            this.isimagecapture = false;
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields })
    wiredWorkOrder(result) {
        this.wiredWorkOrderResult = result;
        if (result.data != undefined) {
            console.log('in wire');
            this.workOrder = result.data.fields;
            if(this.workOrder.Rectification__c.value == 'Pending' && (this.workOrder.Scope__c != '' && this.workOrder.Scope__c != 'Outside Scope')){
                this.isVisible = true;
            }
        } else if (result.error != undefined) {
            this.handleAlert('error','An error has occured','Please contact Admin for support');
        }
    }

    handleData(e) {
        console.log('e', e.detail.dataValue);
        this.contentDocumentId = e.detail.dataValue;
    }

    handleSave() {
            if(this.checkValidity()){
                checkRectification({ contentDocumentId: this.contentDocumentId, agentComments: this.customerComment, workOrderId: this.recordId })
                .then((result) => {
                    console.log(result);
                    this.result = result;
                    if(this.result == 'Success'){
                        refreshApex(this.wiredWorkOrderResult);
                        this.dispatchEvent(new CloseActionScreenEvent());
                        //this.handleAlert('success','Record Saved Successfully','');
                    }else{
                        this.handleAlert('error','An error has occured','Please contact Admin for support');
                    }
                })
                .catch(error => {
                    error = this.error;
                    this.handleAlert('error','An error has occured','Please contact Admin for support');
                    console.error('Error updating record:', error);
                });
            }else{
                this.handleAlert('error','Unable to Save Record','Please add all details to Save this Record');
            }
    }

    checkValidity(){
        let isValid = true;
        if(this.contentDocumentId == '' || this.contentDocumentId == undefined){
            isValid = false;
            this.handleAlert('error','Upload Image','Please upload image before save');
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