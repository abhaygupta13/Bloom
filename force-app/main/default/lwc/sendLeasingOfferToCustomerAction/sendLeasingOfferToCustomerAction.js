import { LightningElement, api } from 'lwc';
import sendEmailWithDocument from '@salesforce/apex/LeasingOrderController.sendEmailWithDocument';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class SendDocumentEmail extends LightningElement {
    @api recordId;
    isLoading = false;

    async handleSend() {
        this.isLoading = true;

        try {
            await sendEmailWithDocument({ recordId: this.recordId });
             this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Leasing Offer Shared with Customer',
                    variant: 'success',
                    mode: 'dismissable'
                })
            );
        } catch (error) {
            console.error('Error sending email:', error);
             
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Failed to send email.',
                    variant: 'error',
                    mode: 'sticky'
                })
            );
            // Optionally show error toast or message here
        } finally {
            this.isLoading = false;
            this.dispatchEvent(new CloseActionScreenEvent());
        }
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}