import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import checkOut from '@salesforce/apex/ServiceAppointmentController.checkOut';
import { refreshApex } from '@salesforce/apex';
import Rectification from '@salesforce/schema/WorkOrder.Rectification__c';
import Check_In from '@salesforce/schema/WorkOrder.Check_In__c';
import Status from '@salesforce/schema/WorkOrder.Status';
import Customer_Availability from '@salesforce/schema/WorkOrder.Customer_Availability__c';
import { CloseActionScreenEvent } from 'lightning/actions';
import saveSign from '@salesforce/apex/ServiceAppointmentController.saveSign';
import LightningAlert from 'lightning/alert';

let canvas, ctx;
let isDrawing = false;
let prevX = 0, prevY = 0, currX = 0, currY = 0;


const fields = [Rectification, Check_In, Customer_Availability,Status];

export default class CheckOut extends LightningElement {

    // @track stars = [
    //     { index: 1, icon: 'utility:emoji', emojiStyle: 'notSelected-smiley' },
    //     { index: 2, icon: 'utility:emoji', emojiStyle: 'notSelected-smiley' },
    //     { index: 3, icon: 'utility:emoji', emojiStyle: 'notSelected-smiley' },
    //     { index: 4, icon: 'utility:emoji', emojiStyle: 'notSelected-smiley' },
    //     { index: 5, icon: 'utility:emoji', emojiStyle: 'notSelected-smiley' }
    // ];

    @track stars = [
        { index: 1, icon: '😡', emojiStyle: 'emoji blank-smiley sad-smiley' },
        { index: 2, icon: '☹️', emojiStyle: 'emoji blank-smiley confused-smiley' },
        { index: 3, icon: '😐', emojiStyle: 'emoji blank-smiley neutral-smiley' },
        { index: 4, icon: '🙂', emojiStyle: 'emoji blank-smiley happy-smiley' },
        { index: 5, icon: '😁', emojiStyle: 'emoji blank-smiley very-happy-smiley' }
    ];

    @api recordId; // The Work Order Id
    @api objectApiName;
    customerComment;
    contentDocumentId;
    wiredWorkOrderResult;
    error;
    result;
    isimagecapture = true;
    isVisible = false;
    isdlp = false;
    isUnderScopeCapture = false;
    checkInValue;
    signedBy;
    @track workOrder;
    isVisibleWhenNotCheckIN = false;

    connectedCallback() {
        console.log('recordId', this.recordId);
    }


    handleChange(event) {
        this.customerComment = event.currentTarget.value;
    }
    handleSignedBy(event) {
        this.signedBy = event.currentTarget.value;
    }


    // handleRatingClick(event) {
    //     this.checkInValue = event.target.dataset.index;

    //     const rating = parseInt(event.target.dataset.index, 10);
    //     this.stars = this.stars.map(star => ({
    //         ...star,
    //         emojiStyle: star.index <= rating ? 'selected-smiley' : 'notSelected-smiley'
    //     }));

    //     // Dispatch the event with the selected rating value
    //     this.dispatchEvent(new CustomEvent('ratingchange', { detail: { rating } }));
    // }
    handleRatingClick(event) {
    const rating = parseInt(event.target.dataset.index, 10);
    this.checkInValue = rating;

    // Update emoji styles based on the selected rating
    this.stars = this.stars.map(star => ({
        ...star,
        emojiStyle: 
            star.index <= rating 
                ? `emoji filled-smiley ${star.emojiStyle.split(' ')[2]}` // Filled for selected
                : `emoji blank-smiley ${star.emojiStyle.split(' ')[2]}` // Blank for unselected
    }));

    // Dispatch the selected rating value
    this.dispatchEvent(new CustomEvent('ratingchange', { detail: { rating } }));
}


