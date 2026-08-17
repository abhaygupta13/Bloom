import { LightningElement, api, track } from 'lwc';
import generateLeasingStatementSAP from '@salesforce/apex/LeasingSOAPDFHandler.generateSOA_SAP_PDF';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class LeasingDynamicDocGenActions extends LightningElement {
    @api recordId;
    @track selectedAction = '';
    showFirst = false;
    showSecond = false;
    showThird = false;
    showFourth = false;
    statementDate = new Date().toISOString().split('T')[0];
    get options() {
        return [
            { label: 'Leasing Offer', value: 'Leasing Offer' },
            { label: 'Leasing Contract & other docs', value: 'Leasing Contract' },
            { label: 'Statement of Account - Invoice', value: 'SOA-Invoice' },
            { label: 'Statement of Account - Full', value: 'SOA-Full' },
            { label: 'Statement of Account - SAP', value: 'SOA-SAP' }
        ];
    }

    get isDisabled() {
        return !this.selectedAction;
    }
    get isComponentShown() {
        return this.showFirst || this.showSecond || this.showThird || this.showFourth || this.showFifth;
    }
    get showSOAPDate() {
        return this.selectedAction === 'SOA-SAP';
    }

    handleChange(event) {
        this.selectedAction = event.detail.value;
    }
    handleDateChange(event) {
        this.statementDate = event.target.value;
    }

    handleProceed() {
        if (this.selectedAction === 'Leasing Offer') {
            this.showFirst = true;
            this.showSecond = false;
            this.showThird = false;
            this.showFourth = false;
        } else if (this.selectedAction === 'Leasing Contract') {
            this.showSecond = true;
            this.showFirst = false;
            this.showThird = false;
            this.showFourth = false;
        }
        else if (this.selectedAction === 'SOA-Invoice') {
            this.showThird = true;
            this.showFirst = false;
            this.showSecond = false;
            this.showFourth = false;
        }
        else if (this.selectedAction === 'SOA-Full') {
            this.showThird = false;
            this.showFirst = false;
            this.showSecond = false;
            this.showFourth = true;
        }
        else if (this.selectedAction === 'SOA-SAP') {
            this.showThird = false;
            this.showFirst = false;
            this.showSecond = false;
            this.showFourth = false;
            console.log('insider 1');
            this.handleSOAPDFGeneration();
        }
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    handleCloseQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSOAPDFGeneration() {
        console.log('inside');
        this.isLoading = true;
        generateLeasingStatementSAP({ leasingOrderId: this.recordId, statementDate: this.statementDate })
            .then((_) => {
                console.log('PDF request sent');
                this.isLoading = false;
                this.showToast('Success', 'PDF Generation Request created successfully! Mail will be sent to Leasing Manager.', 'success');

                setTimeout(() => this.handleCloseQuickAction(), 100);
            })
            .catch((error) => {
                console.error('Error generating PDF:', JSON.stringify(error));
                this.isLoading = false;
                this.showToast('Error', error.body.message, 'error');
            });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}