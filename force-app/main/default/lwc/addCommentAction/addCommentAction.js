import { LightningElement, api } from 'lwc';
import submitCaseComment from '@salesforce/apex/ServiceRequestController.submitCaseComment';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class AddCommentAction extends LightningElement {
    @api recordId;
    commentText = '';
    showLoading = false;

    handleCommentChange(event) {
        this.commentText = event.target.value;
    }

    handleSubmit() {
        this.showLoading = true;
        submitCaseComment({ caseId: this.recordId, commentBody: this.commentText })
            .then(() => {
                this.showLoading = false;
                this.showToast('Success', 'Comment added successfully.', 'success');
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                this.showLoading = false;
                this.showToast('Error', error.body.message, 'error');
            });
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    // Helper function to show toast notifications
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }
}