    @wire(getRecord, { recordId: '$recordId', fields })
    wiredWorkOrder(result) {
        this.wiredWorkOrderResult = result;
        if (result.data != undefined) {
            console.log('in wire');
            this.workOrder = result.data.fields;
            console.log(this.isVisible, ' << workOrder: ' , this.workOrder);
            if (this.workOrder.Status.value == 'Completed') {
                this.isVisible = false;
                this.isVisibleWhenNotCheckIN = true;
            }
            else if (this.workOrder.Rectification__c.value == 'Completed') {
                this.isVisible = true;
                this.isVisibleWhenNotCheckIN = false;
            }
        } else if (result.error != undefined) {
            console.error('Error retrieving:', error);
            this.handleAlert('error', 'An error has occured', 'Please contact Admin for support');
        }
    }

    handleSave() {
        if (this.checkValidity()) {
            checkOut({ rating: this.checkInValue, comment: this.customerComment, workOrderId: this.recordId,signedBy :this.signedBy })
                .then((result) => {
                    console.log(result);
                    this.result = result;
                    if (this.result == 'Success') {
                        this.saveSigntoRecord();
                        refreshApex(this.wiredWorkOrderResult);
                        this.dispatchEvent(new CloseActionScreenEvent());
                        // this.handleAlert('success','Record Saved Successfully','');
                    } else if (this.result == 'Already checked out') {
                        this.handleAlert('error', 'An error has occured', 'You have already checked out');
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

    saveSigntoRecord() {
        ctx.globalCompositeOperation = "destination-over";
        ctx.fillStyle = "#FFFFFF"; // White background
        ctx.fillRect(0, 0, canvas.width, canvas.height);
        const dataURL = canvas.toDataURL("image/png").replace(/^data:image\/(png|jpg);base64,/, "");
        saveSign({ recordId: this.recordId, strSignElement: dataURL })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Signature saved to record.',
                    variant: 'success',
                }));
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error saving signature',
                    message: error.body.message,
                    variant: 'error',
                }));
            })

    }

    checkValidity() {
        let isValid = true;
        if (this.checkInValue == undefined && this.customerComment) {
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

    renderedCallback() {
        if (!canvas && this.isVisible == true) {
            canvas = this.template.querySelector('canvas');
            ctx = canvas.getContext("2d");
            canvas.width = canvas.parentElement.offsetWidth;
            canvas.height = canvas.parentElement.offsetHeight;
            // Set up mouse and touch event listeners
            canvas.addEventListener('mousedown', this.startDrawing.bind(this));
            canvas.addEventListener('mousemove', this.draw.bind(this));
            canvas.addEventListener('mouseup', this.endDrawing.bind(this));
            canvas.addEventListener('mouseout', this.endDrawing.bind(this));

            canvas.addEventListener('touchstart', this.startDrawing.bind(this), { passive: false });
            canvas.addEventListener('touchmove', this.draw.bind(this), { passive: false });
            canvas.addEventListener('touchend', this.endDrawing.bind(this));
        }
    }

    startDrawing(event) {
        event.preventDefault();
        isDrawing = true;
        const { clientX, clientY } = this.getEventCoordinates(event);
        prevX = clientX - canvas.getBoundingClientRect().left;
        prevY = clientY - canvas.getBoundingClientRect().top;
    }

    draw(event) {
        if (!isDrawing) return;
        event.preventDefault();

        const { clientX, clientY } = this.getEventCoordinates(event);
        currX = clientX - canvas.getBoundingClientRect().left;
        currY = clientY - canvas.getBoundingClientRect().top;

        ctx.beginPath();
        ctx.moveTo(prevX, prevY);
        ctx.lineTo(currX, currY);
        ctx.strokeStyle = "#000000"; // Black signature color
        ctx.lineWidth = 2;
        ctx.stroke();
        ctx.closePath();

        prevX = currX;
        prevY = currY;
    }

    endDrawing() {
        isDrawing = false;
    }

    getEventCoordinates(event) {
        if (event.touches && event.touches[0]) {
            return { clientX: event.touches[0].clientX, clientY: event.touches[0].clientY };
        } else {
            return { clientX: event.clientX, clientY: event.clientY };
        }
    }

    handleSaveClick() {
    }

    handleClearClick() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
    }

}